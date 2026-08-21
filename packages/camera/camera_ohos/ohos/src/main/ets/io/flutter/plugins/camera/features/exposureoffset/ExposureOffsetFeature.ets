// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on ExposureOffsetFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import camera from '@ohos.multimedia.camera';
import { CameraUtils } from '../../CameraUtils';

export class ExposureOffsetFeature extends CameraFeature<Number> {
  private currentSetting: number = 0;

  constructor(cameraProperties: CameraProperties) {
    super(cameraProperties)
  }

  public getDebugName(): string {
    return 'ExposureOffsetFeature';
  }

  public getValue(): Number {
    return this.currentSetting;
  }

  public checkIsSupported(): boolean {
    return true;
  }

  public setValue(value: number, captureSession: camera.PhotoSession | camera.VideoSession): void {
    // currentSetting 存实际应用 EV 值：Dart 侧 CameraController.setExposureOffset 已按 stepSize 取整后
    // 传入 EV 值，Camera.setExposureOffset 用 session.setExposureBias(value) 应用的正是该值。
    // 此前此处换算成步进索引（value/stepSize），导致 setExposureOffset 返回值与契约（返回实
    // 际应用值）不符。
    this.currentSetting = value;
  }


  public getMinExposureOffset(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return CameraUtils.getMinExposureBias(captureSession);
  }

  public getMaxExposureOffset(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return CameraUtils.getMaxExposureBias(captureSession);
  }

  public getExposureOffsetStepSize(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return CameraUtils.getExposureBiasStep(captureSession);
  }
}