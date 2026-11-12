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

// Per-feature getValue/setValue contracts and support flags, with a stubbed
// CameraProperties so no session or device is required.

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { FlashFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/flash/FlashFeature';
import { AutoFocusFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/autofocus/AutoFocusFeature';
import { ExposureLockFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/exposurelock/ExposureLockFeature';
import { ExposureOffsetFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/exposureoffset/ExposureOffsetFeature';
import { ExposurePointFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/exposurepoint/ExposurePointFeature';
import { FocusPointFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/focuspoint/FocusPointFeature';
import { ZoomLevelFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/zoomlevel/ZoomLevelFeature';
import { NoiseReductionFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/noisereduction/NoiseReductionFeature';
import { VideoStabilizationFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/videostabilization/VideoStabilizationFeature';
import { Point } from '../../../main/ets/io/flutter/plugins/camera/features/Point';
import { NoiseReductionMode } from
  '../../../main/ets/io/flutter/plugins/camera/features/noisereduction/NoiseReductionMode';
import { SensorOrientationFeature } from
  '../../../main/ets/io/flutter/plugins/camera/features/sensororientation/SensorOrientationFeature';
import { PlatformVideoStabilizationMode } from
  '../../../main/ets/io/flutter/plugins/camera/Messages';
import {
  StubCameraProperties,
  makeQuerySession,
  makeThrowingQuerySession,
  makeFakeVideoSession,
  makeCrashingVideoSession,
  shellAppliedModes
} from './TestMocks';

const SENSOR_ORIENTATION_STUB: SensorOrientationFeature =
  (new Object() as ESObject) as SensorOrientationFeature;

export default function featuresSetGetTest() {
  describe('FeaturesSetGetTest', () => {
    it('flashFeature_defaultsToAutoAndRoundTrips', 0, () => {
      const feature: FlashFeature = new FlashFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('FlashFeature');
      expect(feature.getValue()).assertEqual(camera.FlashMode.FLASH_MODE_AUTO);
      feature.setValue(camera.FlashMode.FLASH_MODE_OPEN);
      expect(feature.getValue()).assertEqual(camera.FlashMode.FLASH_MODE_OPEN);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('autoFocusFeature_defaultsToContinuousForBothRecordingFlags', 0, () => {
      const photo: AutoFocusFeature = new AutoFocusFeature(new StubCameraProperties(), false);
      const video: AutoFocusFeature = new AutoFocusFeature(new StubCameraProperties(), true);
      expect(photo.getDebugName()).assertEqual('AutoFocusFeature');
      expect(photo.getValue()).assertEqual(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
      expect(video.getValue()).assertEqual(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
    });

    it('autoFocusFeature_roundTripsSingleShotAndLocked', 0, () => {
      const feature: AutoFocusFeature = new AutoFocusFeature(new StubCameraProperties(), false);
      feature.setValue(camera.FocusMode.FOCUS_MODE_AUTO);
      expect(feature.getValue()).assertEqual(camera.FocusMode.FOCUS_MODE_AUTO);
      feature.setValue(camera.FocusMode.FOCUS_MODE_LOCKED);
      expect(feature.getValue()).assertEqual(camera.FocusMode.FOCUS_MODE_LOCKED);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('exposureLockFeature_defaultsToAutoAndRoundTrips', 0, () => {
      const feature: ExposureLockFeature = new ExposureLockFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('ExposureLockFeature');
      expect(feature.getValue()).assertEqual(camera.ExposureMode.EXPOSURE_MODE_AUTO);
      feature.setValue(camera.ExposureMode.EXPOSURE_MODE_LOCKED);
      expect(feature.getValue()).assertEqual(camera.ExposureMode.EXPOSURE_MODE_LOCKED);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('exposureOffsetFeature_storesAppliedEvWithoutStepConversion', 0, () => {
      // Regression lock: the value handed down by Dart is already the applied EV;
      // storing must not divide by the step size again.
      const feature: ExposureOffsetFeature = new ExposureOffsetFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('ExposureOffsetFeature');
      expect(feature.getValue()).assertEqual(0);
      // The optional session parameter is never dereferenced while storing.
      const noSession: camera.PhotoSession = (null as ESObject) as camera.PhotoSession;
      feature.setValue(1.5, noSession);
      expect(feature.getValue()).assertEqual(1.5);
      feature.setValue(-2, noSession);
      expect(feature.getValue()).assertEqual(-2);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('exposurePointFeature_keepsValidPointReference', 0, () => {
      const props: StubCameraProperties = new StubCameraProperties();
      const feature: ExposurePointFeature = new ExposurePointFeature(props, SENSOR_ORIENTATION_STUB);
      expect(feature.getDebugName()).assertEqual('ExposurePointFeature');
      expect(feature.getValue().x == null).assertTrue();
      expect(feature.getValue().y == null).assertTrue();

      const point: Point = new Point(0.5, 0.25);
      feature.setValue(point);
      expect(feature.getValue() === point).assertTrue();
      expect(feature.getValue().x).assertEqual(0.5);
    });

    it('exposurePointFeature_normalizesNullAndPartialCoordinates', 0, () => {
      const props: StubCameraProperties = new StubCameraProperties();
      const feature: ExposurePointFeature = new ExposurePointFeature(props, SENSOR_ORIENTATION_STUB);
      // The implementation tolerates a null value even though the parameter is non-nullable.
      const nullPoint: Point = (null as ESObject) as Point;
      feature.setValue(nullPoint);
      expect(feature.getValue().x == null).assertTrue();
      expect(feature.getValue().y == null).assertTrue();

      // Any null coordinate component resets the whole point.
      feature.setValue(new Point(0.9, null));
      expect(feature.getValue().x == null).assertTrue();
      expect(feature.getValue().y == null).assertTrue();
    });

    it('exposurePointFeature_supportFollowsExposureRegions', 0, () => {
      const zeroRegions: StubCameraProperties = new StubCameraProperties();
      zeroRegions.maxRegionsAutoExposure = 0;
      expect(new ExposurePointFeature(zeroRegions, SENSOR_ORIENTATION_STUB).checkIsSupported())
        .assertFalse();

      const oneRegion: StubCameraProperties = new StubCameraProperties();
      oneRegion.maxRegionsAutoExposure = 1;
      expect(new ExposurePointFeature(oneRegion, SENSOR_ORIENTATION_STUB).checkIsSupported())
        .assertTrue();
    });

    it('focusPointFeature_getValueFallsBackWhenUnset', 0, () => {
      const feature: FocusPointFeature =
        new FocusPointFeature(new StubCameraProperties(), SENSOR_ORIENTATION_STUB);
      expect(feature.getDebugName()).assertEqual('FocusPointFeature');
      expect(feature.getValue() != null).assertTrue();
      expect(feature.getValue().x == null).assertTrue();

      const point: Point = new Point(0.1, 0.2);
      feature.setValue(point);
      expect(feature.getValue() === point).assertTrue();
    });

    it('focusPointFeature_clearsOnNullOrPartialPoint', 0, () => {
      const feature: FocusPointFeature =
        new FocusPointFeature(new StubCameraProperties(), SENSOR_ORIENTATION_STUB);
      const nullPoint: Point = (null as ESObject) as Point;
      feature.setValue(new Point(0.3, 0.4));
      feature.setValue(nullPoint);
      expect(feature.getValue().x == null).assertTrue();

      feature.setValue(new Point(0.3, 0.4));
      feature.setValue(new Point(null, 0.4));
      expect(feature.getValue().x == null).assertTrue();
    });

    it('focusPointFeature_supportFollowsFocusRegions', 0, () => {
      const zeroRegions: StubCameraProperties = new StubCameraProperties();
      zeroRegions.maxRegionsAutoFocus = 0;
      expect(new FocusPointFeature(zeroRegions, SENSOR_ORIENTATION_STUB).checkIsSupported())
        .assertFalse();

      const twoRegions: StubCameraProperties = new StubCameraProperties();
      twoRegions.maxRegionsAutoFocus = 2;
      expect(new FocusPointFeature(twoRegions, SENSOR_ORIENTATION_STUB).checkIsSupported())
        .assertTrue();
    });

    it('zoomLevelFeature_defaultsToOneAndRoundTrips', 0, () => {
      const feature: ZoomLevelFeature = new ZoomLevelFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('ZoomLevelFeature');
      expect(feature.getValue()).assertEqual(1.0);
      feature.setValue(3.5);
      expect(feature.getValue()).assertEqual(3.5);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('noiseReductionFeature_defaultsFastAndNeverSupported', 0, () => {
      const feature: NoiseReductionFeature = new NoiseReductionFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('NoiseReductionFeature');
      expect(feature.getValue()).assertEqual(NoiseReductionMode.fast);
      feature.setValue(NoiseReductionMode.highQuality);
      expect(feature.getValue()).assertEqual(NoiseReductionMode.highQuality);
      // Camera Kit exposes no noise reduction API; the feature must stay unsupported.
      expect(feature.checkIsSupported()).assertFalse();
    });

    it('videoStabilizationFeature_defaultsOffAndRoundTripsAllLevels', 0, () => {
      const feature: VideoStabilizationFeature =
        new VideoStabilizationFeature(new StubCameraProperties());
      expect(feature.getDebugName()).assertEqual('VideoStabilizationFeature');
      expect(feature.getValue()).assertEqual(PlatformVideoStabilizationMode.off);

      feature.setValue(PlatformVideoStabilizationMode.level1);
      expect(feature.getValue()).assertEqual(PlatformVideoStabilizationMode.level1);
      feature.setValue(PlatformVideoStabilizationMode.level3);
      expect(feature.getValue()).assertEqual(PlatformVideoStabilizationMode.level3);
      expect(feature.checkIsSupported()).assertTrue();
    });

    it('videoStabilizationFeature_supportedModesOrderIsLocked', 0, () => {
      // Regression lock for the advertised mode list consumed by Dart.
      const modes: Array<PlatformVideoStabilizationMode> =
        new VideoStabilizationFeature(new StubCameraProperties()).getSupportedModes();
      expect(modes.length).assertEqual(4);
      expect(modes[0]).assertEqual(PlatformVideoStabilizationMode.off);
      expect(modes[1]).assertEqual(PlatformVideoStabilizationMode.level1);
      expect(modes[2]).assertEqual(PlatformVideoStabilizationMode.level2);
      expect(modes[3]).assertEqual(PlatformVideoStabilizationMode.level3);
    });

    it('zoomLevel_minMaxForwardThroughSessionRange', 0, () => {
      const feature: ZoomLevelFeature = new ZoomLevelFeature(new StubCameraProperties());
      const session: camera.PhotoSession = makeQuerySession([1, 10], []);
      expect(feature.getMinimumZoomLevel(session)).assertEqual(1);
      expect(feature.getMaximumZoomLevel(session)).assertEqual(10);
    });

    it('zoomLevel_emptyRangeThrowsThroughFeature', 0, () => {
      const feature: ZoomLevelFeature = new ZoomLevelFeature(new StubCameraProperties());
      let thrown: boolean = false;
      try {
        feature.getMinimumZoomLevel(makeQuerySession([], []));
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();

      let failureThrew: boolean = false;
      try {
        feature.getMaximumZoomLevel(makeThrowingQuerySession());
      } catch (e) {
        failureThrew = true;
      }
      expect(failureThrew).assertTrue();
    });

    it('exposureOffset_minMaxStepForwardThroughSession', 0, () => {
      const feature: ExposureOffsetFeature = new ExposureOffsetFeature(new StubCameraProperties());
      const session: camera.PhotoSession = makeQuerySession([], [-6, 0, 6]);
      expect(feature.getMinExposureOffset(session)).assertEqual(-6);
      expect(feature.getMaxExposureOffset(session)).assertEqual(6);
      // The step is hard-coded in CameraUtils, not queried from the session.
      expect(feature.getExposureOffsetStepSize(session)).assertEqual(0.5);
    });

    it('exposureOffset_emptyBiasRangeThrowsThroughFeature', 0, () => {
      const feature: ExposureOffsetFeature = new ExposureOffsetFeature(new StubCameraProperties());
      let thrown: boolean = false;
      try {
        feature.getMinExposureOffset(makeQuerySession([], []));
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('videoStabilization_updateBuilderAppliesSupportedModeDirectly', 0, () => {
      const feature: VideoStabilizationFeature =
        new VideoStabilizationFeature(new StubCameraProperties());
      feature.setValue(PlatformVideoStabilizationMode.level1);
      // LOW is advertised as supported, so no fallback step may run.
      const session: camera.Session =
        makeFakeVideoSession([camera.VideoStabilizationMode.LOW,
          camera.VideoStabilizationMode.OFF]);
      feature.updateBuilder(session);
      expect(shellAppliedModes.length).assertEqual(1);
      expect(shellAppliedModes[0]).assertEqual(camera.VideoStabilizationMode.LOW);
    });

    it('videoStabilization_updateBuilderFallsBackToAuto', 0, () => {
      const feature: VideoStabilizationFeature =
        new VideoStabilizationFeature(new StubCameraProperties());
      feature.setValue(PlatformVideoStabilizationMode.level2); // -> MIDDLE, unsupported below
      const session: camera.Session =
        makeFakeVideoSession([camera.VideoStabilizationMode.AUTO]);
      feature.updateBuilder(session);
      expect(shellAppliedModes.length).assertEqual(1);
      expect(shellAppliedModes[0]).assertEqual(camera.VideoStabilizationMode.AUTO);
    });

    it('videoStabilization_updateBuilderFallsBackToOffWhenNothingSupported', 0, () => {
      const feature: VideoStabilizationFeature =
        new VideoStabilizationFeature(new StubCameraProperties());
      feature.setValue(PlatformVideoStabilizationMode.level3); // -> HIGH
      const session: camera.Session = makeFakeVideoSession([]);
      feature.updateBuilder(session);
      expect(shellAppliedModes.length).assertEqual(1);
      expect(shellAppliedModes[0]).assertEqual(camera.VideoStabilizationMode.OFF);
    });

    it('videoStabilization_updateBuilderSwallowsCrashingSession', 0, () => {
      // A failing session must not propagate out of updateBuilder.
      const feature: VideoStabilizationFeature =
        new VideoStabilizationFeature(new StubCameraProperties());
      feature.setValue(PlatformVideoStabilizationMode.level1);
      let thrown: boolean = false;
      try {
        feature.updateBuilder(makeCrashingVideoSession());
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
      expect(shellAppliedModes.length).assertEqual(0);
    });
  });
}
