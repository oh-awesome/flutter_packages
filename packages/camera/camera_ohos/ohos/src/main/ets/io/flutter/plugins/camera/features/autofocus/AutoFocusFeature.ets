// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on AutoFocusFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import camera from '@ohos.multimedia.camera';
import { Log } from '@ohos/flutter_ohos';

export class AutoFocusFeature extends CameraFeature<camera.FocusMode> {
  private currentSetting: camera.FocusMode = camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
  private readonly recordingVideo: boolean;

  constructor(cameraProperties: CameraProperties, recordingVideo: boolean) {
    super(cameraProperties);
    this.recordingVideo = recordingVideo;
  }

  getDebugName(): string {
    return 'AutoFocusFeature';
  }

  setValue(value: camera.FocusMode): void {
    Log.d('AutoFocusFeature', 'setValue = ' + value)
    this.currentSetting = value;
  }

  getValue(): camera.FocusMode {
    Log.d('AutoFocusFeature', 'getValue = ' + this.currentSetting)
    return this.currentSetting;
  }

  public checkIsSupported(): boolean {
    // OHOS Camera Kit 支持 FocusMode（AUTO/CONTINUOUS_AUTO/LOCKED），对焦模式能力恒可用
    return true;
  }
}