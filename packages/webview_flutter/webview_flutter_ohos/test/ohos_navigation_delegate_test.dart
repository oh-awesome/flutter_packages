// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webkit.g.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webkit_constants.dart';
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_navigation_delegate_test.mocks.dart';

@GenerateMocks(<Type>[
  ohos_webview.HttpAuthHandler,
  ohos_webview.DownloadListener,
  ohos_webview.SslCertificate,
  ohos_webview.SslError,
  ohos_webview.SslErrorHandler,
  ohos_webview.X509Certificate,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ohosNavigationDelegate', () {
    test('onPageFinished', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      late final String callbackUrl;
      ohosNavigationDelegate.setOnPageFinished(
        (String url) => callbackUrl = url,
      );

      CapturingWebViewClient.lastCreatedDelegate.onPageFinished!(
        CapturingWebViewClient(),
        TestWebView(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('onPageStarted', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      late final String callbackUrl;
      ohosNavigationDelegate.setOnPageStarted(
        (String url) => callbackUrl = url,
      );

      CapturingWebViewClient.lastCreatedDelegate.onPageStarted!(
        CapturingWebViewClient(),
        TestWebView(),
        'https://www.google.com',
      );

      expect(callbackUrl, 'https://www.google.com');
    });

    test('onHttpError from onReceivedHttpError', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      late final HttpResponseError callbackError;
      ohosNavigationDelegate.setOnHttpError(
        (HttpResponseError httpError) => callbackError = httpError,
      );

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpError!(
        CapturingWebViewClient(),
        TestWebView(),
        ohos_webview.WebResourceRequest.pigeon_detached(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: const <String, String>{'X-Mock': 'mocking'},
        ),
        ohos_webview.WebResourceResponse.pigeon_detached(statusCode: 401),
      );

      expect(callbackError.response?.statusCode, 401);
    });

    test('onWebResourceError from onReceivedRequestError', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      late final WebResourceError callbackError;
      ohosNavigationDelegate.setOnWebResourceError(
        (WebResourceError error) => callbackError = error,
      );

      CapturingWebViewClient.lastCreatedDelegate.onReceivedRequestError!(
        CapturingWebViewClient(),
        TestWebView(),
        ohos_webview.WebResourceRequest.pigeon_detached(
          url: 'https://www.google.com',
          isForMainFrame: false,
          isRedirect: true,
          hasGesture: true,
          method: 'GET',
          requestHeaders: const <String, String>{'X-Mock': 'mocking'},
        ),
        ohos_webview.WebResourceError.pigeon_detached(
          errorCode: WebViewClientConstants.errorFileNotFound,
          description: 'Page not found.',
        ),
      );

      expect(callbackError.errorCode, WebViewClientConstants.errorFileNotFound);
      expect(callbackError.description, 'Page not found.');
      expect(callbackError.errorType, WebResourceErrorType.fileNotFound);
      expect(callbackError.isForMainFrame, false);
    });

    test(
      'onNavigationRequest from requestLoading should not be called when loadUrlCallback is not specified',
      () {
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.setOnLoadRequest((_) async {});

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        ohosNavigationDelegate.setOnLoadRequest((_) async {});

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
            url: 'https://www.google.com',
            isForMainFrame: false,
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
      'onLoadRequest from requestLoading should not be called when navigationRequestCallback is not specified',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingWebViewClient.lastCreatedDelegate.requestLoading!(
          CapturingWebViewClient(),
          TestWebView(),
          ohos_webview.WebResourceRequest.pigeon_detached(
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        NavigationRequest? callbackNavigationRequest;
        ohosNavigationDelegate.setOnNavigationRequest((
          NavigationRequest navigationRequest,
        ) {
          callbackNavigationRequest = navigationRequest;
          return NavigationDecision.prevent;
        });

        CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
          CapturingWebViewClient(),
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
          CapturingWebViewClient(),
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
          CapturingWebViewClient(),
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingWebViewClient.lastCreatedDelegate.urlLoading!(
          CapturingWebViewClient(),
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

    test('setOnNavigationRequest should override URL loading', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      ohosNavigationDelegate.setOnNavigationRequest(
        (NavigationRequest request) => NavigationDecision.navigate,
      );

      expect(
        CapturingWebViewClient
            .lastCreatedDelegate
            .synchronousReturnValueForShouldOverrideUrlLoading,
        isTrue,
      );
    });

    test(
      'onLoadRequest from onDownloadStart should not be called when navigationRequestCallback is not specified',
      () {
        final completer = Completer<void>();
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
        );

        ohosNavigationDelegate.setOnLoadRequest((_) {
          completer.complete();
          return completer.future;
        });

        CapturingDownloadListener.lastCreatedListener.onDownloadStart(
          MockDownloadListener(),
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingDownloadListener.lastCreatedListener.onDownloadStart(
          MockDownloadListener(),
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
        final ohosNavigationDelegate = ohosNavigationDelegate(
          _buildCreationParams(),
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

        CapturingDownloadListener.lastCreatedListener.onDownloadStart(
          MockDownloadListener(),
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

    test('onUrlChange', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      late final ohosUrlChange urlChange;
      ohosNavigationDelegate.setOnUrlChange((UrlChange change) {
        urlChange = change as ohosUrlChange;
      });

      CapturingWebViewClient.lastCreatedDelegate.doUpdateVisitedHistory!(
        CapturingWebViewClient(),
        TestWebView(),
        'https://www.google.com',
        false,
      );

      expect(urlChange.url, 'https://www.google.com');
      expect(urlChange.isReload, isFalse);
    });

    test('onReceivedHttpAuthRequest emits host and realm', () {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      String? callbackHost;
      String? callbackRealm;
      ohosNavigationDelegate.setOnHttpAuthRequest((HttpAuthRequest request) {
        callbackHost = request.host;
        callbackRealm = request.realm;
      });

      const expectedHost = 'expectedHost';
      const expectedRealm = 'expectedRealm';

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpAuthRequest!(
        CapturingWebViewClient(),
        TestWebView(),
        ohos_webview.HttpAuthHandler.pigeon_detached(),
        expectedHost,
        expectedRealm,
      );

      expect(callbackHost, expectedHost);
      expect(callbackRealm, expectedRealm);
    });

    test('onReceivedHttpAuthRequest calls cancel by default', () {
      ohosNavigationDelegate(_buildCreationParams());

      final mockAuthHandler = MockHttpAuthHandler();

      CapturingWebViewClient.lastCreatedDelegate.onReceivedHttpAuthRequest!(
        CapturingWebViewClient(),
        TestWebView(),
        mockAuthHandler,
        'host',
        'realm',
      );

      verify(mockAuthHandler.cancel());
    });

    test('setOnSSlAuthError', () async {
      final ohosNavigationDelegate = ohosNavigationDelegate(
        _buildCreationParams(),
      );

      final errorCompleter = Completer<PlatformSslAuthError>();
      await ohosNavigationDelegate.setOnSSlAuthError((
        PlatformSslAuthError error,
      ) {
        errorCompleter.complete(error);
      });

      final certificateData = Uint8List(0);
      const url = 'https://google.com';

      final mockSslError = MockSslError();
      when(mockSslError.url).thenReturn(url);
      when(
        mockSslError.getPrimaryError(),
      ).thenAnswer((_) async => ohos_webview.SslErrorType.dateInvalid);
      final mockSslCertificate = MockSslCertificate();
      final mockX509Certificate = MockX509Certificate();
      when(
        mockX509Certificate.getEncoded(),
      ).thenAnswer((_) async => certificateData);
      when(
        mockSslCertificate.getX509Certificate(),
      ).thenAnswer((_) async => mockX509Certificate);
      when(mockSslError.certificate).thenReturn(mockSslCertificate);

      final mockSslErrorHandler = MockSslErrorHandler();

      CapturingWebViewClient.lastCreatedDelegate.onReceivedSslError!(
        CapturingWebViewClient(),
        TestWebView(),
        mockSslErrorHandler,
        mockSslError,
      );

      final error = await errorCompleter.future as ohosSslAuthError;
      expect(error.certificate?.data, certificateData);
      expect(error.description, 'The date of the certificate is invalid.');
      expect(error.url, url);

      await error.proceed();
      verify(mockSslErrorHandler.proceed());

      clearInteractions(mockSslErrorHandler);

      await error.cancel();
      verify(mockSslErrorHandler.cancel());
    });

    test('setOnSSlAuthError calls cancel by default', () async {
      ohosNavigationDelegate(_buildCreationParams());

      final mockSslErrorHandler = MockSslErrorHandler();

      CapturingWebViewClient.lastCreatedDelegate.onReceivedSslError!(
        CapturingWebViewClient(),
        TestWebView(),
        mockSslErrorHandler,
        MockSslError(),
      );

      verify(mockSslErrorHandler.cancel());
    });
  });
}

ohosNavigationDelegateCreationParams _buildCreationParams() {
  ohos_webview.PigeonOverrides.webViewClient_new =
      CapturingWebViewClient.new;
  ohos_webview.PigeonOverrides.webChromeClient_new =
      CapturingWebChromeClient.new;
  ohos_webview.PigeonOverrides.downloadListener_new =
      CapturingDownloadListener.new;
  return ohosNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
    const PlatformNavigationDelegateCreationParams(),
  );
}

// Records the last created instance of itself.
// ignore: must_be_immutable
class CapturingWebViewClient extends ohos_webview.WebViewClient {
  CapturingWebViewClient({
    super.onPageFinished,
    super.onPageStarted,
    super.onReceivedHttpError,
    super.onReceivedHttpAuthRequest,
    super.onReceivedRequestErrorCompat,
    super.doUpdateVisitedHistory,
    super.onReceivedRequestError,
    super.requestLoading,
    super.urlLoading,
    super.onFormResubmission,
    super.onLoadResource,
    super.onPageCommitVisible,
    super.onReceivedClientCertRequest,
    super.onReceivedLoginRequest,
    super.onReceivedSslError,
    super.onScaleChanged,
  }) : super.pigeon_detached() {
    lastCreatedDelegate = this;
  }

  static CapturingWebViewClient lastCreatedDelegate = CapturingWebViewClient();

  bool synchronousReturnValueForShouldOverrideUrlLoading = false;

  @override
  Future<void> setSynchronousReturnValueForShouldOverrideUrlLoading(
    bool value,
  ) async {
    synchronousReturnValueForShouldOverrideUrlLoading = value;
  }
}

// Records the last created instance of itself.
class CapturingWebChromeClient extends ohos_webview.WebChromeClient {
  CapturingWebChromeClient({
    super.onProgressChanged,
    required super.onShowFileChooser,
    super.onGeolocationPermissionsShowPrompt,
    super.onGeolocationPermissionsHidePrompt,
    super.onShowCustomView,
    super.onHideCustomView,
    super.onPermissionRequest,
    super.onConsoleMessage,
    super.onJsAlert,
    required super.onJsConfirm,
    super.onJsPrompt,
  }) : super.pigeon_detached() {
    lastCreatedDelegate = this;
  }

  static CapturingWebChromeClient lastCreatedDelegate =
      CapturingWebChromeClient(
        onJsConfirm: (_, __, ___, ____) async => false,
        onShowFileChooser: (_, __, ___) async => <String>[],
      );
}

// Records the last created instance of itself.
class CapturingDownloadListener extends ohos_webview.DownloadListener {
  CapturingDownloadListener({required super.onDownloadStart})
    : super.pigeon_detached() {
    lastCreatedListener = this;
  }

  static CapturingDownloadListener lastCreatedListener =
      CapturingDownloadListener(
        onDownloadStart: (_, __, ___, ____, _____, ______) {},
      );
}

class TestWebView extends ohos_webview.WebView {
  TestWebView() : super.pigeon_detached();
}
