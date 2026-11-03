// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Contract tests for the `webview_flutter_platform_interface` surface that is
// implemented by this package. Every case drives the OHOS implementation
// (OhosWebViewController, OhosNavigationDelegate, OhosSslAuthError,
// OhosWebViewWidget, WebViewOhosCookieManager) and asserts the observable
// behavior: values returned to the caller and Pigeon messages sent to the
// platform side. Native callbacks are stubbed by `OhosPigeonTestMocks`.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart' as ohos_webview;
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_ohos/src/legacy/webview_ohos_cookie_manager.dart'
    as legacy_cookie_manager;
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart'
    as legacy_pi;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_pigeon_test_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
  });

  tearDown(() {
    OhosPigeonTestMocks.clearRecords();
  });

  group('PlatformWebViewController (via OhosWebViewController)', () {
    late PlatformWebViewController controller;

    setUp(() {
      controller = OhosWebViewController(
        OhosWebViewControllerCreationParams(),
      );
    });

    test(
      'should send the scrollTo platform message when PlatformWebViewController.scrollTo is invoked',
      () async {
        await controller.scrollTo(120, 240);

        final List<PlatformChannelCallRecord> calls =
            OhosPigeonTestMocks.getCallsForChannel(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollTo',
        );
        expect(calls.isNotEmpty, true);
      },
    );

    test(
      'should send the scrollBy platform message when PlatformWebViewController.scrollBy is invoked',
      () async {
        await controller.scrollBy(10, 20);

        final List<PlatformChannelCallRecord> calls =
            OhosPigeonTestMocks.getCallsForChannel(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollBy',
        );
        expect(calls.isNotEmpty, true);
      },
    );

    test(
      'should return the scroll offset when PlatformWebViewController.getScrollPosition is invoked',
      () async {
        final Offset position = await controller.getScrollPosition();

        expect(position.dx, 100);
        expect(position.dy, 200);
      },
    );

    test(
      'should store the callback when PlatformWebViewController.setOnPlatformPermissionRequest is invoked',
      () async {
        await controller.setOnPlatformPermissionRequest(
          (PlatformWebViewPermissionRequest request) {},
        );
      },
    );
  });

  group('PlatformNavigationDelegate (via OhosNavigationDelegate)', () {
    late PlatformNavigationDelegate delegate;

    setUp(() {
      delegate = OhosNavigationDelegate(
        PlatformNavigationDelegateCreationParams(),
      );
    });

    test(
      'should accept the navigation request callback when setOnNavigationRequest is invoked',
      () async {
        await delegate.setOnNavigationRequest(
          (NavigationRequest request) => NavigationDecision.navigate,
        );
      },
    );

    test(
      'should accept the page callbacks when setOnPageStarted and setOnPageFinished are invoked',
      () async {
        await delegate.setOnPageStarted((String url) {});
        await delegate.setOnPageFinished((String url) {});
      },
    );

    test(
      'should accept the resource callbacks when setOnHttpError and setOnWebResourceError are invoked',
      () async {
        await delegate.setOnHttpError(
          (HttpResponseError error) {},
        );
        await delegate.setOnWebResourceError(
          (WebResourceError error) {},
        );
      },
    );

    test(
      'should accept the progress callback when setOnProgress is invoked',
      () async {
        await delegate.setOnProgress((int progress) {});
      },
    );

    test(
      'should accept the url callback when setOnUrlChange is invoked',
      () async {
        await delegate.setOnUrlChange((UrlChange change) {});
      },
    );

    test(
      'should accept the auth callbacks when setOnHttpAuthRequest and setOnSSlAuthError are invoked',
      () async {
        await delegate.setOnHttpAuthRequest((HttpAuthRequest request) {});
        await delegate.setOnSSlAuthError((PlatformSslAuthError error) {});
      },
    );
  });

  group('PlatformSslAuthError (via OhosSslAuthError)', () {
    late _FakeSslErrorHandler handler;
    late PlatformSslAuthError sslAuthError;

    setUp(() async {
      handler = _FakeSslErrorHandler();
      sslAuthError = await OhosSslAuthError.fromNativeCallback(
        handler: handler,
        certificateHint: '',
        description: 'untrusted certificate',
        url: 'https://flutter.dev',
      );
    });

    test(
      'should expose description and certificate when created from a native callback',
      () {
        expect(sslAuthError.description, 'untrusted certificate');
        expect(sslAuthError.certificate, isNull);
      },
    );

    test(
      'should append the issuer hint to the description when ArkWeb provides one',
      () async {
        final PlatformSslAuthError withHint =
            await OhosSslAuthError.fromNativeCallback(
          handler: handler,
          certificateHint: 'issuer-hint',
          description: 'untrusted certificate',
          url: 'https://flutter.dev',
        );

        expect(withHint.description, contains('untrusted certificate'));
        expect(withHint.description, contains('issuer-hint'));
      },
    );

    test(
      'should delegate to the native handler when PlatformSslAuthError.proceed is invoked',
      () async {
        await sslAuthError.proceed();

        expect(handler.proceedCount, 1);
        expect(handler.cancelCount, 0);
      },
    );

    test(
      'should delegate to the native handler when PlatformSslAuthError.cancel is invoked',
      () async {
        await sslAuthError.cancel();

        expect(handler.cancelCount, 1);
        expect(handler.proceedCount, 0);
      },
    );
  });

  group('WebViewCookieManagerPlatform (via WebViewOhosCookieManager)', () {
    test(
      'should remove all cookies when WebViewCookieManagerPlatform.clearCookies is invoked',
      () async {
        final legacy_pi.WebViewCookieManagerPlatform cookieManager =
            legacy_cookie_manager.WebViewOhosCookieManager();

        final bool removed = await cookieManager.clearCookies();

        expect(removed, true);
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.removeAllCookies',
          ).isNotEmpty,
          true,
        );
      },
    );

    test(
      'should send the formatted cookie when WebViewCookieManagerPlatform.setCookie is invoked',
      () async {
        final legacy_pi.WebViewCookieManagerPlatform cookieManager =
            legacy_cookie_manager.WebViewOhosCookieManager();

        await cookieManager.setCookie(
          const legacy_pi.WebViewCookie(
            name: 'foo&',
            value: 'bar@',
            domain: 'flutter.dev',
          ),
        );

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.setCookie',
          ).isNotEmpty,
          true,
        );
      },
    );
  });

  group('PlatformWebViewWidget (via OhosWebViewWidget)', () {
    testWidgets(
      'should return a PlatformViewLink when PlatformWebViewWidget.build is invoked',
      (WidgetTester tester) async {
        BuildContext? capturedContext;
        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        );

        final OhosWebViewController controller = OhosWebViewController(
          OhosWebViewControllerCreationParams(),
        );
        final PlatformWebViewWidget widget = OhosWebViewWidget(
          OhosWebViewWidgetCreationParams(controller: controller),
        );

        final Widget built = widget.build(capturedContext!);

        expect(built, isA<PlatformViewLink>());
      },
    );
  });

  group('platform interface value types', () {
    test(
      'should expose the log level when a JavaScriptConsoleMessage is constructed',
      () {
        const JavaScriptConsoleMessage message = JavaScriptConsoleMessage(
          level: JavaScriptLogLevel.debug,
          message: 'log',
        );
        expect(message.level, JavaScriptLogLevel.debug);
      },
    );

    test(
      'should expose the default text when a JavaScriptTextInputDialogRequest is constructed',
      () {
        const JavaScriptTextInputDialogRequest request =
            JavaScriptTextInputDialogRequest(
          message: 'prompt',
          url: 'https://flutter.dev',
          defaultText: 'default',
        );
        expect(request.defaultText, 'default');
      },
    );

    test(
      'should expose the main frame flag when a NavigationRequest is constructed',
      () {
        const NavigationRequest request = NavigationRequest(
          url: 'https://flutter.dev',
          isMainFrame: true,
        );
        expect(request.isMainFrame, true);
      },
    );

    test(
      'should expose the error code when a WebResourceError is constructed',
      () {
        const WebResourceError error = WebResourceError(
          errorCode: -106,
          description: 'failed to connect',
        );
        expect(error.errorCode, -106);
      },
    );

    test(
      'should reflect presence when WebSetting.isPresent is read for present and absent values',
      () {
        const legacy_pi.WebSetting<String?> present =
            legacy_pi.WebSetting<String?>.of('agent');
        const legacy_pi.WebSetting<String?> absent =
            legacy_pi.WebSetting<String?>.absent();
        expect(present.isPresent, true);
        expect(absent.isPresent, false);
      },
    );

    test(
      'should expose progress tracking when legacy WebSettings.hasProgressTracking is read',
      () {
        final legacy_pi.WebSettings webSettings = legacy_pi.WebSettings(
          hasProgressTracking: true,
          userAgent: const legacy_pi.WebSetting<String?>.absent(),
        );
        expect(webSettings.hasProgressTracking, true);
      },
    );

    test(
      'should expose the playback policy when legacy CreationParams.autoMediaPlaybackPolicy is read',
      () {
        final legacy_pi.CreationParams creationParams = legacy_pi.CreationParams(
          autoMediaPlaybackPolicy:
              legacy_pi.AutoMediaPlaybackPolicy.always_allow,
        );
        expect(
          creationParams.autoMediaPlaybackPolicy,
          legacy_pi.AutoMediaPlaybackPolicy.always_allow,
        );
      },
    );

    test(
      'should serialize both legacy HTTP methods when WebViewRequestMethodExtensions.serialize is invoked',
      () {
        expect(
          legacy_pi.WebViewRequestMethod.get.serialize(),
          'get',
        );
        expect(
          legacy_pi.WebViewRequestMethod.post.serialize(),
          'post',
        );
      },
    );
  });
}

/// Hand-rolled stand-in for the native SSL error handler that records
/// decisions instead of sending Pigeon messages.
// ignore: must_be_immutable
class _FakeSslErrorHandler extends ohos_webview.SslErrorHandler {
  _FakeSslErrorHandler() : super();

  int cancelCount = 0;
  int proceedCount = 0;

  @override
  Future<void> cancel() async {
    cancelCount++;
  }

  @override
  Future<void> proceed() async {
    proceedCount++;
  }
}
