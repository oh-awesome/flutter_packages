// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on FlashFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import camera from '@ohos.multimedia.camera';

export class FlashFeature extends CameraFeature<camera.FlashMode> {
  private currentSetting: camera.FlashMode = camera.FlashMode.FLASH_MODE_AUTO;

  constructor(cameraProperties: CameraProperties) {
    super(cameraProperties)
  }

  public getDebugName(): string {
    return 'FlashFeature';
  }

  public getValue(): camera.FlashMode {
    return this.currentSetting;
  }

  public setValue(value: camera.FlashMode): void {
    this.currentSetting = value;
  }

  public checkIsSupported(): boolean {
    // OHOS Camera Kit 支持 FlashMode（CLOSE/OPEN/AUTO/ALWAYS_OPEN）；
    // 是否真正带闪光灯由运行时 session.hasFlash() 判断，这里恒可用
    return true;
  }
}