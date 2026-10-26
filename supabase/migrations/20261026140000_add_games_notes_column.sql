-- Valora: the games table was missing the notes column.
-- ALREADY APPLIED to the live project (pgjymcazcsjbkzvqwmhd) on 2026-10-26 as the migration
-- add_games_notes_column. Kept here so a fresh project (or a fork) ends up in the same state.
--
-- Why: Game.toJson() sends a notes value with every game it saves, but the table had no such
-- column, so every insert failed with PGRST204 (HTTP 400) and the app said "Couldn't save".
-- Idempotent.

ALTER TABLE public.games ADD COLUMN IF NOT EXISTS notes TEXT;
