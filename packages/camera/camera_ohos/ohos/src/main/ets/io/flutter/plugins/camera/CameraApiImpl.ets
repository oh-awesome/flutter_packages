/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
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

// 定义参数对象接口
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

// 定义接口来解决类型问题
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

  // 从 MethodCallHandlerImpl 移植的属性
  private cameraPermissions: CameraPermissions;
  private camera: Camera | null = null;
  private flutterTexture: SurfaceTextureEntry | null = null;
  private textureId: number = -1;
  private curStatus: STATUS = STATUS.DEFAULT;
  // 已释放标志：dispose() 后置 true，防护 create 权限异步回调迟到导致 dispose 后重建相机
  private disposed: boolean = false;
  private currentImageFormat: string = 'jpeg';
  private currentResolutionPreset: ResolutionPreset = ResolutionPreset.medium;
  private currentEnableAudio: boolean = false;
  // JPEG 质量 / 图片格式会话级缓存：切换摄像头会新建 Camera 实例（jpegQuality/imageFileFormat
  // 复位为默认），此处缓存最近一次设置值，在 new Camera 后自动重放，避免切换后 Quality
  // 失效。
  private currentJpegQuality: number | null = null;
  private currentImageFileFormat: PlatformImageFileFormat = PlatformImageFileFormat.jpeg;
  private cameraIdPositionMap: Map<string, camera.CameraPosition> = new Map();

  constructor(ability: UIAbility, binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry) {
    super();
    this.ability = ability;
    this.context = ability.context;
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
    this.imageStreamChannel = new EventChannel(binaryMessenger, 'plugins.flutter.io/camera_ohos/imageStream');
    this.cameraPermissions = new CameraPermissions();

    // 确保状态正确初始化
    this.curStatus = STATUS.DEFAULT;
    this.textureId = -1;
    this.camera = null;
    this.flutterTexture = null;
  }

  // 添加正确的 create 方法实现以匹配 CameraApi 接口
  // 在 create 方法中增强错误处理
  async create(cameraName: string, mediaSettings: PlatformMediaSettings, result: Result<number>): Promise<void> {
    try {
      this.disposed = false;   // 复位已释放标志，允许重新创建

      console.log('mediaSettings:', JSON.stringify(mediaSettings));

      if (this.curStatus != STATUS.DEFAULT) {
        result.error(new FlutterError('CREATE_ERROR', 'Camera create is already in progress',
            'Camera create is already in progress', ''));
        return;
      }
      this.curStatus = STATUS.CREATE_ING;

      if (this.camera) {
        // releaseCamera 不释放 DeviceOrientationManager 的 display 监听；dispose() 是完整释放入口
        await this.camera.dispose();
      }
      // 切换相机时旧 StreamHandler 闭包捕获旧 Camera，显式解绑切断 channel 对旧 Camera 的引用链
      // ；
      // 新相机会在 startVideoRecording/startPreviewWithImageStream 时重新注册 handler
      try {
        this.imageStreamChannel.setStreamHandler(null);
      } catch (handlerError) {
        Log.e(TAG, 'create: failed to clear image stream handler: ' + (handlerError as Error).message);
      }
      if (this.textureId > -1) {
        this.unregisterTexture(this.textureId);
      }

      // 检查权限
      this.cameraPermissions.requestPermissions(
        this.context,
        mediaSettings.getEnableAudio(),
        (errCode: string | null, errDesc: string | null) => {

          if (errCode == null) {
            // 权限回调迟到：dispose() 已释放资源，直接报错返回，避免在已释放上下文上重
            // 建相机
            if (this.disposed) {
              this.curStatus = STATUS.DEFAULT;
              result.error(new FlutterError('CREATE_ERROR', 'CameraPlugin disposed during permission request',
                  'CameraPlugin disposed during permission request', ''));
              return;
            }
            try {

              this.registerCameraTexture();


              // 创建相机实例
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
              // registerCameraTexture 已注册纹理但 instantiateCamera 抛错：回滚纹理，
              // 保证异常路径与正常路径（dispose 清理）资源状态一致，避免纹理泄漏
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
      );
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
      // 不再吞错降级：抛给 Pigeon 包装层（Messages.ets setUp 的 try/catch+wrapError）转
      // PlatformException
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

  // 在 initialize 方法中增强错误处理
  async initialize(imageFormat: PlatformImageFormatGroup): Promise<void> {


    this.curStatus = STATUS.INITIALIZE_ING;
    if (this.camera != null) {
      try {
        const imageFormatString = PlatformImageFormatGroup[imageFormat];
        this.currentImageFormat = imageFormatString;
        await this.camera.open(imageFormatString);
        this.curStatus = STATUS.DEFAULT;
      } catch (e) {
        Log.e(TAG, 'initialize failed: ' + e.message);
        this.curStatus = STATUS.DEFAULT;
        // 与上游对齐：throw 的路径不发事件——若同时发事件再 throw，Dart 侧 initializeCamera
        // 中"错误事件先完成 completer、PlatformException catch 再二次 completeError"会抛
        // StateError。此处仅关闭相机释放资源（Camera.close 内部有 isClosed 守卫，重复调用
        // 安全），错误经 Pigeon 错误回复单通道到达 Dart。
        try {
          await this.camera.close();
        } catch (closeError) {
          Log.e(TAG, 'close after initialize failed: ' + closeError.message);
        }
        throw new FlutterError('CameraError', e.message, e.message, '');
      }
    } else {
      // this.camera == null 时无法获取 cameraId 后缀，事件只能发往无人监听的裸 channel，
      // 因此仅通过 throw 向方法调用方返回错误（wrapError → Dart PlatformException）
      this.curStatus = STATUS.DEFAULT;
      throw new FlutterError('cameraNotFound',
          'Camera not found. Please call the \'create\' method before calling \'initialize\'.',
          'Camera not found. Please call the \'create\' method before calling \'initialize\'.', '');
    }
  }

  // 在 dispose 方法中改进错误处理
  async dispose(): Promise<void> {
    try {
      this.disposed = true;   // 标记已释放，防护 create 权限异步回调迟到重建
      // 先停止相机
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
      // 释放纹理
      if (this.textureId > -1) {
        try {
          this.unregisterTexture(this.textureId);
        } catch (textureError) {
          console.error(`Failed to unregister texture: ${textureError}`);
        }
      }
      // 解绑图像流 EventChannel stream handler，切断闭包对 Camera 的引用链（防 Dart 侧滞留订阅导
      // 致泄漏）
      try {
        this.imageStreamChannel.setStreamHandler(null);
      } catch (streamHandlerError) {
        console.error(`Failed to clear image stream handler: ${streamHandlerError}`);
      }
      this.flutterTexture = null;         // 释放 SurfaceTextureEntry 引用
      this.cameraIdPositionMap.clear();   // 清空 CameraPosition 缓存
      // 资源释放后复位状态，避免 create 成功后未 initialize 即 dispose 的恢复路径再次 create
      // 误报 already in progress
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
      // 重新抛出，让 Pigeon 生成的 setUp handler 的 try/catch+wrapError 传播到 Dart
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

  async startVideoRecording(enableStream: boolean): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        if (this.camera == null) {
          reject(new FlutterError('CAMERA_NOT_INITIALIZED', 'Camera not initialized', 'Camera not initialized', ''));
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
        this.camera.startVideoRecording(methodResult, enableStream ? this.imageStreamChannel : null);
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
      // startPreview() 返回异步链：消费并捕获异常，避免未处理 Promise 拒绝（对齐
      // startPreviewWithImageStream 模式）
      this.camera.startPreview().catch((e: Error) => {
        Log.e(TAG, 'stopImageStream: startPreview failed: ' + e.message);
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
          // 与 Camera.setImageFileFormat 对齐：跨格式切换时缓存中的 JPEG 质量一并
          // 失效（重置为 null），防止旧质量在切回 jpeg 后或相机重建重放时复活。
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
            // auto 对应连续自动对焦（对齐 camera_android 的 CONTINUOUS_PICTURE），
            // 单次 FOCUS_MODE_AUTO 对焦完成即停，观感如同锁定。
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


  // 从 MethodCallHandlerImpl 移植的私有方法
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

    // 重建 Camera 实例后重放会话级输出设置（JPEG 质量 / 图片格式），避免切换后 Quality 失
    // 效。
    this.replayCameraOutputSettings();

    const reply: HashMap<String, Object> = new HashMap();
    reply.set('cameraId', this.textureId);
    result.success(this.textureId);
  }

  // 切换摄像头会 new Camera 全新实例（jpegQuality/imageFileFormat 复位为默认），
  // 此处将缓存的会话级设置重放到新实例上。
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
    // 仅在用户显式设置过质量且当前格式为 jpeg 时重放；currentJpegQuality 为 null
    // （用户从未设置）时必须保持原值——null 语义是"不启用拍照落盘重编码"，
    // 此处禁止补写默认值或向相机下发 100，否则未设置过的会话会在重建后被动启用重编码。
    if (this.currentJpegQuality != null && this.currentImageFileFormat == PlatformImageFileFormat.jpeg) {
      this.camera.setJpegImageQuality(methodResult, this.currentJpegQuality);
    }
  }


  prepareForVideoRecording(): void {
    console.log('prepareForVideoRecording success');
  }

  private async switchToRearCamera(): Promise<void> {
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
      try {
        oldCamera.onAutoSwitchToRearCamera = null; // 避免循环触发
        await oldCamera.close();
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: close current camera failed: ' + e.message);
      }
      // close() 已停方向监听；dispose() 幂等兜底，确保旧 Camera 完整释放（含 closed 事件通知
      // ）
      try {
        await oldCamera.dispose();
      } catch (e) {
        Log.e(TAG, 'switchToRearCamera: dispose old camera failed: ' + e.message);
      }
      // 切换相机时旧 StreamHandler 闭包捕获旧 Camera，显式解绑切断引用链
      try {
        this.imageStreamChannel.setStreamHandler(null);
      } catch (handlerError) {
        Log.e(TAG, 'switchToRearCamera: failed to clear image stream handler: ' + (handlerError as Error).message);
      }
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

    // 重建 Camera 实例后重放会话级输出设置，避免自动切后摄后 Quality 失效。
    this.replayCameraOutputSettings();

    try {
      await this.camera.open(this.currentImageFormat);
    } catch (e) {
      Log.e(TAG, 'switchToRearCamera: open rear camera failed: ' + e.message);
      // Camera.open 失败不再自带错误事件（见 Camera.open 注释），此处补发以保持
      // 三折叠自动切后摄失败对 Dart 侧的通知
      try {
        const cameraEventApi = new CameraEventApi(
            this.binaryMessenger, this.camera?.dartMessenger?.getCameraIdSuffix());
        cameraEventApi.error(e.message, { reply: () => {} });
      } catch (eventError) {
        Log.e(TAG, 'switchToRearCamera: send error event failed: ' + eventError.message);
      }
      return;
    }

    try {
      const cameraEventApi = new CameraEventApi(this.binaryMessenger, this.camera?.dartMessenger?.getCameraIdSuffix());
      cameraEventApi.cameraSwitched('CAMERA_AUTO_SWITCHED_TO_REAR', { reply: () => {} });
    } catch (e) {
      Log.e(TAG, 'switchToRearCamera: send CAMERA_AUTO_SWITCHED_TO_REAR event failed: ' + e.message);
    }
  }

  // 设置视频防抖模式
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
      // 传递给底层相机对象处理
      this.camera.setVideoStabilizationMode(methodResult, mode);
    } catch (error) {
      Log.e(TAG, `CameraApiImpl.ets - setVideoStabilizationMode exception: ${error}`);
      result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Failed to set video stabilization mode',
          'Failed to set video stabilization mode', ''));
    }
  }

  // 获取当前设备支持的视频防抖模式列表
  getSupportedVideoStabilizationModes(result: Result<Array<PlatformVideoStabilizationMode>>): void {
    Log.i(TAG, 'CameraApiImpl.ets - getSupportedVideoStabilizationModes called');
    try {
      if (this.camera == null) {
        Log.e(TAG, 'CameraApiImpl.ets - getSupportedVideoStabilizationModes error: Camera not initialized');
        result.error(new FlutterError('VIDEO_STABILIZATION_ERROR', 'Camera not initialized',
            'Camera not initialized', ''));
        return;
      }

      // 调用相机对象获取支持的防抖模式
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
