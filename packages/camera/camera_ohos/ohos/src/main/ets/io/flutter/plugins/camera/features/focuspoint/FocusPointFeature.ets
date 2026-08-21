// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on FocusPointFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { Point } from '../Point';
import { CameraFeature } from '../CameraFeature';
import { CameraProperties } from '../../CameraProperties';
import { SensorOrientationFeature } from '../sensororientation/SensorOrientationFeature';

export class FocusPointFeature extends CameraFeature<Point> {
  private focusPoint: Point | null = null;
  private readonly sensorOrientationFeature: SensorOrientationFeature;

  constructor(cameraProperties: CameraProperties, sensorOrientationFeature: SensorOrientationFeature) {
    super(cameraProperties);
    this.sensorOrientationFeature = sensorOrientationFeature;
  }

  public getDebugName(): string {
    return 'FocusPointFeature';
  }

  public getValue(): Point {
    return this.focusPoint == null ? new Point(null, null) : this.focusPoint; // todo:
  }

  public setValue(value: Point): void {
    this.focusPoint = value == null || value.x == null || value.y == null ? null : value;
  }

  public checkIsSupported(): boolean {
    let supportedRegions: number = this.cameraProperties.getControlMaxRegionsAutoFocus();
    return supportedRegions != null && supportedRegions > 0;
  }
}
