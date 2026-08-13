# quick_actions_ohos

This project is based on [quick_actions](https://pub.dev/packages/quick_actions).

## Introduction

quick_actions_ohos is the OpenHarmony (OHOS) implementation of `quick_actions`, bringing home-screen Quick Actions to Flutter apps. A long-press on the app icon reveals preset shortcuts; tapping one passes the corresponding action back to Flutter through launch parameters, so the app can deep-link to a target page or feature in one step.<br/>

On OHOS, home-screen shortcuts are configured statically (declared in `shortcuts_config.json`). This plugin is responsible for setting/clearing shortcut items (it only maintains plugin-side state) and for dispatching the tapped action back to Dart.

## Installation

Add the following dependency to pubspec.yaml in your project directory:

```yaml
dependencies:
  quick_actions_ohos:
    git: 
      url: https://gitcode.com/openharmony-tpc/flutter_packages/tree/master/packages/quick_actions
      ref: TAG # Select a TAG from the TAG version mapping table below
```

Run the command

```bash
flutter pub get
```

> TAG naming rule: `original-version-ohos-version-betax`. Changes between TAGs are documented in CHANGELOG.OpenHarmony.md.

| Flutter framework version | TAG name | Branch |
| ------------------------- | -------- | ------ |
| 3.22                      | 1.0.0-ohos-1.0.0 | br_3.35 |
| 3.27                      | 1.0.0-ohos-1.0.0 | br_3.35 |
| 3.35                      | 1.0.0-ohos-1.0.0 | br_3.35 |

> No TAG is provided for Flutter 3.7; the 3.7 framework is not supported.

## Constraints

### Compatibility

Tested and passed on the following versions:

1. Flutter: 3.22.0-ohos; SDK: 5.0.5(17); IDE: DevEco Studio: 5.1.0.828; ROM: 6.0.0.120 SP8;
2. Flutter: oh-3.27.4-dev; SDK: 5.0.5(17); IDE: DevEco Studio: 5.1.0.828; ROM: 6.0.0.120 SP8;
3. Flutter: 3.35.7-ohos-0.0.1; SDK: 5.0.5(17); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### Permission Requirements

None. This plugin does not touch sensitive capabilities such as networking or the file system, so no extra permissions are required in `module.json5`.

## Usage Example

Using quick_actions_ohos involves three steps: register a callback, set shortcut items, and dispatch the action on the native side. The following snippet shows the simplest usage:<br/>

```dart
import 'package:quick_actions_ohos/quick_actions_ohos.dart';

final QuickActionsOhos quickActions = QuickActionsOhos();

Future<void> initQuickActions() async {
  // Register the shortcut-action callback, fired when the user taps a home-screen shortcut
  await quickActions.initialize((String shortcutType) {
    // Navigate to the page identified by shortcutType
  });

  // On OHOS this only maintains plugin-side state; actual shortcuts must be declared in shortcuts_config.json
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

For the full example, see [example/lib/main.dart](example/lib/main.dart).

## Usage

### 1. Register the shortcut-action callback (initialize)

Call `initialize` to register a callback and, at the same time, query whether this launch was triggered by a shortcut. This is the first method to call.

```dart
await quickActions.initialize((String shortcutType) {
  // shortcutType corresponds to the type field of ShortcutItem
});
```

> `initialize` internally calls `getLaunchAction` to query the cold-start action. If the launch carries a shortcut action, the callback is fired immediately.

### 2. Set shortcut items (setShortcutItems)

```dart
await quickActions.setShortcutItems(<ShortcutItem>[
  const ShortcutItem(
    type: 'action_one',       // must match the flutter_quick_action value in shortcuts_config.json
    localizedTitle: 'Action one',
    icon: 'ic_shortcut',      // native resource name under resources/base/media/ (no extension)
  ),
]);
```

> On OHOS, `setShortcutItems` only maintains plugin-side state (it does not call a system API to register). The shortcuts that actually appear on the home screen must be declared statically in `shortcuts_config.json`; keep the `type` values consistent on both sides.

### 3. Clear shortcut items (clearShortcutItems)

```dart
await quickActions.clearShortcutItems();
```

> This method only clears the shortcut items kept in plugin-side state; it does not affect the shortcuts declared statically in `shortcuts_config.json`, nor the pending launch action (aligned with Android/iOS, where clearing shortcuts does not touch the launch action).

### 4. Native integration (EntryAbility)

On OHOS, tapping a home-screen shortcut launches the Ability with the action carried in Want parameters. Extract the action in `EntryAbility` and forward it to the plugin so it is dispatched to Dart:

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

  // The Want parameters carry the shortcut type under the EXTRA_ACTION key (flutter_quick_action)
  private dispatchShortcut(want: Want): void {
    const action = want.parameters?.[EXTRA_ACTION] as string | undefined;
    if (action && action.length > 0) {
      QuickActionsPlugin.dispatchShortcutAction(action);
    }
  }
}
```

### 5. Static shortcut configuration (shortcuts_config.json)

Declare each shortcut in `entry/src/main/resources/base/profile/shortcuts_config.json`:

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

Reference it from the target ability `metadata` in `entry/src/main/module.json5`:

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

> `wants[0].parameters` must use the key `flutter_quick_action` (i.e. `EXTRA_ACTION`), and its value must match the Dart-side `ShortcutItem.type`. A home-screen shortcut tap reaches the correct handler through this mapping.

## Interface

### Constants

| Name | Type | Parameter type | Return value | OHOS support | Description |
| ---- | ---- | --------------- | ------------ | ------------ | ----------- |
| EXTRA_ACTION | constant | / | string | yes | Native-layer exported constant, value `flutter_quick_action`, used to pass the shortcut action type in Want parameters |

### Properties

| Name | Type | Parameter type | Return value | OHOS support | Description |
| ---- | ---- | --------------- | ------------ | ------------ | ----------- |
| ShortcutItem.type | property | / | String | yes | Unique identifier of the shortcut; must match the `flutter_quick_action` value in shortcuts_config.json |
| ShortcutItem.localizedTitle | property | / | String | yes | Localized title of the shortcut |
| ShortcutItem.localizedSubtitle | property | / | String? | partially | Localized subtitle. OHOS does not render subtitles for static shortcuts; the field is preserved only for cross-platform parity (aligned with iOS). Passing it will not raise an error |
| ShortcutItem.icon | property | / | String? | yes | Native resource name (under `resources/base/media/`, no extension), not a Flutter asset |

### API

> [!TIP] A value of "yes" in "OHOS support" means the property is supported; "no" means it is not. Usage is cross-platform consistent, matching the effect of iOS or Android.

#### QuickActionsOhos

| Name | Type | Parameter type | Return value | OHOS support | Description |
| ---- | ---- | --------------- | ------------ | ------------ | ----------- |
| getLaunchAction() | method | / | Future&lt;String?&gt; | yes | Obtains whether this launch was triggered by a shortcut and the triggered action string; called internally by `initialize` |
| setShortcutItems() | method | List&lt;ShortcutItem&gt; items | Future&lt;void&gt; | yes | Sets the shortcut item list. On OHOS it only maintains plugin-side state; actual shortcuts are statically configured |
| clearShortcutItems() | method | / | Future&lt;void&gt; | yes | Clears the shortcut items saved in the plugin (in-memory state only); does not affect the launch action |

> On failure a `PlatformException` is thrown with error codes: `channel-error` (channel not established), `quick_action_getlaunchaction_failure` (get launch action failed), `quick_action_setshortcutitems_failure` (set failed), `quick_action_clearshortcutitems_failure` (clear failed), `quick_action_decodeshortcutitem_failure` (shortcut item message decode failed, e.g. malformed wire format).

## Known Issues

- OHOS does not currently support registering or removing system home-screen shortcuts at runtime. `setShortcutItems` and `clearShortcutItems` only maintain plugin-side state (and emit a runtime `console.warn`); system shortcuts must still be declared statically via `shortcuts_config.json`.
- OHOS has no equivalent of Android's `ShortcutManagerCompat.reportShortcutUsed`, so shortcut-usage analytics are not reported.

## Directory Structure

```
|---- directory
|     |---- example        # full example app
|           |---- integration_test  # integration tests
|           |---- lib               # example Dart code
|           |---- ohos              # OHOS project (EntryAbility wiring + shortcuts_config.json)
|           |---- test_driver       # integration test driver
|     |---- lib            # Dart core code
|           |---- src
|           |---- messages.g.dart              # platform-channel message classes (hand-written Pigeon-style)
|           |---- quick_actions_ohos.dart      # main entry file of the library
|     |---- ohos           # OHOS adapter code
|           |---- src/main/ets/QuickActionsPlugin.ets  # native plugin implementation
|           |---- Index.ets                            # OHOS library entry
|     |---- test           # unit test files
|     |---- CHANGELOG.md            # change log
|     |---- README.OpenHarmony.md   # English documentation
|     |---- README.OpenHarmony_CN.md # Chinese documentation
|     |---- README.OpenSource.md    # open-source notice
|     |---- pubspec.yaml            # configuration file
```

## Contributing

If you find any problems while using this library, feel free to open an [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues) . PRs are also very welcome at [pulls](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) .

## License

This project is licensed under [BSD-3-Clause](LICENSE) . Feel free to enjoy and contribute to open source.
