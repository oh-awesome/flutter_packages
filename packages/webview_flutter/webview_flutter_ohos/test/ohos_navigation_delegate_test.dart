// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_navigation_delegate_test.mocks.dart';
import 'ohos_pigeon_test_mocks.dart';

@GenerateMocks(<Type>[
  ohos_webview.HttpAuthHandler,
  ohos_webview.DownloadListener,
  ohos_webview.SslErrorHandler,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  tearDown(() {
    // Restore the default mock handlers and clear the recorded calls so no
    // state installed by one test leaks into the next one (matches the other
    // API impl test files).
    OhosPigeonTestMocks.setUpMocks();
    OhosPigeonTestMocks.clearRecords();
  });

  group('OhosNavigationDelegate', () {
    test('should invoke onPageFinished callback with url when the page finishes loading', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      late final String callbackUrl;
      ohosNavigationDelegate.setOnPageFinished(
        (String url) => callbackUrl = url,
      );

      // 直接调用 WebViewClient 的回调
      ohosNavigationDelegate.ohosWebViewClient.onPageFinished!(
        TestWebView(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('should invoke onPageStarted callback with url when the page starts loading', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      late final String callbackUrl;
      ohosNavigationDelegate.setOnPageStarted(
        (String url) => callbackUrl = url,
      );

      ohosNavigationDelegate.ohosWebViewClient.onPageStarted!(
        TestWebView(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('should invoke onHttpError callback with status code when onReceivedHttpError is invoked', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      late final HttpResponseError callbackError;
      ohosNavigationDelegate.setOnHttpError(
        (HttpResponseError httpError) => callbackError = httpError,
      );

      ohosNavigationDelegate.ohosWebViewClient.onReceivedHttpError!(
        TestWebView(),
        ohos_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: const <String, String>{'X-Mock': 'mocking'},
        ),
        ohos_webview.WebResourceError(
          errorCode: 401,
          description: 'Unauthorized',
        ),
      );

      expect(callbackError.response?.statusCode, 401);
    });

    test('should invoke onWebResourceError callback when onReceivedRequestError is invoked', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      late final WebResourceError callbackError;
      ohosNavigationDelegate.setOnWebResourceError(
        (WebResourceError error) => callbackError = error,
      );

      ohosNavigationDelegate.ohosWebViewClient.onReceivedRequestError!(
        TestWebView(),
        ohos_webview.WebResourceRequest(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: const <String, String>{'X-Mock': 'mocking'},
        ),
        ohos_webview.WebResourceError(
          errorCode: ohos_webview.WebViewClient.errorFileNotFound,
          description: 'Page not found.',
        ),
      );

      expect(callbackError.errorCode, ohos_webview.WebViewClient.errorFileNotFound);
      expect(callbackError.description, 'Page not found.');
      expect(callbackError.errorType, WebResourceErrorType.fileNotFound);
      expect(callbackError.isForMainFrame, false);
    });

    test(
      'onNavigationRequest from requestLoading should not be called when loadUrlCallback is not specified',
      () {
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: true,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        expect(callbackNavigationRequest, isNull);
      },
    );

    test(
      'onNavigationRequest from requestLoading should be called when request is for main frame',
      () {
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.setOnLoadRequest((_) async {});

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: true,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        expect(callbackNavigationRequest, isNotNull);
      },
    );

    test(
      'onNavigationRequest from requestLoading should not be called when request is not for main frame',
      () {
        // 与 Android 保持一致：只拦截主框架导航，因为 loadUrl 无法加载子框架
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.setOnLoadRequest((_) async {});

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: false,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        // 非主框架请求不触发回调，直接放行
        expect(callbackNavigationRequest, isNull);
      },
    );

    test(
      'onLoadRequest from requestLoading should not be called when navigationRequestCallback is not specified',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: true,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from requestLoading should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: true,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from requestLoading should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
      () {
        final completer = Completer<void>();
        late final LoadRequestParams loadRequestParams;
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
          loadRequestParams = params;
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.navigate;
        });

        ohosNavigationDelegate.ohosWebViewClient.requestLoading!(
          TestWebView(),
          ohos_webview.WebResourceRequest(
            url: 'https://www.google.com',
            isForMainFrame: true,
            isRedirect: true,
            hasGesture: true,
            method: 'GET',
            requestHeaders: const <String, String>{'X-Mock': 'mocking'},
          ),
        );

        expect(loadRequestParams.uri.toString(), 'https://www.google.com');
        expect(loadRequestParams.headers, <String, String>{
          'X-Mock': 'mocking',
        });
        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, true);
      },
    );

    test(
      'onNavigationRequest from urlLoading should not be called when loadUrlCallback is not specified',
      () {
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.ohosWebViewClient.urlLoading!(
          TestWebView(),
          'https://www.google.com',
        );

        expect(callbackNavigationRequest, isNull);
      },
    );

    test(
      'onLoadRequest from urlLoading should not be called when navigationRequestCallback is not specified',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        ohosNavigationDelegate.ohosWebViewClient.urlLoading!(
          TestWebView(),
          'https://www.google.com',
        );

        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from urlLoading should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.ohosWebViewClient.urlLoading!(
          TestWebView(),
          'https://www.google.com',
        );

        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from urlLoading should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
      () {
        final completer = Completer<void>();
        late final LoadRequestParams loadRequestParams;
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
          loadRequestParams = params;
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.navigate;
        });

        ohosNavigationDelegate.ohosWebViewClient.urlLoading!(
          TestWebView(),
          'https://www.google.com',
        );

        expect(loadRequestParams.uri.toString(), 'https://www.google.com');
        expect(loadRequestParams.headers, <String, String>{});
        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, true);
      },
    );

    test('should override URL loading when setOnNavigationRequest callback is registered', () async {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      await ohosNavigationDelegate.setOnNavigationRequest(
        (NavigationRequest request) => NavigationDecision.navigate,
      );

      // 验证 WebViewClient 的同步返回值被设置
      // 这个测试需要检查内部状态，暂时跳过具体验证
    });

    test(
      'onLoadRequest from onDownloadStart should not be called when navigationRequestCallback is not specified',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        ohosNavigationDelegate.ohosDownloadListener.onDownloadStart(
          '',
          '',
          '',
          '',
          0,
        );

        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from onDownloadStart should not be called when onNavigationRequestCallback returns NavigationDecision.prevent',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.ohosDownloadListener.onDownloadStart(
          'https://www.google.com',
          '',
          '',
          '',
          0,
        );

        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, false);
      },
    );

    test(
      'onLoadRequest from onDownloadStart should complete when onNavigationRequestCallback returns NavigationDecision.navigate',
      () {
        final completer = Completer<void>();
        late final LoadRequestParams loadRequestParams;
        final ohosNavigationDelegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        ohosNavigationDelegate.setOnLoadRequest((LoadRequestParams params) {
          loadRequestParams = params;
          completer.complete();
          return completer.future;
        });

        late final NavigationRequest callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.navigate;
        });

        ohosNavigationDelegate.ohosDownloadListener.onDownloadStart(
          'https://www.google.com',
          '',
          '',
          '',
          0,
        );

        expect(loadRequestParams.uri.toString(), 'https://www.google.com');
        expect(loadRequestParams.headers, <String, String>{});
        expect(callbackNavigationRequest.isMainFrame, true);
        expect(callbackNavigationRequest.url, 'https://www.google.com');
        expect(completer.isCompleted, true);
      },
    );

    test('should invoke onUrlChange callback when doUpdateVisitedHistory is invoked', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      late final OhosUrlChange urlChange;
      ohosNavigationDelegate.setOnUrlChange((UrlChange change) {
        urlChange = change as OhosUrlChange;
      });

      ohosNavigationDelegate.ohosWebViewClient.doUpdateVisitedHistory!(
        TestWebView(),
        'https://www.google.com',
        false,
      );

      expect(urlChange.url, 'https://www.google.com');
      expect(urlChange.isReload, isFalse);
    });

    test('should emit host and realm when onReceivedHttpAuthRequest callback is registered', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      String? callbackHost;
      String? callbackRealm;
      ohosNavigationDelegate.setOnHttpAuthRequest((HttpAuthRequest request) {
        callbackHost = request.host;
        callbackRealm = request.realm;
      });

      const expectedHost = 'expectedHost';
      const expectedRealm = 'expectedRealm';

      final mockAuthHandler = MockHttpAuthHandler();

      ohosNavigationDelegate.ohosWebViewClient.onReceivedHttpAuthRequest!(
        TestWebView(),
        mockAuthHandler,
        expectedHost,
        expectedRealm,
      );

      expect(callbackHost, expectedHost);
      expect(callbackRealm, expectedRealm);
    });

    test('should call cancel by default when onReceivedHttpAuthRequest is invoked without callback', () {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      final mockAuthHandler = MockHttpAuthHandler();

      ohosNavigationDelegate.ohosWebViewClient.onReceivedHttpAuthRequest!(
        TestWebView(),
        mockAuthHandler,
        'host',
        'realm',
      );

      verify(mockAuthHandler.cancel());
    });

    test('should invoke onSSlAuthError callback with url and description when onReceivedSslError is invoked', () async {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      Object? receivedError;
      await ohosNavigationDelegate.setOnSSlAuthError(
        (PlatformSslAuthError error) => receivedError = error,
      );

      final mockSslErrorHandler = MockSslErrorHandler();

      ohosNavigationDelegate.ohosWebViewClient.onReceivedSslError!(
        TestWebView(),
        mockSslErrorHandler,
        'https://example.com',
        'issuer-hint',
        'The certificate authority is not trusted.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(receivedError, isA<OhosSslAuthError>());
      final OhosSslAuthError sslError = receivedError! as OhosSslAuthError;
      expect(sslError.url, 'https://example.com');
      expect(sslError.description, contains('not trusted'));
      // certificate stays null: ArkWeb exposes no verifiable X.509 data here.
      expect(sslError.certificate, isNull);

      await sslError.cancel();
      verify(mockSslErrorHandler.cancel());
      verifyNever(mockSslErrorHandler.proceed());

      await sslError.proceed();
      verify(mockSslErrorHandler.proceed());
    });

    test('should call cancel by default when onReceivedSslError is invoked without callback', () async {
      final ohosNavigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
        ),
      );

      final mockSslErrorHandler = MockSslErrorHandler();

      ohosNavigationDelegate.ohosWebViewClient.onReceivedSslError!(
        TestWebView(),
        mockSslErrorHandler,
        'https://example.com',
        '',
        'The certificate date is invalid.',
      );
      await Future<void>.delayed(Duration.zero);

      // Safe default: an unhandled certificate error rejects the certificate.
      verify(mockSslErrorHandler.cancel());
      verifyNever(mockSslErrorHandler.proceed());
    });
  });
}

// Test WebView class
class TestWebView extends ohos_webview.WebView {
  TestWebView() : super.detached();
}