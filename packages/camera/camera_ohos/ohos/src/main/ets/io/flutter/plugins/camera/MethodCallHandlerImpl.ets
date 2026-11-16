/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import camera from '@ohos.multimedia.camera';
import UIAbility from '@ohos.app.ability.UIAbility';
import { HashMap } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { BinaryMessenger, EventChannel, Log, MethodCall, TextureRegistry } from '@ohos/flutter_ohos';
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
  // Pending startImageStream deferred during a camera transition (create/initialize/dispose).
  // Holds the arrival-time textureId (the Dart cameraId): when the transition exits, the request is
  // executed only if that id still matches the current textureId, otherwise dropped silently —
  // the Dart side re-subscribes under the new cameraId and re-issues startImageStream itself.
  // Single slot (newest wins); cleared by stopImageStream (subscription gone) and dropped on
  // dispose completion.
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
          this.camera.releaseCamera();
        }
        if (this.textureId > -1) {
          this.unregisterTexture(this.textureId);
        }
        // 检查权限
        this.cameraPermissions.requestPermissions(
          this.context,
          call.argument('enableAudio'),
          (errCode: string | null, errDesc: string | null) => {
            if (errCode == null) {
              try {
                this.registerCameraTexture();
                this.instantiateCamera(call, result);
              } catch (e) {
                this.curStatus = STATUS.DEFAULT;
                this.handleException(e, result);
              }
            } else {
              this.curStatus = STATUS.DEFAULT;
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
            await this.camera.open(call.argument('imageFormatGroup'));
            this.curStatus = STATUS.DEFAULT;
            // Transition exit: run a pending deferred startImageStream now that the instance
            // settled. A failed open resolves normally after closing the instance, so the
            // closed-instance guard inside drops the request.
            this._evaluatePendingStartImageStream();
            result.success(null)
          } catch (e) {
            Log.e(TAG, 'initialize failed: ' + e.message);
            this.curStatus = STATUS.DEFAULT;
            // 先发送错误事件到 Dart 层
            this.camera?.dartMessenger.sendCameraErrorEvent(e.message);
            // 再关闭相机释放资源
            try {
              await this.camera?.close();
            } catch (closeError) {
              Log.e(TAG, 'close after initialize failed: ' + closeError.message);
            }
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
        let reset: number = call.argument('reset');
        let x: number | null = null;
        let y: number | null = null;
        if (reset == null || !reset) {
          x = call.argument("x");
          y = call.argument("y");
        }
        try {
          this.camera!.getFocusMode(result)
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
          // Mid-transition (create/initialize): defer instead of running against a half-built
          // instance — running here corrupts the camera service state (GetSupportedOutputCapability
          // parse error / cameraInput.open parameter error / 'Session not config' on the next open),
          // and an error reply would just surface as a new Dart-side dialog. Record a pending
          // request, evaluated when the transition exits (see _evaluatePendingStartImageStream);
          // reply success so the Dart future completes. DEFAULT-state null-camera still falls
          // through unchanged.
          if (this.curStatus != STATUS.DEFAULT) {
            this.pendingStartImageStream = this.textureId;
            Log.w(TAG, 'startImageStream: mid-transition, deferring (textureId=' + this.textureId + ')');
            result.success(null);
          } else {
            this.camera!.startPreviewWithImageStream(this.imageStreamChannel);
            result.success(null);
          }
        } catch (e) {
          this.handleException(e, result);
        }
        break;
      }
      case 'stopImageStream': {
        try {
          // A stop (subscription cancel) arriving while a start is pending makes the pending start
          // obsolete: the subscription is gone, so the transition exit must not start a stream nobody
          // listens to. Cleared in front of any guard so the cancel always wins.
          if (this.pendingStartImageStream != null) {
            this.pendingStartImageStream = null;
            Log.d(TAG, 'stopImageStream: cleared pending startImageStream (subscription cancelled)');
          }
          if (this.camera != null && !this.camera.isImageStreamActiveState()) {
            // Guard 1: a stop landing on the current instance with no active image stream (e.g.
            // a Dart-side subscription cancel reaching a freshly recreated instance after a
            // lifecycle recreate) is a no-op: neither stop nor preview restart applies, and
            // firing startPreview onto an instance whose open() is in flight raises 7400101
            // SERVICE_FATAL_ERROR.
            Log.d(TAG, 'stopImageStream: no active image stream, skipping');
            result.success(null);
          } else if (this.camera != null && this.curStatus != STATUS.DEFAULT) {
            // Guard 2: during create/initialize/dispose the in-flight transition's own flow starts
            // the preview when ready; the deferred restart here would race it on the same
            // cameraInput (7400101). Skip rather than defer: after initialize completes the preview
            // is already restarted by open() itself, so deferring would only add a redundant
            // restart.
            this.camera.clearImageStreamActiveState();
            Log.w(TAG, 'stopImageStream: mid-transition, skipping preview restart');
            result.success(null);
          } else {
            // Normal path (behavior unchanged): the restart IS the stop; the startPreview rebuild
            // replaces the stream session, so clear the marker up front so a back-to-back second
            // stop stays a no-op.
            this.camera!.clearImageStreamActiveState();
            this.camera!.startPreview();
            result.success(null);
          }
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
        try {
          let cameraName: string = call.argument('cameraName');
          let cameraProperties: CameraProperties =
            new CameraPropertiesImpl(cameraName, CameraUtils.getCameraManager(this.context));
          this.camera?.setDescriptionWhileRecording(result, cameraProperties);
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
        // A pending deferred startImageStream belongs to a subscription of the instance being
        // released (Dart cancels stream subscriptions on dispose); drop it so it cannot execute
        // after the instance is gone. A following create issues fresh requests under its new
        // cameraId.
        if (this.pendingStartImageStream != null) {
          this.pendingStartImageStream = null;
          Log.d(TAG, 'dispose: dropped pending startImageStream');
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
  // matching); otherwise dropped silently. Failures during execution are logged only — the original
  // call already replied success to Dart, so throwing here would just create the error surface the
  // deferral exists to avoid. A transition still in flight leaves the request pending for the next
  // exit point.
  private _evaluatePendingStartImageStream(): void {
    if (this.pendingStartImageStream == null) {
      return;
    }
    if (this.curStatus != STATUS.DEFAULT) {
      // Still mid-transition (e.g. a new create has already arrived): leave the request pending
      // for the next exit point.
      return;
    }
    const requestedTextureId: number | null = this.pendingStartImageStream;
    this.pendingStartImageStream = null;
    if (this.camera == null) {
      Log.d(TAG, 'startImageStream: pending request dropped: no camera instance');
      return;
    }
    if (this.camera.isClosedState()) {
      Log.d(TAG, 'startImageStream: pending request dropped: camera already closed (failed open)');
      return;
    }
    if (requestedTextureId !== this.textureId) {
      Log.d(TAG, 'startImageStream: pending request dropped: stale cameraId (requested ' +
        requestedTextureId + ', current ' + this.textureId + ')');
      return;
    }
    if (this.camera.isImageStreamActiveState()) {
      Log.d(TAG, 'startImageStream: pending request skipped: image stream already active');
      return;
    }
    try {
      this.camera.startPreviewWithImageStream(this.imageStreamChannel);
      Log.i(TAG, 'startImageStream: pending request executed after transition settled');
    } catch (e) {
      Log.e(TAG, 'startImageStream: pending request failed (logged only): ' + e.message);
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
        this.cameraPermissions,
        this.textureRegistry);

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