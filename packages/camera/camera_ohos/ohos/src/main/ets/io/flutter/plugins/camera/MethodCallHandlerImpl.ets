// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on MethodCallHandlerImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import camera from '@ohos.multimedia.camera';
import UIAbility from '@ohos.app.ability.UIAbility';
import { HashMap } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { BinaryMessenger, EventChannel, MethodCall, TextureRegistry } from '@ohos/flutter_ohos';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { Camera } from './Camera';
import { Point } from './features/Point';
import { CameraUtils } from './CameraUtils';
import { DartMessenger } from './DartMessenger';
import { CameraProperties } from './CameraProperties';
import { FlashMode } from './features/flash/FlashMode';
import { CameraPermissions } from './CameraPermissions';
import { FocusMode } from './features/autofocus/FocusMode';
import { CameraPropertiesImpl } from './CameraPropertiesImpl';
import { ExposureMode } from './features/exposurelock/ExposureMode';
import { CameraFeatureFactoryImpl } from './features/CameraFeatureFactoryImpl';
import { ResolutionPreset, ResolutionPreset_valueOf } from './types/ResolutionPreset';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';

const TAG: string = "MethodCallHandlerImpl";

const enum STATUS {
  DEFAULT,
  CREATE_ING,
  INITIALIZE_ING,
}

export class MethodCallHandlerImpl implements MethodCallHandler {
  private ability: UIAbility;
  private context: Context;
  private messenger: BinaryMessenger;
  private cameraPermissions: CameraPermissions;
  private textureRegistry: TextureRegistry;
  private methodChannel: MethodChannel;
  private imageStreamChannel: EventChannel;
  private camera: Camera | null = null;
  private flutterTexture: SurfaceTextureEntry | null = null;
  private textureId: number = -1;
  private curStatus: STATUS = STATUS.DEFAULT;
  // The in-flight release of the previous camera instance started by create. Rebuilding (open) must
  // wait for this to settle: a new open racing the still-running release leaves stale session/output
  // state at the camera service and surfaces as device OnError (7400103 'Session not config') on the
  // open chain when the rebuild lands mid-release (rapid toggles of the example's audio toggle).
  private pendingRelease: Promise<void> | null = null;
  // Pending startImageStream deferred during a camera transition (create/initialize). Holds the
  // arrival-time textureId (the Dart cameraId): when the transition exits, the request is executed
  // only if that id still matches the current textureId, otherwise dropped silently — the Dart
  // side re-subscribes under the new cameraId and re-issues startImageStream itself. Single
  // slot (newest wins); cleared by stopImageStream (subscription gone) and on dispose completion.
  private pendingStartImageStream: number | null = null;

  constructor(
    ability: UIAbility,
    messenger: BinaryMessenger,
    cameraPermissions: CameraPermissions,
    textureRegistry: TextureRegistry) {
    this.ability = ability;
    this.context = ability.context;
    this.messenger = messenger
    this.cameraPermissions = cameraPermissions;
    this.textureRegistry = textureRegistry;

    this.methodChannel = new MethodChannel(messenger, 'plugins.flutter.io/camera_ohos');
    this.imageStreamChannel =
      new EventChannel(messenger, 'plugins.flutter.io/camera_ohos/imageStream');
    this.methodChannel.setMethodCallHandler(this);
  }

  public async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    console.info(TAG, 'onMethodCall', call.method);
    switch (call.method) {
      case 'availableCameras': {
        try {
          result.success(CameraUtils.getAvailableCameras(this.context))
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'create': {
        if (this.curStatus != STATUS.DEFAULT) {
          result.success(null);
          return;
        }
        this.curStatus = STATUS.CREATE_ING;
        if (this.camera) {
          // Record the in-flight release so the rebuild below waits for it (see pendingRelease):
          // an unawaited release races the new instance's open at the camera service.
          this.pendingRelease = this.camera.releaseCamera();
        }
        if (this.textureId > -1) {
          this.unregisterTexture(this.textureId);
        }
        // 检查权限
        this.cameraPermissions.requestPermissions(
          this.context,
          call.argument('enableAudio'),
          async (errCode: string | null, errDesc: string | null) => {
            if (errCode == null) {
              try {
                // Serialize the rebuild behind the previous instance's release (see pendingRelease).
                // Timeout guard: a wedged release must not block the rebuild forever.
                if (this.pendingRelease != null) {
                  try {
                    await Promise.race([
                      this.pendingRelease,
                      new Promise<void>((resolve: () => void) => setTimeout(resolve, 2000)),
                    ]);
                  } catch (e) {
                    console.error(TAG, 'create: waiting for the previous release failed: ' + (e as Error).message);
                  }
                  this.pendingRelease = null;
                  // Grace period after the release promise settles: the camera service tears the
                  // old session/device down asynchronously, so the client-side IPC returning does
                  // NOT mean the service-side resources have landed. Reopening inside that window
                  // surfaces as device OnError (7400103 'Session not config'). A short fixed delay
                  // keeps the new open clear of the teardown; it only applies when an actual
                  // release happened, so first-time create stays immediate.
                  await new Promise<void>((resolve: () => void) => setTimeout(resolve, 300));
                }
                this.registerCameraTexture();
                this.instantiateCamera(call, result);
              } catch (e) {
                this.curStatus = STATUS.DEFAULT;
                this.handleException(e, result);
              }
            } else {
              this.curStatus = STATUS.DEFAULT;
              // The rebuild is aborted; drop the recorded release reference (the release itself
              // already ran, so an already-settled promise reference is just stale state).
              this.pendingRelease = null;
              result.error(errCode, errDesc, null);
            }
          }
        );
        break;
      }
      case 'initialize':
        this.curStatus = STATUS.INITIALIZE_ING;
        if (this.camera != null) {
          try {
            this.camera.open(call.argument('imageFormatGroup')).then(() => {
              this.curStatus = STATUS.DEFAULT;
              // Transition exit: run a pending deferred startImageStream once the instance settled.
              this.evaluatePendingStartImageStream();
              result.success(null);
            }).catch(async (e: BusinessError) => {
              console.error(TAG, 'initialize failed: ' + e.message);
              this.curStatus = STATUS.DEFAULT;
              // Report error to Dart side first (before close sends closing event)
              this.handleException(e, result);
              // Then close camera to release resources
              try {
                await this.camera!.close();
              } catch (closeError) {
                console.error(TAG, 'close after initialize failed: ' + closeError.message);
              }
            });
          } catch (e) {
            this.curStatus = STATUS.DEFAULT;
            this.handleException(e, result)
          }
        } else {
          this.curStatus = STATUS.DEFAULT;
          result.error(
            "cameraNotFound",
            "Camera Not found. Please call the 'create' method before calling 'initialize",
            null);
        }
        break;
      case 'takePicture':
        this.camera!.takePicture(result);
        break;
      case 'prepareForVideoRecording': {
        result.success(null);
        break;
      }
      case 'startVideoRecording': {
        let enableStream = call.argument('enableStream') as boolean;
        this.camera!.startVideoRecording(result, enableStream ? this.imageStreamChannel : null);
        break;
      }
      case 'stopVideoRecording': {
        this.camera!.stopVideoRecording(result);
        break;
      }
      case 'pauseVideoRecording': {
        this.camera!.pauseVideoRecording(result);
        break;
      }
      case 'resumeVideoRecording': {
        {
          this.camera!.resumeVideoRecording(result);
          break;
        }
      }
      case 'setFlashMode': {
        let modeStr: string = call.argument("mode");
        let mode: camera.FlashMode | null = FlashMode.getValueForString(modeStr);
        if (mode == null) {
          result.error("setFlashModeFailed", "Unknown flash mode " + modeStr, null);
          return;
        }
        try {
          this.camera!.setFlashMode(result, mode);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setExposureMode': {
        let modeStr: string = call.argument('mode');
        let mode: camera.ExposureMode | null = ExposureMode.getValueForString(modeStr);
        if (mode == null) {
          result.error("setExposureModeFailed", "Unknown exposure mode " + modeStr, null);
          return;
        }
        try {
          this.camera!.setExposureMode(result, mode);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setExposurePoint': {
        if (this.camera == null) {
          result.error('EXPOSURE_POINT_ERROR', 'Camera not initialized', null);
          return;
        }
        let reset: number = call.argument('reset');
        let x: number | null = null;
        let y: number | null = null;
        if (reset == null || !reset) {
          x = call.argument("x");
          y = call.argument("y");
        }
        try {
          this.camera!.setExposurePoint(result, new Point(x, y));
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'getMinExposureOffset': {
        try {
          let mixExposureOffset: number = this.camera!.getMinExposureOffset();
          result.success(mixExposureOffset);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'getMaxExposureOffset': {
        try {
          let maxExposureOffset: number = this.camera!.getMaxExposureOffset();
          result.success(maxExposureOffset);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'getExposureOffsetStepSize': {
        try {
          let exposureOffsetStepSize: number = this.camera!.getExposureOffsetStepSize();
          result.success(exposureOffsetStepSize);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setExposureOffset': {
        try {
          this.camera!.setExposureOffset(result, call.argument("offset"));
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setFocusMode': {
        let modeStr: string = call.argument('mode');
        let mode: camera.FocusMode | null = FocusMode.getValueForString(modeStr);
        if (mode == null) {
          result.error("setFocusModeFailed", "Unknown focus mode " + modeStr, null);
          return;
        }
        try {
          this.camera!.setFocusMode(result, mode);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setFocusPoint': {
        let reset: number = call.argument('reset');
        let x: number | null = null;
        let y: number | null = null;
        if (reset == null || !reset) {
          x = call.argument('x');
          y = call.argument('y');
        }
        try {
          this.camera!.setFocusPoint(result, new Point(x, y));
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'startImageStream': {
        try {
          // Mid-transition (create/initialize): running here would execute against a half-open
          // instance and corrupt the camera service state (GetSupportedOutputCapability parse
          // error / 'Session not config' on the next open). Defer instead of running or erroring:
          // record the arrival-time textureId, re-evaluated when the transition exits (see
          // evaluatePendingStartImageStream). The request still replies success to Dart — the
          // subscription exists, the stream starts once the instance settles. DEFAULT-state
          // null-camera still fails below unchanged.
          if (this.curStatus != STATUS.DEFAULT) {
            this.pendingStartImageStream = this.textureId;
            console.info(TAG, 'startImageStream: mid-transition, deferring (textureId=' + this.textureId + ')');
            result.success(null);
            return;
          }
          this.camera!.startPreviewWithImageStream(this.imageStreamChannel);
          result.success(null);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'stopImageStream': {
        try {
          // A stop (subscription cancel) arriving while a start is pending makes the pending start
          // obsolete: the subscription is gone, so the transition exit must not start a stream nobody
          // listens to. Cleared before any guard so the cancel always wins.
          if (this.pendingStartImageStream != null) {
            this.pendingStartImageStream = null;
            console.info(TAG, 'stopImageStream: cleared pending startImageStream (subscription cancelled)');
          }
          // Guard 1: a stop landing on the current instance with no active image stream (e.g.
          // a Dart-side subscription cancel reaching a freshly recreated instance after a
          // lifecycle recreate) is a no-op: neither stop nor preview restart applies, and
          // firing startPreview onto an instance whose open() is in flight raises 7400101
          // SERVICE_FATAL_ERROR.
          if (this.camera != null && !this.camera.isImageStreamActiveState()) {
            console.info(TAG, 'stopImageStream: no active image stream, skipping');
            result.success(null);
            return;
          }
          // Guard 2: during create/initialize the in-flight transition's own open() restarts the
          // preview when it lands; the deferred startPreview here would race it on the same
          // cameraInput (7400101). We skip rather than defer: once the transition exits, the
          // preview is already restarted by open() itself, so deferring would only add a
          // redundant restart.
          if (this.curStatus != STATUS.DEFAULT) {
            // The chained dispose can already have released the camera (the null window
            // between dispose and create): a no-op keeps the normal Dart reply instead of
            // relying on a TypeError thrown by the non-null assertion.
            if (this.camera == null) {
              result.success(null);
              return;
            }
            this.camera.clearImageStreamActiveState();
            console.info(TAG, 'stopImageStream: mid-transition, skipping preview restart');
            result.success(null);
            return;
          }
          // Normal path (behavior unchanged): the restart IS the stop; the startPreview rebuild
          // replaces the stream session, so clear the marker up front so a back-to-back second
          // stop stays a no-op.
          if (this.camera == null) {
            result.success(null);
            return;
          }
          this.camera.clearImageStreamActiveState();
          this.camera.startPreview();
          result.success(null);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'getMaxZoomLevel': {
        if (this.camera == null) {
          return;
        }
        try {
          let maxZoomLevel: number = this.camera!.getMaxZoomLevel();
          result.success(maxZoomLevel);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'getMinZoomLevel': {
        if (this.camera == null) {
          return;
        }
        try {
          let minZoomLevel: number = this.camera!.getMinZoomLevel();
          result.success(minZoomLevel);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'setZoomLevel': {
        if (this.camera == null) {
          return;
        }
        let zoom: number | null = call.argument('zoom');
        if (zoom == null) {
          result.error(
            "ZOOM_ERROR", "setZoomLevel is called without specifying a zoom level.", null);
          return;
        }

        try {
          this.camera.setZoomLevel(result, zoom);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'lockCaptureOrientation': {
        let orientation: DeviceOrientation =
          CameraUtils.deserializeDeviceOrientation(call.argument("orientation"));
        try {
          this.camera!.lockCaptureOrientation(orientation);
          result.success(null);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'unlockCaptureOrientation': {
        try {
          this.camera!.unlockCaptureOrientation();
          result.success(null);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'pausePreview': {
        try {
          this.camera!.pausePreview(result);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'resumePreview': {
        try {
          this.camera!.resumePreview(result);
        } catch (e) {
          this.handleException(e, result);
        }
      }
        break;
      case 'setDescriptionWhileRecording': {
        if (this.camera == null) {
          result.error('DESCRIPTION_ERROR', 'Camera not initialized', null);
          return;
        }
        try {
          let cameraName: string = call.argument('cameraName');
          let cameraProperties: CameraProperties =
            new CameraPropertiesImpl(cameraName, CameraUtils.getCameraManager(this.context));
          this.camera.setDescriptionWhileRecording(result, cameraProperties);
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'dispose': {
        this.unregisterTexture(call.argument('cameraId'));
        if (this.camera) {
          try {
            await this.camera.close();
          } catch (closeError) {
            console.error(`Failed to close camera: ${closeError}`);
          }
          try {
            await this.camera.dispose();
          } catch (disposeError) {
            console.error(`Failed to dispose camera: ${disposeError}`);
          }
          this.camera = null;
        }
        // A pending deferred startImageStream belongs to a subscription of the released instance
        // (Dart cancels stream subscriptions on dispose); drop it so it cannot execute after the
        // instance is gone. A following create issues fresh requests under its new cameraId.
        if (this.pendingStartImageStream != null) {
          this.pendingStartImageStream = null;
          console.info(TAG, 'dispose: dropped pending startImageStream');
        }
        result.success(null);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  // Evaluates the pending deferred startImageStream (see pendingStartImageStream): runs only when
  // the instance has settled (DEFAULT state, camera present, request's arrival-time textureId still
  // matching); otherwise dropped silently. Failures are logged only — the original call already
  // replied success to Dart, so throwing here would just create the error surface the deferral
  // exists to avoid. A transition still in flight leaves the request pending for the next exit point.
  private evaluatePendingStartImageStream(): void {
    if (this.pendingStartImageStream == null) {
      return;
    }
    if (this.curStatus != STATUS.DEFAULT) {
      // Still mid-transition: leave the request pending for the next exit point.
      return;
    }
    const requestedTextureId: number | null = this.pendingStartImageStream;
    this.pendingStartImageStream = null;
    if (this.camera == null) {
      console.info(TAG, 'startImageStream: pending request dropped: no camera instance');
      return;
    }
    if (requestedTextureId !== this.textureId) {
      console.info(TAG, 'startImageStream: pending request dropped: stale cameraId (requested ' +
        requestedTextureId + ', current ' + this.textureId + ')');
      return;
    }
    if (this.camera.isImageStreamActiveState()) {
      console.info(TAG, 'startImageStream: pending request skipped: image stream already active');
      return;
    }
    try {
      this.camera.startPreviewWithImageStream(this.imageStreamChannel);
      console.info(TAG, 'startImageStream: pending request executed after transition settled');
    } catch (e) {
      console.error(TAG, 'startImageStream: pending request failed (logged only): ' + (e as Error).message);
    }
  }

  private registerCameraTexture(): void {
    this.textureId = this.textureRegistry.getTextureId();
    this.flutterTexture = this.textureRegistry.registerTexture(this.textureId);
  }

  private unregisterTexture(textureId: number): void {
    this.textureRegistry!.unregisterTexture(textureId);
    this.textureId = -1;
  }

  stopListening(): void {
    this.methodChannel.setMethodCallHandler(null);
  }

  private instantiateCamera(call: MethodCall, result: MethodResult): void {
    let cameraName: string = call.argument('cameraName');
    let preset: string = call.argument('resolutionPreset');
    let enableAudio: boolean = call.argument('enableAudio');

    const dartMessenger: DartMessenger =
      new DartMessenger(this.messenger, this.textureId);
    const cameraProperties: CameraProperties =
      new CameraPropertiesImpl(cameraName, CameraUtils.getCameraManager(this.context));
    const resolutionPreset: ResolutionPreset = ResolutionPreset_valueOf(preset);

    this.camera =
      new Camera(
        this.ability,
        this.flutterTexture!,
        new CameraFeatureFactoryImpl(),
        dartMessenger,
        cameraProperties,
        resolutionPreset,
        enableAudio,
        this.cameraPermissions);

    const reply: HashMap<String, Object> = new HashMap();
    reply.set('cameraId', this.textureId);
    result.success(reply);
  }

  private handleException(error: BusinessError, result: MethodResult): void {
    if (Object.values(camera.CameraErrorCode).includes(error.code)) {
      result.error("CameraError", error.message, null);
      return;
    }
    throw error as Error;
  }
}