import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  return new Response(
    JSON.stringify({ status: 'up', timestamp: new Date().toISOString() }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
})
