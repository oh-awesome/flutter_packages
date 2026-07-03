<p align="center">
  <h1 align="center"> <code>path_provider</code> </h1>
</p>

This project is based on [path_provider@2.1.0](https://pub.dev/packages/path_provider/versions/2.1.0).

## Introduction

`path_provider` is used in Flutter to obtain common file system paths on devices, such as temporary directories, application document directories, cache directories, and external storage related paths. This implementation integrates with `path_provider` through a federated plugin, providing consistent platform channel capabilities on OpenHarmony as the official plugin.

## Installation

Go to the project directory and add the following dependencies in pubspec.yaml:

```yaml
...

dependencies:
  path_provider:
    git: 
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/path_provider/path_provider
      ref: br_path_provider-v2.1.4_ohos
```

Execute command:

```bash
flutter pub get
```

## Constraints and Limitations

### Compatibility

Tested and verified on the following versions:
1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### Permission Requirements

Some permissions are system-level (`system-level`), while the default application level is `normal`, which can only use `normal` level permissions. Therefore, if system-level permissions are requested in the application, errors may occur when installing the HAP package.

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

The example in this repository [`example/lib/main.dart`](./example/lib/main.dart) follows the same implementation approach: both depend on `path_provider_platform_interface`, use `PathProviderPlatform.instance` to call `getTemporaryPath()`, `getApplicationDocumentsPath()`, etc.; the UI side triggers requests in button `onPressed` and displays paths or errors through `FutureBuilder`. The code snippets in this document are simplified examples, please refer to `example/lib/main.dart` for the complete runnable version.

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

## Usage Instructions

1. Add dependency on `path_provider` in `pubspec.yaml` (Git source and `ref` configured as above); the example project will resolve `path_provider_platform_interface` through transitive dependencies.
2. For path queries, refer to the example implementation approach: call `getTemporaryPath()` and other methods through `PathProviderPlatform.instance`, and trigger via buttons on the UI side, displaying results through `FutureBuilder`. The code snippets in this document are simplified examples, please refer to `example/lib/main.dart` for the complete runnable version.

## API Reference

### API

The following lists the support status of path capabilities related to the `path_provider` platform interface in this OHOS implementation. The application layer should still use the functions exported by the main `path_provider` package.

| Name                | Return Value                        |  Description               | Type       | OHOS Support |
|---------------------|-------------------------------------------------------------------------------------------------------|------|-------|-------------------|
 | getTemporaryPath()   |   Future<String?>             |         Obtain the unbacked temporary directory path on the device, which is suitable for storing the cache of downloaded files.     | function | yes               |	 
 | getApplicationSupportPath()   |    Future<String?>     |    The method to obtain the path of the directory of the application support files, the path of the directory where the application may place the application support files. If the directory does not exist, it will be automatically created.       | function | yes  
 | getLibraryPath()   |    Future<String?>     |    Get the path of the application Library directory (used on iOS/macOS platforms). OHOS does not support this, calling will throw `UnsupportedError`. The example app still provides a corresponding button to verify this behavior.         | function | no               |             |	 
 | getApplicationDocumentsPath() |     Future<String?>  |          The method to obtain the file path of the application, in which the application can place user-generated data or data that cannot be recreated by the application.       | function | yes               |	 
 | getApplicationCachePath()   | Future<String?>       |          The method to obtain the application cache path: The application may place a path specific to the application cache file directory. If the directory does not exist, it will be automatically created.      | function       | yes              |	 
 | getExternalCachePaths()     | Future<List<String?>> | Obtaining the cached data of the application can be stored in external directory paths, which are usually located on external storage, such as separate partitions or SD cards. A mobile phone may have multiple available storage directories.  | function       | yes               |	 
 | getExternalStoragePath()    |   Future<String?>         |       The method of obtaining the top-level storage path of the application, where the application can access the directory path of the top-level storage.     |        function       | yes               |	 
 | getExternalStoragePaths([StorageDirectory](#StorageDirectory) arg_directory)   | Future<List<String?>> |   The method of obtaining the top-level storage path of the application, the paths where application-specific data can be stored in external directories, and these paths are usually located on external storage, such as separate partitions or SD cards. A mobile phone may have multiple available storage directories. | function       | yes   
 | getDownloadsPath()   | Future<String?>       | Get the path of the download files directory; on OHOS, this is implemented based on `getExternalStoragePaths(StorageDirectory.downloads)`, returns null when no path is available. | function | yes           |

### Properties

#### StorageDirectory

| Name              | Description                                                | Type                                        | OHOS Support |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- | ------------ |
 |  StorageDirectory.music  | The type of music file stored in the directory |  enum | yes   |	 
 |  StorageDirectory.podcasts  | The audio file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.ringtones  | The ringtone file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.alarms  | The file type of the alarm bell in the storage directory |  enum | yes   |	 
 |  StorageDirectory.notifications  | The notification file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.pictures  | The image file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.movies  | The movie file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.downloads  | The download file type of the storage directory |  enum | yes   |	 
 |  StorageDirectory.dcim  | The types of photo and video files stored in the directory |  enum | yes   |	 
 |  StorageDirectory.documents  | The common file types of the storage directory |  enum | yes   |

## Unsupported Capabilities

- `StorageDirectory.root`: The public API's `StorageDirectory` enum **does not include** `root`, **not supported** `StorageDirectory.root` usage. To get the root directory, use `getExternalStoragePaths(type: null)`.
- `getLibraryPath()`: OHOS does not provide an equivalent Library directory concept as iOS/macOS, this implementation will throw `UnsupportedError('getLibraryPath is not supported on OHOS')` (behavior consistent with Android implementation). The example app [`example/lib/main.dart`](./example/lib/main.dart) still retains the **Get Library Directory** button, clicking it will show the above error message through `FutureBuilder`.

## Differences from Android

Some "external storage" related interfaces are inconsistent with Android behavior, and cannot be aligned due to platform capability limitations:

- `getExternalStorageDirectory()`: Android returns the application-specific directory on external storage, OHOS returns the `files` directory within the application sandbox (internal storage).
- `getExternalCacheDirectories()`: Android can return multiple external cache directories, OHOS only returns a single application `cache` directory.
- `getExternalStorageDirectories(type)`: Android returns multiple system-level external media/storage directories, OHOS creates subdirectories by type under the `files` directory and returns a single path.

## Known Issues

## Directory Structure

```
|---- path_provider_ohos
|     |---- example                    # Example application
|           |---- lib                  # Example Dart code
|           |---- ohos                 # Example application native code
|     |---- lib                        # Dart core implementation
|           |---- path_provider_ohos.dart   # Plugin main entry
|           |---- messages.g.dart           # Platform channel message definition
|     |---- ohos                       # OpenHarmony native code directory
|           |---- src/main/ets/components/plugin/PathProviderOhosPlugin.ets  # Plugin entry
|     |---- test                       # Unit tests
|     |---- CHANGELOG.md               # Version changelog
|     |---- LICENSE                    # BSD-3-Clause
|     |---- pubspec.yaml               # Package configuration file
|     |---- README_CN.md   # Chinese documentation
|     |---- README.md      # English documentation
```

## Contributing

If you encounter any issues during use, please submit an [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues). Of course, [PR](https://gitcode.com/openharmony-tpc/flutter_packages/pulls) contributions are also very welcome.

## License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/path_provider/path_provider_ohos/LICENSE), please feel free to enjoy and participate in open source.

> Template version: v0.0.1
