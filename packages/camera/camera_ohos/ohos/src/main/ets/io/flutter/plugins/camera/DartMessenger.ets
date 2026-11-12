// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on DartMessenger.java originally written by
// Copyright 2013 The Flutter Authors.

import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { CameraGlobalEventApi, PlatformDeviceOrientation } from './Messages';
import { Log } from '@ohos/flutter_ohos';

export class DartMessenger {
  private binaryMessenger: BinaryMessenger;
  private cameraIdSuffix: string;

  constructor(messenger: BinaryMessenger, textureId?: number) {
    this.binaryMessenger = messenger;
    this.cameraIdSuffix = textureId != null ? textureId.toString() : '';
  }

  getCameraIdSuffix(): string {
    return this.cameraIdSuffix;
  }

  sendDeviceOrientationChangeEvent(orientation: DeviceOrientation) {
    try {
      const globalEventApi = new CameraGlobalEventApi(this.binaryMessenger);
      const platformOrientation = this.toPlatformDeviceOrientation(orientation);
      globalEventApi.deviceOrientationChanged(platformOrientation, { reply: (_) => {} });
    } catch (error) {
      // 该方法在 display.on('change') 系统回调中被调用，需防御性捕获，避免异常冒泡导致回
      // 调崩溃
      Log.e('DartMessenger', 'sendDeviceOrientationChangeEvent failed: ' + (error as Error).message);
    }
  }

  private toPlatformDeviceOrientation(orientation: DeviceOrientation): PlatformDeviceOrientation {
    switch (orientation) {
      case DeviceOrientation.PORTRAIT_UP:
        return PlatformDeviceOrientation.portraitUp;
      case DeviceOrientation.PORTRAIT_DOWN:
        return PlatformDeviceOrientation.portraitDown;
      case DeviceOrientation.LANDSCAPE_LEFT:
        return PlatformDeviceOrientation.landscapeLeft;
      case DeviceOrientation.LANDSCAPE_RIGHT:
        return PlatformDeviceOrientation.landscapeRight;
      default:
        return PlatformDeviceOrientation.portraitUp;
    }
  }

  finish(result: MethodResult, payload?: Object) {
    result.success(payload);
  }

  public error(
    result: MethodResult,
    errorCode: string,
    errorMessage?: string,
    errorDetails?: Object) {
    result.error(errorCode, errorMessage, errorDetails);
  }

  getBinaryMessenger(): BinaryMessenger {
    return this.binaryMessenger;
  }
}