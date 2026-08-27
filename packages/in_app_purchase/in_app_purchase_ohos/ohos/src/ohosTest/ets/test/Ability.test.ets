/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import {
  FlutterPluginBinding, FlutterEngine, FlutterAssets, TextureRegistry,
  AbilityPluginBinding, NewWantListener, WindowFocusChangedListener, OnSaveStateListener,
  BinaryMessenger, BinaryReply, TaskQueue, TaskQueueOptions,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import UIAbility from '@ohos.app.ability.UIAbility';
import { InAppPurchasePlugin } from '../../../main/ets/components/InAppPurchasePlugin';

/**
 * A BinaryMessenger stub used to satisfy the plugin's channel setup without a
 * running Flutter engine. It never actually delivers messages.
 */
class MockMessenger implements BinaryMessenger {
  sendCount: number = 0;

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    return {} as TaskQueue;
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
    this.sendCount += 1;
  }

  setMessageHandler(channel: String, handler: Object | null, taskQueue?: TaskQueue, ...args: Object[]): void {
  }
}

/**
 * An AbilityPluginBinding stub that exposes the ability the plugin needs for
 * onAttachedToAbility. The listener registration methods are not used by the
 * plugin and are therefore no-ops.
 */
class MockAbilityPluginBinding implements AbilityPluginBinding {
  private ability: UIAbility;

  constructor(ability: UIAbility) {
    this.ability = ability;
  }

  getAbility(): UIAbility {
    return this.ability;
  }

  addOnNewWantListener(listener: NewWantListener): void {
  }

  removeOnNewWantListener(listener: NewWantListener): void {
  }

  addOnWindowFocusChangedListener(listener: WindowFocusChangedListener): void {
  }

  removeOnWindowFocusChangedListener(listener: WindowFocusChangedListener): void {
  }

  addOnSaveStateListener(listener: OnSaveStateListener): void {
  }

  removeOnSaveStateListener(listener: OnSaveStateListener): void {
  }
}

/**
 * ArkTS rejects `null as T`, `null as unknown as T` and even an inline
 * `null as T | null as T` double cast (the compiler narrows the null literal
 * back to `null`). A null returned from a function keeps the declared return
 * type `Object | null`, which is not narrowed, so it can be narrowed to any
 * class/interface type. The engine-owning binding members below are never
 * dereferenced by InAppPurchasePlugin, so a null value is safe at runtime.
 */
function nullContext(): common.Context {
  return nullable() as common.Context;
}

function nullFlutterEngine(): FlutterEngine {
  return nullable() as FlutterEngine;
}

function nullFlutterAssets(): FlutterAssets {
  return nullable() as FlutterAssets;
}

function nullTextureRegistry(): TextureRegistry {
  return nullable() as TextureRegistry;
}

/**
 * Returns a null value whose static type is `Object | null`. A null literal that
 * is assigned to a variable or cast inline is narrowed back to `null` by ArkTS,
 * which then rejects `null -> T`. Returning null from a function keeps the
 * declared return type, so callers can narrow it to any class/interface type.
 */
function nullable(): Object | null {
  return null;
}

/**
 * Builds a FlutterPluginBinding that only exposes the members the plugin uses
 * (getBinaryMessenger / getApplicationContext). The engine-owning members are
 * null because they are never dereferenced by InAppPurchasePlugin.
 */
function createPluginBinding(): FlutterPluginBinding {
  const messenger: BinaryMessenger = new MockMessenger();
  return new FlutterPluginBinding(
    nullContext(),
    nullFlutterEngine(),
    messenger,
    nullFlutterAssets(),
    nullTextureRegistry(),
  );
}

export default function abilityTest() {
  describe('AbilityTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
    })

    it('plugin_uniqueClassName_shouldReturnPluginName', 0, () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      expect(plugin.getUniqueClassName()).assertEqual('InAppPurchasePlugin');
    })

    it('plugin_setUpAndTeardownMethodChannel_shouldNotThrow', 0, () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      const messenger: BinaryMessenger = new MockMessenger();
      plugin.setUpMethodChannel(messenger, nullContext());
      plugin.teardownMethodChannel();
      expect(true).assertTrue();
    })

    it('plugin_attachAndDetachFromEngine_shouldNotThrow', 0, () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      const binding: FlutterPluginBinding = createPluginBinding();
      plugin.onAttachedToEngine(binding);
      plugin.onDetachedFromEngine(binding);
      expect(true).assertTrue();
    })

    it('plugin_attachAndDetachFromAbility_shouldNotThrow', 0, async () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      let ability: UIAbility | null = null;
      // Only the ability acquisition is guarded: when there is no top ability in
      // this environment, the test is skipped. Any exception thrown later by
      // onAttachedToAbility (e.g. a broken binding or a null context) now fails
      // the test instead of being silently swallowed by a wide catch.
      try {
        ability = await AbilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      } catch (e) {
        plugin.onDetachedFromAbility();
        expect(true).assertTrue();
        return;
      }
      if (ability == null) {
        plugin.onDetachedFromAbility();
        expect(true).assertTrue();
        return;
      }
      const binding: AbilityPluginBinding = new MockAbilityPluginBinding(ability);
      plugin.onAttachedToAbility(binding);
      plugin.onDetachedFromAbility();
      expect(true).assertTrue();
    })

    it('plugin_teardownWithoutSetup_shouldNotThrow', 0, () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      // Teardown before any engine attach must be a safe no-op.
      plugin.teardownMethodChannel();
      expect(true).assertTrue();
    })

    it('plugin_detachFromAbilityWithoutAttach_shouldNotThrow', 0, () => {
      const plugin: InAppPurchasePlugin = new InAppPurchasePlugin();
      // Detach before any ability attach must be a safe no-op.
      plugin.onDetachedFromAbility();
      expect(true).assertTrue();
    })
  })
}
