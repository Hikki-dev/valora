-- Add seen_changelog_count to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS seen_changelog_count INTEGER DEFAULT 0;

-- Enable pg_cron for automation
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily collection snapshots (requires the take_daily_snapshot function to exist)
-- We assume it was defined in a previous migration or we'll define a placeholder if needed.
SELECT cron.schedule('daily-snapshot', '0 0 * * *', 'SELECT take_daily_snapshot()');

-- Keep-warm for Edge Functions
SELECT cron.schedule('keep-warm', '*/5 * * * *', 
  $$SELECT net.http_get('https://pgjymcazcsjbkzvqwmhd.supabase.co/functions/v1/ping')$$);
