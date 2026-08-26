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
// 单元测试辅助:记录型 BinaryMessenger、回复记录器、与 MessagesAsync.ets 中
// PigeonCodec 线格式一致的测试编解码器,以及同步/异步两套 API 的 Fake 实现。

import {
  BinaryMessenger,
  BinaryMessageHandler,
  BinaryReply,
  TaskQueue,
  TaskQueueOptions
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import SendableBinaryMessageHandler
  from '@ohos/flutter_ohos/src/main/ets/plugin/common/SendableBinaryMessageHandler';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { FlutterError, SharedPreferencesApi, wrapError } from '../../../main/ets/shared_preferences/Messages';
import {
  SharedPreferencesAsyncApi,
  SharedPreferencesPigeonOptions,
  StringListResult
} from '../../../main/ets/shared_preferences/MessagesAsync';
import common from '@ohos.app.ability.common';

/** 记录所有通过 setMessageHandler 注册的通道处理器,供测试直接以编码字节调用。 */
export class RecordingMessenger implements BinaryMessenger {
  public handlers: Map<string, BinaryMessageHandler> = new Map<string, BinaryMessageHandler>();

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    throw new Error('makeBackgroundTaskQueue is not used in unit tests');
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
    // 测试不关心发往 Flutter 侧的消息,记录通道名即可
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | SendableBinaryMessageHandler | null,
    taskQueue?: TaskQueue, ...args: Object[]): void {
    const key: string = channel.toString();
    if (handler === null) {
      this.handlers.delete(key);
    } else {
      this.handlers.set(key, handler as BinaryMessageHandler);
    }
  }
}

/** 记录 handler 提交的原始回复字节。 */
export class RecordingReply implements BinaryReply {
  public replied: ArrayBuffer | null = null;
  public reply: (reply: ArrayBuffer | null) => void = (data: ArrayBuffer | null): void => {
    this.replied = data;
  };
}

/**
 * 与 MessagesAsync.ets 内部 PigeonCodec 相同线格式(129/130/131 自定义类型标签)
 * 的编解码器。测试用它编码发给被注册 handler 的参数、解码 handler 的回复,
 * 从而让生产 PigeonCodec 的 readValueOfType/writeValue 全程参与编解码。
 */
export class TestPigeonCodec extends StandardMessageCodec {
  writeValue(stream: ESObject, value: ESObject): ESObject {
    if (typeof value === 'bigint') {
      stream.writeUint8(4);
      stream.writeInt64(value, true);
    } else if (typeof value === 'number') {
      stream.writeUint8(6);
      this.writeAlignment(stream, 8);
      stream.writeFloat64(value, true);
    } else if (value instanceof SharedPreferencesPigeonOptions) {
      stream.writeUint8(130);
      const encoded: Object[] = (value as SharedPreferencesPigeonOptions).encode() as Object[];
      return this.writeValue(stream, encoded);
    } else if (value instanceof StringListResult) {
      stream.writeUint8(131);
      const slr: StringListResult = value as StringListResult;
      stream.writeUint8(12);
      this.writeSize(stream, 2);
      this.writeValue(stream, slr.jsonEncodedValue ?? null);
      stream.writeUint8(129);
      stream.writeUint8(4);
      stream.writeInt64(BigInt(slr.type as number), true);
      return stream;
    } else {
      return super.writeValue(stream, value);
    }
    return stream;
  }

  readValueOfType(type: number, buffer: ESObject): Object | null {
    switch (type) {
      case 129: {
        const enumValue: number | null = this.readValue(buffer) as number | null;
        return enumValue;
      }
      case 130: {
        const optionsData: Object[] = this.readValue(buffer) as Object[];
        return SharedPreferencesPigeonOptions.decode(optionsData);
      }
      case 131: {
        const resultData: Object[] = this.readValue(buffer) as Object[];
        return StringListResult.decode(resultData);
      }
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/** 等待异步 handler 的 .then/.catch 微任务队列排空。 */
export async function sleep(ms: number): Promise<void> {
  await new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, ms);
  });
}

const CALL_SETTLE_MS = 30;

/** 以编码字节方式调用注册在 RecordingMessenger 上的通道,返回解码后的回复。 */
export class ChannelCaller {
  public messenger: RecordingMessenger;
  private codec: TestPigeonCodec = new TestPigeonCodec();

  constructor(messenger: RecordingMessenger) {
    this.messenger = messenger;
  }

  has(name: string): boolean {
    return this.messenger.handlers.has(name);
  }

  count(): number {
    return this.messenger.handlers.size;
  }

  async call(name: string, args: Object[]): Promise<ESObject> {
    const handler: BinaryMessageHandler | undefined = this.messenger.handlers.get(name);
    if (handler === undefined) {
      return null;
    }
    const bytes: ArrayBuffer = this.codec.encodeMessage(args as ESObject);
    const recording: RecordingReply = new RecordingReply();
    handler.onMessage(bytes, recording);
    await sleep(CALL_SETTLE_MS);
    if (recording.replied === null) {
      return null;
    }
    return this.codec.decodeMessage(recording.replied);
  }
}

/** SharedPreferencesApi(同步)的可控行为替身。 */
export class FakeSyncApi implements SharedPreferencesApi {
  public removeResult: boolean = true;
  public removeShouldThrow: boolean = false;
  public settersFail: boolean = false;
  public clearResult: boolean = true;
  public getAllResult: Map<string, Object> = new Map<string, Object>();
  public lastKey: string = '';
  public calls: string[] = new Array<string>();

  remove(key: string): boolean {
    this.calls.push('remove');
    this.lastKey = key;
    if (this.removeShouldThrow) {
      throw new FlutterError('remove_failed', 'boom', 'detail');
    }
    return this.removeResult;
  }

  private setterOutcome(): Promise<boolean> {
    if (this.settersFail) {
      return Promise.reject(new Error('setter failed'));
    }
    return Promise.resolve(true);
  }

  setBool(key: string, value: boolean): Promise<boolean> {
    this.calls.push('setBool');
    this.lastKey = key;
    return this.setterOutcome();
  }

  setString(key: string, value: string): Promise<boolean> {
    this.calls.push('setString');
    this.lastKey = key;
    return this.setterOutcome();
  }

  setInt(key: string, value: bigint): Promise<boolean> {
    this.calls.push('setInt');
    this.lastKey = key;
    return this.setterOutcome();
  }

  setDouble(key: string, value: number): Promise<boolean> {
    this.calls.push('setDouble');
    this.lastKey = key;
    return this.setterOutcome();
  }

  setEncodedStringList(key: string, value: string): Promise<boolean> {
    this.calls.push('setEncodedStringList');
    this.lastKey = key;
    return this.setterOutcome();
  }

  setDeprecatedStringList(key: string, value: string[]): Promise<boolean> {
    this.calls.push('setDeprecatedStringList');
    this.lastKey = key;
    return this.setterOutcome();
  }

  clear(prefix: string, allowList: string[] | null): Promise<boolean> {
    this.calls.push('clear');
    this.lastKey = prefix;
    if (this.settersFail) {
      return Promise.reject(new Error('clear failed'));
    }
    return Promise.resolve(this.clearResult);
  }

  getAll(prefix: string, allowList: string[] | null): Promise<Map<string, Object>> {
    this.calls.push('getAll');
    this.lastKey = prefix;
    if (this.settersFail) {
      return Promise.reject(new FlutterError('get_all_failed', 'boom', 'detail'));
    }
    return Promise.resolve(this.getAllResult);
  }

  getCodec(): MessageCodec<Object> {
    return new StandardMessageCodec();
  }

  setup(messenger: BinaryMessenger, api: SharedPreferencesApi): void {
    // 测试中不需要真实的 setup 行为
  }
}

/** SharedPreferencesAsyncApi 的可控行为替身。 */
export class FakeAsyncApi implements SharedPreferencesAsyncApi {
  public fail: boolean = false;
  public nullResult: boolean = false;
  public stringResult: string | null = 'stub-string';
  public boolResult: boolean | null = true;
  public doubleResult: number | null = 1.5;
  public intResult: bigint | null = BigInt(7);
  public platformListResult: string[] | null = new Array<string>('a', 'b');
  public stringListResult: StringListResult | null = new StringListResult('[]');
  public allResult: Map<string, Object> = new Map<string, Object>();
  public keysResult: string[] = new Array<string>('k1');
  public lastKey: string = '';
  public calls: string[] = new Array<string>();

  private outcome(): Promise<void> {
    if (this.fail) {
      return Promise.reject(new FlutterError('async_failed', 'boom', 'detail'));
    }
    return Promise.resolve();
  }

  private rejected<T>(): Promise<T> {
    return Promise.reject(new FlutterError('async_failed', 'boom', 'detail'));
  }

  setBool(key: string, value: boolean, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setBool');
    this.lastKey = key;
    return this.outcome();
  }

  setString(key: string, value: string, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setString');
    this.lastKey = key;
    return this.outcome();
  }

  setInt(key: string, value: bigint, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setInt');
    this.lastKey = key;
    return this.outcome();
  }

  setDouble(key: string, value: number, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setDouble');
    this.lastKey = key;
    return this.outcome();
  }

  setEncodedStringList(key: string, value: string, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setEncodedStringList');
    this.lastKey = key;
    return this.outcome();
  }

  setDeprecatedStringList(key: string, value: string[], options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('setDeprecatedStringList');
    this.lastKey = key;
    return this.outcome();
  }

  getString(key: string, options: SharedPreferencesPigeonOptions): Promise<string | null> {
    this.calls.push('getString');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<string | null>();
    }
    return Promise.resolve(this.stringResult);
  }

  getBool(key: string, options: SharedPreferencesPigeonOptions): Promise<boolean | null> {
    this.calls.push('getBool');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<boolean | null>();
    }
    return Promise.resolve(this.boolResult);
  }

  getDouble(key: string, options: SharedPreferencesPigeonOptions): Promise<number | null> {
    this.calls.push('getDouble');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<number | null>();
    }
    return Promise.resolve(this.doubleResult);
  }

  getInt(key: string, options: SharedPreferencesPigeonOptions): Promise<bigint | null> {
    this.calls.push('getInt');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<bigint | null>();
    }
    return Promise.resolve(this.intResult);
  }

  getPlatformEncodedStringList(key: string, options: SharedPreferencesPigeonOptions): Promise<string[] | null> {
    this.calls.push('getPlatformEncodedStringList');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<string[] | null>();
    }
    return Promise.resolve(this.platformListResult);
  }

  getStringList(key: string, options: SharedPreferencesPigeonOptions): Promise<StringListResult | null> {
    this.calls.push('getStringList');
    this.lastKey = key;
    if (this.fail) {
      return this.rejected<StringListResult | null>();
    }
    return Promise.resolve(this.stringListResult);
  }

  clear(allowList: string[] | null, options: SharedPreferencesPigeonOptions): Promise<void> {
    this.calls.push('clear');
    return this.outcome();
  }

  getAll(allowList: string[] | null, options: SharedPreferencesPigeonOptions): Promise<Map<string, Object>> {
    this.calls.push('getAll');
    if (this.nullResult) {
      return Promise.resolve(null as ESObject as Map<string, Object>);
    }
    if (this.fail) {
      return this.rejected<Map<string, Object>>();
    }
    return Promise.resolve(this.allResult);
  }

  getKeys(allowList: string[] | null, options: SharedPreferencesPigeonOptions): Promise<string[]> {
    this.calls.push('getKeys');
    if (this.nullResult) {
      return Promise.resolve(null as ESObject as string[]);
    }
    if (this.fail) {
      return this.rejected<string[]>();
    }
    return Promise.resolve(this.keysResult);
  }
}

/** FlutterPluginBinding 的替身:只提供插件实际使用的两个方法。 */
export class TestPluginBinding {
  public context: common.Context | null = null;
  public messenger: BinaryMessenger;

  constructor(context: common.Context | null, messenger: BinaryMessenger) {
    this.context = context;
    this.messenger = messenger;
  }

  getApplicationContext(): common.Context {
    return this.context as common.Context;
  }

  getBinaryMessenger(): BinaryMessenger {
    return this.messenger;
  }
}

/** 通过 ESObject 中转,把替身安全地当作 FlutterPluginBinding 传入插件。 */
export function asPluginBinding(binding: TestPluginBinding): ESObject {
  return binding as ESObject;
}
