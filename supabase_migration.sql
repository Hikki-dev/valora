-- Run this in your Supabase SQL Editor

-- ============================================================
-- PROFILES (Core table)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id                  UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username            TEXT,
  avatar_url          TEXT,
  last_seen_version   TEXT,
  onboarded_at        TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ  DEFAULT now(),
  created_at          TIMESTAMPTZ  DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================
-- ENUMS
-- ============================================================
DO $$ BEGIN
  CREATE TYPE platform_type AS ENUM ('ps_disc', 'psn', 'steam', 'epic', 'nintendo');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- COLLECTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.collections (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  platform    platform_type NOT NULL,
  name        TEXT         NOT NULL,
  created_at  TIMESTAMPTZ  DEFAULT now(),
  UNIQUE(user_id, platform)
);
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own collections" ON public.collections;
CREATE POLICY "Users own collections"
  ON public.collections FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_collections_user ON public.collections(user_id);

-- ============================================================
-- GAMES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.games (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID          NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  user_id       UUID          NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT          NOT NULL,
  cover_url     TEXT,
  platform      platform_type NOT NULL,
  external_id   TEXT,
  genre         TEXT,
  developer     TEXT,
  release_year  INTEGER,
  condition     TEXT          DEFAULT 'complete',
  price_paid    NUMERIC(10,2),
  added_at      TIMESTAMPTZ   DEFAULT now()
);
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own games" ON public.games;
CREATE POLICY "Users own games"
  ON public.games FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_games_user       ON public.games(user_id);
CREATE INDEX IF NOT EXISTS idx_games_collection ON public.games(collection_id);
CREATE INDEX IF NOT EXISTS idx_games_platform   ON public.games(platform);

-- ============================================================
-- VALUATIONS (one-to-one with games)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.valuations (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id        UUID         NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  user_id        UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  price_loose    NUMERIC(10,2),
  price_complete NUMERIC(10,2),
  price_new      NUMERIC(10,2),
  price_digital  NUMERIC(10,2),
  currency       TEXT         DEFAULT 'USD',
  source         TEXT,
  fetched_at     TIMESTAMPTZ  DEFAULT now(),
  UNIQUE(game_id)
);
ALTER TABLE public.valuations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own valuations" ON public.valuations;
CREATE POLICY "Users own valuations"
  ON public.valuations FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_valuations_game    ON public.valuations(game_id);
CREATE INDEX IF NOT EXISTS idx_valuations_user    ON public.valuations(user_id);
CREATE INDEX IF NOT EXISTS idx_valuations_fetched ON public.valuations(fetched_at);

-- ============================================================
-- VALUE SNAPSHOTS (for history chart)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.value_snapshots (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  total_value NUMERIC(10,2) NOT NULL,
  breakdown   JSONB,
  snapped_at  DATE         DEFAULT CURRENT_DATE,
  UNIQUE(user_id, snapped_at)
);
ALTER TABLE public.value_snapshots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own snapshots" ON public.value_snapshots;
CREATE POLICY "Users own snapshots"
  ON public.value_snapshots FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_snapshots_user_date ON public.value_snapshots(user_id, snapped_at);

-- ============================================================
-- WISHLISTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.wishlists (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID          NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT          NOT NULL,
  platform      platform_type NOT NULL,
  external_id   TEXT,
  cover_url     TEXT,
  target_price  NUMERIC(10,2),
  current_price NUMERIC(10,2),
  added_at      TIMESTAMPTZ   DEFAULT now()
);
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own wishlist" ON public.wishlists;
CREATE POLICY "Users own wishlist"
  ON public.wishlists FOR ALL USING (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON public.wishlists(user_id);

-- ============================================================
-- RATE LIMITS (Edge Function access only)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.rate_limits (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  window_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  call_count   INTEGER     DEFAULT 1,
  UNIQUE(user_id, window_start)
);
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role only" ON public.rate_limits;
CREATE POLICY "Service role only"
  ON public.rate_limits FOR ALL USING (false);

-- ============================================================
-- AUTO-PROFILE TRIGGER (create profile row on signup)
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, last_seen_version, onboarded_at, updated_at)
  VALUES (NEW.id, NULL, NULL, NOW())
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- BATCH VIEW — eliminates N+1 on dashboard load
-- ============================================================
DROP VIEW IF EXISTS public.games_with_valuations CASCADE;
CREATE OR REPLACE VIEW public.games_with_valuations AS
SELECT
  g.*,
  v.price_loose,
  v.price_complete,
  v.price_new,
  v.price_digital,
  v.currency,
  v.source,
  v.fetched_at,
  CASE g.condition
    WHEN 'loose'    THEN v.price_loose
    WHEN 'complete' THEN v.price_complete
    WHEN 'new'      THEN v.price_new
    ELSE COALESCE(v.price_digital, v.price_complete, v.price_loose)
  END AS current_value
FROM public.games g
LEFT JOIN public.valuations v ON v.game_id = g.id;

-- ============================================================
-- DAILY SNAPSHOT FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION take_daily_snapshot()
RETURNS void AS $$
BEGIN
  INSERT INTO public.value_snapshots (user_id, total_value, breakdown, snapped_at)
  SELECT
    gv.user_id,
    SUM(gv.current_value)                                    AS total_value,
    jsonb_object_agg(gv.platform, pt.platform_total)         AS breakdown,
    CURRENT_DATE
  FROM (
    SELECT user_id, platform, SUM(current_value) AS platform_total
    FROM public.games_with_valuations
    WHERE current_value IS NOT NULL
    GROUP BY user_id, platform
  ) pt
  JOIN public.games_with_valuations gv USING (user_id)
  GROUP BY gv.user_id
  ON CONFLICT (user_id, snapped_at)
    DO UPDATE SET total_value = EXCLUDED.total_value,
                  breakdown   = EXCLUDED.breakdown;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RATE LIMIT RPC (atomic increment)
-- ============================================================
CREATE OR REPLACE FUNCTION increment_rate_limit(
  p_user_id     UUID,
  p_window_start TIMESTAMPTZ,
  p_limit        INTEGER DEFAULT 60
)
RETURNS TABLE(is_limited BOOLEAN) AS $$
BEGIN
  INSERT INTO public.rate_limits (user_id, window_start, call_count)
  VALUES (p_user_id, p_window_start, 1)
  ON CONFLICT (user_id, window_start)
    DO UPDATE SET call_count = rate_limits.call_count + 1;

  RETURN QUERY
    SELECT (call_count > p_limit) AS is_limited
    FROM public.rate_limits
    WHERE user_id = p_user_id AND window_start = p_window_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
