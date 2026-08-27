// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on WebViewFlutterPlugin.java originally written by
// Copyright 2013 The Flutter Authors.

import { FlutterPluginBinding, FlutterPlugin } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import PluginRegistry from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/PluginRegistry';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import PlatformViewRegistry from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewRegistry';
import { OhosObjectHostApiImpl } from './OhosObjectHostApiImpl';
import { CookieManagerHostApiImpl } from './CookieManagerHostApiImpl';
import { CustomViewCallbackHostApiImpl } from './CustomViewCallbackHostApiImpl';
import { DownloadListenerFlutterApiImpl } from './DownloadListenerFlutterApiImpl';
import { DownloadListenerCreator, DownloadListenerHostApiImpl } from './DownloadListenerHostApiImpl';
import { FlutterAssetManager, PluginBindingFlutterAssetManager } from './FlutterAssetManager';
import { FlutterAssetManagerHostApiImpl } from './FlutterAssetManagerHostApiImpl';
import GeneratedOhosWebView, {
  CookieManagerHostApi,
  CustomViewCallbackHostApi,
  DownloadListenerHostApi,
  FlutterAssetManagerHostApi,
  GeolocationPermissionsCallbackHostApi,
  HttpAuthHandlerHostApi,
  SslErrorHandlerHostApi,
  InstanceManagerHostApi,
  JavaScriptChannelHostApi,
  PermissionRequestHostApi,
  OhosObjectFlutterApi,
  OhosObjectHostApi,
  WebViewHostApi,
  InstanceManagerApi,
  WebViewClientHostApi,
  WebChromeClientHostApi,
  WebSettingsHostApi,
  WebViewFeatureHostApi,
  WebStorageHostApi
} from './GeneratedOhosWebView';
import { GeolocationPermissionsCallbackHostApiImpl } from './GeolocationPermissionsCallbackHostApiImpl';
import { HttpAuthHandlerHostApiImpl } from './HttpAuthHandlerHostApiImpl';
import { SslErrorHandlerHostApiImpl } from './SslErrorHandlerHostApiImpl';
import { InstanceManager } from './InstanceManager';
import { JavaScriptChannelCreator, JavaScriptChannelHostApiImpl } from './JavaScriptChannelHostApiImpl';
import { PermissionRequestHostApiImpl } from './PermissionRequestHostApiImpl';
import { WebViewHostApiImpl, WebViewProxy } from './WebViewHostApiImpl';
import { FlutterWebViewFactory } from './FlutterWebViewFactory';
import { JavaScriptChannelFlutterApiImpl } from './JavaScriptChannelFlutterApiImpl';
import { WebViewClientCreator, WebViewClientHostApiImpl } from './WebViewClientHostApiImpl';
import { WebViewClientFlutterApiImpl } from './WebViewClientFlutterApiImpl';
import { WebChromeClientCreator, WebChromeClientHostApiImpl } from './WebChromeClientHostApiImpl';
import { WebChromeClientFlutterApiImpl } from './WebChromeClientFlutterApiImpl';
import { WebSettingsCreator, WebSettingsHostApiImpl } from './WebSettingsHostApiImpl';
import { WebViewFeatureHostApiImpl } from './WebViewFeatureHostApiImpl';
import { WebStorageHostApiImpl } from './WebStorageHostApiImpl';

const TAG:string = "WebViewFlutterPlugin";
export class WebViewFlutterPlugin implements FlutterPlugin {
  getUniqueClassName(): string {
    return TAG;
  }

  private instanceManager: InstanceManager|null = null;

  private webViewHostApiImpl: WebViewHostApiImpl|null = null;

  setUp(
    binaryMessenger: BinaryMessenger, viewRegistry: PlatformViewRegistry, context: Context,
    flutterAssetManager: FlutterAssetManager
  ) {
    this.instanceManager = new InstanceManager({
      onFinalize: (identifier: number) => {
        new OhosObjectFlutterApi(binaryMessenger).dispose(
          identifier, { reply: () => {
        } }
        )
      }
    })

    InstanceManagerHostApi.setup(
      binaryMessenger,
      {
        clear: () => {
          if(this.instanceManager)
            this.instanceManager.clear();
        }
      }
    );
    viewRegistry.registerViewFactory(
      "plugins.flutter.io/webview", new FlutterWebViewFactory(this.instanceManager)
    );

    let webViewHostApi: WebViewHostApi =
      new WebViewHostApiImpl(
        this.instanceManager, new WebViewProxy(), binaryMessenger, context);
    // Kept as the concrete impl so onDetachedFromEngine can run its
    // active-view disposal backstop.
    this.webViewHostApiImpl = webViewHostApi as WebViewHostApiImpl;
    let javaScriptChannelHostApi: JavaScriptChannelHostApi =
      new JavaScriptChannelHostApiImpl(
        this.instanceManager,
        new JavaScriptChannelCreator(),
        new JavaScriptChannelFlutterApiImpl(binaryMessenger, this.instanceManager),
      );

    OhosObjectHostApi.setup(binaryMessenger, new OhosObjectHostApiImpl(this.instanceManager));

    WebViewHostApi.setup(binaryMessenger, webViewHostApi);

    JavaScriptChannelHostApi.setup(binaryMessenger, javaScriptChannelHostApi);

    WebViewClientHostApi.setup(
      binaryMessenger,
      new WebViewClientHostApiImpl(
        this.instanceManager,
        new WebViewClientCreator(),
        new WebViewClientFlutterApiImpl(binaryMessenger, this.instanceManager))
    );

    WebChromeClientHostApi.setup(
      binaryMessenger,
      new WebChromeClientHostApiImpl(
        this.instanceManager,
        new WebChromeClientCreator(),
        new WebChromeClientFlutterApiImpl(binaryMessenger, this.instanceManager))
    );

    DownloadListenerHostApi.setup(
      binaryMessenger,
      new DownloadListenerHostApiImpl(
        this.instanceManager,
        new DownloadListenerCreator(),
        new DownloadListenerFlutterApiImpl(binaryMessenger, this.instanceManager))
    );

    WebSettingsHostApi.setup(
      binaryMessenger,
      new WebSettingsHostApiImpl(
        this.instanceManager, new WebSettingsCreator())
    );

    WebViewFeatureHostApi.setup(
      binaryMessenger,
      new WebViewFeatureHostApiImpl()
    );

    FlutterAssetManagerHostApi.setup(
      binaryMessenger, new FlutterAssetManagerHostApiImpl(flutterAssetManager)
    );

    CookieManagerHostApi.setup(
      binaryMessenger, new CookieManagerHostApiImpl(binaryMessenger, this.instanceManager)
    );

    WebStorageHostApi.setup(
      binaryMessenger,
      new WebStorageHostApiImpl()
    );

    PermissionRequestHostApi.setup(
      binaryMessenger, new PermissionRequestHostApiImpl(binaryMessenger, this.instanceManager)
    );

    GeolocationPermissionsCallbackHostApi.setup(
      binaryMessenger,
      new GeolocationPermissionsCallbackHostApiImpl(binaryMessenger, this.instanceManager)
    );
    CustomViewCallbackHostApi.setup(
      binaryMessenger, new CustomViewCallbackHostApiImpl(binaryMessenger, this.instanceManager));
    HttpAuthHandlerHostApi.setup(
      binaryMessenger, new HttpAuthHandlerHostApiImpl(binaryMessenger, this.instanceManager));
    SslErrorHandlerHostApi.setup(
      binaryMessenger, new SslErrorHandlerHostApiImpl(binaryMessenger, this.instanceManager));
  }

  onAttachedToEngine(binding: FlutterPluginBinding) {
    this.setUp(
      binding.getBinaryMessenger(),
      binding.getPlatformViewRegistry(),
      binding.getApplicationContext(),
      new PluginBindingFlutterAssetManager(
        binding.getApplicationContext().resourceManager, binding.getFlutterAssets())
    );
  }

  onDetachedFromEngine(binding: FlutterPluginBinding) {
    // Leak fix backstop: dispose any WebView that was never disposed
    // individually (e.g. its controller never attached), stopping its
    // polling intervals, display listeners and dialogs before the handlers
    // and instance manager go away. dispose() is idempotent, so views the
    // platform view registry disposes later are unaffected.
    if (this.webViewHostApiImpl != null) {
      this.webViewHostApiImpl.disposeAllActiveWebViews();
      this.webViewHostApiImpl = null;
    }
    // Resource cleanup: unregister the Pigeon handlers registered by setUp()
    // and drop all instance references. This runs only after engine detach;
    // message routing and live WebView behavior are unchanged while attached.
    const binaryMessenger: BinaryMessenger = binding.getBinaryMessenger();
    InstanceManagerHostApi.setup(binaryMessenger, null);
    OhosObjectHostApi.setup(binaryMessenger, null);
    WebViewHostApi.setup(binaryMessenger, null);
    JavaScriptChannelHostApi.setup(binaryMessenger, null);
    WebViewClientHostApi.setup(binaryMessenger, null);
    WebChromeClientHostApi.setup(binaryMessenger, null);
    DownloadListenerHostApi.setup(binaryMessenger, null);
    WebSettingsHostApi.setup(binaryMessenger, null);
    WebViewFeatureHostApi.setup(binaryMessenger, null);
    FlutterAssetManagerHostApi.setup(binaryMessenger, null);
    CookieManagerHostApi.setup(binaryMessenger, null);
    WebStorageHostApi.setup(binaryMessenger, null);
    PermissionRequestHostApi.setup(binaryMessenger, null);
    GeolocationPermissionsCallbackHostApi.setup(binaryMessenger, null);
    CustomViewCallbackHostApi.setup(binaryMessenger, null);
    HttpAuthHandlerHostApi.setup(binaryMessenger, null);
    // Leak fix (symmetric deregistration): setUp() registers the SSL handler
    // above, but it was never unregistered here, leaving the Pigeon handler
    // (and its captured impl/instance manager) reachable after engine detach.
    SslErrorHandlerHostApi.setup(binaryMessenger, null);

    if (this.instanceManager != null) {
      this.instanceManager.clear();
      this.instanceManager.stopFinalizationListener();
      this.instanceManager = null;
    }
  }

  getInstanceManager() {
    return this.instanceManager;
  }
}
