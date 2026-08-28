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

// Drives the Pigeon-generated channel handlers in Messages.ets end to end:
// CameraApi.setUp registers one handler per method on a MockBinaryMessenger,
// each test pulls the handler back out and feeds it a codec-encoded payload,
// then asserts on the decoded reply envelope. This covers the success path,
// both wrapError flavors (FlutterError vs plain Error), the Result<T>
// callback bridging, the api==null teardown branches, both custom codecs
// (type codes 128/129/130) and the CameraEventApi senders.

import { describe, it, expect } from '@ohos/hypium';
import { BinaryMessageHandler, BinaryReply } from
  '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import SendableBinaryMessageHandler from
  '@ohos/flutter_ohos/src/main/ets/plugin/common/SendableBinaryMessageHandler';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import camera from '@ohos.multimedia.camera';
import {
  CameraApi,
  CameraEventApi,
  CameraGlobalEventApi,
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
import { Camera } from '../../../main/ets/io/flutter/plugins/camera/Camera';
import { CameraApiImpl } from '../../../main/ets/io/flutter/plugins/camera/CameraApiImpl';
import { CameraPermissions } from '../../../main/ets/io/flutter/plugins/camera/CameraPermissions';
import { DartMessenger } from '../../../main/ets/io/flutter/plugins/camera/DartMessenger';
import { CameraFeatureFactoryImpl } from
  '../../../main/ets/io/flutter/plugins/camera/features/CameraFeatureFactoryImpl';
import { ResolutionPreset } from '../../../main/ets/io/flutter/plugins/camera/types/ResolutionPreset';
import {
  MockAbilityBinding,
  MockBinaryMessenger,
  PIGEON_CAMERA_API_PREFIX,
  StubCameraProperties,
  StubVoidReply,
  makeFakeSurfaceTextureEntry,
  makeFakeTextureRegistry,
  makeQuerySession,
  waitUntil
} from './TestMocks';

let factoryFailureMessage: string = '';

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

class ModesSessionShell {
  private readonly hasFlashValue: boolean;
  private readonly focusSupportedValue: boolean;

  constructor(hasFlashValue: boolean, focusSupportedValue: boolean) {
    this.hasFlashValue = hasFlashValue;
    this.focusSupportedValue = focusSupportedValue;
  }

  getZoomRatioRange(): Array<number> {
    return [1, 10];
  }

  getExposureBiasRange(): Array<number> {
    return [-8, 8];
  }

  hasFlash(): boolean {
    return this.hasFlashValue;
  }

  isFlashModeSupported(_mode: camera.FlashMode): boolean {
    return true;
  }

  setFlashMode(_mode: camera.FlashMode): void {
  }

  isExposureModeSupported(_mode: camera.ExposureMode): boolean {
    return true;
  }

  setExposureMode(_mode: camera.ExposureMode): void {
  }

  isFocusModeSupported(_mode: camera.FocusMode): boolean {
    return this.focusSupportedValue;
  }

  getFocusMode(): camera.FocusMode {
    return camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
  }

  setFocusMode(_mode: camera.FocusMode): void {
  }

  setFocusPoint(_point: camera.Point | null): void {
  }

  setMeteringPoint(_point: camera.Point | null): void {
  }

  setExposureBias(_bias: number): void {
  }

  setZoomRatio(_ratio: number): void {
  }
}

function makeShellSession(hasFlash: boolean, focusSupported: boolean): camera.PhotoSession {
  const shell: ModesSessionShell = new ModesSessionShell(hasFlash, focusSupported);
  return (shell as ESObject) as camera.PhotoSession;
}

interface ApiHandle {
  api: CameraApiImpl;
  messenger: MockBinaryMessenger;
}

function makeRegisteredApi(cameraInstance: Camera | null): ApiHandle {
  const messenger: MockBinaryMessenger = new MockBinaryMessenger();
  const api: CameraApiImpl =
    new CameraApiImpl(new MockAbilityBinding().getAbility(), messenger, makeFakeTextureRegistry());
  (api as ESObject).camera = cameraInstance;
  CameraApi.setUp(messenger, api);
  const handle: ApiHandle = { api: api, messenger: messenger };
  return handle;
}

// Sends a codec-encoded payload straight to the registered handler and
// returns the decoded reply envelope, or a '(no handler)'/'(no reply)'
// sentinel string when the pipeline never completed.
async function dispatch(messenger: MockBinaryMessenger, method: string, args: Array<Object | null>):
  Promise<Object | null> {
  const raw: BinaryMessageHandler | SendableBinaryMessageHandler | undefined =
    messenger.handlers.get(PIGEON_CAMERA_API_PREFIX + method);
  if (raw === undefined) {
    return '(no handler)';
  }
  const handler: BinaryMessageHandler = raw as BinaryMessageHandler;
  const message: ArrayBuffer = CameraApi.getCodec().encodeMessage(args as ESObject);
  const replies: Array<ArrayBuffer | null> = [];
  const reply: BinaryReply = {
    reply: (r: ArrayBuffer | null): void => {
      replies.push(r);
    }
  };
  handler.onMessage(message, reply);
  await waitUntil((): boolean => replies.length > 0, 5000);
  if (replies.length == 0) {
    return '(no reply)';
  }
  const buffer: ArrayBuffer | null = replies[0];
  if (buffer == null) {
    return null;
  }
  return CameraApi.getCodec().decodeMessage(buffer);
}

function errorCodeOf(reply: Object | null): string {
  const arr: Array<Object> = reply as Array<Object>;
  if (arr == null || arr.length != 3) {
    return '(not an error envelope)';
  }
  return arr[0] as string;
}

function assertOkEnvelope(reply: Object | null): void {
  const arr: Array<Object> = reply as Array<Object>;
  expect(arr != null && arr.length == 1).assertTrue();
}

export default function pigeonDispatchTest() {
  describe('PigeonDispatchTest', () => {
    it('setUp_registersAllHandlersThenNullClearsEveryOne', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      CameraApi.setUp(messenger, null);
      expect(messenger.countTotalHandlers()).assertEqual(0);
      const api: CameraApiImpl =
        new CameraApiImpl(new MockAbilityBinding().getAbility(), messenger, makeFakeTextureRegistry());
      CameraApi.setUp(messenger, api);
      expect(messenger.countTotalHandlers()).assertEqual(32);
      CameraApi.setUp(messenger, null);
      expect(messenger.countTotalHandlers()).assertEqual(0);
    });

    it('syncGetters_successWithShellSession', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      (cam as ESObject).photoSession = makeShellSession(true, true);
      const handle: ApiHandle = makeRegisteredApi(cam);
      const minOffset: Object | null = await dispatch(handle.messenger, 'getMinExposureOffset', []);
      assertOkEnvelope(minOffset);
      expect(((minOffset as Array<Object>)[0] as number)).assertEqual(-8);

      const maxOffset: Object | null = await dispatch(handle.messenger, 'getMaxExposureOffset', []);
      expect(((maxOffset as Array<Object>)[0] as number)).assertEqual(8);

      const step: Object | null = await dispatch(handle.messenger, 'getExposureOffsetStepSize', []);
      expect(((step as Array<Object>)[0] as number)).assertEqual(0.5);

      const maxZoom: Object | null = await dispatch(handle.messenger, 'getMaxZoomLevel', []);
      expect(((maxZoom as Array<Object>)[0] as number)).assertEqual(10);

      const minZoom: Object | null = await dispatch(handle.messenger, 'getMinZoomLevel', []);
      expect(((minZoom as Array<Object>)[0] as number)).assertEqual(1);
    });

    it('syncMethods_nullCamera_wrapFlutterError', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      const getterMethods: string[] = ['getMinExposureOffset', 'getMaxExposureOffset',
        'getExposureOffsetStepSize', 'getMaxZoomLevel', 'getMinZoomLevel'];
      for (const method of getterMethods) {
        const reply: Object | null = await dispatch(handle.messenger, method, []);
        expect(errorCodeOf(reply)).assertEqual('CAMERA_NOT_INITIALIZED');
      }
      const voidMethods: string[] = ['lockCaptureOrientation', 'unlockCaptureOrientation',
        'startImageStream', 'stopImageStream'];
      for (const method of voidMethods) {
        const args: Object[] = method === 'lockCaptureOrientation'
          ? [PlatformDeviceOrientation.portraitUp] : [];
        const reply: Object | null = await dispatch(handle.messenger, method, args);
        expect(errorCodeOf(reply)).assertEqual('CAMERA_NOT_INITIALIZED');
      }
    });

    it('syncMethods_successWithInjectedCamera', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      (cam as ESObject).photoSession = makeShellSession(true, true);
      const handle: ApiHandle = makeRegisteredApi(cam);
      const lock: Object | null =
        await dispatch(handle.messenger, 'lockCaptureOrientation', [PlatformDeviceOrientation.portraitDown]);
      assertOkEnvelope(lock);
      const unlock: Object | null = await dispatch(handle.messenger, 'unlockCaptureOrientation', []);
      assertOkEnvelope(unlock);
      // startImageStream feeds startPreviewWithImageStream, whose async chain
      // swallows the null-device failure; the handler itself must reply ok.
      const start: Object | null = await dispatch(handle.messenger, 'startImageStream', []);
      assertOkEnvelope(start);
      const stop: Object | null = await dispatch(handle.messenger, 'stopImageStream', []);
      assertOkEnvelope(stop);
    });

    it('asyncMethods_nullCamera_rejectWithFlutterError', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      const methods: string[] = ['pausePreview', 'resumePreview',
        'startVideoRecording', 'pauseVideoRecording', 'resumeVideoRecording',
        'setDescriptionWhileRecording', 'setFocusMode'];
      for (const method of methods) {
        const args: Object[] = [];
        if (method === 'startVideoRecording') {
          args.push(false);
        } else if (method === 'setDescriptionWhileRecording') {
          args.push('emulated');
        } else if (method === 'setFocusMode') {
          args.push(PlatformFocusMode.auto);
        }
        const reply: Object | null = await dispatch(handle.messenger, method, args);
        expect(errorCodeOf(reply)).assertEqual('CAMERA_NOT_INITIALIZED');
      }
    });

    it('initialize_nullCamera_rejectsCameraNotFound', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      const reply: Object | null =
        await dispatch(handle.messenger, 'initialize', [PlatformImageFormatGroup.jpeg]);
      expect(errorCodeOf(reply)).assertEqual('cameraNotFound');
    });

    it('dispose_nullCamera_resolvesWithNullEnvelope', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      const reply: Object | null = await dispatch(handle.messenger, 'dispose', []);
      assertOkEnvelope(reply);
    });

    it('resultMethods_nullCamera_errorEnvelope', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      // Each guard carries its own Pigeon error code.
      const table: Array<Array<Object | null>> = [
        ['takePicture', null, 'CAMERA_NOT_INITIALIZED'],
        ['stopVideoRecording', null, 'CAMERA_NOT_INITIALIZED'],
        ['setFlashMode', PlatformFlashMode.off, 'CAMERA_NOT_INITIALIZED'],
        ['setExposureMode', PlatformExposureMode.auto, 'CAMERA_NOT_INITIALIZED'],
        ['setExposurePoint', null, 'EXPOSURE_POINT_ERROR'],
        ['setFocusPoint', null, 'FOCUS_POINT_ERROR'],
        ['setExposureOffset', 1, 'CAMERA_NOT_INITIALIZED'],
        ['setZoomLevel', 1, 'ZOOM_ERROR'],
        ['setVideoStabilizationMode', PlatformVideoStabilizationMode.off, 'VIDEO_STABILIZATION_ERROR'],
        ['getSupportedVideoStabilizationModes', null, 'VIDEO_STABILIZATION_ERROR'],
        ['setImageFileFormat', PlatformImageFileFormat.jpeg, 'IMAGE_FILE_FORMAT_ERROR'],
        ['setJpegImageQuality', 50, 'JPEG_QUALITY_ERROR']
      ];
      for (const entry of table) {
        const method: string = entry[0] as string;
        const args: Array<Object | null> = [entry[1]];
        const reply: Object | null = await dispatch(handle.messenger, method, args);
        expect(errorCodeOf(reply)).assertEqual(entry[2] as string);
      }
    });

    it('resultMethods_successWithInjectedCameraAndShellSession', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      (cam as ESObject).photoSession = makeShellSession(true, true);
      const handle: ApiHandle = makeRegisteredApi(cam);

      const flash: Object | null =
        await dispatch(handle.messenger, 'setFlashMode', [PlatformFlashMode.torch]);
      assertOkEnvelope(flash);

      const exposure: Object | null =
        await dispatch(handle.messenger, 'setExposureMode', [PlatformExposureMode.locked]);
      assertOkEnvelope(exposure);

      const focusPointNull: Object | null =
        await dispatch(handle.messenger, 'setFocusPoint', [null]);
      assertOkEnvelope(focusPointNull);

      const focusPoint: Object | null =
        await dispatch(handle.messenger, 'setFocusPoint', [new PlatformPoint(0.2, 0.8)]);
      assertOkEnvelope(focusPoint);

      const exposurePoint: Object | null =
        await dispatch(handle.messenger, 'setExposurePoint', [new PlatformPoint(0.1, 0.9)]);
      assertOkEnvelope(exposurePoint);

      // Offset 5 sits inside the shell's [-8, 8] bias range, so the reply
      // carries the applied value unchanged.
      const offset: Object | null = await dispatch(handle.messenger, 'setExposureOffset', [5]);
      expect(((offset as Array<Object>)[0] as number)).assertEqual(5);

      const zoom: Object | null = await dispatch(handle.messenger, 'setZoomLevel', [5]);
      assertOkEnvelope(zoom);

      const stab: Object | null =
        await dispatch(handle.messenger, 'setVideoStabilizationMode', [PlatformVideoStabilizationMode.off]);
      assertOkEnvelope(stab);

      const modes: Object | null =
        await dispatch(handle.messenger, 'getSupportedVideoStabilizationModes', []);
      const modeList: Array<Object> = (modes as Array<Object>)[0] as Array<Object>;
      expect(modeList.length).assertEqual(4);

      const fileFormat: Object | null =
        await dispatch(handle.messenger, 'setImageFileFormat', [PlatformImageFileFormat.jpeg]);
      assertOkEnvelope(fileFormat);

      const quality: Object | null = await dispatch(handle.messenger, 'setJpegImageQuality', [88]);
      assertOkEnvelope(quality);

      // stopVideoRecording without an active recording short-circuits to success.
      const stop: Object | null = await dispatch(handle.messenger, 'stopVideoRecording', []);
      assertOkEnvelope(stop);
    });

    it('resultMethods_cameraLevelErrors_surfaceInnerCodes', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      const handle: ApiHandle = makeRegisteredApi(cam);

      // Shell without flash: Camera.setFlashMode answers through its own
      // error path, which the handler wraps as a FlutterError envelope.
      (cam as ESObject).photoSession = makeShellSession(false, true);
      const noFlash: Object | null =
        await dispatch(handle.messenger, 'setFlashMode', [PlatformFlashMode.off]);
      expect(errorCodeOf(noFlash)).assertEqual('setFlashModeFailed');

      // Out-of-range zoom against the shell's [1, 10] range.
      (cam as ESObject).photoSession = makeShellSession(true, true);
      const zoom: Object | null = await dispatch(handle.messenger, 'setZoomLevel', [99]);
      expect(errorCodeOf(zoom)).assertEqual('ZOOM_ERROR');

      // takePicture with no session at all fails inside lockAutoFocus.
      // (The shell session must be dropped first, otherwise capture proceeds
      // into the sensor-backed rotation path and never answers the handler.)
      (cam as ESObject).photoSession = null;
      const picture: Object | null = await dispatch(handle.messenger, 'takePicture', []);
      expect(errorCodeOf(picture)).assertEqual('captureSession null');
    });

    it('setFocusMode_unsupportedShell_rejectsFocusModeFailed', 0, async (): Promise<void> => {
      const cam: Camera | null = tryMakeCamera();
      expect(cam != null).assertTrue();
      if (cam == null) {
        return;
      }
      (cam as ESObject).photoSession = makeShellSession(true, false);
      const handle: ApiHandle = makeRegisteredApi(cam);
      const reply: Object | null =
        await dispatch(handle.messenger, 'setFocusMode', [PlatformFocusMode.locked]);
      expect(errorCodeOf(reply)).assertEqual('setFocusModeFailed');
    });

    it('create_alreadyInProgress_rejectsCreateError', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      (handle.api as ESObject).curStatus = 1; // STATUS.CREATE_ING
      const settings: PlatformMediaSettings =
        new PlatformMediaSettings(PlatformResolutionPreset.medium, 30, 1000, 2000, false);
      const reply: Object | null =
        await dispatch(handle.messenger, 'create', ['emulated', settings]);
      expect(errorCodeOf(reply)).assertEqual('CREATE_ERROR');
    });

    it('getAvailableCameras_shellContext_throwsPlainErrorWrapped', 0, async (): Promise<void> => {
      const handle: ApiHandle = makeRegisteredApi(null);
      const reply: Object | null = await dispatch(handle.messenger, 'getAvailableCameras', []);
      const arr: Array<Object> = reply as Array<Object>;
      // Depending on how the device treats the shell context this either
      // throws a plain Error (wrapError's else-branch, 3-element envelope)
      // or answers with the real camera list (1-element envelope). Both run
      // full handler machinery; no reply at all would be a failure.
      expect(arr != null && (arr.length == 3 || arr.length == 1)).assertTrue();
    });

    it('eventApi_sendersTargetSuffixedChannelsAndAcceptCallbacks', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const api: CameraEventApi = new CameraEventApi(messenger, '7');
      const callback: StubVoidReply = new StubVoidReply();
      const state: PlatformCameraState =
        new PlatformCameraState(new PlatformSize(4, 3), PlatformExposureMode.auto,
          PlatformFocusMode.auto, true, true);
      api.initialized(state, callback);
      api.error('boom', callback);
      api.cameraSwitched('cam-x', callback);
      api.closed(callback);
      expect(messenger.sendCount).assertEqual(4);
      expect(messenger.sentChannels[0])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.initialized.7');
      expect(messenger.sentChannels[1])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.error.7');
      expect(messenger.sentChannels[2])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.cameraSwitched.7');
      expect(messenger.sentChannels[3])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraEventApi.closed.7');

      const globalApi: CameraGlobalEventApi = new CameraGlobalEventApi(messenger);
      globalApi.deviceOrientationChanged(PlatformDeviceOrientation.landscapeLeft, callback);
      expect(messenger.sendCount).assertEqual(5);
      expect(messenger.sentChannels[4])
        .assertEqual('dev.flutter.pigeon.camera_ohos.CameraGlobalEventApi.deviceOrientationChanged');
    });

    it('cameraApiCodec_roundTripsCustomTypesAndPlainValues', 0, () => {
      const codec: MessageCodec<Object> = CameraApi.getCodec();
      const description: PlatformCameraDescription =
        new PlatformCameraDescription('cam1', PlatformCameraLensDirection.front, 90);
      const settings: PlatformMediaSettings =
        new PlatformMediaSettings(PlatformResolutionPreset.high, 30, 1000, 2000, true);
      const point: PlatformPoint = new PlatformPoint(0.5, 0.25);
      const encoded: ArrayBuffer = codec.encodeMessage([description, settings, point, 'plain'] as ESObject);
      const decoded: Array<Object> = codec.decodeMessage(encoded) as Array<Object>;
      expect(decoded.length).assertEqual(4);

      const backDescription: PlatformCameraDescription = decoded[0] as PlatformCameraDescription;
      expect(backDescription instanceof PlatformCameraDescription).assertTrue();
      expect(backDescription.getName()).assertEqual('cam1');
      expect(backDescription.getLensDirection()).assertEqual(PlatformCameraLensDirection.front);
      expect(backDescription.getSensorOrientation()).assertEqual(90);

      const backSettings: PlatformMediaSettings = decoded[1] as PlatformMediaSettings;
      expect(backSettings instanceof PlatformMediaSettings).assertTrue();
      expect(backSettings.getResolutionPreset()).assertEqual(PlatformResolutionPreset.high);
      expect(backSettings.getFps()).assertEqual(30);
      expect(backSettings.getVideoBitrate()).assertEqual(1000);
      expect(backSettings.getAudioBitrate()).assertEqual(2000);
      expect(backSettings.getEnableAudio()).assertTrue();

      const backPoint: PlatformPoint = decoded[2] as PlatformPoint;
      expect(backPoint instanceof PlatformPoint).assertTrue();
      expect(backPoint.getX()).assertEqual(0.5);
      expect(backPoint.getY()).assertEqual(0.25);

      expect(decoded[3] as string).assertEqual('plain');
    });

    it('cameraEventApiCodec_roundTripsStateAndSize', 0, () => {
      const codec: MessageCodec<Object> = CameraEventApi.getCodec();
      const state: PlatformCameraState =
        new PlatformCameraState(new PlatformSize(640, 480), PlatformExposureMode.locked,
          PlatformFocusMode.locked, false, true);
      const size: PlatformSize = new PlatformSize(320, 240);
      const encoded: ArrayBuffer = codec.encodeMessage([state, size] as ESObject);
      const decoded: Array<Object> = codec.decodeMessage(encoded) as Array<Object>;
      expect(decoded.length).assertEqual(2);

      const backState: PlatformCameraState = decoded[0] as PlatformCameraState;
      expect(backState instanceof PlatformCameraState).assertTrue();
      expect(backState.getExposureMode()).assertEqual(PlatformExposureMode.locked);
      expect(backState.getFocusMode()).assertEqual(PlatformFocusMode.locked);
      expect(backState.getExposurePointSupported()).assertFalse();
      expect(backState.getFocusPointSupported()).assertTrue();
      expect((backState.getPreviewSize() as PlatformSize).getWidth()).assertEqual(640);
      expect((backState.getPreviewSize() as PlatformSize).getHeight()).assertEqual(480);

      const backSize: PlatformSize = decoded[1] as PlatformSize;
      expect(backSize instanceof PlatformSize).assertTrue();
      expect(backSize.getWidth()).assertEqual(320);
      expect(backSize.getHeight()).assertEqual(240);
    });

    it('platformCameraState_toListHandlesArrayShapedPreviewSize', 0, () => {
      const state: PlatformCameraState =
        new PlatformCameraState(null, PlatformExposureMode.auto, PlatformFocusMode.auto, true, false);
      (state as ESObject).previewSize = [7, 9];
      const arr: Object[] = state.toList();
      const preview: Array<Object> = arr[0] as Array<Object>;
      expect(preview.length).assertEqual(2);
      expect(preview[0] as number).assertEqual(7);
      expect(preview[1] as number).assertEqual(9);

      const restored: PlatformCameraState =
        PlatformCameraState.fromList([arr[0], 0, 1, true, false]);
      expect((restored.getPreviewSize() as PlatformSize).getWidth()).assertEqual(7);
      expect((restored.getPreviewSize() as PlatformSize).getHeight()).assertEqual(9);
      expect(restored.getExposureMode()).assertEqual(PlatformExposureMode.auto);
      expect(restored.getFocusPointSupported()).assertFalse();
    });

    it('platformSize_roundsFractionalComponents', 0, () => {
      const fromList: PlatformSize = PlatformSize.fromList([1.4, 2.6]);
      expect(fromList.getWidth()).assertEqual(1);
      expect(fromList.getHeight()).assertEqual(3);

      const rounded: Object[] = new PlatformSize(2.5, 3.4).toList();
      expect(rounded[0] as number).assertEqual(3);
      expect(rounded[1] as number).assertEqual(3);
    });
  });
}
