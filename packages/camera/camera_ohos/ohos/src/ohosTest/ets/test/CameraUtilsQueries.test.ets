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

// CameraUtils session-query helpers driven through minimal fake session shells.
// Locks the two different failure semantics: support probes and min/max
// extractors rethrow, while the raw range getters swallow and return [].

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { CameraUtils } from '../../../main/ets/io/flutter/plugins/camera/CameraUtils';
import {
  makeQuerySession,
  makeThrowingQuerySession,
  makeFlashSession,
  makeCrashingFlashSession,
  makeFakeCameraManager,
  makeFakeDevice
} from './TestMocks';

export default function cameraUtilsQueriesTest() {
  describe('CameraUtilsQueriesTest', () => {
    it('hasFlash_passesThroughSessionAnswer', 0, () => {
      expect(CameraUtils.hasFlash(makeFlashSession(true, true, true))).assertTrue();
      expect(CameraUtils.hasFlash(makeFlashSession(false, true, true))).assertFalse();
    });

    it('hasFlash_rethrowsSessionFailure', 0, () => {
      // A failed system probe must not read as "device has no flash".
      let thrown: boolean = false;
      try {
        CameraUtils.hasFlash(makeCrashingFlashSession());
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('flashAndExposureModeSupport_passThrough', 0, () => {
      const session: camera.PhotoSession = makeFlashSession(true, true, false);
      expect(CameraUtils.isFlashModeSupported(session, camera.FlashMode.FLASH_MODE_OPEN))
        .assertTrue();
      expect(CameraUtils.isExposureModeSupported(session, camera.ExposureMode.EXPOSURE_MODE_AUTO))
        .assertFalse();
    });

    it('flashAndExposureModeSupport_rethrowOnFailure', 0, () => {
      const session: camera.PhotoSession = makeThrowingQuerySession();
      let flashThrew: boolean = false;
      try {
        CameraUtils.isFlashModeSupported(session, camera.FlashMode.FLASH_MODE_AUTO);
      } catch (e) {
        flashThrew = true;
      }
      let exposureThrew: boolean = false;
      try {
        CameraUtils.isExposureModeSupported(session, camera.ExposureMode.EXPOSURE_MODE_LOCKED);
      } catch (e) {
        exposureThrew = true;
      }
      expect(flashThrew).assertTrue();
      expect(exposureThrew).assertTrue();
    });

    it('zoomAndBiasRanges_passThroughInOrder', 0, () => {
      const session: camera.PhotoSession = makeQuerySession([1, 10], [-6, 6]);
      const zoom: Array<number> = CameraUtils.getZoomRatioRange(session);
      expect(zoom.length).assertEqual(2);
      expect(zoom[0]).assertEqual(1);
      expect(zoom[1]).assertEqual(10);
      const bias: Array<number> = CameraUtils.getExposureBiasRange(session);
      expect(bias[0]).assertEqual(-6);
      expect(bias[1]).assertEqual(6);
    });

    it('rawRangeGetters_swallowFailureAndReturnEmpty', 0, () => {
      // Unlike the probes above, the raw getters degrade to [] on failure.
      const session: camera.PhotoSession = makeThrowingQuerySession();
      expect(CameraUtils.getZoomRatioRange(session).length).assertEqual(0);
      expect(CameraUtils.getExposureBiasRange(session).length).assertEqual(0);
    });

    it('zoomRatioBounds_extractMinAndMax', 0, () => {
      const session: camera.PhotoSession = makeQuerySession([0.5, 12], []);
      expect(CameraUtils.getMinZoomRatio(session)).assertEqual(0.5);
      expect(CameraUtils.getMaxZoomRatio(session)).assertEqual(12);
    });

    it('zoomRatioBounds_emptyRangeThrows', 0, () => {
      const session: camera.PhotoSession = makeQuerySession([], []);
      let thrown: boolean = false;
      let message: string = '';
      try {
        CameraUtils.getMinZoomRatio(session);
      } catch (e) {
        thrown = true;
        message = (e as Error).message;
      }
      expect(thrown).assertTrue();
      expect(message).assertContain('empty range');
    });

    it('zoomRatioBounds_rethrowSessionFailure', 0, () => {
      const session: camera.PhotoSession = makeThrowingQuerySession();
      let minThrew: boolean = false;
      let maxThrew: boolean = false;
      try {
        CameraUtils.getMinZoomRatio(session);
      } catch (e) {
        minThrew = true;
      }
      try {
        CameraUtils.getMaxZoomRatio(session);
      } catch (e) {
        maxThrew = true;
      }
      expect(minThrew).assertTrue();
      expect(maxThrew).assertTrue();
    });

    it('exposureBiasBounds_extractFirstAndLast', 0, () => {
      const session: camera.PhotoSession = makeQuerySession([], [-4, 0, 4]);
      expect(CameraUtils.getMinExposureBias(session)).assertEqual(-4);
      expect(CameraUtils.getMaxExposureBias(session)).assertEqual(4);
    });

    it('exposureBiasBounds_emptyRangeAndFailureThrow', 0, () => {
      let emptyThrew: boolean = false;
      try {
        CameraUtils.getMinExposureBias(makeQuerySession([], []));
      } catch (e) {
        emptyThrew = true;
      }
      expect(emptyThrew).assertTrue();

      let failureThrew: boolean = false;
      try {
        CameraUtils.getMaxExposureBias(makeThrowingQuerySession());
      } catch (e) {
        failureThrew = true;
      }
      expect(failureThrew).assertTrue();
    });

    it('exposureBiasStep_isConstantHalfWithoutTouchingSession', 0, () => {
      // The step is hard-coded; the session is never dereferenced (null is fine).
      const noSession: camera.PhotoSession = (null as ESObject) as camera.PhotoSession;
      expect(CameraUtils.getExposureBiasStep(noSession)).assertEqual(0.5);
    });

    it('getCameraDevice_findsDeviceById', 0, () => {
      const device: camera.CameraDevice = makeFakeDevice('back1', 1, 90);
      const manager: camera.CameraManager = makeFakeCameraManager([device]);
      const found: camera.CameraDevice | null = CameraUtils.getCameraDevice('back1', manager);
      expect(found != null).assertTrue();
      expect((found as camera.CameraDevice) === device).assertTrue();
    });

    it('getCameraDevice_unknownIdReturnsNull', 0, () => {
      const manager: camera.CameraManager =
        makeFakeCameraManager([makeFakeDevice('back1', 1, 90)]);
      expect(CameraUtils.getCameraDevice('front9', manager) == null).assertTrue();
    });

    it('getCameraDevice_managerFailureReturnsNull', 0, () => {
      // Service failure must degrade to "no such device", not crash the caller.
      const manager: camera.CameraManager = makeFakeCameraManager([]);
      const empty: camera.CameraDevice | null =
        CameraUtils.getCameraDevice('back1', manager);
      expect(empty == null).assertTrue();
    });
  });
}
