/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
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

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart' as ohos_webview;
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview_controller.dart';
import 'package:webview_flutter_ohos/src/ohos_proxy.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_navigation_delegate_test.mocks.dart';
import 'test_ohos_webview.g.dart';

@GenerateMocks(<Type>[
  TestInstanceManagerHostApi,
  TestWebViewClientHostApi,
  TestDownloadListenerHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestInstanceManagerHostApi.setup(MockTestInstanceManagerHostApi());
  });

  group('OhosNavigationDelegate', () {
    late MockTestWebViewClientHostApi mockWebViewClientHostApi;
    late MockTestDownloadListenerHostApi mockDownloadListenerHostApi;
    late InstanceManager instanceManager;

    setUp(() {
      mockWebViewClientHostApi = MockTestWebViewClientHostApi();
      TestWebViewClientHostApi.setup(mockWebViewClientHostApi);
      mockDownloadListenerHostApi = MockTestDownloadListenerHostApi();
      TestDownloadListenerHostApi.setup(mockDownloadListenerHostApi);
      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
    });

    test('setOnLoadRequest', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              urlLoading: urlLoading,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      LoadRequestParams? loadRequestParams;
      await navigationDelegate
          .setOnLoadRequest((LoadRequestParams params) async {
        loadRequestParams = params;
      });

      expect(loadRequestParams, isNull);
    });

    test('setOnPageStarted', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              onPageStarted: onPageStarted,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      await navigationDelegate.setOnPageStarted((String url) {});
    });

    test('setOnPageFinished', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              onPageFinished: onPageFinished,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      await navigationDelegate.setOnPageFinished((String url) {});
    });

    test('setOnWebResourceError', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              onReceivedRequestError: onReceivedRequestError,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      await navigationDelegate
          .setOnWebResourceError((WebResourceError error) {});
    });

    test('setOnUrlChange', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              doUpdateVisitedHistory: doUpdateVisitedHistory,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      await navigationDelegate.setOnUrlChange((UrlChange change) {});
    });

    test('setOnHttpError', () async {
      final OhosNavigationDelegate navigationDelegate = OhosNavigationDelegate(
        OhosNavigationDelegateCreationParams
            .fromPlatformNavigationDelegateCreationParams(
          const PlatformNavigationDelegateCreationParams(),
          ohosWebViewProxy: OhosWebViewProxy(
            createOhosWebViewClient: ({
              onPageStarted,
              onPageFinished,
              onReceivedHttpError,
              onReceivedRequestError,
              onReceivedError,
              requestLoading,
              urlLoading,
              doUpdateVisitedHistory,
              onReceivedHttpAuthRequest,
              onReceivedSslError,
            }) =>
                ohos_webview.WebViewClient.detached(
              onReceivedHttpError: onReceivedHttpError,
              instanceManager: instanceManager,
            ),
            createOhosWebChromeClient: ohos_webview.WebChromeClient.detached,
            createDownloadListener: ({
              required onDownloadStart,
            }) =>
                ohos_webview.DownloadListener.detached(
              onDownloadStart: onDownloadStart,
              instanceManager: instanceManager,
            ),
          ),
        ),
      );

      await navigationDelegate.setOnHttpError((HttpResponseError error) {});
    });
  });
}
