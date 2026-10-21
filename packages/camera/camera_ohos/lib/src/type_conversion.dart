// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';

import 'messages.g.dart';

/// Converts method channel call [data] for `receivedImageStreamData` to a
/// [CameraImageData].
CameraImageData cameraImageFromPlatformData(Map<dynamic, dynamic> data) {
  return CameraImageData(
      format: _cameraImageFormatFromPlatformData(data['format']),
      height: data['height'] as int,
      width: data['width'] as int,
      lensAperture: (data['lensAperture'] as num?)?.toDouble(),
      sensorExposureTime: data['sensorExposureTime'] as int?,
      sensorSensitivity: (data['sensorSensitivity'] as num?)?.toDouble(),
      planes: List<CameraImagePlane>.unmodifiable(
          (data['planes'] as List<dynamic>).map<CameraImagePlane>(
              (dynamic planeData) => _cameraImagePlaneFromPlatformData(
                  planeData as Map<dynamic, dynamic>))));
}

CameraImageFormat _cameraImageFormatFromPlatformData(dynamic data) {
  return CameraImageFormat(_imageFormatGroupFromPlatformData(data), raw: data);
}

ImageFormatGroup _imageFormatGroupFromPlatformData(dynamic data) {
  // Maps OHOS native camera.CameraFormat constants to [ImageFormatGroup]. The
  // full CameraFormat set is RGBA_8888(3) / YUV_420_SP(1003) / JPEG(2000) /
  // YCBCR_P010(2001) / YCRCB_P010(2002) / HEIC(2003). Constants without a
  // faithful [ImageFormatGroup] counterpart fall through to `unknown` on
  // purpose - mislabeling a stream is worse than reporting it as unknown:
  // - RGBA_8888(3): the closest group, `bgra8888`, describes BGRA byte order
  //   and would mislead consumers;
  // - YCBCR_P010(2001) / YCRCB_P010(2002): there is no 10-bit group;
  // - HEIC(2003): a HEIC container is not JPEG-decodable, so it must not be
  //   reported as `jpeg`.
  switch (data) {
    case 1003:
      // OHOS camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP: the image stream
      // delivers NV21 (YUV420 semi-planar, V first) frames from the preview
      // stream. Confirmed on device by chroma-pair order measurement, and per
      // the OpenHarmony docs which state this constant corresponds to NV21.
      // Mapped to nv21 to match Android's ImageFormatGroup.nv21 semantics
      // (single buffer, VU byte order).
      return ImageFormatGroup.nv21;
    case 2000:
      // OHOS camera.CameraFormat.CAMERA_FORMAT_JPEG: if a device's preview
      // profiles deliver JPEG-compressed stream frames, they are labeled jpeg.
      return ImageFormatGroup.jpeg;
  }

  return ImageFormatGroup.unknown;
}

CameraImagePlane _cameraImagePlaneFromPlatformData(Map<dynamic, dynamic> data) {
  return CameraImagePlane(
      bytes: data['bytes'] as Uint8List,
      bytesPerPixel: data['bytesPerPixel'] as int?,
      bytesPerRow: data['bytesPerRow'] as int,
      height: data['height'] as int?,
      width: data['width'] as int?);
}

/// Converts a [ImageFileFormat] to its pigeon equivalent.
PlatformImageFileFormat imageFileFormatToPlatform(ImageFileFormat format) {
  switch (format) {
    case ImageFileFormat.jpeg:
      return PlatformImageFileFormat.jpeg;
    case ImageFileFormat.heif:
      return PlatformImageFileFormat.heif;
  }
}
