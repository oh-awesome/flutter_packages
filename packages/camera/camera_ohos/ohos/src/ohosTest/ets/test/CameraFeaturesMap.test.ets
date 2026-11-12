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

// CameraFeatures registry behavior plus a full factory-driven init round.

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { CameraFeatures } from
  '../../../main/ets/io/flutter/plugins/camera/features/CameraFeatures';
import { CameraFeatureFactoryImpl } from
  '../../../main/ets/io/flutter/plugins/camera/features/CameraFeatureFactoryImpl';
import { AutoFocusFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/autofocus/AutoFocusFeature';
import { FpsRangeFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/fpsrange/FpsRangeFeature';
import { ResolutionFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/resolution/ResolutionFeature';
import { VideoStabilizationFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/videostabilization/VideoStabilizationFeature';
import { ResolutionPreset } from
  '../../../main/ets/io/flutter/plugins/camera/features/resolution/ResolutionPreset';
import { DartMessenger } from '../../../main/ets/io/flutter/plugins/camera/DartMessenger';
import {
  MockBinaryMessenger,
  StubCameraProperties,
  makeFakeAbility
} from './TestMocks';

export default function cameraFeaturesMapTest() {
  describe('CameraFeaturesMapTest', () => {
    let registry: CameraFeatures = new CameraFeatures();

    it('gettersReturnUndefinedBeforeAnySetter', 0, () => {
      const fresh: CameraFeatures = new CameraFeatures();
      expect(fresh.getAutoFocus() == undefined).assertTrue();
      expect(fresh.getFpsRange() == undefined).assertTrue();
      expect(fresh.getVideoStabilization() == undefined).assertTrue();
    });

    it('setGetPairsReturnSameReference', 0, () => {
      const props: StubCameraProperties = new StubCameraProperties();

      const autoFocus: AutoFocusFeature = new AutoFocusFeature(props, false);
      registry.setAutoFocus(autoFocus);
      expect(registry.getAutoFocus() === autoFocus).assertTrue();

      const fpsRange: FpsRangeFeature = new FpsRangeFeature(props);
      registry.setFpsRange(fpsRange);
      expect(registry.getFpsRange() === fpsRange).assertTrue();

      const stabilization: VideoStabilizationFeature = new VideoStabilizationFeature(props);
      registry.setVideoStabilization(stabilization);
      expect(registry.getVideoStabilization() === stabilization).assertTrue();
    });

    it('setterOverwritesPreviousEntry', 0, () => {
      const props: StubCameraProperties = new StubCameraProperties();
      const first: FpsRangeFeature = new FpsRangeFeature(props);
      const second: FpsRangeFeature = new FpsRangeFeature(props);

      registry.setFpsRange(first);
      registry.setFpsRange(second);
      expect(registry.getFpsRange() === second).assertTrue();
    });

    describe('CameraFeaturesInit', () => {
      // Real factory wiring; the only place the display-listening SensorOrientationFeature
      // is constructed, disposed again once all cases have run.
      let features: CameraFeatures | null = null;

      beforeAll(() => {
        const props: StubCameraProperties = new StubCameraProperties();
        const messenger: DartMessenger =
          new DartMessenger(new MockBinaryMessenger());
        features = CameraFeatures.init(
          new CameraFeatureFactoryImpl(), props, makeFakeAbility(), messenger,
          ResolutionPreset.high);
      });

      afterAll(() => {
        if (features != null) {
          const sensorOrientation = features.getSensorOrientation();
          if (sensorOrientation != null && sensorOrientation != undefined) {
            sensorOrientation.dispose();
          }
        }
      });

      it('initPopulatesEveryFeatureGetter', 0, () => {
        const initialized: CameraFeatures = features as CameraFeatures;
        expect(initialized.getAutoFocus() != null).assertTrue();
        expect(initialized.getExposureLock() != null).assertTrue();
        expect(initialized.getExposureOffset() != null).assertTrue();
        expect(initialized.getExposurePoint() != null).assertTrue();
        expect(initialized.getFlash() != null).assertTrue();
        expect(initialized.getFocusPoint() != null).assertTrue();
        expect(initialized.getFpsRange() != null).assertTrue();
        expect(initialized.getNoiseReduction() != null).assertTrue();
        expect(initialized.getSensorOrientation() != null).assertTrue();
        expect(initialized.getZoomLevel() != null).assertTrue();
        expect(initialized.getResolution() != null).assertTrue();
        expect(initialized.getVideoStabilization() != null).assertTrue();
      });

      it('initWiresDefaultValuesMatchingDirectConstruction', 0, () => {
        const initialized: CameraFeatures = features as CameraFeatures;
        expect(initialized.getAutoFocus().getValue())
          .assertEqual(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
        expect(initialized.getFlash().getValue()).assertEqual(camera.FlashMode.FLASH_MODE_AUTO);
        expect(initialized.getZoomLevel().getValue()).assertEqual(1.0);
        expect(initialized.getSensorOrientation().getValue()).assertEqual(90);
        expect(initialized.getExposureLock().checkIsSupported()).assertTrue();
      });
    });
  });
}
