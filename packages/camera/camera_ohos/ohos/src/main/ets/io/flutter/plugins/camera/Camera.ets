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
import { buffer, HashMap, List } from '@kit.ArkTS';
import { EventChannel, Log } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
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
  private isClosed: boolean = false;

  constructor(
    ability: UIAbility,
    flutterTexture: SurfaceTextureEntry,
    cameraFeatureFactory: CameraFeatureFactory,
    dartMessenger: DartMessenger,
    cameraProperties: CameraProperties,
    resolutionPreset: ResolutionPreset,
    enableAudio: boolean,
    permissions: CameraPermissions,
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
    this.cameraFeatures =
      CameraFeatures.init(
        cameraFeatureFactory, cameraProperties, ability, dartMessenger, resolutionPreset);

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
    this.isClosed = false;  // 重置关闭状态，允许重新打开
    this.imageFormatGroup = imageFormatGroup;
    const resolutionFeature: ResolutionFeature = this.cameraFeatures.getResolution();

    if (!resolutionFeature.checkIsSupported()) {
      this.dartMessenger.sendCameraErrorEvent(
        "Camera with name \""
          + this.cameraProperties.getCameraName()
          + "\" is not supported by this plugin.");
      return;
    }

    let imageFormat: number = supportedImageFormats.get(imageFormatGroup);
    if (imageFormat == null) {
      Log.w(TAG, "The selected imageFormatGroup is not supported by ohos. Defaulting to yuv420")
      imageFormat = image.ImageFormat.JPEG
    }

    this.imageStreamReader = new ImageStreamReader(
      resolutionFeature.getPreviewSize(),
      imageFormat,
      1
    )

    this.cameraDevice = CameraUtils.getCameraDevice(this.cameraProperties.getCameraName(), this.cameraManager);
    this.cameraInput = this.cameraManager.createCameraInput(this.cameraDevice);
    try {
      await this.cameraInput.open();
    } catch (err) {
      const errorDescription = this.getCameraOpenErrorDescription(err);
      // Send error event before close to ensure error arrives at Dart side before closing event
      this.dartMessenger.sendCameraErrorEvent(errorDescription);
      await this.close();
      throw err as Error;
    }

    try {
      await this.startPreview();
      if (!this.recordingVideo) {
        this.dartMessenger.sendCameraInitializedEvent(
          resolutionFeature.getPreviewSize().width,
          resolutionFeature.getPreviewSize().height,
          ExposureMode.getValueForMode(this.cameraFeatures.getExposureLock().getValue()),
          FocusMode.getValueForMode(this.cameraFeatures.getAutoFocus().getValue()),
          this.cameraFeatures.getExposurePoint().checkIsSupported(),
          this.cameraFeatures.getFocusPoint().checkIsSupported()
        )
      }
    } catch (e) {
      this.dartMessenger.sendCameraErrorEvent(this.getErrorMessage(e));
      await this.close();
      throw e as Error;
    }
  }

  private getCameraOpenErrorDescription(err: Object): string {
    const businessError = err as BusinessError;
    switch (businessError.code) {
      case camera.CameraErrorCode.INVALID_ARGUMENT:
        return "Can not use camera cause of conflict.";
      case camera.CameraErrorCode.DEVICE_DISABLED:
        return "Camera disabled cause of security reason.";
      case camera.CameraErrorCode.SERVICE_FATAL_ERROR:
        return "Camera service fatal error.";
      default:
        return this.getErrorMessage(err);
    }
  }

  private getErrorMessage(error: Object): string {
    const message = (error as BusinessError).message;
    return message == null || message.length === 0 ? "Unknown camera error" : message;
  }

  getDeviceOrientationManager(): DeviceOrientationManager {
    return this.cameraFeatures?.getSensorOrientation().getDeviceOrientationManager();
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
      result?.success(null)
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
      Log.e(TAG, "pausePreview: failed to stop preview output: " + e.message);
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
      Log.e(TAG, "resumePreview: failed to start preview output: " + e.message);
    }
    this.pausedPreview = false;
    result.success(null);
  }

  // 设置曝光区域中心点
  setExposurePoint(result: MethodResult, point: Point) {
    const exposurePointFeature: ExposurePointFeature = this.cameraFeatures.getExposurePoint();
    exposurePointFeature.setValue(point);

    //Reference: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-camera-meteringpoint
    //The application's preview interface layout is based on the vertical direction when the device's charging port is at the bottom. The layout's width and height are {w, h}, and the touch point is {x, y}. Therefore, the converted coordinates are {y/h, 1-x/w}.
    //Here, the coordinates passed to Dart are based on the vertical direction. x and y have already been calculated, and the range is [0,1].
    const exposurePoint: camera.Point | null
      = (point.x == null || point.y == null) ? null : { x: point.y, y: 1-point.x };

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

    const modeExistence: boolean = Object.values(camera.ExposureMode).includes(newMode);

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
      result.success(null)
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

    let settings: camera.PhotoCaptureSetting = {
      quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
      rotation: this.photoRotation,
      location: captureLocation,
      mirror: false,
    };

    this.cameraCaptureCallback.setCameraState(CameraState.STATE_CAPTURING);

    // 触发拍照
    this.photoOutPut?.capture(settings, (err: BusinessError) => {
      // 拍照完成，更新CameraState
      this.cameraCaptureCallback.setCameraState(CameraState.STATE_PREVIEW);
      if (err) {
        console.error(`Failed to capture the photo ${err.code}`);
        this.dartMessenger.sendCameraErrorEvent(err.message);
        return;
      }
      // 拍照成功
    });
  }

  getDeviceDegree(): Promise<number> {
    return new Promise<number>((resolve) => {
      try {
        sensor.getSingleSensor(sensor.SensorId.GRAVITY).then((data: sensor.Sensor) => {
          sensor.once(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse) => {
            let x: number = data.x;
            let y: number = data.y;
            let z: number = data.z;
            let deviceDegree: number;
            if ((x * x + y * y) * 3 < z * z) {
              deviceDegree = -1;
            } else {
              let sd: Decimal = Decimal.atan2(y, -x);
              let sc: Decimal = Decimal.round(Number(sd) / 3.141592653589 * 180)
              deviceDegree = 90 - Number(sc);
              deviceDegree = deviceDegree >= 0 ? deviceDegree% 360 : deviceDegree% 360 + 360;
            }
            resolve(deviceDegree);
          });
        });
      } catch (error) {
        let err = error as BusinessError;
        Log.e(TAG, "Failed to register gravity sensor: " + err.message);
        resolve(-1); // 异常时返回默认值
      }
    });
  }

  unlockAutoFocus(): void {
    if (this.photoSession == null) {
      console.info("[unlockAutoFocus] captureSession null, returning");
      return;
    }
    try {

    } catch (e) {
      this.dartMessenger.sendCameraErrorEvent(e.message)
      return;
    }
  }

  async startVideoRecording(result: MethodResult, imageStreamChannel: EventChannel | null) {
    this.prepareRecording(result);

    if (imageStreamChannel != null) {
      this.setStreamHandler(imageStreamChannel);
    }

    this.initialCameraFacing = this.cameraProperties.getLensFacing();

    try {
      // 开始录制
      await this.startCapture(true, imageStreamChannel != null);
      this.recordingVideo = true;
      result.success(null);
    } catch (e) {
      this.recordingVideo = false;
      this.captureFile = null;
      let errMsg = "Unknown error";
      if (e instanceof Error) {
        errMsg = e.message;
      } else if (typeof e === 'string') {
        errMsg = e;
      }
      result.error("videoRecordingFailed", errMsg, null);
    }
  }

  async stopVideoRecording(result: MethodResult) {
    if (!this.recordingVideo) {
      result.success(null);
      return;
    }

    if (!this.avRecorder) {
      this.recordingVideo = false;
      result.error("videoRecordingFailed", "avRecorder is not initialized", null);
      return;
    }

    this.cameraFeatures.setAutoFocus(this.cameraFeatureFactory.createAutoFocusFeature(this.cameraProperties, false));
    this.recordingVideo = false;
    const isPrepared =
      this.avRecorder.state === 'started' || this.avRecorder.state === 'paused' || this.avRecorder.state === 'prepared';
    try {
      if (isPrepared) {
        await this.avRecorder.stop();
      }
      await this.avRecorder.release();
      // 停止录像输出流
      await this.videoOutput?.stop();
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
        await this.open(this.imageFormatGroup);
      } catch (e) {
        Log.d(TAG, "close file or openPreview error" + e.toString());
      }
    }
    result.success(this.videoPath);
  }

  async startPreview(): Promise<void> {
    if (this.recordingVideo) {
      await this.startPreviewWithVideo();
    } else {
      await this.startPreviewWithPhoto();
    }
  }

  // 开启录像预览
  async startPreviewWithVideo() {
    this.cameraOutputCapability =
      CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
        this.cameraManager);
    let videoSessionProfile: VideoSessionProfile = this.cameraFeatures
                                                       .getResolution()
                                                       .getVideoSessionProfile(
                                                         this.cameraOutputCapability.previewProfiles,
                                                         this.cameraOutputCapability.videoProfiles);

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
    await this.videoSession?.start();

    await this.applyFlashMode(this.videoSession!);

    if (this.pausedPreview) {
      await this.previewOutput.stop();
    }
    if (this.recordingVideo && this.avRecorder != undefined && this.avRecorder.state === 'paused') {
      // 录像中且暂停状态
    } else {
      await this.videoOutput.start();
    }
  }

  // 开启拍照预览
  async startPreviewWithPhoto() {
    this.cameraOutputCapability =
      CameraUtils.getSupportedOutputCapability(this.cameraDevice!, camera.SceneMode.NORMAL_PHOTO, this.cameraManager)
    let previewProfileIndex = this.cameraFeatures
                                  .getResolution()
                                  .getPreviewProfileIndex(this.cameraOutputCapability.previewProfiles);
    let previewSize: camera.Size = this.cameraOutputCapability.previewProfiles[previewProfileIndex].size;
    this.cameraFeatures.getResolution().setPreviewSize(previewSize);
    this.previewOutput = this.cameraManager.createPreviewOutput(
      this.cameraOutputCapability.previewProfiles[previewProfileIndex],
      this.flutterTexture.getSurfaceId().toString());
    let photoProfileIndex = this.cameraFeatures
                                .getResolution()
                                .getPhotoProfileIndex(this.cameraOutputCapability.photoProfiles);
    this.photoOutPut = this.cameraManager.createPhotoOutput(
      this.cameraOutputCapability.photoProfiles[photoProfileIndex]);

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
    this.getCurSession().setZoomRatio(this.nowZoom);
    await this.photoSession.start();

    await this.applyFlashMode(this.photoSession);

    if (this.pausedPreview) {
      await this.previewOutput.stop();
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
            Log.e(TAG, "convertBufferToFile failed: " + error.message)
          });
        }
      });
  }

  async convertBufferToFile(data: ArrayBuffer) {
    const photoUri: string = getContext(this).cacheDir + this.takePictureName;
    const file: fs.File = fs.openSync(photoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      await fs.write(file.fd, data);
      if (this.takePictureResult) {
        this.takePictureResult.success(photoUri);
        this.takePictureResult = undefined;
      }
    } catch (error) {
      this.takePictureResult?.error(
        "imageFileFormatEncodingFailed",
        error instanceof Error ? error.message : "Failed to write captured image.",
        null);
      this.takePictureResult = undefined;
      try {
        fs.unlinkSync(photoUri);
      } catch (cleanupError) {
        Log.e(TAG, "convertBufferToFile: failed to delete temp file: " + cleanupError.message);
      }
    } finally {
      fs.closeSync(file);
    }
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
      Log.e(TAG, "startImageStream: failed to stop photoSession: " + e.message);
    }
    try {
      if (this.videoSession != null) {
        await this.videoSession?.stop();
      }
    } catch (e) {
      Log.e(TAG, "startImageStream: failed to stop videoSession: " + e.message);
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
    await this.photoSession.start();
  }

  async prepareMediaRecorder(cameraManager: camera.CameraManager,
    cameraOutputCapability: camera.CameraOutputCapability, url: string) {
    Log.i(TAG, "prepareMediaRecorder");
    if (this.avRecorder != null) {
      await this.avRecorder.release();
    }
  }

  async startCapture(record: boolean, stream: boolean): Promise<void> {
    if (!this.pausedPreview) {
      await this.getCurSession().stop();
    }
    this.photoSession = null;
    this.isVideoMode = true;
    let that = this;
    return new Promise<void>((resolve, reject) => {
      media.createAVRecorder(async (error, recorder) => {
        if (recorder != null) {
          try {
            that.avRecorder = recorder;
            let videoUri: string = getContext(that).cacheDir + '/REC' + Date.now().toString() + '.mp4';
            that.captureFile = fs.openSync(videoUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
            let fd = that.captureFile.fd;
            let displayRotation = display.getDefaultDisplaySync().rotation * camera.ImageRotation.ROTATION_90;
            let previewRotation = that.previewOutput!.getPreviewRotation(displayRotation);

            that.cameraOutputCapability =
              CameraUtils.getSupportedOutputCapability(that.cameraDevice!, camera.SceneMode.NORMAL_VIDEO,
                that.cameraManager);
            let videoSessionProfile: VideoSessionProfile = that.cameraFeatures
              .getResolution()
              .getVideoSessionProfile(
                that.cameraOutputCapability.previewProfiles,
                that.cameraOutputCapability.videoProfiles);

            that.aVRecorderProfile.videoFrameWidth = videoSessionProfile.getCaptureProfile()?.size.width;
            that.aVRecorderProfile.videoFrameHeight = videoSessionProfile.getCaptureProfile()?.size.height;
            const avRecorderConfig = await that.getAVRecorderConfig(fd, previewRotation);
            await that.avRecorder.prepare(avRecorderConfig).then(async () => {
              that.videoId = await that.avRecorder?.getInputSurface();
            });

            let previewSize: camera.Size = videoSessionProfile.getPreviewProfile()!.size;
            that.cameraFeatures.getResolution().setPreviewSize(previewSize);
            that.previewOutput = that.cameraManager.createPreviewOutput(
              videoSessionProfile.getPreviewProfile(),
              that.flutterTexture.getSurfaceId().toString());
            that.videoOutput = that.cameraManager.createVideoOutput(
              videoSessionProfile.getCaptureProfile(),
              that.videoId);
            that.videoSession = that.cameraManager.createSession(camera.SceneMode.NORMAL_VIDEO) as camera.VideoSession;
            that.videoSession?.beginConfig();
            await that.cameraInput?.open();
            that.videoSession?.addInput(that.cameraInput);
            that.videoSession?.addOutput(that.previewOutput);
            if (stream && that.imageStreamReader != null) {
              let surfaceId: string = await that.imageStreamReader.getReceivingSurfaceId();
              that.previewOutput2 =
                that.cameraManager.createPreviewOutput(videoSessionProfile.getPreviewProfile(), surfaceId);
              that.videoSession.addOutput(that.previewOutput2);
            }
            that.videoSession?.addOutput(that.videoOutput);
            await that.videoSession?.commitConfig();
            that.getCurSession().setZoomRatio(that.nowZoom);
            await that.videoSession?.start();

            await that.applyFlashMode(that.videoSession!);

            await that.videoOutput.start();
            if (that.pausedPreview) {
              await that.previewOutput.stop();
            }
            if (record) {
              await that.avRecorder.start();
            }
            // 确保 avRecorder 状态真正准备好
            if (record && that.avRecorder.state !== 'started') {
              Log.w(TAG, "avRecorder is not in started state after start()");
            }
            resolve();
          } catch (e) {
            Log.e(TAG, "startAVRecorder error: " + e);
            reject(e);
          }
        } else {
          Log.e(TAG, "startVideo createAVRecorder fail :" + error.message);
          reject(error);
        }
      });
    });
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

  // 关闭
  public async close(): Promise<void> {
    if (this.isClosed) {
      return;
    }
    this.isClosed = true;
    await this.stopAndReleaseCamera();

    try {
      await this.avRecorder?.reset();
    } catch (resetError) {
      Log.d(TAG, "avRecorder reset error: " + resetError.toString());
    }
    try {
      await this.avRecorder?.release();
    } catch (releaseError) {
      Log.d(TAG, "avRecorder release error: " + releaseError.toString());
    }
    this.avRecorder = null;

    this.cameraDevice = null;

    this.dartMessenger.sendCameraClosingEvent();
  }

  // 关闭摄像头输入流
  private async stopAndReleaseCamera() {
    if (this.cameraInput != null) {
      try {
        this.photoSession?.removeInput(this.cameraInput);
      } catch (e) {
        Log.e(TAG, "stopAndReleaseCamera: failed to remove input from photoSession: " + e.message);
      }
      try {
        this.videoSession?.removeInput(this.cameraInput);
      } catch (e) {
        Log.e(TAG, "stopAndReleaseCamera: failed to remove input from videoSession: " + e.message);
      }
      try {
        this.cameraInput.close();
      } catch (e) {
        Log.e(TAG, "Failed to close cameraInput: " + e.toString());
      }

      this.cameraInput = null;
    }
    // 释放输出资源
    await this.releasePreviewOutput();
    await this.releaseVideoOutput();
    await this.releasePhotoOutput();
    // 停止并释放 session
    await this.releaseSession();

    if (this.cameraDevice != null) {
      this.cameraDevice = null;
    }
  }

  public setDescriptionWhileRecording(result: MethodResult, properties: CameraProperties) {
    result.error("error", "Camera switching is not supported while recording.", null);
    return;
  }

  async dispose() {
    console.error(TAG, 'dispose');
    await this.close();
    this.getDeviceOrientationManager().stop();
  }

  // 释放Session
  private async releaseSession() {
    if (this.photoSession != null) {
      try {
        await this.photoSession.stop();
      } catch (e) {
        Log.e(TAG, "releaseSession: failed to stop photoSession: " + e.message);
      }
      try {
        await this.photoSession.release();
      } catch (e) {
        Log.e(TAG, "releaseSession: failed to release photoSession: " + e.message);
      }
      this.photoSession = null;
    }
    if (this.videoSession != null) {
      try {
        await this.videoSession.stop();
      } catch (e) {
        Log.e(TAG, "releaseSession: failed to stop videoSession: " + e.message);
      }
      try {
        await this.videoSession.release();
      } catch (e) {
        Log.e(TAG, "releaseSession: failed to release videoSession: " + e.message);
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
        Log.e(TAG, "releaseCameraInput: failed to close cameraInput: " + e.message);
      }
    }
  }

  private async releasePreviewOutput() {
    if (this.previewOutput != null) {
      try {
        await this.previewOutput.release();
        this.previewOutput = null;
      } catch (e) {
        Log.e(TAG, "releasePreviewOutput: failed to release previewOutput: " + e.message);
      }
    }
    if (this.previewOutput2 != null) {
      try {
        await this.previewOutput2.release();
        this.previewOutput2 = null;
      } catch (e) {
        Log.e(TAG, "releasePreviewOutput: failed to release previewOutput2: " + e.message);
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
        Log.e(TAG, "releasePhotoOutput: failed to release photoOutput: " + e.message);
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
        Log.e(TAG, "releaseVideoOutput: failed to release videoOutput: " + e.message);
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
}
