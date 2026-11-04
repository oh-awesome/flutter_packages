// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on ImagePickerPlugin.java originally written by
// Copyright 2013 The Flutter Authors.

import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';

import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import common from '@ohos.app.ability.common';
import Ability from '@ohos.app.ability.Ability';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import ImagePickerDelegate, { CameraDevice } from './ImagePickerDelegate';
import {
  GeneralOptions,
  ImagePickerApi,
  ImageSelectionOptions,
  SourceSpecification,
  Result,
  SourceType,
  MediaSelectionOptions,
  CacheRetrievalResult,
  VideoSelectionOptions,
  SourceCamera,
  FlutterError
} from './Messages';
import ImagePickerCache from './ImagePickerCache';
import ExifDataCopier from './ExifDataCopier';
import ImageResizer from './ImageResizer';
import UIAbility from '@ohos.app.ability.UIAbility';
import ArrayList from '@ohos.util.ArrayList';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'ImagePickerPlugin';

// implements ImagePickerApi is commented out: ArkTS's implements clause only accepts interfaces
// (arkts-implements-only-iface), while ImagePickerApi is an abstract class with static getCodec/setup,
// which cannot be turned into an interface (static methods cannot enter an interface); restoring
// implements causes a compile failure (verified by test, rolled back under OH-014).
// Here the Pigeon handler is attached via duck typing with `this as ESObject`; signature validation
// relies on the forced cast in the Messages.ets setup plus the entry-level try-catch fallback,
// which is the established practice under this ArkTS language limitation.
export default class ImagePickerPlugin implements FlutterPlugin, AbilityAware {
  private static TAG = 'ImagePickerPlugin';
  private pluginBinding: FlutterPluginBinding | null = null;
  private state: AbilityState | null = null;

  getUniqueClassName(): string {
    return ImagePickerPlugin.TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
    // On engine detach, release AbilityState synchronously and unregister the MessageChannel
    // handlers, avoiding dangling callbacks and leftover resources
    if (this.state != null) {
      this.state.release();
      this.state = null;
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    if (!this.pluginBinding) {
      return
    }
    this.setup(this.pluginBinding.getBinaryMessenger(), this.pluginBinding.getApplicationContext(),
      binding.getAbility(), binding);
  }

  onDetachedFromAbility(): void {
    if (this.state != null) {
      this.state.release();
      this.state = null;
    }
  }

  setup(messenger: BinaryMessenger, context: common.Context, ability: UIAbility, binding: AbilityPluginBinding): void {
    // Defensive: if an old AbilityState exists (onAttachedToAbility may fire repeatedly in abnormal scenarios),
    // release the old instance first to unregister its message handlers, avoiding leftover
    // handlers on the 4 BasicMessageChannels
    if (this.state != null) {
      this.state.release();
    }
    this.state = new AbilityState(ability, null, messenger, this as ESObject, binding, context);
  }

  constructor(delegate?: ImagePickerDelegate, ability?: UIAbility) {
    if (delegate != null && ability != null) {
      this.state = new AbilityState(ability, delegate);
    }
  }

  pickImages(source: SourceSpecification, options: ImageSelectionOptions,
      generalOptions: GeneralOptions, result: Result<ArrayList<string>>) {
    // Defensive argument boundary validation at the ArkTS layer (already validated on the Dart
    // side; this is a second line of defense in this standalone module)
    if (!this.validateImageOptions(options, result) || !this.validateGeneralOptions(generalOptions, result)) {
      return;
    }
    let delegate: ImagePickerDelegate | null = this.getImagePickerDelegate();
    if (delegate === null) {
      result.error(new FlutterError('no_activity', 'image_picker plugin requires a foreground ability', null));
      return;
    }
    try {
      this.setCameraDevice(delegate, source);
      if (generalOptions.getAllowMultiple()) {
        delegate.chooseMultiImagesFromGallery(options, generalOptions.getUsePhotoPicker(),
          generalOptions.getLimit(), result);
      } else {
        switch (source.getType()) {
          case SourceType.GALLERY: {
            delegate.chooseImageFromGallery(options, generalOptions.getUsePhotoPicker(), result);
            break;
          }
          case SourceType.CAMERA: {
            delegate.takeImageWithCamera(options, result);
            break;
          }
          default: {
            // Defensive fallback: an unknown source type must reply with an error,
            // otherwise the Dart-side Future hangs forever
            result.error(new FlutterError('invalid_source', 'Unknown source type', null));
            break;
          }
        }
      }
    } catch (e) {
      // Entry-level fallback: convert synchronous exceptions into an error reply,
      // preventing the Dart-side Future from hanging forever
      Log.e(TAG, 'pickImages failed: ' + (e as Error).message);
      result.error(new FlutterError('pick_images_failed', 'Failed to pick images: ' + (e as Error).message, null));
    }
  }

  pickVideos(source: SourceSpecification, options: VideoSelectionOptions,
      generalOptions: GeneralOptions, result: Result<ArrayList<string>>): void {
    // Defensive argument boundary validation at the ArkTS layer
    if (!this.validateVideoOptions(options, result) || !this.validateGeneralOptions(generalOptions, result)) {
      return;
    }
    let delegate: ImagePickerDelegate | null = this.getImagePickerDelegate();
    if (delegate === null) {
      result.error(new FlutterError('no_activity', 'image_picker plugin requires a foreground ability', null));
      return;
    }
    try {
      this.setCameraDevice(delegate, source);
      if (generalOptions.getAllowMultiple()) {
        let limit = generalOptions.getLimit();
        delegate.chooseMultiVideoFromGallery(options, generalOptions.getUsePhotoPicker(), limit, result);
      } else {
        switch (source.getType()) {
          case SourceType.GALLERY: {
            delegate.chooseVideoFromGallery(options, generalOptions.getUsePhotoPicker(), result);
            break;
          }
          case SourceType.CAMERA: {
            delegate.takeVideoWithCamera(options, result);
            break;
          }
          default: {
            // Defensive fallback: an unknown source type must reply with an error,
            // otherwise the Dart-side Future hangs forever
            result.error(new FlutterError('invalid_source', 'Unknown source type', null));
            break;
          }
        }
      }
    } catch (e) {
      Log.e(TAG, 'pickVideos failed: ' + (e as Error).message);
      result.error(new FlutterError('pick_videos_failed', 'Failed to pick videos: ' + (e as Error).message, null));
    }
  }

  pickMedia(mediaSelectionOptions: MediaSelectionOptions, generalOptions: GeneralOptions,
      result: Result<ArrayList<string>>): void {
    // Defensive argument boundary validation at the ArkTS layer (imageSelectionOptions may be null)
    const imageOptions = mediaSelectionOptions.getImageSelectionOptions();
    if (imageOptions != null && !this.validateImageOptions(imageOptions, result)) {
      return;
    }
    if (!this.validateGeneralOptions(generalOptions, result)) {
      return;
    }
    let delegate: ImagePickerDelegate | null = this.getImagePickerDelegate();
    if (delegate === null) {
      result.error(new FlutterError('no_activity', 'image_picker plugin requires a foreground ability', null));
      return;
    }
    try {
      delegate.chooseMediaFromGallery(mediaSelectionOptions, generalOptions, result);
    } catch (e) {
      Log.e(TAG, 'pickMedia failed: ' + (e as Error).message);
      result.error(new FlutterError('pick_media_failed', 'Failed to pick media: ' + (e as Error).message, null));
    }
  }

  async retrieveLostResults(): Promise<CacheRetrievalResult | null> {
    let delegate = this.getImagePickerDelegate();
    if (delegate == null) {
      throw new FlutterError('no_activity', 'image_picker plugin requires a foreground ability', null);
    }
    return await delegate.retrieveLostImage().then((result) => {
      return result;
    });
  }

  getAbilityState(): AbilityState | null {
    return this.state;
  }

  static constructorDelegate(setupAbility: UIAbility): ImagePickerDelegate {
    let cache: ImagePickerCache = new ImagePickerCache(setupAbility.context);
    let exifDataCopier: ExifDataCopier = new ExifDataCopier();
    let imageResizer: ImageResizer = new ImageResizer(setupAbility.context, exifDataCopier);
    return new ImagePickerDelegate(setupAbility, imageResizer, cache);
  }

  getImagePickerDelegate(): ImagePickerDelegate | null {
    if (this.state == null || this.state.getAbility() == null) {
      return null;
    }
    return this.state.getDelegate();
  }

  // Defensive argument boundary validation at the ArkTS layer: imageQuality must be 0-100; when
  // maxWidth/maxHeight are unset, Pigeon decodes them as null (on the Dart side double? sends null
  // when unset, and Messages.ets setMaxWidth stores it directly with no null guard), so null means
  // no scaling, consistent with the `!= null` checks in ImageResizer/ImagePickerCache;
  // 0 or negative values would produce zero/negative-sized images in ImageResizer and are invalid.
  // When false is returned, an invalid_argument error reply has already been sent.
  private validateImageOptions(options: ImageSelectionOptions, result: Result<ArrayList<string>>): boolean {
    const quality: number = options.getQuality();
    if (quality < 0 || quality > 100) {
      result.error(new FlutterError('invalid_argument', 'imageQuality must be between 0 and 100', null));
      return false;
    }
    const maxWidth: number | null = options.getMaxWidth();
    const maxHeight: number | null = options.getMaxHeight();
    if (maxWidth != null && maxWidth <= 0) {
      result.error(new FlutterError('invalid_argument', 'maxWidth must be null or positive', null));
      return false;
    }
    if (maxHeight != null && maxHeight <= 0) {
      result.error(new FlutterError('invalid_argument', 'maxHeight must be null or positive', null));
      return false;
    }
    return true;
  }

  private validateVideoOptions(options: VideoSelectionOptions, result: Result<ArrayList<string>>): boolean {
    const maxDuration: number = options.getMaxDurationSeconds();
    if (maxDuration < 0) {
      result.error(new FlutterError('invalid_argument', 'maxDuration cannot be negative', null));
      return false;
    }
    return true;
  }

  private validateGeneralOptions(generalOptions: GeneralOptions, result: Result<ArrayList<string>>): boolean {
    if (generalOptions.getAllowMultiple()) {
      const limit: number = generalOptions.getLimit();
      if (limit < 2) {
        result.error(new FlutterError('invalid_argument', 'limit cannot be lower than 2', null));
        return false;
      }
    }
    return true;
  }

  setCameraDevice(delegate: ImagePickerDelegate, source: SourceSpecification) {
    let camera: SourceCamera = source.getCamera();
    if (camera != null) {
      // Explicit initialization fallback: even if an unexpected enum value other than FRONT/REAR
      // appears, no runtime error is triggered by device being left unassigned
      let device: CameraDevice = CameraDevice.REAR;
      switch (camera) {
        case SourceCamera.FRONT: {
          device = CameraDevice.FRONT;
          break;
        }
        case SourceCamera.REAR: {
          device = CameraDevice.REAR;
          break;
        }
        default: {
          break;
        }
      }
      delegate.setCameraDevice(device);
    }
  }
}

class AbilityState {
  private ability: UIAbility | null;
  private context: common.Context | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private messenger: BinaryMessenger | null = null;
  private delegate: ImagePickerDelegate | null = null;

  constructor(ability: UIAbility, delegate?: ImagePickerDelegate | null, messenger?: BinaryMessenger,
      handler?: ImagePickerApi, abilityBinding?: AbilityPluginBinding, context?: common.Context) {
    this.ability = ability;
    if (context) {
      this.context = context;
    }
    if (abilityBinding) {
      this.abilityBinding = abilityBinding;
    }
    if (messenger) {
      this.messenger = messenger;
    }
    if (delegate) {
      this.delegate = delegate;
    }

    this.delegate = ImagePickerPlugin.constructorDelegate(this.ability);
    ImagePickerApi.setup(messenger as BinaryMessenger, handler);
  }

  release(): void {
    if (this.abilityBinding != null) {
      this.abilityBinding = null;
    }

    // Must pass a real messenger: setup(null, null) returns early because of !binaryMessenger, so
    // the handlers on the 4 BasicMessageChannels would never be removed; only a real messenger plus
    // a null api reaches the else branch, where channel.setMessageHandler(null) unregisters the handlers
    ImagePickerApi.setup(this.messenger, null);
    this.messenger = null;
    this.ability = null;
    // Release delegate resources in one place: the photoPicker instance, pending reply callbacks and
    // temp files, preventing dangling result references and delayed GC of PhotoViewPicker/preferences
    // on engine detach, plus unbounded accumulation of temp files in the cache directory
    if (this.delegate != null) {
      this.delegate.release();
    }
    this.delegate = null;
    this.context = null;
  }

  getAbility(): Ability | null {
    return this.ability;
  }

  getDelegate(): ImagePickerDelegate | null {
    return this.delegate;
  }
}
