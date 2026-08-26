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
// MessagesAsync.ets 单元测试:数据类型 encode/decode、PigeonCodec 线格式,
// 以及 setupSharedPreferencesAsyncApi 注册的全部 15 条通道的成功/失败路径。

import { describe, it, expect, beforeAll } from '@ohos/hypium';
import {
  StringListLookupResultType,
  SharedPreferencesPigeonOptions,
  StringListResult,
  setupSharedPreferencesAsyncApi
} from '../../../main/ets/shared_preferences/MessagesAsync';
import { ChannelCaller, FakeAsyncApi, RecordingMessenger, TestPigeonCodec } from './MockHelpers';

const ASYNC_PREFIX = 'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.';
const OPTS: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, false);

export default function messagesAsyncTest(): void {
  describe('MessagesAsyncTypesTest', () => {
    it('stringListLookupResultTypeEnumValuesAreStable', 0, () => {
      expect(StringListLookupResultType.platformEncoded).assertEqual(0);
      expect(StringListLookupResultType.jsonEncoded).assertEqual(1);
      expect(StringListLookupResultType.unexpectedString).assertEqual(2);
    });

    it('pigeonOptionsDefaultUsesDataStoreWithoutFileName', 0, () => {
      const options: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions();
      expect(options.useDataStore).assertTrue();
      expect(options.fileName).assertUndefined();
    });

    it('pigeonOptionsEncodeWritesFileNameAndFlag', 0, () => {
      const options: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions('cache.txt', false);
      const encoded: Object[] = options.encode() as Object[];
      expect(encoded.length).assertEqual(2);
      expect(encoded[0]).assertEqual('cache.txt');
      expect(encoded[1]).assertEqual(false);
    });

    it('pigeonOptionsEncodeOmitsUndefinedFileNameAsNull', 0, () => {
      const options: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions(undefined, true);
      const encoded: Object[] = options.encode() as Object[];
      expect(encoded[0]).assertNull();
      expect(encoded[1]).assertEqual(true);
    });

    it('pigeonOptionsDecodeReversesEncode', 0, () => {
      const encoded: Object[] = ['store.bin', false] as Object[];
      const decoded: SharedPreferencesPigeonOptions = SharedPreferencesPigeonOptions.decode(encoded);
      expect(decoded.fileName).assertEqual('store.bin');
      expect(decoded.useDataStore).assertFalse();
    });

    it('stringListResultDefaultsToJsonEncodedType', 0, () => {
      const result: StringListResult = new StringListResult('["a"]');
      expect(result.type).assertEqual(StringListLookupResultType.jsonEncoded);
      expect(result.jsonEncodedValue).assertEqual('["a"]');
    });

    it('stringListResultEncodeDecodeRoundTrips', 0, () => {
      const result: StringListResult =
        new StringListResult('["x","y"]', StringListLookupResultType.platformEncoded);
      const encoded: Object[] = result.encode() as Object[];
      expect(encoded[0]).assertEqual('["x","y"]');
      expect(encoded[1]).assertEqual(StringListLookupResultType.platformEncoded);
      const decoded: StringListResult = StringListResult.decode(encoded);
      expect(decoded.jsonEncodedValue).assertEqual('["x","y"]');
      expect(decoded.type).assertEqual(StringListLookupResultType.platformEncoded);
    });
  });

  describe('PigeonCodecWireFormatTest', () => {
    // 通过与生产 PigeonCodec 相同线格式的 TestPigeonCodec 做 encode/decode 往返,
    // 覆盖 bigint/number/自定义类型 130/131 及透传给 StandardCodec 的基础类型。
    const codec: TestPigeonCodec = new TestPigeonCodec();

    it('roundTripsPrimitiveValues', 0, () => {
      expect(codec.decodeMessage(codec.encodeMessage(null as ESObject))).assertNull();
      expect(codec.decodeMessage(codec.encodeMessage(true as ESObject))).assertEqual(true);
      expect(codec.decodeMessage(codec.encodeMessage('hello' as ESObject))).assertEqual('hello');
      expect(codec.decodeMessage(codec.encodeMessage(3.25 as ESObject))).assertEqual(3.25);
    });

    it('roundTripsBigIntAsInt64', 0, () => {
      const decoded: ESObject = codec.decodeMessage(codec.encodeMessage(BigInt(1234567890123) as ESObject));
      // flutter_ohos StandardMessageCodec 会把安全范围内的 int64 解码为 number,
      // 只断言数值经 type 4 int64 线格式往返后无损
      expect(Number(decoded)).assertEqual(1234567890123);
    });

    it('roundTripsListAndMap', 0, () => {
      const list: Object[] = ['a', 'b'] as Object[];
      const decodedList: Object[] = codec.decodeMessage(codec.encodeMessage(list as ESObject)) as Object[];
      expect(decodedList.length).assertEqual(2);
      expect(decodedList[0]).assertEqual('a');

      const map: Map<string, Object> = new Map<string, Object>();
      map.set('k', 'v' as Object);
      const decodedMap: Map<string, Object> =
        codec.decodeMessage(codec.encodeMessage(map as ESObject)) as Map<string, Object>;
      expect(decodedMap.get('k')).assertEqual('v');
    });

    it('roundTripsPigeonOptionsWithType130', 0, () => {
      const options: SharedPreferencesPigeonOptions = new SharedPreferencesPigeonOptions('f1', false);
      const decoded: ESObject = codec.decodeMessage(codec.encodeMessage(options as ESObject));
      expect(decoded instanceof SharedPreferencesPigeonOptions).assertTrue();
      const decodedOptions: SharedPreferencesPigeonOptions = decoded as SharedPreferencesPigeonOptions;
      expect(decodedOptions.fileName).assertEqual('f1');
      expect(decodedOptions.useDataStore).assertFalse();
    });

    it('roundTripsStringListResultWithType131', 0, () => {
      const result: StringListResult =
        new StringListResult('["z"]', StringListLookupResultType.unexpectedString);
      const decoded: ESObject = codec.decodeMessage(codec.encodeMessage(result as ESObject));
      expect(decoded instanceof StringListResult).assertTrue();
      const decodedResult: StringListResult = decoded as StringListResult;
      expect(decodedResult.jsonEncodedValue).assertEqual('["z"]');
      expect(Number(decodedResult.type)).assertEqual(StringListLookupResultType.unexpectedString);
    });
  });

  describe('SetupSharedPreferencesAsyncApiTest', () => {
    let messenger: RecordingMessenger = new RecordingMessenger();
    let api: FakeAsyncApi = new FakeAsyncApi();
    let caller: ChannelCaller = new ChannelCaller(messenger);

    beforeAll(() => {
      setupSharedPreferencesAsyncApi(messenger, api, '.data_store');
    });

    it('registersAllFifteenChannelsWithSuffix', 0, () => {
      expect(caller.count()).assertEqual(15);
      expect(caller.has(ASYNC_PREFIX + 'setBool.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'setString.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'setInt.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'setDouble.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'setEncodedStringList.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'setDeprecatedStringList.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getString.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getBool.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getDouble.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getInt.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getPlatformEncodedStringList.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getStringList.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'clear.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getAll.data_store')).assertTrue();
      expect(caller.has(ASYNC_PREFIX + 'getKeys.data_store')).assertTrue();
    });

    it('defaultSuffixRegistersBareChannelNames', 0, () => {
      const bare: RecordingMessenger = new RecordingMessenger();
      const bareCaller: ChannelCaller = new ChannelCaller(bare);
      setupSharedPreferencesAsyncApi(bare, api);
      expect(bareCaller.has(ASYNC_PREFIX + 'setBool')).assertTrue();
      expect(bareCaller.count()).assertEqual(15);
    });

    it('setterChannelsDeliverArgsAndReplyEmpty', 0, async () => {
      const keyArgs: string[] = ['k-bool', 'k-str', 'k-int', 'k-double', 'k-enc', 'k-dep'];
      const setBoolReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setBool.data_store', [keyArgs[0], true, OPTS] as Object[]);
      const setStringReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setString.data_store', [keyArgs[1], 'v', OPTS] as Object[]);
      const setIntReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setInt.data_store', [keyArgs[2], BigInt(42), OPTS] as Object[]);
      const setDoubleReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setDouble.data_store', [keyArgs[3], 1.5, OPTS] as Object[]);
      const setEncodedReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setEncodedStringList.data_store', [keyArgs[4], '["a"]', OPTS] as Object[]);
      const setDeprecatedReply: ESObject =
        await caller.call(ASYNC_PREFIX + 'setDeprecatedStringList.data_store',
          [keyArgs[5], ['a', 'b'] as string[], OPTS] as Object[]);
      const replies: ESObject[] = [setBoolReply, setStringReply, setIntReply, setDoubleReply, setEncodedReply,
        setDeprecatedReply];
      for (let i = 0; i < replies.length; i++) {
        const replyList: Object[] = replies[i] as Object[];
        expect(replyList.length).assertEqual(0);
      }
      const setters: string[] = ['setBool', 'setString', 'setInt', 'setDouble', 'setEncodedStringList',
        'setDeprecatedStringList'];
      for (let i = 0; i < setters.length; i++) {
        expect(api.calls.includes(setters[i])).assertTrue();
      }
      expect(api.lastKey).assertEqual('k-dep');
    });

    it('setterChannelFailureRepliesWrappedError', 0, async () => {
      api.fail = true;
      const reply: Object[] = await caller.call(ASYNC_PREFIX + 'setBool.data_store',
        ['k', true, OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('async_failed');
      expect(reply[1]).assertEqual('boom');
      api.fail = false;
    });

    it('getterChannelsReturnWrappedResult', 0, async () => {
      const stringReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getString.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(stringReply[0]).assertEqual('stub-string');
      const boolReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getBool.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(boolReply[0]).assertEqual(true);
      const doubleReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getDouble.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(doubleReply[0]).assertEqual(1.5);
      const intReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getInt.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(Number(intReply[0])).assertEqual(7);
    });

    it('getListGettersReturnCollectionsAndResult', 0, async () => {
      const platformReply: Object[] = await caller.call(ASYNC_PREFIX + 'getPlatformEncodedStringList.data_store',
        ['k', OPTS] as Object[]) as Object[];
      const platformList: string[] = platformReply[0] as string[];
      expect(platformList.length).assertEqual(2);
      expect(platformList[0]).assertEqual('a');

      const stringListReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getStringList.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(stringListReply[0] instanceof StringListResult).assertTrue();
      const slr: StringListResult = stringListReply[0] as StringListResult;
      expect(slr.jsonEncodedValue).assertEqual('[]');
      expect(Number(slr.type)).assertEqual(StringListLookupResultType.jsonEncoded);
    });

    it('getAllAndGetKeysReturnCollections', 0, async () => {
      api.allResult.set('mk', 'mv' as Object);
      const allReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getAll.data_store', [null, OPTS] as Object[]) as Object[];
      const allMap: Map<string, Object> = allReply[0] as Map<string, Object>;
      expect(allMap.get('mk')).assertEqual('mv');

      const keysReply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getKeys.data_store', [null, OPTS] as Object[]) as Object[];
      const keys: string[] = keysReply[0] as string[];
      expect(keys.length).assertEqual(1);
      expect(keys[0]).assertEqual('k1');
    });

    it('getAllNullResultRepliesErrorInsteadOfNull', 0, async () => {
      api.nullResult = true;
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getAll.data_store', [null, OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[1]).assertContain('Host platform returned null value');
      api.nullResult = false;
    });

    it('getKeysNullResultRepliesErrorInsteadOfNull', 0, async () => {
      api.nullResult = true;
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getKeys.data_store', [null, OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[1]).assertContain('Host platform returned null value');
      api.nullResult = false;
    });

    it('getterChannelFailureRepliesWrappedError', 0, async () => {
      api.fail = true;
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getString.data_store', ['k', OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(3);
      expect(reply[0]).assertEqual('async_failed');
      api.fail = false;
    });

    it('clearChannelRepliesEmptyOnSuccess', 0, async () => {
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'clear.data_store', [null, OPTS] as Object[]) as Object[];
      expect(reply.length).assertEqual(0);
    });

    it('everyChannelFailureRepliesWrappedError', 0, async () => {
      // 逐条通道触发 .catch 分支,覆盖 setup 中全部 15 个 handler 的错误回复路径
      api.fail = true;
      const setterNames: string[] = ['setBool', 'setString', 'setInt', 'setDouble', 'setEncodedStringList',
        'setDeprecatedStringList'];
      const setterArgs: Object[][] = [
        ['k', true, OPTS] as Object[],
        ['k', 'v', OPTS] as Object[],
        ['k', BigInt(1), OPTS] as Object[],
        ['k', 1.5, OPTS] as Object[],
        ['k', '["a"]', OPTS] as Object[],
        ['k', ['a'] as string[], OPTS] as Object[]
      ];
      for (let i = 0; i < setterNames.length; i++) {
        const reply: Object[] =
          await caller.call(ASYNC_PREFIX + setterNames[i] + '.data_store', setterArgs[i]) as Object[];
        expect(reply.length).assertEqual(3);
        expect(reply[0]).assertEqual('async_failed');
        expect(reply[1]).assertEqual('boom');
      }
      const getterNames: string[] = ['getString', 'getBool', 'getDouble', 'getInt',
        'getPlatformEncodedStringList', 'getStringList', 'clear', 'getAll', 'getKeys'];
      for (let i = 0; i < getterNames.length; i++) {
        const reply: Object[] =
          await caller.call(ASYNC_PREFIX + getterNames[i] + '.data_store', ['k', OPTS] as Object[]) as Object[];
        expect(reply.length).assertEqual(3);
        expect(reply[0]).assertEqual('async_failed');
      }
      api.fail = false;
    });

    it('getAllReplyMapEncodesPigeonOptionsWithProductionCodec', 0, async () => {
      // 回复中的 Map 携带 PigeonOptions,生产 PigeonCodec.writeValue 需走 130 类型分支编码
      api.allResult.set('opt', OPTS as Object);
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getAll.data_store', [null, OPTS] as Object[]) as Object[];
      const allMap: Map<string, Object> = reply[0] as Map<string, Object>;
      expect(allMap.get('opt') instanceof SharedPreferencesPigeonOptions).assertTrue();
      api.allResult.clear();
    });

    it('stringListResultArgDecodedByProductionCodec', 0, async () => {
      // 参数中携带 StringListResult(131),生产 PigeonCodec.readValueOfType 需走 131/129 分支解码
      const arg: StringListResult =
        new StringListResult('["z"]', StringListLookupResultType.platformEncoded);
      const reply: Object[] =
        await caller.call(ASYNC_PREFIX + 'getString.data_store', ['k-slr', arg] as Object[]) as Object[];
      expect(reply[0]).assertEqual('stub-string');
      expect(api.lastKey).assertEqual('k-slr');
    });

    it('nullApiUnregistersAllHandlers', 0, () => {
      setupSharedPreferencesAsyncApi(messenger, null, '.data_store');
      expect(caller.count()).assertEqual(0);
    });
  });
}
