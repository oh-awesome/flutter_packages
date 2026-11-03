// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Direct coverage of `WebSettingsHostApiImpl` (20 uncovered items from the
// XTS report). Every case instantiates the Impl itself, registers real
// instance identifiers for the settings object and its owning WebView, and
// asserts on the recorded Pigeon channel call.

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart'
    as ohos_webview;
import 'package:webview_flutter_ohos/src/ohos_webview_api_impls.dart'
    as api_impls;

import 'ohos_pigeon_test_mocks.dart';

const String _webSettingsHostApiPrefix =
    'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.';

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebView].
class TestPigeonWebView extends ohos_webview.WebView {
  TestPigeonWebView() : super.detached();
}

/// Test subclass exposing the protected detached constructor of
/// [ohos_webview.WebSettings].
class TestPigeonWebSettings extends ohos_webview.WebSettings {
  TestPigeonWebSettings() : super.detached();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late api_impls.WebSettingsHostApiImpl api;
  late InstanceManager instanceManager;
  late TestPigeonWebSettings settings;
  late int settingsId;

  setUpAll(() {
    OhosPigeonTestMocks.setUpMocks();
  });

  setUp(() {
    OhosPigeonTestMocks.clearRecords();
    api = api_impls.WebSettingsHostApiImpl();
    instanceManager = ohos_webview.OhosObject.globalInstanceManager;
    settings = TestPigeonWebSettings();
    settingsId = instanceManager.addDartCreatedInstance(settings);
  });

  tearDown(() {
    // Restore the default mock handlers so an error/return-value override
    // installed by one test cannot leak into the next one.
    OhosPigeonTestMocks.setUpMocks();
    OhosPigeonTestMocks.clearRecords();
  });

  /// Returns the arguments of the last recorded call for [method].
  List<dynamic> lastArgs(String method) {
    return OhosPigeonTestMocks
        .getLastCallForChannel('$_webSettingsHostApiPrefix$method')!
        .arguments;
  }

  group('WebSettingsHostApiImpl.createFromInstance', () {
    test('should send create with settings id and webview id', () async {
      final TestPigeonWebView webView = TestPigeonWebView();
      final int webViewId = instanceManager.addDartCreatedInstance(webView);

      final TestPigeonWebSettings freshSettings = TestPigeonWebSettings();
      await api.createFromInstance(freshSettings, webView);

      final List<dynamic> args = lastArgs('create');
      expect(args[0], instanceManager.getIdentifier(freshSettings));
      expect(args[1], webViewId);
    });
  });

  group('WebSettingsHostApiImpl boolean setters', () {
    test('should send setDomStorageEnabled with id and flag', () async {
      await api.setDomStorageEnabledFromInstance(settings, true);
      expect(lastArgs('setDomStorageEnabled'), <dynamic>[settingsId, true]);
    });

    test(
      'should send setJavaScriptCanOpenWindowsAutomatically with id and flag',
      () async {
        await api.setJavaScriptCanOpenWindowsAutomaticallyFromInstance(
            settings, false);
        expect(
          lastArgs('setJavaScriptCanOpenWindowsAutomatically'),
          <dynamic>[settingsId, false],
        );
      },
    );

    test('should send setSupportMultipleWindows with id and support',
        () async {
      await api.setSupportMultipleWindowsFromInstance(settings, true);
      expect(
          lastArgs('setSupportMultipleWindows'), <dynamic>[settingsId, true]);
    });

    test('should send setBackgroundColor with id and color', () async {
      await api.setBackgroundColorFromInstance(settings, 0xFF00FF00);
      expect(lastArgs('setBackgroundColor'), <dynamic>[settingsId, 0xFF00FF00]);
    });

    test('should send setJavaScriptEnabled with id and flag', () async {
      await api.setJavaScriptEnabledFromInstance(settings, true);
      expect(lastArgs('setJavaScriptEnabled'), <dynamic>[settingsId, true]);
    });

    test(
      'should send setUserAgentString with id and a user agent',
      () async {
        await api.setUserAgentStringFromInstance(
            settings, 'Mozilla/5.0 (ohos)');
        expect(lastArgs('setUserAgentString'),
            <dynamic>[settingsId, 'Mozilla/5.0 (ohos)']);
      },
    );

    test('should send setUserAgentString with a null user agent', () async {
      await api.setUserAgentStringFromInstance(settings, null);
      expect(lastArgs('setUserAgentString'), <dynamic>[settingsId, null]);
    });

    test(
      'should send setMediaPlaybackRequiresUserGesture with id and require',
      () async {
        await api.setMediaPlaybackRequiresUserGestureFromInstance(
            settings, true);
        expect(lastArgs('setMediaPlaybackRequiresUserGesture'),
            <dynamic>[settingsId, true]);
      },
    );

    test('should send setSupportZoom with id and support', () async {
      await api.setSupportZoomFromInstance(settings, true);
      expect(lastArgs('setSupportZoom'), <dynamic>[settingsId, true]);
    });

    test('should send setLoadWithOverviewMode with id and overview',
        () async {
      await api.setLoadWithOverviewModeFromInstance(settings, true);
      expect(lastArgs('setLoadWithOverviewMode'), <dynamic>[settingsId, true]);
    });

    test('should send setUseWideViewPort with id and use', () async {
      await api.setUseWideViewPortFromInstance(settings, true);
      expect(lastArgs('setUseWideViewPort'), <dynamic>[settingsId, true]);
    });

    test('should send setDisplayZoomControls with id and enabled',
        () async {
      await api.setDisplayZoomControlsFromInstance(settings, false);
      expect(
          lastArgs('setDisplayZoomControls'), <dynamic>[settingsId, false]);
    });

    test('should send setBuiltInZoomControls with id and enabled',
        () async {
      await api.setBuiltInZoomControlsFromInstance(settings, true);
      expect(lastArgs('setBuiltInZoomControls'), <dynamic>[settingsId, true]);
    });

    test('should send setAllowFileAccess with id and enabled', () async {
      await api.setAllowFileAccessFromInstance(settings, true);
      expect(lastArgs('setAllowFileAccess'), <dynamic>[settingsId, true]);
    });

    test('should send setAllowFullScreenRotate with id and enabled',
        () async {
      await api.setAllowFullScreenRotateInstance(settings, true);
      expect(lastArgs('setAllowFullScreenRotate'), <dynamic>[settingsId, true]);
    });

    test('should send setPaymentRequestEnabled with id and enabled',
        () async {
      await api.setPaymentRequestEnabledFromInstance(settings, true);
      expect(
          lastArgs('setPaymentRequestEnabled'), <dynamic>[settingsId, true]);
    });
  });

  group('WebSettingsHostApiImpl.setTextZoomFromInstance', () {
    test('should send setTextZoom with id and zoom percentage', () async {
      await api.setSetTextZoomFromInstance(settings, 120);
      expect(lastArgs('setTextZoom'), <dynamic>[settingsId, 120]);
    });
  });

  group('WebSettingsHostApiImpl.getUserAgentStringFromInstance', () {
    test('should return the user agent string', () async {
      expect(await api.getUserAgentStringFromInstance(settings),
          'Mozilla/5.0');
      expect(lastArgs('getUserAgentString'), <dynamic>[settingsId]);
    });
  });

  group('WebSettingsHostApiImpl enum-backed setters', () {
    test(
      'should send the enum index from setMixedContentModeFromInstance',
      () async {
        await api.setMixedContentModeFromInstance(
          settings,
          ohos_webview.MixedContentMode.compatibilityMode,
        );
        expect(lastArgs('setMixedContentMode'),
            <dynamic>[settingsId, ohos_webview.MixedContentMode.compatibilityMode.index]);
      },
    );

    test(
      'should send the enum index from setOverScrollModeFromInstance',
      () async {
        await api.setOverScrollModeFromInstance(
          settings,
          ohos_webview.OverScrollMode.always,
        );
        expect(lastArgs('setOverScrollMode'),
            <dynamic>[settingsId, ohos_webview.OverScrollMode.always.index]);
      },
    );
  });

  group('WebSettingsHostApiImpl error propagation', () {
    test(
      'should propagate the platform error when the channel replies with an error',
      () async {
        OhosPigeonTestMocks.overrideWithError(
          '${_webSettingsHostApiPrefix}setJavaScriptEnabled',
          'setJavaScriptEnabled-failed',
          'native rejected the flag',
        );

        await expectLater(
          api.setJavaScriptEnabledFromInstance(settings, true),
          throwsA(isA<PlatformException>()),
        );
      },
    );
  });

  group('WebSettingsHostApiImpl concurrency', () {
    test(
      'should execute interleaved settings from two callers in submission order with the last value winning',
      () async {
        // Two callers alternate writes to the same settings instance. The
        // channel must receive every call with the right instance id, in
        // submission order, so the final recorded value is the last write
        // (mirrors the native single-threaded UI-thread serialization).
        const int writesPerCaller = 8;
        final List<int> submitted = <int>[];
        await Future.wait(<Future<void>>[
          for (int i = 0; i < writesPerCaller; i++)
            api.setDomStorageEnabledFromInstance(settings, i.isEven)
              ..whenComplete(() => submitted.add(i * 2)),
          for (int i = 0; i < writesPerCaller; i++)
            api.setJavaScriptEnabledFromInstance(settings, i.isOdd)
              ..whenComplete(() => submitted.add(i * 2 + 1)),
        ]);

        final List<PlatformChannelCallRecord> domCalls =
            OhosPigeonTestMocks.getCallsForChannel(
          '$_webSettingsHostApiPrefix${'setDomStorageEnabled'}',
        );
        final List<PlatformChannelCallRecord> jsCalls =
            OhosPigeonTestMocks.getCallsForChannel(
          '$_webSettingsHostApiPrefix${'setJavaScriptEnabled'}',
        );
        expect(domCalls.length, writesPerCaller);
        expect(jsCalls.length, writesPerCaller);
        for (int i = 0; i < writesPerCaller; i++) {
          expect(domCalls[i].arguments[0], settingsId);
          expect(domCalls[i].arguments[1], i.isEven);
          expect(jsCalls[i].arguments[0], settingsId);
          expect(jsCalls[i].arguments[1], i.isOdd);
        }

        // Last write wins: the final recorded flags are the last submitted
        // values from each caller.
        expect(domCalls.last.arguments[1],
            (writesPerCaller - 1).isEven);
        expect(jsCalls.last.arguments[1], (writesPerCaller - 1).isOdd);
      },
    );
  });
}
