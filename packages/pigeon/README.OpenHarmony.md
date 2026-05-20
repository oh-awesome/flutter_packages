

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


| Name          | Description                                                                                                               | Type       | ohos Support |
| ------------- | ------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------ |
| @HostApi()    | Defines interfaces using the @HostApi() annotation, which are implemented by the native platform and called by Flutter    | annotation | yes          |
| @FlutterApi() | Defines interfaces using the @FlutterApi() annotation, which are implemented by Flutter and called by the native platform | annotation | yes          |


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

The table below briefly lists common **codegen gaps** between **OHOS ArkTS** output and typical **Kotlin (Android)** or **Swift** Pigeon generators for selected features. Teams should validate generated sources for their own IDLs.


| #   | Capability                                           | Typical difference vs Kotlin/Swift generators                                                                                                                                                                                                                                                                                          |
| --- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6   | `@TaskQueue` / `TaskQueueType`                       | Kotlin binds a `**TaskQueue`** into the `**BasicMessageChannel` constructor**. `**flutter_ohos` commonly exposes `BasicMessageChannel` with three arguments only** (`binaryMessenger`, channel name, `codec`), so generated ArkTS **usually cannot pass the fourth queue argument Android uses**.                                      |
| 7   | `@EventChannelApi`                                   | Kotlin/Swift pipelines can emit a **full EventChannel/stream-handler scaffold** from the IDL. `**ArkTSGenerator` may still fall short of the same fully automated scaffold**—hosts often write **their own `EventChannel` wiring and lifecycle teardown** beside generated types.                                                      |
| 9   | **Advanced** `@ProxyApi` (inheritance, weak refs, …) | Kotlin supports a **broader** Proxy surface. OHOS tends to ship an **MVP** (for example `**InstanceManager` backed by strong references**), whose cleanup semantics **need not match** JVM weak-reference behavior; **nested proxy inheritance (`superClass`, …)** should be validated on **both** Kotlin/Swift **and** ArkTS outputs. |
| 10  | `sealed` class hierarchies                           | Kotlin/Swift generators cover curated **sealed subtype** graphs. ArkTS codegen **may not fully cover arbitrary sealed hierarchies across all IDL usages**—always compile and integrate-test `**dart run pigeon` output for Kotlin/Swift alongside ArkTS** when `sealed` appears in the pigeon file.                                    |


## 8. **License**

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/br_pigeon-v26.3.4_ohos/packages/pigeon/LICENSE).

> Template version: v0.0.1

