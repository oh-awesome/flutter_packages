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
import { MethodCall, MethodChannel } from '@ohos/flutter_ohos';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import QrCodeFlutterPlugin from './VideoPlayerFlutterPlugin';
import ChannelDelegateImpl from './ChannelDelegateImpl';
import QrCaptureView from './VideoView';
import common from '@ohos.app.ability.common';

const LOG_TAG = "[VideoViewManager] :"
const METHOD_CHANNEL_NAME = "plugins/qr_capture/method"

export class VideoViewManager extends ChannelDelegateImpl {
  private plugin: QrCodeFlutterPlugin | null = null
  public windowAutoincrementId: number = 0
  public debuggingEnabled = false;
  public qrCaptureView: QrCaptureView | null = null;
  cameraWidth: number = 0;
  cameraHeight: number = 0;

  constructor(plugin: QrCodeFlutterPlugin, id: number) {
    super(new MethodChannel(plugin.messenger!, METHOD_CHANNEL_NAME + '_' + id));
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const context = getContext(this) as common.UIAbilityContext;
    switch (call.method) {
      default:
        result.notImplemented();
        break;
    }
  }

  public dispose(): void {
    super.dispose();
    this.plugin = null;
  }
}