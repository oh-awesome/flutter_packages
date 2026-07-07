

<p align="center">
  <h1 align="center"> <code>camera_ohos</code> </h1>
</p>



This project is developed based on [camera@0.10.5+4](https://pub.dev/packages/camera/versions/0.10.5+4).

## 1. Installation and Usage

### 1.1 Installation

Navigate to your project directory and add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  camera_ohos:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/camera/camera_ohos
      # ref: camera-v0.10.5_5-ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below
```

Run the command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.35 | `camera-v0.11.3-ohos-1.0.0` | `br_camera-v0.11.3_ohos` |
| 3.27 | `camera-v0.11.1-ohos-1.0.0` | `br_camera-v0.11.1_ohos` |
| 3.22 | `camera-v0.11.0_2-ohos-1.0.0` | `br_camera-v0.11.0+2_ohos` |
| 3.7 | `camera-v0.10.5_5-ohos-1.0.0` | `master` |

<!-- tabs:end -->

### 1.2 Usage

For usage examples, see [ohos/example](./example).

## 2. Constraints

### 2.1 Compatibility

Tested and passed on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 Permission Requirements

Some of the following permissions require the `system_basic` privilege level, while the default application privilege level is `normal`, which can only use `normal`-level permissions. As a result, you may encounter error **9568289** when installing the HAP package. Please refer to the [documentation](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) to change the application level to `system_basic`.

#### 2.2.1 Add permissions in module.json5 under the entry directory

Open `entry/src/main/module.json5` and add:

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

#### 2.2.2 Add the reason for requesting the above permissions under the entry directory

Open `entry/src/main/resources/base/element/string.json` and add:

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

> [!TIP] An **ohos Support** value of **yes** means the property is supported on the ohos platform; **no** means not supported. The usage method is consistent across platforms, and the behavior is aligned with iOS or Android.

| Name                                                         | return value                                          | Description                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | -------------------------------------------- | -------- | ------------ |
| availableCameras()                                           | Future<List<[CameraDescription](#CameraDescription)>> | Gets the list of available cameras.                           | function | yes          |
| createCamera([CameraDescription](#CameraDescription) cameraDescription, [ResolutionPreset](#ResolutionPreset)? resolutionPreset, { bool enableAudio = false }) | Future<int>                                           | Creates an uninitialized camera instance and returns its cameraId. | function | yes          |
| initializeCamera(int cameraId, {[ImageFormatGroup](#ImageFormatGroup) imageFormatGroup = ImageFormatGroup.unknow}) | Future<void>                                          | Initializes the camera on the device.                         | function | yes          |
| dispose(int cameraId)                                        | Future<void>                                          | Releases the resources held by this camera.                       | function | yes          |
| lockCaptureOrientation(int cameraId,   [DeviceOrientation](#DeviceOrientation) orientation, ) | Future<void>                                          | Locks the capture orientation.                                 | function | yes          |
| unlockCaptureOrientation(int cameraId)                       | Future<void>                                          | Unlocks the capture orientation.                                 | function | yes          |
| takePicture(int cameraId)                                    | Future<XFile>                                         | Takes a picture and returns the file path of the picture.                 | function | yes          |
| prepareForVideoRecording()                                   | Future<void>                                          | Prepares the capture session for video recording.                   | function | no           |
| startVideoRecording(int cameraId)                            | Future<void>                                          | Starts recording video.                                 | function | yes          |
| startVideoCapturing([VideoCaptureOptions](#VideoCaptureOptions) options) | Future<void>                                          | Starts a video recording and/or streaming session.                | function | yes          |
| stopVideoRecording(int cameraId)                             | Future<XFile>                                         | Stops video recording and returns the file path where the video is saved.     | function | yes          |
| pauseVideoRecording(int cameraId)                            | Future<void>                                          | Pauses video recording.                                 | function | yes          |
| resumeVideoRecording(int cameraId)                           | Future<void>                                          | Resumes video recording after pausing.                         | function | yes          |
| setFlashMode(int cameraId, [FlashMode](#FlashMode) mode)     | Future<void>                                          | Sets the flash mode.                               | function | yes          |
| setExposureMode(int cameraId, [ExposureMode](#ExposureMode) mode) | Future<void>                                          | Sets the exposure mode.                                 | function | yes          |
| setExposurePoint(int cameraId, Point<double>? point)         | Future<void>                                          | Sets the exposure point for auto exposure.                     | function | yes          |
| getMinExposureOffset(int cameraId)                           | Future<double>                                        | Gets the minimum exposure offset value.                           | function | yes          |
| getMaxExposureOffset(int cameraId)                           | Future<double>                                        | Gets the maximum exposure offset value.                           | function | yes          |
| getExposureOffsetStepSize(int cameraId)                      | Future<double>                                        | Gets the exposure offset step size.                             | function | yes          |
| setExposureOffset(int cameraId, double offset)               | Future<double>                                        | Sets the exposure offset value.                               | function | yes          |
| setFocusMode(int cameraId, [FocusMode](#FocusMode) mode)     | Future<void>                                          | Sets the focus mode.                                 | function | yes          |
| setFocusPoint(int cameraId, Point<double>? point)            | Future<void>                                          | Sets the focus point for auto focus.                         | function | yes          |
| getMaxZoomLevel(int cameraId)                                | Future<double>                                        | Gets the maximum zoom level.                             | function | yes          |
| getMinZoomLevel(int cameraId)                                | Future<double>                                        | Gets the minimum zoom level.                             | function | yes          |
| setZoomLevel(int cameraId, double zoom)                      | Future<void>                                          | Sets the zoom level.                                 | function | yes          |
| pausePreview(int cameraId)                                   | Future<void>                                          | Pauses preview of the current frame.                         | function | yes          |
| resumePreview(int cameraId)                                  | Future<void>                                          | Resumes a paused preview.                         | function | yes          |
| setDescriptionWhileRecording([CameraDescription](#CameraDescription) description) | Future<void>                                          | Switches the camera currently in use during recording.             | function | no           |

## 4. Properties

### CameraDescription

| Name              | Description                                                | Type                                        | ohos Support |
| ----------------- | ---------------------------------------------------------- | ------------------------------------------- | ------------ |
| name              | Camera device name.                                               | String                                      | yes          |
| lensDirection     | The direction the camera faces.                                         | [CameraLensDirection](#CameraLensDirection) | yes          |
| sensorOrientation | The angle the output image needs to be rotated to be displayed upright in its original orientation on the device screen. | int                                         | yes          |
| lensType          | The type of lens equipped on the camera.                                       | [CameraLensType](#CameraLensType)           | yes          |

### CameraLensDirection

| Name                         | Description                                    | Type | ohos Support |
| ---------------------------- | ---------------------------------------------- | ---- | ------------ |
| CameraLensDirection.front    | Front camera (the user looks at the screen and the camera sees the user). | enum | yes          |
| CameraLensDirection.back     | Rear camera (when the user looks at the screen, the camera cannot see the user).   | enum | yes          |
| CameraLensDirection.external | External camera, may not be mounted on the device.               | enum | yes          |

### CameraLensType

| Name                     | Description                              | Type | ohos Support |
| ------------------------ | ---------------------------------------- | ---- | ------------ |
| CameraLensType.wide      | Built-in wide-angle camera device type.                     | enum | yes          |
| CameraLensType.telephoto | A built-in camera device type with a longer focal length than a wide-angle camera. | enum | yes          |
| CameraLensType.ultraWide | A built-in camera device type with a shorter focal length than a wide-angle camera. | enum | yes          |
| CameraLensType.unknown   | Unknown camera device type.                     | enum | yes          |

### ResolutionPreset

| Name                       | Description                              | Type | ohos Support |
| -------------------------- | ---------------------------------------- | ---- | ------------ |
| ResolutionPreset.low       | 352x288 on iOS, ~240p on Android and Web | enum | yes          |
| ResolutionPreset.medium    | 480p                                     | enum | yes          |
| ResolutionPreset.high      | 720p                                     | enum | yes          |
| ResolutionPreset.veryHigh  | 1080p                                    | enum | yes          |
| ResolutionPreset.ultraHigh | 2160p                                    | enum | yes          |
| ResolutionPreset.max       | Maximum available resolution.                         | enum | yes          |

### imageFormatGroup

| Name                      | Description                           | Type | ohos Support |
| ------------------------- | ------------------------------------- | ---- | ------------ |
| ImageFormatGroup.unknown  | The image format does not belong to any specific group.            | enum | no           |
| ImageFormatGroup.yuv420   | Multi-plane YUV 420 format.           | enum | no           |
| ImageFormatGroup.bgra8888 | 32-bit BGRA.                          | enum | no           |
| ImageFormatGroup.jpeg     | 32-bit RGB image encoded as JPEG bytes.           | enum | yes          |
| ImageFormatGroup.nv21     | YCrCb format for images, using the NV21 encoding format. | enum | no           |

### DeviceOrientation

| Name                             | Description                                                | Type | ohos Support |
| -------------------------------- | ---------------------------------------------------------- | ---- | ------------ |
| DeviceOrientation.portraitUp     | If the device displays in portrait at startup, the launch logo displays in [portraitUp]. | enum | yes          |
| DeviceOrientation.landscapeLeft  | Direction rotated 90 degrees counterclockwise from [portraitUp].                       | enum | yes          |
| DeviceOrientation.portraitDown   | Direction 180 degrees opposite to [portraitUp].                        | enum | yes          |
| DeviceOrientation.landscapeRight | Direction rotated 90 degrees clockwise from [portraitUp].                       | enum | yes          |

### VideoCaptureOptions

| Name           | Description                          | Type                             | ohos Support |
| -------------- | ------------------------------------ | -------------------------------- | ------------ |
| cameraId       | The ID of the camera used for capture.                 | int                              | yes          |
| streamCallback | An optional callback function for enabling streaming. | Function(CameraImageData image)? | yes          |
| streamOptions  | Configuration options for streaming.                     | CameraImageStreamOptions?        | yes          |

### CameraImageData

| Name               | Description                         | Type                                        | ohos Support |
| ------------------ | ----------------------------------- | ------------------------------------------- | ------------ |
| format             | The format of the provided image.                    | [CameraImageFormat](#CameraImageFormat)     | yes          |
| planes             | The pixel planes of this image.                  | List<[CameraImagePlane](#CameraImagePlane)> | yes          |
| height             | The height of the image (pixels).                  | int                                         | yes          |
| width              | The width of the image (in pixels).          | int                                         | yes          |
| lensAperture       | The aperture setting for this image.                  | double                                      | yes          |
| sensorExposureTime | The sensor exposure time for this image in nanoseconds.        | int                                         | yes          |
| sensorSensitivity  | Sensor sensitivity, in standard ISO arithmetic units. | double                                      | yes          |

### CameraImageStreamOptions

| Name          | Description                          | Type      | ohos Support |
| ------------- | ------------------------------------ | --------- | ------------ |
| bytes         | Bytes representing this plane.                     | Uint8List | yes          |
| bytesPerRow   | The row stride for this color plane, in bytes.     | int       | yes          |
| bytesPerPixel | The byte distance between adjacent pixel samples, when available. | int       | yes          |
| height        | The height of the pixel buffer, if available.           | int       | yes          |
| width         | The width of the pixel buffer, if available.           | int       | yes          |

### FlashMode

| Name             | Description                          | Type      | ohos Support |
| ---------------- | ------------------------------------ | --------- | ------------ |
| FlashMode.off    | Do not use flash when taking a photo.                 | Uint8List | yes          |
| FlashMode.auto   | Let the device decide whether to fire the flash when taking a photo.       | int       | yes          |
| FlashMode.always | Always use flash when taking a photo.                 | int       | yes          |
| FlashMode.torch  | Turns the flash on and keeps it on until turned off. | int       | yes          |

### ExposureMode

| Name                | Description            | Type      | ohos Support |
| ------------------- | ---------------------- | --------- | ------------ |
| ExposureMode.auto   | Automatically determines exposure settings.       | Uint8List | yes          |
| ExposureMode.locked | Locks the currently determined exposure settings. | int       | yes          |

### FocusMode

| Name             | Description            | Type      | ohos Support |
| ---------------- | ---------------------- | --------- | ------------ |
| FocusMode.auto   | Automatically determines focus settings.       | Uint8List | yes          |
| FocusMode.locked | Locks the currently determined focus settings. | int       | yes          |

## 5. Known Issues

- [ ] On the ohos side, setDescriptionWhileRecording has no effect and returns the error:

  ```
  Camera switching is not supported while recording.
  ```

  

## 6. License

This project is licensed under [The MIT License (MIT)](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/camera/camera_ohos/LICENSE), feel free to use and contribute.



> Template version: v0.0.1  
