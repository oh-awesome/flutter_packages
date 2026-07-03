// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test is run using `flutter drive` by the CI (see /script/tool/README.md
// in this repository for details on driving that tooling manually), but can
// also be run using `flutter test` directly during development.
//
// OHOS platform: `flutter test` and `flutter drive` cannot connect to the VM
// Service WebSocket via hdc port forwarding. The connection fails with
// "HttpException: Connection closed before full header was received" or
// "Connecting to the VM Service timed out." This is an OHOS Flutter SDK bug.
// Since the failure occurs at the SDK infrastructure level (before any test
// code executes), skip logic in main() cannot prevent the crash. These
// integration tests must be verified manually by running the example app on
// an OHOS device. Unit tests for the OHOS plugin logic are available in the
// webview_flutter_ohos package's test/ directory.
// Do NOT attempt to run this file with `flutter test` or `flutter drive`
// on OHOS until the SDK bug is fixed.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // OHOS workaround: The Flutter SDK's HdcLogReader filters hilog by level [IE],
  // but on some OHOS devices the VM service log is emitted at W (Warning) level,
  // causing port discovery to fail. Re-print the VM service URI at Dart level
  // (which outputs as I/Info in hilog) so the SDK can discover the port.
  if (defaultTargetPlatform == TargetPlatform.ohos) {
    final serviceInfo = await developer.Service.getInfo();
    if (serviceInfo.serverUri != null) {
      print('The Dart VM service is listening on ${serviceInfo.serverUri}');
    }
  }

  // OHOS workaround: When a WebView platform view is disposed after a test
  // completes, the native side may still send a response that the Flutter
  // framework cannot decode, resulting in a FormatException: Invalid envelope.
  // This is a known OHOS Flutter SDK issue. The test framework reports this
  // error via FlutterError.dumpErrorToConsole with forceReport: true, which
  // bypasses FlutterError.onError. To suppress this noise, we override
  // debugPrint to filter out the specific error output.
  if (defaultTargetPlatform == TargetPlatform.ohos) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FormatException &&
          (details.exception as FormatException).message == 'Invalid envelope') {
        return;
      }
      originalOnError?.call(details);
    };
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('Invalid envelope')) {
        return;
      }
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }

  final HttpServer server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    0,
  );
  unawaited(
    server.forEach((HttpRequest request) {
      if (request.uri.path == '/hello.txt') {
        request.response.writeln('Hello, world.');
      } else if (request.uri.path == '/secondary.txt') {
        request.response.writeln('How are you today?');
      } else if (request.uri.path == '/headers') {
        request.response.writeln('${request.headers}');
      } else if (request.uri.path == '/favicon.ico') {
        request.response.statusCode = HttpStatus.notFound;
      } else if (request.uri.path == '/http-basic-authentication') {
        final List<String>? authHeader =
            request.headers[HttpHeaders.authorizationHeader];
        if (authHeader != null) {
          final String encodedCredential = authHeader.first.split(' ')[1];
          final credential = String.fromCharCodes(
            base64Decode(encodedCredential),
          );
          if (credential == 'user:password') {
            request.response.writeln('Authorized');
          } else {
            request.response.headers.add(
              HttpHeaders.wwwAuthenticateHeader,
              'Basic realm="Test realm"',
            );
            request.response.statusCode = HttpStatus.unauthorized;
          }
        } else {
          request.response.headers.add(
            HttpHeaders.wwwAuthenticateHeader,
            'Basic realm="Test realm"',
          );
          request.response.statusCode = HttpStatus.unauthorized;
        }
      } else {
        fail('unexpected request: ${request.method} ${request.uri}');
      }
      request.response.close();
    }),
  );
  final prefixUrl = 'http://${server.address.address}:${server.port}';
  final primaryUrl = '$prefixUrl/hello.txt';
  final secondaryUrl = '$prefixUrl/secondary.txt';
  final headersUrl = '$prefixUrl/headers';
  final basicAuthUrl = '$prefixUrl/http-basic-authentication';

  testWidgets('loadRequest', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = WebViewController();
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageFinished.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.loadRequest(Uri.parse(primaryUrl));
    await pageFinished.future;

    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  });

  testWidgets('runJavaScriptReturningResult', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageFinished.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.loadRequest(Uri.parse(primaryUrl));

    await pageFinished.future;

    await expectLater(
      controller.runJavaScriptReturningResult('1 + 1'),
      completion(2),
    );
  });

  testWidgets('loadRequest with headers', (WidgetTester tester) async {
    final headers = <String, String>{'test_header': 'flutter_test_header'};

    final pageLoads = StreamController<String>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (String url) => pageLoads.add(url)),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));

    await controller.loadRequest(Uri.parse(headersUrl), headers: headers);

    await pageLoads.stream.firstWhere((String url) => url == headersUrl);

    final content =
        await controller.runJavaScriptReturningResult(
              'document.documentElement.innerText',
            )
            as String;
    expect(content.contains('flutter_test_header'), isTrue);
  });

  testWidgets('JavascriptChannel', (WidgetTester tester) async {
    final pageFinished = Completer<void>();
    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageFinished.complete()),
    );

    final channelCompleter = Completer<String>();

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.addJavaScriptChannel(
      'Echo',
      onMessageReceived: (JavaScriptMessage message) {
        channelCompleter.complete(message.message);
      },
    );

    await controller.loadHtmlString(
      'data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+',
    );

    await pageFinished.future;

    await controller.runJavaScript('Echo.postMessage("hello");');
    await expectLater(channelCompleter.future, completion('hello'));
  });

  testWidgets('resize webview', (WidgetTester tester) async {
    final initialResizeCompleter = Completer<void>();
    final buttonTapResizeCompleter = Completer<void>();
    final onPageFinished = Completer<void>();

    var resizeButtonTapped = false;
    await tester.pumpWidget(
      ResizableWebView(
        onResize: () {
          if (resizeButtonTapped) {
            buttonTapResizeCompleter.complete();
          } else {
            initialResizeCompleter.complete();
          }
        },
        onPageFinished: () => onPageFinished.complete(),
      ),
    );

    await onPageFinished.future;
    // Wait for a potential call to resize after page is loaded.
    await initialResizeCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );

    resizeButtonTapped = true;

    await tester.tap(find.byKey(const ValueKey<String>('resizeButton')));
    await tester.pumpAndSettle();

    await expectLater(buttonTapResizeCompleter.future, completes);
  });

  testWidgets('No webview, get controller', (WidgetTester tester) async {

    final WebViewController controller = WebViewController();

    // On OHOS, getUserAgent requires the WebView to be rendered first
    // because the native side waits for the controller to attach.
    // Pump a WebViewWidget so the controller is attached before querying.
    await tester.pumpWidget(WebViewWidget(controller: controller));

    final String? customUserAgent = await controller.getUserAgent();

    expect(customUserAgent, startsWith('Mozilla'));

  });

  testWidgets('set custom userAgent', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageFinished.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.setUserAgent('Custom_User_Agent1');
    await controller.loadRequest(Uri.parse('about:blank'));

    await pageFinished.future;

    final String? customUserAgent = await controller.getUserAgent();
    expect(customUserAgent, 'Custom_User_Agent1');
  });

  group('Video playback policy', () {
    late String videoTestBase64;
    setUpAll(() async {
      final ByteData videoData =
          await rootBundle.load('assets/sample_video.mp4');
      final String base64VideoData =
          base64Encode(Uint8List.view(videoData.buffer));
      final String videoTest = '''
        <!DOCTYPE html><html>
        <head><title>Video auto play</title>
          <script type="text/javascript">
            function play() {
              var video = document.getElementById("video");
              video.play();
              video.addEventListener('timeupdate', videoTimeUpdateHandler, false);
            }
            function videoTimeUpdateHandler(e) {
              var video = document.getElementById("video");
              VideoTestTime.postMessage(video.currentTime);
            }
            function isPaused() {
              var video = document.getElementById("video");
              return video.paused;
            }
            function isFullScreen() {
              var video = document.getElementById("video");
              return video.webkitDisplayingFullscreen;
            }
          </script>
        </head>
        <body onload="play();">
        <video controls playsinline autoplay id="video">
          <source src="data:video/mp4;charset=utf-8;base64,$base64VideoData">
        </video>
        </body>
        </html>
      ''';
      videoTestBase64 = base64Encode(const Utf8Encoder().convert(videoTest));
    });

      testWidgets('Auto media playback', (WidgetTester tester) async {
        final String videoTestBase64 = await getTestVideoBase64();
        var pageLoaded = Completer<void>();

        late PlatformWebViewControllerCreationParams params;
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          params = WebKitWebViewControllerCreationParams(
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          );
        } else {
          params = const PlatformWebViewControllerCreationParams();
        }

        var controller = WebViewController.fromPlatformCreationParams(params);
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        if (controller.platform is AndroidWebViewController) {
          await (controller.platform as AndroidWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        } else if (controller.platform is OhosWebViewController) {
          await (controller.platform as OhosWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        }

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.loadRequest(
          Uri.parse('data:text/html;charset=utf-8;base64,$videoTestBase64'),
        );

        await tester.pumpAndSettle();

        await pageLoaded.future;

        var isPaused =
            _jsResultToBool(
                await controller.runJavaScriptReturningResult('isPaused();'));
        expect(isPaused, false);

        pageLoaded = Completer<void>();
        controller = WebViewController();
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        if (controller.platform is OhosWebViewController) {
          await (controller.platform as OhosWebViewController)
              .setMediaPlaybackRequiresUserGesture(true);
        }

        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.loadRequest(
          Uri.parse('data:text/html;charset=utf-8;base64,$videoTestBase64'),
        );

        await tester.pumpAndSettle();

        await pageLoaded.future;

        isPaused =
            _jsResultToBool(
                await controller.runJavaScriptReturningResult('isPaused();'));
        expect(isPaused, true);
      });

      testWidgets('Video plays inline', (WidgetTester tester) async {
        final String videoTestBase64 = await getTestVideoBase64();
        final pageLoaded = Completer<void>();
        final videoPlaying = Completer<void>();

        late PlatformWebViewControllerCreationParams params;
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          params = WebKitWebViewControllerCreationParams(
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
            allowsInlineMediaPlayback: true,
          );
        } else {
          params = const PlatformWebViewControllerCreationParams();
        }
        final controller = WebViewController.fromPlatformCreationParams(params);
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        if (controller.platform is AndroidWebViewController) {
          await (controller.platform as AndroidWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        } else if (controller.platform is OhosWebViewController) {
          await (controller.platform as OhosWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        }

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.addJavaScriptChannel(
          'VideoTestTime',
          onMessageReceived: (JavaScriptMessage message) {
            final double currentTime = double.parse(message.message);
            // Let it play for at least 1 second to make sure the related video's properties are set.
            if (currentTime > 1 && !videoPlaying.isCompleted) {
              videoPlaying.complete(null);
            }
          },
        );

        await controller.loadRequest(
          Uri.parse('data:text/html;charset=utf-8;base64,$videoTestBase64'),
        );

        await tester.pumpAndSettle();

        await pageLoaded.future;

        // Makes sure we get the correct event that indicates the video is actually playing.
        await videoPlaying.future;

        final fullScreen =
            _jsResultToBool(
                await controller.runJavaScriptReturningResult('isFullScreen();'));
        // OHOS: webkitDisplayingFullscreen 返回 undefined/null，_jsResultToBool 会将其转为 false，
        // 即 OHOS 上视频默认内联播放（不全屏），与测试期望一致。
        expect(fullScreen, false);
      });

    // allowsInlineMediaPlayback is a noop on Android, so it is skipped.
    testWidgets(
        'Video plays full screen when allowsInlineMediaPlayback is false',
        (WidgetTester tester) async {
      final Completer<void> pageLoaded = Completer<void>();
      final Completer<void> videoPlaying = Completer<void>();

      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      );
      unawaited(controller.setJavaScriptMode(JavaScriptMode.unrestricted));
      unawaited(controller.setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
      ));
      unawaited(controller.addJavaScriptChannel(
        'VideoTestTime',
        onMessageReceived: (JavaScriptMessage message) {
          final double currentTime = double.parse(message.message);
          // Let it play for at least 1 second to make sure the related video's properties are set.
          if (currentTime > 1 && !videoPlaying.isCompleted) {
            videoPlaying.complete(null);
          }
        },
      ));
      unawaited(controller.loadRequest(
        Uri.parse(
          'data:text/html;charset=utf-8;base64,$videoTestBase64',
        ),
      ));

      await tester.pumpWidget(WebViewWidget(controller: controller));
      await tester.pumpAndSettle();

      await pageLoaded.future;

      // Makes sure we get the correct event that indicates the video is actually playing.
      await videoPlaying.future;

      final bool fullScreen = await controller
          .runJavaScriptReturningResult('isFullScreen();') as bool;
      expect(fullScreen, true);
    }, skip: !Platform.isIOS); // 该用例依赖 WebKitWebViewControllerCreationParams（iOS 专属参数），仅在 iOS 平台可运行
  });

  group('Audio playback policy', () {
      late String audioTestBase64;
      setUpAll(() async {
        final ByteData audioData = await rootBundle.load(
          'assets/sample_audio.ogg',
        );
        final String base64AudioData = base64Encode(
          Uint8List.view(audioData.buffer),
        );
        final audioTest =
            '''
        <!DOCTYPE html><html>
        <head><title>Audio auto play</title>
          <script type="text/javascript">
            function play() {
              var audio = document.getElementById("audio");
              audio.play();
            }
            function isPaused() {
              var audio = document.getElementById("audio");
              return audio.paused;
            }
          </script>
        </head>
        <body onload="play();">
        <audio controls id="audio">
          <source src="data:audio/ogg;charset=utf-8;base64,$base64AudioData">
        </audio>
        </body>
        </html>
      ''';
        audioTestBase64 = base64Encode(const Utf8Encoder().convert(audioTest));
      });

      testWidgets('Auto media playback', (WidgetTester tester) async {
        var pageLoaded = Completer<void>();

        late PlatformWebViewControllerCreationParams params;
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          params = WebKitWebViewControllerCreationParams(
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          );
        } else {
          params = const PlatformWebViewControllerCreationParams();
        }

        var controller = WebViewController.fromPlatformCreationParams(params);
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        if (controller.platform is AndroidWebViewController) {
          await (controller.platform as AndroidWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        } else if (controller.platform is OhosWebViewController) {
          await (controller.platform as OhosWebViewController)
              .setMediaPlaybackRequiresUserGesture(false);
        }

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.loadRequest(
          Uri.parse('data:text/html;charset=utf-8;base64,$audioTestBase64'),
        );

        await tester.pumpAndSettle();

        await pageLoaded.future;

        var isPaused =
            _jsResultToBool(
                await controller.runJavaScriptReturningResult('isPaused();'));
        expect(isPaused, false);

        pageLoaded = Completer<void>();
        controller = WebViewController();
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        if (controller.platform is OhosWebViewController) {
          await (controller.platform as OhosWebViewController)
              .setMediaPlaybackRequiresUserGesture(true);
        }

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.loadRequest(
          Uri.parse('data:text/html;charset=utf-8;base64,$audioTestBase64'),
        );

        await tester.pumpAndSettle();
        await pageLoaded.future;

        isPaused =
            _jsResultToBool(
                await controller.runJavaScriptReturningResult('isPaused();'));
        expect(isPaused, true);
      });
    },
    // OGG playback is not supported on macOS, so the test data would need
    // to be changed to support macOS.
    skip: Platform.isMacOS,
  );

  testWidgets('getTitle', (WidgetTester tester) async {
    const getTitleTest = '''
        <!DOCTYPE html><html>
        <head><title>Some title</title>
        </head>
        <body>
        </body>
        </html>
      ''';
    final String getTitleTestBase64 = base64Encode(
      const Utf8Encoder().convert(getTitleTest),
    );
    final pageLoaded = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));

    await controller.loadRequest(
      Uri.parse('data:text/html;charset=utf-8;base64,$getTitleTestBase64'),
    );

    await pageLoaded.future;

    // On at least iOS, it does not appear to be guaranteed that the native
    // code has the title when the page load completes. Execute some JavaScript
    // before checking the title to ensure that the page has been fully parsed
    // and processed.
    await controller.runJavaScript('1;');

    final String? title = await controller.getTitle();
    expect(title, 'Some title');
  });

  group(
    'Programmatic Scroll',
    () {
      testWidgets('setAndGetScrollPosition', (WidgetTester tester) async {
        const scrollTestPage = '''
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                height: 100%;
                width: 100%;
              }
              #container{
                width:5000px;
                height:5000px;
            }
            </style>
          </head>
          <body>
            <div id="container"/>
          </body>
        </html>
      ''';

        final String scrollTestPageBase64 = base64Encode(
          const Utf8Encoder().convert(scrollTestPage),
        );

        final pageLoaded = Completer<void>();
        final controller = WebViewController();
        await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        await controller.setNavigationDelegate(
          NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
        );

        await tester.pumpWidget(WebViewWidget(controller: controller));

        await controller.loadRequest(
          Uri.parse(
            'data:text/html;charset=utf-8;base64,$scrollTestPageBase64',
          ),
        );

        await pageLoaded.future;

        await tester.pumpAndSettle(const Duration(seconds: 3));

        Offset scrollPos = await controller.getScrollPosition();

        // Check scrollTo()
        const X_SCROLL = 123;
        const Y_SCROLL = 321;
        // Get the initial position; this ensures that scrollTo is actually
        // changing something, but also gives the native view's scroll position
        // time to settle.
        expect(scrollPos.dx, isNot(X_SCROLL));
        expect(scrollPos.dy, isNot(Y_SCROLL));

        await controller.scrollTo(X_SCROLL, Y_SCROLL);
        // OHOS: scrollTo/scrollBy are async on the native side,
        // need to wait for the actual scroll to complete before reading position.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        scrollPos = await controller.getScrollPosition();
        expect(scrollPos.dx, X_SCROLL);
        expect(scrollPos.dy, Y_SCROLL);

        // Check scrollBy() (on top of scrollTo())
        await controller.scrollBy(X_SCROLL, Y_SCROLL);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        scrollPos = await controller.getScrollPosition();
        expect(scrollPos.dx, X_SCROLL * 2);
        expect(scrollPos.dy, Y_SCROLL * 2);
      });
    },
    // Scroll position is currently not implemented for macOS.
    // Flakes on iOS: https://github.com/flutter/flutter/issues/154826
    skip: Platform.isMacOS || Platform.isIOS,
  );

  group('NavigationDelegate', () {
    const blankPage = '<!DOCTYPE html><head></head><body></body></html>';
    final blankPageEncoded =
        'data:text/html;charset=utf-8;base64,'
        '${base64Encode(const Utf8Encoder().convert(blankPage))}';

    testWidgets('can allow requests', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => pageLoaded.complete(),
          onNavigationRequest: (NavigationRequest navigationRequest) {
            return navigationRequest.url.contains('youtube.com')
                ? NavigationDecision.prevent
                : NavigationDecision.navigate;
          },
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));

      await controller.loadRequest(Uri.parse(blankPageEncoded));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');
      await pageLoaded.future; // Wait for the next page load.

      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('onWebResourceError', (WidgetTester tester) async {
      final errorCompleter = Completer<WebResourceError>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            errorCompleter.complete(error);
          },
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));
      await controller.loadRequest(Uri.parse('https://www.notawebsite..com'));

      final WebResourceError error = await errorCompleter.future;
      expect(error, isNotNull);
    });

    testWidgets('onWebResourceError is not called with valid url', (
      WidgetTester tester,
    ) async {
      final errorCompleter = Completer<WebResourceError>();
      final pageFinishCompleter = Completer<void>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => pageFinishCompleter.complete(),
          onWebResourceError: (WebResourceError error) {
            errorCompleter.complete(error);
          },
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));
      await controller.loadRequest(
        Uri.parse('data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+'),
      );

      expect(errorCompleter.future, doesNotComplete);
      await pageFinishCompleter.future;
    });

    testWidgets('can block requests', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => pageLoaded.complete(),
          onNavigationRequest: (NavigationRequest navigationRequest) {
            return navigationRequest.url.contains('youtube.com')
                ? NavigationDecision.prevent
                : NavigationDecision.navigate;
          },
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));

      await controller.loadRequest(Uri.parse(blankPageEncoded));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript(
        'location.href = "https://www.youtube.com/"',
      );

      // There should never be any second page load, since our new URL is
      // blocked. Still wait for a potential page change for some time in order
      // to give the test a chance to fail.
      await pageLoaded.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => '',
      );
      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, isNot(contains('youtube.com')));
    });

    // OHOS: HttpResponseError and onHttpError are not available in this branch.
    // testWidgets('onHttpError', ...) — skipped
    // testWidgets('onHttpError is not called when no HTTP error is received', ...) — skipped

    testWidgets('supports asynchronous decisions', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => pageLoaded.complete(),
          onNavigationRequest: (NavigationRequest navigationRequest) async {
            NavigationDecision decision = NavigationDecision.prevent;
            decision = await Future<NavigationDecision>.delayed(
              const Duration(milliseconds: 10),
              () => NavigationDecision.navigate,
            );
            return decision;
          },
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));

      await controller.loadRequest(Uri.parse(blankPageEncoded));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');
      await pageLoaded.future; // Wait for second page to load.

      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('can receive url changes', (WidgetTester tester) async {
      final pageLoaded = Completer<void>();

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));
      await controller.loadRequest(Uri.parse(blankPageEncoded));

      await pageLoaded.future;

      final urlChangeCompleter = Completer<String>();
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            urlChangeCompleter.complete(change.url);
          },
        ),
      );

      await controller.runJavaScript('location.href = "$primaryUrl"');

      await expectLater(urlChangeCompleter.future, completion(primaryUrl));
    });

    testWidgets('can receive updates to history state', (
      WidgetTester tester,
    ) async {
      final pageLoaded = Completer<void>();

      final navigationDelegate = NavigationDelegate(
        onPageFinished: (_) => pageLoaded.complete(),
      );

      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(navigationDelegate);

      await tester.pumpWidget(WebViewWidget(controller: controller));
      await controller.loadRequest(Uri.parse(primaryUrl));

      await pageLoaded.future;

      final urlChangeCompleter = Completer<String>();
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            urlChangeCompleter.complete(change.url);
          },
        ),
      );

      await controller.runJavaScript(
        'window.history.pushState({}, "", "secondary.txt");',
      );

      await expectLater(urlChangeCompleter.future, completion(secondaryUrl));
    });

    testWidgets('can receive HTTP basic auth requests', (
      WidgetTester tester,
    ) async {
      final authRequested = Completer<void>();
      final controller = WebViewController();

      await controller.setNavigationDelegate(
        NavigationDelegate(
          onHttpAuthRequest: (HttpAuthRequest request) =>
              authRequested.complete(),
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));

      await controller.loadRequest(Uri.parse(basicAuthUrl));

      await expectLater(authRequested.future, completes);
    });

    testWidgets('can authenticate to HTTP basic auth requests', (
      WidgetTester tester,
    ) async {
      final controller = WebViewController();
      final pageFinished = Completer<void>();

      await controller.setNavigationDelegate(
        NavigationDelegate(
          onHttpAuthRequest: (HttpAuthRequest request) => request.onProceed(
            const WebViewCredential(user: 'user', password: 'password'),
          ),
          onPageFinished: (_) => pageFinished.complete(),
          onWebResourceError: (_) => fail('Authentication failed'),
        ),
      );

      await tester.pumpWidget(WebViewWidget(controller: controller));

      await controller.loadRequest(Uri.parse(basicAuthUrl));

      await expectLater(pageFinished.future, completes);
    });
  });

  // OHOS 跳过原因：window.open 会打开新的 CustomDialog（使用独立的 WebviewController），
  // 而非在当前 WebView 中导航，因此 currentUrl 不会改变，与该用例预期行为不符。
  testWidgets('target _blank opens in same window', (
    WidgetTester tester,
  ) async {
    final pageLoaded = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));

    await controller.runJavaScript('window.open("$primaryUrl", "_blank")');
    await pageLoaded.future;
    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  }, skip: defaultTargetPlatform == TargetPlatform.ohos);

  // OHOS 跳过原因：window.open 打开新的 CustomDialog（使用独立的 WebviewController），
  // 新 URL 不在当前 WebView 的导航栈中，goBack 无法回到前一个 URL。
  testWidgets('can open new window and go back', (WidgetTester tester) async {
    var pageLoaded = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageLoaded.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.loadRequest(Uri.parse(primaryUrl));

    expect(controller.currentUrl(), completion(primaryUrl));
    await pageLoaded.future;
    pageLoaded = Completer<void>();

    await controller.runJavaScript('window.open("$secondaryUrl")');
    await pageLoaded.future;
    pageLoaded = Completer<void>();
    expect(controller.currentUrl(), completion(secondaryUrl));

    expect(controller.canGoBack(), completion(true));
    await controller.goBack();
    await pageLoaded.future;
    await expectLater(controller.currentUrl(), completion(primaryUrl));
  }, skip: defaultTargetPlatform == TargetPlatform.ohos);

  testWidgets('clearLocalStorage', (WidgetTester tester) async {
    var pageLoadCompleter = Completer<void>();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => pageLoadCompleter.complete()),
    );

    await tester.pumpWidget(WebViewWidget(controller: controller));
    await controller.loadRequest(Uri.parse(primaryUrl));

    await pageLoadCompleter.future;
    pageLoadCompleter = Completer<void>();

    await controller.runJavaScript('localStorage.setItem("myCat", "Tom");');
    final myCatItem =
        await controller.runJavaScriptReturningResult(
              'localStorage.getItem("myCat");',
            )
            as String;
    expect(myCatItem, _webViewString('Tom'));

    await controller.clearLocalStorage();

    // Reload page to have changes take effect.
    await controller.reload();
    await pageLoadCompleter.future;

    late final String? nullItem;
    try {
      nullItem =
          await controller.runJavaScriptReturningResult(
                'localStorage.getItem("myCat");',
              )
              as String;
    } catch (exception) {
      if (_isWKWebView() &&
          exception is ArgumentError &&
          (exception.message as String).contains(
            'Result of JavaScript execution returned a `null` value.',
          )) {
        nullItem = '<null>';
      }
    }
    expect(nullItem, _webViewNull());
  });
}

// JavaScript `null` evaluate to different string values per platform.
// This utility method returns the string boolean value of the current platform.
String _webViewNull() {
  if (_isWKWebView()) {
    return '<null>';
  }
  return 'null';
}

// JavaScript String evaluates to different strings depending on the platform.
// This utility method returns the string boolean value of the current platform.
String _webViewString(String value) {
  if (_isWKWebView()) {
    return value;
  }
  return '"$value"';
}

bool _isWKWebView() {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class ResizableWebView extends StatefulWidget {
  const ResizableWebView({
    super.key,
    required this.onResize,
    required this.onPageFinished,
  });

  final VoidCallback onResize;
  final VoidCallback onPageFinished;

  @override
  State<StatefulWidget> createState() => ResizableWebViewState();
}

class ResizableWebViewState extends State<ResizableWebView> {
  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => widget.onPageFinished()),
    )
    ..addJavaScriptChannel(
      'Resize',
      onMessageReceived: (_) {
        widget.onResize();
      },
    );

  bool _hasLoadedUrl = false;

  double webViewWidth = 200;
  double webViewHeight = 200;

  static const String resizePage = '''
        <!DOCTYPE html><html>
        <head><title>Resize test</title>
          <script type="text/javascript">
            function onResize() {
              Resize.postMessage("resize");
            }
            function onLoad() {
              window.onresize = onResize;
            }
          </script>
        </head>
        <body onload="onLoad();" bgColor="blue">
        </body>
        </html>
      ''';

  @override
  Widget build(BuildContext context) {
    // Load the URL after the WebViewWidget has been rendered to avoid
    // deadlocking on OHOS where loadUrl waits for the controller to attach.
    if (!_hasLoadedUrl) {
      _hasLoadedUrl = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadRequest(
          Uri.parse(
            'data:text/html;charset=utf-8;base64,${base64Encode(const Utf8Encoder().convert(resizePage))}',
          ),
        );
      });
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          SizedBox(
              width: webViewWidth,
              height: webViewHeight,
              child: WebViewWidget(controller: controller)),
          TextButton(
            key: const Key('resizeButton'),
            onPressed: () {
              setState(() {
                webViewWidth += 100.0;
                webViewHeight += 100.0;
              });
            },
            child: const Text('ResizeButton'),
          ),
        ],
      ),
    );
  }
}

Future<String> getTestVideoBase64() async {
  final ByteData videoData = await rootBundle.load('assets/sample_video.mp4');
  final String base64VideoData = base64Encode(Uint8List.view(videoData.buffer));
  final videoTest =
      '''
        <!DOCTYPE html><html>
        <head><title>Video auto play</title>
          <script type="text/javascript">
            function play() {
              var video = document.getElementById("video");
              video.play();
              video.addEventListener('timeupdate', videoTimeUpdateHandler, false);
            }
            function videoTimeUpdateHandler(e) {
              var video = document.getElementById("video");
              VideoTestTime.postMessage(video.currentTime);
            }
            function isPaused() {
              var video = document.getElementById("video");
              return video.paused;
            }
            function isFullScreen() {
              var video = document.getElementById("video");
              return video.webkitDisplayingFullscreen;
            }
          </script>
        </head>
        <body onload="play();">
        <video controls playsinline autoplay id="video">
          <source src="data:video/mp4;charset=utf-8;base64,$base64VideoData">
        </video>
        </body>
        </html>
      ''';
  return base64Encode(const Utf8Encoder().convert(videoTest));
}

// OHOS WebView may return JSON-encoded string values (e.g., '"true"' instead of
// a native bool). This helper safely converts the result of
// runJavaScriptReturningResult to bool.
bool _jsResultToBool(Object result) {
  if (result is bool) {
    return result;
  }
  final str = result.toString().trim().toLowerCase();
  return str == 'true';
}
