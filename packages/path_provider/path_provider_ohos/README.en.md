<p align="center">
  <h1 align="center"> <code>path_provider</code> </h1>
</p>

This project is developed based on [path_provider@2.1.4](https://pub.dev/packages/path_provider/versions/2.1.4).

## Introduction

`path_provider` in Flutter is used to obtain common filesystem paths on a device, such as temporary directories, application documents directories, cache directories, and external-storage-related paths. This implementation integrates with `path_provider` through the federated plugin architecture, providing platform channel capabilities on OpenHarmony that are consistent with the official plugin.

## Installation

Go to your project directory and add the following dependency in `pubspec.yaml`:

```yaml
...

dependencies:
  path_provider:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/path_provider/path_provider
      # ref: provider-v2.1.4_ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below
...
```

Run the following command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.41 | `provider-v2.1.5-ohos-1.0.0` | `br_path_provider-v2.1.5_ohos` |
| 3.35 | `provider-v2.1.5-ohos-1.0.0` | `br_path_provider-v2.1.5_ohos` |
| 3.27 | `provider-v2.1.5-ohos-1.0.0` | `br_path_provider-v2.1.5_ohos` |
| 3.22 | `provider-v2.1.4_ohos-1.0.0` | `br_path_provider-v2.1.4_ohos` |
| 3.7 | `provider-v2.1.1-ohos-1.0.0` | `master` |

## Constraints and Limitations

### Compatibility

Verified on the following versions:

1. Flutter: 3.22.4-ohos-1.1.4-beta; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.0.830; ROM: 6.1 Developer Beta;

### Permission Requirements

Some permissions are system-level (`system-level`), while the default application level is `normal` and only `normal`-level permissions can be used. Therefore, if the application requests system-level permissions, errors may occur when installing the HAP package.

Open `entry/src/main/module.json5` and add:

```yaml
"requestPermissions": [
  {
   "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when":"inuse"
    }
  },
]
```

Open `entry/src/main/resources/base/element/string.json` and add:

```
...
{
  "string": [
    {
      "name": "network_reason",
      "value": "Use network"
    },
  ]
}
```

## Usage Example

The example in this repository, [`example/lib/main.dart`](./example/lib/main.dart), follows the same implementation approach as below: both depend on `path_provider_platform_interface`, use `PathProviderPlatform.instance` to call `getTemporaryPath()`, `getApplicationDocumentsPath()`, and similar methods; on the UI side, requests are triggered from button `onPressed` handlers and paths or errors are shown with `FutureBuilder`. The snippet below is a simplified example. For a complete runnable version, refer to `example/lib/main.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Future<void> logPathsFromExample() async {
  final PathProviderPlatform provider = PathProviderPlatform.instance;

  final temp = await provider.getTemporaryPath();
  debugPrint('Temporary: $temp');

  final docs = await provider.getApplicationDocumentsPath();
  debugPrint('Documents: $docs');

  final support = await provider.getApplicationSupportPath();
  debugPrint('Support: $support');

  final cache = await provider.getApplicationCachePath();
  debugPrint('Cache: $cache');
}
```

## Usage Notes

1. Add `path_provider` in `pubspec.yaml` (configure the Git source and `ref` as in the previous section). The example project resolves `path_provider_platform_interface` as a transitive dependency.
2. For path queries, follow the example approach: use `PathProviderPlatform.instance` and methods such as `getTemporaryPath()`, trigger requests from UI buttons, and present results with `FutureBuilder`. The snippet in this document is simplified; for a complete runnable version, refer to `example/lib/main.dart`.

## API Reference

### API

The following table lists support status in this OHOS implementation for path capabilities related to the `path_provider` platform interface. At the application layer, continue using APIs exported by the main `path_provider` package.

| Name                | Return value                        | Description               | Type       | OHOS support |
|---------------------|-------------------------------------------------------------------------------------------------------|------|-------|-------------------|
| getTemporaryPath()   |   Future<String?>             |         Gets the application temporary directory path, returns the cache directory (cacheDir) within the app sandbox.     | function | yes               |
| getApplicationSupportPath()   |    Future<String?>     |    Gets the application support files directory path, returns the files directory (filesDir) within the app sandbox.         | function | yes               |
| getLibraryPath()   |    Future<String?>     |    Gets the application Library directory path (used on iOS/macOS, etc.). Not supported on OHOS; calls throw `UnsupportedError`. The example app still includes a button to verify this behavior.         | function | no               |
| getApplicationDocumentsPath() |     Future<String?>  |          Gets the application documents directory path, returns the data directory (dataDir) within the app sandbox.       | function | yes               |
| getApplicationCachePath()   | Future<String?>       |          Gets the application cache directory path, returns the cache directory (cacheDir) within the app sandbox.      | function       | yes              |
| getExternalCachePaths()     | Future<List<String>?> | Gets external cache directory paths list. OHOS returns the cache directory (cacheDir) within the app sandbox, different from Android behavior.  | function       | yes               |
| getExternalStoragePath()    |   Future<String?>         |       Gets the application external storage path, the directory path where the application can access external storage.     |        function       | yes               |
| getExternalStoragePaths([StorageDirectory](#StorageDirectory) arg_directory)   | Future<List<String>?> |   Gets the application external storage root directory path, the paths where application-specific data can be stored in external directories, typically located on external storage such as separate partitions or SD cards. A phone may have multiple available storage directories. | function       | yes               |
| getDownloadsPath()   | Future<String?>       | Gets the directory path where downloaded files can be stored; on OHOS this is implemented via internal method `_getExternalStoragePaths(StorageDirectory.downloads)`, returning null when no path is available. | function | yes               |

### Properties

#### StorageDirectory

| Name              | Description                                                | Type                                        | OHOS support |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- | ------------ |
|  StorageDirectory.music  | Music file type in the storage directory |  enum | yes   |
|  StorageDirectory.podcasts  | Audio file type in the storage directory |  enum | yes   |
|  StorageDirectory.ringtones  | Ringtone file type in the storage directory |  enum | yes   |
|  StorageDirectory.alarms  | Alarm ringtone file type in the storage directory |  enum | yes   |
|  StorageDirectory.notifications  | Notification file type in the storage directory |  enum | yes   |
|  StorageDirectory.pictures  | Picture file type in the storage directory |  enum | yes   |
|  StorageDirectory.movies  | Movie file type in the storage directory |  enum | yes   |
|  StorageDirectory.downloads  | Download file type in the storage directory |  enum | yes   |
|  StorageDirectory.dcim  | Photo and video file type in the storage directory |  enum | yes   |
|  StorageDirectory.documents  | Standard file type in the storage directory |  enum | yes   |

## Unsupported capabilities

- `StorageDirectory.root`: Although the internal implementation defines a `root` enum value (used to handle `type: null` cases), the public `StorageDirectory` enum **does not include** `root`; **`StorageDirectory.root` is not supported**. Use `getExternalStoragePaths(type: null)` for the root directory.
- `getLibraryPath()`: OHOS has no Library directory equivalent to iOS/macOS. This implementation throws `UnsupportedError('getLibraryPath is not supported on OHOS')` (same behavior as the Android implementation). The example app [`example/lib/main.dart`](./example/lib/main.dart) still includes a **Get Library Directory** button so you can trigger the call and see the error via `FutureBuilder`.

## Differences from Android

Some external-storage-related APIs behave differently from Android and cannot be fully aligned due to platform limitations:

- `getExternalStoragePath()`: On Android, returns the app-specific directory on external storage; on OHOS, returns the `files` directory inside the app sandbox (internal storage).
- `getExternalCachePaths()`: On Android, may return multiple external cache directories; on OHOS, only a single app `cache` directory is returned.
- `getExternalStoragePaths(type)`: On Android, returns multiple system-level external media/storage directories; on OHOS, creates a subdirectory by type under `files` and returns a single path.

## Known Issues

## Directory Structure

```
|---- path_provider_ohos
|     |---- example                    # Example application
|           |---- lib                  # Example Dart code
|           |---- ohos                 # Native code for the example application
|     |---- lib                        # Dart core implementation
|           |---- path_provider_ohos.dart   # Plugin main entry
|           |---- messages.g.dart           # Platform channel message definitions
|     |---- ohos                       # OpenHarmony native code directory
|           |---- src/main/ets/io/flutter/plugins/pathprovider/PathProviderPlugin.ets # Plugin entry
|     |---- test                       # Unit tests
|     |---- CHANGELOG.md               # Version change log
|     |---- LICENSE                    # BSD-3-Clause
|     |---- pubspec.yaml               # Package configuration file
|     |---- README_CN.md   # Chinese documentation
|     |---- README.md      # English documentation
```

## Contributing

If you run into any problems while using this project, you can file an [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues). Pull requests are also very welcome: [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls).

## License

This project is licensed under [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/path_provider/path_provider_ohos/LICENSE). You are welcome to use and contribute to open source freely.

> Template version: v0.0.1
