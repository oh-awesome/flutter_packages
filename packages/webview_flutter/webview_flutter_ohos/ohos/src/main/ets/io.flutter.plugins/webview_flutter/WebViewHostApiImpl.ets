// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on WebViewHostApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView'
import { DVModel, DVModelParameters } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicView'
import { Result, WebViewHostApi, WebViewPoint, HttpAuthHandler, SslErrorHandler } from './GeneratedOhosWebView'
import web_webview from '@ohos.web.webview'
import { WebBuilder, OhosWebView } from './OhosWebView'
import { createDVModelFromJson } from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicViewJson'
import { DVModelJson } from "./DynamicUtils"
import { InstanceManager } from './InstanceManager'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import common from '@ohos.app.ability.common'
import { WebChromeClient } from './WebChromeClientHostApiImpl'
import { WebViewClient } from './WebViewClientHostApiImpl'
import { WebSettings } from './WebSettingsHostApiImpl'
import { DynamicUtils } from "./DynamicUtils"
import { DownloadListener } from './DownloadListenerFlutterApiImpl'
import { DisplayListenerProxy } from './DisplayListenerProxy'
import { JavaScriptChannel } from './JavaScriptChannel'
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { WebViewFlutterApiImpl } from './WebViewFlutterApiImpl.ets'
import window from '@ohos.window'
import display from '@ohos.display'

const TAG: string = "WebViewHostApiImpl";

class EmptyDownloadListener implements DownloadListener {
  onDownloadStart(
    url: string,
    userAgent: string,
    contentDisposition: string,
    mimeType: string,
    contentLength: number
  ): void {
  }
}

/**
 * Parses ArkWeb OnSslErrorEventReceiveEvent.error (SslError enum).
 * Values: Invalid=0, HostMismatch=1, DateInvalid=2, Untrusted=3.
 */
function arkWebSslErrorNumericCode(raw: ESObject): number | undefined {
  if (raw === undefined || raw === null) {
    return undefined;
  }
  if (typeof raw === 'number') {
    return raw;
  }
  const n = Number(raw);
  return Number.isNaN(n) ? undefined : n;
}

/** Wording aligned with Android [AndroidSslAuthError] where categories match. */
function arkWebSslErrorCodeToDescription(code: number): string {
  switch (code) {
    case 0:
      return 'A generic SSL error occurred.';
    case 1:
      return 'Hostname mismatch.';
    case 2:
      return 'The certificate date is invalid.';
    case 3:
      return 'The certificate authority is not trusted.';
    default:
      return `SSL certificate validation failed (error code ${code}).`;
  }
}

export declare class PlatformViewVisibleAreaEventOptions {
  enable: boolean // Enable variable area monitoring
  ratios: Array<number> // Ratio thresholds for visible area changes, e.g., [0.0, 1.0] means 0% to 100% visible
  expectedUpdateInterval: number // Expected interval for visible area updates in milliseconds
  onInactiveThreshold: number // Texture continuous production pause operation visible area threshold
  onActiveThreshold: number // Texture continuous production activation operation visible area threshold
}

export class WebViewHostApiImpl extends WebViewHostApi {
  private instanceManager: InstanceManager;

  private webViewProxy: WebViewProxy;

  private binaryMessenger: BinaryMessenger;

  private context: common.Context;
  private api?: WebViewFlutterApiImpl;

  // Leak fix registry: every created WebViewPlatformView that may still be
  // running its controller-attach polling interval. Views unregister
  // themselves in release(); disposeAllActiveWebViews() is the engine-detach
  // backstop so no polling timer outlives the engine.
  private activeWebViews: Set<WebViewPlatformView> = new Set<WebViewPlatformView>();

  constructor(
    instanceManager: InstanceManager,
    webViewProxy: WebViewProxy,
    binaryMessenger: BinaryMessenger,
    context: common.Context
  ) {
    super();
    this.instanceManager = instanceManager;
    this.webViewProxy = webViewProxy;
    this.binaryMessenger = binaryMessenger;
    this.context = context;
  }

  setContext(context: common.Context): void {
    this.context = context;
  }

  // Defensive check: fail fast with a readable error instead of an undefined
  // property crash when the identifier is unknown. Valid identifiers follow
  // exactly the same path as before.
  private requireWebViewInstance(instanceId: number): WebViewPlatformView {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(instanceId);
    if (!webView) {
      throw new Error('WebViewHostApiImpl instance not found, id = ' + instanceId);
    }
    return webView;
  }

  create(instanceId: number): void {
    let displayProxy: DisplayListenerProxy = new DisplayListenerProxy();
    displayProxy.onPreWebViewInitialization();
    const webView: WebViewPlatformView = this.webViewProxy.createWebView(this.binaryMessenger, this.instanceManager);
    displayProxy.onPostWebViewInitialization();
    // Ownership: the proxy's display listeners live as long as this WebView
    // instance; WebViewPlatformView.release() unregisters them via cleanup().
    webView.setDisplayListenerProxy(displayProxy);
    this.instanceManager.addDartCreatedInstance(webView, instanceId);
    // Leak fix tracking: remember the view until it disposes so
    // disposeAllActiveWebViews() can stop its polling interval on engine
    // detach even if the platform view was never disposed individually.
    this.activeWebViews.add(webView);
    webView.setOnDisposedCallback(() => {
      this.activeWebViews.delete(webView);
    });
  }

  // Leak fix: fully release every WebView that is still registered when the
  // engine detaches. release() is idempotent, clears each view's polling
  // intervals, display listeners and dialog, and removes itself from the
  // registry; views already released individually are simply no longer
  // present here.
  disposeAllActiveWebViews(): void {
    const views: WebViewPlatformView[] = Array.from(this.activeWebViews);
    for (const webView of views) {
      webView.release();
    }
    this.activeWebViews.clear();
  }

  loadData(instanceId: number, data: string, mimeType: string, encoding: string): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    try {
      webView.getController().loadData(data, mimeType, encoding, ' ', ' ');
    } catch (error) {
      Log.e(TAG, 'loadData err = ' + error);
      throw new Error(String(error));
    }
  }

  async loadDataWithBaseUrl(
    instanceId: number, baseUrl: string, data: string, mimeType: string, encoding: string, historyUrl: string
  ): Promise<void> {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      // 当baseUrl为空时，其值默认为resource://rawfile/。这样设置是为了解决<a href="">标签锚点无效问题。
      webView.getController().loadData(data, mimeType, encoding, baseUrl == null || baseUrl.trim().length === 0 ? "resource://rawfile/" : baseUrl , historyUrl == null ? " " : historyUrl);
    } catch (err) {
      Log.e(TAG, "loadDataWithBaseUrl err = " + err);
      // Error-path fix only: rethrow the original error after logging so the
      // failure is observable instead of silently swallowed. The success
      // path and the error object/text are unchanged.
      throw new Error(String(err));
    }
  }

  async loadUrl(instanceId: number, url: string, headers: Map<string, string>): Promise<void> {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      if (url.startsWith("resources/rawfile/")) {
        try {
          // 设置允许可以跨域访问的路径列表
          webView.getController().setPathAllowingUniversalAccess([
            getContext().resourceDir
          ])
        } catch (err) {
          Log.e(TAG, "setPathAllowingUniversalAccess err = " + err);
        }
        webView.getController().loadUrl($rawfile(url.replace("resources/rawfile/","")), this.toWebHeaders(headers));
      }else {
        webView.getController().loadUrl(url, this.toWebHeaders(headers));
      }
      webView.setUrl(webView.getController().getUrl());
    } catch (err) {
      Log.e(TAG, "loadUrl err = " + err);
      // Error-path fix only: rethrow the original error after logging so the
      // failure is observable instead of silently swallowed. The success
      // path, the inner best-effort rawfile path setup and the error object
      // are unchanged.
      throw new Error(String(err));
    }
  }

  toWebHeaders(headers: Map<string, string>): Array<web_webview.WebHeader> {
    let result: Array<web_webview.WebHeader> = new Array;
    if (headers == null || headers.size == 0) {
      return result;
    }
    for (let arr of headers) {
      let key = arr[0];
      let value = arr[1];
      let header: web_webview.WebHeader = { headerKey: key, headerValue: value };
      result.push(header);
    }
    return result;
  }

  async postUrl(instanceId: number, url: string, data: Uint8Array):  Promise<void> {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    await webView.waitControllerAttached();
    try {
      webView.getController().postUrl(url,data.buffer);
    } catch (err) {
      Log.e(TAG, "postUrl err = " + err);
      // Error-path fix only: rethrow the original error after logging so the
      // failure is observable instead of silently swallowed. The success
      // path and the error object/text are unchanged.
      throw new Error(String(err));
    }
  }

  async getUrl(instanceId: number): Promise<string> {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    await webView.waitControllerAttached();
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path and return value are the same.
    try {
      return webView.getController().getUrl();
    } catch (err) {
      Log.e(TAG, 'getUrl err = ' + err);
      throw new Error(String(err));
    }
  }

  canGoBack(instanceId: number): boolean {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path and return value are the same.
    try {
      return webView.getController().accessBackward();
    } catch (err) {
      Log.e(TAG, 'canGoBack err = ' + err);
      throw new Error(String(err));
    }
  }

  canGoForward(instanceId: number): boolean {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path and return value are the same.
    try {
      return webView.getController().accessForward();
    } catch (err) {
      Log.e(TAG, 'canGoForward err = ' + err);
      throw new Error(String(err));
    }
  }

  goBack(instanceId: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path is the same.
    try {
      webView.getController().backward();
    } catch (err) {
      Log.e(TAG, 'goBack err = ' + err);
      throw new Error(String(err));
    }
  }

  goForward(instanceId: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path is the same.
    try {
      webView.getController().forward();
    } catch (err) {
      Log.e(TAG, 'goForward err = ' + err);
      throw new Error(String(err));
    }
  }

  reload(instanceId: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path is the same.
    try {
      webView.getController().refresh();
    } catch (err) {
      Log.e(TAG, 'reload err = ' + err);
      throw new Error(String(err));
    }
  }

  clearCache(instanceId: number, includeDiskFiles: boolean): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Wait for controller to be attached before clearing cache
    webView.waitControllerAttached().then(() => {
      // Failure-path diagnostics only: the Pigeon signature is void, so the
      // reply has already been sent; the log makes the ArkWeb failure
      // observable instead of silently swallowing it. The success path and
      // the call timing are unchanged.
      try {
        webView.getController().removeCache(includeDiskFiles);
      } catch (err) {
        Log.e(TAG, 'clearCache removeCache err = ' + err);
      }
    }).catch(() => {
      // If controller is not attached, silently ignore (no cache to clear yet)
    });
  }

  evaluateJavascript(instanceId: number, javascriptString: string, result: Result<string>): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    webView.getController().runJavaScript(javascriptString)
      .then(
        scriptResult => {
          result.success(scriptResult);
        }
      )
      .catch(
        (error: ESObject) => {
          result.error(error);
        }
      )
  }

  getTitle(instanceId: number): string {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The success path and return value are the same.
    try {
      return webView.getController().getTitle();
    } catch (err) {
      Log.e(TAG, 'getTitle err = ' + err);
      throw new Error(String(err));
    }
  }

  scrollTo(instanceId: number, x: number, y: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // scrollTo may need the page to be loaded first
    webView.waitControllerAttached().then(() => {
      // Failure-path diagnostics only: the Pigeon signature is void, so the
      // reply has already been sent; the log makes an ArkWeb failure
      // observable. The cached position is updated only after a successful
      // ArkWeb call so it never drifts from the real scroll state.
      try {
        webView.getController().scrollTo(x, y);
      } catch (err) {
        Log.e(TAG, 'scrollTo controller err = ' + err);
        return;
      }
      // Manually update scroll position since scrollTo doesn't trigger onScroll callback
      webView.setScrollPosition(x, y);
    }).catch((error: Error) => {
      // Observation only: consume the rejection with a log; scrolling is not
      // performed when waiting for the controller fails.
      Log.e(TAG, 'scrollTo err = ' + error);
    });
  }

  scrollBy(instanceId: number, x: number, y: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    webView.waitControllerAttached().then(() => {
      // Failure-path diagnostics only: see scrollTo above. The cached
      // position is updated only after a successful ArkWeb call.
      const currentX = webView.getScrollX();
      const currentY = webView.getScrollY();
      try {
        webView.getController().scrollBy(x, y);
      } catch (err) {
        Log.e(TAG, 'scrollBy controller err = ' + err);
        return;
      }
      // Manually update scroll position since scrollBy doesn't trigger onScroll callback
      webView.setScrollPosition(currentX + x, currentY + y);
    }).catch((error: Error) => {
      // Observation only: consume the rejection with a log; scrolling is not
      // performed when waiting for the controller fails.
      Log.e(TAG, 'scrollBy err = ' + error);
    });
  }

  getScrollX(instanceId: number): number {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    return webView.getScrollX();
  }

  getScrollY(instanceId: number): number {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    return webView.getScrollY()
  }

  getScrollPosition(instanceId: number): WebViewPoint {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    return WebViewPoint.Builder()
      .setX(webView.getScrollX())
      .setY(webView.getScrollY())
      .build();
  }

  setWebContentsDebuggingEnabled(enabled: boolean): void {
    this.webViewProxy.setWebContentsDebuggingEnabled(enabled);
  }

  setWebViewClient(instanceId: number, webViewClientInstanceId: number) {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: fail with a descriptive error instead of
    // storing an undefined client. A valid instance takes the exact same path.
    const webViewClient: WebViewClient = this.instanceManager.getInstance(webViewClientInstanceId);
    if (!webViewClient) {
      throw new Error('WebViewClient instance not found, id = ' + webViewClientInstanceId);
    }
    webView.setWebViewClient(webViewClient);
  }

  async addJavaScriptChannel(instanceId: number, javaScriptChannelInstanceId: number): Promise<void> {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only (mirrors removeJavaScriptChannel): fail
    // with a descriptive error instead of registering an undefined channel.
    // A valid instance takes the exact same path; the controller wait,
    // registration and refresh order are unchanged.
    const javaScriptChannel: JavaScriptChannel = this.instanceManager.getInstance(javaScriptChannelInstanceId);
    if (!javaScriptChannel) {
      throw new Error('JavaScriptChannel instance not found, id = ' + javaScriptChannelInstanceId);
    }
    await webView.waitControllerAttached();
    try {
      webView.addJavaScriptChannel(javaScriptChannel);
      webView.getController().registerJavaScriptProxy(
        {
          postMessage: (message: ESObject) => {
            javaScriptChannel.postMessage(String(message))
          },
        },
        javaScriptChannel.getJavaScriptChannelName(),
        ["postMessage"]
      )
      webView.getController().refresh()
    } catch (err) {
      Log.e(TAG, "addJavaScriptChannel err = " + err);
      // Error-path fix only: rethrow the original error after logging so the
      // failure is observable instead of silently swallowed. The success
      // path and the error object/text are unchanged.
      throw new Error(String(err));
    }
  }

  removeJavaScriptChannel(instanceId: number, javaScriptChannelInstanceId: number): void {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Defensive check (failure path only): a missing channel identifier
    // previously crashed when the channel name was read; now it fails with a
    // descriptive error instead.
    const javaScriptChannel: JavaScriptChannel = this.instanceManager.getInstance(javaScriptChannelInstanceId);
    if (!javaScriptChannel) {
      throw new Error('JavaScriptChannel instance not found, id = ' + javaScriptChannelInstanceId);
    }
    webView.removeJavaScriptChannel(javaScriptChannel.getJavaScriptChannelName());
    // Failure-path diagnostics only: log with the method name and rethrow the
    // original error unchanged. The InstanceManager removal below is skipped
    // on failure, exactly as before; the success path is the same.
    try {
      webView.getController().deleteJavaScriptRegister(javaScriptChannel.getJavaScriptChannelName());
    } catch (err) {
      Log.e(TAG, 'deleteJavaScriptRegister err = ' + err);
      throw new Error(String(err));
    }
    this.instanceManager.remove(javaScriptChannelInstanceId);
  }

  setDownloadListener(instanceId: number, listenerInstanceId: number) {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: fail with a descriptive error instead of
    // storing an undefined listener. A valid instance takes the same path.
    const downloadListener: DownloadListener = this.instanceManager.getInstance(listenerInstanceId);
    if (!downloadListener) {
      throw new Error('DownloadListener instance not found, id = ' + listenerInstanceId);
    }
    webView.setDownloadListener(downloadListener);
  }

  setWebChromeClient(instanceId: number, clientInstanceId: number) {
    const webView: WebViewPlatformView = this.requireWebViewInstance(instanceId);
    // Failure-path diagnostics only: fail with a descriptive error instead of
    // storing an undefined client. A valid instance takes the same path.
    const webChromeClient: WebChromeClient = this.instanceManager.getInstance(clientInstanceId);
    if (!webChromeClient) {
      throw new Error('WebChromeClient instance not found, id = ' + clientInstanceId);
    }
    webView.setWebChromeClient(webChromeClient);
  }

  getInstanceManager(): InstanceManager {
    return this.instanceManager;
  }

  setApi(api: WebViewFlutterApiImpl) {
    this.api = api;
  }
}

export class WebViewPlatformView extends PlatformView {

  // Ownership note: per SDK @ohos.web.webview.d.ts, WebCookieManager is a
  // process-wide ArkWeb service. The instance held here is a lightweight
  // handle with no per-instance native resources, so dispose() has nothing
  // to release for it; the service itself outlives this view by design.
  private webCookieManager: web_webview.WebCookieManager = new web_webview.WebCookieManager();

  private controller: web_webview.WebviewController = new web_webview.WebviewController();

  private tempUrl: string = "";

  private downloadListener: DownloadListener = {} as ESObject;

  private webChromeClient: WebChromeClient | null = null;

  private webViewClient: WebViewClient | null = null;

  private webSettings: WebSettings | null = null;

  private dialogController: CustomDialogController | null = null;

  private scrollX: number = 0;

  private scrollY: number = 0;

  private returnValueForShouldOverrideUrlLoading: boolean = false;

  private controllerAttached: boolean = false;

  private onDisposeCallback?: () => void;

  private rotation: number = 0;
  
  userAgentString: string = '';
 	  	 
 	isWebViewBinding: boolean = false;

  private webViewFlutterApi: WebViewFlutterApiImpl;

  private javaScriptChannels: Map<string, JavaScriptChannel> = new Map();

  private visibleAreaEventEnable: boolean = true;

  private visibleAreaEventRatios: Array<number> = [0, 0.1, 0.2, 0.5, 0.8, 1];

  private visibleAreaEventExpectedUpdateInterval: number = 1;

  private visibleAreaEventInactiveThreshold: number = 0.0;

  private visibleAreaEventActiveThreshold: number = 0.1;

  private displayListenerProxy: DisplayListenerProxy | null = null;

  private pendingControllerAttachIntervals: Set<number> = new Set<number>();

  // Pending rejections for controller-attach waits. release() completes them
  // with a concrete error so callers never await a promise that can no longer
  // settle. Typed as a set of Error-returning reject functions.
  private pendingAttachRejects: Set<(error: Error) => void> = new Set<(error: Error) => void>();

  private isDisposed: boolean = false;

  // Registry hook: invoked at the end of release() so WebViewHostApiImpl can
  // drop this view from its active-view set. Typed as an explicit
  // parameter-less, void-returning function.
  private onDisposedCallback: (() => void) | null = null;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super();
    this.webViewFlutterApi = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);
  }

  onDownloadStart = (event: ESObject) => {
    // Use-after-dispose guard: late events arriving after release() must not
    // reach the released listener. Release already reset the field to the
    // empty sentinel; this guard only covers the same object, it does not
    // create new closures or unbind ArkUI's declarative references.
    if (this.isDisposed) {
      return;
    }
    if (this.downloadListener && this.downloadListener.onDownloadStart) {
      this.downloadListener.onDownloadStart(
        event.url,
        event.userAgent,
        event.contentDisposition,
        event.mimetype,
        event.contentLength
      )
    }
  }

  onPageBegin = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webViewClient) {
      this.webViewClient.onPageStarted(this, event.url);
    }
  }

  onPageEnd = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webViewClient) {
      this.webViewClient.onPageFinished(this, event.url);
    }
  }

  onErrorReceive = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webViewClient) {
      this.webViewClient.onReceivedError(this, event.request, event.error);
    }
  }

  onHttpErrorReceive = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webViewClient) {
      this.webViewClient.onReceivedHttpError(this, event.request, event.response);
    }
  }

  onOverrideUrlLoading = (request: WebResourceRequest) => {
    // Use-after-dispose guard: deny navigation for a destroyed view instead
    // of consulting the released client. See onDownloadStart.
    if (this.isDisposed) {
      return true;
    }
    Log.i(TAG, "onOverrideUrlLoading request = " + JSON.stringify(request))
    if(request.getRequestUrl() == 'loaded:///'){
      return true;
    }

    if (this.webViewClient) {
      return this.webViewClient.shouldOverrideUrlLoading(this, request);
    }

    return false;
  }

  onRefreshAccessedHistory = (event: ESObject) => {
    if (this.webViewClient) {
      this.webViewClient.doUpdateVisitedHistory(this, event.url, event.isRefreshed);
    }
  }

  onHttpAuthRequest = (event: ESObject): boolean => {
    Log.i(TAG, "onHttpAuthRequest host=" + event.host + " realm=" + event.realm);
    if (this.webViewClient) {
      const wrappedHandler = new OhosHttpAuthHandler(event.handler);
      this.webViewClient.onReceivedHttpAuthRequest(this, wrappedHandler, event.host, event.realm);
      return true;
    }
    return false;
  }

  onSslErrorReceive = (event: ESObject): void => {
    if (!event || !event.handler) {
      Log.e(TAG, 'onSslErrorReceive: missing event or handler');
      return;
    }
    let urlStr = '';
    try {
      if (event.originalUrl !== undefined && event.originalUrl !== null) {
        urlStr = `${event.originalUrl}`;
      } else if (event.url !== undefined && event.url !== null) {
        urlStr = `${event.url}`;
      }
    } catch (err) {
      Log.e(TAG, 'onSslErrorReceive url extract err = ' + err);
    }

    // OnSslErrorEventReceiveEvent often omits URL (see ArkWeb docs); use controller URL for main frame.
    if (!urlStr || urlStr.trim().length === 0) {
      try {
        const fromCtrl = this.controller.getUrl();
        if (fromCtrl !== undefined && fromCtrl !== null && `${fromCtrl}`.trim().length > 0) {
          urlStr = `${fromCtrl}`;
        }
      } catch (_) {
      }
    }
    if (!urlStr || urlStr.trim().length === 0) {
      urlStr = this.getUrl() ?? '';
    }

    let description = 'SSL certificate validation failed.';
    try {
      const code = arkWebSslErrorNumericCode(event.error ?? event.sslError);
      if (code !== undefined) {
        description = arkWebSslErrorCodeToDescription(code);
      } else if (event.error !== undefined && event.error !== null) {
        description = `SSL error: ${event.error}`;
      }
    } catch (errDesc) {
      Log.e(TAG, 'onSslErrorReceive description extract err = ' + errDesc);
    }

    let certStr = '';
    try {
      if (event.certIssuer !== undefined && event.certIssuer !== null) {
        certStr = `${event.certIssuer}`;
      }
    } catch (errCert) {
      Log.e(TAG, 'onSslErrorReceive cert extract err = ' + errCert);
    }

    // Port-adaptation fix: the upstream branch misspells this field name
    // throughout; the local field is `webViewClient`. The two references in
    // this block were missed during the port, so the condition was always
    // falsy and every SSL error fell through to the default cancel(). Only
    // the identifier is corrected; the safe-default control flow (no client
    // -> cancel, forwarding failure -> cancel) is unchanged.
    if (this.webViewClient) {
      try {
        const wrappedHandler = new OhosSslErrorHandler(event.handler as ESObject);
        this.webViewClient.onReceivedSslError(this, wrappedHandler, urlStr, certStr, description);
      } catch (errForward) {
        Log.e(TAG, 'onSslErrorReceive forward err = ' + errForward);
        new OhosSslErrorHandler(event.handler as ESObject).cancel();
      }
    } else {
      new OhosSslErrorHandler(event.handler as ESObject).cancel();
    }
  }

  onProgressChange = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webChromeClient) {
      this.webChromeClient.onProgressChanged(this, event.newProgress)
    }
  }

  onGeolocationShow = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webChromeClient) {
      this.webChromeClient.onGeolocationPermissionsShowPrompt(event.origin, event.geolocation)
    }
  }

  onGeolocationHide = () => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webChromeClient) {
      this.webChromeClient.onGeolocationPermissionsHidePrompt();
    }
  }

  onShowFileSelector = (event: ESObject) => {
    // Use-after-dispose guard: decline selection for a destroyed view.
    if (this.isDisposed) {
      return false;
    }
    if (this.webChromeClient) {
      return this.webChromeClient.onShowFileChooser(this, event.result, event.fileSelector)
    }
    return false;
  }

  onPermissionRequest = (event: ESObject) => {
    // Use-after-dispose guard: see onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    if (this.webChromeClient) {
      this.webChromeClient.onPermissionRequest(event.request);
    }
  }

  onConsoleMessage = (event: ESObject) => {
    let message:ConsoleMessage = event.message;
    if (this.webChromeClient) {
        this.webChromeClient.onConsoleMessage(event.message);
    } else {
      Log.d(TAG, "logLevel: " + message.getMessageLevel() + " "+ message.getMessage());
    }
    return true;
  }

  onWindowNew = (event: ESObject) => {
    if (this.webChromeClient) {
      this.webChromeClient.onCreateWindow(this, event.isAlert, event.isUserTrigger, event.handler)
    }
  }

  onWindowExit = () => {
    if (this.dialogController) {
      this.dialogController.close();
      // Resource-release fix: drop the reference as soon as the dialog closes
      // itself so a disposed dialog is never closed twice or retained.
      this.dialogController = null;
    }
  }

  onScroll = (event: ESObject) => {
    // Use-after-dispose guard: stop sending scroll messages to the Dart side
    // once the view is disposed. See onDownloadStart.
    if (this.isDisposed) {
      return;
    }
    this.webViewFlutterApi.onScrollChanged(this, event.xOffset, event.yOffset, this.scrollX, this.scrollY, {reply: () => {}})
    this.scrollX = event.xOffset;
    this.scrollY = event.yOffset;
  }

  aboutToAppear() {
    this.isWebViewBinding = true;
  }

  onControllerAttached = () => {
    Log.d(TAG, "onControllerAttached");
    if (this.userAgentString) {
      this.setCustomUserAgent(this.userAgentString);
      this.controller.refresh();
    }
    this.controllerAttached = true;
    this.reRegisterJavaScriptChannels();
  }

  aboutToDisappear() {
    this.isWebViewBinding = false;
  }

  setOnDisposeCallback(callback: () => void) {
    this.onDisposeCallback = callback;
  }

  setOnDisposedCallback(callback: () => void): void {
    this.onDisposedCallback = callback;
  }

  setDisplayListenerProxy(proxy: DisplayListenerProxy): void {
    this.displayListenerProxy = proxy;
  }

  onJsAlert = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsAlert(this, event.url, event.message, event.result);
    }
    return true;
  }

  onJsConfirm = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsConfirm(this, event.url, event.message, event.result);
    }
    return true;
  }

  onJsPrompt = (event: ESObject): boolean => {
    if (this.webChromeClient && event) {
      return this.webChromeClient.onJsPrompt(this, event.url, event.message, event.value, event.result);
    }
    return true;
  }

  onFullScreenEnter = (event: ESObject) => {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let windowClass = context.windowStage.getMainWindowSync();
      windowClass.setWindowSystemBarEnable([]);
      this.rotation = windowClass.getPreferredOrientation();
      let isAllowFullScreenRotate = this.getWebSettings()?.getAllowFullScreenRotate();
      if (isAllowFullScreenRotate) {
        windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE);
      }
    } catch (error) {
      Log.e(TAG, 'onFullScreenEnter err = ' + error);
      throw new Error(String(error));
    }
  }

  onFullScreenExit = () => {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let windowClass = context.windowStage.getMainWindowSync();
      windowClass.setWindowSystemBarEnable(['status', 'navigation']);
      windowClass.setPreferredOrientation(this.rotation);
      this.reRegisterJavaScriptChannels();
    } catch (error) {
      // Observation only: log and rethrow the same error; the success path
      // order is unchanged.
      Log.e(TAG, 'onFullScreenExit err = ' + error);
      throw new Error(String(error));
    }
  }

  getType(): string {
    return 'web';
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(WebBuilder);
  }

  dispose(): void {
    // Platform-view disposal is not necessarily end-of-life: removing the
    // widget from the tree disposes the platform view while the Dart
    // controller (and the native instance it references) stay alive, and a
    // new widget can re-attach the same instance (the OhosWebViewController
    // reuse flow). Keep the historical minimal behavior here so a re-attached
    // view keeps working - forwarding callbacks, clients, JavaScript
    // channels and settings are all left untouched. The full resource
    // teardown lives in release(), which runs only at true end-of-life
    // (engine detach or Dart-side instance release).
    // dispose() guard: stopAllMedia() can throw once the ArkWeb component is
    // already destroyed. Catching keeps disposal a no-op instead of crashing
    // the teardown path; live media behavior is unchanged.
    try {
      this.controller.stopAllMedia();
    } catch (error) {
      Log.e(TAG, 'dispose stopAllMedia err = ' + error);
    }
    this.onDisposeCallback && this.onDisposeCallback();
    this.onDisposeCallback = undefined;
  }

  // Full end-of-life teardown. Runs from disposeAllActiveWebViews() at
  // engine detach and from OhosObjectHostApiImpl when the Dart side drops
  // the weak reference to this instance (the controller and every widget
  // referencing it are gone), so it must never run for a view that a new
  // widget could still re-attach. Idempotent; live WebView behavior is
  // unchanged.
  release(): void {
    if (this.isDisposed) {
      return;
    }
    this.isDisposed = true;
    // Resource cleanup: release everything created for this platform view.
    for (let intervalId of this.pendingControllerAttachIntervals) {
      clearInterval(intervalId);
    }
    this.pendingControllerAttachIntervals.clear();
    // Error-propagation fix: release and engine detach complete pending
    // controller-attach waits with a concrete error instead of leaving them
    // pending forever. No timeout is imposed while the WebView is alive.
    for (let rejectWait of this.pendingAttachRejects) {
      rejectWait(new Error('WebView was disposed before its controller attached.'));
    }
    this.pendingAttachRejects.clear();
    // Disposal-stage cleanup only: unregister every ArkWeb JavaScript proxy
    // registered through registerJavaScriptProxy before dropping the map, so
    // the engine-side anonymous closures are not merely forgotten but
    // explicitly removed. A single failed deregistration is logged and does
    // not block the cleanup of the remaining channels. Live channel behavior
    // while the WebView is alive is unchanged.
    for (let channelName of this.javaScriptChannels.keys()) {
      const channelNameStr: string = channelName;
      try {
        this.controller.deleteJavaScriptRegister(channelNameStr);
      } catch (err) {
        Log.e(TAG, 'dispose deleteJavaScriptRegister err = ' + err + ', channel = ' + channelNameStr);
      }
    }
    this.javaScriptChannels.clear();
    if (this.displayListenerProxy) {
      this.displayListenerProxy.cleanup();
      this.displayListenerProxy = null;
    }
    if (this.dialogController) {
      try {
        this.dialogController.close();
      } catch (error) {
        Log.e(TAG, 'dispose close dialog err = ' + error);
      }
      this.dialogController = null;
    }
    // Leak fix (cycle break): unbind the cached WebSettings so the
    // WebViewPlatformView -> WebSettingsImpl -> WebViewPlatformView cycle no
    // longer keeps both objects alive after disposal. Live getter/setter
    // paths are unchanged; a released settings object throws a descriptive
    // disposed error instead of touching a dead view.
    if (this.webSettings !== null) {
      this.webSettings.releaseWebView();
      this.webSettings = null;
    }
    // release() guard: stopAllMedia() can throw once the ArkWeb component is
    // already destroyed. Catching keeps the teardown sequence running so the
    // callback and reference cleanup below still complete. This only makes
    // the teardown path more reliable; live media behavior is unchanged.
    try {
      this.controller.stopAllMedia();
    } catch (error) {
      Log.e(TAG, 'release stopAllMedia err = ' + error);
    }
    // Leak fix (callback chains): drop the pure-callback holders so a
    // disposed view no longer retains the Dart-side client/listener objects.
    // The nullable clients are reset to null; `downloadListener` keeps its
    // legacy non-nullable sentinel type (see field declaration), so it is
    // documented as a platform-legacy constraint instead of being recast.
    this.webViewClient = null;
    this.webChromeClient = null;
    // Leak fix (download callbacks): release the retained listener object by
    // reassigning the field's empty-object sentinel, cast to the concrete
    // DownloadListener interface type. The sentinel has no onDownloadStart
    // member, so the forwarding guard above treats it as 'no listener'; a
    // disposed view no longer forwards download events to the old listener.
    this.downloadListener = new EmptyDownloadListener();
    this.onDisposeCallback && this.onDisposeCallback();
    this.onDisposeCallback = undefined;
    // Registry hook: let WebViewHostApiImpl drop this view from its
    // active-view set now that disposal is complete.
    if (this.onDisposedCallback !== null) {
      this.onDisposedCallback();
      this.onDisposedCallback = null;
    }
  }

  getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions {
    return {
      enable: this.visibleAreaEventEnable,
      ratios: this.visibleAreaEventRatios,
      expectedUpdateInterval: this.visibleAreaEventExpectedUpdateInterval,
      onInactiveThreshold : this.visibleAreaEventInactiveThreshold,
      onActiveThreshold : this.visibleAreaEventActiveThreshold
    } as PlatformViewVisibleAreaEventOptions;
  }

  onInactive(): void {
    this.controller.onInactive();
  }

  onActive(): void {
    this.controller.onActive();
  }

  getController(): web_webview.WebviewController {
    return this.controller;
  }

  setCustomUserAgent(userAgentString: string) {
    this.userAgentString = userAgentString;
    this.controller.setCustomUserAgent(userAgentString);
  }

  setUrl(url: string): void {
    this.tempUrl = url;
  }

  getUrl(): string {
    return this.tempUrl;
  }

  getWebCookieManager(): web_webview.WebCookieManager {
    return this.webCookieManager
  }

  setDownloadListener(listener: DownloadListener) {
    this.downloadListener = listener;
  }

  setWebViewClient(webViewClient: WebViewClient) {
    this.webViewClient = webViewClient;
  }

  setWebChromeClient(webChromeClient: WebChromeClient) {
    this.webChromeClient = webChromeClient;
  }

  setDialogController(dialogController: CustomDialogController) {
    this.dialogController = dialogController;
  }

  getDialogController(): CustomDialogController | null {
    return this.dialogController;
  }

  getWebSettings(): WebSettings {
    if (this.webSettings == null) {
      this.webSettings = new WebSettingsImpl(this);
    }
    return this.webSettings!;
  }

  getScrollX(): number {
    return this.scrollX;
  }

  getScrollY(): number {
    return this.scrollY;
  }

  setScrollPosition(x: number, y: number): void {
    this.scrollX = x;
    this.scrollY = y;
    this.webViewFlutterApi.onScrollChanged(this, x, y, this.scrollX, this.scrollY, {reply: () => {}});
  }

  setReturnValueForShouldOverrideUrlLoading(value: boolean) {
    this.returnValueForShouldOverrideUrlLoading = value;
  }

  async waitControllerAttached() {
    if (!this.controllerAttached) {
      // Preserve the original contract: callers wait until attachment or
      // disposal. An arbitrary timeout would make slow device startup fail
      // even though the controller can still attach successfully.
      await this.checkControllerAttached()
    }
  }

  checkControllerAttached(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.pendingAttachRejects.add(reject);
        let intervalId = setInterval(() => {
          if (this.controllerAttached) {
            clearInterval(intervalId)
            this.pendingControllerAttachIntervals.delete(intervalId);
            this.pendingAttachRejects.delete(reject);
            resolve()
          }
        }, 20)
        // Resource tracking: remember the interval id so release() can stop
        // polling if the controller never attaches. Waiting behavior while
        // the WebView is alive is unchanged.
        this.pendingControllerAttachIntervals.add(intervalId);
      } catch (err) {
        this.pendingAttachRejects.delete(reject);
        // Error-propagation fix: reject with the original error so callers
        // can diagnose an interval-creation failure instead of receiving a
        // bare undefined rejection.
        reject(err instanceof Error ? err : new Error('checkControllerAttached failed: ' + err));
      }
    })
  }

  addJavaScriptChannel(channel: JavaScriptChannel) {
    this.javaScriptChannels.set(channel.getJavaScriptChannelName(), channel);
  }

  removeJavaScriptChannel(channelName: string) {
    this.javaScriptChannels.delete(channelName);
  }

  reRegisterJavaScriptChannels() {
    if (this.javaScriptChannels.size === 0) {
      return;
    }
    try {
      this.javaScriptChannels.forEach((channel: JavaScriptChannel, channelName: string) => {
        this.controller.registerJavaScriptProxy(
          {
            postMessage: (message: string) => {
              channel.postMessage(message)
            },
          },
          channelName,
          ["postMessage"]
        )
      })
      this.controller.refresh()
    } catch (err) {
      Log.e(TAG, "reRegisterJavaScriptChannels err = " + err);
    }
  }

}

export class WebViewProxy {
  createWebView(binaryMessenger:BinaryMessenger, instanceManager:InstanceManager): WebViewPlatformView {
    return new WebViewPlatformView(binaryMessenger, instanceManager);
  }

  setWebContentsDebuggingEnabled(enabled: boolean): void {
    web_webview.WebviewController.setWebDebuggingAccess(enabled);
  }
}

class WebSettingsImpl implements WebSettings {
  // Leak fix (cycle break): nullable per the remediation plan so dispose()
  // can break the WebViewPlatformView -> WebSettingsImpl -> WebViewPlatformView
  // cycle. Still a concrete type, never ESObject/Object/any.
  private webView: WebViewPlatformView | null;
  private defaultUserAgent: string = '';
  params: DVModelParameters = new DVModelParameters;
  domStorageAccess: boolean = false;
  allowWindowOpenMethod : boolean = false;
  multiWindowAccess : boolean = false;
  backgroundColor : string = "";
  javaScriptAccess : boolean = false;
  mediaPlayGestureAccess : boolean = false;
  zoomAccess : boolean = true;
  overviewModeAccess : boolean = false;
  wideViewModeAccess: boolean = false;
  fileAccess : boolean = true;
  textZoomRatio : number = 0;
  textZoomRatioCallback?: (ratio: number) => void;
  isAllowFullScreenRotate: boolean = false;
  paymentRequestEnabled: boolean = false;
  mixedMode: number = 0; // Default: MixedMode.All (allow all mixed content)
  overScrollMode: number = 0; // Default: OverScrollMode.NEVER

  constructor(webView: WebViewPlatformView) {
    this.webView = webView;
    //this.params = webView.getView().params;
  }

  setDomStorageEnabled(flag: boolean) {
    this.domStorageAccess = flag;
  }

  getDomStorageEnabled() : boolean{
    return this.domStorageAccess;
  }

  setJavaScriptCanOpenWindowsAutomatically(flag: boolean) {
    this.allowWindowOpenMethod = flag;
  }

  getJavaScriptCanOpenWindowsAutomatically() : boolean{
    return this.allowWindowOpenMethod;
  }

  setSupportMultipleWindows(support: boolean) {
    this.multiWindowAccess = support;
  }

  getSupportMultipleWindows()  : boolean{
    return this.multiWindowAccess;
  }

  setBackgroundColor(color: number) {
    // number 无法实现透明度，所以转成 string
    let colorStr = `#${color.toString(16).padStart(8, '0')}`;
    this.backgroundColor = colorStr;
  }

  getBackgroundColor() : string{
    return this.backgroundColor;
  }

  setJavaScriptEnabled(flag: boolean) {
    this.javaScriptAccess = flag;
  }

  getJavaScriptEnabled() : boolean {
    return this.javaScriptAccess;
  }

  // Leak fix (cycle break): returns the owning WebView while this settings
  // object is attached, or a descriptive disposed error after release().
  // Only the disposal path ever sees the null branch; live getters and
  // setters behave exactly as before.
  private attachedWebView(): WebViewPlatformView {
    if (this.webView === null) {
      throw new Error('WebSettings was released; its WebView has been disposed.');
    }
    return this.webView;
  }

  // Leak fix (cycle break): idempotent unbind called from the owning
  // WebViewPlatformView.release(); drops the back reference so the
  // view/settings pair becomes collectable. Live behavior is unchanged.
  releaseWebView(): void {
    this.clearOnTextZoomChanged();
    this.webView = null;
  }

  async setUserAgentString(userAgentString: string) {
    const webView: WebViewPlatformView = this.attachedWebView();
    await webView.waitControllerAttached();
    webView.setCustomUserAgent(userAgentString);
  }

  setMediaPlaybackRequiresUserGesture(require: boolean) {
    this.mediaPlayGestureAccess = require;
  }

  getMediaPlaybackRequiresUserGesture() : boolean{
    return this.mediaPlayGestureAccess;
  }

  setSupportZoom(support: boolean) {
    this.zoomAccess = support;
  }

  getSupportZoom() : boolean{
    return this.zoomAccess;
  }

  setLoadWithOverviewMode(overview: boolean) {
    this.overviewModeAccess = overview;
  }

  getLoadWithOverviewMode() : boolean {
    return this.overviewModeAccess;
  }

  setUseWideViewPort(use: boolean) {
    this.wideViewModeAccess = use;
  }

  getUseWideViewPort() : boolean {
    return this.wideViewModeAccess;
  }

  setDisplayZoomControls(enabled: boolean) {
    // ArkWeb does not expose Android-style on-screen zoom controls.
  }

  setBuiltInZoomControls(enabled: boolean) {
    // ArkWeb manages zoom gestures without a built-in zoom-control API.
  }

  setAllowFileAccess(enabled: boolean) {
    this.fileAccess = enabled;
  }

  getAllowFileAccess() : boolean {
    return this.fileAccess;
  }

  setTextZoom(textZoom: number) {
    this.textZoomRatio = textZoom;
    this.textZoomRatioCallback && this.textZoomRatioCallback(textZoom);
  }

  async getUserAgentString(): Promise<string> {
    const webView: WebViewPlatformView = this.attachedWebView();
    try {
      await webView.waitControllerAttached();
    } catch(err) {
      Log.e(TAG, 'getUserAgentString err = ' + err)
    }
    if (webView.userAgentString) {
      return webView.userAgentString;
    }

    if (webView.isWebViewBinding) {
      return webView.getController().getCustomUserAgent();
    }

    if (this.defaultUserAgent) {
      //  整个app只需要一次initializeWebEngine。
      return this.defaultUserAgent;
    }

    web_webview.WebviewController.initializeWebEngine();
    this.defaultUserAgent = web_webview.WebviewController.getDefaultUserAgent();

    return this.defaultUserAgent;
  }

  getTextZoom() : number{
    return this.textZoomRatio;
  }

  onTextZoomChanged(callback: (ratio: number) => void): void {
    this.textZoomRatioCallback = callback;
  }

  // Resource cleanup: drop the callback registered by onTextZoomChanged() so
  // the settings object no longer captures the disappeared component. Only
  // called after the component is gone; live text zoom behavior is unchanged.
  clearOnTextZoomChanged(): void {
    this.textZoomRatioCallback = undefined;
  }

  setAllowFullScreenRotate(enabled: boolean) {
    this.isAllowFullScreenRotate = enabled;
  }

  getAllowFullScreenRotate() : boolean {
    return this.isAllowFullScreenRotate;
  }

  setPaymentRequestEnabled(enabled: boolean) {
    // ArkWeb has no public Payment Request backend. Retain the requested value
    // for API compatibility and feature reporting only.
    this.paymentRequestEnabled = enabled;
  }

  setMixedContentMode(mode: number) {
    this.mixedMode = mode;
  }

  getMixedMode(): number {
    return this.mixedMode;
  }

  setOverScrollMode(mode: number) {
    this.overScrollMode = mode;
  }

  getOverScrollMode(): number {
    return this.overScrollMode;
  }
}

class OhosHttpAuthHandler implements HttpAuthHandler {
  private nativeHandler: ESObject;
  private savedUsername: string = '';
  private savedPassword: string = '';

  constructor(handler: ESObject) {
    this.nativeHandler = handler;
  }

  cancel(): void {
    this.nativeHandler.cancel();
  }

  proceed(username: string, password: string): void {
    this.savedUsername = username;
    this.savedPassword = password;
    this.nativeHandler.confirm(username, password);
  }

  useHttpAuthUsernamePassword(): boolean {
    // Low-version/exception hardening only: when the API is absent the
    // optional call still short-circuits to false as before; when the call
    // itself throws, log it and keep the same conservative false result
    // instead of crashing the caller.
    try {
      return this.nativeHandler.isHttpAuthInfoSaved?.() ?? false;
    } catch (err) {
      Log.e(TAG, 'useHttpAuthUsernamePassword err = ' + err);
      return false;
    }
  }
}

class OhosSslErrorHandler implements SslErrorHandler {
  private nativeHandler: ESObject;

  constructor(handler: ESObject) {
    this.nativeHandler = handler;
  }

  cancel(): void {
    try {
      if (typeof this.nativeHandler.handleCancel === 'function') {
        try {
          this.nativeHandler.handleCancel(true);
        } catch (_e) {
          this.nativeHandler.handleCancel();
        }
      }
    } catch (err) {
      Log.e(TAG, 'OhosSslErrorHandler.cancel err = ' + err);
    }
  }

  proceed(): void {
    try {
      this.nativeHandler.handleConfirm?.();
    } catch (err) {
      Log.e(TAG, 'OhosSslErrorHandler.proceed err = ' + err);
    }
  }
}
