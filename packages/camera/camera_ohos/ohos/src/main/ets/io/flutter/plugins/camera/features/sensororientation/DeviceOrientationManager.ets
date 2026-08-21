// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on DeviceOrientationManager.java originally written by
// Copyright 2013 The Flutter Authors.

import Ability from '@ohos.app.ability.Ability';
import { DartMessenger } from '../../DartMessenger';
import display from '@ohos.display';

import { BusinessError, Callback } from '@ohos.base';

import { DeviceOrientation } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';

const handleOrientationChange = (
  newOrientation: DeviceOrientation,
  previousOrientation: DeviceOrientation,
  messenger: DartMessenger) => {
  if (newOrientation !== previousOrientation) {
    messenger.sendDeviceOrientationChangeEvent(newOrientation);
  }
}


export class DeviceOrientationManager {
  private readonly ability: Ability;
  private readonly messenger: DartMessenger;
  private readonly isFrontFacing: boolean;
  private readonly sensorOrientation: number;
  private lastOrientation: DeviceOrientation = DeviceOrientation.PORTRAIT_UP;
  private displayClass: display.Display | null = null;
  private displayChangeCallback: Callback<number> | null = null;
  private started: boolean = false;


  public static create(
    ability: Ability,
    messenger: DartMessenger,
    isFrontFacing: boolean,
    sensorOrientation: number
  ): DeviceOrientationManager {
    return new DeviceOrientationManager(ability, messenger, isFrontFacing, sensorOrientation);
  }

  constructor(
    ability: Ability,
    messenger: DartMessenger,
    isFrontFacing: boolean,
    sensorOrientation: number) {
    this.ability = ability;
    this.messenger = messenger;
    this.isFrontFacing = isFrontFacing;
    this.sensorOrientation = sensorOrientation;
  }

  public start() {
    if (this.started) {
      return;
    }
    this.handleUIOrientationChange();
    this.displayChangeCallback = (data: number) => {
      this.handleUIOrientationChange();
    };
    display.on('change', this.displayChangeCallback);
    this.started = true;
  }

  public stop() {
    if (!this.started) {
      return;
    }
    if (this.displayChangeCallback != null) {
      display.off('change', this.displayChangeCallback);
      this.displayChangeCallback = null;
    }
    this.displayClass = null;
    this.started = false;
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
    handleOrientationChange(orientation, this.lastOrientation, this.messenger);
    this.lastOrientation = orientation;
  }

  getUIOrientation(): DeviceOrientation {
    const rotation: number | undefined = display.getDefaultDisplaySync().rotation;
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