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
    const isOtherDigital = ['epic', 'ps4_digital', 'ps5_digital', 'psn_digital', 'nintendo_digital'].includes(platform)
    const isNintendoPhysical = ['nintendo', 'nintendo_physical'].includes(platform)

    if (isPhysicalPlayStation || isNintendoPhysical) {
       if (externalId) {
          priceData = await fetchPriceCharting(externalId)
       } else {
          // Fallback to title search if no external ID
          priceData = await fetchCheapShark(title, platform)
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
  }
}

async function fetchCheapShark(title: string, platform: string) {
  // 1. Search for the game to get internal ID
  const searchRes = await fetch(
    `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}&limit=1`
  )
  if (!searchRes.ok) throw new Error(`CheapShark search error: ${searchRes.statusText}`)
  
  const games = await searchRes.json()
  const game = games?.[0]
  if (!game) {
    return {
      price_loose: null,
      price_complete: null,
      price_new: null,
      price_digital: 0,
      source: 'cheapshark',
      currency: 'USD',
    }
  }

  // 2. Get current cheapest deal for this game
  const detailRes = await fetch(
    `https://www.cheapshark.com/api/1.0/games?id=${game.gameID}`
  )
  if (!detailRes.ok) throw new Error(`CheapShark detail error: ${detailRes.statusText}`)
  
  const details = await detailRes.json()
  const deals = details.deals || []
  
  // Find the lowest current price across all stores
  let lowestCurrent = 0
  if (deals.length > 0) {
    lowestCurrent = Math.min(...deals.map((d: any) => parseFloat(d.price)))
  } else {
    // Fallback to the historical cheapest if no current deals (rare for CheapShark)
    lowestCurrent = parseFloat(game.cheapest || '0')
  }

  return {
    price_loose: null,
    price_complete: null,
    price_new: null,
    price_digital: lowestCurrent,
    source: 'cheapshark',
    currency: 'USD',
  }
}
