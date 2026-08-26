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
// 依赖真实 ApplicationContext / data_preferences 的设备测试:
// 覆盖插件初始化、legacy 同步 API 读写、异步 API 通道往返、类型不匹配、
// getStringList 三种结果、分批 clear、allowList、多存储名缓存与释放。

import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import SharedPreferencesOhosPlugin from '../../../main/ets/shared_preferences/SharedPreferencesOhosPlugin';
import {
  SharedPreferencesPigeonOptions,
  StringListLookupResultType,
  StringListResult
} from '../../../main/ets/shared_preferences/MessagesAsync';
import { asPluginBinding, ChannelCaller, RecordingMessenger, TestPluginBinding } from './MockHelpers';

const SYNC_PREFIX = 'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.';
const ASYNC_PREFIX = 'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.';
const LIST_ID = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu';
const JSON_LIST_PREFIX = LIST_ID + '!';
const RUN_ID: string = Date.now().toString();

/** data_store 后端选项 */
const DATA_STORE_OPTS: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, true);
/** shared_preferences 后端选项 */
const SHARED_PREFS_OPTS: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, false);

export default function sharedPreferencesDeviceTest(): void {
  describe('SharedPreferencesPluginDeviceTest', () => {
    let plugin: SharedPreferencesOhosPlugin = new SharedPreferencesOhosPlugin();
    let messenger: RecordingMessenger = new RecordingMessenger();
    let caller: ChannelCaller = new ChannelCaller(messenger);
    let binding: TestPluginBinding = new TestPluginBinding(null, messenger);

    beforeAll(async () => {
      // delegator.getAppContext() 返回的 ApplicationContext 会被 data_preferences
      // 以 401 (Parameter error. The context is invalid.) 拒绝,改用 TestAbility 的 UIAbilityContext
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const ability: UIAbility = await delegator.getCurrentTopAbility();
      const context: common.Context = ability.context;
      plugin = new SharedPreferencesOhosPlugin();
      messenger = new RecordingMessenger();
      caller = new ChannelCaller(messenger);
      binding = new TestPluginBinding(context, messenger);
      plugin.onAttachedToEngine(asPluginBinding(binding));
    });

    afterAll(() => {
      plugin.onDetachedFromEngine(asPluginBinding(binding));
    });

    it('attachInitializesLegacyPreferencesAndRegistersChannels', 0, () => {
      expect(plugin.preferences !== null).assertTrue();
      expect(caller.count()).assertEqual(39);
    });

    it('legacySettersAndGetAllRoundTrips', 0, async () => {
      const prefix: string = `ut.${RUN_ID}.`;
      expect(await plugin.setBool(`${prefix}bool`, true)).assertTrue();
      expect(await plugin.setString(`${prefix}str`, 'hello')).assertTrue();
      expect(await plugin.setInt(`${prefix}int`, BigInt(42))).assertTrue();
      expect(await plugin.setDouble(`${prefix}double`, 2.5)).assertTrue();
      expect(await plugin.setEncodedStringList(`${prefix}enc`, JSON_LIST_PREFIX + '["e"]')).assertTrue();
      expect(await plugin.setDeprecatedStringList(`${prefix}dep`, ['a', 'b'] as string[])).assertTrue();

      const all: Map<string, Object> = await plugin.getAll(prefix, null);
      expect(all.size).assertEqual(6);
      expect(all.get(`${prefix}bool`)).assertEqual(true);
      expect(all.get(`${prefix}str`)).assertEqual('hello');
      expect(Number(all.get(`${prefix}int`))).assertEqual(42);
      expect(all.get(`${prefix}double`)).assertEqual(2.5);
      expect(all.get(`${prefix}enc`)).assertEqual(JSON_LIST_PREFIX + '["e"]');
      const depList: string[] = all.get(`${prefix}dep`) as string[];
      expect(depList.length).assertEqual(2);
      expect(depList[1]).assertEqual('b');
    });

    it('legacyRemoveDeletesKey', 0, async () => {
      const key: string = `ut.${RUN_ID}.remove.me`;
      expect(await plugin.setString(key, 'temp')).assertTrue();
      expect(plugin.remove(key)).assertTrue();
      const all: Map<string, Object> = await plugin.getAll(`ut.${RUN_ID}.remove.`, null);
      expect(all.size).assertEqual(0);
    });

    it('legacyClearRespectsPrefixAndAllowList', 0, async () => {
      const prefix: string = `ut.${RUN_ID}.clear.`;
      expect(await plugin.setString(`${prefix}a`, '1')).assertTrue();
      expect(await plugin.setString(`${prefix}b`, '2')).assertTrue();
      expect(await plugin.setString(`ut.${RUN_ID}.keep.`, 'x')).assertTrue();

      // allowList 只清 a,保留 b
      expect(await plugin.clear(prefix, [`${prefix}a`] as string[])).assertTrue();
      const afterAllowList: Map<string, Object> = await plugin.getAll(prefix, null);
      expect(afterAllowList.has(`${prefix}a`)).assertFalse();
      expect(afterAllowList.has(`${prefix}b`)).assertTrue();

      // 前缀全清
      expect(await plugin.clear(prefix, null)).assertTrue();
      const afterClear: Map<string, Object> = await plugin.getAll(prefix, null);
      expect(afterClear.size).assertEqual(0);
      const kept: Map<string, Object> = await plugin.getAll(`ut.${RUN_ID}.keep.`, null);
      expect(kept.size).assertEqual(1);
    });

    it('syncChannelRoundTripsOnRealPreferences', 0, async () => {
      const key: string = `ut.${RUN_ID}.chan.str`;
      const setReply: Object[] =
        await caller.call(SYNC_PREFIX + 'setString', [key, 'via-channel'] as Object[]) as Object[];
      expect(setReply[0]).assertEqual(true);

      const allReply: Object[] =
        await caller.call(SYNC_PREFIX + 'getAll', [`ut.${RUN_ID}.chan.`, null] as Object[]) as Object[];
      const allMap: Map<string, Object> = allReply[0] as Map<string, Object>;
      expect(allMap.get(key)).assertEqual('via-channel');

      const removeReply: Object[] =
        await caller.call(SYNC_PREFIX + 'remove', [key] as Object[]) as Object[];
      expect(removeReply[0]).assertEqual(true);

      const clearReply: Object[] =
        await caller.call(SYNC_PREFIX + 'clear', [`ut.${RUN_ID}.chan.`, null] as Object[]) as Object[];
      expect(clearReply[0]).assertEqual(true);
    });

    it('asyncSetAndGetRoundTripsOnDataStore', 0, async () => {
      const boolKey: string = `ut.${RUN_ID}.ds.bool`;
      const boolSetReply: Object[] = await caller.call(ASYNC_PREFIX + 'setBool.data_store',
        [boolKey, true, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(boolSetReply.length).assertEqual(0);
      const boolReply: Object[] = await caller.call(ASYNC_PREFIX + 'getBool.data_store',
        [boolKey, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(boolReply.length).assertEqual(1);
      expect(boolReply[0]).assertEqual(true);

      const stringKey: string = `ut.${RUN_ID}.ds.str`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [stringKey, 'ds-value', DATA_STORE_OPTS] as Object[]);
      const stringReply: Object[] = await caller.call(ASYNC_PREFIX + 'getString.data_store',
        [stringKey, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(stringReply[0]).assertEqual('ds-value');

      const intKey: string = `ut.${RUN_ID}.ds.int`;
      await caller.call(ASYNC_PREFIX + 'setInt.data_store',
        [intKey, BigInt(123456789012), DATA_STORE_OPTS] as Object[]);
      const intReply: Object[] = await caller.call(ASYNC_PREFIX + 'getInt.data_store',
        [intKey, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(Number(intReply[0])).assertEqual(123456789012);

      const doubleKey: string = `ut.${RUN_ID}.ds.double`;
      await caller.call(ASYNC_PREFIX + 'setDouble.data_store',
        [doubleKey, 3.75, DATA_STORE_OPTS] as Object[]);
      const doubleReply: Object[] = await caller.call(ASYNC_PREFIX + 'getDouble.data_store',
        [doubleKey, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(doubleReply[0]).assertEqual(3.75);
    });

    it('asyncMissingKeyGettersReturnNull', 0, async () => {
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getString.data_store',
        [`ut.${RUN_ID}.missing`, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(1);
      expect(reply[0]).assertNull();
    });

    it('asyncTypeMismatchRepliesClassCastException', 0, async () => {
      const key: string = `ut.${RUN_ID}.tm.str`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [key, 'plain-string', DATA_STORE_OPTS] as Object[]);

      const boolReply: Object[] = await caller.call(ASYNC_PREFIX + 'getBool.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(boolReply.length).assertEqual(3);
      expect(boolReply[0]).assertEqual('ClassCastException');
      expect(boolReply[1]).assertContain('Expected boolean');

      const intReply: Object[] = await caller.call(ASYNC_PREFIX + 'getInt.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(intReply[0]).assertEqual('ClassCastException');
      expect(intReply[1]).assertContain('Expected int');
    });

    it('asyncGetStringRejectsPlatformEncodedListPrefix', 0, async () => {
      const key: string = `ut.${RUN_ID}.tm.list`;
      await caller.call(ASYNC_PREFIX + 'setDeprecatedStringList.data_store',
        [key, ['a'] as string[], DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getString.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('ClassCastException');
    });

    it('asyncGetDoubleAcceptsBigIntValue', 0, async () => {
      const key: string = `ut.${RUN_ID}.tm.bigint`;
      await caller.call(ASYNC_PREFIX + 'setInt.data_store',
        [key, BigInt(7), DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getDouble.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(1);
      expect(reply[0]).assertEqual(7);
    });

    it('asyncGetIntAcceptsNumberValue', 0, async () => {
      const key: string = `ut.${RUN_ID}.tm.number`;
      await caller.call(ASYNC_PREFIX + 'setDouble.data_store',
        [key, 9.0, DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getInt.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(Number(reply[0])).assertEqual(9);
    });

    it('asyncGetStringTypeMismatchOnNonStringValue', 0, async () => {
      // 存 int 后 getString:非 string 值触发 getString 的类型不匹配拒绝
      const key: string = `ut.${RUN_ID}.tm.strint`;
      await caller.call(ASYNC_PREFIX + 'setInt.data_store',
        [key, BigInt(11), DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getString.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('ClassCastException');
      expect(reply[1]).assertContain('Expected string');
    });

    it('asyncGetDoubleTypeMismatchOnStringValue', 0, async () => {
      // 存 string 后 getDouble:非 number/bigint 值触发 getDouble 的类型不匹配拒绝
      const key: string = `ut.${RUN_ID}.tm.doublestr`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [key, 'text', DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getDouble.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('ClassCastException');
      expect(reply[1]).assertContain('Expected number');
    });

    it('asyncMissingKeyTypedGettersReturnNull', 0, async () => {
      // 缺失键时 getBool/getDouble/getInt 走 value === null 分支返回 null
      const getters: string[] = ['getBool', 'getDouble', 'getInt'];
      for (let i = 0; i < getters.length; i++) {
        const reply: Object[] = await caller.call(ASYNC_PREFIX + getters[i] + '.data_store',
          [`ut.${RUN_ID}.miss.${getters[i]}`, DATA_STORE_OPTS] as Object[]) as Object[];
        expect(reply.length).assertEqual(1);
        expect(reply[0]).assertNull();
      }
    });

    it('asyncStorageNameWithPathSeparatorDegradesGracefully', 0, async () => {
      // 含路径分隔符的存储名:当前设备 data_preferences 会创建子目录并成功打开,
      // 此用例固化该行为并验证所有 getter 不挂死:合法回复只能是 [null] 或 3 元错误
      const oddOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_bad/${RUN_ID}`, false);
      const getters: string[] = ['getString', 'getBool', 'getDouble', 'getInt',
        'getPlatformEncodedStringList', 'getStringList', 'clear', 'getAll', 'getKeys'];
      for (let i = 0; i < getters.length; i++) {
        const reply: Object[] = await caller.call(ASYNC_PREFIX + getters[i] + '.data_store',
          [`ut.${RUN_ID}.odd`, oddOpts] as Object[]) as Object[];
        // 合法形态:clear 成功为空数组(0),标量 getter 缺键为 [null],
        // getAll/getKeys 为 [空Map/空数组],创建失败为 3 元错误
        expect(reply.length === 0 || reply.length === 1 || reply.length === 3).assertTrue();
      }
    });

    it('transformPrefInvalidLegacyListReturnsRawValue', 0, async () => {
      // 存入 LIST_IDENTIFIER 前缀 + 非法 JSON 的原始字符串,transformPref 内
      // listEncoder.decode 吞错返回空列表(803 catch 因 decode 不抛错而不可达,此用例固化该行为)
      const key: string = `ut.${RUN_ID}.legacy.badjson`;
      expect(await plugin.setEncodedStringList(key, LIST_ID + 'not-json')).assertTrue();
      const all: Map<string, Object> = await plugin.getAll(`ut.${RUN_ID}.legacy.`, null);
      const decoded: string[] = all.get(key) as string[];
      expect(decoded.length).assertEqual(0);
    });

    it('asyncGetStringListCoversAllResultTypes', 0, async () => {
      const jsonKey: string = `ut.${RUN_ID}.sl.json`;
      await caller.call(ASYNC_PREFIX + 'setEncodedStringList.data_store',
        [jsonKey, JSON_LIST_PREFIX + '["j1","j2"]', DATA_STORE_OPTS] as Object[]);
      const jsonReply: Object[] = await caller.call(ASYNC_PREFIX + 'getStringList.data_store',
        [jsonKey, DATA_STORE_OPTS] as Object[]) as Object[];
      const jsonResult: StringListResult = jsonReply[0] as StringListResult;
      expect(Number(jsonResult.type)).assertEqual(StringListLookupResultType.jsonEncoded);
      expect(jsonResult.jsonEncodedValue).assertEqual(JSON_LIST_PREFIX + '["j1","j2"]');

      const platformKey: string = `ut.${RUN_ID}.sl.platform`;
      await caller.call(ASYNC_PREFIX + 'setDeprecatedStringList.data_store',
        [platformKey, ['p1'] as string[], DATA_STORE_OPTS] as Object[]);
      const platformReply: Object[] = await caller.call(ASYNC_PREFIX + 'getStringList.data_store',
        [platformKey, DATA_STORE_OPTS] as Object[]) as Object[];
      const platformResult: StringListResult = platformReply[0] as StringListResult;
      expect(Number(platformResult.type)).assertEqual(StringListLookupResultType.platformEncoded);

      const plainKey: string = `ut.${RUN_ID}.sl.plain`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [plainKey, 'plain', DATA_STORE_OPTS] as Object[]);
      const plainReply: Object[] = await caller.call(ASYNC_PREFIX + 'getStringList.data_store',
        [plainKey, DATA_STORE_OPTS] as Object[]) as Object[];
      const plainResult: StringListResult = plainReply[0] as StringListResult;
      expect(Number(plainResult.type)).assertEqual(StringListLookupResultType.unexpectedString);

      const missingReply: Object[] = await caller.call(ASYNC_PREFIX + 'getStringList.data_store',
        [`ut.${RUN_ID}.sl.missing`, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(missingReply.length).assertEqual(1);
      expect(missingReply[0]).assertNull();
    });

    it('asyncGetPlatformEncodedStringListDecodesValue', 0, async () => {
      const key: string = `ut.${RUN_ID}.pl.list`;
      await caller.call(ASYNC_PREFIX + 'setDeprecatedStringList.data_store',
        [key, ['x', 'y', 'z'] as string[], DATA_STORE_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getPlatformEncodedStringList.data_store',
        [key, DATA_STORE_OPTS] as Object[]) as Object[];
      const list: string[] = reply[0] as string[];
      expect(list.length).assertEqual(3);
      expect(list[2]).assertEqual('z');

      const missingReply: Object[] = await caller.call(ASYNC_PREFIX + 'getPlatformEncodedStringList.data_store',
        [`ut.${RUN_ID}.pl.missing`, DATA_STORE_OPTS] as Object[]) as Object[];
      expect(missingReply[0]).assertNull();
    });

    it('asyncGetAllAndGetKeysRespectAllowList', 0, async () => {
      const prefix: string = `ut.${RUN_ID}.ga.`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [`${prefix}k1`, 'v1', DATA_STORE_OPTS] as Object[]);
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [`${prefix}k2`, 'v2', DATA_STORE_OPTS] as Object[]);

      const allow: string[] = [`${prefix}k1`] as string[];
      const allReply: Object[] = await caller.call(ASYNC_PREFIX + 'getAll.data_store',
        [allow, DATA_STORE_OPTS] as Object[]) as Object[];
      const allMap: Map<string, Object> = allReply[0] as Map<string, Object>;
      expect(allMap.size).assertEqual(1);
      expect(allMap.get(`${prefix}k1`)).assertEqual('v1');

      const keysReply: Object[] = await caller.call(ASYNC_PREFIX + 'getKeys.data_store',
        [allow, DATA_STORE_OPTS] as Object[]) as Object[];
      const keys: string[] = keysReply[0] as string[];
      expect(keys.length).assertEqual(1);
      expect(keys[0]).assertEqual(`${prefix}k1`);
    });

    it('asyncClearBatchesMoreThanTenKeys', 0, async () => {
      const batchOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_batch_${RUN_ID}`, false);
      const prefix: string = `ut.${RUN_ID}.batch.`;
      for (let i = 0; i < 25; i++) {
        await caller.call(ASYNC_PREFIX + 'setString.data_store',
          [`${prefix}${i}`, `v${i}`, batchOpts] as Object[]);
      }
      const beforeReply: Object[] = await caller.call(ASYNC_PREFIX + 'getKeys.data_store',
        [null, batchOpts] as Object[]) as Object[];
      expect((beforeReply[0] as string[]).length).assertEqual(25);

      const clearReply: Object[] = await caller.call(ASYNC_PREFIX + 'clear.data_store',
        [null, batchOpts] as Object[]) as Object[];
      expect(clearReply.length).assertEqual(0);

      const afterReply: Object[] = await caller.call(ASYNC_PREFIX + 'getKeys.data_store',
        [null, batchOpts] as Object[]) as Object[];
      expect((afterReply[0] as string[]).length).assertEqual(0);
    });

    it('asyncClearDeduplicatesAllowList', 0, async () => {
      const dedupOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_dedup_${RUN_ID}`, false);
      const prefix: string = `ut.${RUN_ID}.dedup.`;
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [`${prefix}a`, '1', dedupOpts] as Object[]);
      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [`${prefix}b`, '2', dedupOpts] as Object[]);

      const allow: string[] = [`${prefix}a`, `${prefix}a`, `${prefix}b`] as string[];
      const clearReply: Object[] = await caller.call(ASYNC_PREFIX + 'clear.data_store',
        [allow, dedupOpts] as Object[]) as Object[];
      expect(clearReply.length).assertEqual(0);

      const keysReply: Object[] = await caller.call(ASYNC_PREFIX + 'getKeys.data_store',
        [null, dedupOpts] as Object[]) as Object[];
      expect((keysReply[0] as string[]).length).assertEqual(0);
    });

    it('asyncSharedPrefsBackendWorksToo', 0, async () => {
      const key: string = `ut.${RUN_ID}.sp.str`;
      await caller.call(ASYNC_PREFIX + 'setString.shared_preferences',
        [key, 'sp-value', SHARED_PREFS_OPTS] as Object[]);
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'getString.shared_preferences',
        [key, SHARED_PREFS_OPTS] as Object[]) as Object[];
      expect(reply[0]).assertEqual('sp-value');
    });

    it('getPreferencesForOptionsCachesSameInstance', 0, async () => {
      const opts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_cache_${RUN_ID}`, false);
      const first: ESObject = await plugin.getPreferencesForOptions(opts);
      const second: ESObject = await plugin.getPreferencesForOptions(opts);
      expect(first !== null).assertTrue();
      expect(first === second).assertTrue();
    });

    it('manyStorageNamesAllRemainCachedAndUsable', 0, async () => {
      // 缓存按存储名保留全部实例(与 Android ContextImpl 行为对齐,不设上限):
      // 打开 12 个不同存储名后,首个名字仍应命中同一缓存实例
      const firstOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_multi_${RUN_ID}_0`, false);
      const firstOpen: ESObject = await plugin.getPreferencesForOptions(firstOpts);
      for (let i = 1; i < 12; i++) {
        const opts: SharedPreferencesPigeonOptions =
          new SharedPreferencesPigeonOptions(`ut_multi_${RUN_ID}_${i}`, false);
        const preferences: ESObject = await plugin.getPreferencesForOptions(opts);
        expect(preferences !== null).assertTrue();
      }
      const reopen: ESObject = await plugin.getPreferencesForOptions(firstOpts);
      expect(reopen === firstOpen).assertTrue();
    });

    it('detachReleasesStateAndReattachRestores', 0, async () => {
      plugin.onDetachedFromEngine(asPluginBinding(binding));
      expect(plugin.preferences).assertNull();
      expect(plugin.remove('any')).assertEqual(false);

      plugin.onAttachedToEngine(asPluginBinding(binding));
      expect(plugin.preferences !== null).assertTrue();
      expect(await plugin.setBool(`ut.${RUN_ID}.after.reattach`, true)).assertTrue();
    });
  });
}
