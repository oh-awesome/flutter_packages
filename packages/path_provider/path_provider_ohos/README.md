<p align="center">
  <h1 align="center"> <code>path_provider</code> </h1>
</p>

This project is developed based on [path_provider@2.1.2](https://pub.dev/packages/path_provider/versions/2.1.2).

## Introduction

`path_provider` in Flutter is used to obtain common filesystem paths on a device, such as temporary directories, application documents directories, cache directories, and external-storage-related paths. This implementation integrates with `path_provider` through the federated plugin architecture, providing platform channel capabilities on OpenHarmony that are consistent with the official plugin.

## Installation

Go to your project directory and add the following dependency in `pubspec.yaml`:

```yaml
dependencies:
  path_provider:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/path_provider/path_provider
      ref: br_path_provider-v2.1.5_ohos
```

Run the following command:

```bash
flutter pub get
```

## Constraints and Limitations

### Compatibility

Verified on the following versions:

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;
2. Flutter: 3.35.8-ohos-0.0.3; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
3. Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

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
| getTemporaryPath()   |   Future<String?>             | Gets a non-backed-up temporary directory path on the device, suitable for caching downloaded files.     | function | yes               |
| getApplicationSupportPath()   |    Future<String?>     | Method to get the application support files directory path—the path of the directory where the application may place application support files; if the directory does not exist, it is created automatically.         | function | yes               |
| getApplicationDocumentsPath() |     Future<String?>  | Method to get the application documents directory path where the application may place user-generated data or data that cannot be recreated by the application.       | function | yes               |
| getApplicationCachePath()   | Future<String?>       | Method to get the application cache path—the path of the directory where the application may place application-specific cache files; if the directory does not exist, it is created automatically.      | function       | yes              |
| getExternalCachePaths()     | Future<List<String?>> | Gets directory paths where the application's cache data can be stored externally; these paths are typically on external storage, such as separate partitions or SD cards. A phone may have multiple available storage directories.  | function       | yes               |
| getExternalStoragePath()    |   Future<String?>         | Method to get the application's top-level storage path—the directory path where the application can access top-level storage.     |        function       | yes               |
| getExternalStoragePaths([StorageDirectory](#StorageDirectory) arg_directory)   | Future<List<String?>> | Method to get top-level storage paths for the application—paths to external directories where application-specific data can be stored; these paths are typically on external storage, such as separate partitions or SD cards. A phone may have multiple available storage directories. | function       | yes               |

### Properties

#### StorageDirectory

| Name              | Description                                                | Type                                        | OHOS support |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- | ------------ |
|  StorageDirectory.root  | Root directory type in the storage directory |  enum | yes   |
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

## Differences from Android

Some external-storage-related APIs behave differently from Android and cannot be fully aligned due to platform limitations:

- `getExternalStorageDirectory()`: On Android, returns the app-specific directory on external storage; on OHOS, returns the `files` directory inside the app sandbox (internal storage).
- `getExternalCacheDirectories()`: On Android, may return multiple external cache directories; on OHOS, only a single app `cache` directory is returned.
- `getExternalStorageDirectories(type)`: On Android, returns multiple system-level external media/storage directories; on OHOS, creates a subdirectory by type under `files` and returns a single path.

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
|           |---- src/main/ets/components/plugin/PathProviderOhosPlugin.ets  # Plugin entry
|     |---- test                       # Unit tests
|     |---- CHANGELOG.md               # Version change log
|     |---- LICENSE                    # BSD-3-Clause
|     |---- pubspec.yaml               # Package configuration file
|     |---- README_CN.md   # Chinese documentation
|     |---- README.md      # English documentation
```

## Contributing

If you run into any problems while using this project, you can file an [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues). Pull requests are also very welcome: [PR](https://gitcode.com/openharmony-tpc/flutter_packages/pulls).

## License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/path_provider/path_provider_ohos/LICENSE). You are welcome to use and contribute to open source freely.

> Template version: v0.0.1
