// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Direct coverage of the client-related HostApiImpl and FlutterApiImpl items
// the XTS report listed as uncovered: `WebChromeClientHostApiImpl` (6),
// `WebChromeClientFlutterApiImpl` (4), `JavaScriptChannelHostApiImpl` (1),
// `WebViewClientHostApiImpl` (2) and `DownloadListenerHostApiImpl` (1).
// HostApi cases assert on the recorded Pigeon channel call; FlutterApi cases
// drive the Dart-side callback dispatch with registered instance identifiers.

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart'
    as api_impls;

import 'ohos_pigeon_test_mocks.dart';

const String _webChromeClientHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.';
const String _javaScriptChannelHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelHostApi.';
const String _webViewClientHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.';
const String _downloadListenerHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.DownloadListenerHostApi.';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebChromeClient].
class TestPigeonWebChromeClient extends ohos_webview.WebChromeClient {
  TestPigeonWebChromeClient({
    super.onJsAlert,
    super.onJsConfirm,
    super.onJsPrompt,
    super.onShowFileChooser,
  }) : super.detached();
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
/// [ohos_webview.WebView].
class TestPigeonWebView extends ohos_webview.WebView {
  TestPigeonWebView() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.FileChooserParams].
class TestPigeonFileChooserParams extends ohos_webview.FileChooserParams {
  TestPigeonFileChooserParams()
      : super.detached(
          isCaptureEnabled: false,
          acceptTypes: <String>['image/*'],
          filenameHint: null,
          mode: ohos_webview.FileChooserMode.open,
        );
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

  group('WebChromeClientHostApiImpl', () {
    late api_impls.WebChromeClientHostApiImpl api;

    setUp(() {
      api = api_impls.WebChromeClientHostApiImpl();
    });

    test('should send create with the assigned identifier', () async {
      final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();

      await api.createFromInstance(client);

      final int assignedId = instanceManager.getIdentifier(client)!;
      expect(lastArgs('${_webChromeClientHostApiPrefix}create'),
          <dynamic>[assignedId]);
    });

    test(
      'should send the value from setSynchronousReturnValueForOnShowFileChooserFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setSynchronousReturnValueForOnShowFileChooserFromInstance(
            client, true);

        expect(
          lastArgs(
              '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnShowFileChooser'),
          <dynamic>[id, true],
        );
      },
    );

    test(
      'should send the value from setSynchronousReturnValueForOnConsoleMessageFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setSynchronousReturnValueForOnConsoleMessageFromInstance(
            client, true);

        expect(
          lastArgs(
              '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnConsoleMessage'),
          <dynamic>[id, true],
        );
      },
    );

    test(
      'should send the value from setSynchronousReturnValueForOnJsAlertFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setSynchronousReturnValueForOnJsAlertFromInstance(
            client, true);

        expect(
          lastArgs(
              '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnJsAlert'),
          <dynamic>[id, true],
        );
      },
    );

    test(
      'should send the value from setSynchronousReturnValueForOnJsConfirmFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setSynchronousReturnValueForOnJsConfirmFromInstance(
            client, true);

        expect(
          lastArgs(
              '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnJsConfirm'),
          <dynamic>[id, true],
        );
      },
    );

    test(
      'should send the value from setSynchronousReturnValueForOnJsPromptFromInstance',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setSynchronousReturnValueForOnJsPromptFromInstance(
            client, true);

        expect(
          lastArgs(
              '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnJsPrompt'),
          <dynamic>[id, true],
        );
      },
    );

    test(
      'should propagate the platform error when the channel replies with an error',
      () async {
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient();
        instanceManager.addDartCreatedInstance(client);

        OhosPigeonTestMocks.overrideWithError(
          '${_webChromeClientHostApiPrefix}setSynchronousReturnValueForOnJsAlert',
          'setter-failed',
          'native rejected the value',
        );

        await expectLater(
          api.setSynchronousReturnValueForOnJsAlertFromInstance(client, true),
          throwsA(isA<PlatformException>()),
        );
      },
    );
  });

  group('WebChromeClientFlutterApiImpl', () {
    late api_impls.WebChromeClientFlutterApiImpl flutterApi;

    setUp(() {
      flutterApi = api_impls.WebChromeClientFlutterApiImpl();
    });

    test(
      'should return the file list from the onShowFileChooser callback',
      () async {
        final List<String> chosenFiles = <String>['/tmp/a.png'];
        final TestPigeonWebChromeClient client = TestPigeonWebChromeClient(
          onShowFileChooser:
              (ohos_webview.WebView webView, ohos_webview.FileChooserParams params) async =>
                  chosenFiles,
        );
        final int clientId = instanceManager.addDartCreatedInstance(client);
        final int webViewId =
            instanceManager.addDartCreatedInstance(TestPigeonWebView());
        final int paramsId = instanceManager
            .addDartCreatedInstance(TestPigeonFileChooserParams());

        final List<String?> reply = await flutterApi.onShowFileChooser(
          clientId,
          webViewId,
          paramsId,
        );

        expect(reply, chosenFiles);
      },
    );

    test(
      'should return an empty list from onShowFileChooser when no callback is registered',
      () async {
        final int clientId =
            instanceManager.addDartCreatedInstance(TestPigeonWebChromeClient());
        final int webViewId =
            instanceManager.addDartCreatedInstance(TestPigeonWebView());
        final int paramsId = instanceManager
            .addDartCreatedInstance(TestPigeonFileChooserParams());

        final List<String?> reply = await flutterApi.onShowFileChooser(
          clientId,
          webViewId,
          paramsId,
        );

        expect(reply, isEmpty);
      },
    );

    test('should invoke the onJsAlert callback and complete its future',
        () async {
      final List<String> receivedUrls = <String>[];
      final TestPigeonWebChromeClient client = TestPigeonWebChromeClient(
        onJsAlert: (String url, String message) async {
          receivedUrls.add(url);
        },
      );
      final int clientId = instanceManager.addDartCreatedInstance(client);

      await flutterApi.onJsAlert(clientId, 'https://flutter.dev', 'hello');

      expect(receivedUrls, <String>['https://flutter.dev']);
    });

    test('should return the decision from the onJsConfirm callback',
        () async {
      final TestPigeonWebChromeClient client = TestPigeonWebChromeClient(
        onJsConfirm: (String url, String message) async => true,
      );
      final int clientId = instanceManager.addDartCreatedInstance(client);

      final bool confirmed =
          await flutterApi.onJsConfirm(clientId, 'https://flutter.dev', 'ok?');

      expect(confirmed, true);
    });

    test('should return the value from the onJsPrompt callback', () async {
      final TestPigeonWebChromeClient client = TestPigeonWebChromeClient(
        onJsPrompt:
            (String url, String message, String defaultValue) async => 'typed',
      );
      final int clientId = instanceManager.addDartCreatedInstance(client);

      final String reply = await flutterApi.onJsPrompt(
        clientId,
        'https://flutter.dev',
        'name?',
        'default',
      );

      expect(reply, 'typed');
    });
  });

  group('JavaScriptChannelHostApiImpl', () {
    test('should send create with identifier and channel name', () async {
      final api_impls.JavaScriptChannelHostApiImpl api =
          api_impls.JavaScriptChannelHostApiImpl();
      final TestPigeonJavaScriptChannel channel = TestPigeonJavaScriptChannel(
        'test_channel',
        postMessage: (String message) {},
      );

      await api.createFromInstance(channel);

      final int assignedId = instanceManager.getIdentifier(channel)!;
      expect(lastArgs('${_javaScriptChannelHostApiPrefix}create'),
          <dynamic>[assignedId, 'test_channel']);
    });
  });

  group('WebViewClientHostApiImpl', () {
    late api_impls.WebViewClientHostApiImpl api;

    setUp(() {
      api = api_impls.WebViewClientHostApiImpl();
    });

    test('should send create with the assigned identifier', () async {
      final TestPigeonWebViewClient client = TestPigeonWebViewClient();

      await api.createFromInstance(client);

      final int assignedId = instanceManager.getIdentifier(client)!;
      expect(lastArgs('${_webViewClientHostApiPrefix}create'),
          <dynamic>[assignedId]);
    });

    test(
      'should send the value from setShouldOverrideUrlLoadingReturnValueFromInstance',
      () async {
        final TestPigeonWebViewClient client = TestPigeonWebViewClient();
        final int id = instanceManager.addDartCreatedInstance(client);

        await api.setShouldOverrideUrlLoadingReturnValueFromInstance(
            client, false);

        expect(
          lastArgs(
              '${_webViewClientHostApiPrefix}setSynchronousReturnValueForShouldOverrideUrlLoading'),
          <dynamic>[id, false],
        );
      },
    );
  });

  group('DownloadListenerHostApiImpl', () {
    test('should send create with the assigned identifier', () async {
      final api_impls.DownloadListenerHostApiImpl api =
          api_impls.DownloadListenerHostApiImpl();
      final TestPigeonDownloadListener listener = TestPigeonDownloadListener();

      await api.createFromInstance(listener);

      final int assignedId = instanceManager.getIdentifier(listener)!;
      expect(lastArgs('${_downloadListenerHostApiPrefix}create'),
          <dynamic>[assignedId]);
    });
  });
}
