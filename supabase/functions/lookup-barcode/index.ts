import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts'

const Schema = z.object({
  upc: z.string().regex(/^\d{8,14}$/, 'Invalid UPC format'),
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    await verifyUser(req)
    const { upc } = Schema.parse(await req.json())

    const res = await fetch(`https://api.upcitemdb.com/prod/trial/lookup?upc=${upc}`)
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
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
