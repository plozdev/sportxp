-- SportXP onboarding v1. Apply as project owner in Supabase SQL Editor.
-- Progress: profiles.onboarding_step = answered count (0..5); 5 = complete.
-- Answers live in a private table because a step alone cannot recover a score.
BEGIN;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_step integer NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ALTER COLUMN elo_rating DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN elo_rating DROP DEFAULT;
ALTER TABLE public.profiles ALTER COLUMN tier_name DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN tier_name DROP DEFAULT;
GRANT SELECT (onboarding_step) ON public.profiles TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.sportxp_tier_name(p_elo integer)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path = ''
AS $$ SELECT CASE WHEN p_elo IS NULL THEN null
  WHEN p_elo < 450 THEN 'Nhập môn'
  WHEN p_elo < 600 THEN 'Phong trào cơ bản'
  WHEN p_elo < 750 THEN 'Phong trào Trung bình'
  WHEN p_elo < 1000 THEN 'Phong trào Khá'
  ELSE 'Bán chuyên / Thi đấu' END $$;

CREATE TABLE IF NOT EXISTS public.onboarding_responses (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  answers integer[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT onboarding_answers_length CHECK (cardinality(answers) BETWEEN 0 AND 5)
);
ALTER TABLE public.onboarding_responses ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.onboarding_responses FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_onboarding_state()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_profile public.profiles%ROWTYPE;
  v_answers integer[];
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501'; END IF;
  -- Also covers projects without an auth.users signup trigger.
  INSERT INTO public.profiles(id, display_name, elo_rating, tier_name, onboarding_step)
  VALUES (v_user, coalesce(nullif(left(btrim(auth.jwt()->'user_metadata'->>'display_name'), 60), ''), 'Vận động viên'), null, null, 0)
  ON CONFLICT (id) DO NOTHING;
  SELECT * INTO STRICT v_profile FROM public.profiles WHERE id = v_user FOR UPDATE;
  INSERT INTO public.onboarding_responses(user_id) VALUES (v_user) ON CONFLICT DO NOTHING;
  SELECT answers INTO v_answers FROM public.onboarding_responses WHERE user_id = v_user;
  IF v_profile.onboarding_step <> 5 AND v_profile.onboarding_step <> cardinality(v_answers) THEN
    UPDATE public.profiles SET onboarding_step = cardinality(v_answers) WHERE id = v_user
      RETURNING * INTO v_profile;
  END IF;
  RETURN jsonb_build_object('onboarding_step', v_profile.onboarding_step,
    'answers', to_jsonb(v_answers), 'display_name', v_profile.display_name,
    'elo_rating', v_profile.elo_rating, 'tier_name', v_profile.tier_name);
END;
$$;

CREATE OR REPLACE FUNCTION public.save_onboarding_answer(p_question_index integer, p_choice_index integer)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_profile public.profiles%ROWTYPE;
  v_answers integer[];
  v_points integer := 300;
  v_tier text;
  v_weights integer[][] := ARRAY[
    ARRAY[0,50,120,200], ARRAY[0,60,100,150], ARRAY[0,100,150,-1],
    ARRAY[0,50,100,130], ARRAY[0,50,100,150]
  ];
  i integer;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501'; END IF;
  IF p_question_index IS NULL OR p_choice_index IS NULL OR
     p_question_index NOT BETWEEN 0 AND 4 OR p_choice_index NOT BETWEEN 0 AND 3 OR
     (p_question_index = 2 AND p_choice_index = 3) THEN
    RAISE EXCEPTION 'Invalid answer' USING ERRCODE = '22023';
  END IF;
  -- Locks in the same order as get_onboarding_state; serializes device updates.
  SELECT * INTO STRICT v_profile FROM public.profiles WHERE id = v_user FOR UPDATE;
  SELECT answers INTO v_answers FROM public.onboarding_responses WHERE user_id = v_user FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Load onboarding before answering' USING ERRCODE = '22023'; END IF;
  IF v_profile.onboarding_step = 5 THEN
    -- A replay after a lost response is safe; completed Elo cannot be reset.
    IF v_answers[p_question_index + 1] IS DISTINCT FROM p_choice_index THEN
      RAISE EXCEPTION 'Onboarding already completed' USING ERRCODE = '22023';
    END IF;
    RETURN public.get_onboarding_state();
  END IF;
  IF p_question_index > cardinality(v_answers) THEN
    RAISE EXCEPTION 'Answer questions in order' USING ERRCODE = '22023';
  END IF;
  -- Revising an earlier answer invalidates subsequent answers.
  v_answers := coalesce(v_answers[1:p_question_index], '{}'::integer[]) || ARRAY[p_choice_index];
  UPDATE public.onboarding_responses SET answers = v_answers, updated_at = now() WHERE user_id = v_user;
  IF cardinality(v_answers) = 5 THEN
    FOR i IN 1..5 LOOP
      v_points := v_points + v_weights[i][v_answers[i] + 1];
    END LOOP;
    v_points := least(850, greatest(300, v_points));
    v_tier := public.sportxp_tier_name(v_points);
    UPDATE public.profiles SET onboarding_step = 5, elo_rating = v_points, tier_name = v_tier WHERE id = v_user;
  ELSE
    UPDATE public.profiles SET onboarding_step = cardinality(v_answers) WHERE id = v_user;
  END IF;
  RETURN public.get_onboarding_state();
END;
$$;

REVOKE ALL ON FUNCTION public.get_onboarding_state() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.save_onboarding_answer(integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_onboarding_state() TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_onboarding_answer(integer,integer) TO authenticated;

-- Guard initial rating and progress even if existing profile RLS permits edits.
-- SECURITY DEFINER functions run as their owner; regular API writes do not.
CREATE OR REPLACE FUNCTION public.guard_onboarding_profile()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon', 'authenticator') THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.onboarding_step <> 0 OR NEW.elo_rating IS NOT NULL OR NEW.tier_name IS NOT NULL THEN
        RAISE EXCEPTION 'Use onboarding to initialize rank' USING ERRCODE = '42501';
      END IF;
    ELSIF NEW.onboarding_step IS DISTINCT FROM OLD.onboarding_step OR
          NEW.elo_rating IS DISTINCT FROM OLD.elo_rating OR
          NEW.tier_name IS DISTINCT FROM OLD.tier_name THEN
      RAISE EXCEPTION 'Rank and onboarding progress are server managed' USING ERRCODE = '42501';
    END IF;
  END IF;
  -- Keeps the new tiers consistent when the existing match RPC changes Elo.
  IF TG_OP = 'INSERT' THEN
    NEW.tier_name := public.sportxp_tier_name(NEW.elo_rating);
  ELSIF NEW.elo_rating IS DISTINCT FROM OLD.elo_rating THEN
    NEW.tier_name := public.sportxp_tier_name(NEW.elo_rating);
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS guard_onboarding_profile ON public.profiles;
CREATE TRIGGER guard_onboarding_profile BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.guard_onboarding_profile();
NOTIFY pgrst, 'reload schema';
COMMIT;
