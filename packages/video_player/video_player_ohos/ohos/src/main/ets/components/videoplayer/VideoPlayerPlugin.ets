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
import { PlatformVideoViewFactory } from './PlatformVideoViewFactory';
import fs from '@ohos.file.fs';

const TAG: string = "VideoPlayerPlugin";
const FILE_URI_PREFIX: string = 'file://';

function openSandboxFile(filePath: string): fs.File {
  try {
    return fs.openSync(filePath);
  } catch (e) {
    if (!filePath.startsWith(FILE_URI_PREFIX)) {
      throw e instanceof Error ? e : new Error(`${e}`);
    }
    let sandboxPath = filePath.substring(FILE_URI_PREFIX.length);
    try {
      sandboxPath = decodeURIComponent(sandboxPath);
    } catch (decodeErr) {
      Log.w(TAG, 'decode file uri failed: ' + JSON.stringify(decodeErr));
    }
    Log.i(TAG, 'retry open sandbox path: ' + sandboxPath);
    return fs.openSync(sandboxPath);
  }
}

// Move the FlutterState class definition to the top.
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
  // Recorded when ability arrives before engine attach; after engine attach, create the API channel as compensation.
  private pendingAbilityBinding: AbilityPluginBinding | null = null;
  // Recorded when ability arrives before engine attach; after engine attach, rebuild the method channel.
  private pendingChannel: boolean = false;

  getUniqueClassName(): string {
    return TAG;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method == "getFileFdByPath") {
      try {
        let filePath = call.argument("filePath") as string;
        Log.i(TAG, 'filePath: ' + filePath);
        let openFile: fs.File = openSandboxFile(filePath);
        result.success(openFile.fd);
      } catch (e) {
        Log.e(TAG, 'getFileFdByPath failed with err: ' + e);
        result.success(-1);
      }
    } else if (call.method == "closeFileFd") {
      // When create fails on the Dart side, reclaim the fd not consumed by the player to avoid a leak.
      try {
        let fd = call.argument("fd") as number;
        fs.closeSync(fd);
        result.success(true);
      } catch (e) {
        Log.w(TAG, 'closeFileFd failed with err: ' + e);
        result.success(false);
      }
    } else if (call.method == "setKeepScreenOn") {
      // Dart passes through preventsDisplaySleepDuringVideoPlayback;
      // drives the native side to control screen keep-on by this flag.
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
      // Unrecognized methods must be replied to, otherwise the Flutter-side Future hangs forever.
      result.notImplemented();
    }
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
    Log.i(TAG, "VideoPlayer onAttachedToEngine");
    this.flutterState = new FlutterState(this.pluginBinding.getBinaryMessenger(), this.pluginBinding.getTextureRegistry());
    this.pluginBinding.getPlatformViewRegistry().registerViewFactory(
      'plugins.flutter.io/video_player_ohos',
      new PlatformVideoViewFactory((playerId: number) => {
        return this.videoPlayerApiImpl?.getPlayer(playerId) ?? null;
      })
    );
    // Compensation for ability arriving before engine attach: additionally create the VideoPlayerApiImpl channel.
    if (this.pendingAbilityBinding != null && this.videoPlayerApiImpl == null) {
      Log.i(TAG, "VideoPlayer compensate VideoPlayerApiImpl setup after engine attach");
      const abilityBinding = this.pendingAbilityBinding;
      this.videoPlayerApiImpl = new VideoPlayerApiImpl(this.flutterState, abilityBinding);
      this.videoPlayerApiImpl.setup(this.pluginBinding.getBinaryMessenger());
      this.pendingAbilityBinding = null;
    }
    // Compensation for ability arriving before engine attach: additionally create the method channel.
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
      // Engine not attached yet; record it for later compensation.
      Log.w(TAG, "VideoPlayer onAttachedToAbility before engine attach, defer setup");
      this.pendingAbilityBinding = binding;
    }
    if (this.pluginBinding != null) {
      this.channel = new MethodChannel(this.pluginBinding.getBinaryMessenger(), "plugins.flutter.io/video_player_ohos");
      this.channel.setMethodCallHandler(this);
    } else {
      // Record for compensation; rebuild the channel in onAttachedToEngine after engine attach.
      this.pendingChannel = true;
    }
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, "VideoPlayer onDetachedFromAbility");
    this.disposeAll();
  }

  // Generic method for releasing resources
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
