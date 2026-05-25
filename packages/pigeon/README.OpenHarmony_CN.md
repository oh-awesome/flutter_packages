# `pigeon`

本项目基于 [pigeon@26.3.4](https://pub.dev/packages/pigeon/versions/26.3.4) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

#### pubspec.yaml

```yaml

dependencies:
  pigeon:
    git: 
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/pigeon"
      ref: "br_pigeon-v26.3.4_ohos"

```

执行命令

```bash
flutter pub get
```

### 1.2 使用案例

使用案例详见 [example](./example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter version 3.41.10-ohos-0.0.1; SDK: 6.0.0.47 (API Version 20 Release); IDE: DevEco Studio: 6.0.0.858; ROM: 6.0.0.125 SP8;

## 3. API

> [!TIP] "Pigeon"是一个代码生成工具，通过终端执行命令调用，不涉及API

## 4. 注解

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该注解；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。


| Name          | Description                                      | Type       | ohos Support |
| ------------- | ------------------------------------------------ | ---------- | ------------ |
| @HostApi()    | 使用 @HostApi() 注解定义接口，这些接口由原生平台实现，供 Flutter 调用    | annotation | yes          |
| @FlutterApi() | 使用 @FlutterApi() 注解定义接口，这些接口由 Flutter 实现，供原生平台调用 | annotation | yes          |


## 5. 命令

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该命令；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

使用：`flutter pub run pigeon --input <pigeon path> --dart_out<dart path> [option]*`


| Command                       | Description                   | ohos Support |
| ----------------------------- | ----------------------------- | ------------ |
| --input                       | 指定输入的 Dart 文件路径，该文件中定义了通信接口   | yes          |
| --dart_out                    | 指定生成的 Dart 文件的输出路径            | yes          |
| --objc_header_out <iOS头文件路径>  | 指定生成的 iOS 头文件(".h")路径         | yes          |
| --objc_source_out <iOS实现文件路径> | 指定生成的 iOS 源文件(".m")路径         | yes          |
| --java_out <Android Java文件路径> | 指定生成的 Android Java 文件路径       | yes          |
| --java_package <Android包名>    | 指定生成的 Android Java 文件包名       | yes          |
| --arkts_out <ArkTS文件路径>       | 指定生成的鸿蒙 ArkTS 文件路径            | yes          |
| --kotlin_out <Kotlin输出文件路径>   | 指定生成的 Android Kotlin 文件路径     | yes          |
| --swift_out <Swift输出文件路径>     | 指定生成的 macOS swift 文件路径        | yes          |
| --cpp_header_out <C++头文件路径>   | 指定生成的 Windows 头文件(".h")文件路径   | yes          |
| --cpp_source_out <C++实现文件路径>  | 指定生成的 Windows 源文件(".cpp")文件路径 | yes          |


## 6. 遗留问题

## 7. 其他

Pigeon **ArkTS（OHOS）** 宿主生成结果与典型 **Android（Kotlin）、iOS/macOS（Swift）** 生成路径相比，至少在下列几项上容易存在能力或脚手架程度上的差异；集成时请按业务逐项核对生成的 ArkTS / Kotlin（或 Swift）源码。


| 序号  | 能力项                                 | OHOS ArkTS 与 Kotlin / Swift（参考生成侧）的差异要点                                                                                                                                                |
| --- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `@TaskQueue` / `TaskQueueType`      | Kotlin 等可将 **`TaskQueue`** 与 **`BasicMessageChannel`** 构造函数绑定。**`flutter_ohos`** 当前的 **`BasicMessageChannel` 一般为三参数**（`binaryMessenger`、频道名、`codec`），生成器通常**无法像 Android 一样传入第四个队列参数**。 |
| 2   | `@EventChannelApi`                  | Kotlin / Swift 侧可生成 **`EventChannel` / `StreamHandler`** 等与 IDL 配套的一整套宿主代码。**`ArkTSGenerator`** 对部分场景仍可能没有与 Kotlin 同等程度的端到端自动生成；宿主侧常需额外编写 **`EventChannel`** 注册、生命周期与安全卸载等与插件入口的粘合代码。  |
| 3   | **枚举（enum）的伴侣类包装**                 | 除 `export enum` 外，生成器还会为每个 Pigeon 枚举生成 **`<枚举名>Enum` 伴侣类**（如携带 `index` 等），在 **`toList` / `fromList` 与 `PigeonCodec`** 中通过 **`new <枚举名>Enum(...)` 包装** 参与编解码，以契合 `StandardMessageCodec` 对自定义类型的传递。Kotlin / Swift 侧生成物通常更直接地使用 **语言原生 enum**，**形态与手写习惯与 ArkTS 不一致**；宿主侧若混用「裸枚举值」与「包装实例」易导致编解码失败，须按生成代码的 getter/setter 与 codec 分支使用。 |
| 4   | **`@ProxyApi` 进阶能力**（继承、弱引用 GC 语义等） | Kotlin 侧的 ProxyApi **功能面更宽**。OHOS 路线当前多落在 MVP：例如 **`InstanceManager` 常为强引用模型**，与 JVM 侧的弱引用回收路径语义不一定一致；IDL 中出现多级继承、**`superClass`** 等特点时更需在 Kotlin 与本仓库 ArkTS 生成物两边分别验证。                |
| 5   | **`sealed` 数据类继承**                  | Kotlin / Swift 普遍支持受限的 sealed 父子类建模与生成。OHOS ArkTS 对「任意 HostApi 或数据结构里的 sealed 继承树」的生成范围可能不完整；使用前应对同一份 pigeon 输出的 Kotlin（或 Swift）与 ArkTS 文件都做编译与联调测试。                                   |


## 8. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/br_pigeon-v26.3.4_ohos/packages/pigeon/LICENSE) ，请自由地享受和参与开源。

> 模板版本: v0.0.1

