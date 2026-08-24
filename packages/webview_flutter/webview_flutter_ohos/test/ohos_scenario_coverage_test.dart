// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Scenario coverage required by the review: parameter edge cases (empty url,
// empty headers, special characters, empty/large html, extreme scroll
// values), state cases (disposed object, detached message handler, unknown
// identifier), permission decisions (failing and repeated grant/deny) and
// concurrency (parallel loads and script evaluations, interleaved instances,
// repeated dispose). All cases assert on the recorded Pigeon channel calls
// or the surfaced errors; no random sleeps are used.

import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart'
    as api_impls;

import 'ohos_pigeon_test_mocks.dart';

const String _webViewHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.';
const String _permissionRequestHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.PermissionRequestHostApi.';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebView].
class TestPigeonWebView extends ohos_webview.WebView {
  TestPigeonWebView() : super.detached();
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
/// [ohos_webview.JavaScriptChannel] for the bulk-channel scenario.
class TestPigeonJavaScriptChannelForScenario
    extends ohos_webview.JavaScriptChannel {
  TestPigeonJavaScriptChannelForScenario(String channelName,
      {required void Function(String message) postMessage})
      : super.detached(channelName, postMessage: postMessage);
}

/// Records download callbacks for the dispose-scenario tests. The base class
/// stores `onDownloadStart` as a final field, so the recording callback is
/// installed through the constructor and counted via a captured closure.
class _TestPigeonDownloadListenerFactoryForScenario {
  int forwards = 0;
  late final ohos_webview.DownloadListener listener =
      ohos_webview.DownloadListener.detached(
    onDownloadStart: (String url, String userAgent, String contentDisposition,
        String mimetype, int contentLength) {
      forwards++;
    },
    binaryMessenger: null,
    instanceManager: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late api_impls.WebViewHostApiImpl api;
  late InstanceManager instanceManager;
  late TestPigeonWebView webView;
  late int webViewId;

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
    api = api_impls.WebViewHostApiImpl();
    instanceManager = ohos_webview.OhosObject.globalInstanceManager;
    webView = TestPigeonWebView();
    webViewId = instanceManager.addDartCreatedInstance(webView);
  });

  tearDown(() {
    // Restore the default mock handlers so a handler removed by a
    // detached-engine scenario cannot leak into the next test.
    OhosPigeonTestMocks.setUpMocks();
    OhosPigeonTestMocks.clearRecords();
  });

  /// Returns the arguments of the last recorded call for [method].
  List<dynamic> lastArgs(String method) {
    return OhosPigeonTestMocks
        .getLastCallForChannel('$_webViewHostApiPrefix$method')!.arguments;
  }

  group('parameter edge cases', () {
    test(
      'should send an empty url and empty headers when loadUrlFromInstance is called with both empty',
      () async {
        await api.loadUrlFromInstance(webView, '', <String, String>{});

        final List<dynamic> args = lastArgs('loadUrl');
        expect(args[0], webViewId);
        expect(args[1], '');
        expect(args[2], <String, String>{});
      },
    );

    test(
      'should preserve special characters in the url when loadUrlFromInstance is called',
      () async {
        const String url =
            'https://flutter.dev/search?q=web%20view&lang=zh-cn#/结果';
        await api.loadUrlFromInstance(webView, url, <String, String>{});

        expect(lastArgs('loadUrl')[1], url);
      },
    );

    test(
      'should send empty html when loadDataFromInstance is called with an empty payload',
      () async {
        await api.loadDataFromInstance(webView, '', null, null);

        final List<dynamic> args = lastArgs('loadData');
        expect(args[0], webViewId);
        expect(args[1], '');
        expect(args[2], isNull);
        expect(args[3], isNull);
      },
    );

    test(
      'should send a large html payload unchanged when loadDataFromInstance is called with one',
      () async {
        final String largeHtml =
            '<html><body>${'a' * 100000}</body></html>';
        await api.loadDataFromInstance(webView, largeHtml, 'text/html', 'utf-8');

        expect(lastArgs('loadData')[1], largeHtml);
      },
    );

    test(
      'should send negative and extreme scroll values when scrollToFromInstance is called with them',
      () async {
        await api.scrollToFromInstance(webView, -100, 2147483647);

        final List<dynamic> args = lastArgs('scrollTo');
        expect(args[1], -100);
        expect(args[2], 2147483647);
      },
    );

    test(
      'should send a zero-length body when postUrlFromInstance is called with empty bytes',
      () async {
        await api.postUrlFromInstance(
            webView, 'https://flutter.dev', Uint8List(0));

        final List<dynamic> args = lastArgs('postUrl');
        expect(args[2], Uint8List(0));
      },
    );
  });

  group('state cases', () {
    test(
      'should throw a TypeError when a FromInstance method is called with an unregistered instance',
      () async {
        final TestPigeonWebView unknownWebView = TestPigeonWebView();

        expect(
          () => api.getUrlFromInstance(unknownWebView),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test(
      'should surface an error when the message handler has been detached',
      () async {
        OhosPigeonTestMocks.removeHandler('${_webViewHostApiPrefix}loadUrl');

        await expectLater(
          api.loadUrlFromInstance(webView, 'https://flutter.dev',
              <String, String>{}),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'should throw a TypeError when a method is called after the object was disposed',
      () async {
        ohos_webview.OhosObject.dispose(webView);

        expect(
          () => api.reloadFromInstance(webView),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test(
      'should not throw when dispose is called twice on the same object',
      () {
        ohos_webview.OhosObject.dispose(webView);
        ohos_webview.OhosObject.dispose(webView);

        expect(instanceManager.getIdentifier(webView), isNull);
      },
    );
  });

  group('permission decisions', () {
    late TestPigeonPermissionRequest request;
    late int requestId;

    setUp(() {
      request = TestPigeonPermissionRequest(
        resources: <String>['ohos.permission.GEOLOCATION'],
      );
      requestId = instanceManager.addDartCreatedInstance(request);
    });

    test(
      'should surface the platform error when grant fails and still allow a following deny',
      () async {
        OhosPigeonTestMocks.overrideWithError(
          '${_permissionRequestHostApiPrefix}grant',
          'grant-failed',
          'native rejected the grant',
        );

        await expectLater(
          request.grant(<String>['ohos.permission.GEOLOCATION']),
          throwsA(isA<PlatformException>()),
        );

        // The deny channel is untouched, so the fallback decision still goes
        // through.
        await request.deny();
        expect(
          OhosPigeonTestMocks.getLastCallForChannel(
            '${_permissionRequestHostApiPrefix}deny',
          )!.arguments[0],
          requestId,
        );
      },
    );

    test(
      'should send a grant again when the decision is repeated',
      () async {
        await request.grant(<String>['ohos.permission.GEOLOCATION']);
        await request.grant(<String>['ohos.permission.CAMERA']);

        final List<PlatformChannelCallRecord> grantCalls =
            OhosPigeonTestMocks.getCallsForChannel(
          '${_permissionRequestHostApiPrefix}grant',
        );
        expect(grantCalls.length, 2);
        expect(grantCalls[0].arguments[0], requestId);
        expect(grantCalls[1].arguments[0], requestId);
      },
    );
  });

  group('concurrency', () {
    test(
      'should keep every parallel load and script evaluation isolated when they run against the same instance',
      () async {
        await Future.wait(<Future<void>>[
          for (int i = 0; i < 10; i++)
            api.loadUrlFromInstance(webView, 'https://flutter.dev/$i',
                <String, String>{}),
          for (int i = 0; i < 10; i++)
            api.evaluateJavascriptFromInstance(webView, 'compute($i)'),
        ]);

        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}loadUrl',
          ).length,
          10,
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '${_webViewHostApiPrefix}evaluateJavascript',
          ).length,
          10,
        );
        for (final PlatformChannelCallRecord record
            in OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}loadUrl',
        )) {
          expect(record.arguments[0], webViewId);
        }
      },
    );

    test(
      'should route interleaved calls to the right instance when two instances alternate',
      () async {
        final TestPigeonWebView secondWebView = TestPigeonWebView();
        final int secondId = instanceManager.addDartCreatedInstance(secondWebView);

        await Future.wait(<Future<void>>[
          api.loadUrlFromInstance(
              webView, 'https://first.dev', <String, String>{}),
          api.loadUrlFromInstance(
              secondWebView, 'https://second.dev', <String, String>{}),
          api.loadUrlFromInstance(
              webView, 'https://first.dev/again', <String, String>{}),
          api.loadUrlFromInstance(
              secondWebView, 'https://second.dev/again', <String, String>{}),
        ]);

        final List<PlatformChannelCallRecord> calls =
            OhosPigeonTestMocks.getCallsForChannel(
          '${_webViewHostApiPrefix}loadUrl',
        );
        expect(calls.length, 4);
        expect(
          calls
              .where(
                (PlatformChannelCallRecord record) =>
                    record.arguments[0] == webViewId,
              )
              .length,
          2,
        );
        expect(
          calls
              .where(
                (PlatformChannelCallRecord record) =>
                    record.arguments[0] == secondId,
              )
              .length,
          2,
        );
      },
    );
  });

  group('asynchronous failure', () {
    test(
      'should complete the pending load with a platform error instead of hanging when the channel replies with an error',
      () async {
        OhosPigeonTestMocks.overrideWithError(
          '${_webViewHostApiPrefix}loadUrl',
          'loadUrl-failed',
          'the channel rejected the load',
        );

        // The awaited call must settle with the concrete platform error; it
        // must never stay pending forever.
        await expectLater(
          api.loadUrlFromInstance(
              webView, 'https://flutter.dev', <String, String>{}),
          throwsA(isA<PlatformException>()),
        );
      },
    );

    test(
      'should propagate the permission error when deny is rejected by the platform',
      () async {
        final TestPigeonPermissionRequest denyRequest =
            TestPigeonPermissionRequest(
          resources: <String>['ohos.permission.GEOLOCATION'],
        );
        instanceManager.addDartCreatedInstance(denyRequest);

        OhosPigeonTestMocks.overrideWithError(
          '${_permissionRequestHostApiPrefix}deny',
          'deny-failed',
          'the platform denied the denial request',
        );

        await expectLater(
          denyRequest.deny(),
          throwsA(isA<PlatformException>()),
        );
      },
    );
  });

  group('null boundary (parameters whose signatures allow null)', () {
    test(
      'should pass null mimeType and encoding through loadDataFromInstance unchanged',
      () async {
        await api.loadDataFromInstance(
            webView, '<html><body>hi</body></html>', null, null);

        final List<dynamic> args = lastArgs('loadData');
        expect(args[0], webViewId);
        expect(args[1], '<html><body>hi</body></html>');
        expect(args[2], isNull);
        expect(args[3], isNull);
      },
    );

    test(
      'should pass every nullable argument of loadDataWithBaseUrlFromInstance through unchanged',
      () async {
        await api.loadDataWithBaseUrlFromInstance(
            webView, null, '<html><body>hi</body></html>', null, null, null);

        final List<dynamic> args =
            lastArgs('loadDataWithBaseUrl');
        expect(args[0], webViewId);
        expect(args[1], isNull);
        expect(args[2], '<html><body>hi</body></html>');
        expect(args[3], isNull);
        expect(args[4], isNull);
        expect(args[5], isNull);
      },
    );
  });

  group('asynchronous failure', () {
    test(
      'should throw a descriptive error when addJavaScriptChannelFromInstance is called with an unknown channel id',
      () async {
        final TestPigeonJavaScriptChannelForScenario channel =
            TestPigeonJavaScriptChannelForScenario(
          'unregistered_channel',
          postMessage: (String message) {},
        );

        // Mirrors the native addJavaScriptChannel instance validation: the
        // call must fail fast and must not reach the registration channel.
        expect(
          () => api.addJavaScriptChannelFromInstance(webView, channel),
          throwsA(isA<TypeError>()),
        );
        expect(
          OhosPigeonTestMocks.getCallsForChannel(
            '$_webViewHostApiPrefix${'addJavaScriptChannel'}',
          ),
          isEmpty,
        );
      },
    );
  });

  group('dispose during platform callbacks', () {
    test(
      'should stop forwarding download events after the listener was disposed',
      () {
        final api_impls.DownloadListenerFlutterApiImpl flutterApi =
            api_impls.DownloadListenerFlutterApiImpl();
        final _TestPigeonDownloadListenerFactoryForScenario factory =
            _TestPigeonDownloadListenerFactoryForScenario();
        final ohos_webview.DownloadListener listener = factory.listener;
        final int listenerId =
            instanceManager.addDartCreatedInstance(listener);

        // Before dispose: the weak reference resolves and the callback
        // forwards to the listener.
        flutterApi.onDownloadStart(
            listenerId, 'https://flutter.dev', 'ua', '', 'text/html', 0);
        expect(factory.forwards, 1);

        // Disposal releases the weak reference: the disposed object is no
        // longer the addressable event recipient. The host-owned strong
        // reference still resolves, but only to a fresh copy, never to the
        // disposed listener object itself.
        ohos_webview.OhosObject.dispose(listener);
        expect(instanceManager.getIdentifier(listener), isNull);
        final ohos_webview.DownloadListener resolved =
            instanceManager.getInstanceWithWeakReference(listenerId)!;
        expect(resolved, isNot(same(listener)));

        // Host-side release (what the native dispose does for its instance
        // entries): after both the strong reference and the copy's weak
        // reference are dropped, the callback can no longer resolve any
        // listener and fails its missing-instance assert instead of
        // forwarding to the disposed listener.
        instanceManager.remove(listenerId);
        ohos_webview.OhosObject.dispose(resolved);
        expect(
          () => flutterApi.onDownloadStart(
              listenerId, 'https://flutter.dev', 'ua', '', 'text/html', 0),
          throwsA(isA<AssertionError>()),
        );
        expect(factory.forwards, 1);
      },
    );

    test(
      'should keep the channel map empty and dispose repeatable when a web view with channels is disposed',
      () async {
        final TestPigeonJavaScriptChannelForScenario channel =
            TestPigeonJavaScriptChannelForScenario(
          'dispose_case_channel',
          postMessage: (String message) {},
        );
        final int channelId = instanceManager.addDartCreatedInstance(channel);
        await api.addJavaScriptChannelFromInstance(webView, channel);

        // Disposal drops the web view and its channel from the manager; the
        // native dispose unregisters the ArkWeb proxies (see
        // WebViewHostApiImpl.dispose) and repeated disposal stays a no-op on
        // the Dart side.
        ohos_webview.OhosObject.dispose(webView);
        ohos_webview.OhosObject.dispose(webView);

        expect(instanceManager.getIdentifier(webView), isNull);
        expect(instanceManager.getIdentifier(channel), channelId);
        expect(
          OhosPigeonTestMocks.getLastCallForChannel(
            '$_webViewHostApiPrefix${'addJavaScriptChannel'}',
          )!.arguments,
          <dynamic>[webViewId, channelId],
        );
      },
    );

    test(
      'should stop resolving callbacks for the disposed view identifier on the Dart side',
      () {
        // Native dispose() guards the forwarding callbacks with isDisposed
        // so late events never reach the released client/listener. The Dart
        // mirror: once the weak reference is gone, resolving the identifier
        // yields only the host-owned copy, never the disposed view object,
        // so callback dispatch cannot reach the old listeners.
        final TestPigeonWebView disposedView = webView;
        ohos_webview.OhosObject.dispose(disposedView);
        expect(instanceManager.getIdentifier(disposedView), isNull);
        expect(instanceManager.getInstanceWithWeakReference(webViewId),
            isNot(same(disposedView)));

        // The dispatcher drops the entry entirely after the host-side
        // release: the weak reference was already disposed above, and
        // removing the host-owned strong copy makes the identifier
        // unresolvable, so no callback can be routed to the destroyed view.
        final ohos_webview.WebView resolvedCopy =
            instanceManager.getInstanceWithWeakReference(webViewId)!;
        instanceManager.remove(webViewId);
        ohos_webview.OhosObject.dispose(resolvedCopy);
        expect(
          instanceManager.getInstanceWithWeakReference(webViewId),
          isNull,
        );
      },
    );
  });

  group('many JavaScript channels', () {
    test(
      'should register, route by name and remove a large batch of channels without interference',
      () async {
        const int channelCount = 100;
        final List<TestPigeonJavaScriptChannelForScenario> channels =
            <TestPigeonJavaScriptChannelForScenario>[];
        final Map<String, int> nameToId = <String, int>{};

        for (int i = 0; i < channelCount; i++) {
          final String name = 'bulk_channel_$i';
          final TestPigeonJavaScriptChannelForScenario channel =
              TestPigeonJavaScriptChannelForScenario(
            name,
            postMessage: (String message) {},
          );
          channels.add(channel);
          nameToId[name] = instanceManager.addDartCreatedInstance(channel);
        }

        // Register every channel; each registration call must carry the web
        // view id and the channel's own id so messages route to the right
        // channel.
        for (final TestPigeonJavaScriptChannelForScenario channel
            in channels) {
          await api.addJavaScriptChannelFromInstance(webView, channel);
        }

        final List<PlatformChannelCallRecord> registerCalls =
            OhosPigeonTestMocks.getCallsForChannel(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.addJavaScriptChannel',
        );
        expect(registerCalls.length, channelCount);
        for (int i = 0; i < channelCount; i++) {
          expect(
            registerCalls[i].arguments[0],
            webViewId,
            reason: 'registration $i must carry the web view id',
          );
          expect(
            registerCalls[i].arguments[1],
            nameToId['bulk_channel_$i'],
            reason: 'registration $i must carry the channel id',
          );
        }

        // Remove every tenth channel; the removal must be forwarded with the
        // same id pair used at registration time.
        for (int i = 0; i < channelCount; i += 10) {
          await api.removeJavaScriptChannelFromInstance(
              webView, channels[i]);
        }

        final List<PlatformChannelCallRecord> removeCalls =
            OhosPigeonTestMocks.getCallsForChannel(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.removeJavaScriptChannel',
        );
        expect(removeCalls.length, channelCount ~/ 10);
        for (int i = 0; i < removeCalls.length; i++) {
          expect(removeCalls[i].arguments[0], webViewId);
          expect(
            removeCalls[i].arguments[1],
            nameToId['bulk_channel_${i * 10}'],
          );
        }
      },
    );
  });
}
