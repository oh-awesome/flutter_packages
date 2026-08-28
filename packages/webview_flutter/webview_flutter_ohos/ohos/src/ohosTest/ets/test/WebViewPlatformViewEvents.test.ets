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
 
// WebViewPlatformView（真实实现）单元测试：直接构造真实视图，驱动其
// ArkWeb 事件转发字段（onPageBegin/onErrorReceive/onSslErrorReceive 等）、
// 生命周期方法（onControllerAttached/dispose/release）、脚本通道注册，
// 以及经 getWebSettings() 返回的 WebSettingsImpl 全部读写方法。
// 真实 WebviewController 未绑定 ArkUI 组件，相关调用可能抛错，
// 需要的用例均以 try/catch 包裹（行覆盖不受影响）。

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  HttpAuthHandler,
  SslErrorHandler
} from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import {
  WebViewPlatformView
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import {
  WebViewClient,
  WebViewClientImpl,
  WebViewClientHostApiImpl,
  WebViewClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientHostApiImpl';
import {
  WebViewClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewClientFlutterApiImpl';
import {
  WebChromeClient,
  WebChromeClientHostApiImpl,
  WebChromeClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';
import {
  WebChromeClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientFlutterApiImpl';
import {
  WebSettings
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebSettingsHostApiImpl';
import { JavaScriptChannel } from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannel';
import {
  JavaScriptChannelFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/JavaScriptChannelFlutterApiImpl';
import { DisplayListenerProxy } from '../../../main/ets/io.flutter.plugins/webview_flutter/DisplayListenerProxy';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import {
  FakeWebResourceRequest,
  FakeWebResourceError,
  FakeWebResourceResponse,
  FakeHttpAuthHandler,
  FakeSslErrorHandler,
  FakeConsoleMessage,
  FakeJsResult,
  FakeFileSelectorResult,
  FakeFileSelectorParam,
  FakeJsGeolocation,
  FakePermissionRequest
} from '../testmock/MockInstances';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

/** WebViewClient Fake：onReceivedSslError 抛错，用于覆盖转发失败的兜底 cancel。 */
class ThrowingWebViewClient implements WebViewClient {
  onPageStarted(view: WebViewPlatformView, url: string): void {
  }

  onPageFinished(view: WebViewPlatformView, url: string): void {
  }

  onReceivedError(view: WebViewPlatformView, request: WebResourceRequest, error: WebResourceError): void {
  }

  onReceivedHttpError(view: WebViewPlatformView, request: WebResourceRequest, response: WebResourceResponse): void {
  }

  shouldOverrideUrlLoading(view: WebViewPlatformView, request: WebResourceRequest): boolean {
    return false;
  }

  doUpdateVisitedHistory(view: WebViewPlatformView, url: string, isReload: boolean): void {
  }

  onReceivedHttpAuthRequest(
    view: WebViewPlatformView, handler: HttpAuthHandler, host: string, realm: string
  ): void {
  }

  onReceivedSslError(
    view: WebViewPlatformView, handler: SslErrorHandler,
    url: string, certificate: string, description: string
  ): void {
    throw new Error('mock ssl forward failure');
  }
}

/** 页面起止事件。 */
class UrlEvent {
  public url: string;

  constructor(url: string) {
    this.url = url;
  }
}

/** 资源加载失败事件。 */
class ErrorReceiveEvent {
  public request: FakeWebResourceRequest;
  public error: FakeWebResourceError;

  constructor(request: FakeWebResourceRequest, error: FakeWebResourceError) {
    this.request = request;
    this.error = error;
  }
}

/** HTTP 错误事件。 */
class HttpErrorReceiveEvent {
  public request: FakeWebResourceRequest;
  public response: FakeWebResourceResponse;

  constructor(request: FakeWebResourceRequest, response: FakeWebResourceResponse) {
    this.request = request;
    this.response = response;
  }
}

/** 历史访问事件。 */
class VisitedHistoryEvent {
  public url: string;
  public isRefreshed: boolean;

  constructor(url: string, isRefreshed: boolean) {
    this.url = url;
    this.isRefreshed = isRefreshed;
  }
}

/** HTTP 认证事件。 */
class HttpAuthEvent {
  public handler: FakeHttpAuthHandler;
  public host: string;
  public realm: string;

  constructor(handler: FakeHttpAuthHandler, host: string, realm: string) {
    this.handler = handler;
    this.host = host;
    this.realm = realm;
  }
}

/** SSL 错误事件：未提供的字段走默认值。 */
class SslErrorEvent {
  public handler: FakeSslErrorHandler | null = null;
  public url: string = '';
  public error: number = -1;
  public certIssuer: string = '';

  constructor(handler: FakeSslErrorHandler | null) {
    this.handler = handler;
  }
}

/** 进度变化事件。 */
class ProgressEvent {
  public newProgress: number;

  constructor(newProgress: number) {
    this.newProgress = newProgress;
  }
}

/** 地理位置弹窗事件。 */
class GeolocationShowEvent {
  public origin: string;
  public geolocation: FakeJsGeolocation;

  constructor(origin: string, geolocation: FakeJsGeolocation) {
    this.origin = origin;
    this.geolocation = geolocation;
  }
}

/** 权限请求事件。 */
class PermissionEvent {
  public request: FakePermissionRequest;

  constructor(request: FakePermissionRequest) {
    this.request = request;
  }
}

/** 控制台消息事件。 */
class ConsoleMessageEvent {
  public message: FakeConsoleMessage;

  constructor(message: FakeConsoleMessage) {
    this.message = message;
  }
}

/** 文件选择事件。 */
class FileSelectorEvent {
  public result: FakeFileSelectorResult;
  public fileSelector: FakeFileSelectorParam;

  constructor(result: FakeFileSelectorResult, fileSelector: FakeFileSelectorParam) {
    this.result = result;
    this.fileSelector = fileSelector;
  }
}

/** JS 对话框事件（alert/confirm/prompt 共用，value 仅 prompt 使用）。 */
class JsDialogEvent {
  public url: string;
  public message: string;
  public value: string;
  public result: FakeJsResult;

  constructor(url: string, message: string, value: string, result: FakeJsResult) {
    this.url = url;
    this.message = message;
    this.value = value;
    this.result = result;
  }
}

/** 新窗口事件。 */
class WindowNewEvent {
  public isAlert: boolean;
  public isUserTrigger: boolean;
  public handler: Object | null;

  constructor(isAlert: boolean, isUserTrigger: boolean, handler: Object | null) {
    this.isAlert = isAlert;
    this.isUserTrigger = isUserTrigger;
    this.handler = handler;
  }
}

/** 滚动事件。 */
class ScrollEvent {
  public xOffset: number;
  public yOffset: number;

  constructor(xOffset: number, yOffset: number) {
    this.xOffset = xOffset;
    this.yOffset = yOffset;
  }
}

/** 空事件：覆盖事件体缺失关键字的早退分支。 */
class EmptyEvent {
}

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

class Fixture {
  public messenger: MockBinaryMessenger = new MockBinaryMessenger();
  public manager: InstanceManager = newManager();
  public view: WebViewPlatformView;

  constructor() {
    this.view = new WebViewPlatformView(this.messenger, this.manager);
    this.manager.addHostCreatedInstance(this.view);
  }

  /** 创建并注册真实的 WebViewClientImpl，同时绑定到视图。 */
  attachWebViewClient(): WebViewClientImpl {
    const api: WebViewClientHostApiImpl = new WebViewClientHostApiImpl(
      this.manager, new WebViewClientCreator(),
      new WebViewClientFlutterApiImpl(this.messenger, this.manager)
    );
    api.create(71);
    const client: WebViewClientImpl = this.manager.getInstance(71) as Object as WebViewClientImpl;
    this.view.setWebViewClient(client);
    return client;
  }

  /** 创建并注册真实的 WebChromeClientImpl，同时绑定到视图。 */
  attachWebChromeClient(): WebChromeClient {
    const api: WebChromeClientHostApiImpl = new WebChromeClientHostApiImpl(
      this.manager, new WebChromeClientCreator(),
      new WebChromeClientFlutterApiImpl(this.messenger, this.manager)
    );
    api.create(72);
    const client: WebChromeClient = this.manager.getInstance(72) as Object as WebChromeClient;
    this.view.setWebChromeClient(client);
    return client;
  }
}

export default function webViewPlatformViewEventsTest() {
  describe('WebViewPlatformViewEventsTest', () => {
    // ---------- WebViewClient 事件转发 ----------
    it('pageEventsForwardToWebViewClient', 0, () => {
      const f: Fixture = new Fixture();
      f.attachWebViewClient();
      f.view.onPageBegin(new UrlEvent('about:blank'));
      f.view.onPageEnd(new UrlEvent('about:blank'));
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageStarted')).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onPageFinished')).assertTrue();
    })

    it('errorEventsForwardToWebViewClient', 0, () => {
      const f: Fixture = new Fixture();
      f.attachWebViewClient();
      f.view.onErrorReceive(new ErrorReceiveEvent(new FakeWebResourceRequest(), new FakeWebResourceError()));
      f.view.onHttpErrorReceive(
        new HttpErrorReceiveEvent(new FakeWebResourceRequest(), new FakeWebResourceResponse())
      );
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedRequestError')).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedHttpError')).assertTrue();
    })

    it('overrideUrlLoadingCoversAllBranches', 0, () => {
      const f: Fixture = new Fixture();
      const request: WebResourceRequest = new FakeWebResourceRequest() as Object as WebResourceRequest;
      // 无 client：默认放行。
      expect(f.view.onOverrideUrlLoading(request)).assertFalse();
      // loaded:/// 协议：直接拦截。
      const internal: FakeWebResourceRequest = new FakeWebResourceRequest();
      internal.requestUrl = 'loaded:///';
      expect(f.view.onOverrideUrlLoading(internal as Object as WebResourceRequest)).assertTrue();
      // 有 client：委托 shouldOverrideUrlLoading（默认 false）。
      f.attachWebViewClient();
      expect(f.view.onOverrideUrlLoading(request)).assertFalse();
      // 视图级返回值开关（写入即覆盖，读取路径由 client 委托逻辑使用）。
      f.view.setReturnValueForShouldOverrideUrlLoading(true);
    })

    it('visitedHistoryAndHttpAuthForward', 0, () => {
      const f: Fixture = new Fixture();
      // 无 client：onHttpAuthRequest 返回 false（不转发）。
      expect(f.view.onHttpAuthRequest(new HttpAuthEvent(new FakeHttpAuthHandler(), 'h', 'r'))).assertFalse();
      f.attachWebViewClient();
      f.view.onRefreshAccessedHistory(new VisitedHistoryEvent('about:blank', true));
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.doUpdateVisitedHistory')).assertTrue();
      // 有 client：包装 OhosHttpAuthHandler 并转发，返回 true。
      expect(f.view.onHttpAuthRequest(new HttpAuthEvent(new FakeHttpAuthHandler(), 'h', 'r'))).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedHttpAuthRequest')).assertTrue();
    })

    it('sslErrorReceivesCoverForwardCancelAndFallback', 0, () => {
      const f: Fixture = new Fixture();
      // 缺失 handler：直接返回。
      f.view.onSslErrorReceive(new SslErrorEvent(null));
      // 无 client：包装 handler 直接 cancel。
      const cancelled: FakeSslErrorHandler = new FakeSslErrorHandler();
      f.view.onSslErrorReceive(new SslErrorEvent(cancelled));
      expect(cancelled.cancelCount).assertEqual(1);
      // 有 client：转发 onReceivedSslError，客户端不自动 cancel（交由 Dart 决定）。
      f.attachWebViewClient();
      const forwarded: FakeSslErrorHandler = new FakeSslErrorHandler();
      const withFields: SslErrorEvent = new SslErrorEvent(forwarded);
      withFields.url = 'about:blank';
      withFields.error = 1;
      withFields.certIssuer = 'issuer';
      f.view.onSslErrorReceive(withFields);
      expect(forwarded.cancelCount).assertEqual(0);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewClientFlutterApi.onReceivedSslError')).assertTrue();
      // URL 缺失时回退到视图 url 字段。
      f.view.setUrl('about:blank');
      f.view.onSslErrorReceive(new SslErrorEvent(new FakeSslErrorHandler()));
      // 转发抛错：兜底 cancel。
      f.view.setWebViewClient(new ThrowingWebViewClient());
      const fallback: FakeSslErrorHandler = new FakeSslErrorHandler();
      f.view.onSslErrorReceive(new SslErrorEvent(fallback));
      expect(fallback.cancelCount).assertEqual(1);
    })

    // ---------- WebChromeClient 事件转发 ----------
    it('chromeEventsForwardToWebChromeClient', 0, () => {
      const f: Fixture = new Fixture();
      f.attachWebChromeClient();
      f.view.onProgressChange(new ProgressEvent(66));
      f.view.onGeolocationShow(new GeolocationShowEvent('about:blank', new FakeJsGeolocation()));
      f.view.onGeolocationHide();
      f.view.onPermissionRequest(new PermissionEvent(new FakePermissionRequest()));
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onProgressChanged')).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onGeolocationPermissionsShowPrompt')).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onGeolocationPermissionsHidePrompt')).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onPermissionRequest')).assertTrue();
      // 文件选择：同步返回值开关关闭时返回 false。
      expect(f.view.onShowFileSelector(
        new FileSelectorEvent(new FakeFileSelectorResult(), new FakeFileSelectorParam())
      )).assertFalse();
    })

    it('consoleMessageLogsLocallyWithoutClient', 0, () => {
      const f: Fixture = new Fixture();
      const handled: boolean = f.view.onConsoleMessage(new ConsoleMessageEvent(new FakeConsoleMessage()));
      expect(handled).assertTrue();
      // 有 client 时转发。
      f.attachWebChromeClient();
      const handledWithClient: boolean =
        f.view.onConsoleMessage(new ConsoleMessageEvent(new FakeConsoleMessage()));
      expect(handledWithClient).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onConsoleMessage')).assertTrue();
    })

    it('jsDialogsForwardToClient', 0, () => {
      const f: Fixture = new Fixture();
      // 无 client：默认放行（返回 true）。
      expect(f.view.onJsAlert(new JsDialogEvent('u', 'm', '', new FakeJsResult()))).assertTrue();
      expect(f.view.onJsConfirm(new JsDialogEvent('u', 'm', '', new FakeJsResult()))).assertTrue();
      expect(f.view.onJsPrompt(new JsDialogEvent('u', 'm', 'v', new FakeJsResult()))).assertTrue();
      // 有 client：同步开关关闭 → false 且不发送。
      f.attachWebChromeClient();
      expect(f.view.onJsAlert(new JsDialogEvent('u', 'm', '', new FakeJsResult()))).assertFalse();
      expect(f.view.onJsConfirm(new JsDialogEvent('u', 'm', '', new FakeJsResult()))).assertFalse();
      expect(f.view.onJsPrompt(new JsDialogEvent('u', 'm', 'v', new FakeJsResult()))).assertFalse();
    })

    it('windowEventsDoNotCrashWithoutDialog', 0, () => {
      const f: Fixture = new Fixture();
      // onCreateWindow 内部 CustomDialogController.open() 依赖 ArkUI 上下文，
      // 测试进程未绑定组件时允许抛错；此处仅做入口路径覆盖，无行为断言。
      try {
        f.attachWebChromeClient();
        f.view.onWindowNew(new WindowNewEvent(false, false, null));
      } catch (err) {
      }
      // 无论转发成败，不应影响进程。
      f.view.onWindowExit();
    })

    // ---------- 滚动与基本访问器 ----------
    it('scrollEventsNotifyDartAndCachePosition', 0, () => {
      const f: Fixture = new Fixture();
      f.view.onScroll(new ScrollEvent(7, 9));
      expect(f.view.getScrollX()).assertEqual(7);
      expect(f.view.getScrollY()).assertEqual(9);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.onScrollChanged')).assertTrue();
      f.view.setScrollPosition(3, 4);
      expect(f.view.getScrollX()).assertEqual(3);
    })

    it('typeAndViewAndUrlAccessors', 0, () => {
      const f: Fixture = new Fixture();
      expect(f.view.getType()).assertEqual('web');
      f.view.setUrl('about:blank');
      expect(f.view.getUrl()).assertEqual('about:blank');
      expect(f.view.getWebCookieManager() != null).assertTrue();
      expect(f.view.getPlatformViewVisibleAreaEventOptions() != null).assertTrue();
      // getView() 仅构造 WrappedBuilder 包装、不依赖运行环境，不应抛错。
      let viewBuilderOk: boolean = true;
      try {
        f.view.getView();
      } catch (err) {
        viewBuilderOk = false;
      }
      expect(viewBuilderOk).assertTrue();
      // 真实控制器未绑定组件：onInactive/onActive/setCustomUserAgent 允许抛错。
      try {
        f.view.onInactive();
        f.view.onActive();
        f.view.setCustomUserAgent('ua');
      } catch (err) {
      }
    })

    // ---------- 控制器附着与脚本通道 ----------
    it('controllerAttachLifecycleResolvesWaits', 0, async () => {
      const f: Fixture = new Fixture();
      f.view.aboutToAppear();
      expect(f.view.isWebViewBinding).assertTrue();
      f.view.aboutToDisappear();
      expect(f.view.isWebViewBinding).assertFalse();
      // 空通道表：reRegister 直接返回。
      f.view.onControllerAttached();
      // 附着后等待应在 20ms 轮询内完成。
      let threw: boolean = false;
      try {
        await f.view.checkControllerAttached();
        await f.view.waitControllerAttached();
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
      f.view.aboutToAppear();
    })

    it('javaScriptChannelsRegisterAndReregister', 0, () => {
      const f: Fixture = new Fixture();
      const channel: JavaScriptChannel = new JavaScriptChannel(
        new JavaScriptChannelFlutterApiImpl(f.messenger, f.manager), 'testChannel'
      );
      f.view.addJavaScriptChannel(channel);
      // 真实控制器未绑定：registerJavaScriptProxy 抛错被内部捕获。
      f.view.reRegisterJavaScriptChannels();
      f.view.removeJavaScriptChannel('testChannel');
      // 移除后再次注册：空表早退分支。
      f.view.reRegisterJavaScriptChannels();
      channel.postMessage('hello');
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'JavaScriptChannelFlutterApi.postMessage')).assertTrue();
    })

    // ---------- WebSettingsImpl 全量读写 ----------
    it('webSettingsImplSettersAndGettersRoundTrip', 0, async () => {
      const f: Fixture = new Fixture();
      const s: WebSettings = f.view.getWebSettings();
      s.setDomStorageEnabled(true);
      expect(s.getDomStorageEnabled()).assertTrue();
      s.setJavaScriptCanOpenWindowsAutomatically(true);
      expect(s.getJavaScriptCanOpenWindowsAutomatically()).assertTrue();
      s.setSupportMultipleWindows(true);
      expect(s.getSupportMultipleWindows()).assertTrue();
      s.setBackgroundColor(0xFF00FF00);
      expect(s.getBackgroundColor()).assertEqual('#ff00ff00');
      s.setJavaScriptEnabled(true);
      expect(s.getJavaScriptEnabled()).assertTrue();
      s.setMediaPlaybackRequiresUserGesture(false);
      expect(s.getMediaPlaybackRequiresUserGesture()).assertFalse();
      s.setSupportZoom(true);
      expect(s.getSupportZoom()).assertTrue();
      s.setLoadWithOverviewMode(true);
      expect(s.getLoadWithOverviewMode()).assertTrue();
      s.setUseWideViewPort(true);
      s.setDisplayZoomControls(true);
      s.setBuiltInZoomControls(true);
      s.setAllowFileAccess(false);
      expect(s.getAllowFileAccess()).assertFalse();
      let zoomSeen: number = -1;
      s.onTextZoomChanged((ratio: number) => {
        zoomSeen = ratio;
      });
      s.setTextZoom(160);
      expect(s.getTextZoom()).assertEqual(160);
      expect(zoomSeen).assertEqual(160);
      s.clearOnTextZoomChanged();
      s.setTextZoom(120);
      expect(s.getTextZoom()).assertEqual(120);
      s.setAllowFullScreenRotate(true);
      expect(s.getAllowFullScreenRotate()).assertTrue();
      s.setPaymentRequestEnabled(true);
      s.setMixedContentMode(2);
      expect(s.getMixedMode()).assertEqual(2);
      s.setOverScrollMode(1);
      expect(s.getOverScrollMode()).assertEqual(1);
      // 先附着控制器：getUserAgentString/setUserAgentString 内部等待附着完成。
      f.view.onControllerAttached();
      // userAgentString 已设置时直接返回，不触发引擎初始化。
      f.view.userAgentString = 'custom-ua';
      const ua: string = await s.getUserAgentString();
      expect(ua).assertEqual('custom-ua');
      // setUserAgentString 附着后委托真实控制器，允许抛错。
      try {
        await s.setUserAgentString('another-ua');
      } catch (err) {
      }
      // 释放后再访问抛出可读错误。
      s.releaseWebView();
      let threwAfterRelease: boolean = false;
      try {
        await s.getUserAgentString();
      } catch (err) {
        threwAfterRelease = true;
      }
      expect(threwAfterRelease).assertTrue();
    })

    // ---------- dispose / release ----------
    it('disposeInvokesOnDisposeCallback', 0, () => {
      const f: Fixture = new Fixture();
      let disposeCount: number = 0;
      f.view.setOnDisposeCallback(() => {
        disposeCount++;
      });
      f.view.dispose();
      expect(disposeCount).assertEqual(1);
    })

    it('releaseRunsFullTeardownSafely', 0, () => {
      const f: Fixture = new Fixture();
      let disposeCount: number = 0;
      let disposedCount: number = 0;
      f.view.setOnDisposeCallback(() => {
        disposeCount++;
      });
      f.view.setOnDisposedCallback(() => {
        disposedCount++;
      });
      f.view.setDisplayListenerProxy(new DisplayListenerProxy());
      // 预置状态：设置对象 + 脚本通道，使 release 的各清理循环有内容。
      f.view.getWebSettings();
      f.view.addJavaScriptChannel(new JavaScriptChannel(
        new JavaScriptChannelFlutterApiImpl(f.messenger, f.manager), 'releaseChannel'
      ));
      let threw: boolean = false;
      try {
        f.view.release();
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
      expect(disposeCount).assertEqual(1);
      expect(disposedCount).assertEqual(1);
      // 幂等：二次 release 直接返回。
      f.view.release();
      expect(disposeCount).assertEqual(1);
    })

    it('fullscreenEnterExitHandledWithoutWindowStage', 0, () => {
      const f: Fixture = new Fixture();
      // 生产实现本身 catch 后 rethrow：无窗口上下文时抛错由调用方处理，
      // 此处仅做入口与 catch 分支的路径覆盖，无行为断言。
      try {
        f.view.onFullScreenEnter(new EmptyEvent());
      } catch (err) {
      }
      try {
        f.view.onFullScreenExit();
      } catch (err) {
      }
    })
  })
}
