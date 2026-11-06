// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:camera_ohos/src/messages.g.dart';
import 'package:camera_ohos/src/type_conversion.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 测试用例：CameraImageData 能够被创建
  test('CameraImageData can be created', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 1,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.height, 1);
    expect(cameraImage.width, 4);
    expect(cameraImage.format.group, ImageFormatGroup.unknown);
    expect(cameraImage.planes.length, 1);
  });

  // Test: unmapped format 35 (Android YUV_420_888, not an OHOS constant) should report unknown

  test('CameraImageData has ImageFormatGroup.unknown for format 35', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 35,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.format.group, ImageFormatGroup.unknown);
  });

  test('CameraImageData has ImageFormatGroup.unknown for format 256', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 256,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.format.group, ImageFormatGroup.unknown);
  });

  test('CameraImageData has ImageFormatGroup.unknown for format 17', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 17,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.format.group, ImageFormatGroup.unknown);
  });

  // Test: CameraImageData has ImageFormatGroup.nv21

  test('CameraImageData has ImageFormatGroup.nv21', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 1003,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.format.group, ImageFormatGroup.nv21);
    expect(cameraImage.format.raw, 1003);
  });

  // Test: CameraImageData has ImageFormatGroup.jpeg

  test('CameraImageData has ImageFormatGroup.jpeg', () {
    final CameraImageData cameraImage = cameraImageFromPlatformData(
      <dynamic, dynamic>{
        'format': 2000,
        'height': 1,
        'width': 4,
        'lensAperture': 1.8,
        'sensorExposureTime': 9991324,
        'sensorSensitivity': 92.0,
        'planes': <dynamic>[
          <dynamic, dynamic>{
            'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
            'bytesPerPixel': 1,
            'bytesPerRow': 4,
            'height': 1,
            'width': 4,
          },
        ],
      },
    );
    expect(cameraImage.format.group, ImageFormatGroup.jpeg);
    expect(cameraImage.format.raw, 2000);
  });

  // 测试用例：imageFileFormatToPlatform 应当将 jpeg 映射为 PlatformImageFileFormat.jpeg
  test(
    'imageFileFormatToPlatform should map jpeg to PlatformImageFileFormat.jpeg',
    () {
      expect(
        imageFileFormatToPlatform(ImageFileFormat.jpeg),
        PlatformImageFileFormat.jpeg,
      );
    },
  );

  // 测试用例：imageFileFormatToPlatform 应当将 heif 映射为 PlatformImageFileFormat.heif
  test(
    'imageFileFormatToPlatform should map heif to PlatformImageFileFormat.heif',
    () {
      expect(
        imageFileFormatToPlatform(ImageFileFormat.heif),
        PlatformImageFileFormat.heif,
      );
    },
  );
}
