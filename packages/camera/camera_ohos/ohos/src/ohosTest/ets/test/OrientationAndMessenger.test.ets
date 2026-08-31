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

// Orientation plumbing: CameraUtils serialization, DartMessenger channel sends
// and DeviceOrientationManager angle math (display callbacks never started).

import { describe, it, expect } from '@ohos/hypium';
import { CameraUtils } from '../../../main/ets/io/flutter/plugins/camera/CameraUtils';
import { DartMessenger } from '../../../main/ets/io/flutter/plugins/camera/DartMessenger';
import { DeviceOrientationManager } from
  '../../../main/ets/io/flutter/plugins/camera/features/sensororientation/DeviceOrientationManager';
import {
  MockBinaryMessenger,
  MockMethodResult,
  makeFakeAbility
} from './TestMocks';
import { DeviceOrientation } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';

export default function orientationAndMessengerTest() {
  describe('OrientationAndMessengerTest', () => {
    it('serializeDeviceOrientation_mapsAllFourValues', 0, () => {
      expect(CameraUtils.serializeDeviceOrientation(DeviceOrientation.PORTRAIT_UP))
        .assertEqual('portraitUp');
      expect(CameraUtils.serializeDeviceOrientation(DeviceOrientation.PORTRAIT_DOWN))
        .assertEqual('portraitDown');
      expect(CameraUtils.serializeDeviceOrientation(DeviceOrientation.LANDSCAPE_LEFT))
        .assertEqual('landscapeLeft');
      expect(CameraUtils.serializeDeviceOrientation(DeviceOrientation.LANDSCAPE_RIGHT))
        .assertEqual('landscapeRight');
    });

    it('deserializeDeviceOrientation_mapsAllFourStrings', 0, () => {
      expect(CameraUtils.deserializeDeviceOrientation('portraitUp'))
        .assertEqual(DeviceOrientation.PORTRAIT_UP);
      expect(CameraUtils.deserializeDeviceOrientation('portraitDown'))
        .assertEqual(DeviceOrientation.PORTRAIT_DOWN);
      expect(CameraUtils.deserializeDeviceOrientation('landscapeLeft'))
        .assertEqual(DeviceOrientation.LANDSCAPE_LEFT);
      expect(CameraUtils.deserializeDeviceOrientation('landscapeRight'))
        .assertEqual(DeviceOrientation.LANDSCAPE_RIGHT);
    });

    it('serialization_roundTripsBothWays', 0, () => {
      const values: Array<DeviceOrientation> = [
        DeviceOrientation.PORTRAIT_UP,
        DeviceOrientation.PORTRAIT_DOWN,
        DeviceOrientation.LANDSCAPE_LEFT,
        DeviceOrientation.LANDSCAPE_RIGHT
      ];
      const names: Array<string> =
        ['portraitUp', 'portraitDown', 'landscapeLeft', 'landscapeRight'];
      for (let i = 0; i < values.length; i++) {
        expect(CameraUtils.deserializeDeviceOrientation(
          CameraUtils.serializeDeviceOrientation(values[i])) === values[i]).assertTrue();
        expect(CameraUtils.serializeDeviceOrientation(
          CameraUtils.deserializeDeviceOrientation(names[i]))).assertEqual(names[i]);
      }
    });

    it('serialization_throwsOnNullAndUnknownInput', 0, () => {
      let threwSerializeNull: boolean = false;
      try {
        CameraUtils.serializeDeviceOrientation((null as ESObject) as DeviceOrientation);
      } catch (e) {
        threwSerializeNull = true;
      }
      expect(threwSerializeNull).assertTrue();

      let threwDeserializeNull: boolean = false;
      try {
        CameraUtils.deserializeDeviceOrientation((null as ESObject) as string);
      } catch (e) {
        threwDeserializeNull = true;
      }
      expect(threwDeserializeNull).assertTrue();

      let threwUnknown: boolean = false;
      try {
        CameraUtils.deserializeDeviceOrientation('upsideDown');
      } catch (e) {
        threwUnknown = true;
      }
      expect(threwUnknown).assertTrue();
    });

    it('dartMessenger_cameraIdSuffixDefaultsAndOverrides', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const noId: DartMessenger = new DartMessenger(messenger);
      expect(noId.getCameraIdSuffix()).assertEqual('');
      expect(noId.getBinaryMessenger() === messenger).assertTrue();

      const withId: DartMessenger = new DartMessenger(messenger, 3);
      expect(withId.getCameraIdSuffix()).assertEqual('3');
    });

    it('dartMessenger_finishDelegatesToSuccess', 0, () => {
      const result: MockMethodResult = new MockMethodResult();
      const messenger: DartMessenger = new DartMessenger(new MockBinaryMessenger(), 1);
      messenger.finish(result, 'payload-object' as Object);
      expect(result.successArgs.length).assertEqual(1);
      expect(result.successArgs[0] === 'payload-object').assertTrue();
      expect(result.notImplementedCount).assertEqual(0);
    });

    it('dartMessenger_errorDelegatesToErrorResult', 0, () => {
      const result: MockMethodResult = new MockMethodResult();
      const messenger: DartMessenger = new DartMessenger(new MockBinaryMessenger(), 1);
      messenger.error(result, 'cameraAccessDenied', 'no permission');
      expect(result.errorCodes.length).assertEqual(1);
      expect(result.errorCodes[0]).assertEqual('cameraAccessDenied');
      expect(result.errorMessages[0]).assertEqual('no permission');
    });

    it('dartMessenger_sendsGlobalEventOnPigeonChannel', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const dartMessenger: DartMessenger = new DartMessenger(messenger, 7);
      dartMessenger.sendDeviceOrientationChangeEvent(DeviceOrientation.PORTRAIT_UP);
      expect(messenger.sendCount).assertEqual(1);
      expect(messenger.sentChannels.length).assertEqual(1);
      expect(messenger.sentChannels[0])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraGlobalEventApi.deviceOrientationChanged');
      expect(messenger.lastPayload != null).assertTrue();

      // A second event on a different orientation still reaches the same channel.
      dartMessenger.sendDeviceOrientationChangeEvent(DeviceOrientation.LANDSCAPE_LEFT);
      expect(messenger.sendCount).assertEqual(2);
    });

    it('dartMessenger_unknownOrientationFallsBackWithoutThrowing', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const dartMessenger: DartMessenger = new DartMessenger(messenger);
      // Defensive catch must swallow any unexpected enum value.
      dartMessenger.sendDeviceOrientationChangeEvent(
        (99 as ESObject) as DeviceOrientation);
      expect(messenger.sendCount).assertEqual(1);
    });

    it('deviceOrientationManager_photoAnglesBackCamera', 0, () => {
      // Formula: (angle + sensorOrientation + 270) % 360.
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), false, 90);

      expect(manager.getPhotoOrientation(DeviceOrientation.PORTRAIT_UP)).assertEqual(90);
      expect(manager.getPhotoOrientation(DeviceOrientation.PORTRAIT_DOWN)).assertEqual(270);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_LEFT)).assertEqual(0);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_RIGHT)).assertEqual(180);
    });

    it('deviceOrientationManager_photoAnglesFrontCamera', 0, () => {
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), true, 90);

      // Landscape angles swap for the front lens.
      expect(manager.getPhotoOrientation(DeviceOrientation.PORTRAIT_UP)).assertEqual(90);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_LEFT)).assertEqual(180);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_RIGHT)).assertEqual(0);
    });

    it('deviceOrientationManager_photoAngleWrapsWithZeroSensor', 0, () => {
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), false, 0);
      expect(manager.getPhotoOrientation(DeviceOrientation.PORTRAIT_UP)).assertEqual(0);
      expect(manager.getPhotoOrientation(DeviceOrientation.PORTRAIT_DOWN)).assertEqual(180);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_LEFT)).assertEqual(270);
      expect(manager.getPhotoOrientation(DeviceOrientation.LANDSCAPE_RIGHT)).assertEqual(90);
    });

    it('deviceOrientationManager_videoAnglesBackAndFront', 0, () => {
      // Base mapping UP/DOWN/LEFT/RIGHT -> 0/180/270/90; front negates then re-mods.
      const back90: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), false, 90);
      expect(back90.getVideoOrientation(DeviceOrientation.PORTRAIT_UP)).assertEqual(90);
      expect(back90.getVideoOrientation(DeviceOrientation.PORTRAIT_DOWN)).assertEqual(270);
      expect(back90.getVideoOrientation(DeviceOrientation.LANDSCAPE_LEFT)).assertEqual(0);
      expect(back90.getVideoOrientation(DeviceOrientation.LANDSCAPE_RIGHT)).assertEqual(180);

      const front270: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), true, 270);
      expect(front270.getVideoOrientation(DeviceOrientation.PORTRAIT_UP))
        .assertEqual((-0 + 270 + 360) % 360);
      expect(front270.getVideoOrientation(DeviceOrientation.LANDSCAPE_RIGHT))
        .assertEqual((-90 + 270 + 360) % 360);
    });

    it('deviceOrientationManager_missingArgumentReturnsLastUiOrientation', 0, () => {
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), false, 90);
      // start() never ran, so lastOrientation keeps its PORTRAIT_UP initial value
      // and the undefined-argument branch returns it as-is (not an angle).
      expect(manager.getLastUIOrientation()).assertEqual(DeviceOrientation.PORTRAIT_UP);
      expect(manager.getPhotoOrientation(undefined)).assertEqual(DeviceOrientation.PORTRAIT_UP);
    });

    it('deviceOrientationManager_getUIOrientationMapsDisplayRotation', 0, () => {
      // display.getDefaultDisplaySync() is readable in the test process, but
      // the physical rotation cannot be injected; lock "no throw + the result
      // stays inside the serialized enum domain".
      const manager: DeviceOrientationManager = new DeviceOrientationManager(
        makeFakeAbility(), new DartMessenger(new MockBinaryMessenger()), false, 90);
      const orientation: DeviceOrientation = manager.getUIOrientation();
      const valid: boolean = orientation == DeviceOrientation.PORTRAIT_UP ||
        orientation == DeviceOrientation.PORTRAIT_DOWN ||
        orientation == DeviceOrientation.LANDSCAPE_LEFT ||
        orientation == DeviceOrientation.LANDSCAPE_RIGHT;
      expect(valid).assertTrue();
    });
  });
}
