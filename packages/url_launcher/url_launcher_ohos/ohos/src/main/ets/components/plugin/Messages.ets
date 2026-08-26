/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG = 'UrlLauncher'

export class FlutterError extends Error {
  /** The error code. */
  public code: string;

  /** The error details. Must be a datatype supported by the api codec. */
  public details: ESObject;

  constructor(code: string, message: string, details: ESObject) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

export function wrapError(exception: Error): Array<Object> {
  let errorList = new Array<Object>();
  if (exception instanceof FlutterError) {
    let error = exception as FlutterError;
    errorList.push(error.code);
    errorList.push(error.message);
    errorList.push(error.details);
  } else {
    errorList.push(exception.name);
    errorList.push(exception.message ?? '');
    errorList.push('Stacktrace: ' + exception.stack);
  }
  return errorList;
}

/**
 * Configuration options for an in-app WebView.
 *
 */
export class WebViewOptions {
  private enableJavaScript: boolean = false;

  public getEnableJavaScript(): boolean {
    return this.enableJavaScript;
  }

  public setEnableJavaScript(setterArg: boolean): void {
    if (setterArg == null) {
      throw new ReferenceError('Nonnull field "enableJavaScript" is null.');
    }
    this.enableJavaScript = setterArg;
  }

  private enableDomStorage: boolean = false;

  public getEnableDomStorage(): boolean {
    return this.enableDomStorage;
  }

  public setEnableDomStorage(setterArg: boolean): void {
    if (setterArg == null) {
      throw new ReferenceError('Nonnull field "enableDomStorage" is null.');
    }
    this.enableDomStorage = setterArg;
  }

  private headers: Map<string, string> = new Map<string, string>();

  public getHeaders(): Map<string, string> {
    return this.headers;
  }

  public setHeaders(setterArg: Map<string, string>) {
    if (setterArg == null) {
      throw new ReferenceError('Nonnull field "headers" is null.');
    }
    // 防御性过滤：Dart 侧 Pigeon 生成 Map<String?, String?> 允许 null key/value，
    // OHOS 侧 Map<string, string> 不接受 null，过滤掉可能的 null entry 避免运行时异常
    let filtered = new Map<string, string>();
    setterArg.forEach((value: string, key: string) => {
      if (key != null && value != null) {
        filtered.set(key, value);
      }
    });
    this.headers = filtered;
  }

  toList(): Array<ESObject> {
    let toListResult = new Array<Object>();
    toListResult.push(this.enableJavaScript);
    toListResult.push(this.enableDomStorage);
    toListResult.push(this.headers);
    return toListResult;
  }

  static fromList(list: Array<Object>): WebViewOptions {
    if (!list || list.length < 3) {
      throw new FlutterError('INVALID_DATA', 'WebViewOptions list requires at least 3 elements', null);
    }
    let result = new WebViewOptions();
    let enableJavaScript = list[0] as boolean;
    result.setEnableJavaScript(enableJavaScript);
    let enableDomStorage = list[1] as boolean;
    result.setEnableDomStorage(enableDomStorage);
    let headers = list[2];
    result.setHeaders(headers as Map<string, string>);
    return result;
  }

  /** Constructor is non-public to enforce null safety; use Builder. */
  private WebViewOptions() {}
}

export class UrlLauncherApiCodec extends StandardMessageCodec {
  public static INSTANCE: UrlLauncherApiCodec = new UrlLauncherApiCodec();

  private constructor() {
    super();
  }

  readValueOfType(type: number, buffer: ByteBuffer): Object {
    switch (type) {
      case 128:
        return WebViewOptions.fromList(super.readValue(buffer) as Array<Object>);
      case 129:
        return BrowserOptions.fromList(super.readValue(buffer) as Array<Object>);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): void {
    if (value instanceof WebViewOptions) {
      stream.writeInt8(128);
      this.writeValue(stream, (value as WebViewOptions).toList());
    } else if (value instanceof BrowserOptions) {
      stream.writeInt8(129);
      this.writeValue(stream, (value as BrowserOptions).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/**
 * Configuration options for a browser view.
 *
 */
export class BrowserOptions {
  private showTitle: boolean = false;

  public getShowTitle(): boolean {
    return this.showTitle;
  }

  public setShowTitle(setterArg: boolean): void {
    if (setterArg == null) {
      throw new ReferenceError('Nonnull field "showTitle" is null.');
    }
    this.showTitle = setterArg;
  }

  toList(): Array<ESObject> {
    let toListResult = new Array<Object>();
    toListResult.push(this.showTitle);
    return toListResult;
  }

  static fromList(list: Array<Object>): BrowserOptions {
    if (!list || list.length < 1) {
      throw new FlutterError('INVALID_DATA', 'BrowserOptions list is empty', null);
    }
    let result = new BrowserOptions();
    let showTitle = list[0] as boolean;
    result.setShowTitle(showTitle);
    return result;
  }

  /** Constructor is non-public to enforce null safety; use Builder. */
  private BrowserOptions() {}
}

export interface UrlLauncherApi {
  /** Returns true if the URL can definitely be launched. */
  canLaunchUrl(url: string): boolean;

  /** Opens the URL externally, returning true if successful.
   *  异步接口：startAbility() 返回 Promise，需 await 后反映实际启动结果 */
  launchUrl(url: string, headers: Map<string, string>): Promise<boolean>;

  /** Opens the URL in an in-app WebView, returning true if it opens successfully.
   *  异步接口：router.pushUrl() 返回 Promise，需 await 后反映实际启动结果 */
  openUrlInWebView(url: string, options: WebViewOptions, browserOptions: BrowserOptions): Promise<boolean>;

  /** Closes the view opened by [openUrlInSafariViewController]. */
  closeWebView(): void;

  /** The codec used by UrlLauncherApi. */
  getCodec(): MessageCodec<ESObject>;

  /** Sets up an instance of `UrlLauncherApi` to handle messages through the `binaryMessenger`. */
  setup(binaryMessenger: BinaryMessenger | null, api: UrlLauncherApi | null): ESObject;
}