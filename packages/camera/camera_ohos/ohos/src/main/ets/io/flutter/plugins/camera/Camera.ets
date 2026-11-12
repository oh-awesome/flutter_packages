// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import { media } from '@kit.MediaKit';
import fs from '@ohos.file.fs';
import Ability from '@ohos.app.ability.Ability';
import UIAbility from '@ohos.app.ability.UIAbility';
import camera from '@ohos.multimedia.camera';
import image from '@ohos.multimedia.image';
import { Decimal, JSON } from '@kit.ArkTS';
import { BinaryMessenger, EventChannel, Log } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { SurfaceTextureEntry, TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { CameraFeatureFactory } from './features/CameraFeatureFactory';
import { DartMessenger } from './DartMessenger';
import { CameraProperties } from './CameraProperties';
import { ResolutionPreset } from './types/ResolutionPreset';
import { CameraCaptureCallback, CameraCaptureStateListener } from './CameraCaptureCallback';
import { CameraFeatures } from './features/CameraFeatures';
import { CaptureTimeoutsWrapper } from './types/CaptureTimeoutsWrapper';
import { CameraCaptureProperties } from './types/CameraCaptureProperties';
import { ResolutionFeature, VideoSessionProfile } from './features/resolution/ResolutionFeature';
import { CameraUtils } from './CameraUtils';
import { ImageStreamReader } from './media/ImageStreamReader';
import { BusinessError } from '@kit.BasicServicesKit';
import { CameraState } from './CameraState';
import { AutoFocusFeature } from './features/autofocus/AutoFocusFeature';
import { DeviceOrientationManager } from './features/sensororientation/DeviceOrientationManager';
import { Point } from './features/Point';
import { FlashFeature } from './features/flash/FlashFeature';
import { ExposureLockFeature } from './features/exposurelock/ExposureLockFeature';
import { ExposurePointFeature } from './features/exposurepoint/ExposurePointFeature';
import { ExposureOffsetFeature } from './features/exposureoffset/ExposureOffsetFeature';
import { FocusPointFeature } from './features/focuspoint/FocusPointFeature';
import { ZoomLevelFeature } from './features/zoomlevel/ZoomLevelFeature';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import display from '@ohos.display';
import { AudioPermission, CameraPermissions } from './CameraPermissions';
import { ZslCapability, ZslVersionGate } from './ZslCapability';
import {
  CameraEventApi,
  PlatformCameraState,
  PlatformExposureMode,
  PlatformFocusMode,
  PlatformImageFileFormat,
  PlatformSize,
  PlatformVideoStabilizationMode
} from './Messages';
import { sensor } from '@kit.SensorServiceKit';

const TAG = 'Camera';

// Only used to create the image stream's ImageReceiver; unrelated to the format reported to Dart.
// Image format mapping: the OHOS ImageReceiver practically only supports JPEG.
// PlatformImageFormatGroup enum strings from Pigeon (jpeg/yuv420/nv21/bgra8888) are resolved uniformly;
// non-jpeg requests log a warning and fall back to JPEG, avoiding silent dead mappings from mismatched hash keys.
function getSupportedImageFormat(imageFormatGroup: string | null): image.ImageFormat {
  if (imageFormatGroup === 'jpeg') {
    return image.ImageFormat.JPEG;
  }
  Log.w(TAG, 'The selected imageFormatGroup ' + imageFormatGroup + ' is not supported by ohos. ' +
    'ImageReceiver creation format defaults to JPEG; the image stream reports the actual output format ' +
    'CAMERA_FORMAT_YUV_420_SP');
  return image.ImageFormat.JPEG;
}

export class Camera implements CameraCaptureStateListener {
  private static TAG: string = 'Camera';
  cameraFeatures: CameraFeatures;
  private imageFormatGroup: string | null = null;
  private flutterTexture: SurfaceTextureEntry;
  private resolutionPreset: ResolutionPreset;
  private enableAudio: boolean;
  private applicationContext: Context;
  private textureRegistry: TextureRegistry | null = null;
  dartMessenger: DartMessenger;
  private cameraProperties: CameraProperties;
  private cameraFeatureFactory: CameraFeatureFactory;
  private ability: Ability;
  private cameraCaptureCallback: CameraCaptureCallback;
  private cameraDevice: camera.CameraDevice | null = null;
  private cameraInput: camera.CameraInput | null = null;
  imageStreamReader: ImageStreamReader | null = null;
  private previewOutput: camera.PreviewOutput | null = null; // First preview output stream
  private previewOutput2: camera.PreviewOutput | null = null; // Second preview output stream
  private pausedPreview: boolean = false; // Preview paused
  private captureTimeouts: CaptureTimeoutsWrapper;
  private captureProps: CameraCaptureProperties;
  private cameraManager: camera.CameraManager;
  private avRecorder: media.AVRecorder | null = null;
  private videoOutput: camera.VideoOutput | null = null;
  private recordingVideo: boolean = false;
  private captureFile: fs.File | null = null;
  private cameraOutputCapability: camera.CameraOutputCapability | null = null;
  private initialCameraFacing: number = 0;
  private photoSession: camera.PhotoSession | null = null; // Photo mode
  private videoSession: camera.VideoSession | null = null; // Video mode
  private cameras: Array<camera.CameraDevice> | null = null;
  private photoOutput: camera.PhotoOutput | null = null;
  private fd: number = -1;
  private isVideoMode: boolean = false; // Video mode
  private aVRecorderProfile: media.AVRecorderProfile = {
    audioChannels: 2,
    audioCodec: media.CodecMimeType.AUDIO_AAC,
    audioBitrate: 48000,
    audioSampleRate: 48000,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4, // Video container format; only MP4 is supported
    videoBitrate: 100000000, // Video bitrate
    videoCodec: media.CodecMimeType.VIDEO_AVC, // Video codec; mpeg4 and avc are supported
    videoFrameWidth: 1920, // Video resolution width
    videoFrameHeight: 1080, // Video resolution height
    videoFrameRate: 30 // Video frame rate
  };
  private phAccessHelper: photoAccessHelper.PhotoAccessHelper;
  private videoPath: string | null = null;
  private videoId: string | undefined = undefined;
  private takePictureResult: MethodResult | undefined;
  private takePictureName: string = '';
  private permissions: CameraPermissions;
  private photoRotation: camera.ImageRotation | undefined;
  private nowZoom: number = 1;
  private imageFileFormat: PlatformImageFileFormat = PlatformImageFileFormat.jpeg;
  // JPEG compression quality (1-100); null means camera default output (raw buffer written directly,
  // no re-encoding). OHOS PhotoCaptureSetting.quality only offers a 3-level enum and cannot express
  // 1-100 precision, so captures are re-encoded with ImagePacker at this quality when writing to disk.
  private jpegQuality: number | null = null;
  // Zero-shutter-lag (SPEED photo priority) request state; re-applied on session rebuilds
  // and replayed onto recreated Camera instances by CameraApiImpl.
  private zeroShutterLagRequested: boolean = false;
  // ZSL API version gate + cached capability probe; short-circuits all ZSL calls on
  // pre-API 21 runtimes so the PhotoQualityPrioritization symbols are never touched.
  private zslCapability: ZslCapability = new ZslCapability();
  // Start time of the in-flight capture, used to measure the full capture-to-file latency.
  private captureStartTime: number = 0;
  private displayChangeCallback: ((_displayId: number) => void) | null = null;
  private photoAssetAvailableCallback:
    ((err: BusinessError, photoAsset: photoAccessHelper.PhotoAsset) => void) | null = null;
  private lastDisplayRotation: number = -1;
  private foldStatusChangeCallback: ((foldStatus: display.FoldStatus) => void) | null = null;
  private autoDeviceSwitchCallback: ((err: BusinessError, status: camera.AutoDeviceSwitchStatus) => void) | null = null;
  private autoDeviceSwitchSession: camera.PhotoSession | camera.VideoSession | null = null;
  public onAutoSwitchToRearCamera: (() => void) | null = null;
  private lastDeviceDegree: number = 0;
  private isClosed: boolean = false;
  private targetVideoBitrate: number | null = null;
  private targetAudioBitrate: number | null = null;
  private heifEncodingSupported: boolean | null = null;

  constructor(
    ability: UIAbility,
    flutterTexture: SurfaceTextureEntry,
    cameraFeatureFactory: CameraFeatureFactory,
    dartMessenger: DartMessenger,
    cameraProperties: CameraProperties,
    resolutionPreset: ResolutionPreset,
    enableAudio: boolean,
    permissions: CameraPermissions,
    textureRegistry?: TextureRegistry,
    fps: number = 30,
    videoBitrate: number = 100000000,
    audioBitrate: number = 48000,
    zslGate?: ZslVersionGate,
  ) {
    if (ability == null) {
      throw new Error('No Ability available!');
    }
    // ZSL gate injection: the default production gate reads sdkApiVersion once; tests
    // inject a fake gate to simulate pre-API 21 runtimes without a real low-API device.
    if (zslGate) {
      this.zslCapability = new ZslCapability(zslGate);
    }

    this.ability = ability;
    this.enableAudio = enableAudio;
    this.permissions = permissions;
    this.flutterTexture = flutterTexture;
    this.dartMessenger = dartMessenger;
    this.applicationContext = ability.context;
    this.cameraProperties = cameraProperties;
    this.cameraFeatureFactory = cameraFeatureFactory;
    this.resolutionPreset = resolutionPreset;
    this.textureRegistry = textureRegistry || null;
    this.cameraFeatures =
      CameraFeatures.init(
        cameraFeatureFactory, cameraProperties, ability, dartMessenger, resolutionPreset);
    this.cameraFeatures.getFpsRange().setValue(fps);
    this.targetVideoBitrate = videoBitrate;
    this.targetAudioBitrate = audioBitrate;

    this.cameraManager = CameraUtils.getCameraManager(this.applicationContext);
    // Create capture callback.
    this.captureTimeouts = new CaptureTimeoutsWrapper(3000, 3000);
    this.captureProps = new CameraCaptureProperties();
    this.cameraCaptureCallback = CameraCaptureCallback.create(this, this.captureTimeouts, this.captureProps);

    this.phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
  }


  public onConverged(): void {
  }

  public onPrecapture(): void {
  }

  // Get the session instance for the current scene (photo mode, video mode).
  getCurSession(): camera.PhotoSession | camera.VideoSession {
    return this.isVideoMode ? this.videoSession! : this.photoSession!;
  }

  public async open(imageFormatGroup: string | null): Promise<void> {
    // Re-opening after close/dispose (isClosed=true) is forbidden: rebuilding resources in a released
    // state leaves registered display/fold listeners and native sessions behind, creating a "zombie
    // camera" (e.g. the trailing rebuild in stopVideoRecording finally).
    if (this.isClosed) {
      Log.w(TAG, 'open() called after close/dispose, ignoring to avoid resource leak');
      return;
    }
    // Reset isClosed so a camera rebuilt after close() is still fully released by a later close()
    this.isClosed = false;
    this.imageFormatGroup = imageFormatGroup;
    const resolutionFeature: ResolutionFeature = this.cameraFeatures.getResolution();

    if (!resolutionFeature.checkIsSupported()) {
      this.sendCameraErrorEvent(
        'Camera with name "' +
          this.cameraProperties.getCameraName() +
          '" is not supported by this plugin.');
      return;
    }

    // Release possibly stale resources before rebuilding to avoid overwrite leaks
    await this.releasePreviewOutput();
    await this.releasePhotoOutput();
    await this.releaseSession();   // Release the stale session to avoid overwrite leaks on rebuild
    if (this.imageStreamReader != null) {
      try {
        this.imageStreamReader.close();
      } catch (e) {
        Log.d(TAG, 'open: failed to close imageStreamReader: ' + e.message);
      }
      this.imageStreamReader = null;
    }

    let imageFormat: number = getSupportedImageFormat(imageFormatGroup);

    // The ImageReceiver creation format only decides how the receiver is set up;
    // it does NOT describe the frames actually delivered by the preview stream.
    // The reported format defaults to CAMERA_FORMAT_YUV_420_SP here (NV21 on current
    // devices) and is later updated to the format of the selected preview profile in
    // startImageStream()/startCapture(), so the value reported to Dart still reflects
    // the real buffer layout and the Dart-side mapping (type_conversion.dart) can
    // recognize it.
    const reportedImageFormat: number = camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP;
    this.imageStreamReader = new ImageStreamReader(
      resolutionFeature.getPreviewSize(),
      imageFormat,
      1,
      reportedImageFormat
    )

    // Enhanced error handling for camera device acquisition
    this.cameraDevice = CameraUtils.getCameraDevice(this.cameraProperties.getCameraName(), this.cameraManager);
    if (!this.cameraDevice) {
      this.imageStreamReader?.close();
      this.imageStreamReader = null;
      this.sendCameraErrorEvent('Failed to get camera device: ' + this.cameraProperties.getCameraName());
      return;
    }

    // Fixed the issue where the camera could not be turned on
    // when switching cameras after the 3.35 adaptation
    if (this.cameraInput) {
      await this.cameraInput.close();
    }

    if (this.isTriFoldDevice() && display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED) {
      if (this.cameraDevice.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        Log.w(TAG, 'Cannot open front camera in tri-fold dual-screen state');
        // Release the ImageStreamReader created above so the failure path does not leak the native receiver.
        this.imageStreamReader?.close();
        this.imageStreamReader = null;
        this.sendCameraErrorEvent('FRONT_CAMERA_UNAVAILABLE');
        return;
      }
    }

    try{
      // createCameraInput is inside the try so open failures use the unified error mapping and cleanup.
      this.cameraInput = this.cameraManager.createCameraInput(this.cameraDevice);
      await this.cameraInput.open();
      await this.startPreview();
      if (!this.recordingVideo) {
        this.sendCameraInitializedEvent(resolutionFeature);
      }
      this.registerFoldStatusChangeListener();
      // close() stopped orientation listening; restart after rebuild (start is idempotent and safe to repeat)
      this.getDeviceOrientationManager()?.start();
    }catch (err) {
      // Release what this open attempt built WITHOUT flipping isClosed: the instance
      // must stay re-openable because CameraApiImpl.initialize retries a contention
      // failed open once. close() would set isClosed=true and turn that retry into a
      // silent no-op zombie success; the full close semantics (in-flight capture reply,
      // captureFile, recording teardown) have no in-flight counterpart during open.
      await this.releaseSession();
      await this.releasePhotoOutput();
      await this.releasePreviewOutput();
      await this.releaseCameraInput();
      // The image stream reader (native ImageReceiver) and the fold listener are
      // also owned by this open attempt; release them here or a switch-time open
      // failure leaks the receiver and the listener closure keeps the failed
      // Camera alive until the next camera op triggers close().
      if (this.imageStreamReader != null) {
        try {
          this.imageStreamReader.close();
        } catch (streamError) {
          Log.d(TAG, 'open: failed to close imageStreamReader: ' + (streamError as Error).message);
        }
        this.imageStreamReader = null;
      }
      this.unregisterFoldStatusChangeListener();
      let errorDescription: string;
      switch (err.code) {
      case camera.CameraErrorCode.INVALID_ARGUMENT:
      errorDescription = 'Can not use camera cause of conflict.';
      break;
      case camera.CameraErrorCode.DEVICE_DISABLED:
      errorDescription = 'Camera disabled cause of security reason.';
      break;
      case camera.CameraErrorCode.SERVICE_FATAL_ERROR:
      errorDescription = 'Camera service fatal error.';
      break;
      default:
      errorDescription = 'Unknown camera error';
      }
      // Errors propagate only via exceptions: event-emitting paths do not throw, throwing paths do not emit;
      // each caller picks its own reporting channel.
      // initialize reports via the Pigeon error reply;
      // the tri-fold auto rear-switch emits in its own catch.
      // Double reporting would double-complete Dart's initializeCamera completer and throw StateError.
      // The mapped, readable message is thrown; the original error is kept in logs.
      Log.e(TAG, 'open failed: ' + errorDescription + ' (' + err.message + ')');
      throw new Error(errorDescription);
    }
  }

  getDeviceOrientationManager(): DeviceOrientationManager {
    return this.cameraFeatures?.getSensorOrientation().getDeviceOrientationManager();
  }

  // Unified error event sender
  private sendCameraErrorEvent(errorMessage: string): void {
    try {
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger, this.dartMessenger.getCameraIdSuffix());
      cameraEventApi.error(errorMessage, { reply: () => {} });
    } catch (e) {
      Log.e(TAG, 'Failed to send camera error event: ' + e.message);
    }
  }

  // Unified closing event sender
  private sendCameraClosingEvent(): void {
    try {
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger, this.dartMessenger.getCameraIdSuffix());
      cameraEventApi.closed({ reply: () => {} });
    } catch (e) {
      Log.e(TAG, 'Failed to send camera closing event: ' + e.message);
    }
  }

  private sendCameraInitializedEvent(resolutionFeature: ResolutionFeature): void {
    try {
      // Get the BinaryMessenger instance
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger, this.dartMessenger.getCameraIdSuffix());

      // Fetch required values from camera features
      const previewSize = new PlatformSize(
        resolutionFeature.getPreviewSize().width,
        resolutionFeature.getPreviewSize().height
      );

      const exposureMode = this.convertExposureMode(
        this.cameraFeatures.getExposureLock().getValue()
      );

      const focusMode = this.convertFocusMode(
        this.cameraFeatures.getAutoFocus().getValue()
      );

      const exposurePointSupported = this.cameraFeatures.getExposurePoint().checkIsSupported();
      const focusPointSupported = this.cameraFeatures.getFocusPoint().checkIsSupported();

      const initialState = new PlatformCameraState(
        previewSize,
        exposureMode,
        focusMode,
        exposurePointSupported,
        focusPointSupported
      );

      cameraEventApi.initialized(initialState, { reply: () => {} });
    } catch (e) {
      Log.e(TAG, 'Failed to send camera initialized event: ' + e.message);
    }
  }

  // Conversion helper
  private convertExposureMode(exposureMode: camera.ExposureMode): PlatformExposureMode {
    switch (exposureMode) {
      case camera.ExposureMode.EXPOSURE_MODE_LOCKED:
        return PlatformExposureMode.locked;
      case camera.ExposureMode.EXPOSURE_MODE_AUTO:
      default:
        return PlatformExposureMode.auto;
    }
  }

  private convertFocusMode(focusMode: camera.FocusMode): PlatformFocusMode {
    switch (focusMode) {
      case camera.FocusMode.FOCUS_MODE_LOCKED:
        return PlatformFocusMode.locked;
      case camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO:
      default:
        return PlatformFocusMode.auto;
    }
  }

  setFocusPoint(result: MethodResult, point: Point) {
    const focusPointFeature: FocusPointFeature = this.cameraFeatures.getFocusPoint();
    focusPointFeature.setValue(point);

    // Reference:
    // https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-camera-focus#setfocuspoint11
    // The application's preview interface layout is based on the vertical direction when the device's charging port is
    // at the bottom. The layout's width and height are {w, h}, and the touch point is {x, y}. Therefore, the converted
    // coordinates are {y/h, 1-x/w}.
    // Here, the coordinates passed to Dart are based on the vertical direction. x and y have already been calculated,
    // and the range is [0,1].
    const focusPoint: camera.Point | null
      = (point.x == null || point.y == null) ? null : { x: point.y, y: 1-point.x };
    try {
      this.getCurSession().setFocusPoint(focusPoint);
      result.success(null);
    } catch (error) {
      result.error('setFocusPointFailed', 'Could not set focus point.', null);
    }
  }

  setFocusMode(result: MethodResult, newMode: camera.FocusMode) {
    if (!this.getCurSession().isFocusModeSupported(newMode)) {
      result.error('setFocusModeFailed', 'The focus mode is unsupported.', null);
      return;
    }
    const autoFocusFeature: AutoFocusFeature = this.cameraFeatures.getAutoFocus();
    autoFocusFeature.setValue(newMode);

    try {
      const before = this.getCurSession().getFocusMode();
      this.getCurSession().setFocusMode(newMode)
      const after = this.getCurSession().getFocusMode();
      Log.i('Camera', `[setFocusMode] requested=${newMode} before=${before} after=${after}`);
      result?.success(null)
    } catch (error) {
      result?.error('setFocusModeFailed', `${JSON.stringify(error)}`, null)
    }
  }

  // Sets the exposure compensation.
  // offset is the actual EV value (rounded to a step on the Dart side); setExposureBias applies it and
  // must return the applied EV value.
  // (ExposureOffsetFeature.getValue() returns that value directly).
  setExposureOffset(result: MethodResult, offset: number) {
    const exposureOffsetFeature: ExposureOffsetFeature = this.cameraFeatures.getExposureOffset();
    const session = this.getCurSession();
    // Clamp to the device range [min, max] to avoid out-of-range system calls; return the applied value.
    const minOffset: number = exposureOffsetFeature.getMinExposureOffset(session);
    const maxOffset: number = exposureOffsetFeature.getMaxExposureOffset(session);
    const clampedOffset: number = Math.min(Math.max(offset, minOffset), maxOffset);
    exposureOffsetFeature.setValue(clampedOffset, session);

    try {
      session.setExposureBias(clampedOffset);
      result.success(exposureOffsetFeature.getValue());
    } catch (error) {
      result.error('setExposureOffsetFailed', 'Could not set exposure offset.', null);
    }
  }

  public getMaxZoomLevel(): number {
    if (this.photoSession == null && this.videoSession == null) {
      return 0;   // Session not established: unknown marker (aligned with CameraPropertiesImpl docs)
    }
    return this.cameraFeatures.getZoomLevel().getMaximumZoomLevel(this.getCurSession());
  }

  public getMinZoomLevel(): number {
    if (this.photoSession == null && this.videoSession == null) {
      return 0;   // Session not established: unknown marker (aligned with CameraPropertiesImpl docs)
    }
    return this.cameraFeatures.getZoomLevel().getMinimumZoomLevel(this.getCurSession());
  }

  public setZoomLevel(result: MethodResult, zoom: number): void {
    const zoomLevel: ZoomLevelFeature = this.cameraFeatures.getZoomLevel();
    let maxZoom: number = zoomLevel.getMaximumZoomLevel(this.getCurSession());
    let minZoom: number = zoomLevel.getMinimumZoomLevel(this.getCurSession());

    if (zoom > maxZoom || zoom < minZoom) {
      result.error('ZOOM_ERROR',
        'Zoom level out of bounds (zoom level should be between ' + minZoom + ' and ' + maxZoom + ').', null);
      return;
    }

    try {
      this.getCurSession().setZoomRatio(zoom);
    } catch (error) {
      Log.e(TAG, 'setZoomLevel failed: zoom=' + zoom + ', error=' + error.message);
      result.error('setZoomLevelFailed', 'Could not set zoom level.', null);
      return;
    }
    this.nowZoom = zoom;
    zoomLevel.setValue(zoom);
    result.success(null);
  }

  public lockCaptureOrientation(orientation: DeviceOrientation): void {
    this.cameraFeatures.getSensorOrientation().lockCaptureOrientation(orientation);
  }

  public unlockCaptureOrientation(): void {
    this.cameraFeatures.getSensorOrientation().unlockCaptureOrientation();
  }

  // Pause the preview
  public async pausePreview(result: MethodResult) {
    try {
      await this.previewOutput?.stop();
      await this.previewOutput2?.stop();
    } catch (e) {
      Log.e(TAG, 'pausePreview: failed to stop preview output: ' + e.message);
      result.error('pausePreviewFailed', 'Could not pause preview.', null);
      return;
    }
    this.pausedPreview = true;
    result.success(null);
  }

  // Resume the preview
  public async resumePreview(result: MethodResult) {
    try {
      if (this.pausedPreview) {
        await this.previewOutput?.start();
        await this.previewOutput2?.start();
      }
    } catch (e) {
      Log.e(TAG, 'resumePreview: failed to start preview output: ' + e.message);
      result.error('resumePreviewFailed', 'Could not resume preview.', null);
      return;
    }
    this.pausedPreview = false;
    result.success(null);
  }

  // Set the exposure point
  setExposurePoint(result: MethodResult, point: Point) {
    const exposurePointFeature: ExposurePointFeature = this.cameraFeatures.getExposurePoint();
    exposurePointFeature.setValue(point);

    const exposurePoint: camera.Point | null
      = (point.x == null || point.y == null) ? null : { x: point.y, y: 1-point.x };

    try {
      this.getCurSession().setMeteringPoint(exposurePoint);
      result.success(null);
    } catch (error) {
      result.error('setExposurePointFailed', 'Could not set exposure point.', null);
    }
  }

  // Sets the exposure mode.
  // Check support before setting; use isExposureModeSupported.
  // isExposureModeSupported。
  setExposureMode(result: MethodResult, newMode: camera.ExposureMode) {
    if (!CameraUtils.isExposureModeSupported(this.getCurSession(), newMode)) {
      result.error('setExposureModeFailed', 'The exposure mode is unsupported.', null);
      return;
    }

    let modeExistence: boolean = false;
    Object.values(camera.ExposureMode).forEach((value) => {
      if (newMode == value) {
        modeExistence = true
      }
    })

    if (!modeExistence) {
      result.error('setExposureModeFailed', 'The exposure mode is unsupported.', null);
      return;
    }

    const exposureLockFeature: ExposureLockFeature = this.cameraFeatures.getExposureLock();
    exposureLockFeature.setValue(newMode);

    try {
      this.getCurSession().setExposureMode(newMode);
      result.success(null)
    } catch (error) {
      result.error('setExposureModeError', JSON.stringify(error), null)
    }
  }

  // Sets the flash mode.
  // Check support before setting:
  // hasFlash for flash availability.
  // isFlashModeSupported for the specific flash mode.
  setFlashMode(result: MethodResult, newMode: camera.FlashMode) {
    if (!CameraUtils.hasFlash(this.getCurSession())) {
      result.error('setFlashModeFailed', 'The camera device does not have flash.', null);
      return;
    }

    if (!CameraUtils.isFlashModeSupported(this.getCurSession(), newMode)) {
      result.error('setFlashModeFailed', ' The flash mode is unsupported.', null);
      return;
    }

    // Save the new flash mode setting.
    const flashFeature: FlashFeature = this.cameraFeatures.getFlash();
    flashFeature.setValue(newMode);

    try {
      this.getCurSession().setFlashMode(newMode);
      result.success(null);
    } catch (error) {
      result.error('setFlashModeFailed', 'The setFlashMode call failed', null);
    }
  }

  getMinExposureOffset() {
    return this.cameraFeatures.getExposureOffset().getMinExposureOffset(this.getCurSession());
  }

  getMaxExposureOffset() {
    return this.cameraFeatures.getExposureOffset().getMaxExposureOffset(this.getCurSession());
  }

  getExposureOffsetStepSize() {
    return this.cameraFeatures.getExposureOffset().getExposureOffsetStepSize(this.getCurSession());
  }

  private async applyFlashMode(session: camera.PhotoSession | camera.VideoSession): Promise<void> {
    const hasFlash: boolean = session.hasFlash();
    if (!hasFlash) {
      Log.w(TAG, 'Device does not support flash, skipping flash mode application');
      return;
    }

    try {
      const flashMode: camera.FlashMode = this.cameraFeatures.getFlash().getValue();
      if (session.isFlashModeSupported(flashMode)) {
        await session.setFlashMode(flashMode);
      } else {
        Log.w(TAG, 'Flash mode ' + flashMode +
          ' is not supported by the current session, skipping flash mode application');
      }
    } catch (error) {
      Log.e(TAG, 'applyFlashMode error: ' + error.message);
    }
  }

  async takePicture(result: MethodResult) {
    if (this.cameraCaptureCallback.getCameraState() != CameraState.STATE_PREVIEW) {
      result.error('captureAlreadyActive', 'Picture is currently already being captured', null);
      return;
    }
    this.takePictureResult = result;
    this.takePictureName = '/IMG_' + Date.now().toString() + this.getCurrentImageFileExtension();
    try {
      await this.runPictureAutoFocus();
    } catch (error) {
      // Exception while initiating capture (e.g. session state): fail fast to avoid a hanging Dart Future
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      this.takePictureResult?.error('captureFailed', error.message, null);
      this.takePictureResult = undefined;
      return;
    }
  }

  /** Start capturing a picture, doing autofocus first. */
  private async runPictureAutoFocus(): Promise<void> {
    this.cameraCaptureCallback.setCameraState(CameraState.STATE_WAITING_FOCUS);
    await this.lockAutoFocus();
  }

  async lockAutoFocus(): Promise<void> {
    if (this.photoSession == null) {
      const errMsg = '[unlockAutoFocus] captureSession null, returning';
      Log.e(TAG, errMsg);
      // reset status and callback error
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      this.takePictureResult?.error('captureSession null', errMsg, -1);
      this.takePictureResult = undefined;   // Drop the reference so the MethodResult closure does not linger
      return;
    }

    let captureLocation: camera.Location = {
      latitude: 0,
      longitude: 0,
      altitude: 0,
    };
    const sensorOrientationFeature = this.cameraFeatures.getSensorOrientation();
    const lockedOrientation = sensorOrientationFeature.getLockedCaptureOrientation();
    if (lockedOrientation !== null) {
      const deviceOrientationManager = sensorOrientationFeature.getDeviceOrientationManager();
      const rotationDegree = deviceOrientationManager.getPhotoOrientation(lockedOrientation) as number;
      this.photoRotation = this.photoOutput?.getPhotoRotation(rotationDegree);
    } else {
      const deviceDegree: number = await this.getDeviceDegree();
      this.photoRotation = this.photoOutput?.getPhotoRotation(deviceDegree);
    }

    const enableMirror = this.isFrontCamera() && (this.photoOutput?.isMirrorSupported() ?? false);

    let settings: camera.PhotoCaptureSetting = {
      quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
      rotation: this.photoRotation,
      location: captureLocation,
      mirror: enableMirror,
    };

    this.cameraCaptureCallback.setCameraState(CameraState.STATE_CAPTURING);

    // Trigger the capture
    this.captureStartTime = Date.now();
    this.photoOutput?.capture(settings, (err: BusinessError) => {
      // Capture finished, update CameraState
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      if (err) {
        Log.e(TAG, 'Failed to capture the photo: ' + err.code);
        this.takePictureResult?.error(err.code.toString(), err.message, err.data);
        this.takePictureResult = undefined;
        this.sendCameraErrorEvent(err.message);
        return;
      }
      // Capture succeeded
      Log.i(TAG, 'capture latency (control): ' + (Date.now() - this.captureStartTime) +
        'ms (zslRequested=' + this.zeroShutterLagRequested + ')');
    });
  }

  private isFrontCamera(): boolean {
    return this.cameraDevice?.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT;
  }

  private async enableVideoMirrorIfNeeded(): Promise<void> {
    const isFront = this.isFrontCamera();
    const mirrorSupported = this.videoOutput?.isMirrorSupported() ?? false;
    Log.d(TAG, `enableVideoMirrorIfNeeded: isFrontCamera=${isFront}, isMirrorSupported=${mirrorSupported}`);
    if (!isFront || !mirrorSupported) {
      return;
    }
    this.videoOutput!.enableMirror(true);
    if (this.avRecorder != null && this.avRecorder.state === 'prepared') {
      try {
        const deviceDegree = await this.getDeviceDegree();
        const videoRotation = this.videoOutput!.getVideoRotation(deviceDegree);
        await this.avRecorder.updateRotation(videoRotation);
      } catch (e) {
        Log.d(TAG, 'enableVideoMirrorIfNeeded updateRotation error: ' + e.toString());
      }
    }
  }

  private getRealSensorData(data: sensor.GravityResponse): number {
    let x = data.x;
    let y = data.y;
    let z = data.z;
    if ((x * x + y * y) * 3 < z * z) {
      return this.lastDeviceDegree;
    } else {
      try {
        let sd: Decimal = Decimal.atan2(y, -x);
        let sc: Decimal = Decimal.round(Number(sd) / 3.141592653589 * 180);
        this.lastDeviceDegree = 90 - Number(sc);
        this.lastDeviceDegree = this.lastDeviceDegree >= 0
          ? this.lastDeviceDegree % 360
          : this.lastDeviceDegree % 360 + 360;
      } catch (error) {
        let err = error as BusinessError;
        Log.e(TAG, 'Decimal failed, error: ' + err.code);
      }
    }
    return this.lastDeviceDegree;
  }

  async getDeviceDegree(): Promise<number> {
    let sensorList: sensor.Sensor[];
    try {
      sensorList = await sensor.getSensorList();
    } catch (error) {
      let err = error as BusinessError;
      Log.e(TAG, 'getSensorList failed, error: ' + err.code);
      return -1;
    }

    let isGravitySupported: boolean = false;
    for (let i = 0; i < sensorList.length; i++) {
      if (sensorList[i].sensorId === sensor.SensorId.GRAVITY) {
        isGravitySupported = true;
        break;
      }
    }

    const SENSOR_TIMEOUT_MS = 3000;
    const sensorName = isGravitySupported ? 'GRAVITY' : 'ACCELEROMETER';
    let gravityCallback: ((data: sensor.GravityResponse) => void) | null = null;
    let accelCallback: ((data: sensor.AccelerometerResponse) => void) | null = null;
    const sensorPromise = new Promise<number>((resolve) => {
      if (isGravitySupported) {
        gravityCallback = (data: sensor.GravityResponse): void => {
          resolve(this.getRealSensorData(data));
        };
        sensor.once(sensor.SensorId.GRAVITY, gravityCallback);
      } else {
        accelCallback = (data: sensor.AccelerometerResponse): void => {
          resolve(this.getRealSensorData(data));
        };
        sensor.once(sensor.SensorId.ACCELEROMETER, accelCallback);
      }
    });

    let timerId: number = -1;
    const timeoutPromise = new Promise<number>((resolve) => {
      timerId = setTimeout(() => {
        Log.w(TAG, `Sensor(${sensorName}) timed out, using lastDeviceDegree: ${this.lastDeviceDegree}`);
        resolve(this.lastDeviceDegree);
      }, SENSOR_TIMEOUT_MS);
    });

    const result = await Promise.race([sensorPromise, timeoutPromise]);
    clearTimeout(timerId);
    // Cancel the pending once-listener so its closure does not hold this Camera until the next sensor event.
    if (isGravitySupported && gravityCallback != null) {
      try {
        sensor.off(sensor.SensorId.GRAVITY, gravityCallback);
      } catch (e) {
        Log.d(TAG, 'Failed to unregister GRAVITY sensor listener: ' + e.message);
      }
    } else if (accelCallback != null) {
      try {
        sensor.off(sensor.SensorId.ACCELEROMETER, accelCallback);
      } catch (e) {
        Log.d(TAG, 'Failed to unregister ACCELEROMETER sensor listener: ' + e.message);
      }
    }
    return result;
  }

  private async updateVideoRotation(): Promise<void> {
    if (!this.videoOutput || !this.avRecorder) {
      return;
    }
    try {
      const deviceDegree = await this.getDeviceDegree();
      const videoRotation = this.videoOutput.getVideoRotation(deviceDegree);
      Log.d(TAG, 'video rotation is: ' + videoRotation);
      if (this.avRecorder.state === 'prepared') {
        await this.avRecorder.updateRotation(videoRotation);
      }
    } catch (e) {
      Log.e(TAG, 'updateVideoRotation error: ' + e.toString());
    }
  }

  async startVideoRecording(result: MethodResult, imageStreamChannel: EventChannel | null,
    videoOutputPath: string | null) {
    this.prepareRecording(result);

    if (imageStreamChannel != null) {
      this.setStreamHandler(imageStreamChannel);
    }

    this.initialCameraFacing = this.cameraProperties.getLensFacing();
    this.recordingVideo = true;

    try {
      // Start recording
      await this.startCapture(true, imageStreamChannel != null, videoOutputPath);
      result.success(null);
    } catch (e) {
      this.recordingVideo = false;
      if (this.captureFile) {
        try {
          fs.close(this.captureFile);
        } catch (closeErr) {
          Log.d(TAG, 'startVideoRecording: failed to close captureFile: ' + (closeErr as Error).message);
        }
        this.captureFile = null;
      }
      result.error('videoRecordingFailed', e.message, null);
    }
  }

  async stopVideoRecording(result: MethodResult) {
    if (!this.recordingVideo || !this.avRecorder) {
      result.success(null);
      return;
    }

    this.cameraFeatures.setAutoFocus(this.cameraFeatureFactory.createAutoFocusFeature(this.cameraProperties, false));
    this.recordingVideo = false;
      const isPrepared = this.avRecorder.state === 'started' || this.avRecorder.state === 'paused' ||
        this.avRecorder.state === 'prepared';
    try {
      if (isPrepared) {
        await this.avRecorder.stop();
      }
      await this.avRecorder.release();
      // Stop the recording output stream
      this.videoOutput?.stop();
      if (isPrepared) {
        this.videoPath = this.captureFile?.path ?? null;
      } else {
        this.videoPath = null;
      }
    } catch (e) {
      this.videoPath = null;
      Log.d(TAG, 'videoSession stop error' + e.toString());
    } finally {
      try {
        // Release the recording output
        if (this.videoOutput != null) {
          try { await this.videoOutput.stop(); } catch (e) { Log.d(TAG, 'Failed to stop videoOutput: ' + e.message); }
          try {
            await this.videoOutput.release();
          } catch (e) {
            Log.d(TAG, 'Failed to release videoOutput: ' + e.message);
          }
          this.videoOutput = null;
        }
        // Release the video session
        if (this.videoSession != null) {
          try { await this.videoSession.stop(); } catch (e) { Log.d(TAG, 'Failed to stop videoSession: ' + e.message); }
          try {
            await this.videoSession.release();
          } catch (e) {
            Log.d(TAG, 'Failed to release videoSession: ' + e.message);
          }
          this.videoSession = null;
        }
        // Release the old preview output
        if (this.previewOutput != null) {
          try {
            await this.previewOutput.release();
          } catch (e) {
            Log.d(TAG, 'Failed to release previewOutput: ' + e.message);
          }
          this.previewOutput = null;
        }
        // Release stream helpers (previewOutput2/photoOutput/imageStreamReader) to avoid leaks.
        await this.releasePreviewOutput();
        await this.releasePhotoOutput();
        if (this.imageStreamReader != null) {
          try {
            this.imageStreamReader.close();
          } catch (e) {
            Log.d(TAG, 'stopVideoRecording: failed to close imageStreamReader: ' + e.message);
          }
          this.imageStreamReader = null;
        }
        if (this.captureFile) {
          fs.close(this.captureFile);
        }
        this.captureFile = null;
        this.isVideoMode = false;
        await this.open(this.imageFormatGroup);
      } catch (e) {
        Log.e(TAG, 'stopVideoRecording: reopen camera failed: ' + e.toString());
        this.sendCameraErrorEvent('Camera reopen failed after recording: ' + e.message);
      }
    }
    result.success(this.videoPath);
  }

  async startPreview() {
    if (this.recordingVideo) {
      await this.startPreviewWithVideo();
    } else {
      await this.startPreviewWithPhoto();
    }
  }

  // Start video preview
  async startPreviewWithVideo() {
    try {
      this.cameraOutputCapability =
        CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
          this.cameraManager);
      // Select the profile with the fps parameter, consistent with startCapture logic
      const preferredFps = this.cameraFeatures.getFpsRange().getValue();
      let videoSessionProfile: VideoSessionProfile = this.cameraFeatures
                                                         .getResolution()
                                                         .getVideoSessionProfile(
                                                           this.cameraOutputCapability.previewProfiles,
                                                           this.cameraOutputCapability.videoProfiles,
                                                           preferredFps
                                                         );

      let previewSize: camera.Size = videoSessionProfile.getPreviewProfile()!.size;
      this.cameraFeatures.getResolution().setPreviewSize(previewSize);
      this.previewOutput = this.cameraManager.createPreviewOutput(
        videoSessionProfile.getPreviewProfile(),
        this.flutterTexture.getSurfaceId().toString());
      this.videoOutput = this.cameraManager.createVideoOutput(
        videoSessionProfile.getCaptureProfile(),
        this.videoId);
      this.videoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_VIDEO) as camera.VideoSession;
      this.videoSession?.beginConfig();
      this.videoSession?.addInput(this.cameraInput);
      this.videoSession?.addOutput(this.previewOutput);
      this.videoSession?.addOutput(this.videoOutput);
      await this.videoSession?.commitConfig();

      this.updatePreviewRotation();
      this.registerDisplayChangeListener();
      await this.enableVideoMirrorIfNeeded();
      await this.updateVideoRotation();
      await this.videoSession?.start();
      if (preferredFps) {
        this.setFrameRate(this.videoOutput, preferredFps)
      }
      this.enableAutoDeviceSwitch(this.videoSession!);
      this.sendCameraInitializedEvent(this.cameraFeatures.getResolution());

      await this.applyFlashMode(this.videoSession!);

      if (this.pausedPreview) {
        await this.previewOutput.stop();
      }
      if (this.recordingVideo && this.avRecorder != undefined && this.avRecorder.state === 'paused') {
        // Recording and in paused state
      } else {
        await this.videoOutput.start();
      }
    } catch (e) {
      await this.releaseCamera()
      Log.e(TAG, 'Failed to start video preview: ' + e)
      throw e as Error;   // Do not swallow: open()/startVideoRecording must see the preview failure
    }
  }

  // Start photo preview
  async startPreviewWithPhoto() {
    try {
      if (!this.cameraDevice) {
        throw new Error('Camera device not initialized');
      }

      if (!this.cameraInput) {
        throw new Error('Camera input not initialized');
      }

      if (!this.flutterTexture) {
        throw new Error('Flutter texture not initialized');
      }

      this.cameraOutputCapability =
        CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_PHOTO, this.cameraManager);

      if (!this.cameraOutputCapability ||
          this.cameraOutputCapability.previewProfiles.length === 0 ||
          this.cameraOutputCapability.photoProfiles.length === 0) {
        throw new Error('Failed to get camera output capability');
      }
      // Find the matching preview profile
      let previewProfileIndex = this.cameraFeatures
                                    .getResolution()
                                    .getPreviewProfileIndex(this.cameraOutputCapability.previewProfiles);
      // Find the matching photo profile
      let photoProfileIndex = this.cameraFeatures
                                  .getResolution()
                                  .getPhotoProfileIndex(this.cameraOutputCapability.photoProfiles);
      // Validate the Surface ID
      const surfaceId = this.flutterTexture.getSurfaceId();
      if (surfaceId <= 0) {
        throw new Error('Invalid Flutter texture Surface ID: ' + surfaceId);
      }
      const surfaceIdString = surfaceId.toString();
      let previewSize: camera.Size = this.cameraOutputCapability.previewProfiles[previewProfileIndex].size;
      this.cameraFeatures.getResolution().setPreviewSize(previewSize);
      this.previewOutput = this.cameraManager.createPreviewOutput(
        this.cameraOutputCapability.previewProfiles[previewProfileIndex],
        surfaceIdString);
      this.photoOutput = this.cameraManager.createPhotoOutput(
        this.cameraOutputCapability.photoProfiles[photoProfileIndex]);

      // Register the photo callback (keep the reference for precise unregistration in releasePhotoOutput)
      this.registerPhotoAssetAvailableListener();

      this.photoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.photoSession.beginConfig();
      this.photoSession.addInput(this.cameraInput);
      this.photoSession.addOutput(this.previewOutput);
      this.photoSession.addOutput(this.photoOutput);
      await this.photoSession.commitConfig();

      this.updatePreviewRotation();
      this.registerDisplayChangeListener();
      this.getCurSession().setZoomRatio(this.nowZoom);
      await this.photoSession.start();
      this.enableAutoDeviceSwitch(this.photoSession);
      await this.applyFlashMode(this.photoSession);
      this.applyZeroShutterLag();
      if (this.pausedPreview) {
        await this.previewOutput.stop();
      }
    } catch (error) {
      // Clean up resources
      this.unregisterDisplayChangeListener();
      try {
        // Release session/outputs uniformly so stop-without-release does not leak native resources
        await this.releaseSession();
        await this.releasePreviewOutput();
        await this.releasePhotoOutput();
      } catch (cleanupError) {
        Log.e(TAG, 'startPreviewWithPhoto cleanup failed: ' + cleanupError.message);
      }
      throw error as Error;   // Do not swallow: open() must see the preview failure instead of a false success
    }
  }

  mediaLibRequestBuffer(photoAsset: photoAccessHelper.PhotoAsset) {
    let requestOptions: photoAccessHelper.RequestOptions = {
      deliveryMode: photoAccessHelper.DeliveryMode.BALANCE_MODE,
    }
    let that = this;
    photoAccessHelper.MediaAssetManager.requestImageData(this.applicationContext, photoAsset,
      requestOptions, {
        onDataPrepared(data: ArrayBuffer) {
          that.convertBufferToFile(data).catch((error: Error) => {
            Log.e(TAG, 'convertBufferToFile failed: ' + error.message)
          });
        }
      });
  }

  async convertBufferToFile(data: ArrayBuffer) {
    const photoUri: string = getContext(this).cacheDir + this.takePictureName;
    let file: fs.File | null = null;
    try {
      file = fs.openSync(photoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      if (this.imageFileFormat === PlatformImageFileFormat.heif) {
        await this.packImageBufferToFile(data, file.fd);
      } else if (this.jpegQuality !== null) {
        // User explicitly set JPEG quality: re-encode with ImagePacker (OHOS photo quality is only a 3-level
        // enum without continuous precision, so re-encode when writing to disk).
        await this.packJpegBufferToFile(data, file.fd, this.jpegQuality);
      } else {
        await fs.write(file.fd, data);
      }
      if (this.takePictureResult) {
        this.takePictureResult.success(photoUri);
        this.takePictureResult = undefined;
        Log.i(TAG, 'capture to file: ' + (Date.now() - this.captureStartTime) +
          'ms (zslRequested=' + this.zeroShutterLagRequested + ')');
      }
    } catch (error) {
      this.takePictureResult?.error(
        'imageFileFormatEncodingFailed',
        error instanceof Error ? error.message : 'Failed to write captured image.',
        null);
      this.takePictureResult = undefined;
      try {
        fs.unlinkSync(photoUri);
      } catch (cleanupError) {
        Log.e(TAG, 'convertBufferToFile: failed to delete temp file: ' + cleanupError.message);
      }
    } finally {
      // openSync failure leaves file null; null-check before closeSync to avoid a second throw on undefined
      if (file) {
        try {
          fs.closeSync(file);
        } catch (e) {
          Log.d(TAG, 'convertBufferToFile: failed to close file: ' + e.message);
        }
      }
    }
  }

  public setJpegImageQuality(result: MethodResult, quality: number): void {
    if (quality < 1 || quality > 100) {
      result.error(
        'invalidJpegQuality',
        'JPEG quality must be between 1 and 100.',
        null);
      return;
    }
    if (this.imageFileFormat === PlatformImageFileFormat.jpeg) {
      this.jpegQuality = quality;
    }
    result.success(null);
  }

  public setImageFileFormat(result: MethodResult, format: PlatformImageFileFormat): void {
    if (format === PlatformImageFileFormat.heif && !this.isHeifEncodingSupported()) {
      result.error(
        'unsupportedImageFileFormat',
        'HEIF encoding is not supported on this OHOS device/runtime.',
        null);
      return;
    }
    if (this.imageFileFormat !== format) {
      // Cross-format switches invalidate the stored JPEG quality: quality belongs to one jpeg session only,
      // resetting to null on switch-back so stale quality cannot quietly revive.
      this.jpegQuality = null;
    }
    this.imageFileFormat = format;
    result.success(null);
  }

  public isZeroShutterLagSupported(): boolean {
    const photoOutput = this.photoOutput;
    // The version gate inside isCapable short-circuits on pre-API 21 runtimes without
    // touching photoOutput; on API21+ the probe result is cached per Camera instance.
    const capable: boolean = photoOutput != null && this.zslCapability.isCapable(photoOutput);
    Log.i(TAG, 'ZeroShutterLag: supported=' + capable);
    return capable;
  }

  // Re-applies the stored request to the live photoOutput. No-ops when the request is
  // off (devices never touched keep their stock default priority), when no photoOutput
  // exists (video mode), or when the version/capability gate is false. Errors are
  // logged only; the try/catch stays as defense-in-depth for gate misjudgement.
  private applyZeroShutterLag(): void {
    const photoOutput = this.photoOutput;
    if (!this.zeroShutterLagRequested || photoOutput == null) {
      return;
    }
    if (!this.zslCapability.isCapable(photoOutput)) {
      return;
    }
    try {
      photoOutput.setPhotoQualityPrioritization(camera.PhotoQualityPrioritization.SPEED);
      Log.i(TAG, 'ZeroShutterLag: replayed SPEED after session rebuild');
    } catch (e) {
      Log.e(TAG, 'applyZeroShutterLag: ' + e.message);
    }
  }

  // Stores the request and applies it to the live photoOutput when present. Disabling
  // restores HIGH_QUALITY once while the output is live; session rebuilds with the flag
  // off are no-ops so devices never touched keep their stock default priority. On
  // pre-API 21 runtimes (or when the capability gate is false) the setting is skipped
  // but the request is still recorded and success is reported unconditionally, keeping
  // the best-effort contract intact.
  public setZeroShutterLagEnabled(result: MethodResult, enabled: boolean): void {
    this.zeroShutterLagRequested = enabled;
    const photoOutput = this.photoOutput;
    if (photoOutput != null) {
      if (!this.zslCapability.isCapable(photoOutput)) {
        Log.i(TAG, 'ZeroShutterLag: photo quality prioritization skipped: capability gate false');
      } else {
        try {
          photoOutput.setPhotoQualityPrioritization(
            enabled ? camera.PhotoQualityPrioritization.SPEED : camera.PhotoQualityPrioritization.HIGH_QUALITY);
          Log.i(TAG, 'ZeroShutterLag: photo quality prioritization set to ' + (enabled ? 'SPEED' : 'HIGH_QUALITY'));
        } catch (e) {
          Log.e(TAG, 'setZeroShutterLagEnabled: ' + e.message);
        }
      }
    } else {
      Log.i(TAG, 'ZeroShutterLag: photo quality prioritization skipped: no photoOutput (video mode)');
    }
    result.success(null);
  }

  private getCurrentImageFileExtension(): string {
    switch (this.imageFileFormat) {
      case PlatformImageFileFormat.heif:
        return '.heif';
      case PlatformImageFileFormat.jpeg:
      default:
        return '.jpg';
    }
  }

  private isHeifEncodingSupported(): boolean {
    if (this.heifEncodingSupported !== null) {
      return this.heifEncodingSupported;
    }
    let imagePackerObj: image.ImagePacker | null = null;
    try {
      imagePackerObj = image.createImagePacker();
      const supportedFormats = imagePackerObj.supportedFormats;
      Log.d(TAG, 'isHeifEncodingSupported supportedFormats : ' + JSON.stringify(supportedFormats));
      // On OHOS, heif and heic formats are identical, but heic is unsupported before API 14
      this.heifEncodingSupported = supportedFormats.includes('image/heif') || supportedFormats.includes('image/heic');
    } catch (error) {
      Log.w(TAG, 'Failed to query HEIF encoding support: ' + error);
      this.heifEncodingSupported = false;
      return false;
    } finally {
      imagePackerObj?.release();
    }
    return this.heifEncodingSupported;
  }

  // Re-encodes the captured buffer to JPEG with the given quality (1-100) and writes it to a file.
  // Implements continuous precision for setJpegImageQuality (OHOS PhotoCaptureSetting.quality is a 3-level enum).
  private async packJpegBufferToFile(data: ArrayBuffer, fd: number, quality: number): Promise<void> {
    let imageSource: image.ImageSource | null = null;
    let imagePackerObj: image.ImagePacker | null = null;
    try {
      imageSource = image.createImageSource(data);
      imagePackerObj = image.createImagePacker();
      await imagePackerObj.packToFile(imageSource, fd, {
        format: 'image/jpeg',
        quality: quality,
        needsPackProperties: true,
      });
    } finally {
      if (imagePackerObj != null) {
        await imagePackerObj.release();
      }
      if (imageSource != null) {
        await imageSource.release();
      }
    }
  }

  private async packImageBufferToFile(data: ArrayBuffer, fd: number): Promise<void> {
    let imageSource: image.ImageSource | null = null;
    let imagePackerObj: image.ImagePacker | null = null;
    try {
      imageSource = image.createImageSource(data);
      imagePackerObj = image.createImagePacker();
      await imagePackerObj.packToFile(imageSource, fd, {
        format: 'image/heif',
        quality: 100,
        needsPackProperties: true,
      });
    } finally {
      if (imagePackerObj != null) {
        await imagePackerObj.release();
      }
      if (imageSource != null) {
        await imageSource.release();
      }
    }
  }

  async pauseVideoRecording(result: MethodResult) {
    if (!this.recordingVideo) {
      result.success(null);
      return;
    }

    try {
      // Pause is a valid transition only from the started state
      if (this.avRecorder != undefined && this.avRecorder.state === 'started') {
        await this.avRecorder.pause();
        await this.videoOutput?.stop(); // Stop the camera output stream
      }

    } catch (e) {
      const err = e as BusinessError;
      Log.d(TAG, 'pauseVideoRecording error')
      result.error('videoRecordingFailed', err.message, null);
      return;
    }
    result.success(null);
  }

  async resumeVideoRecording(result: MethodResult) {
    if (!this.recordingVideo) {
      result.success(null);
      return;
    }
    try {
      // Resume is a valid transition only from the paused state
      if (this.avRecorder != undefined && this.avRecorder.state === 'paused') {
        await this.videoOutput?.start(); // Start the camera output stream
        await this.avRecorder?.resume();
      } else {
        result.error(
          'videoRecordingFailed', 'avRecorder state is not paused', null);
        return;
      }
    } catch (e) {
      const err = e as BusinessError;
      result.error('videoRecordingFailed', err.message, null);
      return;
    }

    result.success(null);
  }

  startPreviewWithImageStream(imageStreamChannel: EventChannel) {
    this.setStreamHandler(imageStreamChannel);
    // Consume the async chain and catch failures so async cleanup errors in startImageStream do not
    // become unhandled Promise rejections.
    this.startImageStream().catch((e: Error) => {
      Log.e(TAG, 'startImageStream failed: ' + e.message);
      this.sendCameraErrorEvent('startImageStream failed: ' + e.message);
    });
  }

  async startImageStream() {
    // Release stale session/outputs to avoid native PhotoOutput/PhotoSession overwrite leaks
    await this.releaseSession();
    await this.releasePhotoOutput();
    await this.releasePreviewOutput();

    // Step tracker for failure localization: the next occurrence of the switch-race
    // 401/7400101 failures can be pinned to the exact native call via this marker.
    let step = 'getSupportedOutputCapability';
    try {
      let profiles =
        CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_PHOTO, this.cameraManager)
      let previewProfileIndex = this.cameraFeatures
                                    .getResolution()
                                    .getPreviewProfileIndex(profiles.previewProfiles);
      const actualFormat: number = profiles.previewProfiles[previewProfileIndex].format;
      if (actualFormat !== camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP) {
        Log.w(TAG, 'Selected preview profile format is ' + actualFormat +
          ', not CAMERA_FORMAT_YUV_420_SP. The image stream reports the actual format.');
      }
      this.imageStreamReader!.setReportedImageFormat(actualFormat);
      step = 'createPreviewOutput';
      this.previewOutput = this.cameraManager.createPreviewOutput(
        profiles.previewProfiles[previewProfileIndex],
        this.flutterTexture.getSurfaceId().toString());
      step = 'createPhotoOutput';
      let photoProfileIndex = this.cameraFeatures
                                  .getResolution()
                                  .getPhotoProfileIndex(profiles.photoProfiles);
      this.photoOutput = this.cameraManager.createPhotoOutput(
        profiles.photoProfiles[photoProfileIndex]);
      step = 'getReceivingSurfaceId';
      let imageReceiverSurfaceId: string = await this.imageStreamReader!.getReceivingSurfaceId();
      step = 'createPreviewOutput(imageReceiver)';
      this.previewOutput2 =
        this.cameraManager.createPreviewOutput(profiles.previewProfiles[previewProfileIndex], imageReceiverSurfaceId);

      this.registerPhotoAssetAvailableListener();

      step = 'createSession';
      this.photoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.photoSession.beginConfig();
      step = 'cameraInput.open';
      await this.cameraInput?.open();
      this.photoSession.addInput(this.cameraInput);
      this.photoSession.addOutput(this.previewOutput);
      this.photoSession.addOutput(this.previewOutput2);
      this.photoSession.addOutput(this.photoOutput);
      step = 'commitConfig';
      await this.photoSession.commitConfig();
      this.updatePreviewRotation();
      this.registerDisplayChangeListener();
      step = 'session.start';
      await this.photoSession.start();
      this.enableAutoDeviceSwitch(this.photoSession);
      this.applyZeroShutterLag();
    } catch (e) {
      Log.e(TAG, 'startImageStream failed at step [' + step + ']: ' + e.message);
      await this.releaseSession();
      await this.releasePhotoOutput();
      await this.releasePreviewOutput();
      // Black-screen fallback: when this path runs during camera switching, the old
      // instance is already gone and a failed stream start would leave the texture
      // dead. Restart a plain photo preview so the user keeps a live picture (stream
      // frames resume once Dart retries); the primary error still propagates to Dart
      // via the caller's catch.
      await this.startPreviewWithPhoto().catch((fallbackError: Error) => {
        Log.e(TAG, 'startImageStream: fallback preview also failed: ' + fallbackError.message);
      });
      throw e as Error;  // Rethrow so the caller catch propagates the failure to Dart.
    }
  }

  async prepareMediaRecorder(cameraManager: camera.CameraManager,
    cameraOutputCapability: camera.CameraOutputCapability, url: string) {
    Log.i(TAG, 'prepareMediaRecorder');
    if (this.avRecorder != null) {
      this.avRecorder.release();
    }
  }

  async startCapture(record: boolean, stream: boolean, videoOutputPath: string | null = null) {
    if (!this.pausedPreview) {
      await this.getCurSession().stop();
    }
    // Release stale photoSession/photoOutput/previewOutput to avoid native overwrite leaks
    await this.releaseSession();
    await this.releasePhotoOutput();
    await this.releasePreviewOutput();
    this.isVideoMode = true;
    try {
      let recorder = await media.createAVRecorder();
      if (recorder != null) {
        this.avRecorder = recorder;
        let videoUri: string = videoOutputPath ?? (getContext(this).cacheDir + '/REC' + Date.now().toString() + '.mp4');
        this.captureFile = fs.openSync(videoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        let fd = this.captureFile.fd;

        this.cameraOutputCapability =
          CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
            this.cameraManager);
        // In video mode, select the session profile based on the target fps as well.
        const preferredFps = this.cameraFeatures.getFpsRange().getValue();
        let videoSessionProfile: VideoSessionProfile = this.cameraFeatures
                                                           .getResolution()
                                                           .getVideoSessionProfile(
                                                             this.cameraOutputCapability.previewProfiles,
                                                             this.cameraOutputCapability.videoProfiles,
                                                             preferredFps);

        this.aVRecorderProfile.videoFrameWidth = videoSessionProfile.getCaptureProfile()?.size.width;
        this.aVRecorderProfile.videoFrameHeight = videoSessionProfile.getCaptureProfile()?.size.height;
        // Update the AVRecorder target frame rate using the filtered profile.
        this.updateRecorderFrameRate(videoSessionProfile.getCaptureProfile());
        if (this.targetVideoBitrate != null && this.targetVideoBitrate > 0) {
            this.aVRecorderProfile.videoBitrate = this.targetVideoBitrate;
        }
        if (this.enableAudio && this.targetAudioBitrate != null && this.targetAudioBitrate > 0) {
            this.aVRecorderProfile.audioBitrate = this.targetAudioBitrate;
        }
        const avRecorderConfig = await this.getAVRecorderConfig(fd, this.getCurrentPreviewRotation());
        await this.avRecorder.prepare(avRecorderConfig).then(async () => {
          this.videoId = await this.avRecorder?.getInputSurface();
        });

        const actualFormat: number = videoSessionProfile.getPreviewProfile()!.format;
        if (actualFormat !== camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP) {
          Log.w(TAG, 'Selected preview profile format is ' + actualFormat +
            ', not CAMERA_FORMAT_YUV_420_SP. The image stream reports the actual format.');
        }
        this.imageStreamReader!.setReportedImageFormat(actualFormat);
        let previewSize: camera.Size = videoSessionProfile.getPreviewProfile()!.size;
        this.cameraFeatures.getResolution().setPreviewSize(previewSize);
        this.previewOutput = this.cameraManager.createPreviewOutput(
          videoSessionProfile.getPreviewProfile(),
          this.flutterTexture.getSurfaceId().toString());
        this.videoOutput = this.cameraManager.createVideoOutput(
          videoSessionProfile.getCaptureProfile(),
          this.videoId);
        this.videoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_VIDEO) as camera.VideoSession;
        this.videoSession?.beginConfig();
        await this.cameraInput?.open();
        this.videoSession?.addInput(this.cameraInput);
        this.videoSession?.addOutput(this.previewOutput);
        if (stream && this.imageStreamReader != null) {
          let surfaceId: string = await this.imageStreamReader.getReceivingSurfaceId();
          this.previewOutput2 =
            this.cameraManager.createPreviewOutput(videoSessionProfile.getPreviewProfile(), surfaceId);
          this.videoSession.addOutput(this.previewOutput2);
        }
        this.videoSession?.addOutput(this.videoOutput);
        await this.videoSession?.commitConfig();
        if (this.videoSession) {
            this.cameraFeatures.getVideoStabilization().updateBuilder(this.videoSession);
        }
        this.updatePreviewRotation();
        this.registerDisplayChangeListener();
        this.getCurSession().setZoomRatio(this.nowZoom);
        await this.enableVideoMirrorIfNeeded();
        await this.updateVideoRotation();
        await this.videoSession?.start();
        this.enableAutoDeviceSwitch(this.videoSession!);
        this.sendCameraInitializedEvent(this.cameraFeatures.getResolution());

        if (preferredFps) {
          this.setFrameRate(this.videoOutput, preferredFps)
        }

        await this.applyFlashMode(this.videoSession!);

        await this.videoOutput.start();
        try {
          if (this.pausedPreview) {
            await this.previewOutput.stop();
          }
          if (record) {
            await this.avRecorder.start();
          }
        } catch (e) {
            const err = e as BusinessError;
            Log.e(TAG, 'startAVRecorder error: ' + err.message);
            throw err as Error;
        }
      } else {
        Log.e(TAG, 'startVideo createAVRecorder fail : recorder is null');
        // Rethrow to the outer catch for unified cleanup; startVideoRecording reports videoRecordingFailed
        throw new Error('createAVRecorder returned null');
      }
    } catch (error) {
      Log.e(TAG, 'startVideo createAVRecorder fail :' + error.message);
      // Clean up created resources
      if (this.avRecorder) {
        try {
          await this.avRecorder.release();
        } catch (e) {
          Log.d(TAG, 'startCapture: failed to release avRecorder: ' + e.message);
        }
        this.avRecorder = null;
      }
      if (this.captureFile) {
        try {
          fs.close(this.captureFile);
        } catch (e) {
          Log.d(TAG, 'startCapture: failed to close captureFile: ' + e.message);
        }
        this.captureFile = null;
      }
      await this.releaseVideoOutput();
      await this.releasePhotoOutput();
      await this.releasePreviewOutput();
      await this.releaseSession();
      throw error as Error;  // Rethrow for the caller to handle
    }
  }

  async getAVRecorderConfig(fd: number, rotation: camera.ImageRotation): Promise<media.AVRecorderConfig> {
    let aVRecorderConfig: media.AVRecorderConfig | undefined = undefined;
    if (this.enableAudio) {
      const hasAudioPermission = await this.permissions.checkPermissions(AudioPermission);
      if (hasAudioPermission) {
        aVRecorderConfig = {
          audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
          videoSourceType: media.VideoSourceType.VIDEO_SOURCE_TYPE_SURFACE_YUV,
          profile: this.aVRecorderProfile,
          url: `fd://${fd}`,
          rotation: rotation,
        };
      }
    }
    if (aVRecorderConfig == undefined) {
      aVRecorderConfig = {
        videoSourceType: media.VideoSourceType.VIDEO_SOURCE_TYPE_SURFACE_YUV,
        profile: this.aVRecorderProfile,
        url: `fd://${fd}`,
        rotation: rotation,
      };
    }
    return aVRecorderConfig;
  }

  private updateRecorderFrameRate(profile: camera.VideoProfile | undefined): void {
    if (profile == null) {
      return;
    }

    const fpsFeature = this.cameraFeatures.getFpsRange();
    const preferredFps = fpsFeature.getPreferredFpsForProfile(profile);

    // The target fps is clamped to the profile supported range, avoiding illegal frame rate settings.
    if (preferredFps != null && preferredFps > 0) {
      this.aVRecorderProfile.videoFrameRate = preferredFps;
    }
  }

  // Set the video stabilization mode
  public setVideoStabilizationMode(result: MethodResult, mode: PlatformVideoStabilizationMode) {
    Log.i(TAG, 'setVideoStabilizationMode called with mode: ' + mode);
    // Store the user-selected stabilization mode
    this.cameraFeatures.getVideoStabilization().setValue(mode);

    // Logged to note that the actual application happens when recording starts
    Log.i(TAG, 'Video stabilization mode ' + mode + ' saved, will be applied during video recording start');

    result.success(null);
  }

  // Get the stabilization modes supported by the current camera
  public getSupportedVideoStabilizationModes(): PlatformVideoStabilizationMode[] {
    Log.i(TAG, 'getSupportedVideoStabilizationModes called');
    // Query the underlying support via the feature manager
    const modes = this.cameraFeatures.getVideoStabilization().getSupportedModes();
    Log.i(TAG, 'getSupportedVideoStabilizationModes returning from feature: ' + modes);
    return modes;
  }

  async prepareRecording(result: MethodResult): Promise<void> {
    this.cameraFeatures.setAutoFocus(this.cameraFeatureFactory.createAutoFocusFeature(this.cameraProperties, true));
  }

  private setStreamHandler(imageStreamChannel: EventChannel): void {
    let that = this;
    let streamHandler: StreamHandler = {
      onListen(args: ESObject, imageStreamSink: EventSink): void {
        that.setImageStreamImageAvailableListener(imageStreamSink);
      },
      onCancel(args: ESObject): void {
        if (that.imageStreamReader == null) {
          return
        }
        that.imageStreamReader.removeListener()
      }
    }
    imageStreamChannel.setStreamHandler(streamHandler)
  }

  private setImageStreamImageAvailableListener(imageStreamSink: EventSink) {
    if (this.imageStreamReader == null) {
      return;
    }
    this.imageStreamReader.subscribeListener(this.captureProps, imageStreamSink);
  }

  private getCurrentPreviewRotation(): camera.ImageRotation {
    try {
      const displayRotation = display.getDefaultDisplaySync().rotation * camera.ImageRotation.ROTATION_90;
      return this.previewOutput!.getPreviewRotation(displayRotation);
    } catch (e) {
      Log.w(TAG, 'Failed to get current preview rotation: ' + e.message);
      return camera.ImageRotation.ROTATION_0;
    }
  }

  private setTextureBufferSize(width: number, height: number): void {
    if (this.textureRegistry != null) {
      const textureId = this.flutterTexture.getTextureId();
      try {
        this.textureRegistry.setTextureBufferSize(textureId, width, height);
        Log.d(TAG, `setTextureBufferSize: textureId=${textureId}, size=${width}x${height}`);
      } catch (e) {
        Log.e(TAG, 'Failed to set texture buffer size: ' + e.message);
      }
    } else {
      Log.w(TAG, 'Cannot set texture buffer size: textureRegistry is null');
    }
  }

  private updatePreviewRotation(): void {
    if (this.previewOutput == null) {
      Log.w(TAG, 'updatePreviewRotation: previewOutput is null');
      return;
    }
    try {
      let previewRotation = this.getCurrentPreviewRotation();
      const previewSize = this.cameraFeatures.getResolution().getPreviewSize();
      const needSwap = (previewRotation === camera.ImageRotation.ROTATION_90 ||
                       previewRotation === camera.ImageRotation.ROTATION_270);
      const bufferWidth = needSwap ? previewSize.height : previewSize.width;
      const bufferHeight = needSwap ? previewSize.width : previewSize.height;
      this.setTextureBufferSize(bufferWidth, bufferHeight);
      this.previewOutput.setPreviewRotation(previewRotation, false);

      Log.d(TAG, `Preview rotation updated: previewRotation=${previewRotation},` +
        ` bufferSize=${bufferWidth}x${bufferHeight}, cameraProfileSize=${previewSize.width}x${previewSize.height}`);
    } catch (error) {
      Log.e(TAG, 'Failed to update preview rotation: ' + error.message);
    }
  }

  private registerDisplayChangeListener(): void {
    this.unregisterDisplayChangeListener();

    try {
      this.lastDisplayRotation = display.getDefaultDisplaySync().rotation;
      this.displayChangeCallback = (_displayId: number) => {
        const rotation = display.getDefaultDisplaySync().rotation;
        if (rotation !== this.lastDisplayRotation) {
          this.lastDisplayRotation = rotation;
          this.updatePreviewRotation();
        }
      };
      display.on('change', this.displayChangeCallback);
      Log.d(TAG, 'Display change listener registered');
    } catch (error) {
      Log.e(TAG, 'Failed to register display change listener: ' + error.message);
    }
  }

  private unregisterDisplayChangeListener(): void {
    if (this.displayChangeCallback != null) {
      try {
        display.off('change', this.displayChangeCallback);
        this.displayChangeCallback = null;
        Log.d(TAG, 'Display change listener unregistered');
      } catch (error) {
        Log.e(TAG, 'Failed to unregister display change listener: ' + error.message);
      }
    }
  }

  private isTriFoldDevice(): boolean {
    try {
      if (!display.isFoldable()) {
        return false;
      }
      const foldCreaseRegion = display.getCurrentFoldCreaseRegion();
      return foldCreaseRegion.creaseRects.length === 2;
    } catch (e) {
      Log.w(TAG, 'Failed to detect tri-fold device: ' + e.message);
      return false;
    }
  }

  private enableAutoDeviceSwitch(session: camera.PhotoSession | camera.VideoSession): void {
    this.unregisterAutoDeviceSwitchListener();
    // On tri-fold devices the plugin handles front-camera fold transitions itself via
    // foldStatusChangeCallback -> switchToRearCamera. Leaving the system autoDeviceSwitch
    // enabled here makes both mechanisms operate on the same session during a fast fold
    // (the system runs SwitchDevice while the plugin is releasing the session), which
    // surfaces as "Device conflict" when opening the rear camera. Disable it
    // for the front camera on tri-fold devices; the rear camera keeps using it.
    if (this.isTriFoldDevice() &&
      this.cameraDevice?.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      Log.d(TAG, "Auto device switch disabled for front camera on tri-fold device");
      return;
    }
    if (!session.isAutoDeviceSwitchSupported()) {
      Log.d(TAG, 'Auto device switch is not supported on this device');
      return;
    }
    try {
      session.enableAutoDeviceSwitch(true);
      Log.d(TAG, 'Auto device switch enabled');
    } catch (error) {
      let err = error as BusinessError;
      Log.e(TAG, `enableAutoDeviceSwitch failed, error code: ${err.code}, error message: ${err.message}`);
      return;
    }
    this.autoDeviceSwitchCallback = (err: BusinessError, status: camera.AutoDeviceSwitchStatus): void => {
      if (err !== undefined && err.code !== 0) {
        Log.e(TAG, `autoDeviceSwitchStatusChange callback error, errorCode: ${err.code}`);
        return;
      }
      Log.i(TAG, `autoDeviceSwitchStatusChange: isDeviceSwitched=${status.isDeviceSwitched}` +
        `, isDeviceCapabilityChanged=${status.isDeviceCapabilityChanged}`);
      if (status.isDeviceSwitched) {
        if (this.previewOutput == null) {
          Log.w(TAG, 'autoDeviceSwitchCallback: previewOutput is null, skipping preview rotation update');
        } else {
          this.updatePreviewRotation();
        }
        if (this.recordingVideo) {
          this.enableVideoMirrorIfNeeded().catch((e: Error): void =>
            Log.w(TAG, 'Failed to update video mirror after device switch: ' + e.message));
        }
        this.sendCameraInitializedEvent(this.cameraFeatures.getResolution());
        Log.d(TAG, 'Preview rotation and initialized event updated after auto device switch');
      }
      if (status.isDeviceCapabilityChanged) {
        try {
          const minZoom = this.cameraFeatures.getZoomLevel().getMinimumZoomLevel(session);
          session.setZoomRatio(minZoom);
          this.nowZoom = minZoom;
          Log.d(TAG, `Zoom reset to minimum ${minZoom} after device capability change`);
        } catch (e) {
          Log.w(TAG, 'Failed to reset zoom after device capability change: ' + e.message);
        }
      }
    };
    this.autoDeviceSwitchSession = session;
    session.on('autoDeviceSwitchStatusChange', this.autoDeviceSwitchCallback);
    Log.d(TAG, 'Auto device switch listener registered');
  }

  private unregisterAutoDeviceSwitchListener(): void {
    if (this.autoDeviceSwitchCallback != null && this.autoDeviceSwitchSession != null) {
      try {
        this.autoDeviceSwitchSession.off('autoDeviceSwitchStatusChange', this.autoDeviceSwitchCallback);
        Log.d(TAG, 'Auto device switch listener unregistered');
      } catch (error) {
        Log.e(TAG, 'Failed to unregister auto device switch listener: ' + error.message);
      }
    }
    this.autoDeviceSwitchCallback = null;
    this.autoDeviceSwitchSession = null;
  }

  private registerFoldStatusChangeListener(): void {
    if (!this.isTriFoldDevice()) {
      return;
    }
    this.unregisterFoldStatusChangeListener();
    this.foldStatusChangeCallback = async (foldStatus: display.FoldStatus) => {
      if (this.isClosed) {
        Log.w(TAG, 'foldStatusChangeCallback: Camera is already closed, ignoring');
        return;
      }
      if (foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED) {
        if (this.cameraDevice?.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          Log.w(TAG, 'Tri-fold device switched to dual-screen while using front camera, auto switching to rear');
          if (this.onAutoSwitchToRearCamera != null) {
            this.onAutoSwitchToRearCamera();
          } else {
            // Send error event before close() to ensure dartMessenger is still valid
            this.sendCameraErrorEvent('FRONT_CAMERA_UNAVAILABLE');
            try {
              await this.close();
            } catch (e) {
              Log.e(TAG, 'foldStatusChangeCallback: close failed: ' + (e as Error).message);
            }
          }
        }
      }
    };
    try {
      display.on('foldStatusChange', this.foldStatusChangeCallback);
      Log.d(TAG, 'Fold status change listener registered');
    } catch (error) {
      Log.e(TAG, 'Failed to register fold status change listener: ' + error.message);
    }
  }

  private unregisterFoldStatusChangeListener(): void {
    if (this.foldStatusChangeCallback != null) {
      try {
        display.off('foldStatusChange', this.foldStatusChangeCallback);
        this.foldStatusChangeCallback = null;
        Log.d(TAG, 'Fold status change listener unregistered');
      } catch (error) {
        Log.e(TAG, 'Failed to unregister fold status change listener: ' + error.message);
      }
    }
  }

  // Exposed for CameraApiImpl contention retry: guards against retrying open() on a
  // torn-down instance (open-after-close is a silent no-op by design).
  public isClosedState(): boolean {
    return this.isClosed;
  }

  // Close
  public async close(): Promise<void> {
    if (this.isClosed) {
      return;
    }
    this.isClosed = true;
    // Complete the Pigeon reply for an in-flight capture with error BEFORE clearing the reference, so the
    // Dart takePicture Future does not hang forever when dispose happens mid-capture.
    if (this.takePictureResult != null) {
      this.takePictureResult.error('cameraClosed', 'Camera was closed before picture could be taken.', null);
      this.takePictureResult = undefined;
    }
    this.unregisterDisplayChangeListener();
    this.unregisterFoldStatusChangeListener();
    this.unregisterAutoDeviceSwitchListener();
    // Stop the DeviceOrientationManager display change listener to leave no residue after close (idempotent)
    this.getDeviceOrientationManager()?.stop();

    await this.stopAndReleaseCamera();

    try {
      await this.avRecorder?.reset();
    } catch (resetError) {
      Log.d(TAG, 'avRecorder reset error: ' + resetError.toString());
    }
    try {
      await this.avRecorder?.release();
    } catch (releaseError) {
      Log.d(TAG, 'avRecorder release error: ' + releaseError.toString());
    }
    this.avRecorder = null;
    this.cameraDevice = null;
    this.sendCameraClosingEvent();
    // An abandoned recording leaves captureFile open; close it to avoid leaking the fd.
    if (this.captureFile) {
      try {
        fs.close(this.captureFile);
      } catch (e) {
        Log.d(TAG, 'close: failed to close captureFile: ' + e.message);
      }
      this.captureFile = null;
    }
  }

  // Stop and release the camera input stream
  private async stopAndReleaseCamera() {
    if (this.cameraInput != null) {
      try {
        this.photoSession?.removeInput(this.cameraInput);
      } catch (e) {
        Log.e(TAG, 'stopAndReleaseCamera: failed to remove input from photoSession: ' + e.message);
      }
      try {
        this.videoSession?.removeInput(this.cameraInput);
      } catch (e) {
        Log.e(TAG, 'stopAndReleaseCamera: failed to remove input from videoSession: ' + e.message);
      }
      try {
        this.cameraInput.close();
      } catch (e) {
        Log.e(TAG, 'Failed to close cameraInput: ' + e.toString());
      }
      this.cameraInput = null;
    }
    // (2) Release output resources
    // Stop an in-flight recording so the mp4 container is finalized before outputs are released.
    if (this.recordingVideo && this.avRecorder != null) {
      const isPrepared = this.avRecorder.state === 'started' || this.avRecorder.state === 'paused' ||
        this.avRecorder.state === 'prepared';
      if (isPrepared) {
        try {
          await this.avRecorder.stop();
        } catch (e) {
          Log.e(TAG, 'stopAndReleaseCamera: failed to stop avRecorder: ' + e.message);
        }
      }
      this.recordingVideo = false;
    }
    await this.releasePreviewOutput();
    await this.releaseVideoOutput();
    await this.releasePhotoOutput();
    // (3) Stop and release the session
    await this.releaseSession();
    if (this.imageStreamReader != null) {
      try {
        this.imageStreamReader.close();
        this.imageStreamReader = null;
      } catch (e) {
        Log.e(TAG, 'stopAndReleaseCamera: failed to close imageStreamReader: ' + e.message);
      }
    }

    if (this.cameraDevice != null) {
      this.cameraDevice = null;
    }
  }

  public setDescriptionWhileRecording(result: MethodResult, properties: CameraProperties) {
    // OHOS Camera Kit has no switch-camera-while-recording API (switchToRearCamera is a close-recreate flow,
    // not applicable while recording).
    // Return a stable English error code so Dart can recognize this platform limitation.
    result.error('setDescriptionWhileRecordingUnsupported', 'Camera switching is not supported while recording.', null);
    return;
  }

  async dispose() {
    Log.e(TAG, 'dispose');
    await this.close();
    // close() already stopped orientation listening (idempotent); finalize via the feature for cohesive release
    this.cameraFeatures.getSensorOrientation().dispose();
  }

  // Release the session
  private async releaseSession() {
    if (this.photoSession != null) {
      try {
        await this.photoSession.stop();
      } catch (e) {
        Log.e(TAG, 'releaseSession: failed to stop photoSession: ' + e.message);
      }
      try {
        await this.photoSession.release();
      } catch (e) {
        Log.e(TAG, 'releaseSession: failed to release photoSession: ' + e.message);
      }
      this.photoSession = null;
    }
    if (this.videoSession != null) {
      try {
        await this.videoSession.stop();
      } catch (e) {
        Log.e(TAG, 'releaseSession: failed to stop videoSession: ' + e.message);
      }
      try {
        await this.videoSession.release();
      } catch (e) {
        Log.e(TAG, 'releaseSession: failed to release videoSession: ' + e.message);
      }
      this.videoSession = null;
    }
  }

  private async releaseCameraInput() {
    if (this.cameraInput != null) {
      try {
        await this.cameraInput.close();
        this.cameraInput = null;
      } catch (e) {
        Log.e(TAG, 'releaseCameraInput: failed to close cameraInput: ' + e.message);
      }
    }
  }

  private async releasePreviewOutput() {
    if (this.previewOutput != null) {
      try {
        await this.previewOutput.release();
        this.previewOutput = null;
      } catch (e) {
        Log.e(TAG, 'releasePreviewOutput: failed to release previewOutput: ' + e.message);
      }
    }
    if (this.previewOutput2 != null) {
      try {
        await this.previewOutput2.release();
        this.previewOutput2 = null;
      } catch (e) {
        Log.e(TAG, 'releasePreviewOutput: failed to release previewOutput2: ' + e.message);
      }
    }
  }

  private registerPhotoAssetAvailableListener(): void {
    this.photoAssetAvailableCallback = (err: BusinessError, photoAsset: photoAccessHelper.PhotoAsset): void => {
      if (err) {
        this.takePictureResult?.error(err.code.toString(), err.message, err.data);
        this.takePictureResult = undefined;
        return;
      }
      this.mediaLibRequestBuffer(photoAsset);
    };
    this.photoOutput?.on('photoAssetAvailable', this.photoAssetAvailableCallback);
  }

  private async releasePhotoOutput() {
    if (this.photoOutput != null) {
      try {
        // Unregister with the stored callback reference so a bare off() does not remove other listeners.
        if (this.photoAssetAvailableCallback != null) {
          this.photoOutput.off('photoAssetAvailable', this.photoAssetAvailableCallback);
          this.photoAssetAvailableCallback = null;
        }
        await this.photoOutput.release();
        this.photoOutput = null;
      } catch (e) {
        Log.e(TAG, 'releasePhotoOutput: failed to release photoOutput: ' + e.message);
      }
    }
  }

  private async releaseVideoOutput() {
    if (this.videoOutput != null) {
      try {
        await this.videoOutput.stop();
        await this.videoOutput.release();
        this.videoOutput = null;
      } catch (e) {
        Log.e(TAG, 'releaseVideoOutput: failed to release videoOutput: ' + e.message);
      }
    }
  }

  // Release the camera
  async releaseCamera() {
    await this.releaseCameraInput();
    await this.releaseSession();
    await this.releasePreviewOutput();
    await this.releaseVideoOutput();
    await this.releasePhotoOutput();
  }

  setFrameRate(videoOutput: camera.VideoOutput, fps: number) {
    try {
      const frameRate = videoOutput.getActiveFrameRate();
      Log.d(TAG, `setFrameRate frameRate = ${JSON.stringify(frameRate)}`)
      let mFps = fps
      if (fps > frameRate.max) {
        mFps = frameRate.max
      } else if (fps < frameRate.min) {
        mFps = frameRate.min
      }
      Log.d(TAG, `setFrameRate mFps = ${mFps}`)
      videoOutput.setFrameRate(mFps, mFps)
    } catch (e) {
      Log.e(TAG, `setFrameRate error = ${JSON.stringify(e)}`)
    }
  }
}
