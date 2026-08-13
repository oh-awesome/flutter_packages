# quick_actions_ohos

本项目基于 [quick_actions](https://pub.dev/packages/quick_actions) 开发。

## 简介

quick_actions_ohos 是 `quick_actions` 的 OpenHarmony（OHOS）平台实现，为 Flutter 应用提供桌面快捷动作（Quick Actions）能力。用户长按应用图标即可看到预设的快捷项，点击后会通过启动参数把对应的 action 回调到 Flutter，实现一步直达指定页面或功能。<br/>

OHOS 桌面快捷项为静态配置（通过 `shortcuts_config.json` 声明），本插件负责快捷项的设置/清空（仅维护插件内状态）以及点击 action 的回调分发。

## 下载安装

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

```yaml
dependencies:
  quick_actions_ohos:
    git: 
      url: https://gitcode.com/openharmony-tpc/flutter_packages/tree/master/packages/quick_actions
      ref: TAG # 根据下方表格选择不同框架适配的TAG版本
```

执行命令

```bash
flutter pub get
```

> TAG 命名规则：`原库版本-ohos-版本号-betax`，不同 TAG 之间的变更详见 CHANGELOG.OpenHarmony.md。

| Flutter 框架版本 | TAG 名称 | 分支名 |
| --------------- | -------- | ------ |
| 3.22            | 1.0.0-ohos-1.0.0| br_3.35 |
| 3.27            | 1.0.0-ohos-1.0.0| br_3.35 |
| 3.35            | 1.0.0-ohos-1.0.0| br_3.35 |

> 本库未提供适配 Flutter 3.7 的 TAG，3.7 框架不支持。

## 约束与限制

### 兼容性

在以下版本中已测试通过：

1. Flutter: 3.22.0-ohos; SDK: 5.0.5(17); IDE: DevEco Studio: 5.1.0.828; ROM: 6.0.0.120 SP8;
2. Flutter: oh-3.27.4-dev; SDK: 5.0.5(17); IDE: DevEco Studio: 5.1.0.828; ROM: 6.0.0.120 SP8;
3. Flutter: 3.35.7-ohos-0.0.1; SDK: 5.0.5(17); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### 权限要求

无。本插件不涉及网络、文件等敏感权限，无需在 `module.json5` 中声明额外权限。

## 使用示例

quick_actions_ohos 的使用分为三步：注册回调、设置快捷项、原生层分发 action。以下片段是最简单的使用方式：<br/>

```dart
import 'package:quick_actions_ohos/quick_actions_ohos.dart';

final QuickActionsOhos quickActions = QuickActionsOhos();

Future<void> initQuickActions() async {
  // 注册快捷动作回调，用户点击桌面快捷项后触发
  await quickActions.initialize((String shortcutType) {
    // 根据 shortcutType 跳转到对应页面
  });

  // 在 OHOS 上仅维护插件内状态，实际快捷项需在 shortcuts_config.json 中静态声明
  await quickActions.setShortcutItems(<ShortcutItem>[
    const ShortcutItem(
      type: 'action_one',
      localizedTitle: 'Action one',
      icon: 'ic_shortcut',
    ),
    const ShortcutItem(
      type: 'action_two',
      localizedTitle: 'Action two',
      icon: 'ic_shortcut',
    ),
  ]);
}
```

完整示例参见 [example/lib/main.dart](example/lib/main.dart)。

## 使用说明

### 1. 注册快捷动作回调（initialize）

调用 `initialize` 注册回调，同时查询本次启动是否由快捷动作触发。该方法是使用插件的第一步。

```dart
await quickActions.initialize((String shortcutType) {
  // shortcutType 对应 ShortcutItem 的 type 字段
});
```

> `initialize` 内部会调用 `getLaunchAction` 查询冷启动 action。若启动时带有快捷项 action，会立即触发回调。

### 2. 设置快捷项（setShortcutItems）

```dart
await quickActions.setShortcutItems(<ShortcutItem>[
  const ShortcutItem(
    type: 'action_one',       // 与 shortcuts_config.json 中的 flutter_quick_action 值一致
    localizedTitle: 'Action one',
    icon: 'ic_shortcut',      // resources/base/media/ 下的原生资源名（不含扩展名）
  ),
]);
```

> 在 OHOS 上，`setShortcutItems` 仅维护插件内状态（不调用系统 API 注册）。实际出现在桌面的快捷项必须通过 `shortcuts_config.json` 静态声明，请保证两边的 `type` 一致。

### 3. 清空快捷项（clearShortcutItems）

```dart
await quickActions.clearShortcutItems();
```

> 该方法仅清空插件内保存的快捷项，不影响 `shortcuts_config.json` 中静态声明的快捷项，也不影响待投递的启动 action（与 Android/iOS 对齐，清空快捷项不触及启动动作）。

### 4. 原生层集成（EntryAbility）

OHOS 桌面快捷项点击会以 Want 参数的形式启动 Ability。需在 `EntryAbility` 中提取 action 并转发给插件分发到 Dart：

```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import QuickActionsPlugin, { EXTRA_ACTION } from 'quick_actions_ohos';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);
    this.dispatchShortcut(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParam);
    this.dispatchShortcut(want);
  }

  // Want 参数中以 EXTRA_ACTION 键（flutter_quick_action）携带快捷项 type
  private dispatchShortcut(want: Want): void {
    const action = want.parameters?.[EXTRA_ACTION] as string | undefined;
    if (action && action.length > 0) {
      QuickActionsPlugin.dispatchShortcutAction(action);
    }
  }
}
```

### 5. 静态快捷项配置（shortcuts_config.json）

在 `entry/src/main/resources/base/profile/shortcuts_config.json` 中声明每个快捷项：

```json5
// resources/base/profile/shortcuts_config.json
{
  "shortcuts": [
    {
      "shortcutId": "action_one",
      "label": "$string:action_one_label",
      "icon": "$media:icon",
      "wants": [
        {
          "bundleName": "com.example.my_app",
          "moduleName": "entry",
          "abilityName": "EntryAbility",
          "parameters": { "flutter_quick_action": "action_one" }
        }
      ]
    }
  ]
}
```

在 `entry/src/main/module.json5` 的目标 ability `metadata` 中引用：

```json5
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "metadata": [
          { "name": "ohos.ability.shortcuts", "resource": "$profile:shortcuts_config" }
        ]
      }
    ]
  }
}
```

> `wants[0].parameters` 必须使用键 `flutter_quick_action`（即 `EXTRA_ACTION`），其值需与 Dart 侧 `ShortcutItem.type` 一致，桌面快捷项点击正是通过此对应关系到达正确处理函数的。

## 接口说明

### 常量

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| ---- | ---- | -------- | ------ | -------------- | ---- |
| EXTRA_ACTION | 常量 | / | string | yes | 原生层导出常量，值为 `flutter_quick_action`，用于 Want 参数中传递快捷动作类型标识 |

### 属性

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| ---- | ---- | -------- | ------ | -------------- | ---- |
| ShortcutItem.type | 属性 | / | String | yes | 快捷项唯一标识符，应与 shortcuts_config.json 中的 `flutter_quick_action` 值一致 |
| ShortcutItem.localizedTitle | 属性 | / | String | yes | 快捷项本地化标题 |
| ShortcutItem.localizedSubtitle | 属性 | / | String? | partially | 本地化副标题。OHOS 静态快捷项不渲染副标题，该字段仅为跨平台一致性保留（与 iOS 对齐），调用方传入不会报错 |
| ShortcutItem.icon | 属性 | / | String? | yes | 原生资源名称（位于 `resources/base/media/` 下，不含扩展名），非 Flutter 资产 |

### API

> [!TIP] "OHOS 平台支持"为 yes 表示支持该属性，no 则表示不支持。使用方法跨平台一致，效果对标 IOS 或 Android 的效果。

#### QuickActionsOhos

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| ---- | ---- | -------- | ------ | -------------- | ---- |
| getLaunchAction() | 方法 | / | Future&lt;String?&gt; | yes | 获取本次启动是否由快捷动作触发及触发的 action 字符串，由 `initialize` 内部调用 |
| setShortcutItems() | 方法 | List&lt;ShortcutItem&gt; items | Future&lt;void&gt; | yes | 设置快捷项列表。在 OHOS 上仅维护插件内状态，实际快捷项为静态配置 |
| clearShortcutItems() | 方法 | / | Future&lt;void&gt; | yes | 清空插件内保存的快捷项（仅清内存状态），不影响启动 action |

> 调用失败时会抛出 `PlatformException`，错误码：`channel-error`（通道未建立）、`quick_action_getlaunchaction_failure`（获取启动 action 失败）、`quick_action_setshortcutitems_failure`（设置失败）、`quick_action_clearshortcutitems_failure`（清空失败）、`quick_action_decodeshortcutitem_failure`（快捷项消息解码失败）。

## 遗留问题

- OHOS 暂不支持运行时动态注册和移除系统桌面快捷项。`setShortcutItems` 与 `clearShortcutItems` 当前仅维护插件内状态（并输出运行时 `console.warn` 警告），系统快捷项仍需通过 `shortcuts_config.json` 静态配置。
- OHOS 没有 Android `ShortcutManagerCompat.reportShortcutUsed` 的等价 API，因此不会上报快捷项使用统计。

## 目录结构

```
|---- 目录
|     |---- example        # 完整示例应用
|           |---- integration_test  # 集成测试
|           |---- lib               # 示例 Dart 代码
|           |---- ohos              # OHOS工程（含 EntryAbility 接线与 shortcuts_config.json）
|           |---- test_driver       # 集成测试驱动
|     |---- lib            # Dart 核心代码
|           |---- src
|           |---- messages.g.dart              # 平台通道消息类（Pigeon 风格手写）
|           |---- quick_actions_ohos.dart      # 库的主入口文件
|     |---- ohos           # OHOS适配代码
|           |---- src/main/ets/QuickActionsPlugin.ets  # 原生插件实现
|           |---- Index.ets                            # OHOS库入口
|     |---- test           # 单元测试文件
|     |---- CHANGELOG.md            # 更新日志
|     |---- README.OpenHarmony.md   # 英文说明文档
|     |---- README.OpenHarmony_CN.md # 中文说明文档
|     |---- README.OpenSource.md    # 开源说明
|     |---- pubspec.yaml            # 配置文件
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues) ，当然，也非常欢迎发 [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) 共建。

## 开源协议

本项目基于 [BSD-3-Clause](LICENSE) ，请自由地享受和参与开源。
