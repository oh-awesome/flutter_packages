<p align="center">
  <h1 align="center"> <code>camera</code> </h1>
</p>

本项目基于 [camera@0.11.0+2](https://pub.dev/packages/camera/versions/0.11.0+2) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  camera:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/camera/camera
      # ref: camera-v0.11.0_2-ohos-1.0.0
      ref: TAG  #   请根据下方TAG版本对应表选择TAG
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG 版本对应表**

| Flutter 框架版本 | TAG | 分支 |
| :--- | :--- | :--- |
| 3.35 | `camera-v0.11.3-ohos-1.0.0` | `br_camera-v0.11.3_ohos` |
| 3.27 | `camera-v0.11.1-ohos-1.0.0` | `br_camera-v0.11.1_ohos` |
| 3.22 | `camera-v0.11.0_2-ohos-1.0.0` | `br_camera-v0.11.0+2_ohos` |
| 3.7 | `camera-v0.10.5_5-ohos-1.0.0` | `master` |

## 1.2 使用案例

使用案例详见 [ohos/example](./example/)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 HarmonyOS 端适配说明

为保证录制稳定性，**本插件在 HarmonyOS 平台进行了如下修改**：

**禁止在录制过程中切换前后摄像头**

在录像状态下调用 `CameraController.setDescriptionWhileRecording()` 将无效，并返回错误提示：

```
Camera switching is not supported while recording.
```

此修改仅影响 HarmonyOS 端，**在 Android/iOS 平台保持原有行为**。请开发者在使用此插件开发时注意平台差异，避免在录制状态中调用切换摄像头逻辑，或使用平台判断进行适配。

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| availableCameras()                                           | Future<List<CameraDescription>>                       | 获取设备上可用的摄像头列表。     | function | yes          |
| CameraController(CameraDescription description, ResolutionPreset resolutionPreset, {bool enableAudio = true, ...}) | CameraController                                      | 创建摄像头控制器。 | class    | yes          |
| initialize()                                                 | Future<void>                                          | 初始化摄像头。 | function | yes          |
| takePicture()                                                | Future<XFile>                                         | 拍摄一张照片。 | function | yes          |
| startVideoRecording()                                        | Future<void>                                          | 开始录制视频。 | function | yes          |
| stopVideoRecording()                                         | Future<XFile>                                         | 停止录制视频并返回文件。 | function | yes          |
| pauseVideoRecording()                                        | Future<void>                                          | 暂停视频录制。 | function | yes          |
| resumeVideoRecording()                                       | Future<void>                                          | 恢复视频录制。 | function | yes          |
| setFlashMode(FlashMode mode)                                 | Future<void>                                          | 设置闪光灯模式。 | function | yes          |
| setZoomLevel(double zoom)                                    | Future<void>                                          | 设置缩放级别。 | function | yes          |
| setDescriptionWhileRecording(CameraDescription description)  | Future<void>                                          | 录制过程中切换摄像头。（ohos 不支持） | function | no           |
| dispose()                                                    | Future<void>                                          | 释放摄像头资源。 | function | yes          |

## 4. 遗留问题

- 不支持在录制过程中切换前后摄像头。

## 5. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/camera/camera/LICENSE)，请自由地享受和参与开源。

> 模板版本: v0.0.1
