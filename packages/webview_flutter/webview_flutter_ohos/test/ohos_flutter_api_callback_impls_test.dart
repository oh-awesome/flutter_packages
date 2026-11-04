// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Unit tests for the Pigeon `*FlutterApiImpl` callback implementations that
// forward native-side events to Dart instances registered in an
// `InstanceManager`, plus `OhosWebViewFlutterApis.ensureSetUp`. Each case
// registers real instances with a fresh manager, invokes the callback method
// exactly as the native side would, and asserts the forwarded arguments —
// these callbacks cannot be exercised through the HostApi mocks because they
// are invoked by the platform, so they are driven directly here.

import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart' as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview.g.dart' as pigeon;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart';

import 'ohos_pigeon_test_mocks.dart';

InstanceManager _newManager() => InstanceManager(onWeakReferenceRemoved: (int identifier) {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(OhosPigeonTestMocks.setUpMocks);

  setUp(OhosPigeonTestMocks.clearRecords);

  tearDown(OhosPigeonTestMocks.clearRecords);

  group('OhosWebViewFlutterApis', () {
    test('ensureSetUp should register the Flutter Api implementations and be '
        'idempotent', () {
      final apis = OhosWebViewFlutterApis();

      apis.ensureSetUp();
      // The static guard makes repeated calls a no-op.
      apis.ensureSetUp();

      expect(apis.webViewClientFlutterApi, isA<WebViewClientFlutterApiImpl>());
      expect(apis.webChromeClientFlutterApi, isA<WebChromeClientFlutterApiImpl>());
      expect(apis.webViewFlutterApi, isA<WebViewFlutterApiImpl>());
      expect(apis.javaScriptChannelFlutterApi, isA<JavaScriptChannelFlutterApiImpl>());
      expect(OhosWebViewFlutterApis.instance, isA<OhosWebViewFlutterApis>());
    });
  });

  group('OhosObjectFlutterApiImpl', () {
    test('dispose should remove the strongly referenced instance of the '
        'identifier', () {
      final InstanceManager manager = _newManager();
      final instance = ohos_webview.View.detached();
      manager.addHostCreatedInstance(instance, 43);

      final api = OhosObjectFlutterApiImpl(instanceManager: manager);
      api.dispose(43);

      expect(manager.remove<ohos_webview.View>(43), isNull);
      // Disposing an unknown identifier is a no-op.
      api.dispose(9999);
    });
  });

  group('WebViewFlutterApiImpl', () {
    test('create should add a detached WebView for the identifier', () {
      final InstanceManager manager = _newManager();
      final api = WebViewFlutterApiImpl(instanceManager: manager);

      api.create(7);

      expect(
        manager.getInstanceWithWeakReference<ohos_webview.WebView>(7),
        isA<ohos_webview.WebView>(),
      );
    });

    test('onScrollChanged should forward the scroll offsets to the WebView', () {
      final InstanceManager manager = _newManager();
      final receivedOffsets = <int>[];
      final webView = ohos_webview.WebView.detached(
        onScrollChanged: (int left, int top, int oldLeft, int oldTop) =>
            receivedOffsets.addAll(<int>[left, top, oldLeft, oldTop]),
      );
      manager.addHostCreatedInstance(webView, 201);

      WebViewFlutterApiImpl(instanceManager: manager).onScrollChanged(201, 1, 2, 3, 4);

      expect(receivedOffsets, <int>[1, 2, 3, 4]);
    });
  });

  group('JavaScriptChannelFlutterApiImpl', () {
    test('postMessage should forward the message to the JavaScriptChannel', () {
      final InstanceManager manager = _newManager();
      final receivedMessages = <String>[];
      final channel = ohos_webview.JavaScriptChannel.detached(
        'testChannel',
        postMessage: receivedMessages.add,
      );
      manager.addHostCreatedInstance(channel, 31);

      JavaScriptChannelFlutterApiImpl(instanceManager: manager).postMessage(31, 'hello from JS');

      expect(receivedMessages, <String>['hello from JS']);
    });
  });

  group('WebViewClientFlutterApiImpl', () {
    test('onPageFinished should forward the url to the WebViewClient callback', () {
      final InstanceManager manager = _newManager();
      String? receivedUrl;
      Object? receivedWebView;
      final client = ohos_webview.WebViewClient.detached(
        onPageFinished: (ohos_webview.WebView webView, String url) {
          receivedWebView = webView;
          receivedUrl = url;
        },
      );
      final webView = ohos_webview.WebView.detached();
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(webView, 12);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).onPageFinished(11, 12, 'https://flutter.dev');

      expect(receivedWebView, same(webView));
      expect(receivedUrl, 'https://flutter.dev');
    });

    test('onPageStarted should forward the url to the WebViewClient callback', () {
      final InstanceManager manager = _newManager();
      String? receivedUrl;
      final client = ohos_webview.WebViewClient.detached(
        onPageStarted: (ohos_webview.WebView webView, String url) => receivedUrl = url,
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).onPageStarted(11, 12, 'https://flutter.dev');

      expect(receivedUrl, 'https://flutter.dev');
    });

    test('onReceivedError should forward the legacy error to the WebViewClient '
        'callback', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      // ignore: deprecated_member_use_from_same_package
      final client = ohos_webview.WebViewClient.detached(
        // ignore: deprecated_member_use_from_same_package
        onReceivedError:
            (ohos_webview.WebView webView, int errorCode, String description, String failingUrl) =>
                received.addAll(<Object?>[webView, errorCode, description, failingUrl]),
      );
      final webView = ohos_webview.WebView.detached();
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(webView, 12);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).onReceivedError(11, 12, -1, 'net error', 'https://flutter.dev');

      expect(received, <Object?>[webView, -1, 'net error', 'https://flutter.dev']);
    });

    test('onReceivedRequestError should forward the converted request and error', () {
      final InstanceManager manager = _newManager();
      ohos_webview.WebResourceRequest? receivedRequest;
      ohos_webview.WebResourceError? receivedError;
      final client = ohos_webview.WebViewClient.detached(
        onReceivedRequestError:
            (
              ohos_webview.WebView webView,
              ohos_webview.WebResourceRequest request,
              ohos_webview.WebResourceError error,
            ) {
              receivedRequest = request;
              receivedError = error;
            },
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(instanceManager: manager).onReceivedRequestError(
        11,
        12,
        pigeon.WebResourceRequestData(
          url: 'https://flutter.dev',
          isForMainFrame: true,
          isRedirect: false,
          hasGesture: true,
          method: 'GET',
          requestHeaders: <String?, String?>{},
        ),
        pigeon.WebResourceErrorData(errorCode: -2, description: 'not found'),
      );

      expect(receivedRequest?.url, 'https://flutter.dev');
      expect(receivedRequest?.isForMainFrame, isTrue);
      expect(receivedRequest?.method, 'GET');
      expect(receivedError?.errorCode, -2);
      expect(receivedError?.description, 'not found');
    });

    test('requestLoading should forward the converted request to the '
        'WebViewClient callback', () {
      final InstanceManager manager = _newManager();
      String? receivedUrl;
      final client = ohos_webview.WebViewClient.detached(
        requestLoading: (ohos_webview.WebView webView, ohos_webview.WebResourceRequest request) =>
            receivedUrl = request.url,
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(instanceManager: manager).requestLoading(
        11,
        12,
        pigeon.WebResourceRequestData(
          url: 'https://example.com',
          isForMainFrame: false,
          hasGesture: false,
          method: 'POST',
          requestHeaders: <String?, String?>{},
        ),
      );

      expect(receivedUrl, 'https://example.com');
    });

    test('urlLoading should forward the url to the WebViewClient callback', () {
      final InstanceManager manager = _newManager();
      String? receivedUrl;
      final client = ohos_webview.WebViewClient.detached(
        urlLoading: (ohos_webview.WebView webView, String url) => receivedUrl = url,
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).urlLoading(11, 12, 'https://example.com');

      expect(receivedUrl, 'https://example.com');
    });

    test('doUpdateVisitedHistory should forward the url and isReload flag', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final client = ohos_webview.WebViewClient.detached(
        doUpdateVisitedHistory: (ohos_webview.WebView webView, String url, bool isReload) =>
            received.addAll(<Object?>[url, isReload]),
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).doUpdateVisitedHistory(11, 12, 'https://flutter.dev', true);

      expect(received, <Object?>['https://flutter.dev', true]);
    });

    test('onReceivedHttpAuthRequest should forward the handler, host and realm', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final handler = ohos_webview.HttpAuthHandler();
      final client = ohos_webview.WebViewClient.detached(
        onReceivedHttpAuthRequest:
            (
              ohos_webview.WebView webView,
              ohos_webview.HttpAuthHandler authHandler,
              String host,
              String realm,
            ) => received.addAll(<Object?>[authHandler, host, realm]),
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);
      manager.addHostCreatedInstance(handler, 13);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).onReceivedHttpAuthRequest(11, 12, 13, 'example.com', 'realm');

      expect(received, <Object?>[handler, 'example.com', 'realm']);
    });

    test('onReceivedHttpError should forward the converted request and error', () {
      final InstanceManager manager = _newManager();
      int? receivedErrorCode;
      String? receivedUrl;
      final client = ohos_webview.WebViewClient.detached(
        onReceivedHttpError:
            (
              ohos_webview.WebView webView,
              ohos_webview.WebResourceRequest request,
              ohos_webview.WebResourceError error,
            ) {
              receivedErrorCode = error.errorCode;
              receivedUrl = request.url;
            },
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);

      WebViewClientFlutterApiImpl(instanceManager: manager).onReceivedHttpError(
        11,
        12,
        pigeon.WebResourceRequestData(
          url: 'https://flutter.dev/404',
          isForMainFrame: true,
          hasGesture: false,
          method: 'GET',
          requestHeaders: <String?, String?>{},
        ),
        pigeon.WebResourceErrorData(errorCode: 404, description: 'http error'),
      );

      expect(receivedErrorCode, 404);
      expect(receivedUrl, 'https://flutter.dev/404');
    });

    test('onReceivedSslError should forward the handler and certificate details', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final handler = ohos_webview.SslErrorHandler();
      final client = ohos_webview.WebViewClient.detached(
        onReceivedSslError:
            (
              ohos_webview.WebView webView,
              ohos_webview.SslErrorHandler sslHandler,
              String url,
              String certificate,
              String description,
            ) => received.addAll(<Object?>[sslHandler, url, certificate, description]),
      );
      manager.addHostCreatedInstance(client, 11);
      manager.addHostCreatedInstance(ohos_webview.WebView.detached(), 12);
      manager.addHostCreatedInstance(handler, 13);

      WebViewClientFlutterApiImpl(
        instanceManager: manager,
      ).onReceivedSslError(11, 12, 13, 'https://flutter.dev', 'cert', 'ssl error');

      expect(received, <Object?>[handler, 'https://flutter.dev', 'cert', 'ssl error']);
    });
  });

  group('WebChromeClientFlutterApiImpl', () {
    test('onProgressChanged should forward the progress to the WebChromeClient', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final client = ohos_webview.WebChromeClient.detached(
        onProgressChanged: (ohos_webview.WebView webView, int progress) =>
            received.addAll(<Object?>[webView, progress]),
      );
      final webView = ohos_webview.WebView.detached();
      manager.addHostCreatedInstance(client, 21);
      manager.addHostCreatedInstance(webView, 22);

      WebChromeClientFlutterApiImpl(instanceManager: manager).onProgressChanged(21, 22, 88);

      expect(received, <Object?>[webView, 88]);
    });

    test('onGeolocationPermissionsShowPrompt should forward origin and callback', () async {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final callback = ohos_webview.GeolocationPermissionsCallback.detached();
      final client = ohos_webview.WebChromeClient.detached(
        onGeolocationPermissionsShowPrompt:
            (String origin, ohos_webview.GeolocationPermissionsCallback geoCallback) async {
              received.addAll(<Object?>[origin, geoCallback]);
            },
      );
      manager.addHostCreatedInstance(client, 21);
      manager.addHostCreatedInstance(callback, 23);

      WebChromeClientFlutterApiImpl(
        instanceManager: manager,
      ).onGeolocationPermissionsShowPrompt(21, 23, 'https://flutter.dev');

      expect(received, <Object?>['https://flutter.dev', callback]);
    });

    test('onGeolocationPermissionsHidePrompt should forward the client instance', () {
      final InstanceManager manager = _newManager();
      Object? receivedClient;
      final client = ohos_webview.WebChromeClient.detached(
        onGeolocationPermissionsHidePrompt: (ohos_webview.WebChromeClient instance) =>
            receivedClient = instance,
      );
      manager.addHostCreatedInstance(client, 21);

      WebChromeClientFlutterApiImpl(
        instanceManager: manager,
      ).onGeolocationPermissionsHidePrompt(21);

      expect(receivedClient, same(client));
    });

    test('onPermissionRequest should forward the request to the WebChromeClient', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final request = ohos_webview.PermissionRequest.detached(
        resources: <String>['camera'],
        binaryMessenger: null,
        instanceManager: null,
      );
      final client = ohos_webview.WebChromeClient.detached(
        onPermissionRequest:
            (
              ohos_webview.WebChromeClient instance,
              ohos_webview.PermissionRequest permissionRequest,
            ) => received.addAll(<Object?>[instance, permissionRequest]),
      );
      manager.addHostCreatedInstance(client, 21);
      manager.addHostCreatedInstance(request, 24);

      WebChromeClientFlutterApiImpl(instanceManager: manager).onPermissionRequest(21, 24);

      expect(received, <Object?>[client, request]);
    });

    test('onShowCustomView should forward the view and the hide callback', () {
      final InstanceManager manager = _newManager();
      final received = <Object?>[];
      final view = ohos_webview.View.detached();
      final customViewCallback = ohos_webview.CustomViewCallback.detached();
      final client = ohos_webview.WebChromeClient.detached(
        onShowCustomView:
            (
              ohos_webview.WebChromeClient instance,
              ohos_webview.View customView,
              ohos_webview.CustomViewCallback callback,
            ) => received.addAll(<Object?>[instance, customView, callback]),
      );
      manager.addHostCreatedInstance(client, 21);
      manager.addHostCreatedInstance(view, 25);
      manager.addHostCreatedInstance(customViewCallback, 26);

      WebChromeClientFlutterApiImpl(instanceManager: manager).onShowCustomView(21, 25, 26);

      expect(received, <Object?>[client, view, customViewCallback]);
    });

    test('onHideCustomView should forward the client instance', () {
      final InstanceManager manager = _newManager();
      Object? receivedClient;
      final client = ohos_webview.WebChromeClient.detached(
        onHideCustomView: (ohos_webview.WebChromeClient instance) => receivedClient = instance,
      );
      manager.addHostCreatedInstance(client, 21);

      WebChromeClientFlutterApiImpl(instanceManager: manager).onHideCustomView(21);

      expect(receivedClient, same(client));
    });

    test('onConsoleMessage should forward the console message to the client', () {
      final InstanceManager manager = _newManager();
      ohos_webview.ConsoleMessage? receivedMessage;
      final client = ohos_webview.WebChromeClient.detached(
        onConsoleMessage:
            (ohos_webview.WebChromeClient instance, ohos_webview.ConsoleMessage message) =>
                receivedMessage = message,
      );
      manager.addHostCreatedInstance(client, 21);

      final consoleMessage = ohos_webview.ConsoleMessage(
        lineNumber: 7,
        message: 'console.log',
        level: ohos_webview.ConsoleMessageLevel.warning,
        sourceId: 'https://flutter.dev',
      );
      WebChromeClientFlutterApiImpl(instanceManager: manager).onConsoleMessage(21, consoleMessage);

      expect(receivedMessage, same(consoleMessage));
      expect(receivedMessage?.message, 'console.log');
      expect(receivedMessage?.level, ohos_webview.ConsoleMessageLevel.warning);
    });
  });

  group('FileChooserParamsFlutterApiImpl', () {
    test('create should add a FileChooserParams with the forwarded parameters', () {
      final InstanceManager manager = _newManager();
      FileChooserParamsFlutterApiImpl(instanceManager: manager).create(
        61,
        true,
        <String?>['image/*', 'video/*'],
        ohos_webview.FileChooserMode.openMultiple,
        'attachment',
      );

      final ohos_webview.FileChooserParams params = manager
          .getInstanceWithWeakReference<ohos_webview.FileChooserParams>(61)!;
      expect(params.isCaptureEnabled, isTrue);
      expect(params.acceptTypes, <String>['image/*', 'video/*']);
      expect(params.mode, ohos_webview.FileChooserMode.openMultiple);
      expect(params.filenameHint, 'attachment');
    });
  });

  group('GeolocationPermissionsCallbackFlutterApiImpl', () {
    test('create should add a GeolocationPermissionsCallback for the identifier', () {
      final InstanceManager manager = _newManager();
      GeolocationPermissionsCallbackFlutterApiImpl(instanceManager: manager).create(62);

      expect(
        manager.getInstanceWithWeakReference<ohos_webview.GeolocationPermissionsCallback>(62),
        isA<ohos_webview.GeolocationPermissionsCallback>(),
      );
    });
  });

  group('PermissionRequestFlutterApiImpl', () {
    test('create should add a PermissionRequest with the forwarded resources', () {
      final InstanceManager manager = _newManager();
      PermissionRequestFlutterApiImpl(
        instanceManager: manager,
      ).create(63, <String?>['camera', 'microphone']);

      final ohos_webview.PermissionRequest request = manager
          .getInstanceWithWeakReference<ohos_webview.PermissionRequest>(63)!;
      expect(request.resources, <String>['camera', 'microphone']);
    });
  });

  group('CustomViewCallbackFlutterApiImpl', () {
    test('create should add a CustomViewCallback for the identifier', () {
      final InstanceManager manager = _newManager();
      CustomViewCallbackFlutterApiImpl(instanceManager: manager).create(64);

      expect(
        manager.getInstanceWithWeakReference<ohos_webview.CustomViewCallback>(64),
        isA<ohos_webview.CustomViewCallback>(),
      );
    });
  });

  group('ViewFlutterApiImpl', () {
    test('create should add a View for the identifier', () {
      final InstanceManager manager = _newManager();
      ViewFlutterApiImpl(instanceManager: manager).create(65);

      expect(manager.getInstanceWithWeakReference<ohos_webview.View>(65), isA<ohos_webview.View>());
    });
  });

  group('HttpAuthHandlerFlutterApiImpl', () {
    test('create should add an HttpAuthHandler for the identifier', () {
      final InstanceManager manager = _newManager();
      HttpAuthHandlerFlutterApiImpl(instanceManager: manager).create(66);

      expect(
        manager.getInstanceWithWeakReference<ohos_webview.HttpAuthHandler>(66),
        isA<ohos_webview.HttpAuthHandler>(),
      );
    });
  });

  group('SslErrorHandlerFlutterApiImpl', () {
    test('create should add an SslErrorHandler for the identifier', () {
      final InstanceManager manager = _newManager();
      SslErrorHandlerFlutterApiImpl(instanceManager: manager).create(67);

      expect(
        manager.getInstanceWithWeakReference<ohos_webview.SslErrorHandler>(67),
        isA<ohos_webview.SslErrorHandler>(),
      );
    });
  });
}
