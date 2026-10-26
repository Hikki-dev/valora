import { z } from 'zod'
import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { checkRateLimit } from '../_shared/rateLimit.ts'

const RequestSchema = z.object({
  gameId:     z.string().uuid('gameId must be a valid UUID'),
  platform:   z.enum(['ps_disc', 'psn', 'steam', 'epic', 'nintendo']),
  externalId: z.string().min(1).max(128).regex(
    /^[a-zA-Z0-9_\-\s:]+$/,
    'externalId contains invalid characters'
  ).nullable().optional(),
  title:       z.string().min(1).max(200),
  // Which PlayStation the disc is for. Only used to price discs from eBay.
  generation:  z.enum(['ps4', 'ps5']).nullable().optional(),
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

// `null` means "the source had no price" and is stored as such: the app shows "—".
// We never invent a number.
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
    const { user, supabase } = await verifyUser(req)
    await checkRateLimit(supabase, user.id, 60, 'fetch-price')

    let body: z.infer<typeof RequestSchema>
    try {
      body = RequestSchema.parse(await req.json())
    } catch (e: any) {
      return json({ error: 'Invalid input', details: e.errors }, 400)
    }

    // Cache check (RLS scopes this to the caller's own valuation row)
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

    let priceData: PriceResult
    try {
      if (body.platform === 'ps_disc') {
        if (Deno.env.get('PRICE_CHARTING_TOKEN')) {
          // Paid, sold-price data. Used whenever the token is set.
          priceData = body.externalId
            ? await fetchPriceCharting(body.externalId)
            : await fetchPriceChartingByTitle(body.title)
        } else {
          // Free alternative: live eBay listings.
          priceData = await fetchEbay(body.title, body.generation ?? null)
        }
      } else if (body.platform === 'steam') {
        if (!body.externalId) return json({ error: 'Steam games require an externalId' }, 400)
        priceData = await fetchSteam(body.externalId)
      } else {
        priceData = await fetchCheapShark(body.title)
      }
    } catch (sourceErr: any) {
      // Source is down / rate limited / not configured. Keep serving the last known price.
      console.error('[fetch-price] source failure:', sourceErr?.message)
      if (cached) return json(cached)
      priceData = NO_PRICE('unavailable')
    }

    // The source answered but had no price. Never replace a last-known price with
    // blanks; just note that we checked so the cache TTL is respected.
    if (!hasPrice(priceData) && hasPrice(cached)) {
      const { data: touched } = await supabase
        .from('valuations')
        .update({ fetched_at: new Date().toISOString() })
        .eq('game_id', body.gameId)
        .select()
        .single()
      return json(touched ?? cached)
    }

    const { data: valuation, error: upsertError } = await supabase
      .from('valuations')
      .upsert(
        { game_id: body.gameId, user_id: user.id, ...priceData, fetched_at: new Date().toISOString() },
        { onConflict: 'game_id' }
      )
      .select()
      .single()

    if (upsertError) throw upsertError

    // History: only store a point when the price actually moved (free-tier DB quota).
    if (priceChanged(cached, priceData)) {
      const log = edgeLogHistory(supabase, body.gameId, priceData)
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

// PriceCharting reports prices in cents. Free/demo tiers redact them (0 or missing):
// in that case we report "no price", never a made-up one.
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

// CheapShark only tracks PC storefronts. It cannot price PSN or Nintendo eShop titles,
// so those report "no price" instead of a misleading PC price (users can enter a value).
async function fetchCheapShark(title: string): Promise<PriceResult> {
  const games = await fetchJson(
    `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}&limit=10`
  )
  const wanted = normalizeTitle(title)
  const match = (games as any[] | null)?.find(
    (g) => normalizeTitle(g?.external ?? '') === wanted
  )
  const price = match?.cheapest != null ? parseFloat(match.cheapest) : NaN

  return {
    ...NO_PRICE('cheapshark'),
    price_digital: Number.isFinite(price) ? price : null,
  }
}

// ---------------------------------------------------------------------------
// eBay (free): used and new asking prices from live listings.
// Used for PlayStation discs when PRICE_CHARTING_TOKEN is not set. These are what
// sellers ask right now, not what games sold for, so they are estimates. Needs a
// free eBay developer keyset: EBAY_CLIENT_ID and EBAY_CLIENT_SECRET.
// ---------------------------------------------------------------------------
const EBAY_VIDEO_GAMES_CATEGORY = '139973'
let ebayToken: { value: string; expires: number } | null = null

async function ebayAccessToken(): Promise<string> {
  const id = Deno.env.get('EBAY_CLIENT_ID')
  const secret = Deno.env.get('EBAY_CLIENT_SECRET')
  if (!id || !secret) throw new Error('EBAY_CLIENT_ID / EBAY_CLIENT_SECRET are not configured')
  if (ebayToken && ebayToken.expires > Date.now() + 60_000) return ebayToken.value

  const res = await fetch('https://api.ebay.com/identity/v1/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: `Basic ${btoa(`${id}:${secret}`)}`,
    },
    body: 'grant_type=client_credentials&scope=' +
      encodeURIComponent('https://api.ebay.com/oauth/api_scope'),
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  })
  if (!res.ok) throw new Error(`eBay token request returned ${res.status}`)
  const d = await res.json()
  ebayToken = {
    value: String(d.access_token),
    expires: Date.now() + Number(d.expires_in ?? 7200) * 1000,
  }
  return ebayToken.value
}

async function ebaySearch(token: string, q: string, condition: 'USED' | 'NEW'): Promise<any[]> {
  const url = new URL('https://api.ebay.com/buy/browse/v1/item_summary/search')
  url.searchParams.set('q', q)
  url.searchParams.set('category_ids', EBAY_VIDEO_GAMES_CATEGORY)
  url.searchParams.set('filter', `buyingOptions:{FIXED_PRICE},conditions:{${condition}},priceCurrency:USD`)
  url.searchParams.set('limit', '50')
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}`, 'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US' },
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  })
  if (!res.ok) throw new Error(`eBay search returned ${res.status}`)
  return (await res.json())?.itemSummaries ?? []
}

const TITLE_STOP_WORDS = new Set(['the', 'of', 'and', 'a', 'an', 'for', 'to', 'in', 'on'])
// Listings that are not a copy of the game (or are not in a normal state).
const NOT_A_COPY =
  /\b(digital code|download code|code only|no disc|case only|manual only|cover only|art only|artwork|disc only|disk only|lot|bundle|steelbook|poster|strategy guide|sticker|empty|replacement|broken|damaged|cracked|for parts)\b/i
const CONSOLE_TITLE: Record<string, RegExp> = {
  ps5: /\b(ps5|playstation 5)\b/,
  ps4: /\b(ps4|playstation 4)\b/,
}

// Words of a title with apostrophes and a trailing plural/possessive "s" ignored, so
// "Marvel's Spider-Man 2" and "Marvels Spider Man 2" count as the same words.
const titleWords = (t: string): Set<string> =>
  new Set(
    t.toLowerCase().replace(/['\u2019]/g, '').replace(/[^a-z0-9]+/g, ' ').trim().split(' ')
      .filter(Boolean)
      .map((w) => (w.length > 3 && w.endsWith('s') ? w.slice(0, -1) : w))
  )

function relevantListingPrices(items: any[], wantedTitle: string, gen: 'ps4' | 'ps5' | null): number[] {
  const words = [...titleWords(wantedTitle)].filter((w) => !TITLE_STOP_WORDS.has(w))
  const out: number[] = []
  for (const item of items) {
    const raw = String(item?.title ?? '')
    const t = normalizeTitle(raw)
    const have = titleWords(raw)
    if (!words.every((w) => have.has(w))) continue
    if (NOT_A_COPY.test(raw)) continue
    if (gen) {
      const other = gen === 'ps5' ? 'ps4' : 'ps5'
      // A listing that names both generations is ambiguous, so it is skipped.
      if (!CONSOLE_TITLE[gen].test(t) || CONSOLE_TITLE[other].test(t)) continue
    }
    const value = Number(item?.price?.value)
    if (item?.price?.currency === 'USD' && Number.isFinite(value) && value >= 3) out.push(value)
  }
  return out
}

// Middle value, ignoring the cheapest and dearest tenth when there are enough listings.
// Fewer than `min` listings is not enough evidence, so the answer is "no price".
function trimmedMedian(values: number[], min = 3): number | null {
  if (values.length < min) return null
  const v = [...values].sort((a, b) => a - b)
  const cut = v.length >= 10 ? Math.floor(v.length * 0.1) : 0
  const kept = v.slice(cut, v.length - cut)
  const mid = Math.floor(kept.length / 2)
  const median = kept.length % 2 ? kept[mid] : (kept[mid - 1] + kept[mid]) / 2
  return Math.round(median * 100) / 100
}

async function fetchEbay(title: string, gen: 'ps4' | 'ps5' | null): Promise<PriceResult> {
  const token = await ebayAccessToken()
  const tag = gen === 'ps5' ? 'PS5' : gen === 'ps4' ? 'PS4' : 'PlayStation'
  const q = `${title} ${tag}`
  const used = trimmedMedian(relevantListingPrices(await ebaySearch(token, q, 'USED'), title, gen))
  const sealed = trimmedMedian(relevantListingPrices(await ebaySearch(token, q, 'NEW'), title, gen))
  // A used listing is normally a disc in its case, so it is reported as "complete".
  // "Loose" (disc only) cannot be told apart reliably, so it stays empty.
  if (used == null && sealed == null) return NO_PRICE('ebay')
  return { ...NO_PRICE('ebay'), price_complete: used, price_new: sealed }
}

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
