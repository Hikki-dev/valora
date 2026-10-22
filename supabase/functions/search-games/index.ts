import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { checkRateLimit } from '../_shared/rateLimit.ts'
import { z } from 'zod'

const Schema = z.object({
  query: z.string().min(1).max(100),
  limit: z.number().min(1).max(20).optional().default(15),
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { user, supabase } = await verifyUser(req) // Auth required even for search
    await checkRateLimit(supabase, user.id, 300, 'search-games')
    const body = Schema.parse(await req.json())

    const res = await fetch(
      `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(body.query)}&limit=${body.limit}`,
      { signal: AbortSignal.timeout(8000) }
    )
    if (!res.ok) throw new Error(`Upstream search failed: ${res.status}`)
    const data = await res.json()

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (err: any) {
    const msg = String(err?.message ?? '')
    const status = msg.includes('Unauthorized') ? 401 : msg.includes('Rate limit') ? 429 : 400
    return new Response(JSON.stringify({ error: status === 400 ? 'Invalid request' : msg }), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
