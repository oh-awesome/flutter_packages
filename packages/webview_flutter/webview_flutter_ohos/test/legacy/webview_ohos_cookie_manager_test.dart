// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_ohos/src/ohos_webkit.g.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/legacy/webview_ohos_cookie_manager.dart';
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'webview_ohos_cookie_manager_test.mocks.dart';

@GenerateMocks(<Type>[ohos_webview.CookieManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clearCookies should call ohos_webview.clearCookies', () {
    final mockCookieManager = MockCookieManager();
    when(
      mockCookieManager.removeAllCookies(),
    ).thenAnswer((_) => Future<bool>.value(true));
    WebViewOhosCookieManager(
      cookieManager: mockCookieManager,
    ).clearCookies();
    verify(mockCookieManager.removeAllCookies());
  });

  test('setCookie should throw ArgumentError for cookie with invalid path', () {
    expect(
      () => WebViewOhosCookieManager(cookieManager: MockCookieManager())
          .setCookie(
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
    'setCookie should call ohos_webview.csetCookie with properly formatted cookie value',
    () {
      final mockCookieManager = MockCookieManager();
      WebViewOhosCookieManager(cookieManager: mockCookieManager).setCookie(
        const WebViewCookie(name: 'foo&', value: 'bar@', domain: 'flutter.dev'),
      );
      verify(
        mockCookieManager.setCookie('flutter.dev', 'foo%26=bar%40; path=/'),
      );
    },
  );
}
