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
 
// HostApi 实现类单元测试：各 XxxHostApiImpl 的行为分支，
// 以及 GeneratedOhosWebView.setup() 的消息处理器注册。

import { describe, it, expect } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebViewHostApi,
  WebSettingsHostApi,
  WebChromeClientHostApi,
  WebViewClientHostApi,
  WebViewFeatureHostApi,
  WebStorageHostApi,
  GeolocationPermissionsCallbackHostApi,
  HttpAuthHandlerHostApi,
  SslErrorHandlerHostApi,
  CookieManagerHostApi,
  PermissionRequestHostApi,
  CustomViewCallbackHostApi,
  DownloadListenerHostApi,
  FlutterAssetManagerHostApi,
  JavaScriptChannelHostApi,
  OhosObjectHostApi,
  InstanceManagerHostApi,
  InstanceManagerApi
} from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import {
  WebViewHostApiImpl,
  WebViewProxy
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import {
  WebSettingsHostApiImpl,
  WebSettingsCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebSettingsHostApiImpl';
import {
  WebChromeClientHostApiImpl,
  WebChromeClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';
import {
  WebViewClientHostApiImpl,
  WebViewClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientHostApiImpl';
import { WebViewFeatureHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewFeatureHostApiImpl';
import { OhosObjectHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/OhosObjectHostApiImpl';
import { PermissionRequestHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/PermissionRequestHostApiImpl';
import { CustomViewCallbackHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/CustomViewCallbackHostApiImpl';
import { SslErrorHandlerHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/SslErrorHandlerHostApiImpl';
import { HttpAuthHandlerHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/HttpAuthHandlerHostApiImpl';
import { GeolocationPermissionsCallbackHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeolocationPermissionsCallbackHostApiImpl';
import {
  DownloadListenerHostApiImpl,
  DownloadListenerCreator,
  DownloadListener
} from '../../../main/ets/io.flutter.plugins/webview_flutter/DownloadListenerHostApiImpl';
import {
  JavaScriptChannelHostApiImpl,
  JavaScriptChannelCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannelHostApiImpl';
import { CookieManagerHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/CookieManagerHostApiImpl';
import { WebStorageHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebStorageHostApiImpl';
import { FlutterAssetManagerHostApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/FlutterAssetManagerHostApiImpl';
import { WebViewClientFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientFlutterApiImpl';
import { WebViewFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewFlutterApiImpl';
import { WebChromeClientFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientFlutterApiImpl';
import { DownloadListenerFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/DownloadListenerFlutterApiImpl';
import { JavaScriptChannelFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannelFlutterApiImpl';
import { JavaScriptChannel } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannel';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import {
  FakePermissionRequest,
  FakeJsGeolocation,
  FakeSslErrorHandler,
  FakeHttpAuthHandler,
  FakeCustomViewCallback
} from '../testmock/MockInstances';
import { coerce } from '../testmock/MockInstances';
import { FakeWebViewPlatformView, FakeFlutterAssetManager } from '../testmock/MockViews';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

class PlainObject {
}

class StubInstanceManagerApi implements InstanceManagerApi {
  clear(): void {
  }
}

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

export default function hostApiImplTest() {
  describe('HostApiImplTest', () => {
    // ---------- setup() 注册覆盖 ----------
    it('setupRegistersHandlersForAllHostApis', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const context: common.Context = coerce<common.Context>(undefined);

      WebViewHostApi.setup(
        messenger,
        new WebViewHostApiImpl(manager, new WebViewProxy(), messenger, context)
      );
      WebSettingsHostApi.setup(
        messenger,
        new WebSettingsHostApiImpl(manager, new WebSettingsCreator())
      );
      WebChromeClientHostApi.setup(
        messenger,
        new WebChromeClientHostApiImpl(
          manager, new WebChromeClientCreator(), new WebChromeClientFlutterApiImpl(messenger, manager)
        )
      );
      WebViewClientHostApi.setup(
        messenger,
        new WebViewClientHostApiImpl(
          manager, new WebViewClientCreator(), new WebViewClientFlutterApiImpl(messenger, manager)
        )
      );
      WebViewFeatureHostApi.setup(messenger, new WebViewFeatureHostApiImpl());
      WebStorageHostApi.setup(messenger, new WebStorageHostApiImpl());
      GeolocationPermissionsCallbackHostApi.setup(
        messenger, new GeolocationPermissionsCallbackHostApiImpl(messenger, manager)
      );
      HttpAuthHandlerHostApi.setup(
        messenger, new HttpAuthHandlerHostApiImpl(messenger, manager)
      );
      SslErrorHandlerHostApi.setup(
        messenger, new SslErrorHandlerHostApiImpl(messenger, manager)
      );
      CookieManagerHostApi.setup(
        messenger, new CookieManagerHostApiImpl(messenger, manager)
      );
      PermissionRequestHostApi.setup(
        messenger, new PermissionRequestHostApiImpl(messenger, manager)
      );
      CustomViewCallbackHostApi.setup(
        messenger, new CustomViewCallbackHostApiImpl(messenger, manager)
      );
      DownloadListenerHostApi.setup(
        messenger,
        new DownloadListenerHostApiImpl(
          manager, new DownloadListenerCreator(),
          new DownloadListenerFlutterApiImpl(messenger, manager)
        )
      );
      FlutterAssetManagerHostApi.setup(
        messenger, new FlutterAssetManagerHostApiImpl(new FakeFlutterAssetManager())
      );
      JavaScriptChannelHostApi.setup(
        messenger,
        new JavaScriptChannelHostApiImpl(
          manager, new JavaScriptChannelCreator(),
          new JavaScriptChannelFlutterApiImpl(messenger, manager)
        )
      );
      OhosObjectHostApi.setup(messenger, new OhosObjectHostApiImpl(manager));
      InstanceManagerHostApi.setup(messenger, new StubInstanceManagerApi());

      expect(messenger.handlerChannelNames.length >= 16).assertTrue();
      expect(messenger.hasHandlerFor(CHANNEL_PREFIX + 'WebViewHostApi.create')).assertTrue();
      expect(messenger.hasHandlerFor(CHANNEL_PREFIX + 'OhosObjectHostApi.dispose')).assertTrue();
      expect(messenger.hasHandlerFor(CHANNEL_PREFIX + 'InstanceManagerHostApi.clear')).assertTrue();
      expect(messenger.hasHandlerFor(CHANNEL_PREFIX + 'JavaScriptChannelHostApi.create')).assertTrue();
      expect(messenger.hasHandlerFor(CHANNEL_PREFIX + 'DownloadListenerHostApi.create')).assertTrue();
    })

    it('setupWithNullApiDeregistersHandlers', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      OhosObjectHostApi.setup(messenger, new OhosObjectHostApiImpl(manager));
      expect(messenger.getHandler(CHANNEL_PREFIX + 'OhosObjectHostApi.dispose') != null).assertTrue();
      OhosObjectHostApi.setup(messenger, null);
      expect(messenger.getHandler(CHANNEL_PREFIX + 'OhosObjectHostApi.dispose') == null).assertTrue();
    })

    // ---------- WebViewFeatureHostApiImpl ----------
    it('paymentRequestFeatureIsUnsupported', 0, () => {
      const api: WebViewFeatureHostApiImpl = new WebViewFeatureHostApiImpl();
      expect(api.isFeatureSupported('PAYMENT_REQUEST')).assertFalse();
    })

    it('unknownFeatureIsUnsupportedAndLogs', 0, () => {
      const api: WebViewFeatureHostApiImpl = new WebViewFeatureHostApiImpl();
      expect(api.isFeatureSupported('NOT_A_REAL_FEATURE')).assertFalse();
    })

    // ---------- OhosObjectHostApiImpl ----------
    it('disposeReleasesWebViewAndRemovesIt', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      const id: number = manager.addHostCreatedInstance(view);
      new OhosObjectHostApiImpl(manager).dispose(id);
      expect(view.releaseCount).assertEqual(1);
      // "已移除"判据：按 identifier 查询失效（WeakMap 反查不清除，见
      // InstanceManager.remove 实际行为）。
      expect(manager.getInstance(id)).assertUndefined();
    })

    it('disposeWithUnknownIdentifierIsSafe', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new OhosObjectHostApiImpl(manager).dispose(99999);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })

    it('disposeWithNonPlatformViewOnlyRemovesIt', 0, () => {
      const manager: InstanceManager = newManager();
      const plain: PlainObject = new PlainObject();
      const id: number = manager.addHostCreatedInstance(plain);
      new OhosObjectHostApiImpl(manager).dispose(id);
      expect(manager.getInstance(id)).assertUndefined();
    })

    // ---------- PermissionRequestHostApiImpl ----------
    it('permissionRequestGrantForwardsResources', 0, () => {
      const manager: InstanceManager = newManager();
      const request: FakePermissionRequest = new FakePermissionRequest();
      const id: number = manager.addHostCreatedInstance(request);
      new PermissionRequestHostApiImpl(new MockBinaryMessenger(), manager).grant(id, ['camera', 'mic']);
      expect(request.grantCount).assertEqual(1);
      expect(request.grantedResources.length).assertEqual(2);
      expect(request.grantedResources[0]).assertEqual('camera');
    })

    it('permissionRequestDenyForwards', 0, () => {
      const manager: InstanceManager = newManager();
      const request: FakePermissionRequest = new FakePermissionRequest();
      const id: number = manager.addHostCreatedInstance(request);
      new PermissionRequestHostApiImpl(new MockBinaryMessenger(), manager).deny(id);
      expect(request.denyCount).assertEqual(1);
    })

    it('permissionRequestUnknownIdThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new PermissionRequestHostApiImpl(new MockBinaryMessenger(), manager).grant(424242, []);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- CustomViewCallbackHostApiImpl ----------
    it('customViewCallbackHiddenForwards', 0, () => {
      const manager: InstanceManager = newManager();
      const callback: FakeCustomViewCallback = new FakeCustomViewCallback();
      const id: number = manager.addHostCreatedInstance(callback);
      new CustomViewCallbackHostApiImpl(new MockBinaryMessenger(), manager).onCustomViewHidden(id);
      expect(callback.hiddenCount).assertEqual(1);
    })

    it('customViewCallbackUnknownIdThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new CustomViewCallbackHostApiImpl(new MockBinaryMessenger(), manager).onCustomViewHidden(777);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- SslErrorHandlerHostApiImpl ----------
    it('sslCancelInvokesHandlerAndReleasesIt', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeSslErrorHandler = new FakeSslErrorHandler();
      const id: number = manager.addHostCreatedInstance(handler);
      new SslErrorHandlerHostApiImpl(new MockBinaryMessenger(), manager).cancel(id);
      expect(handler.cancelCount).assertEqual(1);
      // 一次性决策：决策后即从实例表移除，防止泄漏。
      expect(manager.getInstance(id)).assertUndefined();
    })

    it('sslProceedInvokesHandlerAndReleasesIt', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeSslErrorHandler = new FakeSslErrorHandler();
      const id: number = manager.addHostCreatedInstance(handler);
      new SslErrorHandlerHostApiImpl(new MockBinaryMessenger(), manager).proceed(id);
      expect(handler.proceedCount).assertEqual(1);
      expect(manager.getInstance(id)).assertUndefined();
    })

    it('sslUnknownIdThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new SslErrorHandlerHostApiImpl(new MockBinaryMessenger(), manager).cancel(8888);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- HttpAuthHandlerHostApiImpl ----------
    it('httpAuthUsePasswordForwardsResult', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeHttpAuthHandler = new FakeHttpAuthHandler();
      handler.usePasswordResult = true;
      const id: number = manager.addHostCreatedInstance(handler);
      const result: boolean =
        new HttpAuthHandlerHostApiImpl(new MockBinaryMessenger(), manager).useHttpAuthUsernamePassword(id);
      expect(result).assertTrue();
    })

    it('httpAuthProceedForwardsCredentialsAndReleases', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeHttpAuthHandler = new FakeHttpAuthHandler();
      const id: number = manager.addHostCreatedInstance(handler);
      new HttpAuthHandlerHostApiImpl(new MockBinaryMessenger(), manager).proceed(id, 'user', 'pass');
      expect(handler.lastUsername).assertEqual('user');
      expect(handler.lastPassword).assertEqual('pass');
      expect(manager.getInstance(id)).assertUndefined();
    })

    it('httpAuthCancelForwardsAndReleases', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeHttpAuthHandler = new FakeHttpAuthHandler();
      const id: number = manager.addHostCreatedInstance(handler);
      new HttpAuthHandlerHostApiImpl(new MockBinaryMessenger(), manager).cancel(id);
      expect(handler.cancelCount).assertEqual(1);
      expect(manager.getInstance(id)).assertUndefined();
    })

    it('httpAuthQueryDoesNotReleaseInstance', 0, () => {
      const manager: InstanceManager = newManager();
      const handler: FakeHttpAuthHandler = new FakeHttpAuthHandler();
      const id: number = manager.addHostCreatedInstance(handler);
      new HttpAuthHandlerHostApiImpl(new MockBinaryMessenger(), manager).useHttpAuthUsernamePassword(id);
      expect(manager.containsInstance(handler)).assertTrue();
    })

    it('httpAuthUnknownIdThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new HttpAuthHandlerHostApiImpl(new MockBinaryMessenger(), manager).cancel(66666);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- GeolocationPermissionsCallbackHostApiImpl ----------
    it('geolocationInvokeForwardsArguments', 0, () => {
      const manager: InstanceManager = newManager();
      const callback: FakeJsGeolocation = new FakeJsGeolocation();
      const id: number = manager.addHostCreatedInstance(callback);
      new GeolocationPermissionsCallbackHostApiImpl(new MockBinaryMessenger(), manager)
        .invoke(id, 'about:blank', true, false);
      expect(callback.invokeCount).assertEqual(1);
      expect(callback.lastOrigin).assertEqual('about:blank');
      expect(callback.lastAllow).assertTrue();
      expect(callback.lastRetain).assertFalse();
    })

    it('geolocationUnknownIdThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new GeolocationPermissionsCallbackHostApiImpl(new MockBinaryMessenger(), manager)
          .invoke(55555, 'origin', false, false);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- DownloadListenerHostApiImpl ----------
    it('downloadListenerCreateRegistersDartInstance', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new DownloadListenerHostApiImpl(
        manager, new DownloadListenerCreator(), new DownloadListenerFlutterApiImpl(messenger, manager)
      ).create(77);
      const listener: DownloadListener = manager.getInstance(77) as Object as DownloadListener;
      expect(listener != null).assertTrue();
    })

    it('downloadListenerOnStartSendsToDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new DownloadListenerHostApiImpl(
        manager, new DownloadListenerCreator(), new DownloadListenerFlutterApiImpl(messenger, manager)
      ).create(77);
      const listener: DownloadListener = manager.getInstance(77) as Object as DownloadListener;
      listener.onDownloadStart('about:blank', 'ua', 'attachment', 'application/vnd.android.package-archive', 1024);
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'DownloadListenerFlutterApi.onDownloadStart')).assertTrue();
    })

    // ---------- JavaScriptChannelHostApiImpl ----------
    it('javaScriptChannelCreateRegistersChannelWithName', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new JavaScriptChannelHostApiImpl(
        manager, new JavaScriptChannelCreator(),
        new JavaScriptChannelFlutterApiImpl(messenger, manager)
      ).create(88, 'my_channel');
      const channel: JavaScriptChannel = manager.getInstance(88) as Object as JavaScriptChannel;
      expect(channel.getJavaScriptChannelName()).assertEqual('my_channel');
    })

    // ---------- CookieManagerHostApiImpl ----------
    it('cookieManagerAttachInstanceIsNoOp', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        new CookieManagerHostApiImpl(new MockBinaryMessenger(), manager).attachInstance(1);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })

    it('cookieManagerRejectsUnknownWebViewIdentifier', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      let message: string = '';
      try {
        new CookieManagerHostApiImpl(new MockBinaryMessenger(), manager)
          .setAcceptThirdPartyCookies(1, 99999, true);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('not found')).assertTrue();
    })

    // ---------- WebStorageHostApiImpl ----------
    it('webStorageCreateIsNoOp', 0, () => {
      let threw: boolean = false;
      try {
        new WebStorageHostApiImpl().create(1);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })

    // ---------- FlutterAssetManagerHostApiImpl ----------
    it('assetManagerListReturnsValues', 0, async () => {
      const fake: FakeFlutterAssetManager = new FakeFlutterAssetManager();
      const api: FlutterAssetManagerHostApiImpl = new FlutterAssetManagerHostApiImpl(fake);
      const paths: Array<string> = await api.list('assets');
      expect(paths.length).assertEqual(2);
      expect(paths[0]).assertEqual('assets/a.txt');
    })

    it('assetManagerListEmptyDirectoryReturnsEmpty', 0, async () => {
      const fake: FakeFlutterAssetManager = new FakeFlutterAssetManager();
      fake.listResult = [];
      const api: FlutterAssetManagerHostApiImpl = new FlutterAssetManagerHostApiImpl(fake);
      const paths: Array<string> = await api.list('empty');
      expect(paths.length).assertEqual(0);
    })

    it('assetManagerListRethrowsOnError', 0, async () => {
      const fake: FakeFlutterAssetManager = new FakeFlutterAssetManager();
      fake.shouldThrow = true;
      const api: FlutterAssetManagerHostApiImpl = new FlutterAssetManagerHostApiImpl(fake);
      let message: string = '';
      try {
        await api.list('bad');
      } catch (err) {
        message = `${err}`;
      }
      expect(message.includes('mock list failure')).assertTrue();
    })

    it('assetManagerGetAssetFilePathByNameDelegates', 0, () => {
      const api: FlutterAssetManagerHostApiImpl =
        new FlutterAssetManagerHostApiImpl(new FakeFlutterAssetManager());
      expect(api.getAssetFilePathByName('foo.png')).assertEqual('flutter_assets/foo.png');
    })

    // ---------- WebViewHostApiImpl ----------
    it('webViewHostApiExposesInstanceManager', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const context: common.Context = coerce<common.Context>(undefined);
      const api: WebViewHostApiImpl =
        new WebViewHostApiImpl(manager, new WebViewProxy(), messenger, context);
      expect(api.getInstanceManager()).assertEqual(manager);
    })

    it('webViewHostApiSetApiReplacesApi', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const context: common.Context = coerce<common.Context>(undefined);
      const api: WebViewHostApiImpl =
        new WebViewHostApiImpl(manager, new WebViewProxy(), messenger, context);
      let threw: boolean = false;
      try {
        api.setApi(new WebViewFlutterApiImpl(messenger, manager));
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })
  })
}
