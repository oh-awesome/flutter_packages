import 'dart:math';
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_ohos/src/messages.g.dart';
import 'package:camera_ohos/src/utils.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 测试组：工具方法
  group('Utility methods', () {
    // 测试用例：解析相机镜头方向时，提供有效值应返回 CameraLensDirection
    test(
      'Should return CameraLensDirection when valid value is supplied when parsing camera lens direction',
      () {
        expect(
          cameraLensDirectionFromPlatform(PlatformCameraLensDirection.back),
          CameraLensDirection.back,
        );
        expect(
          cameraLensDirectionFromPlatform(PlatformCameraLensDirection.front),
          CameraLensDirection.front,
        );
        expect(
          cameraLensDirectionFromPlatform(PlatformCameraLensDirection.external),
          CameraLensDirection.external,
        );
    });

    // 测试用例：deviceOrientationToPlatform() 应当正确序列化

    test('deviceOrientationToPlatform() should serialize correctly', () {
      expect(
        deviceOrientationToPlatform(DeviceOrientation.portraitUp),
        PlatformDeviceOrientation.portraitUp,
      );
      expect(
        deviceOrientationToPlatform(DeviceOrientation.portraitDown),
        PlatformDeviceOrientation.portraitDown,
      );
      expect(
        deviceOrientationToPlatform(DeviceOrientation.landscapeRight),
        PlatformDeviceOrientation.landscapeRight,
      );
      expect(
        deviceOrientationToPlatform(DeviceOrientation.landscapeLeft),
        PlatformDeviceOrientation.landscapeLeft,
      );
    });

    // 测试用例：deviceOrientationFromPlatform() 应当正确反序列化

    test('deviceOrientationFromPlatform() should deserialize correctly', () {
      expect(
        deviceOrientationFromPlatform(PlatformDeviceOrientation.portraitUp),
        DeviceOrientation.portraitUp,
      );
      expect(
        deviceOrientationFromPlatform(PlatformDeviceOrientation.portraitDown),
        DeviceOrientation.portraitDown,
      );
      expect(
        deviceOrientationFromPlatform(PlatformDeviceOrientation.landscapeRight),
        DeviceOrientation.landscapeRight,
      );
      expect(
        deviceOrientationFromPlatform(PlatformDeviceOrientation.landscapeLeft),
        DeviceOrientation.landscapeLeft,
      );
    });

    // 测试用例：exposureModeFromPlatform() 应当正确反序列化

    test('exposureModeFromPlatform() should deserialize correctly', () {
      expect(
        exposureModeFromPlatform(PlatformExposureMode.auto),
        ExposureMode.auto,
      );
      expect(
        exposureModeFromPlatform(PlatformExposureMode.locked),
        ExposureMode.locked,
      );
    });

    // 测试用例：exposureModeToPlatform() 应当正确序列化

    test('exposureModeToPlatform() should serialize correctly', () {
      expect(
        exposureModeToPlatform(ExposureMode.auto),
        PlatformExposureMode.auto,
      );
      expect(
        exposureModeToPlatform(ExposureMode.locked),
        PlatformExposureMode.locked,
      );
    });

    // 测试用例：focusModeFromPlatform() 应当正确反序列化

    test('focusModeFromPlatform() should deserialize correctly', () {
      expect(focusModeFromPlatform(PlatformFocusMode.auto), FocusMode.auto);
      expect(focusModeFromPlatform(PlatformFocusMode.locked), FocusMode.locked);
    });

    // 测试用例：focusModeToPlatform() 应当正确序列化

    test('focusModeToPlatform() should serialize correctly', () {
      expect(focusModeToPlatform(FocusMode.auto), PlatformFocusMode.auto);
      expect(focusModeToPlatform(FocusMode.locked), PlatformFocusMode.locked);
    });

    // 测试用例：resolutionPresetToPlatform() 应当正确序列化

    test('resolutionPresetToPlatform() should serialize correctly', () {
      expect(
        resolutionPresetToPlatform(ResolutionPreset.low),
        PlatformResolutionPreset.low,
      );
      expect(
        resolutionPresetToPlatform(ResolutionPreset.medium),
        PlatformResolutionPreset.medium,
      );
      expect(
        resolutionPresetToPlatform(ResolutionPreset.high),
        PlatformResolutionPreset.high,
      );
      expect(
        resolutionPresetToPlatform(ResolutionPreset.veryHigh),
        PlatformResolutionPreset.veryHigh,
      );
      expect(
        resolutionPresetToPlatform(ResolutionPreset.ultraHigh),
        PlatformResolutionPreset.ultraHigh,
      );
      expect(
        resolutionPresetToPlatform(ResolutionPreset.max),
        PlatformResolutionPreset.max,
      );
      expect(resolutionPresetToPlatform(null), PlatformResolutionPreset.high);
    });

    // 测试用例：mediaSettingsToPlatform() 应当正确序列化

    test('mediaSettingsToPlatform() should serialize correctly', () {
      expect(
        mediaSettingsToPlatform(null).resolutionPreset,
        PlatformResolutionPreset.high,
      );
      expect(mediaSettingsToPlatform(null).enableAudio, false);
      expect(
        mediaSettingsToPlatform(
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            enableAudio: true,
            videoBitrate: 100,
            audioBitrate: 200,
            fps: 30,
          ),
        ).resolutionPreset,
        PlatformResolutionPreset.low,
      );
      expect(
        mediaSettingsToPlatform(
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            enableAudio: true,
            videoBitrate: 100,
            audioBitrate: 200,
            fps: 30,
          ),
        ).enableAudio,
        true,
      );
      expect(
        mediaSettingsToPlatform(
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            enableAudio: true,
            videoBitrate: 100,
            audioBitrate: 200,
            fps: 30,
          ),
        ).videoBitrate,
        100,
      );
      expect(
        mediaSettingsToPlatform(
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            enableAudio: true,
            videoBitrate: 100,
            audioBitrate: 200,
            fps: 30,
          ),
        ).audioBitrate,
        200,
      );
      expect(
        mediaSettingsToPlatform(
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            enableAudio: true,
            videoBitrate: 100,
            audioBitrate: 200,
            fps: 30,
          ),
        ).fps,
        30,
      );
    });

    // 测试用例：imageFormatGroupToPlatform() 应当正确序列化

    test('imageFormatGroupToPlatform() should serialize correctly', () {
      expect(
        imageFormatGroupToPlatform(ImageFormatGroup.unknown),
        PlatformImageFormatGroup.yuv420,
      );
      expect(
        imageFormatGroupToPlatform(ImageFormatGroup.yuv420),
        PlatformImageFormatGroup.yuv420,
      );
      expect(
        imageFormatGroupToPlatform(ImageFormatGroup.bgra8888),
        PlatformImageFormatGroup.yuv420,
      );
      expect(
        imageFormatGroupToPlatform(ImageFormatGroup.jpeg),
        PlatformImageFormatGroup.jpeg,
      );
      expect(
        imageFormatGroupToPlatform(ImageFormatGroup.nv21),
        PlatformImageFormatGroup.nv21,
      );
    });

    // 测试用例：flashModeToPlatform() 应当正确序列化

    test('flashModeToPlatform() should serialize correctly', () {
      expect(flashModeToPlatform(FlashMode.auto), PlatformFlashMode.auto);
      expect(flashModeToPlatform(FlashMode.off), PlatformFlashMode.off);
      expect(flashModeToPlatform(FlashMode.always), PlatformFlashMode.always);
      expect(flashModeToPlatform(FlashMode.torch), PlatformFlashMode.torch);
    });

    // 测试用例：pointToPlatform() 应当正确序列化

    test('pointToPlatform() should serialize correctly', () {
      expect(pointToPlatform(null), null);
      expect(pointToPlatform(const Point<double>(1.0, 2.0))?.x, 1.0);
      expect(pointToPlatform(const Point<double>(1.0, 2.0))?.y, 2.0);
    });

    // 测试用例：videoStabilizationModeFromPlatform() 应当正确反序列化

    test(
      'videoStabilizationModeFromPlatform() should deserialize correctly',
      () {
        expect(
          videoStabilizationModeFromPlatform(
            PlatformVideoStabilizationMode.off,
          ),
          VideoStabilizationMode.off,
        );
        expect(
          videoStabilizationModeFromPlatform(
            PlatformVideoStabilizationMode.level1,
          ),
          VideoStabilizationMode.level1,
        );
        expect(
          videoStabilizationModeFromPlatform(
            PlatformVideoStabilizationMode.level2,
          ),
          VideoStabilizationMode.level2,
        );
        expect(
          videoStabilizationModeFromPlatform(
            PlatformVideoStabilizationMode.level3,
          ),
          VideoStabilizationMode.level3,
        );
      },
    );

    // 测试用例：videoStabilizationModeToPlatform() 应当正确序列化

    test('videoStabilizationModeToPlatform() should serialize correctly', () {
      expect(
        videoStabilizationModeToPlatform(VideoStabilizationMode.off),
        PlatformVideoStabilizationMode.off,
      );
      expect(
        videoStabilizationModeToPlatform(VideoStabilizationMode.level1),
        PlatformVideoStabilizationMode.level1,
      );
      expect(
        videoStabilizationModeToPlatform(VideoStabilizationMode.level2),
        PlatformVideoStabilizationMode.level2,
      );
      expect(
        videoStabilizationModeToPlatform(VideoStabilizationMode.level3),
        PlatformVideoStabilizationMode.level3,
      );
    });
  });
}
