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
import { SharedPreferencesApi, wrapError } from './Messages';
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

  remove(key: string): boolean {
    try {
      let result = true
      this.preferences?.delete(key,async (err: ESObject) => {
        if (err) {
          Log.w(TAG, "Failed to delete.  message =" + err.message);
          result =  false;
        }
        Log.i(TAG, "Succeeded in deleting.");
        await this.preferences?.flush();
      })
      return result;
    } catch (err) {
      Log.e(TAG, "Failed to delete. " + JSON.stringify(err));
      return false;
    }
  }

  setString(key: string, value: string): Promise<void> {
    if (value.startsWith(LIST_IDENTIFIER)) {
      throw new Error(
        "StorageError: This string cannot be stored as it clashes with special identifier prefixes");
    }
    return this.put(key, value);
  }

  setInt(key: string, value: bigint): Promise<void> {
    return this.put(key, value);
  }

  put(key: string, value: ESObject): Promise<void> {
    try {
      if (this.preferences == null) {
        return new Promise((reject) => {
          reject();
        });
      } else {
        this.preferences.put(key, value);
        return this.preferences.flush();
      }
    } catch(err) {
      Log.w(TAG, "Failed to put value of 'startup'. " + JSON.stringify(err));
      return new Promise((reject) => {
        reject();
      });
    }
  }

  setDouble(key: string, value: number): Promise<void> {
    return this.put(key, value);
  }

  setStringList(key: string, value: string[]): Promise<void> {
    Log.w(TAG, "setStringList :" + value);
    Log.w(TAG, "setStringList encoded:" + (LIST_IDENTIFIER + this.listEncoder.encode(value)));
    return this.put(key, LIST_IDENTIFIER + this.listEncoder.encode(value));
  }

  clear(prefix: string, allowList: string[]): Promise<void> {
    try {
      this.preferences?.getAll().then((value: object) => {
        let allKeys = Object.keys(value);
        for (let key of allKeys) {
          if (key.startsWith(prefix) && (allowList == null || allowList.indexOf(key) != -1)) {
            this.preferences?.delete(key);
          }
        }
        return this.preferences?.flush();
      }).catch((err: ESObject) => {
        Log.w(TAG, "Failed to clear." + JSON.stringify(err));
      });
    } catch (err) {
      Log.w(TAG, "Failed to clear." + JSON.stringify(err));
    }
    return new Promise((reject) => {
      reject();
    })
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

  transformPref(value: Object): Object {
    if (typeof value == "string") {
      let stringValue = (value as string);
      if (stringValue.startsWith(LIST_IDENTIFIER)) {
        return this.listEncoder.decode(stringValue.substring(LIST_IDENTIFIER.length));
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
      return JSON.parse(buf.toString()) as string[];
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

  async getString(key: string, options: SharedPreferencesPigeonOptions): Promise<string | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (typeof value === 'string' && !(value as string).startsWith(LIST_IDENTIFIER)) {
        return value as string;
      }
      return null;
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
      return typeof value === 'boolean' ? value as boolean : null;
    } catch (err) {
      Log.w(TAG, "Failed to getBool: " + JSON.stringify(err));
      return Promise.reject(err);
    }
  }

  async getDouble(key: string, options: SharedPreferencesPigeonOptions): Promise<number | null> {
    try {
      if (this.plugin.preferences == null) {
        return null;
      }
      const value = await this.plugin.preferences.get(key, null) as ExtendedPreferenceValue;
      if (typeof value === 'number') {
        return value as number;
      } else if (typeof value === 'bigint') {
        return Number(value);
      }
      return null;
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
      const value = await this.plugin.preferences.get(key, BigInt(0)) as ExtendedPreferenceValue;
      if (typeof value === 'bigint' || typeof value === 'number') {
        return BigInt(value);
      }
      return null;
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
      if (typeof value === 'string' && (value as string).startsWith(LIST_IDENTIFIER)) {
        return this.plugin.listEncoder.decode((value as string).substring(LIST_IDENTIFIER.length));
      }
      return null;
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

  async setString(key: string, value: string, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.put(key, value);
  }

  async setInt(key: string, value: bigint, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setInt(key, value);
  }

  async setDouble(key: string, value: number, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setDouble(key, value);
  }

  async setStringList(key: string, value: Array<string>, options: SharedPreferencesPigeonOptions): Promise<void> {
    return this.plugin.setStringList(key, value);
  }
}
