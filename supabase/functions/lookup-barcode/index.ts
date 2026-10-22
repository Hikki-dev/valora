import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { checkRateLimit } from '../_shared/rateLimit.ts'
import { z } from 'zod'

const Schema = z.object({
  upc: z.string().regex(/^\d{8,14}$/, 'Invalid UPC format'),
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { user, supabase } = await verifyUser(req)
    // UPCitemdb's free trial tier is capped at ~100 lookups/day across ALL users.
    await checkRateLimit(supabase, user.id, 20, 'lookup-barcode')
    const { upc } = Schema.parse(await req.json())

    const res = await fetch(`https://api.upcitemdb.com/prod/trial/lookup?upc=${upc}`,
      { signal: AbortSignal.timeout(8000) })
    if (!res.ok) throw new Error(`Upstream lookup failed: ${res.status}`)
    const data = await res.json()
    const item = data.items?.[0]

    if (!item) return new Response(JSON.stringify({ found: false }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

    return new Response(JSON.stringify({
      found: true,
      title: item.title ?? 'Unknown',
      thumb: item.images?.[0] ?? '',
      upc,
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err: any) {
    const msg = String(err?.message ?? '')
    const status = msg.includes('Unauthorized') ? 401 : msg.includes('Rate limit') ? 429 : 400
    return new Response(JSON.stringify({ error: status === 400 ? 'Invalid request' : msg }), {
      status, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
