# CHANGELOG for OpenHarmony

## camera-v0.12.2-ohos-1.0.0 - 2026.11

* **Added:**

  `videoOutputPath` support: recordings can be written to a caller-provided
  app-sandbox path (validated to end with `.mp4` natively), falling back to
  the default cache directory when omitted. Aligns with the upstream camera
  0.12.2 platform interface.

  Zero-shutter-lag support (`isZeroShutterLagSupported` /
  `setZeroShutterLagEnabled` from the upstream 0.12.2 platform interface),
  mapped to photo output quality prioritization
  (`PhotoQualityPrioritization.SPEED`, API 21+; unsupported / ignored on
  older APIs). The requested state is preserved across camera switches and
  session rebuilds, mirroring the upstream iOS implementation.

* **Fixed:**

  `dispose` during an active recording now finalizes the mp4 via
  `AVRecorder.stop()` per the state machine and closes the capture file,
  instead of only resetting the recorder, so recording-interrupted-by-dispose
  no longer produces corrupted output files.
  Recording frame stream subscription leak in `startVideoCapturing`: repeated
  calls no longer orphan the previous callback's subscription; the stream is
  torn down on stop and dispose.
  Image stream format reporting followed the `ImageReceiver` creation format
  instead of the actual selected preview profile; frames now report the real
  delivered format (NV21, `1003` → `ImageFormatGroup.nv21`, `2000` →
  `ImageFormatGroup.jpeg`; formats without a faithful group report as
  `unknown`), and the legacy Android constant branches were removed.
  ZSL (zero-shutter-lag) calls are now isolated behind an explicit version
  gate (`deviceInfo.sdkApiVersion >= 21`) plus a cached photoOutput
  capability probe, so pre-API 21 runtimes short-circuit without touching
  the API 21+ symbols (no more throw-and-catch noise) and the camera-switch
  replay stays silent when the gate is off.
  `stopImageStream` no longer unconditionally restarts the preview. A stop
  landing on an instance with no active image stream (for example a
  Dart-side subscription cancel reaching a freshly recreated instance
  after a background/foreground lifecycle recreate) is now a no-op, and
  during create/initialize/switch/dispose transitions the preview restart
  is skipped so it cannot race the in-flight `open()` (7400101
  SERVICE_FATAL_ERROR) on the new instance.
  `startImageStream` issued during a camera transition (create/initialize/
  switch/dispose) is no longer executed against the half-initialized
  instance — which corrupted the camera service state and surfaced as
  'GetSupportedOutputCapability parse error' / 'Session not config' dialogs —
  the request is deferred and re-evaluated once the transition settles, and
  dropped silently when its cameraId has gone stale (the Dart side
  re-subscribes under the new cameraId).

## camera-0.12.0+2-ohos-1.0.0 - 2026.08

* **Added:**

  `setJpegImageQuality` (1-100) with post-capture JPEG re-encoding via `ImagePacker` and replay of output settings across camera switches.
  `cameraSwitched` event aligned on the Dart side through the Pigeon `CameraEventApi`.
  Test helpers and Coverage Gap / Edge Case groups in `test/ohos_camera_test.dart`.

* **Changed:**

  Replaced 30+ bare `Error` instances with coded `FlutterError` so `CameraException.code` stays stable and failures are no longer swallowed by getters, `create` or capability queries.
  Annotated Pigeon methods (`initialize`, `dispose`, video-recording controls, `setFocusMode`, `pausePreview`/`resumePreview`, `setDescriptionWhileRecording`, `stopVideoRecording`) with `@async` so errors reach Dart through `wrapError`.
  Stabilized error codes (`setDescriptionWhileRecordingUnsupported`, `EXPOSURE_POINT_ERROR`, `setFocusModeFailed`).
  Clamped the exposure offset to the device range and returned the actually applied EV value.
  Corrected capability reporting: metering regions `0 → 1`, `getLensFacing` returns the `CameraPosition` enum (front-camera fix), and `getSensorOrientation`/`availableCameras` report real sensor orientation.
  Replaced the misleading `supportedImageFormats` map with `getSupportedImageFormat()` and recognized OHOS JPEG format `2000`.
  Upgraded to Flutter 3.44 / Dart ^3.12 / `camera_platform_interface` ^2.13 / Pigeon fork `v26.3.4-ohos-1.0.0`.
  Made `Timeout` usable and `DeviceOrientationManager.start/stop` idempotent with reference-based listener removal.

* **Removed:**

  Legacy MethodChannel path (`MethodCallHandlerImpl`, `DartMessenger` event channels) — communication is now Pigeon-only.
  16 dead-code files (placeholders, empty classes and unused utilities) and the `CameraProperties` interface slim-down (15 → 5 methods).

* **Fixed:**

  Hardened resource lifecycle: full `dispose` before `create` rebuild, texture/state rollback, `imageStreamChannel` unbinding, and the zombie-camera guard in `open()`.
  Listener leaks: precise `photoAssetAvailable` unregistration, `ImageStreamReader` subscribe/close de-dup, and sensor `once` listener removal after `Promise.race`.
  Error-path leaks (three-fold front-camera `ImageStreamReader`, `nextImage.release()`) and double-response/double-throw in `getFocusMode` and `convertBufferToFile`.
  Plugin lifecycle (`onAttachedToAbility`/`onDetachedFromAbility`/`onDetachedFromEngine`) against detach races and direct engine destruction.

## 0.10.8+8

* Adds pub topics to package metadata.

## 0.10.8+7

* Fixes video record crash on Android versions lower than 12.
* Updates minimum supported SDK version to Flutter 3.7/Dart 2.19.

## 0.10.8+6

* Migrates `styleFrom` usage in examples off of deprecated `primary` and `onPrimary` parameters.

## 0.10.8+5

* Provides a default exposure point if null.

## 0.10.8+4

* Adjusts SDK checks for better testability.

## 0.10.8+3

* Fixes unawaited_futures violations.
* Removes duplicate line in `MediaRecorderBuilder.java`.
* Adds support for concurrently capturing images and image streaming/recording.

## 0.10.8+2

* Removes obsolete null checks on non-nullable values.

## 0.10.8+1

* Fixes lint errors.
* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.

## 0.10.8

* Updates gradle, AGP and fixes some lint errors.

## 0.10.7

* Adds support for NV21 as a new streaming format in Android which includes correct handling of
  image padding when present.

## 0.10.6+2

* Fixes compatibility with AGP versions older than 4.2.

## 0.10.6+1

* Adds a namespace for compatibility with AGP 8.0.

## 0.10.6

* Fixes Java warnings.

## 0.10.5

* Allows camera to be switched while video recording.

## 0.10.4+3

* Clarifies explanation of endorsement in README.

## 0.10.4+2

* Aligns Dart and Flutter SDK constraints.
* Updates compileSdkVersion to 33.
* Fixes false positive for CamcorderProfile deprecation warning
  that was already fixed.
* Changes the severity of `javac` warnings so that they are treated as errors and fixes the violations.

## 0.10.4+1

* Updates links for the merge of flutter/plugins into flutter/packages.

## 0.10.4

* Temporarily fixes issue with requested video profiles being null by falling back to deprecated behavior in that case.

## 0.10.3

* Adds back use of Optional type.
* Updates minimum Flutter version to 3.0.

## 0.10.2+3

* Updates code for stricter lint checks.

## 0.10.2+2

* Fixes zoom computation for virtual cameras hiding physical cameras in Android 11+.
* Removes the unused CameraZoom class from the codebase.

## 0.10.2+1

* Updates code for stricter lint checks.

## 0.10.2

* Remove usage of deprecated quiver Optional type.

## 0.10.1

* Implements an option to also stream when recording a video.

## 0.10.0+5

* Fixes `ArrayIndexOutOfBoundsException` when the permission request is interrupted.

## 0.10.0+4

* Upgrades `androidx.annotation` version to 1.5.0.

## 0.10.0+3

* Updates code for `no_leading_underscores_for_local_identifiers` lint.

## 0.10.0+2

* Removes call to `join` on the camera's background `HandlerThread`.
* Updates minimum Flutter version to 2.10.

## 0.10.0+1

* Fixes avoid_redundant_argument_values lint warnings and minor typos.

## 0.10.0

* **Breaking Change** Updates Android camera access permission error codes to be consistent with other platforms. If your app still handles the legacy `cameraPermission` exception, please update it to handle the new permission exception codes that are noted in the README.
* Ignores missing return warnings in preparation for [upcoming analysis changes](https://github.com/flutter/flutter/issues/105750).

## 0.9.8+3

* Skips duplicate calls to stop background thread and removes unnecessary closings of camera capture sessions on Android.

## 0.9.8+2

* Fixes exception in registerWith caused by the switch to an in-package method channel.

## 0.9.8+1

* Ignores deprecation warnings for upcoming styleFrom button API changes.

## 0.9.8

* Switches to internal method channel implementation.

## 0.9.7+1

* Splits from `camera` as a federated implementation.
