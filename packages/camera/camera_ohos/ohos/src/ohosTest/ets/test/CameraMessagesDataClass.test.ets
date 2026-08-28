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

// Pigeon-generated data classes and channel plumbing in Messages.ets.
// The file is hand maintained; these tests only read it.

import { describe, it, expect } from '@ohos/hypium';
import {
  CameraApi,
  CameraEventApi,
  FlutterError,
  PlatformCameraDescription,
  PlatformCameraLensDirection,
  PlatformCameraState,
  PlatformDeviceOrientation,
  PlatformExposureMode,
  PlatformFlashMode,
  PlatformFocusMode,
  PlatformImageFileFormat,
  PlatformImageFormatGroup,
  PlatformMediaSettings,
  PlatformPoint,
  PlatformResolutionPreset,
  PlatformSize,
  PlatformVideoStabilizationMode
} from '../../../main/ets/io/flutter/plugins/camera/Messages';
import {
  MockBinaryMessenger,
  StubBinaryMessageHandler,
  StubVoidReply
} from './TestMocks';

export default function cameraMessagesDataClassTest() {
  describe('CameraMessagesDataClassTest', () => {
    it('platformSize_roundTripsThroughList', 0, () => {
      const size: PlatformSize = new PlatformSize(1920, 1080);
      const restored: PlatformSize = PlatformSize.fromList(size.toList());
      expect(restored.getWidth()).assertEqual(1920);
      expect(restored.getHeight()).assertEqual(1080);
    });

    it('platformPoint_roundTripsAndKeepsValues', 0, () => {
      const point: PlatformPoint = new PlatformPoint(0.25, -0.75);
      const restored: PlatformPoint = PlatformPoint.fromList(point.toList());
      expect(restored.getX()).assertEqual(0.25);
      expect(restored.getY()).assertEqual(-0.75);

      const origin: PlatformPoint = new PlatformPoint(0, 0);
      expect(origin.getX()).assertEqual(0);
      expect(origin.getY()).assertEqual(0);
    });

    it('platformCameraDescription_roundTripsWithNestedEnum', 0, () => {
      const description: PlatformCameraDescription =
        new PlatformCameraDescription('back-cam', PlatformCameraLensDirection.back, 90);
      const restored: PlatformCameraDescription =
        PlatformCameraDescription.fromList(description.toList());
      expect(restored.getName()).assertEqual('back-cam');
      expect(restored.getLensDirection()).assertEqual(PlatformCameraLensDirection.back);
      expect(restored.getSensorOrientation()).assertEqual(90);
    });

    it('platformMediaSettings_roundTripsAllFields', 0, () => {
      const settings: PlatformMediaSettings =
        new PlatformMediaSettings(PlatformResolutionPreset.high, 30, 5000000, 48000, true);
      const restored: PlatformMediaSettings = PlatformMediaSettings.fromList(settings.toList());
      expect(restored.getResolutionPreset()).assertEqual(PlatformResolutionPreset.high);
      expect(restored.getFps()).assertEqual(30);
      expect(restored.getVideoBitrate()).assertEqual(5000000);
      expect(restored.getAudioBitrate()).assertEqual(48000);
      expect(restored.getEnableAudio()).assertTrue();
    });

    it('platformCameraState_roundTripsWithNestedPreviewSize', 0, () => {
      const state: PlatformCameraState = new PlatformCameraState(
        new PlatformSize(1280, 720),
        PlatformExposureMode.auto,
        PlatformFocusMode.locked,
        true,
        false);
      const restored: PlatformCameraState = PlatformCameraState.fromList(state.toList());
      expect(restored.getPreviewSize() != null).assertTrue();
      expect((restored.getPreviewSize() as PlatformSize).getWidth()).assertEqual(1280);
      expect((restored.getPreviewSize() as PlatformSize).getHeight()).assertEqual(720);
      expect(restored.getExposureMode()).assertEqual(PlatformExposureMode.auto);
      expect(restored.getFocusMode()).assertEqual(PlatformFocusMode.locked);
      expect(restored.getExposurePointSupported()).assertTrue();
      expect(restored.getFocusPointSupported()).assertFalse();
    });

    it('platformCameraState_nullPreviewSizeSurvivesRoundTrip', 0, () => {
      const state: PlatformCameraState = new PlatformCameraState(
        null, PlatformExposureMode.locked, PlatformFocusMode.auto, false, true);
      const restored: PlatformCameraState = PlatformCameraState.fromList(state.toList());
      expect(restored.getPreviewSize() == null).assertTrue();
      expect(restored.getExposurePointSupported()).assertFalse();
      expect(restored.getFocusPointSupported()).assertTrue();
    });

    it('platformEnums_numericContractsAreLocked', 0, () => {
      // PlatformFocusMode mirrors Camera Kit's non-sequential FocusMode values.
      expect(PlatformFocusMode.auto).assertEqual(1);
      expect(PlatformFocusMode.locked).assertEqual(3);

      expect(PlatformFlashMode.off).assertEqual(0);
      expect(PlatformFlashMode.auto).assertEqual(1);
      expect(PlatformFlashMode.always).assertEqual(2);
      expect(PlatformFlashMode.torch).assertEqual(3);

      expect(PlatformVideoStabilizationMode.off).assertEqual(0);
      expect(PlatformVideoStabilizationMode.level1).assertEqual(1);
      expect(PlatformVideoStabilizationMode.level2).assertEqual(2);
      expect(PlatformVideoStabilizationMode.level3).assertEqual(3);

      expect(PlatformCameraLensDirection.front).assertEqual(0);
      expect(PlatformCameraLensDirection.back).assertEqual(1);
      expect(PlatformCameraLensDirection.external).assertEqual(2);

      expect(PlatformDeviceOrientation.portraitUp).assertEqual(0);
      expect(PlatformDeviceOrientation.portraitDown).assertEqual(1);
      expect(PlatformDeviceOrientation.landscapeLeft).assertEqual(2);
      expect(PlatformDeviceOrientation.landscapeRight).assertEqual(3);

      expect(PlatformExposureMode.auto).assertEqual(0);
      expect(PlatformExposureMode.locked).assertEqual(1);

      expect(PlatformImageFormatGroup.jpeg).assertEqual(1);
      expect(PlatformImageFileFormat.jpeg).assertEqual(0);
      expect(PlatformImageFileFormat.heif).assertEqual(1);
    });

    it('flutterError_holdsAllFourFields', 0, () => {
      const error: FlutterError = new FlutterError('CameraAccessDenied', 'PlatformException',
        'access denied', 'stack line');
      expect(error.code).assertEqual('CameraAccessDenied');
      expect(error.name).assertEqual('PlatformException');
      expect(error.message).assertEqual('access denied');
      expect(error.stack).assertEqual('stack line');
    });

    it('setUpNull_clearsSentinelPigeonHandler', 0, () => {
      // Registering a handler on the exact getAvailableCameras pigeon channel simulates a
      // previously attached api; setUp(null) must deregister it without throwing.
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      messenger.setMessageHandler(
        'dev.flutter.pigeon.camera_ohos.CameraApi.getAvailableCameras',
        new StubBinaryMessageHandler());
      expect(messenger.hasHandler('dev.flutter.pigeon.camera_ohos.CameraApi.getAvailableCameras'))
        .assertTrue();

      let threw: boolean = false;
      try {
        CameraApi.setUp(messenger, null);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(messenger.hasHandler('dev.flutter.pigeon.camera_ohos.CameraApi.getAvailableCameras'))
        .assertFalse();
    });

    it('setUpNull_isIdempotentWhenNothingRegistered', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      let threw: boolean = false;
      try {
        CameraApi.setUp(messenger, null);
        CameraApi.setUp(messenger, null);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(messenger.countPigeonHandlers()).assertEqual(0);
    });

    it('eventApi_appendsChannelSuffixWhenProvided', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const eventApi: CameraEventApi = new CameraEventApi(messenger, 'sfx');
      eventApi.error('boom happened', new StubVoidReply());
      expect(messenger.sendCount).assertEqual(1);
      expect(messenger.sentChannels[0])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.error.sfx');
    });

    it('eventApi_defaultSuffixKeepsBareChannelName', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const eventApi: CameraEventApi = new CameraEventApi(messenger);
      eventApi.error('another boom', new StubVoidReply());
      expect(messenger.sentChannels[0])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.error');
    });
  });
}
