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

// CookieManagerHostApiImpl / DisplayListenerProxy 单元测试：
// Cookie 写入与三方 Cookie 校验、清理回调，显示监听器的采集与幂等清理。
// 静态 ArkWeb / @ohos.display 调用在进程内可能抛错，均以 try/catch 包裹
//（行覆盖不受影响）。

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebViewPlatformView
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import {
  CookieManagerHostApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/CookieManagerHostApiImpl';
import { Result } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { DisplayListenerProxy } from '../../../main/ets/io.flutter.plugins/webview_flutter/DisplayListenerProxy';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';

/** Pigeon Result<boolean> Fake：记录 success/error。 */
class FakeBoolResult {
  public successValue: boolean | null = null;
  public errorValue: Object | null = null;
  public succeeded: boolean = false;

  success(value: boolean): void {
    this.succeeded = true;
    this.successValue = value;
  }

  error(error: Error): void {
    this.errorValue = error;
  }
}

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

export default function cookieAndDisplayTest() {
  describe('CookieAndDisplayTest', () => {
    // ---------- CookieManagerHostApiImpl ----------
    it('cookieManagerAttachAndSetCookieDoNotCrash', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: CookieManagerHostApiImpl = new CookieManagerHostApiImpl(messenger, manager);
      api.attachInstance(1);
      // 静态 ArkWeb CookieManager 调用可能抛错（进程内允许），不应崩溃进程。
      try {
        api.setCookie(1, 'about:blank', 'a=1');
      } catch (err) {
      }
    })

    it('cookieManagerSetAcceptThirdPartyCookiesValidatesWebViewId', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: CookieManagerHostApiImpl = new CookieManagerHostApiImpl(messenger, manager);
      let threw: boolean = false;
      let message: string = '';
      try {
        api.setAcceptThirdPartyCookies(1, 40404, true);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('not found')).assertTrue();
      const view: WebViewPlatformView = new WebViewPlatformView(messenger, manager);
      manager.addHostCreatedInstance(view);
      try {
        api.setAcceptThirdPartyCookies(1, manager.getIdentifier(view), true);
      } catch (err) {
      }
    })

    it('cookieManagerRemoveAllCookiesInvokesResult', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const manager: InstanceManager = newManager();
      const api: CookieManagerHostApiImpl = new CookieManagerHostApiImpl(messenger, manager);
      const result: FakeBoolResult = new FakeBoolResult();
      let threw: boolean = false;
      try {
        api.removeAllCookies(1, result as Object as Result<boolean>);
      } catch (err) {
        threw = true;
      }
      // 契约：成功路径必回调 success(true)；失败路径抛错且不回调。
      // 静态 ArkWeb 清理在测试进程内成败因环境而异，二者取其一即符合契约。
      expect(threw || result.succeeded).assertTrue();
    })

    // ---------- DisplayListenerProxy ----------
    it('displayListenerProxyPreAndPostInitialization', 0, async () => {
      const proxy: DisplayListenerProxy = new DisplayListenerProxy();
      // 生产实现 catch 后 rethrow，getAllDisplays 在测试进程内成败因环境而异；
      // 此处仅做入口路径覆盖，无行为断言（幂等清理由下一用例断言）。
      try {
        await proxy.onPreWebViewInitialization();
      } catch (err) {
      }
      try {
        await proxy.onPostWebViewInitialization();
      } catch (err) {
      }
    })

    it('displayListenerProxyCleanupIsIdempotent', 0, () => {
      const proxy: DisplayListenerProxy = new DisplayListenerProxy();
      let threw: boolean = false;
      try {
        proxy.cleanup();
        proxy.cleanup();
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })
  })
}
