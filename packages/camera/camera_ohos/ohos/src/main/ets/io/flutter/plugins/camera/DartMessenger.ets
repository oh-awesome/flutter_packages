// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on DartMessenger.java originally written by
// Copyright 2013 The Flutter Authors.

import { HashMap } from '@kit.ArkTS';
import { MethodChannel } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { CameraUtils } from './CameraUtils';
import { FocusMode } from './features/autofocus/FocusMode';
import { ExposureMode } from './features/exposurelock/ExposureMode';
import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { CameraGlobalEventApi, PlatformDeviceOrientation } from './Messages';

enum DeviceEventType {
  ORIENTATION_CHANGED = "orientation_changed",
}

enum CameraEventType {
  ERROR = "error",
  CLOSING = "camera_closing",
  INITIALIZED = "initialized",
}

export class DartMessenger {
  private binaryMessenger: BinaryMessenger;
  private cameraChannel: MethodChannel;
  private deviceChannel: MethodChannel;

  constructor(messenger: BinaryMessenger, textureId?: number) {
    this.binaryMessenger = messenger;
    // 初始化相机事件通道
    this.cameraChannel = new MethodChannel(messenger, `flutter.io/cameraPlugin/camera${textureId || ''}`);
    // 初始化设备事件通道
    this.deviceChannel = new MethodChannel(messenger, 'flutter.io/cameraPlugin/device');
  }

  sendDeviceOrientationChangeEvent(orientation: DeviceOrientation) {
    const globalEventApi = new CameraGlobalEventApi(this.binaryMessenger);
    const platformOrientation = this.toPlatformDeviceOrientation(orientation);
    globalEventApi.deviceOrientationChanged(platformOrientation, { reply: (_) => {} });
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

  sendCameraInitializedEvent(
    previewWidth: number,
    previewHeight: number,
    exposureMode: ExposureMode,
    focusMode: FocusMode,
    exposurePointSupported: boolean,
    focusPointSupported: boolean) {
    if(previewWidth == null || previewHeight == null || exposureMode == null || focusMode == null ||exposurePointSupported==null || focusPointSupported == null){
      return;
    }

    let args: HashMap<String, Object> = new HashMap();
    args.set("previewWidth", previewWidth);
    args.set("previewHeight", previewHeight);
    args.set("exposureMode", 'auto');
    args.set("focusMode", 'auto');
    args.set("exposurePointSupported", exposurePointSupported);
    args.set("focusPointSupported", focusPointSupported);
    this.sendCameraEvent(CameraEventType.INITIALIZED, args);
  }

  sendCameraClosingEvent() {
    this.sendCameraEvent(CameraEventType.CLOSING);
  }

  sendCameraErrorEvent(description?: string) {
    const args: HashMap<String, Object> = new HashMap();
    if (description) {
      args.set('description', description);
    }
    this.sendCameraEvent(CameraEventType.ERROR, args);
  }

  sendCameraEvent(eventType: CameraEventType, args: HashMap<String, Object> = new HashMap()) {
    if (this.cameraChannel == null) {
      return;
    }
    this.cameraChannel.invokeMethod(eventType, args)
  }

  sendDeviceEvent(eventType: DeviceEventType, args: HashMap<String, Object> = new HashMap()) {
    if (this.deviceChannel == null) {
      return;
    }
    this.deviceChannel.invokeMethod(eventType, args)
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