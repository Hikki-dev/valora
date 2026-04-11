import { corsHeaders } from '../_shared/cors.ts'
import { verifyUser } from '../_shared/auth.ts'
import { z } from 'https://deno.land/x/zod@v3.22.4/mod.ts'

const Schema = z.object({
  steamId: z.string().regex(/^\d{17}$/, 'Invalid Steam ID format'),
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { user } = await verifyUser(req) // AUTH REQUIRED
    const { steamId } = Schema.parse(await req.json())

    const apiKey = Deno.env.get('STEAM_API_KEY')
    if (!apiKey) throw new Error('STEAM_API_KEY not configured')

    const url = `https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=${apiKey}&steamid=${steamId}&format=json&include_appinfo=1`
    const response = await fetch(url)
    if (!response.ok) throw new Error(`Steam API error: ${response.statusText}`)

    const data = await response.json()
    const games = (data.response?.games ?? []).map((g: any) => ({
      externalId: g.appid.toString(),
      title: g.name ?? 'Unknown Game',
      coverUrl: `https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/${g.appid}/library_600x900.jpg`,
      playtimeForever: g.playtime_forever ?? 0,
      platform: 'steam',
    }))

    return new Response(JSON.stringify({ games }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (err: any) {
    const status = err.message.includes('Unauthorized') ? 401 :
                   err.message.includes('Invalid Steam') ? 400 : 500
    return new Response(JSON.stringify({ error: err.message }), {
      status, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
