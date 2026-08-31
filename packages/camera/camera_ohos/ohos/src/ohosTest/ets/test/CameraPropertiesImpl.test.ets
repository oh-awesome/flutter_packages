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

// CameraPropertiesImpl against a fake camera manager/device.

import { describe, it, expect } from '@ohos/hypium';
import { CameraPropertiesImpl } from
  '../../../main/ets/io/flutter/plugins/camera/CameraPropertiesImpl';
import {
  CAMERA_POSITION_BACK_VALUE,
  makeFakeCameraManager,
  makeFakeDevice,
  makeThrowingCameraManager
} from './TestMocks';

export default function cameraPropertiesImplTest() {
  describe('CameraPropertiesImplTest', () => {
    it('regionCounts_areConstantOneByContract', 0, () => {
      const manager = makeFakeCameraManager(
        [makeFakeDevice('back-cam', CAMERA_POSITION_BACK_VALUE, 90)]);
      const properties: CameraPropertiesImpl =
        new CameraPropertiesImpl('back-cam', manager);
      // Reported as capability ceiling constants so Dart sees the point
      // features as supported; must not change with device queries.
      expect(properties.getControlMaxRegionsAutoExposure()).assertEqual(1);
      expect(properties.getControlMaxRegionsAutoFocus()).assertEqual(1);
    });

    it('getters_transparentlyExposeDeviceFields', 0, () => {
      const manager = makeFakeCameraManager(
        [makeFakeDevice('front-cam', 2, 270)]);
      const properties: CameraPropertiesImpl =
        new CameraPropertiesImpl('front-cam', manager);

      expect(properties.getCameraName()).assertEqual('front-cam');
      expect(properties.getLensFacing()).assertEqual(2);
      expect(properties.getSensorOrientation()).assertEqual(270);
    });

    it('constructor_throwsWhenDeviceIdUnknown', 0, () => {
      const manager = makeFakeCameraManager(
        [makeFakeDevice('back-cam', CAMERA_POSITION_BACK_VALUE, 90)]);
      let thrown: boolean = false;
      let message: string = '';
      try {
        new CameraPropertiesImpl('missing-id', manager);
      } catch (e) {
        thrown = true;
        message = (e as Error).message;
      }
      expect(thrown).assertTrue();
      expect(message).assertContain('无法获取相机设备');
      expect(message).assertContain('missing-id');
    });

    it('constructor_propagatesManagerFailureAsThrow', 0, () => {
      // getSupportedCameras() throwing is swallowed by the device map builder,
      // which yields an empty map; the outer null check then throws.
      let thrown: boolean = false;
      try {
        new CameraPropertiesImpl('any', makeThrowingCameraManager());
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });
  });
}
