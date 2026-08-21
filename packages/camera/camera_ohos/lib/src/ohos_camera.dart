// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stream_transform/stream_transform.dart';

import 'messages.g.dart';
import 'type_conversion.dart';
import 'utils.dart';

/// The Ohos implementation of [CameraPlatform] that uses method channels.
class OhosCamera extends CameraPlatform {
  /// Creates a new [CameraPlatform] instance.
  OhosCamera({@visibleForTesting CameraApi? hostApi})
      : _hostApi = hostApi ?? CameraApi();

  /// Registers this class as the default instance of [CameraPlatform].
  static void registerWith() {
    CameraPlatform.instance = OhosCamera();
  }

  final CameraApi _hostApi;

  /// The controller we need to broadcast the different events coming
  /// from handleMethodCall, specific to camera events.
  ///
  /// It is a `broadcast` because multiple controllers will connect to
  /// different stream views of this Controller.
  /// This is only exposed for test purposes. It shouldn't be used by clients of
  /// the plugin as it may break or change at any time.
  @visibleForTesting
  final StreamController<CameraEvent> cameraEventStreamController =
      StreamController<CameraEvent>.broadcast();

  /// Stream controller for camera-switched events (e.g., automatic switch to
  /// rear camera in tri-fold dual-screen mode).
  @visibleForTesting
  final StreamController<String> cameraSwitchedStreamController =
      StreamController<String>.broadcast();

  /// Handler for device-level callbacks from the native side.
  @visibleForTesting
  late final HostDeviceMessageHandler hostHandler = HostDeviceMessageHandler();

  /// Map of camera IDs to camera-level callback handlers listening to their
  /// respective platform channels.
  @visibleForTesting
  final Map<int, HostCameraMessageHandler> hostCameraHandlers =
      <int, HostCameraMessageHandler>{};

  // The stream to receive frames from the native code.
  StreamSubscription<dynamic>? _platformImageStreamSubscription;

  // The stream for vending frames to platform interface clients.
  StreamController<CameraImageData>? _frameStreamController;

  // Map of camera IDs to recording state, preventing duplicate recording per camera.
  final Map<int, bool> _isRecordingMap = <int, bool>{};

  Stream<CameraEvent> _cameraEvents(int cameraId) =>
      cameraEventStreamController.stream
          .where((CameraEvent event) => event.cameraId == cameraId);

  /// Returns a stream of camera-switched event names.
  Stream<String> onCameraSwitched(int cameraId) =>
      cameraSwitchedStreamController.stream;

  @override
  Future<List<CameraDescription>> availableCameras() async {
    try {
      final List<PlatformCameraDescription?> cameraDescriptions =
          await _hostApi.getAvailableCameras();
      return cameraDescriptions
          .where((description) => description != null)
          .cast<PlatformCameraDescription>()
          .map((PlatformCameraDescription cameraDescription) {
        return CameraDescription(
            name: cameraDescription.name,
            lensDirection: cameraLensDirectionFromPlatform(
                cameraDescription.lensDirection),
            sensorOrientation: cameraDescription.sensorOrientation);
      }).toList();
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<int> createCamera(
    CameraDescription cameraDescription,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) =>
      createCameraWithSettings(
          cameraDescription,
          MediaSettings(
            resolutionPreset: resolutionPreset,
            enableAudio: enableAudio,
          ));

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async {
    try {
      return await _hostApi.create(
          cameraDescription.name, mediaSettingsToPlatform(mediaSettings));
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    hostCameraHandlers.putIfAbsent(
        cameraId,
        () => HostCameraMessageHandler(cameraId, cameraEventStreamController,
            cameraSwitchedStreamController));

    final Completer<void> completer = Completer<void>();
    bool completed = false;

    unawaited(onCameraInitialized(cameraId)
        .first
        .then((CameraInitializedEvent value) {
      if (!completed) {
        completed = true;
        completer.complete();
      }
    }));

    StreamSubscription<CameraErrorEvent>? errorSub;
    errorSub = onCameraError(cameraId).listen((CameraErrorEvent event) {
      if (!completed) {
        completed = true;
        completer
            .completeError(CameraException('CameraError', event.description));
        errorSub?.cancel();
      }
    });

    try {
      await _hostApi.initialize(imageFormatGroupToPlatform(imageFormatGroup));
    } on PlatformException catch (e, s) {
      completed = true;
      unawaited(errorSub.cancel());
      completer.completeError(CameraException(e.code, e.message), s);
    }

    try {
      return await completer.future;
    } finally {
      unawaited(errorSub.cancel());
    }
  }

  @override
  Future<void> dispose(int cameraId) async {
    _isRecordingMap.remove(cameraId);
    final HostCameraMessageHandler? handler =
        hostCameraHandlers.remove(cameraId);
    handler?.dispose();

    await _hostApi.dispose();
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return _cameraEvents(cameraId).whereType<CameraInitializedEvent>();
  }

  @override
  Stream<CameraResolutionChangedEvent> onCameraResolutionChanged(int cameraId) {
    return _cameraEvents(cameraId).whereType<CameraResolutionChangedEvent>();
  }

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) {
    return _cameraEvents(cameraId).whereType<CameraClosingEvent>();
  }

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) {
    return _cameraEvents(cameraId).whereType<CameraErrorEvent>();
  }

  @override
  Stream<VideoRecordedEvent> onVideoRecordedEvent(int cameraId) {
    return _cameraEvents(cameraId).whereType<VideoRecordedEvent>();
  }

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() {
    return hostHandler.deviceEventStreamController.stream
        .whereType<DeviceOrientationChangedEvent>();
  }

  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) async {
    await _hostApi
        .lockCaptureOrientation(deviceOrientationToPlatform(orientation));
  }

  @override
  Future<void> unlockCaptureOrientation(int cameraId) async {
    await _hostApi.unlockCaptureOrientation();
  }

  @override
  Future<XFile> takePicture(int cameraId) async {
    final String path = await _hostApi.takePicture();
    return XFile(path);
  }

  // This optimization is unnecessary on Ohos.
  @override
  Future<void> prepareForVideoRecording() async {}

  @override
  Future<void> startVideoRecording(int cameraId,
      {Duration? maxVideoDuration}) async {
    // Ignore maxVideoDuration, as it is unimplemented and deprecated.
    return startVideoCapturing(VideoCaptureOptions(cameraId));
  }

  @override
  Future<void> startVideoCapturing(VideoCaptureOptions options) async {
    if (_isRecordingMap[options.cameraId] == true) return;
    _isRecordingMap[options.cameraId] = true;
    try {
      await _hostApi.startVideoRecording(options.streamCallback != null);
    } catch (e) {
      _isRecordingMap[options.cameraId] = false;
      rethrow;
    }
    if (options.streamCallback != null) {
      _installStreamController().stream.listen(options.streamCallback);
      _startStreamListener();
    }
  }

  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    if (_isRecordingMap[cameraId] != true) {
      throw CameraException('videoRecordingFailed', 'No recording in progress');
    }
    try {
      final String path = await _hostApi.stopVideoRecording();
      return XFile(path);
    } finally {
      _isRecordingMap[cameraId] = false;
    }
  }

  @override
  Future<void> pauseVideoRecording(int cameraId) =>
      _hostApi.pauseVideoRecording();

  @override
  Future<void> resumeVideoRecording(int cameraId) =>
      _hostApi.resumeVideoRecording();

  @override
  bool supportsImageStreaming() => true;

  @override
  Stream<CameraImageData> onStreamedFrameAvailable(int cameraId,
      {CameraImageStreamOptions? options}) {
    _installStreamController(onListen: _onFrameStreamListen);
    return _frameStreamController!.stream;
  }

  StreamController<CameraImageData> _installStreamController(
      {void Function()? onListen}) {
    _frameStreamController = StreamController<CameraImageData>(
      onListen: onListen ?? () {},
      onPause: _onFrameStreamPauseResume,
      onResume: _onFrameStreamPauseResume,
      onCancel: _onFrameStreamCancel,
    );
    return _frameStreamController!;
  }

  void _onFrameStreamListen() {
    _startPlatformStream();
  }

  Future<void> _startPlatformStream() async {
    await _hostApi.startImageStream();
    _startStreamListener();
  }

  void _startStreamListener() {
    if (_platformImageStreamSubscription != null) return;
    const EventChannel cameraEventChannel =
        EventChannel('plugins.flutter.io/camera_ohos/imageStream');
    _platformImageStreamSubscription =
        cameraEventChannel.receiveBroadcastStream().listen((dynamic imageData) {
      _frameStreamController!
          .add(cameraImageFromPlatformData(imageData as Map<dynamic, dynamic>));
    }, onError: (Object error) {
      _platformImageStreamSubscription = null;
    }, onDone: () {
      _platformImageStreamSubscription = null;
    });
  }

  FutureOr<void> _onFrameStreamCancel() async {
    await _hostApi.stopImageStream();
    await _platformImageStreamSubscription?.cancel();
    _platformImageStreamSubscription = null;
    _frameStreamController = null;
  }

  void _onFrameStreamPauseResume() {
    throw CameraException('InvalidCall',
        'Pause and resume are not supported for onStreamedFrameAvailable');
  }

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) =>
      _hostApi.setFlashMode(flashModeToPlatform(mode));

  @override
  Future<void> setExposureMode(int cameraId, ExposureMode mode) =>
      _hostApi.setExposureMode(exposureModeToPlatform(mode));

  @override
  Future<void> setExposurePoint(int cameraId, Point<double>? point) {
    assert(point == null || point.x >= 0 && point.x <= 1);
    assert(point == null || point.y >= 0 && point.y <= 1);

    return _hostApi.setExposurePoint(pointToPlatform(point));
  }

  @override
  Future<double> getMinExposureOffset(int cameraId) async {
    return _hostApi.getMinExposureOffset();
  }

  @override
  Future<double> getMaxExposureOffset(int cameraId) async {
    return _hostApi.getMaxExposureOffset();
  }

  @override
  Future<double> getExposureOffsetStepSize(int cameraId) async {
    return _hostApi.getExposureOffsetStepSize();
  }

  @override
  Future<double> setExposureOffset(int cameraId, double offset) async {
    return _hostApi.setExposureOffset(offset);
  }

  @override
  Future<void> setFocusMode(int cameraId, FocusMode mode) =>
      _hostApi.setFocusMode(focusModeToPlatform(mode));

  @override
  Future<void> setFocusPoint(int cameraId, Point<double>? point) {
    assert(point == null || point.x >= 0 && point.x <= 1);
    assert(point == null || point.y >= 0 && point.y <= 1);

    return _hostApi.setFocusPoint(pointToPlatform(point));
  }

  @override
  Future<double> getMaxZoomLevel(int cameraId) async {
    return _hostApi.getMaxZoomLevel();
  }

  @override
  Future<double> getMinZoomLevel(int cameraId) async {
    return _hostApi.getMinZoomLevel();
  }

  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {
    try {
      await _hostApi.setZoomLevel(zoom);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> pausePreview(int cameraId) async {
    await _hostApi.pausePreview();
  }

  @override
  Future<Iterable<VideoStabilizationMode>> getSupportedVideoStabilizationModes(
    int cameraId,
  ) async {
    final List<PlatformVideoStabilizationMode?> modes = await _hostApi
        .getSupportedVideoStabilizationModes();
    return modes
        .where((mode) => mode != null)
        .cast<PlatformVideoStabilizationMode>()
        .map(videoStabilizationModeFromPlatform);
  }

  @override
  Future<void> setVideoStabilizationMode(
    int cameraId,
    VideoStabilizationMode mode,
  ) async {
    try {
      await _hostApi.setVideoStabilizationMode(
        videoStabilizationModeToPlatform(mode),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> resumePreview(int cameraId) async {
    await _hostApi.resumePreview();
  }

  @override
  Future<void> setImageFileFormat(int cameraId, ImageFileFormat format) async {
    try {
      await _hostApi.setImageFileFormat(imageFileFormatToPlatform(format));
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> setJpegImageQuality(int cameraId, int quality) async {
    try {
      await _hostApi.setJpegImageQuality(quality);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  // OHOS 平台限制：Camera Kit 无"录制中切换相机"API，原生侧恒返回
  // setDescriptionWhileRecordingUnsupported 错误，此处透传为 CameraException。
  Future<void> setDescriptionWhileRecording(
      CameraDescription description) async {
    try {
      await _hostApi.setDescriptionWhileRecording(description.name);
    } on PlatformException catch (e) {
      throw CameraException(
        e.code,
        e.message,
      );
    }
  }

  @override
  Widget buildPreview(int cameraId) {
    return Texture(textureId: cameraId);
  }
}

/// Handles callbacks from the platform host that are not camera-specific.
@visibleForTesting
class HostDeviceMessageHandler implements CameraGlobalEventApi {
  /// Creates a new handler and registers it to listen to the global event platform channel.
  HostDeviceMessageHandler() {
    CameraGlobalEventApi.setUp(this);
  }

  /// The controller that broadcasts device events coming from the host platform.
  final StreamController<DeviceEvent> deviceEventStreamController =
      StreamController<DeviceEvent>.broadcast();
  @override
  void deviceOrientationChanged(PlatformDeviceOrientation orientation) {
    deviceEventStreamController.add(DeviceOrientationChangedEvent(
        deviceOrientationFromPlatform(orientation)));
  }
}

/// Handles camera-specific callbacks from the platform host.
@visibleForTesting
class HostCameraMessageHandler implements CameraEventApi {
  /// Creates a new handler and registers it to listen to its camera's platform channel.
  HostCameraMessageHandler(this.cameraId, this.cameraEventStreamController,
      this.cameraSwitchedStreamController) {
    CameraEventApi.setUp(this, messageChannelSuffix: '$cameraId');
  }

  /// Removes this handler from its platform channel.
  void dispose() {
    CameraEventApi.setUp(null, messageChannelSuffix: '$cameraId');
  }

  /// The ID of the camera for which this handler listens for events.
  final int cameraId;

  /// The controller which broadcasts camera events from the host platform.
  final StreamController<CameraEvent> cameraEventStreamController;

  /// The controller which broadcasts camera-switched events from the host platform.
  final StreamController<String> cameraSwitchedStreamController;
  @override
  void error(String message) {
    cameraEventStreamController.add(CameraErrorEvent(cameraId, message));
  }

  /// Called when a camera is switched (e.g., on tri-fold devices).
  @override
  void cameraSwitched(String newCameraName) {
    cameraSwitchedStreamController.add(newCameraName);
  }

  @override
  void initialized(PlatformCameraState initialState) {
    cameraEventStreamController.add(CameraInitializedEvent(
        cameraId,
        initialState.previewSize?.width ?? 0,
        initialState.previewSize?.height ?? 0,
        exposureModeFromPlatform(initialState.exposureMode),
        initialState.exposurePointSupported,
        focusModeFromPlatform(initialState.focusMode),
        initialState.focusPointSupported));
  }

  @override
  void closed() {
    cameraEventStreamController.add(CameraClosingEvent(cameraId));
  }
}
