// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on ZoomLevelFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import { CameraUtils } from '../../CameraUtils';
import camera from '@ohos.multimedia.camera';

const DEFAULT_ZOOM_LEVEL = 1.0;

export class ZoomLevelFeature extends CameraFeature<number> {
  private readonly hasSupport: boolean = false;
  private currentSetting: number = DEFAULT_ZOOM_LEVEL;
  private minimumZoomLevel: number = this.currentSetting;
  private readonly maximumZoomLevel: number;

  constructor(cameraProperties: CameraProperties) {
    super(cameraProperties);
    // 最小/最大变焦范围运行时由 CameraUtils.getZoomRatioRange 从 session 读取
    // （见 getMinimumZoomLevel/getMaximumZoomLevel），此处仅设置构造期默认值。
    this.minimumZoomLevel = 0;
    this.maximumZoomLevel = 1;
    this.hasSupport = true;
  }

  public getDebugName(): string {
    return 'ZoomLevelFeature';
  }

  public getValue(): number {
    return this.currentSetting;
  }

  public setValue(value: number): void {
    this.currentSetting = value;
  }

  public checkIsSupported(): boolean {
    return this.hasSupport;
  }

  public getMinimumZoomLevel(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return CameraUtils.getMinZoomRatio(captureSession);
  }

  public getMaximumZoomLevel(captureSession: camera.PhotoSession | camera.VideoSession): number {
    return CameraUtils.getMaxZoomRatio(captureSession);
  }
}