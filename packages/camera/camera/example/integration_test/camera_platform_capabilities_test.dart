// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

/// Integration tests for camera platform capabilities that are specific to
/// OHOS. The upstream camera_test.dart gates three of these behaviors behind
/// other platforms (Android/iOS); this file exercises the same behaviors on
/// OHOS, where the camera_ohos implementation supports them.
///
/// The fourth test is a capability-gap record: OHOS Camera Kit has no API for
/// switching the camera while a recording is running, and the camera_ohos
/// plugin surfaces that limitation as a CameraException with the stable code
/// `setDescriptionWhileRecordingUnsupported`. The test pins that contract so
/// a future implementation change cannot silently break consumers relying on
/// the error.
///
/// No tester.pump/pumpAndSettle anywhere: pumping hangs the live camera
/// preview under the integration test binding (see
/// camera_app_coverage_test.dart), so every wait is a real-time poll with
/// Future.delayed.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The default frame policy only renders frames on explicit pumps, which
  // freezes the UI after pumpWidget. fullyLive keeps real frames flowing.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// Polls [condition] in real time until it turns true.
  Future<void> waitUntil(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 20),
    required String reason,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      if (await condition()) {
        return;
      }
      if (stopwatch.elapsed > timeout) {
        fail('$reason (timed out after ${stopwatch.elapsed.inSeconds}s)');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Loads the device cameras or fails with a clear message. Unlike the
  /// upstream camera_test.dart, an empty camera list is a hard failure here:
  /// these capability tests are meaningless without a camera.
  Future<List<CameraDescription>> loadCameras() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      fail('No cameras available on this device.');
    }
    return cameras;
  }

  testWidgets('Pause and resume video recording on OHOS', (WidgetTester tester) async {
    final List<CameraDescription> cameras = await loadCameras();

    final controller = CameraController(cameras[0], ResolutionPreset.low);
    await controller.initialize();
    await controller.prepareForVideoRecording();

    await controller.startVideoRecording();
    final int recordingStart = DateTime.now().millisecondsSinceEpoch;

    // Mirrors the upstream "Pause and resume video recording" body, but with
    // Future.delayed instead of dart:io sleep (synchronous sleeps have hung
    // runs on OHOS before).
    var timePaused = 0;
    const pauseIterations = 2;
    for (var i = 0; i < pauseIterations; i++) {
      await controller.pauseVideoRecording();
      final int pauseStart = DateTime.now().millisecondsSinceEpoch;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await controller.resumeVideoRecording();
      timePaused += DateTime.now().millisecondsSinceEpoch - pauseStart;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final XFile file = await controller.stopVideoRecording();
    final int recordingTime = DateTime.now().millisecondsSinceEpoch - recordingStart;

    final videoController = VideoPlayerController.file(File(file.path));
    await videoController.initialize().timeout(const Duration(seconds: 30));
    final int duration = videoController.value.duration.inMilliseconds;
    await videoController.dispose();
    await controller.dispose();

    // The paused spans must not count toward the recorded duration.
    expect(duration, lessThan(recordingTime - timePaused));
  });

  testWidgets('Image streaming delivers preview-sized frames on OHOS', (WidgetTester tester) async {
    final List<CameraDescription> cameras = await loadCameras();

    final controller = CameraController(cameras[0], ResolutionPreset.low);
    await controller.initialize();

    // The preview size arrives via the cameraInitialized event after
    // initialize() resolves; wait for it before deriving expectations.
    await waitUntil(
      () async => controller.value.previewSize != null,
      reason: 'previewSize was never reported after initialize',
    );
    final Size previewSize = controller.value.previewSize!;

    var frameCount = 0;
    CameraImage? firstFrame;
    await controller.startImageStream((CameraImage image) {
      frameCount++;
      firstFrame ??= image;
    });
    expect(controller.value.isStreamingImages, isTrue);

    await waitUntil(() async => frameCount >= 3, reason: 'streamed frames never arrived');

    // Rotation may swap width/height, so compare the pixel count.
    final CameraImage frame = firstFrame!;
    expect(frame.width, greaterThan(0));
    expect(frame.height, greaterThan(0));
    expect(
      frame.width * frame.height,
      previewSize.width * previewSize.height,
      reason:
          'streamed frame ${frame.width}x${frame.height} does not '
          'match the preview size $previewSize',
    );

    await controller.stopImageStream();
    expect(controller.value.isStreamingImages, isFalse);
    await controller.dispose();
  });

  /// Starts a streaming session with [imageFormatGroup] and returns the first
  /// delivered frame. Mirrors the structure of the upstream iOS-only
  /// imageFormatGroup test.
  Future<CameraImage> startStreaming(
    List<CameraDescription> cameras,
    ImageFormatGroup? imageFormatGroup,
  ) async {
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.low,
      imageFormatGroup: imageFormatGroup,
    );
    await controller.initialize();
    final completer = Completer<CameraImage>();

    await controller.startImageStream((CameraImage image) {
      if (!completer.isCompleted) {
        unawaited(
          controller.stopImageStream().then((_) => controller.dispose()).then((_) {
            completer.complete(image);
          }),
        );
      }
    });
    return completer.future.timeout(const Duration(seconds: 30));
  }

  testWidgets('Image streaming with imageFormatGroup on OHOS', (WidgetTester tester) async {
    final List<CameraDescription> cameras = await loadCameras();

    // The OHOS preview stream always delivers YUV_420_SP frames, which the
    // camera_ohos plugin reports with NV21 semantics regardless of the
    // requested group (see type_conversion.dart in camera_ohos: the
    // CAMERA_FORMAT_YUV_420_SP constant maps to ImageFormatGroup.nv21).
    // Both requested groups must therefore observe the same reported value.
    for (final group in <ImageFormatGroup>[ImageFormatGroup.yuv420, ImageFormatGroup.nv21]) {
      final CameraImage image = await startStreaming(cameras, group);
      expect(image.format.group, ImageFormatGroup.nv21);
    }
  });

  testWidgets('setDescription while recording is rejected on OHOS', (WidgetTester tester) async {
    // Capability-gap record: OHOS Camera Kit has no API for switching the
    // camera while a recording is running. The camera_ohos plugin surfaces
    // this as a CameraException with the stable code
    // `setDescriptionWhileRecordingUnsupported` (ohos_camera.dart transparently
    // passes through the platform error). This test pins that contract.
    final List<CameraDescription> cameras = await loadCameras();

    final controller = CameraController(cameras[0], ResolutionPreset.low);
    await controller.initialize();
    await controller.prepareForVideoRecording();
    await controller.startVideoRecording();
    expect(controller.value.isRecordingVideo, isTrue);

    await expectLater(
      controller.setDescription(cameras.first).timeout(const Duration(seconds: 15)),
      throwsA(
        isA<CameraException>().having(
          (CameraException e) => e.code,
          'code',
          'setDescriptionWhileRecordingUnsupported',
        ),
      ),
    );

    // The rejected call must leave the recording untouched; stop it cleanly.
    final XFile file = await controller.stopVideoRecording();
    expect(File(file.path).existsSync(), isTrue);
    await controller.dispose();
  });
}
