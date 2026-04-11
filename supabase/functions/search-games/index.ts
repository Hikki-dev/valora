import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { z } from 'zod'

const Schema = z.object({
  query: z.string().min(1).max(100),
  limit: z.number().min(1).max(20).optional().default(15),
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    await verifyUser(req) // Auth required even for search
    const body = Schema.parse(await req.json())

    const res = await fetch(
      `https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(body.query)}&limit=${body.limit}`
    )
    const data = await res.json()

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: err.message.includes('Unauthorized') ? 401 : 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
