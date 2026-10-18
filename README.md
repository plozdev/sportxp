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
--dart-define-from-file=.env --dart-define=ROOMS_V2_ENABLED=true
```

The local `.idea/runConfigurations/main_dart.xml` is configured with these
arguments (IDE files are gitignored). Stop and run again after changing defines;
hot reload does not update them. Enable rooms v2 only against a database with
the Phase 2A migration applied, as described below. `--no-wasm-dry-run` belongs
to web builds and should not be included in an Android run configuration.

Rebuild when changing `.env`. Do not bundle a service-role key. A public anon key
is expected to be present in the compiled client; authorization belongs in RLS
and server functions. JSON defines remain supported via config/supabase.example.json.
Android release Internet permission is configured. Without configuration the app
shows a dark setup state rather than demo records.

## Implemented

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

## Social profile setup

Apply `supabase/migrations/20261018180000_social_phase1.sql` as the database owner
after the onboarding and skill-tier migrations, first on staging. It adds stable
profile IDs, friendships, blocks, private audit events, RPCs and restrictive
profile policies. Review existing consumers: profile SELECT grants become an
explicit whitelist, and private/blocked profiles are filtered at the server.

QR, camera/link input, connection lists and friend actions require this migration.
The existing profile can still load without it. Set `PROFILE_LINK_ORIGIN` to your
HTTPS origin at build time for `https://<host>/#/p/<public_id>` web links; leave it
empty for the `sportxp://profile/<public_id>` native scheme. Verified HTTPS native
links still require domain association files and native signing configuration.

The isolated SQL test uses `@electric-sql/pglite` installed outside the repository:
`node supabase/tests/social_phase1_test.cjs <installation-directory>`.

## Managed rooms (Phase 2A)

The new room workflow is gated by `--dart-define=ROOMS_V2_ENABLED=true`. Apply
`supabase/migrations/20261019000100_rooms_phase2a.sql` after Phase 1, on staging
first, and deploy the enabled client together with the schema cutover. The flag
defaults to false so the existing MVP can run before the new backend is ready.
After cutover, direct room writes from old clients are rejected; create/join and
all room transitions must use `room_command_v2`.

Phase 2A adds public/private rooms, organizer/player host roles, start/end times,
skill/fee/cancellation terms, transactional slots/calendar, FIFO eligible waiters,
revision-bound reconfirmation, notices and private audit history. Finishing a
room does not award Elo or attendance/trust. Legacy rooms remain read-only and
are not silently imported into the new calendar with an invented end time.

Tests: `node supabase/tests/rooms_phase2a_test.cjs <pglite-install-directory>` and
`flutter test --dart-define=ROOMS_V2_ENABLED=true test/managed_rooms_test.dart`.

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
Taxonomy v2 now has 20 levels (Yếu-/Yếu/Yếu+, TBY, TB, TBK, Khá, Tốt and
Cao thủ phong trào). These are SportXP calibration boundaries, not a national
standard. 850 Elo is provisional TB+; 1000 Elo is TBK+, not a professional status.
After the onboarding migration, apply
supabase/migrations/20261018_skill_tiers_v2.sql to sync labels without changing Elo.
Profile progress and onboarding use the same enum. Research and the reviewed
rating model are in docs/how-elo-works.md.
Apply supabase/migrations/20261018_onboarding.sql in Supabase SQL Editor before
using this app version. Migration is provided locally and has not been deployed.
See docs/onboarding.md for behavior, server requirements and validation details.
