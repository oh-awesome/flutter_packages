## camera-v0.11.0_2-ohos-1.0.3 - 2026.10

* **Added:**

  Unit tests covering the OHOS image stream format mapping for `1003` (`ImageFormatGroup.nv21`). ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Unit tests covering the OHOS image stream format mapping for `2000` (`ImageFormatGroup.jpeg`). ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Unit tests asserting legacy Android constants (`35`/`256`/`17`) fall through to `unknown`. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  

* **Changed:**

  Image stream format reporting now follows the actual `format` of the selected `previewProfile` instead of the `ImageReceiver` creation format. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  `_imageFormatGroupFromPlatformData` maps `1003` to `ImageFormatGroup.nv21`, matching the NV21 byte order confirmed on device. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  `_imageFormatGroupFromPlatformData` maps `2000` to `ImageFormatGroup.jpeg`. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  

* **Removed:**

  Legacy Android dead branch (`case 35` → `ImageFormatGroup.yuv420`) from the OHOS format mapping. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Legacy Android dead branch (`case 256` → `ImageFormatGroup.jpeg`) from the OHOS format mapping. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Legacy Android dead branch (`case 17` → `ImageFormatGroup.nv21`) from the OHOS format mapping. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  

* **Fixed:**

  `sensorExposureTime` no longer reports the sensor sensitivity value. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Misleading fallback log message now reports the actual output format. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  `resumeVideoRecording` no longer fails with "avRecorder state is not paused" when the camera is recreated during a paused recording. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Pause/resume admission now uses an app-level `pausedRequested` flag instead of transient `avRecorder.state` reads. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  Outdated `CameraValue.toString` assertion in the `camera` package tests caused by `CameraLensType` from the hosted `camera_platform_interface`. ([#1761](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1761))  
  `stopImageStream` no longer unconditionally restarts the preview. A stop landing on an instance with no active image stream (for example a Dart-side subscription cancel reaching a freshly recreated instance after a background/foreground lifecycle recreate) is now a no-op, and during create/initialize/dispose transitions the preview restart is skipped so it cannot race the in-flight `open()` (7400101 SERVICE_FATAL_ERROR) on the new instance. ([#1832](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1832))  
  `startImageStream` issued during a camera transition (create/initialize/dispose) is no longer executed against the half-initialized instance — which corrupted the camera service state and surfaced as 'GetSupportedOutputCapability parse error' / 'Session not config' dialogs — the request is deferred and re-evaluated once the transition settles, and dropped silently when its cameraId has gone stale (the Dart side re-subscribes under the new cameraId). ([#1832](https://gitcode.com/CPF-Flutter/flutter_packages/pull/1832))  
