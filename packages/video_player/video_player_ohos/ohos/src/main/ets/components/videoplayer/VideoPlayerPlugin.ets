// Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on VideoPlayerPlugin.java originally written by
// Copyright 2013 The Flutter Authors.

import { MethodCall, MethodCallHandler, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { VideoPlayerApi } from './VideoPlayerApi';
import { VideoPlayerApiImpl } from './VideoPlayerApiImpl';
import fs from '@ohos.file.fs';

const TAG: string = "VideoPlayerPlugin";

// 将 FlutterState 类移到顶部定义
export class FlutterState {
  private binaryMessenger: BinaryMessenger;
  private textureRegistry: TextureRegistry;

  constructor(binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry) {
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
  }

  getBinaryMessenger(): BinaryMessenger {
    return this.binaryMessenger;
  }

  getTextureRegistry(): TextureRegistry {
    return this.textureRegistry;
  }
}

export class VideoPlayerPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private pluginBinding: FlutterPluginBinding | null = null;
  private videoPlayerApiImpl: VideoPlayerApiImpl | null = null;
  private flutterState: FlutterState | null = null;
  private channel: MethodChannel | null = null;
  // ability 先于 engine attach 到达时记录，engine attach 后补偿创建 API 通道。
  private pendingAbilityBinding: AbilityPluginBinding | null = null;
  // ability 先于 engine attach 到达时记录，engine attach 后补偿创建 method channel。
  private pendingChannel: boolean = false;

  getUniqueClassName(): string {
    return TAG;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method == "getFileFdByPath") {
      try {
        let filePath = call.argument("filePath") as string;
        Log.i(TAG, 'filePath: ' + filePath);
        let openFile: fs.File = fs.openSync(filePath);
        result.success(openFile.fd);
      } catch (e) {
        Log.e(TAG, 'getFileFdByPath failed with err: ' + e);
        result.success(-1);
      }
    } else if (call.method == "closeFileFd") {
      // Dart 侧 create 失败时回收未被播放器消费的 fd，避免泄漏。
      try {
        let fd = call.argument("fd") as number;
        fs.closeSync(fd);
        result.success(true);
      } catch (e) {
        Log.w(TAG, 'closeFileFd failed with err: ' + e);
        result.success(false);
      }
    } else if (call.method == "setKeepScreenOn") {
      // Dart 层 preventsDisplaySleepDuringVideoPlayback 透传，驱动原生按标志控制屏幕常亮。
      try {
        let playerId = call.argument("playerId") as number;
        let keepScreenOn = call.argument("keepScreenOn") as boolean;
        if (this.videoPlayerApiImpl != null) {
          this.videoPlayerApiImpl.setKeepScreenOn(playerId, keepScreenOn);
        }
        result.success(true);
      } catch (e) {
        Log.w(TAG, 'setKeepScreenOn failed with err: ' + e);
        result.success(false);
      }
    } else {
      // 未识别的方法必须回复，否则 Flutter 侧 Future 将永久挂起。
      result.notImplemented();
    }
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
    Log.i(TAG, "VideoPlayer onAttachedToEngine");
    this.flutterState = new FlutterState(this.pluginBinding.getBinaryMessenger(), this.pluginBinding.getTextureRegistry());
    // ability 先于 engine attach 到达时的补偿：补充创建 VideoPlayerApiImpl 通道。
    if (this.pendingAbilityBinding != null && this.videoPlayerApiImpl == null) {
      Log.i(TAG, "VideoPlayer compensate VideoPlayerApiImpl setup after engine attach");
      const abilityBinding = this.pendingAbilityBinding;
      this.videoPlayerApiImpl = new VideoPlayerApiImpl(this.flutterState, abilityBinding);
      this.videoPlayerApiImpl.setup(this.pluginBinding.getBinaryMessenger());
      this.pendingAbilityBinding = null;
    }
    // ability 先于 engine attach 到达时的补偿：补建 method channel。
    if (this.pendingChannel && this.channel == null) {
      Log.i(TAG, "VideoPlayer compensate channel setup after engine attach");
      this.channel = new MethodChannel(this.pluginBinding.getBinaryMessenger(), "plugins.flutter.io/video_player_ohos");
      this.channel.setMethodCallHandler(this);
      this.pendingChannel = false;
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, "VideoPlayer onDetachedFromEngine");
    this.disposeAll();
    this.pluginBinding = null;
    this.flutterState = null;
    this.pendingAbilityBinding = null;
    this.pendingChannel = false;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, "VideoPlayer onAttachedToAbility");
    if (this.flutterState != null && this.pluginBinding != null && this.videoPlayerApiImpl == null) {
      this.videoPlayerApiImpl = new VideoPlayerApiImpl(this.flutterState, binding);
      this.videoPlayerApiImpl.setup(this.pluginBinding.getBinaryMessenger());
    } else if (this.videoPlayerApiImpl == null) {
      // engine 尚未 attach，记录待补偿。
      Log.w(TAG, "VideoPlayer onAttachedToAbility before engine attach, defer setup");
      this.pendingAbilityBinding = binding;
    }
    if (this.pluginBinding != null) {
      this.channel = new MethodChannel(this.pluginBinding.getBinaryMessenger(), "plugins.flutter.io/video_player_ohos");
      this.channel.setMethodCallHandler(this);
    } else {
      // 记录待补偿，engine attach 后在 onAttachedToEngine 中补建通道。
      this.pendingChannel = true;
    }
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, "VideoPlayer onDetachedFromAbility");
    this.disposeAll();
  }

  // 添加资源释放的通用方法
  private disposeAll(): void {
    if (this.videoPlayerApiImpl != null) {
      if (this.pluginBinding != null) {
        this.videoPlayerApiImpl.teardown(this.pluginBinding.getBinaryMessenger());
      }
      this.videoPlayerApiImpl.disposeAllPlayers();
      this.videoPlayerApiImpl = null;
    }
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }
}
