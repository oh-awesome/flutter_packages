/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
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
import UrlLauncherPlugin from '../../../../index';
import { BinaryMessenger, TaskQueue, BinaryMessageHandler, BinaryReply } from '@ohos/flutter_ohos';

class FakeBinaryMessenger implements BinaryMessenger {
  public registered: Map<string, BinaryMessageHandler | null> = new Map();

  makeBackgroundTaskQueue(options?: TaskQueue): TaskQueue {
    return new EmptyTaskQueue();
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | null,
    taskQueue?: TaskQueue, ...args: Object[]): void {
    this.registered.set(channel.toString(), handler);
  }
}

class EmptyTaskQueue implements TaskQueue {
}

/** Fake Ability context (UrlLauncher only holds the reference and reads filesDir) */
class FakeAbilityContext {
  filesDir: string = '/data/app/files';
}

class FakeAbility {
  context: FakeAbilityContext = new FakeAbilityContext();
}

/** Simulates a FlutterPluginBinding: the plugin only calls getBinaryMessenger(); passed in via as ESObject */
class FakeEngineBinding {
  private messenger: FakeBinaryMessenger;

  constructor(messenger: FakeBinaryMessenger) {
    this.messenger = messenger;
  }

  getBinaryMessenger(): FakeBinaryMessenger {
    return this.messenger;
  }
}

/** Simulates an AbilityPluginBinding: the plugin only calls getAbility().context */
class FakeAbilityBinding {
  private ability: FakeAbility;

  constructor(ability: FakeAbility) {
    this.ability = ability;
  }

  getAbility(): FakeAbility {
    return this.ability;
  }
}

const CH_CAN_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl';
const CH_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.launchUrl';
const CH_OPEN_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView';
const CH_CLOSE_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.closeWebView';

/**
 * Counts the channels with an active (non-null) handler.
 * Deregistration is setMessageHandler(ch, null): the Map key is kept with a null value,
 * so size cannot be used directly.
 */
function activeChannelCount(m: FakeBinaryMessenger): number {
  let n = 0;
  let v1 = m.registered.get(CH_CAN_LAUNCH);
  let v2 = m.registered.get(CH_LAUNCH);
  let v3 = m.registered.get(CH_OPEN_WEBVIEW);
  let v4 = m.registered.get(CH_CLOSE_WEBVIEW);
  if (v1 !== null && v1 !== undefined) {
    n++;
  }
  if (v2 !== null && v2 !== undefined) {
    n++;
  }
  if (v3 !== null && v3 !== undefined) {
    n++;
  }
  if (v4 !== null && v4 !== undefined) {
    n++;
  }
  return n;
}

/**
 * UrlLauncherPlugin.ets unit tests (full lifecycle paths, fake bindings injected)
 *
 * Source semantics:
 * - onAttachedToEngine: only stores the binding; registration happens only if urlLauncherApi
 *   already exists (Ability attached first)
 * - onAttachedToAbility: creates the api and calls setup (if the engine has not arrived,
 *   messenger is null → setup is a no-op)
 * - onDetachedFromAbility / onDetachedFromEngine: setup(messenger, null) deregisters the 4 channels
 */
export default function urlLauncherPluginTest() {
  describe('UrlLauncherPluginTest', () => {
    let plugin: UrlLauncherPlugin = new UrlLauncherPlugin();
    let messenger: FakeBinaryMessenger = new FakeBinaryMessenger();
    let engineBinding: FakeEngineBinding = new FakeEngineBinding(messenger);
    let abilityBinding: FakeAbilityBinding = new FakeAbilityBinding(new FakeAbility());

    beforeAll(() => {
      plugin = new UrlLauncherPlugin();
      messenger = new FakeBinaryMessenger();
      engineBinding = new FakeEngineBinding(messenger);
      abilityBinding = new FakeAbilityBinding(new FakeAbility());
    });
    beforeEach(() => {
      messenger.registered.clear();
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    // ---------- Identity ----------
    it('getUniqueClassName_returns_class_name', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('UrlLauncherPlugin');
    });

    // ---------- Lifecycle: engine first, ability later ----------
    it('attachEngine_then_attachAbility_registers_channels', 0, () => {
      // Engine arrives alone: api is null, no channels registered
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Ability arrives: creates the api and calls setup → 4 channels active
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      // Teardown
      plugin.onDetachedFromAbility();
      expect(activeChannelCount(messenger)).assertEqual(0);
      plugin.onDetachedFromEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
    });

    it('detachAbility_deregisters_channels', 0, () => {
      plugin.onAttachedToEngine(engineBinding as ESObject);
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      plugin.onDetachedFromAbility();
      expect(activeChannelCount(messenger)).assertEqual(0);
      plugin.onDetachedFromEngine(engineBinding as ESObject);
    });

    // ---------- Lifecycle: ability first, engine later (deferred setup) ----------
    it('attachAbility_before_engine_defers_setup', 0, () => {
      // Ability arrives first: pluginBinding is null → setup(null, api) is a no-op
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Engine arrives: the api already exists → the 4 channels are registered retroactively
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      plugin.onDetachedFromAbility();
      plugin.onDetachedFromEngine(engineBinding as ESObject);
    });

    it('reattachEngine_after_detach_needs_ability_to_reregister', 0, () => {
      plugin.onAttachedToEngine(engineBinding as ESObject);
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      // Detach the engine: deregisters and nulls api/binding
      plugin.onDetachedFromEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Re-attach the engine: api is null, nothing registered
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Only after re-attaching the Ability are the 4 channels restored
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      plugin.onDetachedFromAbility();
      plugin.onDetachedFromEngine(engineBinding as ESObject);
    });

    it('detachEngine_after_ability_deregisters_channels', 0, () => {
      plugin.onAttachedToEngine(engineBinding as ESObject);
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      plugin.onDetachedFromEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
    });

    // ---------- No-attach empty-state safety ----------
    it('onDetachedFromAbility_without_attach_is_noop', 0, () => {
      plugin.onDetachedFromAbility();
      expect(activeChannelCount(messenger)).assertEqual(0);
    });

    it('detach_engine_without_attach_is_noop', 0, () => {
      plugin.onDetachedFromEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
    });
  });
}
