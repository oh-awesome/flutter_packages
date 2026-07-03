// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_pigeon_test_mocks.dart';
import 'ohos_webview_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[ohos_webview.CookieManager, OhosWebViewController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
  });

  test('clearCookies should call ohos_webview.clearCookies', () async {
    final ohos_webview.CookieManager mockCookieManager = MockCookieManager();

    when(
      mockCookieManager.removeAllCookies(),
    ).thenAnswer((_) => Future<bool>.value(true));

    final params =
        OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        );

    final bool hasClearedCookies = await OhosWebViewCookieManager(
      params,
      cookieManager: mockCookieManager,
    ).clearCookies();

    expect(hasClearedCookies, true);
    verify(mockCookieManager.removeAllCookies());
  });

  test('setCookie should throw ArgumentError for cookie with invalid path', () {
    final params =
        OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        );

    final ohosCookieManager = OhosWebViewCookieManager(
      params,
      cookieManager: MockCookieManager(),
    );

    expect(
      () => ohosCookieManager.setCookie(
        const WebViewCookie(
          name: 'foo',
          value: 'bar',
          domain: 'flutter.dev',
          path: 'invalid;path',
        ),
      ),
      throwsA(const TypeMatcher<ArgumentError>()),
    );
  });

  test(
    'setCookie should call ohos_webview.setCookie with properly formatted cookie value',
    () {
      final ohos_webview.CookieManager mockCookieManager =
          MockCookieManager();
      final params =
          OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
            const PlatformWebViewCookieManagerCreationParams(),
          );

      OhosWebViewCookieManager(
        params,
        cookieManager: mockCookieManager,
      ).setCookie(
        const WebViewCookie(name: 'foo&', value: 'bar@', domain: 'flutter.dev'),
      );

      verify(
        mockCookieManager.setCookie('flutter.dev', 'foo%26=bar%40; path=/'),
      );
    },
  );

  test('setAcceptThirdPartyCookies', () async {
    final mockController = MockOhosWebViewController();

    final webView = ohos_webview.WebView.detached();

    final int webViewIdentifier = ohos_webview.OhosObject.globalInstanceManager
        .addDartCreatedInstance(webView);

    when(mockController.webViewIdentifier).thenReturn(webViewIdentifier);

    final params =
        OhosWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        );

    final mockCookieManager = MockCookieManager();

    await OhosWebViewCookieManager(
      params,
      cookieManager: mockCookieManager,
    ).setAcceptThirdPartyCookies(mockController, false);

    verify(mockCookieManager.setAcceptThirdPartyCookies(webView, false));
  });
}
