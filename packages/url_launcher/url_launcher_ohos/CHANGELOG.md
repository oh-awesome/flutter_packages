## url_launcher_v6.3.2-ohos-1.0.2-2026.8

- Fixed the reference leak in `UrlLauncherPlugin` caused by failing to clean up the message handler and null out `urlLauncherApi` (which holds `UIAbilityContext`) in `onDetachedFromAbility`/`onDetachedFromEngine`.
- Added fallback logic in `onAttachedToEngine`: when the Ability is attached before the Engine, re-invoke `setup()` to register the message handler, avoiding initialization order issues.
- Fixed the circular reference formed by `InAppBrowser` component callback closures: `aboutToDisappear()` now explicitly clears the component's held references, nulls out `webviewController`, and removes the listener via an exact `emitter.off("closeWebView")` reference.
- Added `.catch()` and the `isAlive` lifecycle flag to `InAppBrowser` async callbacks to avoid race conditions after the component is destroyed; added null-safety protection for `router.getParams()`.
- Converted all launch sub-methods (tel/sms/mailto/web/file/other/appGallery) to `async/await + try-catch`: they return `true` on success and throw a `FlutterError` carrying a specific error code (`INVALID_URL`/`INVALID_PATH`/`LAUNCH_ERROR`/`CANNOT_LAUNCH`/`MISSING_CONFIG`) on failure, eliminating the "false success" caused by fire-and-forget.
- Fixed the `parseUrl` prefix concatenation bug in `launchTel`/`launchMail` (producing `tel::`/`mailto::`), now using the original URL and adding null-value validation.
- Added URL null-value validation at the `canLaunchUrl`/`launchUrl` entry points; `canLaunchUrl` now first dynamically verifies the handling app's existence via `bundleManager.canOpenLink`, falling back to prefix matching for built-in protocols (aligned with Android's resolveActivity behavior).
- Added exception handling around `fileuri.getUriFromPath` in `launchFile`; returns failure and logs when the file name is missing or the path is invalid.
- Fixed the whitespace-matching regex for phone numbers in `format()` (changed `new RegExp('/[\s]/g')` to `/\s/g`) and added input validation.
- The `sms:` protocol now supports the `?body=` query parameter to pre-fill the SMS body, with fault-tolerant decoding of encodeURIComponent-encoded content.
- Added parameter completeness validation to platform channel message handling, returning `INVALID_ARG` for invalid parameters; `launchUrl` now filters out null keys/values in headers before forwarding.
- Added parameter length validation to `WebViewOptions.fromList()` to avoid runtime crashes; `setHeaders()` defensively filters out null entries.

- Changed `closeWebView()` return type from `boolean` to `void`, aligning with the Dart contract and the Android reference implementation.
- Changed `wrapError()`'s non-FlutterError branch to a 3-element array `[code, message, details]`, aligning with the Android error structure and fixing the issue where `PlatformException.details` was always null on the Dart side.
- Removed the unused `getPermission()` dead code and its excessive permission declaration.