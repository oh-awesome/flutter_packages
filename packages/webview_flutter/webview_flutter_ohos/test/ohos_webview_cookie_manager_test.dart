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
import 'package:webview_flutter_ohos/src/ohos_webview.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview_cookie_manager.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_webview_cookie_manager_test.mocks.dart';
import 'test_ohos_webview.g.dart';

@GenerateMocks(<Type>[
  TestCookieManagerHostApi,
  TestInstanceManagerHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestInstanceManagerHostApi.setup(MockTestInstanceManagerHostApi());
  });

  group('OhosWebViewCookieManager', () {
    late MockTestCookieManagerHostApi mockCookieManagerHostApi;
    late InstanceManager instanceManager;
    late CookieManager mockCookieManager;

    setUp(() {
      mockCookieManagerHostApi = MockTestCookieManagerHostApi();
      TestCookieManagerHostApi.setup(mockCookieManagerHostApi);

      instanceManager = InstanceManager(onWeakReferenceRemoved: (_) {});
      mockCookieManager =
          CookieManager.detached(instanceManager: instanceManager);
      instanceManager.addDartCreatedInstance(mockCookieManager);
    });

    test('setCookie', () async {
      final OhosWebViewCookieManager cookieManager = OhosWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
        cookieManager: mockCookieManager,
      );

      await cookieManager.setCookie(
        WebViewCookie(name: 'test', value: 'value', domain: 'flutter.dev'),
      );

      verify(mockCookieManagerHostApi.setCookie(
        argThat(isA<int>()),
        'flutter.dev',
        argThat(contains('test=value')),
      ));
    });

    test('clearCookies', () async {
      when(mockCookieManagerHostApi.removeAllCookies(any))
          .thenAnswer((_) async => true);

      final OhosWebViewCookieManager cookieManager = OhosWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
        cookieManager: mockCookieManager,
      );

      final bool cleared = await cookieManager.clearCookies();

      expect(cleared, true);
      verify(mockCookieManagerHostApi.removeAllCookies(any));
    });
  });
}
