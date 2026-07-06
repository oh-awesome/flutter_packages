<div align="center">
  <h1>file_selector_ohos</h1>
</div>

This project is developed based on [file_selector@1.0.0](https://pub.dev/packages/file_selector/versions/1.0.0).

## Introduction

`file_selector_ohos` is the OpenHarmony platform implementation of `file_selector`, providing file selection capabilities for Flutter apps, including single-file selection and multi-file selection.

## Installation

Navigate to your project directory and add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->


```yaml
dependencies:
  file_selector:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/file_selector/file_selector
      # ref: file_selector-v1.0.1-ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below
```

Run the command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.7 | `file_selector-v1.0.1-ohos-1.0.0` | `master` |
| 3.22 | `file_selector-v1.0.3-ohos-1.0.0` | `br_file_selector-v1.0.3_ohos` |
| 3.27 | `file_selector-v1.0.3-ohos-1.0.0` | `br_file_selector-v1.0.3_ohos` |
| 3.35 | `file_selector-v1.1.0-ohos-1.0.0` | `br_file_selector-v1.1.0_ohos` |

## Constraints and Limitations

### Compatibility

Tested and passed on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.2.268; ROM: 6.0.0.130 SP18;

### 2.2 Permission Requirements

Some of the following permissions require the `system_basic` privilege level, while the default application privilege level is `normal`, which can only use `normal`-level permissions. Installation of the HAP package may fail due to privilege level mismatch. Please refer to the official platform permission management documentation for configuration.

#### Add permissions in module.json5 under the entry directory

Open `entry/src/main/module.json5` and add:

```yaml
...
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

#### Add the reason for requesting the above permissions under the entry directory

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

```dart
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

Future<void> pickTextFile() async {
  // Import and define file filter conditions
  const XTypeGroup typeGroup = XTypeGroup(
    label: 'text',
    extensions: <String>['txt', 'json'],
    uniformTypeIdentifiers: <String>['public.text'],
  );

  // Open the file picker through the platform interface
  final XFile? file = await FileSelectorPlatform.instance.openFile(
    acceptedTypeGroups: <XTypeGroup>[typeGroup],
  );
  if (file == null) {
    return;
  }
}
```


## API Reference


### API

> [!TIP] In the "ohos Support" column, **yes** means the property is supported on the ohos platform; **no** means not supported; **partially** means partially supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

| Name                                                         | return value        | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ------------------- | ------------------------------------------------------------ | -------- | ------------ |
| openFile({List<[XTypeGroup](#XTypeGroup)>? acceptedTypeGroups, String? initialDirectory, String? confirmButtonText,}) | Future<XFile?>      | Opens a file dialog for loading files and returns the list of file responses selected by the user. | function | partially          |
| openFiles({List<[XTypeGroup](#XTypeGroup)>? acceptedTypeGroups, String? initialDirectory, String? confirmButtonText,}) | Future<List<XFile>> | Opens a file dialog for loading files and returns the list of file responses selected by the user. | function | partially          |
| getDirectoryPath({String? initialDirectory, String? confirmButtonText,}) | Future<String?>     | Opens a file dialog for selecting a directory and returns the selected directory path.         | function | no           |

### Parameters

| Name               | Description                                                                                                                                                                         | Type                        | ohos Support |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-------------------|
| acceptedTypeGroups  | A list of file type groups that can be selected in the dialog. The display behavior depends on the platform.                                                                                                                                 | List<[XTypeGroup](#XTypeGroup)>?               | yes               |
| initialDirectory  | The full path of the directory displayed when the dialog opens. If not provided, the platform chooses an initial location.                                                                                                                                | String?               | yes               |
| confirmButtonText | Text on the dialog confirm button. If not provided, the default OS label is used (for example, "Open").                                                                                                                                 | String?               | no              |

### XTypeGroup

| Name               | Description                                                                                                                                                                         | Type                        | ohos Support |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-------------------|
| label  | The "name" or reference of this type group.                                                                                                                                 | String?               | yes               |
| extensions  | File extensions for this group.                                                                                                                                 | List<String>?               | yes               |
| mimeTypes  | MIME types for this group.                                                                                                                                 | List<String>?               | yes               |
| uniformTypeIdentifiers  | Uniform type identifiers for this group.                                                                                                                                 | List<String>?               | no              |
| webWildCards  | Web wildcards for this group (for example: image/*, video/*).                                                                                                                                 | List<String>?               | no              |


## Known Issues

The confirm button of the system picker dialog cannot be customized. Directory selection is not supported in picker dialogs on phone devices. `webWildCards` only takes effect on the Web platform. `uniformTypeIdentifiers` is a list of Uniform Type Identifiers (UTIs) and only takes effect on iOS / macOS platforms.


## Directory Structure

```text
file_selector_ohos/
├─ lib/                         # OpenHarmony platform implementation export and core logic
├─ ohos/                        # OpenHarmony native implementation
├─ pigeons/                     # Pigeon interface definitions
├─ example/                     # Example app
├─ test/                        # Test code
├─ pubspec.yaml                 # Package configuration
└─ README.md                    # Documentation
```

## Contributing

If you find any issues during use, please submit an [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues). PRs are also welcome.

## License

This project is licensed under [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/file_selector/file_selector_ohos/LICENSE), feel free to use and contribute.
