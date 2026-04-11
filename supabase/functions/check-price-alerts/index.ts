import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // Find all wishlist items where current_price dropped below target_price
  const { data: hits } = await supabase
    .from('wishlists')
    .select('*, profiles(id)')
    .not('target_price', 'is', null)
    .not('current_price', 'is', null)
    .lte('current_price', 'target_price')
    .eq('alerted', false); // Don't re-alert

  if (hits) {
    for (const h of hits) {
        await supabase.from('wishlists').update({ alerted: true }).eq('id', h.id);
    }
  }

  return new Response(JSON.stringify({ alerts: hits?.length ?? 0 }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
