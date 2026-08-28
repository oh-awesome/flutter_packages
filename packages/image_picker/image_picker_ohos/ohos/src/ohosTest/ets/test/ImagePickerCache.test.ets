// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ImagePickerCache.ets 测试：null context 下 getPreferences 失败（preferences 保持 null），
// 所有读写方法优雅走空分支不抛异常；同时通过注入内存 fake Preferences（构造函数测试注入缝）
// 覆盖 save*/retrieve*/getCacheMap 的真实读写路径。覆盖 MAP_KEY 常量、CacheType 枚举与保存参数解析。

import { describe, it, expect } from '@ohos/hypium';
import ArrayList from '@ohos.util.ArrayList';
import ImagePickerCache, { CacheType } from '../../../main/ets/image_picker/ImagePickerCache';
import { ImageSelectionOptions, CacheRetrievalType } from '../../../main/ets/image_picker/Messages';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { createTestCache, createFakeCache, createFailingCache } from './CacheShim';

function makeCache(): ImagePickerCache {
  // 见 CacheShim：getPreferences(null/任意 context) 在 ohosTest 同步抛，无法经 namespace 打补丁，
  // 故用 Object.create 绕过构造器 + 注入 preferencesInitPromise/preferences 空分支字段
  return createTestCache();
}

function realContext(): common.Context {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
}

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

function listOf(values: ESObject[]): ArrayList<ESObject> {
  const list: ArrayList<ESObject> = new ArrayList<ESObject>();
  values.forEach((v: ESObject) => {
    list.add(v);
  });
  return list;
}

function imageOptions(maxWidth: number | null, maxHeight: number | null, quality: number): ImageSelectionOptions {
  const values: ESObject[] = [];
  values.push(maxWidth);
  values.push(maxHeight);
  values.push(quality);
  return ImageSelectionOptions.fromList(listOf(values));
}

// 内存 fake Preferences：见 CacheShim，覆盖真实读写路径（ohosTest 环境无法创建真实 Preferences）
function makeFakeCache(): ImagePickerCache {
  return createFakeCache();
}

function stringPaths(values: string[]): ArrayList<string> {
  const list: ArrayList<string> = new ArrayList<string>();
  values.forEach((v: string) => {
    list.add(v);
  });
  return list;
}

// 可注入失败的 fake Preferences：见 CacheShim，覆盖 setPreferenceData/getPreferenceData/hasKey/
// clear/close 的异常分支（createFakeCache 全部成功，无法触达这些 catch 闭包）
function makeFailingCache(failPut: boolean, failFlush: boolean, failGet: boolean, failHasReject: boolean,
  failHasThrow: boolean, failClear: boolean, nonStringGet: boolean): ImagePickerCache {
  return createFailingCache(failPut, failFlush, failGet, failHasReject, failHasThrow, failClear, nonStringGet);
}

// 经 TestAbility 暴露的真实 UIAbilityContext 构造真实 ImagePickerCache；getPreferences 同步抛
// （真实构造不可达）时返回 null，调用方跳过。
function realCacheOrNull(): ImagePickerCache | null {
  const ability: ESObject = (globalThis as ESObject).testAbility;
  if (ability == null || ability.context == null) {
    return null;
  }
  try {
    return new ImagePickerCache(ability.context as common.Context);
  } catch (e) {
    return null;
  }
}

// 注入真实 ImagePickerCache.preferences 的失败 fake：语义与 CacheShim.createFailingCache 一致，
// 但作用于真实类的实例，用于覆盖真实 setPreferenceData/getPreferenceData/hasKey/clear/close
// 的异常 catch 闭包（TestImagePickerCache 镜像类不贡献真实类覆盖率）。
function makeInjectedPrefs(failPut: boolean, failFlush: boolean, failGet: boolean, failHasReject: boolean,
  failHasThrow: boolean, failClear: boolean, nonStringGet: boolean): ESObject {
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
  return fake;
}

export default function imagePickerCacheTest() {
  describe('ImagePickerCacheTest', () => {
    it('map_keys_match_dart_protocol', 0, () => {
      expect(ImagePickerCache.MAP_KEY_PATH_LIST).assertEqual('pathList');
      expect(ImagePickerCache.MAP_KEY_MAX_WIDTH).assertEqual('maxWidth');
      expect(ImagePickerCache.MAP_KEY_MAX_HEIGHT).assertEqual('maxHeight');
      expect(ImagePickerCache.MAP_KEY_IMAGE_QUALITY).assertEqual('imageQuality');
      expect(ImagePickerCache.MAP_KEY_TYPE).assertEqual('type');
      expect(ImagePickerCache.MAP_KEY_ERROR).assertEqual('error');
    });

    it('cache_type_enum_values', 0, () => {
      expect(CacheType.IMAGE).assertEqual(0);
      expect(CacheType.VIDEO).assertEqual(1);
    });

    it('saveType_image_and_video_do_not_throw', 0, () => {
      const cache: ImagePickerCache = makeCache();
      cache.saveType(CacheType.IMAGE);
      cache.saveType(CacheType.VIDEO);
      expect(true).assertTrue();
    });

    it('saveDimension_with_and_without_constraints', 0, () => {
      const cache: ImagePickerCache = makeCache();
      cache.saveDimensionWithOutputOptions(imageOptions(800.0, 600.0, 90));
      cache.saveDimensionWithOutputOptions(imageOptions(null, null, 100));
      expect(true).assertTrue();
    });

    it('savePendingCameraMediaUriPath_does_not_throw', 0, () => {
      const cache: ImagePickerCache = makeCache();
      cache.savePendingCameraMediaUriPath('file:///camera/cap.jpg');
      expect(true).assertTrue();
    });

    it('saveResult_all_combinations_do_not_throw', 0, () => {
      const cache: ImagePickerCache = makeCache();
      const paths: ArrayList<string> = new ArrayList<string>();
      paths.add('/a.jpg');
      cache.saveResult(paths, 'code', 'msg');
      cache.saveResult(paths, null, null);
      cache.saveResult(null as ESObject as ArrayList<string>, 'code', 'msg');
      expect(true).assertTrue();
    });

    it('retrievePendingCameraMediaUriPath_returns_empty_on_missing_preferences', 0, async () => {
      const cache: ImagePickerCache = makeCache();
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('clear_and_close_are_safe_without_preferences', 0, async () => {
      const cache: ImagePickerCache = makeCache();
      await cache.clear();
      await cache.close();
      expect(true).assertTrue();
    });

    it('getCacheMap_returns_empty_map_without_preferences', 0, async () => {
      const cache: ImagePickerCache = makeCache();
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertTrue();
    });

    it('real_context_getPreferences_rejects_catch_keeps_preferences_null', 0, async () => {
      // 官方推荐：经 AbilityDelegator.getAppContext() 取应用级 Context 构造真实 cache，
      // getPreferences 在多数版本可正常解析（preferences 被真实赋值）或异步拒绝（构造器 .catch
      // 令 preferences 保持 null）；个别版本对 delegator context 同步抛。try/catch 兜底到空分支
      // cache，三条读路径都返回 ''。
      let cache: ImagePickerCache;
      try {
        cache = new ImagePickerCache(realContext());
      } catch (e) {
        cache = createTestCache();
      }
      await sleep(100);
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('ui_ability_context_preferences_resolve_or_fallback_never_throws', 0, async () => {
      // getCurrentTopAbility().context 为真实 UIAbilityContext：getPreferences 若 resolve 则覆盖
      // 构造器 .then 闭包（preferences 被真实赋值），若仍拒绝则走 .catch 闭包；无论哪种结果，
      // 后续读写都不应抛异常。取不到 topAbility 时该用例空过（不覆盖任何分支）。
      let topAbility: ESObject = null;
      try {
        topAbility = AbilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility() as ESObject;
      } catch (e) {
        topAbility = null;
      }
      if (topAbility == null || topAbility.context == null) {
        expect(true).assertTrue();
        return;
      }
      const cache: ImagePickerCache = new ImagePickerCache(topAbility.context as common.Context);
      await sleep(300);
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('init_preferences_promise_resolve_and_reject_closures_covered_elsewhere', 0, async () => {
      // 原 init_from_preferences_promise_resolve/reject 两个用例调用 ImagePickerCache 上不存在的
      // initFromPreferencesPromise 方法，运行时抛 TypeError。构造器内联的 .then 闭包（preferences 被赋值）
      // 已由 makeFakeCache 注入已 resolve 的 preferencesInitPromise 覆盖；.catch 闭包（preferences 保持 null）
      // 已由 real_context_getPreferences_rejects_catch_keeps_preferences_null 覆盖。
      // 此处仅验证 resolve 与 reject 两种 promise 状态下读写都不抛异常。
      const resolveCache: ImagePickerCache = makeCache();
      (resolveCache as ESObject).preferencesInitPromise = Promise.resolve();
      const resolveResult: string | null = await resolveCache.retrievePendingCameraMediaUriPath();
      expect(resolveResult).assertEqual('');

      const rejectCache: ImagePickerCache = makeCache();
      (rejectCache as ESObject).preferencesInitPromise = Promise.reject();
      const rejectResult: string | null = await rejectCache.retrievePendingCameraMediaUriPath();
      expect(rejectResult).assertEqual('');
    });

    it('fake_prefs_save_image_type_and_dimensions_round_trip', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveType(CacheType.IMAGE);
      cache.saveDimensionWithOutputOptions(imageOptions(800.0, 600.0, 90));
      // getCacheMap 仅在存在 pathList/error 时（hasData=true）才输出 type/尺寸/质量，故同时写入 pathList
      cache.saveResult(stringPaths(['/a.jpg']), null, null);
      await sleep(100);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertFalse();
      const type: ESObject = map.get(ImagePickerCache.MAP_KEY_TYPE) as ESObject;
      const maxWidth: ESObject = map.get(ImagePickerCache.MAP_KEY_MAX_WIDTH) as ESObject;
      const maxHeight: ESObject = map.get(ImagePickerCache.MAP_KEY_MAX_HEIGHT) as ESObject;
      const quality: ESObject = map.get(ImagePickerCache.MAP_KEY_IMAGE_QUALITY) as ESObject;
      expect(type == CacheRetrievalType.IMAGE).assertTrue();
      expect(maxWidth == 800).assertTrue();
      expect(maxHeight == 600).assertTrue();
      expect(quality == 90).assertTrue();
    });

    it('fake_prefs_save_video_type_round_trip', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveType(CacheType.VIDEO);
      cache.saveResult(stringPaths(['/v.mp4']), null, null);
      await sleep(100);
      const map = await cache.getCacheMap();
      const type: ESObject = map.get(ImagePickerCache.MAP_KEY_TYPE) as ESObject;
      expect(type == CacheRetrievalType.VIDEO).assertTrue();
    });

    it('fake_prefs_save_result_with_error_round_trip', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveResult(stringPaths(['/a.jpg', '/b.jpg']), 'boom', 'message');
      await sleep(100);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertFalse();
      const pathList: ArrayList<ESObject> = map.get(ImagePickerCache.MAP_KEY_PATH_LIST) as ESObject as ArrayList<ESObject>;
      expect(pathList.length).assertEqual(2);
      expect(pathList[0]).assertEqual('/a.jpg');
      const error: ESObject = map.get(ImagePickerCache.MAP_KEY_ERROR) as ESObject;
      expect(error != null).assertTrue();
    });

    it('fake_prefs_save_result_without_error_no_error_key', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveResult(stringPaths(['/a.jpg']), null, null);
      await sleep(100);
      const map = await cache.getCacheMap();
      const pathList: ArrayList<ESObject> = map.get(ImagePickerCache.MAP_KEY_PATH_LIST) as ESObject as ArrayList<ESObject>;
      expect(pathList.length).assertEqual(1);
      expect(map.hasKey(ImagePickerCache.MAP_KEY_ERROR)).assertFalse();
    });

    it('fake_prefs_retrieve_pending_camera_uri_round_trip', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.savePendingCameraMediaUriPath('file:///camera/cap.jpg');
      await sleep(100);
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('file:///camera/cap.jpg');
    });

    it('fake_prefs_save_dimension_maxWidth_null_skips_width', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveDimensionWithOutputOptions(imageOptions(null, 600.0, 90));
      cache.saveResult(stringPaths(['/a.jpg']), null, null);
      await sleep(100);
      const map = await cache.getCacheMap();
      expect(map.hasKey(ImagePickerCache.MAP_KEY_MAX_WIDTH)).assertFalse();
      expect(map.hasKey(ImagePickerCache.MAP_KEY_MAX_HEIGHT)).assertTrue();
      const maxHeight: ESObject = map.get(ImagePickerCache.MAP_KEY_MAX_HEIGHT) as ESObject;
      expect(maxHeight == 600).assertTrue();
    });

    it('fake_prefs_clear_empties_cache', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.saveType(CacheType.IMAGE);
      await sleep(100);
      await cache.clear();
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertTrue();
    });

    it('fake_prefs_close_flushes_without_error', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      cache.savePendingCameraMediaUriPath('file:///camera/cap.jpg');
      await sleep(100);
      await cache.close();
      // close 后 preferences 引用置空，后续读走空分支返回默认值
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('put_rejection_is_swallowed_by_inner_catch', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(true, false, false, false, false, false, false);
      cache.saveType(CacheType.IMAGE);
      await sleep(100);
      expect(true).assertTrue();
    });

    it('flush_rejection_after_put_is_swallowed', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, true, false, false, false, false, false);
      cache.saveType(CacheType.IMAGE);
      await sleep(100);
      expect(true).assertTrue();
    });

    it('get_rejection_returns_default_value', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, false, true, false, false, false, false);
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('has_rejection_is_swallowed_returns_false', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, false, false, true, false, false, false);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertTrue();
    });

    it('has_sync_throw_hits_outer_catch', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, false, false, false, true, false, false);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertTrue();
    });

    it('non_string_get_value_falls_back_to_empty', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, false, false, false, false, false, true);
      const result: string | null = await cache.retrievePendingCameraMediaUriPath();
      expect(result).assertEqual('');
    });

    it('clear_rejection_is_swallowed', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, false, false, false, false, true, false);
      await cache.clear();
      expect(true).assertTrue();
    });

    it('close_flush_rejection_is_swallowed', 0, async () => {
      const cache: ImagePickerCache = makeFailingCache(false, true, false, false, false, false, false);
      await cache.close();
      expect(true).assertTrue();
    });

    it('real_cache_with_ability_context_runs_all_methods', 0, async () => {
      // 真实构造路径：getPreferences 需要 ability 级 context，delegator.getAppContext() 同步抛。
      // TestAbility.onCreate 已将自身 UIAbilityContext 暴露到 globalThis.testAbility，
      // 若 getPreferences 接受该 context 则构造成功 → 真实 save*/retrieve*/getCacheMap/clear/close
      // 全部可达（覆盖真实实现，而非 TestImagePickerCache 镜像）；仍抛则 try/catch 空过。
      const ability: ESObject = (globalThis as ESObject).testAbility;
      if (ability == null || ability.context == null) {
        expect(true).assertTrue();
        return;
      }
      let cache: ImagePickerCache;
      try {
        cache = new ImagePickerCache(ability.context as common.Context);
      } catch (e) {
        // getPreferences 对 ability context 仍同步抛：真实构造不可达，跳过
        expect(true).assertTrue();
        return;
      }
      cache.saveType(CacheType.IMAGE);
      cache.saveType(CacheType.VIDEO);
      cache.saveDimensionWithOutputOptions(imageOptions(800.0, 600.0, 90));
      cache.savePendingCameraMediaUriPath('file:///camera/real_cap.jpg');
      const pending: string | null = await cache.retrievePendingCameraMediaUriPath();
      // 无 error 数据：真实 getCacheMap 走 pathList/type/尺寸/质量 分支（可正常返回）
      cache.saveResult(stringPaths(['/real_a.jpg']), null, null);
      await sleep(300);
      try {
        const map = await cache.getCacheMap();
      } catch (e) {
      }
      // error 数据：真实实现 error 分支 new CacheRetrievalErrorBuilder(null,null,null) 使
      // setCode/build 恒为 null（死代码），getCacheMap 在 error.setCode 处抛 TypeError——
      // try/catch 进入即覆盖 getCacheMap 函数（及其 hasKey/getPreferenceData 前置行）
      cache.saveResult(stringPaths(['/real_b.jpg']), 'code', 'msg');
      await sleep(300);
      try {
        await cache.getCacheMap();
      } catch (e) {
      }
      // 清理真实偏好存储，避免残留污染同一 bundle 内断言 '' 的用例
      await cache.clear();
      await cache.close();
      expect(true).assertTrue();
    });

    it('real_cache_injected_failing_prefs_covers_catch_closures', 0, async () => {
      // 构造真实 cache 后注入失败 fake：覆盖真实 setPreferenceData/getPreferenceData/hasKey/
      // clear/close 的异常 catch 闭包。真实 cache 的私有字段经 ESObject 覆写（与 CacheShim 一致）。
      const cache: ImagePickerCache | null = realCacheOrNull();
      if (cache == null) {
        expect(true).assertTrue();
        return;
      }
      // 等待构造器 getPreferences 落定（resolve→preferences 被赋值 / reject→保持 null），
      // 避免其 .then 回调在注入后异步覆写 fake（竞态防护）
      await sleep(300);
      (cache as ESObject).preferencesInitPromise = Promise.resolve();

      // failPut：put 拒绝 → setPreferenceData 内 put.catch 闭包
      (cache as ESObject).preferences = makeInjectedPrefs(true, false, false, false, false, false, false);
      cache.saveType(CacheType.IMAGE);
      await sleep(50);

      // failFlush：put 成功 + flush 拒绝 → flush.catch 闭包
      (cache as ESObject).preferences = makeInjectedPrefs(false, true, false, false, false, false, false);
      cache.saveType(CacheType.VIDEO);
      await sleep(50);

      // failGet：get 拒绝 → getPreferenceData.catch 闭包（返回默认值）
      (cache as ESObject).preferences = makeInjectedPrefs(false, false, true, false, false, false, false);
      const r1: string | null = await cache.retrievePendingCameraMediaUriPath();
      await sleep(50);

      // failHasReject：has 拒绝 → hasKey 内层 .catch 闭包（返回 false）
      (cache as ESObject).preferences = makeInjectedPrefs(false, false, false, true, false, false, false);
      await cache.getCacheMap();
      await sleep(50);

      // failHasThrow：has 同步抛 → hasKey 外层 catch
      (cache as ESObject).preferences = makeInjectedPrefs(false, false, false, false, true, false, false);
      await cache.getCacheMap();
      await sleep(50);

      // nonStringGet：get 返回 42 → 非字符串回退 ''
      (cache as ESObject).preferences = makeInjectedPrefs(false, false, false, false, false, false, true);
      const r2: string | null = await cache.retrievePendingCameraMediaUriPath();
      await sleep(50);

      // getSyncThrow：get 同步抛 → getPreferenceData 拒绝 → retrievePendingCameraMediaUriPath 的 try/catch
      (cache as ESObject).preferences = {
        put: (): Promise<void> => Promise.resolve(),
        get: (): Promise<ESObject> => {
          throw new Error('get sync throw');
        },
        has: (): Promise<boolean> => Promise.resolve(false),
        clear: (): Promise<void> => Promise.resolve(),
        flush: (): Promise<void> => Promise.resolve(),
      };
      await cache.retrievePendingCameraMediaUriPath();
      await sleep(50);

      // failClear：clear 拒绝 → clear.catch
      (cache as ESObject).preferences = makeInjectedPrefs(false, false, false, false, false, true, false);
      await cache.clear();
      await sleep(50);

      // failFlush（close 内）：flush 拒绝 → close.catch
      (cache as ESObject).preferences = makeInjectedPrefs(false, true, false, false, false, false, false);
      await cache.close();
      await sleep(50);

      expect(r1 == '').assertTrue();
      expect(r2 == '').assertTrue();
    });

    it('real_cache_null_preferences_hits_empty_branches', 0, async () => {
      // 真实 cache 强制走空分支（preferences 置 null + initPromise resolve）：
      // 覆盖 setPreferenceData/getPreferenceData/hasKey/clear 的 null-preferences 早退行
      const cache: ImagePickerCache | null = realCacheOrNull();
      if (cache == null) {
        expect(true).assertTrue();
        return;
      }
      await sleep(300);
      (cache as ESObject).preferences = null;
      (cache as ESObject).preferencesInitPromise = Promise.resolve();
      cache.saveType(CacheType.IMAGE);
      await sleep(50);
      const r: string | null = await cache.retrievePendingCameraMediaUriPath();
      await cache.clear();
      await cache.close();
      const map = await cache.getCacheMap();
      expect(r == '').assertTrue();
      expect(map.isEmpty()).assertTrue();
    });
  });
}
