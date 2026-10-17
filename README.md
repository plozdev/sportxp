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

Rebuild when changing `.env`. Do not bundle a service-role key. A public anon key
is expected to be present in the compiled client; authorization belongs in RLS
and server functions. JSON defines remain supported via config/supabase.example.json.
Android release Internet permission is configured. Without configuration the app
shows a dark setup state rather than demo records.

## Implemented

- Password login/sign-up, confirmation-email state, session persistence, logout.
  Mutating actions prompt login and resume the requested action after success.
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

## Backend verification and remaining deployment prerequisite

The supplied .env reaches the live backend. Read-only probes returned HTTP 401
for the four table endpoints. The courts error is PostgreSQL 42501:
`permission denied for table courts` for anon. The token has anon role, has not
expired and matches the project. No live data or permissions were modified.

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
- lib/features/auth: auth modal.
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
Apply supabase/migrations/20261018_onboarding.sql in Supabase SQL Editor before
using this app version. Migration is provided locally and has not been deployed.
See docs/onboarding.md for behavior, server requirements and validation details.
