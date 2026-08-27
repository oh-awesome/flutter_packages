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
 
// 测试辅助：各回调/事件接口的 Fake 实现，用于记录 HostApi 触发的调用。
// PermissionRequest / JsGeolocation / FileSelectorParam / WebResourceRequest /
// WebResourceError / Header 为 @ohos.web.webview 的全局（ambient）接口，
// 与被测源码中的引用方式一致，无需 import。

import {
  HttpAuthHandler,
  SslErrorHandler,
  CustomViewCallback
} from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { DownloadListener } from '../../../main/ets/io.flutter.plugins/webview_flutter/DownloadListenerFlutterApiImpl';
import { DVModelJson } from '../../../main/ets/io.flutter.plugins/webview_flutter/DynamicUtils';
import { WebChromeClient } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';

/**
 * 类型转换辅助（仅测试用）：把可空/原始值原样转换为目标类型，
 * 使 test/ 目录下的用例无需书写 ESObject 断言。
 */
export function coerce<T>(value: Object | undefined | null): T {
  return value as ESObject as T;
}

/**
 * 构造 DVModelJson：children 元素类型含 ESObject，仅在 testmock 内声明，
 * test/ 目录传入具体类型的 attributes/events/build 使用。
 */
export function newDvModel(
  compType: string,
  attributes: Object,
  events: Object,
  build?: Object
): DVModelJson {
  return new DVModelJson(compType, [], attributes, events, build);
}

/**
 * 经动态类型调用 onConsoleMessage：WebChromeClient 接口将其声明为 void，
 * 实现（WebChromeClientImpl）实际返回 boolean，此处取回真实返回值供断言。
 */
export function callOnConsoleMessage(client: WebChromeClient, message: Object): boolean {
  return (client as ESObject).onConsoleMessage(message as ESObject) as boolean;
}

/**
 * 权限请求回调 Fake：记录 grant / deny 调用。
 * 注意：PermissionRequest / JsGeolocation / FileSelectorParam /
 * WebResourceError / WebResourceRequest 在 SDK web.d.ts 中是 declare class
 * （非 interface），ArkTS 不允许 implements 也不宜 extends（原生构造），
 * 因此这里是普通类，使用处通过 `as ESObject as Xxx` 双重断言传入。
 */
export class FakePermissionRequest {
  public grantedResources: Array<string> = [];
  public grantCount: number = 0;
  public denyCount: number = 0;

  grant(resources: Array<string>): void {
    this.grantCount++;
    this.grantedResources = resources;
  }

  deny(): void {
    this.denyCount++;
  }

  getOrigin(): string {
    return 'about:blank';
  }

  getAccessibleResource(): Array<string> {
    return ['camera', 'microphone'];
  }
}

/** 地理位置权限回调 Fake。 */
export class FakeJsGeolocation {
  public lastOrigin: string = '';
  public lastAllow: boolean = false;
  public lastRetain: boolean = false;
  public invokeCount: number = 0;

  invoke(origin: string, allow: boolean, retain: boolean): void {
    this.invokeCount++;
    this.lastOrigin = origin;
    this.lastAllow = allow;
    this.lastRetain = retain;
  }
}

/** 文件选择参数 Fake：mode 可注入非法值以覆盖错误分支。 */
export class FakeFileSelectorParam {
  public capture: boolean = false;
  public acceptType: Array<string> = ['image/*'];
  public mode: FileSelectorMode = FileSelectorMode.FileOpenMode;
  public title: string = 'Choose file';

  isCapture(): boolean {
    return this.capture;
  }

  getAcceptType(): Array<string> {
    return this.acceptType;
  }

  getMode(): FileSelectorMode {
    return this.mode;
  }

  getTitle(): string {
    return this.title;
  }

  getMimeTypes(): Array<string> {
    return ['image/png'];
  }

  getSuggestedName(): string {
    return 'suggested.png';
  }

  getDefaultPath(): string {
    return '/data/storage';
  }

  getDescriptions(): Array<string> {
    return ['PNG image'];
  }

  isAcceptAllOptionExcluded(): boolean {
    return false;
  }

  getAcceptableFileTypes(): Array<Array<AcceptableFileType>> {
    return [];
  }
}

/** HTTP 认证处理器 Fake。 */
export class FakeHttpAuthHandler implements HttpAuthHandler {
  public cancelCount: number = 0;
  public lastUsername: string = '';
  public lastPassword: string = '';
  public usePasswordResult: boolean = false;

  cancel(): void {
    this.cancelCount++;
  }

  proceed(username: string, password: string): void {
    this.lastUsername = username;
    this.lastPassword = password;
  }

  useHttpAuthUsernamePassword(): boolean {
    return this.usePasswordResult;
  }
}

/** SSL 错误处理器 Fake。 */
export class FakeSslErrorHandler implements SslErrorHandler {
  public cancelCount: number = 0;
  public proceedCount: number = 0;

  cancel(): void {
    this.cancelCount++;
  }

  proceed(): void {
    this.proceedCount++;
  }

  // OhosSslErrorHandler 包装类实际调用的是 ArkWeb 风格的 handleConfirm/handleCancel。
  handleCancel(): void {
    this.cancelCount++;
  }

  handleConfirm(): void {
    this.proceedCount++;
  }
}

/** 全屏自定义视图回调 Fake。 */
export class FakeCustomViewCallback implements CustomViewCallback {
  public hiddenCount: number = 0;

  onCustomViewHidden(): void {
    this.hiddenCount++;
  }
}

/** 下载监听 Fake：记录 onDownloadStart 参数。 */
export class FakeDownloadListener implements DownloadListener {
  public lastUrl: string = '';
  public lastUserAgent: string = '';
  public lastContentDisposition: string = '';
  public lastMimetype: string = '';
  public lastContentLength: number = -1;
  public startCount: number = 0;

  onDownloadStart(
    url: string,
    userAgent: string,
    contentDisposition: string,
    mimeType: string,
    contentLength: number
  ): void {
    this.startCount++;
    this.lastUrl = url;
    this.lastUserAgent = userAgent;
    this.lastContentDisposition = contentDisposition;
    this.lastMimetype = mimeType;
    this.lastContentLength = contentLength;
  }
}

/** 资源加载错误 Fake。 */
export class FakeWebResourceError {
  constructor() {
  }

  public errorCode: number = 500;
  public errorInfo: string = 'server error';

  getErrorCode(): number {
    return this.errorCode;
  }

  getErrorInfo(): string {
    return this.errorInfo;
  }
}

/** HTTP Header Fake（web 全局 Header 接口）。 */
export class FakeHeader implements Header {
  public headerKey: string = '';
  public headerValue: string = '';

  constructor(key: string, value: string) {
    this.headerKey = key;
    this.headerValue = value;
  }
}

/** 资源请求 Fake。 */
export class FakeWebResourceRequest {
  public requestUrl: string = 'about:blank';
  public mainFrame: boolean = true;
  public redirect: boolean = false;
  public requestGesture: boolean = true;
  public requestMethod: string = 'GET';
  public requestHeaders: Array<Header> = [];

  constructor() {
    this.requestHeaders.push(new FakeHeader('Accept', 'text/html'));
  }

  getRequestUrl(): string {
    return this.requestUrl;
  }

  isMainFrame(): boolean {
    return this.mainFrame;
  }

  isRedirect(): boolean {
    return this.redirect;
  }

  isRequestGesture(): boolean {
    return this.requestGesture;
  }

  getRequestMethod(): string {
    return this.requestMethod;
  }

  getRequestHeader(): Array<Header> {
    return this.requestHeaders;
  }
}

/** JsResult Fake（ArkWeb 环境声明类，普通类 + 双重断言使用）。 */
export class FakeJsResult {
  public confirmCount: number = 0;
  public cancelCount: number = 0;
  public promptValue: string = '';

  handleConfirm(): void {
    this.confirmCount++;
  }

  handleCancel(): void {
    this.cancelCount++;
  }

  handlePromptConfirm(value: string): void {
    this.promptValue = value;
    this.confirmCount++;
  }
}

/** ConsoleMessage Fake：记录级别可注入以覆盖 toConsoleMessageLevel 分支。 */
export class FakeConsoleMessage {
  public lineNumber: number = 3;
  public message: string = 'console-hello';
  public level: MessageLevel = MessageLevel.Info;
  public sourceId: string = 'about:blank';

  getLineNumber(): number {
    return this.lineNumber;
  }

  getMessage(): string {
    return this.message;
  }

  getMessageLevel(): MessageLevel {
    return this.level;
  }

  getSourceId(): string {
    return this.sourceId;
  }
}

/** FileSelectorResult Fake：记录 handleFileList 传入的文件列表。 */
export class FakeFileSelectorResult {
  public fileList: Array<string> | null = null;

  handleFileList(fileList: Array<string>): void {
    this.fileList = fileList;
  }
}

/**
 * WebResourceResponse Fake：供 onReceivedHttpError 使用。
 * 注意：createWebResourceErrorData 的 instanceof WebResourceResponse 分支
 * 在运行时对普通类恒为 false（SDK 声明类无运行时值），实际落入
 * WebResourceError 分支，因此提供 getErrorCode/getErrorInfo。
 */
export class FakeWebResourceResponse {
  public statusCode: number = 500;
  public reasonPhrase: string = 'Internal Server Error';
  public responseHeaders: Array<Header> = [new FakeHeader('Server', 'mock')];

  getErrorCode(): number {
    return this.statusCode;
  }

  getErrorInfo(): string {
    return this.reasonPhrase;
  }

  getResponseHeaders(): Array<Header> {
    return this.responseHeaders;
  }
}
