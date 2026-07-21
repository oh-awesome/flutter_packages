# `pigeon`

本项目基于 [pigeon@25.5.0](https://pub.dev/packages/pigeon/versions/25.5.0) 开发。

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
      ref: "br_pigeon-v25.3.2_ohos_dev"

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

1. Flutter version 3.27.5-ohos-1.0.6; SDK: 6.0.0.47 (API Version 20 Release); IDE: DevEco Studio: 6.0.0.858; ROM: 6.0.0.125 SP8;

## 3. API

> [!TIP] "Pigeon"是一个代码生成工具，通过终端执行命令调用，不涉及API

## 4. 注解

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该注解；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果与各 Flutter 宿主目标保持一致。


| Name               | Description                                      | Type       | ohos Support |
| ------------------ | ------------------------------------------------ | ---------- | ------------ |
| @HostApi()         | 使用 @HostApi() 注解定义接口，这些接口由原生平台实现，供 Flutter 调用    | annotation | yes          |
| @FlutterApi()      | 使用 @FlutterApi() 注解定义接口，这些接口由 Flutter 实现，供原生平台调用 | annotation | yes          |
| @ProxyApi()        | 定义基于 `InstanceManager`、弱引用 GC、继承与适配器的双向对象引用（详见 §7）。 | annotation | partially    |
| @TaskQueue()       | IDL 可标注 `@TaskQueue`；**`flutter_ohos` 的 `BasicMessageChannel` 目前仅三参数**，队列**尚未绑定**到通道（详见 §7）。 | annotation | partially    |


## 5. 命令

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该命令；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果与各 Flutter 宿主目标保持一致。

使用：`flutter pub run pigeon --input <pigeon path> --dart_out<dart path> [option]*`

> 上游 pigeon 还提供面向 JVM 与原生宿主的附加输出参数，详见 [上游包文档](https://pub.dev/packages/pigeon)；下表侧重 OHOS ArkTS 工作流常用参数。


| Command                       | Description                   | ohos Support |
| ----------------------------- | ----------------------------- | ------------ |
| --input                       | 指定输入的 Dart 文件路径，该文件中定义了通信接口   | yes          |
| --dart_out                    | 指定生成的 Dart 文件的输出路径            | yes          |
| --arkts_out                   | 指定生成的 ohos ArkTS 文件路径            | yes          |
| --java_out                    | 指定生成的 JVM 宿主 Java 文件路径       | yes          |
| --java_package                | 指定生成的 JVM 宿主 Java 文件包名       | yes          |
| --cpp_header_out              | 指定生成的 Windows 头文件（`.h`）路径   | yes          |
| --cpp_source_out              | 指定生成的 Windows 源文件（`.cpp`）路径 | yes          |


## 6. 遗留问题

## 7. ArkTS 生成说明

§4 汇总了**注解级别**的 OHOS 支持情况。下表列出 **ArkTS（OHOS）** 宿主生成结果与典型 **对等 Pigeon 宿主生成器**在**代码生成与运行时**上的差异；集成时请按业务逐项核对生成的 ArkTS 与对等宿主源码。


| 序号  | 能力项                                 | OHOS ArkTS 与对等宿主生成器的差异要点                                                                                                                                                |
| --- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `@TaskQueue` / `TaskQueueType`（**部分**） | 部分宿主生成器将 **`TaskQueue`** 作为 **`BasicMessageChannel` 第四参数**。**`flutter_ohos` 当前仅提供三参数**构造，因此即使 IDL 标注 `@TaskQueue(type: TaskQueueType.serialBackgroundThread)`，ArkTS 仍生成**标准三参数通道**；处理器在默认平台线程执行，待 `flutter_ohos` 支持四参数后再对齐。 |
| 2   | **枚举（enum）的伴侣类包装**                 | 除 `export enum` 外，生成器还会为每个 Pigeon 枚举生成 **`<枚举名>Enum` 伴侣类**（如携带 `index` 等），在 **`toList` / `fromList` 与 `PigeonCodec`** 中通过 **`new <枚举名>Enum(...)` 包装** 参与编解码，以契合 `StandardMessageCodec` 对自定义类型的传递。对等宿主侧生成物通常更直接地使用 **语言原生 enum**，**形态与手写习惯与 ArkTS 不一致**；宿主侧若混用「裸枚举值」与「包装实例」易导致编解码失败，须按生成代码的 getter/setter 与 codec 分支使用。 |
| 3   | `@ProxyApi`（**部分支持**）              | **已实现：** `PigeonInstanceManager`（**WeakRef + FinalizationRegistry** GC）、`PigeonProxyApiRegistrar`、`PigeonApi<名称>` 适配器、**继承/接口** registrar getter、**`List<某ProxyApi>`** 类型映射、codec **`pigeon_newInstance` 分发**（子类优先于父类拓扑排序）、实例引用标签 128。**IDL 中的最低宿主 API 字段**通过 **`PigeonMinApi.isSatisfied()`** 记录以保持跨平台一致，但**不在 OHOS 侧强制执行**。若 ProxyApi 声明**必填** Flutter 回调，Dart 侧可能不生成 `pigeon_newInstance` 处理器。宿主实现类名宜与 **Pigeon 配置中声明的宿主类名**（或 ProxyApi 名称）一致，以便 codec `instanceof` 分发。 |
| 4   | **`sealed` 数据类继承**                  | 对等宿主生成器普遍支持受限的 sealed 父子类建模与生成。ArkTS 生成器在 codec 中设置 **`excludeSealedClasses: true`**，对「任意 HostApi 或数据结构里的 sealed 继承树」的覆盖可能不完整；使用前应对同一份 pigeon 输出的 ArkTS 与对等宿主文件都做编译与联调测试。                                   |
| 5   | `messageChannelSuffix`              | ArkTS **`HostApi.setup(..., messageChannelSuffix: '')`** 与 **`FlutterApi` 构造器**支持与 Dart 相同的后缀，非空时向频道名追加 **`.suffix`**。 |
| 6   | 类型化二进制数据（`Uint8List`、`Float32List` 等） | `Uint8List`、`Int32List`、`Int64List`、`Float32List`、`Float64List` 在 ArkTS 侧映射为 **`number[]`**，而非 `Uint8Array` 等类型化数组。对等宿主生成器通常使用平台原生字节/浮点缓冲区，codec 支持更丰富。 |
| 7   | 宿主专属配置注解                              | 仅作用于 **非 `--arkts_out` 目标** 的注解，对 **ArkTS 输出会被忽略**。 |


## 8. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/br_pigeon-v25.3.2_ohos_dev/packages/pigeon/LICENSE) ，请自由地享受和参与开源。

> 模板版本: v0.0.1
