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
 
import { BinaryMessenger, MethodResult } from '@ohos/flutter_ohos';
import MethodChannel, { MethodResult as FlutterMethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import Any from '@ohos/flutter_ohos/src/main/ets/plugin/common/Any';
import { CameraApi, PlatformCameraDescription, PlatformCameraLensDirection, PlatformMediaSettings, PlatformImageFormatGroup, PlatformDeviceOrientation, PlatformFlashMode, PlatformExposureMode, PlatformFocusMode, PlatformPoint, Result, FlutterError } from './Messages';
import { CameraUtils } from './CameraUtils';
import { FlashMode } from './features/flash/FlashMode';
import { ExposureMode } from './features/exposurelock/ExposureMode';
import { FocusMode } from './features/autofocus/FocusMode';
import { Point } from './features/Point';
import { Camera } from './Camera';
import { CameraPermissions } from './CameraPermissions';
import { DartMessenger } from './DartMessenger';
import { CameraProperties } from './CameraProperties';
import { CameraPropertiesImpl } from './CameraPropertiesImpl';
import { CameraFeatureFactoryImpl } from './features/CameraFeatureFactoryImpl';
import { ResolutionPreset, ResolutionPreset_valueOf } from './types/ResolutionPreset';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { EventChannel, TextureRegistry } from '@ohos/flutter_ohos';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { HashMap } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import camera from '@ohos.multimedia.camera';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';

const TAG: string = "CameraApiImpl";

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

interface ExceptionResultCallback {
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
  getMinExposureOffset(): number {
    try {
      if (this.camera == null) {
        return 0.0;
      }
      return this.camera!.getMinExposureOffset();
    } catch (error) {
      console.error('getMinExposureOffset error:', error);
      return 0.0;
    }
  }

  getMaxExposureOffset(): number {
    try {
      if (this.camera == null) {
        return 0.0;
      }
      return this.camera!.getMaxExposureOffset();
    } catch (error) {
      console.error('getMaxExposureOffset error:', error);
      return 0.0;
    }
  }

  getExposureOffsetStepSize(): number {
    try {
      if (this.camera == null) {
        return 0.0;
      }
      return this.camera!.getExposureOffsetStepSize();
    } catch (error) {
      console.error('getExposureOffsetStepSize error:', error);
      return 0.0;
    }
  }
  // Fix method signature to match CameraApi interface
  pausePreview(): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('pausePreview success');
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error(`pausePreview error: ${errorCode}: ${errorMessage}`);
        },
        notImplemented: () => {
          console.error('pausePreview not implemented');
        }
      };
      this.camera!.pausePreview(methodResult);
    } catch (error) {
      console.error('PAUSE_PREVIEW_ERROR: Failed to pause preview');
    }
  }

  // Fix method signature to match CameraApi interface
  resumePreview(): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('resumePreview success');
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error(`resumePreview error: ${errorCode}: ${errorMessage}`);
        },
        notImplemented: () => {
          console.error('resumePreview not implemented');
        }
      };
      this.camera!.resumePreview(methodResult);
    } catch (error) {
      console.error('RESUME_PREVIEW_ERROR: Failed to resume preview');
    }
  }
  // resumePreview(): void {
  //   throw new Error('Method not implemented.');
  // }
  getMaxZoomLevel(): number {
    try {
      if (this.camera == null) {
        return 1.0;
      }
      return this.camera!.getMaxZoomLevel();
    } catch (error) {
      console.error('getMaxZoomLevel error:', error);
      return 1.0;
    }
  }

  getMinZoomLevel(): number {
    try {
      if (this.camera == null) {
        return 1.0;
      }
      return this.camera!.getMinZoomLevel();
    } catch (error) {
      console.error('getMinZoomLevel error:', error);
      return 1.0;
    }
  }

  setFocusPoint(point: PlatformPoint, result: Result<void>): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('FOCUS_POINT_ERROR: Method not implemented'));
        }
      };
      this.camera!.setFocusPoint(methodResult, new Point(point.getX(), point.getY()));
    } catch (error) {
      result.error(new Error('FOCUS_POINT_ERROR: Failed to set focus point'));
    }
  }
  
  async setDescriptionWhileRecording(description: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        const methodResult: CameraMethodResult = {
          success: (value: Any) => {
            console.log('setDescriptionWhileRecording success');
            resolve();
          },
          error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
            console.error(`setDescriptionWhileRecording error: ${errorCode}: ${errorMessage}`);
            reject(new Error(`${errorMessage}`));
          },
          notImplemented: () => {
            console.error('setDescriptionWhileRecording not implemented');
            reject(new Error('setDescriptionWhileRecording not implemented'));
          }
        };
        const cameraProperties: CameraProperties = new CameraPropertiesImpl(description, CameraUtils.getCameraManager(this.context));
        this.camera?.setDescriptionWhileRecording(methodResult, cameraProperties);
      } catch (error) {
        console.error('DESCRIPTION_ERROR: Failed to set description while recording');
        reject(error);
      }
    });
  }
  private methodChannel: MethodChannel;
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

  constructor(ability: UIAbility, binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry) {
    super();
    this.ability = ability;
    this.context = ability.context;
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
    this.methodChannel = new MethodChannel(binaryMessenger, 'plugins.flutter.io/camera_ohos');
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
  create(cameraName: string, mediaSettings: PlatformMediaSettings, result: Result<number>): void {
    try {

      console.log('mediaSettings:', JSON.stringify(mediaSettings));
      
      if (this.curStatus != STATUS.DEFAULT) {
        result.success(-1);
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
        mediaSettings.getEnableAudio(),
        (errCode: string | null, errDesc: string | null) => {
         
          if (errCode == null) {
            try {
    
              this.registerCameraTexture();

              
              // 创建相机实例
              class CallArgumentImpl implements CallArgument {
                argument(key: string): string | number | boolean | null {
                  switch (key) {
                    case 'cameraName': return cameraName;
                    case 'resolutionPreset': return mediaSettings.getResolutionPreset();
                    case 'enableAudio': return mediaSettings.getEnableAudio();
                    default: return null;
                  }
                }
              }
              const call: CallArgument = new CallArgumentImpl();


      
              this.instantiateCamera(call, result);
            } catch (e) {
             
              this.curStatus = STATUS.DEFAULT;
              result.error(new Error(`CREATE_ERROR: ${(e as Error).message}`));
            }
          } else {
        
            this.curStatus = STATUS.DEFAULT;
            result.error(new Error(`${errCode}: ${errDesc}`));
          }
        }
      );
    } catch (error) {
    
      this.curStatus = STATUS.DEFAULT;
      result.error(new Error(`CREATE_ERROR: ${(error as Error).message}`));
    }
  }


  getAvailableCameras(): PlatformCameraDescription[] {
    try {
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
      return [];
    }
  }

  // 在 initialize 方法中增强错误处理
  initialize(imageFormat: PlatformImageFormatGroup): void {
    if (this.camera == null) {
      throw new FlutterError(
        'cameraNotFound',
        'cameraNotFound',
        "Camera not found. Please call the 'create' method before calling 'initialize'.",
        ''
      );
    }

    this.curStatus = STATUS.INITIALIZE_ING;
    const imageFormatString = PlatformImageFormatGroup[imageFormat];
    this.camera.open(imageFormatString).then(() => {
      this.curStatus = STATUS.DEFAULT;
    }).catch((e: Error) => {
      console.error(TAG, 'initialize failed: ' + e.message);
      this.curStatus = STATUS.DEFAULT;
    });
  }

  // 在 dispose 方法中改进错误处理
  dispose(): void {
    try {
      // 先停止相机
      if (this.camera) {
        try {
          this.camera.close();
        } catch (closeError) {
          console.error(`Failed to close camera: ${closeError}`);
        }
        try {
          this.camera?.dispose();
          this.camera = null;

        } catch (disposeError) {
          console.error(`Failed to dispose camera: ${disposeError}`);
        }
      }
      // 释放纹理
      if (this.textureId > -1) {
        try {
          this.unregisterTexture(this.textureId);
        } catch (textureError) {
          console.error(`Failed to unregister texture: ${textureError}`);
        }
      }
    } catch (error) {
      console.error(`DISPOSE_ERROR: ${(error as Error).message}`);
    }
  }

  lockCaptureOrientation(orientation: PlatformDeviceOrientation): void {
    try {
      const deviceOrientation = CameraUtils.deserializeDeviceOrientation(PlatformDeviceOrientation[orientation]);
      this.camera!.lockCaptureOrientation(deviceOrientation);
      console.log('lockCaptureOrientation success');
    } catch (error) {
      console.error('lockCaptureOrientation error:', error);
    }
  }

  unlockCaptureOrientation(): void {
    try {
      this.camera!.unlockCaptureOrientation();
      console.log('unlockCaptureOrientation success');
    } catch (error) {
      console.error('unlockCaptureOrientation error:', error);
    }
  }

  takePicture(result: Result<string>): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(value as string);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('TAKE_PICTURE_ERROR: Method not implemented'));
        }
      };
      this.camera!.takePicture(methodResult);
    } catch (error) {
      result.error(new Error('TAKE_PICTURE_ERROR: Failed to take picture'));
    }
  }

  startVideoRecording(enableStream: boolean): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('startVideoRecording success:', value);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error('startVideoRecording error:', errorCode, errorMessage);
        },
        notImplemented: () => {
          console.error('startVideoRecording not implemented');
        }
      };
      this.camera!.startVideoRecording(methodResult, enableStream ? this.imageStreamChannel : null);
    } catch (error) {
      console.error('startVideoRecording error:', error);
    }
  }

  stopVideoRecording(result: Result<string>): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('stopVideoRecording success:', value);
          result.success(value);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error('stopVideoRecording error:', errorCode, errorMessage);
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          console.error('stopVideoRecording not implemented');
          result.error(new Error('STOP_VIDEO_RECORDING_ERROR: Method not implemented'));
        }
      };
      this.camera!.stopVideoRecording(methodResult);
    } catch (error) {
      console.error('stopVideoRecording error:', error);
      result.error(new Error('STOP_VIDEO_RECORDING_ERROR: Failed to stop video recording'));
    }
  }

  pauseVideoRecording(): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('pauseVideoRecording success:', value);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error('pauseVideoRecording error:', errorCode, errorMessage);
        },
        notImplemented: () => {
          console.error('pauseVideoRecording not implemented');
        }
      };
      this.camera!.pauseVideoRecording(methodResult);
    } catch (error) {
      console.error('pauseVideoRecording error:', error);
    }
  }

  resumeVideoRecording(): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('resumeVideoRecording success:', value);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error('resumeVideoRecording error:', errorCode, errorMessage);
        },
        notImplemented: () => {
          console.error('resumeVideoRecording not implemented');
        }
      };
      this.camera!.resumeVideoRecording(methodResult);
    } catch (error) {
      console.error('resumeVideoRecording error:', error);
    }
  }

  startImageStream(): void {
    try {
      this.camera!.startPreviewWithImageStream(this.imageStreamChannel);
      console.log('startImageStream success');
    } catch (error) {
      console.error('startImageStream error:', error);
    }
  }

  stopImageStream(): void {
    try {
      this.camera!.startPreview();
      console.log('stopImageStream success');
    } catch (error) {
      console.error('stopImageStream error:', error);
    }
  }

  setFlashMode(flashMode: PlatformFlashMode, result: Result<void>): void {
    try {
      const flashModeString = PlatformFlashMode[flashMode];
      const mode = FlashMode.getValueForString(flashModeString);
      if (mode == null) {
        result.error(new Error(`FLASH_MODE_ERROR: Unknown flash mode ${flashModeString}`));
        return;
      }
      
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('FLASH_MODE_ERROR: Method not implemented'));
        }
      };
      this.camera!.setFlashMode(methodResult, mode);
    } catch (error) {
      result.error(new Error('FLASH_MODE_ERROR: Failed to set flash mode'));
    }
  }

  setExposureMode(exposureMode: PlatformExposureMode, result: Result<void>): void {
    try {
      const exposureModeString = PlatformExposureMode[exposureMode];
      const mode = ExposureMode.getValueForString(exposureModeString);
      if (mode == null) {
        result.error(new Error(`EXPOSURE_MODE_ERROR: Unknown exposure mode ${exposureModeString}`));
        return;
      }
      
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('EXPOSURE_MODE_ERROR: Method not implemented'));
        }
      };
      this.camera!.setExposureMode(methodResult, mode);
    } catch (error) {
      result.error(new Error('EXPOSURE_MODE_ERROR: Failed to set exposure mode'));
    }
  }

  setExposurePoint(point: PlatformPoint, result: Result<void>): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('EXPOSURE_POINT_ERROR: Method not implemented'));
        }
      };
      this.camera!.setExposurePoint(methodResult, new Point(point.getX(), point.getY()));
    } catch (error) {
      result.error(new Error('EXPOSURE_POINT_ERROR: Failed to set exposure point'));
    }
  }

  setExposureOffset(offset: number, result: Result<number>): void {
    try {
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(value as number);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('EXPOSURE_OFFSET_ERROR: Method not implemented'));
        }
      };
      this.camera!.setExposureOffset(methodResult, offset);
    } catch (error) {
      result.error(new Error('EXPOSURE_OFFSET_ERROR: Failed to set exposure offset'));
    }
  }

  setFocusMode(focusMode: PlatformFocusMode): void {
    try {
      const focusModeString = PlatformFocusMode[focusMode];
      const mode = FocusMode.getValueForString(focusModeString);
      if (mode == null) {
        console.error(`FOCUS_MODE_ERROR: Unknown focus mode ${focusModeString}`);
        return;
      }
      
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          console.log('setFocusMode success');
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          console.error(`setFocusMode error: ${errorCode}: ${errorMessage}`);
        },
        notImplemented: () => {
          console.error('setFocusMode not implemented');
        }
      };
      this.camera!.setFocusMode(methodResult, mode);
    } catch (error) {
      console.error('FOCUS_MODE_ERROR: Failed to set focus mode');
    }
  }

  setZoomLevel(zoom: number, result: Result<void>): void {
    try {
      if (this.camera == null) {
        result.error(new Error('ZOOM_ERROR: Camera not initialized'));
        return;
      }
      
      const methodResult: CameraMethodResult = {
        success: (value: Any) => {
          result.success(undefined);
        },
        error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
          result.error(new Error(`${errorCode}: ${errorMessage}`));
        },
        notImplemented: () => {
          result.error(new Error('ZOOM_ERROR: Method not implemented'));
        }
      };
      this.camera.setZoomLevel(methodResult, zoom);
    } catch (error) {
      result.error(new Error('ZOOM_ERROR: Failed to set zoom level'));
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
    let enableAudio: boolean = call.argument('enableAudio') as boolean;

    // 在 instantiateCamera 方法中
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
        this.cameraPermissions);

    const reply: HashMap<String, Object> = new HashMap();
    reply.set('cameraId', this.textureId);
    result.success(this.textureId);
  }


  private handleException(error: BusinessError, result: ExceptionResultCallback): void {
    if (Object.values(camera.CameraErrorCode).includes(error.code)) {
      const errorDetails: Record<string, string> = {};
      result.error("CameraError", error.message, errorDetails);
      return;
    }
    // 对于未知错误，也要抛出以确保错误不被静默处理
    const errorDetails: Record<string, string> = {};
    result.error('CAMERA_ERROR', error.message || 'Unknown error', errorDetails);
    // 同时抛出错误以保持与 MethodCallHandlerImpl 的一致性
    throw error as Error;
  }

  // 停止监听方法
  stopListening(): void {
    this.methodChannel.setMethodCallHandler(null);
  }

  prepareForVideoRecording(): void {
    console.log('prepareForVideoRecording success');
  }
}
