<p align="center">
  <h1 align="center"> <code>camera</code> </h1>
</p>

This project is based on [camera@0.11.0+2](https://pub.dev/packages/camera/versions/0.11.0+2).

## 1. Installation & Usage

### 1.1 Installation

In your project directory, add the following dependency to `pubspec.yaml`:

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
      ref: TAG  #   Select a TAG according to the TAG version table below
...
```

Run the command

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

## 1.2 Example

For usage examples, see [ohos/example](./example/).

## 2. Constraints & Limitations

### 2.1 Compatibility

Tested with the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 HarmonyOS Adaptation Notes

To ensure recording stability, **this plugin makes the following modification on HarmonyOS**:

**Switching between front and rear cameras during recording is disabled**

Calling `CameraController.setDescriptionWhileRecording()` while in a recording state will have no effect and returns the error:

```
Camera switching is not supported while recording.
```

This modification only affects the HarmonyOS side; **the original behavior is preserved on Android/iOS**. Developers using this plugin should be aware of the platform difference and avoid calling camera-switching logic while recording, or use platform checks for adaptation.

## 3. API

> [!TIP] An "ohos Support" value of `yes` means the property is supported on the ohos platform; `no` means not supported; `partially` means partially supported. Usage is cross-platform consistent, and the behavior is aligned with iOS or Android.

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| availableCameras()                                           | Future<List<CameraDescription>>                       | Returns the list of available cameras on the device.     | function | yes          |
| CameraController(CameraDescription description, ResolutionPreset resolutionPreset, {bool enableAudio = true, ...}) | CameraController                                      | Creates a camera controller. | class    | yes          |
| initialize()                                                 | Future<void>                                          | Initializes the camera. | function | yes          |
| takePicture()                                                | Future<XFile>                                         | Takes a single picture. | function | yes          |
| startVideoRecording()                                        | Future<void>                                          | Starts video recording. | function | yes          |
| stopVideoRecording()                                         | Future<XFile>                                         | Stops video recording and returns the file. | function | yes          |
| pauseVideoRecording()                                        | Future<void>                                          | Pauses video recording. | function | yes          |
| resumeVideoRecording()                                       | Future<void>                                          | Resumes video recording. | function | yes          |
| setFlashMode(FlashMode mode)                                 | Future<void>                                          | Sets the flash mode. | function | yes          |
| setZoomLevel(double zoom)                                    | Future<void>                                          | Sets the zoom level. | function | yes          |
| setDescriptionWhileRecording(CameraDescription description)  | Future<void>                                          | Switches the camera during recording. (not supported on ohos) | function | no           |
| dispose()                                                    | Future<void>                                          | Releases camera resources. | function | yes          |

## 4. Known Issues

- Switching between front and rear cameras during recording is not supported.

## 5. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/camera/camera/LICENSE). Feel free to use and contribute.

> Template version: v0.0.1
