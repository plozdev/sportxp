-- ==============================================================================
-- SportXP Local Database Initialization
-- Chứa Schema đầy đủ mới nhất, loại bỏ hoàn toàn các bảng feed/activity dư thừa.
-- ==============================================================================

-- 1. Thiết lập Roles chuẩn Supabase
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;

-- 2. Bảng Courts (Sân cầu lông)
CREATE TABLE IF NOT EXISTS public.courts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text NOT NULL,
  distance_km numeric(4,1) DEFAULT 0.0,
  created_at timestamptz DEFAULT now()
);

-- 3. Bảng Profiles (Hồ sơ Vận động viên & Elo)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name text NOT NULL DEFAULT 'Vận động viên',
  elo_rating integer,
  tier_name text,
  trust_score integer DEFAULT 100,
  win_streak integer DEFAULT 0,
  onboarding_step integer NOT NULL DEFAULT 0,
  public_id text UNIQUE,
  social_visibility text NOT NULL DEFAULT 'public' CHECK (social_visibility IN ('public', 'friends')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Bảng Friendships / Đồng đội
CREATE TABLE IF NOT EXISTS public.friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_b uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at timestamptz DEFAULT now(),
  CONSTRAINT chk_friendships_order CHECK (user_a < user_b),
  CONSTRAINT uq_friendships_pair UNIQUE (user_a, user_b)
);

-- 5. Bảng User Blocks
CREATE TABLE IF NOT EXISTS public.user_blocks (
  blocker_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- 6. Bảng Match Rooms (Phòng tìm kèo)
CREATE TABLE IF NOT EXISTS public.match_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  court_id uuid NOT NULL REFERENCES public.courts(id) ON DELETE RESTRICT,
  play_time timestamptz NOT NULL,
  max_slots integer NOT NULL DEFAULT 4,
  current_players integer NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'full', 'in_progress', 'completed', 'canceled')),
  terms_revision integer NOT NULL DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 7. Bảng Room Members (Thành viên tham gia phòng)
CREATE TABLE IF NOT EXISTS public.room_members (
  room_id uuid NOT NULL REFERENCES public.match_rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('host', 'member')),
  status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'attended', 'no_show', 'canceled')),
  admitted_at timestamptz DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);

-- 8. Bảng Match Results (Kết quả trận đấu & Lịch sử đối đầu)
CREATE TABLE IF NOT EXISTS public.match_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid REFERENCES public.match_rooms(id) ON DELETE SET NULL,
  court_name text NOT NULL,
  team_a_names text NOT NULL,
  team_b_names text NOT NULL,
  score_text text NOT NULL,
  winner_team text NOT NULL CHECK (winner_team IN ('A', 'B')),
  elo_change integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- 9. Bảng Onboarding Responses
CREATE TABLE IF NOT EXISTS public.onboarding_responses (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  answers integer[] NOT NULL DEFAULT '{}',
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT onboarding_answers_length CHECK (cardinality(answers) BETWEEN 0 AND 5)
);

-- 10. Hàm quy đổi Rank Tier từ Elo (Hệ thống phân cấp chuẩn SportXP v2)
CREATE OR REPLACE FUNCTION public.sportxp_tier_name(p_elo integer)
RETURNS text LANGUAGE sql IMMUTABLE
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

-- 11. Cấp quyền truy cập cho anon và authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ==============================================================================
-- Seed Data Mới Nhất (Đồng bộ 100% với dữ liệu thực tế trên Supabase Cloud)
-- ==============================================================================

-- Seed Sân cầu lông (Courts)
INSERT INTO public.courts (id, name, address, distance_km, created_at) VALUES
('34e55945-cbab-4de2-8da5-a70ab71664cf', 'Sân Đào Duy Anh', 'Phú Nhuận, TP.HCM', 1.8, '2026-10-17 19:10:43+00'),
('59f0c842-6ef9-4df1-89b8-eea48f564fde', 'Sân Cầu Lông Kim Cương', 'Thủ Đức, TP.HCM', 2.4, '2026-10-17 19:10:43+00'),
('af4b1067-d5fa-48f1-a1b6-baf75c47fd7a', 'Sân Cầu Lông Bình Triệu', 'Bình Thạnh, TP.HCM', 3.1, '2026-10-17 19:10:43+00')
ON CONFLICT (id) DO NOTHING;

-- Seed Người chơi mẫu (Profiles)
INSERT INTO public.profiles (id, display_name, elo_rating, tier_name, trust_score, win_streak, public_id) VALUES
('11111111-1111-1111-1111-111111111111', 'Trần Hữu Minh (Top 1)', 1650, 'Tốt+', 100, 7, 'minh-pro'),
('22222222-2222-2222-2222-222222222222', 'Lê Tuấn Nam', 1350, 'Khá+', 98, 4, 'nam-badminton'),
('33333333-3333-3333-3333-333333333333', 'Phạm Quốc Bảo', 920, 'TB+', 95, 2, 'bao-smash'),
('44444444-4444-4444-4444-444444444444', 'Nguyễn Đức Hoàng', 780, 'TB', 100, 3, 'hoang-sportxp')
ON CONFLICT (id) DO NOTHING;

-- Seed Lịch sử kết quả trận đấu (Match Results)
INSERT INTO public.match_results (id, court_name, team_a_names, team_b_names, score_text, winner_team, elo_change, created_at) VALUES
('da4e6a51-9fb5-4f3b-8592-366a7a343807', 'Sân Đào Duy Anh', 'BẠN & MINH', 'LINH & NAM', '21–19  21–16', 'A', 18, '2026-10-17 19:10:43+00'),
('0420d59a-a277-4f8c-a77d-53daf2edbe2f', 'Sân Cầu Lông Kim Cương', 'HOÀNG & TUẤN', 'HÙNG & KHOA', '21–14  18–21  21–19', 'A', 22, '2026-10-17 19:10:43+00')
ON CONFLICT (id) DO NOTHING;


-- ==============================================================================
-- SportXP Tournaments Schema & Policies (20261028000000_tournaments.sql)
-- Thiết kế hướng tới Người chơi (VĐV) và tương thích hoàn toàn cho Chủ sân (Host)
-- ==============================================================================

BEGIN;

-- 1. Bảng Giải đấu (Tournaments)
CREATE TABLE IF NOT EXISTS public.tournaments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL, -- Chủ sân / Host tạo giải
  court_id uuid REFERENCES public.courts(id) ON DELETE SET NULL,  -- Sân tổ chức (nếu chọn từ hệ thống sân)
  title text NOT NULL,                                           -- Tên giải đấu
  venue_name text NOT NULL,                                      -- Địa điểm / Tên sân thi đấu
  address text NOT NULL,                                         -- Địa chỉ sân
  format text NOT NULL DEFAULT 'doubles' CHECK (format IN ('singles', 'doubles', 'mixed')), -- Thể thức thi đấu
  banner_url text,                                               -- Ảnh bìa giải đấu
  min_tier text,                                                 -- Yêu cầu Rank tối thiểu (vd: TB)
  max_tier text,                                                 -- Yêu cầu Rank tối đa (vd: Khá+)
  entry_fee numeric(12, 0) NOT NULL DEFAULT 0,                   -- Lệ phí tham gia (VNĐ)
  prize_pool numeric(12, 0) NOT NULL DEFAULT 0,                  -- Tổng giải thưởng (VNĐ)
  max_slots integer NOT NULL DEFAULT 16,                         -- Số lượng VĐV / Cặp đấu tối đa
  current_slots integer NOT NULL DEFAULT 0,                      -- Số lượng đã đăng ký
  start_date timestamptz NOT NULL,                               -- Thời gian bắt đầu
  end_date timestamptz,                                          -- Thời gian kết thúc
  status text NOT NULL DEFAULT 'registering' CHECK (status IN ('draft', 'registering', 'ongoing', 'completed', 'canceled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Bảng Danh sách VĐV tham gia giải đấu (Tournament Participants)
CREATE TABLE IF NOT EXISTS public.tournament_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  partner_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL, -- Bạn đánh cùng (nếu đánh đôi)
  status text NOT NULL DEFAULT 'registered' CHECK (status IN ('registered', 'paid', 'confirmed', 'checked_in', 'eliminated', 'champion', 'runner_up')),
  created_at timestamptz DEFAULT now(),
  CONSTRAINT uq_tournament_player UNIQUE (tournament_id, user_id)
);

-- 3. Row Level Security & Grants
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_participants ENABLE ROW LEVEL SECURITY;

-- Mọi người dùng (kể cả anon) đều được xem danh sách giải đấu công khai
CREATE POLICY "Public read tournaments" ON public.tournaments
  FOR SELECT TO anon, authenticated USING (status != 'draft');

-- VĐV đăng nhập xem được danh sách người tham gia
CREATE POLICY "Public read participants" ON public.tournament_participants
  FOR SELECT TO anon, authenticated USING (true);

-- VĐV tự đăng ký giải đấu
CREATE POLICY "Users can register tournament" ON public.tournament_participants
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Cấp quyền SELECT cho anon & authenticated
GRANT SELECT ON public.tournaments TO anon, authenticated;
GRANT SELECT, INSERT ON public.tournament_participants TO anon, authenticated;

-- ==============================================================================
-- Seed Dữ liệu Giải đấu Thực tế Mẫu (Chuẩn phong trào TP.HCM)
-- ==============================================================================
INSERT INTO public.tournaments (
  id, title, venue_name, address, format, min_tier, max_tier, entry_fee, prize_pool, max_slots, current_slots, start_date, status
) VALUES
(
  'e1111111-1111-1111-1111-111111111111',
  'SportXP Open Championship 2026',
  'Sân Cầu Lông Kỳ Hòa, Quận 10',
  'Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM',
  'doubles',
  'TB',
  'Khá+',
  200000,
  5000000,
  32,
  18,
  now() + interval '14 days',
  'registering'
),
(
  'e2222222-2222-2222-2222-222222222222',
  'Cúp Tân Binh Phong Trào - Tranh Đĩa Bạc',
  'Sân Cầu Lông Đào Duy Anh',
  'Đào Duy Anh, Phú Nhuận, TP.HCM',
  'doubles',
  'Nhập môn',
  'TBY+',
  150000,
  3000000,
  16,
  12,
  now() + interval '7 days',
  'registering'
),
(
  'e3333333-3333-3333-3333-333333333333',
  'Super Smash Master - Đơn Nam Hạng Khá',
  'Sân Cầu Lông Kim Cương',
  'Thủ Đức, TP.HCM',
  'singles',
  'Khá-',
  'Cao thủ phong trào',
  250000,
  8000000,
  16,
  16,
  now() + interval '3 days',
  'ongoing'
)
ON CONFLICT (id) DO NOTHING;

COMMIT;
