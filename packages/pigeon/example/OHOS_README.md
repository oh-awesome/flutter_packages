# Pigeon OHOS / ArkTS Example

This document describes how the [example app](./app) integrates Pigeon-generated ArkTS code on OpenHarmony.

## Prerequisites

- Flutter OHOS SDK (see [README.en.md](../README.en.md) §2.1).
- DevEco Studio with matching OpenHarmony SDK.
- `pigeon` from this repository (`oh-3.44.9-dev`).

## Generate ArkTS code

From `example/app`:

```bash
dart run pigeon --input pigeons/messages.dart \
  --dart_out lib/src/messages.g.dart \
  --arkts_out ohos/entry/src/main/ets/plugins/Messages.ets \
  --dart_package_name pigeon_example_package
```

Additional pigeon inputs in this example:

| Input | ArkTS output |
| ----- | ------------ |
| `lib/pigeonTest.dart` | `ohos/entry/src/main/ets/plugins/PigeonTest.ets` |
| `pigeons/event_channel_messages.dart` | `ohos/entry/src/main/ets/plugins/EventChannelMessages.ets` |

## Host plugin structure

| File | Role |
| ---- | ---- |
| `MessagePlugin.ets` | Registers `ExampleHostApi`, EventChannel, and ProxyApi demo; **reference lifecycle cleanup** in `onDetachedFromEngine` |
| `DemoHostApiImpl.ets` | Echo implementations for type-roundtrip tests |
| `DemoProxyApiImpl.ets` | ProxyApi registrar and sample host objects |

## Lifecycle checklist (memory safety)

In `onDetachedFromEngine`:

1. Stop in-flight work (e.g. event timers).
2. `ExampleHostApi.setup(messenger, null)` and `DemoHostApi.setup(messenger, null)`.
3. `proxyRegistrar.tearDown()` then set registrar to `null`.
4. `eventChannel.setStreamHandler(null)`.

## Run the example

1. `flutter pub get` in `example/app`.
2. Regenerate pigeon outputs if IDL changed (see **Generate ArkTS code** above).
3. Open `example/app/ohos` in **DevEco Studio** (File → Open → select the `ohos` folder).
4. In DevEco: **File → Project Structure** → confirm SDK matches [README.en.md](../README.en.md) §2.1.
5. Connect a HarmonyOS device or start an emulator, then **Run** the `entry` module.
6. Optional CLI: from `example/app`, `flutter build hap` (requires Flutter OHOS toolchain on `PATH`).

## Troubleshooting

- **Codec / channel mismatch**: ensure `dart_package_name` matches `pubspec.yaml` `name`.
- **Plugin not registered**: check `EntryAbility` / `GeneratedPluginRegistrant` and `MessagePlugin.onAttachedToEngine`.
- **Memory warnings in review**: follow the lifecycle checklist above; detach must null out APIs and `setStreamHandler(null)`.
