-- VALORA PRODUCTION HARDENING: DATABASE AUTOMATION & SECURITY
-- Run this in the Supabase SQL Editor

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Security: Ensure Wishlists are strictly isolated (RLS)
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can only see their own wishlist items" ON wishlists;
CREATE POLICY "Users can only see their own wishlist items" ON wishlists
  FOR ALL TO authenticated
  USING (auth.uid() = user_id);

-- 3. Automation: Daily Valuation Snapshots
CREATE OR REPLACE FUNCTION take_valuation_snapshots()
RETURNS void AS $$
BEGIN
  INSERT INTO public.value_snapshots (user_id, total_value, snapped_at)
  SELECT 
    user_id,
    SUM(COALESCE(market_value, 0)) as total_value,
    NOW() as snapped_at
  FROM public.games_with_valuations
  GROUP BY user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Schedule the SNAPSHOT (Runs every day at Midnight UTC)
SELECT cron.schedule('0 0 * * *', 'SELECT take_valuation_snapshots()');

-- 5. Realtime: Enable for core tables if not already
ALTER PUBLICATION supabase_realtime ADD TABLE games;
ALTER PUBLICATION supabase_realtime ADD TABLE valuations;

-- 6. Cleanup: Remove sample data (Optional)
-- DELETE FROM games WHERE title ILIKE '%sample%';
