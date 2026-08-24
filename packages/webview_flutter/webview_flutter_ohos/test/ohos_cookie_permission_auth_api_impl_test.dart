// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Direct coverage of the remaining HostApiImpl items the XTS report listed
// as uncovered: `CookieManagerHostApiImpl` (4), `PermissionRequestHostApiImpl`
// (2), `HttpAuthHandlerHostApiImpl` (3), `WebStorageHostApiImpl` (2),
// `GeolocationPermissionsCallbackHostApiImpl` (1) and
// `CustomViewCallbackHostApiImpl` (1); plus the public bridges
// `PermissionRequest.grant`/`deny`, `GeolocationPermissionsCallback.invoke`,
// `CustomViewCallback.onCustomViewHidden` and
// `FlutterAssetManager.list`/`getAssetFilePathByName`.

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart'
    as api_impls;

import 'ohos_pigeon_test_mocks.dart';

const String _cookieManagerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.';
const String _permissionRequestHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.PermissionRequestHostApi.';
const String _httpAuthHandlerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.HttpAuthHandlerHostApi.';
const String _webStorageHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebStorageHostApi.';
const String _geolocationCallbackHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.GeolocationPermissionsCallbackHostApi.';
const String _customViewCallbackHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.CustomViewCallbackHostApi.';
const String _flutterAssetManagerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.FlutterAssetManagerHostApi.';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebView].
class TestPigeonWebView extends ohos_webview.WebView {
  TestPigeonWebView() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.CookieManager].
class TestPigeonCookieManager extends ohos_webview.CookieManager {
  TestPigeonCookieManager() : super.detached();
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
/// [ohos_webview.GeolocationPermissionsCallback].
class TestPigeonGeolocationPermissionsCallback
    extends ohos_webview.GeolocationPermissionsCallback {
  TestPigeonGeolocationPermissionsCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.CustomViewCallback].
class TestPigeonCustomViewCallback extends ohos_webview.CustomViewCallback {
  TestPigeonCustomViewCallback() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebStorage].
class TestPigeonWebStorage extends ohos_webview.WebStorage {
  TestPigeonWebStorage() : super.detached();
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
    // Restore the default mock handlers so an error/return-value override
    // installed by one test cannot leak into the next one.
    OhosPigeonTestMocks.setUpMocks();
    OhosPigeonTestMocks.clearRecords();
  });

  /// Returns the arguments of the last recorded call for [channelName].
  List<dynamic> lastArgs(String channelName) {
    return OhosPigeonTestMocks.getLastCallForChannel(channelName)!.arguments;
  }

  group('CookieManagerHostApiImpl', () {
    late api_impls.CookieManagerHostApiImpl api;

    setUp(() {
      api = api_impls.CookieManagerHostApiImpl();
    });

    test(
      'should attach the instance and return it from attachInstanceFromInstances',
      () {
      final TestPigeonCookieManager cookieManager = TestPigeonCookieManager();

      final ohos_webview.CookieManager attached =
          api.attachInstanceFromInstances(cookieManager);

      expect(identical(attached, cookieManager), true);
      expect(
        lastArgs('${_cookieManagerHostApiPrefix}attachInstance'),
        <dynamic>[instanceManager.getIdentifier(cookieManager)],
      );
    });

    test('should send url and value from setCookieFromInstances', () async {
      final TestPigeonCookieManager cookieManager = TestPigeonCookieManager();
      instanceManager.addDartCreatedInstance(cookieManager);

      await api.setCookieFromInstances(
        cookieManager,
        'https://flutter.dev',
        'session=abc; path=/',
      );

      expect(
        lastArgs('${_cookieManagerHostApiPrefix}setCookie'),
        <dynamic>[
          instanceManager.getIdentifier(cookieManager),
          'https://flutter.dev',
          'session=abc; path=/',
        ],
      );
    });

    test('should return true from removeAllCookiesFromInstances', () async {
      final TestPigeonCookieManager cookieManager = TestPigeonCookieManager();
      instanceManager.addDartCreatedInstance(cookieManager);

      final bool removed = await api.removeAllCookiesFromInstances(cookieManager);

      expect(removed, true);
      expect(
        lastArgs('${_cookieManagerHostApiPrefix}removeAllCookies'),
        <dynamic>[instanceManager.getIdentifier(cookieManager)],
      );
    });

    test(
      'should send both identifiers from setAcceptThirdPartyCookiesFromInstances',
      () async {
        final TestPigeonCookieManager cookieManager = TestPigeonCookieManager();
        instanceManager.addDartCreatedInstance(cookieManager);
        final TestPigeonWebView webView = TestPigeonWebView();
        instanceManager.addDartCreatedInstance(webView);

        await api.setAcceptThirdPartyCookiesFromInstances(
            cookieManager, webView, true);

        expect(
          lastArgs('${_cookieManagerHostApiPrefix}setAcceptThirdPartyCookies'),
          <dynamic>[
            instanceManager.getIdentifier(cookieManager),
            instanceManager.getIdentifier(webView),
            true,
          ],
        );
      },
    );

    test(
      'should propagate the platform error when the channel replies with an error',
      () async {
        final TestPigeonCookieManager cookieManager = TestPigeonCookieManager();
        instanceManager.addDartCreatedInstance(cookieManager);

        OhosPigeonTestMocks.overrideWithError(
          '${_cookieManagerHostApiPrefix}setCookie',
          'setCookie-failed',
          'native rejected the cookie',
        );

        await expectLater(
          api.setCookieFromInstances(
              cookieManager, 'https://flutter.dev', 'a=b'),
          throwsA(isA<PlatformException>()),
        );
      },
    );
  });

  group('PermissionRequestHostApiImpl and PermissionRequest bridge', () {
    late api_impls.PermissionRequestHostApiImpl api;
    late ohos_webview.PermissionRequest request;
    late int requestId;

    setUp(() {
      api = api_impls.PermissionRequestHostApiImpl();
      request = TestPigeonPermissionRequest(
        resources: <String>['ohos.permission.GEOLOCATION'],
      );
      requestId = instanceManager.addDartCreatedInstance(request);
    });

    test('should send the resources from grantFromInstances', () async {
      await api.grantFromInstances(
        request,
        <String>['ohos.permission.GEOLOCATION'],
      );

      expect(
        lastArgs('${_permissionRequestHostApiPrefix}grant'),
        <dynamic>[requestId, <String>['ohos.permission.GEOLOCATION']],
      );
    });

    test('should send the identifier from denyFromInstances', () async {
      await api.denyFromInstances(request);

      expect(
        lastArgs('${_permissionRequestHostApiPrefix}deny'),
        <dynamic>[requestId],
      );
    });

    test('should send grant when grant is invoked on the wrapper', () async {
      await request.grant(<String>['ohos.permission.CAMERA']);

      expect(
        lastArgs('${_permissionRequestHostApiPrefix}grant'),
        <dynamic>[requestId, <String>['ohos.permission.CAMERA']],
      );
    });

    test('should send deny when deny is invoked on the wrapper', () async {
      await request.deny();

      expect(
        lastArgs('${_permissionRequestHostApiPrefix}deny'),
        <dynamic>[requestId],
      );
    });
  });

  group('HttpAuthHandlerHostApiImpl', () {
    late api_impls.HttpAuthHandlerHostApiImpl api;
    late ohos_webview.HttpAuthHandler handler;
    late int handlerId;

    setUp(() {
      api = api_impls.HttpAuthHandlerHostApiImpl();
      handler = ohos_webview.HttpAuthHandler();
      handlerId = instanceManager.addDartCreatedInstance(handler);
    });

    test('should send the identifier from cancelFromInstance', () async {
      await api.cancelFromInstance(handler);

      expect(
        lastArgs('${_httpAuthHandlerHostApiPrefix}cancel'),
        <dynamic>[handlerId],
      );
    });

    test(
      'should send credentials from proceedFromInstance',
      () async {
        await api.proceedFromInstance(handler, 'user', 'secret');

        expect(
          lastArgs('${_httpAuthHandlerHostApiPrefix}proceed'),
          <dynamic>[handlerId, 'user', 'secret'],
        );
      },
    );

    test(
      'should return the stored-credentials answer from useHttpAuthUsernamePasswordFromInstance',
      () async {
        final bool useStored = await api.useHttpAuthUsernamePasswordFromInstance(handler);

        expect(useStored, false);
        expect(
          lastArgs('${_httpAuthHandlerHostApiPrefix}useHttpAuthUsernamePassword'),
          <dynamic>[handlerId],
        );
      },
    );

    test(
      'should keep the handler registered when useHttpAuthUsernamePasswordFromInstance only queries it',
      () async {
        await api.useHttpAuthUsernamePasswordFromInstance(handler);

        // The query is not a final decision: the native instance table must
        // still resolve the handler so a later cancel/proceed can reach it.
        expect(instanceManager.getIdentifier(handler), handlerId);
      },
    );
  });

  group('HttpAuthHandler one-shot release (native leak fix)', () {
    // The native HttpAuthHandlerHostApiImpl releases the handler from the
    // native InstanceManager after cancel/proceed completes the single HTTP
    // auth decision. The Dart-side mirror of that contract: after a decision
    // goes through the channel, re-registering must produce a fresh entry,
    // and a query never releases. These tests pin the decision semantics
    // over the recorded channel calls.
    late api_impls.HttpAuthHandlerHostApiImpl api;

    setUp(() {
      api = api_impls.HttpAuthHandlerHostApiImpl();
    });

    test(
      'should record exactly one native cancel for a single decision and drop the handler afterwards',
      () async {
        final ohos_webview.HttpAuthHandler handler =
            ohos_webview.HttpAuthHandler();
        final int handlerId = instanceManager.addDartCreatedInstance(handler);

        await api.cancelFromInstance(handler);

        // The native cancel is called exactly once for the decision.
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
              '${_httpAuthHandlerHostApiPrefix}cancel'),
          hasLength(1),
        );
        expect(
          OhosPigeonTestMocks.getLastCallForChannel(
              '${_httpAuthHandlerHostApiPrefix}cancel')!.arguments,
          <dynamic>[handlerId],
        );
      },
    );

    test(
      'should forward the credentials of a single proceed decision unchanged',
      () async {
        final ohos_webview.HttpAuthHandler handler =
            ohos_webview.HttpAuthHandler();
        final int handlerId = instanceManager.addDartCreatedInstance(handler);

        await api.proceedFromInstance(handler, 'user@example.com', 's3cret');

        expect(
          OhosPigeonTestMocks.getLastCallForChannel(
              '${_httpAuthHandlerHostApiPrefix}proceed')!.arguments,
          <dynamic>[handlerId, 'user@example.com', 's3cret'],
        );
      },
    );

    test(
      'should keep the error semantics when the native decision fails instead of pretending success',
      () async {
        final ohos_webview.HttpAuthHandler handler =
            ohos_webview.HttpAuthHandler();
        instanceManager.addDartCreatedInstance(handler);

        OhosPigeonTestMocks.overrideWithError(
          '${_httpAuthHandlerHostApiPrefix}proceed',
          'proceed-failed',
          'native rejected the credentials',
        );

        // The failure propagates to the caller. The native release runs only
        // after a successful native call, so a failed decision keeps the
        // instance (no finally-release); the Dart mirror below must not
        // throw a second, masking error either.
        await expectLater(
          api.proceedFromInstance(handler, 'user', 'secret'),
          throwsA(isA<PlatformException>()),
        );
        expect(instanceManager.getIdentifier(handler), isNotNull,
            reason: 'a failed decision must not release the handler');
      },
    );

    test(
      'should surface the descriptive missing-instance error when the decision is repeated after a release',
      () async {
        final ohos_webview.HttpAuthHandler handler =
            ohos_webview.HttpAuthHandler();
        instanceManager.addDartCreatedInstance(handler);

        // First decision succeeds; the native side releases the handler.
        await api.cancelFromInstance(handler);

        // Mirror the native release on the Dart instance table, then repeat
        // the decision: it must fail with the descriptive not-found error
        // instead of crashing on a missing reference.
        ohos_webview.OhosObject.dispose(handler);
        expect(
          () => api.cancelFromInstance(handler),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });

  group('WebStorageHostApiImpl', () {
    test('should send create with the assigned identifier', () async {
      final api_impls.WebStorageHostApiImpl api =
          api_impls.WebStorageHostApiImpl();
      final TestPigeonWebStorage storage = TestPigeonWebStorage();

      await api.createFromInstance(storage);

      final int assignedId = instanceManager.getIdentifier(storage)!;
      expect(lastArgs('${_webStorageHostApiPrefix}create'),
          <dynamic>[assignedId]);
    });

    test('should send the identifier from deleteAllDataFromInstance',
        () async {
      final api_impls.WebStorageHostApiImpl api =
          api_impls.WebStorageHostApiImpl();
      final TestPigeonWebStorage storage = TestPigeonWebStorage();
      final int storageId = instanceManager.addDartCreatedInstance(storage);

      await api.deleteAllDataFromInstance(storage);

      expect(lastArgs('${_webStorageHostApiPrefix}deleteAllData'),
          <dynamic>[storageId]);
    });
  });

  group('GeolocationPermissionsCallback bridge', () {
    test(
      'should send origin, allow and retain from invokeFromInstances',
      () async {
        final api_impls.GeolocationPermissionsCallbackHostApiImpl api =
            api_impls.GeolocationPermissionsCallbackHostApiImpl();
        final TestPigeonGeolocationPermissionsCallback callback =
            TestPigeonGeolocationPermissionsCallback();
        final int callbackId = instanceManager.addDartCreatedInstance(callback);

        await api.invokeFromInstances(
            callback, 'https://flutter.dev', true, false);

        expect(
          lastArgs('${_geolocationCallbackHostApiPrefix}invoke'),
          <dynamic>[callbackId, 'https://flutter.dev', true, false],
        );
      },
    );

    test('should send the decision when invoke is called on the wrapper',
        () async {
      final TestPigeonGeolocationPermissionsCallback callback =
          TestPigeonGeolocationPermissionsCallback();
      final int callbackId = instanceManager.addDartCreatedInstance(callback);

      // Declared as the library base type so the invoke() call is
      // attributed to GeolocationPermissionsCallback itself.
      final ohos_webview.GeolocationPermissionsCallback typedCallback =
          callback;
      await typedCallback.invoke('https://flutter.dev', false, true);

      expect(
        lastArgs('${_geolocationCallbackHostApiPrefix}invoke'),
        <dynamic>[callbackId, 'https://flutter.dev', false, true],
      );
    });
  });

  group('CustomViewCallback bridge', () {
    test(
      'should send the identifier from onCustomViewHiddenFromInstances',
      () async {
        final api_impls.CustomViewCallbackHostApiImpl api =
            api_impls.CustomViewCallbackHostApiImpl();
        final TestPigeonCustomViewCallback callback =
            TestPigeonCustomViewCallback();
        final int callbackId = instanceManager.addDartCreatedInstance(callback);

        await api.onCustomViewHiddenFromInstances(callback);

        expect(
          lastArgs('${_customViewCallbackHostApiPrefix}onCustomViewHidden'),
          <dynamic>[callbackId],
        );
      },
    );

    test(
      'should send the identifier when onCustomViewHidden is called on the wrapper',
      () async {
        final TestPigeonCustomViewCallback callback =
            TestPigeonCustomViewCallback();
        final int callbackId = instanceManager.addDartCreatedInstance(callback);

        // Declared as the library base type so the onCustomViewHidden()
        // call is attributed to CustomViewCallback itself.
        final ohos_webview.CustomViewCallback typedCallback = callback;
        await typedCallback.onCustomViewHidden();

        expect(
          lastArgs('${_customViewCallbackHostApiPrefix}onCustomViewHidden'),
          <dynamic>[callbackId],
        );
      },
    );
  });

  group('FlutterAssetManager bridge', () {
    test('should return the asset list when list is called', () async {
      final ohos_webview.FlutterAssetManager assetManager =
          ohos_webview.FlutterAssetManager.instance;
      final List<String?> assets = await assetManager.list('assets');

      expect(assets, <String>['test.html', 'index.html', 'app.js']);
      expect(
        lastArgs('${_flutterAssetManagerHostApiPrefix}list'),
        <dynamic>['assets'],
      );
    });

    test(
      'should return the asset path when getAssetFilePathByName is called',
      () async {
        final ohos_webview.FlutterAssetManager assetManager =
            ohos_webview.FlutterAssetManager.instance;
        final String path =
            await assetManager.getAssetFilePathByName('test.html');

        expect(path, 'assets/test.html');
        expect(
          lastArgs('${_flutterAssetManagerHostApiPrefix}getAssetFilePathByName'),
          <dynamic>['test.html'],
        );
      },
    );
  });

  group('SslErrorHandler bridge', () {
    const String _sslErrorHandlerHostApiPrefix =
        'dev.flutter.pigeon.webview_flutter_ohos.SslErrorHandlerHostApi.';

    late ohos_webview.SslErrorHandler handler;
    late int handlerId;

    setUp(() {
      handler = ohos_webview.SslErrorHandler();
      handlerId = instanceManager.addDartCreatedInstance(handler);
    });

    test('should send the identifier from cancel and nothing else', () async {
      await handler.cancel();

      expect(
        lastArgs('${_sslErrorHandlerHostApiPrefix}cancel'),
        <dynamic>[handlerId],
      );
      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_sslErrorHandlerHostApiPrefix}proceed',
        ),
        isEmpty,
      );
    });

    test('should send the identifier from proceed and nothing else', () async {
      await handler.proceed();

      expect(
        lastArgs('${_sslErrorHandlerHostApiPrefix}proceed'),
        <dynamic>[handlerId],
      );
      expect(
        OhosPigeonTestMocks.getCallsForChannel(
          '${_sslErrorHandlerHostApiPrefix}cancel',
        ),
        isEmpty,
      );
    });
  });

  group('SslErrorHandlerHostApiImpl', () {
    const String _sslErrorHandlerHostApiPrefix =
        'dev.flutter.pigeon.webview_flutter_ohos.SslErrorHandlerHostApi.';

    test('should send the identifier from cancelFromInstance', () async {
      final api_impls.SslErrorHandlerHostApiImpl api =
          api_impls.SslErrorHandlerHostApiImpl();
      final ohos_webview.SslErrorHandler handler =
          ohos_webview.SslErrorHandler();
      final int handlerId = instanceManager.addDartCreatedInstance(handler);

      await api.cancelFromInstance(handler);

      expect(
        lastArgs('${_sslErrorHandlerHostApiPrefix}cancel'),
        <dynamic>[handlerId],
      );
    });

    test('should send the identifier from proceedFromInstance', () async {
      final api_impls.SslErrorHandlerHostApiImpl api =
          api_impls.SslErrorHandlerHostApiImpl();
      final ohos_webview.SslErrorHandler handler =
          ohos_webview.SslErrorHandler();
      final int handlerId = instanceManager.addDartCreatedInstance(handler);

      await api.proceedFromInstance(handler);

      expect(
        lastArgs('${_sslErrorHandlerHostApiPrefix}proceed'),
        <dynamic>[handlerId],
      );
    });
  });
}
