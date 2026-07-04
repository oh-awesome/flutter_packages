<p align="center">
  <h1 align="center"> <code>local_auth</code> </h1>
</p>


This project is developed based on [local_auth@2.2.0](https://pub.dev/packages/local_auth/versions/2.2.0).

## 1. Installation and Usage

### 1.1 Installation

Navigate to your project directory and add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  local_auth:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/local_auth/local_auth
      # ref: local_auth-v2.1.6-ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below
```

Run the command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.7 | `local_auth-v2.1.6-ohos-1.0.0` | `master` |
| 3.22 | `local_auth-v2.3.0-ohos-1.0.0` | `br_local_auth-v2.3.0_ohos` |
| 3.27 | `local_auth-v2.3.0-ohos-1.0.0` | `br_local_auth-v2.3.0_ohos` |
| 3.35 | `local_auth-v3.0.0-ohos-1.0.0` | `br_local_auth-v3.0.0_ohos` |

<!-- tabs:end -->

### 1.2 Usage

For usage examples, see [ohos/example](./example).

## 2. Constraints

### 2.1 Compatibility

Tested and passed on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 Permission Requirements

This plugin requires the `ohos.permission.ACCESS_BIOMETRIC` permission to implement its functionality. Please apply for the permission.

#### 2.2.1 Add permissions in module.json5 under the entry directory

Open `entry/src/main/module.json5` and add:

```diff
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC",
        "reason": "$string:EntryAbility_accessBiometricReason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ]
  }
}
```

#### 2.2.2 Add the reason for requesting the above permission under the entry directory

Open `entry/src/main/resources/base/element/string.json` and add:

```diff
{
  "string": [
    {
      "name": "EntryAbility_accessBiometricReason",
      "value": "Verify User"
    }
  ]
}
```

## 3. API

> [!TIP] A "**ohos Support**" value of **yes** means the property is supported on the ohos platform; **no** means not supported; **partially** means partially supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

| Name                     | Return                      | Description                    | Type     | ohos Support |
| ------------------------ | --------------------------- | ------------------------------ | -------- | ------------ |
| deviceSupportsBiometrics | Future<bool>                | Checks whether biometric hardware is supported.       | function | yes          |
| isDeviceSupported        | Future<bool>                | Checks whether local authentication is supported.           | function | yes          |
| getEnrolledBiometrics    | Future<List<BiometricType>> | Gets the biometric types enrolled on the device. | function | yes          |
| authenticate             | Future<bool>                | Performs authentication.                   | function | yes          |
| stopAuthentication       | Future<bool>                | Cancels the current authentication.                   | function | yes          |

## 4. Properties

> [!TIP] A "**ohos Support**" value of **yes** means the property is supported on the ohos platform; **no** means not supported; **partially** means partially supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

### BiometricType

| Name        | Description | Type | ohos Support |
| ----------- | ----------- | ---- | ------------ |
| face        | Face recognition    | enum | yes          |
| fingerprint | Fingerprint recognition    | enum | yes          |
| weak        | Weak biometrics  | enum | yes          |
| strong      | Strong biometrics  | enum | yes          |

### AuthenticationOptions

| Name            | Description                  | Type | ohos Support |
| --------------- | ---------------------------- | ---- | ------------ |
| biometricOnly   | Whether to use biometrics only           | bool | yes          |
| useErrorDialogs | Whether to use the default error dialog   | bool | yes          |
| stickyAuth      | Whether to maintain authentication state after the app moves to the background | bool | yes          |

## 5. Known Issues

None

## 6. License

This project is licensed under [BSD 3-Clause License](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/local_auth/local_auth_ohos/LICENSE), feel free to use and contribute.
