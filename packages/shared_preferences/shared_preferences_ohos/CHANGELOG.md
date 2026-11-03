## shared_preferences-v2.5.6-ohos-1.0.0 - 2026.11

### Added

* Adds unit and on-device test coverage for the legacy big-integer decode and the async non-scalar filtering fixes (102 ohosTest cases in total).
* Extends the Dart unit tests to full public API coverage (async registration, option conversion and backend selection) with exception and boundary scenarios.

### Changed

* Continues the OpenHarmony (ohos) platform implementation based on upstream `shared_preferences` 2.5.6.
* Adapts to the Flutter 3.47.7-ohos toolchain; verified on Flutter 3.41.10, 3.44.9 and 3.47.7.
* Makes concurrent legacy writes deterministic by using `putSync`, and turns the example spec demo page into a visual pass/fail verification page.
* Unifies the source copyright headers (fixes the license header file name, applies the Huawei Apache-2.0 block) and translates the remaining Chinese comments to English.

### Fixed

* Restores reading doubles written with prefix encodings so values stored by older plugin versions decode correctly after upgrade.
* Decodes legacy base-36 big-integer values (Android migration data) in legacy `getAll`, falling back to the raw string for invalid payloads instead of throwing a Dart-side `getInt` error.
* Aligns async `getAll`/`getKeys`/`clear` with the Android `preferencesFilter`: without an allow list only plugin-writable scalar values are read, listed, or deleted, so natively written non-scalar entries are preserved.

## shared_preferences-v2.5.5-ohos-1.0.0 - 2026.8

### Added

* Caches Async API `Preferences` instances by storage name to reduce repeated `getPreferences` calls; releases all cached instances on engine detach.
* Adds edge-case, concurrency, platform-interface, async API, legacy-to-async migration and DevTools extension data test suites under `shared_preferences/test`.
* Adds ArkTS on-device unit tests (ohosTest, 97 cases) for the OpenHarmony native implementation.
* Adds a Modification Tests page to the example app for verifying modified legacy/async behaviors.

### Changed

* Continues the OpenHarmony (ohos) platform implementation based on upstream `shared_preferences` 2.5.5.
* Adapts to the Flutter 3.44.9-ohos toolchain.
* Aligns the `shared_preferences_platform_interface` dependency to `^2.4.0`.

### Fixed

* Fixes `wrapError` to gracefully handle `BusinessError` (e.g. from `@ohos.data.preferences`) that lacks a meaningful `name`/`toString`, so the error payload is not encoded as null and does not crash the Dart pigeon reply.
