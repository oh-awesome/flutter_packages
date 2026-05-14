/*
* Copyright (c) 2026 Huawei Device Co., Ltd. All rights reserved.
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE_HW file.
*/

// Native counterpart of lib/src/messages_async.g.dart (Pigeon SharedPreferencesAsyncApi).
// Hand-translated from Android MessagesAsync.g.kt (Pigeon v16.0.5) to ArkTS.
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { wrapError } from './Messages';

const TAG = 'MessagesAsync';

/** Mirror of Dart `SharedPreferencesPigeonOptions { String? fileKey }`. */
export class SharedPreferencesPigeonOptions {
  fileKey: string | null = null;

  static decode(list: Array<Object>): SharedPreferencesPigeonOptions {
    const o = new SharedPreferencesPigeonOptions();
    o.fileKey = (list[0] as string | null);
    return o;
  }

  encode(): Array<Object | null> {
    return [this.fileKey];
  }
}

/** Codec mirroring Dart `_SharedPreferencesAsyncApiCodec` (only custom tag 128). */
class SharedPreferencesAsyncApiCodec extends StandardMessageCodec {
  writeValue(stream: ESObject, value: ESObject): void {
    if (value instanceof SharedPreferencesPigeonOptions) {
      (stream as ESObject).writeByte(128);
      super.writeValue(stream, (value as SharedPreferencesPigeonOptions).encode());
    } else {
      super.writeValue(stream, value);
    }
  }

  readValueOfType(type: number, buffer: ESObject): ESObject {
    if (type === 128) {
      return SharedPreferencesPigeonOptions.decode(super.readValue(buffer) as Array<Object>);
    }
    return super.readValueOfType(type, buffer);
  }
}

/** Async API mirroring Dart `SharedPreferencesAsyncApi`. All methods return Promises. */
export interface SharedPreferencesAsyncApi {
  setBool(key: string, value: boolean, options: SharedPreferencesPigeonOptions): Promise<void>;
  setString(key: string, value: string, options: SharedPreferencesPigeonOptions): Promise<void>;
  setInt(key: string, value: bigint, options: SharedPreferencesPigeonOptions): Promise<void>;
  setDouble(key: string, value: number, options: SharedPreferencesPigeonOptions): Promise<void>;
  setStringList(key: string, value: Array<string>, options: SharedPreferencesPigeonOptions): Promise<void>;
  getString(key: string, options: SharedPreferencesPigeonOptions): Promise<string | null>;
  getBool(key: string, options: SharedPreferencesPigeonOptions): Promise<boolean | null>;
  getDouble(key: string, options: SharedPreferencesPigeonOptions): Promise<number | null>;
  getInt(key: string, options: SharedPreferencesPigeonOptions): Promise<bigint | null>;
  getStringList(key: string, options: SharedPreferencesPigeonOptions): Promise<Array<string> | null>;
  clear(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<void>;
  getAll(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<Map<string, Object>>;
  getKeys(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<Array<string>>;
}

const ASYNC_CODEC: MessageCodec<Object> = new SharedPreferencesAsyncApiCodec() as MessageCodec<Object>;

/**
 * Sets up all 13 async Pigeon channels backed by `api`.
 * Mirrors Android `SharedPreferencesAsyncApi.setUp()` structure.
 */
export function setupSharedPreferencesAsyncApi(
    messenger: BinaryMessenger, api: SharedPreferencesAsyncApi | null): void {
  // setBool
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.setBool',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const valueArg = args[1] as boolean;
          const optionsArg = args[2] as SharedPreferencesPigeonOptions;
          api.setBool(keyArg, valueArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to setBool. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // setString
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.setString',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const valueArg = args[1] as string;
          const optionsArg = args[2] as SharedPreferencesPigeonOptions;
          api.setString(keyArg, valueArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to setString. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // setInt
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.setInt',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const valueArg = BigInt(args[1] as bigint);
          const optionsArg = args[2] as SharedPreferencesPigeonOptions;
          api.setInt(keyArg, valueArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to setInt. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // setDouble
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.setDouble',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const valueArg = args[1] as number;
          const optionsArg = args[2] as SharedPreferencesPigeonOptions;
          api.setDouble(keyArg, valueArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to setDouble. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // setStringList
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.setStringList',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const valueArg = args[1] as Array<string>;
          const optionsArg = args[2] as SharedPreferencesPigeonOptions;
          api.setStringList(keyArg, valueArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to setStringList. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getString
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getString',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getString(keyArg, optionsArg)
            .then((result: string | null) => { reply.reply([result]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getString. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getBool
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getBool',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getBool(keyArg, optionsArg)
            .then((result: boolean | null) => { reply.reply([result]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getBool. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getDouble
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getDouble',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getDouble(keyArg, optionsArg)
            .then((result: number | null) => { reply.reply([result]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getDouble. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getInt
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getInt',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getInt(keyArg, optionsArg)
            .then((result: bigint | null) => { reply.reply([result]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getInt. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getStringList
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getStringList',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const keyArg = args[0] as string;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getStringList(keyArg, optionsArg)
            .then((result: Array<string> | null) => { reply.reply([result]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getStringList. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // clear
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.clear',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const allowListArg = args[0] as Array<string> | null;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.clear(allowListArg, optionsArg)
            .then(() => { reply.reply([null]); })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to clear. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getAll
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getAll',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const allowListArg = args[0] as Array<string> | null;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getAll(allowListArg, optionsArg)
            .then((result: Map<string, Object>) => {
              if (result == null) {
                reply.reply(wrapError(new Error('Host platform returned null value for non-null return value.')));
              } else {
                reply.reply([result]);
              }
            })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getAll. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }

  // getKeys
  {
    const channel = new BasicMessageChannel<Object>(
      messenger,
      'dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesAsyncApi.getKeys',
      ASYNC_CODEC);
    if (api != null) {
      channel.setMessageHandler({
        onMessage(msg: Object, reply: Reply<Object>): void {
          const args = msg as Array<Object>;
          const allowListArg = args[0] as Array<string> | null;
          const optionsArg = args[1] as SharedPreferencesPigeonOptions;
          api.getKeys(allowListArg, optionsArg)
            .then((result: Array<string>) => {
              if (result == null) {
                reply.reply(wrapError(new Error('Host platform returned null value for non-null return value.')));
              } else {
                reply.reply([result]);
              }
            })
            .catch((err: Error) => {
              Log.w(TAG, 'Failed to getKeys. message =' + err.message);
              reply.reply(wrapError(err));
            });
        }
      });
    } else {
      channel.setMessageHandler(null);
    }
  }
}
