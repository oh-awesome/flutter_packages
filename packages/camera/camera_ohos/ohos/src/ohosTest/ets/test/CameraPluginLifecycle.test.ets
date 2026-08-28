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

// CameraPlugin lifecycle: attach order, pigeon channel registration and the
// idempotent teardown paths. Uses fakes throughout; no camera is ever opened.

import { describe, it, expect } from '@ohos/hypium';
import CameraPlugin from '../../../main/ets/io/flutter/plugins/camera/CameraPlugin';
import {
  MockAbilityBinding,
  MockBinaryMessenger,
  PIGEON_CAMERA_API_PREFIX,
  createMockPluginBinding
} from './TestMocks';

export default function cameraPluginLifecycleTest() {
  describe('CameraPluginLifecycleTest', () => {
    it('attachEngineOnly_registersNoPigeonHandlers', 0, () => {
      const plugin: CameraPlugin = new CameraPlugin();
      expect(plugin.getUniqueClassName()).assertEqual('CameraPlugin');

      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      plugin.onAttachedToEngine(createMockPluginBinding(messenger));
      expect(messenger.countPigeonHandlers()).assertEqual(0);
    });

    it('attachAfterEngineRegistersFullPigeonChannelSet', 0, () => {
      const plugin: CameraPlugin = new CameraPlugin();
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      plugin.onAttachedToEngine(createMockPluginBinding(messenger));

      plugin.onAttachedToAbility(new MockAbilityBinding());
      // The generated setUp call registers one channel per CameraApi method.
      const count: number = messenger.countPigeonHandlers();
      expect(count > 0).assertTrue();
      expect(messenger.hasHandler(
        'dev.flutter.pigeon.camera_ohos.CameraApi.getAvailableCameras')).assertTrue();
      expect(messenger.countTotalHandlers()).assertEqual(count);
    });

    it('abilityDetachClearsAllPigeonHandlersAndIsIdempotent', 0, async (): Promise<void> => {
      const plugin: CameraPlugin = new CameraPlugin();
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      plugin.onAttachedToEngine(createMockPluginBinding(messenger));
      plugin.onAttachedToAbility(new MockAbilityBinding());
      expect(messenger.countPigeonHandlers() > 0).assertTrue();

      await plugin.onDetachedFromAbility();
      expect(messenger.countPigeonHandlers()).assertEqual(0);

      // A second detach must stay quiet (setUp(null) is idempotent).
      let secondThrow: boolean = false;
      try {
        await plugin.onDetachedFromAbility();
      } catch (e) {
        secondThrow = true;
      }
      expect(secondThrow).assertFalse();
      expect(messenger.countPigeonHandlers()).assertEqual(0);
    });

    it('reattachAfterDetachRestoresChannels', 0, async (): Promise<void> => {
      const plugin: CameraPlugin = new CameraPlugin();
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const binding = createMockPluginBinding(messenger);
      const abilityBinding: MockAbilityBinding = new MockAbilityBinding();

      plugin.onAttachedToEngine(binding);
      plugin.onAttachedToAbility(abilityBinding);
      await plugin.onDetachedFromAbility();
      expect(messenger.countPigeonHandlers()).assertEqual(0);

      plugin.onAttachedToAbility(abilityBinding);
      expect(messenger.countPigeonHandlers() > 0).assertTrue();
    });

    it('engineDetachWithoutAbilityTakesDefensivePath', 0, () => {
      const plugin: CameraPlugin = new CameraPlugin();
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const binding = createMockPluginBinding(messenger);

      plugin.onAttachedToEngine(binding);
      let threw: boolean = false;
      try {
        plugin.onDetachedFromEngine(binding);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('engineDetachAfterAbilityDetachDoesNotReregister', 0, async (): Promise<void> => {
      const plugin: CameraPlugin = new CameraPlugin();
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const binding = createMockPluginBinding(messenger);

      plugin.onAttachedToEngine(binding);
      plugin.onAttachedToAbility(new MockAbilityBinding());
      await plugin.onDetachedFromAbility();
      expect(messenger.countPigeonHandlers()).assertEqual(0);

      plugin.onDetachedFromEngine(binding);
      expect(messenger.countPigeonHandlers()).assertEqual(0);
    });
  });
}
