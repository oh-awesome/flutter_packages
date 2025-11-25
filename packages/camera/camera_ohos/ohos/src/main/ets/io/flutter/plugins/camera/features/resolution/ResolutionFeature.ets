// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on ResolutionFeature.java originally written by
// Copyright 2013 The Flutter Authors.

import camera from '@ohos.multimedia.camera';
import { CameraFeature } from '../CameraFeature';
import { ResolutionPreset } from './ResolutionPreset';
import { CameraProperties } from '../../CameraProperties';

export class VideoSessionProfile {
  private previewProfile: camera.Profile | undefined = undefined;
  private captureProfile: camera.VideoProfile | undefined = undefined;

  public setPreviewProfile(profile: camera.Profile): void {
    this.previewProfile = profile;
  }

  public getPreviewProfile(): camera.Profile | undefined {
    return this.previewProfile;
  }

  public setCaptureProfile(profile: camera.VideoProfile): void {
    this.captureProfile = profile;
  }

  public getCaptureProfile(): camera.VideoProfile | undefined {
    return this.captureProfile;
  }
}

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
      return profile.size.width === presetSize!.width && profile.size.height === presetSize!.height
    });
    if (index >= 0) { return index; }

    index = 0;
    tempWidth = 0;
    let minDiff = Number.MAX_VALUE;
    for (let i = 0; i < profiles.length; i++) {
      const widthDiff = presetSize!.width - profiles[i].size.width;
      const heightDiff = presetSize!.height - profiles[i].size.height;
      const diff = widthDiff * widthDiff + heightDiff * heightDiff;

      if (diff < minDiff) {
        minDiff = diff;
        index = i;
      }
    }
    return index;
  }

  public getVideoSessionProfile(
    previewProfilesArray: Array<camera.Profile>,
    videoProfilesArray: Array<camera.VideoProfile>): VideoSessionProfile {

    // Collect all preview configuration ratios.
    const previewAspectRatios: Set<string> = new Set();
    previewProfilesArray.forEach((profile: camera.Profile) => {
      const aspectRatio = this.simplifyAspectRatio(profile.size.width, profile.size.height);
      previewAspectRatios.add(aspectRatio);
    });

    const presetSize: camera.Size | undefined = ResolutionFeature.PRESET_SIZE_MAP.get(this.currentSetting);

    let bestVideoProfile: camera.VideoProfile | undefined = undefined;
    let bestPreviewProfile: camera.Profile | undefined = undefined;
    let minDifference = Number.MAX_VALUE;

    // Iterate through all recording profiles to retrieve the optimal recording resolution.
    for (let i = 0; i < videoProfilesArray.length; i++) {
      const videoProfile = videoProfilesArray[i];
      const videoAspectRatio = this.simplifyAspectRatio(videoProfile.size.width, videoProfile.size.height);

      // Check if the video ratio exists in the preview configuration.
      if (!previewAspectRatios.has(videoAspectRatio)) {
        continue;
      }

      // Check if it exactly matches the preset resolution.
      if (presetSize &&
        videoProfile.size.width === presetSize.width &&
        videoProfile.size.height === presetSize.height) {
        bestVideoProfile = videoProfile;
        break;
      }

      const difference = presetSize ? this.calculateDifference(videoProfile, presetSize) : 0;
      if (difference < minDifference) {
        minDifference = difference;
        bestVideoProfile = videoProfile;
      }
    }
    bestPreviewProfile = this.findMatchingPreviewProfile(previewProfilesArray, bestVideoProfile!);

    // If it does not match, set it to the default value.
    if (!bestVideoProfile || !bestPreviewProfile) {
      bestVideoProfile = videoProfilesArray.find(profile =>
      profile.size.width === 1920 &&
        profile.size.height === 1080 &&
        profile.format === camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP
      );
      bestPreviewProfile = previewProfilesArray.find(profile =>
      profile.size.width === 1920 &&
        profile.size.height === 1080 &&
        profile.format === camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP
      );
    }

    const videoSessionProfile: VideoSessionProfile = new VideoSessionProfile();
    videoSessionProfile.setPreviewProfile(bestPreviewProfile!);
    videoSessionProfile.setCaptureProfile(bestVideoProfile!);
    return videoSessionProfile;
  }

  private findMatchingPreviewProfile(
    previewProfiles: Array<camera.Profile>,
    videoProfile: camera.VideoProfile): camera.Profile | undefined {

    const targetRatio = this.simplifyAspectRatio(videoProfile.size.width, videoProfile.size.height);
    const targetWidth = videoProfile.size.width;
    let closestPreview: camera.Profile | undefined = undefined;
    let minWidthDiff = Number.MAX_VALUE;

    for (const profile of previewProfiles) {
      const ratio = this.simplifyAspectRatio(profile.size.width, profile.size.height);
      if (ratio === targetRatio) {
        const widthDiff = Math.abs(profile.size.width - targetWidth);
        if (widthDiff === 0) {
          closestPreview = profile;
          break;
        }
        if (widthDiff < minWidthDiff) {
          minWidthDiff = widthDiff;
          closestPreview = profile;
        }
      }
    }
    return closestPreview;
  }

  private simplifyAspectRatio(width: number, height: number): string {
    const gcd = (a: number, b: number): number => {
      return b === 0 ? a : gcd(b, a % b);
    };
    const divisor = gcd(width, height);
    const simplifiedWidth = width / divisor;
    const simplifiedHeight = height / divisor;
    return `${simplifiedWidth}:${simplifiedHeight}`;
  }

  private calculateDifference(profile: camera.VideoProfile, presetSize: camera.Size): number {
    const widthDiff = profile.size.width - presetSize.width;
    const heightDiff = profile.size.height - presetSize.height;
    return widthDiff * widthDiff + heightDiff * heightDiff;
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
