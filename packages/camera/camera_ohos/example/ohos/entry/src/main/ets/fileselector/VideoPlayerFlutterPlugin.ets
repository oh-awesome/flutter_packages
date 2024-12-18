/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { AbilityAware, AbilityPluginBinding, BinaryMessenger } from '@ohos/flutter_ohos';
import { UIAbility } from '@kit.AbilityKit';
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { VideoViewManager } from './VideoViewManager';
import QRCaptureViewFactory from './VideoViewFactory'
import common from '@ohos.app.ability.common';

const TAG = '[QrCodeFlutterPlugin] :'

export default class VideoPlayerFlutterPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private applicationContext: Context | null = null;
  private ability: UIAbility | null = null;
  public messenger: BinaryMessenger | null = null;
  private qrCodeViewManager: VideoViewManager | null = null;
  private context: common.Context | null = null;

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    this.ability = null;
  }

  getUniqueClassName(): string {
    return "VideoPlayerFlutterPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.messenger = binding.getBinaryMessenger();
    this.applicationContext = binding.getApplicationContext();
    // 注册自定义视图
    const qRCaptureViewFactory = new QRCaptureViewFactory(this, this.applicationContext);
    binding.getPlatformViewRegistry()
      .registerViewFactory(QRCaptureViewFactory.VIEW_TYPE_ID, qRCaptureViewFactory);
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "plugins/qr_capture/method");
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext()
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
  }
}