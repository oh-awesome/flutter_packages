// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on DeviceOrientationManager.java originally written by
// Copyright 2013 The Flutter Authors.

import Ability from '@ohos.app.ability.Ability';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import display from '@ohos.display';

import { BusinessError, Callback } from '@ohos.base';

import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { CameraGlobalEventApi, PlatformDeviceOrientation } from '../../Messages';

const handleOrientationChange = (
  newOrientation: DeviceOrientation,
  previousOrientation: DeviceOrientation,
  globalEventApi: CameraGlobalEventApi) => {
  if (newOrientation !== previousOrientation) {
    let platformOrientation: PlatformDeviceOrientation;
    switch (newOrientation) {
      case DeviceOrientation.PORTRAIT_UP:
        platformOrientation = PlatformDeviceOrientation.portraitUp;
        break;
      case DeviceOrientation.PORTRAIT_DOWN:
        platformOrientation = PlatformDeviceOrientation.portraitDown;
        break;
      case DeviceOrientation.LANDSCAPE_LEFT:
        platformOrientation = PlatformDeviceOrientation.landscapeLeft;
        break;
      case DeviceOrientation.LANDSCAPE_RIGHT:
        platformOrientation = PlatformDeviceOrientation.landscapeRight;
        break;
      default:
        platformOrientation = PlatformDeviceOrientation.portraitUp;
        break;
    }
    let callback: Reply<void> = {
      reply: (result: void | null) => {}
    };
    globalEventApi.deviceOrientationChanged(platformOrientation, callback);
  }
}


export class DeviceOrientationManager {
  // private static readonly orientationIntentFilter: IntentFilter =
  //   new IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED);
  private readonly ability: Ability;
  private readonly binaryMessenger: BinaryMessenger;
  private readonly isFrontFacing: boolean;
  private readonly sensorOrientation: number;
  private lastOrientation: DeviceOrientation = DeviceOrientation.PORTRAIT_UP;
  private displayClass: display.Display | null = null;
  private globalEventApi: CameraGlobalEventApi | null = null;


  public static create(
    ability: Ability,
    binaryMessenger: BinaryMessenger,
    isFrontFacing: boolean,
    sensorOrientation: number
  ): DeviceOrientationManager {
    return new DeviceOrientationManager(ability, binaryMessenger, isFrontFacing, sensorOrientation);
  }

  constructor(
    ability: Ability,
    binaryMessenger: BinaryMessenger,
    isFrontFacing: boolean,
    sensorOrientation: number) {
    this.ability = ability;
    this.binaryMessenger = binaryMessenger;
    this.isFrontFacing = isFrontFacing;
    this.sensorOrientation = sensorOrientation;
    this.globalEventApi = new CameraGlobalEventApi(binaryMessenger);
  }

  public start() {
    this.handleUIOrientationChange();
    let callback: Callback<number> = (data: number) => {
      this.handleUIOrientationChange();
    };
    display.on('change', callback)
  }

  public stop() {
    display.off('change');
    this.displayClass = null;
  }

  public getPhotoOrientation(orientation?: DeviceOrientation) {
    if (orientation === undefined) {
      return this.lastOrientation;
    }
    let angle: number = 0;
    if (orientation == null) {
      orientation = this.getUIOrientation();
    }
    switch (orientation) {
      case DeviceOrientation.PORTRAIT_UP:
        angle = 90;
        break;
      case DeviceOrientation.PORTRAIT_DOWN:
        angle = 270;
        break;
      case DeviceOrientation.LANDSCAPE_LEFT:
        angle = this.isFrontFacing ? 180 : 0;
        break;
      case DeviceOrientation.LANDSCAPE_RIGHT:
        angle = this.isFrontFacing ? 0 : 180;
        break;
    }
    return (angle + this.sensorOrientation + 270) % 360;
  }


  public getVideoOrientation(orientation?: DeviceOrientation): number {


    let angle: number = 0;

    // Fallback to device orientation when the orientation value is null.
    if (orientation == null) {
      orientation = this.getUIOrientation();
    }

    switch (orientation) {
      case DeviceOrientation.PORTRAIT_UP:
        angle = 0;
        break;
      case DeviceOrientation.PORTRAIT_DOWN:
        angle = 180;
        break;
      case DeviceOrientation.LANDSCAPE_LEFT:
        angle = 270;
        break;
      case DeviceOrientation.LANDSCAPE_RIGHT:
        angle = 90;
        break;
    }

    if (this.isFrontFacing) {
      angle *= -1;
    }

    return (angle + this.sensorOrientation + 360) % 360;
  }

  public getLastUIOrientation(): DeviceOrientation {
    return this.lastOrientation;
  }

  handleUIOrientationChange() {
    let orientation: DeviceOrientation = this.getUIOrientation();
    if (this.globalEventApi) {
      handleOrientationChange(orientation, this.lastOrientation, this.globalEventApi);
    }
    this.lastOrientation = orientation;
  }

  getUIOrientation(): DeviceOrientation {
    const rotation: number | undefined = display.getDefaultDisplaySync().rotation;
    const orientation: display.Orientation | undefined = display.getDefaultDisplaySync().orientation
    switch (rotation) {
      case display.Orientation.PORTRAIT:
        return DeviceOrientation.PORTRAIT_UP;
      case display.Orientation.LANDSCAPE:
        return DeviceOrientation.LANDSCAPE_LEFT;
      case display.Orientation.PORTRAIT_INVERTED:
        return DeviceOrientation.PORTRAIT_DOWN;
      case display.Orientation.LANDSCAPE_INVERTED:
        return DeviceOrientation.LANDSCAPE_RIGHT;
      default:
        return DeviceOrientation.PORTRAIT_UP;
    }
  }
}
