// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Coverage scanner probe: this file lives in `webview_flutter_ohos/test` on
// purpose. If a future coverage report counts the tests below, the scanner
// includes the OHOS package test directory; if the reported coverage is
// unchanged, the scanner only counts tests of the main `webview_flutter`
// package and the gap must be closed there instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI coverage probe (webview_flutter_ohos/test)', () {
    setUp(() {
      // Each probe case is independent and needs no shared state.
    });

    test(
      'should expose x and y when a ScrollPositionChange is constructed',
      () {
        const ScrollPositionChange position = ScrollPositionChange(7, 11);
        expect(position.x, 7);
        expect(position.y, 11);
      },
    );

    test('should expose name and value when a WebViewCookie is constructed',
        () {
      const WebViewCookie cookie = WebViewCookie(
        name: 'probe',
        value: '1',
        domain: 'flutter.dev',
      );
      expect(cookie.name, 'probe');
      expect(cookie.value, '1');
      expect(cookie.domain, 'flutter.dev');
    });

    test(
      'should serialize both HTTP methods when the request method extensions are used',
      () {
        expect(LoadRequestMethod.get.serialize(), 'get');
        expect(LoadRequestMethod.post.serialize(), 'post');
      },
    );
  });
}
