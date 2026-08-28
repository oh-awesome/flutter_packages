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
 
// 用例清单：新增测试套件后在此登记。

import localUnitTest from './LocalUnit.test';
import instanceManagerTest from './InstanceManager.test';
import dynamicUtilsTest from './DynamicUtils.test';
import generatedOhosWebViewTest from './GeneratedOhosWebView.test';
import hostApiImplTest from './HostApiImpl.test';
import flutterApiImplTest from './FlutterApiImpl.test';
import clientImplTest from './ClientImpl.test';
import webViewHostApiTest from './WebViewHostApi.test';
import webChromeClientTest from './WebChromeClient.test';
import webViewPlatformViewEventsTest from './WebViewPlatformViewEvents.test';
import webViewFlutterPluginTest from './WebViewFlutterPlugin.test';
import cookieAndDisplayTest from './CookieAndDisplay.test';

export default function testsuite() {
  localUnitTest();
  instanceManagerTest();
  dynamicUtilsTest();
  generatedOhosWebViewTest();
  hostApiImplTest();
  flutterApiImplTest();
  clientImplTest();
  webViewHostApiTest();
  webChromeClientTest();
  webViewPlatformViewEventsTest();
  webViewFlutterPluginTest();
  cookieAndDisplayTest();
}
