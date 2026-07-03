/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import { FlutterError, SharedPreferencesApi, wrapError } from './Messages';
import {
  SharedPreferencesAsyncApi,
  SharedPreferencesPigeonOptions,
  setupSharedPreferencesAsyncApi
} from './MessagesAsync';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import data_preferences from '@ohos.data.preferences'
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import buffer  from '@ohos.buffer';

const TAG = "SharedPreferencesOhosPlugin"
const PREFERENCES_NAME = "FlutterSharedPreferences";
const LIST_IDENTIFIER = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu";
// 与 Android 对齐，增加 BIG_INTEGER_PREFIX 和 DOUBLE_PREFIX 特殊前缀常量
const BIG_INTEGER_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy";
const DOUBLE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu";

export default class SharedPreferencesOhosPlugin implements FlutterPlugin, SharedPreferencesApi {

  preferences: data_preferences.Preferences | null = null;
  listEncoder: ListEncoderImpl;

  getUniqueClassName(): string {
    return "SharedPreferencesOhosPlugin"
  }

  constructor() {
    this.listEncoder = new ListEncoderImpl();
  }

  setup(binaryMessenger: BinaryMessenger, api: SharedPreferencesApi | null): void {
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.remove", this.getCodec());
      Log.d(TAG, 'setup')
      if (api != null) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            try {
              let output = api.remove(keyArg);
              wrapped.push(output);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.getAll", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            Log.d(TAG, 'onMessage reply:' + reply)
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let prefixArg = args[0] as string;
            let allowListArg = args[1] as Array<string>;
            api.getAll(prefixArg, allowListArg).then((res) => {
              wrapped.push(res);
              Log.w(TAG, "getAll res=" + JSON.stringify(res));
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to getAll. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.clear", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            Log.d(TAG, 'onMessage reply:' + reply)
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let prefixArg = args[0] as string;
            let allowListArg = args[1] as Array<string>;
            api.clear(prefixArg, allowListArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to clear. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.setInt", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            let valueArg = BigInt(args[1] as bigint);
            api.setInt(keyArg, valueArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to setInt. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.setString", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            let valueArg = args[1] as string;
            api.setString(keyArg, valueArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to setString. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.setDouble", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            let valueArg = args[1] as number;
            api.setDouble(keyArg, valueArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to setDouble. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.setBool", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            let valueArg = args[1] as boolean;
            api.setBool(keyArg, valueArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to setBool. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, "dev.flutter.pigeon.shared_preferences_ohos.SharedPreferencesApi.setStringList", this.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(msg: Object, reply: Reply<Object>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let keyArg = args[0] as string;
            let valueArg = args[1] as Array<string>;
            api.setStringList(keyArg, valueArg).then(() => {
              wrapped.push(true);
              reply.reply(wrapped)
            }).catch((err: ESObject) => {
              Log.w(TAG, "Failed to setStringList. code =" + err.code +", message =" + err.message);
              let errs = wrapError(err);
              wrapped = errs;
              reply.reply(wrapped)
            })
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
  }

  // 确保删除并持久化后再返回，与 Android commit() 行为一致
  remove(key: string): boolean {
    try {
      if (this.preferences == null) {
        return false;
      }
      this.preferences.deleteSync(key);
      this.preferences.flushSync();
      Log.i(TAG, "Succeeded in deleting key: " + key);
      return true;
    } catch (err) {
      Log.e(TAG, "Failed to delete. " + JSON.stringify(err));
      return false;
    }
  }

  // 与 Android 对齐，增加三种特殊前缀的检查
  setString(key: string, value: string): Promise<void> {
    if (value.startsWith(LIST_IDENTIFIER) ||
        value.startsWith(BIG_INTEGER_PREFIX) ||
        value.startsWith(DOUBLE_PREFIX)) {
      return Promise.reject(new Error(
        "StorageError: This string cannot be stored as it clashes with special identifier prefixes"));
    }
    return this.put(key, value);
  }

  setInt(key: string, value: bigint): Promise<void> {
    return this.put(key, value);
  }

  put(key: string, value: ESObject): Promise<void> {
    try {
      if (this.preferences == null) {
        return Promise.reject(new Error("Preferences not initialized"));
      }
      this.preferences.putSync(key, value);
      return this.preferences.flush();
    } catch(err) {
      Log.w(TAG, "Failed to put value of 'startup'. " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  // 读取时通过 transformPref() 解码还原为 double
  setDouble(key: string, value: number): Promise<void> {
    return this.put(key, DOUBLE_PREFIX + value.toString());
  }

  setStringList(key: string, value: string[]): Promise<void> {
    Log.w(TAG, "setStringList :" + value);
    Log.w(TAG, "setStringList encoded:" + (LIST_IDENTIFIER + this.listEncoder.encode(value)));
    return this.put(key, LIST_IDENTIFIER + this.listEncoder.encode(value));
  }

  // 等待所有删除和 flush 完成后再返回，与 Android commit() 行为一致
  async clear(prefix: string, allowList: string[]): Promise<void> {
    try {
      if (this.preferences == null) {
        return Promise.reject(new Error("Preferences not initialized"));
      }
      const allData = await this.preferences.getAll() as Record<string, ESObject>;
      const allKeys = Object.keys(allData);
      for (let key of allKeys) {
        if (key.startsWith(prefix) && (allowList == null || allowList.indexOf(key) != -1)) {
          this.preferences.deleteSync(key);
        }
      }
      await this.preferences.flush();
    } catch (err) {
      Log.w(TAG, "Failed to clear." + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  filterData(value: [string, Object], prefix: string, allowList: string[]): Map<string, Object> {
    let allVal = Object.entries(value);
    let filteredPrefs = new Map<string, Object>();
    for (let val of allVal) {
      let key = val[0];
      let v = val[1];
      if (key.startsWith(prefix) && (allowList == null || allowList.indexOf(key) != -1)) {
        filteredPrefs.set(key, this.transformPref(v));
        Log.w(TAG, "filterData00：key:" + key + " val:" + (this.transformPref(v)));
      }
    }
    Log.w(TAG, "filterData1：" + JSON.stringify(filteredPrefs));
    return filteredPrefs;
  }

  async getAll(prefix: string, allowList: Array<string>): Promise<Object> {
    try {
      let res = new Map<string, Object>();
      if (this.preferences == null) {
        return new Promise((reject) => {
          reject("Failed to getAll");
        })
      }
      await this.preferences.getAll().then((obj: Object) => {
        res = this.filterData(obj as [string, ESObject], prefix, allowList);
      })
      return new Promise((resolve) => {
        resolve(res);
      })
    } catch (err) {
      Log.w(TAG, "Failed to excute getAll." + JSON.stringify(err));
      return new Promise((reject) => {
        reject("Failed to getAll");
      })
    }
  }

  getCodec(): MessageCodec<Object> {
    return new StandardMessageCodec();
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    try {
      this.preferences = data_preferences.getPreferencesSync(binding.getApplicationContext(), { name: PREFERENCES_NAME });
 	    Log.i(TAG, "Succeeded in getting preferences.");
    } catch(err) {
      Log.w(TAG, "Failed to get preferences."+ JSON.stringify(err));
    }
    this.setup(binding.getBinaryMessenger(), this);
    setupSharedPreferencesAsyncApi(binding.getBinaryMessenger(), new SharedPreferencesAsyncApiImpl(this));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    try {
      let promise = this.preferences?.flush();
      promise?.then(() => {
        Log.i(TAG, "Succeeded in flushing.");
      }).catch((err: ESObject) => {
        Log.w(TAG, "Failed to flush." + JSON.stringify(err));
      })
    } catch (err) {
      Log.w(TAG, "Failed to flush." + JSON.stringify(err));
    }
    this.setup(binding.getBinaryMessenger(), null);
    setupSharedPreferencesAsyncApi(binding.getBinaryMessenger(), null);
  }

  setBool(key: string, value: boolean): Promise<void> {
    return this.put(key, value)
  }

  // 增加 DOUBLE_PREFIX 和 BIG_INTEGER_PREFIX 的解码逻辑
  // 与 Android Legacy 的 transformPref() 对齐，确保读取时能正确还原编码值
  transformPref(value: Object): Object {
    if (typeof value == "string") {
      let stringValue = (value as string);
      if (stringValue.startsWith(LIST_IDENTIFIER)) {
        return this.listEncoder.decode(stringValue.substring(LIST_IDENTIFIER.length));
      } else if (stringValue.startsWith(DOUBLE_PREFIX)) {
        // 解码 DOUBLE_PREFIX 编码的 double 值
        return parseFloat(stringValue.substring(DOUBLE_PREFIX.length));
      } else if (stringValue.startsWith(BIG_INTEGER_PREFIX)) {
        // 解码 BIG_INTEGER_PREFIX 编码的 BigInteger 值（确认无跨平台共享场景）
        let encoded = stringValue.substring(BIG_INTEGER_PREFIX.length);
        return BigInt(encoded);
      }
    }
    if (typeof value == "bigint") {
      return BigInt(value);
    }
    return value;
  }
}

// Extended type definition to handle all OHOS ValueType values
type ExtendedPreferenceValue = string | number | boolean | bigint | object | null;

// ListEncoder implementation
interface ListEncoder {
  encode(list: string[]): string;
  decode(encoded: string): string[];
}

class ListEncoderImpl implements ListEncoder {
  encode(list: string[]): string {
    try {
      const jsonList = JSON.stringify(list);
      return buffer.from(jsonList).toString('base64');
    } catch (err) {
      Log.e(TAG, "Failed encode." + JSON.stringify(err));
    }
    return '';
  }

  decode(encoded: string): string[] {
    try {
      const buf = buffer.from(encoded, 'base64');
      const parsed = JSON.parse(buf.toString()) as string[];
      // Return a mutable array (JSON.parse returns fixed-length array)
      const result: string[] = [];
      for (let i = 0; i < parsed.length; i++) {
        result.push(parsed[i]);
      }
      return result;
    } catch (err) {
      Log.e(TAG, "Failed decode." + JSON.stringify(err));
      return [];
    }
  }
}

// Async API implementation class
class SharedPreferencesAsyncApiImpl implements SharedPreferencesAsyncApi {
  private plugin: SharedPreferencesOhosPlugin;

  constructor(plugin: SharedPreferencesOhosPlugin) {
    this.plugin = plugin;
  }

  private typeMismatch(key: string, expectedType: string, actualValue: ExtendedPreferenceValue): FlutterError {
    const actualType = actualValue === null ? 'null' : typeof actualValue;
    return new FlutterError(
      'ClassCastException',
      `Expected ${expectedType} for key "${key}", but found ${actualType}.`,
      `key=${key}, expectedType=${expectedType}, actualType=${actualType}`
    );
  }

  // 读取字符串时需排除所有特殊前缀编码的值（LIST/DOUBLE/BIG_INTEGER），
  // 这些值不应作为普通字符串返回，而应触发类型不匹配错误
  async getString(key: string, options: SharedPreferencesPigeonOptions): Promise<string | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (value == null) {
        return null;
      }
      if (typeof value === 'string' &&
          !(value as string).startsWith(LIST_IDENTIFIER) &&
          !(value as string).startsWith(DOUBLE_PREFIX) &&
          !(value as string).startsWith(BIG_INTEGER_PREFIX)) {
        return value as string;
      }
      return Promise.reject(this.typeMismatch(key, 'string', value));
    } catch (err) {
      Log.w(TAG, "Failed to getString: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getBool(key: string, options: SharedPreferencesPigeonOptions): Promise<boolean | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (value == null) {
        return null;
      }
      if (typeof value === 'boolean') {
        return value as boolean;
      }
      return Promise.reject(this.typeMismatch(key, 'boolean', value));
    } catch (err) {
      Log.w(TAG, "Failed to getBool: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  // 增加 DOUBLE_PREFIX 字符串编码值的解码，与 Legacy setDouble 编码方式保持一致
  async getDouble(key: string, options: SharedPreferencesPigeonOptions): Promise<number | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (value == null) {
        return null;
      }
      if (typeof value === 'number') {
        return value as number;
      } else if (typeof value === 'string' && (value as string).startsWith(DOUBLE_PREFIX)) {
        // 解码 DOUBLE_PREFIX 编码的 double 值
        return parseFloat((value as string).substring(DOUBLE_PREFIX.length));
      } else if (typeof value === 'bigint') {
        return Number(value);
      }
      return Promise.reject(this.typeMismatch(key, 'number', value));
    } catch (err) {
      Log.w(TAG, "Failed to getDouble: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getInt(key: string, options: SharedPreferencesPigeonOptions): Promise<bigint | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (value == null) {
        return null;
      }
      if (typeof value === 'bigint' || typeof value === 'number') {
        return BigInt(value);
      }
      return Promise.reject(this.typeMismatch(key, 'int', value));
    } catch (err) {
      Log.w(TAG, "Failed to getInt: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getStringList(key: string, options: SharedPreferencesPigeonOptions): Promise<Array<string> | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (value == null) {
        return null;
      }
      if (typeof value === 'string' && (value as string).startsWith(LIST_IDENTIFIER)) {
        return this.plugin.listEncoder.decode((value as string).substring(LIST_IDENTIFIER.length));
      }
      return Promise.reject(this.typeMismatch(key, 'StringList', value));
    } catch (err) {
      Log.w(TAG, "Failed to getStringList: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async clear(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<void> {
    try {
      if (this.plugin.preferences == null) {
        return Promise.reject(new Error("Preferences not initialized"));
      }
      const allData = await this.plugin.preferences.getAll() as Record<string, ExtendedPreferenceValue>;
      const allKeys = Object.keys(allData);
      const deletePromises: Promise<void>[] = [];
      for (let key of allKeys) {
        if (allowList == null || allowList.indexOf(key) != -1) {
          deletePromises.push(new Promise<void>((resolve, reject) => {
            this.plugin.preferences?.delete(key, (err: ESObject) => {
              if (err) {
                reject(err);
              } else {
                resolve();
              }
            });
          }));
        }
      }
      await Promise.all(deletePromises);
      return this.plugin.preferences.flush();
    } catch (err) {
      Log.w(TAG, "Failed to clear: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getAll(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<Map<string, Object>> {
    try {
      if (this.plugin.preferences == null) {
        return new Map<string, Object>();
      }
      const allData = await this.plugin.preferences.getAll() as Record<string, ExtendedPreferenceValue>;
      const result = new Map<string, Object>();
      Object.keys(allData).forEach((key: string) => {
        const value = allData[key];
        if (this.preferencesFilter(key, value, allowList) && value != null) {
          const transformedValue = this.plugin.transformPref(value as Object);
          if (transformedValue != null) {
            result.set(key, transformedValue);
          }
        }
      });
      return result;
    } catch (err) {
      Log.w(TAG, "Failed to getAll: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getKeys(allowList: Array<string> | null, options: SharedPreferencesPigeonOptions): Promise<Array<string>> {
    try {
      if (this.plugin.preferences == null) {
        return [];
      }
      const allData = await this.plugin.preferences.getAll() as Record<string, ExtendedPreferenceValue>;
      const allKeys = Object.keys(allData);
      return allKeys.filter((key: string) => {
        const value = allData[key];
        return this.preferencesFilter(key, value, allowList);
      });
    } catch (err) {
      Log.w(TAG, "Failed to getKeys: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  private preferencesFilter(key: string, value: ExtendedPreferenceValue, allowList: Array<string> | null): boolean {
    if (allowList == null) {
      return typeof value === 'boolean' || typeof value === 'bigint' ||
             typeof value === 'string' || typeof value === 'number';
    }
    return allowList.indexOf(key) !== -1;
  }

  // Async setter methods
  async setBool(key: string, value: boolean, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setBool(key, value);
  }

  // 复用 Legacy setString 的前缀检查逻辑，防止通过 Async API 存入特殊前缀字符串
  async setString(key: string, value: string, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setString(key, value);
  }

  async setInt(key: string, value: bigint, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setInt(key, value);
  }

  // Async API 对应 Android DataStore，直接存储 number，不使用 DOUBLE_PREFIX 编码
  async setDouble(key: string, value: number, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.put(key, value);
  }

  async setStringList(key: string, value: Array<string>, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setStringList(key, value);
  }
}
