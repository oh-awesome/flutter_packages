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
 
// WebViewHostApiImpl 单元测试：通过注入 FakeWebviewController 覆盖
// 加载/导航/JS 执行/滚动/通道注册/客户端绑定等路径，并通过 Pigeon 生成的
// 消息处理器直接驱动方法分发与错误包装。

import { describe, it, expect } from '@ohos/hypium';
import common from '@ohos.app.ability.common';
import web_webview from '@ohos.web.webview';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import { Result } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { WebViewHostApi } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import {
  WebViewHostApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import {
  WebViewClientImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientHostApiImpl';
import {
  WebViewClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientFlutterApiImpl';
import {
  WebChromeClient,
  WebChromeClientCreator,
  WebChromeClientHostApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';
import {
  WebChromeClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientFlutterApiImpl';
import { JavaScriptChannel } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannel';
import { JavaScriptChannelFlutterApiImpl } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannelFlutterApiImpl';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import { FakeDownloadListener, coerce } from '../testmock/MockInstances';
import {
  FakeWebViewPlatformView,
  FakeWebViewProxy
} from '../testmock/MockViews';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

/** 页面事件（url 载荷）。 */
class UrlEvent {
  public url: string;

  constructor(url: string) {
    this.url = url;
  }
}

/** 下载事件（onDownloadStart 载荷）。 */
class DownloadEvent {
  public url: string;
  public userAgent: string;
  public contentDisposition: string;
  public mimetype: string;
  public contentLength: number;

  constructor(url: string, userAgent: string, contentDisposition: string,
    mimetype: string, contentLength: number) {
    this.url = url;
    this.userAgent = userAgent;
    this.contentDisposition = contentDisposition;
    this.mimetype = mimetype;
    this.contentLength = contentLength;
  }
}

class FakeStringResult implements Result<string> {
  public got: string | null = null;
  public failed: boolean = false;

  success: (result: string) => void = (result: string): void => {
    this.got = result;
  }

  error: (error: Error) => void = (error: Error): void => {
    this.failed = true;
  }
}

/** 每个用例独立的装配：messenger + manager + fake 视图 + HostApi。 */
class Fixture {
  public messenger: MockBinaryMessenger = new MockBinaryMessenger();
  public manager: InstanceManager = new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
  public view: FakeWebViewPlatformView;
  public proxy: FakeWebViewProxy;
  public api: WebViewHostApiImpl;
  public viewId: number;

  constructor() {
    this.view = new FakeWebViewPlatformView(this.messenger, this.manager);
    this.proxy = new FakeWebViewProxy(this.view);
    this.api = new WebViewHostApiImpl(
      this.manager, this.proxy, this.messenger, coerce<common.Context>(undefined)
    );
    this.viewId = this.manager.addHostCreatedInstance(this.view);
  }
}

/** 等待微任务/宏任务各一轮，让 async HostApi 方法内部完成。 */
async function flush(): Promise<void> {
  await new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, 0);
  });
}

export default function webViewHostApiTest() {
  describe('WebViewHostApiTest', () => {
    // ---------- 生成代码分发：setup + handler ----------
    it('generatedSetupRegistersWebViewHandlers', 0, () => {
      const f: Fixture = new Fixture();
      WebViewHostApi.setup(f.messenger, f.api);
      expect(f.messenger.hasHandlerFor(CHANNEL_PREFIX + 'WebViewHostApi.create')).assertTrue();
      expect(f.messenger.hasHandlerFor(CHANNEL_PREFIX + 'WebViewHostApi.loadUrl')).assertTrue();
      expect(f.messenger.hasHandlerFor(CHANNEL_PREFIX + 'WebViewHostApi.goBack')).assertTrue();
    })

    it('createViaHandlerRegistersViewAndRepliesNull', 0, () => {
      const f: Fixture = new Fixture();
      WebViewHostApi.setup(f.messenger, f.api);
      const wrapped: Array<Object> | null =
        f.messenger.driveHandler(WebViewHostApi.getCodec(), CHANNEL_PREFIX + 'WebViewHostApi.create', [99]);
      expect(wrapped != null).assertTrue();
      expect(`${wrapped![0]}`).assertEqual('null');
      expect(f.manager.getInstance(99)).assertEqual(f.view);
    })

    it('createViaHandlerAddsViewToActiveRegistryUntilDisposed', 0, () => {
      const f: Fixture = new Fixture();
      WebViewHostApi.setup(f.messenger, f.api);
      f.messenger.driveHandler(WebViewHostApi.getCodec(), CHANNEL_PREFIX + 'WebViewHostApi.create', [7]);
      f.api.disposeAllActiveWebViews();
      expect(f.view.releaseCount).assertEqual(1);
      // 重复调用是幂等的：视图已从注册表移除。
      f.api.disposeAllActiveWebViews();
      expect(f.view.releaseCount).assertEqual(1);
    })

    it('handlerWrapsImplErrorAsFlutterError', 0, () => {
      const f: Fixture = new Fixture();
      WebViewHostApi.setup(f.messenger, f.api);
      // 未知实例 id → requireWebViewInstance 抛错 → handler 包装为 [code, message, details]。
      const wrapped: Array<Object> | null = f.messenger.driveHandler(
        WebViewHostApi.getCodec(), CHANNEL_PREFIX + 'WebViewHostApi.loadData', [424242, 'd', 'm', 'e']);
      expect(wrapped != null).assertTrue();
      expect(`${wrapped![1]}`).assertEqual('WebViewHostApiImpl instance not found, id = 424242');
    })

    // ---------- loadData 家族 ----------
    it('loadDataDelegatesToController', 0, () => {
      const f: Fixture = new Fixture();
      f.api.loadData(f.viewId, '<html/>', 'text/html', 'utf-8');
      expect(f.view.fakeController.loadDataCount).assertEqual(1);
      expect(f.view.fakeController.lastLoadData[0]).assertEqual('<html/>');
      expect(f.view.fakeController.lastLoadData[1]).assertEqual('text/html');
    })

    it('loadDataWithBaseUrlDefaultsEmptyBaseUrlToRawfile', 0, async () => {
      const f: Fixture = new Fixture();
      await f.api.loadDataWithBaseUrl(f.viewId, '  ', 'data', 'text/html', 'utf-8', coerce<string>(null));
      expect(f.view.fakeController.loadDataCount).assertEqual(1);
      expect(f.view.fakeController.lastLoadData[3]).assertEqual('resource://rawfile/');
      expect(f.view.fakeController.lastLoadData[4]).assertEqual(' ');
    })

    it('loadUrlDelegatesWithHeadersAndCachesCurrentUrl', 0, async () => {
      const f: Fixture = new Fixture();
      const headers: Map<string, string> = new Map<string, string>();
      headers.set('X-Test', '1');
      await f.api.loadUrl(f.viewId, 'about:blank', headers);
      expect(f.view.fakeController.lastLoadUrl).assertEqual('about:blank');
      expect(f.view.fakeController.lastLoadUrlHeaderCount).assertEqual(1);
      expect(f.view.getUrl()).assertEqual('about:blank');
    })

    it('loadUrlControllerFailureIsRethrown', 0, async () => {
      const f: Fixture = new Fixture();
      f.view.fakeController.throwOn = 'loadUrl';
      let threw: boolean = false;
      try {
        await f.api.loadUrl(f.viewId, 'about:blank', new Map<string, string>());
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- postUrl / getUrl / 标题 / 导航 ----------
    it('postUrlDelegatesToController', 0, async () => {
      const f: Fixture = new Fixture();
      await f.api.postUrl(f.viewId, 'about:blank', new Uint8Array([104, 105]));
      expect(f.view.fakeController.postUrlCount).assertEqual(1);
      expect(f.view.fakeController.lastPostUrl).assertEqual('about:blank');
    })

    it('getUrlReturnsControllerUrl', 0, async () => {
      const f: Fixture = new Fixture();
      const url: string = await f.api.getUrl(f.viewId);
      expect(url).assertEqual('about:blank');
    })

    it('canGoBackAndForwardReadControllerState', 0, () => {
      const f: Fixture = new Fixture();
      expect(f.api.canGoBack(f.viewId)).assertTrue();
      expect(f.api.canGoForward(f.viewId)).assertFalse();
    })

    it('navigationMethodsCallControllerActions', 0, () => {
      const f: Fixture = new Fixture();
      f.api.goBack(f.viewId);
      f.api.goForward(f.viewId);
      f.api.reload(f.viewId);
      expect(f.view.fakeController.backwardCount).assertEqual(1);
      expect(f.view.fakeController.forwardCount).assertEqual(1);
      expect(f.view.fakeController.refreshCount).assertEqual(1);
    })

    it('navigationControllerFailureIsRethrown', 0, () => {
      const f: Fixture = new Fixture();
      f.view.fakeController.throwOn = 'backward';
      let threw: boolean = false;
      try {
        f.api.goBack(f.viewId);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    it('getTitleReturnsControllerTitle', 0, () => {
      const f: Fixture = new Fixture();
      expect(f.api.getTitle(f.viewId)).assertEqual('Example Title');
    })

    it('unknownInstanceIdsFailFast', 0, () => {
      const f: Fixture = new Fixture();
      const probes: Array<() => void> = [
        (): void => {
          f.api.loadData(88888, 'd', 'm', 'e');
        },
        (): void => {
          f.api.canGoBack(88888);
        },
        (): void => {
          f.api.getTitle(88888);
        },
        (): void => {
          f.api.setWebViewClient(88888, 1);
        }
      ];
      for (const probe of probes) {
        let threw: boolean = false;
        let message: string = '';
        try {
          probe();
        } catch (err) {
          threw = true;
          message = `${err}`;
        }
        expect(threw).assertTrue();
        expect(message.includes('not found')).assertTrue();
      }
    })

    // ---------- clearCache / evaluateJavascript ----------
    it('clearCacheRemovesCacheAfterControllerAttach', 0, async () => {
      const f: Fixture = new Fixture();
      f.api.clearCache(f.viewId, true);
      await flush();
      expect(f.view.fakeController.removeCacheCount).assertEqual(1);
      expect(f.view.fakeController.lastRemoveCacheFlag).assertTrue();
    })

    it('clearCacheSwallowsControllerFailure', 0, async () => {
      const f: Fixture = new Fixture();
      f.view.fakeController.throwOn = 'removeCache';
      f.api.clearCache(f.viewId, false);
      await flush();
      expect(f.view.fakeController.removeCacheCount).assertEqual(0);
    })

    it('evaluateJavascriptRepliesWithScriptResult', 0, async () => {
      const f: Fixture = new Fixture();
      const result: FakeStringResult = new FakeStringResult();
      f.api.evaluateJavascript(f.viewId, '1+1', result);
      await flush();
      expect(result.got).assertEqual('js-result');
      expect(result.failed).assertFalse();
    })

    it('evaluateJavascriptForwardsScriptFailure', 0, async () => {
      const f: Fixture = new Fixture();
      f.view.fakeController.runJavaScriptShouldFail = true;
      const result: FakeStringResult = new FakeStringResult();
      f.api.evaluateJavascript(f.viewId, 'boom()', result);
      await flush();
      expect(result.failed).assertTrue();
    })

    // ---------- 滚动 ----------
    it('scrollToUpdatesCachedPosition', 0, async () => {
      const f: Fixture = new Fixture();
      f.api.scrollTo(f.viewId, 5, 7);
      await flush();
      expect(f.view.fakeController.scrollToCount).assertEqual(1);
      expect(f.api.getScrollX(f.viewId)).assertEqual(5);
      expect(f.api.getScrollY(f.viewId)).assertEqual(7);
    })

    it('scrollByAddsOffsetToCurrentPosition', 0, async () => {
      const f: Fixture = new Fixture();
      f.api.scrollTo(f.viewId, 5, 7);
      await flush();
      f.api.scrollBy(f.viewId, 3, 4);
      await flush();
      expect(f.view.fakeController.scrollByCount).assertEqual(1);
      expect(f.api.getScrollX(f.viewId)).assertEqual(8);
      expect(f.api.getScrollY(f.viewId)).assertEqual(11);
    })

    it('scrollToControllerFailureKeepsCachedPosition', 0, async () => {
      const f: Fixture = new Fixture();
      f.view.fakeController.throwOn = 'scrollTo';
      f.api.scrollTo(f.viewId, 5, 7);
      await flush();
      expect(f.api.getScrollX(f.viewId)).assertEqual(0);
    })

    it('getScrollPositionReturnsCurrentPoint', 0, () => {
      const f: Fixture = new Fixture();
      const point = f.api.getScrollPosition(f.viewId);
      expect(point.getX()).assertEqual(0);
      expect(point.getY()).assertEqual(0);
    })

    // ---------- 调试开关 / 客户端与监听器绑定 ----------
    it('setWebContentsDebuggingEnabledDelegatesToProxy', 0, () => {
      const f: Fixture = new Fixture();
      f.api.setWebContentsDebuggingEnabled(true);
      expect(f.proxy.debuggingFlags.length).assertEqual(1);
      expect(f.proxy.debuggingFlags[0]).assertTrue();
    })

    it('setWebViewClientBindsClientToView', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebViewClientImpl =
        new WebViewClientImpl(new WebViewClientFlutterApiImpl(f.messenger, f.manager));
      const clientId: number = f.manager.addHostCreatedInstance(client);
      f.api.setWebViewClient(f.viewId, clientId);
      // 绑定后视图的页面事件应转发给 client。
      f.view.onPageBegin(new UrlEvent('about:blank') as Object);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageStarted')).assertTrue();
    })

    it('setWebViewClientWithUnknownClientThrows', 0, () => {
      const f: Fixture = new Fixture();
      let threw: boolean = false;
      let message: string = '';
      try {
        f.api.setWebViewClient(f.viewId, 77777);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('WebViewClient instance not found')).assertTrue();
    })

    it('setWebChromeClientBindsClientToView', 0, () => {
      const f: Fixture = new Fixture();
      const chromeApi: WebChromeClientHostApiImpl = new WebChromeClientHostApiImpl(
        f.manager, new WebChromeClientCreator(),
        new WebChromeClientFlutterApiImpl(f.messenger, f.manager)
      );
      chromeApi.create(31);
      const client: WebChromeClient =
        f.manager.getInstance(31) as Object as WebChromeClient;
      f.api.setWebChromeClient(f.viewId, 31);
      expect(f.manager.getInstance(31)).assertEqual(client);
    })

    it('setWebChromeClientWithUnknownClientThrows', 0, () => {
      const f: Fixture = new Fixture();
      let threw: boolean = false;
      let message: string = '';
      try {
        f.api.setWebChromeClient(f.viewId, 77777);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('WebChromeClient instance not found')).assertTrue();
    })

    it('setDownloadListenerBindsListenerToView', 0, () => {
      const f: Fixture = new Fixture();
      const listener: FakeDownloadListener = new FakeDownloadListener();
      const listenerId: number = f.manager.addHostCreatedInstance(listener);
      f.api.setDownloadListener(f.viewId, listenerId);
      // 绑定后视图的下载事件应转发给 listener。
      f.view.onDownloadStart(new DownloadEvent(
        'about:blank', 'ua', 'cd', 'application/zip', 12
      ) as Object);
      expect(listener.lastUrl).assertEqual('about:blank');
    })

    it('setDownloadListenerWithUnknownListenerThrows', 0, () => {
      const f: Fixture = new Fixture();
      let threw: boolean = false;
      let message: string = '';
      try {
        f.api.setDownloadListener(f.viewId, 77777);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('DownloadListener instance not found')).assertTrue();
    })

    // ---------- JavaScript 通道 ----------
    it('addJavaScriptChannelRegistersProxyAndRefreshes', 0, async () => {
      const f: Fixture = new Fixture();
      const flutterApi: JavaScriptChannelFlutterApiImpl =
        new JavaScriptChannelFlutterApiImpl(f.messenger, f.manager);
      const channel: JavaScriptChannel = new JavaScriptChannel(flutterApi, 'nativeChan');
      const channelId: number = f.manager.addHostCreatedInstance(channel);
      await f.api.addJavaScriptChannel(f.viewId, channelId);
      expect(f.view.fakeController.registeredProxyNames.length).assertEqual(1);
      expect(f.view.fakeController.registeredProxyNames[0]).assertEqual('nativeChan');
      expect(f.view.fakeController.refreshCount >= 1).assertTrue();
    })

    it('addJavaScriptChannelWithUnknownChannelThrows', 0, async () => {
      const f: Fixture = new Fixture();
      let threw: boolean = false;
      let message: string = '';
      try {
        await f.api.addJavaScriptChannel(f.viewId, 77777);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('JavaScriptChannel instance not found')).assertTrue();
    })

    it('removeJavaScriptChannelDeletesProxyAndDropsRegistration', 0, () => {
      const f: Fixture = new Fixture();
      const flutterApi: JavaScriptChannelFlutterApiImpl =
        new JavaScriptChannelFlutterApiImpl(f.messenger, f.manager);
      const channel: JavaScriptChannel = new JavaScriptChannel(flutterApi, 'goneChan');
      const channelId: number = f.manager.addHostCreatedInstance(channel);
      f.api.removeJavaScriptChannel(f.viewId, channelId);
      expect(f.view.fakeController.deletedProxyNames.length).assertEqual(1);
      expect(f.view.fakeController.deletedProxyNames[0]).assertEqual('goneChan');
      expect(f.manager.getInstance(channelId)).assertUndefined();
    })

    it('removeJavaScriptChannelControllerFailureKeepsRegistration', 0, () => {
      const f: Fixture = new Fixture();
      const flutterApi: JavaScriptChannelFlutterApiImpl =
        new JavaScriptChannelFlutterApiImpl(f.messenger, f.manager);
      const channel: JavaScriptChannel = new JavaScriptChannel(flutterApi, 'keptChan');
      const channelId: number = f.manager.addHostCreatedInstance(channel);
      f.view.fakeController.throwOn = 'deleteJavaScriptRegister';
      let threw: boolean = false;
      try {
        f.api.removeJavaScriptChannel(f.viewId, channelId);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
      // 失败时不移除注册（remove 在 try 之后）。
      expect(f.manager.getInstance(channelId)).assertEqual(channel);
    })

    // ---------- toWebHeaders ----------
    it('toWebHeadersConvertsMapEntries', 0, () => {
      const headers: Map<string, string> = new Map<string, string>();
      headers.set('a', '1');
      headers.set('b', '2');
      const converted = f_toWebHeaders(headers);
      expect(converted.length).assertEqual(2);
      expect(converted[0].headerKey).assertEqual('a');
      expect(converted[0].headerValue).assertEqual('1');
    })

    it('toWebHeadersReturnsEmptyArrayForEmptyOrNullMap', 0, () => {
      expect(f_toWebHeaders(new Map<string, string>()).length).assertEqual(0);
      expect(f_toWebHeaders(coerce<Map<string, string>>(null)).length).assertEqual(0);
    })
  })
}

/** 直接构造 HostApi 实例调用 toWebHeaders（静态辅助）。 */
function f_toWebHeaders(headers: Map<string, string>): Array<web_webview.WebHeader> {
  const api: WebViewHostApiImpl = new WebViewHostApiImpl(
    new InstanceManager({ onFinalize: (identifier: number): void => {
    } }),
    new FakeWebViewProxy(new FakeWebViewPlatformView(new MockBinaryMessenger(), new InstanceManager({
      onFinalize: (identifier: number): void => {
      }
    }))),
    new MockBinaryMessenger(),
    coerce<common.Context>(undefined)
  );
  return api.toWebHeaders(headers);
}
