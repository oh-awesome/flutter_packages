<p align="center">
  <h1 align="center"> <code>shared_preferences</code> </h1>
</p>

This project is based on [shared_preferences@2.3.2](https://pub.dev/packages/shared_preferences/versions/2.3.2).

## 1. Installation & Usage

### 1.1 Installation

In your project directory, add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  shared_preferences:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/shared_preferences/shared_preferences
      # ref: shared_preferences-v2.3.2-ohos-1.0.1
      ref: TAG  #   Select a TAG according to the TAG version table below
...
```

Run the command

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG Version Table**

| Flutter Version | TAG1 | TAG2 | Branch |
| :--- | :--- | :--- | :--- |
| 3.41 | `shared_preferences-v2.5.4-ohos-1.0.0` | `shared_preferences-v2.5.4-ohos-1.0.1` | `br_shared_preferences-v2.5.4_ohos` |
| 3.35 | `shared_preferences-v2.5.4-ohos-1.0.0` | `shared_preferences-v2.5.4-ohos-1.0.1` | `br_shared_preferences-v2.5.4_ohos` |
| 3.27 | `shared_preferences-v2.5.3-ohos-1.0.0` | `shared_preferences-v2.5.3-ohos-1.0.1` | `br_shared_preferences-v2.5.3_ohos` |
| 3.22 | `shared_preferences-v2.3.2-ohos-1.0.0` | `shared_preferences-v2.3.2-ohos-1.0.1` | `br_shared_preferences-v2.3.2_ohos` |
| 3.7 | `shared_preferences-v2.2.2-ohos-1.0.0` | `shared_preferences-v2.2.2-ohos-1.0.1` | `master` |

## 1.2 Example

For usage examples, see [ohos/example](./example/).

## 2. Constraints & Limitations

### 2.1 Compatibility

Tested with the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] An "ohos Support" value of `yes` means the property is supported on the ohos platform; `no` means not supported; `partially` means partially supported. Usage is cross-platform consistent, and the behavior is aligned with iOS or Android.

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| setInt(String key, int value)                                | Future<bool>                                          | Associates an int value with the specified key.      | function | yes          |
| setDouble(String key, double value)                          | Future<bool>                                          | Associates a double value with the specified key.     | function | yes          |
| setBool(String key, bool value)                              | Future<bool>                                          | Associates a bool value with the specified key.        | function | yes          |
| setString(String key, String value)                          | Future<bool>                                          | Associates a String value with the specified key.     | function | yes          |
| setStringList(String key, List<String> value)                | Future<bool>                                          | Associates a list of strings with the specified key. | function | yes          |
| getInt(String key)                                           | int?                                                  | Reads the int value of the specified key. | function | yes          |
| getDouble(String key)                                        | double?                                               | Reads the double value of the specified key.   | function | yes          |
| getBool(String key)                                          | bool?                                                 | Reads the bool value of the specified key.      | function | yes          |
| getString(String key)                                        | String?                                               | Reads the String value of the specified key.     | function | yes          |
| getStringList(String key)                                    | List<String>?                                         | Reads the list of strings of the specified key. | function | yes          |
| remove(String key)                                           | Future<bool>                                          | Removes the specified key.      | function | yes          |
| clear()                                                      | Future<bool>                                          | Clears all preferences.           | function | yes          |
| containsKey(String key)                                      | bool                                                  | Checks whether the specified key is contained.      | function | yes          |
| reload()                                                     | Future<void>                                          | Reloads the preferences.    | function | yes          |

## 4. Known Issues

## 5. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/shared_preferences/shared_preferences/LICENSE). Feel free to use and contribute.

> Template version: v0.0.1
