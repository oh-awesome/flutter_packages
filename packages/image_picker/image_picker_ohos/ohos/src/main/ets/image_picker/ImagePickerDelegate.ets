// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on ImagePickerDelegate.java originally written by
// Copyright 2013 The Flutter Authors.

import ArrayList from '@ohos.util.ArrayList';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import fs from '@ohos.file.fs'
import common from '@ohos.app.ability.common';
import ImagePickerCache, { CacheType } from './ImagePickerCache'
import FileUtils from './FileUtils'
import { fileUri } from '@kit.CoreFileKit';
import {
  FlutterError,
  ImageSelectionOptions,
  VideoSelectionOptions,
  Result,
  CacheRetrievalResult,
  CacheRetrievalError,
  CacheRetrievalType,
  MediaSelectionOptions,
  GeneralOptions
} from './Messages'
import ImageResizer from './ImageResizer';
import HashMap from '@ohos.util.HashMap';
import UIAbility from '@ohos.app.ability.UIAbility';
import { BusinessError } from '@ohos.base';
import { cameraPicker, camera } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import DateTimeUtil from './DateTimeUtil';
import ImagePickerUtils from './ImagePickerUtils';

export default class ImagePickerDelegate {
  private static TAG = 'ImagePickerDelegate';
  private imageResizer: ImageResizer;
  private cache: ImagePickerCache;
  private pendingCameraMediaUri: string | null = null;
  // 相机预创建文件路径：拍摄成功时该文件即真实照片/视频（保留），
  // 取消/相机不可用/结果解析失败时删除，避免 cacheDir 残留空文件
  private pendingCameraFilePath: string | null = null;
  private pendingCallState: PendingCallState | null = null;
  private context: common.UIAbilityContext | null = null;
  // photoPicker 可空：release() 时置 null 释放系统资源，避免 PhotoViewPicker 实例被长期持有
  private photoPicker: photoAccessHelper.PhotoViewPicker | null = new photoAccessHelper.PhotoViewPicker();
  private cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;

  constructor(ability: UIAbility, imageResizer: ImageResizer, cache: ImagePickerCache, context?: common.UIAbilityContext,
    pendingImageOptions?: ImageSelectionOptions, pendingVideoOptions?: VideoSelectionOptions,
    result?: Result<ArrayList<string>>) {
    this.imageResizer = imageResizer;
    if (result != null) {
      this.pendingCallState = new PendingCallState(pendingImageOptions as ESObject, pendingVideoOptions, result);
    }
    this.cache = cache;
    this.context = ability.context;
  }

  setCameraDevice(device: CameraDevice): void {
    if (device == CameraDevice.REAR) {
      this.cameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
    }

    if (device == CameraDevice.FRONT) {
      this.cameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
    }
  }

  saveStateBeforeResult(): void {
    let localImageOptions: ImageSelectionOptions;

    if (this.pendingCallState == null) {
      return;
    }
    localImageOptions = this.pendingCallState.imageOptions;

    this.cache.saveType(localImageOptions != null ? CacheType.IMAGE : CacheType.VIDEO);
    if (localImageOptions != null) {
      this.cache.saveDimensionWithOutputOptions(localImageOptions);
    }

    let localPendingCameraMediaUri = this.pendingCameraMediaUri;
    if (localPendingCameraMediaUri != null) {
      this.cache.savePendingCameraMediaUriPath(localPendingCameraMediaUri);
    }
  }

  async retrieveLostImage(): Promise<CacheRetrievalResult | null> {
    // let cacheMap: HashMap<string, ESObject|null> = await this.cache.getCacheMap().then(map=> {
    //   return map;
    // });
    let cacheMap: HashMap<string, ESObject | null> = await this.cache.getCacheMap()
    if (cacheMap.isEmpty()) {
      return null;
    }
    // Dart 侧解码 CacheRetrievalResult 时对 type/paths 做非空断言（messages.g.dart result[0]!/result[2]!），
    // 因此二者必须设置非空值，缺失时分别按 IMAGE 和空列表兜底，避免通道解码崩溃
    let result = new CacheRetrievalResult();
    let type: ESObject = cacheMap.get(ImagePickerCache.MAP_KEY_TYPE);
    result.setType(type != null ? type as CacheRetrievalType : CacheRetrievalType.IMAGE);
    let error: ESObject = cacheMap.get(ImagePickerCache.MAP_KEY_ERROR);
    if (error != null) {
      result.setError(error as CacheRetrievalError);
    }

    // 类型安全转型：cacheMap.get 返回 ESObject，Preference 中数据类型可能因损坏/版本迁移而不匹配，
    // 直接 as ArrayList 强转会在遍历时抛未捕获异常；先 instanceof 校验再转型
    let pathListRaw: ESObject = cacheMap.get(ImagePickerCache.MAP_KEY_PATH_LIST);
    let pathList: ArrayList<string> | null = null;
    if (pathListRaw != null && pathListRaw instanceof ArrayList) {
      pathList = pathListRaw as ArrayList<string>;
    }
    let newPathList: ArrayList<string> = new ArrayList();
    if (pathList != null) {
      for (let path of pathList) {
        let maxWidth: number = cacheMap.get(ImagePickerCache.MAP_KEY_MAX_WIDTH) as number;
        let maxHeight: number = cacheMap.get(ImagePickerCache.MAP_KEY_MAX_HEIGHT) as number;
        let boxedImageQuality: number = cacheMap.get(ImagePickerCache.MAP_KEY_IMAGE_QUALITY) as number;
        let imageQulity: number = boxedImageQuality == null ? 100 : boxedImageQuality;

        newPathList.add(await this.imageResizer.resizeImageIfNeeded(path, maxWidth, maxHeight, imageQulity)
          .then((fileName) => {
            return fileName;
          })
        );
      }
    }
    result.setPaths(newPathList);
    // await 缓存清理完成后再返回（clear 内部已 await preferences.clear() + flush()）
    await this.cache.clear();
    return result;
  }

  chooseMedia(maxMultiple: number, handleType: string, type?: photoAccessHelper.PhotoViewMIMETypes) {
    const picker: photoAccessHelper.PhotoViewPicker | null = this.photoPicker;
    if (picker == null) {
      // 防御：delegate 已 release（photoPicker 置 null）后不应再发起选择
      Log.e(ImagePickerDelegate.TAG, 'chooseMedia: photoPicker is null, picker already released');
      this.finishWithError('internal_error', 'Image picker has been released');
      return;
    }
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = type;
    photoSelectOptions.maxSelectNumber = maxMultiple;

    picker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
      // 防御性检查：若选择期间 delegate 被释放（pendingCallState 已清空），不再处理结果，
      // 避免闭包长期持有 this 引用形成延迟 GC（内存检视建议）
      if (this.pendingCallState == null) {
        return;
      }
      this.handleResultType(handleType, 0, photoSelectResult.photoUris)
    }).catch((err: BusinessError) => {
      if (this.pendingCallState == null) {
        return;
      }
      // 异常处理器自身需 try-catch 包裹，避免 handleResultType 抛异常形成未处理拒绝（Promise 二次失败无法再被捕获）
      try {
        this.handleResultType(handleType, -1, [])
      } catch (e) {
        Log.e(ImagePickerDelegate.TAG, 'Error handler threw: ' + (e as Error).message);
        // 兜底回包，确保 Dart 侧 Future 一定收到结果
        this.finishWithListSuccess(new ArrayList<string>());
      }
      Log.e(ImagePickerDelegate.TAG, `PhotoViewPicker.select failed with err: ${err}`)
    })
  }

  handleResultType(handleType: string, code: number, uris: Array<string>) {
    // 先持久化本次选择的类型和缩放参数，进程被杀后 retrieveLostImage 才能恢复出完整结果
    this.saveStateBeforeResult();
    switch (handleType) {
      case 'handleChooseVideoResult':
        this.handleChooseVideoResult(code, uris);
        break;
      case 'handleChooseImageResult':
        this.handleChooseImageResult(code, uris);
        break;
      case 'handleChooseMediaResult':
        this.handleChooseMediaResult(code, uris);
        break;
      case 'handleChooseMultiImageResult':
        this.handleChooseMultiImageResult(code, uris);
        break;
      case 'handleChooseMultiVideoResult':
        this.handleChooseMultiVideoResult(code, uris);
        break;
    }
  }

  // 选择多个图片或者多个视频
  chooseMediaFromGallery(options: MediaSelectionOptions, generalOptions: GeneralOptions,
    result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(options.getImageSelectionOptions(), null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }
    let limit = 1;
    if (generalOptions.getAllowMultiple()) {
      limit = generalOptions.getLimit();
    }
    // pickMedia 为混合媒体（图片+视频）选择。PhotoViewMIMETypes 仅有 IMAGE_TYPE/VIDEO_TYPE 两个常量，
    // 无混合类型常量，故不设置 MIMEType（PhotoSelectOptions.MIMEType 保持默认不限制类型，
    // 图片和视频均可选），与 Android 的 PickVisualMedia.ImageAndVideo 行为一致
    this.chooseMedia(limit, 'handleChooseMediaResult')
  }

  handleChooseMediaResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      this.handleMediaResult(uris, 'no_valid_media_uri', 'Cannot find the selected media.');
    } else {
      // 选择器系统错误：显式回包空列表（不能传 null，否则 finishWithListSuccess 无法回包导致 Future 挂起）
      this.finishWithListSuccess(new ArrayList<string>());
    }
  }

  // 多图片选择结果处理：与 Android handleChooseMultiImageResult 对齐，
  // 失败时报 missing_valid_image_uri（区别于混合媒体的 no_valid_media_uri）
  handleChooseMultiImageResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      this.handleMediaResult(uris, 'missing_valid_image_uri', 'Cannot find at least one of the selected images.');
    } else {
      this.finishWithListSuccess(new ArrayList<string>());
    }
  }

  async handleMediaResult(uris: Array<string>, errorCode: string, errorMessage: string): Promise<void> {
    try {
      let localImageOptions: ImageSelectionOptions | null = null;
      if (this.pendingCallState != null) {
        localImageOptions = this.pendingCallState.imageOptions;
      }
      let pathList: ArrayList<string> = new ArrayList();
      if (localImageOptions != null && localImageOptions != undefined) {
        for (let path of uris) {
          let isVideo = this.isVideoFile(path);
          if (path.search('video/') < 0 && !isVideo && this.pendingCallState) {
            path = await this.getResizedImagePath(path, this.pendingCallState.imageOptions);
          }
          let realPath = FileUtils.getPathFromUri(this.context, path);
          Log.i(ImagePickerDelegate.TAG, 'getPathFromUri : ' + realPath);
          if (realPath == null) {
            Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + path);
            // 与 Android getPathsFromIntent 对齐：任一 URI 无法解析即整体报错，
            // 而非跳过该 URI 返回部分成功
            this.finishWithError(errorCode, errorMessage);
            return;
          }
          pathList.add(realPath);
        }
      } else {
        for (let path of uris) {
          let realPath = FileUtils.getPathFromUri(this.context, path);
          if (realPath == null) {
            Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + path);
            // 与 Android getPathsFromIntent 对齐：任一 URI 无法解析即整体报错
            this.finishWithError(errorCode, errorMessage);
            return;
          }
          pathList.add(realPath);
        }
      }
      // uris 为空表示用户取消（选择器以 code=0 + 空列表回调取消），返回空列表而非错误；
      // 任一 URI 解析失败已在循环内整体报错（与 Android getPathsFromIntent 任一失败即
      // finishWithError 对齐），能走到这里说明所有路径均解析成功
      this.finishWithListSuccess(pathList);
    } catch (e) {
      // 兜底：异步异常必须通过 finishWithError 传播到 Flutter 层，
      // 否则 Dart 侧收到空列表无法区分"用户取消"与"内部错误"（与 Android 异常传播对齐）
      Log.e(ImagePickerDelegate.TAG, 'handleMediaResult failed: ' + (e as Error).message);
      this.finishWithError('internal_error', 'Failed to process media result: ' + (e as Error).message);
    }
  }

  // 选择一个视频
  chooseVideoFromGallery(options: VideoSelectionOptions, usePhotoPicker: boolean, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    this.chooseMedia(1, 'handleChooseVideoResult', photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE);
  }

  // 选择多个视频
  chooseMultiVideoFromGallery(options: VideoSelectionOptions, usePhotoPicker: boolean, limit: number, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    // 多视频选择必须走 handleChooseMultiVideoResult 遍历所有 URI，
    // handleChooseVideoResult 仅处理 uris[0]，否则多选视频只会返回第一个
    this.chooseMedia(limit, 'handleChooseMultiVideoResult', photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE);
  }

  handleChooseVideoResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      if (uris.length === 0) {
        Log.e(ImagePickerDelegate.TAG, 'handleChooseVideoResult: empty uri list');
        this.finishWithSuccess(null);
        return;
      }
      let realPath = FileUtils.getPathFromUri(this.context, uris[0]);
        if (realPath == null) {
            Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + uris[0]);
            // 与 Android no_valid_video_uri 错误码对齐：URI 无效时返回具体错误而非空结果
            this.finishWithError('no_valid_video_uri', 'Cannot find the selected video.');
            return;
          }
      this.handleVideoResult(realPath as string, false);
    } else {
      this.finishWithSuccess(null);
    }
  }

  // 多视频选择结果处理：遍历所有 URI 返回完整路径列表，与 Android handleChooseMultiVideoResult 对齐
  handleChooseMultiVideoResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      let pathList: ArrayList<string> = new ArrayList();
      for (let uri of uris) {
        let realPath = FileUtils.getPathFromUri(this.context, uri);
        if (realPath == null) {
          Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + uri);
          // 与 Android getPathsFromIntent 对齐（OH-040 同语义）：任一 URI 无法解析即整体报错，
          // 而非跳过失败项返回部分成功
          this.finishWithError('missing_valid_video_uri', 'Cannot find at least one of the selected videos.');
          return;
        }
        pathList.add(realPath);
      }
      // uris 为空表示用户取消，返回空列表；能走到这里说明所有 URI 均解析成功
      this.finishWithListSuccess(pathList);
    } else {
      this.finishWithListSuccess(new ArrayList<string>());
    }
  }

  // 唤起相机录像
  takeVideoWithCamera(options: VideoSelectionOptions, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    // 新增：运行时权限检查
    // 由于 ImagePickerUtils.needRequestCameraPermission 是异步回调方式
    // 改为使用新增的异步权限请求方法
    this.checkAndRequestCameraPermission().then((hasCameraPermission) =>{
      if (!hasCameraPermission) {
        this.pendingCallState = null;  // 清理状态
        result.error(new FlutterError('camera_access_denied', 'The user did not allow camera access.', null));
        return;
      }
      Log.i(ImagePickerDelegate.TAG, 'launchTakeVideoWithCameraWant duration: ' + options.getMaxDurationSeconds());
      this.launchTakeVideoWithCameraWant(options.getMaxDurationSeconds());
    }).catch((err: BusinessError) => {
         this.pendingCallState = null;  // 清理状态，避免后续调用收到 already_active
         result.error(new FlutterError('camera_permission_error',err.message, null));
         return;
    });
  }

  async launchTakeVideoWithCameraWant(duration: number): Promise<void> {
    const fileName = this.saveFileName(false);
    let filePath = `${(this.context as Context).cacheDir}/${fileName}`;
    this.pendingCameraFilePath = filePath;
    let pickerProfile: cameraPicker.PickerProfile = {
      cameraPosition: this.cameraPosition,
      videoDuration: duration,
      saveUri: this.saveFileUri(filePath)
    }

    cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.VIDEO], pickerProfile).then((pickerResult: cameraPicker.PickerResult) => {
      // 修改：传入 resultUri
      this.handleCaptureVideoResult(pickerResult.resultCode, pickerResult.resultUri);
    }).catch((err: BusinessError) => {
          Log.e(ImagePickerDelegate.TAG, 'cameraPicker.pick VIDEO failed: ' + err.message);
          // 相机不可用时删除预创建空文件，并返回具体错误码（与 Android no_available_camera 行为对齐），而非静默空结果
          this.cleanupPreCreatedCameraFile();
          this.finishWithError('no_available_camera', 'No cameras available for taking videos.');
        });
  }

  private saveFileUri(filePath: string): string {
    // RandomAccessFile 无 closeSync，改用 openSync 创建文件后立即 closeSync 关闭句柄，避免 fd 泄漏
    const file = fs.openSync(filePath, fs.OpenMode.CREATE);
    try {
      return fileUri.getUriFromPath(filePath);
    } finally {
      fs.closeSync(file);
    }
  }

  private saveFileName(isPhoto: boolean): string{
    const dateTimeUtil: DateTimeUtil = new DateTimeUtil();
    const date: string = dateTimeUtil.getDate();
    const time: string = dateTimeUtil.getTime();
    if (isPhoto) {
      return `${`IMG_${date}_${time}`}.jpg`;
    } else {
      return `${`VID_${date}_${time}`}.mp4`;
    }
  }

  // 选择单个图片
  chooseImageFromGallery(options: ImageSelectionOptions, usePhotoPicker: boolean, result: Result<ArrayList<string>>) {
    Log.i(ImagePickerDelegate.TAG, 'chooseImageFromGallery enter');
    if (!this.setPendingOptionsAndResult(options, null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    this.chooseMedia(1, 'handleChooseImageResult', photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE)
  }

  handleChooseImageResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      if (uris.length === 0) {
        Log.e(ImagePickerDelegate.TAG, 'handleChooseImageResult: empty uri list');
        this.finishWithSuccess(null);
        return;
      }
      let realPath = FileUtils.getPathFromUri(this.context, uris[0]);
      if (realPath == null) {
            Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + uris[0]);
            // 与 Android no_valid_image_uri 错误码对齐：URI 无效时返回具体错误而非空结果
            this.finishWithError('no_valid_image_uri', 'Cannot find the selected image.');
            return;
          }
      this.handleImageResult(realPath as string, false);
    } else {
      this.finishWithSuccess(null);
    }
  }

  // 选择多个图片
  // 签名与 Android ImagePickerDelegate.chooseMultiImagesFromGallery(options, usePhotoPicker, limit, result)
  // 对齐：usePhotoPicker 参数在 OHOS 实现中恒走原生 PhotoViewPicker，故仅保留签名不做分支（与
  // chooseImageFromGallery/chooseVideoFromGallery/chooseMultiVideoFromGallery 兄弟方法一致）。
  chooseMultiImagesFromGallery(options: ImageSelectionOptions, usePhotoPicker: boolean, limit: number,
                               result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(options, null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }
    // 多图选择须走 handleChooseMultiImageResult：失败时报 missing_valid_image_uri（与 Android 对齐），
    // 区别于混合媒体的 handleChooseMediaResult/no_valid_media_uri
    this.chooseMedia(limit, 'handleChooseMultiImageResult', photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE)
  }

  // 唤起相机拍照
  takeImageWithCamera(options: ImageSelectionOptions, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(options, null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }
      // 新增：运行时权限检查
      // 由于 ImagePickerUtils.needRequestCameraPermission 是异步回调方式
      // 改为使用新增的异步权限请求方法
     this.checkAndRequestCameraPermission().then((hasCameraPermission: boolean) =>{
       if (!hasCameraPermission) {
         this.pendingCallState = null;  // 清理状态，避免后续调用收到 already_active
         result.error(new FlutterError('camera_access_denied', 'The user did not allow camera access.', null));
         return;
       }
       this.launchTakeImageWithCameraWant();
      }).catch((err: BusinessError) => {
                 this.pendingCallState = null;  // 清理状态，避免后续调用收到 already_active
                 result.error(new FlutterError('camera_permission_error',err.message, null));
                 return;
            });

  }

  launchTakeImageWithCameraWant() {
    const fileName = this.saveFileName(true);
    let filePath = `${(this.context as Context).cacheDir}/${fileName}`;
    this.pendingCameraFilePath = filePath;
    let pickerProfile: cameraPicker.PickerProfile = {
      cameraPosition: this.cameraPosition,
      saveUri: this.saveFileUri(filePath)
    }

    cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile).then((pickerResult: cameraPicker.PickerResult) => {
      this.pendingCameraMediaUri = pickerResult.resultUri;
      // 修改：传入 resultUri 而非预设的 filePath
      this.handleCaptureImageResult(pickerResult.resultCode, pickerResult.resultUri);
    }).catch((err: BusinessError) => {
           Log.e(ImagePickerDelegate.TAG, 'cameraPicker.pick PHOTO failed: ' + err.message);
           // 相机不可用时删除预创建空文件，并返回具体错误码（与 Android no_available_camera 行为对齐），而非静默空结果
           this.cleanupPreCreatedCameraFile();
           this.finishWithError('no_available_camera', 'No cameras available for taking pictures.');
         });
  }

  setPendingOptionsAndResult(imageOptions: ImageSelectionOptions | null, videoOptions: VideoSelectionOptions | null,
    result: Result<ArrayList<string>>): boolean {
    if (this.pendingCallState !== null && this.pendingCallState !== undefined) {
      // 已有进行中的选择调用，返回 false 让调用方收到 already_active，
      // 否则新调用方的 result 会被静默丢弃，Dart 侧 Future 永久挂起
      Log.i(ImagePickerDelegate.TAG, 'There is already an open gallery, use it directly to select images');
      return false;
    }
    Log.i(ImagePickerDelegate.TAG, 'Prepare to awaken a new one');
    this.pendingCallState = new PendingCallState(imageOptions, videoOptions, result);
    // 此方法为同步签名（返回 boolean 供 already_active 判断），无法 await；
    // clear() 内部已 await clear + flush，本次选择结果回包（save*）发生在用户交互之后，
    // 远超 clear 窗口，理论竞态风险可忽略
    this.cache.clear();
    return true;
  }

  finishWithAlreadyActiveError(result: Result<ArrayList<string>>) {
    result.error(new FlutterError('already_active', 'Image picker is already active', null));
  }

  handleCaptureImageResult(code: number, path: string): void {
    if (code === 0) {
      // 使用 resultUri 解析真实文件路径
      let realPath: string | null = null;
      if (path) {
        realPath = FileUtils.getPathFromUri(this.context, path);
      }
      // 如果解析失败，回退到 pendingCameraMediaUri
      if (!realPath && this.pendingCameraMediaUri) {
        realPath = FileUtils.getPathFromUri(this.context, this.pendingCameraMediaUri);
      }
      if (!realPath) {
            // 结果解析失败：删除预创建的空文件后回包空结果
            this.cleanupPreCreatedCameraFile();
            this.finishWithSuccess(null);
            Log.e(ImagePickerDelegate.TAG, 'Failed to get file path from URI');
            return;
          }
      // 拍摄成功：预创建文件即为真实照片，保留文件并清除跟踪，避免后续取消误删
      this.pendingCameraFilePath = null;
      this.handleImageResult(realPath || path, true); // filePath 作为兜底
    } else {
      // 用户取消拍摄：删除预创建的空文件，避免 cacheDir 残留
      this.cleanupPreCreatedCameraFile();
      this.finishWithSuccess(null);
    }
  }

  handleCaptureVideoResult(code: number, path: string): void {
    if (code === 0) {
      let realPath: string | null = null;
      if (path) {
        realPath = FileUtils.getPathFromUri(this.context, path);
      }
      if (!realPath) {
        Log.e(ImagePickerDelegate.TAG, 'Failed to get video path from camera capture URI');
        // 结果解析失败：删除预创建的空文件后回包空结果
        this.cleanupPreCreatedCameraFile();
        this.finishWithSuccess(null);
        return;
      }
      // 拍摄成功：预创建文件即为真实视频，保留文件并清除跟踪
      this.pendingCameraFilePath = null;
      this.finishWithSuccess(realPath);
    } else {
      // 用户取消拍摄：删除预创建的空文件，避免 cacheDir 残留
      this.cleanupPreCreatedCameraFile();
      this.finishWithSuccess(null);
    }
  }

  async handleImageResult(path: string, shouldDeleteOriginalIfScaled: boolean): Promise<void> {
    try {
      Log.i(ImagePickerDelegate.TAG, 'handleImageResult enter');
      let localImageOptions: ImageSelectionOptions | null = null;
      if (this.pendingCallState != null) {
        localImageOptions = this.pendingCallState.imageOptions;
      }

      if (localImageOptions != null) {
        let finalImagePath = await this.getResizedImagePath(path, localImageOptions);
        if (finalImagePath != null && finalImagePath != path && shouldDeleteOriginalIfScaled) {
        try {
            fs.unlink(path);
          } catch (e) {
            Log.e(ImagePickerDelegate.TAG, 'Failed to delete original file: ' + e);
            // 删除失败不影响最终结果，继续返回缩放后的图片路径
          }
        }
        this.finishWithSuccess(finalImagePath);
      } else {
        this.finishWithSuccess(path);
      }
    } catch (e) {
      // 兜底：异步异常必须通过 finishWithError 传播到 Flutter 层，
      // 否则 Dart 侧收到 null 无法区分"用户取消"与"内部错误"（与 Android 异常传播对齐）
      Log.e(ImagePickerDelegate.TAG, 'handleImageResult failed: ' + (e as Error).message);
      this.finishWithError('internal_error', 'Failed to process image result: ' + (e as Error).message);
    }
  }

  handleVideoResult(path: string | null, shouldDeleteOriginalIfScaled: boolean): void {
    this.finishWithSuccess(path);
  }

  finishWithSuccess(path: string | null): void {
    Log.i(ImagePickerDelegate.TAG, path);
    let pathList: ArrayList<string> = new ArrayList();
    if (path !== null) {
      pathList.add(path)
    }
    let localResult: Result<ArrayList<string>> | null = null;

    if (this.pendingCallState !== null) {
      localResult = this.pendingCallState.result;
    }
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null; // 清理相机媒体URI

    if (localResult === null) {
      if (!pathList.isEmpty()) {
        this.cache.saveResult(pathList, null, null);
      }
    } else {
      localResult.success(pathList);
    }
  }

  finishWithListSuccess(path: ArrayList<string> | null): void {
    let localResult: Result<ArrayList<string>> | null = null;
    if (this.pendingCallState != null) {
      localResult = this.pendingCallState.result;
    }
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null; // 清理相机媒体URI

    if (localResult === null) {
      // 与 finishWithSuccess 一致：仅在非空时写入缓存，避免空列表 + null error 触发
      // Dart 侧 getLostData 的 assert(result.paths.isEmpty != (result.error == null)) 失败
      if (path != null && !path.isEmpty()) {
        this.cache.saveResult(path, null, null);
      }
    } else {
      // path 为 null 时也必须回调 success(空列表)，否则 Dart 侧 Future 永久挂起
      // （与 Android finishWithListSuccess 始终调用 result.success 的行为对齐）
      localResult.success(path ?? new ArrayList<string>());
    }
  }

  finishWithError(code: string, message: string): void {
    let localResult: Result<ArrayList<string>> | null = null;
    if (this.pendingCallState != null) {
      localResult = this.pendingCallState.result;
    }
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null; // 清理相机媒体URI
    if (localResult != null) {
      localResult.error(new FlutterError(code, message, null));
    }
  }

  // 引擎/Ability 解绑时清理待回复回调，避免 result 引用悬挂导致 delegate 延迟 GC。
  // 注意：此处不删除 pendingCameraFilePath，该文件可能是拍摄中/已完成的结果，需保留供 retrieveLostData 使用
  clearPendingCallState(): void {
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null;
    this.pendingCameraFilePath = null;
  }

  // 删除相机预创建但未使用的空文件（用户取消/相机不可用/结果解析失败时调用），避免 cacheDir 残留
  private cleanupPreCreatedCameraFile(): void {
    if (this.pendingCameraFilePath != null) {
      try {
        fs.unlink(this.pendingCameraFilePath);
      } catch (e) {
        Log.e(ImagePickerDelegate.TAG, 'Failed to delete pre-created camera file: ' + (e as Error).message);
      }
      this.pendingCameraFilePath = null;
    }
  }

  // 引擎/Ability 解绑时清理插件创建的临时文件（缩放图片、URI 拷贝副本）
  cleanupTempFiles(): void {
    FileUtils.cleanupTempFiles(this.context);
  }

  // 引擎/Ability 解绑时统一释放资源：PhotoViewPicker 实例置 null 释放系统资源，
  // 同时清理待回复回调与临时文件，并异步关闭 Preferences（内存检视：photoPicker/preferences 此前从未被释放）。
  release(): void {
    this.photoPicker = null;
    this.clearPendingCallState();
    this.cleanupTempFiles();
    // fire-and-forget：cleanup 不阻塞解绑流程
    this.cache.close();
  }

  async getResizedImagePath(path: string, outputOptions: ImageSelectionOptions): Promise<string> {
    return this.imageResizer.resizeImageIfNeeded(path, outputOptions.getMaxWidth(), outputOptions.getMaxHeight(),
      outputOptions.getQuality());
  }

  // 新增辅助方法检查权限
  private async checkAndRequestCameraPermission(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      ImagePickerUtils.needRequestCameraPermission((_err: BusinessError, isInManifest: boolean ) => {
        if (!isInManifest) {
          // manifest 中未声明权限，说明不需要相机权限
          resolve(true);
          return;
        }
        // manifest 中声明了权限，进行运行时请求
        ImagePickerUtils.requestCameraPermission(this.context as common.Context)
          .then((granted) => resolve(granted))
          .catch(() => resolve(false));
      });
    });
  }

  // 新增：视频判断方法
  private isVideoFile(filePath: string): boolean {
    const videoExtensions = ['.mp4', '.3gp', '.mkv', '.webm', '.avi', '.mov', '.m4v'];
    const lowerPath = filePath.toLowerCase();
    return videoExtensions.some(ext => lowerPath.endsWith(ext));
  }
}

class PendingCallState {
  imageOptions: ImageSelectionOptions;
  videoOptions: VideoSelectionOptions;
  result: Result<ArrayList<string>>;

  constructor(imageOptions: ImageSelectionOptions | ESObject, videoOptions: VideoSelectionOptions | ESObject,
    result: Result<ArrayList<string>>) {
    this.imageOptions = imageOptions;
    this.videoOptions = videoOptions;
    this.result = result;
  }
}

export enum CameraDevice {
  REAR,
  FRONT
}