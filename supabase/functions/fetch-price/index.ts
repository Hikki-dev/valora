import { z } from 'zod'
import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { checkRateLimit } from '../_shared/rateLimit.ts'

// Input validation schema — rejects malformed requests before any logic
const RequestSchema = z.object({
  gameId:     z.string().uuid('gameId must be a valid UUID'),
  platform:   z.enum(['ps_disc', 'psn', 'steam', 'epic', 'nintendo']),
  externalId: z.string().min(1).max(128).regex(
    /^[a-zA-Z0-9_\-\s:]+$/,
    'externalId contains invalid characters'
  ),
  title:       z.string().min(1).max(200),
  forceRefresh: z.boolean().optional().default(false),
})

// Cache TTL by platform (hours)
const CACHE_TTL: Record<string, number> = {
  ps_disc:  24,
  psn:       6,
  steam:     6,
  epic:      6,
  nintendo:  6,
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Auth check
    const { user, supabase } = await verifyUser(req)

    // 2. Rate limit check
    await checkRateLimit(supabase, user.id)

    // 3. Input validation
    let body: z.infer<typeof RequestSchema>
    try {
      body = RequestSchema.parse(await req.json())
    } catch (e: any) {
      return new Response(
        JSON.stringify({ error: 'Invalid input', details: e.errors }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Cache check
    if (!body.forceRefresh) {
      const { data: cached } = await supabase
        .from('valuations')
        .select('*')
        .eq('game_id', body.gameId)
        .single()

      if (cached?.fetched_at) {
        const ageHours =
          (Date.now() - new Date(cached.fetched_at).getTime()) / 3_600_000
        if (ageHours < CACHE_TTL[body.platform]) {
          return new Response(JSON.stringify(cached), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      }
    }

    // 5. Fetch fresh price from appropriate source
    let priceData: Record<string, any>

    if (body.platform === 'ps_disc') {
      priceData = await fetchPriceCharting(body.externalId)
    } else if (body.platform === 'steam') {
      priceData = await fetchSteam(body.externalId)
    } else {
      priceData = await fetchCheapShark(body.title, body.platform)
    }

    // 6. Upsert to DB and return
    const { data: valuation, error: upsertError } = await supabase
      .from('valuations')
      .upsert(
        { game_id: body.gameId, user_id: user.id, ...priceData, fetched_at: new Date().toISOString() },
        { onConflict: 'game_id' }
      )
      .select()
      .single()

    if (upsertError) throw upsertError

    return new Response(JSON.stringify(valuation), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err: any) {
    const status =
      err.message.includes('Unauthorized') ? 401 :
      err.message.includes('Rate limit')   ? 429 :
      err.message.includes('Invalid input') ? 400 : 500

    return new Response(
      JSON.stringify({ error: err.message }),
      { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// ── Price source implementations ──────────────────────────────────────────────

async function fetchPriceCharting(externalId: string) {
  // Uses the public demo token for low-volume personal use
  const token = Deno.env.get('PRICE_CHARTING_TOKEN') ??
    'c0b53bce27c1bdab90b1605249e600dc43dfd1d5'

  const res = await fetch(
    `https://www.pricecharting.com/api/product?id=${encodeURIComponent(externalId)}&t=${token}`,
    { headers: { 'User-Agent': 'Valora/1.0' } }
  )
  if (!res.ok) throw new Error(`PriceCharting error: ${res.status}`)
  const d = await res.json()

  return {
    price_loose:    (d['loose-price']   ?? 0) / 100,
    price_complete: (d['cib-price']     ?? 0) / 100,
    price_new:      (d['new-price']     ?? 0) / 100,
    price_digital:  null,
    source:         'pricecharting',
    currency:       'USD',
  }
}

async function fetchSteam(appId: string) {
  const res = await fetch(
    `https://store.steampowered.com/api/appdetails?appids=${encodeURIComponent(appId)}&cc=US&l=english`
  )
  if (!res.ok) throw new Error(`Steam API error: ${res.status}`)
  const data = await res.json()
  const app = data[appId]?.data

  return {
    price_loose:    null,
    price_complete: null,
    price_new:      null,
    price_digital:  app?.price_overview?.final
      ? app.price_overview.final / 100
      : 0,
    source:         'steam',
    currency:       'USD',
  }
}

async function fetchCheapShark(title: string, platform: string) {
  const res = await fetch(
    `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}&limit=5`
  )
  if (!res.ok) throw new Error(`CheapShark error: ${res.status}`)
  const games = await res.json()

  // Find best price match across deals
  const game = games?.[0]
  const price = game?.cheapestPriceEver
    ? parseFloat(game.cheapestPriceEver)
    : 0

  return {
    price_loose:    null,
    price_complete: null,
    price_new:      null,
    price_digital:  price,
    source:         'cheapshark',
    currency:       'USD',
  }
}
