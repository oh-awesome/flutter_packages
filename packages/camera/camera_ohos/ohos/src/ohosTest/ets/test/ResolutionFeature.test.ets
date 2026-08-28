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

// ResolutionFeature: preset size table, best-profile selection and the video
// session profile pairing algorithm.

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { ResolutionFeature, VideoSessionProfile } from
  '../../../main/ets/io/flutter/plugins/camera/features/resolution/ResolutionFeature';
import { ResolutionPreset } from
  '../../../main/ets/io/flutter/plugins/camera/features/resolution/ResolutionPreset';
import { CameraProperties } from '../../../main/ets/io/flutter/plugins/camera/CameraProperties';
import { StubCameraProperties, makeProfile, makeVideoProfile } from './TestMocks';

function makeFeature(preset: ResolutionPreset): ResolutionFeature {
  return new ResolutionFeature(new StubCameraProperties(), preset, 'back-cam');
}

export default function resolutionFeatureTest() {
  describe('ResolutionFeatureTest', () => {
    it('getDebugName_returnsClassName', 0, () => {
      expect(makeFeature(ResolutionPreset.high).getDebugName()).assertEqual('ResolutionFeature');
    });

    it('value_roundTripsPreset', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      expect(feature.getValue()).assertEqual(ResolutionPreset.high);
      feature.setValue(ResolutionPreset.max);
      expect(feature.getValue()).assertEqual(ResolutionPreset.max);
    });

    it('supportedWhenCameraIdPresentOnly', 0, () => {
      expect(makeFeature(ResolutionPreset.high).checkIsSupported()).assertTrue();

      // The feature is unusable when no camera id was handed down.
      const props: CameraProperties = new StubCameraProperties();
      const noName: string = (null as ESObject) as string;
      const detached: ResolutionFeature =
        new ResolutionFeature(props, ResolutionPreset.high, noName);
      expect(detached.checkIsSupported()).assertFalse();
    });

    it('presetSizeTable_matchesUpstreamDimensions', 0, () => {
      const table: ReadonlyMap<ResolutionPreset, camera.Size> =
        ResolutionFeature.PRESET_SIZE_MAP;

      const low: camera.Size | undefined = table.get(ResolutionPreset.low);
      expect(low != undefined).assertTrue();
      expect((low as camera.Size).width).assertEqual(320);
      expect((low as camera.Size).height).assertEqual(240);

      const medium: camera.Size | undefined = table.get(ResolutionPreset.medium);
      expect(medium != undefined).assertTrue();
      expect((medium as camera.Size).width).assertEqual(720);
      expect((medium as camera.Size).height).assertEqual(480);

      const high: camera.Size | undefined = table.get(ResolutionPreset.high);
      expect(high != undefined).assertTrue();
      expect((high as camera.Size).width).assertEqual(1280);
      expect((high as camera.Size).height).assertEqual(720);

      const veryHigh: camera.Size | undefined = table.get(ResolutionPreset.veryHigh);
      expect(veryHigh != undefined).assertTrue();
      expect((veryHigh as camera.Size).width).assertEqual(1920);
      expect((veryHigh as camera.Size).height).assertEqual(1080);

      const ultraHigh: camera.Size | undefined = table.get(ResolutionPreset.ultraHigh);
      expect(ultraHigh != undefined).assertTrue();
      expect((ultraHigh as camera.Size).width).assertEqual(3840);
      expect((ultraHigh as camera.Size).height).assertEqual(2160);

      // max has no fixed size; selection scans the available profiles instead.
      expect(table.get(ResolutionPreset.max) == undefined).assertTrue();
    });

    it('sizes_defaultToFullHdAndSettersCopyFields', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      expect(feature.getPreviewSize().width).assertEqual(1920);
      expect(feature.getPreviewSize().height).assertEqual(1080);
      expect(feature.getCaptureSize().width).assertEqual(1920);

      const preview: camera.Size = { width: 1280, height: 720 };
      feature.setPreviewSize(preview);
      expect(feature.getPreviewSize().width).assertEqual(1280);
      expect(feature.getPreviewSize().height).assertEqual(720);

      const capture: camera.Size = makeProfile(3840, 2160).size;
      feature.setCaptureSize(capture);
      expect(feature.getCaptureSize().width).assertEqual(3840);
      expect(feature.getCaptureSize().height).assertEqual(2160);
    });

    it('bestAvailableProfileIndex_maxPrefersWidestThenTaller', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.max);
      const widest: Array<camera.Profile> =
        [makeProfile(640, 480), makeProfile(1280, 720), makeProfile(1920, 1080)];
      expect(feature.getBestAvailableProfileIndex(widest, ResolutionPreset.max)).assertEqual(2);

      const sameWidth: Array<camera.Profile> = [makeProfile(640, 480), makeProfile(640, 360)];
      expect(
        feature.getBestAvailableProfileIndex(sameWidth, ResolutionPreset.max)).assertEqual(0);
    });

    it('bestAvailableProfileIndex_exactPresetHitWins', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      const profiles: Array<camera.Profile> =
        [makeProfile(320, 240), makeProfile(1280, 720)];
      expect(feature.getBestAvailableProfileIndex(profiles, ResolutionPreset.high)).assertEqual(1);
    });

    it('bestAvailableProfileIndex_nearestSquaredDifferenceFallback', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      // No exact 1280x720 entry; 1600x900 has the smallest squared distance.
      const profiles: Array<camera.Profile> =
        [makeProfile(640, 480), makeProfile(1600, 900), makeProfile(3840, 2160)];
      expect(feature.getBestAvailableProfileIndex(profiles, ResolutionPreset.high)).assertEqual(1);
    });

    it('previewProfileIndex_capsUltraAndMaxAtVeryHigh', 0, () => {
      const profiles: Array<camera.Profile> =
        [makeProfile(1280, 720), makeProfile(1920, 1080)];

      expect(makeFeature(ResolutionPreset.ultraHigh).getPreviewProfileIndex(profiles))
        .assertEqual(1);
      expect(makeFeature(ResolutionPreset.max).getPreviewProfileIndex(profiles)).assertEqual(1);
      // Settings at or below veryHigh use their own preset size.
      expect(makeFeature(ResolutionPreset.high).getPreviewProfileIndex(profiles)).assertEqual(0);
    });

    it('photoProfileIndex_usesCurrentSetting', 0, () => {
      // medium (720x480) has no exact entry; 1280x720 is squared-closest.
      const profiles: Array<camera.Profile> = [makeProfile(1280, 720), makeProfile(1920, 1080)];
      expect(makeFeature(ResolutionPreset.medium).getPhotoProfileIndex(profiles)).assertEqual(0);
      // ultraHigh picks the 1920x1080 entry because preview caps at veryHigh only
      // in getPreviewProfileIndex; photo keeps searching with ultraHigh (no hit) and
      // also lands on the closest one.
      expect(makeFeature(ResolutionPreset.ultraHigh).getPhotoProfileIndex(profiles))
        .assertEqual(1);
    });

    it('videoSessionProfile_highPresetPairsExactVideoWithWidestSameRatioPreview', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      const previews: Array<camera.Profile> = [makeProfile(1920, 1080), makeProfile(640, 480)];
      const videos: Array<camera.VideoProfile> = [
        makeVideoProfile(1920, 1080),
        makeVideoProfile(1280, 720)
      ];
      const result: VideoSessionProfile =
        feature.getVideoSessionProfile(previews, videos, null);
      const capture: camera.VideoProfile = result.getCaptureProfile() as camera.VideoProfile;
      expect(capture.size.width).assertEqual(1280);
      expect(capture.size.height).assertEqual(720);
      const preview: camera.Profile = result.getPreviewProfile() as camera.Profile;
      expect(preview.size.width).assertEqual(1920);
      expect(preview.size.height).assertEqual(1080);
    });

    it('videoSessionProfile_nearestDifferenceChosenWithoutExactHit', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.medium);
      const previews: Array<camera.Profile> = [makeProfile(640, 480)];
      // Both are 4:3 like the only preview; 960x720 is squared-closest to 720x480.
      const videos: Array<camera.VideoProfile> = [
        makeVideoProfile(1280, 720, 30, 30),
        makeVideoProfile(960, 720, 30, 30)
      ];
      // 1280x720 is 16:9 and gets skipped for ratio mismatch; 960x720 wins.
      const capture: camera.VideoProfile =
        feature.getVideoSessionProfile(previews, videos, null)
          .getCaptureProfile() as camera.VideoProfile;
      expect(capture.size.width).assertEqual(960);
      expect(capture.size.height).assertEqual(720);
    });

    it('videoSessionProfile_maxSettingMatchesByAspectRatioDescendingArea', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.max);
      const previews: Array<camera.Profile> = [makeProfile(640, 480), makeProfile(1920, 1080)];
      const videos: Array<camera.VideoProfile> = [
        makeVideoProfile(640, 480),
        makeVideoProfile(1920, 1080)
      ];
      const result: VideoSessionProfile = feature.getVideoSessionProfile(previews, videos, null);
      expect((result.getCaptureProfile() as camera.VideoProfile).size.width).assertEqual(1920);
      expect((result.getPreviewProfile() as camera.Profile).size.width).assertEqual(1920);
    });

    it('videoSessionProfile_targetFpsReordersCandidates', 0, () => {
      // Neither profile supports 30fps exactly; distance ordering must put 640x480
      // (distance 20) ahead of 1280x720 (distance 30).
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.low);
      const previews: Array<camera.Profile> = [makeProfile(320, 240), makeProfile(320, 180)];
      const videos: Array<camera.VideoProfile> = [
        makeVideoProfile(1280, 720, 60, 120),
        makeVideoProfile(640, 480, 5, 10)
      ];
      const result: VideoSessionProfile =
        feature.getVideoSessionProfile(previews, videos, 30);
      const capture: camera.VideoProfile = result.getCaptureProfile() as camera.VideoProfile;
      expect(capture.size.width).assertEqual(640);
      const preview: camera.Profile = result.getPreviewProfile() as camera.Profile;
      expect(preview.size.width).assertEqual(320);
      expect(preview.size.height).assertEqual(240);
    });

    it('videoSessionProfile_targetFpsExactRangeBeatsLaterEntries', 0, () => {
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      const previews: Array<camera.Profile> = [makeProfile(1280, 720)];
      const videos: Array<camera.VideoProfile> = [
        makeVideoProfile(1920, 1080, 10, 60),
        makeVideoProfile(1280, 720, 30, 30)
      ];
      const capture: camera.VideoProfile =
        feature.getVideoSessionProfile(previews, videos, 30)
          .getCaptureProfile() as camera.VideoProfile;
      expect(capture.size.width).assertEqual(1280);
    });

    it('videoSessionProfile_maxSettingFallsBackWithoutRatioMatchDoesNotCrash', 0, () => {
      // On the max path an aspect-ratio mismatch falls through to the default
      // pairing without touching the undefined best video profile.
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.max);
      const previews: Array<camera.Profile> = [makeProfile(640, 480)];
      const videos: Array<camera.VideoProfile> = [makeVideoProfile(320, 240)];
      let threw: boolean = false;
      try {
        feature.getVideoSessionProfile(previews, videos, null);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('videoSessionProfile_noRatioMatchThrowsBeforeFallback', 0, () => {
      // Known defect lock-in: when no video profile matches a preview aspect
      // ratio below the max preset, the code dereferences the still-undefined
      // best video profile before reaching the intended Full-HD fallback /
      // 'No valid video/preview profile available' guard.
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      const previews: Array<camera.Profile> = [makeProfile(640, 480)];
      const videos: Array<camera.VideoProfile> = [makeVideoProfile(1920, 1080)];
      let thrown: boolean = false;
      let message: string = '';
      try {
        feature.getVideoSessionProfile(previews, videos, null);
      } catch (e) {
        thrown = true;
        message = (e as Error).message;
      }
      expect(thrown).assertTrue();
      expect(message).assertContain('undefined');
    });

    it('videoSessionProfile_emptyInputsThrow', 0, () => {
      // Same crash-first behavior as above; the dedicated guard message is
      // currently unreachable through the non-max path.
      const feature: ResolutionFeature = makeFeature(ResolutionPreset.high);
      let thrown: boolean = false;
      let message: string = '';
      try {
        feature.getVideoSessionProfile([], [], null);
      } catch (e) {
        thrown = true;
        message = (e as Error).message;
      }
      expect(thrown).assertTrue();
      expect(message.length > 0).assertTrue();
    });
  });
}
