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

// CameraApiImpl's uninitialized-camera contract: every API method guards on
// `camera == null` before touching hardware, and a freshly constructed
// instance (MockAbilityBinding chain, camera stays null) drives each guard.
// These branches are what Dart relies on for "call before create" errors.

import { describe, it, expect } from '@ohos/hypium';
import { CameraApiImpl } from '../../../main/ets/io/flutter/plugins/camera/CameraApiImpl';
import {
  FlutterError,
  PlatformCameraDescription,
  PlatformDeviceOrientation,
  PlatformExposureMode,
  PlatformFlashMode,
  PlatformFocusMode,
  PlatformImageFileFormat,
  PlatformImageFormatGroup,
  PlatformVideoStabilizationMode
} from '../../../main/ets/io/flutter/plugins/camera/Messages';
import {
  MockAbilityBinding,
  MockBinaryMessenger,
  StubPigeonResult,
  makeFakeTextureRegistry
} from './TestMocks';

function makeApi(): CameraApiImpl {
  const messenger: MockBinaryMessenger = new MockBinaryMessenger();
  return new CameraApiImpl(new MockAbilityBinding().getAbility(), messenger,
    makeFakeTextureRegistry());
}

function syncGuardCode(action: () => void): string {
  try {
    action();
  } catch (e) {
    return (e as FlutterError).code;
  }
  return '(did not throw)';
}

async function rejectGuardCode(pending: Promise<void>): Promise<string> {
  try {
    await pending;
  } catch (e) {
    return (e as FlutterError).code;
  }
  return '(did not reject)';
}

export default function cameraApiImplGuardsTest() {
  describe('CameraApiImplGuardsTest', () => {
    // --- Synchronous getters: guard throws CAMERA_NOT_INITIALIZED ---

    it('getMinExposureOffset_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().getMinExposureOffset();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('getMaxExposureOffset_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().getMaxExposureOffset();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('getExposureOffsetStepSize_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().getExposureOffsetStepSize();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('getMaxZoomLevel_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().getMaxZoomLevel();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('getMinZoomLevel_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().getMinZoomLevel();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('lockCaptureOrientation_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().lockCaptureOrientation(PlatformDeviceOrientation.portraitUp);
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('unlockCaptureOrientation_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().unlockCaptureOrientation();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('startImageStream_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().startImageStream();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('stopImageStream_guardThrows', 0, () => {
      expect(syncGuardCode((): void => {
        makeApi().stopImageStream();
      })).assertEqual('CAMERA_NOT_INITIALIZED');
    });

    // --- Async methods: guard rejects with CAMERA_NOT_INITIALIZED ---

    it('pausePreview_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().pausePreview()))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('resumePreview_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().resumePreview()))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('startVideoRecording_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().startVideoRecording(true)))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('pauseVideoRecording_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().pauseVideoRecording()))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('resumeVideoRecording_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().resumeVideoRecording()))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('setDescriptionWhileRecording_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().setDescriptionWhileRecording('back')))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('setFocusMode_guardRejects', 0, async (): Promise<void> => {
      expect(await rejectGuardCode(makeApi().setFocusMode(PlatformFocusMode.auto)))
        .assertEqual('CAMERA_NOT_INITIALIZED');
    });

    it('initialize_guardThrowsCameraNotFound', 0, async (): Promise<void> => {
      // Distinct code: initialize must tell Dart to create() first, and it
      // must reset the status machine so a later create is not blocked.
      expect(await rejectGuardCode(makeApi().initialize(PlatformImageFormatGroup.jpeg)))
        .assertEqual('cameraNotFound');
    });

    // --- Result-based methods: guard routes to result.error with a dedicated code ---

    it('takePicture_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<string> = new StubPigeonResult<string>();
      makeApi().takePicture(result);
      expect(result.firstErrorCode()).assertEqual('CAMERA_NOT_INITIALIZED');
      expect(result.successCount).assertEqual(0);
    });

    it('stopVideoRecording_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<string> = new StubPigeonResult<string>();
      makeApi().stopVideoRecording(result);
      expect(result.firstErrorCode()).assertEqual('CAMERA_NOT_INITIALIZED');
      expect(result.successCount).assertEqual(0);
    });

    it('setFocusPoint_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setFocusPoint(null, result);
      expect(result.firstErrorCode()).assertEqual('FOCUS_POINT_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('setFlashMode_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setFlashMode(PlatformFlashMode.off, result);
      expect(result.firstErrorCode()).assertEqual('CAMERA_NOT_INITIALIZED');
      expect(result.successCount).assertEqual(0);
    });

    it('setExposureMode_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setExposureMode(PlatformExposureMode.auto, result);
      expect(result.firstErrorCode()).assertEqual('CAMERA_NOT_INITIALIZED');
      expect(result.successCount).assertEqual(0);
    });

    it('setExposurePoint_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setExposurePoint(null, result);
      expect(result.firstErrorCode()).assertEqual('EXPOSURE_POINT_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('setExposureOffset_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<number> = new StubPigeonResult<number>();
      makeApi().setExposureOffset(1.5, result);
      expect(result.firstErrorCode()).assertEqual('CAMERA_NOT_INITIALIZED');
      expect(result.successCount).assertEqual(0);
    });

    it('setZoomLevel_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setZoomLevel(2.5, result);
      expect(result.firstErrorCode()).assertEqual('ZOOM_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('setImageFileFormat_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setImageFileFormat(PlatformImageFileFormat.jpeg, result);
      expect(result.firstErrorCode()).assertEqual('IMAGE_FILE_FORMAT_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('setJpegImageQuality_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setJpegImageQuality(88, result);
      expect(result.firstErrorCode()).assertEqual('JPEG_QUALITY_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('setVideoStabilizationMode_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<void> = new StubPigeonResult<void>();
      makeApi().setVideoStabilizationMode(PlatformVideoStabilizationMode.level1, result);
      expect(result.firstErrorCode()).assertEqual('VIDEO_STABILIZATION_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    it('getSupportedVideoStabilizationModes_guardErrorsResult', 0, () => {
      const result: StubPigeonResult<Array<PlatformVideoStabilizationMode>> =
        new StubPigeonResult<Array<PlatformVideoStabilizationMode>>();
      makeApi().getSupportedVideoStabilizationModes(result);
      expect(result.firstErrorCode()).assertEqual('VIDEO_STABILIZATION_ERROR');
      expect(result.successCount).assertEqual(0);
    });

    // --- Lifecycle paths reachable without a camera ---

    it('prepareForVideoRecording_isNoOpWithoutCamera', 0, () => {
      // ohos has no preparation step; the call must stay a quiet no-op.
      let threw: boolean = false;
      try {
        makeApi().prepareForVideoRecording();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('dispose_completesWithoutCameraAndIsIdempotent', 0, async (): Promise<void> => {
      const api: CameraApiImpl = makeApi();
      let threw: boolean = false;
      try {
        await api.dispose();
        await api.dispose();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('getAvailableCameras_enumeratesDeviceCamerasInTestProcess', 0, () => {
      // Camera Kit device enumeration needs no camera permission, so the real
      // system service answers here and the method returns descriptions instead
      // of throwing; lock that success contract (non-empty list). On a
      // camera-less environment this legitimately fails rather than faking a
      // pass.
      const cameras: Array<PlatformCameraDescription> = makeApi().getAvailableCameras();
      expect(cameras.length >= 1).assertTrue();
    });
  });
}
