-- SportXP skill taxonomy v2. Apply AFTER 20261018_onboarding.sql.
-- Labels and boundaries are internal calibration policy, not national standards.
-- This migration does not change any Elo value or onboarding answer.
BEGIN;
CREATE OR REPLACE FUNCTION public.sportxp_tier_name(p_elo integer)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path = ''
AS $$ SELECT CASE
  WHEN p_elo IS NULL THEN null
  WHEN p_elo < 400 THEN 'Nhập môn'
  WHEN p_elo < 450 THEN 'Yếu-'
  WHEN p_elo < 500 THEN 'Yếu'
  WHEN p_elo < 550 THEN 'Yếu+'
  WHEN p_elo < 600 THEN 'TBY-'
  WHEN p_elo < 650 THEN 'TBY'
  WHEN p_elo < 700 THEN 'TBY+'
  WHEN p_elo < 750 THEN 'TB-'
  WHEN p_elo < 800 THEN 'TB'
  WHEN p_elo < 900 THEN 'TB+'
  WHEN p_elo < 950 THEN 'TBK-'
  WHEN p_elo < 1000 THEN 'TBK'
  WHEN p_elo < 1100 THEN 'TBK+'
  WHEN p_elo < 1200 THEN 'Khá-'
  WHEN p_elo < 1300 THEN 'Khá'
  WHEN p_elo < 1400 THEN 'Khá+'
  WHEN p_elo < 1500 THEN 'Tốt-'
  WHEN p_elo < 1600 THEN 'Tốt'
  WHEN p_elo < 1700 THEN 'Tốt+'
  ELSE 'Cao thủ phong trào'
END $$;

UPDATE public.profiles
SET tier_name = public.sportxp_tier_name(elo_rating)
WHERE tier_name IS DISTINCT FROM public.sportxp_tier_name(elo_rating);

NOTIFY pgrst, 'reload schema';
COMMIT;
