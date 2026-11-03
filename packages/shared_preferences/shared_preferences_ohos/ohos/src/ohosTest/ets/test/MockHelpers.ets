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
// Unit test helpers: a recording BinaryMessenger, a reply recorder, a test
// codec sharing the wire format of the PigeonCodec in MessagesAsync.ets, and
// fakes for both the sync and async APIs.

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

/** Records every channel handler registered via setMessageHandler so tests can call them with encoded bytes. */
export class RecordingMessenger implements BinaryMessenger {
  public handlers: Map<string, BinaryMessageHandler> = new Map<string, BinaryMessageHandler>();

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    throw new Error('makeBackgroundTaskQueue is not used in unit tests');
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
    // Tests do not care about messages sent towards Flutter; the channel name is enough.
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

/** Records the raw reply bytes submitted by a handler. */
export class RecordingReply implements BinaryReply {
  public replied: ArrayBuffer | null = null;
  public reply: (reply: ArrayBuffer | null) => void = (data: ArrayBuffer | null): void => {
    this.replied = data;
  };
}

/**
 * A codec with the same wire format (custom type tags 129/130/131) as the
 * internal PigeonCodec in MessagesAsync.ets. Tests use it to encode arguments
 * sent to a registered handler and to decode its replies, so the production
 * PigeonCodec's readValueOfType/writeValue participate end to end.
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

/** Waits for the microtask queues of async handlers' .then/.catch to drain. */
export async function sleep(ms: number): Promise<void> {
  await new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, ms);
  });
}

const CALL_SETTLE_MS = 30;

/** Calls a channel registered on the RecordingMessenger with encoded bytes and returns the decoded reply. */
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

/** Controllable test double for SharedPreferencesApi (sync). */
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
    // No real setup behavior is needed in tests.
  }
}

/** Controllable test double for SharedPreferencesAsyncApi. */
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

/** Test double for FlutterPluginBinding: provides only the two methods the plugin actually uses. */
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

/** Passes the double into the plugin safely as a FlutterPluginBinding via an ESObject round trip. */
export function asPluginBinding(binding: TestPluginBinding): ESObject {
  return binding as ESObject;
}
