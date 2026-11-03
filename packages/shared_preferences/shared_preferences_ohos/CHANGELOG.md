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
