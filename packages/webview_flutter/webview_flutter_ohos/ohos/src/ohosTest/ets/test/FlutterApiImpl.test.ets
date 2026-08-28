/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
 
// FlutterApi 实现类单元测试：实例注册 + Pigeon 通道发送 + 回调触发。

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import { WebViewFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewFlutterApiImpl';
import { WebViewFlutterApi, Reply } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { PermissionRequestFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/PermissionRequestFlutterApiImpl';
import { CustomViewCallbackFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/CustomViewCallbackFlutterApiImpl';
import { CustomViewCallbackFlutterApi } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { HttpAuthHandlerFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/HttpAuthHandlerFlutterApiImpl';
import { SslErrorHandlerFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/SslErrorHandlerFlutterApiImpl';
import { GeolocationPermissionsCallbackFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeolocationPermissionsCallbackFlutterApiImpl';
import { ViewFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/ViewFlutterApiImpl';
import { ViewFlutterApi } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { JavaScriptChannelFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannelFlutterApiImpl';
import { JavaScriptChannel } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannel';
import { DownloadListenerFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/DownloadListenerFlutterApiImpl';
import { FileChooserParamsFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/FileChooserParamsFlutterApiImpl';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import {
  FakePermissionRequest,
  FakeHttpAuthHandler,
  FakeSslErrorHandler,
  FakeJsGeolocation,
  FakeCustomViewCallback,
  FakeFileSelectorParam,
  FakeDownloadListener
} from '../testmock/MockInstances';
import { coerce } from '../testmock/MockInstances';
import { FakeWebViewPlatformView } from '../testmock/MockViews';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

export default function flutterApiImplTest() {
  describe('FlutterApiImplTest', () => {
    // ---------- WebViewFlutterApiImpl ----------
    it('webViewCreateRegistersInstanceAndSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      const api: WebViewFlutterApiImpl = new WebViewFlutterApiImpl(messenger, manager);
      let replied: boolean = false;
      const reply: Reply<void> = { reply: (r): void => {
        replied = true;
      } };
      api.create(view, reply);
      expect(manager.getIdentifier(view)).assertEqual(65536);
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.create')).assertTrue();
      expect(replied).assertTrue();
    })

    it('webViewCreateSkipsAlreadyRegisteredInstance', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      manager.addHostCreatedInstance(view);
      new WebViewFlutterApiImpl(messenger, manager).create(view, { reply: (r): void => {
      } });
      expect(messenger.sendCount).assertEqual(0);
    })

    it('webViewOnScrollChangedSendsWithInstanceId', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      const id: number = manager.addHostCreatedInstance(view);
      new WebViewFlutterApiImpl(messenger, manager)
        .onScrollChanged(view, 1, 2, 3, 4, { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.onScrollChanged')).assertTrue();
      expect(id).assertEqual(65536);
    })

    it('webViewSetApiReroutesMessages', 0, () => {
      const first: MockBinaryMessenger = new MockBinaryMessenger();
      const second: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(first, manager);
      manager.addHostCreatedInstance(view);
      const api: WebViewFlutterApiImpl = new WebViewFlutterApiImpl(first, manager);
      api.setApi(new WebViewFlutterApi(second));
      api.onScrollChanged(view, 1, 2, 3, 4, { reply: (r): void => {
      } });
      expect(first.sendCount).assertEqual(0);
      expect(second.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.onScrollChanged')).assertTrue();
    })

    // ---------- PermissionRequestFlutterApiImpl ----------
    it('permissionRequestCreateSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const request: FakePermissionRequest = new FakePermissionRequest();
      new PermissionRequestFlutterApiImpl(messenger, manager)
        .create(request as Object as PermissionRequest, ['camera'], { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'PermissionRequestFlutterApi.create')).assertTrue();
      expect(manager.containsInstance(request)).assertTrue();
    })

    it('permissionRequestCreateSkipsRegistered', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const request: FakePermissionRequest = new FakePermissionRequest();
      manager.addHostCreatedInstance(request);
      new PermissionRequestFlutterApiImpl(messenger, manager)
        .create(request as Object as PermissionRequest, ['camera'], { reply: (r): void => {
        } });
      expect(messenger.sendCount).assertEqual(0);
    })

    // ---------- CustomViewCallbackFlutterApiImpl ----------
    it('customViewCallbackCreateSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const callback: FakeCustomViewCallback = new FakeCustomViewCallback();
      new CustomViewCallbackFlutterApiImpl(messenger, manager)
        .create(callback, { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'CustomViewCallbackFlutterApi.create')).assertTrue();
    })

    it('customViewCallbackSetApiReroutes', 0, () => {
      const first: MockBinaryMessenger = new MockBinaryMessenger();
      const second: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: CustomViewCallbackFlutterApiImpl =
        new CustomViewCallbackFlutterApiImpl(first, manager);
      impl.setApi(new CustomViewCallbackFlutterApi(second));
      impl.create(new FakeCustomViewCallback(), { reply: (r): void => {
      } });
      expect(first.sendCount).assertEqual(0);
      expect(second.sendCount).assertEqual(1);
    })

    // ---------- HttpAuthHandlerFlutterApiImpl ----------
    it('httpAuthHandlerCreateSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new HttpAuthHandlerFlutterApiImpl(messenger, manager)
        .create(new FakeHttpAuthHandler(), { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'HttpAuthHandlerFlutterApi.create')).assertTrue();
    })

    // ---------- SslErrorHandlerFlutterApiImpl ----------
    it('sslHandlerCreateSendsWhenUnregistered', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new SslErrorHandlerFlutterApiImpl(messenger, manager)
        .create(new FakeSslErrorHandler(), { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'SslErrorHandlerFlutterApi.create')).assertTrue();
    })

    it('sslHandlerCreateRepliesImmediatelyWhenRegistered', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const handler: FakeSslErrorHandler = new FakeSslErrorHandler();
      manager.addHostCreatedInstance(handler);
      let replied: boolean = false;
      new SslErrorHandlerFlutterApiImpl(messenger, manager)
        .create(handler, { reply: (r): void => {
          replied = true;
        } });
      expect(replied).assertTrue();
      expect(messenger.sendCount).assertEqual(0);
    })

    // ---------- GeolocationPermissionsCallbackFlutterApiImpl ----------
    it('geolocationCallbackCreateSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new GeolocationPermissionsCallbackFlutterApiImpl(messenger, manager)
        .create(new FakeJsGeolocation() as Object as JsGeolocation, { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'GeolocationPermissionsCallbackFlutterApi.create')).assertTrue();
    })

    // ---------- ViewFlutterApiImpl ----------
    it('viewCreateSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new ViewFlutterApiImpl(messenger, manager)
        .create(new FakeCustomViewCallback(), { reply: (r): void => {
        } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'ViewFlutterApi.create')).assertTrue();
    })

    it('viewSetApiReroutes', 0, () => {
      const first: MockBinaryMessenger = new MockBinaryMessenger();
      const second: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: ViewFlutterApiImpl = new ViewFlutterApiImpl(first, manager);
      impl.setApi(new ViewFlutterApi(second));
      impl.create(new FakeCustomViewCallback(), { reply: (r): void => {
      } });
      expect(first.sendCount).assertEqual(0);
      expect(second.hasSentTo(CHANNEL_PREFIX + 'ViewFlutterApi.create')).assertTrue();
    })

    // ---------- JavaScriptChannelFlutterApiImpl ----------
    it('javaScriptChannelPostMessageSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const flutterApi: JavaScriptChannelFlutterApiImpl =
        new JavaScriptChannelFlutterApiImpl(messenger, manager);
      const channel: JavaScriptChannel = new JavaScriptChannel(flutterApi, 'chan');
      manager.addHostCreatedInstance(channel);
      let replied: boolean = false;
      flutterApi.postMessage(channel, 'hello', { reply: (r): void => {
        replied = true;
      } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'JavaScriptChannelFlutterApi.postMessage')).assertTrue();
      expect(replied).assertTrue();
    })

    it('javaScriptChannelPostMessageUnregisteredSendsWithMinusOne', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const flutterApi: JavaScriptChannelFlutterApiImpl =
        new JavaScriptChannelFlutterApiImpl(messenger, manager);
      const orphan: JavaScriptChannel = new JavaScriptChannel(flutterApi, 'orphan');
      // 实际行为：getIdentifier 对未注册实例返回 -1（非 null），
      // 下游 if (identifier == null) 分支不会命中，不抛错而是以 -1 发送。
      let threw: boolean = false;
      try {
        flutterApi.postMessage(orphan, 'x', { reply: (r): void => {
        } });
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'JavaScriptChannelFlutterApi.postMessage')).assertTrue();
    })

    // ---------- DownloadListenerFlutterApiImpl ----------
    it('downloadListenerOnStartSendsWithIdentifier', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: DownloadListenerFlutterApiImpl =
        new DownloadListenerFlutterApiImpl(messenger, manager);
      const listener: FakeDownloadListener = new FakeDownloadListener();
      manager.addHostCreatedInstance(listener);
      impl.onDownloadStart(listener, 'about:blank', 'ua', 'cd', 'application/octet-stream', 5, { reply: (r): void => {
      } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'DownloadListenerFlutterApi.onDownloadStart')).assertTrue();
    })

    it('downloadListenerUnknownInstanceReturnsMinusOne', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: DownloadListenerFlutterApiImpl =
        new DownloadListenerFlutterApiImpl(messenger, manager);
      // 实际行为：未注册实例 getIdentifier 返回 -1（非 null），
      // if (identifier == null) 抛错分支为死代码，不生效。
      expect(impl.getIdentifierForListener(new FakeDownloadListener())).assertEqual(-1);
    })

    // ---------- FileChooserParamsFlutterApiImpl ----------
    it('fileChooserCreateMapsModesAndSends', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: FileChooserParamsFlutterApiImpl =
        new FileChooserParamsFlutterApiImpl(messenger, manager);
      const param: FakeFileSelectorParam = new FakeFileSelectorParam();
      param.mode = FileSelectorMode.FileSaveMode;
      impl.create(param as Object as FileSelectorParam, { reply: (r): void => {
      } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'FileChooserParamsFlutterApi.create')).assertTrue();
    })

    it('fileChooserCreateSkipsRegistered', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: FileChooserParamsFlutterApiImpl =
        new FileChooserParamsFlutterApiImpl(messenger, manager);
      const param: FakeFileSelectorParam = new FakeFileSelectorParam();
      manager.addHostCreatedInstance(param);
      impl.create(param as Object as FileSelectorParam, { reply: (r): void => {
      } });
      expect(messenger.sendCount).assertEqual(0);
    })

    it('fileChooserUnsupportedModeThrows', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const impl: FileChooserParamsFlutterApiImpl =
        new FileChooserParamsFlutterApiImpl(messenger, manager);
      const param: FakeFileSelectorParam = new FakeFileSelectorParam();
      param.mode = coerce<FileSelectorMode>(99);
      let threw: boolean = false;
      let message: string = '';
      try {
        impl.create(param as Object as FileSelectorParam, { reply: (r): void => {
        } });
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('Unsupported FileChooserMode')).assertTrue();
    })
  })
}
