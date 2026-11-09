# material_ui (OpenHarmony)

本项目基于 [material_ui@1.9.0](https://pub.dev/packages/material_ui/versions/1.9.0) 开发。

## 简介

`material_ui` 为 Flutter 应用提供 Material Design 界面组件。本项目提供其 OpenHarmony 平台适配。

## 下载安装

在工程 pubspec.yaml 中添加依赖：

```yaml
dependencies:
  material_ui:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/material_ui"
      # 选择包含适配代码且与应用所用 Flutter 版本匹配的分支/TAG。
      ref: oh-3.47.7-dev
```

执行命令安装依赖：

```bash
flutter pub get
```

## 约束与限制

### 兼容性

需要使用支持 OpenHarmony 的 Flutter SDK。包的版本约束为 Flutter `>=3.47.0`、Dart `^3.13.0`。

适配环境：

| 工具或系统 | 版本 |
| --- | --- |
| Flutter | 3.47.7+ohos-0.0.1-canary1 |
| DevEco Studio | 26.0.0 Release (26.0.0.821) |
| SDK | 5.0.5(17) |
| ROM | 7.0.0.111 SP10 |

## 使用方法

在 Dart 文件中导入组件库：

```dart
import 'package:material_ui/material_ui.dart';
```

组件用法与迁移步骤见 [README.md](README.md)，更多示例见 [example](example/README.md)。

## 贡献代码

使用中遇到问题欢迎提交 [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues)，也欢迎通过 [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) 贡献代码。

## 开源协议

本项目遵循 [BSD-3-Clause License](LICENSE)。
