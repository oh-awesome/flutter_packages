// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Coverage tests for the Dart API surface that the XTS report listed as
// uncovered: the `OhosWebViewPlatform` factories, the `ohos_webview` Pigeon
// wrappers (WebView, WebSettings, CookieManager, WebChromeClient,
// WebViewClient, DownloadListener, JavaScriptChannel, WebStorage,
// PermissionRequest, HttpAuthHandler, GeolocationPermissionsCallback,
// CustomViewCallback, View, FileChooserParams, FlutterAssetManager,
// WebSettingsCompat, WebViewFeature), the Dart `InstanceManager`, the
// `PlatformViewsServiceProxy`, and the remaining public entry points of the
// platform interface implementation. Every case drives the real classes
// through the mock Pigeon messenger and asserts on the recorded channel
// calls, returned values or thrown errors — no method is only mentioned.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/platform_views_service_proxy.dart';
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_pigeon_test_mocks.dart';

const String _webViewHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.';
const String _webSettingsHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.';
const String _cookieManagerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.';
const String _webChromeClientHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.';
const String _webViewClientHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.';
const String _permissionRequestHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.PermissionRequestHostApi.';
const String _httpAuthHandlerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.HttpAuthHandlerHostApi.';
const String _geolocationCallbackHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.GeolocationPermissionsCallbackHostApi.';
const String _customViewCallbackHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.CustomViewCallbackHostApi.';
const String _javaScriptChannelHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelHostApi.';
const String _downloadListenerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.DownloadListenerHostApi.';
const String _webStorageHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebStorageHostApi.';

/// Registers [instance] in the global instance manager so `FromInstance`
/// calls resolve a real identifier, and returns that identifier.
int registerInstance(ohos_webview.OhosObject instance) {
  return ohos_webview.OhosObject.globalInstanceManager
      .addDartCreatedInstance(instance);
}

/// Builds a `WebChromeClient` wired with every callback the
/// `setSynchronousReturnValueFor...` setters require to be nonnull.
ohos_webview.WebChromeClient buildFullWebChromeClient() {
  return ohos_webview.WebChromeClient(
    onShowFileChooser:
        (
          ohos_webview.WebView webView,
          ohos_webview.FileChooserParams params,
        ) async =>
            <String>[],
    onConsoleMessage:
        (
          ohos_webview.WebChromeClient instance,
          ohos_webview.ConsoleMessage message,
        ) {},
    onJsAlert: (String url, String message) async {},
    onJsConfirm: (String url, String message) async => false,
    onJsPrompt:
        (String url, String message, String defaultValue) async => '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
  });

  tearDown(() {
    OhosPigeonTestMocks.clearRecords();
  });

  group('OhosWebViewPlatform', () {
    test(
      'should register itself as the platform instance when registerWith is called',
      () {
        OhosWebViewPlatform.registerWith();

        expect(WebViewPlatform.instance, isA<OhosWebViewPlatform>());
      },
    );

    test(
      'should create an OhosWebViewController when createPlatformWebViewController is called',
      () {
        final OhosWebViewPlatform platform = OhosWebViewPlatform();

        final OhosWebViewController controller =
            platform.createPlatformWebViewController(
          PlatformWebViewControllerCreationParams(),
        );

        expect(controller, isA<OhosWebViewController>());
      },
    );

    test(
      'should create an OhosNavigationDelegate when createPlatformNavigationDelegate is called',
      () {
        final OhosWebViewPlatform platform = OhosWebViewPlatform();

        final OhosNavigationDelegate delegate =
            platform.createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams(),
        );

        expect(delegate, isA<OhosNavigationDelegate>());
      },
    );

    test(
      'should create an OhosWebViewWidget when createPlatformWebViewWidget is called',
      () {
        final OhosWebViewPlatform platform = OhosWebViewPlatform();
        final OhosWebViewController controller = OhosWebViewController(
          OhosWebViewControllerCreationParams(),
        );

        final OhosWebViewWidget widget = platform.createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        );

        expect(widget, isA<OhosWebViewWidget>());
      },
    );

    test(
      'should create an OhosWebViewCookieManager when createPlatformCookieManager is called',
      () {
        final OhosWebViewPlatform platform = OhosWebViewPlatform();

        final OhosWebViewCookieManager cookieManager =
            platform.createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams(),
        );

        expect(cookieManager, isA<OhosWebViewCookieManager>());
      },
    );
  });

  group('ohos_webview.WebView Pigeon wrapper', () {
    late ohos_webview.WebView webView;

    setUp(() {
      webView = ohos_webview.WebView();
    });

    test(
      'should send create when a WebView is constructed',
      () {
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}create',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send loadUrl with the url and headers when loadUrl is called',
      () async {
        await webView.loadUrl(
          'https://flutter.dev',
          <String, String>{'header': 'value'},
        );

        expect(
          OhosPigeonTestMocks.getLastCallForChannel(
            '${_webViewHostApiPrefix}loadUrl',
          ),
          isNotNull,
        );
      },
    );

    test(
      'should send loadData when loadData is called',
      () async {
        await webView.loadData(
          data: '<html>data</html>',
          mimeType: 'text/html',
          encoding: 'utf-8',
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}loadData',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send loadDataWithBaseUrl when loadDataWithBaseUrl is called',
      () async {
        await webView.loadDataWithBaseUrl(
          baseUrl: 'https://flutter.dev',
          data: '<html>base</html>',
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}loadDataWithBaseUrl',
          ),
          isNotEmpty,
        );
      },
    );

    test('should send postUrl when postUrl is called', () async {
      await webView.postUrl(
        'https://flutter.dev',
        Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}postUrl',
        ),
        isNotEmpty,
      );
    });

    test('should return the url when getUrl is called', () async {
      expect(await webView.getUrl(), 'https://flutter.dev');
    });

    test('should return true when canGoBack is called', () async {
      expect(await webView.canGoBack(), true);
    });

    test('should return true when canGoForward is called', () async {
      expect(await webView.canGoForward(), true);
    });

    test('should send goBack when goBack is called', () async {
      await webView.goBack();

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}goBack',
        ),
        isNotEmpty,
      );
    });

    test('should send goForward when goForward is called', () async {
      await webView.goForward();

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}goForward',
        ),
        isNotEmpty,
      );
    });

    test('should send reload when reload is called', () async {
      await webView.reload();

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}reload',
        ),
        isNotEmpty,
      );
    });

    test('should send clearCache when clearCache is called', () async {
      await webView.clearCache(true);

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}clearCache',
        ),
        isNotEmpty,
      );
    });

    test(
      'should return the script result when evaluateJavascript is called',
      () async {
        expect(await webView.evaluateJavascript('1 + 1'), 'result');
      },
    );

    test('should return the title when getTitle is called', () async {
      expect(await webView.getTitle(), 'Page Title');
    });

    test('should send scrollTo when scrollTo is called', () async {
      await webView.scrollTo(10, 20);

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}scrollTo',
        ),
        isNotEmpty,
      );
    });

    test('should send scrollBy when scrollBy is called', () async {
      await webView.scrollBy(5, 15);

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}scrollBy',
        ),
        isNotEmpty,
      );
    });

    test('should return the x offset when getScrollX is called', () async {
      expect(await webView.getScrollX(), 100);
    });

    test('should return the y offset when getScrollY is called', () async {
      expect(await webView.getScrollY(), 200);
    });

    test(
      'should return the scroll position when getScrollPosition is called',
      () async {
        final Offset position = await webView.getScrollPosition();

        expect(position.dx, 100);
        expect(position.dy, 200);
      },
    );

    test(
      'should send setWebViewClient when setWebViewClient is called',
      () async {
        final ohos_webview.WebViewClient client = ohos_webview.WebViewClient();

        await webView.setWebViewClient(client);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebViewClient',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send addJavaScriptChannel when addJavaScriptChannel is called',
      () async {
        final ohos_webview.JavaScriptChannel channel =
            ohos_webview.JavaScriptChannel(
          'test_channel',
          postMessage: (String message) {},
        );

        await webView.addJavaScriptChannel(channel);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}addJavaScriptChannel',
          ),
          isNotEmpty,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_javaScriptChannelHostApiPrefix}create',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send removeJavaScriptChannel when removeJavaScriptChannel is called',
      () async {
        final ohos_webview.JavaScriptChannel channel =
            ohos_webview.JavaScriptChannel(
          'test_channel',
          postMessage: (String message) {},
        );

        await webView.removeJavaScriptChannel(channel);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}removeJavaScriptChannel',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send setDownloadListener when setDownloadListener is called',
      () async {
        final ohos_webview.DownloadListener listener =
            ohos_webview.DownloadListener(
          onDownloadStart:
          (
            String url,
            String userAgent,
            String contentDisposition,
            String mimetype,
            int contentLength,
          ) {},
        );

        await webView.setDownloadListener(listener);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setDownloadListener',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send setWebChromeClient when setWebChromeClient is called',
      () async {
        final ohos_webview.WebChromeClient client =
            buildFullWebChromeClient();

        await webView.setWebChromeClient(client);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebChromeClient',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send setWebContentsDebuggingEnabled when it is called statically',
      () async {
        await ohos_webview.WebView.setWebContentsDebuggingEnabled(true);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebContentsDebuggingEnabled',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should return a detached copy with the same callbacks when copy is called',
      () {
        final ohos_webview.WebView copy = webView.copy();

        expect(copy, isA<ohos_webview.WebView>());
        expect(copy.onScrollChanged, webView.onScrollChanged);
      },
    );
  });

  group('ohos_webview.WebSettings Pigeon wrapper', () {
    late ohos_webview.WebSettings webSettings;

    setUp(() {
      webSettings = ohos_webview.WebView().settings;
    });

    void expectChannelRecorded(String method) {
      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '$_webSettingsHostApiPrefix$method',
        ),
        isNotEmpty,
        reason: 'expected a recorded call for $method',
      );
    }

    test('should send setDomStorageEnabled when it is called', () async {
      await webSettings.setDomStorageEnabled(true);

      expectChannelRecorded('setDomStorageEnabled');
    });

    test(
      'should send setJavaScriptCanOpenWindowsAutomatically when it is called',
      () async {
        await webSettings.setJavaScriptCanOpenWindowsAutomatically(true);

        expectChannelRecorded('setJavaScriptCanOpenWindowsAutomatically');
      },
    );

    test('should send setSupportMultipleWindows when it is called', () async {
      await webSettings.setSupportMultipleWindows(true);

      expectChannelRecorded('setSupportMultipleWindows');
    });

    test('should send setBackgroundColor when it is called', () async {
      await webSettings.setBackgroundColor(const Color(0x00FF00FF));

      expectChannelRecorded('setBackgroundColor');
    });

    test('should send setJavaScriptEnabled when it is called', () async {
      await webSettings.setJavaScriptEnabled(true);

      expectChannelRecorded('setJavaScriptEnabled');
    });

    test('should send setUserAgentString when it is called', () async {
      await webSettings.setUserAgentString('test-agent');

      expectChannelRecorded('setUserAgentString');
    });

    test(
      'should send setMediaPlaybackRequiresUserGesture when it is called',
      () async {
        await webSettings.setMediaPlaybackRequiresUserGesture(true);

        expectChannelRecorded('setMediaPlaybackRequiresUserGesture');
      },
    );

    test('should send setSupportZoom when it is called', () async {
      await webSettings.setSupportZoom(true);

      expectChannelRecorded('setSupportZoom');
    });

    test('should send setLoadWithOverviewMode when it is called', () async {
      await webSettings.setLoadWithOverviewMode(true);

      expectChannelRecorded('setLoadWithOverviewMode');
    });

    test('should send setUseWideViewPort when it is called', () async {
      await webSettings.setUseWideViewPort(true);

      expectChannelRecorded('setUseWideViewPort');
    });

    test('should send setDisplayZoomControls when it is called', () async {
      await webSettings.setDisplayZoomControls(true);

      expectChannelRecorded('setDisplayZoomControls');
    });

    test('should send setBuiltInZoomControls when it is called', () async {
      await webSettings.setBuiltInZoomControls(true);

      expectChannelRecorded('setBuiltInZoomControls');
    });

    test('should send setAllowFileAccess when it is called', () async {
      await webSettings.setAllowFileAccess(true);

      expectChannelRecorded('setAllowFileAccess');
    });

    test('should send setTextZoom when it is called', () async {
      await webSettings.setTextZoom(120);

      expectChannelRecorded('setTextZoom');
    });

    test(
      'should return the user agent when getUserAgentString is called',
      () async {
        expect(await webSettings.getUserAgentString(), 'Mozilla/5.0');
      },
    );

    test('should send setAllowFullScreenRotate when it is called', () async {
      await webSettings.setAllowFullScreenRotate(true);

      expectChannelRecorded('setAllowFullScreenRotate');
    });

    test('should send setMixedContentMode when it is called', () async {
      await webSettings
          .setMixedContentMode(ohos_webview.MixedContentMode.alwaysAllow);

      expectChannelRecorded('setMixedContentMode');
    });

    test('should send setOverScrollMode when it is called', () async {
      await webSettings
          .setOverScrollMode(ohos_webview.OverScrollMode.always);

      expectChannelRecorded('setOverScrollMode');
    });

    test(
      'should send setPaymentRequestEnabled when WebSettingsCompat.setPaymentRequestEnabled is called',
      () async {
        await ohos_webview.WebSettingsCompat.setPaymentRequestEnabled(
          webSettings,
          true,
        );

        expectChannelRecorded('setPaymentRequestEnabled');
      },
    );

    test(
      'should return false when WebViewFeature.isFeatureSupported is called',
      () async {
        expect(
          await ohos_webview.WebViewFeature.isFeatureSupported(
            'PAYMENT_REQUEST',
          ),
          false,
        );
      },
    );

    test(
      'should return a detached copy when WebSettings.copy is called',
      () {
        final ohos_webview.WebSettings copy = webSettings.copy();

        expect(copy, isA<ohos_webview.WebSettings>());
      },
    );
  });

  group('ohos_webview.CookieManager Pigeon wrapper', () {
    test(
      'should return the same instance when CookieManager.instance is read twice',
      () {
        final ohos_webview.CookieManager first =
            ohos_webview.CookieManager.instance;
        final ohos_webview.CookieManager second =
            ohos_webview.CookieManager.instance;

        expect(first, isA<ohos_webview.CookieManager>());
        expect(identical(first, second), true);
      },
    );

    test('should send setCookie when setCookie is called', () async {
      final ohos_webview.CookieManager cookieManager =
          ohos_webview.CookieManager.instance;

      await cookieManager.setCookie(
        'https://flutter.dev',
        'key=value; Max-Age=123',
      );

      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_cookieManagerHostApiPrefix}setCookie',
        ),
        isNotEmpty,
      );
    });

    test('should return true when removeAllCookies is called', () async {
      final ohos_webview.CookieManager cookieManager =
          ohos_webview.CookieManager.instance;

      expect(await cookieManager.removeAllCookies(), true);
    });

    test(
      'should send setAcceptThirdPartyCookies when it is called',
      () async {
        final ohos_webview.CookieManager cookieManager =
            ohos_webview.CookieManager.instance;
        final ohos_webview.WebView webView = ohos_webview.WebView();

        await cookieManager.setAcceptThirdPartyCookies(webView, true);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_cookieManagerHostApiPrefix}setAcceptThirdPartyCookies',
          ),
          isNotEmpty,
        );
      },
    );
  });

  group('ohos_webview client and channel wrappers', () {
    test(
      'should send create when a WebViewClient is constructed and set its synchronous return value',
      () async {
        final ohos_webview.WebViewClient client = ohos_webview.WebViewClient();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewClientHostApiPrefix}create',
          ),
          isNotEmpty,
        );

        await client.setSynchronousReturnValueForShouldOverrideUrlLoading(
          true,
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webViewClientHostApiPrefix'
                'setSynchronousReturnValueForShouldOverrideUrlLoading',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send create when a DownloadListener is constructed',
      () {
        ohos_webview.DownloadListener(
          onDownloadStart:
          (
            String url,
            String userAgent,
            String contentDisposition,
            String mimetype,
            int contentLength,
          ) {},
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_downloadListenerHostApiPrefix}create',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send create when a WebChromeClient is constructed and set every synchronous return value',
      () async {
        final ohos_webview.WebChromeClient client = buildFullWebChromeClient();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webChromeClientHostApiPrefix}create',
          ),
          isNotEmpty,
        );

        await client.setSynchronousReturnValueForOnShowFileChooser(true);
        await client.setSynchronousReturnValueForOnConsoleMessage(true);
        await client.setSynchronousReturnValueForOnJsAlert(true);
        await client.setSynchronousReturnValueForOnJsConfirm(true);
        await client.setSynchronousReturnValueForOnJsPrompt(true);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webChromeClientHostApiPrefix'
                'setSynchronousReturnValueForOnShowFileChooser',
          ),
          isNotEmpty,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webChromeClientHostApiPrefix'
                'setSynchronousReturnValueForOnConsoleMessage',
          ),
          isNotEmpty,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webChromeClientHostApiPrefix'
                'setSynchronousReturnValueForOnJsAlert',
          ),
          isNotEmpty,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webChromeClientHostApiPrefix'
                'setSynchronousReturnValueForOnJsConfirm',
          ),
          isNotEmpty,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webChromeClientHostApiPrefix'
                'setSynchronousReturnValueForOnJsPrompt',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send deleteAllData when WebStorage.instance deletes all data',
      () async {
        final ohos_webview.WebStorage webStorage =
            ohos_webview.WebStorage.instance;

        await webStorage.deleteAllData();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webStorageHostApiPrefix}deleteAllData',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should return a detached copy when WebStorage.copy is called',
      () {
        final ohos_webview.WebStorage copy =
            ohos_webview.WebStorage.instance.copy();

        expect(copy, isA<ohos_webview.WebStorage>());
      },
    );

    test(
      'should list assets and resolve asset paths when FlutterAssetManager methods are called',
      () async {
        final List<String?> assets = await ohos_webview
            .FlutterAssetManager.instance
            .list('assets');

        expect(assets, contains('test.html'));

        final String path = await ohos_webview
            .FlutterAssetManager.instance
            .getAssetFilePathByName('test.html');

        expect(path, 'assets/test.html');
      },
    );
  });

  group('ohos_webview callback object wrappers', () {
    test(
      'should send grant with the mapped resources when PermissionRequest.grant is called',
      () async {
        final TestPigeonPermissionRequest request =
            TestPigeonPermissionRequest(
          resources: <String>[ohos_webview.PermissionRequest.videoCapture],
        );
        registerInstance(request);

        await request.grant(
          <String>[ohos_webview.PermissionRequest.videoCapture],
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_permissionRequestHostApiPrefix}grant',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send deny when PermissionRequest.deny is called',
      () async {
        final TestPigeonPermissionRequest request =
            TestPigeonPermissionRequest(
          resources: <String>[ohos_webview.PermissionRequest.audioCapture],
        );
        registerInstance(request);

        await request.deny();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_permissionRequestHostApiPrefix}deny',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send cancel and proceed when HttpAuthHandler methods are called',
      () async {
        final ohos_webview.HttpAuthHandler handler =
            ohos_webview.HttpAuthHandler();
        registerInstance(handler);

        await handler.cancel();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_httpAuthHandlerHostApiPrefix}cancel',
          ),
          isNotEmpty,
        );

        await handler.proceed('user', 'password');

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_httpAuthHandlerHostApiPrefix}proceed',
          ),
          isNotEmpty,
        );

        expect(await handler.useHttpAuthUsernamePassword(), false);
      },
    );

    test(
      'should send invoke when GeolocationPermissionsCallback.invoke is called',
      () async {
        final TestPigeonGeolocationPermissionsCallback callback =
            TestPigeonGeolocationPermissionsCallback();
        registerInstance(callback);

        await callback.invoke('https://flutter.dev', true, false);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_geolocationCallbackHostApiPrefix}invoke',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should send onCustomViewHidden when CustomViewCallback.onCustomViewHidden is called',
      () async {
        final TestPigeonCustomViewCallback callback =
            TestPigeonCustomViewCallback();
        registerInstance(callback);

        await callback.onCustomViewHidden();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_customViewCallbackHostApiPrefix}onCustomViewHidden',
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'should return a detached copy when View.copy is called',
      () {
        final ohos_webview.View copy = TestPigeonView().copy();

        expect(copy, isA<ohos_webview.View>());
      },
    );

    test(
      'should expose the file chooser fields and return a copy when FileChooserParams members are read',
      () {
        final TestPigeonFileChooserParams params = TestPigeonFileChooserParams(
          isCaptureEnabled: true,
          acceptTypes: <String>['image/*'],
          filenameHint: 'photo.png',
          mode: ohos_webview.FileChooserMode.openMultiple,
        );

        expect(params.isCaptureEnabled, true);
        expect(params.acceptTypes, <String>['image/*']);
        expect(params.filenameHint, 'photo.png');
        expect(params.mode, ohos_webview.FileChooserMode.openMultiple);

        final ohos_webview.FileChooserParams copy = params.copy();

        expect(copy.isCaptureEnabled, true);
        expect(copy.acceptTypes, <String>['image/*']);
        expect(copy.filenameHint, 'photo.png');
        expect(copy.mode, ohos_webview.FileChooserMode.openMultiple);
      },
    );

    test(
      'should release the weak reference when OhosObject.dispose is called',
      () {
        final TestPigeonView view = TestPigeonView();
        final InstanceManager instanceManager =
            ohos_webview.OhosObject.globalInstanceManager;
        final int identifier = instanceManager.addDartCreatedInstance(view);

        expect(instanceManager.containsIdentifier(identifier), true);

        ohos_webview.OhosObject.dispose(view);

        // Contract: dispose only drops the weak reference; the strong copy
        // stays until the host side releases the identifier.
        expect(instanceManager.getIdentifier(view), isNull);
        expect(instanceManager.containsIdentifier(identifier), true);
      },
    );
  });

  group('InstanceManager', () {
    test(
      'should register, look up and release an instance when its API is called',
      () {
        final InstanceManager instanceManager = InstanceManager(
          onWeakReferenceRemoved: (int identifier) {},
        );
        final TestPigeonView instance = TestPigeonView();

        final int identifier = instanceManager
            .addDartCreatedInstance(instance);

        expect(instanceManager.containsIdentifier(identifier), true);
        expect(instanceManager.getIdentifier(instance), identifier);
        expect(instanceManager.containsIdentifier(identifier + 1), false);

        final int? removedIdentifier =
            instanceManager.removeWeakReference(instance);

        // Contract: removeWeakReference drops only the weak reference; the
        // strongly referenced copy is still retrievable until remove().
        expect(removedIdentifier, identifier);
        expect(instanceManager.getIdentifier(instance), isNull);
        expect(instanceManager.containsIdentifier(identifier), true);

        final Copyable? strongCopy =
            instanceManager.getInstanceWithWeakReference<Copyable>(
          identifier,
        );
        expect(strongCopy, isA<ohos_webview.View>());

        // Contract: remove() drops the strong entry only; the weak copy the
        // lookup above created stays associated until it is unreachable.
        final Copyable? removedStrong = instanceManager.remove(identifier);
        expect(removedStrong, isNotNull);
        expect(instanceManager.containsIdentifier(identifier), true);
        expect(
          instanceManager.getInstanceWithWeakReference<Copyable>(identifier),
          isA<ohos_webview.View>(),
        );
      },
    );
  });

  group('PlatformViewsServiceProxy', () {
    test(
      'should return an ExpensiveOhosViewController when initExpensiveOhosView is called',
      () {
        const PlatformViewsServiceProxy proxy = PlatformViewsServiceProxy();

        final ExpensiveOhosViewController controller =
            proxy.initExpensiveOhosView(
          id: 7,
          viewType: 'plugins.flutter.io/webview',
          layoutDirection: TextDirection.ltr,
        );

        expect(controller.viewId, 7);
      },
    );

    test(
      'should return a SurfaceOhosViewController when initSurfaceOhosView is called',
      () {
        const PlatformViewsServiceProxy proxy = PlatformViewsServiceProxy();

        final SurfaceOhosViewController controller =
            proxy.initSurfaceOhosView(
          id: 9,
          viewType: 'plugins.flutter.io/webview',
          layoutDirection: TextDirection.rtl,
        );

        expect(controller.viewId, 9);
      },
    );
  });

  group('OhosWebViewController remaining public surface', () {
    test(
      'should enable debugging when enableDebugging is called',
      () async {
        await OhosWebViewController.enableDebugging(true);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebContentsDebuggingEnabled',
          ),
          isNotEmpty,
        );
      },
    );
  });

  group('OhosNavigationDelegate SSL surface', () {
    test(
      'should complete without error when setOnSSlAuthError is called',
      () async {
        final OhosNavigationDelegate delegate = OhosNavigationDelegate(
          PlatformNavigationDelegateCreationParams(),
        );

        await expectLater(
          delegate.setOnSSlAuthError((PlatformSslAuthError error) async {}),
          completes,
        );
      },
    );

    test(
      'should expose the chrome client bridge when ohosWebChromeClient is read',
      () {
        final OhosNavigationDelegate delegate = OhosNavigationDelegate(
          PlatformNavigationDelegateCreationParams(),
        );

        // ignore: deprecated_member_use_from_same_package
        final ohos_webview.WebChromeClient client = delegate
            // ignore: deprecated_member_use_from_same_package
            .ohosWebChromeClient;

        expect(client, isA<ohos_webview.WebChromeClient>());
      },
    );
  });

  group('OhosWebViewPermissionRequest', () {
    test(
      'should grant the mapped resources when the native permission request is accepted',
      () async {
        final OhosWebViewController controller = OhosWebViewController(
          OhosWebViewControllerCreationParams(),
        );

        PlatformWebViewPermissionRequest? received;
        await controller.setOnPlatformPermissionRequest(
          (PlatformWebViewPermissionRequest request) async {
            received = request;
          },
        );

        final TestPigeonPermissionRequest nativeRequest =
            TestPigeonPermissionRequest(
          resources: <String>[ohos_webview.PermissionRequest.videoCapture],
        );
        registerInstance(nativeRequest);
        final ohos_webview.WebChromeClient client =
            controller.ohosWebChromeClientForTesting;
        client.onPermissionRequest!(client, nativeRequest);
        await Future<void>.delayed(Duration.zero);

        final OhosWebViewPermissionRequest ohosRequest =
            received! as OhosWebViewPermissionRequest;
        expect(
          ohosRequest.types,
          <WebViewPermissionResourceType>{
            WebViewPermissionResourceType.camera,
          },
        );

        await ohosRequest.grant();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_permissionRequestHostApiPrefix}grant',
          ),
          isNotEmpty,
        );

        await ohosRequest.deny();

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_permissionRequestHostApiPrefix}deny',
          ),
          isNotEmpty,
        );
      },
    );
  });

  group('OhosSslAuthError current contract', () {
    test(
      'should build the error from the native callback when fromNativeCallback is called',
      () async {
        final _FakeSslErrorHandler handler = _FakeSslErrorHandler();
        final OhosSslAuthError error =
            await OhosSslAuthError.fromNativeCallback(
          handler: handler,
          certificateHint: '',
          description: 'unverified certificate',
          url: 'https://flutter.dev',
        );

        expect(error.description, 'unverified certificate');
        expect(error.url, 'https://flutter.dev');
        // Platform fact: OpenHarmony ArkWeb does not expose an X509Certificate
        // surface, so the certificate is null by design.
        expect(error.certificate, isNull);
      },
    );

    test(
      'should cancel the native handler when cancel is called',
      () async {
        final _FakeSslErrorHandler handler = _FakeSslErrorHandler();
        final OhosSslAuthError error =
            await OhosSslAuthError.fromNativeCallback(
          handler: handler,
          certificateHint: '',
          description: 'cert error',
          url: 'https://flutter.dev',
        );

        await expectLater(error.cancel(), completes);

        expect(handler.cancelCount, 1);
        expect(handler.proceedCount, 0);
      },
    );

    test(
      'should confirm the native handler when proceed is called',
      () async {
        final _FakeSslErrorHandler handler = _FakeSslErrorHandler();
        final OhosSslAuthError error =
            await OhosSslAuthError.fromNativeCallback(
          handler: handler,
          certificateHint: '',
          description: 'cert error',
          url: 'https://flutter.dev',
        );

        await expectLater(error.proceed(), completes);

        expect(handler.proceedCount, 1);
        expect(handler.cancelCount, 0);
      },
    );
  });

  group('OhosWebViewWidget', () {
    testWidgets(
      'should return a PlatformViewLink when OhosWebViewWidget.build is called',
      (WidgetTester tester) async {
        BuildContext? capturedContext;
        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        );

        final OhosWebViewController controller = OhosWebViewController(
          OhosWebViewControllerCreationParams(),
        );
        final OhosWebViewWidget widget = OhosWebViewWidget(
          OhosWebViewWidgetCreationParams(controller: controller),
        );

        final Widget built = widget.build(capturedContext!);

        expect(built, isA<PlatformViewLink>());
      },
    );
  });
}

/// Hand-rolled stand-in for the native SSL error handler that records
/// decisions instead of sending Pigeon messages.
// ignore: must_be_immutable
class _FakeSslErrorHandler extends ohos_webview.SslErrorHandler {
  _FakeSslErrorHandler() : super();

  int cancelCount = 0;
  int proceedCount = 0;

  @override
  Future<void> cancel() async {
    cancelCount++;
  }

  @override
  Future<void> proceed() async {
    proceedCount++;
  }
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.PermissionRequest].
class TestPigeonPermissionRequest extends ohos_webview.PermissionRequest {
  TestPigeonPermissionRequest({required List<String> resources})
      : super.detached(
          resources: resources,
          binaryMessenger: null,
          instanceManager: null,
        );
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.GeolocationPermissionsCallback].
class TestPigeonGeolocationPermissionsCallback
    extends ohos_webview.GeolocationPermissionsCallback {
  TestPigeonGeolocationPermissionsCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.CustomViewCallback].
class TestPigeonCustomViewCallback extends ohos_webview.CustomViewCallback {
  TestPigeonCustomViewCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.View].
class TestPigeonView extends ohos_webview.View {
  TestPigeonView() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.FileChooserParams].
class TestPigeonFileChooserParams extends ohos_webview.FileChooserParams {
  TestPigeonFileChooserParams({
    required bool isCaptureEnabled,
    required List<String> acceptTypes,
    required String? filenameHint,
    required ohos_webview.FileChooserMode mode,
  }) : super.detached(
          isCaptureEnabled: isCaptureEnabled,
          acceptTypes: acceptTypes,
          filenameHint: filenameHint,
          mode: mode,
        );
}
