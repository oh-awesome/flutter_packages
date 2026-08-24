## image_picker-1.2.3-ohos-1.0.0 - 2026.8

* Adapted to Flutter 3.35 / 3.41 / 3.44 (including OHOS custom SDK), with verified compatibility matrix covering the same version.

* Fixed the issue where multiple video selection only returned the first video (`chooseMultiVideoFromGallery` misused a single result processor).

* Fixed the issue where empty paths in `finishWithListSuccess` never called back, causing Dart Future to hang indefinitely.

* Fixed the serialization/deserialization type error in `CacheRetrievalResult`.

* Completed fine-grained error codes (`no_available_camera` / `no_valid_*` / `missing_valid_video_uri` / `no_activity`).

* Cleaned up pre-created files when camera shooting was canceled or failed to avoid temporary file residue.

* Performed boundary checks on ArkTS layer parameters (imageQuality 0-100, maxWidth/maxHeight non-negative, limit ≥ 2).

* Fixed the issue where scaling output always resulted in JPEG, causing PNG transparency channels to be lost (transparent images were output in alpha). (PNG)

* Fixed double-constraint size overflow when setting maxWidth/maxHeight simultaneously

* Quality hardening (G.TYP.04): switched all string literals in OHOS .ets sources to single quotes to comply with ArkTS style rules.

* Moved the file-descriptor close in `saveFileUri` into a `finally` block so the handle is released even if URI resolution throws.

* Fixed log-message typos (`PhotoViewPicker.select failed whih err` → `with err`; `Close image failed failed` → `Close image failed`).

* Batch URI parsing failure results in an overall error, aligning with Android semantics

* Temporary files are now uniformly consolidated into `image_picker_tmp/`, recursively cleaned up during plugin unbinding

* Plugin unbinding releases PhotoViewPicker/Preferences and unregisters message channel handlers

* README includes version compatibility, upgrade migration, DevEco environment configuration, and platform difference explanations.

## 0.8.7+4

* Support OpenHarmony
