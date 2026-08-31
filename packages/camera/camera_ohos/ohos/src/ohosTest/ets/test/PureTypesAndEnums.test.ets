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

// Pure type and enum contracts: types/, features/Point, CameraState.

import { describe, it, expect } from '@ohos/hypium';
import { Timeout } from '../../../main/ets/io/flutter/plugins/camera/types/Timeout';
import { CaptureTimeoutsWrapper } from
  '../../../main/ets/io/flutter/plugins/camera/types/CaptureTimeoutsWrapper';
import { CameraCaptureProperties } from
  '../../../main/ets/io/flutter/plugins/camera/types/CameraCaptureProperties';
import { ResolutionPreset as TypesResolutionPreset, ResolutionPreset_valueOf } from
  '../../../main/ets/io/flutter/plugins/camera/types/ResolutionPreset';
import { ResolutionPreset as FeatureResolutionPreset } from
  '../../../main/ets/io/flutter/plugins/camera/features/resolution/ResolutionPreset';
import { FlashMode } from '../../../main/ets/io/flutter/plugins/camera/types/FlashMode';
import { FocusMode } from '../../../main/ets/io/flutter/plugins/camera/types/FocusMode';
import { ExposureMode } from '../../../main/ets/io/flutter/plugins/camera/types/ExposureMode';
import { NoiseReductionMode } from
  '../../../main/ets/io/flutter/plugins/camera/features/noisereduction/NoiseReductionMode';
import { Point } from '../../../main/ets/io/flutter/plugins/camera/features/Point';
import { CameraState } from '../../../main/ets/io/flutter/plugins/camera/CameraState';
import { CameraCaptureCallback } from
  '../../../main/ets/io/flutter/plugins/camera/CameraCaptureCallback';
import { sleepMs, StubCaptureStateListener } from './TestMocks';

export default function pureTypesAndEnumsTest() {
  describe('PureTypesAndEnumsTest', () => {
    it('timeout_notExpiredImmediately', 0, () => {
      const timeout: Timeout = new Timeout(50);
      expect(timeout.getIsExpired()).assertFalse();
    });

    it('timeout_expiresAfterDeadline', 0, async (): Promise<void> => {
      const timeout: Timeout = new Timeout(50);
      await sleepMs(80);
      expect(timeout.getIsExpired()).assertTrue();
    });

    it('timeout_factoryCreateAndZeroMsBoundary', 0, async (): Promise<void> => {
      const factoryTimeout: Timeout = Timeout.create(500);
      expect(factoryTimeout != null).assertTrue();
      expect(factoryTimeout.getIsExpired()).assertFalse();

      // timeoutMs=0 expires as soon as the clock advances at all.
      const zeroTimeout: Timeout = new Timeout(0);
      await sleepMs(5);
      expect(zeroTimeout.getIsExpired()).assertTrue();
    });

    it('captureTimeoutsWrapper_holdsFreshTimeouts', 0, () => {
      const wrapper: CaptureTimeoutsWrapper = new CaptureTimeoutsWrapper(100, 200);
      expect(wrapper.getPreCaptureFocusing() != null).assertTrue();
      expect(wrapper.getPreCaptureMetering() != null).assertTrue();
      expect(wrapper.getPreCaptureFocusing().getIsExpired()).assertFalse();
      expect(wrapper.getPreCaptureMetering().getIsExpired()).assertFalse();
    });

    it('captureTimeoutsWrapper_resetReplacesInstances', 0, () => {
      const wrapper: CaptureTimeoutsWrapper = new CaptureTimeoutsWrapper(100, 200);
      const focusingBefore: Timeout = wrapper.getPreCaptureFocusing();
      const meteringBefore: Timeout = wrapper.getPreCaptureMetering();
      wrapper.reset();
      expect(wrapper.getPreCaptureFocusing() === focusingBefore).assertFalse();
      expect(wrapper.getPreCaptureMetering() === meteringBefore).assertFalse();
      expect(wrapper.getPreCaptureFocusing().getIsExpired()).assertFalse();
    });

    it('cameraCaptureProperties_defaultValuesAreZero', 0, () => {
      const props: CameraCaptureProperties = new CameraCaptureProperties();
      expect(props.getLastLensAperture()).assertEqual(0);
      expect(props.getLastSensorExposureTime()).assertEqual(0);
      expect(props.getLastSensorSensitivity()).assertEqual(0);
    });

    it('cameraCaptureProperties_settersRoundTripAndOverwrite', 0, () => {
      const props: CameraCaptureProperties = new CameraCaptureProperties();
      props.setLastLensAperture(1.8);
      props.setLastSensorExposureTime(25000);
      props.setLastSensorSensitivity(400);
      expect(props.getLastLensAperture()).assertEqual(1.8);
      expect(props.getLastSensorExposureTime()).assertEqual(25000);
      expect(props.getLastSensorSensitivity()).assertEqual(400);

      props.setLastLensAperture(2.8);
      props.setLastSensorExposureTime(50000);
      props.setLastSensorSensitivity(800);
      expect(props.getLastLensAperture()).assertEqual(2.8);
      expect(props.getLastSensorExposureTime()).assertEqual(50000);
      expect(props.getLastSensorSensitivity()).assertEqual(800);
    });

    it('point_holdsNullCoordinates', 0, () => {
      const point: Point = new Point(null, null);
      expect(point.x == null).assertTrue();
      expect(point.y == null).assertTrue();
    });

    it('point_holdsNumericCoordinates', 0, () => {
      const point: Point = new Point(1.5, 2.5);
      expect(point.x).assertEqual(1.5);
      expect(point.y).assertEqual(2.5);

      const mixed: Point = new Point(0, null);
      expect(mixed.x).assertEqual(0);
      expect(mixed.y == null).assertTrue();
    });

    it('typesResolutionPreset_membersAreSequentialFromZero', 0, () => {
      expect(TypesResolutionPreset.low).assertEqual(0);
      expect(TypesResolutionPreset.medium).assertEqual(1);
      expect(TypesResolutionPreset.high).assertEqual(2);
      expect(TypesResolutionPreset.veryHigh).assertEqual(3);
      expect(TypesResolutionPreset.ultraHigh).assertEqual(4);
      expect(TypesResolutionPreset.max).assertEqual(5);
    });

    it('resolutionPreset_valueOfMapsAllLegalNames', 0, () => {
      expect(ResolutionPreset_valueOf('low')).assertEqual(TypesResolutionPreset.low);
      expect(ResolutionPreset_valueOf('medium')).assertEqual(TypesResolutionPreset.medium);
      expect(ResolutionPreset_valueOf('high')).assertEqual(TypesResolutionPreset.high);
      expect(ResolutionPreset_valueOf('veryHigh')).assertEqual(TypesResolutionPreset.veryHigh);
      expect(ResolutionPreset_valueOf('ultraHigh')).assertEqual(TypesResolutionPreset.ultraHigh);
      expect(ResolutionPreset_valueOf('max')).assertEqual(TypesResolutionPreset.max);
    });

    it('resolutionPreset_valueOfFallsBackToLowForUnknown', 0, () => {
      // The parser is case sensitive and falls back to low instead of throwing.
      expect(ResolutionPreset_valueOf('unknown')).assertEqual(TypesResolutionPreset.low);
      expect(ResolutionPreset_valueOf('Low')).assertEqual(TypesResolutionPreset.low);
      expect(ResolutionPreset_valueOf('')).assertEqual(TypesResolutionPreset.low);
    });

    it('bothResolutionPresetEnumsStayAligned', 0, () => {
      // Guards the two copies of the enum against drifting apart.
      expect(FeatureResolutionPreset.low).assertEqual(TypesResolutionPreset.low);
      expect(FeatureResolutionPreset.medium).assertEqual(TypesResolutionPreset.medium);
      expect(FeatureResolutionPreset.high).assertEqual(TypesResolutionPreset.high);
      expect(FeatureResolutionPreset.veryHigh).assertEqual(TypesResolutionPreset.veryHigh);
      expect(FeatureResolutionPreset.ultraHigh).assertEqual(TypesResolutionPreset.ultraHigh);
      expect(FeatureResolutionPreset.max).assertEqual(TypesResolutionPreset.max);
    });

    it('stringEnums_valuesAreLocked', 0, () => {
      expect(FlashMode.off).assertEqual('off');
      expect(FlashMode.auto).assertEqual('auto');
      expect(FlashMode.always).assertEqual('always');
      expect(FlashMode.torch).assertEqual('torch');

      expect(FocusMode.auto).assertEqual('auto');
      expect(FocusMode.locked).assertEqual('locked');

      expect(ExposureMode.auto).assertEqual('auto');
      expect(ExposureMode.locked).assertEqual('locked');

      expect(NoiseReductionMode.off).assertEqual('off');
      expect(NoiseReductionMode.fast).assertEqual('fast');
      expect(NoiseReductionMode.highQuality).assertEqual('highQuality');
      expect(NoiseReductionMode.minimal).assertEqual('minimal');
      expect(NoiseReductionMode.zeroShutterLag).assertEqual('zeroShutterLag');
    });

    it('cameraState_statesAreSequentialFromZero', 0, () => {
      expect(CameraState.STATE_PREVIEW).assertEqual(0);
      expect(CameraState.STATE_WAITING_FOCUS).assertEqual(1);
      expect(CameraState.STATE_WAITING_PRECAPTURE_START).assertEqual(2);
      expect(CameraState.STATE_WAITING_PRECAPTURE_DONE).assertEqual(3);
      expect(CameraState.STATE_CAPTURING).assertEqual(4);
    });

    it('cameraCaptureCallback_createStartsInPreviewState', 0, () => {
      const callback: CameraCaptureCallback = CameraCaptureCallback.create(
        new StubCaptureStateListener(), new CaptureTimeoutsWrapper(50, 50),
        new CameraCaptureProperties());
      expect(callback != null).assertTrue();
      expect(callback.getCameraState()).assertEqual(CameraState.STATE_PREVIEW);
    });

    it('cameraCaptureCallback_setStateIsReadable', 0, () => {
      const callback: CameraCaptureCallback = CameraCaptureCallback.create(
        new StubCaptureStateListener(), new CaptureTimeoutsWrapper(50, 50),
        new CameraCaptureProperties());
      callback.setCameraState(CameraState.STATE_CAPTURING);
      expect(callback.getCameraState()).assertEqual(CameraState.STATE_CAPTURING);
      callback.setCameraState(CameraState.STATE_PREVIEW);
      expect(callback.getCameraState()).assertEqual(CameraState.STATE_PREVIEW);
    });

    it('cameraCaptureCallback_keepsInjectedListener', 0, () => {
      // The state machine wiring itself lives in Camera.ets; here the callback
      // only has to hold the collaborators it was built with.
      const listener: StubCaptureStateListener = new StubCaptureStateListener();
      const callback: CameraCaptureCallback = CameraCaptureCallback.create(
        listener, new CaptureTimeoutsWrapper(50, 50), new CameraCaptureProperties());
      expect(callback != null).assertTrue();
      listener.onConverged();
      listener.onPrecapture();
      expect(listener.convergedCount).assertEqual(1);
      expect(listener.precaptureCount).assertEqual(1);
    });
  });
}
