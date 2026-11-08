// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:camera_ohos/camera_ohos.dart';
import 'package:camera_ohos_example/camera_controller.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    CameraPlatform.instance = OhosCamera();
  });

  /// Creates and initializes a controller for [camera] (defaults to the first
  /// available camera) and waits until the platform reports a preview size, so
  /// that follow-up capture APIs are safe to call.
  Future<CameraController> createInitializedController({
    CameraDescription? camera,
    ResolutionPreset resolutionPreset = ResolutionPreset.low,
  }) async {
    final List<CameraDescription> cameras = await CameraPlatform.instance
        .availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available on this device.');
    }
    final CameraController controller = CameraController(
      camera ?? cameras.first,
      mediaSettings: MediaSettings(resolutionPreset: resolutionPreset),
    );
    await controller.initialize();
    final Stopwatch stopwatch = Stopwatch()..start();
    while (controller.value.previewSize == null) {
      if (stopwatch.elapsed > const Duration(seconds: 10)) {
        throw StateError('previewSize was never reported after initialize.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return controller;
  }

  /// Runs [action] and catches whatever it throws (including timeouts), so a
  /// test can assert on the caught error without hanging on a future that
  /// never completes.
  Future<Object?> catchWhatever(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return 'TimeoutException: operation did not complete within 10s';
    } catch (error) {
      return error;
    }
    return null;
  }

  testWidgets('takePicture returns a file that exists on disk', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    expect(controller.value.isTakingPicture, isFalse);
    final XFile file = await controller.takePicture();
    expect(controller.value.isTakingPicture, isFalse);
    expect(File(file.path).existsSync(), isTrue);
    await controller.dispose();
  });

  testWidgets('pausePreview/resumePreview toggle isPreviewPaused', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    final DeviceOrientation orientationBefore =
        controller.value.deviceOrientation;
    await controller.pausePreview();
    expect(controller.value.isPreviewPaused, isTrue);
    expect(controller.value.previewPauseOrientation, orientationBefore);
    await controller.resumePreview();
    expect(controller.value.isPreviewPaused, isFalse);
    expect(controller.value.previewPauseOrientation, isNull);
    await controller.dispose();
  });

  testWidgets('setFlashMode accepts all four modes', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    for (final FlashMode mode in FlashMode.values) {
      await controller.setFlashMode(mode);
      expect(controller.value.flashMode, mode);
    }
    await controller.dispose();
  });

  testWidgets('setExposureMode/setFocusMode switch auto and locked', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    await controller.setExposureMode(ExposureMode.auto);
    expect(controller.value.exposureMode, ExposureMode.auto);
    // Exposure/focus LOCK requires API 20+ on OHOS; README.CN.md documents focus
    // lock as unsupported below API 20. Assert the documented contract: either
    // the locked state applies cleanly, or the device rejects it with a typed
    // CameraException (never a crash or a silently wrong state).
    final Object? exposureLocked = await catchWhatever(() async {
      await controller.setExposureMode(ExposureMode.locked);
      expect(controller.value.exposureMode, ExposureMode.locked);
    });
    if (exposureLocked is CameraException) {
      debugPrint('ExposureMode.locked unsupported on this device: $exposureLocked');
    } else {
      expect(exposureLocked, isNull, reason: 'setExposureMode(locked): $exposureLocked');
    }
    await controller.setExposureMode(ExposureMode.auto);
    expect(controller.value.exposureMode, ExposureMode.auto);
    final Object? focusLocked = await catchWhatever(() async {
      await controller.setFocusMode(FocusMode.locked);
      expect(controller.value.focusMode, FocusMode.locked);
    });
    if (focusLocked is CameraException) {
      debugPrint('FocusMode.locked unsupported on this device: $focusLocked');
    } else {
      expect(focusLocked, isNull, reason: 'setFocusMode(locked): $focusLocked');
    }
    await controller.setFocusMode(FocusMode.auto);
    expect(controller.value.focusMode, FocusMode.auto);
    await controller.dispose();
  });

  testWidgets('setExposureOffset rounds and clamps to the device range', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    final int id = controller.cameraId;
    final double min = await CameraPlatform.instance.getMinExposureOffset(id);
    final double max = await CameraPlatform.instance.getMaxExposureOffset(id);
    final double step = await CameraPlatform.instance.getExposureOffsetStepSize(
      id,
    );
    debugPrint('Exposure offset range: [$min, $max], step: $step');

    for (final double offset in <double>[0, 1000000, -1000000]) {
      final double result = await controller.setExposureOffset(offset);
      expect(result.isFinite, isTrue, reason: 'offset $offset -> $result');
      expect(
        result,
        inInclusiveRange(min - step, max + step),
        reason: 'offset $offset -> $result, range [$min, $max], step $step',
      );
    }
    final double zero = await controller.setExposureOffset(0);
    expect(zero, closeTo(0, step > 0.5 ? step : 0.5));

    await controller.dispose();
  });

  testWidgets(
    'lockCaptureOrientation/unlockCaptureOrientation toggle lock state',
    (WidgetTester tester) async {
      final CameraController controller = await createInitializedController();
      final DeviceOrientation orientationBefore =
          controller.value.deviceOrientation;
      await controller.lockCaptureOrientation();
      expect(controller.value.isCaptureOrientationLocked, isTrue);
      expect(
        controller.value.lockedCaptureOrientation,
        orientationBefore,
        reason:
            'lock without argument must lock the current device orientation',
      );
      await controller.unlockCaptureOrientation();
      expect(controller.value.isCaptureOrientationLocked, isFalse);
      expect(controller.value.lockedCaptureOrientation, isNull);
      await controller.dispose();
    },
  );

  testWidgets('setImageFileFormat and video stabilization APIs succeed', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    await controller.setImageFileFormat(ImageFileFormat.jpeg);
    // Behavior chain: picture capture still works after switching the format.
    final XFile file = await controller.takePicture();
    expect(File(file.path).existsSync(), isTrue);

    final Iterable<VideoStabilizationMode> modes = await controller
        .getSupportedVideoStabilizationModes();
    // Post-fix verification: the pigeon decode now maps wire ints into
    // PlatformVideoStabilizationMode enums, so the result must be fully
    // iterable without a TypeError and every element a real enum value.
    final List<VideoStabilizationMode> modeList = modes.toList();
    expect(modeList, isA<List<VideoStabilizationMode>>());
    expect(modeList, isNotEmpty);
    for (final VideoStabilizationMode mode in modeList) {
      expect(mode, isA<VideoStabilizationMode>());
    }
    expect(modeList, contains(VideoStabilizationMode.off));
    await controller.setVideoStabilizationMode(VideoStabilizationMode.off);
    await controller.dispose();
  });

  testWidgets(
    'startVideoRecording with a stream callback stops the stream on stop',
    (WidgetTester tester) async {
      final CameraController controller = await createInitializedController();
      final Completer<CameraImageData> firstFrame =
          Completer<CameraImageData>();
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording(
        streamCallback: (CameraImageData image) {
          if (!firstFrame.isCompleted) {
            firstFrame.complete(image);
          }
        },
      );
      expect(controller.value.isRecordingVideo, isTrue);
      expect(controller.value.isStreamingImages, isTrue);
      await firstFrame.future.timeout(const Duration(seconds: 15));
      final XFile file = await controller.stopVideoRecording();
      expect(controller.value.isRecordingVideo, isFalse);
      expect(controller.value.isStreamingImages, isFalse);
      expect(controller.value.recordingOrientation, isNull);
      expect(File(file.path).existsSync(), isTrue);
      await controller.dispose();
    },
  );

  testWidgets('controller utility surface and Optional members behave', (
    WidgetTester tester,
  ) async {
    // Utility surface on a live controller.
    final CameraController controller = await createInitializedController();
    expect(controller.cameraId, greaterThanOrEqualTo(0));
    final Widget preview = controller.buildPreview();
    expect(preview, isA<Texture>());
    expect((preview as Texture).textureId, controller.cameraId);
    expect(controller.value.toString(), contains('CameraValue('));
    expect(controller.value.toString(), contains('isRecordingVideo: false'));
    expect(controller.value.toString(), contains('isPreviewPaused: false'));

    // Guard branch: removing a listener after dispose must not throw.
    final VoidCallback listener = () {};
    controller.removeListener(listener);
    await controller.dispose();
    expect(() => controller.removeListener(listener), returnsNormally);

    // Optional absent-branch members.
    final Optional<int> absent = Optional<int>.absent();
    expect(absent.isPresent, isFalse);
    expect(absent.isNotPresent, isTrue);
    expect(absent.orNull, isNull);
    expect(absent.or(42), 42);
    expect(absent.toList(), isEmpty);
    expect(absent.toString(), 'Optional { absent }');
    expect(() => absent.value, throwsStateError);

    // Optional present-branch members.
    final Optional<int> present = Optional<int>.of(3);
    expect(present.isPresent, isTrue);
    expect(present.isNotPresent, isFalse);
    expect(present.value, 3);
    expect(present.or(42), 3);
    expect(present.orNull, 3);
    expect(present.toList(), <int>[3]);
    expect(present.hashCode, 3.hashCode);
    expect(present, equals(Optional<int>.of(3)));
    expect(present, isNot(equals(Optional<int>.of(4))));
    expect(present, isNot(equals(absent)));
    expect(present.toString(), 'Optional { value: 3 }');

    bool ifPresentCalled = false;
    present.ifPresent((int v) => ifPresentCalled = true);
    expect(ifPresentCalled, isTrue);
    bool ifAbsentCalled = false;
    absent.ifAbsent(() => ifAbsentCalled = true);
    expect(ifAbsentCalled, isTrue);
    present.ifAbsent(() => fail('ifAbsent must not run on a present Optional'));
    absent.ifPresent(
      (_) => fail('ifPresent must not run on an absent Optional'),
    );

    // transform / transformNullable on both branches.
    expect(present.transform((int v) => v + 1).value, 4);
    expect(present.transform((int v) => v + 1), equals(Optional<int>.of(4)));
    expect(absent.transform((int v) => v + 1).isPresent, isFalse);
    expect(present.transformNullable((int v) => v + 1).value, 4);
    expect(
      present.transformNullable((int v) => null),
      equals(Optional<int>.absent()),
    );
    expect(absent.transformNullable((int v) => v + 1).isPresent, isFalse);

    // fromNullable on both branches.
    expect(Optional<int>.fromNullable(5).isPresent, isTrue);
    expect(Optional<int>.fromNullable(5).value, 5);
    expect(Optional<int>.fromNullable(null).isPresent, isFalse);

    // Optional.of(null) cannot be reached through the public API under sound
    // null safety: the runtime parameter check rejects null with a TypeError
    // before the ArgumentError guard inside Optional.of can run, so there is
    // no assertion for that branch here.
  });

  testWidgets('setDescription outside recording rebuilds on the new camera', (
    WidgetTester tester,
  ) async {
    final List<CameraDescription> cameras = await CameraPlatform.instance
        .availableCameras();
    if (cameras.length < 2) {
      debugPrint('Only one camera available; rebuild path not exercised.');
      return;
    }
    final CameraController controller = await createInitializedController(
      camera: cameras.first,
    );
    await controller.setDescription(cameras[1]);
    expect(controller.value.description.name, cameras[1].name);
    expect(controller.value.isInitialized, isTrue);
    // The rebuilt controller must still capture with the new camera.
    final XFile file = await controller.takePicture();
    expect(File(file.path).existsSync(), isTrue);
    // Post-fix verification: rebuild -> dispose -> device orientation events
    // must no longer hit the orphaned listener. Before the
    // cancel-before-overwrite fix in _initializeWithDescription, dispose()
    // left a live listener that fired on the disposed ChangeNotifier and
    // tripped the debug assert ("used after being disposed").
    await controller.dispose();
    // Bounded window for in-flight device-orientation events so an orphaned
    // listener would actually be exercised if the leak still existed.
    await Future<void>.delayed(const Duration(seconds: 5));
    debugPrint(
      'dispose after setDescription rebuild survived pending orientation '
      'events without the disposed-notifier assert.',
    );
  });

  testWidgets('API calls after dispose throw CameraException', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    await controller.dispose();

    final Object? takePictureError = await catchWhatever(
      controller.takePicture,
    );
    expect(
      takePictureError,
      isA<CameraException>(),
      reason: 'takePicture after dispose threw $takePictureError',
    );

    final Object? setFlashModeError = await catchWhatever(
      () => controller.setFlashMode(FlashMode.torch),
    );
    expect(
      setFlashModeError,
      isA<CameraException>(),
      reason: 'setFlashMode after dispose threw $setFlashModeError',
    );
  });

  testWidgets('device orientation events update controller state', (
    WidgetTester tester,
  ) async {
    final CameraController controller = await createInitializedController();
    final DeviceOrientation initial = controller.value.deviceOrientation;
    debugPrint('Initial device orientation: $initial');

    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
    ]);
    final Stopwatch stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 10)) {
      if (controller.value.deviceOrientation != initial) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final DeviceOrientation after = controller.value.deviceOrientation;
    expect(
      after,
      isNot(initial),
      reason:
          'deviceOrientation stayed at $initial for 10s after requesting '
          'landscapeLeft; no orientation event reached the controller',
    );

    // Restore portrait afterwards; this is cleanup, not an assertion.
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    debugPrint(
      'Orientation after requesting landscapeLeft: $after, '
      'restoring portraitUp; current: ${controller.value.deviceOrientation}',
    );
    // Wait (bounded) for the device to settle back to portrait; cleanup only.
    final Stopwatch restoreStopwatch = Stopwatch()..start();
    while (restoreStopwatch.elapsed < const Duration(seconds: 10)) {
      if (controller.value.deviceOrientation == DeviceOrientation.portraitUp) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await controller.dispose();
  });
}
