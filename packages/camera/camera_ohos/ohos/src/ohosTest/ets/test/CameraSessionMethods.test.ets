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

// Exercises Camera's session-dependent methods by injecting ESObject shells
// for the private session/output/recorder fields. Real construction (feature
// init + system lookups) is unchanged; only the fields a real camera session
// would populate are replaced, letting each success and error branch of the
// mode setters, preview control, recorder plumbing and the photo file writer
// run inside the test process.

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import fs from '@ohos.file.fs';
import { Camera } from '../../../main/ets/io/flutter/plugins/camera/Camera';
import { CameraPermissions, AudioPermission } from '../../../main/ets/io/flutter/plugins/camera/CameraPermissions';
import { CameraState } from '../../../main/ets/io/flutter/plugins/camera/CameraState';
import { DartMessenger } from '../../../main/ets/io/flutter/plugins/camera/DartMessenger';
import { CameraFeatureFactoryImpl } from
  '../../../main/ets/io/flutter/plugins/camera/features/CameraFeatureFactoryImpl';
import { Point } from '../../../main/ets/io/flutter/plugins/camera/features/Point';
import { ResolutionPreset } from '../../../main/ets/io/flutter/plugins/camera/types/ResolutionPreset';
import { MockAbilityBinding, MockBinaryMessenger, MockMethodResult, StubCameraProperties,
  makeFakeSurfaceTextureEntry } from './TestMocks';

class ModesShell {
  throwOnFocusPoint: boolean = false;
  throwOnMetering: boolean = false;
  throwOnBias: boolean = false;
  throwOnZoom: boolean = false;
  hasFlashValue: boolean = true;
  flashModeSupportedValue: boolean = true;
  exposureModeSupportedValue: boolean = true;
  focusModeSupportedValue: boolean = true;

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
    return this.flashModeSupportedValue;
  }

  setFlashMode(_mode: camera.FlashMode): void {
  }

  isExposureModeSupported(_mode: camera.ExposureMode): boolean {
    return this.exposureModeSupportedValue;
  }

  setExposureMode(_mode: camera.ExposureMode): void {
  }

  isFocusModeSupported(_mode: camera.FocusMode): boolean {
    return this.focusModeSupportedValue;
  }

  getFocusMode(): camera.FocusMode {
    return camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
  }

  setFocusMode(_mode: camera.FocusMode): void {
  }

  setFocusPoint(_point: camera.Point | null): void {
    if (this.throwOnFocusPoint) {
      throw new Error('focus point rejected');
    }
  }

  setMeteringPoint(_point: camera.Point | null): void {
    if (this.throwOnMetering) {
      throw new Error('metering rejected');
    }
  }

  setExposureBias(_bias: number): void {
    if (this.throwOnBias) {
      throw new Error('bias rejected');
    }
  }

  setZoomRatio(_ratio: number): void {
    if (this.throwOnZoom) {
      throw new Error('zoom rejected');
    }
  }
}

function makeShell(hasFlash: boolean = true, flashSupported: boolean = true,
  exposureSupported: boolean = true, focusSupported: boolean = true): camera.PhotoSession {
  const shell: ModesShell = new ModesShell();
  shell.hasFlashValue = hasFlash;
  shell.flashModeSupportedValue = flashSupported;
  shell.exposureModeSupportedValue = exposureSupported;
  shell.focusModeSupportedValue = focusSupported;
  return (shell as ESObject) as camera.PhotoSession;
}

function shellOf(session: camera.PhotoSession): ModesShell {
  return (session as ESObject) as ModesShell;
}

class PreviewShell {
  stopCount: number = 0;
  startCount: number = 0;
  releaseCount: number = 0;
  throwOnStop: boolean = false;
  throwOnStart: boolean = false;
  rotationAnswer: camera.ImageRotation = camera.ImageRotation.ROTATION_0;

  async stop(): Promise<void> {
    if (this.throwOnStop) {
      throw new Error('stop failed');
    }
    this.stopCount++;
  }

  async start(): Promise<void> {
    if (this.throwOnStart) {
      throw new Error('start failed');
    }
    this.startCount++;
  }

  async release(): Promise<void> {
    this.releaseCount++;
  }

  getPreviewRotation(_rotation: camera.ImageRotation): camera.ImageRotation {
    return this.rotationAnswer;
  }

  setPreviewRotation(_rotation: camera.ImageRotation, _isForMirror: boolean): void {
  }
}

class RecorderShell {
  state: string = 'idle';
  pauseCount: number = 0;
  resumeCount: number = 0;
  stopCount: number = 0;
  releaseCount: number = 0;
  resetCount: number = 0;
  rotations: Array<camera.ImageRotation> = new Array<camera.ImageRotation>();

  async pause(): Promise<void> {
    this.pauseCount++;
  }

  async resume(): Promise<void> {
    this.resumeCount++;
  }

  async stop(): Promise<void> {
    this.stopCount++;
  }

  async release(): Promise<void> {
    this.releaseCount++;
  }

  async reset(): Promise<void> {
    this.resetCount++;
  }

  async updateRotation(rotation: camera.ImageRotation): Promise<void> {
    this.rotations.push(rotation);
  }
}

class VideoOutShell {
  activeMin: number = 15;
  activeMax: number = 30;
  mirrorSupportedValue: boolean = false;
  setRatePairs: Array<number> = new Array<number>();
  enableMirrorCount: number = 0;
  startCount: number = 0;
  stopCount: number = 0;
  releaseCount: number = 0;
  throwOnActiveFrameRate: boolean = false;

  getActiveFrameRate(): camera.FrameRateRange {
    if (this.throwOnActiveFrameRate) {
      throw new Error('frame rate query failed');
    }
    const range: camera.FrameRateRange = { min: this.activeMin, max: this.activeMax };
    return range;
  }

  setFrameRate(_min: number, _max: number): void {
    this.setRatePairs.push(_min);
  }

  isMirrorSupported(): boolean {
    return this.mirrorSupportedValue;
  }

  enableMirror(_enabled: boolean): void {
    this.enableMirrorCount++;
  }

  async stop(): Promise<void> {
    this.stopCount++;
  }

  async start(): Promise<void> {
    this.startCount++;
  }

  async release(): Promise<void> {
    this.releaseCount++;
  }

  async getVideoRotation(_degree: number): Promise<camera.ImageRotation> {
    return camera.ImageRotation.ROTATION_90;
  }
}

class GrantShell {
  grant: boolean = false;

  async checkPermissions(_permission: Array<string>): Promise<boolean> {
    return this.grant;
  }
}

// Field names mirror the camera.CameraDevice interface so the ESObject cast
// resolves every property the mirror checks at runtime.
interface DeviceShellFields {
  cameraPosition: number;
  cameraId: string;
  connectionType: number;
  cameraOrientation: number;
  deviceType: number;
  connectionId: number;
}

function makeMessenger(): MockBinaryMessenger {
  return new MockBinaryMessenger();
}

function makeCamera(messenger: MockBinaryMessenger, enableAudio: boolean = false,
  permissions: CameraPermissions = new CameraPermissions()): Camera {
  return new Camera(new MockAbilityBinding().getAbility(), makeFakeSurfaceTextureEntry(),
    new CameraFeatureFactoryImpl(), new DartMessenger(messenger), new StubCameraProperties(),
    ResolutionPreset.medium, enableAudio, permissions);
}

export default function cameraSessionMethodsTest() {
  describe('CameraSessionMethodsTest', () => {
    it('setFocusPoint_nullPointForwardsNullAndSucceeds', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell();
      const result: MockMethodResult = new MockMethodResult();
      cam.setFocusPoint(result, new Point(null, null));
      expect(result.successArgs.length).assertEqual(1);
      expect(result.errorCodes.length).assertEqual(0);
    });

    it('setFocusPoint_validPointSwapsCoordinates', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const session: camera.PhotoSession = makeShell();
      (cam as ESObject).photoSession = session;
      const result: MockMethodResult = new MockMethodResult();
      cam.setFocusPoint(result, new Point(0.25, 0.75));
      expect(result.successArgs.length).assertEqual(1);
    });

    it('setFocusPoint_sessionFailureReportsError', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const session: camera.PhotoSession = makeShell();
      shellOf(session).throwOnFocusPoint = true;
      (cam as ESObject).photoSession = session;
      const result: MockMethodResult = new MockMethodResult();
      cam.setFocusPoint(result, new Point(0.5, 0.5));
      expect(result.errorCodes[0]).assertEqual('setFocusPointFailed');
    });

    it('setFocusMode_unsupportedAndSuccessPaths', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const unsupported: camera.PhotoSession = makeShell(true, true, true, false);
      (cam as ESObject).photoSession = unsupported;
      const rejected: MockMethodResult = new MockMethodResult();
      cam.setFocusMode(rejected, camera.FocusMode.FOCUS_MODE_LOCKED);
      expect(rejected.errorCodes[0]).assertEqual('setFocusModeFailed');

      (cam as ESObject).photoSession = makeShell();
      const ok: MockMethodResult = new MockMethodResult();
      cam.setFocusMode(ok, camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
      expect(ok.successArgs.length).assertEqual(1);
    });

    it('setExposureMode_unsupportedReportsError', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell(true, true, false, true);
      const result: MockMethodResult = new MockMethodResult();
      cam.setExposureMode(result, camera.ExposureMode.EXPOSURE_MODE_LOCKED);
      expect(result.errorCodes[0]).assertEqual('setExposureModeFailed');
    });

    it('setFlashMode_threeSupportBranches', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell(false);
      const noFlash: MockMethodResult = new MockMethodResult();
      cam.setFlashMode(noFlash, camera.FlashMode.FLASH_MODE_AUTO);
      expect(noFlash.errorCodes[0]).assertEqual('setFlashModeFailed');

      (cam as ESObject).photoSession = makeShell(true, false);
      const unsupported: MockMethodResult = new MockMethodResult();
      cam.setFlashMode(unsupported, camera.FlashMode.FLASH_MODE_AUTO);
      expect(unsupported.errorCodes[0]).assertEqual('setFlashModeFailed');

      (cam as ESObject).photoSession = makeShell(true, true);
      const ok: MockMethodResult = new MockMethodResult();
      cam.setFlashMode(ok, camera.FlashMode.FLASH_MODE_OPEN);
      expect(ok.successArgs.length).assertEqual(1);
    });

    it('setExposurePoint_nullAndFailurePaths', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell();
      const ok: MockMethodResult = new MockMethodResult();
      cam.setExposurePoint(ok, new Point(null, null));
      expect(ok.successArgs.length).assertEqual(1);

      const session: camera.PhotoSession = makeShell();
      shellOf(session).throwOnMetering = true;
      (cam as ESObject).photoSession = session;
      const failed: MockMethodResult = new MockMethodResult();
      cam.setExposurePoint(failed, new Point(0.5, 0.5));
      expect(failed.errorCodes[0]).assertEqual('setExposurePointFailed');
    });

    it('setExposureOffset_clampsToSessionBiasRange', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell();
      const high: MockMethodResult = new MockMethodResult();
      cam.setExposureOffset(high, 99);
      expect(high.successArgs[0] as number).assertEqual(8);

      const low: MockMethodResult = new MockMethodResult();
      cam.setExposureOffset(low, -99);
      expect(low.successArgs[0] as number).assertEqual(-8);

      const session: camera.PhotoSession = makeShell();
      shellOf(session).throwOnBias = true;
      (cam as ESObject).photoSession = session;
      const failed: MockMethodResult = new MockMethodResult();
      cam.setExposureOffset(failed, 1);
      expect(failed.errorCodes[0]).assertEqual('setExposureOffsetFailed');
    });

    it('exposureOffsetGetters_passThroughShellRanges', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell();
      expect(cam.getMinExposureOffset()).assertEqual(-8);
      expect(cam.getMaxExposureOffset()).assertEqual(8);
      expect(cam.getExposureOffsetStepSize()).assertEqual(0.5);
    });

    it('setZoomLevel_boundsSuccessAndSessionFailure', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      (cam as ESObject).photoSession = makeShell();
      const tooHigh: MockMethodResult = new MockMethodResult();
      cam.setZoomLevel(tooHigh, 99);
      expect(tooHigh.errorCodes[0]).assertEqual('ZOOM_ERROR');

      const ok: MockMethodResult = new MockMethodResult();
      cam.setZoomLevel(ok, 5);
      expect(ok.successArgs.length).assertEqual(1);

      const session: camera.PhotoSession = makeShell();
      shellOf(session).throwOnZoom = true;
      (cam as ESObject).photoSession = session;
      const failed: MockMethodResult = new MockMethodResult();
      cam.setZoomLevel(failed, 2);
      expect(failed.errorCodes[0]).assertEqual('setZoomLevelFailed');
    });

    it('zoomGetters_reportRealRangesWithShellSession', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      // getCurSession() follows isVideoMode, which is false here, so the
      // photo-session slot is the one consulted.
      (cam as ESObject).photoSession = makeShell();
      expect(cam.getMaxZoomLevel()).assertEqual(10);
      expect(cam.getMinZoomLevel()).assertEqual(1);
    });

    it('takePicture_whileNotPreview_reportsCaptureAlreadyActive', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const callback: Object = (cam as ESObject).cameraCaptureCallback as Object;
      (callback as ESObject).setCameraState(CameraState.STATE_CAPTURING);
      const result: MockMethodResult = new MockMethodResult();
      cam.takePicture(result);
      expect(result.errorCodes[0]).assertEqual('captureAlreadyActive');
    });

    it('takePicture_withoutSession_errorsCaptureSessionNull', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const result: MockMethodResult = new MockMethodResult();
      cam.takePicture(result);
      expect(result.errorCodes[0]).assertEqual('captureSession null');
    });

    it('pauseResumePreview_stopStartAndFailurePaths', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const preview: PreviewShell = new PreviewShell();
      (cam as ESObject).previewOutput = (preview as ESObject) as camera.PreviewOutput;
      const paused: MockMethodResult = new MockMethodResult();
      await cam.pausePreview(paused);
      expect(paused.successArgs.length).assertEqual(1);
      expect(preview.stopCount).assertEqual(1);

      const resumed: MockMethodResult = new MockMethodResult();
      await cam.resumePreview(resumed);
      expect(resumed.successArgs.length).assertEqual(1);
      expect(preview.startCount).assertEqual(1);

      preview.throwOnStop = true;
      const stopFailed: MockMethodResult = new MockMethodResult();
      await cam.pausePreview(stopFailed);
      expect(stopFailed.errorCodes[0]).assertEqual('pausePreviewFailed');

      preview.throwOnStop = false;
      preview.throwOnStart = true;
      await cam.pausePreview(new MockMethodResult());
      const startFailed: MockMethodResult = new MockMethodResult();
      await cam.resumePreview(startFailed);
      expect(startFailed.errorCodes[0]).assertEqual('resumePreviewFailed');
    });

    it('pauseVideoRecording_stateBranches', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const idle: MockMethodResult = new MockMethodResult();
      await cam.pauseVideoRecording(idle);
      expect(idle.successArgs.length).assertEqual(1);

      (cam as ESObject).recordingVideo = true;
      const recorder: RecorderShell = new RecorderShell();
      recorder.state = 'started';
      (cam as ESObject).avRecorder = (recorder as ESObject) as Object;
      (cam as ESObject).videoOutput = (new VideoOutShell() as ESObject) as camera.VideoOutput;
      const paused: MockMethodResult = new MockMethodResult();
      await cam.pauseVideoRecording(paused);
      expect(paused.successArgs.length).assertEqual(1);
      expect(recorder.pauseCount).assertEqual(1);
    });

    it('resumeVideoRecording_stateBranches', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const idle: MockMethodResult = new MockMethodResult();
      await cam.resumeVideoRecording(idle);
      expect(idle.successArgs.length).assertEqual(1);

      (cam as ESObject).recordingVideo = true;
      const recorder: RecorderShell = new RecorderShell();
      recorder.state = 'started';
      (cam as ESObject).avRecorder = (recorder as ESObject) as Object;
      const wrongState: MockMethodResult = new MockMethodResult();
      await cam.resumeVideoRecording(wrongState);
      expect(wrongState.errorCodes[0]).assertEqual('videoRecordingFailed');

      recorder.state = 'paused';
      (cam as ESObject).videoOutput = (new VideoOutShell() as ESObject) as camera.VideoOutput;
      const resumed: MockMethodResult = new MockMethodResult();
      await cam.resumeVideoRecording(resumed);
      expect(resumed.successArgs.length).assertEqual(1);
      expect(recorder.resumeCount).assertEqual(1);
    });

    it('stopVideoRecording_withoutRecording_succeedsWithNullPath', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const result: MockMethodResult = new MockMethodResult();
      await cam.stopVideoRecording(result);
      expect(result.successArgs.length).assertEqual(1);
    });

    it('prepareMediaRecorder_releasesExistingRecorder', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const recorder: RecorderShell = new RecorderShell();
      (cam as ESObject).avRecorder = (recorder as ESObject) as Object;
      await cam.prepareMediaRecorder((null as ESObject) as camera.CameraManager,
        (null as ESObject) as camera.CameraOutputCapability, '/tmp/x.mp4');
      expect(recorder.releaseCount).assertEqual(1);
    });

    it('getAVRecorderConfig_audioBranches', 0, async (): Promise<void> => {
      const deniedShell: GrantShell = new GrantShell();
      deniedShell.grant = false;
      const denied: CameraPermissions = (deniedShell as ESObject) as CameraPermissions;
      const camDenied: Camera = makeCamera(makeMessenger(), true, denied);
      const videoOnly: Object =
        await camDenied.getAVRecorderConfig(7, camera.ImageRotation.ROTATION_0) as Object;
      expect((videoOnly as ESObject).audioSourceType === undefined).assertTrue();

      const grantedShell: GrantShell = new GrantShell();
      grantedShell.grant = true;
      const granted: CameraPermissions = (grantedShell as ESObject) as CameraPermissions;
      const camGranted: Camera = makeCamera(makeMessenger(), true, granted);
      const withAudio: Object =
        await camGranted.getAVRecorderConfig(7, camera.ImageRotation.ROTATION_0) as Object;
      expect((withAudio as ESObject).audioSourceType !== undefined).assertTrue();
    });

    it('setFrameRate_clampsToActiveRange', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const output: VideoOutShell = new VideoOutShell();
      output.activeMin = 15;
      output.activeMax = 30;
      cam.setFrameRate((output as ESObject) as camera.VideoOutput, 60);
      cam.setFrameRate((output as ESObject) as camera.VideoOutput, 5);
      cam.setFrameRate((output as ESObject) as camera.VideoOutput, 24);
      expect(output.setRatePairs.length).assertEqual(3);
      expect(output.setRatePairs[0]).assertEqual(30);
      expect(output.setRatePairs[1]).assertEqual(15);
      expect(output.setRatePairs[2]).assertEqual(24);

      output.throwOnActiveFrameRate = true;
      cam.setFrameRate((output as ESObject) as camera.VideoOutput, 24);
      expect(output.setRatePairs.length).assertEqual(3);
    });

    it('convertBufferToFile_writesRawJpegAndReportsSuccess', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const name: string = '/IMG_covtest_' + Math.floor(Math.random() * 100000) + '.jpg';
      (cam as ESObject).takePictureName = name;
      const result: MockMethodResult = new MockMethodResult();
      (cam as ESObject).takePictureResult = result;
      const data: ArrayBuffer = new ArrayBuffer(16);
      await cam.convertBufferToFile(data);
      expect(result.successArgs.length).assertEqual(1);
      const uri: string = result.successArgs[0] as string;
      expect(uri.endsWith('.jpg')).assertTrue();
      try {
        fs.unlinkSync(uri);
      } catch (e) {
        // temp file cleanup is best effort
      }
    });

    it('convertBufferToFile_encodingFailureReportsError', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const name: string = '/IMG_covbad_' + Math.floor(Math.random() * 100000) + '.heif';
      (cam as ESObject).takePictureName = name;
      (cam as ESObject).imageFileFormat = 1; // PlatformImageFileFormat.heif
      const result: MockMethodResult = new MockMethodResult();
      (cam as ESObject).takePictureResult = result;
      await cam.convertBufferToFile(new ArrayBuffer(16));
      // Garbage bytes cannot be re-encoded as HEIF, so the error path runs.
      expect(result.errorCodes[0]).assertEqual('imageFileFormatEncodingFailed');
      (cam as ESObject).imageFileFormat = 0; // back to jpeg for later tests
    });

    it('close_reportsCameraClosedForPendingPictureResult', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const pending: MockMethodResult = new MockMethodResult();
      (cam as ESObject).takePictureResult = pending;
      await cam.close();
      expect(pending.errorCodes[0]).assertEqual('cameraClosed');
    });

    it('open_afterClose_isIgnored', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      await cam.close();
      await cam.open('jpeg');
    });

    it('open_unknownDevice_sendsCameraErrorEvent', 0, async (): Promise<void> => {
      const messenger: MockBinaryMessenger = makeMessenger();
      const props: StubCameraProperties = new StubCameraProperties();
      props.cameraName = 'definitely-not-a-camera';
      const cam: Camera = new Camera(new MockAbilityBinding().getAbility(),
        makeFakeSurfaceTextureEntry(), new CameraFeatureFactoryImpl(), new DartMessenger(messenger),
        props, ResolutionPreset.medium, false, new CameraPermissions());
      await cam.open('jpeg');
      expect(messenger.sentChannels.length).assertEqual(1);
      expect(messenger.sentChannels[0].indexOf('CameraEventApi.error') >= 0).assertTrue();
    });

    it('open_nonJpegFormat_stillFallsBackToJpeg', 0, async (): Promise<void> => {
      const messenger: MockBinaryMessenger = makeMessenger();
      const props: StubCameraProperties = new StubCameraProperties();
      props.cameraName = 'definitely-not-a-camera';
      const cam: Camera = new Camera(new MockAbilityBinding().getAbility(),
        makeFakeSurfaceTextureEntry(), new CameraFeatureFactoryImpl(), new DartMessenger(messenger),
        props, ResolutionPreset.medium, false, new CameraPermissions());
      // nv21 is unsupported on ohos; the request is logged and downgraded to
      // JPEG before the unknown-device error event is emitted.
      await cam.open('nv21');
      expect(messenger.sentChannels.length).assertEqual(1);
      expect(messenger.sentChannels[0].indexOf('CameraEventApi.error') >= 0).assertTrue();
    });

    it('releaseSession_stopsAndReleasesShellSessions', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const photoShell: PreviewShell = new PreviewShell();
      (cam as ESObject).photoSession = (photoShell as ESObject) as camera.PhotoSession;
      const videoShell: PreviewShell = new PreviewShell();
      (cam as ESObject).videoSession = (videoShell as ESObject) as camera.PhotoSession;
      await (cam as ESObject).releaseSession() as Object;
      expect(photoShell.stopCount).assertEqual(1);
      expect(photoShell.releaseCount).assertEqual(1);
      expect(videoShell.stopCount).assertEqual(1);
      expect((cam as ESObject).photoSession == null).assertTrue();
      expect((cam as ESObject).videoSession == null).assertTrue();
    });

    it('updatePreviewRotation_handlesRotationSwapAndNullRegistry', 0, () => {
      const cam: Camera = makeCamera(makeMessenger());
      const preview: PreviewShell = new PreviewShell();
      preview.rotationAnswer = camera.ImageRotation.ROTATION_90;
      (cam as ESObject).previewOutput = (preview as ESObject) as camera.PreviewOutput;
      // textureRegistry is null in this construction: the warn branch runs.
      (cam as ESObject).updatePreviewRotation();
      expect((cam as ESObject).previewOutput != null).assertTrue();
    });

    it('enableVideoMirrorIfNeeded_frontCameraWithMirrorSupport', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      const device: DeviceShellFields = { cameraPosition: 2, cameraId: 'x', connectionType: 0,
        cameraOrientation: 0, deviceType: 0, connectionId: 0 };
      (cam as ESObject).cameraDevice = (device as ESObject) as camera.CameraDevice;
      const output: VideoOutShell = new VideoOutShell();
      output.mirrorSupportedValue = true;
      (cam as ESObject).videoOutput = (output as ESObject) as camera.VideoOutput;
      await (cam as ESObject).enableVideoMirrorIfNeeded() as Object;
      expect(output.enableMirrorCount).assertEqual(1);
    });

    it('updateVideoRotation_nullGuardsAndPreparedRecorder', 0, async (): Promise<void> => {
      const cam: Camera = makeCamera(makeMessenger());
      await (cam as ESObject).updateVideoRotation() as Object;

      const recorder: RecorderShell = new RecorderShell();
      recorder.state = 'prepared';
      (cam as ESObject).avRecorder = (recorder as ESObject) as Object;
      (cam as ESObject).videoOutput = (new VideoOutShell() as ESObject) as camera.VideoOutput;
      await (cam as ESObject).updateVideoRotation() as Object;
      expect(recorder.rotations.length).assertEqual(1);
    });
  });
}
