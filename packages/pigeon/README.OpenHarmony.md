

# `pigeon`



This project is based on [pigeon@26.3.4](https://pub.dev/packages/pigeon/versions/26.3.4) 

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml



#### pubspec.yaml

```yaml

dependencies:
  pigeon:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/pigeon"
      ref: "br_pigeon-v26.3.4_ohos"

```

Execute Command

```bash
flutter pub get
```



### 1.2 Usage

For use cases [example](./example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter version 3.41.10-ohos-0.0.1; SDK: 6.0.0.47 (API Version 20 Release); IDE: DevEco Studio: 6.0.0.858; ROM: 6.0.0.125 SP8;

## 3. API

> [!TIP] "Pigeon" is a code generation tool that is invoked by executing commands in the terminal and does not involve any API.

## 4. Annotation

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this annotation; **no** means the opposite; **partially** means some capabilities of this annotation are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.


| Name               | Description                                                                                                               | Type       | ohos Support |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ |
| @HostApi()         | Defines interfaces using the @HostApi() annotation, which are implemented by the native platform and called by Flutter    | annotation | yes          |
| @FlutterApi()      | Defines interfaces using the @FlutterApi() annotation, which are implemented by Flutter and called by the native platform | annotation | yes          |
| @ProxyApi()        | Defines bidirectional object references with `InstanceManager`, weak-ref GC, inheritance, and per-API adapters (see §7). | annotation | partially    |
| @EventChannelApi() | Defines event-stream APIs. ArkTS emits `PigeonStreamHandler`, `PigeonEventSink`, and per-method `*StreamHandler.register(...)` (see §7). | annotation | yes          |
| @TaskQueue()       | `@TaskQueue` is accepted in the IDL; **`flutter_ohos` `BasicMessageChannel` is three arguments only**, so the queue is **not bound** to the channel yet (see §7). | annotation | partially    |


## 5. Command

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this command; **no** means the opposite; **partially** means some capabilities of this command are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

Usage：`flutter pub run pigeon --input <pigeon path> --dart_out<dart path> [option]*`




| Command                                         | Description                                                                  | ohos Support |
| ----------------------------------------------- | ---------------------------------------------------------------------------- | ------------ |
| --input                                         | Specifies the path to the Dart file that defines the communication interface | yes          |
| --dart_out                                      | Specifies the output path for the generated Dart file                        | yes          |
| --objc_header_out                               | Specifies the output path for the generated iOS header(".h") file            | yes          |
| --objc_source_out                               | Specifies the output path for the generated iOS source(".m") file            | yes          |
| --java_out                                      | Specifies the output path for the generated Android Java file                | yes          |
| --java_package                                  | Specifies the package name for the generated Android Java file               | yes          |
| --arkts_out                                     | Specifies the output path for the generated ohos ArkTS file                  | yes          |
| --kotlin_out                                    | Specifies the output path for the generated Android Kotlin file              | yes          |
| --swift_out                                     | Specifies the output path for the generated macOS Swift file                 | yes          |
| --cpp_header_out <C++ header file path>         | Specifies the output path for the generated Windows C++ header(".h") file    | yes          |
| --cpp_source_out <C++ implementation file path> | Specifies the output path for the generated Windows C++ classes(".cpp") file | yes          |


## 6. Known Issues

## 7. **Others**

Section 4 summarizes **annotation-level** OHOS support. The table below lists **codegen and runtime differences** between **OHOS ArkTS** output and typical **Kotlin (Android)** or **Swift** Pigeon generators. Teams should validate generated sources for their own IDLs.


| #   | Capability                                           | Typical difference vs Kotlin/Swift generators                                                                                                                                                                                                                                                                                          |
| --- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `@TaskQueue` / `TaskQueueType` (**partially**)       | Kotlin binds **`TaskQueue`** as the **fourth** `BasicMessageChannel` argument. **`flutter_ohos` currently exposes a three-argument** `BasicMessageChannel` only, so ArkTS generates a **standard 3-arg channel** even when `@TaskQueue(type: TaskQueueType.serialBackgroundThread)` is present. Handler code runs on the default platform thread until `flutter_ohos` adds 4-arg support. |
| 2   | `@EventChannelApi`                                   | ArkTS generates **`PigeonStreamHandler`**, **`PigeonEventSink`**, **`PigeonEventChannelWrapper`**, and per-method **`*StreamHandler.register(binaryMessenger, handler, instanceName?)`** using **`PigeonMethodChannelCodec`**. Host plugins subclass the generated handler and call **`register`** from `onAttachedToEngine`; call **`setStreamHandler(null)`** on detach. |
| 3   | **Enum companion wrapper**                           | Besides `export enum`, the generator also emits a **`<EnumName>Enum` companion class** (for example carrying `index`) for each Pigeon enum. **`toList` / `fromList` and `PigeonCodec`** wrap values with **`new <EnumName>Enum(...)`** for wire transfer via `StandardMessageCodec`. Kotlin/Swift output typically uses **native enums** directly—the **shape and idioms differ from ArkTS**; mixing raw enum values with wrapped instances on the host side often breaks encode/decode—follow the generated getters/setters and codec branches. |
| 4   | `@ProxyApi` (**partially**)                        | **Implemented:** `PigeonInstanceManager` (**WeakRef + FinalizationRegistry** GC), `PigeonProxyApiRegistrar`, `PigeonApi<Name>` adapters, **inheritance/interface** registrar getters, **`List<MyProxyApi>`** typing, codec **`pigeon_newInstance` dispatch** (topological child-before-parent), and instance-ref tag 128. **`minAndroidApi`** is recorded via **`PigeonMinApi.isSatisfied()`** for IDL parity but **not enforced** on HarmonyOS. If a ProxyApi declares **required** Flutter callbacks, Dart may omit the `pigeon_newInstance` handler—validate host-create flows. Host implementation classes should match **`kotlinOptions.fullClassName`** (or the ProxyApi name) for codec `instanceof` dispatch. |
| 5   | `sealed` class hierarchies                           | Kotlin/Swift generators cover curated **sealed subtype** graphs. ArkTS codegen sets **`excludeSealedClasses: true`** in the codec and **may not fully cover arbitrary sealed hierarchies**—always compile and integration-test **`dart run pigeon` output for Kotlin/Swift alongside ArkTS** when `sealed` appears in the pigeon file. |
| 6   | `messageChannelSuffix`                               | ArkTS **`HostApi.setup(..., messageChannelSuffix: '')`** and **`FlutterApi` constructor** accept the same suffix as Dart, appending **`.suffix`** to channel names when non-empty. |
| 7   | Typed data (`Uint8List`, `Float32List`, …)           | `Uint8List`, `Int32List`, `Int64List`, `Float32List`, and `Float64List` map to ArkTS **`number[]`**, not typed arrays such as `Uint8Array`. Kotlin/Swift use platform-native byte/float buffers with richer codec support. |
| 8   | Platform-specific annotations (`@Swift*`, `@Kotlin*`, `@Objc*`, …) | These annotations affect **other** generators only. They are **ignored** for `--arkts_out` output. |


## 8. **License**

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/br_pigeon-v26.3.4_ohos/packages/pigeon/LICENSE).

> Template version: v0.0.1

