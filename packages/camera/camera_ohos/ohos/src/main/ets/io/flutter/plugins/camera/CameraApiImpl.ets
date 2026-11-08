/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BinaryMessenger, EventChannel, Log, MethodResult, TextureRegistry } from '@ohos/flutter_ohos';
import Any from '@ohos/flutter_ohos/src/main/ets/plugin/common/Any';
import {
  CameraApi,
  CameraEventApi,
  FlutterError,
  PlatformCameraDescription,
  PlatformCameraLensDirection,
  PlatformDeviceOrientation,
  PlatformExposureMode,
  PlatformFlashMode,
  PlatformFocusMode,
  PlatformImageFileFormat,
  PlatformImageFormatGroup,
  PlatformMediaSettings,
  PlatformPoint,
  PlatformVideoStabilizationMode,
  Result
} from './Messages';
import { CameraUtils } from './CameraUtils';
import { FlashMode } from './features/flash/FlashMode';
import { ExposureMode } from './features/exposurelock/ExposureMode';
import { Point } from './features/Point';
import { Camera } from './Camera';
import { DeviceZslVersionGate, ZslVersionGate } from './ZslCapability';
import { CameraPermissions } from './CameraPermissions';
import { DartMessenger } from './DartMessenger';
import { CameraProperties } from './CameraProperties';
import { CameraPropertiesImpl } from './CameraPropertiesImpl';
import { CameraFeatureFactoryImpl } from './features/CameraFeatureFactoryImpl';
import { ResolutionPreset, ResolutionPreset_valueOf } from './types/ResolutionPreset';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { HashMap } from '@kit.ArkTS';
import camera from '@ohos.multimedia.camera';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';

const TAG: string = 'CameraApiImpl';

const enum STATUS {
  DEFAULT,
  CREATE_ING,
  INITIALIZE_ING,
}

enum CAMERA {
  Back = 'back',
  Front = 'front',
  External = 'external',
}

// Defines the parameter object interface.
interface InitializeParams {
  imageFormatGroup: PlatformImageFormatGroup;
}

interface OrientationParams {
  orientation: string;
}

interface FlashModeParams {
  mode: string;
}

interface ExposureModeParams {
  mode: string;
}

interface ExposurePointParams {
  x: number;
  y: number;
}

interface VideoRecordingParams {
  enableStream: boolean;
}

interface ZoomParams {
  zoom: number;
}

interface ExposureOffsetParams {
  offset: number;
}

interface FocusModeParams {
  mode: string;
}

interface FocusPointParams {
  x?: number;
  y?: number;
  reset?: boolean;
}

interface CameraNameParams {
  cameraName: string;
}

interface DisposeParams {
  cameraId: number;
}

// Defines an interface to work around typing issues.
interface CallArgument {
  argument(key: string): string | number | boolean | null;
}

interface ResultCallback {
  success(cameraId: number): void;
  error(errorCode: string, errorMessage: string, errorDetails: Object): void;
}
// Add MethodResult interface for object literals
// Rename to avoid conflict with imported MethodResult
interface CameraMethodResult {
  success: (value: Any) => void;
  error: (errorCode: string, errorMessage: string, errorDetails: Any) => void;
  notImplemented: () => void;
}

export class CameraApiImpl extends CameraApi {
  private currentFps = 30;
  private currentVideoBitrate = 100000000;
  private currentAudioBitrate = 48000;

  getMinExposureOffset(): number {
    if (this.camera == null) {
      throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
    }
    return this.camera!.getMinExposureOffset();
  }

  getMaxExposureOffset(): number {
    if (this.camera == null) {
      throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
    }
    return this.camera!.getMaxExposureOffset();
  }

  getExposureOffsetStepSize(): number {
    if (this.camera == null) {
      throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
    }
    return this.camera!.getExposureOffsetStepSize();
  }
  // Fix method signature to match CameraApi interface
  async pausePreview(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error(`pausePreview error: ${errorCode}: ${errorMessage}`);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('pausePreview not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'pausePreview not implemented',
                'pausePreview not implemented', ''));
          }
        };
        this.camera.pausePreview(methodResult);
      } catch (error) {
        console.error('PAUSE_PREVIEW_ERROR: Failed to pause preview');
        reject(error);
      }
    });
  }

  // Fix method signature to match CameraApi interface
  async resumePreview(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error(`resumePreview error: ${errorCode}: ${errorMessage}`);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('resumePreview not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'resumePreview not implemented',
                'resumePreview not implemented', ''));
          }
        };
        this.camera.resumePreview(methodResult);
      } catch (error) {
        console.error('RESUME_PREVIEW_ERROR: Failed to resume preview');
        reject(error);
      }
    });
  }
  getMaxZoomLevel(): number {
    if (this.camera == null) {
      throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
    }
    return this.camera!.getMaxZoomLevel();
  }

  getMinZoomLevel(): number {
    if (this.camera == null) {
      throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
    }
    return this.camera!.getMinZoomLevel();
  }

  setFocusPoint(point: PlatformPoint | null, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('FOCUS_POINT_ERROR', 'Camera not initialized', 'Camera not initialized', ''));
        return;
      }
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('FOCUS_POINT_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      if (point == null) {
        this.camera!.setFocusPoint(methodResult, new Point(null, null));
      } else {
        this.camera!.setFocusPoint(methodResult, new Point(point.getX(), point.getY()));
      }
    } catch (error) {
      result.error(new FlutterError('FOCUS_POINT_ERROR', 'Failed to set focus point', 'Failed to set focus point', ''));
    }
  }

  async setDescriptionWhileRecording(description: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('setDescriptionWhileRecording success');
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error(`setDescriptionWhileRecording error: ${errorCode}: ${errorMessage}`);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('setDescriptionWhileRecording not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'setDescriptionWhileRecording not implemented',
                'setDescriptionWhileRecording not implemented', ''));
          }
        };
        const cameraProperties: CameraProperties = new CameraPropertiesImpl(description,
            CameraUtils.getCameraManager(this.context));
        this.camera.setDescriptionWhileRecording(methodResult, cameraProperties);
      } catch (error) {
        console.error('DESCRIPTION_ERROR: Failed to set description while recording');
        reject(error);
      }
    });
  }
  private binaryMessenger: BinaryMessenger;
  private context: common.Context;
  private ability: UIAbility;
  private textureRegistry: TextureRegistry;
  private imageStreamChannel: EventChannel;

  // Properties ported from MethodCallHandlerImpl.
  private cameraPermissions: CameraPermissions;
  private camera: Camera | null = null;
  private flutterTexture: SurfaceTextureEntry | null = null;
  private textureId: number = -1;
  private curStatus: STATUS = STATUS.DEFAULT;
  // Disposed flag: set after dispose() so create's late permission callbacks cannot rebuild after release.
  private disposed: boolean = false;
  private currentImageFormat: string = 'jpeg';
  private currentResolutionPreset: ResolutionPreset = ResolutionPreset.medium;
  private currentEnableAudio: boolean = false;
  // Session-level cache for JPEG quality / image file format: camera switching creates a fresh Camera
  // instance (jpegQuality/imageFileFormat reset to defaults); the latest values are cached here and
  // replayed onto each new Camera so quality stays effective across switches.
  private currentJpegQuality: number | null = null;
  private currentImageFileFormat: PlatformImageFileFormat = PlatformImageFileFormat.jpeg;
  // Zero-shutter-lag request state (see Camera.zeroShutterLagRequested); cached here so it
  // can be replayed onto Camera instances recreated by camera switching. On pre-API 21
  // runtimes the gate short-circuit below never records the request, so the replay stays
  // silent instead of triggering a doomed symbol access on every camera switch.
  private zeroShutterLagRequested: boolean = false;
  // ZSL API version gate; injectable so tests can fake pre-API 21 runtimes.
  private zslGate: ZslVersionGate = new DeviceZslVersionGate();
  private cameraIdPositionMap: Map<string, camera.CameraPosition> = new Map();
  private isSwitchingCamera: boolean = false;
  // Deferred preview restart fired by stopImageStream (un-awaited); the camera
  // switch path awaits it so the restart does not overlap the old instance's
  // teardown inside the camera service.
  private pendingPreviewRestart: Promise<void> | null = null;

  private _disposeTimerId: number = -1;
  private static readonly DISPOSE_GRACE_MS: number = 800;

  constructor(ability: UIAbility, binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry,
    zslGate?: ZslVersionGate) {
    super();
    this.ability = ability;
    this.context = ability.context;
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
    this.imageStreamChannel = new EventChannel(binaryMessenger, 'plugins.flutter.io/camera_ohos/imageStream');
    this.cameraPermissions = new CameraPermissions();
    // ZSL gate injection: the default production gate reads sdkApiVersion once; tests
    // inject a fake gate to simulate pre-API 21 runtimes without a real low-API device.
    if (zslGate) {
      this.zslGate = zslGate;
    }

    // Ensure the status is correctly initialized.
    this.curStatus = STATUS.DEFAULT;
    this.textureId = -1;
    this.camera = null;
    this.flutterTexture = null;
  }

  // Implements create to match the CameraApi interface with enhanced error handling.
  async create(cameraName: string, mediaSettings: PlatformMediaSettings, result: Result<number>): Promise<void> {
    try {
      this._cancelPendingDispose();
      this.disposed = false;   // Reset the disposed flag to allow re-creation

      console.log('mediaSettings:', JSON.stringify(mediaSettings));

      if (this.curStatus != STATUS.DEFAULT) {
        result.error(new FlutterError('CREATE_ERROR', 'Camera create is already in progress',
            'Camera create is already in progress', ''));
        return;
      }
      this.curStatus = STATUS.CREATE_ING;

      if (this.camera) {
        // releaseCamera does not stop the DeviceOrientationManager display listener;
        // dispose() is the full release entry.
        await this.camera.dispose();
      }
      // On camera switch the old stream handler closure holds the old Camera; unbind it explicitly to cut the
      // reference chain. The new camera re-registers the handler on startVideoRecording/startPreviewWithImageStream.
      try {
        this.imageStreamChannel.setStreamHandler(null);
      } catch (handlerError) {
        Log.e(TAG, 'create: failed to clear image stream handler: ' + (handlerError as Error).message);
      }
      if (this.textureId > -1) {
        this.unregisterTexture(this.textureId);
      }

      // Check permissions
      this.cameraPermissions.requestPermissions(
        this.context,
        mediaSettings.getEnableAudio(),
        (errCode: string | null, errDesc: string | null) => {

          if (errCode == null) {
            // Late permission callback: dispose() already released resources; fail fast instead of
            // rebuilding the camera on a released context
            if (this.disposed) {
              this.curStatus = STATUS.DEFAULT;
              result.error(new FlutterError('CREATE_ERROR', 'CameraPlugin disposed during permission request',
                  'CameraPlugin disposed during permission request', ''));
              return;
            }
            try {

              this.registerCameraTexture();


              // Create the camera instance
              class CallArgumentImpl implements CallArgument {
                argument(key: string): string | number | boolean | null {
                  switch (key) {
                    case 'cameraName': return cameraName;
                    case 'resolutionPreset': return mediaSettings.getResolutionPreset();
                    case 'fps': return mediaSettings.getFps();
                    case 'videoBitrate': return mediaSettings.getVideoBitrate();
                    case 'audioBitrate': return mediaSettings.getAudioBitrate();
                    case 'enableAudio': return mediaSettings.getEnableAudio();
                    default: return null;
                  }
                }
              }
              const call: CallArgument = new CallArgumentImpl();



              this.instantiateCamera(call, result);
            } catch (e) {

              this.curStatus = STATUS.DEFAULT;
              // registerCameraTexture succeeded but instantiateCamera threw: roll back the texture so the
              // failure path matches the dispose path and avoids texture leaks
              if (this.textureId > -1) {
                try {
                  this.unregisterTexture(this.textureId);
                } catch (rollbackError) {
                  Log.e(TAG, 'create: failed to rollback texture: ' + (rollbackError as Error).message);
                }
              }
              this.flutterTexture = null;
              result.error(new FlutterError('CREATE_ERROR', (e as Error).message, (e as Error).message, ''));
            }
          } else {

            this.curStatus = STATUS.DEFAULT;
            result.error(new FlutterError(errCode, errDesc??'', errDesc??'', ''));
          }
        }
      ).catch((e: Error): void => {
        Log.e(TAG, 'requestPermissions rejected: ' + e.message);
        this.curStatus = STATUS.DEFAULT;
        result.error(new FlutterError('CREATE_ERROR', e.message, e.message, ''));
      });
    } catch (error) {

      this.curStatus = STATUS.DEFAULT;
      result.error(new FlutterError('CREATE_ERROR', (error as Error).message, (error as Error).message, ''));
    }
  }


  getAvailableCameras(): PlatformCameraDescription[] {
    try {
      try {
        const cameraManager = CameraUtils.getCameraManager(this.context);
        const devices = cameraManager.getSupportedCameras();
        for (const d of devices) {
          this.cameraIdPositionMap.set(d.cameraId, d.cameraPosition);
        }
      } catch (e) {
        Log.w(TAG, 'getAvailableCameras: failed to update cameraIdPositionMap: ' + e.message);
      }
      const cameras = CameraUtils.getAvailableCameras(this.context);
      return cameras.map(cameraMap => {
        const name = cameraMap.get('name') as string || '';
        const lensFacing = cameraMap.get('lensFacing')
        let lensDirection:PlatformCameraLensDirection = PlatformCameraLensDirection.back
        if (lensFacing === CAMERA.Back) {
          lensDirection = PlatformCameraLensDirection.back;
        } else if (lensFacing === CAMERA.Front) {
          lensDirection = PlatformCameraLensDirection.front;
        } else if (lensFacing === CAMERA.External) {
          lensDirection = PlatformCameraLensDirection.external;
        }
        const sensorOrientation = cameraMap.get('sensorOrientation') as number || 0;

        return new PlatformCameraDescription(name, lensDirection, sensorOrientation);
      });
    } catch (error) {
      console.error('getAvailableCameras error:', error);
      // No swallow-and-degrade: rethrow to the Pigeon wrapper (try/catch + wrapError in Messages.ets setUp)
      // which converts it to a PlatformException.
      throw error as Error;
    }
  }

  private resolveCurrentCameraId(requestedCameraId: string): string {
    let currentDevices: camera.CameraDevice[] = [];
    try {
      const cameraManager = CameraUtils.getCameraManager(this.context);
      currentDevices = cameraManager.getSupportedCameras();
    } catch (e) {
      Log.w(TAG, 'resolveCurrentCameraId: getSupportedCameras failed: ' + e.message);
      return requestedCameraId;
    }
    if (currentDevices.some((d: camera.CameraDevice) => d.cameraId === requestedCameraId)) {
      return requestedCameraId;
    }
    const desiredPosition = this.cameraIdPositionMap.get(requestedCameraId);
    if (desiredPosition === undefined) {
      Log.w(TAG, `resolveCurrentCameraId: unknown camera ID '${requestedCameraId}', using as-is`);
      return requestedCameraId;
    }
    const matchingDevice = currentDevices.find((d: camera.CameraDevice) => d.cameraPosition === desiredPosition);
    if (matchingDevice) {
      Log.i(TAG, `resolveCurrentCameraId: resolved stale ID '${requestedCameraId}'` +
        ` (position=${desiredPosition}) → '${matchingDevice.cameraId}'`);
      return matchingDevice.cameraId;
    }
    Log.w(TAG, `resolveCurrentCameraId: no camera found for position` +
      ` ${desiredPosition}, using original ID '${requestedCameraId}'`);
    return requestedCameraId;
  }

  // Enhanced error handling for the initialize method.
  async initialize(imageFormat: PlatformImageFormatGroup): Promise<void> {
    this._cancelPendingDispose();

    this.curStatus = STATUS.INITIALIZE_ING;
    if (this.camera != null) {
      const imageFormatString = PlatformImageFormatGroup[imageFormat];
      this.currentImageFormat = imageFormatString;
      // Camera-switch contention retry: when this initialize races the previous
      // instance's native teardown, open() can fail with 'Camera service fatal
      // error' even after the 100ms settle delay on devices whose native release
      // takes longer than the settle window. Wait and retry once on the same
      // instance before giving up; non-contention failures retry nothing.
      const maxAttempts: number = 2;
      let lastErrorMessage: string = '';
      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          await this.camera.open(imageFormatString);
          this.curStatus = STATUS.DEFAULT;
          return;
        } catch (e) {
          const err = e as Error;
          const isContention = err.message.includes('Camera service fatal error');
          Log.e(TAG, 'initialize: open attempt ' + attempt + '/' + maxAttempts +
            (isContention ? ' (contention)' : '') + ' failed: ' + err.message);
          lastErrorMessage = err.message;
          if (attempt < maxAttempts && isContention) {
            // Defense-in-depth: reopening a torn-down (isClosed) camera is a silent
            // no-op by design, which would fake a success. Skip the retry if the
            // instance ended up closed despite the non-self-closing cleanup above.
            if (this.camera.isClosedState()) {
              Log.e(TAG, 'initialize: camera closed after failed open, skip contention retry');
              break;
            }
            // Let the camera service drain the previous session's async teardown,
            // then reopen on the same instance.
            await new Promise<void>((resolve: () => void) => { setTimeout(resolve, 300); });
          }
        }
      }
      // All attempts failed: close to release resources (Camera.close has an isClosed
      // guard, so repeat calls are safe); the error reaches Dart solely via the Pigeon
      // error reply (single-channel convention: the throwing path must not also emit
      // an event, otherwise Dart-side initializeCamera would double-complete its
      // completer and throw StateError).
      this.curStatus = STATUS.DEFAULT;
      try {
        await this.camera.close();
      } catch (closeError) {
        Log.e(TAG, 'close after initialize failed: ' + closeError.message);
      }
      throw new FlutterError('CameraError', lastErrorMessage, lastErrorMessage, '');
    } else {
      // With this.camera == null there is no cameraId suffix, so events would go to a bare channel with
      // no listener; report the error to the caller only by throwing (wrapError -> Dart PlatformException).
      this.curStatus = STATUS.DEFAULT;
      throw new FlutterError('cameraNotFound',
          'Camera not found. Please call the \'create\' method before calling \'initialize\'.',
          'Camera not found. Please call the \'create\' method before calling \'initialize\'.', '');
    }
  }

  // Enhanced error handling for the dispose method.
  async dispose(): Promise<void> {
    if (this._disposeTimerId !== -1) {
      Log.w(TAG, 'dispose: already pending, ignoring');
      return;
    }
    this._disposeTimerId = setTimeout((): void => {
      this._disposeTimerId = -1;
      this._doRealDispose();
    }, CameraApiImpl.DISPOSE_GRACE_MS);
    Log.w(TAG, `dispose: deferred ${CameraApiImpl.DISPOSE_GRACE_MS}ms (lifecycle jitter grace window)`);
  }

  private _cancelPendingDispose(): void {
    if (this._disposeTimerId !== -1) {
      clearTimeout(this._disposeTimerId);
      this._disposeTimerId = -1;
      Log.w(TAG, 'dispose: cancelled by initialize/create (resumed reinit)');
    }
  }

  async disposeImmediately(): Promise<void> {
    this._cancelPendingDispose();
    await this._doRealDispose();
  }

  private async _doRealDispose(): Promise<void> {
    const cam = this.camera;
    try {
      this.disposed = true;   // Mark as disposed to guard create's late permission callbacks
      // Stop the camera first
      if (cam) {
        try {
          await cam.close();
        } catch (closeError) {
          console.error(`Failed to close camera: ${closeError}`);
        }
        try {
          await cam.dispose();
        } catch (disposeError) {
          console.error(`Failed to dispose camera: ${disposeError}`);
        }
      }
      if (this.camera === cam) {
        this.camera = null;
        if (this.textureId > -1) {
          try {
            this.unregisterTexture(this.textureId);
          } catch (textureError) {
            console.error(`Failed to unregister texture: ${textureError}`);
          }
        }
      } else {
        Log.w(TAG, '_doRealDispose: camera replaced during await, keeping new camera');
      }
      // Unbind the image stream EventChannel handler to cut the closure-held reference to Camera
      // (prevents leaks from Dart-side lingering subscriptions).
      try {
        this.imageStreamChannel.setStreamHandler(null);
      } catch (streamHandlerError) {
        console.error(`Failed to clear image stream handler: ${streamHandlerError}`);
      }
      this.flutterTexture = null;         // Release the SurfaceTextureEntry reference
      this.cameraIdPositionMap.clear();   // Clear the CameraPosition cache
      // Reset the status after releasing resources so a create-after-dispose-without-initialize recovery
      // path does not misreport "already in progress".
      this.curStatus = STATUS.DEFAULT;
    } catch (error) {
      console.error(`DISPOSE_ERROR: ${(error as Error).message}`);
    }
  }

  lockCaptureOrientation(orientation: PlatformDeviceOrientation): void {
    try {
      if (this.camera == null) {
        throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
      }
      const deviceOrientation = CameraUtils.deserializeDeviceOrientation(PlatformDeviceOrientation[orientation]);
      this.camera.lockCaptureOrientation(deviceOrientation);
      console.log('lockCaptureOrientation success');
    } catch (error) {
      console.error('lockCaptureOrientation error:', error);
      // Rethrow so the Pigeon setUp handler (try/catch + wrapError) propagates the error to Dart.
      throw error as Error;
    }
  }

  unlockCaptureOrientation(): void {
    try {
      if (this.camera == null) {
        throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
      }
      this.camera.unlockCaptureOrientation();
      console.log('unlockCaptureOrientation success');
    } catch (error) {
      console.error('unlockCaptureOrientation error:', error);
      throw error as Error;
    }
  }

  takePicture(result: Result<string>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(value as string);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('TAKE_PICTURE_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      this.camera!.takePicture(methodResult);
    } catch (error) {
      result.error(new FlutterError('TAKE_PICTURE_ERROR', 'Failed to take picture', 'Failed to take picture', ''));
    }
  }

  async startVideoRecording(enableStream: boolean, videoOutputPath: string | null): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        if (videoOutputPath != null && !videoOutputPath.endsWith('.mp4')) {
          reject(new FlutterError('videoRecordingFailed', 'videoOutputPath must end with .mp4',
            'videoOutputPath must end with .mp4', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('startVideoRecording success:', value);
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error('startVideoRecording error:', errorCode, errorMessage);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('startVideoRecording not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'startVideoRecording not implemented',
                'startVideoRecording not implemented', ''));
          }
        };
        this.camera.startVideoRecording(methodResult, enableStream ? this.imageStreamChannel : null, videoOutputPath);
      } catch (error) {
        console.error('startVideoRecording error:', error);
        reject(error);
      }
    });
  }

  stopVideoRecording(result: Result<string>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('stopVideoRecording success:', value);
          result.success(value);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error('stopVideoRecording error:', errorCode, errorMessage);
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          console.error('stopVideoRecording not implemented');
          result.error(new FlutterError('STOP_VIDEO_RECORDING_ERROR', 'Method not implemented',
              'Method not implemented', ''));
        }
      };
      this.camera!.stopVideoRecording(methodResult);
    } catch (error) {
      console.error('stopVideoRecording error:', error);
      result.error(new FlutterError('STOP_VIDEO_RECORDING_ERROR', 'Failed to stop video recording',
          'Failed to stop video recording', ''));
    }
  }

  async pauseVideoRecording(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('pauseVideoRecording success:', value);
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error('pauseVideoRecording error:', errorCode, errorMessage);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('pauseVideoRecording not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'pauseVideoRecording not implemented',
                'pauseVideoRecording not implemented', ''));
          }
        };
        this.camera.pauseVideoRecording(methodResult);
      } catch (error) {
        console.error('pauseVideoRecording error:', error);
        reject(error);
      }
    });
  }

  async resumeVideoRecording(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('resumeVideoRecording success:', value);
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error('resumeVideoRecording error:', errorCode, errorMessage);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('resumeVideoRecording not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'resumeVideoRecording not implemented',
                'resumeVideoRecording not implemented', ''));
          }
        };
        this.camera.resumeVideoRecording(methodResult);
      } catch (error) {
        console.error('resumeVideoRecording error:', error);
        reject(error);
      }
    });
  }

  startImageStream(): void {
    try {
      if (this.camera == null) {
        throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
      }
      this.camera.startPreviewWithImageStream(this.imageStreamChannel);
      console.log('startImageStream success');
    } catch (error) {
      console.error('startImageStream error:', error);
      throw error as Error;
    }
  }

  stopImageStream(): void {
    try {
      if (this.camera == null) {
        throw new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', '');
      }
      // startPreview() returns an async chain: consume and catch it to avoid unhandled rejections
      // (mirrors the startPreviewWithImageStream pattern).
      this.pendingPreviewRestart = this.camera.startPreview().catch((e: Error): void => {
        // Camera switching/disposal tears the old instance down asynchronously; when the
        // deferred startPreview of stopImageStream loses that race, the failure belongs to
        // an instance that is being discarded anyway (the new instance's preview takes
        // over right after). Classify by lifecycle state instead of error message text so
        // upstream wording changes cannot silently break the classification.
        if (this.disposed || this.isSwitchingCamera) {
          Log.e(TAG, 'stopImageStream: startPreview skipped (teardown race): ' + e.message);
          return;
        }
        Log.e(TAG, 'stopImageStream: startPreview failed: ' + e.message);
        // No sendCameraErrorEvent helper on this class; report through the same
        // CameraEventApi channel the camera-switch path uses (same Dart-side event).
        try {
          const cameraEventApi = new CameraEventApi(this.binaryMessenger,
            this.camera?.dartMessenger?.getCameraIdSuffix());
          cameraEventApi.error('stopImageStream: startPreview failed: ' + e.message, { reply: (): void => {} });
        } catch (eventError) {
          Log.e(TAG, 'stopImageStream: send error event failed: ' + (eventError as Error).message);
        }
      });
      console.log('stopImageStream success');
    } catch (error) {
      console.error('stopImageStream error:', error);
      throw error as Error;
    }
  }

  setImageFileFormat(format: PlatformImageFileFormat, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('IMAGE_FILE_FORMAT_ERROR', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          // Aligned with Camera.setImageFileFormat: a cross-format switch also invalidates the cached
          // JPEG quality (reset to null), preventing stale quality from reviving after switching back to
          // jpeg or after camera rebuild replay.
          if (this.currentImageFileFormat !== format) {
            this.currentJpegQuality = null;
          }
          this.currentImageFileFormat = format;
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('IMAGE_FILE_FORMAT_ERROR', 'Method not implemented',
              'Method not implemented', ''));
        }
      };
      this.camera.setImageFileFormat(methodResult, format);
    } catch (error) {
      result.error(new FlutterError('IMAGE_FILE_FORMAT_ERROR', 'Failed to set image file format',
          'Failed to set image file format', ''));
    }
  }

  setJpegImageQuality(quality: number, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('JPEG_QUALITY_ERROR', 'Camera not initialized', 'Camera not initialized', ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          this.currentJpegQuality = quality;
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('JPEG_QUALITY_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      this.camera.setJpegImageQuality(methodResult, quality);
    } catch (error) {
      result.error(new FlutterError('JPEG_QUALITY_ERROR', 'Failed to set JPEG quality',
          'Failed to set JPEG quality', ''));
    }
  }

  async setZeroShutterLagEnabled(enabled: boolean): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        // Pre-API 21 runtimes: report success without recording the request, so the
        // camera-switch replay stays silent (the gate makes the feature a no-op anyway).
        if (!this.zslGate.isVersionSupported()) {
          resolve();
          return;
        }
        this.zeroShutterLagRequested = enabled;
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            reject(new FlutterError('ZERO_SHUTTER_LAG_ERROR', 'Method not implemented',
                'Method not implemented', ''));
          }
        };
        this.camera.setZeroShutterLagEnabled(methodResult, enabled);
      } catch (error) {
        reject(new FlutterError('ZERO_SHUTTER_LAG_ERROR', 'Failed to set zero shutter lag',
            'Failed to set zero shutter lag', ''));
      }
    });
  }

  isZeroShutterLagSupported(result: Result<boolean>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      // Pre-API 21 runtimes: false without touching the camera delegate.
      if (!this.zslGate.isVersionSupported()) {
        result.success(false);
        return;
      }
      result.success(this.camera.isZeroShutterLagSupported());
    } catch (error) {
      result.error(new FlutterError('ZERO_SHUTTER_LAG_ERROR', 'Failed to query zero shutter lag support',
          'Failed to query zero shutter lag support', ''));
    }
  }

  setFlashMode(flashMode: PlatformFlashMode, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      const flashModeString = PlatformFlashMode[flashMode];
      const mode = FlashMode.getValueForString(flashModeString);
      if (mode == null) {
        result.error(new FlutterError('FLASH_MODE_ERROR', `Unknown flash mode ${flashModeString}`,
            `Unknown flash mode ${flashModeString}`, ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('FLASH_MODE_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      this.camera!.setFlashMode(methodResult, mode);
    } catch (error) {
      result.error(new FlutterError('FLASH_MODE_ERROR', 'Failed to set flash mode', 'Failed to set flash mode', ''));
    }
  }

  setExposureMode(exposureMode: PlatformExposureMode, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      const exposureModeString = PlatformExposureMode[exposureMode];
      const mode = ExposureMode.getValueForString(exposureModeString);
      if (mode == null) {
        result.error(new FlutterError('EXPOSURE_MODE_ERROR', `Unknown exposure mode ${exposureModeString}`,
            `Unknown exposure mode ${exposureModeString}`, ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('EXPOSURE_MODE_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      this.camera!.setExposureMode(methodResult, mode);
    } catch (error) {
      result.error(new FlutterError('EXPOSURE_MODE_ERROR', 'Failed to set exposure mode',
          'Failed to set exposure mode', ''));
    }
  }

  setExposurePoint(point: PlatformPoint | null, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('EXPOSURE_POINT_ERROR', 'Camera not initialized', 'Camera not initialized', ''));
        return;
      }
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('EXPOSURE_POINT_ERROR', 'Method not implemented', 'Method not implemented',
              ''));
        }
      };
      if (point == null) {
        this.camera!.setExposurePoint(methodResult, new Point(null, null));
      } else {
        this.camera!.setExposurePoint(methodResult, new Point(point.getX(), point.getY()));
      }
    } catch (error) {
      result.error(new FlutterError('EXPOSURE_POINT_ERROR', 'Failed to set exposure point',
          'Failed to set exposure point', ''));
    }
  }

  setExposureOffset(offset: number, result: Result<number>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized',
            ''));
        return;
      }
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(value as number);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('EXPOSURE_OFFSET_ERROR', 'Method not implemented', 'Method not implemented',
              ''));
        }
      };
      this.camera!.setExposureOffset(methodResult, offset);
    } catch (error) {
      result.error(new FlutterError('EXPOSURE_OFFSET_ERROR', 'Failed to set exposure offset',
          'Failed to set exposure offset', ''));
    }
  }

  async setFocusMode(focusMode: PlatformFocusMode): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
          return;
        }
        let mode: camera.FocusMode;
        switch (focusMode) {
          case PlatformFocusMode.auto:
            // auto maps to continuous auto focus (aligned with camera_android CONTINUOUS_PICTURE); a single
            // FOCUS_MODE_AUTO stops once focus completes, which feels like a lock.
            mode = camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
            break;
          case PlatformFocusMode.locked:
            mode = camera.FocusMode.FOCUS_MODE_LOCKED;
            break;
          default:
            console.error(`FOCUS_MODE_ERROR: Unknown focus mode ${focusMode}`);
            reject(new FlutterError('SET_FOCUS_MODE_ERROR', `Unknown focus mode ${focusMode}`,
                `Unknown focus mode ${focusMode}`, ''));
            return;
        }

        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('setFocusMode success');
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error(`setFocusMode error: ${errorCode}: ${errorMessage}`);
            reject(new FlutterError(errorCode, errorMessage, errorMessage, ''));
          },
          notImplemented: () => {
            console.error('setFocusMode not implemented');
            reject(new FlutterError('NOT_IMPLEMENTED', 'setFocusMode not implemented',
                'setFocusMode not implemented', ''));
          }
        };
        this.camera.setFocusMode(methodResult, mode);
      } catch (error) {
        console.error('FOCUS_MODE_ERROR: Failed to set focus mode');
        reject(error);
      }
    });
  }

  setZoomLevel(zoom: number, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new FlutterError('ZOOM_ERROR', 'Camera not initialized', 'Camera not initialized', ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          result.error(new FlutterError('ZOOM_ERROR', 'Method not implemented', 'Method not implemented', ''));
        }
      };
      this.camera.setZoomLevel(methodResult, zoom);
    } catch (error) {
      result.error(new FlutterError('ZOOM_ERROR', 'Failed to set zoom level', 'Failed to set zoom level', ''));
    }
  }


  // Private helpers ported from MethodCallHandlerImpl.
  private registerCameraTexture(): void {
    this.textureId = this.textureRegistry.getTextureId();
    this.flutterTexture = this.textureRegistry.registerTexture(this.textureId);
  }

  private unregisterTexture(textureId: number): void {
    this.textureRegistry!.unregisterTexture(textureId);
    this.textureId = -1;
  }


  private instantiateCamera(call: CallArgument, result: Result<number>): void {
    let cameraName: string = call.argument('cameraName') as string;
    const resolutionPreset: ResolutionPreset = call.argument('resolutionPreset') as ResolutionPreset;
    let fps: number | null = call.argument('fps') as number | null;
    let videoBitrate: number | null = call.argument('videoBitrate') as number | null;
    let audioBitrate: number | null = call.argument('audioBitrate') as number | null;

    this.currentFps = fps ?? 30;
    this.currentVideoBitrate = videoBitrate ?? 100000000;
    this.currentAudioBitrate = audioBitrate ?? 48000;

    let enableAudio: boolean = call.argument('enableAudio') as boolean;

    this._cancelPendingDispose();

    this.currentResolutionPreset = resolutionPreset;
    this.currentEnableAudio = enableAudio;
    cameraName = this.resolveCurrentCameraId(cameraName);
    const dartMessenger: DartMessenger =
      new DartMessenger(this.binaryMessenger, this.textureId);
    const cameraProperties: CameraProperties =
      new CameraPropertiesImpl(cameraName, CameraUtils.getCameraManager(this.context));

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
        this.textureRegistry,
        this.currentFps,
        this.currentVideoBitrate,
        this.currentAudioBitrate);

    this.camera.onAutoSwitchToRearCamera = (): void => {
      this.switchToRearCamera().catch((e: Error): void =>
        Log.e(TAG, 'Auto switch to rear camera failed: ' + e.message));
    };

    // Replay session-level output settings (JPEG quality / image format) after the Camera instance is
    // rebuilt, keeping quality effective across switches.
    this.replayCameraOutputSettings();

    const reply: HashMap<String, Object> = new HashMap();
    reply.set('cameraId', this.textureId);
    result.success(this.textureId);
  }

  // Camera switching creates a fresh Camera instance (jpegQuality/imageFileFormat reset to defaults);
  // replay the cached session-level settings onto the new instance.
  private replayCameraOutputSettings(): void {
    if (this.camera == null) {
      return;
    }
    const methodResult: CameraMethodResult = {
      success: (_value: Any) => {
      },
      error: (errorCode: string, errorMessage: string, _errorDetails: Any) => {
        Log.e(TAG, 'replayCameraOutputSettings: ' + errorCode + ': ' + errorMessage);
      },
      notImplemented: () => {
      }
    };
    this.camera.setImageFileFormat(methodResult, this.currentImageFileFormat);
    // Replay only when the user explicitly set a quality AND the current format is jpeg; when
    // currentJpegQuality is null (never set) it must stay null - null means "no re-encoding on capture",
    // so writing a default or pushing 100 to the camera is forbidden here; sessions that never set
    // quality must not passively enable re-encoding after rebuild.
    if (this.currentJpegQuality != null && this.currentImageFileFormat == PlatformImageFileFormat.jpeg) {
      this.camera.setJpegImageQuality(methodResult, this.currentJpegQuality);
    }
    // Replay only when the user explicitly requested ZSL; default-off devices must stay
    // untouched (same explicit-request rationale as currentJpegQuality above). The gate
    // check is belt-and-braces: pre-API 21 runtimes never record the request (short
    // circuit in setZeroShutterLagEnabled), so the replay condition is false there.
    if (this.zeroShutterLagRequested && this.zslGate.isVersionSupported()) {
      this.camera.setZeroShutterLagEnabled(methodResult, true);
    }
  }


  prepareForVideoRecording(): void {
    console.log('prepareForVideoRecording success');
  }

  private async switchToRearCamera(): Promise<void> {
    if (this.isSwitchingCamera) {
      Log.w(TAG, 'switchToRearCamera: already in progress, ignoring');
      return;
    }
    this.isSwitchingCamera = true;
    this._cancelPendingDispose();
    try {
      const cameraManager = CameraUtils.getCameraManager(this.context);
      let allCameraDevices: camera.CameraDevice[];
      try {
        allCameraDevices = cameraManager.getSupportedCameras();
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: getSupportedCameras failed: ' + e.message);
        return;
      }

      const backCamera = allCameraDevices.find(
        (d: camera.CameraDevice) => d.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK
      );
      if (!backCamera) {
        Log.w(TAG, 'switchToRearCamera: no rear camera found');
        return;
      }

      const oldCamera = this.camera;
      if (oldCamera != null) {
        // Serialize with the old instance's deferred preview restart: stopImageStream
        // fires it un-awaited, and its overlap with the switch teardown inside the
        // camera service produced 'Camera service fatal error'/401 failures (see the
        // switch black-screen log analysis). Best-effort wait; the chain has its own
        // catch, so awaiting cannot throw here.
        if (this.pendingPreviewRestart != null) {
          try {
            await this.pendingPreviewRestart;
          } catch (e) {
            Log.d(TAG, 'switchToRearCamera: pending preview restart already failed: ' + (e as Error).message);
          }
          this.pendingPreviewRestart = null;
        }
        try {
          oldCamera.onAutoSwitchToRearCamera = null; // Prevent re-trigger loops
          await oldCamera.close();
        } catch (e) {
          Log.e(TAG, 'switchToRearCamera: close current camera failed: ' + e.message);
        }
        // close() already stopped orientation listening; dispose() runs idempotently to fully release
        // the old Camera (including the closed event notification).
        try {
          await oldCamera.dispose();
        } catch (e) {
          Log.e(TAG, 'switchToRearCamera: dispose old camera failed: ' + e.message);
        }
        // On camera switch the old stream handler closure holds the old Camera; unbind to cut the chain.
        try {
          this.imageStreamChannel.setStreamHandler(null);
        } catch (handlerError) {
          Log.e(TAG, 'switchToRearCamera: failed to clear image stream handler: ' + (handlerError as Error).message);
        }
        // Give the camera service a moment to finish draining the old session's async
        // teardown (native releases keep running on worker threads after close()
        // resolves); overlapping new-instance setup with that drain produced the
        // switch black screen on slower devices.
        await new Promise<void>((resolve: () => void) => { setTimeout(resolve, 100); });
      }
      this.camera = null;

      if (!this.flutterTexture) {
        Log.e(TAG, 'switchToRearCamera: flutterTexture is null, cannot proceed');
        return;
      }

      const dartMessenger = new DartMessenger(this.binaryMessenger, this.textureId);
      let cameraProperties: CameraProperties;
      try {
        cameraProperties = new CameraPropertiesImpl(backCamera.cameraId, cameraManager);
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: create CameraPropertiesImpl failed: ' + e.message);
        return;
      }

      this.camera = new Camera(
        this.ability,
        this.flutterTexture,
        new CameraFeatureFactoryImpl(),
        dartMessenger,
        cameraProperties,
        this.currentResolutionPreset,
        this.currentEnableAudio,
        this.cameraPermissions,
        this.textureRegistry,
        this.currentFps,
        this.currentVideoBitrate,
        this.currentAudioBitrate
      );
      this.camera.onAutoSwitchToRearCamera = (): void => {
        this.switchToRearCamera().catch((e: Error): void =>
          Log.e(TAG, 'Auto switch to rear camera failed: ' + e.message));
      };

      // Replay session-level output settings after the Camera instance is rebuilt (auto rear-switch case).
      this.replayCameraOutputSettings();

      try {
        await this.camera.open(this.currentImageFormat);
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: open rear camera failed: ' + e.message);
        // Camera.open no longer emits an error event on failure (see Camera.open); re-emit here so the
        // tri-fold auto rear-switch failure still reaches Dart.
        try {
          const cameraEventApi = new CameraEventApi(
              this.binaryMessenger, this.camera?.dartMessenger?.getCameraIdSuffix());
          cameraEventApi.error(e.message, { reply: () => {} });
        } catch (eventError) {
          Log.e(TAG, 'switchToRearCamera: send error event failed: ' + eventError.message);
        }
        // Tear the failed instance down (imageStreamReader/native ImageReceiver, fold
        // listener, partial session resources): this switch path returns without any
        // later close() covering this camera, so skipping cleanup would leak the
        // receiver and the fold-listener closure would keep the failed Camera from GC.
        try {
          await this.camera.close();
          await this.camera.dispose();
        } catch (cleanupError) {
          Log.e(TAG, 'switchToRearCamera: failed camera cleanup error: ' + cleanupError.message);
        }
        this.camera = null;
        return;
      }

      try {
        const cameraEventApi = new CameraEventApi(this.binaryMessenger,
          this.camera?.dartMessenger?.getCameraIdSuffix());
        cameraEventApi.cameraSwitched('CAMERA_AUTO_SWITCHED_TO_REAR', { reply: () => {} });
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: send CAMERA_AUTO_SWITCHED_TO_REAR event failed: ' + e.message);
      }
    } finally {
      this.isSwitchingCamera = false;
    }
  }

  // Set the video stabilization mode
  setVideoStabilizationMode(mode: PlatformVideoStabilizationMode, result: Result<void>): void {
    Log.i(TAG, `CameraApiImpl.ets - setVideoStabilizationMode called with mode: ${mode}`);
    try {
      if (this.camera == null) {
        Log.e(TAG, 'CameraApiImpl.ets - setVideoStabilizationMode error: Camera not initialized');
        result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Camera not initialized',
            'Camera not initialized', ''));
        return;
      }

      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          Log.i(TAG, 'CameraApiImpl.ets - setVideoStabilizationMode success');
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          Log.e(TAG, `CameraApiImpl.ets - setVideoStabilizationMode error: ${errorCode}: ${errorMessage}`);
          result.error(new FlutterError(errorCode, errorMessage, errorMessage, ''));
        },
        notImplemented: () => {
          Log.e(TAG, 'CameraApiImpl.ets - setVideoStabilizationMode not implemented');
          result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Method not implemented',
              'Method not implemented', ''));
        }
      };
      // Delegate to the underlying camera object
      this.camera.setVideoStabilizationMode(methodResult, mode);
    } catch (error) {
      Log.e(TAG, `CameraApiImpl.ets - setVideoStabilizationMode exception: ${error}`);
      result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Failed to set video stabilization mode',
          'Failed to set video stabilization mode', ''));
    }
  }

  // Get the video stabilization modes supported by the current device
  getSupportedVideoStabilizationModes(result: Result<Array<PlatformVideoStabilizationMode>>): void {
    Log.i(TAG, 'CameraApiImpl.ets - getSupportedVideoStabilizationModes called');
    try {
      if (this.camera == null) {
        Log.e(TAG, 'CameraApiImpl.ets - getSupportedVideoStabilizationModes error: Camera not initialized');
        result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Camera not initialized',
            'Camera not initialized', ''));
        return;
      }

      // Query the camera object for supported stabilization modes
      const modes = this.camera.getSupportedVideoStabilizationModes();
      Log.i(TAG, `CameraApiImpl.ets - getSupportedVideoStabilizationModes modes: ${JSON.stringify(modes)}`);
      result.success(modes);
    } catch (error) {
      Log.e(TAG, `CameraApiImpl.ets - getSupportedVideoStabilizationModes exception: ${error}`);
      result.error(new FlutterError('VIDEO_STABILIZATION_ERROR',
          'Failed to get supported video stabilization modes', 'Failed to get supported video stabilization modes',
          ''));
    }
  }
}
