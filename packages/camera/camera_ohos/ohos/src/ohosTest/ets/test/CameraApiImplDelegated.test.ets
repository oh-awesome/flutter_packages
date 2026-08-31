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

// Covers CameraApiImpl's delegated branches (everything past the
// camera==null guards): a controllable FakeCamera is injected into the
// private camera field and answers each call in one of four scripted modes
// (success / error callback / notImplemented / throw), so every branch of
// the CameraMethodResult closures and the outer try/catch fallbacks runs.
// Private helpers (replayCameraOutputSettings, switchToRearCamera) are
// reached through ESObject calls, which matches their runtime dispatch.

import { describe, it, expect } from '@ohos/hypium';
import { EventChannel } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { DeviceOrientation } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/systemchannels/PlatformChannel';
import { CameraApiImpl } from '../../../main/ets/io/flutter/plugins/camera/CameraApiImpl';
import {
  FlutterError,
  PlatformDeviceOrientation,
  PlatformExposureMode,
  PlatformFlashMode,
  PlatformFocusMode,
  PlatformImageFileFormat,
  PlatformImageFormatGroup,
  PlatformPoint,
  PlatformVideoStabilizationMode
} from '../../../main/ets/io/flutter/plugins/camera/Messages';
import { CameraPermissions } from '../../../main/ets/io/flutter/plugins/camera/CameraPermissions';
import { Point } from '../../../main/ets/io/flutter/plugins/camera/features/Point';
import {
  MockAbilityBinding,
  MockBinaryMessenger,
  StubPigeonResult,
  makeFakeTextureRegistry
} from './TestMocks';

// Scripted camera double: records every delegated call and answers Result
// callbacks according to failMode ('' = success, 'error', 'notImplemented',
// 'throw' = raise synchronously).
class FakeCamera {
  calls: Array<string> = new Array<string>();
  failMode: string = '';
  failOpenWith: string = '';

  private deliver(name: string, result: MethodResult): void {
    this.calls.push(name);
    if (this.failMode === 'throw') {
      throw new Error('camera exploded');
    }
    if (this.failMode === 'error') {
      result.error('deliberateFailure', 'scripted failure', null);
      return;
    }
    if (this.failMode === 'notImplemented') {
      result.notImplemented();
      return;
    }
    result.success(null);
  }

  takePicture(result: MethodResult): void {
    this.deliver('takePicture', result);
  }

  stopVideoRecording(result: MethodResult): void {
    this.deliver('stopVideoRecording', result);
  }

  startVideoRecording(result: MethodResult, _channel: EventChannel | null): void {
    this.deliver('startVideoRecording', result);
  }

  pauseVideoRecording(result: MethodResult): void {
    this.deliver('pauseVideoRecording', result);
  }

  resumeVideoRecording(result: MethodResult): void {
    this.deliver('resumeVideoRecording', result);
  }

  pausePreview(result: MethodResult): void {
    this.deliver('pausePreview', result);
  }

  resumePreview(result: MethodResult): void {
    this.deliver('resumePreview', result);
  }

  setDescriptionWhileRecording(result: MethodResult, _properties: Object): void {
    this.deliver('setDescriptionWhileRecording', result);
  }

  setFocusMode(result: MethodResult, _mode: Object): void {
    this.deliver('setFocusMode', result);
  }

  setFocusPoint(result: MethodResult, _point: Point): void {
    this.deliver('setFocusPoint', result);
  }

  setExposureMode(result: MethodResult, _mode: Object): void {
    this.deliver('setExposureMode', result);
  }

  setExposurePoint(result: MethodResult, _point: Point): void {
    this.deliver('setExposurePoint', result);
  }

  setExposureOffset(result: MethodResult, _offset: number): void {
    this.deliver('setExposureOffset', result);
  }

  setFlashMode(result: MethodResult, _mode: Object): void {
    this.deliver('setFlashMode', result);
  }

  setZoomLevel(result: MethodResult, _zoom: number): void {
    this.deliver('setZoomLevel', result);
  }

  setVideoStabilizationMode(result: MethodResult, _mode: PlatformVideoStabilizationMode): void {
    this.deliver('setVideoStabilizationMode', result);
  }

  setImageFileFormat(result: MethodResult, _format: PlatformImageFileFormat): void {
    this.deliver('setImageFileFormat', result);
  }

  setJpegImageQuality(result: MethodResult, _quality: number): void {
    this.deliver('setJpegImageQuality', result);
  }

  getSupportedVideoStabilizationModes(): PlatformVideoStabilizationMode[] {
    this.calls.push('getSupportedVideoStabilizationModes');
    return [PlatformVideoStabilizationMode.off, PlatformVideoStabilizationMode.level1,
      PlatformVideoStabilizationMode.level2, PlatformVideoStabilizationMode.level3];
  }

  getMaxZoomLevel(): number {
    return 10;
  }

  getMinZoomLevel(): number {
    return 1;
  }

  getMinExposureOffset(): number {
    return -8;
  }

  getMaxExposureOffset(): number {
    return 8;
  }

  getExposureOffsetStepSize(): number {
    return 0.5;
  }

  lockCaptureOrientation(_orientation: DeviceOrientation): void {
    this.calls.push('lockCaptureOrientation');
  }

  unlockCaptureOrientation(): void {
    this.calls.push('unlockCaptureOrientation');
  }

  startPreviewWithImageStream(_channel: EventChannel): void {
    this.calls.push('startPreviewWithImageStream');
  }

  async startPreview(): Promise<void> {
    this.calls.push('startPreview');
  }

  async open(_imageFormatGroup: string | null): Promise<void> {
    this.calls.push('open');
    if (this.failOpenWith !== '') {
      throw new Error(this.failOpenWith);
    }
  }

  async close(): Promise<void> {
    this.calls.push('close');
  }

  async dispose(): Promise<void> {
    this.calls.push('dispose');
  }
}

interface DelegateHandle {
  api: CameraApiImpl;
  fake: FakeCamera;
}

// Texture registry shell whose unregister actually works, so the dispose
// path can reset textureId instead of dying inside the swallowed TypeError.
class WorkingRegistryShell {
  unregisterTexture(_textureId: number): void {
  }
}

function makeDelegatedApi(failMode: string): DelegateHandle {
  const api: CameraApiImpl =
    new CameraApiImpl(new MockAbilityBinding().getAbility(), new MockBinaryMessenger(),
      makeFakeTextureRegistry());
  const fake: FakeCamera = new FakeCamera();
  fake.failMode = failMode;
  (api as ESObject).camera = (fake as ESObject) as Object;
  (api as ESObject).textureRegistry =
    (new WorkingRegistryShell() as ESObject) as Object;
  const handle: DelegateHandle = { api: api, fake: fake };
  return handle;
}

async function rejectCode(pending: Promise<void>): Promise<string> {
  try {
    await pending;
  } catch (e) {
    return (e as FlutterError).code;
  }
  return '(did not reject)';
}

export default function cameraApiImplDelegatedTest() {
  describe('CameraApiImplDelegatedTest', () => {
    it('resultMethods_delegateSuccessToCamera', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      const ok: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setJpegImageQuality(85, ok);
      expect(ok.successCount).assertEqual(1);
      expect(((handle.api as ESObject).currentJpegQuality as number)).assertEqual(85);

      handle.api.setVideoStabilizationMode(PlatformVideoStabilizationMode.level2, ok);
      expect(ok.successCount).assertEqual(2);

      handle.api.setZoomLevel(3, ok);
      expect(ok.successCount).assertEqual(3);

      const offset: StubPigeonResult<number> = new StubPigeonResult<number>();
      handle.api.setExposureOffset(-2, offset);
      expect(offset.successCount).assertEqual(1);
      expect(offset.errors.length).assertEqual(0);
    });

    it('setImageFileFormat_crossFormatInvalidatesCachedQuality', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      (handle.api as ESObject).currentJpegQuality = 80;
      const ok: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setImageFileFormat(PlatformImageFileFormat.heif, ok);
      expect(ok.successCount).assertEqual(1);
      expect(((handle.api as ESObject).currentImageFileFormat as number))
        .assertEqual(PlatformImageFileFormat.heif);
      expect(((handle.api as ESObject).currentJpegQuality == null)).assertTrue();

      // Same-format switch must keep the cache untouched (still null here).
      handle.api.setImageFileFormat(PlatformImageFileFormat.heif, ok);
      expect(ok.successCount).assertEqual(2);
    });

    it('resultMethods_delegateErrorCallbacksAsFlutterErrors', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('error');
      const failed: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setJpegImageQuality(50, failed);
      handle.api.setVideoStabilizationMode(PlatformVideoStabilizationMode.off, failed);
      handle.api.setZoomLevel(1, failed);
      expect(failed.errors.length).assertEqual(3);
      expect((failed.errors[0] as FlutterError).code).assertEqual('deliberateFailure');

      const picture: StubPigeonResult<string> = new StubPigeonResult<string>();
      handle.api.takePicture(picture);
      expect((picture.errors[0] as FlutterError).code).assertEqual('deliberateFailure');
    });

    it('resultMethods_delegateNotImplementedCallbacks', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('notImplemented');
      const quality: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setJpegImageQuality(50, quality);
      expect((quality.errors[0] as FlutterError).code).assertEqual('JPEG_QUALITY_ERROR');

      const stab: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setVideoStabilizationMode(PlatformVideoStabilizationMode.off, stab);
      expect((stab.errors[0] as FlutterError).code).assertEqual('VIDEO_STABILIZATION_ERROR');

      const picture: StubPigeonResult<string> = new StubPigeonResult<string>();
      handle.api.takePicture(picture);
      expect((picture.errors[0] as FlutterError).code).assertEqual('TAKE_PICTURE_ERROR');
    });

    it('resultMethods_cameraThrowingFallsIntoCatchBranch', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('throw');
      const failed: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setJpegImageQuality(50, failed);
      expect((failed.errors[0] as FlutterError).code).assertEqual('JPEG_QUALITY_ERROR');

      const stab: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setVideoStabilizationMode(PlatformVideoStabilizationMode.off, stab);
      expect((stab.errors[0] as FlutterError).code).assertEqual('VIDEO_STABILIZATION_ERROR');
    });

    it('pointMethods_passNullAndNonNullVariants', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      const ok: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setFocusPoint(null, ok);
      handle.api.setFocusPoint(new PlatformPoint(0.1, 0.2), ok);
      handle.api.setExposurePoint(null, ok);
      handle.api.setExposurePoint(new PlatformPoint(0.3, 0.4), ok);
      expect(ok.successCount).assertEqual(4);
      expect(handle.fake.calls.length).assertEqual(4);
      expect(handle.fake.calls[0]).assertEqual('setFocusPoint');
      expect(handle.fake.calls[2]).assertEqual('setExposurePoint');
    });

    it('modeSetters_resolveKnownEnums', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      const ok: StubPigeonResult<void> = new StubPigeonResult<void>();
      handle.api.setFlashMode(PlatformFlashMode.auto, ok);
      handle.api.setExposureMode(PlatformExposureMode.locked, ok);
      expect(ok.successCount).assertEqual(2);
    });

    it('asyncMethods_delegateSuccessErrorAndNotImplemented', 0, async (): Promise<void> => {
      const okHandle: DelegateHandle = makeDelegatedApi('');
      await okHandle.api.pausePreview();
      await okHandle.api.resumePreview();
      await okHandle.api.pauseVideoRecording();
      await okHandle.api.resumeVideoRecording();
      await okHandle.api.startVideoRecording(true);
      await okHandle.api.setFocusMode(PlatformFocusMode.locked);
      expect(okHandle.fake.calls.indexOf('pausePreview') >= 0).assertTrue();

      const errorHandle: DelegateHandle = makeDelegatedApi('error');
      expect(await rejectCode(errorHandle.api.pausePreview())).assertEqual('deliberateFailure');
      expect(await rejectCode(errorHandle.api.setFocusMode(PlatformFocusMode.auto)))
        .assertEqual('deliberateFailure');

      const niHandle: DelegateHandle = makeDelegatedApi('notImplemented');
      expect(await rejectCode(niHandle.api.resumeVideoRecording())).assertEqual('NOT_IMPLEMENTED');
    });

    it('setFocusMode_unknownNumericModeRejects', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      const bogus: PlatformFocusMode = (2 as ESObject) as PlatformFocusMode;
      expect(await rejectCode(handle.api.setFocusMode(bogus))).assertEqual('SET_FOCUS_MODE_ERROR');
    });

    it('setDescriptionWhileRecording_managerLookupFailsBeforeDelegation', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      // The shell context cannot reach the camera service, so CameraPropertiesImpl
      // construction throws and the outer catch rejects with the raw error.
      let rejected: boolean = false;
      try {
        await handle.api.setDescriptionWhileRecording('emulated');
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('getters_delegateToCameraValues', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      expect(handle.api.getMaxZoomLevel()).assertEqual(10);
      expect(handle.api.getMinZoomLevel()).assertEqual(1);
      expect(handle.api.getMinExposureOffset()).assertEqual(-8);
      expect(handle.api.getMaxExposureOffset()).assertEqual(8);
      expect(handle.api.getExposureOffsetStepSize()).assertEqual(0.5);
    });

    it('getSupportedModes_delegatesFourStabilizationModes', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      const modes: StubPigeonResult<Array<PlatformVideoStabilizationMode>> =
        new StubPigeonResult<Array<PlatformVideoStabilizationMode>>();
      handle.api.getSupportedVideoStabilizationModes(modes);
      expect(modes.successCount).assertEqual(1);
      expect(handle.fake.calls.indexOf('getSupportedVideoStabilizationModes') >= 0).assertTrue();
    });

    it('orientationAndStreamMethods_delegateQuietly', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      handle.api.lockCaptureOrientation(PlatformDeviceOrientation.landscapeLeft);
      handle.api.unlockCaptureOrientation();
      handle.api.startImageStream();
      handle.api.stopImageStream();
      expect(handle.fake.calls.indexOf('lockCaptureOrientation') >= 0).assertTrue();
      expect(handle.fake.calls.indexOf('startPreviewWithImageStream') >= 0).assertTrue();
    });

    it('initialize_delegatesOpenAndResolves', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      await handle.api.initialize(PlatformImageFormatGroup.jpeg);
      expect(handle.fake.calls.indexOf('open') >= 0).assertTrue();
    });

    it('initialize_openFailureClosesAndRejectsCameraError', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      handle.fake.failOpenWith = 'open boom';
      let code: string = '(did not reject)';
      try {
        await handle.api.initialize(PlatformImageFormatGroup.jpeg);
      } catch (e) {
        code = (e as FlutterError).code;
      }
      expect(code).assertEqual('CameraError');
      expect(handle.fake.calls.indexOf('close') >= 0).assertTrue();
    });

    it('dispose_closesDisposesAndResetsTexture', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      (handle.api as ESObject).textureId = 5;
      await handle.api.dispose();
      expect(handle.fake.calls.indexOf('close') >= 0).assertTrue();
      expect(handle.fake.calls.indexOf('dispose') >= 0).assertTrue();
      expect(((handle.api as ESObject).camera == null)).assertTrue();
      expect(((handle.api as ESObject).textureId as number)).assertEqual(-1);
    });

    it('replayCameraOutputSettings_appliesCachedQualityOnlyForJpeg', 0, () => {
      const handle: DelegateHandle = makeDelegatedApi('');
      (handle.api as ESObject).currentJpegQuality = 70;
      (handle.api as ESObject).currentImageFileFormat = PlatformImageFileFormat.jpeg;
      (handle.api as ESObject).replayCameraOutputSettings();
      expect(handle.fake.calls.indexOf('setImageFileFormat') >= 0).assertTrue();
      expect(handle.fake.calls.indexOf('setJpegImageQuality') >= 0).assertTrue();

      // With heif as current format the cached quality must not be replayed.
      const heifHandle: DelegateHandle = makeDelegatedApi('');
      (heifHandle.api as ESObject).currentJpegQuality = 70;
      (heifHandle.api as ESObject).currentImageFileFormat = PlatformImageFileFormat.heif;
      (heifHandle.api as ESObject).replayCameraOutputSettings();
      expect(heifHandle.fake.calls.indexOf('setJpegImageQuality') >= 0).assertFalse();
    });

    it('switchToRearCamera_closesOldCameraUntilTextureGuard', 0, async (): Promise<void> => {
      const handle: DelegateHandle = makeDelegatedApi('');
      // Device enumeration works without permissions in the test process, so
      // a rear camera is found, the old (fake) camera is closed and disposed,
      // and the flow stops at the null-flutterTexture guard before rebuilding.
      await (handle.api as ESObject).switchToRearCamera() as Object;
      expect(handle.fake.calls.indexOf('close') >= 0).assertTrue();
      expect(handle.fake.calls.indexOf('dispose') >= 0).assertTrue();
      expect(((handle.api as ESObject).camera == null)).assertTrue();
    });
  });
}
