-- Optional clean-ups that could NOT be applied through the MCP connection: every DROP (and
-- CREATE INDEX / cron.schedule) timed out there. Run this once in the Supabase dashboard
-- SQL editor. None of it changes behaviour; it removes dead objects and speeds up reads.

-- Legacy duplicate RLS policies (currently neutralised with USING (false)).
DROP POLICY IF EXISTS "Users can manage their own games"            ON public.games;
DROP POLICY IF EXISTS "Users can only see their own games"          ON public.games;
DROP POLICY IF EXISTS "Users own games"                             ON public.games;
DROP POLICY IF EXISTS "Users can manage their own collections"      ON public.collections;
DROP POLICY IF EXISTS "Users can only see their own wishlist items" ON public.wishlists;
DROP POLICY IF EXISTS "Users own snapshots"                         ON public.value_snapshots;
DROP POLICY IF EXISTS "Users own their snapshots"                   ON public.value_snapshots;

-- Dead functions: the cron jobs that called take_valuation_snapshots() already failed nightly
-- (it referenced a column that does not exist) and were removed; the old rate-limit signature is
-- a compatibility shim nothing calls any more.
DROP FUNCTION IF EXISTS public.take_valuation_snapshots();
DROP FUNCTION IF EXISTS public.increment_rate_limit(uuid, timestamptz, integer);

-- Indexes: drop duplicates / never-used, add the one the library query needs.
DROP INDEX IF EXISTS public.idx_valuations_game;      -- duplicate of valuations_game_id_key
DROP INDEX IF EXISTS public.idx_valuations_fetched;
DROP INDEX IF EXISTS public.idx_snapshots_user_date;  -- duplicate of the (user_id, snapped_at) unique
DROP INDEX IF EXISTS public.idx_games_platform;
DROP INDEX IF EXISTS public.idx_games_user;
CREATE INDEX IF NOT EXISTS idx_games_user_added     ON public.games     (user_id, added_at DESC);
DROP INDEX IF EXISTS public.idx_wishlist_user;
CREATE INDEX IF NOT EXISTS idx_wishlists_user_added ON public.wishlists (user_id, added_at DESC);

-- Keep the free-tier database small.
SELECT cron.schedule('housekeeping', '15 3 * * *',
  'delete from public.rate_limits where window_start < now() - interval ''1 day''; delete from public.price_history where fetched_at < now() - interval ''2 years'';');
