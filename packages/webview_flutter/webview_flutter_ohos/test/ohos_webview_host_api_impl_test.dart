// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Direct coverage of `WebViewHostApiImpl` (24 uncovered items from the XTS
// report) plus the WebView-related public bridges the report listed:
// `WebViewProxy.createWebView`/`setWebContentsDebuggingEnabled`,
// `OhosWebViewProxy.setWebContentsDebuggingEnabled` and the legacy
// `OhosWebView.clearCookies`. Every case instantiates the Impl itself,
// registers a real instance identifier and asserts on the recorded Pigeon
// channel call (identifier, arguments, return value) instead of only
// exercising a higher-level wrapper.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/legacy/webview_ohos.dart'
    as legacy_webview;
import 'package:webview_flutter_ohos/src/legacy/webview_ohos_cookie_manager.dart'
    as legacy_cookie_manager;
import 'package:webview_flutter_ohos/src/ohos_proxy.dart' as ohos_proxy;
import 'package:webview_flutter_ohos/src/legacy/webview_ohos_widget.dart'
    as legacy_widget;
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart'
    as api_impls;
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart'
    as legacy_pi;

import 'ohos_pigeon_test_mocks.dart';

const String _webViewHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebView].
class TestPigeonWebView extends ohos_webview.WebView {
  TestPigeonWebView() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebViewClient].
class TestPigeonWebViewClient extends ohos_webview.WebViewClient {
  TestPigeonWebViewClient() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebChromeClient].
class TestPigeonWebChromeClient extends ohos_webview.WebChromeClient {
  TestPigeonWebChromeClient() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.JavaScriptChannel].
class TestPigeonJavaScriptChannel extends ohos_webview.JavaScriptChannel {
  TestPigeonJavaScriptChannel(String channelName,
      {required void Function(String message) postMessage})
      : super.detached(channelName, postMessage: postMessage);
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.DownloadListener].
class TestPigeonDownloadListener extends ohos_webview.DownloadListener {
  TestPigeonDownloadListener()
      : super.detached(
          onDownloadStart:
              (String url, String userAgent, String contentDisposition,
                      String mimetype, int contentLength) {},
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late api_impls.WebViewHostApiImpl api;
  late InstanceManager instanceManager;

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
    api = api_impls.WebViewHostApiImpl();
    instanceManager = ohos_webview.OhosObject.globalInstanceManager;
  });

  tearDown(() {
    // Restore the default mock handlers so an error/return-value override
    // installed by one test cannot leak into the next one.
    OhosPigeonTestMocks.setUpMocks();
    OhosPigeonTestMocks.clearRecords();
  });

  group('WebViewHostApiImpl.createFromInstance', () {
    test('should send create with the assigned identifier', () async {
      final TestPigeonWebView webView = TestPigeonWebView();

      await api.createFromInstance(webView);

      final int assignedId = instanceManager.getIdentifier(webView)!;
      expect(
        OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}create',
        )!.arguments[0],
        assignedId,
      );
    });
  });

  group('WebViewHostApiImpl.loadDataFromInstance', () {
    test('should send loadData with instance id, data, mime type and encoding',
        () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      await api.loadDataFromInstance(
        webView,
        '<html>data</html>',
        'text/html',
        'utf-8',
      );

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}loadData',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], '<html>data</html>');
      expect(args[2], 'text/html');
      expect(args[3], 'utf-8');
    });

    test(
      'should propagate the platform error when the channel replies with an error',
      () async {
        final TestPigeonWebView webView = TestPigeonWebView();
        instanceManager.addDartCreatedInstance(webView);

        OhosPigeonTestMocks.overrideWithError(
          '${_webViewHostApiPrefix}loadData',
          'loadData-failed',
          'native rejected the payload',
        );

        await expectLater(
          api.loadDataFromInstance(webView, '<html>bad</html>', null, null),
          throwsA(isA<PlatformException>()),
        );
      },
    );
  });

  group('WebViewHostApiImpl.loadDataWithBaseUrlFromInstance', () {
    test('should send loadDataWithBaseUrl with every argument', () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      await api.loadDataWithBaseUrlFromInstance(
        webView,
        'https://flutter.dev',
        '<html>base</html>',
        'text/html',
        'utf-8',
        'https://history.dev',
      );

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}loadDataWithBaseUrl',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], 'https://flutter.dev');
      expect(args[2], '<html>base</html>');
      expect(args[3], 'text/html');
      expect(args[4], 'utf-8');
      expect(args[5], 'https://history.dev');
    });

    test(
      'should send loadDataWithBaseUrl with null optional arguments',
      () async {
        final TestPigeonWebView webView = TestPigeonWebView();
        final int id = instanceManager.addDartCreatedInstance(webView);

        await api.loadDataWithBaseUrlFromInstance(
          webView,
          null,
          '<html>plain</html>',
          null,
          null,
          null,
        );

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}loadDataWithBaseUrl',
        )!.arguments;
        expect(args[0], id);
        expect(args[1], isNull);
      },
    );
  });

  group('WebViewHostApiImpl.loadUrlFromInstance', () {
    test('should send loadUrl with instance id, url and headers', () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      await api.loadUrlFromInstance(
        webView,
        'https://flutter.dev',
        <String, String>{'token': 'abc'},
      );

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}loadUrl',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], 'https://flutter.dev');
      expect(args[2], <String, String>{'token': 'abc'});
    });
  });

  group('WebViewHostApiImpl.postUrlFromInstance', () {
    test('should send postUrl with instance id, url and byte data', () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      await api.postUrlFromInstance(
        webView,
        'https://flutter.dev',
        Uint8List.fromList(<int>[1, 2, 3]),
      );

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}postUrl',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], 'https://flutter.dev');
      expect(args[2], Uint8List.fromList(<int>[1, 2, 3]));
    });
  });

  group('WebViewHostApiImpl getters', () {
    late TestPigeonWebView webView;

    setUp(() {
      webView = TestPigeonWebView();
      instanceManager.addDartCreatedInstance(webView);
    });

    test('should return the url from getUrlFromInstance', () async {
      expect(await api.getUrlFromInstance(webView), 'https://flutter.dev');
    });

    test('should return true from canGoBackFromInstance', () async {
      expect(await api.canGoBackFromInstance(webView), true);
    });

    test('should return true from canGoForwardFromInstance', () async {
      expect(await api.canGoForwardFromInstance(webView), true);
    });

    test('should send goBackFromInstance with the instance id', () async {
      final int id = instanceManager.getIdentifier(webView)!;
      await api.goBackFromInstance(webView);
      expect(
        OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}goBack',
        )!.arguments[0],
        id,
      );
    });

    test('should send goForwardFromInstance with the instance id', () async {
      final int id = instanceManager.getIdentifier(webView)!;
      await api.goForwardFromInstance(webView);
      expect(
        OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}goForward',
        )!.arguments[0],
        id,
      );
    });

    test('should send reloadFromInstance with the instance id', () async {
      final int id = instanceManager.getIdentifier(webView)!;
      await api.reloadFromInstance(webView);
      expect(
        OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}reload',
        )!.arguments[0],
        id,
      );
    });

    test('should return the title from getTitleFromInstance', () async {
      expect(await api.getTitleFromInstance(webView), 'Page Title');
    });

    test('should return 100 from getScrollXFromInstance', () async {
      expect(await api.getScrollXFromInstance(webView), 100);
    });

    test('should return 200 from getScrollYFromInstance', () async {
      expect(await api.getScrollYFromInstance(webView), 200);
    });
  });

  group('WebViewHostApiImpl.clearCacheFromInstance', () {
    test('should send clearCache with instance id and disk flag', () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      await api.clearCacheFromInstance(webView, true);

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}clearCache',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], true);
    });
  });

  group('WebViewHostApiImpl.evaluateJavascriptFromInstance', () {
    test('should send evaluateJavascript with instance id and script',
        () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int id = instanceManager.addDartCreatedInstance(webView);

      final String? result =
          await api.evaluateJavascriptFromInstance(webView, '1 + 1');

      expect(result, 'result');
      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}evaluateJavascript',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], '1 + 1');
    });
  });

  group('WebViewHostApiImpl scrolling', () {
    late TestPigeonWebView webView;

    setUp(() {
      webView = TestPigeonWebView();
      instanceManager.addDartCreatedInstance(webView);
    });

    test('should send scrollToFromInstance with instance id, x and y',
        () async {
      final int id = instanceManager.getIdentifier(webView)!;
      await api.scrollToFromInstance(webView, 10, 20);
      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}scrollTo',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], 10);
      expect(args[2], 20);
    });

    test('should send scrollByFromInstance with instance id, x and y',
        () async {
      final int id = instanceManager.getIdentifier(webView)!;
      await api.scrollByFromInstance(webView, 5, 15);
      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}scrollBy',
      )!.arguments;
      expect(args[0], id);
      expect(args[1], 5);
      expect(args[2], 15);
    });

    test(
      'should return an Offset built from the WebViewPoint when getScrollPositionFromInstance is called',
      () async {
        expect(
          await api.getScrollPositionFromInstance(webView),
          const Offset(100.0, 200.0),
        );
      },
    );
  });

  group('WebViewHostApiImpl client and channel wiring', () {
    late TestPigeonWebView webView;

    setUp(() {
      webView = TestPigeonWebView();
      instanceManager.addDartCreatedInstance(webView);
    });

    test('should send both identifiers from setWebViewClientFromInstance',
        () async {
      final TestPigeonWebViewClient client = TestPigeonWebViewClient();
      final int clientId = instanceManager.addDartCreatedInstance(client);

      await api.setWebViewClientFromInstance(webView, client);

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}setWebViewClient',
      )!.arguments;
      expect(args[0], instanceManager.getIdentifier(webView));
      expect(args[1], clientId);
    });

    test('should send both identifiers from addJavaScriptChannelFromInstance',
        () async {
      final TestPigeonJavaScriptChannel channel = TestPigeonJavaScriptChannel(
        'test_channel',
        postMessage: (String message) {},
      );
      final int channelId = instanceManager.addDartCreatedInstance(channel);

      await api.addJavaScriptChannelFromInstance(webView, channel);

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}addJavaScriptChannel',
      )!.arguments;
      expect(args[0], instanceManager.getIdentifier(webView));
      expect(args[1], channelId);
    });

    test('should send both identifiers from removeJavaScriptChannelFromInstance',
        () async {
      final TestPigeonJavaScriptChannel channel = TestPigeonJavaScriptChannel(
        'test_channel',
        postMessage: (String message) {},
      );
      final int channelId = instanceManager.addDartCreatedInstance(channel);

      await api.removeJavaScriptChannelFromInstance(webView, channel);

      final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
        '${_webViewHostApiPrefix}removeJavaScriptChannel',
      )!.arguments;
      expect(args[0], instanceManager.getIdentifier(webView));
      expect(args[1], channelId);
    });

    test(
      'should send the listener identifier from setDownloadListenerFromInstance',
      () async {
        final TestPigeonDownloadListener listener = TestPigeonDownloadListener();
        final int listenerId = instanceManager.addDartCreatedInstance(listener);

        await api.setDownloadListenerFromInstance(webView, listener);

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}setDownloadListener',
        )!.arguments;
        expect(args[0], instanceManager.getIdentifier(webView));
        expect(args[1], listenerId);
      },
    );

    test(
      'should send a null listener when setDownloadListenerFromInstance receives null',
      () async {
        await api.setDownloadListenerFromInstance(webView, null);

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}setDownloadListener',
        )!.arguments;
        expect(args[0], instanceManager.getIdentifier(webView));
        expect(args[1], isNull);
      },
    );

    test(
      'should send the client identifier from setWebChromeClientFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int clientId = instanceManager.addDartCreatedInstance(client);

        await api.setWebChromeClientFromInstance(webView, client);

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}setWebChromeClient',
        )!.arguments;
        expect(args[0], instanceManager.getIdentifier(webView));
        expect(args[1], clientId);
      },
    );

    test(
      'should send a null client when setWebChromeClientFromInstance receives null',
      () async {
        await api.setWebChromeClientFromInstance(webView, null);

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}setWebChromeClient',
        )!.arguments;
        expect(args[0], instanceManager.getIdentifier(webView));
        expect(args[1], isNull);
      },
    );
  });

  group('WebView.loadData base64 encoded html', () {
    test(
      'should load base64 encoded html through loadDataFromInstance unchanged',
      () async {
        // Reproduce the documented flow from the loadData dartdoc sample:
        // encode the html, then load it through the Impl. The encoded payload
        // must reach the channel byte-for-byte with the base64 encoding flag.
        final String unencodedHtml = '<html><body>hello</body></html>';
        final String encodedHtml = base64.encode(utf8.encode(unencodedHtml));

        final TestPigeonWebView webView = TestPigeonWebView();
        final int id = instanceManager.addDartCreatedInstance(webView);
        await api.loadDataFromInstance(
          webView,
          encodedHtml,
          'text/html',
          'base64',
        );

        final List<dynamic> args = OhosPigeonTestMocks.getLastCallForChannel(
          '${_webViewHostApiPrefix}loadData',
        )!.arguments;
        expect(args[0], id);
        expect(args[1], encodedHtml);
        expect(args[3], 'base64');
      },
    );
  });

  group('WebViewProxy (legacy)', () {
    test('should construct a registered WebView when createWebView is called',
        () async {
      final legacy_widget.WebViewProxy proxy = const legacy_widget.WebViewProxy();

      final ohos_webview.WebView webView = proxy.createWebView();

      expect(
        instanceManager.getIdentifier(webView),
        isNotNull,
      );
      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}create',
        ).isNotEmpty,
        true,
      );
    });

    test(
      'should send setWebContentsDebuggingEnabled when called on the legacy proxy',
      () async {
        final legacy_widget.WebViewProxy proxy = const legacy_widget.WebViewProxy();

        await proxy.setWebContentsDebuggingEnabled(true);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebContentsDebuggingEnabled',
          ).isNotEmpty,
          true,
        );
      },
    );
  });

  group('OhosWebViewProxy', () {
    test(
      'should send setWebContentsDebuggingEnabled when called on the ohos proxy',
      () async {
        const ohos_proxy.OhosWebViewProxy proxy = ohos_proxy.OhosWebViewProxy();

        await proxy.setWebContentsDebuggingEnabled(false);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}setWebContentsDebuggingEnabled',
          ).isNotEmpty,
          true,
        );
      },
    );
  });

  group('OhosWebView.clearCookies (legacy)', () {
    test(
      'should delegate to the registered cookie manager platform when clearCookies is called',
      () async {
        legacy_pi.WebViewCookieManagerPlatform.instance =
            legacy_cookie_manager.WebViewOhosCookieManager();
        final legacy_webview.OhosWebView ohosWebView =
            legacy_webview.OhosWebView();

        final bool cleared = await ohosWebView.clearCookies();

        expect(cleared, true);
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.removeAllCookies',
          ).isNotEmpty,
          true,
        );
      },
    );
  });
}
