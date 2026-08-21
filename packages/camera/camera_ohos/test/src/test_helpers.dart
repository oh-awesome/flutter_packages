import 'package:camera_ohos/src/messages.g.dart';
import 'package:camera_ohos/src/ohos_camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:mockito/mockito.dart';

import '../ohos_camera_test.mocks.dart';

/// Creates an initialized [OhosCamera] backed by [mockApi].
///
/// Returns the camera instance and the created camera id in a record. The
/// camera is fully initialized (the `initialized` platform callback is fired)
/// so tests can exercise post-initialization behavior immediately.
Future<(OhosCamera, int)> createInitializedCamera(
  MockCameraApi mockApi, {
  int cameraId = 1,
}) async {
  when(mockApi.create(any, any)).thenAnswer((_) async => cameraId);
  when(mockApi.initialize(any)).thenAnswer((_) async {});
  final OhosCamera camera = OhosCamera(hostApi: mockApi);
  final int id = await camera.createCamera(
    const CameraDescription(
      name: 'Test',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ),
    ResolutionPreset.high,
  );
  final Future<void> initializeFuture = camera.initializeCamera(id);
  camera.hostCameraHandlers[id]!.initialized(testCameraState());
  await initializeFuture;
  return (camera, id);
}

/// Builds a default [PlatformCameraState] used to complete initialization.
PlatformCameraState testCameraState({
  double width = 1920,
  double height = 1080,
}) {
  return PlatformCameraState(
    previewSize: PlatformSize(width: width, height: height),
    exposureMode: PlatformExposureMode.auto,
    exposurePointSupported: true,
    focusMode: PlatformFocusMode.auto,
    focusPointSupported: true,
  );
}
