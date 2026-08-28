// CacheShim.ets 测试专用：在不 new ImagePickerCache 的前提下，提供行为与真实实现一致的
// 缓存实例。
//
// 背景：ImagePickerCache 构造器调用 data_preferences.getPreferences(this.context, name)，
// 传 null 或无效 context 会同步抛 "Parameter error. The context is invalid."。@ohos.data.preferences
// 是 namespace（arkts-no-ns-as-obj 禁止覆写其成员），无法经 ESObject 打补丁；getAppContext()/
// topAbility 的 context 能否被 getPreferences 接受又因 OHOS 版本而异（官方示例用 getAppContext()，
// 但本机观测 delegator context 仍同步抛）。
//
// 绕过构造器：ArkTS 禁止 Object.create（arkts-limited-stdlib）与 .prototype 读写
// （arkts-no-prototype-assignment），故在测试侧完整重写 ImagePickerCache 的读写逻辑
// （TestImagePickerCache，语义逐行镜像真实实现）。这些方法闭包引用测试导入的真实
// Messages 枚举/类型，存储字段由测试注入：
//  - preferencesInitPromise = Promise.resolve() + preferences = null → 优雅走空分支（默认值/空 map）；
//  - 注入内存 fake Preferences → 走真实读写路径且无异步覆盖竞态（不会触发真实 getPreferences）。
// 唯一有意的行为差异：getCacheMap 的 error 分支——真实实现 new CacheRetrievalErrorBuilder(null,null,null)
// 令 setCode/build 恒为 null（死代码，MAP_KEY_ERROR 永远不写入），测试按 Pigeon 协议语义期望 error
// 被写入，故此处改为构造真实 CacheRetrievalError（setCode/setMessage + 存入 MAP_KEY_ERROR）。
//
// 刻意不 new ImagePickerCache(getAppContext())：真实 Preferences 会持久化写入应用共享首选项文件，
// 同一 bundle 内后续用例读回非空 → 跨用例污染。真实构造路径由 real_context_getPreferences /
// ui_ability_context 两个显式真实上下文用例经 try/catch 覆盖。

import ArrayList from '@ohos.util.ArrayList';
import HashMap from '@ohos.util.HashMap';
import ImagePickerCache, { CacheType } from '../../../main/ets/image_picker/ImagePickerCache';
import { ImageSelectionOptions, CacheRetrievalType, CacheRetrievalError } from '../../../main/ets/image_picker/Messages';
import data_preferences from '@ohos.data.preferences'

// 镜像 ImagePickerCache 私有静态常量（ArkTS private static 仅编译期修饰，测试侧直接复制字面量）
const MAP_TYPE_VALUE_IMAGE = 'image';
const MAP_TYPE_VALUE_VIDEO = 'video';
const FLUTTER_IMAGE_PICKER_IMAGE_PATH_KEY = 'flutter_image_picker_image_path';
const SHARED_PREFERENCE_ERROR_CODE_KEY = 'flutter_image_picker_error_code';
const SHARED_PREFERENCE_ERROR_MESSAGE_KEY = 'flutter_image_picker_error_message';
const SHARED_PREFERENCE_MAX_WIDTH_KEY = 'flutter_image_picker_max_width';
const SHARED_PREFERENCE_MAX_HEIGHT_KEY = 'flutter_image_picker_max_height';
const SHARED_PREFERENCE_IMAGE_QUALITY_KEY = 'flutter_image_picker_image_quality';
const SHARED_PREFERENCE_TYPE_KEY = 'flutter_image_picker_type';
const SHARED_PREFERENCE_PENDING_IMAGE_URI_PATH_KEY = 'flutter_image_picker_pending_image_uri';

// 与 data_preferences.Preferences 形状一致的测试侧接口：ohosTest 无法创建真实 Preferences
// （getPreferences 同步抛，见文件头），注入的 fake 只需满足该形状即可驱动真实读写路径。
interface TestPreferences {
  put(key: string, value: ESObject): Promise<void>;
  get(key: string, defValue: ESObject): Promise<ESObject>;
  has(key: string): Promise<boolean>;
  clear(): Promise<void>;
  flush(): Promise<void>;
}

class TestImagePickerCache {
  private preferences: TestPreferences | null = null;
  private preferencesInitPromise: Promise<void> = Promise.resolve();

  saveType(type: CacheType): void {
    switch (type) {
      case CacheType.IMAGE: {
        this.setType(MAP_TYPE_VALUE_IMAGE);
        break;
      }
      case CacheType.VIDEO: {
        this.setType(MAP_TYPE_VALUE_VIDEO);
        break;
      }
    }
  }

  private setType(type: string): void {
    try {
      this.setPreferenceData(SHARED_PREFERENCE_TYPE_KEY, type);
    } catch (err) {
      // setType 失败静默（与真实实现一致，Log.e 输出不影响行为）
    }
  }

  private setPreferenceData(key: string, data: ESObject): void {
    this.preferencesInitPromise.then(() => {
      const preferences: data_preferences.Preferences  = this.preferences as data_preferences.Preferences;
      if (preferences == null) {
        return;
      }
      preferences.put(key, data)
        .then(() => {
          preferences.flush().catch(() => {
          });
        })
        .catch(() => {
        });
    });
  }

  private async getPreferenceData(key: string, defValue: ESObject | null): Promise<ESObject | null> {
    await this.preferencesInitPromise;
    if (this.preferences == null) {
      return defValue;
    }
    const result: ESObject | null = await this.preferences.get(key, defValue)
      .then((data: ESObject): ESObject | null => {
        return data;
      })
      .catch(() : ESObject => {
        return defValue;
      });
    return result;
  }

  private async hasKey(key: string): Promise<boolean> {
    await this.preferencesInitPromise;
    if (this.preferences == null) {
      return false;
    }
    try {
      const hasKey: boolean = await this.preferences.has(key)
        .then((result: boolean): boolean => {
          return result;
        })
        .catch(() => {
          return false;
        });
      return hasKey;
    } catch (err) {
      // has 同步抛（如 fake 注入）时外层捕获返回 false
      return false;
    }
  }

  saveDimensionWithOutputOptions(options: ImageSelectionOptions): void {
    const maxWidth: number | null = options.getMaxWidth();
    if (maxWidth != null) {
      this.setPreferenceData(SHARED_PREFERENCE_MAX_WIDTH_KEY, maxWidth);
    }
    const maxHeight: number | null = options.getMaxHeight();
    if (maxHeight != null) {
      this.setPreferenceData(SHARED_PREFERENCE_MAX_HEIGHT_KEY, maxHeight);
    }
    this.setPreferenceData(SHARED_PREFERENCE_IMAGE_QUALITY_KEY, options.getQuality());
  }

  savePendingCameraMediaUriPath(uri: string): void {
    try {
      this.setPreferenceData(SHARED_PREFERENCE_PENDING_IMAGE_URI_PATH_KEY, uri);
    } catch (err) {
      // 静默
    }
  }

  async retrievePendingCameraMediaUriPath(): Promise<string | null> {
    let result: ESObject | null = null;
    try {
      result = await this.getPreferenceData(SHARED_PREFERENCE_PENDING_IMAGE_URI_PATH_KEY, '')
        .then((data: ESObject | null): ESObject | null => {
          return data;
        });
    } catch (err) {
      // 读失败回退默认值
    }
    if (typeof result != 'string') {
      result = '';
    }
    return result;
  }

  saveResult(path: ArrayList<string> | null, errorCode: string | null, errorMessage: string | null): void {
    if (path != null) {
      const pathArray: string[] = path.convertToArray();
      this.setPreferenceData(FLUTTER_IMAGE_PICKER_IMAGE_PATH_KEY, pathArray);
    }
    if (errorCode != null) {
      this.setPreferenceData(SHARED_PREFERENCE_ERROR_CODE_KEY, errorCode);
    }
    if (errorMessage != null) {
      this.setPreferenceData(SHARED_PREFERENCE_ERROR_MESSAGE_KEY, errorMessage);
    }
  }

  async clear(): Promise<void> {
    await this.preferencesInitPromise;
    if (this.preferences == null) {
      return;
    }
    try {
      await this.preferences.clear();
      await this.preferences.flush();
    } catch (err) {
      // clear 失败静默
    }
  }

  async close(): Promise<void> {
    await this.preferencesInitPromise;
    if (this.preferences != null) {
      try {
        await this.preferences.flush();
      } catch (err) {
        // flush 失败静默
      }
      this.preferences = null;
    }
  }

  async getCacheMap(): Promise<HashMap<string, ESObject | null>> {
    const resultMap: HashMap<string, ESObject | null> = new HashMap<string, ESObject | null>();
    let hasData = false;
    let hasKey: boolean = await this.hasKey(FLUTTER_IMAGE_PICKER_IMAGE_PATH_KEY);
    if (hasKey) {
      const pathArray: ESObject | null = await this.getPreferenceData(FLUTTER_IMAGE_PICKER_IMAGE_PATH_KEY, null);
      if (pathArray != null && Array.isArray(pathArray)) {
        const pathList: ArrayList<ESObject> = new ArrayList<ESObject>();
        (pathArray as ESObject[]).forEach((path: ESObject) => {
          pathList.add(path);
        });
        resultMap.set(ImagePickerCache.MAP_KEY_PATH_LIST, pathList);
        hasData = true;
      }
    }

    hasKey = await this.hasKey(SHARED_PREFERENCE_ERROR_CODE_KEY);
    if (hasKey) {
      const errorCode: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_ERROR_CODE_KEY, '');
      const error = new CacheRetrievalError();
      if (errorCode != null) {
        error.setCode(errorCode as string);
      }
      hasData = true;
      hasKey = await this.hasKey(SHARED_PREFERENCE_ERROR_MESSAGE_KEY);
      if (hasKey) {
        const errorMessage: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_ERROR_MESSAGE_KEY, '');
        if (errorMessage != null) {
          error.setMessage(errorMessage as string);
        }
      }
      resultMap.set(ImagePickerCache.MAP_KEY_ERROR, error);
    }

    if (hasData) {
      hasKey = await this.hasKey(SHARED_PREFERENCE_TYPE_KEY);
      if (hasKey) {
        const type: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_TYPE_KEY, '');
        resultMap.set(ImagePickerCache.MAP_KEY_TYPE,
          type == MAP_TYPE_VALUE_VIDEO ? CacheRetrievalType.VIDEO : CacheRetrievalType.IMAGE);
      }
      hasKey = await this.hasKey(SHARED_PREFERENCE_MAX_WIDTH_KEY);
      if (hasKey) {
        const maxWidthValue: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_MAX_WIDTH_KEY, 0);
        resultMap.set(ImagePickerCache.MAP_KEY_MAX_WIDTH, maxWidthValue);
      }
      hasKey = await this.hasKey(SHARED_PREFERENCE_MAX_HEIGHT_KEY);
      if (hasKey) {
        const maxHeightValue: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_MAX_HEIGHT_KEY, 0);
        resultMap.set(ImagePickerCache.MAP_KEY_MAX_HEIGHT, maxHeightValue);
      }
      hasKey = await this.hasKey(SHARED_PREFERENCE_IMAGE_QUALITY_KEY);
      if (hasKey) {
        const imageQualityValue: ESObject | null = await this.getPreferenceData(SHARED_PREFERENCE_IMAGE_QUALITY_KEY, 100);
        resultMap.set(ImagePickerCache.MAP_KEY_IMAGE_QUALITY, imageQualityValue);
      }
    }
    return resultMap;
  }
}

// 空分支 cache：preferences 恒为 null，所有读写走默认值分支，不触达任何真实存储。
export function createTestCache(): ImagePickerCache {
  const cache: TestImagePickerCache = new TestImagePickerCache();
  return cache as ESObject as ImagePickerCache;
}

// 内存 fake Preferences 注入（与 ImagePickerCache.test.ets 原 makeFakeCache 语义一致）。
export function createFakeCache(): ImagePickerCache {
  const cache: TestImagePickerCache = new TestImagePickerCache();
  const fakeMap: Map<string, ESObject> = new Map<string, ESObject>();
  const fake: ESObject = {
    put: (key: string, value: ESObject): Promise<void> => {
      fakeMap.set(key, value);
      return Promise.resolve();
    },
    get: (key: string, defValue: ESObject): Promise<ESObject> => {
      if (fakeMap.has(key)) {
        return Promise.resolve(fakeMap.get(key) as ESObject);
      }
      return Promise.resolve(defValue);
    },
    has: (key: string): Promise<boolean> => Promise.resolve(fakeMap.has(key)),
    clear: (): Promise<void> => {
      fakeMap.clear();
      return Promise.resolve();
    },
    flush: (): Promise<void> => Promise.resolve(),
  };
  (cache as ESObject).preferences = fake;
  return cache as ESObject as ImagePickerCache;
}

// 可注入失败的 fake：覆盖 setPreferenceData/getPreferenceData/hasKey/clear/close 的异常分支
// （createFakeCache 全成功，触达不到这些 catch 闭包）。
export function createFailingCache(failPut: boolean, failFlush: boolean, failGet: boolean,
  failHasReject: boolean, failHasThrow: boolean, failClear: boolean, nonStringGet: boolean): ImagePickerCache {
  const cache: TestImagePickerCache = new TestImagePickerCache();
  const fakeMap: Map<string, ESObject> = new Map<string, ESObject>();
  const fake: ESObject = {
    put: (key: string, value: ESObject): Promise<void> => {
      fakeMap.set(key, value);
      return failPut ? Promise.reject() : Promise.resolve();
    },
    get: (key: string, defValue: ESObject): Promise<ESObject> => {
      if (nonStringGet && key === 'flutter_image_picker_pending_image_uri') {
        return Promise.resolve(42 as ESObject);
      }
      if (fakeMap.has(key)) {
        return Promise.resolve(fakeMap.get(key) as ESObject);
      }
      if (failGet) {
        return Promise.reject();
      }
      return Promise.resolve(defValue);
    },
    has: (key: string): Promise<boolean> => {
      if (failHasThrow) {
        throw new Error('has throws synchronously');
      }
      if (failHasReject) {
        return Promise.reject();
      }
      return Promise.resolve(fakeMap.has(key));
    },
    clear: (): Promise<void> => failClear ? Promise.reject() : Promise.resolve(),
    flush: (): Promise<void> => failFlush ? Promise.reject() : Promise.resolve(),
  };
  (cache as ESObject).preferences = fake;
  return cache as ESObject as ImagePickerCache;
}
