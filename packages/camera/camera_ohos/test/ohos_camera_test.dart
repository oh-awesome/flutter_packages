import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:camera_ohos/src/messages.g.dart';
import 'package:camera_ohos/src/ohos_camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'ohos_camera_test.mocks.dart';
import 'src/test_helpers.dart';

@GenerateMocks(<Type>[CameraApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test case: registers the instance
  test('registers instance', () async {
    OhosCamera.registerWith();
    expect(CameraPlatform.instance, isA<OhosCamera>());
  });

  // Test group: creation, initialization and disposal tests
  group('Creation, Initialization & Disposal Tests', () {
    // Test case: should send create data and return the camera id
    test('Should send creation data and receive back a camera id', () async {
      final MockCameraApi mockApi = MockCameraApi();
      when(mockApi.create(any, any)).thenAnswer((_) async => 1);
      final OhosCamera camera = OhosCamera(hostApi: mockApi);

      final int cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );

      verify(
        mockApi.create(
          'Test',
          argThat(
            isA<PlatformMediaSettings>().having(
              (s) => s.resolutionPreset,
              'resolutionPreset',
              PlatformResolutionPreset.high,
            ),
          ),
        ),
      ).called(1);
      expect(cameraId, 1);
    });

    // Test case: should throw CameraException when create throws a PlatformException
    test(
      'Should throw CameraException when create throws a PlatformException',
      () async {
        final MockCameraApi mockApi = MockCameraApi();
        when(mockApi.create(any, any)).thenThrow(
          PlatformException(
            code: 'TESTING_ERROR_CODE',
            message: 'Mock error message used during testing.',
          ),
        );
        final OhosCamera camera = OhosCamera(hostApi: mockApi);

        expect(
          () => camera.createCamera(
            const CameraDescription(
              name: 'Test',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 0,
            ),
            ResolutionPreset.high,
          ),
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'TESTING_ERROR_CODE')
                .having(
                  (e) => e.description,
                  'description',
                  'Mock error message used during testing.',
                ),
          ),
        );
      },
    );

    // Test case: should throw CameraException when initialize throws a PlatformException
    test(
      'Should throw CameraException when initialize throws a PlatformException',
      () async {
        final MockCameraApi mockApi = MockCameraApi();
        when(mockApi.initialize(any)).thenThrow(
          PlatformException(
            code: 'TESTING_ERROR_CODE',
            message: 'Mock error message used during testing.',
          ),
        );
        final OhosCamera camera = OhosCamera(hostApi: mockApi);

        expect(
          () => camera.initializeCamera(0),
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'TESTING_ERROR_CODE')
                .having(
                  (e) => e.description,
                  'description',
                  'Mock error message used during testing.',
                ),
          ),
        );
      },
    );

    // Test case: should send initialization data
    test('Should send initialization data', () async {
      final MockCameraApi mockApi = MockCameraApi();
      when(mockApi.create(any, any)).thenAnswer((_) async => 1);
      when(mockApi.initialize(any)).thenAnswer((_) async {});
      final OhosCamera camera = OhosCamera(hostApi: mockApi);
      final int cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );

      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.hostCameraHandlers[cameraId]!.initialized(
        PlatformCameraState(
          previewSize: PlatformSize(width: 1920, height: 1080),
          exposureMode: PlatformExposureMode.auto,
          exposurePointSupported: true,
          focusMode: PlatformFocusMode.auto,
          focusPointSupported: true,
        ),
      );
      await initializeFuture;

      verify(mockApi.initialize(PlatformImageFormatGroup.yuv420)).called(1);
    });

    // Test case: should send a disposal call on dispose
    test('Should send a disposal call on dispose', () async {
      final MockCameraApi mockApi = MockCameraApi();
      when(mockApi.create(any, any)).thenAnswer((_) async => 1);
      when(mockApi.initialize(any)).thenAnswer((_) async {});
      when(mockApi.dispose()).thenAnswer((_) async {});
      final OhosCamera camera = OhosCamera(hostApi: mockApi);
      final int cameraId = await camera.createCamera(
        const CameraDescription(
          name: 'Test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);
      camera.hostCameraHandlers[cameraId]!.initialized(
        PlatformCameraState(
          previewSize: PlatformSize(width: 1920, height: 1080),
          exposureMode: PlatformExposureMode.auto,
          exposurePointSupported: true,
          focusMode: PlatformFocusMode.auto,
          focusPointSupported: true,
        ),
      );
      await initializeFuture;

      await camera.dispose(cameraId);

	  expect(cameraId, 1);
      verify(mockApi.dispose()).called(1);
    });
  });

  // Test group: event tests
  group('Event Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;

    setUp(() async {
      mockApi = MockCameraApi();
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Test case: should receive the initialized event
    test('Should receive initialized event', () async {
      final Stream<CameraInitializedEvent> eventStream = camera
          .onCameraInitialized(cameraId);
      final StreamQueue<CameraInitializedEvent> streamQueue =
          StreamQueue<CameraInitializedEvent>(eventStream);

      camera.hostCameraHandlers[cameraId]!.initialized(
        PlatformCameraState(
          previewSize: PlatformSize(width: 3840, height: 2160),
          exposureMode: PlatformExposureMode.auto,
          exposurePointSupported: true,
          focusMode: PlatformFocusMode.auto,
          focusPointSupported: true,
        ),
      );

      final CameraInitializedEvent event = await streamQueue.next;
      expect(event.cameraId, cameraId);
      expect(event.previewWidth, 3840);
      expect(event.previewHeight, 2160);
      expect(event.exposureMode, ExposureMode.auto);
      expect(event.exposurePointSupported, true);
      expect(event.focusMode, FocusMode.auto);
      expect(event.focusPointSupported, true);

      await streamQueue.cancel();
    });

    // Test case: should receive camera closing events
    test('Should receive camera closing events', () async {
      final Stream<CameraClosingEvent> eventStream = camera.onCameraClosing(
        cameraId,
      );
      final StreamQueue<CameraClosingEvent> streamQueue =
          StreamQueue<CameraClosingEvent>(eventStream);

      camera.hostCameraHandlers[cameraId]!.closed();
      camera.hostCameraHandlers[cameraId]!.closed();
      camera.hostCameraHandlers[cameraId]!.closed();

      expect((await streamQueue.next).cameraId, cameraId);
      expect((await streamQueue.next).cameraId, cameraId);
      expect((await streamQueue.next).cameraId, cameraId);

      await streamQueue.cancel();
    });

    // Test case: should receive camera error events
    test('Should receive camera error events', () async {
      final Stream<CameraErrorEvent> errorStream = camera.onCameraError(
        cameraId,
      );
      final StreamQueue<CameraErrorEvent> streamQueue =
          StreamQueue<CameraErrorEvent>(errorStream);

      camera.hostCameraHandlers[cameraId]!.error('Error Description');
      camera.hostCameraHandlers[cameraId]!.error('Error Description');
      camera.hostCameraHandlers[cameraId]!.error('Error Description');

      expect((await streamQueue.next).description, 'Error Description');
      expect((await streamQueue.next).description, 'Error Description');
      expect((await streamQueue.next).description, 'Error Description');

      await streamQueue.cancel();
    });

    // Test case: should receive device orientation change events
    test('Should receive device orientation change events', () async {
      final Stream<DeviceOrientationChangedEvent> eventStream = camera
          .onDeviceOrientationChanged();
      final StreamQueue<DeviceOrientationChangedEvent> streamQueue =
          StreamQueue<DeviceOrientationChangedEvent>(eventStream);

      camera.hostHandler.deviceOrientationChanged(
        PlatformDeviceOrientation.portraitUp,
      );
      camera.hostHandler.deviceOrientationChanged(
        PlatformDeviceOrientation.portraitUp,
      );
      camera.hostHandler.deviceOrientationChanged(
        PlatformDeviceOrientation.portraitUp,
      );

      expect(
        (await streamQueue.next).orientation,
        DeviceOrientation.portraitUp,
      );
      expect(
        (await streamQueue.next).orientation,
        DeviceOrientation.portraitUp,
      );
      expect(
        (await streamQueue.next).orientation,
        DeviceOrientation.portraitUp,
      );

      await streamQueue.cancel();
    });
  });

  // Test group: function tests
  group('Function Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;

    setUp(() async {
      mockApi = MockCameraApi();
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Test case: should fetch CameraDescription instances for available cameras
    test(
      'Should fetch CameraDescription instances for available cameras',
      () async {
        final List<PlatformCameraDescription> returnData =
            <PlatformCameraDescription>[
              PlatformCameraDescription(
                name: 'Test 1',
                lensDirection: PlatformCameraLensDirection.front,
                sensorOrientation: 1,
              ),
              PlatformCameraDescription(
                name: 'Test 2',
                lensDirection: PlatformCameraLensDirection.back,
                sensorOrientation: 2,
              ),
            ];
        when(mockApi.getAvailableCameras()).thenAnswer((_) async => returnData);

        final List<CameraDescription> cameras = await camera.availableCameras();

        verify(mockApi.getAvailableCameras()).called(1);
        expect(cameras.length, returnData.length);
        expect(cameras[0].name, 'Test 1');
        expect(cameras[0].lensDirection, CameraLensDirection.front);
        expect(cameras[0].sensorOrientation, 1);
        expect(cameras[1].name, 'Test 2');
        expect(cameras[1].lensDirection, CameraLensDirection.back);
        expect(cameras[1].sensorOrientation, 2);
      },
    );

    // Test case: should throw CameraException when availableCameras throws a PlatformException
    test(
      'Should throw CameraException when availableCameras throws a PlatformException',
      () {
        when(mockApi.getAvailableCameras()).thenThrow(
          PlatformException(
            code: 'TESTING_ERROR_CODE',
            message: 'Mock error message used during testing.',
          ),
        );

        expect(
          camera.availableCameras,
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'TESTING_ERROR_CODE')
                .having(
                  (e) => e.description,
                  'description',
                  'Mock error message used during testing.',
                ),
          ),
        );
      },
    );

    // Test case: should take a picture and return an XFile instance
    test('Should take a picture and return an XFile instance', () async {
      when(mockApi.takePicture()).thenAnswer((_) async => '/test/path.jpg');

      final XFile file = await camera.takePicture(cameraId);

      verify(mockApi.takePicture()).called(1);
      expect(file.path, '/test/path.jpg');
    });

    // Test case: should start video recording
    test('Should start video recording', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});

      await camera.startVideoRecording(cameraId);

      verify(mockApi.startVideoRecording(false, null)).called(1);
    });

    // Test case: should stop the video recording and return the file
    test('Should stop a video recording and return the file', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      when(
        mockApi.stopVideoRecording(),
      ).thenAnswer((_) async => '/test/path.mp4');

      await camera.startVideoRecording(cameraId);
      final XFile file = await camera.stopVideoRecording(cameraId);

      verify(mockApi.stopVideoRecording()).called(1);
      expect(file.path, '/test/path.mp4');
    });

    // Test case: should pause the video recording
    test('Should pause a video recording', () async {
      when(mockApi.pauseVideoRecording()).thenAnswer((_) async {});

      await camera.pauseVideoRecording(cameraId);

      verify(mockApi.pauseVideoRecording()).called(1);
    });

    // Test case: should resume the video recording
    test('Should resume a video recording', () async {
      when(mockApi.resumeVideoRecording()).thenAnswer((_) async {});

      await camera.resumeVideoRecording(cameraId);

      verify(mockApi.resumeVideoRecording()).called(1);
    });

    // Test case: should set the flash mode
    test('Should set the flash mode', () async {
      when(mockApi.setFlashMode(any)).thenAnswer((_) async {});

      await camera.setFlashMode(cameraId, FlashMode.always);

      verify(mockApi.setFlashMode(PlatformFlashMode.always)).called(1);
    });

    // Test case: should set the exposure mode
    test('Should set the exposure mode', () async {
      when(mockApi.setExposureMode(any)).thenAnswer((_) async {});

      await camera.setExposureMode(cameraId, ExposureMode.auto);

      verify(mockApi.setExposureMode(PlatformExposureMode.auto)).called(1);
    });

    // Test case: should set the exposure point
    test('Should set the exposure point', () async {
      when(mockApi.setExposurePoint(any)).thenAnswer((_) async {});

      await camera.setExposurePoint(cameraId, const Point<double>(0.5, 0.5));

      verify(
        mockApi.setExposurePoint(
          argThat(
            isA<PlatformPoint>()
                .having((p) => p.x, 'x', 0.5)
                .having((p) => p.y, 'y', 0.5),
          ),
        ),
      ).called(1);
    });

    // Test case: should get the min exposure offset
    test('Should get the min exposure offset', () async {
      when(mockApi.getMinExposureOffset()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getMinExposureOffset(cameraId);

      verify(mockApi.getMinExposureOffset()).called(1);
      expect(stepSize, 1.0);
    });

    // Test case: should get the max exposure offset
    test('Should get the max exposure offset', () async {
      when(mockApi.getMaxExposureOffset()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getMaxExposureOffset(cameraId);

      verify(mockApi.getMaxExposureOffset()).called(1);
      expect(stepSize, 1.0);
    });

    // Test case: should get the exposure offset step size
    test('Should get the exposure offset step size', () async {
      when(mockApi.getExposureOffsetStepSize()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getExposureOffsetStepSize(cameraId);

      verify(mockApi.getExposureOffsetStepSize()).called(1);
      expect(stepSize, 1.0);
    });

    // Test case: should set the exposure offset
    test('Should set the exposure offset', () async {
      when(mockApi.setExposureOffset(any)).thenAnswer((_) async => 1.0);

      final double actualOffset = await camera.setExposureOffset(cameraId, 1.0);

      verify(mockApi.setExposureOffset(1.0)).called(1);
      expect(actualOffset, 1.0);
    });

    // Test case: should set the focus mode
    test('Should set the focus mode', () async {
      when(mockApi.setFocusMode(any)).thenAnswer((_) async {});

      await camera.setFocusMode(cameraId, FocusMode.auto);

      verify(mockApi.setFocusMode(PlatformFocusMode.auto)).called(1);
    });

    // Test case: should set the focus point
    test('Should set the focus point', () async {
      when(mockApi.setFocusPoint(any)).thenAnswer((_) async {});

      await camera.setFocusPoint(cameraId, const Point<double>(0.5, 0.5));

      verify(
        mockApi.setFocusPoint(
          argThat(
            isA<PlatformPoint>()
                .having((p) => p.x, 'x', 0.5)
                .having((p) => p.y, 'y', 0.5),
          ),
        ),
      ).called(1);
    });

    test('Should build a texture widget as preview widget', () async {
      // Act
      final Widget widget = camera.buildPreview(cameraId);

      // Act
      expect(widget is Texture, isTrue);
      expect((widget as Texture).textureId, cameraId);
    });

    // Test case: should get the max zoom level
    test('Should get the max zoom level', () async {
      when(mockApi.getMaxZoomLevel()).thenAnswer((_) async => 1.0);

      final double maxZoomLevel = await camera.getMaxZoomLevel(cameraId);

      verify(mockApi.getMaxZoomLevel()).called(1);
      expect(maxZoomLevel, 1.0);
    });

    // Test case: should get the min zoom level
    test('Should get the min zoom level', () async {
      when(mockApi.getMinZoomLevel()).thenAnswer((_) async => 1.0);

      final double maxZoomLevel = await camera.getMinZoomLevel(cameraId);

      verify(mockApi.getMinZoomLevel()).called(1);
      expect(maxZoomLevel, 1.0);
    });

    // Test case: should set the zoom level
    test('Should set the zoom level', () async {
      when(mockApi.setZoomLevel(any)).thenAnswer((_) async {});

      await camera.setZoomLevel(cameraId, 1.0);

      verify(mockApi.setZoomLevel(1.0)).called(1);
    });

    // Test case: should throw CameraException when an illegal zoom level is supplied
    test(
      'Should throw CameraException when illegal zoom level is supplied',
      () async {
        when(mockApi.setZoomLevel(any)).thenThrow(
          PlatformException(code: 'ZOOM_ERROR', message: 'Illegal zoom error'),
        );

        expect(
          () => camera.setZoomLevel(cameraId, -1.0),
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'ZOOM_ERROR')
                .having(
                  (e) => e.description,
                  'description',
                  'Illegal zoom error',
                ),
          ),
        );
      },
    );

    // Test case: should lock the capture orientation
    test('Should lock the capture orientation', () async {
      when(mockApi.lockCaptureOrientation(any)).thenAnswer((_) async {});

      await camera.lockCaptureOrientation(
        cameraId,
        DeviceOrientation.portraitUp,
      );

      verify(
        mockApi.lockCaptureOrientation(PlatformDeviceOrientation.portraitUp),
      ).called(1);
    });

    // Test case: should unlock the capture orientation
    test('Should unlock the capture orientation', () async {
      when(mockApi.unlockCaptureOrientation()).thenAnswer((_) async {});

      await camera.unlockCaptureOrientation(cameraId);

      verify(mockApi.unlockCaptureOrientation()).called(1);
    });

    // Test case: should pause the camera preview
    test('Should pause the camera preview', () async {
      when(mockApi.pausePreview()).thenAnswer((_) async {});

      await camera.pausePreview(cameraId);

      verify(mockApi.pausePreview()).called(1);
    });

    // Test case: should resume the camera preview
    test('Should resume the camera preview', () async {
      when(mockApi.resumePreview()).thenAnswer((_) async {});

      await camera.resumePreview(cameraId);

      verify(mockApi.resumePreview()).called(1);
    });

    // Test case: should send create data with settings and return the camera id
    test(
      'Should send creation data with settings and receive back a camera id',
      () async {
        when(mockApi.create(any, any)).thenAnswer((_) async => 1);

        final int cameraId = await camera.createCameraWithSettings(
          const CameraDescription(
            name: 'Test',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
          const MediaSettings(
            resolutionPreset: ResolutionPreset.high,
            enableAudio: true,
            videoBitrate: 200000,
            audioBitrate: 32000,
            fps: 30,
          ),
        );

        verify(
          mockApi.create(
            'Test',
            argThat(
              isA<PlatformMediaSettings>()
                  .having(
                    (s) => s.resolutionPreset,
                    'resolutionPreset',
                    PlatformResolutionPreset.high,
                  )
                  .having((s) => s.enableAudio, 'enableAudio', true)
                  .having((s) => s.videoBitrate, 'videoBitrate', 200000)
                  .having((s) => s.audioBitrate, 'audioBitrate', 32000)
                  .having((s) => s.fps, 'fps', 30),
            ),
          ),
        ).called(1);
        expect(cameraId, 1);
      },
    );

    // Test case: should get the supported video stabilization modes
    test('Should get supported video stabilization modes', () async {
      when(mockApi.getSupportedVideoStabilizationModes()).thenAnswer(
        (_) async => <PlatformVideoStabilizationMode>[
          PlatformVideoStabilizationMode.off,
          PlatformVideoStabilizationMode.level1,
        ],
      );

      final Iterable<VideoStabilizationMode> modes = await camera
          .getSupportedVideoStabilizationModes(cameraId);

      verify(mockApi.getSupportedVideoStabilizationModes()).called(1);
      expect(modes.toList(), <VideoStabilizationMode>[
        VideoStabilizationMode.off,
        VideoStabilizationMode.level1,
      ]);
    });

    // Test case: should set the video stabilization mode
    test('Should set video stabilization mode', () async {
      when(mockApi.setVideoStabilizationMode(any)).thenAnswer((_) async {});

      await camera.setVideoStabilizationMode(
        cameraId,
        VideoStabilizationMode.level1,
      );

      verify(
        mockApi.setVideoStabilizationMode(
          PlatformVideoStabilizationMode.level1,
        ),
      ).called(1);
    });

    // Test case: should throw CameraException when setVideoStabilizationMode throws a PlatformException
    test(
      'Should throw CameraException when setVideoStabilizationMode throws a PlatformException',
      () async {
        when(mockApi.setVideoStabilizationMode(any)).thenThrow(
          PlatformException(code: 'STAB_ERROR', message: 'Stabilization error'),
        );

        expect(
          () => camera.setVideoStabilizationMode(
            cameraId,
            VideoStabilizationMode.level1,
          ),
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'STAB_ERROR')
                .having(
                  (e) => e.description,
                  'description',
                  'Stabilization error',
                ),
          ),
        );
      },
    );

    // Test case: should set the description while recording
    test('Should set description while recording', () async {
      when(mockApi.setDescriptionWhileRecording(any)).thenAnswer((_) async {});

      await camera.setDescriptionWhileRecording(
        const CameraDescription(
          name: 'Test2',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 90,
        ),
      );

      verify(mockApi.setDescriptionWhileRecording('Test2')).called(1);
    });

    // Test case: should throw CameraException when setDescriptionWhileRecording throws a PlatformException
    test(
      'Should throw CameraException when setDescriptionWhileRecording throws a PlatformException',
      () async {
        when(mockApi.setDescriptionWhileRecording(any)).thenThrow(
          PlatformException(
            code: 'setDescriptionWhileRecordingUnsupported',
            message: 'Mock error message used during testing.',
          ),
        );

        expect(
          () => camera.setDescriptionWhileRecording(
            const CameraDescription(
              name: 'Test2',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 90,
            ),
          ),
          throwsA(
            isA<CameraException>()
                .having(
                  (e) => e.code,
                  'code',
                  'setDescriptionWhileRecordingUnsupported',
                )
                .having(
                  (e) => e.description,
                  'description',
                  'Mock error message used during testing.',
                ),
          ),
        );
      },
    );

    // Test case: should support image streaming
    test('Should support image streaming', () {
      expect(camera.supportsImageStreaming(), true);
    });

    // Test case: should build the preview widget
    test('Should build preview widget', () {
      final Widget widget = camera.buildPreview(cameraId);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, cameraId);
    });

    // Test case: should start video capturing with a stream
    test('Should start video capturing with stream', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      when(mockApi.startImageStream()).thenAnswer((_) async {});

      final Completer<void> streamCallbackCompleter = Completer<void>();
      await camera.startVideoCapturing(
        VideoCaptureOptions(
          cameraId,
          streamCallback: (CameraImageData data) {
            streamCallbackCompleter.complete();
          },
        ),
      );

      verify(mockApi.startVideoRecording(true, null)).called(1);

      // startVideoCapturing does not call startImageStream.
      // startImageStream is only called when we listen to onStreamedFrameAvailable
      final Stream<CameraImageData> stream = camera.onStreamedFrameAvailable(
        cameraId,
      );
      final StreamSubscription<CameraImageData> subscription = stream.listen(
        (_) {},
      );
      // Allow async microtasks to run so _startPlatformStream is executed
      await Future<void>.delayed(Duration.zero);
      verify(mockApi.startImageStream()).called(1);
      subscription.cancel();
    });

    // Test case: should start video capturing without a stream
    test('Should start video capturing without stream', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});

      await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

      verify(mockApi.startVideoRecording(false, null)).called(1);
    });

    // Test case: should pass videoOutputPath through to the host API
    test('Should pass videoOutputPath through to the host API', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});

      await camera.startVideoCapturing(
        VideoCaptureOptions(cameraId, videoOutputPath: '/test/output.mp4'),
      );

      verify(mockApi.startVideoRecording(false, '/test/output.mp4')).called(1);
    });

    // Test case: should also pass videoOutputPath through to the host API with a stream
    test(
      'Should pass videoOutputPath through to the host API with a stream',
      () async {
        when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
        when(mockApi.startImageStream()).thenAnswer((_) async {});

        await camera.startVideoCapturing(
          VideoCaptureOptions(
            cameraId,
            streamCallback: (CameraImageData data) {},
            videoOutputPath: '/test/output.mp4',
          ),
        );

        verify(mockApi.startVideoRecording(true, '/test/output.mp4')).called(1);
      },
    );
  });

  // Test group: coverage gap tests (completing public XTS interface coverage)
  group('Coverage Gap Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;

    setUp(() async {
      mockApi = MockCameraApi();
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Test case: should emit camera switched events
    test('Should emit camera switched events', () async {
      final Stream<String> switchedStream = camera.onCameraSwitched(cameraId);
      final StreamQueue<String> streamQueue =
          StreamQueue<String>(switchedStream);

      camera.hostCameraHandlers[cameraId]!.cameraSwitched('rear');
      // Reference the controller field directly so the coverage script can resolve it.
      expect(camera.cameraSwitchedStreamController.hasListener, isTrue);

      expect(await streamQueue.next, 'rear');
      await streamQueue.cancel();
    });

    // Test case: should emit camera resolution changed events
    test('Should emit camera resolution changed events', () async {
      final Stream<CameraResolutionChangedEvent> eventStream =
          camera.onCameraResolutionChanged(cameraId);
      final StreamQueue<CameraResolutionChangedEvent> streamQueue =
          StreamQueue<CameraResolutionChangedEvent>(eventStream);

      camera.cameraEventStreamController.add(
        CameraResolutionChangedEvent(cameraId, 1920, 1080),
      );

      final CameraResolutionChangedEvent event = await streamQueue.next;
      expect(event.captureWidth, 1920);
      expect(event.captureHeight, 1080);
      await streamQueue.cancel();
    });

    // Test case: should emit video recorded events
    test('Should emit video recorded events', () async {
      final Stream<VideoRecordedEvent> eventStream =
          camera.onVideoRecordedEvent(cameraId);
      final StreamQueue<VideoRecordedEvent> streamQueue =
          StreamQueue<VideoRecordedEvent>(eventStream);

      camera.cameraEventStreamController.add(VideoRecordedEvent(
        cameraId,
        XFile('/test.mp4'),
        const Duration(seconds: 10),
      ));

      final VideoRecordedEvent event = await streamQueue.next;
      expect(event.file.path, '/test.mp4');
      expect(event.maxVideoDuration, const Duration(seconds: 10));
      await streamQueue.cancel();
    });

    // Test case: should complete prepareForVideoRecording normally
    test('Should complete prepareForVideoRecording', () async {
      await camera.prepareForVideoRecording();
    });

    // Test case: should set the image file format
    test('Should set the image file format', () async {
      when(mockApi.setImageFileFormat(any)).thenAnswer((_) async {});

      await camera.setImageFileFormat(cameraId, ImageFileFormat.jpeg);

      verify(mockApi.setImageFileFormat(PlatformImageFileFormat.jpeg))
          .called(1);
    });

    // Test case: should set the JPEG image quality
    test('Should set the jpeg image quality', () async {
      when(mockApi.setJpegImageQuality(any)).thenAnswer((_) async {});

      await camera.setJpegImageQuality(cameraId, 85);

      verify(mockApi.setJpegImageQuality(85)).called(1);
    });

    // Test case: isZeroShutterLagSupported should return the host result (supported)
    test('Should return true when zero-shutter-lag is supported', () async {
      when(mockApi.isZeroShutterLagSupported()).thenAnswer((_) async => true);

      final bool supported = await camera.isZeroShutterLagSupported(cameraId);

      verify(mockApi.isZeroShutterLagSupported()).called(1);
      expect(supported, true);
    });

    // Test case: isZeroShutterLagSupported should return the host result (unsupported)
    test(
      'Should return false when zero-shutter-lag is not supported',
      () async {
        when(
          mockApi.isZeroShutterLagSupported(),
        ).thenAnswer((_) async => false);

        final bool supported = await camera.isZeroShutterLagSupported(cameraId);

        verify(mockApi.isZeroShutterLagSupported()).called(1);
        expect(supported, false);
      },
    );

    // Test case: should pass the ZSL toggle through to the host API
    test(
      'Should pass zero-shutter-lag enabled flag through to the host API',
      () async {
        when(mockApi.setZeroShutterLagEnabled(any)).thenAnswer((_) async {});

        await camera.setZeroShutterLagEnabled(cameraId, true);

        verify(mockApi.setZeroShutterLagEnabled(true)).called(1);
      },
    );

    // Test case: should throw CameraException when setImageFileFormat throws a PlatformException
    test('Should throw CameraException when setImageFileFormat throws a '
        'PlatformException', () async {
      when(mockApi.setImageFileFormat(any)).thenThrow(
        PlatformException(code: 'IMG_FMT_ERROR', message: 'Image format error'),
      );

      expect(
        () => camera.setImageFileFormat(cameraId, ImageFileFormat.jpeg),
        throwsA(
          isA<CameraException>()
              .having((e) => e.code, 'code', 'IMG_FMT_ERROR')
              .having(
                (e) => e.description,
                'description',
                'Image format error',
              ),
        ),
      );
    });

    // Test case: should throw CameraException when setJpegImageQuality throws a PlatformException
    test('Should throw CameraException when setJpegImageQuality throws a '
        'PlatformException', () async {
      when(mockApi.setJpegImageQuality(any)).thenThrow(
        PlatformException(
          code: 'JPEG_QUALITY_ERROR',
          message: 'Jpeg quality error',
        ),
      );

      expect(
        () => camera.setJpegImageQuality(cameraId, 85),
        throwsA(
          isA<CameraException>()
              .having((e) => e.code, 'code', 'JPEG_QUALITY_ERROR')
              .having(
                (e) => e.description,
                'description',
                'Jpeg quality error',
              ),
        ),
      );
    });

    // Test case: a directly constructed HostCameraMessageHandler should broadcast camera events
    test('Should broadcast camera events from a directly constructed '
        'HostCameraMessageHandler', () async {
      final StreamController<CameraEvent> eventCtrl =
          StreamController<CameraEvent>.broadcast();
      final StreamController<String> switchedCtrl =
          StreamController<String>.broadcast();
      final HostCameraMessageHandler handler = HostCameraMessageHandler(
        42,
        eventCtrl,
        switchedCtrl,
      );
      final StreamQueue<CameraEvent> eventQueue = StreamQueue<CameraEvent>(
        eventCtrl.stream,
      );
      final StreamQueue<String> switchedQueue = StreamQueue<String>(
        switchedCtrl.stream,
      );

      handler.initialized(
        PlatformCameraState(
          previewSize: PlatformSize(width: 1920, height: 1080),
          exposureMode: PlatformExposureMode.auto,
          exposurePointSupported: true,
          focusMode: PlatformFocusMode.auto,
          focusPointSupported: true,
        ),
      );
      handler.error('boom');
      handler.closed();
      handler.cameraSwitched('front');

      final CameraInitializedEvent initEvent =
          (await eventQueue.next) as CameraInitializedEvent;
      expect(initEvent.previewWidth, 1920);
      expect(initEvent.previewHeight, 1080);
      final CameraErrorEvent errorEvent =
          (await eventQueue.next) as CameraErrorEvent;
      expect(errorEvent.description, 'boom');
      expect(await eventQueue.next, isA<CameraClosingEvent>());
      expect(await switchedQueue.next, 'front');

      handler.dispose();
      await eventQueue.cancel();
      await switchedQueue.cancel();
      await eventCtrl.close();
      await switchedCtrl.close();
    });

    // Test case: a directly constructed HostDeviceMessageHandler should broadcast device orientation events
    test('Should broadcast device orientation from a directly constructed '
        'HostDeviceMessageHandler', () async {
      final HostDeviceMessageHandler handler = HostDeviceMessageHandler();
      final StreamQueue<DeviceEvent> eventQueue = StreamQueue<DeviceEvent>(
        handler.deviceEventStreamController.stream,
      );

      handler.deviceOrientationChanged(PlatformDeviceOrientation.landscapeLeft);

      final DeviceOrientationChangedEvent event =
          (await eventQueue.next) as DeviceOrientationChangedEvent;
      expect(event.orientation, DeviceOrientation.landscapeLeft);
      await eventQueue.cancel();
      await handler.deviceEventStreamController.close();
    });
  });

  // Test group: edge case and exception scenario tests (completing test scenario coverage)
  group('Edge Case Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;

    setUp(() async {
      mockApi = MockCameraApi();
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Parameter edge case: should send a null exposure point
    test('Should send null exposure point', () async {
      when(mockApi.setExposurePoint(any)).thenAnswer((_) async {});

      await camera.setExposurePoint(cameraId, null);

      verify(mockApi.setExposurePoint(null)).called(1);
    });

    // Parameter edge case: should throw AssertionError when the exposure point is out of range
    test('Should throw AssertionError when exposure point is out of range', () {
      expect(
        () => camera.setExposurePoint(cameraId, const Point<double>(1.5, 0.5)),
        throwsAssertionError,
      );
    });

    // Parameter edge case: should send a null focus point
    test('Should send null focus point', () async {
      when(mockApi.setFocusPoint(any)).thenAnswer((_) async {});

      await camera.setFocusPoint(cameraId, null);

      verify(mockApi.setFocusPoint(null)).called(1);
    });

    // Parameter edge case: should throw AssertionError when the focus point is out of range
    test('Should throw AssertionError when focus point is out of range', () {
      expect(
        () => camera.setFocusPoint(cameraId, const Point<double>(0.5, -0.2)),
        throwsAssertionError,
      );
    });

    // State edge case: stopping video without an active recording should throw CameraException
    test(
      'Should throw CameraException when stopping video without recording',
      () async {
        expect(
          () => camera.stopVideoRecording(cameraId),
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'videoRecordingFailed')
                .having(
                  (e) => e.description,
                  'description',
                  'No recording in progress',
                ),
          ),
        );
      },
    );

    // State edge case: an initialization error event should fail initialization
    test('Should fail initialization with CameraException on error event', () async {
      final Future<void> initializeFuture = camera.initializeCamera(cameraId);

      camera.hostCameraHandlers[cameraId]!.error('Initialization failed');
      // initializeCamera internally awaits the initialized event via `.first`; re-emit one here
      // so the pending future completes normally and that tearDown closing the controller does not
      // trigger a "No element" unhandled error (the error handler already set completed=true and is ignored).
      camera.hostCameraHandlers[cameraId]!.initialized(testCameraState());

        await expectLater(
          initializeFuture,
          throwsA(
            isA<CameraException>()
                .having((e) => e.code, 'code', 'CameraError'),
          ),
        );
      },
    );

    // State edge case: dispose should clear the handler and recording state
    test('Should clear handler and recording state on dispose', () async {
      when(mockApi.dispose()).thenAnswer((_) async {});

      await camera.dispose(cameraId);

      expect(camera.hostCameraHandlers.containsKey(cameraId), isFalse);
      // _isRecordingMap is private; verify it indirectly through observable behavior:
      // stopping video after dispose should throw "no recording in progress".
      expect(
        () => camera.stopVideoRecording(cameraId),
        throwsA(
          isA<CameraException>()
              .having((e) => e.code, 'code', 'videoRecordingFailed'),
        ),
      );
    });

    // Concurrency: should deduplicate concurrent startVideoCapturing requests
    test(
      'Should deduplicate concurrent startVideoCapturing requests',
      () async {
        when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});

        await camera.startVideoCapturing(VideoCaptureOptions(cameraId));
        await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

        verify(mockApi.startVideoRecording(false, null)).called(1);
      },
    );

    // Concurrency: should reset the recording state after a failed start
    test('Should reset recording state after failed start', () async {
      when(mockApi.startVideoRecording(any, any)).thenThrow(
        PlatformException(code: 'RECORD_FAILED', message: 'Record failed'),
      );

      await expectLater(
        camera.startVideoCapturing(VideoCaptureOptions(cameraId)),
        throwsA(isA<PlatformException>()),
      );

      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

      verify(mockApi.startVideoRecording(false, null)).called(2);
    });

    // Concurrency: multiple cameras may record concurrently
    test('Should allow recording on multiple cameras concurrently', () async {
      int nextId = 0;
      when(mockApi.create(any, any)).thenAnswer((_) async => ++nextId);
      when(mockApi.initialize(any)).thenAnswer((_) async {});
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      final OhosCamera camera = OhosCamera(hostApi: mockApi);

      final int cameraIdA = await camera.createCamera(
        const CameraDescription(
          name: 'A',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );
      final int cameraIdB = await camera.createCamera(
        const CameraDescription(
          name: 'B',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      );

      await camera.startVideoCapturing(VideoCaptureOptions(cameraIdA));
      await camera.startVideoCapturing(VideoCaptureOptions(cameraIdB));

      verify(mockApi.startVideoRecording(false, null)).called(2);
    });

    // Boundary: should return an empty list when no cameras are available
    test('Should return empty list when no cameras available', () async {
      when(mockApi.getAvailableCameras())
          .thenAnswer((_) async => <PlatformCameraDescription?>[]);

      final List<CameraDescription> cameras = await camera.availableCameras();

      expect(cameras, isEmpty);
    });

    // Boundary: exposure point boundary values should pass through
    test('Should set exposure point at boundary values', () async {
      when(mockApi.setExposurePoint(any)).thenAnswer((_) async {});

      await camera.setExposurePoint(cameraId, const Point<double>(0.0, 1.0));

      verify(
        mockApi.setExposurePoint(
          argThat(
            isA<PlatformPoint>()
                .having((p) => p.x, 'x', 0.0)
                .having((p) => p.y, 'y', 1.0),
          ),
        ),
      ).called(1);
    });
  });

  // Test group: recording frame stream lifecycle tests (startVideoCapturing subscription cleanup)
  group('Video Recording Frame Stream Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;
    const MethodChannel imageStreamChannel = MethodChannel(
      'plugins.flutter.io/camera_ohos/imageStream',
    );

    setUp(() async {
      mockApi = MockCameraApi();
      // The EventChannel listen/cancel handshake just returns null; frame data is injected
      // via handlePlatformMessage from the "host" side.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(imageStreamChannel, (
            MethodCall call,
          ) async {
            return null;
          });
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(imageStreamChannel, null);
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Delivers one YUV420 frame to the plugin from the host side via the mocked EventChannel.
    // EventChannel parses host messages with decodeEnvelope, so wrap the payload in a success envelope.
    Future<void> sendFrame() async {
      final ByteData? encoded = const StandardMethodCodec()
          .encodeSuccessEnvelope(<Object?, Object?>{
            'format':
                35, // YUV420, see the format mapping in type_conversion.dart
            'width': 4,
            'height': 4,
            'planes': <Object?>[
              <Object?, Object?>{
                'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
                'bytesPerRow': 4,
              },
            ],
          });
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            imageStreamChannel.name,
            encoded,
            (ByteData? reply) {},
          );
      // The EventChannel broadcast controller is asynchronous: events reach listeners
      // in a later microtask; pump one event-loop turn so delivery completes (and wrong deliveries get a chance before negative assertions).
      await Future<void>.delayed(Duration.zero);
    }

    // Test case: the frame callback should receive frame data during recording
    test('Should deliver frames to the recording stream callback', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});

      int frameCount = 0;
      await camera.startVideoCapturing(
        VideoCaptureOptions(
          cameraId,
          streamCallback: (CameraImageData data) {
            frameCount++;
          },
        ),
      );
      // Wait for the EventChannel listen handshake to complete before injecting a frame.
      await Future<void>.delayed(Duration.zero);

      await sendFrame();

      expect(frameCount, 1);
    });

    // Test case: the frame callback should stop receiving frames after stopVideoRecording (subscription cleanup)
    test('Should stop delivering frames after stopVideoRecording', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      when(
        mockApi.stopVideoRecording(),
      ).thenAnswer((_) async => '/test/path.mp4');

      int frameCount = 0;
      await camera.startVideoCapturing(
        VideoCaptureOptions(
          cameraId,
          streamCallback: (CameraImageData data) {
            frameCount++;
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await sendFrame();
      expect(frameCount, 1);

      await camera.stopVideoRecording(cameraId);
      // After stopping, deliver a frame; the callback must not fire again.
      await sendFrame();

      expect(
        frameCount,
        1,
        reason:
            'frames must not reach the callback after '
            'stopVideoRecording',
      );
    });

    // Test case: repeated startVideoCapturing should cancel the stale subscription so only the new callback receives frames
    test(
      'Should replace stale frame subscription on repeated startVideoCapturing',
      () async {
        when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
        when(
          mockApi.stopVideoRecording(),
        ).thenAnswer((_) async => '/test/path.mp4');

        int framesA = 0;
        int framesB = 0;
        await camera.startVideoCapturing(
          VideoCaptureOptions(
            cameraId,
            streamCallback: (CameraImageData data) {
              framesA++;
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await sendFrame();
        expect(framesA, 1);

        await camera.stopVideoRecording(cameraId);

        await camera.startVideoCapturing(
          VideoCaptureOptions(
            cameraId,
            streamCallback: (CameraImageData data) {
              framesB++;
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await sendFrame();

        // Old callback A no longer receives frames (core assertion of the leak fix); new callback B receives normally.
        expect(framesA, 1);
        expect(framesB, 1);
        verify(mockApi.startVideoRecording(true, null)).called(2);
      },
    );

    // Test case: dispose should cancel the recording frame stream subscription so the frame callback stops receiving frames
    test('Should cancel the recording frame stream on dispose', () async {
      when(mockApi.startVideoRecording(any, any)).thenAnswer((_) async {});
      when(mockApi.dispose()).thenAnswer((_) async {});

      int frameCount = 0;
      await camera.startVideoCapturing(
        VideoCaptureOptions(
          cameraId,
          streamCallback: (CameraImageData data) {
            frameCount++;
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await sendFrame();
      expect(frameCount, 1);

      await camera.dispose(cameraId);
      await sendFrame();

      expect(
        frameCount,
        1,
        reason: 'frames must not reach the callback after dispose',
      );
    });
  });

  // Test group: frame stream lifecycle tests (onStreamedFrameAvailable error/close/pause-resume paths)
  group('Frame Stream Lifecycle Tests', () {
    late OhosCamera camera;
    late int cameraId;
    late MockCameraApi mockApi;
    const MethodChannel imageStreamChannel = MethodChannel(
      'plugins.flutter.io/camera_ohos/imageStream',
    );

    setUp(() async {
      mockApi = MockCameraApi();
      // The EventChannel listen/cancel handshake just returns null; error and close events are injected
      // via handlePlatformMessage from the "host" side.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(imageStreamChannel, (
            MethodCall call,
          ) async {
            return null;
          });
      (camera, cameraId) = await createInitializedCamera(mockApi);
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(imageStreamChannel, null);
      await camera.cameraEventStreamController.close();
      await camera.cameraSwitchedStreamController.close();
      await camera.hostHandler.deviceEventStreamController.close();
    });

    // Test case: after the frame stream channel emits an error, the underlying subscription should be cleared and re-listening should rebuild it
    test('Should rebuild the frame stream subscription after an error event', () async {
      when(mockApi.startImageStream()).thenAnswer((_) async {});
      when(mockApi.stopImageStream()).thenAnswer((_) async {});

      int listenHandshakes = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(imageStreamChannel, (
            MethodCall call,
          ) async {
            if (call.method == 'listen') {
              listenHandshakes++;
            }
            return null;
          });

      final Stream<CameraImageData> firstStream = camera
          .onStreamedFrameAvailable(cameraId);
      final StreamSubscription<CameraImageData> first = firstStream.listen(
        (_) {},
      );
      // Wait for the onListen microtask: startImageStream + EventChannel 'listen' handshake.
      await Future<void>.delayed(Duration.zero);
      expect(listenHandshakes, 1);

      // Inject an error envelope from the host side: the EventChannel internally throws a
      // PlatformException in decodeEnvelope, which reaches the subscription onError callback via addError (clearing the underlying subscription).
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            imageStreamChannel.name,
            const StandardMethodCodec().encodeErrorEnvelope(
              code: 'streamError',
              message: 'frame stream error',
            ),
            (ByteData? reply) {},
          );
      await Future<void>.delayed(Duration.zero);

      // After onError cleared the underlying subscription the _startStreamListener guard passes; listening again should
      // redo the EventChannel 'listen' handshake (otherwise the guard returns early and the count stalls at 1).
      final StreamSubscription<CameraImageData> second = camera
          .onStreamedFrameAvailable(cameraId)
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(
        listenHandshakes,
        2,
        reason:
            'onError must clear the stale subscription so the next listener '
            'rebuilds it',
      );

      // Cleanup: cancel the rebuilt subscription first (its underlying subscription is the current field reference), then the first one.
      await second.cancel();
      await first.cancel();
    });

    // Test case: after the frame stream channel closes, the underlying subscription should be cleared and re-listening should rebuild it
    test(
      'Should rebuild the frame stream subscription after the channel closes',
      () async {
        when(mockApi.startImageStream()).thenAnswer((_) async {});
        when(mockApi.stopImageStream()).thenAnswer((_) async {});

        int listenHandshakes = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(imageStreamChannel, (
              MethodCall call,
            ) async {
              if (call.method == 'listen') {
                listenHandshakes++;
              }
              return null;
            });

        final Stream<CameraImageData> firstStream = camera
            .onStreamedFrameAvailable(cameraId);
        final StreamSubscription<CameraImageData> first = firstStream.listen(
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);
        expect(listenHandshakes, 1);

        // Inject null data: the EventChannel internal handler closes the broadcast stream on null,
        // the onDone callback runs and clears the underlying subscription.
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              imageStreamChannel.name,
              null,
              (ByteData? reply) {},
            );
        await Future<void>.delayed(Duration.zero);

        // After onDone cleared the underlying subscription the guard passes: listening again should redo the 'listen' handshake.
        final StreamSubscription<CameraImageData> second = camera
            .onStreamedFrameAvailable(cameraId)
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);
        expect(
          listenHandshakes,
          2,
          reason:
              'onDone must clear the stale subscription so the next listener '
              'rebuilds it',
        );

        // Cleanup order is the same as the error case.
        await second.cancel();
        await first.cancel();
      },
    );

    // Test case: pausing/resuming the frame stream should throw the InvalidCall CameraException
    test(
      'Should throw CameraException when pausing or resuming the streamed frame stream',
      () async {
        when(mockApi.startImageStream()).thenAnswer((_) async {});
        when(mockApi.stopImageStream()).thenAnswer((_) async {});

        final StreamSubscription<CameraImageData> subscription = camera
            .onStreamedFrameAvailable(cameraId)
            .listen((_) {});
        await Future<void>.delayed(Duration.zero);

        // StreamController invokes onPause/onResume through _runGuarded; exceptions thrown by the callbacks go
        // through the zone uncaught-error channel (neither synchronous throws nor stream error events),
        // so capture them in a controlled runZonedGuarded and assert there.
        final List<Object> uncaughtErrors = <Object>[];
        runZonedGuarded(
          () {
            subscription.pause();
            subscription.resume();
          },
          (Object error, StackTrace stackTrace) {
            uncaughtErrors.add(error);
          },
        );

        expect(uncaughtErrors, hasLength(2));
        for (final Object error in uncaughtErrors) {
          expect(
            error,
            isA<CameraException>()
                .having((e) => e.code, 'code', 'InvalidCall')
                .having(
                  (e) => e.description,
                  'description',
                  'Pause and resume are not supported for onStreamedFrameAvailable',
                ),
          );
        }

        await subscription.cancel();
      },
    );
  });
}
