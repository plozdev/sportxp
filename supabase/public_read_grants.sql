-- Run as the project owner in Supabase SQL Editor.
-- Fixes the observed anon SELECT permission denial for the public browsing UI.
-- RLS remains in force; this does not create policies or disable RLS.
BEGIN;
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT (id, name, distance_km) ON public.courts TO anon, authenticated;
GRANT SELECT (id, display_name, elo_rating, tier_name, trust_score, win_streak)
  ON public.profiles TO anon, authenticated;
GRANT SELECT (id, host_id, court_id, play_time, max_slots, current_players, status)
  ON public.match_rooms TO anon, authenticated;
GRANT SELECT (id, court_name, team_a_names, team_b_names, score_text,
  winner_team, elo_change, created_at) ON public.match_results TO anon, authenticated;
COMMIT;

-- Authenticated writes additionally require existing server authorization:
-- * INSERT on match_rooms fields court_id, host_id, play_time, max_slots,
--   current_players, status; RLS must enforce host_id = auth.uid().
-- * UPDATE current_players, status plus SELECT for the conditional join.
--   Server policy/trigger must enforce append-only self-join and capacity.
-- * EXECUTE on record_match_and_update_elo(uuid,text,text,text,text,boolean).
--   The RPC must verify p_user_id = auth.uid() and update Elo transactionally.
-- Do not grant clients UPDATE on profiles.elo_rating or trust_score.
-- Use inspect_existing_backend.sql to review existing policies/function body.
