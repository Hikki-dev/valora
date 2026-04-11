-- Add individual game price history tracking
-- Created strictly for zero-cost personal tracking

CREATE TABLE IF NOT EXISTS public.price_history (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    game_id uuid REFERENCES public.games(id) ON DELETE CASCADE,
    price_loose numeric,
    price_complete numeric,
    price_new numeric,
    price_digital numeric,
    source text,
    fetched_at timestamp with time zone DEFAULT now()
);

-- Index for fast lookup in individual game charts
CREATE INDEX IF NOT EXISTS idx_price_history_game_date ON public.price_history(game_id, fetched_at DESC);

-- Enable RLS
ALTER TABLE public.price_history ENABLE ROW LEVEL SECURITY;

-- Allow users to see only their own game price history (via games table ownership)
DROP POLICY IF EXISTS "Users can view private price history of their games" ON public.price_history;
CREATE POLICY "Users can view private price history of their games"
ON public.price_history FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.games
        WHERE games.id = price_history.game_id
        AND games.user_id = auth.uid()
    )
);

-- The Edge Function will handle insertions (service_role or authenticated with proper logic)
DROP POLICY IF EXISTS "Users can insert price history for their games" ON public.price_history;
CREATE POLICY "Users can insert price history for their games"
ON public.price_history FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.games
        WHERE games.id = price_history.game_id
        AND games.user_id = auth.uid()
    )
);
