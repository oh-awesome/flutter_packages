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
 
// 测试辅助：视图/资源管理相关的 Fake 实现。

import resourceManager from '@ohos.resourceManager';
import web_webview from '@ohos.web.webview';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebViewPlatformView,
  WebViewProxy
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import { WebSettings } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebSettingsHostApiImpl';
import { FlutterAssetManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/FlutterAssetManager';

@Builder
function emptyBuilder(params: Params) {
}

/** 最小可用的 PlatformView Fake，用于 FlutterWebViewFactory 的取回逻辑测试。 */
export class FakePlatformView extends PlatformView {
  getView(): WrappedBuilder<[Params]> {
    return wrapBuilder(emptyBuilder);
  }

  dispose(): void {
  }
}

/**
 * WebviewController Fake（ArkWeb 环境声明类不可实现，普通类记录调用，
 * 使用处以 as ESObject as WebviewController 双重断言传入）。
 * 通过 throwOn 字段可让指定方法抛错，覆盖 HostApi 的错误分支。
 */
export class FakeWebviewController {
  public throwOn: string = '';
  public loadUrlCount: number = 0;
  public lastLoadUrl: string = '';
  public lastLoadUrlHeaderCount: number = -1;
  public loadDataCount: number = 0;
  public lastLoadData: Array<string> = [];
  public postUrlCount: number = 0;
  public lastPostUrl: string = '';
  public urlToReturn: string = 'about:blank';
  public titleToReturn: string = 'Example Title';
  public accessBackwardToReturn: boolean = true;
  public accessForwardToReturn: boolean = false;
  public removeCacheCount: number = 0;
  public lastRemoveCacheFlag: boolean = false;
  public runJavaScriptResult: string = 'js-result';
  public runJavaScriptShouldFail: boolean = false;
  public scrollToCount: number = 0;
  public scrollByCount: number = 0;
  public lastScrollTo: Array<number> = [];
  public registeredProxyNames: Array<string> = [];
  public deletedProxyNames: Array<string> = [];
  public backwardCount: number = 0;
  public forwardCount: number = 0;
  public refreshCount: number = 0;

  private maybeThrow(name: string): void {
    if (this.throwOn === name) {
      throw new Error('fake controller failure on ' + name);
    }
  }

  loadData(data: string, mimeType: string, encoding: string, baseUrl: string, historyUrl: string): void {
    this.maybeThrow('loadData');
    this.loadDataCount++;
    this.lastLoadData = [data, mimeType, encoding, baseUrl, historyUrl];
  }

  loadUrl(url: string, headers?: Array<web_webview.WebHeader>): void {
    this.maybeThrow('loadUrl');
    this.loadUrlCount++;
    this.lastLoadUrl = url;
    this.lastLoadUrlHeaderCount = headers == null ? -1 : headers.length;
  }

  getUrl(): string {
    this.maybeThrow('getUrl');
    return this.urlToReturn;
  }

  getTitle(): string {
    this.maybeThrow('getTitle');
    return this.titleToReturn;
  }

  postUrl(url: string, buffer: ArrayBuffer): void {
    this.maybeThrow('postUrl');
    this.postUrlCount++;
    this.lastPostUrl = url;
  }

  accessBackward(): boolean {
    this.maybeThrow('accessBackward');
    return this.accessBackwardToReturn;
  }

  accessForward(): boolean {
    this.maybeThrow('accessForward');
    return this.accessForwardToReturn;
  }

  backward(): void {
    this.maybeThrow('backward');
    this.backwardCount++;
  }

  forward(): void {
    this.maybeThrow('forward');
    this.forwardCount++;
  }

  refresh(): void {
    this.maybeThrow('refresh');
    this.refreshCount++;
  }

  removeCache(includeDiskFiles: boolean): void {
    this.maybeThrow('removeCache');
    this.removeCacheCount++;
    this.lastRemoveCacheFlag = includeDiskFiles;
  }

  runJavaScript(script: string): Promise<string> {
    this.maybeThrow('runJavaScript');
    if (this.runJavaScriptShouldFail) {
      return Promise.reject(new Error('fake js failure'));
    }
    return Promise.resolve(this.runJavaScriptResult);
  }

  scrollTo(x: number, y: number): void {
    this.maybeThrow('scrollTo');
    this.scrollToCount++;
    this.lastScrollTo = [x, y];
  }

  scrollBy(x: number, y: number): void {
    this.maybeThrow('scrollBy');
    this.scrollByCount++;
    this.lastScrollTo = [x, y];
  }

  registerJavaScriptProxy(proxy: ESObject, name: string, methodList: Array<string>): void {
    this.maybeThrow('registerJavaScriptProxy');
    this.registeredProxyNames.push(name);
  }

  deleteJavaScriptRegister(name: string): void {
    this.maybeThrow('deleteJavaScriptRegister');
    this.deletedProxyNames.push(name);
  }

  setPathAllowingUniversalAccess(pathList: Array<string>): void {
    this.maybeThrow('setPathAllowingUniversalAccess');
  }
}

/** WebSettings Fake：实现插件自有接口，记录全部设置值。 */
export class FakeWebSettings implements WebSettings {
  public domStorageEnabled: boolean = false;
  public javaScriptCanOpenWindowsAutomatically: boolean = false;
  public supportMultipleWindows: boolean = false;
  public backgroundColor: number = -1;
  public backgroundColorToReturn: string = '#FFFFFFFF';
  public javaScriptEnabled: boolean = false;
  public userAgentString: string = '';
  public userAgentToReturn: string = 'mock-ua';
  public mediaPlaybackRequiresUserGesture: boolean = true;
  public supportZoom: boolean = false;
  public loadWithOverviewMode: boolean = false;
  public useWideViewPort: boolean = false;
  public displayZoomControls: boolean = false;
  public builtInZoomControls: boolean = false;
  public allowFileAccess: boolean = false;
  public textZoom: number = 100;
  public textZoomCallbacks: Array<(ratio: number) => void> = [];
  public allowFullScreenRotate: boolean = false;
  public paymentRequestEnabled: boolean = false;
  public mixedContentMode: number = 0;
  public overScrollMode: number = 0;
  public releaseCount: number = 0;

  setDomStorageEnabled(flag: boolean): void {
    this.domStorageEnabled = flag;
  }

  getDomStorageEnabled(): boolean {
    return this.domStorageEnabled;
  }

  setJavaScriptCanOpenWindowsAutomatically(flag: boolean): void {
    this.javaScriptCanOpenWindowsAutomatically = flag;
  }

  getJavaScriptCanOpenWindowsAutomatically(): boolean {
    return this.javaScriptCanOpenWindowsAutomatically;
  }

  setSupportMultipleWindows(support: boolean): void {
    this.supportMultipleWindows = support;
  }

  getSupportMultipleWindows(): boolean {
    return this.supportMultipleWindows;
  }

  setBackgroundColor(color: number): void {
    this.backgroundColor = color;
  }

  getBackgroundColor(): string {
    return this.backgroundColorToReturn;
  }

  setJavaScriptEnabled(flag: boolean): void {
    this.javaScriptEnabled = flag;
  }

  getJavaScriptEnabled(): boolean {
    return this.javaScriptEnabled;
  }

  setUserAgentString(userAgentString: string): void {
    this.userAgentString = userAgentString;
  }

  setMediaPlaybackRequiresUserGesture(require: boolean): void {
    this.mediaPlaybackRequiresUserGesture = require;
  }

  getMediaPlaybackRequiresUserGesture(): boolean {
    return this.mediaPlaybackRequiresUserGesture;
  }

  setSupportZoom(support: boolean): void {
    this.supportZoom = support;
  }

  getSupportZoom(): boolean {
    return this.supportZoom;
  }

  setLoadWithOverviewMode(overview: boolean): void {
    this.loadWithOverviewMode = overview;
  }

  getLoadWithOverviewMode(): boolean {
    return this.loadWithOverviewMode;
  }

  setUseWideViewPort(use: boolean): void {
    this.useWideViewPort = use;
  }

  getUseWideViewPort(): boolean {
    return this.useWideViewPort;
  }

  setDisplayZoomControls(enabled: boolean): void {
    this.displayZoomControls = enabled;
  }

  setBuiltInZoomControls(enabled: boolean): void {
    this.builtInZoomControls = enabled;
  }

  setAllowFileAccess(enabled: boolean): void {
    this.allowFileAccess = enabled;
  }

  getAllowFileAccess(): boolean {
    return this.allowFileAccess;
  }

  setTextZoom(textZoom: number): void {
    this.textZoom = textZoom;
  }

  getTextZoom(): number {
    return this.textZoom;
  }

  getUserAgentString(): Promise<string> {
    return Promise.resolve(this.userAgentToReturn);
  }

  onTextZoomChanged(callback: (ratio: number) => void): void {
    this.textZoomCallbacks.push(callback);
  }

  clearOnTextZoomChanged(): void {
    this.textZoomCallbacks = [];
  }

  releaseWebView(): void {
    this.releaseCount++;
  }

  setAllowFullScreenRotate(enabled: boolean): void {
    this.allowFullScreenRotate = enabled;
  }

  getAllowFullScreenRotate(): boolean {
    return this.allowFullScreenRotate;
  }

  setPaymentRequestEnabled(enabled: boolean): void {
    this.paymentRequestEnabled = enabled;
  }

  setMixedContentMode(mode: number): void {
    this.mixedContentMode = mode;
  }

  getMixedMode(): number {
    return this.mixedContentMode;
  }

  setOverScrollMode(mode: number): void {
    this.overScrollMode = mode;
  }

  getOverScrollMode(): number {
    return this.overScrollMode;
  }
}

/**
 * WebViewPlatformView Fake：覆写 getController/getWebSettings 返回注入的
 * Fake 对象，覆写 waitControllerAttached 立即完成（避免真实轮询定时器），
 * 覆写 release() 以免触真实的 WebView 生命周期，并记录 release 次数。
 * 注意：super 构造会创建 ArkWeb 控制器句柄，因此本 Fake 仅用于
 * InstrumentTest（ohosTest，设备/模拟器）环境。
 */
export class FakeWebViewPlatformView extends WebViewPlatformView {
  public releaseCount: number = 0;
  public fakeController: FakeWebviewController = new FakeWebviewController();
  public fakeSettings: FakeWebSettings = new FakeWebSettings();

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super(binaryMessenger, instanceManager);
  }

  release(): void {
    this.releaseCount++;
  }

  getController(): web_webview.WebviewController {
    return this.fakeController as ESObject as web_webview.WebviewController;
  }

  getWebSettings(): WebSettings {
    return this.fakeSettings;
  }

  async waitControllerAttached(): Promise<void> {
    return Promise.resolve();
  }
}

/** WebViewProxy Fake：createWebView 返回注入的视图，调试开关调用被记录。 */
export class FakeWebViewProxy extends WebViewProxy {
  public viewToReturn: FakeWebViewPlatformView;
  public debuggingFlags: Array<boolean> = [];

  constructor(view: FakeWebViewPlatformView) {
    super();
    this.viewToReturn = view;
  }

  createWebView(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager): WebViewPlatformView {
    return this.viewToReturn;
  }

  setWebContentsDebuggingEnabled(enabled: boolean): void {
    this.debuggingFlags.push(enabled);
  }
}

/** FlutterAssetManager Fake：list() 结果与异常可注入。 */
export class FakeFlutterAssetManager extends FlutterAssetManager {
  public listResult: Array<string> = ['assets/a.txt', 'assets/b.txt'];
  public shouldThrow: boolean = false;

  constructor() {
    super(undefined as ESObject as resourceManager.ResourceManager);
  }

  getAssetFilePathByName(name: string): string {
    return 'flutter_assets/' + name;
  }

  async list(path: string): Promise<Array<string>> {
    if (this.shouldThrow) {
      throw new Error('mock list failure');
    }
    return this.listResult;
  }
}
