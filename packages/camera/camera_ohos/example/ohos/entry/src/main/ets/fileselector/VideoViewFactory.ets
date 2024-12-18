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
import { Any, PlatformView, PlatformViewFactory, StandardMessageCodec } from '@ohos/flutter_ohos';
import { VideoViewManager } from './VideoViewManager';
import QrCaptureView from './VideoView';
import QrcodeFlutterPlugin from './VideoPlayerFlutterPlugin';

export default class VideoViewFactory extends PlatformViewFactory {
  public static VIEW_TYPE_ID = "plugins/qr_capture_view";
  public plugin: QrcodeFlutterPlugin;
  public viewId: number | null;
  public qrCaptureView: QrCaptureView | null = null;
  private qrCodeViewManager: VideoViewManager | null = null;

  constructor(plugin: QrcodeFlutterPlugin, context: Context) {
    super(StandardMessageCodec.INSTANCE);
    this.plugin = plugin;
    this.viewId = null;
  }

  public create(context: Context, viewId: number, args: Any): PlatformView {
    this.viewId = viewId;
    this.qrCaptureView = new QrCaptureView();
    //  视图桥接逻辑
    this.qrCodeViewManager = new VideoViewManager(this.plugin, this.viewId);
    return new QrCaptureView();
  }

  getViewId() {
    return this.viewId;
  }
}