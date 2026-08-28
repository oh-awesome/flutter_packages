<h1 align="center">image_picker_ohos</h1>

This project is based on [image_picker](https://pub.dev/packages/image_picker) and provides image/video picker capabilities on the OpenHarmony platform.

## Introduction

`image_picker_ohos` is the OpenHarmony platform implementation of the `image_picker` plugin. It supports selecting images and videos from the gallery, taking photos/recording videos with the camera, multi-selecting media files, and image compression/cropping. The plugin bridges to OpenHarmony native capabilities through the Flutter Plugin mechanism, using system APIs such as `photoAccessHelper` and `camera` for media file selection.

## Installation

### Configure pubspec.yaml

Add the dependency to your Flutter project's `pubspec.yaml`:

```yaml
# Option 1: Direct reference (from pub repository)
dependencies:
  image_picker_ohos: ^0.8.13+19

# Option 2: Using Git dependency
dependencies:
  image_picker_ohos:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/image_picker/image_picker_ohos"
      ref: "br_image_picker-v1.2.1_ohos"
```

### Install Dependencies

```bash
# Execute in the project root directory
flutter pub get
```

### DevEco Studio Environment Setup

The `ohos/` module is compiled with the DevEco Studio / HarmonyOS SDK toolchain. Set it up as follows:

1. **Install DevEco Studio**: Download from the [HarmonyOS developer site](https://developer.huawei.com/consumer/cn/deveco-studio/) and install a version that matches the tested matrix below (e.g. DevEco Studio 6.1.1.268 for Flutter 3.44).
2. **Install the HarmonyOS SDK**: Open DevEco Studio, go to `Settings > SDK Manager`, and install the SDK & API version listed in the [Compatibility](#compatibility) matrix (e.g. SDK 5.0.0 / API 12).
3. **Configure `local.properties`** in the host application's `ohos/` directory — point `hwsdk.dir` to the DevEco SDK and `nodejs.dir` to the bundled Node.js runtime:

   ```ini
   hwsdk.dir=D:/DevEco Studio/sdk
   nodejs.dir=D:/DevEco Studio/tools/node
   flutter.sdk=<path-to-OHOS-flutter-SDK>
   ```

   The `flutter.sdk` entry must point to an OHOS-enabled Flutter SDK; using a stock upstream Flutter without OHOS support fails with missing `flutter_ohos` symbols.
4. **Build the HAR**: Open the `ohos/` directory in DevEco Studio and run `Build > Make Module`, or from a terminal run `hvigorw assembleHar` (requires DevEco's `hvigorw` on `PATH`).
5. **Run on a device/emulator**: Connect a HarmonyOS device (or start the emulator), then run `flutter run` from the Flutter project root.

## Constraints and Limitations

### Compatibility
This document is verified based on the following versions:

| Flutter framework version | TAG name                     | Branch    |
|---------------------------|------------------------------|-----------|
| 3.44                      | image_picker-1.2.3-ohos-1.0.0 | oh-3.44.9 |

TAG naming rule: `<upstream-version>-ohos-<version>-betax`; changes between TAGs are recorded in `CHANGELOG.md`.

Tested runtime combinations:

1. Flutter: 3.35.7-ohos-0.0.1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;
2. Flutter: 3.41.10-ohos-0.0.1; SDK: 6.1.0(23); IDE: DevEco Studio: 6.1.0.830; ROM: 6.23.0.100 SP6;
3. Flutter: 3.44.9+ohos-0.0.1-canary1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;

**Version compatibility**: the OHOS implementation depends on the `@ohos/flutter_ohos` runtime (shipped as a HAR), so the Flutter SDK must be an OHOS-enabled build. The three Flutter versions above are all served by the same `image_picker_ohos` version — no extra configuration is needed when switching between them, as long as the DevEco Studio / HarmonyOS SDK / ROM combination stays inside the tested matrix. Unsupported combinations (e.g. a stock upstream Flutter without OHOS support, or a DevEco SDK older than the listed minimum) fail to compile the `ohos/` module and are not supported.

**Upgrade / Migration**:

- **Upstream `image_picker` 1.2.1 → 1.2.3**: the Dart API is source-compatible. Bump `image_picker` / `image_picker_ohos` / `image_picker_platform_interface` in `pubspec.yaml`, then run `flutter pub get`.
- **From a `br_image_picker-v1.2.1_ohos`-era Git dependency**: switch the `ref` to the new TAG (see the table above), update the `image_picker_ohos` HAR reference in the host application (`ohos/oh-package.json5`), and delete stale build artifacts (`ohos/build`, `ohos/oh_modules`) before rebuilding to avoid symbol conflicts.
- **Breaking changes** across upstream `image_picker` versions are recorded in the [upstream CHANGELOG](../CHANGELOG.md); OHOS-specific changes are in this package's `CHANGELOG.md`.

### Permission Requirements

Configure the following permissions in the host application's `ohos/src/main/module.json5`:

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "Access network resources"
      },
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "Read images and videos from the gallery"
      },
      {
        "name": "ohos.permission.WRITE_MEDIA",
        "reason": "Write files to the gallery"
      },
      {
        "name": "ohos.permission.CAMERA",
        "reason": "Use camera for photos or videos"
      }
    ]
  }
}
```

> **Note**: `ohos.permission.INTERNET` is used for resource loading in some scenarios. Configure it based on actual requirements. `ohos.permission.CAMERA` is only required when using the camera to take photos or record videos.

### requestFullMetadata Platform Limitation

> **Note**: The `ImagePickerOptions.requestFullMetadata` parameter is **not supported** on the OpenHarmony platform. OHOS uses a unified `READ_MEDIA` permission model with no fine-grained control over requesting full EXIF metadata (unlike Android/iOS where it affects gallery permission behavior). Setting this flag has no effect on OHOS.

### Platform Differences vs. Android/iOS

- **`usePhotoPicker` has no effect on OHOS**: the upstream `GeneralOptions.usePhotoPicker` flag is ignored on OHOS — the platform only ships the system `PhotoViewPicker` selector with no legacy fallback picker, so the flag does not change any behavior. (`useOhosPhotoPicker` on `ImagePickerOhos` is the OHOS-specific switch that actually controls the native picker, see [Usage Notes](#usage-notes).)
- **Media-type detection**: OHOS distinguishes video from image by the URI path string / file extension (e.g. `.mp4`), whereas Android uses the MIME type returned by `ContentResolver`. For ordinary gallery URIs the results match, but a URI with a missing or ambiguous extension may be classified differently than on Android.
- **`requestFullMetadata` has no effect**: see the note above.

## Usage Examples

### Complete Example (from example/lib/main.dart)

The following code demonstrates typical usage of `image_picker_ohos`.

**Import Module**

```dart
// Import image_picker_ohos
import 'package:image_picker_ohos/image_picker_ohos.dart';
// Import platform interface
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
```

**Initialize Plugin**

```dart
// Get platform instance
final ImagePickerPlatform picker = ImagePickerPlatform.instance;

// On OHOS, enable the native PhotoViewPicker selection UI. It offers a richer
// system picker experience than the platform-interface fallback, and is the
// recommended mode for gallery selection. When disabled (default), selection
// is bridged through the compatibility layer instead.
if (picker is ImagePickerOhos) {
  picker.useOhosPhotoPicker = true;
}
```

**Function Implementation and Result Output**

**Pick a single image (from gallery)**

```dart
// Select a single image from gallery, set max width, height and quality
final XFile? image = await picker.getImageFromSource(
  source: ImageSource.gallery,
  options: ImagePickerOptions(
    maxWidth: 800,
    maxHeight: 600,
    imageQuality: 90,
  ),
);

if (image != null) {
  // Use the image path
  print('Image path: ${image.path}');
}
```

**Pick multiple images**

```dart
// Select multiple images, up to 10
final List<XFile> images = await picker.getMultiImageWithOptions(
  options: MultiImagePickerOptions(
    imageOptions: ImageOptions(
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 90,
    ),
    limit: 10,
  ),
);

// Iterate over multiple images
for (final XFile image in images) {
  print('Image path: ${image.path}');
}
```

**Pick a single image (legacy API)**

```dart
// Use pickImage API (returns PickedFile)
final PickedFile? pickedFile = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 800,
  maxHeight: 600,
  imageQuality: 90,
);

if (pickedFile != null) {
  print('File path: ${pickedFile.path}');
}
```

**Pick multiple images (legacy API)**

```dart
// Use pickMultiImage API
final List<PickedFile>? pickedFiles = await picker.pickMultiImage(
  maxWidth: 800,
  maxHeight: 600,
  imageQuality: 90,
);

if (pickedFiles != null) {
  print('Selected ${pickedFiles.length} images');
}
```

**Pick a video**

```dart
// Select a video from gallery, limit max duration to 10 seconds
final XFile? video = await picker.getVideo(
  source: ImageSource.gallery,
  maxDuration: const Duration(seconds: 10),
);

if (video != null) {
  print('Video path: ${video.path}');
}
```

**Pick a video (legacy API)**

```dart
// Use pickVideo API
final PickedFile? video = await picker.pickVideo(
  source: ImageSource.gallery,
  maxDuration: const Duration(seconds: 10),
);

if (video != null) {
  print('Video path: ${video.path}');
}
```

**Pick multiple videos**

```dart
// Select multiple videos, up to 5, each with max duration of 30 seconds
final List<XFile> videos = await picker.getMultiVideoWithOptions(
  options: MultiVideoPickerOptions(
    maxDuration: const Duration(seconds: 30),
    limit: 5,
  ),
);

print('Selected ${videos.length} videos');
```

**Take a photo**

```dart
// Open camera to take a photo
final XFile? photo = await picker.getImageFromSource(
  source: ImageSource.camera,
);

if (photo != null) {
  print('Photo path: ${photo.path}');
}
```

**Pick media files (mix of images and videos)**

```dart
// Select multiple images and videos simultaneously
final List<XFile> media = await picker.getMedia(
  options: MediaOptions(
    allowMultiple: true,
    imageOptions: ImageOptions(
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 90,
    ),
  ),
);

print('Selected ${media.length} media files');
```

**Retrieve lost data**

```dart
// Restore unprocessed media selection results from before app was reclaimed by system
final LostDataResponse response = await picker.getLostData();

if (!response.isEmpty) {
  final XFile? file = response.file;
  final PlatformException? exception = response.exception;
  
  if (file != null) {
    print('Recovered file: ${file.path}');
  }
  if (exception != null) {
    print('Error during recovery: ${exception.message}');
  }
}
```

## Usage Notes

1. **Native PhotoPicker Support**: Set the `useOhosPhotoPicker` property of the `ImagePickerOhos` instance to `true` to enable the OpenHarmony native `PhotoViewPicker` selection UI for a better user experience. It is the recommended mode for gallery selection; when left `false` (default), selection is bridged through the platform-interface compatibility layer.
2. **Parameter Validation**: `imageQuality` ranges from 0-100, `maxWidth` and `maxHeight` must not be negative, and `limit` must not be lower than 2. An `ArgumentError` will be thrown for invalid parameters.
3. **Camera Device Selection**: `pickImage` / `getImage` / `getVideo` with `source: ImageSource.camera` accept the optional `preferredCameraDevice` parameter (`CameraDevice.rear` / `CameraDevice.front`). OHOS maps it to the system camera picker's front/rear camera; when the value is `CameraDevice.rear` or the device does not expose the requested camera, the system default is used.
4. **Multi-selection Constraints**: In `getMedia()`, the `limit` parameter cannot be set when `allowMultiple` is `false`.
5. **Lost Data Handling**: `getLostData()` is used to recover media selection results that were not fully processed due to system interruptions (e.g., when the app is moved to the background during photo capture and then reclaimed).
6. **Lifecycle**: Some APIs internally use `flutter_plugin_android_lifecycle` to manage lifecycle callbacks.

## API Reference

| Method | Return Type | Ohos Support | Description |
|--------|-------------|-------------|-------------|
| `pickImage()` | `Future<PickedFile?>` | yes | Pick a single image (legacy API) |
| `pickMultiImage()` | `Future<List<PickedFile>?>` | yes | Pick multiple images (legacy API) |
| `pickVideo()` | `Future<PickedFile?>` | yes | Pick a single video (legacy API) |
| `getImage()` | `Future<XFile?>` | yes | Get a single image |
| `getImageFromSource()` | `Future<XFile?>` | yes | Get an image from a specified source, supports `ImagePickerOptions` |
| `getMultiImage()` | `Future<List<XFile>?>` | yes | Get multiple images |
| `getMultiImageWithOptions()` | `Future<List<XFile>>` | yes | Get multiple images with options, supports `MultiImagePickerOptions` |
| `getMedia()` | `Future<List<XFile>>` | yes | Get media files (mix of images and videos), supports `MediaOptions` |
| `getVideo()` | `Future<XFile?>` | yes | Get a video |
| `getMultiVideoWithOptions()` | `Future<List<XFile>>` | yes | Get multiple videos with options, supports `MultiVideoPickerOptions` |
| `supportsImageSource()` | `bool` | yes | Check whether a given `ImageSource` (gallery / camera) is supported on the current platform |
| `retrieveLostData()` | `Future<LostData>` | yes | Retrieve lost data (compatibility API, returns `PickedFile`) |
| `getLostData()` | `Future<LostDataResponse>` | yes | Get lost data (returns `XFile`) |

## Directory Structure

```
image_picker_ohos/
├── lib/                          # Dart source code
│   ├── image_picker_ohos.dart    # Plugin entry, ImagePickerOhos class
│   └── src/
│       └── messages.g.dart       # Pigeon auto-generated message communication code
├── ohos/                         # OpenHarmony platform implementation
│   ├── BuildProfile.ets
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── index.ets                 # HAR module entry
│   ├── oh-package.json5          # HAR package config (version 1.0.0)
│   └── src/main/
│       ├── module.json5          # Module configuration (permission declarations)
│       └── ets/image_picker/     # ArkTS native implementation
│           ├── DateTimeUtil.ts
│           ├── ExifDataCopier.ets
│           ├── FileUtils.ets
│           ├── ImagePickerCache.ets
│           ├── ImagePickerDelegate.ets   # Core media selection delegate
│           ├── ImagePickerPlugin.ets     # Plugin entry (register method channel)
│           ├── ImagePickerUtils.ets
│           ├── ImageResizer.ets          # Image compression and cropping
│           └── Messages.ets              # Message communication handling
├── example/                      # Flutter example application
│   ├── lib/
│   │   └── main.dart             # Example main program
│   ├── integration_test/
│   └── test_driver/
├── test/                         # Unit tests
├── CHANGELOG.md                  # Version changelog
├── LICENSE                       # BSD 3-Clause License
├── OAT.xml                       # Open source compliance configuration
└── pubspec.yaml                  # Dart package configuration
```

## Contributing

Contributions and issues are welcome! Please visit the [repository](https://gitcode.com/openharmony-tpc/flutter_packages/tree/master/packages/image_picker/image_picker_ohos) to submit a Pull Request or report issues.

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).
