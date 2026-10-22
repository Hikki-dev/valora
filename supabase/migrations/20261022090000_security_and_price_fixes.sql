-- Valora: security + price-correctness fixes (2026-10-22)
-- Safe to re-run. Review, then apply with `supabase db push` or the SQL editor.

-- ============================================================================
-- 1. games_with_valuations must respect RLS.
--    A plain view runs with its OWNER's privileges and bypasses row-level
--    security, so any signed-in user could `select * from games_with_valuations`
--    and read every other user's library. security_invoker makes the view run
--    as the caller, so the policies on games/valuations apply. (Postgres 15+.)
--
--    Also fixes the value calculation: the app stores condition as
--    'Loose' | 'CIB' | 'Boxed' | 'New', but the old CASE only matched
--    'loose' | 'complete' | 'new', so CIB/Boxed/New games all fell through to
--    the ELSE branch and were valued at the wrong price.
-- ============================================================================
DROP VIEW IF EXISTS public.games_with_valuations CASCADE;
CREATE VIEW public.games_with_valuations
WITH (security_invoker = true) AS
SELECT
  g.*,
  v.price_loose,
  v.price_complete,
  v.price_new,
  v.price_digital,
  v.currency,
  v.source,
  v.fetched_at,
  CASE lower(g.condition)
    WHEN 'loose'    THEN v.price_loose
    WHEN 'cib'      THEN v.price_complete
    WHEN 'complete' THEN v.price_complete
    WHEN 'boxed'    THEN v.price_complete
    WHEN 'new'      THEN v.price_new
    ELSE COALESCE(v.price_digital, v.price_complete, v.price_loose)
  END AS current_value
FROM public.games g
LEFT JOIN public.valuations v ON v.game_id = g.id;

REVOKE ALL ON public.games_with_valuations FROM anon;
GRANT SELECT ON public.games_with_valuations TO authenticated;

-- ============================================================================
-- 2. Rate limiting: the old RPC was SECURITY DEFINER and trusted a
--    client-supplied p_user_id, so any signed-in user could call it for someone
--    else's id and lock them out. It now uses auth.uid() and has per-function
--    buckets.
-- ============================================================================
ALTER TABLE public.rate_limits ADD COLUMN IF NOT EXISTS bucket TEXT NOT NULL DEFAULT 'default';
ALTER TABLE public.rate_limits DROP CONSTRAINT IF EXISTS rate_limits_user_id_window_start_key;
CREATE UNIQUE INDEX IF NOT EXISTS rate_limits_user_bucket_window_key
  ON public.rate_limits (user_id, bucket, window_start);

DROP FUNCTION IF EXISTS public.increment_rate_limit(UUID, TIMESTAMPTZ, INTEGER);
CREATE OR REPLACE FUNCTION public.increment_rate_limit(
  p_window_start TIMESTAMPTZ,
  p_limit        INTEGER DEFAULT 60,
  p_bucket       TEXT    DEFAULT 'default'
)
RETURNS TABLE(is_limited BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user  UUID := auth.uid();
  v_count INTEGER;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  INSERT INTO public.rate_limits (user_id, bucket, window_start, call_count)
  VALUES (v_user, p_bucket, p_window_start, 1)
  ON CONFLICT (user_id, bucket, window_start)
    DO UPDATE SET call_count = rate_limits.call_count + 1
  RETURNING call_count INTO v_count;

  RETURN QUERY SELECT (v_count > p_limit);
END;
$$;

REVOKE ALL ON FUNCTION public.increment_rate_limit(TIMESTAMPTZ, INTEGER, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.increment_rate_limit(TIMESTAMPTZ, INTEGER, TEXT) TO authenticated;

-- Old windows are useless; keep the free-tier table tiny.
DELETE FROM public.rate_limits WHERE window_start < now() - interval '1 day';

-- ============================================================================
-- 3. SECURITY DEFINER hygiene: pin search_path and stop end users from calling
--    the snapshot job directly (pg_cron runs as postgres and is unaffected).
-- ============================================================================
DO $$
BEGIN
  ALTER FUNCTION public.handle_new_user() SET search_path = public;
EXCEPTION WHEN undefined_function THEN NULL;
END $$;

DO $$
BEGIN
  ALTER FUNCTION public.take_daily_snapshot() SET search_path = public;
  REVOKE ALL ON FUNCTION public.take_daily_snapshot() FROM PUBLIC, anon, authenticated;
EXCEPTION WHEN undefined_function THEN NULL;
END $$;

-- ============================================================================
-- 4. Fake prices: until now the fetch-price function filled in generated
--    "mock" prices whenever PriceCharting returned none. Mark every cached
--    PriceCharting/CheapShark valuation as old so the app re-fetches real data
--    (or shows "—") on next view instead of trusting made-up numbers.
-- ============================================================================
UPDATE public.valuations
   SET fetched_at = now() - interval '30 days'
 WHERE source IN ('pricecharting', 'cheapshark');

-- Faster library/history reads on the free tier.
CREATE INDEX IF NOT EXISTS idx_price_history_game_fetched
  ON public.price_history (game_id, fetched_at);
