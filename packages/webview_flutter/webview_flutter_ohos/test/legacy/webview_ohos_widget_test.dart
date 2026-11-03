// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/legacy/webview_ohos_widget.dart';
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'webview_ohos_widget_test.mocks.dart';

@GenerateMocks(<Type>[
  ohos_webview.FlutterAssetManager,
  ohos_webview.WebSettings,
  ohos_webview.WebStorage,
  ohos_webview.WebView,
  ohos_webview.WebResourceRequest,
  ohos_webview.DownloadListener,
  WebViewOhosJavaScriptChannel,
  ohos_webview.WebChromeClient,
  ohos_webview.WebViewClient,
  JavascriptChannelRegistry,
  WebViewPlatformCallbacksHandler,
  WebViewProxy,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewOhosWidget', () {
    late MockFlutterAssetManager mockFlutterAssetManager;
    late MockWebView mockWebView;
    late MockWebSettings mockWebSettings;
    late MockWebStorage mockWebStorage;
    late MockWebViewProxy mockWebViewProxy;

    late MockWebViewPlatformCallbacksHandler mockCallbacksHandler;
    late MockWebViewClient mockWebViewClient;
    late ohos_webview.DownloadListener downloadListener;
    late ohos_webview.WebChromeClient webChromeClient;

    late MockJavascriptChannelRegistry mockJavascriptChannelRegistry;

    late WebViewOhosPlatformController testController;

    setUp(() {
      mockFlutterAssetManager = MockFlutterAssetManager();
      mockWebView = MockWebView();
      mockWebSettings = MockWebSettings();
      mockWebStorage = MockWebStorage();
      mockWebViewClient = MockWebViewClient();
      when(mockWebView.settings).thenReturn(mockWebSettings);

      mockWebViewProxy = MockWebViewProxy();
      when(mockWebViewProxy.createWebView()).thenReturn(mockWebView);
      when(
        mockWebViewProxy.createWebViewClient(
          onPageStarted: anyNamed('onPageStarted'),
          onPageFinished: anyNamed('onPageFinished'),
          onReceivedRequestError: anyNamed('onReceivedRequestError'),
          requestLoading: anyNamed('requestLoading'),
          urlLoading: anyNamed('urlLoading'),
          // OHOS WebViewClient 没有 onReceivedSslError, onFormResubmission, onReceivedClientCertRequest 参数
        ),
      ).thenReturn(mockWebViewClient);

      mockCallbacksHandler = MockWebViewPlatformCallbacksHandler();
      mockJavascriptChannelRegistry = MockJavascriptChannelRegistry();
    });

    // Builds a OhosWebViewWidget with default parameters.
    Future<void> buildWidget(
      WidgetTester tester, {
      CreationParams? creationParams,
      bool hasNavigationDelegate = false,
      bool hasProgressTracking = false,
      bool useHybridComposition = false,
    }) async {
      await tester.pumpWidget(
        WebViewOhosWidget(
          creationParams:
              creationParams ??
              CreationParams(
                webSettings: WebSettings(
                  userAgent: const WebSetting<String?>.absent(),
                  hasNavigationDelegate: hasNavigationDelegate,
                  hasProgressTracking: hasProgressTracking,
                ),
              ),
          callbacksHandler: mockCallbacksHandler,
          javascriptChannelRegistry: mockJavascriptChannelRegistry,
          webViewProxy: mockWebViewProxy,
          flutterAssetManager: mockFlutterAssetManager,
          webStorage: mockWebStorage,
          onBuildWidget: (WebViewOhosPlatformController controller) {
            testController = controller;
            return Container();
          },
        ),
      );

      mockWebViewClient = testController.webViewClient as MockWebViewClient;
      downloadListener = testController.downloadListener;
      webChromeClient = testController.webChromeClient;
    }

    testWidgets('WebViewOhosWidget', (WidgetTester tester) async {
      await buildWidget(tester);

      verify(mockWebSettings.setDomStorageEnabled(true));
      verify(mockWebSettings.setJavaScriptCanOpenWindowsAutomatically(true));
      verify(mockWebSettings.setSupportMultipleWindows(true));
      verify(mockWebSettings.setLoadWithOverviewMode(true));
      verify(mockWebSettings.setUseWideViewPort(true));
      verify(mockWebSettings.setDisplayZoomControls(false));
      verify(mockWebSettings.setBuiltInZoomControls(true));

      verifyInOrder(<Future<void>>[
        mockWebView.setDownloadListener(downloadListener),
        mockWebView.setWebChromeClient(webChromeClient),
        mockWebView.setWebViewClient(mockWebViewClient),
      ]);
    });

    testWidgets('Create Widget with Hybrid Composition', (
      WidgetTester tester,
    ) async {
      await buildWidget(tester, useHybridComposition: true);
      verify(mockWebViewProxy.createWebView());
    });

    group('CreationParams', () {
      testWidgets('initialUrl', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            initialUrl: 'https://www.google.com',
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );
        verify(
          mockWebView.loadUrl('https://www.google.com', <String, String>{}),
        );
      });

      testWidgets('userAgent', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            userAgent: 'MyUserAgent',
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setUserAgentString('MyUserAgent'));
      });

      testWidgets('autoMediaPlaybackPolicy true', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setMediaPlaybackRequiresUserGesture(any));
      });

      testWidgets('autoMediaPlaybackPolicy false', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            autoMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        verify(mockWebSettings.setMediaPlaybackRequiresUserGesture(false));
      });

      testWidgets('javascriptChannelNames', (WidgetTester tester) async {
        await buildWidget(
          tester,
          creationParams: CreationParams(
            javascriptChannelNames: <String>{'a', 'b'},
            webSettings: WebSettings(
              userAgent: const WebSetting<String?>.absent(),
              hasNavigationDelegate: false,
            ),
          ),
        );

        final List<ohos_webview.JavaScriptChannel> javaScriptChannels =
            verify(
              mockWebView.addJavaScriptChannel(captureAny),
            ).captured.cast<ohos_webview.JavaScriptChannel>();
        expect(javaScriptChannels[0].channelName, 'a');
        expect(javaScriptChannels[1].channelName, 'b');
      });

      group('WebSettings', () {
        testWidgets('javascriptMode', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                javascriptMode: JavascriptMode.unrestricted,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setJavaScriptEnabled(true));
        });

        testWidgets('hasNavigationDelegate', (WidgetTester tester) async {
          final mockWebViewClient = MockWebViewClient();
          when(
            mockWebViewProxy.createWebViewClient(
              onPageStarted: anyNamed('onPageStarted'),
              onPageFinished: anyNamed('onPageFinished'),
              onReceivedRequestError: anyNamed('onReceivedRequestError'),
              requestLoading: anyNamed('requestLoading'),
              urlLoading: anyNamed('urlLoading'),
              // OHOS WebViewClient 没有 onReceivedSslError, onFormResubmission, onReceivedClientCertRequest 参数
            ),
          ).thenReturn(mockWebViewClient);

          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                hasNavigationDelegate: true,
              ),
            ),
          );

          verify(
            mockWebViewClient
                .setSynchronousReturnValueForShouldOverrideUrlLoading(true),
          );
        });

        testWidgets('debuggingEnabled true', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                debuggingEnabled: true,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebViewProxy.setWebContentsDebuggingEnabled(true));
        });

        testWidgets('debuggingEnabled false', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                debuggingEnabled: false,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebViewProxy.setWebContentsDebuggingEnabled(false));
        });

        testWidgets('userAgent', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.of('myUserAgent'),
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setUserAgentString('myUserAgent'));
        });

        testWidgets('zoomEnabled', (WidgetTester tester) async {
          await buildWidget(
            tester,
            creationParams: CreationParams(
              webSettings: WebSettings(
                userAgent: const WebSetting<String?>.absent(),
                zoomEnabled: false,
                hasNavigationDelegate: false,
              ),
            ),
          );

          verify(mockWebSettings.setSupportZoom(false));
        });
      });
    });

    group('WebViewPlatformController', () {
      testWidgets('loadFile without "file://" prefix', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        const filePath = '/path/to/file.html';
        await testController.loadFile(filePath);

        verify(mockWebView.loadUrl('file://$filePath', <String, String>{}));
      });

      testWidgets('loadFile with "file://" prefix', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        await testController.loadFile('file:///path/to/file.html');

        verify(
          mockWebView.loadUrl('file:///path/to/file.html', <String, String>{}),
        );
      });

      testWidgets('loadFile should setAllowFileAccess to true', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        await testController.loadFile('file:///path/to/file.html');

        verify(mockWebSettings.setAllowFileAccess(true));
      });

      testWidgets('loadFlutterAsset', (WidgetTester tester) async {
        await buildWidget(tester);
        const assetKey = 'test_assets/index.html';

        when(
          mockFlutterAssetManager.getAssetFilePathByName(assetKey),
        ).thenAnswer((_) => Future<String>.value('flutter_assets/$assetKey'));
        when(
          mockFlutterAssetManager.list('flutter_assets/test_assets'),
        ).thenAnswer((_) => Future<List<String>>.value(<String>['index.html']));

        await testController.loadFlutterAsset(assetKey);

        // OHOS URL 格式: 'resources/rawfile/flutter_assets/$assetKey'
        verify(
          mockWebView.loadUrl(
            'resources/rawfile/flutter_assets/$assetKey',
            <String, String>{},
          ),
        );
      });

      testWidgets('loadFlutterAsset with file in root', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);
        const assetKey = 'index.html';

        when(
          mockFlutterAssetManager.getAssetFilePathByName(assetKey),
        ).thenAnswer((_) => Future<String>.value('flutter_assets/$assetKey'));
        when(
          mockFlutterAssetManager.list('flutter_assets'),
        ).thenAnswer((_) => Future<List<String>>.value(<String>['index.html']));

        await testController.loadFlutterAsset(assetKey);

        // OHOS URL 格式: 'resources/rawfile/flutter_assets/$assetKey'
        verify(
          mockWebView.loadUrl(
            'resources/rawfile/flutter_assets/$assetKey',
            <String, String>{},
          ),
        );
      });

      testWidgets(
        'loadFlutterAsset throws ArgumentError when asset does not exist',
        (WidgetTester tester) async {
          await buildWidget(tester);
          const assetKey = 'test_assets/index.html';

          when(
            mockFlutterAssetManager.getAssetFilePathByName(assetKey),
          ).thenAnswer((_) => Future<String>.value('flutter_assets/$assetKey'));
          when(
            mockFlutterAssetManager.list('flutter_assets/test_assets'),
          ).thenAnswer((_) => Future<List<String>>.value(<String>['']));

          expect(
            () => testController.loadFlutterAsset(assetKey),
            throwsA(
              isA<ArgumentError>()
                  .having((ArgumentError error) => error.name, 'name', 'key')
                  .having(
                    (ArgumentError error) => error.message,
                    'message',
                    'Asset for key "$assetKey" not found.',
                  ),
            ),
          );
        },
      );

      testWidgets('loadHtmlString without base URL', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        const htmlString = '<html lang=""><body>Test data.</body></html>';
        await testController.loadHtmlString(htmlString);

        verify(
          mockWebView.loadDataWithBaseUrl(
            baseUrl: null,
            data: htmlString,
            mimeType: 'text/html',
            encoding: null,
            historyUrl: null,
          ),
        );
      });

      testWidgets('loadHtmlString with base URL', (WidgetTester tester) async {
        await buildWidget(tester);

        const htmlString = '<html lang=""><body>Test data.</body></html>';
        await testController.loadHtmlString(
          htmlString,
          baseUrl: 'https://flutter.dev',
        );

        verify(
          mockWebView.loadDataWithBaseUrl(
            baseUrl: 'https://flutter.dev',
            data: htmlString,
            mimeType: 'text/html',
            encoding: null,
            historyUrl: null,
          ),
        );
      });

      testWidgets('loadUrl', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.loadUrl('https://www.google.com', <String, String>{
          'a': 'header',
        });

        verify(
          mockWebView.loadUrl('https://www.google.com', <String, String>{
            'a': 'header',
          }),
        );
      });

      group('loadRequest', () {
        testWidgets('Throws ArgumentError for empty scheme', (
          WidgetTester tester,
        ) async {
          await buildWidget(tester);

          expect(
            () async => testController.loadRequest(
              WebViewRequest(
                uri: Uri.parse('www.google.com'),
                method: WebViewRequestMethod.get,
              ),
            ),
            throwsA(const TypeMatcher<ArgumentError>()),
          );
        });

        testWidgets('GET without headers', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(
            WebViewRequest(
              uri: Uri.parse('https://www.google.com'),
              method: WebViewRequestMethod.get,
            ),
          );

          verify(
            mockWebView.loadUrl('https://www.google.com', <String, String>{}),
          );
        });

        testWidgets('GET with headers', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(
            WebViewRequest(
              uri: Uri.parse('https://www.google.com'),
              method: WebViewRequestMethod.get,
              headers: <String, String>{'a': 'header'},
            ),
          );

          verify(
            mockWebView.loadUrl('https://www.google.com', <String, String>{
              'a': 'header',
            }),
          );
        });

        testWidgets('POST without body', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.loadRequest(
            WebViewRequest(
              uri: Uri.parse('https://www.google.com'),
              method: WebViewRequestMethod.post,
            ),
          );

          verify(mockWebView.postUrl('https://www.google.com', Uint8List(0)));
        });

        testWidgets('POST with body', (WidgetTester tester) async {
          await buildWidget(tester);

          final body = Uint8List.fromList('Test Body'.codeUnits);

          await testController.loadRequest(
            WebViewRequest(
              uri: Uri.parse('https://www.google.com'),
              method: WebViewRequestMethod.post,
              body: body,
            ),
          );

          verify(mockWebView.postUrl('https://www.google.com', body));
        });
      });

      testWidgets('no update to userAgentString when there is no change', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        reset(mockWebSettings);

        await testController.updateSettings(
          WebSettings(userAgent: const WebSetting<String>.absent()),
        );

        verifyNever(mockWebSettings.setUserAgentString(any));
      });

      testWidgets('update null userAgentString with empty string', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        reset(mockWebSettings);

        await testController.updateSettings(
          WebSettings(userAgent: const WebSetting<String?>.of(null)),
        );

        verify(mockWebSettings.setUserAgentString(''));
      });

      testWidgets('currentUrl', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.getUrl(),
        ).thenAnswer((_) => Future<String>.value('https://www.google.com'));
        expect(
          testController.currentUrl(),
          completion('https://www.google.com'),
        );
      });

      testWidgets('canGoBack', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.canGoBack(),
        ).thenAnswer((_) => Future<bool>.value(false));
        expect(testController.canGoBack(), completion(false));
      });

      testWidgets('canGoForward', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.canGoForward(),
        ).thenAnswer((_) => Future<bool>.value(true));
        expect(testController.canGoForward(), completion(true));
      });

      testWidgets('goBack', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.goBack();
        verify(mockWebView.goBack());
      });

      testWidgets('goForward', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.goForward();
        verify(mockWebView.goForward());
      });

      testWidgets('reload', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.reload();
        verify(mockWebView.reload());
      });

      testWidgets('clearCache', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.clearCache();
        verify(mockWebView.clearCache(true));
        verify(mockWebStorage.deleteAllData());
      });

      testWidgets('evaluateJavascript', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.evaluateJavascript('runJavaScript'),
        ).thenAnswer((_) => Future<String>.value('returnString'));
        expect(
          testController.evaluateJavascript('runJavaScript'),
          completion('returnString'),
        );
      });

      testWidgets('runJavascriptReturningResult', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.evaluateJavascript('runJavaScript'),
        ).thenAnswer((_) => Future<String>.value('returnString'));
        expect(
          testController.runJavascriptReturningResult('runJavaScript'),
          completion('returnString'),
        );
      });

      testWidgets('runJavascript', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.evaluateJavascript('runJavaScript'),
        ).thenAnswer((_) => Future<String>.value('returnString'));
        expect(testController.runJavascript('runJavaScript'), completes);
      });

      testWidgets('addJavascriptChannels', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.addJavascriptChannels(<String>{'c', 'd'});
        final List<ohos_webview.JavaScriptChannel> javaScriptChannels =
            verify(
              mockWebView.addJavaScriptChannel(captureAny),
            ).captured.cast<ohos_webview.JavaScriptChannel>();
        expect(javaScriptChannels[0].channelName, 'c');
        expect(javaScriptChannels[1].channelName, 'd');
      });

      testWidgets('removeJavascriptChannels', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.addJavascriptChannels(<String>{'c', 'd'});
        await testController.removeJavascriptChannels(<String>{'c', 'd'});
        // OHOS removeJavaScriptChannel 需要 JavaScriptChannel 参数而非 String
        // 使用 called(2) 验证两次调用，而非两次单独的 verify
        verify(mockWebView.removeJavaScriptChannel(argThat(isA<ohos_webview.JavaScriptChannel>()))).called(2);
      });

      testWidgets('getTitle', (WidgetTester tester) async {
        await buildWidget(tester);

        when(
          mockWebView.getTitle(),
        ).thenAnswer((_) => Future<String>.value('Web Title'));
        expect(testController.getTitle(), completion('Web Title'));
      });

      testWidgets('scrollTo', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.scrollTo(1, 2);
        verify(mockWebView.scrollTo(1, 2));
      });

      testWidgets('scrollBy', (WidgetTester tester) async {
        await buildWidget(tester);

        await testController.scrollBy(3, 4);
        verify(mockWebView.scrollBy(3, 4));
      });

      testWidgets('getScrollX', (WidgetTester tester) async {
        await buildWidget(tester);

        // OHOS legacy 实现直接调用 webView.getScrollX()
        when(mockWebView.getScrollX()).thenAnswer(
          (_) => Future<int>.value(23),
        );
        expect(testController.getScrollX(), completion(23));
      });

      testWidgets('getScrollY', (WidgetTester tester) async {
        await buildWidget(tester);

        // OHOS legacy 实现直接调用 webView.getScrollY()
        when(mockWebView.getScrollY()).thenAnswer(
          (_) => Future<int>.value(25),
        );
        expect(testController.getScrollY(), completion(25));
      });
    });

    group('WebViewPlatformCallbacksHandler', () {
      testWidgets('onPageStarted', (WidgetTester tester) async {
        await buildWidget(tester);
        // OHOS 回调签名: (WebView, String) => void
        // Android 回调签名: (WebViewClient, WebView, String) => void
        final onPageStarted =
            verify(
                  mockWebViewProxy.createWebViewClient(
                    onPageStarted: captureAnyNamed('onPageStarted'),
                    onPageFinished: anyNamed('onPageFinished'),
                    onReceivedRequestError: anyNamed('onReceivedRequestError'),
                    requestLoading: anyNamed('requestLoading'),
                    urlLoading: anyNamed('urlLoading'),
                  ),
                ).captured.single
                as void Function(
                  ohos_webview.WebView,
                  String,
                );

        onPageStarted(mockWebView, 'https://google.com');
        verify(mockCallbacksHandler.onPageStarted('https://google.com'));
      });

      testWidgets('onPageFinished', (WidgetTester tester) async {
        await buildWidget(tester);

        final onPageFinished =
            verify(
                  mockWebViewProxy.createWebViewClient(
                    onPageStarted: anyNamed('onPageStarted'),
                    onPageFinished: captureAnyNamed('onPageFinished'),
                    onReceivedRequestError: anyNamed('onReceivedRequestError'),
                    requestLoading: anyNamed('requestLoading'),
                    urlLoading: anyNamed('urlLoading'),
                  ),
                ).captured.single
                as void Function(
                  ohos_webview.WebView,
                  String,
                );

        onPageFinished(mockWebView, 'https://google.com');
        verify(mockCallbacksHandler.onPageFinished('https://google.com'));
      });

      testWidgets('onWebResourceError from onReceivedRequestError', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester);

        final onReceivedRequestError =
            verify(
                  mockWebViewProxy.createWebViewClient(
                    onPageStarted: anyNamed('onPageStarted'),
                    onPageFinished: anyNamed('onPageFinished'),
                    onReceivedRequestError: captureAnyNamed(
                      'onReceivedRequestError',
                    ),
                    requestLoading: anyNamed('requestLoading'),
                    urlLoading: anyNamed('urlLoading'),
                  ),
                ).captured.single
                as void Function(
                  ohos_webview.WebView,
                  ohos_webview.WebResourceRequest,
                  ohos_webview.WebResourceError,
                );

        onReceivedRequestError(
          mockWebView,
          ohos_webview.WebResourceRequest(
            url: 'https://google.com',
            isForMainFrame: true,
            isRedirect: false,
            hasGesture: false,
            method: 'POST',
            requestHeaders: const <String, String>{},
          ),
          ohos_webview.WebResourceError(
            errorCode: ohos_webview.WebViewClient.errorUnsafeResource,
            description: 'description',
          ),
        );

        final error =
            verify(
                  mockCallbacksHandler.onWebResourceError(captureAny),
                ).captured.single
                as WebResourceError;
        expect(error.description, 'description');
        // OHOS errorUnsafeResource = -311 (Android = -16)
        expect(error.errorCode, -311);
        expect(error.failingUrl, 'https://google.com');
        expect(error.domain, isNull);
        expect(error.errorType, WebResourceErrorType.unsafeResource);
      });

      testWidgets('onNavigationRequest from urlLoading', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester, hasNavigationDelegate: true);
        when(
          mockCallbacksHandler.onNavigationRequest(
            isForMainFrame: argThat(isTrue, named: 'isForMainFrame'),
            url: 'https://google.com',
          ),
        ).thenReturn(true);

        final urlLoading =
            verify(
                  mockWebViewProxy.createWebViewClient(
                    onPageStarted: anyNamed('onPageStarted'),
                    onPageFinished: anyNamed('onPageFinished'),
                    onReceivedRequestError: anyNamed('onReceivedRequestError'),
                    requestLoading: anyNamed('requestLoading'),
                    urlLoading: captureAnyNamed('urlLoading'),
                  ),
                ).captured.single
                as void Function(
                  ohos_webview.WebView,
                  String,
                );

        urlLoading(mockWebView, 'https://google.com');
        verify(
          mockCallbacksHandler.onNavigationRequest(
            url: 'https://google.com',
            isForMainFrame: true,
          ),
        );
        verify(mockWebView.loadUrl('https://google.com', <String, String>{}));
      });

      testWidgets('onNavigationRequest from requestLoading', (
        WidgetTester tester,
      ) async {
        await buildWidget(tester, hasNavigationDelegate: true);
        when(
          mockCallbacksHandler.onNavigationRequest(
            isForMainFrame: argThat(isTrue, named: 'isForMainFrame'),
            url: 'https://google.com',
          ),
        ).thenReturn(true);

        final requestLoading =
            verify(
                  mockWebViewProxy.createWebViewClient(
                    onPageStarted: anyNamed('onPageStarted'),
                    onPageFinished: anyNamed('onPageFinished'),
                    onReceivedRequestError: anyNamed('onReceivedRequestError'),
                    requestLoading: captureAnyNamed('requestLoading'),
                    urlLoading: anyNamed('urlLoading'),
                  ),
                ).captured.single
                as void Function(
                  ohos_webview.WebView,
                  ohos_webview.WebResourceRequest,
                );

        requestLoading(
          mockWebView,
          ohos_webview.WebResourceRequest(
            url: 'https://google.com',
            isForMainFrame: true,
            isRedirect: false,
            hasGesture: false,
            method: 'POST',
            requestHeaders: const <String, String>{},
          ),
        );
        verify(
          mockCallbacksHandler.onNavigationRequest(
            url: 'https://google.com',
            isForMainFrame: true,
          ),
        );
        verify(mockWebView.loadUrl('https://google.com', <String, String>{}));
      });

      group('JavascriptChannelRegistry', () {
        testWidgets('onJavascriptChannelMessage', (WidgetTester tester) async {
          await buildWidget(tester);

          await testController.addJavascriptChannels(<String>{'hello'});

          final javaScriptChannel =
              verify(
                    mockWebView.addJavaScriptChannel(captureAny),
                  ).captured.single
                  as WebViewOhosJavaScriptChannel;
          // OHOS JavaScriptChannel.postMessage 只接受 message 参数
          javaScriptChannel.postMessage('goodbye');
          verify(
            mockJavascriptChannelRegistry.onJavascriptChannelMessage(
              'hello',
              'goodbye',
            ),
          );
        });
      });
    });
  });
}
