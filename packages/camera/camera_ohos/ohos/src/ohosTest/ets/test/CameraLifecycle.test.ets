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

// Camera's session-independent surface. Construction runs the real feature
// init plus system lookups (camera manager, PhotoAccessHelper); on-device the
// enumeration APIs answer without permissions, but if the environment refuses
// construction every camera-dependent case exits early with the factory
// failure message instead of faking a pass. Cameras built here are never
// opened: leftover display listeners die with the test process.

import { describe, it, expect } from '@ohos/hypium';
import UIAbility from '@ohos.app.ability.UIAbility';
import { Camera } from '../../../main/ets/io/flutter/plugins/camera/Camera';
import { CameraApiImpl } from '../../../main/ets/io/flutter/plugins/camera/CameraApiImpl';
import { CameraPermissions } from '../../../main/ets/io/flutter/plugins/camera/CameraPermissions';
import { DartMessenger } from '../../../main/ets/io/flutter/plugins/camera/DartMessenger';
import { CameraFeatureFactoryImpl } from
  '../../../main/ets/io/flutter/plugins/camera/features/CameraFeatureFactoryImpl';
import { DeviceOrientationManager } from
  '../../../main/ets/io/flutter/plugins/camera/features/sensororientation/DeviceOrientationManager';
import { ResolutionPreset } from '../../../main/ets/io/flutter/plugins/camera/types/ResolutionPreset';
import {
  FlutterError,
  PlatformImageFileFormat,
  PlatformMediaSettings,
  PlatformResolutionPreset,
  PlatformVideoStabilizationMode
} from '../../../main/ets/io/flutter/plugins/camera/Messages';
import { DeviceOrientation } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import {
  MockAbilityBinding,
  MockBinaryMessenger,
  MockMethodResult,
  StubCameraProperties,
  StubPigeonResult,
  makeFakeAbility,
  makeFakeSurfaceTextureEntry,
  makeFakeTextureRegistry
} from './TestMocks';

let factoryFailureMessage: string = '';

// Returns null (and records why) when Camera construction is unavailable.
function tryMakeCamera(): Camera | null {
  try {
    return new Camera(new MockAbilityBinding().getAbility(), makeFakeSurfaceTextureEntry(),
      new CameraFeatureFactoryImpl(), new DartMessenger(new MockBinaryMessenger()),
      new StubCameraProperties(), ResolutionPreset.medium, false, new CameraPermissions(),
      makeFakeTextureRegistry());
  } catch (e) {
    factoryFailureMessage = (e as Error).message;
    return null;
  }
}

function makeApi(): CameraApiImpl {
  const messenger: MockBinaryMessenger = new MockBinaryMessenger();
  return new CameraApiImpl(new MockAbilityBinding().getAbility(), messenger,
    makeFakeTextureRegistry());
}

export default function cameraLifecycleTest() {
  describe('CameraLifecycleTest', () => {
    it('constructor_createsInstanceInTestProcess', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      // Surfaces the construction failure reason in the assertion output.
      expect(factoryFailureMessage).assertEqual('');
    });

    it('constructor_nullAbilityThrows', 0, () => {
      const noAbility: UIAbility = (null as ESObject) as UIAbility;
      let message: string = '(did not throw)';
      try {
        new Camera(noAbility, makeFakeSurfaceTextureEntry(), new CameraFeatureFactoryImpl(),
          new DartMessenger(new MockBinaryMessenger()), new StubCameraProperties(),
          ResolutionPreset.medium, false, new CameraPermissions());
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('No Ability available!');
    });

    it('zoomLevels_reportZeroBeforeAnySession', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      // Unknown marker while photo/video sessions are not built yet.
      expect(cam.getMaxZoomLevel()).assertEqual(0);
      expect(cam.getMinZoomLevel()).assertEqual(0);
    });

    it('setJpegImageQuality_rejectsOutOfRangeValues', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const low: MockMethodResult = new MockMethodResult();
      cam.setJpegImageQuality(low, 0);
      expect(low.errorCodes.length).assertEqual(1);
      expect(low.errorCodes[0]).assertEqual('invalidJpegQuality');

      const high: MockMethodResult = new MockMethodResult();
      cam.setJpegImageQuality(high, 101);
      expect(high.errorCodes.length).assertEqual(1);
      expect(high.errorCodes[0]).assertEqual('invalidJpegQuality');
    });

    it('setJpegImageQuality_acceptsValidQuality', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const result: MockMethodResult = new MockMethodResult();
      cam.setJpegImageQuality(result, 88);
      expect(result.successArgs.length).assertEqual(1);
      expect(result.errorCodes.length).assertEqual(0);
    });

    it('setImageFileFormat_jpegAlwaysSucceeds', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const result: MockMethodResult = new MockMethodResult();
      cam.setImageFileFormat(result, PlatformImageFileFormat.jpeg);
      expect(result.successArgs.length).assertEqual(1);
      expect(result.errorCodes.length).assertEqual(0);
    });

    it('setImageFileFormat_heifReportsExactlyOneCallback', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      // HEIF support is device-dependent (probed through ImagePacker); lock the
      // callback contract (exactly one of error/success) instead of the verdict.
      const result: MockMethodResult = new MockMethodResult();
      cam.setImageFileFormat(result, PlatformImageFileFormat.heif);
      const callbacks: number = result.successArgs.length + result.errorCodes.length;
      expect(callbacks).assertEqual(1);
    });

    it('videoStabilization_storesModeAndListsFourSupported', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const result: MockMethodResult = new MockMethodResult();
      cam.setVideoStabilizationMode(result, PlatformVideoStabilizationMode.level1);
      expect(result.successArgs.length).assertEqual(1);
      expect(result.errorCodes.length).assertEqual(0);

      const modes: Array<PlatformVideoStabilizationMode> =
        cam.getSupportedVideoStabilizationModes();
      expect(modes.length).assertEqual(4);
      expect(modes[0]).assertEqual(PlatformVideoStabilizationMode.off);
      expect(modes[1]).assertEqual(PlatformVideoStabilizationMode.level1);
      expect(modes[2]).assertEqual(PlatformVideoStabilizationMode.level2);
      expect(modes[3]).assertEqual(PlatformVideoStabilizationMode.level3);
    });

    it('pauseResumePreview_succeedsWithoutOutputs', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const pause: MockMethodResult = new MockMethodResult();
      await cam.pausePreview(pause);
      expect(pause.successArgs.length).assertEqual(1);
      expect(pause.errorCodes.length).assertEqual(0);

      // First resume takes the "not paused" skip branch.
      const resume: MockMethodResult = new MockMethodResult();
      await cam.resumePreview(resume);
      expect(resume.successArgs.length).assertEqual(1);

      // After a pause the resume actually enters the restart branch.
      const pause2: MockMethodResult = new MockMethodResult();
      await cam.pausePreview(pause2);
      const resume2: MockMethodResult = new MockMethodResult();
      await cam.resumePreview(resume2);
      expect(resume2.successArgs.length).assertEqual(1);
      expect(resume2.errorCodes.length).assertEqual(0);
    });

    it('lockUnlockCaptureOrientation_stayQuietWithoutSessions', 0, () => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      // Both only update SensorOrientationFeature state; no session is touched.
      let threw: boolean = false;
      try {
        cam.lockCaptureOrientation(DeviceOrientation.PORTRAIT_UP);
        cam.unlockCaptureOrientation();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('prepareRecording_completesWithoutCamera', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      let threw: boolean = false;
      try {
        await cam.prepareRecording(new MockMethodResult());
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('close_completesOnNeverOpenedCameraAndIsIdempotent', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      let threw: boolean = false;
      try {
        await cam.close();
        await cam.close();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('dispose_completesWithoutResources', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      let threw: boolean = false;
      try {
        await cam.dispose();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('create_secondCallRejectedWhileFirstIsPending', 0, async (): Promise<void> => {
      // With the shell context the first create reaches the permission request
      // and may stay pending without invoking any callback; the status machine
      // must then reject a concurrent second create synchronously.
      const api: CameraApiImpl = makeApi();
      const settings: PlatformMediaSettings =
        new PlatformMediaSettings(PlatformResolutionPreset.medium, 30, 5000000, 48000, false);

      const first: StubPigeonResult<number> = new StubPigeonResult<number>();
      await api.create('emulated', settings, first);

      const second: StubPigeonResult<number> = new StubPigeonResult<number>();
      await api.create('emulated', settings, second);
      expect(second.errors.length).assertEqual(1);
      expect((second.errors[0] as FlutterError).code).assertEqual('CREATE_ERROR');

      // Mark disposed so a late permission callback converges on an error
      // reply instead of rebuilding a camera inside the finished test.
      await api.dispose();
    });

    it('handleUIOrientationChange_staysInsideEnumDomain', 0, () => {
      // display rotation drives the value; it cannot be injected, so lock
      // "no throw + result domain + at most one event per call".
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(messenger), false, 90);
      let threw: boolean = false;
      try {
        manager.handleUIOrientationChange();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();

      const orientation: DeviceOrientation = manager.getLastUIOrientation();
      const valid: boolean = orientation == DeviceOrientation.PORTRAIT_UP ||
        orientation == DeviceOrientation.PORTRAIT_DOWN ||
        orientation == DeviceOrientation.LANDSCAPE_LEFT ||
        orientation == DeviceOrientation.LANDSCAPE_RIGHT;
      expect(valid).assertTrue();
      expect(messenger.sendCount <= 1).assertTrue();
    });
  });
}
