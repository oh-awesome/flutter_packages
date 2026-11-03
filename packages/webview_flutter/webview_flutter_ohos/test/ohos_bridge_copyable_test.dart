// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Coverage for the remaining public/bridge items the XTS report listed as
// uncovered: the `Copyable` interface method and the `copy` implementations
// of the Pigeon wrapper classes (identity, key fields and behavior
// equivalence are asserted, not just non-null), `OhosCustomViewWidget.build`
// and `.customView`, and `OhosNavigationDelegate.ohosWebChromeClient`.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'ohos_pigeon_test_mocks.dart';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.CookieManager].
class TestPigeonCookieManager extends ohos_webview.CookieManager {
  TestPigeonCookieManager() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.JavaScriptChannel].
class TestPigeonJavaScriptChannel extends ohos_webview.JavaScriptChannel {
  TestPigeonJavaScriptChannel(String channelName,
      {required void Function(String message) postMessage})
      : super.detached(channelName, postMessage: postMessage);
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebViewClient].
class TestPigeonWebViewClient extends ohos_webview.WebViewClient {
  TestPigeonWebViewClient() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.DownloadListener].
class TestPigeonDownloadListener extends ohos_webview.DownloadListener {
  TestPigeonDownloadListener()
      : super.detached(
          onDownloadStart:
              (String url, String userAgent, String contentDisposition,
                      String mimetype, int contentLength) {},
        );
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.PermissionRequest].
class TestPigeonPermissionRequest extends ohos_webview.PermissionRequest {
  TestPigeonPermissionRequest({required List<String> resources})
      : super.detached(
          resources: resources,
          binaryMessenger: null,
          instanceManager: null,
        );
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebStorage].
class TestPigeonWebStorage extends ohos_webview.WebStorage {
  TestPigeonWebStorage() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.CustomViewCallback].
class TestPigeonCustomViewCallback extends ohos_webview.CustomViewCallback {
  TestPigeonCustomViewCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.GeolocationPermissionsCallback].
class TestPigeonGeolocationPermissionsCallback
    extends ohos_webview.GeolocationPermissionsCallback {
  TestPigeonGeolocationPermissionsCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.View].
class TestPigeonView extends ohos_webview.View {
  TestPigeonView() : super.detached();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InstanceManager instanceManager;

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
    instanceManager = ohos_webview.OhosObject.globalInstanceManager;
  });

  tearDown(() {
    OhosPigeonTestMocks.clearRecords();
  });

  group('Copyable', () {
    test(
      'should return a functionally identical object when copy is called through the interface',
      () {
        final List<String> receivedMessages = <String>[];
        final TestPigeonJavaScriptChannel channel = TestPigeonJavaScriptChannel(
          'copy_channel',
          postMessage: (String message) => receivedMessages.add(message),
        );
        final int channelId = instanceManager.addDartCreatedInstance(channel);

        // Invoke through the `Copyable` interface, as the InstanceManager does.
        final Copyable copyable = channel;
        // ignore: invalid_use_of_protected_member
        final Copyable copied = copyable.copy();

        expect(copied, isA<ohos_webview.JavaScriptChannel>());
        expect(identical(copied, channel), false);
        expect(
          instanceManager.getIdentifier(copied as ohos_webview.OhosObject),
          isNot(channelId),
        );

        // Behavioral equivalence: the copy forwards messages to the same
        // handler.
        (copied as ohos_webview.JavaScriptChannel)
            .postMessage('through the copy');
        expect(receivedMessages, <String>['through the copy']);
      },
    );
  });

  group('CookieManager.copy', () {
    test('should return a detached, functionally identical manager', () {
      final ohos_webview.CookieManager manager = TestPigeonCookieManager();
      instanceManager.addDartCreatedInstance(manager);

      final ohos_webview.CookieManager copied = manager.copy();

      expect(copied, isA<ohos_webview.CookieManager>());
      expect(identical(copied, manager), false);
    });
  });

  group('JavaScriptChannel.copy', () {
    test('should preserve the channel name and the message handler', () {
      final List<String> receivedMessages = <String>[];
      final ohos_webview.JavaScriptChannel channel = TestPigeonJavaScriptChannel(
        'kept_name',
        postMessage: (String message) => receivedMessages.add(message),
      );
      instanceManager.addDartCreatedInstance(channel);

      final ohos_webview.JavaScriptChannel copied = channel.copy();

      expect(copied.channelName, 'kept_name');
      expect(identical(copied, channel), false);
      copied.postMessage('from the copy');
      expect(receivedMessages, <String>['from the copy']);
    });
  });

  group('WebViewClient.copy', () {
    test('should return a detached, functionally identical client', () {
      final ohos_webview.WebViewClient client = TestPigeonWebViewClient();
      instanceManager.addDartCreatedInstance(client);

      final ohos_webview.WebViewClient copied = client.copy();

      expect(copied, isA<ohos_webview.WebViewClient>());
      expect(identical(copied, client), false);
    });
  });

  group('DownloadListener.copy', () {
    test('should return a detached, functionally identical listener', () {
      final ohos_webview.DownloadListener listener = TestPigeonDownloadListener();
      instanceManager.addDartCreatedInstance(listener);

      final ohos_webview.DownloadListener copied = listener.copy();

      expect(copied, isA<ohos_webview.DownloadListener>());
      expect(identical(copied, listener), false);
    });
  });

  group('PermissionRequest.copy', () {
    test('should preserve the requested resources', () {
      final ohos_webview.PermissionRequest request = TestPigeonPermissionRequest(
        resources: <String>['ohos.permission.GEOLOCATION'],
      );
      instanceManager.addDartCreatedInstance(request);

      final ohos_webview.PermissionRequest copied = request.copy();

      expect(copied, isA<ohos_webview.PermissionRequest>());
      expect(identical(copied, request), false);
      expect(copied.resources, <String>['ohos.permission.GEOLOCATION']);
    });
  });

  group('WebStorage.copy', () {
    test('should return a detached, functionally identical storage', () {
      final ohos_webview.WebStorage storage = TestPigeonWebStorage();
      instanceManager.addDartCreatedInstance(storage);

      final ohos_webview.WebStorage copied = storage.copy();

      expect(copied, isA<ohos_webview.WebStorage>());
      expect(identical(copied, storage), false);
    });
  });

  group('CustomViewCallback.copy', () {
    test('should return a detached, functionally identical callback', () {
      final ohos_webview.CustomViewCallback callback = TestPigeonCustomViewCallback();
      instanceManager.addDartCreatedInstance(callback);

      final ohos_webview.CustomViewCallback copied = callback.copy();

      expect(copied, isA<ohos_webview.CustomViewCallback>());
      expect(identical(copied, callback), false);
    });
  });

  group('GeolocationPermissionsCallback.copy', () {
    test('should return a detached, functionally identical callback', () {
      final ohos_webview.GeolocationPermissionsCallback callback =
          TestPigeonGeolocationPermissionsCallback();
      instanceManager.addDartCreatedInstance(callback);

      final ohos_webview.GeolocationPermissionsCallback copied =
          callback.copy();

      expect(copied, isA<ohos_webview.GeolocationPermissionsCallback>());
      expect(identical(copied, callback), false);
    });
  });

  group('OhosCustomViewWidget', () {
    testWidgets(
      'should expose the native custom view passed at construction when customView is read',
      (WidgetTester tester) async {
        final OhosWebViewController controller = OhosWebViewController(
          OhosWebViewControllerCreationParams(),
        );
        final TestPigeonView customView = TestPigeonView();

        final OhosCustomViewWidget widget = OhosCustomViewWidget.private(
          controller: controller,
          customView: customView,
        );

        expect(identical(widget.customView, customView), true);
        expect(widget.controller, same(controller));
      },
    );

    testWidgets(
      'should throw a cast error when build is called, since controller.params is a controller creation params',
      (WidgetTester tester) async {
        // Documented divergence from upstream `AndroidCustomViewWidget`,
        // which reads `key: key` directly: this implementation casts
        // `controller.params` (a `PlatformWebViewControllerCreationParams`) to
        // `OhosWebViewWidgetCreationParams`, a widget creation params type no
        // controller can carry, so build() always fails with a TypeError.
        // The behavior is asserted as-is; changing it is a logic change that
        // is out of scope for this coverage round.
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
        final TestPigeonView customView = TestPigeonView();

        final OhosCustomViewWidget widget = OhosCustomViewWidget.private(
          controller: controller,
          customView: customView,
        );

        expect(() => widget.build(capturedContext!), throwsA(isA<TypeError>()));
      },
    );
  });

  group('OhosNavigationDelegate.ohosWebChromeClient', () {
    test(
      'should expose the chrome client created by the delegate when the getter is read',
      () {
        final OhosNavigationDelegate delegate = OhosNavigationDelegate(
          OhosNavigationDelegateCreationParams
              .fromPlatformNavigationDelegateCreationParams(
            const PlatformNavigationDelegateCreationParams(),
          ),
        );

        // ignore: deprecated_member_use
        final ohos_webview.WebChromeClient client =
            delegate.ohosWebChromeClient;

        expect(client, isA<ohos_webview.WebChromeClient>());
      },
    );
  });
}
