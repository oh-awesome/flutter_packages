

<p align="center">
  <h1 align="center"> <code>camera_ohos</code> </h1>
</p>



本项目基于 [camera@0.11.3](https://pub.dev/packages/camera/versions/0.11.3) 开发。

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
      # ref: camera-v0.11.3-ohos-1.0.1
      ref: TAG  #   请根据下方TAG版本对应表选择TAG
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG 版本对应表**

| Flutter 框架版本 | TAG1 | TAG2 | 分支 |
| :--- | :--- | :--- | :--- |
| 3.41 | `-` | `camera-v0.12.0_1-ohos-1.0.0` | `br_camera-v0.12.0_1_ohos` |
| 3.35 | `camera-v0.11.3-ohos-1.0.0` | `camera-v0.11.3-ohos-1.0.1` | `br_camera-v0.11.3_ohos` |
| 3.27 | `camera-v0.11.1-ohos-1.0.0` | `camera-v0.11.1-ohos-1.0.1` | `br_camera-v0.11.1_ohos` |
| 3.22 | `camera-v0.11.0_2-ohos-1.0.0` | `camera-v0.11.0_2-ohos-1.0.1` | `br_camera-v0.11.0+2_ohos` |
| 3.7 | `camera-v0.10.5_5-ohos-1.0.0` | `camera-v0.10.5_5-ohos-1.0.1` | `master` |

## 1.2 使用案例

使用案例详见 [ohos/example](./example)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;

### 2.2 权限要求

以下权限中有`system_basic` 权限，而默认的应用权限是 `normal` ，只能使用 `normal` 等级的权限，所以可能会在安装hap包时报错**9568289**，请参考 [文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#section9568289-%E6%9D%83%E9%99%90%E8%AF%B7%E6%B1%82%E5%A4%B1%E8%B4%A5%E5%AF%BC%E8%87%B4%E5%AE%89%E8%A3%85%E5%A4%B1%E8%B4%A5) 修改应用等级为 `system_basic`

####  2.2.1 在 entry 目录下的module.json5中添加权限

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

#### 2.2.2 在 entry 目录下添加申请以上权限的原因

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

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性，no 则表示不支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                                                         | return value                                          | Description                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | -------------------------------------------- | -------- | ------------ |
| availableCameras()                                           | Future<List<[CameraDescription](#CameraDescription)>> | 获取可用摄像头列表                           | function | yes          |
| createCamera([CameraDescription](#CameraDescription) cameraDescription, [ResolutionPreset](#ResolutionPreset)? resolutionPreset, { bool enableAudio = false }) | Future<int>                                           | 创建一个未初始化的摄像头实例并返回其cameraId | function | yes          |
| initializeCamera(int cameraId, {[ImageFormatGroup](#ImageFormatGroup) imageFormatGroup = ImageFormatGroup.unknown}) | Future<void>                                          | 初始化设备上的摄像头                         | function | yes          |
| dispose(int cameraId)                                        | Future<void>                                          | 释放该摄像头占用的资源                       | function | yes          |
| lockCaptureOrientation(int cameraId,   [DeviceOrientation](#DeviceOrientation) orientation, ) | Future<void>                                          | 锁定拍摄方向                                 | function | yes          |
| unlockCaptureOrientation(int cameraId)                       | Future<void>                                          | 解锁拍摄方向                                 | function | yes          |
| takePicture(int cameraId)                                    | Future<XFile>                                         | 拍照，并返回保存该照片的文件路径                 | function | yes          |
| prepareForVideoRecording()                                   | Future<void>                                          | 准备视频录制所需的拍摄会话                   | function | yes           |
| startVideoRecording(int cameraId)                            | Future<void>                                          | 开始录制视频                                 | function | yes          |
| startVideoCapturing([VideoCaptureOptions](#VideoCaptureOptions) options) | Future<void>                                          | 开始录制视频和/或流式传输会话                | function | yes          |
| stopVideoRecording(int cameraId)                             | Future<XFile>                                         | 停止视频录制，并返回保存该视频的文件路径     | function | yes          |
| pauseVideoRecording(int cameraId)                            | Future<void>                                          | 暂停视频录制                                 | function | yes          |
| resumeVideoRecording(int cameraId)                           | Future<void>                                          | 在暂停后恢复视频录制                         | function | yes          |
| setFlashMode(int cameraId, [FlashMode](#FlashMode) mode)     | Future<void>                                          | 设置闪光灯模式                               | function | yes          |
| setExposureMode(int cameraId, [ExposureMode](#ExposureMode) mode) | Future<void>                                          | 设置曝光模式                                 | function | yes          |
| setExposurePoint(int cameraId, Point<double>? point)         | Future<void>                                          | 设置自动曝光的曝光点位置                     | function | yes          |
| getMinExposureOffset(int cameraId)                           | Future<double>                                        | 获取最小曝光补偿值                           | function | yes          |
| getMaxExposureOffset(int cameraId)                           | Future<double>                                        | 获取最大曝光补偿值                           | function | yes          |
| getExposureOffsetStepSize(int cameraId)                      | Future<double>                                        | 获取曝光补偿步长                             | function | yes          |
| setExposureOffset(int cameraId, double offset)               | Future<double>                                        | 设置曝光补偿值                               | function | yes          |
| setFocusMode(int cameraId, [FocusMode](#FocusMode) mode)     | Future<void>                                          | 设置对焦模式                                 | function | yes          |
| setFocusPoint(int cameraId, Point<double>? point)            | Future<void>                                          | 设置自动对焦的对焦点                         | function | yes          |
| getMaxZoomLevel(int cameraId)                                | Future<double>                                        | 获取最大变焦倍数                             | function | yes          |
| getMinZoomLevel(int cameraId)                                | Future<double>                                        | 获取最小变焦倍数                             | function | yes          |
| setZoomLevel(int cameraId, double zoom)                      | Future<void>                                          | 设置变焦倍数                                 | function | yes          |
| pausePreview(int cameraId)                                   | Future<void>                                          | 暂停当前帧的预览显示                         | function | yes          |
| resumePreview(int cameraId)                                  | Future<void>                                          | 恢复已暂停的预览显示                         | function | yes          |
| setDescriptionWhileRecording([CameraDescription](#CameraDescription) description) | Future<void>                                          | 在录制过程中切换当前使用的摄像头             | function | no           |

## 4. 属性

### CameraDescription

| Name              | Description                                                | Type                                        | ohos Support |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- | ------------ |
| name              | 相机设备名称                                               | String                                      | yes          |
| lensDirection     | 摄像机所面对的方向                                         | [CameraLensDirection](#CameraLensDirection) | yes          |
| sensorOrientation | 输出图像需要旋转的角度，以便在设备屏幕上以原始方向直立显示 | int                                         | yes          |
| lensType          | 相机所配备的镜头类型                                       | [CameraLensType](#CameraLensType)           | yes          |

### CameraLensDirection

| Name                         | Description                                    | Type | ohos Support |
| ---------------------------- | ---------------------------------------------- | ---- | ------------ |
| CameraLensDirection.front    | 前置摄像头（用户看着屏幕，摄像头可以看到用户） | enum | yes          |
| CameraLensDirection.back     | 后置摄像头（用户看屏幕时，摄像头看不到用户）   | enum | yes          |
| CameraLensDirection.external | 外部摄像头，可能无法安装到设备上               | enum | yes          |

### CameraLensType

| Name                     | Description                              | Type | ohos Support |
| ------------------------ | ---------------------------------------- | ---- | ------------ |
| CameraLensType.wide      | 内置广角相机设备类型                     | enum | yes          |
| CameraLensType.telephoto | 一种内置相机设备类型，其焦距比广角相机长 | enum | yes          |
| CameraLensType.ultraWide | 一种内置相机设备类型，其焦距比广角相机短 | enum | yes          |
| CameraLensType.unknown   | 未知的摄像头设备类型                     | enum | yes          |

### ResolutionPreset

| Name                       | Description                              | Type | ohos Support |
| -------------------------- | ---------------------------------------- | ---- | ------------ |
| ResolutionPreset.low       | 352x288 on iOS, ~240p on Android and Web | enum | yes          |
| ResolutionPreset.medium    | 480p                                     | enum | yes          |
| ResolutionPreset.high      | 720p                                     | enum | yes          |
| ResolutionPreset.veryHigh  | 1080p                                    | enum | yes          |
| ResolutionPreset.ultraHigh | 2160p                                    | enum | yes          |
| ResolutionPreset.max       | 最高分辨率可用。                         | enum | yes          |

### imageFormatGroup 

| Name                      | Description                           | Type | ohos Support |
| ------------------------- | ------------------------------------- | ---- | ------------ |
| ImageFormatGroup.unknown  | 图像格式不属于任何特定组。            | enum | no           |
| ImageFormatGroup.yuv420   | Multi-plane YUV 420 format.           | enum | no           |
| ImageFormatGroup.bgra8888 | 32-bit BGRA.                          | enum | no           |
| ImageFormatGroup.jpeg     | 32位RGB图像编码成JPEG字节。           | enum | yes          |
| ImageFormatGroup.nv21     | YCrCb格式用于图像，使用NV21编码格式。 | enum | no           |

### DeviceOrientation

| Name                             | Description                                                | Type | ohos Support |
| -------------------------------- | ---------------------------------------------------------- | ---- | ------------ |
| DeviceOrientation.portraitUp     | 如果设备在启动时以竖屏显示，则启动徽标以【portraitUp】显示 | enum | yes          |
| DeviceOrientation.landscapeLeft  | 与【portraitUp】逆时针旋转90度的方向                       | enum | yes          |
| DeviceOrientation.portraitDown   | 与【portraitUp】方向相反的180度方向                        | enum | yes          |
| DeviceOrientation.landscapeRight | 与【portraitUp】顺时针旋转90度的方向                       | enum | yes          |

### VideoCaptureOptions

| Name           | Description                          | Type                             | ohos Support |
| -------------- | ------------------------------------ | -------------------------------- | ------------ |
| cameraId       | 用于捕获的摄像头的ID                 | int                              | yes          |
| streamCallback | 一个可选的回调函数，用于启用流式传输 | Function(CameraImageData image)? | yes          |
| streamOptions  | 流媒体的配置选项                     | CameraImageStreamOptions?        | yes          |

### CameraImageData

| Name               | Description                         | Type                                        | ohos Support |
| ------------------ | ----------------------------------- | ------------------------------------------- | ------------ |
| format             | 提供的图像的格式                    | [CameraImageFormat](#CameraImageFormat)     | yes          |
| planes             | 这张图片的像素平面                  | List<[CameraImagePlane](#CameraImagePlane)> | yes          |
| height             | 图像的高度（像素）                  | int                                         | yes          |
| width              | 图像的宽度（以像素为单位）          | int                                         | yes          |
| lensAperture       | 这张图片的光圈设置                  | double                                      | yes          |
| sensorExposureTime | 此图像的传感器曝光时间为纳秒        | int                                         | yes          |
| sensorSensitivity  | 传感器灵敏度，以标准ISO算术单位表示 | double                                      | yes          |

### CameraImageStreamOptions

| Name          | Description                          | Type      | ohos Support |
| ------------- | ------------------------------------ | --------- | ------------ |
| bytes         | 表示该平面的字节                     | Uint8List | yes          |
| bytesPerRow   | 此颜色平面的行步长，以字节为单位     | int       | yes          |
| bytesPerPixel | 当可用时，相邻像素样本之间的字节距离 | int       | yes          |
| height        | 像素缓冲区的高度，如果可用           | int       | yes          |
| width         | 像素缓冲区的宽度，如果可用           | int       | yes          |

### FlashMode

| Name             | Description                          | Type      | ohos Support |
| ---------------- | ------------------------------------ | --------- | ------------ |
| FlashMode.off    | 拍照时不要使用闪光灯                 | Uint8List | yes          |
| FlashMode.auto   | 让设备决定在拍照时是否使用闪光灯       | int       | yes          |
| FlashMode.always | 拍照时总是使用闪光灯                 | int       | yes          |
| FlashMode.torch  | 打开闪光灯，并保持打开状态，直到关闭 | int       | yes          |

### ExposureMode

| Name                | Description            | Type      | ohos Support |
| ------------------- | ---------------------- | --------- | ------------ |
| ExposureMode.auto   | 自动确定曝光设置       | Uint8List | yes          |
| ExposureMode.locked | 锁定当前确定的曝光设置 | int       | yes          |

### FocusMode

| Name             | Description            | Type      | ohos Support |
| ---------------- | ---------------------- | --------- | ------------ |
| FocusMode.auto   | 自动确定焦点设置       | Uint8List | yes          |
| FocusMode.locked | 锁定当前确定的焦点设置 | int       | yes          |

## 5. 遗留问题

- [ ] ohos 端 执行setDescriptionWhileRecording 设置无效，并返回错误提示：

  ```
  Camera switching is not supported while recording.
  ```

  

## 6. 开源协议

本项目基于 [The MIT License (MIT)](https://gitcode.com/CPF-Flutter/flutter_packages/blob/br_camera-v0.11.3_ohos/packages/camera/camera_ohos/LICENSE) ，请自由地享受和参与开源。



> 模板版本: v0.0.1  
