<p align="center">
  <h1 align="center"> <code>image_picker</code> </h1>
</p>


This project is based on [image_picker@1.0.4](https://pub.dev/packages/image_picker/versions/1.0.4).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/webview_flutter
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [ohos/example](./example/)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.1.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                                                         | return                  | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------- | ------------------------------------------------------------ | -------- | ------------ |
| pickImage({[ImageSource](#ImageSource ) source,double? maxWidth, double? maxHeight, int? imageQuality, [CameraDevice](#CameraDevice) preferredCameraDevice = CameraDevice.rear,bool requestFullMetadata = true}) | Future<XFile?>          | Returns an [XFile] object wrapping the image that was picked. | function | yes          |
| pickMultiImage({double? maxWidth, double? maxHeight, int? imageQuality, bool requestFullMetadata = true}) | Future<List<XFile>>     | Returns a [List<XFile>] object wrapping the images that were picked. | function | yes          |
| pickMedia({double? maxWidth, double? maxHeight, int? imageQuality, bool requestFullMetadata = true}) | Future<XFile?>          | Returns an [XFile] of the image or video that was picked.    | function | yes          |
| pickMultipleMedia({double? maxWidth, double? maxHeight, int? imageQuality, bool requestFullMetadata = true}) | Future<List<XFile>>     | Returns a [List<XFile>] with the images and/or videos that were picked. | function | yes          |
| pickVideo({[ImageSource](#ImageSource ) source，[CameraDevice](#CameraDevice ) preferredCameraDevice = CameraDevice.rear, Duration? maxDuration }) | Future<XFile?>          | Returns an [XFile] object wrapping the video that was picked. | function | yes          |
| retrieveLostData()                                           | Future<LostDataResponse | Retrieve the lost [XFile] when [pickImage], [pickMultiImage] or [pickVideo] failed because the MainActivity <br />is destroyed. (Android only) | function | no           |
| supportsImageSource([ImageSource](#ImageSource) source)      | bool                    | Returns true if the current platform implementation supports [source]. | function | no           |

## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### ImageSource

| Name                | Description                                                  | Type | ohos Support |
| ------------------- | ------------------------------------------------------------ | ---- | ------------ |
| ImageSource.camera  | Opens up the device camera, letting the user to take a new picture. | enum | yes          |
| ImageSource.gallery | Opens the user's photo gallery.                              | enum | yes          |

### CameraDevice

| Name               | Description           | Type | ohos Support |
| ------------------ | --------------------- | ---- | ------------ |
| CameraDevice.rear  | Use the rear camera.  | enum | yes          |
| CameraDevice.front | Use the front camera. | enum | yes          |



## 5. Known Issues

not

## 6. Others

## 7. License

This project is licensed under  [Apache License 2.0](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/image_picker/image_picker/LICENSE) .

> Template version: v0.0.1