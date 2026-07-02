

<p align="center">
  <h1 align="center"> <code>camera_ohos</code> </h1>
</p>





This project is based on  [camera@0.11.3](https://pub.dev/packages/camera/versions/0.11.3)

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  camera:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/camera/camera
      # ref: camera-v0.11.3-ohos-1.0.0
      ref: TAG  #   Select a TAG according to the TAG version table below
...
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG Version Table**

| Flutter Version | TAG | Branch |
| :--- | :--- | :--- |
| 3.7 | `camera-v0.10.5_5-ohos-1.0.0` | `master` |
| 3.22 | `camera-v0.11.0_2-ohos-1.0.0` | `br_camera-v0.11.0+2_ohos` |
| 3.27 | `camera-v0.11.1-ohos-1.0.0` | `br_camera-v0.11.1_ohos` |
| 3.35 | `camera-v0.11.3-ohos-1.0.0` | `br_camera-v0.11.3_ohos` |

## 1.2 Usage

For use cases [ohos/example](./example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;

### 2.2 **Permission Requirements**

The following permissions include the `system_basic` permission, but the default application permission is `normal`. Only the `normal` permission can be used. Therefore, the error **9568289 ** may be reported during the installation of the HAP package. For details, see [Document](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#section9568289-the-installation-fails-because-the-permission-request-fails) Change the application level to `system_basic`.

####  2.2.1 **Add permissions to the module.json5 file in the entry directory.**

Open  `entry/src/main/module.json5` and add the following information:

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

#### 2.2.2 **Add the reason for applying for the preceding permission to the entry directory.**

Open  `entry/src/main/resources/base/element/string.json` and add the following information:

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

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| availableCameras()                                           | Future<List<[CameraDescription](#CameraDescription)>> | Completes with a list of available cameras.                  | function | yes          |
| createCamera([CameraDescription](#CameraDescription) cameraDescription, [ResolutionPreset](#ResolutionPreset)? resolutionPreset, { bool enableAudio = false }) | Future<int>                                           | Creates an uninitialized camera instance and returns the cameraId. | function | yes          |
| initializeCamera(int cameraId, {[ImageFormatGroup](#ImageFormatGroup) imageFormatGroup = ImageFormatGroup.unknown}) | Future<void>                                          | Initializes the camera on the device.                        | function | yes          |
| dispose(int cameraId)                                        | Future<void>                                          | Releases the resources of this camera.                       | function | yes          |
| lockCaptureOrientation(int cameraId,   [DeviceOrientation](#DeviceOrientation) orientation, ) | Future<void>                                          | Locks the capture orientation.                               | function | yes          |
| unlockCaptureOrientation(int cameraId)                       | Future<void>                                          | Unlocks the capture orientation.                             | function | yes          |
| takePicture(int cameraId)                                    | Future<XFile>                                         | Captures an image and returns the file where it was saved.   | function | yes          |
| prepareForVideoRecording()                                   | Future<void>                                          | Prepare the capture session for video recording.             | function | yes          |
| startVideoRecording(int cameraId)                            | Future<void>                                          | Starts a video recording.                                    | function | yes          |
| startVideoCapturing([VideoCaptureOptions](#VideoCaptureOptions) options) | Future<void>                                          | Starts a video recording and/or streaming session.           | function | yes          |
| stopVideoRecording(int cameraId)                             | Future<XFile>                                         | Stops the video recording and returns the file where it was saved. | function | yes          |
| pauseVideoRecording(int cameraId)                            | Future<void>                                          | Pause video recording.                                       | function | yes          |
| resumeVideoRecording(int cameraId)                           | Future<void>                                          | Resume video recording after pausing.                        | function | yes          |
| setFlashMode(int cameraId, [FlashMode](#FlashMode) mode)     | Future<void>                                          | Sets the flash mode for the selected camera.                 | function | yes          |
| setExposureMode(int cameraId, [ExposureMode](#ExposureMode) mode) | Future<void>                                          | Sets the exposure mode for taking pictures.                  | function | yes          |
| setExposurePoint(int cameraId, Point<double>? point)         | Future<void>                                          | Sets the exposure point for automatically determining the exposure values. | function | yes          |
| getMinExposureOffset(int cameraId)                           | Future<double>                                        | Gets the minimum supported exposure offset for the selected camera in EV units. | function | yes          |
| getMaxExposureOffset(int cameraId)                           | Future<double>                                        | Gets the maximum supported exposure offset for the selected camera in EV units. | function | yes          |
| getExposureOffsetStepSize(int cameraId)                      | Future<double>                                        | Gets the supported step size for exposure offset for the selected camera in EV units. | function | yes          |
| setExposureOffset(int cameraId, double offset)               | Future<double>                                        | Sets the exposure offset for the selected camera.            | function | yes          |
| setFocusMode(int cameraId, [FocusMode](#FocusMode) mode)     | Future<void>                                          | Sets the focus mode for taking pictures.                     | function | yes          |
| setFocusPoint(int cameraId, Point<double>? point)            | Future<void>                                          | Sets the focus point for automatically determining the focus values. | function | yes          |
| getMaxZoomLevel(int cameraId)                                | Future<double>                                        | Gets the maximum supported zoom level for the selected camera. | function | yes          |
| getMinZoomLevel(int cameraId)                                | Future<double>                                        | Gets the minimum supported zoom level for the selected camera. | function | yes          |
| setZoomLevel(int cameraId, double zoom)                      | Future<void>                                          | Set the zoom level for the selected camera.                  | function | yes          |
| pausePreview(int cameraId)                                   | Future<void>                                          | Pause the active preview on the current frame for the selected camera. | function | yes          |
| resumePreview(int cameraId)                                  | Future<void>                                          | Resume the paused preview for the selected camera.           | function | yes          |
| setDescriptionWhileRecording([CameraDescription](#CameraDescription) description) | Future<void>                                          | Sets the active camera while recording.                      | function | no           |

## 4. Properties

### CameraDescription

| Name              | Description                                                  | Type                                        | ohos Support |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------- | ------------ |
| name              | The name of the camera device.                               | String                                      | yes          |
| lensDirection     | The direction the camera is facing.                          | [CameraLensDirection](#CameraLensDirection) | yes          |
| sensorOrientation | Clockwise angle through which the output image needs to be rotated to be upright on the device screen in its native orientation. | int                                         | yes          |
| lensType          | The type of lens the camera has.                             | [CameraLensType](#CameraLensType)           | yes          |

### CameraLensDirection

| Name                         | Description                                                  | Type | ohos Support |
| ---------------------------- | ------------------------------------------------------------ | ---- | ------------ |
| CameraLensDirection.front    | Front facing camera (a user looking at the screen is seen by the camera). | enum | yes          |
| CameraLensDirection.back     | Back facing camera (a user looking at the screen is not seen by the camera). | enum | yes          |
| CameraLensDirection.external | External camera which may not be mounted to the device.      | enum | yes          |

### CameraLensType

| Name                     | Description                                                  | Type | ohos Support |
| ------------------------ | ------------------------------------------------------------ | ---- | ------------ |
| CameraLensType.wide      | A built-in wide-angle camera device type.                    | enum | yes          |
| CameraLensType.telephoto | A built-in camera device type with a longer focal length than a wide-angle camera. | enum | yes          |
| CameraLensType.ultraWide | A built-in camera device type with a shorter focal length than a wide-angle camera. | enum | yes          |
| CameraLensType.unknown   | Unknown camera device type.                                  | enum | yes          |

### ResolutionPreset

| Name                       | Description                              | Type | ohos Support |
| -------------------------- | ---------------------------------------- | ---- | ------------ |
| ResolutionPreset.low       | 352x288 on iOS, ~240p on Android and Web | enum | yes          |
| ResolutionPreset.medium    | 480p                                     | enum | yes          |
| ResolutionPreset.high      | 720p                                     | enum | yes          |
| ResolutionPreset.veryHigh  | 1080p                                    | enum | yes          |
| ResolutionPreset.ultraHigh | 2160p                                    | enum | yes          |
| ResolutionPreset.max       | The highest resolution available.        | enum | yes          |

### imageFormatGroup 

| Name                      | Description                                                  | Type | ohos Support |
| ------------------------- | ------------------------------------------------------------ | ---- | ------------ |
| ImageFormatGroup.unknown  | The image format does not fit into any specific group.       | enum | no           |
| ImageFormatGroup.yuv420   | Multi-plane YUV 420 format.                                  | enum | no           |
| ImageFormatGroup.bgra8888 | 32-bit BGRA.                                                 | enum | no           |
| ImageFormatGroup.jpeg     | 32-bit RGB image encoded into JPEG bytes.                    | enum | yes          |
| ImageFormatGroup.nv21     | YCrCb format used for images, which uses the NV21 encoding format. | enum | no           |

### DeviceOrientation

| Name                             | Description                                                  | Type | ohos Support |
| -------------------------------- | ------------------------------------------------------------ | ---- | ------------ |
| DeviceOrientation.portraitUp     | If the device shows its boot logo in portrait, then the boot logo is shown in [portraitUp]. | enum | yes          |
| DeviceOrientation.landscapeLeft  | The orientation that is 90 degrees counterclockwise from [portraitUp]. | enum | yes          |
| DeviceOrientation.portraitDown   | The orientation that is 180 degrees from [portraitUp].       | enum | yes          |
| DeviceOrientation.landscapeRight | The orientation that is 90 degrees clockwise from [portraitUp]. | enum | yes          |

### VideoCaptureOptions

| Name           | Description                                | Type                             | ohos Support |
| -------------- | ------------------------------------------ | -------------------------------- | ------------ |
| cameraId       | The ID of the camera to use for capturing. | int                              | yes          |
| streamCallback | An optional callback to enable streaming.  | Function(CameraImageData image)? | yes          |
| streamOptions  | Configuration options for streaming.        | CameraImageStreamOptions?        | yes          |

### CameraImageData

| Name               | Description                                              | Type                                        | ohos Support |
| ------------------ | -------------------------------------------------------- | ------------------------------------------- | ------------ |
| format             | Format of the image provided.                            | [CameraImageFormat](#CameraImageFormat)     | yes          |
| planes             | The pixels planes for this image.                        | List<[CameraImagePlane](#CameraImagePlane)> | yes          |
| height             | Height of the image in pixels.                           | int                                         | yes          |
| width              | Width of the image in pixels.                            | int                                         | yes          |
| lensAperture       | The aperture settings for this image.                    | double                                      | yes          |
| sensorExposureTime | The sensor exposure time for this image in nanoseconds.  | int                                         | yes          |
| sensorSensitivity  | The sensor sensitivity in standard ISO arithmetic units. | double                                      | yes          |

### CameraImageStreamOptions

| Name          | Description                                                  | Type      | ohos Support |
| ------------- | ------------------------------------------------------------ | --------- | ------------ |
| bytes         | Bytes representing this plane.                               | Uint8List | yes          |
| bytesPerRow   | The row stride for this color plane, in bytes.               | int       | yes          |
| bytesPerPixel | The distance between adjacent pixel samples in bytes, when available. | int       | yes          |
| height        | Height of the pixel buffer, when available.                  | int       | yes          |
| width         | Width of the pixel buffer, when available.                   | int       | yes          |

### FlashMode

| Name             | Description                                                  | Type      | ohos Support |
| ---------------- | ------------------------------------------------------------ | --------- | ------------ |
| FlashMode.off    | Do not use the flash when taking a picture.                  | Uint8List | yes          |
| FlashMode.auto   | Let the device decide whether to flash the camera when taking a picture. | int       | yes          |
| FlashMode.always | Always use the flash when taking a picture.                  | int       | yes          |
| FlashMode.torch  | Turns on the flash light and keeps it on until switched off. | int       | yes          |

### ExposureMode

| Name                | Description                                      | Type      | ohos Support |
| ------------------- | ------------------------------------------------ | --------- | ------------ |
| ExposureMode.auto   | Automatically determine exposure settings.       | Uint8List | yes          |
| ExposureMode.locked | Lock the currently determined exposure settings. | int       | yes          |

### FocusMode

| Name             | Description                                   | Type      | ohos Support |
| ---------------- | --------------------------------------------- | --------- | ------------ |
| FocusMode.auto   | Automatically determine focus settings.       | Uint8List | yes          |
| FocusMode.locked | Lock the currently determined focus settings. | int       | yes          |



## 5. Known Issues

- [ ] On the OpenHarmony platform, invoking `setDescriptionWhileRecording` has no effect and returns an error message: 

  ```
  Camera switching is not supported while recording.
  ```

  

## 6. **License**

This project is licensed under [The MIT License (MIT)](https://gitcode.com/CPF-Flutter/flutter_packages/blob/br_camera-v0.11.3_ohos/packages/camera/camera_ohos/LICENSE).



> Template version: v0.0.1
