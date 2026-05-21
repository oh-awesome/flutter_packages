<p align="center">
  <h1 align="center"> <code>camera_ohos</code> </h1>
</p>

This project is based on [camera@0.12.0+1](https://pub.dev/packages/camera/versions/0.12.0+1).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  camera_ohos:
    git: 
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/camera/camera_ohos
      ref: br_camera-v0.12.0+1_ohos
```

Run the following command:

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For usage examples, see [example](./example).

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.2.650; ROM: 6.1.0.117 SP6;

### 2.2 **Permission Requirements**

The following permissions include the `system_basic` permission, but the default application permission is `normal`. Only the `normal` permission can be used. Therefore, the error \*\*9568289 \*\* may be reported during the installation of the HAP package. For details, see [Document](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__安装hap时提示code9568289-error-install-failed-due-to-grant-request-permissions-failed) Change the application level to `system_basic`.

#### 2.2.1 **Add permissions to the module.json5 file in the entry directory.**

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

> \[!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                                                                                                                                                           | return value                                           | Description                                                               | Type     | ohos Support |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------- | -------- | ------------ |
| availableCameras()                                                                                                                                             | Future\<List<[CameraDescription](#CameraDescription)>> | Gets the list of available cameras.                                       | function | yes          |
| createCamera([CameraDescription](#CameraDescription) cameraDescription, [ResolutionPreset](#ResolutionPreset)? resolutionPreset, { bool enableAudio = false }) | Future<int>                                            | Creates an uninitialized camera instance and returns its `cameraId`.      | function | yes          |
| createCameraWithSettings([CameraDescription](#CameraDescription) cameraDescription, MediaSettings? mediaSettings)                                              | Future<int>                                            | Creates a camera instance with media settings and returns its `cameraId`. | function | yes          |
| initializeCamera(int cameraId, {[ImageFormatGroup](#ImageFormatGroup) imageFormatGroup = ImageFormatGroup.unknown})                                            | Future<void>                                           | Initializes the camera on the device.                                     | function | yes          |
| dispose(int cameraId)                                                                                                                                          | Future<void>                                           | Releases resources used by the camera.                                    | function | yes          |
| onCameraInitialized(int cameraId)                                                                                                                              | Stream<CameraInitializedEvent>                         | Listens for camera initialized events.                                    | function | yes          |
| onCameraResolutionChanged(int cameraId)                                                                                                                        | Stream<CameraResolutionChangedEvent>                   | Listens for camera resolution changed events.                             | function | yes          |
| onCameraClosing(int cameraId)                                                                                                                                  | Stream<CameraClosingEvent>                             | Listens for camera closing events.                                        | function | yes          |
| onCameraError(int cameraId)                                                                                                                                    | Stream<CameraErrorEvent>                               | Listens for camera error events.                                          | function | yes          |
| onVideoRecordedEvent(int cameraId)                                                                                                                             | Stream<VideoRecordedEvent>                             | Listens for video recording completed events.                             | function | yes          |
| onDeviceOrientationChanged()                                                                                                                                   | Stream<DeviceOrientationChangedEvent>                  | Listens for device orientation changed events.                            | function | yes          |
| lockCaptureOrientation(int cameraId, [DeviceOrientation](#DeviceOrientation) orientation)                                                                      | Future<void>                                           | Locks the capture orientation.                                            | function | yes          |
| unlockCaptureOrientation(int cameraId)                                                                                                                         | Future<void>                                           | Unlocks the capture orientation.                                          | function | yes          |
| takePicture(int cameraId)                                                                                                                                      | Future<XFile>                                          | Takes a picture and returns the saved file path.                          | function | yes          |
| setImageFileFormat(int cameraId, ImageFileFormat format)                                                                                                       | Future<void>                                           | Sets the output image format for taking pictures.                         | function | yes          |
| prepareForVideoRecording()                                                                                                                                     | Future<void>                                           | Prepares the capture session required for video recording.                | function | no           |
| startVideoRecording(int cameraId)                                                                                                                              | Future<void>                                           | Starts video recording.                                                   | function | yes          |
| startVideoCapturing([VideoCaptureOptions](#VideoCaptureOptions) options)                                                                                       | Future<void>                                           | Starts a video recording and/or streaming session.                        | function | yes          |
| stopVideoRecording(int cameraId)                                                                                                                               | Future<XFile>                                          | Stops video recording and returns the saved video file path.              | function | yes          |
| pauseVideoRecording(int cameraId)                                                                                                                              | Future<void>                                           | Pauses video recording.                                                   | function | yes          |
| resumeVideoRecording(int cameraId)                                                                                                                             | Future<void>                                           | Resumes video recording after pause.                                      | function | yes          |
| supportsImageStreaming()                                                                                                                                       | bool                                                   | Indicates whether image streaming is supported on the current platform.   | function | yes          |
| onStreamedFrameAvailable(int cameraId, {CameraImageStreamOptions? options})                                                                                    | Stream<CameraImageData>                                | Subscribes to the camera frame data stream.                               | function | yes          |
| setFlashMode(int cameraId, [FlashMode](#FlashMode) mode)                                                                                                       | Future<void>                                           | Sets the flash mode.                                                      | function | yes          |
| setExposureMode(int cameraId, [ExposureMode](#ExposureMode) mode)                                                                                              | Future<void>                                           | Sets the exposure mode.                                                   | function | yes          |
| setExposurePoint(int cameraId, Point<double>? point)                                                                                                           | Future<void>                                           | Sets the auto-exposure metering point.                                    | function | yes          |
| getMinExposureOffset(int cameraId)                                                                                                                             | Future<double>                                         | Gets the minimum exposure compensation value.                             | function | yes          |
| getMaxExposureOffset(int cameraId)                                                                                                                             | Future<double>                                         | Gets the maximum exposure compensation value.                             | function | yes          |
| getExposureOffsetStepSize(int cameraId)                                                                                                                        | Future<double>                                         | Gets the exposure compensation step size.                                 | function | yes          |
| setExposureOffset(int cameraId, double offset)                                                                                                                 | Future<double>                                         | Sets the exposure compensation value.                                     | function | yes          |
| setFocusMode(int cameraId, [FocusMode](#FocusMode) mode)                                                                                                       | Future<void>                                           | Sets the focus mode.                                                      | function | yes          |
| setFocusPoint(int cameraId, Point<double>? point)                                                                                                              | Future<void>                                           | Sets the auto-focus point.                                                | function | yes          |
| getMaxZoomLevel(int cameraId)                                                                                                                                  | Future<double>                                         | Gets the maximum zoom level.                                              | function | yes          |
| getMinZoomLevel(int cameraId)                                                                                                                                  | Future<double>                                         | Gets the minimum zoom level.                                              | function | yes          |
| setZoomLevel(int cameraId, double zoom)                                                                                                                        | Future<void>                                           | Sets the zoom level.                                                      | function | yes          |
| getSupportedVideoStabilizationModes(int cameraId)                                                                                                              | Future\<Iterable<VideoStabilizationMode>>              | Queries the video stabilization modes supported by the device.            | function | yes          |
| setVideoStabilizationMode(int cameraId, VideoStabilizationMode mode)                                                                                           | Future<void>                                           | Sets the video stabilization mode.                                        | function | yes          |
| pausePreview(int cameraId)                                                                                                                                     | Future<void>                                           | Pauses the current preview frame.                                         | function | yes          |
| resumePreview(int cameraId)                                                                                                                                    | Future<void>                                           | Resumes the paused preview.                                               | function | yes          |
| setDescriptionWhileRecording([CameraDescription](#CameraDescription) description)                                                                              | Future<void>                                           | Switches the active camera during recording.                              | function | no           |
| buildPreview(int cameraId)                                                                                                                                     | Widget                                                 | Builds the preview widget.                                                | function | yes          |

## 4. Properties

### CameraDescription

| Name              | Description                                                                            | Type                                        | ohos Support |
| ----------------- | -------------------------------------------------------------------------------------- | ------------------------------------------- | ------------ |
| name              | Camera device name.                                                                    | String                                      | yes          |
| lensDirection     | The direction the camera is facing.                                                    | [CameraLensDirection](#CameraLensDirection) | yes          |
| sensorOrientation | The rotation angle needed for the output image to appear upright on the device screen. | int                                         | yes          |
| lensType          | The type of lens equipped on the camera.                                               | [CameraLensType](#CameraLensType)           | yes          |

### CameraLensDirection

| Name                         | Description                                               | Type | ohos Support |
| ---------------------------- | --------------------------------------------------------- | ---- | ------------ |
| CameraLensDirection.front    | Front camera. A user looking at the screen is visible.    | enum | yes          |
| CameraLensDirection.back     | Rear camera. A user looking at the screen is not visible. | enum | yes          |
| CameraLensDirection.external | External camera that may not be mounted on the device.    | enum | yes          |

### CameraLensType

| Name                     | Description                                                                       | Type | ohos Support |
| ------------------------ | --------------------------------------------------------------------------------- | ---- | ------------ |
| CameraLensType.wide      | Built-in wide-angle camera device type.                                           | enum | yes          |
| CameraLensType.telephoto | Built-in camera device type with a longer focal length than a wide-angle camera.  | enum | yes          |
| CameraLensType.ultraWide | Built-in camera device type with a shorter focal length than a wide-angle camera. | enum | yes          |
| CameraLensType.unknown   | Unknown camera device type.                                                       | enum | yes          |

### ResolutionPreset

| Name                       | Description                               | Type | ohos Support |
| -------------------------- | ----------------------------------------- | ---- | ------------ |
| ResolutionPreset.low       | 352x288 on iOS, \~240p on Android and Web | enum | yes          |
| ResolutionPreset.medium    | 480p                                      | enum | yes          |
| ResolutionPreset.high      | 720p                                      | enum | yes          |
| ResolutionPreset.veryHigh  | 1080p                                     | enum | yes          |
| ResolutionPreset.ultraHigh | 2160p                                     | enum | yes          |
| ResolutionPreset.max       | The highest resolution available.         | enum | yes          |

### imageFormatGroup

| Name                      | Description                                             | Type | ohos Support |
| ------------------------- | ------------------------------------------------------- | ---- | ------------ |
| ImageFormatGroup.unknown  | The image format does not belong to any specific group. | enum | no           |
| ImageFormatGroup.yuv420   | Multi-plane YUV 420 format.                             | enum | no           |
| ImageFormatGroup.bgra8888 | 32-bit BGRA.                                            | enum | no           |
| ImageFormatGroup.jpeg     | 32-bit RGB image encoded into JPEG bytes.               | enum | yes          |
| ImageFormatGroup.nv21     | YCrCb image format using NV21 encoding.                 | enum | no           |

### DeviceOrientation

| Name                             | Description                                                              | Type | ohos Support |
| -------------------------------- | ------------------------------------------------------------------------ | ---- | ------------ |
| DeviceOrientation.portraitUp     | If the device boots in portrait, the boot logo is shown in `portraitUp`. | enum | yes          |
| DeviceOrientation.landscapeLeft  | The orientation rotated 90 degrees counterclockwise from `portraitUp`.   | enum | yes          |
| DeviceOrientation.portraitDown   | The orientation rotated 180 degrees from `portraitUp`.                   | enum | yes          |
| DeviceOrientation.landscapeRight | The orientation rotated 90 degrees clockwise from `portraitUp`.          | enum | yes          |

### VideoCaptureOptions

| Name           | Description                                 | Type                             | ohos Support |
| -------------- | ------------------------------------------- | -------------------------------- | ------------ |
| cameraId       | The ID of the camera used for capturing.    | int                              | yes          |
| streamCallback | Optional callback used to enable streaming. | Function(CameraImageData image)? | yes          |
| streamOptions  | Streaming configuration options.            | CameraImageStreamOptions?        | yes          |

### CameraImageData

| Name               | Description                               | Type                                        | ohos Support |
| ------------------ | ----------------------------------------- | ------------------------------------------- | ------------ |
| format             | Format of the provided image.             | [CameraImageFormat](#CameraImageFormat)     | yes          |
| planes             | Pixel planes of the image.                | List<[CameraImagePlane](#CameraImagePlane)> | yes          |
| height             | Image height in pixels.                   | int                                         | yes          |
| width              | Image width in pixels.                    | int                                         | yes          |
| lensAperture       | Aperture setting of the image.            | double                                      | yes          |
| sensorExposureTime | Sensor exposure time in nanoseconds.      | int                                         | yes          |
| sensorSensitivity  | Sensor sensitivity in standard ISO units. | double                                      | yes          |

### CameraImageStreamOptions

| Name          | Description                                                       | Type      | ohos Support |
| ------------- | ----------------------------------------------------------------- | --------- | ------------ |
| bytes         | Bytes representing the plane.                                     | Uint8List | yes          |
| bytesPerRow   | Row stride of the color plane in bytes.                           | int       | yes          |
| bytesPerPixel | Distance between adjacent pixel samples in bytes, when available. | int       | yes          |
| height        | Height of the pixel buffer, when available.                       | int       | yes          |
| width         | Width of the pixel buffer, when available.                        | int       | yes          |

### FlashMode

| Name             | Description                                                       | Type      | ohos Support |
| ---------------- | ----------------------------------------------------------------- | --------- | ------------ |
| FlashMode.off    | Do not use flash when taking a picture.                           | Uint8List | yes          |
| FlashMode.auto   | Let the device decide whether to use flash when taking a picture. | int       | yes          |
| FlashMode.always | Always use flash when taking a picture.                           | int       | yes          |
| FlashMode.torch  | Turn on the flashlight and keep it on until disabled.             | int       | yes          |

### ExposureMode

| Name                | Description                                       | Type      | ohos Support |
| ------------------- | ------------------------------------------------- | --------- | ------------ |
| ExposureMode.auto   | Automatically determines exposure settings.       | Uint8List | yes          |
| ExposureMode.locked | Locks the currently determined exposure settings. | int       | yes          |

### FocusMode

| Name             | Description                                    | Type      | ohos Support |
| ---------------- | ---------------------------------------------- | --------- | ------------ |
| FocusMode.auto   | Automatically determines focus settings.       | Uint8List | yes          |
| FocusMode.locked | Locks the currently determined focus settings. | int       | yes          |

### VideoStabilizationMode

| Name                          | Description                                                       | Type      | ohos Support |
| ----------------------------- | ----------------------------------------------------------------- | --------- | ------------ |
| VideoStabilizationMode.off    | Video stabilization is disabled                                   | Uint8List | yes          |
| VideoStabilizationMode.level1 | Least stabilized video stabilization mode with the least latency. | int       | yes          |
| VideoStabilizationMode.level2 | More stabilized video with more latency.                          | int       | yes          |
| VideoStabilizationMode.level3 | Most stabilized video with the most latency.                      | int       | yes          |

## 5. Known Issues

- [ ] On the ohos platform, invoking `setDescriptionWhileRecording` is ineffective and returns the following error:
  ```
  Camera switching is not supported while recording.
  ```
- [ ] The FPS setting on the OHOS side is currently not effective.
- [ ] The video preparation API `prepareForVideoRecording()` is not supported on the ohos platform and is currently a no-op implementation.

## 6. Others

## 7. License

This project is based on [The MIT License (MIT)](./LICENSE). Feel free to use and contribute.
