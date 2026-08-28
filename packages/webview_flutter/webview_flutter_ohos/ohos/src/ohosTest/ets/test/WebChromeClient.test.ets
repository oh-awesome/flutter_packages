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
 
// WebChromeClientImpl / WebChromeClientFlutterApiImpl / WebSettingsHostApiImpl
// 单元测试：Chrome 事件转发（进度、控制台、JS 对话框、文件选择、定位与权限）、
// 同步返回值开关，以及全部 WebSettings 读写委托。

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebChromeClient,
  WebChromeClientHostApiImpl,
  WebChromeClientCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientHostApiImpl';
import {
  WebChromeClientFlutterApiImpl
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebChromeClientFlutterApiImpl';
import {
  WebSettingsHostApiImpl,
  WebSettingsCreator
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebSettingsHostApiImpl';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import {
  FakeConsoleMessage,
  FakeJsResult,
  FakeFileSelectorParam,
  FakeFileSelectorResult,
  FakeJsGeolocation,
  FakePermissionRequest
} from '../testmock/MockInstances';
import { FakeWebViewPlatformView } from '../testmock/MockViews';
import { callOnConsoleMessage } from '../testmock/MockInstances';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

class Fixture {
  public messenger: MockBinaryMessenger = new MockBinaryMessenger();
  public manager: InstanceManager = new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
  public view: FakeWebViewPlatformView;
  public viewId: number;
  public chromeApi: WebChromeClientHostApiImpl;
  public chromeClientId: number;
  public settingsApi: WebSettingsHostApiImpl;
  public settingsId: number;

  constructor() {
    this.view = new FakeWebViewPlatformView(this.messenger, this.manager);
    this.viewId = this.manager.addHostCreatedInstance(this.view);
    this.chromeApi = new WebChromeClientHostApiImpl(
      this.manager, new WebChromeClientCreator(),
      new WebChromeClientFlutterApiImpl(this.messenger, this.manager)
    );
    this.chromeApi.create(51);
    this.chromeClientId = 51;
    this.settingsApi = new WebSettingsHostApiImpl(this.manager, new WebSettingsCreator());
    // WebSettings 实例需先 create 注册到 InstanceManager（Creator 经视图取回 Fake）。
    this.settingsApi.create(61, this.viewId);
    this.settingsId = 61;
  }
}

export default function webChromeClientTest() {
  describe('WebChromeClientTest', () => {
    // ---------- 进度与控制台 ----------
    it('onProgressChangedNotifiesDart', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      client.onProgressChanged(f.view, 42);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onProgressChanged')).assertTrue();
    })

    it('onConsoleMessageConvertsLevelAndNotifiesDart', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const message: FakeConsoleMessage = new FakeConsoleMessage();
      message.message = 'tip-message';
      const handled: boolean = callOnConsoleMessage(client, message as Object as ConsoleMessage);
      expect(handled).assertFalse();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onConsoleMessage')).assertTrue();
    })

    it('setReturnValueForOnConsoleMessageChangesReturn', 0, () => {
      const f: Fixture = new Fixture();
      f.chromeApi.setSynchronousReturnValueForOnConsoleMessage(f.chromeClientId, true);
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const handled: boolean = callOnConsoleMessage(client, new FakeConsoleMessage() as Object as ConsoleMessage);
      expect(handled).assertTrue();
    })

    // ---------- JS 对话框 ----------
    it('onJsAlertReturnsFalseByDefault', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const result: FakeJsResult = new FakeJsResult();
      const handled: boolean =
        client.onJsAlert(f.view, 'about:blank', 'hi', result as Object as JsResult);
      expect(handled).assertFalse();
      expect(f.messenger.sendCount).assertEqual(0);
    })

    it('onJsAlertHandlesConfirmAfterDartReply', 0, () => {
      const f: Fixture = new Fixture();
      f.chromeApi.setSynchronousReturnValueForOnJsAlert(f.chromeClientId, true);
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const result: FakeJsResult = new FakeJsResult();
      const handled: boolean =
        client.onJsAlert(f.view, 'about:blank', 'hi', result as Object as JsResult);
      expect(handled).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onJsAlert')).assertTrue();
      // MockBinaryMessenger 的同步 null 应答驱动 reply：应已执行 handleConfirm。
      expect(result.confirmCount).assertEqual(1);
    })

    it('onJsConfirmHandlesCancelForNullReply', 0, () => {
      const f: Fixture = new Fixture();
      f.chromeApi.setSynchronousReturnValueForOnJsConfirm(f.chromeClientId, true);
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const result: FakeJsResult = new FakeJsResult();
      const handled: boolean =
        client.onJsConfirm(f.view, 'about:blank', 'sure?', result as Object as JsResult);
      expect(handled).assertTrue();
      // Dart 侧应答为 null（Mock 自动应答）→ handleCancel。
      expect(result.cancelCount).assertEqual(1);
    })

    it('onJsPromptHandlesCancelForNullReply', 0, () => {
      const f: Fixture = new Fixture();
      f.chromeApi.setSynchronousReturnValueForOnJsPrompt(f.chromeClientId, true);
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const result: FakeJsResult = new FakeJsResult();
      const handled: boolean =
        client.onJsPrompt(f.view, 'about:blank', 'name?', 'default', result as Object as JsResult);
      expect(handled).assertTrue();
      expect(result.cancelCount).assertEqual(1);
    })

    // ---------- 文件选择 ----------
    it('onShowFileChooserRegistersParamsAndReturnsFlag', 0, () => {
      const f: Fixture = new Fixture();
      f.chromeApi.setSynchronousReturnValueForOnShowFileChooser(f.chromeClientId, true);
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const callback: FakeFileSelectorResult = new FakeFileSelectorResult();
      const params: FakeFileSelectorParam = new FakeFileSelectorParam();
      const handled: boolean =
        client.onShowFileChooser(f.view, callback as Object as FileSelectorResult, params as Object as FileSelectorParam);
      expect(handled).assertTrue();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onShowFileChooser')).assertTrue();
    })

    it('onShowFileChooserReturnsFalseWhenDisabled', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      const handled: boolean = client.onShowFileChooser(
        f.view, new FakeFileSelectorResult() as Object as FileSelectorResult,
        new FakeFileSelectorParam() as Object as FileSelectorParam
      );
      expect(handled).assertFalse();
    })

    // ---------- 定位与权限 ----------
    it('onGeolocationPermissionsShowPromptRegistersCallback', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      client.onGeolocationPermissionsShowPrompt(
        'about:blank', new FakeJsGeolocation() as Object as JsGeolocation);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onGeolocationPermissionsShowPrompt')).assertTrue();
    })

    it('onGeolocationPermissionsHidePromptNotifiesDart', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      client.onGeolocationPermissionsHidePrompt();
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onGeolocationPermissionsHidePrompt')).assertTrue();
    })

    it('onPermissionRequestRegistersRequestWithResources', 0, () => {
      const f: Fixture = new Fixture();
      const client: WebChromeClient = f.manager.getInstance(f.chromeClientId) as Object as WebChromeClient;
      client.onPermissionRequest(new FakePermissionRequest() as Object as PermissionRequest);
      expect(f.messenger.hasSentTo(CHANNEL_PREFIX + 'WebChromeClientFlutterApi.onPermissionRequest')).assertTrue();
    })

    // ---------- WebSettingsHostApiImpl ----------
    it('settingsSettersDelegateToWebSettings', 0, () => {
      const f: Fixture = new Fixture();
      f.settingsApi.setDomStorageEnabled(f.settingsId, true);
      f.settingsApi.setJavaScriptEnabled(f.settingsId, true);
      f.settingsApi.setSupportZoom(f.settingsId, true);
      f.settingsApi.setDisplayZoomControls(f.settingsId, true);
      f.settingsApi.setBuiltInZoomControls(f.settingsId, true);
      f.settingsApi.setAllowFileAccess(f.settingsId, true);
      f.settingsApi.setLoadWithOverviewMode(f.settingsId, true);
      f.settingsApi.setUseWideViewPort(f.settingsId, true);
      f.settingsApi.setSupportMultipleWindows(f.settingsId, true);
      f.settingsApi.setJavaScriptCanOpenWindowsAutomatically(f.settingsId, true);
      f.settingsApi.setMediaPlaybackRequiresUserGesture(f.settingsId, false);
      f.settingsApi.setUserAgentString(f.settingsId, 'custom-ua');
      f.settingsApi.setBackgroundColor(f.settingsId, 4294967295);
      f.settingsApi.setTextZoom(f.settingsId, 150);
      f.settingsApi.setAllowFullScreenRotate(f.settingsId, true);
      f.settingsApi.setPaymentRequestEnabled(f.settingsId, false);
      f.settingsApi.setMixedContentMode(f.settingsId, 2);
      f.settingsApi.setOverScrollMode(f.settingsId, 1);
      const s = f.view.fakeSettings;
      expect(s.domStorageEnabled).assertTrue();
      expect(s.javaScriptEnabled).assertTrue();
      expect(s.supportZoom).assertTrue();
      expect(s.displayZoomControls).assertTrue();
      expect(s.builtInZoomControls).assertTrue();
      expect(s.allowFileAccess).assertTrue();
      expect(s.loadWithOverviewMode).assertTrue();
      expect(s.useWideViewPort).assertTrue();
      expect(s.supportMultipleWindows).assertTrue();
      expect(s.javaScriptCanOpenWindowsAutomatically).assertTrue();
      expect(s.mediaPlaybackRequiresUserGesture).assertFalse();
      expect(s.userAgentString).assertEqual('custom-ua');
      expect(s.backgroundColor).assertEqual(4294967295);
      expect(s.textZoom).assertEqual(150);
      expect(s.allowFullScreenRotate).assertTrue();
      expect(s.paymentRequestEnabled).assertFalse();
      expect(s.mixedContentMode).assertEqual(2);
      expect(s.overScrollMode).assertEqual(1);
    })

    it('settingsGetUserAgentStringReadsFromWebSettings', 0, async () => {
      const f: Fixture = new Fixture();
      const ua: string = await f.settingsApi.getUserAgentString(f.settingsId);
      expect(ua).assertEqual('mock-ua');
    })

    it('settingsWithUnknownWebViewThrows', 0, () => {
      const f: Fixture = new Fixture();
      let threw: boolean = false;
      let message: string = '';
      try {
        f.settingsApi.setJavaScriptEnabled(87654, true);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.length > 0).assertTrue();
    })
  })
}
