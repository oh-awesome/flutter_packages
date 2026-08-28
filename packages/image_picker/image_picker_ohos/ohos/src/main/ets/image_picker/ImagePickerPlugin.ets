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

// implements ImagePickerApi 被注释：ArkTS 的 implements 子句只接受接口
// （arkts-implements-only-iface），而 ImagePickerApi 是带静态 getCodec/setup 的抽象类，
// 无法改为 interface（静态方法不进接口），恢复 implements 会编译失败（OH-014 实测已回退）。
// 此处以 `this as ESObject` 鸭子类型接入 Pigeon handler，签名校验靠 Messages.ets setup 强转
// 与入口 try-catch 兜底，属 ArkTS 语言限制下的既定做法。
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
    // 引擎解绑时同步释放 AbilityState，注销 MessageChannel handler，避免回调悬挂与资源残留
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
    // 防御性：若存在旧 AbilityState（异常场景下 onAttachedToAbility 可能重复触发），
    // 先释放旧实例注销消息处理器，避免 4 条 BasicMessageChannel handler 残留
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

  pickImages(source: SourceSpecification, options: ImageSelectionOptions, generalOptions: GeneralOptions, result: Result<ArrayList<string>>) {
    // ArkTS 层防御性参数边界校验（Dart 侧已校验，这里作为独立模块的二次防护）
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
            // 防御性兜底：未知来源类型必须回包错误，否则 Dart 侧 Future 永久挂起
            result.error(new FlutterError('invalid_source', 'Unknown source type', null));
            break;
          }
        }
      }
    } catch (e) {
      // 入口兜底：同步异常转成错误回包，避免 Dart 侧 Future 永久挂起
      Log.e(TAG, 'pickImages failed: ' + (e as Error).message);
      result.error(new FlutterError('pick_images_failed', 'Failed to pick images: ' + (e as Error).message, null));
    }
  }

  pickVideos(source: SourceSpecification, options: VideoSelectionOptions, generalOptions: GeneralOptions, result: Result<ArrayList<string>>): void {
    // ArkTS 层防御性参数边界校验
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
            // 防御性兜底：未知来源类型必须回包错误，否则 Dart 侧 Future 永久挂起
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

  pickMedia(mediaSelectionOptions: MediaSelectionOptions, generalOptions: GeneralOptions, result: Result<ArrayList<string>>): void {
    // ArkTS 层防御性参数边界校验（imageSelectionOptions 可能为 null）
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

  // ArkTS 层防御性参数边界校验：imageQuality 须在 0-100；maxWidth/maxHeight 未设置时由 Pigeon
  // 解码为 null（Dart 端 double? 未设置即发送 null，Messages.ets setMaxWidth 无 null guard 直接存储），
  // 故以 null 表示不缩放，与 ImageResizer/ImagePickerCache 的 `!= null` 判定一致；
  // 0 或负数在 ImageResizer 中会产生 0/负尺寸图片，判定为非法。返回 false 时已回包 invalid_argument 错误。
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
      // 显式初始化兜底：即便出现非 FRONT/REAR 的异常枚举值，也不会因 device 未赋值而触发运行时错误
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

  constructor(ability: UIAbility, delegate?: ImagePickerDelegate | null, messenger?: BinaryMessenger, handler?: ImagePickerApi, abilityBinding?: AbilityPluginBinding, context?: common.Context) {
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

    // 必须传入真实 messenger：setup(null, null) 因 !binaryMessenger 直接 return，
    // 4 条 BasicMessageChannel 的 handler 将从未被移除；传真实 messenger + null api
    // 才会走到 else 分支执行 channel.setMessageHandler(null) 注销 handler
    ImagePickerApi.setup(this.messenger, null);
    this.messenger = null;
    this.ability = null;
    // 统一释放 delegate 资源：photoPicker 实例 + 待回复回调 + 临时文件，
    // 避免引擎解绑时 result 引用悬挂、PhotoViewPicker/preferences 延迟 GC，
    // 以及缓存目录下临时文件无限累积
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
