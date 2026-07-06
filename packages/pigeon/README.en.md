
<p align="center">
  <h1 align="center"> <code>pigeon</code> </h1>
</p>

This project is developed based on [pigeon@14.0.0](https://pub.dev/packages/pigeon/versions/14.0.0).

## 1. Installation and Usage

### 1.1 Installation

Navigate to your project directory and add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->

#### pubspec.yaml

```yaml

dependencies:
  pigeon:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/pigeon"
      # ref: pigeon-v14.0.0-ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below

```

Run the command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.7 | `pigeon-v14.0.0-ohos-1.0.0` | `master` |
| 3.27 | `pigeon-v25.3.2-ohos-1.0.0` | `br_pigeon-v25.3.2_ohos` |
| 3.35 | `pigeon-v26.1.5-ohos-1.0.0` | `br_pigeon-v26.1.5_ohos` |

<!-- tabs:end -->

### 1.2 Usage

For usage examples, see [ohos/example](example).

## 2. Constraints

### 2.1 Compatibility

Tested and passed on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] "Pigeon" is a code generation tool invoked via terminal commands and does not involve APIs.

## 4. Annotations

> [!TIP] An **ohos Support** value of **yes** means the annotation is supported on the ohos platform; **no** means not supported; **partially** means partially supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

| Name                | Description                                                                                                            | Type       | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------|-------------|-------------------|
| @HostApi()           |   Use the @HostApi() annotation to define interfaces implemented by the native platform for Flutter to call.                                                                       | annotation | yes               |
| @FlutterApi()   |  Use the @FlutterApi() annotation to define interfaces implemented by Flutter for the native platform to call.                                                             | annotation | yes               |
| @ProxyApi() | Defines object proxies that can be passed between Dart and the host. | annotation | no |
| @EventChannelApi() | Defines EventChannel streaming APIs. | annotation | no |

## 5. Commands

> [!TIP] An **ohos Support** value of **yes** means the command is supported on the ohos platform; **no** means not supported; **partially** means partially supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

Usage: `flutter pub run pigeon --input <pigeon path> --dart_out<dart path> [option]*`
>
| Command                       | Description                   | ohos Support |
|-------------------------------|-------------------------------|--------------|
| --input <pigeon path>         | Specifies the path of the input Dart file that defines the communication interfaces.   | yes          |
| --dart_out <dart path>        | Specifies the output path of the generated Dart file.            | yes          |
| --objc_header_out <iOS header path>  | Specifies the path of the generated iOS header file (".h").         | yes          |
| --objc_source_out <iOS implementation path> | Specifies the path of the generated iOS source file (".m").         | yes          |
| --java_out <Android Java path> | Specifies the path of the generated Android Java file.       | yes          |
| --java_package <Android package name>    | Specifies the package name of the generated Android Java file.       | yes          |
| --arkts_out <ArkTS path>       | Specifies the path of the generated HarmonyOS ArkTS file.            |     yes      |
| --kotlin_out <Kotlin output path>   | Specifies the path of the generated Android Kotlin file.     |     yes      |
| --swift_out <Swift output path>     | Specifies the path of the generated macOS Swift file.        |     yes      |
| --cpp_header_out <C++ header path>   | Specifies the path of the generated Windows header file (".h").   |     yes      |
| --cpp_source_out <C++ implementation path>  | Specifies the path of the generated Windows source file (".cpp"). |     yes      |

## 6. Known Issues

- `@TaskQueue` can be declared at the IDL layer, but `BasicMessageChannel` of `flutter_ohos` currently only supports a three-argument constructor and cannot fully bind to background queues (partially).
- `@ProxyApi` / `@EventChannelApi` are not connected to the parser on the pigeon 11.0.1 baseline; generating the corresponding ArkTS code is not supported yet.
## 7. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/pigeon/LICENSE), feel free to use and contribute.



> Template version: v0.0.1
