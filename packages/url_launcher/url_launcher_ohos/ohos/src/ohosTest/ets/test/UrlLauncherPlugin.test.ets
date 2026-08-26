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

/** fake Ability context（UrlLauncher 仅持有引用并读 filesDir） */
class FakeAbilityContext {
  filesDir: string = '/data/app/files';
}

class FakeAbility {
  context: FakeAbilityContext = new FakeAbilityContext();
}

/** 模拟 FlutterPluginBinding：插件仅调用 getBinaryMessenger()，经 as ESObject 传入 */
class FakeEngineBinding {
  private messenger: FakeBinaryMessenger;

  constructor(messenger: FakeBinaryMessenger) {
    this.messenger = messenger;
  }

  getBinaryMessenger(): FakeBinaryMessenger {
    return this.messenger;
  }
}

/** 模拟 AbilityPluginBinding：插件仅调用 getAbility().context */
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
 * 统计有效（非 null）handler 的通道数。
 * 反注册是 setMessageHandler(ch, null)：Map 键保留、值为 null，故不能直接用 size。
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
 * UrlLauncherPlugin.ets 单元测试（生命周期全路径，fake binding 注入）
 *
 * 源码语义：
 * - onAttachedToEngine：仅保存 binding；若 urlLauncherApi 已存在（Ability 先到）才补注册
 * - onAttachedToAbility：创建 api 并 setup（engine 未到时 messenger 为 null → setup 空操作）
 * - onDetachedFromAbility / onDetachedFromEngine：setup(messenger, null) 反注册 4 通道
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

    // ---------- 标识 ----------
    it('getUniqueClassName_returns_class_name', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('UrlLauncherPlugin');
    });

    // ---------- 生命周期：Engine 先、Ability 后 ----------
    it('attachEngine_then_attachAbility_registers_channels', 0, () => {
      // Engine 单独到达：api 为 null，不注册通道
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Ability 到达：创建 api 并 setup → 4 通道生效
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      // 清理
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

    // ---------- 生命周期：Ability 先、Engine 后（延迟 setup） ----------
    it('attachAbility_before_engine_defers_setup', 0, () => {
      // Ability 先到：pluginBinding 为 null → setup(null, api) 空操作
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // Engine 到达：api 已存在 → 补注册 4 通道
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      plugin.onDetachedFromAbility();
      plugin.onDetachedFromEngine(engineBinding as ESObject);
    });

    it('reattachEngine_after_detach_needs_ability_to_reregister', 0, () => {
      plugin.onAttachedToEngine(engineBinding as ESObject);
      plugin.onAttachedToAbility(abilityBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(4);
      // 解绑 Engine：反注册且 api/binding 置空
      plugin.onDetachedFromEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // 重新附着 Engine：api 为 null，不注册
      plugin.onAttachedToEngine(engineBinding as ESObject);
      expect(activeChannelCount(messenger)).assertEqual(0);
      // 重新附着 Ability 后才恢复 4 通道
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

    // ---------- 未附着时的空态安全 ----------
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
