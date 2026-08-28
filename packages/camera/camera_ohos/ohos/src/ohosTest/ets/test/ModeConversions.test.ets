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

// Dart string <-> Camera Kit enum conversion tables.

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { FlashMode } from
  '../../../main/ets/io/flutter/plugins/camera/features/flash/FlashMode';
import { ExposureMode } from
  '../../../main/ets/io/flutter/plugins/camera/features/exposurelock/ExposureMode';

export default function modeConversionsTest() {
  describe('ModeConversionsTest', () => {
    it('flashMode_getValueForStringMapsAllFourModes', 0, () => {
      expect(FlashMode.getValueForString('off')).assertEqual(camera.FlashMode.FLASH_MODE_CLOSE);
      expect(FlashMode.getValueForString('auto')).assertEqual(camera.FlashMode.FLASH_MODE_AUTO);
      expect(FlashMode.getValueForString('always')).assertEqual(camera.FlashMode.FLASH_MODE_OPEN);
      expect(FlashMode.getValueForString('torch'))
        .assertEqual(camera.FlashMode.FLASH_MODE_ALWAYS_OPEN);
    });

    it('flashMode_getValueForStringReturnsNullForUnknown', 0, () => {
      expect(FlashMode.getValueForString('bogus') == null).assertTrue();
      expect(FlashMode.getValueForString('') == null).assertTrue();
      expect(FlashMode.getValueForString('OFF') == null).assertTrue();
    });

    it('flashMode_getValueForModeMapsAllFourModes', 0, () => {
      expect(FlashMode.getValueForMode(camera.FlashMode.FLASH_MODE_CLOSE)).assertEqual('off');
      expect(FlashMode.getValueForMode(camera.FlashMode.FLASH_MODE_AUTO)).assertEqual('auto');
      expect(FlashMode.getValueForMode(camera.FlashMode.FLASH_MODE_OPEN)).assertEqual('always');
      expect(FlashMode.getValueForMode(camera.FlashMode.FLASH_MODE_ALWAYS_OPEN))
        .assertEqual('torch');
    });

    it('flashMode_conversionsRoundTrip', 0, () => {
      expect(
        FlashMode.getValueForMode(FlashMode.getValueForString('always') as camera.FlashMode))
        .assertEqual('always');
      expect(
        FlashMode.getValueForMode(FlashMode.getValueForString('torch') as camera.FlashMode))
        .assertEqual('torch');
    });

    it('exposureMode_getValueForStringMapsBothModes', 0, () => {
      expect(ExposureMode.getValueForString('auto'))
        .assertEqual(camera.ExposureMode.EXPOSURE_MODE_AUTO);
      expect(ExposureMode.getValueForString('locked'))
        .assertEqual(camera.ExposureMode.EXPOSURE_MODE_LOCKED);
    });

    it('exposureMode_getValueForStringReturnsNullForUnknown', 0, () => {
      expect(ExposureMode.getValueForString('bogus') == null).assertTrue();
      expect(ExposureMode.getValueForString('unlocked') == null).assertTrue();
      expect(ExposureMode.getValueForString('') == null).assertTrue();
    });

    it('exposureMode_getValueForModeMapsBothModes', 0, () => {
      expect(ExposureMode.getValueForMode(camera.ExposureMode.EXPOSURE_MODE_AUTO))
        .assertEqual('auto');
      expect(ExposureMode.getValueForMode(camera.ExposureMode.EXPOSURE_MODE_LOCKED))
        .assertEqual('locked');
    });

    it('exposureMode_conversionsRoundTrip', 0, () => {
      expect(ExposureMode
        .getValueForMode(ExposureMode.getValueForString('locked') as camera.ExposureMode))
        .assertEqual('locked');
    });
  });
}
