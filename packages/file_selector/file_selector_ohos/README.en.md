<p align="center">
  <h1 align="center"> <code>file_selector</code> </h1>
</p>

This project is developed based on [file_selector@1.1.0](https://pub.dev/packages/file_selector/versions/1.1.0).

## 1. Installation and Usage

### 1.1 Installation

Enter the project directory and add the following dependency in pubspec.yaml:

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  file_selector:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/file_selector/file_selector
      # ref: file_selector-v1.1.0-ohos-1.0.1
      ref: TAG  #   Please select the TAG according to the TAG version table below
```

Run the command

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG1 | TAG2 | Branch |
| :--- | :--- | :--- | :--- |
| 3.41 | `-` | `file_selector-v1.1.0-ohos-1.0.1` | `br_file_selector-v1.1.0_ohos` |
| 3.35 | `-` | `file_selector-v1.1.0-ohos-1.0.1` | `br_file_selector-v1.1.0_ohos` |
| 3.27 | `file_selector-v1.0.3-ohos-1.0.0` | `file_selector-v1.0.3-ohos-1.0.1` | `br_file_selector-v1.0.3_ohos` |
| 3.22 | `file_selector-v1.0.3-ohos-1.0.0` | `file_selector-v1.0.3-ohos-1.0.1` | `br_file_selector-v1.0.3_ohos` |
| 3.7 | `file_selector-v1.0.1-ohos-1.0.0` | `file_selector-v1.0.1-ohos-1.0.1` | `master` |

<!-- tabs:end -->

### 1.2 Usage Example

For usage examples, see [ohos/example](./example)

## 2. Constraints and Limitations

### 2.1 Compatibility

Tested and passed on the following versions

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 Permission Requirements

Some of the following permissions require the `system_basic` privilege level, while the default application privilege level is `normal`, which can only use `normal`-level permissions. Therefore, you may encounter error **9568289** when installing the HAP package. Please refer to the [documentation](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) to change the application level to `system_basic`.

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
      "value": "use network"
    },
  ]
}
```

## 3. API

> [!TIP] The "ohos Support" column marked yes indicates that the ohos platform supports this property; no means not supported; partially means partially supported. The usage is cross-platform consistent, with effects benchmarked against iOS or Android.

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| openFile({List<[XTypeGroup](#XTypeGroup)>? acceptedTypeGroups, String? initialDirectory, String? confirmButtonText,})                                           | Future<XFile?> | Opens a file dialog for loading a file and returns the file selected by the user.                  | function | yes          |
| openFiles({List<[XTypeGroup](#XTypeGroup)>? acceptedTypeGroups, String? initialDirectory, String? confirmButtonText,})                                           | Future<List<XFile>> | Opens a file dialog for loading multiple files and returns the list of files selected by the user.                  | function | yes          |
| getDirectoryPath({String? initialDirectory, String? confirmButtonText,})                                           | Future<String?> | Opens a file dialog to select a directory and returns the selected directory path.                  | function | yes          |

### Parameters

| Name               | Description                                                                                                                                                                         | Type                        | ohos Support |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-------------------|
| acceptedTypeGroups  | The list of file type groups that can be selected in the dialog, displayed depending on the platform.                                                                                                                                 | List<[XTypeGroup](#XTypeGroup)>?               | yes               |
| initialDirectory  | The full path of the directory to display when the dialog opens. If not provided, the platform will choose an initial location.                                                                                                                                | String?               | yes               |
| confirmButtonText  | The text on the dialog's confirm button. If not provided, the default operating system label (e.g., "Open") will be used.                                                                                                                                 | String?               | yes               |

### XTypeGroup

| Name               | Description                                                                                                                                                                         | Type                        | ohos Support |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|-------------------|
| label  | The "name" or reference for this type group.                                                                                                                                 | String?               | yes               |
| extensions  | The file extensions for this group.                                                                                                                                 | List<String>?               | yes               |
| mimeTypes  | The MIME types for this group.                                                                                                                                 | List<String>?               | yes               |
| uniformTypeIdentifiers  | The uniform type identifiers for this group.                                                                                                                                 | List<String>?               | yes               |
| webWildCards  | The web wildcards for this group (e.g., image/*, video/*).                                                                                                                                 | List<String>?               | yes               |

## 4. Known Issues

## 5. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/file_selector/file_selector_ohos/LICENSE). Feel free to use it and contribute to open source.

> Template version: v0.0.1
