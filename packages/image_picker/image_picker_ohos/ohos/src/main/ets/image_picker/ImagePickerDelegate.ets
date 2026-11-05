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
  // Path of the camera pre-created file: on a successful capture the file is the actual photo/video (kept);
  // deleted on cancel / camera unavailable / result parsing failure, to avoid leaving empty files in cacheDir
  private pendingCameraFilePath: string | null = null;
  private pendingCallState: PendingCallState | null = null;
  private context: common.UIAbilityContext | null = null;
  // photoPicker is nullable: set to null in release() to free system resources, so the PhotoViewPicker
  // instance is not held long-term
  private photoPicker: photoAccessHelper.PhotoViewPicker | null = new photoAccessHelper.PhotoViewPicker();
  private cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;

  constructor(ability: UIAbility, imageResizer: ImageResizer, cache: ImagePickerCache,
    context?: common.UIAbilityContext, pendingImageOptions?: ImageSelectionOptions,
    pendingVideoOptions?: VideoSelectionOptions, result?: Result<ArrayList<string>>) {
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
    // The Dart side asserts non-null on type/paths when decoding CacheRetrievalResult
    // (messages.g.dart result[0]!/result[2]!), so both must be set to non-null values; when missing,
    // fall back to IMAGE and an empty list respectively to avoid a channel decoding crash
    let result = new CacheRetrievalResult();
    let type: ESObject = cacheMap.get(ImagePickerCache.MAP_KEY_TYPE);
    result.setType(type != null ? type as CacheRetrievalType : CacheRetrievalType.IMAGE);
    let error: ESObject = cacheMap.get(ImagePickerCache.MAP_KEY_ERROR);
    if (error != null) {
      result.setError(error as CacheRetrievalError);
    }

    // Type-safe cast: cacheMap.get returns ESObject, and the data type stored in Preferences may not
    // match due to corruption/version migration; a direct as ArrayList hard cast would throw an
    // uncaught exception during iteration; check instanceof first, then cast
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
    // await cache cleanup completes before returning (clear already awaits preferences.clear() + flush() internally)
    await this.cache.clear();
    return result;
  }

  chooseMedia(maxMultiple: number, handleType: string, type?: photoAccessHelper.PhotoViewMIMETypes) {
    const picker: photoAccessHelper.PhotoViewPicker | null = this.photoPicker;
    if (picker == null) {
      // Defensive: no selection should be started after the delegate has been released (photoPicker set to null)
      Log.e(ImagePickerDelegate.TAG, 'chooseMedia: photoPicker is null, picker already released');
      this.finishWithError('internal_error', 'Image picker has been released');
      return;
    }
    let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = type;
    photoSelectOptions.maxSelectNumber = maxMultiple;

    picker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
      // Defensive check: if the delegate was released during selection (pendingCallState already
      // cleared), do not process the result, avoiding the closure holding this long-term and
      // delaying GC (memory inspection recommendation)
      if (this.pendingCallState == null) {
        return;
      }
      this.handleResultType(handleType, 0, photoSelectResult.photoUris)
    }).catch((err: BusinessError) => {
      if (this.pendingCallState == null) {
        return;
      }
      // The error handler itself must be wrapped in try-catch, so an exception thrown by
      // handleResultType does not become an unhandled rejection (a failed Promise cannot be caught again)
      try {
        this.handleResultType(handleType, -1, [])
      } catch (e) {
        Log.e(ImagePickerDelegate.TAG, 'Error handler threw: ' + (e as Error).message);
        // Fallback reply, ensuring the Dart-side Future always receives a result
        this.finishWithListSuccess(new ArrayList<string>());
      }
      Log.e(ImagePickerDelegate.TAG, `PhotoViewPicker.select failed with err: ${err}`)
    })
  }

  handleResultType(handleType: string, code: number, uris: Array<string>) {
    // Persist the selection type and scaling parameters first, so retrieveLostImage can restore the
    // full result after the process is killed
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

  // Select multiple images or multiple videos
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
    // pickMedia is mixed-media (image + video) selection. PhotoViewMIMETypes only has the two
    // constants IMAGE_TYPE/VIDEO_TYPE, with no mixed-type constant, so MIMEType is not set
    // (PhotoSelectOptions.MIMEType keeps its default of unrestricted type, allowing both images
    // and videos to be selected), matching the behavior of Android's PickVisualMedia.ImageAndVideo
    this.chooseMedia(limit, 'handleChooseMediaResult')
  }

  handleChooseMediaResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      this.handleMediaResult(uris, 'no_valid_media_uri', 'Cannot find the selected media.');
    } else {
      // Picker system error: explicitly reply with an empty list (null must not be passed, otherwise
      // finishWithListSuccess cannot reply and the Future hangs)
      this.finishWithListSuccess(new ArrayList<string>());
    }
  }

  // Multiple-image selection result handling: aligned with Android handleChooseMultiImageResult,
  // reporting missing_valid_image_uri on failure (as opposed to the mixed-media no_valid_media_uri)
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
            // Aligned with Android getPathsFromIntent: if any URI cannot be resolved, fail the whole call,
            // instead of skipping that URI and returning partial success
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
            // Aligned with Android getPathsFromIntent: if any URI cannot be resolved, fail the whole call
            this.finishWithError(errorCode, errorMessage);
            return;
          }
          pathList.add(realPath);
        }
      }
      // Empty uris means the user canceled (the picker reports cancel as code=0 with an empty list);
      // return an empty list instead of an error; any URI resolution failure already failed the
      // whole call inside the loop (aligned with Android getPathsFromIntent, where any failure
      // calls finishWithError), so reaching here means all paths were resolved successfully
      this.finishWithListSuccess(pathList);
    } catch (e) {
      // Fallback: async exceptions must propagate to the Flutter layer via finishWithError,
      // otherwise the Dart side receives an empty list and cannot distinguish "user cancel" from
      // "internal error" (aligned with Android exception propagation)
      Log.e(ImagePickerDelegate.TAG, 'handleMediaResult failed: ' + (e as Error).message);
      this.finishWithError('internal_error', 'Failed to process media result: ' + (e as Error).message);
    }
  }

  // Select a single video
  chooseVideoFromGallery(options: VideoSelectionOptions, usePhotoPicker: boolean,
    result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    this.chooseMedia(1, 'handleChooseVideoResult', photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE);
  }

  // Select multiple videos
  chooseMultiVideoFromGallery(options: VideoSelectionOptions, usePhotoPicker: boolean, limit: number,
    result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    // Multiple-video selection must go through handleChooseMultiVideoResult to iterate over all URIs;
    // handleChooseVideoResult only handles uris[0], otherwise multi-select video would return only the first one
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
            // Aligned with Android's no_valid_video_uri error code: return a specific error for an
            // invalid URI instead of an empty result
            this.finishWithError('no_valid_video_uri', 'Cannot find the selected video.');
            return;
          }
      this.handleVideoResult(realPath as string, false);
    } else {
      this.finishWithSuccess(null);
    }
  }

  // Multiple-video selection result handling: iterate all URIs and return the full path list,
  // aligned with Android handleChooseMultiVideoResult
  handleChooseMultiVideoResult(code: number, uris: Array<string>): void {
    if (code == 0) {
      let pathList: ArrayList<string> = new ArrayList();
      for (let uri of uris) {
        let realPath = FileUtils.getPathFromUri(this.context, uri);
        if (realPath == null) {
          Log.e(ImagePickerDelegate.TAG, 'Failed to get path from URI: ' + uri);
          // Aligned with Android getPathsFromIntent (same semantics as OH-040): if any URI cannot
          // be resolved, fail the whole call, instead of skipping failed items and returning
          // partial success
          this.finishWithError('missing_valid_video_uri', 'Cannot find at least one of the selected videos.');
          return;
        }
        pathList.add(realPath);
      }
      // Empty uris means the user canceled; return an empty list. Reaching here means all URIs were
      // resolved successfully
      this.finishWithListSuccess(pathList);
    } else {
      this.finishWithListSuccess(new ArrayList<string>());
    }
  }

  // Launch the camera to record a video
  takeVideoWithCamera(options: VideoSelectionOptions, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(null, options, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }

    // Added: runtime permission check
    // Since ImagePickerUtils.needRequestCameraPermission is callback-based async,
    // use the newly added async permission request method instead
    this.checkAndRequestCameraPermission().then((hasCameraPermission) =>{
      if (!hasCameraPermission) {
        this.pendingCallState = null;  // clear state
        result.error(new FlutterError('camera_access_denied', 'The user did not allow camera access.', null));
        return;
      }
      Log.i(ImagePickerDelegate.TAG, 'launchTakeVideoWithCameraWant duration: ' + options.getMaxDurationSeconds());
      this.launchTakeVideoWithCameraWant(options.getMaxDurationSeconds());
    }).catch((err: BusinessError) => {
         this.pendingCallState = null;  // clear state so later calls do not receive already_active
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

    cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.VIDEO], pickerProfile)
      .then((pickerResult: cameraPicker.PickerResult) => {
      // Modified: pass in resultUri
      this.handleCaptureVideoResult(pickerResult.resultCode, pickerResult.resultUri);
    }).catch((err: BusinessError) => {
          Log.e(ImagePickerDelegate.TAG, 'cameraPicker.pick VIDEO failed: ' + err.message);
          // Delete the pre-created empty file when the camera is unavailable and return a specific
          // error code (aligned with Android's no_available_camera behavior) instead of a silent
          // empty result
          this.cleanupPreCreatedCameraFile();
          this.finishWithError('no_available_camera', 'No cameras available for taking videos.');
        });
  }

  private saveFileUri(filePath: string): string {
    // RandomAccessFile has no closeSync; use openSync to create the file and then closeSync the
    // handle immediately to avoid an fd leak
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

  // Select a single image
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
            // Aligned with Android's no_valid_image_uri error code: return a specific error for an
            // invalid URI instead of an empty result
            this.finishWithError('no_valid_image_uri', 'Cannot find the selected image.');
            return;
          }
      this.handleImageResult(realPath as string, false);
    } else {
      this.finishWithSuccess(null);
    }
  }

  // Select multiple images
  // Signature aligned with Android ImagePickerDelegate.chooseMultiImagesFromGallery(options,
  // usePhotoPicker, limit, result): in the OHOS implementation the usePhotoPicker parameter always
  // uses the native PhotoViewPicker, so only the signature is kept with no branching (same as the
  // sibling methods chooseImageFromGallery/chooseVideoFromGallery/chooseMultiVideoFromGallery).
  chooseMultiImagesFromGallery(options: ImageSelectionOptions, usePhotoPicker: boolean, limit: number,
                               result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(options, null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }
    // Multiple-image selection must go through handleChooseMultiImageResult: report
    // missing_valid_image_uri on failure (aligned with Android), as opposed to the mixed-media
    // handleChooseMediaResult/no_valid_media_uri
    this.chooseMedia(limit, 'handleChooseMultiImageResult', photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE)
  }

  // Launch the camera to take a photo
  takeImageWithCamera(options: ImageSelectionOptions, result: Result<ArrayList<string>>): void {
    if (!this.setPendingOptionsAndResult(options, null, result)) {
      this.finishWithAlreadyActiveError(result);
      return;
    }
      // Added: runtime permission check
      // Since ImagePickerUtils.needRequestCameraPermission is callback-based async,
      // use the newly added async permission request method instead
     this.checkAndRequestCameraPermission().then((hasCameraPermission: boolean) =>{
       if (!hasCameraPermission) {
         this.pendingCallState = null;  // clear state so later calls do not receive already_active
         result.error(new FlutterError('camera_access_denied', 'The user did not allow camera access.', null));
         return;
       }
       this.launchTakeImageWithCameraWant();
      }).catch((err: BusinessError) => {
                 this.pendingCallState = null;  // clear state so later calls do not receive already_active
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

    cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile)
      .then((pickerResult: cameraPicker.PickerResult) => {
      this.pendingCameraMediaUri = pickerResult.resultUri;
      // Modified: pass resultUri instead of the pre-set filePath
      this.handleCaptureImageResult(pickerResult.resultCode, pickerResult.resultUri);
    }).catch((err: BusinessError) => {
           Log.e(ImagePickerDelegate.TAG, 'cameraPicker.pick PHOTO failed: ' + err.message);
           // Delete the pre-created empty file when the camera is unavailable and return a specific
           // error code (aligned with Android's no_available_camera behavior) instead of a silent
           // empty result
           this.cleanupPreCreatedCameraFile();
           this.finishWithError('no_available_camera', 'No cameras available for taking pictures.');
         });
  }

  setPendingOptionsAndResult(imageOptions: ImageSelectionOptions | null, videoOptions: VideoSelectionOptions | null,
    result: Result<ArrayList<string>>): boolean {
    if (this.pendingCallState !== null && this.pendingCallState !== undefined) {
      // A selection call is already in progress; return false so the caller receives already_active,
      // otherwise the new caller's result would be silently dropped and the Dart-side Future would hang forever
      Log.i(ImagePickerDelegate.TAG, 'There is already an open gallery, use it directly to select images');
      return false;
    }
    Log.i(ImagePickerDelegate.TAG, 'Prepare to awaken a new one');
    this.pendingCallState = new PendingCallState(imageOptions, videoOptions, result);
    // This method has a synchronous signature (returns a boolean for the already_active check), so it cannot await;
    // clear() already awaits clear + flush internally, and this selection's result reply (save*)
    // happens after user interaction, far beyond the clear window, so the theoretical race risk is
    // negligible
    this.cache.clear();
    return true;
  }

  finishWithAlreadyActiveError(result: Result<ArrayList<string>>) {
    result.error(new FlutterError('already_active', 'Image picker is already active', null));
  }

  handleCaptureImageResult(code: number, path: string): void {
    if (code === 0) {
      // Resolve the real file path from resultUri
      let realPath: string | null = null;
      if (path) {
        realPath = FileUtils.getPathFromUri(this.context, path);
      }
      // If resolution fails, fall back to pendingCameraMediaUri
      if (!realPath && this.pendingCameraMediaUri) {
        realPath = FileUtils.getPathFromUri(this.context, this.pendingCameraMediaUri);
      }
      if (!realPath) {
            // Result parsing failed: delete the pre-created empty file, then reply with an empty result
            this.cleanupPreCreatedCameraFile();
            this.finishWithSuccess(null);
            Log.e(ImagePickerDelegate.TAG, 'Failed to get file path from URI');
            return;
          }
      // Capture succeeded: the pre-created file is the actual photo; keep the file and clear
      // tracking to avoid mistakenly deleting it on a later cancel
      this.pendingCameraFilePath = null;
      this.handleImageResult(realPath || path, true); // filePath as fallback
    } else {
      // User canceled capture: delete the pre-created empty file to avoid leftovers in cacheDir
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
        // Result parsing failed: delete the pre-created empty file, then reply with an empty result
        this.cleanupPreCreatedCameraFile();
        this.finishWithSuccess(null);
        return;
      }
      // Capture succeeded: the pre-created file is the actual video; keep the file and clear tracking
      this.pendingCameraFilePath = null;
      this.finishWithSuccess(realPath);
    } else {
      // User canceled capture: delete the pre-created empty file to avoid leftovers in cacheDir
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
            // Deletion failure does not affect the final result; continue returning the scaled image path
          }
        }
        this.finishWithSuccess(finalImagePath);
      } else {
        this.finishWithSuccess(path);
      }
    } catch (e) {
      // Fallback: async exceptions must propagate to the Flutter layer via finishWithError,
      // otherwise the Dart side receives null and cannot distinguish "user cancel" from
      // "internal error" (aligned with Android exception propagation)
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
    this.pendingCameraMediaUri = null; // clear camera media URI

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
    this.pendingCameraMediaUri = null; // clear camera media URI

    if (localResult === null) {
      // Same as finishWithSuccess: only write to the cache when non-empty, to avoid an empty list +
      // null error triggering
      // the Dart-side getLostData assert(result.paths.isEmpty != (result.error == null)) failure
      if (path != null && !path.isEmpty()) {
        this.cache.saveResult(path, null, null);
      }
    } else {
      // When path is null, success must still be called back (with an empty list), otherwise the
      // Dart-side Future hangs forever
      // (aligned with Android finishWithListSuccess, which always calls result.success)
      localResult.success(path ?? new ArrayList<string>());
    }
  }

  finishWithError(code: string, message: string): void {
    let localResult: Result<ArrayList<string>> | null = null;
    if (this.pendingCallState != null) {
      localResult = this.pendingCallState.result;
    }
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null; // clear camera media URI
    if (localResult != null) {
      localResult.error(new FlutterError(code, message, null));
    }
  }

  // Clear the pending reply callback when the engine/Ability unbinds, to avoid a dangling result
  // reference delaying delegate GC.
  // Note: pendingCameraFilePath is not deleted here; the file may be an in-progress or completed
  // capture result and must be kept for retrieveLostData
  clearPendingCallState(): void {
    this.pendingCallState = null;
    this.pendingCameraMediaUri = null;
    this.pendingCameraFilePath = null;
  }

  // Delete the camera's pre-created but unused empty file (called on user cancel / camera
  // unavailable / result parsing failure) to avoid leftovers in cacheDir
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

  // Clean up temp files created by the plugin (scaled images, URI copy duplicates) when the engine/Ability unbinds
  cleanupTempFiles(): void {
    FileUtils.cleanupTempFiles(this.context);
  }

  // Release resources in one place when the engine/Ability unbinds: set the PhotoViewPicker
  // instance to null to free system resources, clean up the pending reply callback and temp files,
  // and close Preferences asynchronously (memory inspection: photoPicker/preferences were never
  // released before).
  release(): void {
    this.photoPicker = null;
    this.clearPendingCallState();
    this.cleanupTempFiles();
    // fire-and-forget: cleanup does not block the unbind flow
    this.cache.close();
  }

  async getResizedImagePath(path: string, outputOptions: ImageSelectionOptions): Promise<string> {
    return this.imageResizer.resizeImageIfNeeded(path, outputOptions.getMaxWidth(), outputOptions.getMaxHeight(),
      outputOptions.getQuality());
  }

  // Added helper method for permission checks
  private async checkAndRequestCameraPermission(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      ImagePickerUtils.needRequestCameraPermission((_err: BusinessError, isInManifest: boolean ) => {
        if (!isInManifest) {
          // Permission not declared in the manifest, meaning camera permission is not required
          resolve(true);
          return;
        }
        // Permission declared in the manifest; perform the runtime request
        ImagePickerUtils.requestCameraPermission(this.context as common.Context)
          .then((granted) => resolve(granted))
          .catch(() => resolve(false));
      });
    });
  }

  // Added: video detection method
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