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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.g.dart';
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';

import 'ohos_webview_test.mocks.dart';
import 'test_ohos_webview.g.dart';

@GenerateMocks(<Type>[
  TestInstanceManagerHostApi,
  TestOhosObjectHostApi,
  TestWebViewHostApi,
  TestWebSettingsHostApi,
  TestWebChromeClientHostApi,
  TestWebViewClientHostApi,
  TestJavaScriptChannelHostApi,
  TestWebStorageHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestInstanceManagerHostApi.setup(MockTestInstanceManagerHostApi());
    TestOhosObjectHostApi.setup(MockTestOhosObjectHostApi());
  });

  group('OhosObject', () {
    late MockTestOhosObjectHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;

    setUp(() {
      mockPlatformHostApi = MockTestOhosObjectHostApi();
      TestOhosObjectHostApi.setup(mockPlatformHostApi);
      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
    });

    test('dispose', () async {
      int? callbackIdentifier;
      final InstanceManager localInstanceManager = InstanceManager(
        onWeakReferenceRemoved: (int identifier) {
          callbackIdentifier = identifier;
        },
      );

      final OhosObject object = OhosObject.detached(
        instanceManager: localInstanceManager,
      );
      localInstanceManager.addHostCreatedInstance(object, 0);

      OhosObject.dispose(object);

      expect(callbackIdentifier, 0);
    });

    test('OhosObjectFlutterApi.dispose', () {
      final OhosObject object = OhosObject.detached(
        instanceManager: instanceManager,
      );
      instanceManager.addHostCreatedInstance(object, 0);
      instanceManager.removeWeakReference(object);

      expect(instanceManager.containsIdentifier(0), isTrue);

      final OhosObjectFlutterApiImpl flutterApi = OhosObjectFlutterApiImpl(
        instanceManager: instanceManager,
      );
      flutterApi.dispose(0);

      expect(instanceManager.containsIdentifier(0), isFalse);
    });
  });

  group('WebView', () {
    late MockTestWebViewHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;
    late WebView webView;
    late int webViewInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebViewHostApi();
      TestWebViewHostApi.setup(mockPlatformHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      WebView.api = WebViewHostApiImpl(instanceManager: instanceManager);

      webView = WebView(instanceManager: instanceManager);
      webViewInstanceId = instanceManager.getIdentifier(webView)!;
    });

    tearDown(() {
      instanceManager.removeWeakReference(webView);
      instanceManager.remove(webViewInstanceId);
    });

    test('create', () {
      verify(mockPlatformHostApi.create(webViewInstanceId));
    });

    test('loadUrl', () {
      webView.loadUrl('https://flutter.dev', <String, String>{'a': 'header'});
      verify(mockPlatformHostApi.loadUrl(
        webViewInstanceId,
        'https://flutter.dev',
        <String, String>{'a': 'header'},
      ));
    });

    test('postUrl', () {
      final Uint8List data = Uint8List.fromList([1, 2, 3]);
      webView.postUrl('https://flutter.dev', data);
      verify(mockPlatformHostApi.postUrl(
        webViewInstanceId,
        'https://flutter.dev',
        data,
      ));
    });

    test('canGoBack', () {
      when(mockPlatformHostApi.canGoBack(webViewInstanceId)).thenReturn(false);
      expect(webView.canGoBack(), completion(false));
    });

    test('canGoForward', () {
      when(mockPlatformHostApi.canGoForward(webViewInstanceId))
          .thenReturn(true);
      expect(webView.canGoForward(), completion(true));
    });

    test('goBack', () {
      webView.goBack();
      verify(mockPlatformHostApi.goBack(webViewInstanceId));
    });

    test('goForward', () {
      webView.goForward();
      verify(mockPlatformHostApi.goForward(webViewInstanceId));
    });

    test('reload', () {
      webView.reload();
      verify(mockPlatformHostApi.reload(webViewInstanceId));
    });

    test('clearCache', () {
      webView.clearCache(false);
      verify(mockPlatformHostApi.clearCache(webViewInstanceId, false));
    });

    test('evaluateJavascript', () {
      when(mockPlatformHostApi.evaluateJavascript(
        webViewInstanceId,
        'runJavaScript',
      )).thenAnswer((_) => Future<String>.value('returnValue'));
      expect(
        webView.evaluateJavascript('runJavaScript'),
        completion('returnValue'),
      );
    });

    test('getTitle', () {
      when(mockPlatformHostApi.getTitle(webViewInstanceId))
          .thenReturn('aTitle');
      expect(webView.getTitle(), completion('aTitle'));
    });

    test('scrollTo', () {
      webView.scrollTo(10, 20);
      verify(mockPlatformHostApi.scrollTo(webViewInstanceId, 10, 20));
    });

    test('scrollBy', () {
      webView.scrollBy(5, 15);
      verify(mockPlatformHostApi.scrollBy(webViewInstanceId, 5, 15));
    });

    test('getScrollX', () {
      when(mockPlatformHostApi.getScrollX(webViewInstanceId)).thenReturn(10);
      expect(webView.getScrollX(), completion(10));
    });

    test('getScrollY', () {
      when(mockPlatformHostApi.getScrollY(webViewInstanceId)).thenReturn(20);
      expect(webView.getScrollY(), completion(20));
    });

    test('getScrollPosition', () {
      when(mockPlatformHostApi.getScrollPosition(webViewInstanceId))
          .thenReturn(WebViewPoint(x: 10, y: 20));
      expect(webView.getScrollPosition(), completion(const Offset(10, 20)));
    });
  });

  group('WebSettings', () {
    late MockTestWebSettingsHostApi mockPlatformHostApi;
    late MockTestWebViewHostApi mockWebViewHostApi;
    late InstanceManager instanceManager;
    late WebView webView;
    late WebSettings webSettings;
    late int webViewInstanceId;
    late int webSettingsInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebSettingsHostApi();
      TestWebSettingsHostApi.setup(mockPlatformHostApi);
      mockWebViewHostApi = MockTestWebViewHostApi();
      TestWebViewHostApi.setup(mockWebViewHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      WebView.api = WebViewHostApiImpl(instanceManager: instanceManager);
      WebSettings.api =
          WebSettingsHostApiImpl(instanceManager: instanceManager);

      webView = WebView(instanceManager: instanceManager);
      webViewInstanceId = instanceManager.getIdentifier(webView)!;
      webSettings = WebSettings(webView);
      webSettingsInstanceId = instanceManager.getIdentifier(webSettings)!;
    });

    test('setDomStorageEnabled', () {
      webSettings.setDomStorageEnabled(true);
      verify(mockPlatformHostApi.setDomStorageEnabled(
        webSettingsInstanceId,
        true,
      ));
    });

    test('setJavaScriptEnabled', () {
      webSettings.setJavaScriptEnabled(true);
      verify(mockPlatformHostApi.setJavaScriptEnabled(
        webSettingsInstanceId,
        true,
      ));
    });

    test('setUserAgentString', () {
      webSettings.setUserAgentString('Test Agent');
      verify(mockPlatformHostApi.setUserAgentString(
        webSettingsInstanceId,
        'Test Agent',
      ));
    });

    test('getUserAgentString', () {
      when(mockPlatformHostApi.getUserAgentString(webSettingsInstanceId))
          .thenReturn('Test Agent');
      expect(webSettings.getUserAgentString(), completion('Test Agent'));
    });

    test('setSupportZoom', () {
      webSettings.setSupportZoom(true);
      verify(mockPlatformHostApi.setSupportZoom(
        webSettingsInstanceId,
        true,
      ));
    });
  });

  group('WebChromeClient', () {
    late MockTestWebChromeClientHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;
    late WebChromeClient webChromeClient;
    late int webChromeClientInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebChromeClientHostApi();
      TestWebChromeClientHostApi.setup(mockPlatformHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      WebChromeClient.api = WebChromeClientHostApiImpl(
        instanceManager: instanceManager,
      );

      webChromeClient = WebChromeClient(
        onShowFileChooser: (_, __) => Future<List<String>>.value(<String>[]),
        onConsoleMessage: (_, __) {},
        instanceManager: instanceManager,
      );
      webChromeClientInstanceId =
          instanceManager.getIdentifier(webChromeClient)!;
    });

    test('setSynchronousReturnValueForOnShowFileChooser', () {
      webChromeClient.setSynchronousReturnValueForOnShowFileChooser(true);
      verify(mockPlatformHostApi.setSynchronousReturnValueForOnShowFileChooser(
        webChromeClientInstanceId,
        true,
      ));
    });

    test('setSynchronousReturnValueForOnConsoleMessage', () {
      webChromeClient.setSynchronousReturnValueForOnConsoleMessage(true);
      verify(mockPlatformHostApi.setSynchronousReturnValueForOnConsoleMessage(
        webChromeClientInstanceId,
        true,
      ));
    });
  });

  group('WebViewClient', () {
    late MockTestWebViewClientHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;
    late WebViewClient webViewClient;
    late int webViewClientInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebViewClientHostApi();
      TestWebViewClientHostApi.setup(mockPlatformHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      WebViewClient.api = WebViewClientHostApiImpl(
        instanceManager: instanceManager,
      );

      webViewClient = WebViewClient(
        urlLoading: (_, __) {},
        instanceManager: instanceManager,
      );
      webViewClientInstanceId = instanceManager.getIdentifier(webViewClient)!;
    });

    test('setSynchronousReturnValueForShouldOverrideUrlLoading', () {
      webViewClient.setSynchronousReturnValueForShouldOverrideUrlLoading(true);
      verify(mockPlatformHostApi
          .setSynchronousReturnValueForShouldOverrideUrlLoading(
        webViewClientInstanceId,
        true,
      ));
    });
  });

  group('JavaScriptChannel', () {
    late MockTestJavaScriptChannelHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;
    late JavaScriptChannel javaScriptChannel;
    late int javaScriptChannelInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestJavaScriptChannelHostApi();
      TestJavaScriptChannelHostApi.setup(mockPlatformHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      JavaScriptChannel.api = JavaScriptChannelHostApiImpl(
        instanceManager: instanceManager,
      );

      javaScriptChannel = JavaScriptChannel(
        'testChannel',
        postMessage: (_) {},
        instanceManager: instanceManager,
      );
      javaScriptChannelInstanceId =
          instanceManager.getIdentifier(javaScriptChannel)!;
    });

    test('create', () {
      verify(mockPlatformHostApi.create(
        javaScriptChannelInstanceId,
        'testChannel',
      ));
    });
  });

  group('WebStorage', () {
    late MockTestWebStorageHostApi mockPlatformHostApi;
    late InstanceManager instanceManager;
    late WebStorage webStorage;
    late int webStorageInstanceId;

    setUp(() {
      mockPlatformHostApi = MockTestWebStorageHostApi();
      TestWebStorageHostApi.setup(mockPlatformHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      WebStorage.api = WebStorageHostApiImpl(instanceManager: instanceManager);

      webStorage = WebStorage(instanceManager: instanceManager);
      webStorageInstanceId = instanceManager.getIdentifier(webStorage)!;
    });

    test('deleteAllData', () {
      webStorage.deleteAllData();
      verify(mockPlatformHostApi.deleteAllData(webStorageInstanceId));
    });
  });
}
