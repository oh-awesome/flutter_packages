// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on CameraUtils.java originally written by
// Copyright 2013 The Flutter Authors.

import camera from '@ohos.multimedia.camera';
import { BusinessError } from '@ohos.base';
import { HashMap } from '@kit.ArkTS';
import { Log } from '@ohos/flutter_ohos';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';


interface FileInfo {
  prefix: string;
  suffix: string;
  directory: number;
}

const CameraDeviceMap = (cameraManager: camera.CameraManager): HashMap<string, camera.CameraDevice> => {
  const deviceMap: HashMap<string, camera.CameraDevice> = new HashMap();
  try {
    let cameras: Array<camera.CameraDevice> = [];
    cameras = cameraManager.getSupportedCameras();
    
    for (let element of cameras) {
    
      deviceMap.set(element.cameraId, element);
    }
  } catch (error) {
    let err = error as BusinessError;
    Log.e('CameraUtils', 'CameraDeviceMap: getSupportedCameras failed: ' + err.code + ' ' + err.message);
  }
  return deviceMap;
}

export class CameraUtils {

  constructor(context: Context) {
  }

  static getCameraManager(context: Context): camera.CameraManager {
    return camera.getCameraManager(context);
  }

  static getCameraDevice(cameraId: string, cameraManager: camera.CameraManager): camera.CameraDevice | null {
    try {
      const deviceMap = CameraDeviceMap(cameraManager);
      const device = deviceMap.get(cameraId);
      
      if (!device) {
        
        return null;
      }
      
  
      return device;
    } catch (error) {
  
      return null;
    }
  }

  static getCameraInput(cameraDevice: camera.CameraDevice | undefined,
    cameraManager: camera.CameraManager): camera.CameraInput | undefined {
    let cameraInput: camera.CameraInput | undefined = undefined;
    try {
      cameraInput = cameraManager.createCameraInput(cameraDevice);
    } catch (error) {
      let err = error as BusinessError;
      console.error(`The createCameraInput call failed. error code: ${err.code}`);
    }
    return cameraInput;
  }


  static serializeDeviceOrientation(orientation: DeviceOrientation): string {
    if (orientation == null) {
      throw new Error('Could not serialize null device orientation.');
    }
    switch (orientation) {
      case DeviceOrientation.PORTRAIT_UP:
        return 'portraitUp';
      case DeviceOrientation.PORTRAIT_DOWN:
        return 'portraitDown';
      case DeviceOrientation.LANDSCAPE_LEFT:
        return 'landscapeLeft';
      case DeviceOrientation.LANDSCAPE_RIGHT:
        return 'landscapeRight';
      default:
        throw new Error(
          'Could not serialize device orientation: ' + String(orientation));
    }
  }

  static deserializeDeviceOrientation(orientation: string): DeviceOrientation {
    if (orientation == null) {
      throw new Error('Could not deserialize null device orientation.');
    }
    switch (orientation) {
      case 'portraitUp':
        return DeviceOrientation.PORTRAIT_UP;
      case 'portraitDown':
        return DeviceOrientation.PORTRAIT_DOWN;
      case 'landscapeLeft':
        return DeviceOrientation.LANDSCAPE_LEFT;
      case 'landscapeRight':
        return DeviceOrientation.LANDSCAPE_RIGHT;
      default:
        throw new Error(
          'Could not deserialize device orientation: ' + orientation);
    }
  }

  static getAvailableCameras(context: Context): Array<Map<String, Object>> {
    let cameraArray: Array<Map<String, Object>> = [];
    try {
      const cameraManager: camera.CameraManager = camera.getCameraManager(context);
      let cameras: Array<camera.CameraDevice> = [];
      cameras = cameraManager.getSupportedCameras();

      for (let element of cameras) {
        const details: Map<String, Object> = new Map<String, Object>();
        details.set('name', element.cameraId);
        details.set('sensorOrientation', element.cameraOrientation);

        let position: camera.CameraPosition = element.cameraPosition;
        switch (position) {
          case camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED:
            details.set('lensFacing', 'external');
            break;
          case camera.CameraPosition.CAMERA_POSITION_BACK:
            details.set('lensFacing', 'back');
            break;
          case camera.CameraPosition.CAMERA_POSITION_FRONT:
            details.set('lensFacing', 'front');
            break;
          case camera.CameraPosition.CAMERA_POSITION_FOLD_INNER:
            details.set('lensFacing', 'external');
            break;
        }
        cameraArray.push(details);
      }
    } catch (error) {
      let err = error as BusinessError;
      console.error(`The getAvailableCameras call failed. error code: ${err.code}`);
      // No silent fallback to an empty array: failures propagate up and the Pigeon wrapper
      // converts them to PlatformException, so Dart never misreads this as "no cameras available".
      throw new Error(`getAvailableCameras failed: ${err.message}`);
    }
    return cameraArray;
  }

  static getSupportedOutputCapability(device: camera.CameraDevice, mode: camera.SceneMode,
      manager: camera.CameraManager): camera.CameraOutputCapability {
    let capability: camera.CameraOutputCapability = manager.getSupportedOutputCapability(device, mode);
    return capability;
  }

  // Detect whether the device has a flash.
  // A failed system call does not imply unsupported hardware: throw for upper layers,
  // avoiding false "no flash" reports.
  public static hasFlash(captureSession: camera.PhotoSession | camera.VideoSession): boolean {
    try {
      return captureSession.hasFlash();
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The hasFlash call failed. error code: ${err.code}`);
      throw error as Error;
    }
  }

  // Detect whether the flash mode is supported.
  // A failed system call does not imply unsupported: throw for upper layers,
  // avoiding false "flash mode unsupported" reports.
  public static isFlashModeSupported(captureSession: camera.PhotoSession | camera.VideoSession,
      mode: camera.FlashMode): boolean {
    try {
      return captureSession.isFlashModeSupported(mode);
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The isFlashModeSupported call failed. error code: ${err.code}`);
      throw error as Error;
    }
  }

  // Detect whether the exposure mode is supported.
  // A failed system call does not imply unsupported: throw for upper layers,
  // avoiding false "exposure mode unsupported" reports.
  public static isExposureModeSupported(captureSession: camera.PhotoSession | camera.VideoSession,
      mode: camera.ExposureMode): boolean {
    try {
      return captureSession.isExposureModeSupported(mode);
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The isExposureModeSupported call failed. error code: ${err.code}`);
      throw error as Error;
    }
  }

  // Get the supported zoom range.
  public static getZoomRatioRange(captureSession: camera.PhotoSession | camera.VideoSession): Array<number> {
    let zoomRatioRange: Array<number> = [];
    try {
      zoomRatioRange = captureSession.getZoomRatioRange();
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The getZoomRatioRange call failed. error code: ${err.code}`);
    }
    return zoomRatioRange;
  }

  // Get the minimum supported zoom range.
  // Throw when the query fails or returns an empty array; upper-layer FlutterError/Pigeon propagates to
  // Dart instead of silently falling back to default values.
  public static getMinZoomRatio(captureSession: camera.PhotoSession | camera.VideoSession): number {
    let zoomRatioRange: Array<number> = [];
    try {
      zoomRatioRange = captureSession.getZoomRatioRange();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`The getZoomRatioRange call failed. error code: ${err.code}`);
      throw error as Error;
    }
    if (zoomRatioRange.length === 0) {
      throw new Error('The getZoomRatioRange returned empty range');
    }
    return Math.min(...zoomRatioRange);
  }

  // Get the maximum supported zoom range.
  // Throw when the query fails or returns an empty array; upper-layer FlutterError/Pigeon propagates to
  // Dart instead of silently falling back to default values.
  public static getMaxZoomRatio(captureSession: camera.PhotoSession | camera.VideoSession): number {
    let zoomRatioRange: Array<number> = [];
    try {
      zoomRatioRange = captureSession.getZoomRatioRange();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`The getZoomRatioRange call failed. error code: ${err.code}`);
      throw error as Error;
    }
    if (zoomRatioRange.length === 0) {
      throw new Error('The getZoomRatioRange returned empty range');
    }
    return Math.max(...zoomRatioRange);
  }

  // Query the exposure compensation range.
  public static getExposureBiasRange(captureSession: camera.PhotoSession | camera.VideoSession): Array<number> {
    let biasRangeArray: Array<number> = [];
    try {
      biasRangeArray = captureSession.getExposureBiasRange();
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The getExposureBiasRange call failed. error code: ${err.code}`);
    }
    return biasRangeArray;
  }

  // Query the minimum exposure compensation.
  // Throw when the query fails or returns an empty array; upper-layer FlutterError/Pigeon propagates to
  // Dart instead of silently falling back to default values.
  public static getMinExposureBias(captureSession: camera.PhotoSession | camera.VideoSession): number {
    let biasRangeArray: Array<number> = new Array<number>();
    try {
      biasRangeArray = captureSession.getExposureBiasRange();
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The getExposureBiasRange call failed. error code: ${err.code}`);
      throw error as Error;
    }
    if (biasRangeArray.length === 0) {
      throw new Error('The getExposureBiasRange returned empty range');
    }
    return biasRangeArray[0];
  }

  // Query the maximum exposure compensation.
  // Throw when the query fails or returns an empty array; upper-layer FlutterError/Pigeon propagates to
  // Dart instead of silently falling back to default values.
  public static getMaxExposureBias(captureSession: camera.PhotoSession | camera.VideoSession): number {
    let biasRangeArray: Array<number> = new Array<number>();
    try {
      biasRangeArray = captureSession.getExposureBiasRange();
    } catch (error) {
      // Failure returns the error code; handled by upper layers.
      let err = error as BusinessError;
      console.error(`The getExposureBiasRange call failed. error code: ${err.code}`);
      throw error as Error;
    }
    if (biasRangeArray.length === 0) {
      throw new Error('The getExposureBiasRange returned empty range');
    }
    return biasRangeArray[biasRangeArray.length - 1];
  }


  // Query the exposure compensation step size.
  public static getExposureBiasStep(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return 0.5;
  }
}