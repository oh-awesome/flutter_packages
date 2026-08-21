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

  // 测试用例：注册实例
  test('registers instance', () async {
    OhosCamera.registerWith();
    expect(CameraPlatform.instance, isA<OhosCamera>());
  });

  // 测试组：创建、初始化与销毁测试
  group('Creation, Initialization & Disposal Tests', () {
    // 测试用例：应当发送创建数据并返回相机 ID
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

    // 测试用例：当 create 抛出 PlatformException 时应当抛出 CameraException
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

    // 测试用例：当 initialize 抛出 PlatformException 时应当抛出 CameraException
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

    // 测试用例：应当发送初始化数据
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

    // 测试用例：销毁时应当发送 disposal 调用
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

  // 测试组：事件测试
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

    // 测试用例：应当接收到 initialized（初始化完成）事件
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

    // 测试用例：应当接收到 camera closing（相机关闭）事件
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

    // 测试用例：应当接收到 camera error（相机错误）事件
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

    // 测试用例：应当接收到 device orientation change（设备方向改变）事件
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

  // 测试组：功能测试
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

    // 测试用例：应当获取可用相机的 CameraDescription 实例
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

    // 测试用例：当 availableCameras 抛出 PlatformException 时应当抛出 CameraException
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

    // 测试用例：应当拍摄照片并返回 XFile 实例
    test('Should take a picture and return an XFile instance', () async {
      when(mockApi.takePicture()).thenAnswer((_) async => '/test/path.jpg');

      final XFile file = await camera.takePicture(cameraId);

      verify(mockApi.takePicture()).called(1);
      expect(file.path, '/test/path.jpg');
    });

    // 测试用例：应当开始录制视频
    test('Should start video recording', () async {
      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});

      await camera.startVideoRecording(cameraId);

      verify(mockApi.startVideoRecording(false)).called(1);
    });

    // 测试用例：应当停止视频录制并返回文件
    test('Should stop a video recording and return the file', () async {
      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});
      when(mockApi.stopVideoRecording()).thenAnswer((_) async => '/test/path.mp4');

      await camera.startVideoRecording(cameraId);
      final XFile file = await camera.stopVideoRecording(cameraId);

      verify(mockApi.stopVideoRecording()).called(1);
      expect(file.path, '/test/path.mp4');
    });

    // 测试用例：应当暂停视频录制
    test('Should pause a video recording', () async {
      when(mockApi.pauseVideoRecording()).thenAnswer((_) async {});

      await camera.pauseVideoRecording(cameraId);

      verify(mockApi.pauseVideoRecording()).called(1);
    });

    // 测试用例：应当恢复视频录制
    test('Should resume a video recording', () async {
      when(mockApi.resumeVideoRecording()).thenAnswer((_) async {});

      await camera.resumeVideoRecording(cameraId);

      verify(mockApi.resumeVideoRecording()).called(1);
    });

    // 测试用例：应当设置闪光灯模式
    test('Should set the flash mode', () async {
      when(mockApi.setFlashMode(any)).thenAnswer((_) async {});

      await camera.setFlashMode(cameraId, FlashMode.always);

      verify(mockApi.setFlashMode(PlatformFlashMode.always)).called(1);
    });

    // 测试用例：应当设置曝光模式
    test('Should set the exposure mode', () async {
      when(mockApi.setExposureMode(any)).thenAnswer((_) async {});

      await camera.setExposureMode(cameraId, ExposureMode.auto);

      verify(mockApi.setExposureMode(PlatformExposureMode.auto)).called(1);
    });

    // 测试用例：应当设置曝光点
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

    // 测试用例：应当获取最小曝光偏移量
    test('Should get the min exposure offset', () async {
      when(mockApi.getMinExposureOffset()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getMinExposureOffset(cameraId);

      verify(mockApi.getMinExposureOffset()).called(1);
      expect(stepSize, 1.0);
    });

    // 测试用例：应当获取最大曝光偏移量
    test('Should get the max exposure offset', () async {
      when(mockApi.getMaxExposureOffset()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getMaxExposureOffset(cameraId);

      verify(mockApi.getMaxExposureOffset()).called(1);
      expect(stepSize, 1.0);
    });

    // 测试用例：应当获取曝光偏移步长
    test('Should get the exposure offset step size', () async {
      when(mockApi.getExposureOffsetStepSize()).thenAnswer((_) async => 1.0);

      final double stepSize = await camera.getExposureOffsetStepSize(cameraId);

      verify(mockApi.getExposureOffsetStepSize()).called(1);
      expect(stepSize, 1.0);
    });

    // 测试用例：应当设置曝光偏移量
    test('Should set the exposure offset', () async {
      when(mockApi.setExposureOffset(any)).thenAnswer((_) async => 1.0);

      final double actualOffset = await camera.setExposureOffset(cameraId, 1.0);

      verify(mockApi.setExposureOffset(1.0)).called(1);
      expect(actualOffset, 1.0);
    });

    // 测试用例：应当设置对焦模式
    test('Should set the focus mode', () async {
      when(mockApi.setFocusMode(any)).thenAnswer((_) async {});

      await camera.setFocusMode(cameraId, FocusMode.auto);

      verify(mockApi.setFocusMode(PlatformFocusMode.auto)).called(1);
    });

    // 测试用例：应当设置对焦点
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

    // 测试用例：应当获取最大缩放级别
    test('Should get the max zoom level', () async {
      when(mockApi.getMaxZoomLevel()).thenAnswer((_) async => 1.0);

      final double maxZoomLevel = await camera.getMaxZoomLevel(cameraId);

      verify(mockApi.getMaxZoomLevel()).called(1);
      expect(maxZoomLevel, 1.0);
    });

    // 测试用例：应当获取最小缩放级别
    test('Should get the min zoom level', () async {
      when(mockApi.getMinZoomLevel()).thenAnswer((_) async => 1.0);

      final double maxZoomLevel = await camera.getMinZoomLevel(cameraId);

      verify(mockApi.getMinZoomLevel()).called(1);
      expect(maxZoomLevel, 1.0);
    });

    // 测试用例：应当设置缩放级别
    test('Should set the zoom level', () async {
      when(mockApi.setZoomLevel(any)).thenAnswer((_) async {});

      await camera.setZoomLevel(cameraId, 1.0);

      verify(mockApi.setZoomLevel(1.0)).called(1);
    });

    // 测试用例：当提供非法的缩放级别时应当抛出 CameraException
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

    // 测试用例：应当锁定捕获方向
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

    // 测试用例：应当解锁捕获方向
    test('Should unlock the capture orientation', () async {
      when(mockApi.unlockCaptureOrientation()).thenAnswer((_) async {});

      await camera.unlockCaptureOrientation(cameraId);

      verify(mockApi.unlockCaptureOrientation()).called(1);
    });

    // 测试用例：应当暂停相机预览
    test('Should pause the camera preview', () async {
      when(mockApi.pausePreview()).thenAnswer((_) async {});

      await camera.pausePreview(cameraId);

      verify(mockApi.pausePreview()).called(1);
    });

    // 测试用例：应当恢复相机预览
    test('Should resume the camera preview', () async {
      when(mockApi.resumePreview()).thenAnswer((_) async {});

      await camera.resumePreview(cameraId);

      verify(mockApi.resumePreview()).called(1);
    });

    // 测试用例：应当发送带设置的创建数据并返回相机 ID
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

    // 测试用例：应当获取支持的视频防抖模式
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

    // 测试用例：应当设置视频防抖模式
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

    // 测试用例：当 setVideoStabilizationMode 抛出 PlatformException 时应当抛出 CameraException
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

    // 测试用例：应当在录制时设置描述信息
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

    // 测试用例：应当支持图像流
    test('Should support image streaming', () {
      expect(camera.supportsImageStreaming(), true);
    });

    // 测试用例：应当构建预览组件
    test('Should build preview widget', () {
      final Widget widget = camera.buildPreview(cameraId);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, cameraId);
    });

    // 测试用例：应当带数据流开始视频捕获
    test('Should start video capturing with stream', () async {
      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});
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

      verify(mockApi.startVideoRecording(true)).called(1);

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

    // 测试用例：应当无数据流开始视频捕获
    test('Should start video capturing without stream', () async {
      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});

      await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

      verify(mockApi.startVideoRecording(false)).called(1);
    });
  });

  // 测试组：覆盖率缺口测试（补齐 XTS 公开接口覆盖）
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

    // 测试用例：应当发射相机切换事件
    test('Should emit camera switched events', () async {
      final Stream<String> switchedStream = camera.onCameraSwitched(cameraId);
      final StreamQueue<String> streamQueue =
          StreamQueue<String>(switchedStream);

      camera.hostCameraHandlers[cameraId]!.cameraSwitched('rear');
      // 直接引用 controller 字段，使覆盖率脚本能解析该字段。
      expect(camera.cameraSwitchedStreamController.hasListener, isTrue);

      expect(await streamQueue.next, 'rear');
      await streamQueue.cancel();
    });

    // 测试用例：应当发射相机分辨率变化事件
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

    // 测试用例：应当发射视频录制完成事件
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

    // 测试用例：应当正常完成 prepareForVideoRecording
    test('Should complete prepareForVideoRecording', () async {
      await camera.prepareForVideoRecording();
    });

    // 测试用例：应当设置图片文件格式
    test('Should set the image file format', () async {
      when(mockApi.setImageFileFormat(any)).thenAnswer((_) async {});

      await camera.setImageFileFormat(cameraId, ImageFileFormat.jpeg);

      verify(mockApi.setImageFileFormat(PlatformImageFileFormat.jpeg))
          .called(1);
    });

    // 测试用例：应当设置 JPEG 图片质量
    test('Should set the jpeg image quality', () async {
      when(mockApi.setJpegImageQuality(any)).thenAnswer((_) async {});

      await camera.setJpegImageQuality(cameraId, 85);

      verify(mockApi.setJpegImageQuality(85)).called(1);
    });

    // 测试用例：setImageFileFormat 抛出 PlatformException 时应当抛出 CameraException
    test(
      'Should throw CameraException when setImageFileFormat throws a '
      'PlatformException',
      () async {
        when(mockApi.setImageFileFormat(any)).thenThrow(
          PlatformException(
            code: 'IMG_FMT_ERROR',
            message: 'Image format error',
          ),
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
      },
    );

    // 测试用例：setJpegImageQuality 抛出 PlatformException 时应当抛出 CameraException
    test(
      'Should throw CameraException when setJpegImageQuality throws a '
      'PlatformException',
      () async {
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
      },
    );

    // 测试用例：直接构造的 HostCameraMessageHandler 应当广播相机事件
    test(
      'Should broadcast camera events from a directly constructed '
      'HostCameraMessageHandler',
      () async {
        final StreamController<CameraEvent> eventCtrl =
            StreamController<CameraEvent>.broadcast();
        final StreamController<String> switchedCtrl =
            StreamController<String>.broadcast();
        final HostCameraMessageHandler handler =
            HostCameraMessageHandler(42, eventCtrl, switchedCtrl);
        final StreamQueue<CameraEvent> eventQueue =
            StreamQueue<CameraEvent>(eventCtrl.stream);
        final StreamQueue<String> switchedQueue =
            StreamQueue<String>(switchedCtrl.stream);

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
      },
    );

    // 测试用例：直接构造的 HostDeviceMessageHandler 应当广播设备方向事件
    test(
      'Should broadcast device orientation from a directly constructed '
      'HostDeviceMessageHandler',
      () async {
        final HostDeviceMessageHandler handler = HostDeviceMessageHandler();
        final StreamQueue<DeviceEvent> eventQueue = StreamQueue<DeviceEvent>(
          handler.deviceEventStreamController.stream,
        );

        handler.deviceOrientationChanged(
          PlatformDeviceOrientation.landscapeLeft,
        );

        final DeviceOrientationChangedEvent event =
            (await eventQueue.next) as DeviceOrientationChangedEvent;
        expect(event.orientation, DeviceOrientation.landscapeLeft);
        await eventQueue.cancel();
        await handler.deviceEventStreamController.close();
      },
    );
  });

  // 测试组：边界与异常场景测试（补齐测试场景覆盖）
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

    // 参数异常：应当发送空曝光点
    test('Should send null exposure point', () async {
      when(mockApi.setExposurePoint(any)).thenAnswer((_) async {});

      await camera.setExposurePoint(cameraId, null);

      verify(mockApi.setExposurePoint(null)).called(1);
    });

    // 参数异常：曝光点越界时应当抛出 AssertionError
    test('Should throw AssertionError when exposure point is out of range', () {
      expect(
        () => camera.setExposurePoint(cameraId, const Point<double>(1.5, 0.5)),
        throwsAssertionError,
      );
    });

    // 参数异常：应当发送空对焦点
    test('Should send null focus point', () async {
      when(mockApi.setFocusPoint(any)).thenAnswer((_) async {});

      await camera.setFocusPoint(cameraId, null);

      verify(mockApi.setFocusPoint(null)).called(1);
    });

    // 参数异常：对焦点越界时应当抛出 AssertionError
    test('Should throw AssertionError when focus point is out of range', () {
      expect(
        () => camera.setFocusPoint(cameraId, const Point<double>(0.5, -0.2)),
        throwsAssertionError,
      );
    });

    // 状态异常：未录制时停止录像应当抛出 CameraException
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

    // 状态异常：初始化错误事件应当使初始化失败
    test(
      'Should fail initialization with CameraException on error event',
      () async {
        final Future<void> initializeFuture =
            camera.initializeCamera(cameraId);

        camera.hostCameraHandlers[cameraId]!.error('Initialization failed');
        // initializeCamera 内部的 `.first` 会等待 initialized 事件；此处补发一个
        // 让挂起的 future 正常完成，避免 tearDown 关闭 controller 时触发
        // "No element" unhandled error（error 已先置 completed=true，被忽略）。
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

    // 状态异常：dispose 应当清理 handler 与录制状态
    test('Should clear handler and recording state on dispose', () async {
      when(mockApi.dispose()).thenAnswer((_) async {});

      await camera.dispose(cameraId);

      expect(camera.hostCameraHandlers.containsKey(cameraId), isFalse);
      // _isRecordingMap 为私有字段，通过可观察行为间接验证：
      // dispose 后再次停止录像应抛出"未在录制中"。
      expect(
        () => camera.stopVideoRecording(cameraId),
        throwsA(
          isA<CameraException>()
              .having((e) => e.code, 'code', 'videoRecordingFailed'),
        ),
      );
    });

    // 并发：应当去重并发 startVideoCapturing 请求
    test(
      'Should deduplicate concurrent startVideoCapturing requests',
      () async {
        when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});

        await camera.startVideoCapturing(VideoCaptureOptions(cameraId));
        await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

        verify(mockApi.startVideoRecording(false)).called(1);
      },
    );

    // 并发：启动失败后应当复位录制状态
    test('Should reset recording state after failed start', () async {
      when(mockApi.startVideoRecording(any)).thenThrow(
        PlatformException(code: 'RECORD_FAILED', message: 'Record failed'),
      );

      await expectLater(
        camera.startVideoCapturing(VideoCaptureOptions(cameraId)),
        throwsA(isA<PlatformException>()),
      );

      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});
      await camera.startVideoCapturing(VideoCaptureOptions(cameraId));

      verify(mockApi.startVideoRecording(false)).called(2);
    });

    // 并发：多相机可同时录制
    test('Should allow recording on multiple cameras concurrently', () async {
      int nextId = 0;
      when(mockApi.create(any, any)).thenAnswer((_) async => ++nextId);
      when(mockApi.initialize(any)).thenAnswer((_) async {});
      when(mockApi.startVideoRecording(any)).thenAnswer((_) async {});
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

      verify(mockApi.startVideoRecording(false)).called(2);
    });

    // 边界：无相机可用时应当返回空列表
    test('Should return empty list when no cameras available', () async {
      when(mockApi.getAvailableCameras())
          .thenAnswer((_) async => <PlatformCameraDescription?>[]);

      final List<CameraDescription> cameras = await camera.availableCameras();

      expect(cameras, isEmpty);
    });

    // 边界：曝光点边界值应当透传
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
}
