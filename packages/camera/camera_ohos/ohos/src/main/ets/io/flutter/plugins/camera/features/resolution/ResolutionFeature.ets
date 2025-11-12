/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import camera from '@ohos.multimedia.camera';
import { CameraFeature } from '../CameraFeature';
import { ResolutionPreset } from './ResolutionPreset';
import { CameraProperties } from '../../CameraProperties';


export class ResolutionFeature extends CameraFeature<ResolutionPreset> {
  private captureSize: camera.Size = { width: 1920, height: 1080 } as camera.Size;
  private previewSize: camera.Size = { width: 1920, height: 1080 } as camera.Size;
  private currentSetting: ResolutionPreset;
  private cameraId: string | null;

  static readonly PRESET_SIZE_MAP: ReadonlyMap<ResolutionPreset, camera.Size> = new Map([
    [ResolutionPreset.low, { width: 320, height: 240 } as camera.Size],
    [ResolutionPreset.medium, { width: 720, height: 480 } as camera.Size],
    [ResolutionPreset.high, { width: 1280, height: 720 } as camera.Size],
    [ResolutionPreset.veryHigh, { width: 1920, height: 1080 } as camera.Size],
    [ResolutionPreset.ultraHigh, { width: 3840, height: 2160 } as camera.Size],
  ]) as ReadonlyMap<ResolutionPreset, camera.Size>;

  constructor(
    cameraProperties: CameraProperties,
    resolutionPreset: ResolutionPreset,
    cameraName: string) {
    super(cameraProperties);
    this.currentSetting = resolutionPreset;

    if (cameraName == null) {
      this.cameraId = null;
      return;
    }

    this.cameraId = cameraName;
  }

  public getPreviewSize(): camera.Size {
    return this.previewSize;
  }

  public setPreviewSize(size: camera.Size): void {
    this.previewSize = {
      width: size!.width,
      height: size!.height
    };
  }

  public getCaptureSize(): camera.Size {
    return this.captureSize;
  }

  public setCaptureSize(size: camera.Size): void {
    this.captureSize = {
      width: size!.width,
      height: size!.height
    };
  }

  public getPreviewProfileIndex(profiles: Array<camera.Profile>): number {
    if (this.currentSetting > ResolutionPreset.veryHigh) {
      return this.getBestAvailableProfileIndex(profiles, ResolutionPreset.veryHigh);
    } else {
      return this.getBestAvailableProfileIndex(profiles, this.currentSetting);
    }
  }

  public getPhotoProfileIndex(profiles: Array<camera.Profile>): number {
    return this.getBestAvailableProfileIndex(profiles, this.currentSetting);
  }

  public getBestAvailableProfileIndex(profiles: Array<camera.Profile>, preset: ResolutionPreset): number {
    let index: number = 0;
    let tempWidth: number = 0;
    if (preset === ResolutionPreset.max) {
      for (let i = 0; i < profiles.length; i++) {
        if (profiles[i].size.width > tempWidth) {
          tempWidth = profiles[i].size.width;
          index = i;
        } else if (profiles[i].size.width === tempWidth && profiles[i].size.height > profiles[index].size.height) {
          index = i;
        }
      }
      return index;
    }

    let presetSize: camera.Size | undefined = ResolutionFeature.PRESET_SIZE_MAP.get(preset);
    index = profiles.findIndex(profile => {
      profile.size.width === presetSize!.width && profile.size.height === presetSize!.height
    });
    if (index >= 0) { return index; }

    index = 0;
    tempWidth = 0;
    for (let i = 0; i < profiles.length; i++) {
      if (Math.abs(presetSize!.width - profiles[i].size.width) < Math.abs(presetSize!.width - tempWidth)) {
        tempWidth = profiles[i].size.width;
        index = i;
      }
    }
    return index;
  }

  public getDebugName(): string {
    return "ResolutionFeature";

  }

  public setValue(value: ResolutionPreset): void {
    this.currentSetting = value;
  }

  public getValue(): ResolutionPreset {
    return this.currentSetting;
  }

  public checkIsSupported(): boolean {
    return this.cameraId != null;
  }
}
