// CacheShim.ets is test-only: it provides cache instances whose behavior matches the real
// implementation without ever new-ing ImagePickerCache.
//
// Background: the ImagePickerCache constructor calls
// data_preferences.getPreferences(this.context, name); passing a null or invalid context throws
// synchronously with "Parameter error. The context is invalid.". @ohos.data.preferences is a
// namespace (arkts-no-ns-as-obj forbids overriding its members) and cannot be patched via ESObject;
// whether getAppContext()/topAbility's context is accepted by getPreferences varies with the OHOS
// version (official examples use getAppContext(), but on this machine the delegator context was
// still observed to throw synchronously).
//
// Bypassing the constructor: ArkTS forbids Object.create (arkts-limited-stdlib) and .prototype
// reads/writes (arkts-no-prototype-assignment), so the test side fully reimplements
// ImagePickerCache's read/write logic (TestImagePickerCache, mirroring the real implementation
// line by line). These methods' closures reference the real Messages enums/types imported by the
// test; the storage fields are injected by the test:
//  - preferencesInitPromise = Promise.resolve() + preferences = null → gracefully takes the empty
//    branches (defaults/empty map);
//  - injecting an in-memory fake Preferences → takes the real read/write path with no async
//    overwrite race (never triggers real getPreferences).
// The single intentional behavioral difference: getCacheMap's error branch — the real
// implementation does new CacheRetrievalErrorBuilder(null,null,null), leaving setCode/build always
// null (dead code; MAP_KEY_ERROR is never written), while tests, per Pigeon protocol semantics,
// expect error to be written, so this builds a real CacheRetrievalError instead
// (setCode/setMessage + stored under MAP_KEY_ERROR).
//
// Deliberately not new-ing ImagePickerCache(getAppContext()): a real Preferences would persist
// writes into the app's shared preferences file, and later cases in the same bundle would read
// back non-empty values → cross-test pollution. The real construction path is covered, via
// try/catch, by the two explicit real-context cases real_context_getPreferences and
// ui_ability_context.

import ArrayList from '@ohos.util.ArrayList';
import HashMap from '@ohos.util.HashMap';
import ImagePickerCache, { CacheType } from '../../../main/ets/image_picker/ImagePickerCache';
import { ImageSelectionOptions, CacheRetrievalType,
  CacheRetrievalError } from '../../../main/ets/image_picker/Messages';
import data_preferences from '@ohos.data.preferences'

// Mirror of ImagePickerCache's private static constants (ArkTS private static is compile-time only;
// the test side copies the literals directly)
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

// Test-side interface matching the shape of data_preferences.Preferences: ohosTest cannot create
// a real Preferences (getPreferences throws synchronously, see the file header); an injected fake
// only needs to satisfy this shape to drive the real read/write path.
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
      // setType failures are silent (same as the real implementation; Log.e output does not affect behavior)
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
      // When has throws synchronously (e.g. fake injection), the outer catch returns false
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
      // Silent
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
      // Read failure falls back to the default value
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
      // clear failures are silent
    }
  }

  async close(): Promise<void> {
    await this.preferencesInitPromise;
    if (this.preferences != null) {
      try {
        await this.preferences.flush();
      } catch (err) {
        // flush failures are silent
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
        const imageQualityValue: ESObject | null =
          await this.getPreferenceData(SHARED_PREFERENCE_IMAGE_QUALITY_KEY, 100);
        resultMap.set(ImagePickerCache.MAP_KEY_IMAGE_QUALITY, imageQualityValue);
      }
    }
    return resultMap;
  }
}

// Empty-branch cache: preferences is always null, all reads/writes take the default-value branches,
// and no real storage is touched.
export function createTestCache(): ImagePickerCache {
  const cache: TestImagePickerCache = new TestImagePickerCache();
  return cache as ESObject as ImagePickerCache;
}

// In-memory fake Preferences injection (semantically identical to the original makeFakeCache in
// ImagePickerCache.test.ets).
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

// Fail-injectable fake: covers the exception branches of
// setPreferenceData/getPreferenceData/hasKey/clear/close (createFakeCache always succeeds and
// cannot reach these catch closures).
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
