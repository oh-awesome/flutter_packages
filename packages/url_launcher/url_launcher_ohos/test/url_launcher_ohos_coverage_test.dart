/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_ohos/src/messages.g.dart';
import 'package:url_launcher_ohos/url_launcher_ohos.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncherApi api;

  setUp(() {
    api = _FakeUrlLauncherApi();
  });

  group('linkDelegate', () {
    test('is always null on OHOS', () {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(launcher.linkDelegate, isNull);
    });
  });

  group('canLaunch boundary scenarios', () {
    test('returns false for an empty url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(await launcher.canLaunch(''), false);
    });

    test('returns false for a url without a scheme separator', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(await launcher.canLaunch('example.com/path'), false);
    });

    test('returns false for a url with an empty scheme', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(await launcher.canLaunch('://example.com/'), false);
    });

    test('returns true for a scheme-only http url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(await launcher.canLaunch('http:'), true);
    });

    test('handles a very long url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final String longUrl = 'http://example.com/${'a' * 10000}';
      expect(await launcher.canLaunch(longUrl), true);
    });

    test('handles a url with special characters', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      const String url = 'http://example.com/path with spaces?q=%20&x=1#frag';
      expect(await launcher.canLaunch(url), true);
    });

    test('handles a url with non-ASCII characters', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      const String url = 'http://example.com/路径/тест?查询=值';
      expect(await launcher.canLaunch(url), true);
    });

    test(
        'returns false for a non-http url with a special handler domain '
        'when the fallback is not attempted', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(
          await launcher.canLaunch(
              'unknown://${_FakeUrlLauncherApi.specialHandlerDomain}'),
          false);
    });
  });

  group('legacy launch boundary scenarios', () {
    test('throws for an empty url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await expectLater(
          launcher.launch(
            '',
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: const <String, String>{},
          ),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'ACTIVITY_NOT_FOUND')));
    });
  });

  group('launchUrl boundary scenarios', () {
    test('throws for an empty url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await expectLater(
          launcher.launchUrl('', const LaunchOptions()),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'ACTIVITY_NOT_FOUND')));
    });

    test('throws for a url without a scheme', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await expectLater(
          launcher.launchUrl('example.com/path', const LaunchOptions()),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'ACTIVITY_NOT_FOUND')));
    });

    test('launches a very long url', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final String longUrl = 'https://example.com/${'b' * 10000}';
      expect(
          await launcher.launchUrl(
              longUrl,
              const LaunchOptions(
                  mode: PreferredLaunchMode.externalApplication)),
          true);
    });

    test('launches a url with special characters', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      const String url = 'http://example.com/path with spaces?q=%20&x=1#frag';
      expect(await launcher.launchUrl(url, const LaunchOptions()), true);
    });

    test('launches a url with non-ASCII characters', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      const String url = 'https://example.com/路径/тест?查询=值';
      expect(
          await launcher.launchUrl(
              url,
              const LaunchOptions(
                  mode: PreferredLaunchMode.externalApplication)),
          true);
    });

    test('launches a url with percent-encoded characters', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      const String url = 'https://example.com/%E4%B8%AD%E6%96%87?a=1%262';
      expect(
          await launcher.launchUrl(
              url,
              const LaunchOptions(
                  mode: PreferredLaunchMode.externalApplication)),
          true);
    });
  });

  group('launch with browser options', () {
    test('passes showTitle to browser options', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await launcher.launchUrl(
          'http://example.com/',
          const LaunchOptions(
              mode: PreferredLaunchMode.inAppWebView,
              browserConfiguration:
                  InAppBrowserConfiguration(showTitle: true)));

      expect(api.passedBrowserOptions?.showTitle, true);
    });
  });

  group('launch with external non-browser application', () {
    test('launches externally', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final bool launched = await launcher.launchUrl(
          'supportedcustomscheme://example.com/',
          const LaunchOptions(
              mode: PreferredLaunchMode.externalNonBrowserApplication));
      expect(launched, true);
      expect(api.usedWebView, false);
    });
  });

  group('concurrent launches', () {
    test('handles multiple concurrent canLaunch calls', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final List<bool> results = await Future.wait(<Future<bool>>[
        launcher.canLaunch('http://example.com/'),
        launcher.canLaunch('unknown://scheme'),
        launcher.canLaunch('https://example.com/'),
      ]);

      expect(results, <bool>[true, false, true]);
    });

    test('handles multiple concurrent launchUrl calls', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final List<bool> results = await Future.wait(<Future<bool>>[
        launcher.launchUrl('http://example.com/1/', const LaunchOptions()),
        launcher.launchUrl('https://example.com/2/', const LaunchOptions()),
        launcher.launchUrl(
            'supportedcustomscheme://example.com/3/', const LaunchOptions()),
      ]);

      expect(results, everyElement(true));
    });

    test('handles concurrent launch and close calls', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      final List<Object?> results = await Future.wait(<Future<Object?>>[
        launcher.launchUrl('http://example.com/', const LaunchOptions()),
        launcher.closeWebView(),
      ]);

      expect(results[0], true);
      expect(api.closed, true);
    });
  });

  group('supportsMode for current implementation', () {
    test('returns true for in app browser view', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(await launcher.supportsMode(PreferredLaunchMode.inAppBrowserView),
          true);
    });
  });

  group('supportsCloseForMode for current implementation', () {
    test('returns true for in app browser view', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      expect(
          await launcher
              .supportsCloseForMode(PreferredLaunchMode.inAppBrowserView),
          true);
    });
  });

  group('timeout exception scenarios', () {
    test('should complete canLaunch when the host responds in time', () async {
      final _FakeUrlLauncherApi fastApi = _FakeUrlLauncherApi();
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: fastApi);
      expect(await launcher.canLaunch('http://example.com/').timeout(const Duration(seconds: 1)),
          true);
    });

    test('should surface TimeoutException when canLaunch exceeds the timeout', () async {
      final _SlowUrlLauncherApi slowApi = _SlowUrlLauncherApi(const Duration(milliseconds: 200));
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: slowApi);

      await expectLater(
        launcher.canLaunch('http://example.com/').timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should surface TimeoutException when launchUrl exceeds the timeout', () async {
      final _SlowUrlLauncherApi slowApi = _SlowUrlLauncherApi(const Duration(milliseconds: 200));
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: slowApi);

      await expectLater(
        launcher
            .launchUrl('http://example.com/', const LaunchOptions())
            .timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should surface TimeoutException when closeWebView exceeds the timeout', () async {
      final _SlowUrlLauncherApi slowApi = _SlowUrlLauncherApi(const Duration(milliseconds: 200));
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: slowApi);

      await expectLater(
        launcher.closeWebView().timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should complete launchUrl when the host responds in time', () async {
      final _FakeUrlLauncherApi fastApi = _FakeUrlLauncherApi();
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: fastApi);
      expect(
          await launcher
              .launchUrl('http://example.com/', const LaunchOptions())
              .timeout(const Duration(seconds: 1)),
          true);
    });
  });

  group('registerWith', () {
    late UrlLauncherPlatform savedInstance;

    setUp(() {
      savedInstance = UrlLauncherPlatform.instance;
    });

    tearDown(() {
      UrlLauncherPlatform.instance = savedInstance;
    });

    test('should register an UrlLauncherOhos instance as the platform default', () {
      UrlLauncherOhos.registerWith();

      expect(UrlLauncherPlatform.instance, isA<UrlLauncherOhos>());
    });

    test('should leave the global instance restorable after registration', () {
      UrlLauncherOhos.registerWith();

      UrlLauncherPlatform.instance = savedInstance;
      expect(UrlLauncherPlatform.instance, same(savedInstance));
    });
  });

  group('closeWebView', () {
    test('calls through to the host api', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await launcher.closeWebView();

      expect(api.closed, true);
    });

    test('does not throw when called repeatedly', () async {
      final UrlLauncherOhos launcher = UrlLauncherOhos(api: api);
      await launcher.closeWebView();
      await launcher.closeWebView();

      expect(api.closed, true);
    });
  });

  group('WebViewOptions', () {
    test('constructor sets all fields', () {
      final WebViewOptions options = WebViewOptions(
        enableJavaScript: true,
        enableDomStorage: false,
        headers: const <String?, String?>{'key': 'value'},
      );

      expect(options.enableJavaScript, true);
      expect(options.enableDomStorage, false);
      expect(options.headers, const <String?, String?>{'key': 'value'});
    });

    test('encode returns the field values as a list', () {
      final WebViewOptions options = WebViewOptions(
        enableJavaScript: true,
        enableDomStorage: false,
        headers: const <String?, String?>{'key': 'value'},
      );

      expect(options.encode(), <Object?>[
        true,
        false,
        <String?, String?>{'key': 'value'},
      ]);
    });

    test('encode returns an empty header map when no headers are set', () {
      final WebViewOptions options = WebViewOptions(
        enableJavaScript: false,
        enableDomStorage: true,
        headers: const <String?, String?>{},
      );

      expect(options.encode(), <Object?>[false, true, <String?, String?>{}]);
    });

    test('decode reconstructs the options from an encoded list', () {
      final WebViewOptions options = WebViewOptions.decode(<Object?>[
        true,
        false,
        <Object?, Object?>{'key': 'value'},
      ]);

      expect(options.enableJavaScript, true);
      expect(options.enableDomStorage, false);
      expect(options.headers, const <String?, String?>{'key': 'value'});
    });

    test('encode and decode round trip preserves all fields', () {
      final WebViewOptions original = WebViewOptions(
        enableJavaScript: false,
        enableDomStorage: true,
        headers: const <String?, String?>{'a': '1', 'b': '2'},
      );

      final WebViewOptions decoded = WebViewOptions.decode(original.encode());

      expect(decoded.enableJavaScript, original.enableJavaScript);
      expect(decoded.enableDomStorage, original.enableDomStorage);
      expect(decoded.headers, original.headers);
    });
  });

  group('BrowserOptions', () {
    test('constructor sets the showTitle field', () {
      final BrowserOptions options = BrowserOptions(showTitle: true);

      expect(options.showTitle, true);
    });

    test('encode returns the field value as a list', () {
      final BrowserOptions options = BrowserOptions(showTitle: false);

      expect(options.encode(), <Object?>[false]);
    });

    test('decode reconstructs the options from an encoded list', () {
      final BrowserOptions options = BrowserOptions.decode(<Object?>[true]);

      expect(options.showTitle, true);
    });

    test('encode and decode round trip preserves the field', () {
      final BrowserOptions original = BrowserOptions(showTitle: false);

      final BrowserOptions decoded = BrowserOptions.decode(original.encode());

      expect(decoded.showTitle, original.showTitle);
    });
  });

  group('UrlLauncherApi codec', () {
    test('is a StandardMessageCodec', () {
      expect(UrlLauncherApi.codec, isA<StandardMessageCodec>());
    });

    test('encodes and decodes WebViewOptions', () {
      final WebViewOptions options = WebViewOptions(
        enableJavaScript: true,
        enableDomStorage: false,
        headers: const <String?, String?>{'key': 'value'},
      );

      final ByteData encoded = UrlLauncherApi.codec.encodeMessage(options)!;
      final Object? decoded = UrlLauncherApi.codec.decodeMessage(encoded);

      expect(decoded, isA<WebViewOptions>());
      final WebViewOptions decodedOptions = decoded! as WebViewOptions;
      expect(decodedOptions.enableJavaScript, true);
      expect(decodedOptions.enableDomStorage, false);
      expect(decodedOptions.headers, const <String?, String?>{'key': 'value'});
    });

    test('encodes and decodes BrowserOptions', () {
      final BrowserOptions options = BrowserOptions(showTitle: true);

      final ByteData encoded = UrlLauncherApi.codec.encodeMessage(options)!;
      final Object? decoded = UrlLauncherApi.codec.decodeMessage(encoded);

      expect(decoded, isA<BrowserOptions>());
      expect((decoded! as BrowserOptions).showTitle, true);
    });

    test('passes through standard values unchanged', () {
      const Object? message = <Object?>['url', 42, true, null];
      final ByteData encoded = UrlLauncherApi.codec.encodeMessage(message)!;

      expect(UrlLauncherApi.codec.decodeMessage(encoded), message);
    });
  });

  group('UrlLauncherApi', () {
    const String _canLaunchUrlChannel =
        'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl';
    const String _launchUrlChannel =
        'dev.flutter.pigeon.UrlLauncherApi.launchUrl';
    const String _openUrlInWebViewChannel =
        'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView';
    const String _closeWebViewChannel =
        'dev.flutter.pigeon.UrlLauncherApi.closeWebView';

    final BasicMessageChannel<Object?> _canLaunchUrlMessageChannel =
        BasicMessageChannel<Object?>(
            _canLaunchUrlChannel, UrlLauncherApi.codec);
    final BasicMessageChannel<Object?> _launchUrlMessageChannel =
        BasicMessageChannel<Object?>(_launchUrlChannel, UrlLauncherApi.codec);
    final BasicMessageChannel<Object?> _openUrlInWebViewMessageChannel =
        BasicMessageChannel<Object?>(
            _openUrlInWebViewChannel, UrlLauncherApi.codec);
    final BasicMessageChannel<Object?> _closeWebViewMessageChannel =
        BasicMessageChannel<Object?>(
            _closeWebViewChannel, UrlLauncherApi.codec);

    late TestDefaultBinaryMessengerBinding messenger;

    setUp(() {
      messenger = TestDefaultBinaryMessengerBinding.instance;
    });

    tearDown(() {
      messenger.defaultBinaryMessenger
          .setMockDecodedMessageHandler(_canLaunchUrlMessageChannel, null);
      messenger.defaultBinaryMessenger
          .setMockDecodedMessageHandler(_launchUrlMessageChannel, null);
      messenger.defaultBinaryMessenger
          .setMockDecodedMessageHandler(_openUrlInWebViewMessageChannel, null);
      messenger.defaultBinaryMessenger
          .setMockDecodedMessageHandler(_closeWebViewMessageChannel, null);
    });

    test('uses the default messenger when none is injected', () async {
      bool? handlerInvoked;
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _canLaunchUrlMessageChannel, (Object? message) async {
        handlerInvoked = true;
        return <Object?>[true];
      });

      final bool result = await UrlLauncherApi().canLaunchUrl('http://a.com/');

      expect(result, true);
      expect(handlerInvoked, true);
    });

    test('uses the injected messenger', () async {
      bool? handlerInvoked;
      final TestDefaultBinaryMessenger injectedMessenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      injectedMessenger.setMockDecodedMessageHandler(
          _closeWebViewMessageChannel, (Object? message) async {
        handlerInvoked = true;
        return <Object?>[null];
      });

      final UrlLauncherApi api =
          UrlLauncherApi(binaryMessenger: injectedMessenger);
      await api.closeWebView();

      expect(handlerInvoked, true);
    });

    test('canLaunchUrl sends the url on the channel', () async {
      String? receivedUrl;
      bool? handlerInvoked;
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _canLaunchUrlMessageChannel, (Object? message) async {
        handlerInvoked = true;
        receivedUrl = (message! as List<Object?>)[0] as String?;
        return <Object?>[true];
      });

      final bool result = await UrlLauncherApi().canLaunchUrl('http://a.com/');

      expect(result, true);
      expect(handlerInvoked, true);
      expect(receivedUrl, 'http://a.com/');
    });

    test('canLaunchUrl throws channel-error when the channel is missing',
        () async {
      await expectLater(
          UrlLauncherApi().canLaunchUrl('http://a.com/'),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'channel-error')));
    });

    test('canLaunchUrl surfaces platform errors', () async {
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _canLaunchUrlMessageChannel, (Object? message) async {
        return <Object?>['PERMISSION_DENIED', 'no permission', null];
      });

      await expectLater(
          UrlLauncherApi().canLaunchUrl('http://a.com/'),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'PERMISSION_DENIED')));
    });

    test('canLaunchUrl throws null-error for a null return value', () async {
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _canLaunchUrlMessageChannel, (Object? message) async {
        return <Object?>[null];
      });

      await expectLater(
          UrlLauncherApi().canLaunchUrl('http://a.com/'),
          throwsA(isA<PlatformException>()
              .having((PlatformException e) => e.code, 'code', 'null-error')));
    });

    test('launchUrl sends the url and headers on the channel', () async {
      String? receivedUrl;
      Map<Object?, Object?>? receivedHeaders;
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _launchUrlMessageChannel, (Object? message) async {
        final List<Object?> args = message! as List<Object?>;
        receivedUrl = args[0] as String?;
        receivedHeaders = args[1] as Map<Object?, Object?>?;
        return <Object?>[true];
      });

      final bool result = await UrlLauncherApi()
          .launchUrl('http://a.com/', const <String?, String?>{'key': 'value'});

      expect(result, true);
      expect(receivedUrl, 'http://a.com/');
      expect(receivedHeaders, <Object?, Object?>{'key': 'value'});
    });

    test('launchUrl throws channel-error when the channel is missing',
        () async {
      await expectLater(
          UrlLauncherApi()
              .launchUrl('http://a.com/', const <String?, String?>{}),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'channel-error')));
    });

    test('launchUrl returns false when the host reports failure', () async {
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _launchUrlMessageChannel, (Object? message) async {
        return <Object?>[false];
      });

      expect(
          await UrlLauncherApi()
              .launchUrl('http://a.com/', const <String?, String?>{}),
          false);
    });

    test('openUrlInWebView sends the url and options on the channel', () async {
      String? receivedUrl;
      Object? receivedOptions;
      Object? receivedBrowserOptions;
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _openUrlInWebViewMessageChannel, (Object? message) async {
        final List<Object?> args = message! as List<Object?>;
        receivedUrl = args[0] as String?;
        receivedOptions = args[1];
        receivedBrowserOptions = args[2];
        return <Object?>[true];
      });

      final WebViewOptions options = WebViewOptions(
        enableJavaScript: true,
        enableDomStorage: true,
        headers: const <String?, String?>{},
      );
      final bool result = await UrlLauncherApi().openUrlInWebView(
          'http://a.com/', options, BrowserOptions(showTitle: false));

      expect(result, true);
      expect(receivedUrl, 'http://a.com/');
      expect(receivedOptions, isA<WebViewOptions>());
      expect(receivedBrowserOptions, isA<BrowserOptions>());
    });

    test('openUrlInWebView throws channel-error when the channel is missing',
        () async {
      await expectLater(
          UrlLauncherApi().openUrlInWebView(
              'http://a.com/',
              WebViewOptions(
                  enableJavaScript: true,
                  enableDomStorage: true,
                  headers: const <String?, String?>{}),
              BrowserOptions(showTitle: false)),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'channel-error')));
    });

    test('openUrlInWebView returns false when the host reports failure',
        () async {
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _openUrlInWebViewMessageChannel, (Object? message) async {
        return <Object?>[false];
      });

      expect(
          await UrlLauncherApi().openUrlInWebView(
              'http://a.com/',
              WebViewOptions(
                  enableJavaScript: true,
                  enableDomStorage: true,
                  headers: const <String?, String?>{}),
              BrowserOptions(showTitle: false)),
          false);
    });

    test('closeWebView completes when the host acknowledges', () async {
      bool? handlerInvoked;
      messenger.defaultBinaryMessenger.setMockDecodedMessageHandler(
          _closeWebViewMessageChannel, (Object? message) async {
        handlerInvoked = true;
        return <Object?>[null];
      });

      await UrlLauncherApi().closeWebView();

      expect(handlerInvoked, true);
    });

    test('closeWebView throws channel-error when the channel is missing',
        () async {
      await expectLater(
          UrlLauncherApi().closeWebView(),
          throwsA(isA<PlatformException>().having(
              (PlatformException e) => e.code, 'code', 'channel-error')));
    });
  });
}


class _FakeUrlLauncherApi implements UrlLauncherApi {
  WebViewOptions? passedWebViewOptions;
  BrowserOptions? passedBrowserOptions;
  bool? usedWebView;
  bool? closed;


  static String specialHandlerDomain = 'special.handler.domain';

  @override
  Future<bool> canLaunchUrl(String arg_url) async {
    return _launch(arg_url);
  }

  @override
  Future<bool> launchUrl(
      String arg_url, Map<String?, String?> arg_headers) async {
    passedWebViewOptions = WebViewOptions(
      enableJavaScript: false,
      enableDomStorage: false,
      headers: arg_headers,
    );

    usedWebView = false;
    return _launch(arg_url);
  }

  @override
  Future<void> closeWebView() async {
    closed = true;
  }

  @override
  Future<bool> openUrlInWebView(String arg_url, WebViewOptions arg_options,
      BrowserOptions arg_browserOptions) async {
    passedWebViewOptions = arg_options;
    passedBrowserOptions = arg_browserOptions;
    usedWebView = true;
    return _launch(arg_url);
  }

  bool _launch(String url) {
    final String scheme = url.split(':')[0];
    switch (scheme) {
      case 'http':
      case 'https':
      case 'supportedcustomscheme':
        if (url.endsWith('noactivity')) {
          throw PlatformException(code: 'NO_ABILITY');
        }
        return !url.contains(specialHandlerDomain);
      default:
        return false;
    }
  }
}

class _SlowUrlLauncherApi extends _FakeUrlLauncherApi {
  _SlowUrlLauncherApi(this.delay);

  final Duration delay;

  Future<void> _wait() => Future<void>.delayed(delay);

  @override
  Future<bool> canLaunchUrl(String arg_url) async {
    await _wait();
    return super.canLaunchUrl(arg_url);
  }

  @override
  Future<bool> launchUrl(String arg_url, Map<String?, String?> arg_headers) async {
    await _wait();
    return super.launchUrl(arg_url, arg_headers);
  }

  @override
  Future<void> closeWebView() async {
    await _wait();
    return super.closeWebView();
  }

  @override
  Future<bool> openUrlInWebView(
      String arg_url, WebViewOptions arg_options, BrowserOptions arg_browserOptions) async {
    await _wait();
    return super.openUrlInWebView(arg_url, arg_options, arg_browserOptions);
  }
}
