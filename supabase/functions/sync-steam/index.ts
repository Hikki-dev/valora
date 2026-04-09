import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { steamId } = await req.json();
    const apiKey = Deno.env.get("STEAM_API_KEY");

    if (!apiKey) {
      return new Response(JSON.stringify({ error: "STEAM_API_KEY not found in server secrets." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      });
    }

    if (!steamId) {
       return new Response(JSON.stringify({ error: "steamId is required." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // Call Steam API
    const url = `https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=${apiKey}&steamid=${steamId}&format=json&include_appinfo=1`;

    const response = await fetch(url);
    if (!response.ok) {
       throw new Error(`Steam API error: ${response.statusText}`);
    }

    const data = await response.json();
    const games = data.response?.games || [];

    // Map to a clean structure for the app
    const mappedGames = games.map((g: any) => {
      const appId = g.appid.toString();
      return {
        externalId: appId,
        title: g.name || "Unknown Game",
        coverUrl: `https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/${appId}/library_600x900.jpg`,
        playtimeForever: g.playtime_forever || 0,
        platform: "Steam",
      };
    });

    return new Response(JSON.stringify({ games: mappedGames }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
