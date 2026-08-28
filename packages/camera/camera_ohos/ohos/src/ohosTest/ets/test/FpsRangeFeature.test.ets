/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// FpsRangeFeature: target fps storage, null/invalid handling and profile fitting.

import { describe, it, expect } from '@ohos/hypium';
import { FpsRangeFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/fpsrange/FpsRangeFeature';
import { StubCameraProperties, makeVideoProfile } from './TestMocks';

export default function fpsRangeFeatureTest() {
  describe('FpsRangeFeatureTest', () => {
    it('getDebugName_returnsClassName', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('FpsRangeFeature');
    });

    it('value_defaultsToNullUntilSet', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      expect(feature.getValue() == null).assertTrue();
    });

    it('setValue_storesPositiveFps', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(30);
      expect(feature.getValue()).assertEqual(30);
      feature.setValue(60);
      expect(feature.getValue()).assertEqual(60);
    });

    it('setValue_nonNullNonPositiveResetsToNull', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(30);
      feature.setValue(null);
      expect(feature.getValue() == null).assertTrue();

      const zeroCase: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      zeroCase.setValue(0);
      expect(zeroCase.getValue() == null).assertTrue();

      const negativeCase: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      negativeCase.setValue(-15);
      expect(negativeCase.getValue() == null).assertTrue();
    });

    it('setValue_aboveReasonableRangeKeepsValueAndLetsDeviceClamp', 0, () => {
      // >240 only logs a warning; clamping is delegated to the device capability,
      // so the stored value must survive untouched (regression lock).
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(300);
      expect(feature.getValue()).assertEqual(300);
    });

    it('checkIsSupported_isAlwaysTrue', 0, () => {
      const unset: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      expect(unset.checkIsSupported()).assertTrue();

      const setCase: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      setCase.setValue(120);
      expect(setCase.checkIsSupported()).assertTrue();
    });

    it('supportsProfile_nullTargetSupportsAnyProfile', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080))).assertTrue();
      // Even a profile without a frame rate range is accepted while unset.
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080, undefined, undefined)))
        .assertTrue();
    });

    it('supportsProfile_rangeContainment', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(30);
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080, 10, 60))).assertTrue();
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080, 30, 30))).assertTrue();
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080, 15, 25))).assertFalse();
      expect(feature.supportsProfile(makeVideoProfile(1920, 1080, 45, 60))).assertFalse();
    });

    it('supportsProfile_profileWithoutRangeIsRejectedWhenTargetSet', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(30);
      expect(feature.supportsProfile(makeVideoProfile(1280, 720, undefined, undefined)))
        .assertFalse();
    });

    it('getPreferredFpsForProfile_nullTargetReturnsNull', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      expect(feature.getPreferredFpsForProfile(makeVideoProfile(1920, 1080, 10, 60)) == null)
        .assertTrue();
    });

    it('getPreferredFpsForProfile_profileWithoutRangePassesTargetThrough', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(24);
      expect(feature.getPreferredFpsForProfile(
        makeVideoProfile(1280, 720, undefined, undefined))).assertEqual(24);
    });

    it('getPreferredFpsForProfile_clampsToDeviceRange', 0, () => {
      const feature: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      feature.setValue(5);
      expect(feature.getPreferredFpsForProfile(makeVideoProfile(1920, 1080, 10, 60)))
        .assertEqual(10);

      const highCase: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      highCase.setValue(90);
      expect(highCase.getPreferredFpsForProfile(makeVideoProfile(1920, 1080, 10, 60)))
        .assertEqual(60);

      const inCase: FpsRangeFeature = new FpsRangeFeature(new StubCameraProperties());
      inCase.setValue(45);
      expect(inCase.getPreferredFpsForProfile(makeVideoProfile(1920, 1080, 10, 60)))
        .assertEqual(45);
    });
  });
}
