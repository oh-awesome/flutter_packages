<p align="center">
  <h1 align="center"> <code>flutter_plugin_android_lifecycle</code> </h1>
</p>

本项目基于 [flutter_plugin_android_lifecycle](https://pub.dev/packages/flutter_plugin_android_lifecycle) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  flutter_plugin_android_lifecycle:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/flutter_plugin_android_lifecycle
      ref: br_flutter_plugin_android_lifecycle-v2.0.29_ohos_dev

...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [example](example/lib/main.dart)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.1.3; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.1.251; ROM: 6.0.0.115 SP16;
2. Flutter: 3.22.1-ohos-1.0.3; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.1.251; ROM: 6.0.0.115 SP16;
3. Flutter: 3.27.5-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.1.251; ROM: 6.0.0.115 SP16;

## 3. API

不涉及

## 4. 遗留问题

无

## 5. 开源协议

本项目基于 [The MIT License](LICENSE)，请自由地享受和参与开源。
