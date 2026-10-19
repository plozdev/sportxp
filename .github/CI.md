# App readiness checks

CI runs on pushes to `dev`/`main` and pull requests targeting `main`.

- `flutter analyze`: rejects analyzer errors, warnings and lints, including unused imports and locals. It is not a detector for all unused public code.
- `flutter test`: checks authentication, navigation, data flow, authorization, input validation, room lifecycle and layout/runtime exceptions. Fake repositories and HTTP responses isolate these tests from production data; they are not screenshot mockups.
- Fallback-font tests check small-screen accessibility without optional SDK fonts.
- Android debug APK and web release builds check compilation, platform dependencies and resources. Android release signing and device testing remain separate.

Assert behavior and stable IDs rather than demo names, fixture counts, captions or exact visual arrangement. A fixture reset should preserve its initial data; the number of demo activities may change. Keep checks for sorting, privacy, session isolation and runtime exceptions.

All tests remain enabled. CI does not use `continue-on-error` or suppress analyzer findings. Passing checks do not guarantee absence of bugs: physical-device behavior, production backend policies and network conditions still require validation.
