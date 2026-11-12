// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on ExposurePointFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import { Point } from '../Point';
import { SensorOrientationFeature } from '../sensororientation/SensorOrientationFeature';
import camera from '@ohos.multimedia.camera';

export class ExposurePointFeature extends CameraFeature<Point> {
  private exposurePoint: Point = new Point(null, null);
  private readonly sensorOrientationFeature: SensorOrientationFeature;
  private defaultRegionsHasBeenSet: boolean = false;
  public defaultRegions: camera.Rect[] | null = null;

  constructor(
    cameraProperties: CameraProperties,
    sensorOrientationFeature: SensorOrientationFeature) {
    super(cameraProperties);
    this.sensorOrientationFeature = sensorOrientationFeature;
  }

  public getDebugName(): string {
    return 'ExposurePointFeature';
  }

  public getValue(): Point {
    return this.exposurePoint;
  }

  public setValue(value: Point): void {
    this.exposurePoint = (value == null || value.x == null || value.y == null) ? new Point(null, null) : value;
  }

  public checkIsSupported(): boolean {
    let supportedRegions = this.cameraProperties.getControlMaxRegionsAutoExposure();
    return supportedRegions != null && supportedRegions > 0;
  }

  public updateBuilder(): void {
    // todo:??

  }
}
