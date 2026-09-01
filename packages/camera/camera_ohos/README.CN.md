<p align="center">
  <h1 align="center"> <code>camera_ohos</code> </h1>
</p>

本项目基于 [camera@0.12.0+2](https://pub.dev/packages/camera/versions/0.12.0+2) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

### pubspec.yaml

```yaml
dependencies:
  camera_ohos:
    git: 
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/camera/camera_ohos
      ref: camera-v0.12.0+2-ohos-1.0.0
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

以下示例展示基本调用流程：导入包、枚举摄像头、创建并初始化相机、构建预览、拍照。

```dart
import 'package:camera_ohos/camera_ohos.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // OhosCamera 实例由插件自动注册。
  final OhosCamera camera = CameraPlatform.instance as OhosCamera;

  // 1. 枚举可用摄像头。
  final List<CameraDescription> cameras = await camera.availableCameras();
  final CameraDescription backCamera = cameras.first;

  // 2. 创建未初始化的相机实例并初始化。
  final int cameraId = await camera.createCamera(backCamera);
  await camera.initializeCamera(cameraId);

  // 3. 构建预览控件并拍照。
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            camera.buildPreview(cameraId),
            FloatingActionButton(
              onPressed: () async {
                final XFile photo = await camera.takePicture(cameraId);
                debugPrint('照片已保存至 ${photo.path}');
              },
              child: const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    ),
  );
}
```

更多功能（录像、闪光灯/曝光/对焦控制、图像流等）详见 [example](./example)。

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.44.9+ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 26.0.0.621; ROM: 6.1.0.117 SP6;

Flutter 框架版本与本包所基于的上游 `camera` TAG、代码分支对应关系如下：

| Flutter 框架版本 | TAG           | 分支                     |
| ----------------- | ------------- | ------------------------ |
| 3.44 | camera-v0.12.0+2-ohos-1.0.0 | oh-3.44.9-dev |

> 说明：本包基于上游 [camera@0.12.0+2](https://pub.dev/packages/camera/versions/0.12.0+2) 适配。上表分支即 §1.1 安装依赖中 `ref` 引用的分支；本包 `pubspec.yaml` 的包版本为 `0.10.10+11`，与上游 `camera` 版本相互独立。

### 2.2 权限要求

以下权限中有`system_basic` 权限，而默认的应用权限是 `normal` ，只能使用 `normal` 等级的权限，所以可能会在安装hap包时报错**9568289**，请参考 [文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#ZH-CN_TOPIC_0000001884757326__安装hap时提示code9568289-error-install-failed-due-to-grant-request-permissions-failed) 修改应用等级为 `system_basic`

### 2.2.1 在 entry 目录下的module.json5中添加权限

打开 `entry/src/main/module.json5`，添加：

```diff
"requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:reason",
        "usedScene": {
          "abilities": [
            "FormAbility"
          ],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:reason",
        "usedScene": {
          "abilities": [
            "FormAbility"
          ],
          "when": "inuse"
        }
      },
    ]
```

### 2.2.2 在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

```diff
{
  "string": [
    {
      "name": "reason",
      "value": "reason"
    }
  ]
}
```

### 2.3 环境搭建

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 6.0.2.650 及以上版本，并在 SDK Manager 中安装 HarmonyOS SDK 5.0.0(12)。
2. 使用 DevEco Studio 打开 `ohos` 平台工程（例如 `example/ohos`），并在 **File > Project Structure > Signing Configs** 中完成签名配置。应用安装到真机必须使用已签名的 HAP。
3. 使用命令行编译与运行：

   ```bash
   # 编译 release 版 HAP（底层调用 hvigor）。
   flutter build ohos --release

   # 在已连接设备上运行。
   flutter run -d <device-id>

   # 或直接使用 hvigor 编译。
   hvigorw assembleHap --mode module -p product=default
   ```

## 3. API

> \[!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性，no 则表示不支持。使用方法跨平台一致，效果对标 IOS 或 Android 的效果。

| Name                                                                                                                                                           | return value                                           | Description                | Type     | ohos Support |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | -------------------------- | -------- | ------------ |
| registerWith()                                                                                                                                                 | void                                                   | 插件注册                       | function | yes          |
| availableCameras()                                                                                                                                             | Future\<List<[CameraDescription](#CameraDescription)>> | 获取可用摄像头列表                  | function | yes          |
| createCamera([CameraDescription](#CameraDescription) cameraDescription, [ResolutionPreset](#ResolutionPreset)? resolutionPreset, { bool enableAudio = false }) | Future<int>                                            | 创建一个未初始化的摄像头实例并返回其cameraId | function | yes          |
| createCameraWithSettings([CameraDescription](#CameraDescription) cameraDescription, MediaSettings? mediaSettings)                                              | Future<int>                                            | 按媒体参数创建相机实例并返回其cameraId    | function | yes          |
| initializeCamera(int cameraId, {[ImageFormatGroup](#ImageFormatGroup) imageFormatGroup = ImageFormatGroup.unknown})                                            | Future<void>                                           | 初始化设备上的摄像头                 | function | yes          |
| dispose(int cameraId)                                                                                                                                          | Future<void>                                           | 释放该摄像头占用的资源                | function | yes          |
| onCameraInitialized(int cameraId)                                                                                                                              | Stream<CameraInitializedEvent>                         | 监听相机初始化完成事件                | function | yes          |
| onCameraResolutionChanged(int cameraId)                                                                                                                        | Stream<CameraResolutionChangedEvent>                   | 监听相机分辨率变化事件                | function | yes          |
| onCameraClosing(int cameraId)                                                                                                                                  | Stream<CameraClosingEvent>                             | 监听相机关闭事件                   | function | yes          |
| onCameraError(int cameraId)                                                                                                                                    | Stream<CameraErrorEvent>                               | 监听相机错误事件                   | function | yes          |
| onCameraSwitched(int cameraId)                                                                                                                                 | Stream<String>                                       | 监听相机自动切换事件                  | function | yes          |
| onVideoRecordedEvent(int cameraId)                                                                                                                             | Stream<VideoRecordedEvent>                             | 监听录像完成事件                   | function | yes          |
| onDeviceOrientationChanged()                                                                                                                                   | Stream<DeviceOrientationChangedEvent>                  | 监听设备方向变化事件                 | function | yes          |
| lockCaptureOrientation(int cameraId,   [DeviceOrientation](#DeviceOrientation) orientation, )                                                                  | Future<void>                                           | 锁定拍摄方向                     | function | yes          |
| unlockCaptureOrientation(int cameraId)                                                                                                                         | Future<void>                                           | 解锁拍摄方向                     | function | yes          |
| takePicture(int cameraId)                                                                                                                                      | Future<XFile>                                          | 拍照，并返回该照片的文件路径             | function | yes          |
| prepareForVideoRecording()                                                                                                                                     | Future<void>                                           | 准备视频录制所需的拍摄会话              | function | no           |
| startVideoRecording(int cameraId)                                                                                                                              | Future<void>                                           | 开始录制视频                     | function | yes          |
| startVideoCapturing([VideoCaptureOptions](#VideoCaptureOptions) options)                                                                                       | Future<void>                                           | 开始录制视频和/或流式传输会话            | function | yes          |
| stopVideoRecording(int cameraId)                                                                                                                               | Future<XFile>                                          | 停止视频录制，并返回保存该视频的文件路径       | function | yes          |
| pauseVideoRecording(int cameraId)                                                                                                                              | Future<void>                                           | 暂停视频录制                     | function | yes          |
| resumeVideoRecording(int cameraId)                                                                                                                             | Future<void>                                           | 在暂停后恢复视频录制                 | function | yes          |
| supportsImageStreaming()                                                                                                                                       | bool                                                   | 声明当前平台是否支持图像流              | function | yes          |
| onStreamedFrameAvailable(int cameraId, {CameraImageStreamOptions? options})                                                                                    | Stream<CameraImageData>                                | 订阅相机图像帧数据流                 | function | yes          |
| setFlashMode(int cameraId, [FlashMode](#FlashMode) mode)                                                                                                       | Future<void>                                           | 设置闪光灯模式                    | function | yes          |
| setImageFileFormat(int cameraId, ImageFileFormat format)                                                                                                      | Future<void>                                             | 设置拍照生成图片的文件格式（如 JPEG）          | function | yes          |
| setJpegImageQuality(int cameraId, int quality)                                                                                                                | Future<void>                                             | 设置拍照生成的 JPEG 图片质量（1-100）        | function | yes          |
| setExposureMode(int cameraId, [ExposureMode](#ExposureMode) mode)                                                                                              | Future<void>                                           | 设置曝光模式                     | function | yes          |
| setExposurePoint(int cameraId, Point<double>? point)                                                                                                           | Future<void>                                           | 设置自动曝光的曝光点位置               | function | yes          |
| getMinExposureOffset(int cameraId)                                                                                                                             | Future<double>                                         | 获取最小曝光补偿值                  | function | yes          |
| getMaxExposureOffset(int cameraId)                                                                                                                             | Future<double>                                         | 获取最大曝光补偿值                  | function | yes          |
| getExposureOffsetStepSize(int cameraId)                                                                                                                        | Future<double>                                         | 获取曝光补偿步长                   | function | yes          |
| setExposureOffset(int cameraId, double offset)                                                                                                                 | Future<double>                                         | 设置曝光补偿值                    | function | yes          |
| setFocusMode(int cameraId, [FocusMode](#FocusMode) mode)                                                                                                       | Future<void>                                           | 设置对焦模式(小于API20不支持对焦锁定)                     | function | yes          |
| setFocusPoint(int cameraId, Point<double>? point)                                                                                                              | Future<void>                                           | 设置自动对焦的对焦点                 | function | yes          |
| getMaxZoomLevel(int cameraId)                                                                                                                                  | Future<double>                                         | 获取最大变焦倍数                   | function | yes          |
| getMinZoomLevel(int cameraId)                                                                                                                                  | Future<double>                                         | 获取最小变焦倍数                   | function | yes          |
| setZoomLevel(int cameraId, double zoom)                                                                                                                        | Future<void>                                           | 设置变焦倍数                     | function | yes          |
| getSupportedVideoStabilizationModes(int cameraId)                                                                                                              | Future\<Iterable<VideoStabilizationMode>>              | 查询设备支持的视频防抖模式              | function | yes          |
| setVideoStabilizationMode(int cameraId, VideoStabilizationMode mode)                                                                                           | Future<void>                                           | 设置视频防抖模式                   | function | yes          |
| pausePreview(int cameraId)                                                                                                                                     | Future<void>                                           | 暂停当前帧的预览显示                 | function | yes          |
| resumePreview(int cameraId)                                                                                                                                    | Future<void>                                           | 恢复已暂停的预览显示                 | function | yes          |
| setDescriptionWhileRecording([CameraDescription](#CameraDescription) description)                                                                              | Future<void>                                           | 在录制过程中切换当前使用的摄像头           | function | no           |
| buildPreview(int cameraId)                                                                                                                                     | Widget                                                 | 构建预览控件                     | function | yes          |

## 4. 属性

### CameraDescription

| Name              | Description                   | Type                                        | ohos Support |
| ----------------- | ----------------------------- | ------------------------------------------- | ------------ |
| name              | 相机设备名称                        | String                                      | yes          |
| lensDirection     | 摄像机所面对的方向                     | [CameraLensDirection](#CameraLensDirection) | yes          |
| sensorOrientation | 输出图像需要旋转的角度，以便在设备屏幕上以原始方向直立显示 | int                                         | yes          |
| lensType          | 相机所配备的镜头类型                    | [CameraLensType](#CameraLensType)           | yes          |

### CameraLensDirection

| Name                         | Description             | Type | ohos Support |
| ---------------------------- | ----------------------- | ---- | ------------ |
| CameraLensDirection.front    | 前置摄像头（用户看着屏幕，摄像头可以看到用户） | enum | yes          |
| CameraLensDirection.back     | 后置摄像头（用户看屏幕时，摄像头看不到用户）  | enum | yes          |
| CameraLensDirection.external | 外部摄像头，可能无法安装到设备上        | enum | yes          |

### CameraLensType

| Name                     | Description          | Type | ohos Support |
| ------------------------ | -------------------- | ---- | ------------ |
| CameraLensType.wide      | 内置广角相机设备类型           | enum | yes          |
| CameraLensType.telephoto | 一种内置相机设备类型，其焦距比广角相机长 | enum | yes          |
| CameraLensType.ultraWide | 一种内置相机设备类型，其焦距比广角相机短 | enum | yes          |
| CameraLensType.unknown   | 未知的摄像头设备类型           | enum | yes          |

### ResolutionPreset

| Name                       | Description                               | Type | ohos Support |
| -------------------------- | ----------------------------------------- | ---- | ------------ |
| ResolutionPreset.low       | 352x288 on iOS, \~240p on Android and Web | enum | yes          |
| ResolutionPreset.medium    | 480p                                      | enum | yes          |
| ResolutionPreset.high      | 720p                                      | enum | yes          |
| ResolutionPreset.veryHigh  | 1080p                                     | enum | yes          |
| ResolutionPreset.ultraHigh | 2160p                                     | enum | yes          |
| ResolutionPreset.max       | 最高分辨率可用。                                  | enum | yes          |

### imageFormatGroup

| Name                      | Description                 | Type | ohos Support |
| ------------------------- | --------------------------- | ---- | ------------ |
| ImageFormatGroup.unknown  | 图像格式不属于任何特定组。               | enum | no           |
| ImageFormatGroup.yuv420   | Multi-plane YUV 420 format. | enum | no           |
| ImageFormatGroup.bgra8888 | 32-bit BGRA.                | enum | no           |
| ImageFormatGroup.jpeg     | 32位RGB图像编码成JPEG字节。          | enum | yes          |
| ImageFormatGroup.nv21     | YCrCb格式用于图像，使用NV21编码格式。     | enum | no           |

### DeviceOrientation

| Name                             | Description                        | Type | ohos Support |
| -------------------------------- | ---------------------------------- | ---- | ------------ |
| DeviceOrientation.portraitUp     | 如果设备在启动时以竖屏显示，则启动徽标以【portraitUp】显示 | enum | yes          |
| DeviceOrientation.landscapeLeft  | 与【portraitUp】逆时针旋转90度的方向           | enum | yes          |
| DeviceOrientation.portraitDown   | 与【portraitUp】方向相反的180度方向           | enum | yes          |
| DeviceOrientation.landscapeRight | 与【portraitUp】顺时针旋转90度的方向           | enum | yes          |

### VideoCaptureOptions

| Name           | Description        | Type                             | ohos Support |
| -------------- | ------------------ | -------------------------------- | ------------ |
| cameraId       | 用于捕获的摄像头的ID        | int                              | yes          |
| streamCallback | 一个可选的回调函数，用于启用流式传输 | Function(CameraImageData image)? | yes          |
| streamOptions  | 流媒体的配置选项           | CameraImageStreamOptions?        | yes          |

### CameraImageData

| Name               | Description         | Type                                        | ohos Support |
| ------------------ | ------------------- | ------------------------------------------- | ------------ |
| format             | 提供的图像的格式            | [CameraImageFormat](#CameraImageFormat)     | yes          |
| planes             | 这张图片的像素平面           | List<[CameraImagePlane](#CameraImagePlane)> | yes          |
| height             | 图像的高度（像素）           | int                                         | yes          |
| width              | 图像的宽度（以像素为单位）       | int                                         | yes          |
| lensAperture       | 这张图片的光圈设置           | double                                      | yes          |
| sensorExposureTime | 此图像的传感器曝光时间为纳秒      | int                                         | yes          |
| sensorSensitivity  | 传感器灵敏度，以标准ISO算术单位表示 | double                                      | yes          |

### CameraImageStreamOptions

空占位类，当前未使用，仅为平台接口 API 的未来扩展预留，不定义任何字段。

### CameraImagePlane

| Name          | Description        | Type      | ohos Support |
| ------------- | ------------------ | --------- | ------------ |
| bytes         | 表示该平面的字节           | Uint8List | yes          |
| bytesPerRow   | 此颜色平面的行步长，以字节为单位   | int       | yes          |
| bytesPerPixel | 当可用时，相邻像素样本之间的字节距离 | int?      | yes          |
| height        | 像素缓冲区的高度，如果可用      | int?      | yes          |
| width         | 像素缓冲区的宽度，如果可用      | int?      | yes          |

### FlashMode

| Name             | Description        | Type      | ohos Support |
| ---------------- | ------------------ | --------- | ------------ |
| FlashMode.off    | 拍照时不要使用闪光灯         | enum      | yes          |
| FlashMode.auto   | 让设备决定在拍照时是否闪烁相机    | enum      | yes          |
| FlashMode.always | 拍照时总是使用闪光灯         | enum      | yes          |
| FlashMode.torch  | 打开闪光灯，并保持打开状态，直到关闭 | enum      | yes          |

### ExposureMode

| Name                | Description | Type      | ohos Support |
| ------------------- | ----------- | --------- | ------------ |
| ExposureMode.auto   | 自动确定曝光设置    | enum      | yes          |
| ExposureMode.locked | 锁定当前确定的曝光设置 | enum      | yes          |

### FocusMode

| Name             | Description | Type      | ohos Support |
| ---------------- | ----------- | --------- | ------------ |
| FocusMode.auto   | 自动确定焦点设置    | enum      | yes          |
| FocusMode.locked | 锁定当前确定的焦点设置 | enum      | yes          |

### VideoStabilizationMode

| Name                          | Description | Type      | ohos Support |
| ----------------------------- | ----------- | --------- | ------------ |
| VideoStabilizationMode.off    | 视频防抖功能已禁用   | enum      | yes          |
| VideoStabilizationMode.level1 | 最低防抖效果，延迟最低 | enum      | yes          |
| VideoStabilizationMode.level2 | 防抖效果较好，延迟较高 | enum      | yes          |
| VideoStabilizationMode.level3 | 防抖效果最佳，延迟最高 | enum      | yes          |

## 5. 遗留问题

- [ ] ohos 端 执行setDescriptionWhileRecording 设置无效，并返回错误提示：
  ```
  Camera switching is not supported while recording.
  ```
- [ ] ohos 端设置FPS当前不生效
- [ ] ohos 端 不支持录像准备接口 `prepareForVideoRecording()`，当前为空实现
- [ ] `getMaxZoomLevel` 无法在 `create()` 阶段从相机属性读取：OHOS 仅在已建立的相机会话中暴露变焦倍率范围，而该阶段会话尚未建立。`CameraPropertiesImpl.getScalerAvailableMaxDigitalZoom` 返回 0 作为未知标记，实际最大变焦由 `ZoomLevelFeature` 在运行时从会话读取。
- [ ] `CameraDescription.sensorOrientation` 恒为 0：OHOS CameraKit 未暴露传感器方向。

## 6. 其他

## 7. 开源协议

本项目基于 [The MIT License (MIT)](./LICENSE) ，请自由地享受和参与开源。

> 模板版本: v0.0.1

