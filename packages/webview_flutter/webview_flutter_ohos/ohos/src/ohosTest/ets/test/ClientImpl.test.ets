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

// Client / Factory 单元测试：WebViewClient 静态转换、事件转发、
// HostApi 创建流程与 FlutterWebViewFactory 取回逻辑。

import { describe, it, expect } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebViewClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientFlutterApiImpl';
import {
  WebViewClientHostApiImpl,
  WebViewClientCreator,
  WebViewClientImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientHostApiImpl';
import {
  WebChromeClientHostApiImpl,
  WebChromeClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';
import {
  WebChromeClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientFlutterApiImpl';
import {
  FlutterWebViewFactory
} from '../../../main/ets/io.flutter.plugins/webview_flutter/FlutterWebViewFactory';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import {
  FakeWebResourceRequest,
  FakeWebResourceError,
  FakeWebResourceResponse,
  FakeHttpAuthHandler,
  FakeSslErrorHandler,
  FakeHeader
} from '../testmock/MockInstances';
import { FakeWebViewPlatformView, FakePlatformView } from '../testmock/MockViews';
import { coerce } from '../testmock/MockInstances';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

class PlainObject {
}

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

export default function clientImplTest() {
  describe('ClientImplTest', () => {
    // ---------- WebViewClientFlutterApiImpl 静态转换 ----------
    it('createWebResourceErrorDataForUndefinedBuildsUnknownError', 0, () => {
      const data = WebViewClientFlutterApiImpl.createWebResourceErrorData(
        coerce<WebResourceError>(undefined)
      );
      const arr: Array<Object> = data.toArray() as Object as Array<Object>;
      expect(`${arr[0]}`).assertEqual('-1');
      expect(`${arr[1]}`).assertEqual('Unknown error');
    })

    it('createWebResourceErrorDataForErrorUsesCodeAndInfo', 0, () => {
      const error: FakeWebResourceError = new FakeWebResourceError();
      error.errorCode = 403;
      error.errorInfo = 'forbidden';
      const data = WebViewClientFlutterApiImpl.createWebResourceErrorData(
        error as Object as WebResourceError
      );
      const arr: Array<Object> = data.toArray() as Object as Array<Object>;
      expect(`${arr[0]}`).assertEqual('403');
      expect(`${arr[1]}`).assertEqual('forbidden');
    })

    it('toWebHeadersMapReturnsEmptyForUndefined', 0, () => {
      const map = WebViewClientFlutterApiImpl.toWebHeadersMap(
        coerce<Array<Header>>(undefined)
      );
      expect(map.size).assertEqual(0);
    })

    it('toWebHeadersMapConvertsHeaderArray', 0, () => {
      const headers: Array<Header> = [new FakeHeader('a', '1'), new FakeHeader('b', '2')];
      const map = WebViewClientFlutterApiImpl.toWebHeadersMap(headers);
      expect(map.size).assertEqual(2);
      expect(map.get('a')).assertEqual('1');
      expect(map.get('b')).assertEqual('2');
    })

    it('createWebResourceRequestDataMapsAllFields', 0, () => {
      const request: FakeWebResourceRequest = new FakeWebResourceRequest();
      const data = WebViewClientFlutterApiImpl.createWebResourceRequestData(
        request as Object as WebResourceRequest
      );
      expect(data.getUrl()).assertEqual('about:blank');
      expect(data.getIsForMainFrame()).assertTrue();
      expect(data.getIsRedirect()).assertFalse();
      expect(data.getHasGesture()).assertTrue();
      expect(data.getMethod()).assertEqual('GET');
      expect(data.getRequestHeaders().size).assertEqual(1);
      expect(data.getRequestHeaders().get('Accept')).assertEqual('text/html');
    })

    // ---------- WebViewClientImpl 事件转发 ----------
    it('webViewClientOnPageStartedRegistersViewAndNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onPageStarted(view, 'about:blank');
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.create')).assertTrue();
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageStarted')).assertTrue();
    })

    it('webViewClientOnPageFinishedNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onPageFinished(view, 'about:blank');
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageFinished')).assertTrue();
    })

    it('webViewClientUnknownClientSendsWithMinusOne', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      // 实际行为：未注册 client 的 getIdentifier 返回 -1（非 null），
      // getIdentifierForClient 的抛错分支不命中，事件以 -1 正常发给 Dart。
      let threw: boolean = false;
      try {
        client.onPageStarted(view, 'about:blank');
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageStarted')).assertTrue();
    })

    it('webViewClientShouldOverrideUrlLoadingUsesSynchronousReturnValue', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      const request: WebResourceRequest = new FakeWebResourceRequest() as Object as WebResourceRequest;
      expect(client.shouldOverrideUrlLoading(view, request)).assertFalse();
      client.setReturnValueForShouldOverrideUrlLoading(true);
      expect(client.shouldOverrideUrlLoading(view, request)).assertTrue();
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.requestLoading')).assertTrue();
    })

    it('webViewClientOnReceivedErrorNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onReceivedError(
        view,
        new FakeWebResourceRequest() as Object as WebResourceRequest,
        new FakeWebResourceError() as Object as WebResourceError
      );
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedRequestError')).assertTrue();
    })

    it('webViewClientOnReceivedHttpErrorNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onReceivedHttpError(
        view,
        new FakeWebResourceRequest() as Object as WebResourceRequest,
        new FakeWebResourceResponse() as Object as WebResourceResponse
      );
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedHttpError')).assertTrue();
    })

    it('webViewClientDoUpdateVisitedHistoryNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.doUpdateVisitedHistory(view, 'about:blank', false);
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.doUpdateVisitedHistory')).assertTrue();
    })

    it('webViewClientOnReceivedHttpAuthRequestNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onReceivedHttpAuthRequest(
        view, new FakeHttpAuthHandler(), 'host', 'realm'
      );
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedHttpAuthRequest')).assertTrue();
    })

    it('webViewClientOnReceivedSslErrorNotifiesDart', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(messenger, manager));
      manager.addHostCreatedInstance(client);
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      client.onReceivedSslError(view, new FakeSslErrorHandler(), 'about:blank', 'cert', 'desc');
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedSslError')).assertTrue();
    })

    // ---------- WebViewClientHostApiImpl ----------
    it('webViewClientHostApiCreateRegistersClient', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new WebViewClientHostApiImpl(
        manager, new WebViewClientCreator(), new WebViewClientFlutterApiImpl(messenger, manager)
      ).create(11);
      const client: Object = manager.getInstance(11) as Object;
      expect(client instanceof WebViewClientImpl).assertTrue();
    })

    it('webViewClientHostApiSetSynchronousReturnValueApplies', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: WebViewClientHostApiImpl = new WebViewClientHostApiImpl(
        manager, new WebViewClientCreator(), new WebViewClientFlutterApiImpl(messenger, manager)
      );
      api.create(12);
      api.setSynchronousReturnValueForShouldOverrideUrlLoading(12, true);
      const client: WebViewClientImpl = manager.getInstance(12) as Object as WebViewClientImpl;
      const view: FakeWebViewPlatformView = new FakeWebViewPlatformView(messenger, manager);
      expect(client.shouldOverrideUrlLoading(
        view, new FakeWebResourceRequest() as Object as WebResourceRequest
      )).assertTrue();
    })

    it('webViewClientHostApiSetSynchronousOnForeignInstanceThrows', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: WebViewClientHostApiImpl = new WebViewClientHostApiImpl(
        manager, new WebViewClientCreator(), new WebViewClientFlutterApiImpl(messenger, manager)
      );
      manager.addDartCreatedInstance(new PlainObject(), 13);
      let threw: boolean = false;
      try {
        api.setSynchronousReturnValueForShouldOverrideUrlLoading(13, true);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- WebChromeClientHostApiImpl ----------
    it('webChromeClientHostApiCreateRegistersClient', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      new WebChromeClientHostApiImpl(
        manager, new WebChromeClientCreator(),
        new WebChromeClientFlutterApiImpl(messenger, manager)
      ).create(21);
      expect(manager.getInstance(21) != null).assertTrue();
    })

    it('webChromeClientHostApiSetSynchronousValuesApply', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: WebChromeClientHostApiImpl = new WebChromeClientHostApiImpl(
        manager, new WebChromeClientCreator(),
        new WebChromeClientFlutterApiImpl(messenger, manager)
      );
      api.create(22);
      let threw: boolean = false;
      try {
        api.setSynchronousReturnValueForOnShowFileChooser(22, true);
        api.setSynchronousReturnValueForOnConsoleMessage(22, true);
        api.setSynchronousReturnValueForOnJsAlert(22, true);
        api.setSynchronousReturnValueForOnJsConfirm(22, true);
        api.setSynchronousReturnValueForOnJsPrompt(22, true);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })

    it('webChromeClientHostApiUnknownIdThrows', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: WebChromeClientHostApiImpl = new WebChromeClientHostApiImpl(
        manager, new WebChromeClientCreator(),
        new WebChromeClientFlutterApiImpl(messenger, manager)
      );
      let threw: boolean = false;
      let message: string = '';
      try {
        api.setSynchronousReturnValueForOnJsAlert(33333, true);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('not found')).assertTrue();
    })

    // ---------- FlutterWebViewFactory ----------
    it('factoryReturnsRegisteredViewForIdentifier', 0, () => {
      const manager: InstanceManager = newManager();
      const factory: FlutterWebViewFactory = new FlutterWebViewFactory(manager);
      const view: FakePlatformView = new FakePlatformView();
      const id: number = manager.addHostCreatedInstance(view);
      const context: common.Context = coerce<common.Context>(undefined);
      const created = factory.create(context, 0, id);
      expect(created).assertEqual(view);
    })

    it('factoryThrowsWhenIdentifierMissing', 0, () => {
      const factory: FlutterWebViewFactory = new FlutterWebViewFactory(newManager());
      const context: common.Context = coerce<common.Context>(undefined);
      let threw: boolean = false;
      let message: string = '';
      try {
        factory.create(context, 0, null);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('identifier is required')).assertTrue();
    })

    it('factoryThrowsWhenInstanceNotFound', 0, () => {
      const factory: FlutterWebViewFactory = new FlutterWebViewFactory(newManager());
      const context: common.Context = coerce<common.Context>(undefined);
      let threw: boolean = false;
      let message: string = '';
      try {
        factory.create(context, 0, 4321);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('Unable to find WebView instance')).assertTrue();
    })

    it('factoryExposesCreateArgsCodec', 0, () => {
      const factory: FlutterWebViewFactory = new FlutterWebViewFactory(newManager());
      expect(factory.getCreateArgsCodec() != null).assertTrue();
    })
  })
}
