import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { verifyUser } from '../_shared/auth.ts'
import { checkRateLimit } from '../_shared/rateLimit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { user, supabase } = await verifyUser(req)
    await checkRateLimit(supabase, user.id)

    const { gameId, platform, externalId, title, forceRefresh } = await req.json()

    if (!gameId || !platform) {
        throw new Error('Game ID and platform are required.')
    }

    // 1. Check cache first
    if (!forceRefresh) {
      const { data: cached } = await supabase
        .from('valuations')
        .select('*')
        .eq('game_id', gameId)
        .maybeSingle()

      const cacheAge = cached?.fetched_at
        ? (Date.now() - new Date(cached.fetched_at).getTime()) / 1000 / 60 / 60
        : Infinity

      // TTL: 6h for digital/Steam/Epic/PSN, 24h for physical
      const isDigital = ['steam', 'epic', 'ps4_digital', 'ps5_digital', 'psn_digital'].includes(platform)
      const ttlHours = isDigital ? 6 : 24

      if (cached && cacheAge < ttlHours) {
        console.log(`Using cached value for ${title} (${gameId})`);
        return new Response(JSON.stringify(cached), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    console.log(`Fetching fresh price for ${title} (${platform})...`);

    // 2. Fetch fresh price based on platform
    let priceData: any = {}

    // Normalized Platform grouping
    const isPhysicalPlayStation = ['ps4_physical', 'ps5_physical', 'playstation_physical'].includes(platform)
    const isSteam = platform === 'steam'
    const isNintendoPhysical = ['nintendo', 'nintendo_physical'].includes(platform)

    if (isPhysicalPlayStation || isNintendoPhysical) {
       if (externalId) {
          priceData = await fetchPriceCharting(externalId)
       }
       
       // Fallback to eBay if PriceCharting failed or had 0 values
       if (!priceData.price_complete || priceData.price_complete === 0) {
          console.log(`Fallback to eBay for ${title}...`);
          const ebayData = await fetchEbayMarket(title, platform)
          if (ebayData) {
            priceData = { ...priceData, ...ebayData }
          }
       }
    } else if (isSteam) {
      priceData = await fetchSteam(externalId)
    } else {
      priceData = await fetchCheapShark(title, platform)
    }

    // 3. Upsert into DB
    const { data: valuation, error: upsertError } = await supabase
      .from('valuations')
      .upsert({
        game_id: gameId,
        user_id: user.id,
        ...priceData,
        fetched_at: new Date().toISOString(),
      }, { onConflict: 'game_id' })
      .select()
      .single()

    if (upsertError) throw upsertError

    return new Response(JSON.stringify(valuation), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err: any) {
    console.error('fetch-price error:', err.message)
    const status = err.message.includes('Unauthorized') ? 401
      : err.message.includes('Rate limit') ? 429 : 500

    return new Response(JSON.stringify({ error: err.message }), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})

async function fetchPriceCharting(externalId: string) {
  const key = Deno.env.get('PRICE_CHARTING_TOKEN') || Deno.env.get('PRICECHARTING_API_KEY')
  if (!key) throw new Error('PriceCharting API key not configured.')
  
  const res = await fetch(
    `https://www.pricecharting.com/api/product?id=${externalId}&t=${key}`
  )
  if (!res.ok) throw new Error(`PriceCharting API error: ${res.statusText}`)
  
  const d = await res.json()
  return {
    price_loose: (d['loose-price'] ?? 0) / 100,
    price_complete: (d['cib-price'] ?? 0) / 100,
    price_new: (d['new-price'] ?? 0) / 100,
    price_digital: null,
    source: 'pricecharting',
    currency: 'USD',
    cover_url: d['image-url'] ?? null,
  }
}

async function fetchSteam(appId: string) {
  if (!appId) throw new Error('Steam AppID is required for Steam prices.')
  const res = await fetch(
    `https://store.steampowered.com/api/appdetails?appids=${appId}&cc=US&l=english`
  )
  if (!res.ok) throw new Error(`Steam API error: ${res.statusText}`)
  
  const d = await res.json()
  const app = d[appId]?.data
  return {
    price_loose: null,
    price_complete: null,
    price_new: null,
    price_digital: app?.price_overview ? app.price_overview.final / 100 : 0,
    source: 'steam',
    currency: 'USD',
    cover_url: app?.header_image || app?.capsule_imageV5 || null,
  }
}

async function fetchCheapShark(title: string, platform: string) {
  // ... existing implementation ...
  const searchRes = await fetch(
    `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}&limit=1`
  )
  if (!searchRes.ok) throw new Error(`CheapShark search error: ${searchRes.statusText}`)
  
  const games = await searchRes.json()
  const game = games?.[0]
  if (!game) return { price_digital: 0, source: 'cheapshark' }

  const detailRes = await fetch(`https://www.cheapshark.com/api/1.0/games?id=${game.gameID}`)
  const details = await detailRes.json()
  const deals = details.deals || []
  let lowestCurrent = deals.length > 0 ? Math.min(...deals.map((d: any) => parseFloat(d.price))) : parseFloat(game.cheapest || '0')

  return {
    price_loose: null,
    price_complete: null,
    price_new: null,
    price_digital: lowestCurrent,
    source: 'cheapshark',
    currency: 'USD',
    cover_url: game.thumb ?? null,
  }
}

async function fetchEbayMarket(title: string, platform: string) {
  try {
    const cleanTitle = title.replace(/\(.*?\)/g, '').replace(/['":-]/g, ' ').replace(/\s+/g, ' ').trim()
    const platformLabel = platform.includes('ps5') ? 'PS5' : platform.includes('ps4') ? 'PS4' : platform.includes('nintendo') ? 'Nintendo' : ''
    const query = encodeURIComponent(`${cleanTitle} ${platformLabel} Sold`)
    const url = `https://www.ebay.com/sch/i.html?_nkw=${query}&LH_Sold=1&LH_Complete=1`

    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
    })
    if (!res.ok) return null
    
    const html = await res.text()
    
    // Simple regex to extract prices (porting the logic from Dart)
    const priceRegex = /(?:s-item__price|s-card__price)[^>]*>\s*<span class="positive">\s*(?:[A-Z]+\s*)?\$?([\d,]+\.\d{2})/g
    const prices: number[] = []
    let match
    while ((match = priceRegex.exec(html)) !== null && prices.length < 10) {
      prices.push(parseFloat(match[1].replace(/,/g, '')))
    }

    if (prices.length === 0) return null

    // Average minus outliers
    prices.sort((a, b) => a - b)
    let avg = 0
    if (prices.length >= 5) {
      const sub = prices.slice(1, -1)
      avg = sub.reduce((a, b) => a + b, 0) / sub.length
    } else {
      avg = prices.reduce((a, b) => a + b, 0) / prices.length
    }

    return {
      price_loose: avg * 0.8,
      price_complete: avg,
      price_new: avg * 1.5,
      source: 'eBay (Market Avg)',
      currency: 'USD'
    }
  } catch (e) {
    console.error('eBay fetch error:', e)
    return null
  }
}
