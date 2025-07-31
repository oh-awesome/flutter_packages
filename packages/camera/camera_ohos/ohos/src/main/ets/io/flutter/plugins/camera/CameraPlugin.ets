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
import MethodChannel, { MethodCallHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { MethodCallHandlerImpl } from './MethodCallHandlerImpl';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import common from '@ohos.app.ability.common';
import "@ohos/flutter_ohos/src/main/ets/component/FlutterComponent"
import { CameraPermissions } from './CameraPermissions';
import { CameraApi } from './Messages';
import { CameraApiImpl } from './CameraApiImpl';

export default class CameraPlugin implements FlutterPlugin, AbilityAware {
  private TAG: string = 'CameraPlugin';
  private flutterPluginBinding: FlutterPluginBinding | null = null;
  private methodCallHandler: MethodCallHandlerImpl | null = null;
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
    this.flutterPluginBinding = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {

    if (this.flutterPluginBinding != null) {
      this.methodCallHandler = new MethodCallHandlerImpl(binding.getAbility(),
        this.flutterPluginBinding.getBinaryMessenger(), new CameraPermissions(), this.flutterPluginBinding.getTextureRegistry());
      
      // Fix: Add the third parameter (TextureRegistry)
      const applicationContext = binding.getAbility().context.getApplicationContext();
      this.cameraApiImpl = new CameraApiImpl(
        binding.getAbility(),
        this.flutterPluginBinding.getBinaryMessenger(),
        this.flutterPluginBinding.getTextureRegistry()
      );
      
      CameraApi.setUp(this.flutterPluginBinding.getBinaryMessenger(), this.cameraApiImpl);
    }
  }

  onDetachedFromAbility(): void {
    if (this.cameraApiImpl != null) {
      CameraApi.setUp(this.flutterPluginBinding!.getBinaryMessenger(), null);
      this.cameraApiImpl = null;
    }
    if (this.methodCallHandler != null) {
      this.methodCallHandler.stopListening();
      this.methodCallHandler = null;
    }
  }
}