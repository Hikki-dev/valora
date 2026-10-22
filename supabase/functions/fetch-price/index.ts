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
  ).nullable().optional(),
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

const FETCH_TIMEOUT_MS = 8000

// A price result. `null` means "the source had no price" and is stored as such:
// the app shows "—". We never invent a number.
interface PriceResult {
  price_loose:    number | null
  price_complete: number | null
  price_new:      number | null
  price_digital:  number | null
  source:         string
  currency:       string
}

const NO_PRICE = (source: string): PriceResult => ({
  price_loose: null, price_complete: null, price_new: null, price_digital: null,
  source, currency: 'USD',
})

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Auth check
    const { user, supabase } = await verifyUser(req)

    // 2. Rate limit check
    await checkRateLimit(supabase, user.id, 60, 'fetch-price')

    // 3. Input validation
    let body: z.infer<typeof RequestSchema>
    try {
      body = RequestSchema.parse(await req.json())
    } catch (e: any) {
      return json({ error: 'Invalid input', details: e.errors }, 400)
    }

    // 4. Cache check (RLS scopes this to the caller's own valuation row)
    const { data: cached } = await supabase
      .from('valuations')
      .select('*')
      .eq('game_id', body.gameId)
      .maybeSingle()

    if (!body.forceRefresh && cached?.fetched_at) {
      const ageHours =
        (Date.now() - new Date(cached.fetched_at).getTime()) / 3_600_000
      if (ageHours < CACHE_TTL[body.platform]) {
        return json(cached)
      }
    }

    // 5. Fetch fresh price from appropriate source
    let priceData: PriceResult
    try {
      if (body.platform === 'ps_disc') {
        priceData = body.externalId
          ? await fetchPriceCharting(body.externalId)
          : await fetchPriceChartingByTitle(body.title)
      } else if (body.platform === 'steam') {
        if (!body.externalId) return json({ error: 'Steam games require an externalId' }, 400)
        priceData = await fetchSteam(body.externalId)
      } else {
        priceData = await fetchCheapShark(body.title)
      }
    } catch (sourceErr: any) {
      // Source is down / rate limited. Keep serving the last known price
      // rather than overwriting it with nothing.
      console.error('[fetch-price] source failure:', sourceErr?.message)
      if (cached) return json(cached)
      priceData = NO_PRICE('unavailable')
    }

    // 5b. The source answered but had no price. Never replace a last-known price
    // with blanks; just note that we checked so the cache TTL is respected.
    if (!hasPrice(priceData) && hasPrice(cached)) {
      const { data: touched } = await supabase
        .from('valuations')
        .update({ fetched_at: new Date().toISOString() })
        .eq('game_id', body.gameId)
        .select()
        .single()
      return json(touched ?? cached)
    }

    // 6. Upsert to DB
    const { data: valuation, error: upsertError } = await supabase
      .from('valuations')
      .upsert(
        { game_id: body.gameId, user_id: user.id, ...priceData, fetched_at: new Date().toISOString() },
        { onConflict: 'game_id' }
      )
      .select()
      .single()

    if (upsertError) throw upsertError

    // 7. History: only store a point when the price actually moved. Logging every
    // fetch bloats price_history, which counts against the free-tier DB quota.
    if (priceChanged(cached, priceData)) {
      const log = edgeLogHistory(supabase, body.gameId, priceData)
      // Keep the isolate alive until the insert lands (it is not awaited so the
      // response is not delayed).
      ;(globalThis as any).EdgeRuntime?.waitUntil?.(log)
    }

    return json(valuation)

  } catch (err: any) {
    const msg = String(err?.message ?? '')
    const status =
      msg.includes('Unauthorized') || msg.includes('Authorization') ? 401 :
      msg.includes('Rate limit')   ? 429 :
      msg.includes('Invalid input') ? 400 : 500

    // Never leak internal error text (SQL, upstream URLs, tokens) on a 500.
    if (status === 500) console.error('[fetch-price]', err)
    return json({ error: status === 500 ? 'Internal error' : msg }, status)
  }
})

// ── Helpers ───────────────────────────────────────────────────────────────────

const hasPrice = (r: any): boolean =>
  !!r && [r.price_loose, r.price_complete, r.price_new, r.price_digital].some((v) => v != null)

function priceChanged(prev: any, next: PriceResult): boolean {
  if (!prev) return true
  const same = (a: number | null, b: number | null) =>
    (a == null && b == null) || (a != null && b != null && Math.abs(a - b) < 0.005)
  return !(
    same(prev.price_loose, next.price_loose) &&
    same(prev.price_complete, next.price_complete) &&
    same(prev.price_new, next.price_new) &&
    same(prev.price_digital, next.price_digital)
  )
}

async function fetchJson(url: string): Promise<any> {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Valora/1.0' },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  })
  if (!res.ok) throw new Error(`Upstream ${new URL(url).hostname} returned ${res.status}`)
  return await res.json()
}

// PriceCharting reports prices in cents. Free/demo tiers redact them (0 or
// missing) — in that case we report "no price", never a made-up one.
const cents = (v: unknown): number | null => {
  const n = Number(v)
  return Number.isFinite(n) && n > 0 ? n / 100 : null
}

function priceChartingToken(): string {
  const token = Deno.env.get('PRICE_CHARTING_TOKEN')
  if (!token) throw new Error('PRICE_CHARTING_TOKEN is not configured')
  return token
}

function fromPriceCharting(d: any): PriceResult {
  return {
    price_loose:    cents(d?.['loose-price']),
    price_complete: cents(d?.['cib-price']),
    price_new:      cents(d?.['new-price']),
    price_digital:  null,
    source:         'pricecharting',
    currency:       'USD',
  }
}

// ── Price source implementations ──────────────────────────────────────────────

async function fetchPriceCharting(externalId: string): Promise<PriceResult> {
  const d = await fetchJson(
    `https://www.pricecharting.com/api/product?id=${encodeURIComponent(externalId)}&t=${priceChartingToken()}`
  )
  return fromPriceCharting(d)
}

async function fetchPriceChartingByTitle(title: string): Promise<PriceResult> {
  const d = await fetchJson(
    `https://www.pricecharting.com/api/products?q=${encodeURIComponent(title)}&t=${priceChartingToken()}`
  )
  const product = d?.products?.[0]
  return product ? fromPriceCharting(product) : NO_PRICE('pricecharting')
}

async function fetchSteam(appId: string): Promise<PriceResult> {
  const data = await fetchJson(
    `https://store.steampowered.com/api/appdetails?appids=${encodeURIComponent(appId)}&cc=US&l=english`
  )
  const entry = data?.[appId]
  if (!entry?.success) return NO_PRICE('steam')

  const app = entry.data
  // Free-to-play titles have no price_overview: that is a real $0.
  // Anything else without one (unreleased, delisted, region-locked) is "unknown".
  const price = app?.price_overview?.final != null
    ? app.price_overview.final / 100
    : app?.is_free ? 0 : null

  return { ...NO_PRICE('steam'), price_digital: price }
}

const normalizeTitle = (t: string) =>
  t.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim()

// CheapShark only tracks PC storefronts (Steam, Epic, GOG, ...). It cannot price
// PSN or Nintendo eShop titles, so for those we report "no price" instead of a
// misleading PC price. Users can enter a value manually in the app.
async function fetchCheapShark(title: string): Promise<PriceResult> {
  const games = await fetchJson(
    `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}&limit=10`
  )
  const wanted = normalizeTitle(title)
  // Exact title match only — taking games[0] priced the wrong game whenever
  // search ranking differed from the title.
  const match = (games as any[] | null)?.find(
    (g) => normalizeTitle(g?.external ?? '') === wanted
  )
  const price = match?.cheapest != null ? parseFloat(match.cheapest) : NaN

  return {
    ...NO_PRICE('cheapshark'),
    price_digital: Number.isFinite(price) ? price : null,
  }
}

/**
 * Helper to log price history without blocking the main response.
 * This is the engine that builds free historical trends over time.
 */
async function edgeLogHistory(supabase: any, gameId: string, priceData: PriceResult) {
  try {
    const { error } = await supabase
      .from('price_history')
      .insert({
        game_id: gameId,
        price_loose:    priceData.price_loose,
        price_complete: priceData.price_complete,
        price_new:      priceData.price_new,
        price_digital:  priceData.price_digital,
        source:         priceData.source,
      })

    if (error) {
      console.warn(`[HistoryLog] Skip/Error for ${gameId}: ${error.message}`)
    }
  } catch (err) {
    console.error(`[HistoryLog] Critical failure for ${gameId}:`, err)
  }
}
