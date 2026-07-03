// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:camera_ohos/camera_ohos.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/camera_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    CameraPlatform.instance = OhosCamera();
  });

  testWidgets('availableCameras only supports valid back or front cameras',
      (WidgetTester tester) async {
    final List<CameraDescription> availableCameras =
        await CameraPlatform.instance.availableCameras();

    for (final CameraDescription cameraDescription in availableCameras) {
      expect(
          cameraDescription.lensDirection, isNot(CameraLensDirection.external));
      expect(cameraDescription.sensorOrientation, anyOf(0, 90, 180, 270));
    }
  });

  testWidgets('takePictures stores a valid image in memory',
      (WidgetTester tester) async {
    final List<CameraDescription> availableCameras =
        await CameraPlatform.instance.availableCameras();
    if (availableCameras.isEmpty) {
      return;
    }
    for (final CameraDescription cameraDescription in availableCameras) {
      final CameraController controller =
          CameraController(cameraDescription, ResolutionPreset.high);
      await controller.initialize();

      // Take Picture
      final XFile file = await controller.takePicture();

      // Verify the file exists and has content
      final File fileImage = File(file.path);
      expect(fileImage.existsSync(), isTrue);
      expect(fileImage.lengthSync(), greaterThan(0));
    }
  });

  testWidgets('Pause and resume video recording', (WidgetTester tester) async {
    final List<CameraDescription> cameras =
        await CameraPlatform.instance.availableCameras();
    if (cameras.isEmpty) {
      return;
    }

    final CameraController controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );

    await controller.initialize();
    await controller.prepareForVideoRecording();

    int startPause;
    int timePaused = 0;

    await controller.startVideoRecording();
    final int recordingStart = DateTime.now().millisecondsSinceEpoch;
    sleep(const Duration(milliseconds: 500));

    await controller.pauseVideoRecording();
    startPause = DateTime.now().millisecondsSinceEpoch;
    sleep(const Duration(milliseconds: 500));
    await controller.resumeVideoRecording();
    timePaused += DateTime.now().millisecondsSinceEpoch - startPause;

    sleep(const Duration(milliseconds: 500));

    await controller.pauseVideoRecording();
    startPause = DateTime.now().millisecondsSinceEpoch;
    sleep(const Duration(milliseconds: 500));
    await controller.resumeVideoRecording();
    timePaused += DateTime.now().millisecondsSinceEpoch - startPause;

    sleep(const Duration(milliseconds: 500));

    final XFile file = await controller.stopVideoRecording();
    final int recordingTime =
        DateTime.now().millisecondsSinceEpoch - recordingStart;

    // Verify the recorded file exists and has content.
    final File videoFile = File(file.path);
    expect(videoFile.existsSync(), isTrue);
    expect(videoFile.lengthSync(), greaterThan(0));

    // Verify that the total recording time is greater than the paused time.
    expect(recordingTime, greaterThan(timePaused));
  });

  testWidgets('Set description while recording', (WidgetTester tester) async {
    final List<CameraDescription> cameras =
        await CameraPlatform.instance.availableCameras();
    if (cameras.length < 2) {
      return;
    }

    final CameraController controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );

    await controller.initialize();
    await controller.prepareForVideoRecording();

    await controller.startVideoRecording();

    // OHOS does not support switching the camera while recording.
    // Expect a CameraException to be thrown.
    bool failed = false;
    try {
      await controller.setDescription(cameras[1]);
    } catch (err) {
      expect(err, isA<CameraException>());
      expect(
        (err as CameraException).description,
        equals('Camera switching is not supported while recording.'),
      );
      failed = true;
    }

    if (failed) {
      // cameras did not switch
      expect(controller.description, cameras[0]);
    } else {
      // cameras switched
      expect(controller.description, cameras[1]);
    }
  });

  testWidgets('Set description', (WidgetTester tester) async {
    final List<CameraDescription> cameras =
        await CameraPlatform.instance.availableCameras();
    if (cameras.length < 2) {
      return;
    }

    final CameraController controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );

    await controller.initialize();
    await controller.setDescription(cameras[1]);

    expect(controller.description, cameras[1]);
  });

  testWidgets('image streaming', (WidgetTester tester) async {
    final List<CameraDescription> cameras =
        await CameraPlatform.instance.availableCameras();
    if (cameras.isEmpty) {
      return;
    }

    final CameraController controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );

    await controller.initialize();
    bool isDetecting = false;

    await controller.startImageStream((CameraImageData image) {
      if (isDetecting) {
        return;
      }

      isDetecting = true;

      expectLater(image, isNotNull).whenComplete(() => isDetecting = false);
    });

    expect(controller.value.isStreamingImages, true);

    sleep(const Duration(milliseconds: 500));

    await controller.stopImageStream();
    await controller.dispose();
  });
}
