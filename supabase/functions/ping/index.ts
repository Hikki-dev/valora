import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Keep-warm function called by pg_cron
Deno.serve(() => new Response('ok', { status: 200 }))
