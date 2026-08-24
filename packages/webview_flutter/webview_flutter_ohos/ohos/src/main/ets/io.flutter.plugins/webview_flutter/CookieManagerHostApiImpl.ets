// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on CookieManagerHostApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { Result } from './GeneratedOhosWebView'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { InstanceManager } from './InstanceManager'
import { CookieManagerHostApi } from './GeneratedOhosWebView';
import web_webview from '@ohos.web.webview'
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'CookieManagerHostApiImpl';

export class CookieManagerHostApiImpl extends CookieManagerHostApi {
  private binaryMessenger: BinaryMessenger;
  private instanceManager: InstanceManager;

  constructor(binaryMessenger: BinaryMessenger , instanceManager: InstanceManager ) {
    super()
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  private getCookieManagerInstance(identifier: number): ESObject {
    const cookieManagerInstance: ESObject = this.instanceManager.getInstance(identifier)
    if (cookieManagerInstance) {
      return cookieManagerInstance
    }
    else {
      throw new Error("getCookieManagerInstance, no such instance")
    }
  }
  attachInstance(instanceIdentifier: number) {
    // ArkWeb exposes WebCookieManager as a process-wide static service, so
    // there is no native CookieManager object to attach to this identifier.
  }

  setCookie(identifier: number, url: string, value: string) {
    try {
      web_webview.WebCookieManager.setCookie(url, value);
    } catch (error) {
      // Observation only: log then rethrow the same error; the operation is
      // unchanged.
      Log.e(TAG, 'setCookie err = ' + error);
      throw new Error(String(error));
    }
  }

  // Defect fix (cross-language parameter loss): the Pigeon channel already
  // carried a webViewIdentifier argument, but the previous implementation
  // dropped it before this point. The identifier is now received and
  // validated. ArkWeb's WebCookieManager is a process-wide static service, so
  // the setting itself remains process-scoped (documented platform
  // difference); the per-WebView parameter is kept to honor the
  // cross-platform API contract and to reject disposed WebView identifiers.
  setAcceptThirdPartyCookies(identifier: number, webViewIdentifier: number, accept: boolean) {
    if (!this.instanceManager.getInstance(webViewIdentifier)) {
      throw new Error('WebView instance not found for setAcceptThirdPartyCookies, id = ' + webViewIdentifier);
    }
    try {
      web_webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(accept);
    } catch (error) {
      // Observation only: log then rethrow the same error; the operation is
      // unchanged.
      Log.e(TAG, 'setAcceptThirdPartyCookies err = ' + error);
      throw new Error(String(error));
    }
  }

  removeAllCookies(identifier: number, result: Result<boolean> ) {
    try {
      web_webview.WebCookieManager.clearAllCookiesSync()
      result.success(true)
    } catch (error) {
      // Observation only: log then rethrow the same error; the result
      // callback is not invoked on failure, exactly as before.
      Log.e(TAG, 'removeAllCookies err = ' + error);
      throw new Error(String(error));
    }
  }

}

// Naming alignment: renamed from lowercase `cookieManager` to match the
// interface naming convention used across this package. Internal only; no
// references existed outside this file and behavior is unchanged.
export interface CookieManager {
  removeAllCookies(identifier: number, result: Result<boolean> | null): void

  putAcceptThirdPartyCookieEnabled(accept: boolean): void

  setCookie(url: string, value: string): void
}
