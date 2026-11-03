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
 
// WebViewFlutterPlugin 单元测试：引擎挂载时注册全部 Pigeon HostApi 通道与
// PlatformViewFactory，InstanceManagerHostApi.clear 处理器清理实例表，
// 引擎卸载时反注册全部通道并释放 InstanceManager。
// FakeBinding 通过鸭子类型提供 binding 所需的四个 getter。

import { describe, it, expect } from '@ohos/hypium';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import { WebViewFlutterPlugin } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewFlutterPlugin';
import { OhosObjectHostApi } from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import { FakePlatformView } from '../testmock/MockViews';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

/** PlatformViewRegistry Fake：记录注册的工厂名。 */
class FakePlatformViewRegistry {
  public factoryNames: Array<string> = [];

  registerViewFactory(name: string, factory: Object): void {
    this.factoryNames.push(name);
  }
}

/** FlutterAssets Fake：仅满足 PluginBindingFlutterAssetManager 的构造。 */
class FakeFlutterAssets {
  getAssetFilePathByName(name: string): string {
    return 'flutter_assets/' + name;
  }
}

/** ApplicationContext Fake：resourceManager 传 undefined 即可。 */
class FakeApplicationContext {
  public resourceManager: Object | null = null;
}

/** FlutterPluginBinding Fake：onAttached/OnDetachedToEngine 所需的四个 getter。 */
class FakePluginBinding {
  public messenger: MockBinaryMessenger;
  public registry: FakePlatformViewRegistry;

  constructor(messenger: MockBinaryMessenger, registry: FakePlatformViewRegistry) {
    this.messenger = messenger;
    this.registry = registry;
  }

  getBinaryMessenger(): MockBinaryMessenger {
    return this.messenger;
  }

  getPlatformViewRegistry(): FakePlatformViewRegistry {
    return this.registry;
  }

  getApplicationContext(): FakeApplicationContext {
    return new FakeApplicationContext();
  }

  getFlutterAssets(): FakeFlutterAssets {
    return new FakeFlutterAssets();
  }
}

export default function webViewFlutterPluginTest() {
  describe('WebViewFlutterPluginTest', () => {
    it('getUniqueClassNameReturnsTag', 0, () => {
      const plugin: WebViewFlutterPlugin = new WebViewFlutterPlugin();
      expect(plugin.getUniqueClassName()).assertEqual('WebViewFlutterPlugin');
    })

    it('onAttachedToEngineRegistersViewFactoryAndAllHandlers', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const registry: FakePlatformViewRegistry = new FakePlatformViewRegistry();
      const plugin: WebViewFlutterPlugin = new WebViewFlutterPlugin();
      plugin.onAttachedToEngine(new FakePluginBinding(messenger, registry) as Object as FlutterPluginBinding);
      // PlatformViewFactory 注册。
      expect(registry.factoryNames.indexOf('plugins.flutter.io/webview') !== -1).assertTrue();
      // 每个 HostApi 至少一个方法通道被注册。
      const channels: Array<string> = [
        'WebViewHostApi.create',
        'WebViewClientHostApi.create',
        'WebChromeClientHostApi.create',
        'WebSettingsHostApi.setUserAgentString',
        'JavaScriptChannelHostApi.create',
        'DownloadListenerHostApi.create',
        'CookieManagerHostApi.setCookie',
        'WebStorageHostApi.deleteAllData',
        'WebViewFeatureHostApi.isFeatureSupported',
        'FlutterAssetManagerHostApi.list',
        'PermissionRequestHostApi.grant',
        'GeolocationPermissionsCallbackHostApi.invoke',
        'CustomViewCallbackHostApi.onCustomViewHidden',
        'HttpAuthHandlerHostApi.cancel',
        'SslErrorHandlerHostApi.cancel',
        'OhosObjectHostApi.dispose',
        'InstanceManagerHostApi.clear'
      ];
      for (const channel of channels) {
        expect(messenger.getHandler(CHANNEL_PREFIX + channel) != null).assertTrue();
      }
      expect(plugin.getInstanceManager() != null).assertTrue();
    })

    it('instanceManagerClearHandlerClearsInstances', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const registry: FakePlatformViewRegistry = new FakePlatformViewRegistry();
      const plugin: WebViewFlutterPlugin = new WebViewFlutterPlugin();
      plugin.onAttachedToEngine(new FakePluginBinding(messenger, registry) as Object as FlutterPluginBinding);
      const manager: InstanceManager = plugin.getInstanceManager() as Object as InstanceManager;
      const identifier: number = manager.addHostCreatedInstance(new FakePlatformView());
      expect(manager.getInstance(identifier) != null).assertTrue();
      // 驱动 InstanceManagerHostApi.clear 处理器：应清理实例表。
      const decoded: Array<Object> | null = messenger.driveHandler(
        OhosObjectHostApi.getCodec(), CHANNEL_PREFIX + 'InstanceManagerHostApi.clear', []
      );
      expect(decoded != null).assertTrue();
      // 成功应答首元素为 'null'；否则是 [code, message, details] 错误包装。
      expect(`${decoded![0]}`).assertEqual('null');
      expect(manager.getInstance(identifier)).assertUndefined();
    })

    it('onDetachedFromEngineUnregistersHandlersAndReleasesManager', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      const registry: FakePlatformViewRegistry = new FakePlatformViewRegistry();
      const binding: FakePluginBinding = new FakePluginBinding(messenger, registry);
      const plugin: WebViewFlutterPlugin = new WebViewFlutterPlugin();
      plugin.onAttachedToEngine(binding as Object as FlutterPluginBinding);
      plugin.onDetachedFromEngine(binding as Object as FlutterPluginBinding);
      // 全部 Pigeon 通道处理器应已反注册。
      const channels: Array<string> = [
        'WebViewHostApi.create',
        'WebViewClientHostApi.create',
        'WebChromeClientHostApi.create',
        'WebSettingsHostApi.setUserAgentString',
        'JavaScriptChannelHostApi.create',
        'DownloadListenerHostApi.create',
        'CookieManagerHostApi.setCookie',
        'WebStorageHostApi.deleteAllData',
        'WebViewFeatureHostApi.isFeatureSupported',
        'FlutterAssetManagerHostApi.list',
        'PermissionRequestHostApi.grant',
        'GeolocationPermissionsCallbackHostApi.invoke',
        'CustomViewCallbackHostApi.onCustomViewHidden',
        'HttpAuthHandlerHostApi.cancel',
        'SslErrorHandlerHostApi.cancel',
        'OhosObjectHostApi.dispose',
        'InstanceManagerHostApi.clear'
      ];
      for (const channel of channels) {
        expect(messenger.getHandler(CHANNEL_PREFIX + channel) == null).assertTrue();
      }
      expect(plugin.getInstanceManager() == null).assertTrue();
    })
  })
}
