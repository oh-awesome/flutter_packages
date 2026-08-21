// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on CameraPlugin.java originally written by
// Copyright 2013 The Flutter Authors.

import {
  AbilityAware,
  AbilityPluginBinding,
  BinaryMessenger,
  JSONMessageCodec,
  JSONMethodCodec,
  TextureRegistry
} from '@ohos/flutter_ohos';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import common from '@ohos.app.ability.common';
import '@ohos/flutter_ohos/src/main/ets/component/FlutterComponent'
import { CameraApi } from './Messages';
import { CameraApiImpl } from './CameraApiImpl';

export default class CameraPlugin implements FlutterPlugin, AbilityAware {
  private TAG: string = 'CameraPlugin';
  private flutterPluginBinding: FlutterPluginBinding | null = null;
  private textureRegistry : TextureRegistry  | null = null
  private cameraApiImpl: CameraApiImpl | null = null;

  constructor() {
  }


  getUniqueClassName(): string {
    return this.TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.flutterPluginBinding = binding;
    this.textureRegistry = binding.getTextureRegistry();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // 防御性释放：正常流程 onDetachedFromAbility 已先置空 cameraApiImpl，
    // 此处处理引擎直接销毁（未经历 ability detach）的路径。
    const apiImpl = this.cameraApiImpl;
    this.cameraApiImpl = null;
    if (apiImpl != null) {
      apiImpl.dispose().catch((e: Error) => {
        console.error('CameraPlugin.onDetachedFromEngine: dispose failed: ' + e.message);
      });
    }
    // 注销 Pigeon handler：与 onDetachedFromAbility 保持一致，
    // 覆盖引擎直接销毁（未经历 ability detach）的路径；setUp(null) 幂等，重复调用无副作用
    try {
      CameraApi.setUp(binding.getBinaryMessenger(), null);
    } catch (e) {
      console.error('CameraPlugin.onDetachedFromEngine: setUp(null) failed: ' + (e as Error).message);
    }
    this.textureRegistry = null;
    this.flutterPluginBinding = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    try {
      if (this.flutterPluginBinding != null) {
        // Fix: Add the third parameter (TextureRegistry)
        const applicationContext = binding.getAbility().context.getApplicationContext();
        this.cameraApiImpl = new CameraApiImpl(
          binding.getAbility(),
          this.flutterPluginBinding.getBinaryMessenger(),
          this.flutterPluginBinding.getTextureRegistry()
        );

        CameraApi.setUp(this.flutterPluginBinding.getBinaryMessenger(), this.cameraApiImpl);
      }
    } catch (e) {
      console.error('CameraPlugin.onAttachedToAbility failed: ' + (e as Error).message);
      this.onDetachedFromAbility();
    }
  }

  async onDetachedFromAbility(): Promise<void> {
    // 先缓存局部引用并置空成员，避免与 onDetachedFromEngine 竞争导致重复 dispose
    const binding = this.flutterPluginBinding;
    const apiImpl = this.cameraApiImpl;
    this.cameraApiImpl = null;

    if (apiImpl != null) {
      try {
        await apiImpl.dispose();   // 内部执行 camera.close() + camera.dispose() + unregisterTexture
      } catch (e) {
        console.error('CameraPlugin.onDetachedFromAbility: dispose failed: ' + (e as Error).message);
      }
    }
    if (binding != null) {
      try {
        CameraApi.setUp(binding.getBinaryMessenger(), null);   // 注销所有 pigeon handler
      } catch (e) {
        console.error('CameraPlugin.onDetachedFromAbility: setUp(null) failed: ' + (e as Error).message);
      }
    }
  }
}