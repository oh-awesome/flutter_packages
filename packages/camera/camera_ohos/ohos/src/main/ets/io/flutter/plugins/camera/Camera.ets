// Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { buffer, HashMap, JSON, List } from '@kit.ArkTS';
import { EventChannel, Log } from '@ohos/flutter_ohos';
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
import { VideoRenderer } from './VideoRenderer';
import { ImageStreamReader } from './media/ImageStreamReader';
import { BusinessError } from '@kit.BasicServicesKit';
import { CameraState } from './CameraState';
import { AutoFocusFeature } from './features/autofocus/AutoFocusFeature';
import fileIO from '@ohos.fileio';
import { DeviceOrientationManager } from './features/sensororientation/DeviceOrientationManager';
import { Point } from './features/Point';
import { FlashFeature } from './features/flash/FlashFeature';
import { ExposureLockFeature } from './features/exposurelock/ExposureLockFeature';
import { ExposurePointFeature } from './features/exposurepoint/ExposurePointFeature';
import { ExposureOffsetFeature } from './features/exposureoffset/ExposureOffsetFeature';
import { FocusPointFeature } from './features/focuspoint/FocusPointFeature';
import { ZoomLevelFeature } from './features/zoomlevel/ZoomLevelFeature';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { FocusMode } from './features/autofocus/FocusMode';
import { ExposureMode } from './features/exposurelock/ExposureMode';
import PhotoAccessHelper from '@ohos.file.photoAccessHelper';
import systemDateTime from '@ohos.systemDateTime';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { picker } from '@kit.CoreFileKit';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import display from '@ohos.display';
import { AudioPermission, CameraPermissions } from './CameraPermissions';
import { BinaryMessenger } from '@ohos/flutter_ohos';
import { CameraEventApi, PlatformCameraState, PlatformSize, PlatformExposureMode, PlatformFocusMode, PlatformVideoStabilizationMode } from './Messages';
import { Decimal } from '@kit.ArkTS';
import { sensor } from '@kit.SensorServiceKit';

const TAG = "Camera";

const FOUR = 4; // format
const EIGHT = 8; // capacity
const FOUR_THOUSAND_AND_SIXTY_NINE = 4096; // buffer大小

const supportedImageFormats: HashMap<string, image.ImageFormat> = new HashMap();
supportedImageFormats.set("ycbr422sp", image.ImageFormat.YCBCR_422_SP);
supportedImageFormats.set("jpeg", image.ImageFormat.JPEG);

export class Camera implements CameraCaptureStateListener {
  private static TAG: string = 'Camera';
  cameraFeatures: CameraFeatures;
  private imageFormatGroup: string | null = null;
  private videoRenderer: VideoRenderer | null = null;
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
  private previewOutput: camera.PreviewOutput | null = null; // 第一路预览流
  private previewOutput2: camera.PreviewOutput | null = null; // 第二路预览流
  private pausedPreview: boolean = false; // 暂停预览
  private captureTimeouts: CaptureTimeoutsWrapper;
  private captureProps: CameraCaptureProperties;
  private cameraManager: camera.CameraManager;
  private avRecorder: media.AVRecorder | null = null;
  private videoOutput: camera.VideoOutput | null = null;
  private recordingVideo: boolean = false;
  private captureFile: fs.File | null = null;
  private cameraOutputCapability: camera.CameraOutputCapability | null = null;
  private initialCameraFacing: number = 0;
  private photoSession: camera.PhotoSession | null = null; // 拍照模式
  private videoSession: camera.VideoSession | null = null; // 视频模式
  private cameras: Array<camera.CameraDevice> | null = null;
  private photoOutPut: camera.PhotoOutput | null = null;
  private fd: number = -1;
  private isVideoMode: boolean = false; // 视频模式
  private aVRecorderProfile: media.AVRecorderProfile = {
    audioChannels: 2,
    audioCodec: media.CodecMimeType.AUDIO_AAC,
    audioBitrate: 48000,
    audioSampleRate: 48000,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4, // 视频文件封装格式，只支持MP4
    videoBitrate: 100000000, // 视频比特率
    videoCodec: media.CodecMimeType.VIDEO_AVC, // 视频文件编码格式，支持mpeg4和avc两种格式
    videoFrameWidth: 1920, // 视频分辨率的宽
    videoFrameHeight: 1080, // 视频分辨率的高
    videoFrameRate: 30 // 视频帧率
  };
  private phAccessHelper: photoAccessHelper.PhotoAccessHelper;
  private videoPath: string | null = null;
  private videoId: string | undefined = undefined;
  private takePictureResult: MethodResult | undefined;
  private takePictureName: string = '';
  private permissions: CameraPermissions;
  private photoRotation: camera.ImageRotation | undefined;
  private nowZoom: number = 1;
  private displayChangeCallback: ((_displayId: number) => void) | null = null;
  private lastDisplayRotation: number = -1;
  private foldStatusChangeCallback: ((foldStatus: display.FoldStatus) => void) | null = null;
  private autoDeviceSwitchCallback: ((err: BusinessError, status: camera.AutoDeviceSwitchStatus) => void) | null = null;
  private autoDeviceSwitchSession: camera.PhotoSession | camera.VideoSession | null = null;
  public onAutoSwitchToRearCamera: (() => void) | null = null;
  private lastDeviceDegree: number = 0;
  private isClosed: boolean = false;
  private targetVideoBitrate: number | null = null;
  private targetAudioBitrate: number | null = null;

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
  ) {
    if (ability == null) {
      throw new Error('No Ability available!');
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

  // 获取当前场景（拍照模式、视频模式）的Session实例
  getCurSession(): camera.PhotoSession | camera.VideoSession {
    return this.isVideoMode ? this.videoSession! : this.photoSession!;
  }

  public async open(imageFormatGroup: string | null): Promise<void> {

    this.imageFormatGroup = imageFormatGroup;
    const resolutionFeature: ResolutionFeature = this.cameraFeatures.getResolution();

    if (!resolutionFeature.checkIsSupported()) {
      this.sendCameraErrorEvent(
        "Camera with name \""
          + this.cameraProperties.getCameraName()
          + "\" is not supported by this plugin.");
      return;
    }

    let imageFormat: number = supportedImageFormats.get(imageFormatGroup);
    if (imageFormat == null) {
      Log.w(TAG, "The selected imageFormatGroup is not supported by ohos. Defaulting to JPEG")
      imageFormat = image.ImageFormat.JPEG
    }

    this.imageStreamReader = new ImageStreamReader(
      resolutionFeature.getPreviewSize(),
      imageFormat,
      1
    )

    // 增强相机设备获取的错误处理
    this.cameraDevice = CameraUtils.getCameraDevice(this.cameraProperties.getCameraName(), this.cameraManager);
    if (!this.cameraDevice) {
      this.sendCameraErrorEvent("无法获取相机设备: " + this.cameraProperties.getCameraName());
      return;
    }

    // Fixed the issue where the camera could not be turned on
    // when switching cameras after the 3.35 adaptation
    if (this.cameraInput) {
      await this.cameraInput.close();
    }

    if (this.isTriFoldDevice() && display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED) {
      if (this.cameraDevice.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        Log.w(TAG, "Cannot open front camera in tri-fold dual-screen state");
        this.sendCameraErrorEvent("FRONT_CAMERA_UNAVAILABLE");
        return;
      }
    }

    this.cameraInput = this.cameraManager.createCameraInput(this.cameraDevice);
    try{
      await this.cameraInput.open();
      await this.startPreview();
      if (!this.recordingVideo) {
        this.sendCameraInitializedEvent(resolutionFeature);
      }
      this.registerFoldStatusChangeListener();
    }catch (err) {
      this.close();
      let errorDescription: string;
      switch (err.code) {
      case camera.CameraErrorCode.INVALID_ARGUMENT:
      errorDescription = "Can not use camera cause of conflict.";
      break;
      case camera.CameraErrorCode.DEVICE_DISABLED:
      errorDescription = "Camera disabled cause of security reason.";
      break;
      case camera.CameraErrorCode.SERVICE_FATAL_ERROR:
      errorDescription = "Camera service fatal error.";
      break;
      default:
      errorDescription = "Unknown camera error";
      }
      this.dartMessenger.sendCameraErrorEvent(errorDescription);
      throw err as Error;
    }
  }

  getDeviceOrientationManager(): DeviceOrientationManager {
    return this.cameraFeatures?.getSensorOrientation().getDeviceOrientationManager();
  }

  // 统一的错误事件发送方法
  private sendCameraErrorEvent(errorMessage: string): void {
    try {
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger);
      cameraEventApi.error(errorMessage, { reply: () => {} });
    } catch (e) {
      Log.e(TAG, "Failed to send camera error event: " + e.message);
    }
  }

  // 统一的关闭事件发送方法
  private sendCameraClosingEvent(): void {
    try {
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger);
      cameraEventApi.closed({ reply: () => {} });
    } catch (e) {
      Log.e(TAG, "Failed to send camera closing event: " + e.message);
    }
  }

  private sendCameraInitializedEvent(resolutionFeature: ResolutionFeature): void {
    try {
      // 获取 BinaryMessenger 实例
      const binaryMessenger: BinaryMessenger = this.dartMessenger.getBinaryMessenger();
      const cameraEventApi = new CameraEventApi(binaryMessenger);

      // 从相机特性中获取所需的值
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
      Log.e(TAG, "Failed to send camera initialized event: " + e.message);
    }
  }

  // 添加转换方法
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
      case camera.FocusMode.FOCUS_MODE_AUTO:
      default:
        return PlatformFocusMode.auto;
    }
  }

  setFocusPoint(result: MethodResult, point: Point) {
    const focusPointFeature: FocusPointFeature = this.cameraFeatures.getFocusPoint();
    focusPointFeature.setValue(point);

    //Reference: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-camera-focus#setfocuspoint11
 	  //The application's preview interface layout is based on the vertical direction when the device's charging port is at the bottom. The layout's width and height are {w, h}, and the touch point is {x, y}. Therefore, the converted coordinates are {y/h, 1-x/w}.
 	  //Here, the coordinates passed to Dart are based on the vertical direction. x and y have already been calculated, and the range is [0,1].
    const focusPoint: camera.Point | null
      = (point.x == null || point.y == null) ? null : { x: point.y, y: 1-point.x };
    try {
      this.getCurSession().setFocusPoint(focusPoint);
      result.success(null);
    } catch (error) {
      result.error("setFocusPointFailed", "Could not set focus point.", null);
    }
  }

  getFocusMode(result: MethodResult) {
    let nowFocusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_AUTO

    try {
      // 获取当前对焦模式
      nowFocusMode = this.getCurSession().getFocusMode();
      if (nowFocusMode == camera.FocusMode.FOCUS_MODE_MANUAL) {
        nowFocusMode = camera.FocusMode.FOCUS_MODE_AUTO
      } else if (nowFocusMode == camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO) {
        nowFocusMode = camera.FocusMode.FOCUS_MODE_AUTO
      }
    } catch (error) {
      result?.error("getFocusModeFailed", "Could not get focus point", null)
    }

    this.setFocusMode(result, nowFocusMode);
  }

  setFocusMode(result: MethodResult, newMode: camera.FocusMode) {
    if (!this.getCurSession().isFocusModeSupported(newMode)) {
      result.error("setFocusModeFailed", "The focus mode is unsupported.", null);
      return;
    }
    const autoFocusFeature: AutoFocusFeature = this.cameraFeatures.getAutoFocus();
    autoFocusFeature.setValue(newMode);

    try {
      this.getCurSession().setFocusMode(newMode)
      result?.success(null)
    } catch (error) {
      result?.error("焦点设置失败: ", `${JSON.stringify(error)}`, null)
    }
  }

  // 设置曝光补偿
  setExposureOffset(result: MethodResult, offset: number) {
    const exposureOffsetFeature: ExposureOffsetFeature = this.cameraFeatures.getExposureOffset();
    exposureOffsetFeature.setValue(offset, this.photoSession!);

    try {
      this.getCurSession().setExposureBias(offset);
      result.success(exposureOffsetFeature.getValue());
    } catch (error) {
      result.error("setExposureOffsetFailed", "Could not set exposure offset.", null);
    }
  }

  public getMaxZoomLevel(): number {
    return this.cameraFeatures.getZoomLevel().getMaximumZoomLevel(this.getCurSession());
  }

  public getMinZoomLevel(): number {
    return this.cameraFeatures.getZoomLevel().getMinimumZoomLevel(this.getCurSession());
  }

  public setZoomLevel(result: MethodResult, zoom: number): void {
    const zoomLevel: ZoomLevelFeature = this.cameraFeatures.getZoomLevel();
    let maxZoom: number = zoomLevel.getMaximumZoomLevel(this.getCurSession());
    let minZoom: number = zoomLevel.getMinimumZoomLevel(this.getCurSession());

    if (zoom > maxZoom || zoom < minZoom) {
      result.error("ZOOM_ERROR",
        "Zoom level out of bounds (zoom level should be between " + minZoom + " and " + maxZoom + ").", null);
      return;
    }

    try {
      this.getCurSession().setZoomRatio(zoom);
    } catch (error) {
      Log.e(TAG, "setZoomLevel failed: zoom=" + zoom + ", error=" + error.message);
      result.error("setZoomLevelFailed", "Could not set zoom level.", null);
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

  // 暂停预览
  public async pausePreview(result: MethodResult) {
    try {
      await this.previewOutput?.stop();
      await this.previewOutput2?.stop();
    } catch (e) {
    }
    this.pausedPreview = true;
    result.success(null);
  }

  // 恢复预览
  public async resumePreview(result: MethodResult) {
    try {
      if (this.pausedPreview) {
        await this.previewOutput?.start();
        await this.previewOutput2?.start();
      }
    } catch (e) {
    }
    this.pausedPreview = false;
    result.success(null);
  }

  // 设置曝光区域中心点
  setExposurePoint(result: MethodResult, point: Point) {
    const exposurePointFeature: ExposurePointFeature = this.cameraFeatures.getExposurePoint();
    exposurePointFeature.setValue(point);

    const exposurePoint: camera.Point | null
      = (point.x == null || point.y == null) ? null : { x: point.x, y: point.y };

    try {
      this.getCurSession().setMeteringPoint(exposurePoint);
      result.success(null);
    } catch (error) {
      result.error("setExposurePointFailed", "Could not set exposure point.", null);
    }
  }

  // 设置曝光模式。
  // 进行设置之前，需要先检查设备是否支持指定的曝光模式，可使用方法isExposureModeSupported。
  setExposureMode(result: MethodResult, newMode: camera.ExposureMode) {
    if (!CameraUtils.isExposureModeSupported(this.getCurSession(), newMode)) {
      result.error("setExposureModeFailed", "The exposure mode is unsupported.", null);
      return;
    }

    let modeExistence: boolean = false;
    Object.values(camera.ExposureMode).forEach((value) => {
      if (newMode == value) {
        modeExistence = true
      }
    })

    if (!modeExistence) {
      result.error("setExposureModeFailed", "The exposure mode is unsupported.", null);
      return;
    }

    const exposureLockFeature: ExposureLockFeature = this.cameraFeatures.getExposureLock();
    exposureLockFeature.setValue(newMode);

    try {
      this.getCurSession().setExposureMode(newMode);
      result.success(null)
    } catch (error) {
      result.error("setExposureModeError", JSON.stringify(error), null)
    }
  }

  // 设置闪光灯模式。
  // 进行设置之前，需要先检查：
  // 设备是否支持闪光灯，可使用方法hasFlash。
  // 设备是否支持指定的闪光灯模式，可使用方法isFlashModeSupported。
  setFlashMode(result: MethodResult, newMode: camera.FlashMode) {
    if (!CameraUtils.hasFlash(this.getCurSession())) {
      result.error("setFlashModeFailed", "The camera device does not have flash.", null);
      return;
    }

    if (!CameraUtils.isFlashModeSupported(this.getCurSession(), newMode)) {
      result.error("setFlashModeFailed", " The flash mode is unsupported.", null);
      return;
    }

    // Save the new flash mode setting.
    const flashFeature: FlashFeature = this.cameraFeatures.getFlash();
    flashFeature.setValue(newMode);

    try {
      this.getCurSession().setFlashMode(newMode);
      result.success(null);
    } catch (error) {
      result.error("setFlashModeFailed", "The setFlashMode call failed", null);
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
      Log.w(TAG, "Device does not support flash, skipping flash mode application");
      return;
    }

    try {
      const flashMode: camera.FlashMode = this.cameraFeatures.getFlash().getValue();
      if (session.isFlashModeSupported(flashMode)) {
        await session.setFlashMode(flashMode);
      } else {
        Log.w(TAG, "Flash mode " + flashMode + " is not supported by the current session, skipping flash mode application");
      }
    } catch (error) {
      Log.e(TAG, "applyFlashMode error: " + error.message);
    }
  }

  async takePicture(result: MethodResult) {
    if (this.cameraCaptureCallback.getCameraState() != CameraState.STATE_PREVIEW) {
      result.error("captureAlreadyActive", "Picture is currently already being captured", null);
      return;
    }
    this.takePictureResult = result;
    this.takePictureName = '/IMG_' + Date.now().toString() + '.jpg';
    this.runPictureAutoFocus();
  }

  /** Start capturing a picture, doing autofocus first. */
  private runPictureAutoFocus() {
    this.cameraCaptureCallback.setCameraState(CameraState.STATE_WAITING_FOCUS);
    this.lockAutoFocus();
  }

  async lockAutoFocus(): Promise<void> {
    if (this.photoSession == null) {
      const errMsg = "[unlockAutoFocus] captureSession null, returning";
      console.error(TAG, errMsg);
      // reset status and callback error
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      this.takePictureResult?.error("captureSession null", errMsg, -1);
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
      this.photoRotation = this.photoOutPut?.getPhotoRotation(rotationDegree);
    } else {
      const deviceDegree: number = await this.getDeviceDegree();
      this.photoRotation = this.photoOutPut?.getPhotoRotation(deviceDegree);
    }

    const enableMirror = this.isFrontCamera() && (this.photoOutPut?.isMirrorSupported() ?? false);

    let settings: camera.PhotoCaptureSetting = {
      quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
      rotation: this.photoRotation,
      location: captureLocation,
      mirror: enableMirror,
    };

    this.cameraCaptureCallback.setCameraState(CameraState.STATE_CAPTURING);

    // 触发拍照
    this.photoOutPut?.capture(settings, (err: BusinessError) => {
      // 拍照完成，更新CameraState
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      if (err) {
        console.error(`Failed to capture the photo ${err.code}`);
        this.sendCameraErrorEvent(err.message);
        return;
      }
      // 拍照成功
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
        this.lastDeviceDegree = this.lastDeviceDegree >= 0 ? this.lastDeviceDegree % 360 : this.lastDeviceDegree % 360 + 360;
      } catch (error) {
        let err = error as BusinessError;
        console.error(TAG + ' Decimal failed, error: ' + err.code);
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
      Log.e(TAG, "getSensorList failed, error: " + err.code);
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
    const sensorPromise = new Promise<number>((resolve) => {
      if (isGravitySupported) {
        sensor.once(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse) => {
          resolve(this.getRealSensorData(data));
        });
      } else {
        sensor.once(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
          resolve(this.getRealSensorData(data as sensor.GravityResponse));
        });
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

  unlockAutoFocus(): void {
    if (this.photoSession == null) {
      console.info("[unlockAutoFocus] captureSession null, returning");
      return;
    }
    try {

    } catch (e) {
      this.sendCameraErrorEvent(e.message);
      return;
    }
  }

  async startVideoRecording(result: MethodResult, imageStreamChannel: EventChannel | null) {
    this.prepareRecording(result);

    if (imageStreamChannel != null) {
      this.setStreamHandler(imageStreamChannel);
    }

    this.initialCameraFacing = this.cameraProperties.getLensFacing();
    this.recordingVideo = true;

    try {
      // 开始录制
      await this.startCapture(true, imageStreamChannel != null);
      result.success(null);
    } catch (e) {
      this.recordingVideo = false;
      this.captureFile = null;
      result.error("videoRecordingFailed", e.message, null);
    }
  }

  async stopVideoRecording(result: MethodResult) {
    if (!this.recordingVideo || !this.avRecorder) {
      result.success(null);
      return;
    }

    this.cameraFeatures.setAutoFocus(this.cameraFeatureFactory.createAutoFocusFeature(this.cameraProperties, false));
    this.recordingVideo = false;
    const isPrepared = this.avRecorder.state === 'started' || this.avRecorder.state === 'paused' || this.avRecorder.state === 'prepared';
    try {
      if (isPrepared) {
        await this.avRecorder.stop();
      }
      await this.avRecorder.release();
      // 停止录像输出流
      this.videoOutput?.stop();
      if (isPrepared) {
        this.videoPath = this.captureFile?.path ?? null;
      } else {
        this.videoPath = null;
      }
    } catch (e) {
      this.videoPath = null;
      Log.d(TAG, "videoSession stop error" + e.toString());
    } finally {
      try {
        fs.close(this.captureFile);
        this.captureFile = null;
        this.isVideoMode = false;
        this.open(this.imageFormatGroup);
      } catch (e) {
        Log.d(TAG, "close file or openPreview error" + e.toString());
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

  // 开启录像预览
  async startPreviewWithVideo() {
    try {
      this.cameraOutputCapability =
        CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
          this.cameraManager);
      // 使用fps参数选择profile，保持与startCapture逻辑一致
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
        this.previewOutput.stop();
      }
      if (this.recordingVideo && this.avRecorder != undefined && this.avRecorder.state === 'paused') {
        // 录像中且暂停状态
      } else {
        await this.videoOutput.start();
      }
    } catch (e) {
      console.error(TAG, `启用录像预览失败：${e}`)
    }
  }

  // 开启拍照预览
  async startPreviewWithPhoto() {
    try {
      // 验证前置条件
      if (!this.cameraDevice) {
        throw new Error('相机设备未初始化');
      }

      if (!this.cameraInput) {
        throw new Error('相机输入未初始化');
      }

      if (!this.flutterTexture) {
        throw new Error('Flutter纹理未初始化');
      }

      this.cameraOutputCapability =
        CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_PHOTO, this.cameraManager);

      if (!this.cameraOutputCapability ||
          this.cameraOutputCapability.previewProfiles.length === 0 ||
          this.cameraOutputCapability.photoProfiles.length === 0) {
        throw new Error('无法获取相机输出能力');
      }
      // 查找匹配的预览配置
      let previewProfileIndex = this.cameraFeatures
                                    .getResolution()
                                    .getPreviewProfileIndex(this.cameraOutputCapability.previewProfiles);
      // 查找匹配的拍照配置
      let photoProfileIndex = this.cameraFeatures
                                  .getResolution()
                                  .getPhotoProfileIndex(this.cameraOutputCapability.photoProfiles);
      // 验证 Surface ID
      const surfaceId = this.flutterTexture.getSurfaceId();
      if (surfaceId <= 0) {
        throw new Error(`无效的Flutter纹理Surface ID: ${surfaceId}`);
      }
      const surfaceIdString = surfaceId.toString();
      let previewSize: camera.Size = this.cameraOutputCapability.previewProfiles[previewProfileIndex].size;
      this.cameraFeatures.getResolution().setPreviewSize(previewSize);
      this.previewOutput = this.cameraManager.createPreviewOutput(
        this.cameraOutputCapability.previewProfiles[previewProfileIndex],
        surfaceIdString);
      this.photoOutPut = this.cameraManager.createPhotoOutput(
        this.cameraOutputCapability.photoProfiles[photoProfileIndex]);

      // 设置拍照回调
      this.photoOutPut.on('photoAssetAvailable', (err: BusinessError, photoAsset: photoAccessHelper.PhotoAsset): void => {
        if (err) {
          this.takePictureResult?.error(err.code.toString(), err.message, err.data);
          return;
        }
        this.mediaLibRequestBuffer(photoAsset);
      });

      this.photoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.photoSession.beginConfig();
      this.photoSession.addInput(this.cameraInput);
      this.photoSession.addOutput(this.previewOutput);
      this.photoSession.addOutput(this.photoOutPut);
      await this.photoSession.commitConfig();

      this.updatePreviewRotation();
      this.registerDisplayChangeListener();
      this.getCurSession().setZoomRatio(this.nowZoom);
      await this.photoSession.start();
      this.enableAutoDeviceSwitch(this.photoSession);
      await this.applyFlashMode(this.photoSession);
      if (this.pausedPreview) {
        await this.previewOutput.stop();
      }
    } catch (error) {
      // 清理资源
      this.unregisterDisplayChangeListener();
      try {
        if (this.photoSession) {
          await this.photoSession.stop();
          this.photoSession = null;
        }
        if (this.previewOutput) {
          this.previewOutput = null;
        }
        if (this.photoOutPut) {
          this.photoOutPut = null;
        }
      } catch (cleanupError) {

      }

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
          that.convertBufferToFile(data);
        }
      });
  }

  convertBufferToFile(data: ArrayBuffer) {
    let photoUri: string = getContext(this).cacheDir + this.takePictureName;
    let file: fs.File = fs.openSync(photoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.write(file.fd, data).then(() => {
      fs.closeSync(file);
      if (this.takePictureResult) {
        this.takePictureResult.success(photoUri)
        this.takePictureResult = undefined;
      }
    });
  }

  async pauseVideoRecording(result: MethodResult) {
    if (!this.recordingVideo) {
      result.success(null);
      return;
    }

    try {
      if (this.avRecorder != undefined && this.avRecorder.state === 'started') { // 仅在started状态下调用pause为合理状态切换
        await this.avRecorder.pause();
        await this.videoOutput?.stop(); // 停止相机出流
      }

    } catch (e) {
      Log.d(TAG, "pauseVideoRecording error")
      result.error("videoRecordingFailed", e.getMessage(), null);
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
      if (this.avRecorder != undefined && this.avRecorder.state === 'paused') { // 仅在paused状态下调用resume为合理状态切换
        await this.videoOutput?.start(); // 启动相机出流
        await this.avRecorder?.resume();
      } else {
        result.error(
          "videoRecordingFailed", "avRecorder state is not paused", null);
        return;
      }
    } catch (e) {
      result.error("videoRecordingFailed", e.getMessage(), null);
      return;
    }

    result.success(null);
  }

  startPreviewWithImageStream(imageStreamChannel: EventChannel) {
    this.setStreamHandler(imageStreamChannel);
    this.startImageStream();
  }

  async startImageStream() {
    try {
      if (this.photoSession != null) {
        await this.photoSession?.stop()
      }
    } catch (e) {
    }
    try {
      if (this.videoSession != null) {
        await this.videoSession?.stop();
      }
    } catch (e) {
    }

    let profiles =
      CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_PHOTO, this.cameraManager)
    let previewProfileIndex = this.cameraFeatures
                                  .getResolution()
                                  .getPreviewProfileIndex(profiles.previewProfiles);
    this.previewOutput = this.cameraManager.createPreviewOutput(
      profiles.previewProfiles[previewProfileIndex],
      this.flutterTexture.getSurfaceId().toString());
    let photoProfileIndex = this.cameraFeatures
                                .getResolution()
                                .getPhotoProfileIndex(profiles.photoProfiles);
    this.photoOutPut = this.cameraManager.createPhotoOutput(
      profiles.photoProfiles[photoProfileIndex]);
    let imageReceiverSurfaceId: string = await this.imageStreamReader!.getReceivingSurfaceId();
    this.previewOutput2 =
      this.cameraManager.createPreviewOutput(profiles.previewProfiles[previewProfileIndex], imageReceiverSurfaceId);

    this.photoOutPut.on('photoAssetAvailable', (err: BusinessError, photoAsset: photoAccessHelper.PhotoAsset): void => {
      if (err) {
        this.takePictureResult?.error(err.code.toString(), err.message, err.data);
        return;
      }
      this.mediaLibRequestBuffer(photoAsset);
    });

    this.photoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
    this.photoSession.beginConfig();
    await this.cameraInput?.open();
    this.photoSession.addInput(this.cameraInput);
    this.photoSession.addOutput(this.previewOutput);
    this.photoSession.addOutput(this.previewOutput2);
    this.photoSession.addOutput(this.photoOutPut);
    await this.photoSession.commitConfig();
    this.updatePreviewRotation();
    this.registerDisplayChangeListener();
    await this.photoSession.start();
    this.enableAutoDeviceSwitch(this.photoSession);
  }

  async prepareMediaRecorder(cameraManager: camera.CameraManager,
    cameraOutputCapability: camera.CameraOutputCapability, url: string) {
    Log.i(TAG, "prepareMediaRecorder");
    if (this.avRecorder != null) {
      this.avRecorder.release();
    }
  }

  async startCapture(record: boolean, stream: boolean) {
    if (!this.pausedPreview) {
      this.getCurSession().stop();
    }
    this.photoSession = null;
    this.isVideoMode = true;
    try {
      let recorder = await media.createAVRecorder();
      if (recorder != null) {
        this.avRecorder = recorder;
        let videoUri: string = getContext(this).cacheDir + '/REC' + Date.now().toString() + '.mp4';
        this.captureFile = fs.openSync(videoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        let fd = this.captureFile.fd;

        this.cameraOutputCapability =
          CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
            this.cameraManager);
        // 录像模式下同样基于目标 fps 选择最合适的会话 profile。
        const preferredFps = this.cameraFeatures.getFpsRange().getValue();
        let videoSessionProfile: VideoSessionProfile = this.cameraFeatures
                                                           .getResolution()
                                                           .getVideoSessionProfile(
                                                             this.cameraOutputCapability.previewProfiles,
                                                             this.cameraOutputCapability.videoProfiles,
                                                             preferredFps);

        this.aVRecorderProfile.videoFrameWidth = videoSessionProfile.getCaptureProfile()?.size.width;
        this.aVRecorderProfile.videoFrameHeight = videoSessionProfile.getCaptureProfile()?.size.height;
        // 使用筛选后的 profile 更新 AVRecorder 目标帧率。
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
          this.previewOutput2 = this.cameraManager.createPreviewOutput(videoSessionProfile.getPreviewProfile(), surfaceId);
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
          Log.d(TAG, "startAVRecorder error")
        }
      } else {
        Log.e(TAG, "startVideo createAVRecorder fail : recorder is null");
      }
    } catch (error) {
      Log.e(TAG, "startVideo createAVRecorder fail :" + error.message);
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

    // 目标 fps 会按 profile 可支持范围钳制，避免设置非法帧率。
    if (preferredFps != null && preferredFps > 0) {
      this.aVRecorderProfile.videoFrameRate = preferredFps;
    }
  }

  // 设置视频防抖模式
  public setVideoStabilizationMode(result: MethodResult, mode: PlatformVideoStabilizationMode) {
    console.log(Camera.TAG, `Camera.ets - setVideoStabilizationMode called with mode: ${mode}`);
    // 保存用户设置的防抖模式
    this.cameraFeatures.getVideoStabilization().setValue(mode);

    // 记录日志说明实际应用将在录制开始时进行
    console.log(Camera.TAG, `Video stabilization mode ${mode} saved, will be applied during video recording start`);

    result.success(null);
  }

  // 获取当前相机支持的防抖模式列表
  public getSupportedVideoStabilizationModes(): PlatformVideoStabilizationMode[] {
    console.log(Camera.TAG, 'Camera.ets - getSupportedVideoStabilizationModes called');
    // 通过特性管理类查询底层支持情况
    const modes = this.cameraFeatures.getVideoStabilization().getSupportedModes();
    console.log(Camera.TAG, `Camera.ets - getSupportedVideoStabilizationModes returning from feature: ${modes}`);
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
      Log.w(TAG, "Failed to get current preview rotation: " + e.message);
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
        Log.e(TAG, "Failed to set texture buffer size: " + e.message);
      }
    } else {
      Log.w(TAG, "Cannot set texture buffer size: textureRegistry is null");
    }
  }

  private updatePreviewRotation(): void {
    if (this.previewOutput == null) {
      Log.w(TAG, "updatePreviewRotation: previewOutput is null");
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

      Log.d(TAG, `Preview rotation updated: previewRotation=${previewRotation}, bufferSize=${bufferWidth}x${bufferHeight}, cameraProfileSize=${previewSize.width}x${previewSize.height}`);
    } catch (error) {
      Log.e(TAG, "Failed to update preview rotation: " + error.message);
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
      Log.d(TAG, "Display change listener registered");
    } catch (error) {
      Log.e(TAG, "Failed to register display change listener: " + error.message);
    }
  }

  private unregisterDisplayChangeListener(): void {
    if (this.displayChangeCallback != null) {
      try {
        display.off('change', this.displayChangeCallback);
        this.displayChangeCallback = null;
        Log.d(TAG, "Display change listener unregistered");
      } catch (error) {
        Log.e(TAG, "Failed to unregister display change listener: " + error.message);
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
      Log.w(TAG, "Failed to detect tri-fold device: " + e.message);
      return false;
    }
  }

  private enableAutoDeviceSwitch(session: camera.PhotoSession | camera.VideoSession): void {
    this.unregisterAutoDeviceSwitchListener();
    if (!session.isAutoDeviceSwitchSupported()) {
      Log.d(TAG, "Auto device switch is not supported on this device");
      return;
    }
    try {
      session.enableAutoDeviceSwitch(true);
      Log.d(TAG, "Auto device switch enabled");
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
      Log.i(TAG, `autoDeviceSwitchStatusChange: isDeviceSwitched=${status.isDeviceSwitched}, isDeviceCapabilityChanged=${status.isDeviceCapabilityChanged}`);
      if (status.isDeviceSwitched) {
        if (this.previewOutput == null) {
          Log.w(TAG, "autoDeviceSwitchCallback: previewOutput is null, skipping preview rotation update");
        } else {
          this.updatePreviewRotation();
        }
        if (this.recordingVideo) {
          this.enableVideoMirrorIfNeeded().catch((e: Error): void =>
            Log.w(TAG, "Failed to update video mirror after device switch: " + e.message));
        }
        this.sendCameraInitializedEvent(this.cameraFeatures.getResolution());
        Log.d(TAG, "Preview rotation and initialized event updated after auto device switch");
      }
      if (status.isDeviceCapabilityChanged) {
        try {
          const minZoom = this.cameraFeatures.getZoomLevel().getMinimumZoomLevel(session);
          session.setZoomRatio(minZoom);
          this.nowZoom = minZoom;
          Log.d(TAG, `Zoom reset to minimum ${minZoom} after device capability change`);
        } catch (e) {
          Log.w(TAG, "Failed to reset zoom after device capability change: " + e.message);
        }
      }
    };
    this.autoDeviceSwitchSession = session;
    session.on('autoDeviceSwitchStatusChange', this.autoDeviceSwitchCallback);
    Log.d(TAG, "Auto device switch listener registered");
  }

  private unregisterAutoDeviceSwitchListener(): void {
    if (this.autoDeviceSwitchCallback != null && this.autoDeviceSwitchSession != null) {
      try {
        this.autoDeviceSwitchSession.off('autoDeviceSwitchStatusChange', this.autoDeviceSwitchCallback);
        Log.d(TAG, "Auto device switch listener unregistered");
      } catch (error) {
        Log.e(TAG, "Failed to unregister auto device switch listener: " + error.message);
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
    this.foldStatusChangeCallback = (foldStatus: display.FoldStatus) => {
      if (this.isClosed) {
        Log.w(TAG, "foldStatusChangeCallback: Camera is already closed, ignoring");
        return;
      }
      if (foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED) {
        if (this.cameraDevice?.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          Log.w(TAG, "Tri-fold device switched to dual-screen while using front camera, auto switching to rear");
          if (this.onAutoSwitchToRearCamera != null) {
            this.onAutoSwitchToRearCamera();
          } else {
            // Send error event before close() to ensure dartMessenger is still valid
            this.sendCameraErrorEvent("FRONT_CAMERA_UNAVAILABLE");
            this.close();
          }
        }
      }
    };
    try {
      display.on('foldStatusChange', this.foldStatusChangeCallback);
      Log.d(TAG, "Fold status change listener registered");
    } catch (error) {
      Log.e(TAG, "Failed to register fold status change listener: " + error.message);
    }
  }

  private unregisterFoldStatusChangeListener(): void {
    if (this.foldStatusChangeCallback != null) {
      try {
        display.off('foldStatusChange', this.foldStatusChangeCallback);
        this.foldStatusChangeCallback = null;
        Log.d(TAG, "Fold status change listener unregistered");
      } catch (error) {
        Log.e(TAG, "Failed to unregister fold status change listener: " + error.message);
      }
    }
  }

  // 关闭
  public close(): void {
    this.isClosed = true;
    this.unregisterDisplayChangeListener();
    this.unregisterFoldStatusChangeListener();
    this.unregisterAutoDeviceSwitchListener();
    this.stopAndReleaseCamera();

    this.avRecorder?.reset();
    this.avRecorder?.release();
    this.avRecorder = null;

    this.cameraDevice = null;
    this.releaseSession();
    this.sendCameraClosingEvent();
  }

  // 关闭摄像头输入流
  private stopAndReleaseCamera() {
    if (this.cameraInput != null) {
      try {
        this.photoSession?.removeInput(this.cameraInput);
      } catch (e) {
      }
      try {
        this.videoSession?.removeInput(this.cameraInput);
      } catch (e) {
      }

      this.cameraInput.close();
      this.cameraInput = null;
    }

    if (this.cameraDevice != null) {
      this.cameraDevice = null;
      this.photoSession = null;
      this.videoSession = null;
    } else {
      this.stopSession();
    }
  }

  // 停止Session
  async stopSession() {

    if (this.photoSession != null) {
      await this.photoSession.stop();
      this.photoSession = null;
    }
    if (this.videoSession != null) {
      await this.videoSession.stop();
      this.videoSession = null;
    }
  }

  public setDescriptionWhileRecording(result: MethodResult, properties: CameraProperties) {
    result.error("error", "Camera switching is not supported while recording.", null);
    return;
  }

  dispose() {
    console.error(TAG, 'dispose');
    this.close();
    this.getDeviceOrientationManager().stop();
  }

  // 释放Session
  private async releaseSession() {
    if (this.photoSession != null) {
      await this.photoSession.stop();
      await this.photoSession.release();
      this.photoSession = null;
    }
    if (this.videoSession != null) {
      await this.videoSession.stop();
      await this.videoSession.release();
      this.videoSession = null;
    }
  }

  private async releaseCameraInput() {
    if (this.cameraInput != null) {
      try {
        await this.cameraInput.close();
        this.cameraInput = null;
      } catch (e) {
      }
    }
  }

  private async releasePreviewOutput() {
    if (this.previewOutput != null) {
      try {
        await this.previewOutput.release();
        this.previewOutput = null;
      } catch (e) {
      }
    }
  }

  private async releasePhotoOutput() {
    if (this.photoOutPut != null) {
      try {
        this.photoOutPut.off('photoAssetAvailable')
        await this.photoOutPut.release();
        this.photoOutPut = null;
      } catch (e) {
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
      }
    }
  }

  // 释放Camera
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
      console.debug(TAG, `setFrameRate frameRate = ${JSON.stringify(frameRate)}`)
      let mFps = fps
      if (fps > frameRate.max) {
        mFps = frameRate.max
      } else if (fps < frameRate.min) {
        mFps = frameRate.min
      }
      console.debug(TAG, `setFrameRate mFps = ${mFps}`)
      videoOutput.setFrameRate(mFps, mFps)
    } catch (e) {
      console.error(TAG, `setFrameRate error = ${JSON.stringify(e)}`)
    }
  }
}