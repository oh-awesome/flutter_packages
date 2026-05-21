// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on FpsRangeFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import camera from '@ohos.multimedia.camera';
import { CameraFeature } from '../CameraFeature';

const TAG = 'FpsRangeFeature'

export class FpsRangeFeature extends CameraFeature<number | null> {
  // 用户期望的帧率；null 表示沿用设备默认策略。
  private targetFps: number | null = null;

  public getDebugName(): string {
    return "FpsRangeFeature";
  }

  public getValue(): number | null {
    console.log(TAG, `getValue this.targetFps = ${this.targetFps}`)
    return this.targetFps;
  }

  public setValue(value: number | null): void {
    console.log(TAG, `setValue value = ${value}`);

    // 非正数视为未设置
    if (value == null || value <= 0) {
      this.targetFps = null;
      return;
    }

    // 合理性检查：常见视频帧率范围是 1-240fps
    const MAX_REASONABLE_FPS = 240;
    if (value > MAX_REASONABLE_FPS) {
      console.warn(TAG, `setValue: fps value ${value} exceeds reasonable range (>${MAX_REASONABLE_FPS}), will be clamped by device capability`);
    }

    this.targetFps = value;
  }

  public checkIsSupported(): boolean {
    return this.targetFps == null || this.targetFps > 0;
  }

  public supportsProfile(profile: camera.VideoProfile): boolean {
    console.log(TAG, `supportsProfile this.targetFps = ${this.targetFps}`)
    if (this.targetFps == null) {
      return true;
    }

    const range = this.getFrameRateRange(profile);
    if (range == null) {
      return false;
    }

    return this.targetFps >= range.min && this.targetFps <= range.max;
  }

  public getPreferredFpsForProfile(profile: camera.VideoProfile): number | null {
    console.log(TAG, `getPreferredFpsForProfile this.targetFps = ${this.targetFps}`)
    if (this.targetFps == null) {
      return null;
    }

    const range = this.getFrameRateRange(profile);
    if (range == null) {
      return this.targetFps;
    }

    if (this.targetFps < range.min) {
      // 低于设备下限时提升到下限。
      return range.min;
    }
    if (this.targetFps > range.max) {
      // 高于设备上限时压到上限。
      return range.max;
    }
    return this.targetFps;
  }

  private getFrameRateRange(profile: camera.VideoProfile): camera.FrameRateRange {
    return profile.frameRateRange;
  }
}