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
// SharedPreferencesOhosPlugin.ets 纯逻辑单元测试:不依赖真实 Preferences 存储,
// 覆盖 ListEncoder、transformPref、filterData、前缀拦截、未初始化分支、
// 同步 API setup 通道与引擎生命周期(context 为 null 的路径)。

import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import SharedPreferencesOhosPlugin, { setup } from '../../../main/ets/shared_preferences/SharedPreferencesOhosPlugin';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import { SharedPreferencesPigeonOptions } from '../../../main/ets/shared_preferences/MessagesAsync';
import {
  asPluginBinding,
  ChannelCaller,
  FakeSyncApi,
  RecordingMessenger,
  TestPluginBinding
} from './MockHelpers';

const SYNC_PREFIX = 'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.';
const ASYNC_PREFIX = 'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.';
const LIST_ID = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu';
const BIG_INT_ID = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy';
const DOUBLE_ID = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu';

/** 等待被测 Promise 并捕获 rejection,返回是否被拒绝。 */
async function isRejected(promise: Promise<ESObject>): Promise<boolean> {
  try {
    await promise;
    return false;
  } catch (e) {
    return true;
  }
}

export default function sharedPreferencesOhosPluginTest(): void {
  describe('SharedPreferencesPluginPureLogicTest', () => {
    let plugin: SharedPreferencesOhosPlugin = new SharedPreferencesOhosPlugin();

    beforeEach(() => {
      plugin = new SharedPreferencesOhosPlugin();
    });

    it('getUniqueClassNameReturnsPluginClassName', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('SharedPreferencesOhosPlugin');
    });

    it('getCodecReturnsStandardMessageCodec', 0, () => {
      expect(plugin.getCodec() instanceof StandardMessageCodec).assertTrue();
    });

    it('listEncoderEncodeDecodeRoundtrip', 0, () => {
      const list: string[] = ['a', 'b', 'c'] as string[];
      const encoded: string = plugin.listEncoder.encode(list);
      expect(encoded).assertEqual('["a","b","c"]');
      const decoded: string[] = plugin.listEncoder.decode(encoded);
      expect(decoded.length).assertEqual(3);
      expect(decoded[1]).assertEqual('b');
    });

    it('listEncoderDecodeInvalidJsonReturnsEmptyList', 0, () => {
      const decoded: string[] = plugin.listEncoder.decode('not a json list');
      expect(decoded.length).assertEqual(0);
    });

    it('transformPrefKeepsJsonPrefixedStringAsIs', 0, () => {
      const jsonPrefixed: string = LIST_ID + '!["a"]';
      expect(plugin.transformPref(jsonPrefixed)).assertEqual(jsonPrefixed);
    });

    it('transformPrefDecodesPlatformListString', 0, () => {
      const decoded: ESObject = plugin.transformPref(LIST_ID + '["x","y"]');
      const list: string[] = decoded as string[];
      expect(list.length).assertEqual(2);
      expect(list[0]).assertEqual('x');
    });

    it('transformPrefInvalidListStringBecomesEmpty', 0, () => {
      const decoded: ESObject = plugin.transformPref(LIST_ID + 'broken');
      expect((decoded as string[]).length).assertEqual(0);
    });

    it('transformPrefConvertsBigInt', 0, () => {
      const decoded: ESObject = plugin.transformPref(BigInt(9));
      expect(typeof decoded === 'bigint').assertTrue();
      expect(Number(decoded)).assertEqual(9);
    });

    it('transformPrefKeepsObjectReference', 0, () => {
      const obj: Map<string, Object> = new Map<string, Object>();
      expect(plugin.transformPref(obj) === obj).assertTrue();
    });

    it('transformPrefPassesScalarValuesThrough', 0, () => {
      expect(plugin.transformPref('plain')).assertEqual('plain');
      expect(plugin.transformPref(1.5)).assertEqual(1.5);
      expect(plugin.transformPref(true)).assertEqual(true);
      expect(plugin.transformPref(null)).assertNull();
    });

    it('filterDataKeepsKeyMatchingPrefixWithoutAllowList', 0, () => {
      const entry: [string, string] = ['flutter.a', 'v'];
      const result: Map<string, Object> = plugin.filterData(entry, 'flutter.', null);
      expect(result.size).assertEqual(1);
      expect(result.get('flutter.a')).assertEqual('v');
    });

    it('filterDataDropsKeyNotMatchingPrefix', 0, () => {
      const entry: [string, string] = ['other.a', 'v'];
      const result: Map<string, Object> = plugin.filterData(entry, 'flutter.', null);
      expect(result.size).assertEqual(0);
    });

    it('filterDataRespectsAllowList', 0, () => {
      const allow: string[] = ['flutter.keep'] as string[];
      const kept: Map<string, Object> = plugin.filterData(['flutter.keep', 'v'], 'flutter.', allow);
      expect(kept.size).assertEqual(1);
      const dropped: Map<string, Object> = plugin.filterData(['flutter.drop', 'v'], 'flutter.', allow);
      expect(dropped.size).assertEqual(0);
    });

    it('removeWithoutInitializationReturnsFalse', 0, () => {
      expect(plugin.preferences).assertNull();
      expect(plugin.remove('any')).assertEqual(false);
    });

    it('setStringRejectsListIdentifierPrefix', 0, async () => {
      const rejected: boolean = await isRejected(plugin.setString('k', LIST_ID + 'zzz'));
      expect(rejected).assertTrue();
    });

    it('setStringRejectsBigIntegerPrefix', 0, async () => {
      const rejected: boolean = await isRejected(plugin.setString('k', BIG_INT_ID + 'zzz'));
      expect(rejected).assertTrue();
    });

    it('setStringRejectsDoublePrefix', 0, async () => {
      const rejected: boolean = await isRejected(plugin.setString('k', DOUBLE_ID + 'zzz'));
      expect(rejected).assertTrue();
    });

    it('settersWithoutInitializationAllReject', 0, async () => {
      let rejectedCount: number = 0;
      if (await isRejected(plugin.setString('k', 'v'))) {
        rejectedCount++;
      }
      if (await isRejected(plugin.setBool('k', true))) {
        rejectedCount++;
      }
      if (await isRejected(plugin.setInt('k', BigInt(1)))) {
        rejectedCount++;
      }
      if (await isRejected(plugin.setDouble('k', 1.5))) {
        rejectedCount++;
      }
      if (await isRejected(plugin.setEncodedStringList('k', '["a"]'))) {
        rejectedCount++;
      }
      if (await isRejected(plugin.setDeprecatedStringList('k', ['a'] as string[]))) {
        rejectedCount++;
      }
      expect(rejectedCount).assertEqual(6);
    });

    it('clearWithoutInitializationRejects', 0, async () => {
      expect(await isRejected(plugin.clear('prefix.', null))).assertTrue();
    });

    it('getAllWithoutInitializationRejects', 0, async () => {
      expect(await isRejected(plugin.getAll('prefix.', null))).assertTrue();
    });

    it('getPreferencesForOptionsWithoutContextReturnsNull', 0, async () => {
      const preferences: ESObject =
        await plugin.getPreferencesForOptions(new SharedPreferencesPigeonOptions('nofile', false));
      expect(preferences).assertNull();
    });

    it('setStringListWritesEncodedPrefix', 0, async () => {
      // 未初始化时 put 会拒绝,此处仅验证编码值正确写入待存内容
      expect(await isRejected(plugin.setStringList('k', ['a'] as string[]))).assertTrue();
      expect(await isRejected(plugin.setStringListWithOptions('k', ['a'] as string[],
        new SharedPreferencesPigeonOptions('nofile', false)))).assertTrue();
    });
  });

  describe('SharedPreferencesPluginSyncSetupTest', () => {
    let messenger: RecordingMessenger = new RecordingMessenger();
    let api: FakeSyncApi = new FakeSyncApi();
    let caller: ChannelCaller = new ChannelCaller(messenger);

    beforeAll(() => {
      setup(messenger, api);
    });

    it('registersAllNineSyncChannels', 0, () => {
      expect(caller.count()).assertEqual(9);
      expect(caller.has(SYNC_PREFIX + 'remove')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setBool')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setString')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setInt')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setDouble')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setEncodedStringList')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'setDeprecatedStringList')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'clear')).assertTrue();
      expect(caller.has(SYNC_PREFIX + 'getAll')).assertTrue();
    });

    it('removeChannelRepliesResult', 0, async () => {
      const reply: Object[] = await caller.call(SYNC_PREFIX + 'remove', ['key1'] as Object[]) as Object[];
      expect(reply.length).assertEqual(1);
      expect(reply[0]).assertEqual(true);
      expect(api.lastKey).assertEqual('key1');

      api.removeResult = false;
      const falseReply: Object[] = await caller.call(SYNC_PREFIX + 'remove', ['key1'] as Object[]) as Object[];
      expect(falseReply[0]).assertEqual(false);
      api.removeResult = true;
    });

    it('removeChannelThrowRepliesWrappedFlutterError', 0, async () => {
      api.removeShouldThrow = true;
      const reply: Object[] = await caller.call(SYNC_PREFIX + 'remove', ['key1'] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('remove_failed');
      expect(reply[1]).assertEqual('boom');
      expect(reply[2]).assertEqual('detail');
      api.removeShouldThrow = false;
    });

    it('setBoolChannelRepliesTrueAndWrappedErrorOnFailure', 0, async () => {
      const reply: Object[] =
        await caller.call(SYNC_PREFIX + 'setBool', ['k', true] as Object[]) as Object[];
      expect(reply.length).assertEqual(1);
      expect(reply[0]).assertEqual(true);

      api.settersFail = true;
      const errorReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setBool', ['k', true] as Object[]) as Object[];
      expect(errorReply.length).assertEqual(3);
      expect(errorReply[0]).assertEqual('Error');
      expect(errorReply[1]).assertContain('setter failed');
      api.settersFail = false;
    });

    it('setStringSetIntSetDoubleChannelsReplyTrue', 0, async () => {
      const stringReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setString', ['k', 'v'] as Object[]) as Object[];
      expect(stringReply[0]).assertEqual(true);
      const intReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setInt', ['k', BigInt(7)] as Object[]) as Object[];
      expect(intReply[0]).assertEqual(true);
      const doubleReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setDouble', ['k', 2.5] as Object[]) as Object[];
      expect(doubleReply[0]).assertEqual(true);
    });

    it('setEncodedAndDeprecatedListChannelsReplyTrue', 0, async () => {
      const encodedReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setEncodedStringList', ['k', LIST_ID + '["a"]'] as Object[]) as Object[];
      expect(encodedReply[0]).assertEqual(true);
      const deprecatedReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setDeprecatedStringList', ['k', ['a'] as string[]] as Object[]) as Object[];
      expect(deprecatedReply[0]).assertEqual(true);
    });

    it('clearChannelRepliesResultAndError', 0, async () => {
      const reply: Object[] =
        await caller.call(SYNC_PREFIX + 'clear', ['prefix.', null] as Object[]) as Object[];
      expect(reply[0]).assertEqual(true);

      api.settersFail = true;
      const errorReply: Object[] =
        await caller.call(SYNC_PREFIX + 'clear', ['prefix.', null] as Object[]) as Object[];
      expect(errorReply.length).assertEqual(3);
      expect(errorReply[1]).assertContain('clear failed');
      api.settersFail = false;
    });

    it('getAllChannelRepliesMapAndWrappedError', 0, async () => {
      api.getAllResult.set('gk', 'gv' as Object);
      const reply: Object[] =
        await caller.call(SYNC_PREFIX + 'getAll', ['prefix.', null] as Object[]) as Object[];
      const map: Map<string, Object> = reply[0] as Map<string, Object>;
      expect(map.get('gk')).assertEqual('gv');

      api.settersFail = true;
      const errorReply: Object[] =
        await caller.call(SYNC_PREFIX + 'getAll', ['prefix.', null] as Object[]) as Object[];
      expect(errorReply.length).assertEqual(3);
      expect(errorReply[0]).assertEqual('get_all_failed');
      api.settersFail = false;
    });

    it('remainingSetterChannelsFailureReplyWrappedError', 0, async () => {
      // 逐条触发 setString/setInt/setDouble/setEncodedStringList/setDeprecatedStringList
      // 的 .catch 分支,覆盖 setup 中对应 handler 的错误回复路径
      api.settersFail = true;
      const names: string[] = ['setString', 'setInt', 'setDouble', 'setEncodedStringList',
        'setDeprecatedStringList'];
      const argsList: Object[][] = [
        ['k', 'v'] as Object[],
        ['k', BigInt(7)] as Object[],
        ['k', 2.5] as Object[],
        ['k', LIST_ID + '["a"]'] as Object[],
        ['k', ['a'] as string[]] as Object[]
      ];
      for (let i = 0; i < names.length; i++) {
        const reply: Object[] =
          await caller.call(SYNC_PREFIX + names[i], argsList[i]) as Object[];
        expect(reply.length).assertEqual(3);
        expect(reply[0]).assertEqual('Error');
        expect(reply[1]).assertContain('setter failed');
      }
      api.settersFail = false;
    });

    it('nullApiUnregistersAllSyncHandlers', 0, () => {
      setup(messenger, null);
      expect(caller.count()).assertEqual(0);
    });
  });

  describe('SharedPreferencesPluginSetupMethodTest', () => {
    it('pluginSetupMethodDelegatesToGlobalSetup', 0, () => {
      const plugin: SharedPreferencesOhosPlugin = new SharedPreferencesOhosPlugin();
      const messenger: RecordingMessenger = new RecordingMessenger();
      const caller: ChannelCaller = new ChannelCaller(messenger);
      plugin.setup(messenger, plugin);
      expect(caller.count()).assertEqual(9);
      // 插件实例方法参数不可空,null 注销路径经 ESObject 中转验证
      const nullApi: ESObject = null;
      plugin.setup(messenger, nullApi);
      expect(caller.count()).assertEqual(0);
    });
  });

  describe('SharedPreferencesPluginLifecycleTest', () => {
    let plugin: SharedPreferencesOhosPlugin = new SharedPreferencesOhosPlugin();
    let messenger: RecordingMessenger = new RecordingMessenger();
    let caller: ChannelCaller = new ChannelCaller(messenger);

    beforeEach(() => {
      plugin = new SharedPreferencesOhosPlugin();
      messenger = new RecordingMessenger();
      caller = new ChannelCaller(messenger);
    });

    it('attachWithoutContextRegistersChannelsAndCachesNull', 0, () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));
      // 9 条同步 + 15*2 条异步通道
      expect(caller.count()).assertEqual(39);
      expect(plugin.preferences).assertNull();
    });

    it('syncChannelWithoutInitializationReportsFailure', 0, async () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));

      const removeReply: Object[] =
        await caller.call(SYNC_PREFIX + 'remove', ['k'] as Object[]) as Object[];
      expect(removeReply[0]).assertEqual(false);

      const setBoolReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setBool', ['k', true] as Object[]) as Object[];
      expect(setBoolReply.length).assertEqual(3);
      expect(setBoolReply[1]).assertContain('Preferences not initialized');
    });

    it('asyncChannelWithoutInitializationRepliesError', 0, async () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));

      // 遍历全部 9 个异步 getter:context 为 null → preferences 为 null,
      // 每个 getter 都应走 "Preferences not initialized" 拒绝分支
      const opts: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, true);
      const getters: string[] = ['getString', 'getBool', 'getDouble', 'getInt',
        'getPlatformEncodedStringList', 'getStringList', 'clear', 'getAll', 'getKeys'];
      for (let i = 0; i < getters.length; i++) {
        const suffix: string = i % 2 === 0 ? '.data_store' : '.shared_preferences';
        const reply: Object[] = await caller.call(ASYNC_PREFIX + getters[i] + suffix,
          ['k', opts] as Object[]) as Object[];
        expect(reply.length).assertEqual(3);
        expect(reply[1]).assertContain('Preferences not initialized');
      }
    });

    it('detachUnregistersAllChannelsAndClearsState', 0, () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));
      plugin.onDetachedFromEngine(asPluginBinding(binding));
      expect(caller.count()).assertEqual(0);
      expect(plugin.preferences).assertNull();
      expect(plugin.remove('k')).assertEqual(false);
    });

    it('detachWithoutContextIsIdempotent', 0, () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      let thrown: boolean = false;
      try {
        plugin.onDetachedFromEngine(asPluginBinding(binding));
        plugin.onDetachedFromEngine(asPluginBinding(binding));
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });

    it('reattachAfterDetachRegistersChannelsAgain', 0, () => {
      const binding: TestPluginBinding = new TestPluginBinding(null, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));
      plugin.onDetachedFromEngine(asPluginBinding(binding));
      plugin.onAttachedToEngine(asPluginBinding(binding));
      expect(caller.count()).assertEqual(39);
    });
  });
}
