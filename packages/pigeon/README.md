# `pigeon`

本项目基于 [pigeon@27.3.1](https://pub.dev/packages/pigeon/versions/27.3.1) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

#### pubspec.yaml

```yaml

dependencies:
  pigeon:
    git: 
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/pigeon"
      ref: "pigeon-v27.3.1-ohos-1.0.0"

```

**TAG 版本对应表**


| Flutter 框架版本 | TAG1                        | TAG2                        | 分支                       |
| ------------ | --------------------------- | --------------------------- | ------------------------ |
| 3.44         | `pigeon-v27.3.1-ohos-1.0.0` | `-`                         | `oh-3.44.9-dev`          |
| 3.41         | `-`                         | `pigeon-v26.3.4-ohos-1.0.0` | `br_pigeon-v26.3.4_ohos` |
| 3.35         | `pigeon-v26.1.5-ohos-1.0.0` | `pigeon-v26.1.5-ohos-1.0.1` | `br_pigeon-v26.1.5_ohos` |
| 3.27         | `pigeon-v25.3.2-ohos-1.0.0` | `pigeon-v25.3.2-ohos-1.0.1` | `br_pigeon-v25.3.2_ohos` |
| 3.22         | `-`                         | `-`                         | `pigeon-v21.2.0`         |
| 3.7          | `pigeon-v14.0.0-ohos-1.0.0` | `pigeon-v14.0.0-ohos-1.0.1` | `master`                 |


执行命令

```bash
flutter pub get
```



### 1.2 使用案例

使用案例详见 [example](./example)。鸿蒙端到端集成说明见 [example/OHOS_README.md](./example/OHOS_README.md)。

## 2. 约束与限制



### 2.1 兼容性

在以下版本中已测试通过

1. Flutter version 3.44.10-ohos-0.0.1-canary1; SDK: 26.0.0 Beta2 (API Version 26.0.0 Beta2); IDE: DevEco Studio: 26.0.0.621; ROM: 6.1.0.135 SP8;



## 3. API

> [!TIP] "Pigeon"是一个代码生成工具，通过终端执行命令调用，不涉及 API



## 4. 注解

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该注解；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。


| Name               | Description                                                                                         | Type       | ohos Support |
| ------------------ | --------------------------------------------------------------------------------------------------- | ---------- | ------------ |
| @HostApi()         | 使用 @HostApi() 注解定义接口，这些接口由原生平台实现，供 Flutter 调用                                                       | annotation | yes          |
| @FlutterApi()      | 使用 @FlutterApi() 注解定义接口，这些接口由 Flutter 实现，供原生平台调用                                                    | annotation | yes          |
| @ProxyApi()        | 定义基于 `InstanceManager`、弱引用 GC、继承与适配器的双向对象引用（详见 §7）。                                                 | annotation | partially    |
| @EventChannelApi() | 定义事件流 API。ArkTS 生成 `PigeonStreamHandler`、`PigeonEventSink` 及 `*StreamHandler.register(...)`（详见 §7）。 | annotation | yes          |
| @TaskQueue()       | IDL 可标注 `@TaskQueue`；`flutter_ohos` **的** `BasicMessageChannel` **目前仅三参数**，队列**尚未绑定**到通道（详见 §7）。    | annotation | partially    |




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


| 项                                  | 说明                                                                  |
| ---------------------------------- | ------------------------------------------------------------------- |
| `@TaskQueue` 未绑定                   | 待 `flutter_ohos` 支持四参数 `BasicMessageChannel` 后对齐 Kotlin（见 §7 序号 1）。 |
| `Int64List` 精度                     | ArkTS 映射为 `number[]`，超出 ±2^53−1 会丢精度（见 §7 序号 7）。                    |
| `platform_tests/test_plugin/ohos/` | 上游无 OHOS 对等目录；回归在 `example/app/ohos/entry/src/ohosTest/`（Hypium）。   |
| ProxyApi `ESObject` 参数             | 生成期无法引用用户 ProxyApi 类名，运行时以 `ESObject` + 注释提示（见 §7 序号 4）。            |




## 7. 其他

§4 汇总了**注解级别**的鸿蒙支持情况。下表列出 **ArkTS（OHOS）** 宿主生成结果与典型 **Android（Kotlin）、iOS/macOS（Swift）** 生成路径在**代码生成与运行时**上的差异；集成时请按业务逐项核对生成的 ArkTS / Kotlin（或 Swift）源码。


| 序号  | 能力项                                     | OHOS ArkTS 与 Kotlin / Swift（参考生成侧）的差异要点                                                                                                                                                                                                                                                                                                                                                                                                                                |
| --- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `@TaskQueue` / `TaskQueueType`（**部分**）  | Kotlin 将 `TaskQueue` 作为 `BasicMessageChannel` **第四参数**。`flutter_ohos` **当前仅提供三参数**构造，因此即使 IDL 标注 `@TaskQueue(type: TaskQueueType.serialBackgroundThread)`，ArkTS 仍生成**标准三参数通道**；处理器在默认平台线程执行，待 `flutter_ohos` 支持四参数后再对齐 Kotlin。                                                                                                                                                                                                                                         |
| 2   | `@EventChannelApi`                      | ArkTS 生成 `PigeonStreamHandler`、`PigeonEventSink`、`PigeonEventChannelWrapper` 及按方法划分的 `*StreamHandler.register(binaryMessenger, handler, instanceName?)`（使用 `PigeonMethodChannelCodec`）。宿主插件继承生成的 handler，在 `onAttachedToEngine` 中调用 `register`，在 detach 时 `setStreamHandler(null)`。                                                                                                                                                                                    |
| 3   | **枚举（enum）的伴侣类包装**                      | 除 `export enum` 外，生成器还会为每个 Pigeon 枚举生成 `<枚举名>Enum` **伴侣类**（如携带 `index` 等），在 `toList` **/** `fromList` **与** `PigeonCodec` 中通过 `new <枚举名>Enum(...)` **包装** 参与编解码，以契合 `StandardMessageCodec` 对自定义类型的传递。Kotlin / Swift 侧生成物通常更直接地使用 **语言原生 enum**，**形态与手写习惯与 ArkTS 不一致**；宿主侧若混用「裸枚举值」与「包装实例」易导致编解码失败，须按生成代码的 getter/setter 与 codec 分支使用。                                                                                                                                  |
| 4   | `@ProxyApi`（**部分支持**）                   | **已实现：** `PigeonInstanceManager`（**WeakRef + FinalizationRegistry** GC）、`PigeonProxyApiRegistrar`、`PigeonApi<名称>` 适配器、**继承/接口** registrar getter、`List<某ProxyApi>` 类型映射、codec `pigeon_newInstance` **分发**（子类优先于父类拓扑排序）、实例引用标签 128。`minAndroidApi` 通过 `PigeonMinApi.isSatisfied()` 记录以保持 IDL 跨平台一致，但**不在鸿蒙侧强制执行**。若 ProxyApi 声明**必填** Flutter 回调，Dart 侧可能不生成 `pigeon_newInstance` 处理器。宿主实现类名宜与 `kotlinOptions.fullClassName`（或 ProxyApi 名称）一致，以便 codec `instanceof` 分发。 |
| 5   | `sealed` **数据类继承**                      | Kotlin / Swift 普遍支持受限的 sealed 父子类建模与生成。ArkTS 生成器在 codec 中设置 `excludeSealedClasses: true`，对「任意 HostApi 或数据结构里的 sealed 继承树」的覆盖可能不完整；使用前应对同一份 pigeon 输出的 Kotlin（或 Swift）与 ArkTS 文件都做编译与联调测试。                                                                                                                                                                                                                                                                              |
| 6   | `messageChannelSuffix`                  | ArkTS `HostApi.setup(..., messageChannelSuffix: '')` 与 `FlutterApi` **构造器**支持与 Dart 相同的后缀，非空时向频道名追加 `.suffix`。                                                                                                                                                                                                                                                                                                                                                         |
| 7   | 类型化二进制数据（`Uint8List`、`Float32List` 等）   | `Uint8List`、`Int32List`、`Int64List`、`Float32List`、`Float64List` 在 ArkTS 侧映射为 `number[]`，而非 `Uint8Array` 等类型化数组。Kotlin / Swift 使用平台原生字节/浮点缓冲区，codec 支持更丰富。                                                                                                                                                                                                                                                                                                              |
| 8   | 平台专属注解（`@Swift*`、`@Kotlin*`、`@Objc*` 等） | 这些注解仅影响**其他平台**的生成器，对 `--arkts_out` **输出会被忽略**。                                                                                                                                                                                                                                                                                                                                                                                                                        |
| 9   | `PigeonCodec` **构造函数可见性**               | 无 ProxyApi 时 `PigeonCodec` 构造函数为 `private`；存在 ProxyApi 时需被 `PigeonProxyApiBaseCodec` 继承，构造函数为 `public`。此为 ArkTS 语言限制下的设计取舍。                                                                                                                                                                                                                                                                                                                                            |
| 10  | **插件生命周期与内存管理**                         | 宿主 `FlutterPlugin` 应在 `onDetachedFromEngine` 中：`HostApi.setup(messenger, null)`、ProxyApi `tearDown()`、`EventChannel.setStreamHandler(null)`，并停止进行中的异步操作。示例见 `example/app/ohos/.../MessagePlugin.ets`。                                                                                                                                                                                                                                                                  |




## 8. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/oh-3.44.9-dev/packages/pigeon/LICENSE) ，请自由地享受和参与开源。

> 模板版本: v0.0.1

