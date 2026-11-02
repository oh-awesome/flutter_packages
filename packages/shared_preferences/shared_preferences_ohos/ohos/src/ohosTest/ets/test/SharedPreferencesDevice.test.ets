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
// Device tests that need a real ApplicationContext / data_preferences:
// cover plugin initialization, legacy sync API reads/writes, async API
// channel round trips, type mismatches, the three getStringList results,
// batched clear, allowList, and multi-storage-name caching and release.

import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';
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
const BIG_INT_ID = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy';
const JSON_LIST_PREFIX = LIST_ID + '!';
const RUN_ID: string = Date.now().toString();

/** Options for the data_store backend. */
const DATA_STORE_OPTS: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, true);
/** Options for the shared_preferences backend. */
const SHARED_PREFS_OPTS: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, false);

export default function sharedPreferencesDeviceTest(): void {
  describe('SharedPreferencesPluginDeviceTest', () => {
    let plugin: SharedPreferencesOhosPlugin = new SharedPreferencesOhosPlugin();
    let messenger: RecordingMessenger = new RecordingMessenger();
    let caller: ChannelCaller = new ChannelCaller(messenger);
    let binding: TestPluginBinding = new TestPluginBinding(null, messenger);
    let abilityContext: common.Context | null = null;

    beforeAll(async () => {
      // The ApplicationContext returned by delegator.getAppContext() is rejected
      // by data_preferences with 401 (Parameter error. The context is invalid.),
      // so use the TestAbility's UIAbilityContext instead.
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const ability: UIAbility = await delegator.getCurrentTopAbility();
      const context: common.Context = ability.context;
      abilityContext = context;
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

      // allowList clears only a and keeps b.
      expect(await plugin.clear(prefix, [`${prefix}a`] as string[])).assertTrue();
      const afterAllowList: Map<string, Object> = await plugin.getAll(prefix, null);
      expect(afterAllowList.has(`${prefix}a`)).assertFalse();
      expect(afterAllowList.has(`${prefix}b`)).assertTrue();

      // Null allowList clears everything under the prefix.
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
      // Store an int then getString: a non-string value triggers getString's
      // type-mismatch rejection.
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
      // Store a string then getDouble: a non-number/bigint value triggers
      // getDouble's type-mismatch rejection.
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
      // With a missing key, getBool/getDouble/getInt take the value === null
      // branch and return null.
      const getters: string[] = ['getBool', 'getDouble', 'getInt'];
      for (let i = 0; i < getters.length; i++) {
        const reply: Object[] = await caller.call(ASYNC_PREFIX + getters[i] + '.data_store',
          [`ut.${RUN_ID}.miss.${getters[i]}`, DATA_STORE_OPTS] as Object[]) as Object[];
        expect(reply.length).assertEqual(1);
        expect(reply[0]).assertNull();
      }
    });

    it('asyncStorageNameWithPathSeparatorDegradesGracefully', 0, async () => {
      // Storage name with a path separator: the device data_preferences
      // creates a subdirectory and opens successfully. This case pins that
      // behavior and verifies no getter hangs: a valid reply can only be a
      // plain success or a 3-element error.
      const oddOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(`ut_bad/${RUN_ID}`, false);
      const getters: string[] = ['getString', 'getBool', 'getDouble', 'getInt',
        'getPlatformEncodedStringList', 'getStringList', 'clear', 'getAll', 'getKeys'];
      for (let i = 0; i < getters.length; i++) {
        const reply: Object[] = await caller.call(ASYNC_PREFIX + getters[i] + '.data_store',
          [`ut.${RUN_ID}.odd`, oddOpts] as Object[]) as Object[];
        // Valid shapes: clear success is an empty array (0), scalar getters
        // reply [null] on a missing key, getAll/getKeys reply [empty map/array],
        // and creation failure is a 3-element error.
        expect(reply.length === 0 || reply.length === 1 || reply.length === 3).assertTrue();
      }
    });

    it('transformPrefInvalidLegacyListReturnsRawValue', 0, async () => {
      // Store a LIST_IDENTIFIER-prefixed string with invalid JSON; the
      // listEncoder.decode inside transformPref swallows the error and returns
      // an empty list (the surrounding catch is unreachable because decode
      // never throws). This case pins that behavior.
      const key: string = `ut.${RUN_ID}.legacy.badjson`;
      expect(await plugin.setEncodedStringList(key, LIST_ID + 'not-json')).assertTrue();
      const all: Map<string, Object> = await plugin.getAll(`ut.${RUN_ID}.legacy.`, null);
      const decoded: string[] = all.get(key) as string[];
      expect(decoded.length).assertEqual(0);
    });

    it('legacyGetAllDecodesBigIntegerPrefix', 0, async () => {
      // Write legacy BIG_INTEGER_PREFIX entries the way the 2017-era plugin
      // did (base-36 strings) via raw data_preferences; legacy getAll must
      // decode them back to BigInts, matching Android's legacy transformPref.
      const prefix: string = `ut.${RUN_ID}.bigint.`;
      const intKey: string = `${prefix}inRange`;
      const hugeKey: string = `${prefix}huge`;
      // getPreferencesSync matches the plugin's own instance creation for the
      // same (context, name), so both sides share one cached instance.
      const raw: data_preferences.Preferences = data_preferences.getPreferencesSync(
        abilityContext as common.Context, { name: 'FlutterSharedPreferences' });
      raw.putSync(intKey, BIG_INT_ID + '8rc4kbdvss1s'); // 2^60
      raw.putSync(hugeKey, BIG_INT_ID + '6x5kxtvuwilukg'); // 2^70, beyond int64
      raw.flushSync();

      const all: Map<string, Object> = await plugin.getAll(prefix, null);
      expect((all.get(intKey) as bigint) === BigInt('1152921504606846976')).assertTrue();
      expect((all.get(hugeKey) as bigint) === BigInt('1180591620717411303424')).assertTrue();

      plugin.remove(intKey);
      plugin.remove(hugeKey);
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

    it('asyncGetAllClearGetKeysSkipNonScalarValuesWithoutAllowList', 0, async () => {
      // Mirrors Android preferencesFilter: with a null allowList only values of
      // plugin-writable scalar types are managed; entries written natively
      // (arrays/Uint8Array) into the same file are left untouched. With a
      // non-null allowList only key membership matters, as on Android.
      const storageName: string = `ut_filter_${RUN_ID}`;
      const filterOpts: SharedPreferencesPigeonOptions =
        new SharedPreferencesPigeonOptions(storageName, false);
      const prefix: string = `ut.${RUN_ID}.filter.`;
      const scalarKey: string = `${prefix}scalar`;
      const arrayKey: string = `${prefix}array`;
      const bytesKey: string = `${prefix}bytes`;

      await caller.call(ASYNC_PREFIX + 'setString.data_store',
        [scalarKey, 'sv', filterOpts] as Object[]);

      // Write non-scalar entries through raw data_preferences, the way native
      // code sharing the storage file would.
      // getPreferencesSync matches the plugin's own instance creation for the
      // same (context, name), so both sides share one cached instance.
      const raw: data_preferences.Preferences =
        data_preferences.getPreferencesSync(abilityContext as common.Context, { name: storageName });
      const nativeArray: number[] = [1, 2, 3];
      raw.putSync(arrayKey, nativeArray);
      raw.putSync(bytesKey, new Uint8Array([1, 2]));
      raw.flushSync();

      const allReply: Object[] = await caller.call(ASYNC_PREFIX + 'getAll.data_store',
        [null, filterOpts] as Object[]) as Object[];
      const allMap: Map<string, Object> = allReply[0] as Map<string, Object>;
      expect(allMap.has(scalarKey)).assertTrue();
      expect(allMap.has(arrayKey)).assertFalse();
      expect(allMap.has(bytesKey)).assertFalse();

      const keysReply: Object[] = await caller.call(ASYNC_PREFIX + 'getKeys.data_store',
        [null, filterOpts] as Object[]) as Object[];
      const keys: string[] = keysReply[0] as string[];
      expect(keys.includes(scalarKey)).assertTrue();
      expect(keys.includes(arrayKey)).assertFalse();
      expect(keys.includes(bytesKey)).assertFalse();

      const clearReply: Object[] = await caller.call(ASYNC_PREFIX + 'clear.data_store',
        [null, filterOpts] as Object[]) as Object[];
      expect(clearReply.length).assertEqual(0);

      // The scalar entry is gone, while the native entries survive; naming
      // them in an allowList still returns them (membership-only path).
      const afterAllReply: Object[] = await caller.call(ASYNC_PREFIX + 'getAll.data_store',
        [null, filterOpts] as Object[]) as Object[];
      expect((afterAllReply[0] as Map<string, Object>).size).assertEqual(0);

      const memberReply: Object[] = await caller.call(ASYNC_PREFIX + 'getAll.data_store',
        [[arrayKey, bytesKey] as string[], filterOpts] as Object[]) as Object[];
      const memberMap: Map<string, Object> = memberReply[0] as Map<string, Object>;
      expect(memberMap.size).assertEqual(2);
      expect(memberMap.has(arrayKey)).assertTrue();
      expect(memberMap.has(bytesKey)).assertTrue();

      const cleanupReply: Object[] = await caller.call(ASYNC_PREFIX + 'clear.data_store',
        [[arrayKey, bytesKey] as string[], filterOpts] as Object[]) as Object[];
      expect(cleanupReply.length).assertEqual(0);
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
      // The cache keeps one instance per storage name (aligned with Android
      // ContextImpl behavior, no cap): after opening 12 distinct names, the
      // first name must still hit the same cached instance.
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
