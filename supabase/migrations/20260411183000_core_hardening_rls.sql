-- VALORA CORE SECURITY HARDENING: ROW LEVEL SECURITY (RLS)
-- Enables strict data isolation by enforcing user-level ownership on all core records.

-- 1. Enable RLS on all user-owned tables
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.value_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY; -- Case just in case it wasn't already

-- 2. GAMES: Users can only see and manage their own library
DROP POLICY IF EXISTS "Users can only manage their own games" ON public.games;
CREATE POLICY "Users can only manage their own games" ON public.games
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. PROFILES: Users can only see and manage their own profile data
DROP POLICY IF EXISTS "Users can only manage their own profile" ON public.profiles;
CREATE POLICY "Users can only manage their own profile" ON public.profiles
    FOR ALL TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. VALUE SNAPSHOTS: Privacy for financial growth data
DROP POLICY IF EXISTS "Users can only see their own snapshots" ON public.value_snapshots;
CREATE POLICY "Users can only see their own snapshots" ON public.value_snapshots
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. WISHLISTS: Secure future acquisition data
DROP POLICY IF EXISTS "Users can only see their own wishlist items" ON public.wishlists;
CREATE POLICY "Users can only see their own wishlist items" ON public.wishlists
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- SECURITY AUDIT: Verify RLS is active
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
