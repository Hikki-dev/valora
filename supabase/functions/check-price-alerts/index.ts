import { createClient } from '@supabase/supabase-js';

// Invoked by pg_cron / a scheduler. It uses the service-role key (bypasses RLS),
// so it MUST NOT be callable by the public: require a shared secret.
//   supabase secrets set CRON_SECRET=<long random string>
// and send it as the `x-cron-secret` header from the scheduler.
Deno.serve(async (req) => {
  const expected = Deno.env.get('CRON_SECRET');
  const given = req.headers.get('x-cron-secret');
  if (!expected || !given || given !== expected) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // PostgREST cannot compare two columns (`current_price <= target_price`), so the
  // previous `.lte('current_price', 'target_price')` compared against the literal
  // string 'target_price'. Filter the candidates here instead.
  //
  // This is read-only on purpose: the app's Wishlist badge counts rows with
  // alerted = false, so flagging them here (with no push/email channel) would
  // silently clear the badge before the user ever saw the deal.
  const { data, error } = await supabase
    .from('wishlists')
    .select('id, current_price, target_price')
    .not('target_price', 'is', null)
    .not('current_price', 'is', null)
    .eq('alerted', false);

  if (error) {
    console.error('[check-price-alerts]', error.message);
    return new Response(JSON.stringify({ error: 'Query failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const hits = (data ?? []).filter(
    (h) => Number(h.current_price) <= Number(h.target_price)
  );

  return new Response(JSON.stringify({ alerts: hits.length }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
