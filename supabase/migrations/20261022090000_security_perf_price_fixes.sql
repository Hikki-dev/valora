-- Valora: security, performance and price-correctness fixes.
-- ALREADY APPLIED to the live project (pgjymcazcsjbkzvqwmhd) on 2026-10-22 as the migrations
-- add_nintendo_platform, secure_games_view_and_fix_valuation, wishlist_fixes,
-- rate_limit_per_user_buckets, rls_optimise_and_tighten, fix_snapshot_function_and_lock_down_definers.
-- Kept here so a fresh project (or a fork) ends up in the same state. Idempotent where possible.

-- 1. The app stores 'nintendo'; the enum only had nintendo_physical / nintendo_digital.
ALTER TYPE public.platform_type ADD VALUE IF NOT EXISTS 'nintendo';

-- 2. games_with_valuations: run as the caller (security_invoker) so RLS applies. Before this
--    the view ran as its owner, so any signed-in user could read every user's library.
--    Also fixes valuation: the app stores condition as Loose|CIB|Boxed|New.
CREATE OR REPLACE VIEW public.games_with_valuations AS
SELECT
  g.id, g.collection_id, g.user_id, g.title, g.cover_url, g.platform, g.external_id,
  g.genre, g.added_at, g.format, g.region, g.condition, g.estimated_value,
  g.purchase_price, g.price_cache, g.price_fetched_at, g.publisher, g.release_year,
  v.price_loose, v.price_complete, v.price_new, v.price_digital, v.currency, v.source, v.fetched_at,
  COALESCE(
    v.price_digital,
    CASE lower(coalesce(g.condition, ''))
      WHEN 'loose'    THEN v.price_loose
      WHEN 'cib'      THEN v.price_complete
      WHEN 'complete' THEN v.price_complete
      WHEN 'boxed'    THEN v.price_complete
      WHEN 'new'      THEN v.price_new
      ELSE COALESCE(v.price_complete, v.price_loose)
    END
  ) AS current_value
FROM public.games g
LEFT JOIN public.valuations v ON v.game_id = g.id;
ALTER VIEW public.games_with_valuations SET (security_invoker = true);
REVOKE ALL ON public.games_with_valuations FROM anon, PUBLIC;
GRANT SELECT ON public.games_with_valuations TO authenticated;

-- 3. RLS: one policy per table for signed-in users, auth.uid() cached via (select ...).
--    (On the live project the old duplicate policies were neutralised with USING (false);
--     a fresh project simply never gets them.)
CREATE POLICY "own games" ON public.games FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);
-- valuations: you may only write one for a game you own.
ALTER POLICY "Users own valuations" ON public.valuations TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id
              AND EXISTS (SELECT 1 FROM public.games g WHERE g.id = game_id AND g.user_id = (select auth.uid())));
-- value_snapshots: users can read their history, not forge it (the nightly job writes it).
CREATE POLICY "read own snapshots" ON public.value_snapshots FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- 4. Wishlist: no id default (inserts failed) and no 'alerted' column (the badge query failed).
ALTER TABLE public.wishlists ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.wishlists ADD COLUMN IF NOT EXISTS alerted boolean NOT NULL DEFAULT false;

-- 5. Rate limiting: derive the user from the JWT (the old RPC trusted a client-supplied user id,
--    so anyone could burn another user's quota); one bucket per edge function.
ALTER TABLE public.rate_limits ADD COLUMN IF NOT EXISTS bucket text NOT NULL DEFAULT 'default';
CREATE UNIQUE INDEX IF NOT EXISTS rate_limits_user_bucket_window_key
  ON public.rate_limits (user_id, bucket, window_start);
ALTER TABLE public.rate_limits DROP CONSTRAINT IF EXISTS rate_limits_user_id_window_start_key;

CREATE OR REPLACE FUNCTION public.increment_rate_limit(
  p_window_start timestamptz, p_limit integer DEFAULT 60, p_bucket text DEFAULT 'default')
RETURNS TABLE(is_limited boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_user uuid := auth.uid(); v_count integer;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  INSERT INTO public.rate_limits (user_id, bucket, window_start, call_count)
  VALUES (v_user, p_bucket, p_window_start, 1)
  ON CONFLICT (user_id, bucket, window_start)
    DO UPDATE SET call_count = rate_limits.call_count + 1
  RETURNING call_count INTO v_count;
  RETURN QUERY SELECT (v_count > p_limit);
END $$;
REVOKE ALL ON FUNCTION public.increment_rate_limit(timestamptz, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.increment_rate_limit(timestamptz, integer, text) TO authenticated;

-- 6. Nightly snapshot: the old query joined every platform total to every game row, so
--    multi-platform users were over-counted and every platform showed the same number.
CREATE OR REPLACE FUNCTION public.take_daily_snapshot()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  WITH per_platform AS (
    SELECT user_id, platform::text AS platform,
           SUM(COALESCE(current_value, estimated_value)) AS total
    FROM public.games_with_valuations
    GROUP BY user_id, platform
    HAVING SUM(COALESCE(current_value, estimated_value)) IS NOT NULL
  )
  INSERT INTO public.value_snapshots (user_id, total_value, breakdown, snapped_at)
  SELECT user_id, SUM(total), jsonb_object_agg(platform, total), CURRENT_DATE
  FROM per_platform GROUP BY user_id
  ON CONFLICT (user_id, snapped_at)
    DO UPDATE SET total_value = EXCLUDED.total_value, breakdown = EXCLUDED.breakdown
$$;

-- 7. SECURITY DEFINER functions must not be callable through the public API.
ALTER FUNCTION public.handle_new_user() SET search_path = public;
REVOKE ALL ON FUNCTION public.handle_new_user()     FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.take_daily_snapshot() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rls_auto_enable()     FROM PUBLIC, anon, authenticated;

-- 8. Fabricated prices: PriceCharting rows that are exactly 1.15x / 1.5x the loose price are the
--    old generator's mock formula, not market data. Blank them so they read as unknown.
UPDATE public.valuations
   SET price_loose = NULL, price_complete = NULL, price_new = NULL,
       source = 'unavailable', fetched_at = now() - interval '30 days'
 WHERE source = 'pricecharting'
   AND price_loose > 0
   AND abs(price_complete - price_loose * 1.15) < 0.02
   AND abs(price_new      - price_loose * 1.5)  < 0.02;
