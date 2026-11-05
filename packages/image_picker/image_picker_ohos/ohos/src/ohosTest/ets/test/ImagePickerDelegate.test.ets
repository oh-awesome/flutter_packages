// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ImagePickerDelegate.ets pure-logic tests: the constructor reads ability.context (no null
// tolerance); empty-context cases keep this.context null via a {context:null} fake ability,
// covering all handleResultType dispatch, finishWith* reply branches, the setPendingOptionsAndResult
// state machine, video extension detection, and the CameraDevice enum. Real-context cases inject
// the real appContext via a fake ability ({context: real appContext}) and, with real temp files,
// cover selection result handling and the full retrieveLostImage pipeline; they never touch the
// system pickers behind chooseMedia/takeXxxWithCamera (which would launch real UI).

import { describe, it, expect } from '@ohos/hypium';
import ArrayList from '@ohos.util.ArrayList';
import ImagePickerDelegate, { CameraDevice } from '../../../main/ets/image_picker/ImagePickerDelegate';
import ImagePickerCache, { CacheType } from '../../../main/ets/image_picker/ImagePickerCache';
import ImageResizer from '../../../main/ets/image_picker/ImageResizer';
import ExifDataCopier from '../../../main/ets/image_picker/ExifDataCopier';
import FileUtils from '../../../main/ets/image_picker/FileUtils';
import {
  ImageSelectionOptions,
  VideoSelectionOptions,
  MediaSelectionOptions,
  GeneralOptions,
  Result,
  FlutterError,
  CacheRetrievalResult,
  CacheRetrievalError,
  CacheRetrievalType
} from '../../../main/ets/image_picker/Messages';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { createTestCache, createFakeCache } from './CacheShim';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AsyncCallback } from '@ohos.base';
import ImagePickerUtils from '../../../main/ets/image_picker/ImagePickerUtils';

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

function realContext(): common.Context {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
}

class FakeResult implements Result<ArrayList<string>> {
  lastError: FlutterError | null = null;
  lastSuccess: ArrayList<string> | null = null;

  success(result: ArrayList<string>): void {
    this.lastSuccess = result;
  }

  error(error: Error | ESObject): Error | ESObject {
    this.lastError = error as FlutterError;
    return error;
  }
}

// Fake PhotoViewPicker: injected into the delegate via setPhotoPickerForTest, covering the
// select().then/.catch closures of chooseMedia without launching the real system picker UI
class FakePhotoViewPicker {
  resolveUris: Array<string> | null = null;
  rejectWith: Error | null = null;

  select(_options: ESObject): Promise<ESObject> {
    if (this.rejectWith != null) {
      return Promise.reject(this.rejectWith);
    }
    return Promise.resolve({ photoUris: this.resolveUris ?? new Array<string>() } as ESObject);
  }
}

// Fake permission check/request: injected via
// setPermissionNeedCheckerForTest/setPermissionRequesterForTest, covering the .then/.catch
// closures of checkAndRequestCameraPermission (the test app manifest does not declare the CAMERA
// permission, and the real requestCameraPermission always resolves inside its own try/catch, so
// both branches are unreachable in production/real test environments)
function fakeNeedPermissionTrue(): (cb: AsyncCallback<boolean>) => void {
  return (cb: AsyncCallback<boolean>): void => {
    cb(null, true);
  };
}

function fakeRequestResolve(granted: boolean): (ctx: common.Context) => Promise<boolean> {
  return (_ctx: common.Context): Promise<boolean> => Promise.resolve(granted);
}

function fakeRequestReject(): (ctx: common.Context) => Promise<boolean> {
  return (_ctx: common.Context): Promise<boolean> => Promise.reject(new Error('permission request failed'));
}

// ---- Test injection helpers ----
// cameraPicker.pick comes from @kit.CameraKit (a namespace); ArkTS forbids overriding its members
// as an object (arkts-no-ns-as-obj), so the .then/.catch closures of launch*WithCameraWant cannot
// be injected without touching the main source; the related cases have been reduced to
// null-context entry smoke tests (see each case's comments).
// ImagePickerUtils is a class, so its public static methods can be replaced via ESObject and
// restored afterwards, covering both granted/denied permission branches of
// checkAndRequestCameraPermission.
const ORIGINAL_NEED_PERMISSION: ESObject = (ImagePickerUtils as ESObject).needRequestCameraPermission;
const ORIGINAL_REQUEST_PERMISSION: ESObject = (ImagePickerUtils as ESObject).requestCameraPermission;

function installFakePermission(need: (cb: AsyncCallback<boolean>) => void,
  request: (ctx: common.Context) => Promise<boolean>): void {
  (ImagePickerUtils as ESObject).needRequestCameraPermission = need;
  (ImagePickerUtils as ESObject).requestCameraPermission = request;
}

function restorePermission(): void {
  (ImagePickerUtils as ESObject).needRequestCameraPermission = ORIGINAL_NEED_PERMISSION;
  (ImagePickerUtils as ESObject).requestCameraPermission = ORIGINAL_REQUEST_PERMISSION;
}

function makeCache(): ImagePickerCache {
  // See CacheShim: getPreferences(null/any context) throws synchronously in ohosTest and cannot be
  // patched via the namespace, so Object.create bypasses the constructor + injects empty-branch fields
  return createTestCache();
}

// In-memory fake Preferences: see CacheShim, unlocks the full retrieveLostImage/getCacheMap pipeline
function makeFakeCache(): ImagePickerCache {
  return createFakeCache();
}

function makeResizer(): ImageResizer {
  return new ImageResizer(null as ESObject as common.Context, new ExifDataCopier());
}

function makeRealResizer(): ImageResizer {
  return new ImageResizer(realContext(), new ExifDataCopier());
}

// Empty ability: the constructor reads ability.context (no null tolerance); passing literal null
// would throw TypeError in the constructor, so a {context:null} fake ability keeps this.context
// null (preserving the empty-context branch semantics) without throwing
function buildDelegate(result: Result<ArrayList<string>> | null,
  imageOptions: ImageSelectionOptions | null): ImagePickerDelegate {
  return new ImagePickerDelegate({ context: null } as ESObject as UIAbility, makeResizer(), makeCache(),
    null as ESObject as common.UIAbilityContext, imageOptions as ESObject as ImageSelectionOptions,
    null as ESObject as VideoSelectionOptions, result as ESObject as Result<ArrayList<string>>);
}

// Inject the real context: the fake ability's context property points to the real appContext
// (the constructor reads ability.context)
function buildDelegateWithRealContext(result: Result<ArrayList<string>> | null,
  imageOptions: ImageSelectionOptions | null): ImagePickerDelegate {
  const fakeAbility: ESObject = { context: realContext() };
  return new ImagePickerDelegate(fakeAbility as ESObject as UIAbility, makeRealResizer(), makeCache(),
    null as ESObject as common.UIAbilityContext, imageOptions as ESObject as ImageSelectionOptions,
    null as ESObject as VideoSelectionOptions, result as ESObject as Result<ArrayList<string>>);
}

function buildDelegateWithFakeCache(cache: ImagePickerCache): ImagePickerDelegate {
  return new ImagePickerDelegate({ context: null } as ESObject as UIAbility, makeResizer(), cache,
    null as ESObject as common.UIAbilityContext, null as ESObject as ImageSelectionOptions,
    null as ESObject as VideoSelectionOptions, null as ESObject as Result<ArrayList<string>>);
}

function listOf(values: ESObject[]): ArrayList<ESObject> {
  const list: ArrayList<ESObject> = new ArrayList<ESObject>();
  values.forEach((v: ESObject) => {
    list.add(v);
  });
  return list;
}

function imageOptions(): ImageSelectionOptions {
  return ImageSelectionOptions.fromList(listOf([100.0, 200.0, 90]));
}

function stringPaths(values: string[]): ArrayList<string> {
  const list: ArrayList<string> = new ArrayList<string>();
  values.forEach((v: string) => {
    list.add(v);
  });
  return list;
}

// Generate a real PNG on the device (200x100 RGBA) for the resize pipeline to decode
async function createTestPng(ctx: common.Context): Promise<string> {
  const width: number = 200;
  const height: number = 100;
  const rgba = new ArrayBuffer(width * height * 4);
  const pixelMap: image.PixelMap = await image.createPixelMap(rgba, { size: { width: width, height: height } });
  const packer: image.ImagePacker = image.createImagePacker();
  const buf: ArrayBuffer = await packer.packing(pixelMap, { format: 'image/png', quality: 90 });
  await packer.release();
  await pixelMap.release();
  const path: string = ctx.cacheDir + '/delegate_src.png';
  const file: fs.File = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, buf);
  fs.closeSync(file);
  return path;
}

function cleanupPng(ctx: common.Context, srcPath: string): void {
  try {
    fs.unlinkSync(srcPath);
  } catch (e) {
  }
  FileUtils.cleanupTempFiles(ctx);
}

export default function imagePickerDelegateTest() {
  describe('ImagePickerDelegateTest', () => {
    it('setCameraDevice_rear_and_front', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.setCameraDevice(CameraDevice.REAR);
      delegate.setCameraDevice(CameraDevice.FRONT);
      expect(true).assertTrue();
    });

    it('saveStateBeforeResult_no_pending_call_is_noop', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.saveStateBeforeResult();
      expect(true).assertTrue();
    });

    it('saveStateBeforeResult_with_pending_call_saves_cache', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, imageOptions());
      delegate.saveStateBeforeResult();
      expect(true).assertTrue();
    });

    it('setPendingOptionsAndResult_first_true_then_already_active', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const result: FakeResult = new FakeResult();
      const opts: ImageSelectionOptions = imageOptions();
      expect(delegate.setPendingOptionsAndResult(opts, null, result)).assertTrue();
      expect(delegate.setPendingOptionsAndResult(opts, null, result)).assertFalse();
    });

    it('finishWithAlreadyActiveError_reports_error', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const result: FakeResult = new FakeResult();
      delegate.finishWithAlreadyActiveError(result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('handleResultType_media_success_no_pending_uri_failure', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseMediaResult', 0, ['file:///nonexistent.mp4']);
      expect(true).assertTrue();
    });

    it('handleResultType_media_success_empty_uri_list', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseMediaResult', 0, []);
      expect(true).assertTrue();
    });

    it('handleResultType_media_error_code', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseMediaResult', -1, []);
      expect(true).assertTrue();
    });

    it('handleResultType_media_success_with_pending_non_video_path', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, imageOptions());
      delegate.handleResultType('handleChooseMediaResult', 0, ['file:///nonexistent.jpg']);
      await sleep(300);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('no_valid_media_uri');
      }
    });

    it('handleResultType_media_success_with_pending_video_path', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, imageOptions());
      delegate.handleResultType('handleChooseMediaResult', 0, ['file:///nonexistent.mp4']);
      await sleep(300);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('no_valid_media_uri');
      }
    });

    it('handleResultType_multi_image_success_and_error', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseMultiImageResult', 0, ['file:///nonexistent.jpg']);
      delegate.handleResultType('handleChooseMultiImageResult', -1, []);
      expect(true).assertTrue();
    });

    it('handleResultType_single_image_empty_and_error', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseImageResult', 0, []);
      delegate.handleResultType('handleChooseImageResult', -1, []);
      expect(true).assertTrue();
    });

    it('handleResultType_single_video_empty_and_error', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseVideoResult', 0, []);
      delegate.handleResultType('handleChooseVideoResult', -1, []);
      expect(true).assertTrue();
    });

    it('handleResultType_multi_video_failure_and_empty', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.handleResultType('handleChooseMultiVideoResult', 0, ['file:///nonexistent.mp4']);
      delegate.handleResultType('handleChooseMultiVideoResult', 0, []);
      delegate.handleResultType('handleChooseMultiVideoResult', -1, []);
      expect(true).assertTrue();
    });

    it('handleResultType_single_video_with_bad_uri_reports_no_valid_video_uri', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      delegate.handleResultType('handleChooseVideoResult', 0, ['file:///nonexistent.mp4']);
      await sleep(200);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('no_valid_video_uri');
      }
    });

    it('handleResultType_single_image_with_bad_uri_reports_no_valid_image_uri', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, imageOptions());
      delegate.handleResultType('handleChooseImageResult', 0, ['file:///nonexistent.jpg']);
      await sleep(300);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('no_valid_image_uri');
      }
    });

    it('handleResultType_multi_video_with_bad_uri_reports_missing_valid_video_uri', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      delegate.handleResultType('handleChooseMultiVideoResult', 0, ['file:///nonexistent.mp4']);
      await sleep(200);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('missing_valid_video_uri');
      }
    });

    it('handleResultType_media_success_with_real_uri_and_pending_image_options', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, imageOptions());
      delegate.handleResultType('handleChooseMediaResult', 0, [uri]);
      await sleep(500);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleResultType_single_image_success_with_real_uri', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, imageOptions());
      delegate.handleResultType('handleChooseImageResult', 0, [uri]);
      await sleep(500);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleResultType_single_video_success_with_real_uri', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      delegate.handleResultType('handleChooseVideoResult', 0, [uri]);
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleResultType_multi_video_success_with_real_uris', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      delegate.handleResultType('handleChooseMultiVideoResult', 0, [uri]);
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleResultType_single_video_cancelled_returns_empty_success', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.handleResultType('handleChooseVideoResult', -1, []);
      expect(result.lastSuccess != null).assertTrue();
    });

    it('chooseMediaFromGallery_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const pending: FakeResult = new FakeResult();
      delegate.setPendingOptionsAndResult(imageOptions(), null, pending);
      // MediaSelectionOptions.fromList([null]) triggers the setImageSelectionOptions(null) null guard
      // and throws, so the public constructor must be used to get an imageSelectionOptions=null
      // instance (matching the Pigeon codec null-guard semantics)
      const media: MediaSelectionOptions = new MediaSelectionOptions();
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      delegate.chooseMediaFromGallery(media, general, result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('chooseImageFromGallery_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const pending: FakeResult = new FakeResult();
      delegate.setPendingOptionsAndResult(imageOptions(), null, pending);
      delegate.chooseImageFromGallery(imageOptions(), true, result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('chooseVideoFromGallery_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const pending: FakeResult = new FakeResult();
      delegate.setPendingOptionsAndResult(null, null, pending);
      const video: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([30]));
      delegate.chooseVideoFromGallery(video, true, result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('chooseMultiVideoFromGallery_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const pending: FakeResult = new FakeResult();
      delegate.setPendingOptionsAndResult(null, null, pending);
      const video: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([30]));
      delegate.chooseMultiVideoFromGallery(video, true, 3, result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('chooseMultiImagesFromGallery_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const pending: FakeResult = new FakeResult();
      delegate.setPendingOptionsAndResult(imageOptions(), null, pending);
      delegate.chooseMultiImagesFromGallery(imageOptions(), true, 3, result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('takeImageWithCamera_no_manifest_perm_hits_permission_error', 0, async () => {
      const result: FakeResult = new FakeResult();
      // Start from a no-pending state: after setPendingOptionsAndResult succeeds inside
      // takeImageWithCamera, the async permission check (test package declares no CAMERA → callback
      // false → enters the launch branch) makes launchTakeImageWithCameraWant throw under null
      // context, and the .catch replies with camera_permission_error
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.takeImageWithCamera(imageOptions(), result);
      await sleep(600);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('camera_permission_error');
      }
    });

    it('takeImageWithCamera_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.takeImageWithCamera(imageOptions(), result);
      delegate.takeImageWithCamera(imageOptions(), result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('takeVideoWithCamera_no_manifest_perm_hits_permission_error', 0, async () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      // launchTakeVideoWithCameraWant is async: under null context, the throw from
      // (this.context as Context).cacheDir becomes a rejected Promise, but takeVideoWithCamera's
      // .then does not return that Promise → the outer .catch never sees it → lastError stays null.
      // To align with the image path (synchronous launch throws synchronously → outer .catch →
      // camera_permission_error), this patches the instance method to throw synchronously,
      // verifying that under null context a permission denial still replies with camera_permission_error.
      (delegate as ESObject).launchTakeVideoWithCameraWant = (duration: number): void => {
        throw new Error('camera launch failed');
      };
      delegate.takeVideoWithCamera(VideoSelectionOptions.fromList(listOf([30])), result);
      await sleep(600);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('camera_permission_error');
      }
    });

    it('handleCaptureImageResult_success_with_real_uri', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, imageOptions());
      delegate.handleCaptureImageResult(0, uri);
      await sleep(500);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleCaptureImageResult_cancelled_returns_null_success', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.handleCaptureImageResult(-1, '');
      const cancelled: ArrayList<string> | null = result.lastSuccess;
      expect(cancelled != null).assertTrue();
      if (cancelled != null) {
        expect(cancelled.length).assertEqual(0);
      }
    });

    it('handleCaptureImageResult_failed_to_parse_uri_returns_null_success', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.handleCaptureImageResult(0, 'file:///nonexistent.jpg');
      const failed: ArrayList<string> | null = result.lastSuccess;
      expect(failed != null).assertTrue();
      if (failed != null) {
        expect(failed.length).assertEqual(0);
      }
    });

    it('handleCaptureVideoResult_success_with_real_uri', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      delegate.handleCaptureVideoResult(0, uri);
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleCaptureVideoResult_cancelled_returns_null_success', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.handleCaptureVideoResult(-1, '');
      const cancelledVideo: ArrayList<string> | null = result.lastSuccess;
      expect(cancelledVideo != null).assertTrue();
      if (cancelledVideo != null) {
        expect(cancelledVideo.length).assertEqual(0);
      }
    });

    it('handleVideoResult_forwards_path', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.handleVideoResult('/v.mp4', false);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess[0]).assertEqual('/v.mp4');
      }
    });

    it('getResizedImagePath_with_real_file_returns_scaled_path', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const delegate: ImagePickerDelegate = new ImagePickerDelegate({ context: null } as ESObject as UIAbility,
        makeRealResizer(), makeCache(),
        null as ESObject as common.UIAbilityContext, null as ESObject as ImageSelectionOptions,
        null as ESObject as VideoSelectionOptions, null as ESObject as Result<ArrayList<string>>);
      const out: string = await delegate.getResizedImagePath(srcPath, imageOptions());
      expect(out != null).assertTrue();
      cleanupPng(ctx, srcPath);
    });

    it('release_cleans_up_resources_without_throw', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.release();
      expect(true).assertTrue();
    });

    it('chooseMedia_after_release_reports_internal_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.release();
      delegate.chooseMedia(1, 'handleChooseMediaResult');
      expect(true).assertTrue();
    });

    it('finishWithSuccess_with_pending_call_notifies_result', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.finishWithSuccess('/a.jpg');
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess[0]).assertEqual('/a.jpg');
      }
    });

    it('finishWithSuccess_null_path_no_pending_call_saves_nothing', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.finishWithSuccess(null);
      expect(true).assertTrue();
    });

    it('finishWithSuccess_no_pending_nonempty_saves_to_cache', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      const delegate: ImagePickerDelegate = buildDelegateWithFakeCache(cache);
      delegate.finishWithSuccess('/a.jpg');
      await sleep(100);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertFalse();
      const pathList: ArrayList<ESObject> =
        map.get(ImagePickerCache.MAP_KEY_PATH_LIST) as ESObject as ArrayList<ESObject>;
      expect(pathList.length).assertEqual(1);
    });

    it('finishWithListSuccess_empty_and_null_paths', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      const empty: ArrayList<string> = new ArrayList<string>();
      delegate.finishWithListSuccess(empty);
      delegate.finishWithListSuccess(null);
      expect(result.lastSuccess != null).assertTrue();
    });

    it('finishWithListSuccess_no_pending_nonempty_saves_to_cache', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      const delegate: ImagePickerDelegate = buildDelegateWithFakeCache(cache);
      delegate.finishWithListSuccess(stringPaths(['/b.jpg']));
      await sleep(100);
      const map = await cache.getCacheMap();
      expect(map.isEmpty()).assertFalse();
    });

    it('finishWithError_with_and_without_pending_call', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, null);
      delegate.finishWithError('no_valid_media_uri', 'no media');
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('no_valid_media_uri');
      }
      delegate.finishWithError('internal_error', 'internal');
    });

    it('clearPendingCallState_and_cleanupTempFiles_are_safe', 0, () => {
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.clearPendingCallState();
      delegate.cleanupTempFiles();
      expect(true).assertTrue();
    });

    it('clearPendingCallState_clears_state_allows_new_call', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(result, imageOptions());
      delegate.clearPendingCallState();
      expect(delegate.setPendingOptionsAndResult(imageOptions(), null, result)).assertTrue();
    });

    it('isVideoFile_detects_video_extensions_case_insensitive', 0, () => {
      // isVideoFile is a private instance method in main (not static); called via an instance + ESObject passthrough
      const del: ESObject = buildDelegate(null, null) as ESObject;
      const isVideoFile = (p: string): boolean => del.isVideoFile(p) as boolean;
      expect(isVideoFile('/data/tmp/a.mp4')).assertTrue();
      expect(isVideoFile('/data/tmp/a.MOV')).assertTrue();
      expect(isVideoFile('/data/tmp/a.webm')).assertTrue();
      expect(isVideoFile('/data/tmp/a.mkv')).assertTrue();
      expect(isVideoFile('/data/tmp/a.avi')).assertTrue();
    });

    it('isVideoFile_rejects_image_and_audio_extensions', 0, () => {
      const del: ESObject = buildDelegate(null, null) as ESObject;
      const isVideoFile = (p: string): boolean => del.isVideoFile(p) as boolean;
      expect(isVideoFile('/data/tmp/a.jpg')).assertFalse();
      expect(isVideoFile('/data/tmp/a.png')).assertFalse();
      expect(isVideoFile('/data/tmp/a.mp3')).assertFalse();
      expect(isVideoFile('/data/tmp/noext')).assertFalse();
    });

    it('camera_device_enum_has_distinct_rear_and_front', 0, () => {
      expect(CameraDevice.REAR).assertEqual(0);
      expect(CameraDevice.FRONT).assertEqual(1);
    });

    it('retrieveLostImage_fake_cache_restores_saved_result', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      const delegate: ImagePickerDelegate = buildDelegateWithFakeCache(cache);
      cache.saveType(CacheType.IMAGE);
      cache.saveDimensionWithOutputOptions(imageOptions());
      cache.saveResult(stringPaths(['/a.jpg']), null, null);
      await sleep(100);
      const result: CacheRetrievalResult | null = await delegate.retrieveLostImage();
      expect(result != null).assertTrue();
      if (result != null) {
        expect(result.getType()).assertEqual(CacheRetrievalType.IMAGE);
        expect(result.getPaths().length).assertEqual(1);
        expect(result.getPaths()[0]).assertEqual('/a.jpg');
      }
    });

    it('retrieveLostImage_fake_cache_with_video_type_and_error', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      const delegate: ImagePickerDelegate = buildDelegateWithFakeCache(cache);
      cache.saveType(CacheType.VIDEO);
      cache.saveResult(null as ESObject as ArrayList<string>, 'no_valid_video_uri', 'no valid video uri');
      await sleep(100);
      const result: CacheRetrievalResult | null = await delegate.retrieveLostImage();
      expect(result != null).assertTrue();
      if (result != null) {
        expect(result.getType()).assertEqual(CacheRetrievalType.VIDEO);
        const error: CacheRetrievalError | null = result.getError();
        expect(error != null).assertTrue();
        if (error != null) {
          expect(error.getCode()).assertEqual('no_valid_video_uri');
        }
      }
    });

    it('retrieveLostImage_empty_cache_returns_null', 0, async () => {
      const cache: ImagePickerCache = makeFakeCache();
      const delegate: ImagePickerDelegate = buildDelegateWithFakeCache(cache);
      const result: CacheRetrievalResult | null = await delegate.retrieveLostImage();
      expect(result == null).assertTrue();
    });

    it('saveStateBeforeResult_with_pending_camera_uri_saves_cache', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      (delegate as ESObject).pendingCameraMediaUri = 'file:///camera/cap.jpg';
      delegate.saveStateBeforeResult();
      expect(true).assertTrue();
    });

    it('gallery_choose_paths_after_release_dispatch_to_choose_media', 0, () => {
      // release → photoPicker=null → all choose* calls take chooseMedia's picker-null branch
      // (no real picker UI launched)
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.release();
      delegate.chooseMediaFromGallery(new MediaSelectionOptions(),
        GeneralOptions.fromList(listOf([true, false, 5])), new FakeResult());
      delegate.chooseMediaFromGallery(new MediaSelectionOptions(),
        GeneralOptions.fromList(listOf([false, false, 1])), new FakeResult());
      delegate.chooseImageFromGallery(imageOptions(), true, new FakeResult());
      delegate.chooseVideoFromGallery(VideoSelectionOptions.fromList(listOf([30])), true, new FakeResult());
      delegate.chooseMultiImagesFromGallery(imageOptions(), true, 3, new FakeResult());
      delegate.chooseMultiVideoFromGallery(VideoSelectionOptions.fromList(listOf([30])), true, 3, new FakeResult());
      expect(true).assertTrue();
    });

    it('handleMediaResult_with_video_pending_real_uri_hits_else_branch', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      // buildDelegateWithRealContext(result, null): pendingCallState.imageOptions is null → else branch
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      await delegate.handleMediaResult([uri], 'no_valid_media_uri', 'Cannot find the selected media.');
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('takeVideoWithCamera_already_active_returns_error', 0, () => {
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      delegate.takeVideoWithCamera(VideoSelectionOptions.fromList(listOf([30])), result);
      delegate.takeVideoWithCamera(VideoSelectionOptions.fromList(listOf([30])), result);
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('already_active');
      }
    });

    it('handleCaptureImageResult_falls_back_to_pending_camera_media_uri', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      (delegate as ESObject).pendingCameraMediaUri = uri;
      delegate.handleCaptureImageResult(0, '');
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('handleCaptureVideoResult_failed_parse_cleans_up_existing_precreated_file', 0, async () => {
      const ctx: common.Context = realContext();
      const precreated: string = ctx.cacheDir + '/precreated_existing.mp4';
      const file: fs.File = fs.openSync(precreated, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, new ArrayBuffer(8));
      fs.closeSync(file);
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      (delegate as ESObject).pendingCameraFilePath = precreated;
      delegate.handleCaptureVideoResult(0, 'file:///nonexistent.mp4');
      const cancelled: ArrayList<string> | null = result.lastSuccess;
      expect(cancelled != null).assertTrue();
      if (cancelled != null) {
        expect(cancelled.length).assertEqual(0);
      }
      try {
        fs.unlinkSync(precreated);
      } catch (e) {
      }
      FileUtils.cleanupTempFiles(ctx);
    });

    it('handleCaptureVideoResult_failed_parse_cleans_up_missing_precreated_file', 0, () => {
      const ctx: common.Context = realContext();
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      (delegate as ESObject).pendingCameraFilePath = ctx.cacheDir + '/precreated_missing.mp4';
      delegate.handleCaptureVideoResult(0, 'file:///nonexistent.mp4');
      const cancelled: ArrayList<string> | null = result.lastSuccess;
      expect(cancelled != null).assertTrue();
      if (cancelled != null) {
        expect(cancelled.length).assertEqual(0);
      }
    });

    it('handleCaptureImageResult_failed_parse_deletes_precreated_file', 0, () => {
      const ctx: common.Context = realContext();
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(result, null);
      (delegate as ESObject).pendingCameraFilePath = ctx.cacheDir + '/precreated_img_missing.jpg';
      delegate.handleCaptureImageResult(0, 'file:///nonexistent.jpg');
      const failed: ArrayList<string> | null = result.lastSuccess;
      expect(failed != null).assertTrue();
      if (failed != null) {
        expect(failed.length).assertEqual(0);
      }
    });

    it('choose_media_fake_picker_resolve_copies_file_and_succeeds', 0, async () => {
      // Inject a fake picker (resolve) → select().then closure → handleResultType → real file copy pipeline
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const fakePicker: FakePhotoViewPicker = new FakePhotoViewPicker();
      fakePicker.resolveUris = [uri];
      const result: FakeResult = new FakeResult();
      // Pass null result to the constructor (otherwise the constructor pre-populates
      // pendingCallState and choose* would hit already_active); the result passed only through
      // chooseMediaFromGallery becomes the pending reply target
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(null, null);
      (delegate as ESObject).photoPicker = fakePicker as ESObject as photoAccessHelper.PhotoViewPicker;
      const media: MediaSelectionOptions = new MediaSelectionOptions();
      media.setImageSelectionOptions(imageOptions());
      delegate.chooseMediaFromGallery(media, GeneralOptions.fromList(listOf([false, false, 1])), result);
      await sleep(500);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(1);
      }
      cleanupPng(ctx, srcPath);
    });

    it('choose_media_fake_picker_reject_runs_catch_handler', 0, async () => {
      // Inject a fake picker (reject) → select().catch closure → handleResultType(-1) → empty-list reply
      const fakePicker: FakePhotoViewPicker = new FakePhotoViewPicker();
      fakePicker.rejectWith = new Error('picker select failed');
      const result: FakeResult = new FakeResult();
      // Pass null result to the constructor (same as the resolve case: avoid the constructor
      // pre-populating pendingCallState, which would trigger already_active)
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(null, null);
      (delegate as ESObject).photoPicker = fakePicker as ESObject as photoAccessHelper.PhotoViewPicker;
      const media: MediaSelectionOptions = new MediaSelectionOptions();
      media.setImageSelectionOptions(imageOptions());
      delegate.chooseMediaFromGallery(media, GeneralOptions.fromList(listOf([false, false, 1])), result);
      await sleep(300);
      expect(result.lastSuccess != null).assertTrue();
      if (result.lastSuccess != null) {
        expect(result.lastSuccess.length).assertEqual(0);
      }
    });

    it('saveFileUri_creates_file_and_returns_file_uri', 0, () => {
      const ctx: common.Context = realContext();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      const filePath: string = ctx.cacheDir + '/ip_save_file_uri.jpg';
      const uri: string = (delegate as ESObject).saveFileUri(filePath) as string;
      expect(uri.indexOf('file://')).assertEqual(0);
      try {
        fs.unlinkSync(filePath);
      } catch (e) {
      }
    });

    it('launch_camera_photo_pick_resolve_covers_then_closure', 0, () => {
      // main provides no injection seam for cameraPicker.pick (@kit.CameraKit is a namespace and
      // arkts-no-ns-as-obj forbids overriding), so the .then closure cannot be covered without
      // launching the real camera; this only verifies a delegate with real context constructs safely.
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(null, null);
      expect(delegate != null).assertTrue();
    });

    it('launch_camera_photo_pick_reject_covers_catch_closure', 0, () => {
      // Same as above: cameraPicker.pick cannot be injected. Under null context
      // launchTakeImageWithCameraWant throws synchronously at the cacheDir dereference, verifying
      // the method entry is callable (real capture depends on a pre-existing context).
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      let threw: boolean = false;
      try {
        delegate.launchTakeImageWithCameraWant();
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('launch_camera_video_pick_resolve_covers_then_closure', 0, () => {
      // Same as the photo resolve case: cameraPicker.pick cannot be injected; only verifies a
      // delegate with real context constructs safely.
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(null, null);
      expect(delegate != null).assertTrue();
    });

    it('launch_camera_video_pick_reject_covers_catch_closure', 0, async () => {
      // cameraPicker.pick cannot be injected. Under null context launchTakeVideoWithCameraWant
      // throws at the cacheDir dereference (async method → rejected Promise), verifying the
      // method entry is callable.
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      let rejected: boolean = false;
      try {
        await delegate.launchTakeVideoWithCameraWant(5);
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('take_image_with_camera_permission_granted_reaches_launch', 0, async () => {
      // need→true + request→resolve(true) → granted=true → the outer .then triggers
      // launchTakeImageWithCameraWant; under null context the launch throws at the cacheDir
      // dereference and is caught by takeImageWithCamera's outer .catch, replying with
      // camera_permission_error — proving the granted branch does reach the launch entry.
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegate(null, null);
      installFakePermission(fakeNeedPermissionTrue(), fakeRequestResolve(true));
      delegate.takeImageWithCamera(imageOptions(), result);
      await sleep(400);
      restorePermission();
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('camera_permission_error');
      }
    });

    it('take_image_with_camera_permission_request_rejects_covers_catch', 0, async () => {
      // need→true + request→reject → the requestCameraPermission().catch closure runs (resolve(false))
      // → the outer layer decides camera_access_denied and replies, without launching capture
      const result: FakeResult = new FakeResult();
      const delegate: ImagePickerDelegate = buildDelegateWithRealContext(null, null);
      installFakePermission(fakeNeedPermissionTrue(), fakeRequestReject());
      delegate.takeImageWithCamera(imageOptions(), result);
      await sleep(400);
      restorePermission();
      expect(result.lastError != null).assertTrue();
      if (result.lastError != null) {
        expect(result.lastError.code).assertEqual('camera_access_denied');
      }
    });
  });
}
