<p align="center">
  <h1 align="center"> <code>local_auth</code> </h1>
</p>

本项目基于 [local_auth@3.0.2](https://pub.dev/packages/local_auth/versions/3.0.2) 开发。

## 简介

`local_auth` 是一个用于本地身份认证的 Flutter 插件。这个 OpenHarmony 适配实现提供设备能力检测、已注册生物特征查询、身份认证和取消认证能力，并支持自定义 OHOS 侧提示文案。

## 下载安装

进入工程目录并在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  local_auth:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/local_auth/local_auth
      ref: local_auth-v3.0.2-ohos-1.0.0
```

执行命令

```bash
flutter pub get
```
### TAG 版本对应表

| Flutter 框架版本 | TAG 名称 | 分支名 |
| --- | --- | --- |
| 3.44 | local_auth-v3.0.2-ohos-1.0.0 | oh-3.44.9 |

## 约束与限制

### 兼容性

在以下版本中已验证通过：

1. Flutter: 3.44.9+ohos-0.0.1-canary1; SDK: 6.1.0(23); IDE: DevEco Studio 26.0.0 Beta2; ROM: 6.23.0.100 SP6;

### 权限要求

本插件需要申请 `ohos.permission.ACCESS_BIOMETRIC` 权限。

打开 `entry/src/main/module.json5`，添加：

```json
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

打开 `entry/src/main/resources/base/element/string.json`，添加：

```json
{
  "string": [
    {
      "name": "EntryAbility_accessBiometricReason",
      "value": "Verify User"
    }
  ]
}
```

## 使用示例

### 认证与取消认证

```dart
import 'package:flutter/material.dart';
import 'package:local_auth_ohos/local_auth_ohos.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

void main() {
  runApp(const LocalAuthDemoApp());
}

class LocalAuthDemoApp extends StatelessWidget {
  const LocalAuthDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LocalAuthDemoPage());
  }
}

class LocalAuthDemoPage extends StatefulWidget {
  const LocalAuthDemoPage({super.key});

  @override
  State<LocalAuthDemoPage> createState() => _LocalAuthDemoPageState();
}

class _LocalAuthDemoPageState extends State<LocalAuthDemoPage> {
  final LocalAuthPlatform _localAuth = LocalAuthPlatform.instance;
  String _status = '未认证';

  Future<void> _authenticate() async {
    final bool authenticated = await _localAuth.authenticate(
      // 向用户展示的用途说明文案，不能为空。
      localizedReason: '请完成身份验证',
      // 鸿蒙专属弹窗文案集合。`const OhosAuthMessages()` 使用内置英文默认值；
      // 如需自定义文案，参见下方 OhosAuthMessages 属性表。
      authMessages: <AuthMessages>[
        const OhosAuthMessages(),
      ],
      options: const AuthenticationOptions(
        stickyAuth: true,        // 应用切后台再回前台后，是否继续认证流程。
        biometricOnly: true,     // 仅使用生物识别，禁用 PIN/密码等设备凭据回退。
        sensitiveTransaction: true, // 是否启用平台特定的额外安全确认。
      ),
    );

    setState(() {
      _status = authenticated ? '认证成功' : '认证失败';
    });
  }

  Future<void> _cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('local_auth 示例')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_status),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('开始认证'),
            ),
            ElevatedButton(
              onPressed: _cancelAuthentication,
              child: const Text('取消认证'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 检查设备能力与已注册的生物识别

`isDeviceSupported()`、`deviceSupportsBiometrics()` 和 `getEnrolledBiometrics()` 用于在进行认证前检测设备能力，也常用于适配 UI（例如在没有生物识别硬件的设备上隐藏生物识别登录按钮）。

```dart
final LocalAuthPlatform _localAuth = LocalAuthPlatform.instance;

// 设备是否能够运行本地认证流程
//（生物识别或 PIN 等设备凭据）。
final bool isSupported = await _localAuth.isDeviceSupported();

// 设备是否具备任何生物识别硬件（与是否已注册生物识别无关）。
final bool hasBiometricHardware = await _localAuth.deviceSupportsBiometrics();

// 设备上实际已注册的生物识别类型，例如
// [BiometricType.fingerprint, BiometricType.face]。
// OHOS 端当前仅返回 face 和 fingerprint。
final List<BiometricType> enrolledBiometrics =
    await _localAuth.getEnrolledBiometrics();
```

### 展示敏感内容前先认证

常见做法是用 `authenticate()` 校验用户身份后再展示受保护的内容。可结合能力检测，在设备无法认证时给出明确提示。

```dart
Future<void> guardSensitiveAction() async {
  final bool canAuthenticate = await _localAuth.isDeviceSupported();
  if (!canAuthenticate) {
    // 设备没有生物识别硬件，也没有设置设备凭据。
    return;
  }

  final bool authenticated = await _localAuth.authenticate(
    localizedReason: '请认证以查看敏感内容',
    // 鸿蒙专属文案集合；用 AuthMessages 迭代器包裹以兼容多平台。
    authMessages: const <AuthMessages>[OhosAuthMessages()],
    options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
  );

  if (authenticated) {
    // 展示受保护的内容。
  }
}
```

### 取消进行中的认证

`stopAuthentication()` 用于取消当前显示在屏幕上的生物识别弹窗。仅当认证正在进行且被成功取消时返回 `true`。

```dart
final bool cancelled = await _localAuth.stopAuthentication();
```

## 使用说明

`deviceSupportsBiometrics()` 用于检查设备是否具备生物识别硬件；`isDeviceSupported()` 用于检查设备是否支持本地认证流程；`getEnrolledBiometrics()` 用于获取设备上已注册的生物识别类型。

`authenticate()` 需要传入非空的 `localizedReason`，建议同时传入 `OhosAuthMessages()`。当需要仅使用生物识别时，可以将 `AuthenticationOptions.biometricOnly` 设为 `true`；如需在应用切到后台后继续保持认证状态，可以将 `stickyAuth` 设为 `true`。

`stopAuthentication()` 可用于取消当前正在进行的认证。

> `getEnrolledBiometrics()` 在 OHOS 端当前仅返回 `face` 和 `fingerprint`。`PIN` 属于认证方式配置，不会作为生物识别类型返回。

如需自定义 OHOS 侧弹窗文案，可以使用 `OhosAuthMessages`，其中 `authType` 可取 `FACE`、`FINGERPRINT` 或 `PIN`。其他字段用于自定义提示语、按钮文案和设置引导文案。

## 接口说明

## API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性，no 则表示不支持。使用方法跨平台一致，效果对标 IOS 或 Android 的效果。

| 名称                     | 类型     | 参数类型 | 返回值                      | OHOS 平台支持 | 描述                    |
| ------------------------ | -------- | -------- | --------------------------- | ------------- | ----------------------- |
| registerWith             | 方法 | 无       | void                        | yes           | 将 `LocalAuthOhos` 注册为 `LocalAuthPlatform` 的平台实现（插件注册阶段自动调用）。 |
| deviceSupportsBiometrics | 方法 | 无       | Future<bool>                | yes           | 检查是否支持生物识别硬件 |
| isDeviceSupported        | 方法 | 无       | Future<bool>                | yes           | 检查是否支持本地认证     |
| getEnrolledBiometrics    | 方法 | 无       | Future<List<BiometricType>> | yes           | 获取设备上已注册的生物识别类型 |
| authenticate             | 方法 | localizedReason: String, authMessages: Iterable<AuthMessages>, options: AuthenticationOptions | Future<bool> | yes           | 执行身份验证             |
| stopAuthentication       | 方法 | 无       | Future<bool>                | yes           | 取消当前认证             |

`authenticate` 参数说明：

| 参数 | 类型 | 是否必填 | 说明 |
| ---- | ---- | -------- | ---- |
| localizedReason | String | 是 | 认证时向用户展示的用途说明文案，不能为空。 |
| authMessages | Iterable<AuthMessages> | 是 | 本地化的弹窗文案集合。传入 `OhosAuthMessages()` 可自定义 OHOS 端弹窗文案。 |
| options | AuthenticationOptions | 否（有默认值） | 认证选项，如 `biometricOnly`、`stickyAuth`、`sensitiveTransaction`。 |

### BiometricType

| 名称        | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述     |
| ----------- | ---- | -------- | ------ | ------------- | -------- |
| face        | 属性 | enum       | 无     | yes           | 面容识别 |
| fingerprint | 属性 | enum       | 无     | yes           | 指纹识别 |

### AuthenticationOptions

| 名称 | 类型 | 参数类型 | 返回值 | 默认值 | OHOS 平台支持 | 描述 |
| ---- | ---- | -------- | ------ | ------ | ------------- | ---- |
| biometricOnly | 属性 | bool | 无 | false | yes | 为 true 时仅提供生物识别认证，禁用 PIN/密码等设备凭据。 |
| stickyAuth | 属性 | bool | 无 | false | yes | 应用切到后台再回到前台后，是否继续认证流程。 |
| useErrorDialogs | 属性 | bool | 无 | true | no | local_auth 3.x 起已废弃，OHOS 端不使用（恒为 false）。仅为向后兼容保留。 |

> 在 OHOS 端，`stickyAuth` 会被接收并可观测，但由于 `userAuth` 安全组件由系统托管，认证在应用临时切后台时由系统层维持，因此不会手动重启认证流程。`useErrorDialogs` 是遗留字段，仅为向后兼容保留，OHOS 端不使用。

### OhosAuthMessages

> 以下属性均为可空的 `String?`。当属性为 `null` 时，使用对应的默认值。默认值为系统内置的**英文文案**（与 OHOS 系统弹窗实际显示一致）；如需中文显示，请将对应属性显式设置为中文文案。`authType` 用于选择下发给 OHOS 弹窗的认证类型，其余字段用于自定义提示语、按钮文案和引导文案。

| 名称 | 类型 | 默认值（英文系统文案） | 默认值中文释义 | 描述 |
| ---- | ---- | ---------------------- | -------------- | ---- |
| biometricHint | String? | `'Verify identity'` | 验证身份 | 提示用户如何进行生物识别认证的文案。 |
| biometricNotRecognized | String? | `'Not recognized. Try again.'` | 无法识别，请重试 | 生物识别认证失败时显示的文案。 |
| biometricRequiredTitle | String? | `'Biometric required'` | 需要生物识别 | 用户未设置生物识别时显示的标题。 |
| biometricSuccess | String? | `'Success'` | 成功 | 认证成功时显示的文案。 |
| cancelButton | String? | `'Cancel'` | 取消 | 用户退出认证弹窗的按钮文案。 |
| deviceCredentialsRequiredTitle | String? | `'Device credentials required'` | 需要设备凭据 | 设备凭据未设置时显示的标题。 |
| deviceCredentialsSetupDescription | String? | `'Device credentials required'` | 需要设备凭据 | 引导用户设置设备凭据的描述文案。 |
| goToSettingsButton | String? | `'Go to settings'` | 前往设置 | 跳转设置页的按钮文案。 |
| goToSettingsDescription | String? | `'Biometric authentication is not set up on your device. Go to "Settings > Security" to add biometric authentication.'` | 您的设备未设置生物识别，请前往“设置 > 安全”添加生物识别。 | 引导用户前往设置页配置生物识别的描述文案。 |
| signInTitle | String? | `'Authentication required'` | 需要认证 | 提示用户需要认证才能继续的标题。 |
| authType | String? | `''`（空） | （空） | 选择使用的生物识别类型：`FACE`、`FINGERPRINT` 或 `PIN`。留空或未知值时回退为所有受支持类型。 |
| args | getter | — | — | 返回解析后的 OHOS 弹窗文案 `Map<String, String>`（每个属性值，为 `null` 时取默认值），用于通过 method channel 将本地化文案下发到 OHOS 侧。 |

## 遗留问题

无

## 其他

无

## 目录结构

```text
local_auth_ohos/
├─ lib/
│  ├─ local_auth_ohos.dart
│  └─ types/
│     ├─ auth_messages_ohos.dart
│     └─ ohos_auth_error_code.dart
├─ ohos/
│  ├─ index.ets
│  └─ src/main/ets/io/flutter/plugins/localauth/
├─ example/
│  ├─ lib/main.dart
│  └─ ohos/
├─ test/
│  └─ local_auth_test.dart
├─ README_CN.md
├─ README.md
└─ pubspec.yaml
```

## 贡献代码

欢迎通过 GitCode 仓库提交问题反馈或改进建议。提交代码前，请先确认改动不会改变上述公开 API 的行为，并保持中文、英文文档内容一致。

## 开源协议

本项目基于 [BSD 3-Clause License](LICENSE) 开源。
