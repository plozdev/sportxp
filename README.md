# SportXP

Flutter badminton MVP. Existing background `#07080A`, Court Green `#00D665`,
font tokens, four-tab navigation and Bento cards are preserved.

## Run

Requires Flutter 3.47.0 or newer with Dart 3.13.0 or newer (validated with
Flutter 3.47.7 / Dart 3.13.5). Run `flutter upgrade` if your SDK is older.

Flutter 3.47.7 pins `material_color_utilities` to 0.13.0 and `flutter_test`
pins `test_api` to 0.7.12. These can still appear in `flutter pub outdated`;
update Flutter when it supports newer versions instead of overriding SDK pins.

Your root `.env` is gitignored and contains `SUPABASE_URL` and
`SUPABASE_ANON_KEY`. Pass it to Flutter as compile-time configuration:

```sh
flutter pub get
flutter run --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
flutter analyze
flutter test
```

Android Studio: open the project root, select the Flutter `main.dart` run
configuration and an Android device/emulator. In **Run > Edit Configurations >
Additional run args**, use:

```text
--dart-define-from-file=.env
```

The local `.idea/runConfigurations/main_dart.xml` is configured with these
arguments. Stop and run again after changing defines;
hot reload does not update them. The app connects directly to the Supabase backend or local Docker stack defined in `.env`. `--no-wasm-dry-run` belongs
to web builds and should not be included in an Android run configuration.

Rebuild when changing `.env`. Do not bundle a service-role key. A public anon key
is expected to be present in the compiled client; authorization belongs in RLS
and server functions. JSON defines remain supported via config/supabase.example.json.
Android release Internet permission is configured. Without configuration the app
shows a dark setup state rather than demo records.

## Implemented

The current MVP uses the Phase 2–4 sandbox by default. The Supabase data flows
below describe the retained adapters used when mock is explicitly disabled.

- Password login/sign-up, confirmation-email state, session persistence, logout.
  Login/sign-up is a full screen required before any app screen or profile link.
  The global auth gate removes all protected routes/sheets on logout or expiry;
  onboarding runs once before mounting the app Navigator. Profile link targets
  survive login/onboarding; opening a link never sends a friend request.
- Home: newest 100 match_results ordered by created_at descending; record form
  calls record_match_and_update_elo with the exact supplied p_* signature.
- Rooms: OPEN, future rooms joined with courts(name, distance_km); create via
  court dropdown, date/time picker and max_slots (default 4), with host included.
- Join: read latest membership, append authenticated ID with an atomic conditional
  update matching prior array/status/capacity/time; confirmed conflicts retry up to
  three times. No lost concurrent joins; final slot marks FULL, hiding it from
  the OPEN list. Existing members are idempotent. RLS still controls access.
- Leaderboard: first 100 profiles ordered by elo_rating descending, stable ID tie
  order, top-three green accents, name/tier/Elo/streak. Refresh on tab entry/manual
  refresh and local mutations (not a Realtime subscription).
- Passport: authenticated profile fields, no demo metrics or badge.
- Recording success refreshes feed/profile/leaderboard; failed refreshes do not
  re-run the RPC. Loading/error/empty states and retry controls are included.

## Database schema

The current production database schema is maintained in `supabase/schema.sql` (and mirrored for local Docker testing in `docker/init-db/01_schema_and_seed.sql`). It contains the definitions for profiles, courts, match_rooms, room_members, match_results, friendships, onboarding_responses, tournaments, and related tables.

## Social profile setup

Profiles, friendships, blocks, and restrictive profile policies are reflected in `supabase/schema.sql`. Profile SELECT grants become an explicit whitelist, and private/blocked profiles are filtered at the server.

QR, camera/link input, connection lists and friend actions are supported. Set `PROFILE_LINK_ORIGIN` to your
HTTPS origin at build time for `https://<host>/#/p/<public_id>` web links; leave it
empty for the `sportxp://profile/<public_id>` native scheme. Verified HTTPS native
links still require domain association files and native signing configuration.

## Phase 2–4 sandbox (current MVP)

Phase 1 auth, onboarding, social and profile still use Supabase. Rooms, courts,
matches and attendance use one in-memory `MockRoomRepository`, owned by the
signed-in shell; rebuilding widgets or changing tabs does not reset it. Restart,
logout/account change or the sandbox Reset button discards the fixture state.
Only the current user's ID/name/initial rating are read into the sandbox. Mock
roles/friendships, scores and attendance never update Supabase profiles or social.

`ROOMS_MOCK_ENABLED` defaults to true and overrides `ROOMS_V2_ENABLED`. The Home
record button routes to sandbox rooms instead of invoking the old record/Elo RPC.
Home now uses the activity sandbox; it does not query `match_results` while mock
is enabled. Phase 1 profile/social still use Supabase; leaderboard now projects
the same five sandbox identities/ratings, with sample streaks and an active-role
marker. It does not query the real leaderboard when mock is enabled.

Profile → **Đổi tài khoản giả lập** switches the shared room/feed/ranking actor
without signing out, resetting mock data or changing the real profile below the
selector. The selector remains available if the real profile fails to load.

Try: Kèo đấu → Buổi của tôi → active demo → Trận đấu / Điểm danh. Record a
single/doubles match, switch to an opposing player and confirm/dispute it; switch
back to the author to edit. The host can record attendance, the affected player
can object and the host can resolve with a note. Finish the seeded active demo
before starting another room with the same participants. Early start is explicitly
allowed only in this sandbox. Host self-attendance and Elo/Trust calculations are
deferred; booking is only a host declaration, not a venue reservation.

Discovery supports combined area/fixed-distance/date/skill/fee/available-slot
filters before pagination. Private rooms are absent from discovery and visible
under Private only for host/current members. Private admission requires a valid
room code, even for friends; code lookup previews the room and join checks the
code again. Unfriending does not affect room admission. Public discovery filters
by the venue area selected in the mock UI; no GPS/proximity algorithm runs.

`RoomRepository` and `RoomSessionRepository` define the adapter boundary, with
immutable commands, request IDs and versioned result/attendance changes. Tests
exercise permissions, retries, waitlist promotion, consent and lifecycle states.

Phase 4 creates separate personal and host-summary drafts from completed session
logs. Home → Nháp từ log → write caption → choose Friends/Only me → Preview →
Publish. A completed fixture provides drafts immediately. Publish is manual;
pending/disputed results are labeled and excluded from win/loss totals. Later
confirmations update derived totals on refresh while preserving post content.
Cards show no participant tags, attendance or dispute reasons. Private venue/title
are redacted for friends outside that session; user-authored captions are explicit.

`ActivityRepository` owns captions/audience/reactions/tombstones, using typed log
projections from the room store. Request receipts prevent duplicate writes and
content versions reject stale edits. Post deletion never deletes match logs.
The Home sandbox connection sheet can simulate unfriend/block, revoking list,
detail and reaction access. Those connections never modify Phase 1 friendships.
Changing tabs/returning from detail/manual refresh reloads totals; no Realtime
subscription is implemented. Photos, comments, tags, Story export and actual
Elo/Trust updates remain deferred. Tests: `flutter test test/mock_activity_test.dart`.

## Retained Supabase rooms adapter (Phase 2A)

For the retained backend adapter, explicitly set `--dart-define=ROOMS_MOCK_ENABLED=false`
and `--dart-define=ROOMS_V2_ENABLED=true`. The flag
defaults to false so the existing MVP can run in sandbox mode without requiring live backend cutover.
When enabled, create/join and all room transitions use `room_command_v2`.

Phase 2A adds public/private rooms, organizer/player host roles, start/end times,
skill/fee/cancellation terms, transactional slots/calendar, FIFO eligible waiters,
revision-bound reconfirmation, notices and private audit history. Finishing a
room does not award Elo or attendance/trust. Legacy rooms remain read-only and
are not silently imported into the new calendar with an invented end time.

## Backend verification and remaining deployment prerequisite

During the initial integration, read-only probes returned permission errors for
the public role. A later read-only audit on 18 Oct 2026 reached all four main
table endpoints with HTTP 200 for zero-row queries. That confirms column/API
access for those queries, not a full audit of RLS, table contents or authenticated
writes. No live data or permissions were modified during that audit.

`supabase/public_read_grants.sql` provides narrow column SELECT grants for public
browsing. Apply it in the project's SQL Editor. It preserves RLS; existing SELECT
policies must also permit the desired public rows. Signed-in INSERT/UPDATE/RPC
permissions and policies cannot be verified with only an anon key. The read-only
`supabase/inspect_existing_backend.sql` lists policies and the RPC body for review.

Server-side signup must create profiles using auth.users metadata display_name.
The existing RPC must check p_user_id = auth.uid(), update Elo atomically, and
ensure its privileged execution cannot be abused. The frontend never writes Elo.

Team A is explicitly the submitting player's team. The results table has no
user_id, so the public feed labels the winner as team A/B, not as a win/loss for
the current viewer; elo_change is rendered exactly as returned by the backend.
A network failure after an RPC commit is ambiguous: the UI asks users to check
history before retrying. The supplied RPC lacks an idempotency-key parameter,
so no automatic write retries are made.

## Code layout

- lib/app: composition, navigation, auth lifecycle and refresh coordination.
- lib/core: shared theme and Supabase configuration.
- lib/features/auth: required login/sign-up screen and global session gate.
- lib/features/feed: draft/summary, score validation, record form and feed.
- lib/features/matchmaking: room/court models, forms and SupabaseMatchRepository.
- lib/features/profile: profile query and passport.
- lib/features/rankings: leaderboard.
- lib/shared/widgets: Bento layout and asynchronous loading/error UI.

Native health, geofencing and passport image export remain future work. The
legacy in-memory repository is retained for domain tests only. Design standards
are in docs/design-system.md; older scaffold architecture notes are superseded
by the implementation status here.

## New-player onboarding

The five-question assessment now runs after login/restored sessions until
profiles.onboarding_step reaches 5. It resumes saved answers, handles retries,
shows a provisional player card, and initializes Elo to 300..850 on the server.
The new Vietnam recreational tiers replace the previous provisional thresholds.
Taxonomy v2 has 20 levels (Yếu-/Yếu/Yếu+, TBY, TB, TBK, Khá, Tốt and
Cao thủ phong trào). These are SportXP calibration boundaries, not a national
standard. 850 Elo is provisional TB+; 1000 Elo is TBK+, not a professional status.
Profile progress and onboarding use the same enum. Research and the reviewed
rating model are in docs/how-elo-works.md.
See docs/onboarding.md for behavior, server requirements and validation details.
