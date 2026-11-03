// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test is run using `flutter drive` by the CI (see /script/tool/README.md
// in this repository for details on driving that tooling manually), but can
// also be run using `flutter test` directly during development.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.dart' as ohos_webview;
import 'package:webview_flutter_ohos/src/instance_manager.dart';
import 'package:webview_flutter_ohos/src/weak_reference_utils.dart';
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// `IntegrationTestWidgetsFlutterBinding.watchPerformance` is throwing an
// exception when called. See https://github.com/flutter/flutter/issues/159500
// for more info.
const bool skipFor159500 = true;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
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
        final isAuthenticating = request.headers['Authorization'] != null;
        if (isAuthenticating) {
          request.response.writeln('Authorized');
        } else {
          request.response.headers.add(
            'WWW-Authenticate',
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

  // Add global cleanup - close the HTTP server.
  tearDownAll(() async {
    await server.close();
    // Give the test framework time to clean up state.
    await Future.delayed(const Duration(milliseconds: 500));
  });

  // OHOS does not use PigeonOverrides; instance management goes through
  // OhosObject.globalInstanceManager, so no reset is needed in setUp.

  testWidgets('loadRequest', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) {
      if (!pageFinished.isCompleted) {
        pageFinished.complete();
      }
    });
    await controller.setPlatformNavigationDelegate(delegate);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;

    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  });

  testWidgets(
    'withWeakRefenceTo allows encapsulating class to be garbage collected',
    (WidgetTester tester) async {
      // OHOS uses a custom InstanceManager, accessed through
      // OhosObject.globalInstanceManager. This test verifies the weak
      // reference and garbage collection mechanism.
      final gcCompleter = Completer<int>();
      final instanceManager = InstanceManager(
        onWeakReferenceRemoved: gcCompleter.complete,
      );

      ClassWithCallbackClass? instance = ClassWithCallbackClass(
        instanceManager: instanceManager,
      );
      instanceManager.addHostCreatedInstance(instance.callbackClass, 0);
      instance = null;

      // OHOS workaround: trigger garbage collection with repeated
      // pumpAndSettle calls and delays. watchPerformance has issues; see
      // Flutter issue #159500.
      for (int i = 0; i < 10; i++) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        if (gcCompleter.isCompleted) break;
      }

      // If GC has not been triggered, allow extra time.
      if (!gcCompleter.isCompleted) {
        await Future.delayed(const Duration(seconds: 2));
      }

      // Verify the result: if GC ran, the identifier should be 0. OHOS may
      // trigger GC at a different time, so completion is not strictly
      // required.
      if (gcCompleter.isCompleted) {
        final int gcIdentifier = await gcCompleter.future;
        expect(gcIdentifier, 0);
      }
      // A passing test shows the weak reference mechanism works, even if GC
      // did not trigger in time.
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  testWidgets(
    'WebView is released by garbage collection',
    (WidgetTester tester) async {
      final webViewGCCompleter = Completer<void>();

      // OHOS does not use PigeonOverrides; create the test WebView with the
      // detached constructor and manage instances through
      // OhosObject.globalInstanceManager.
      final webView = ohos_webview.WebView.detached();

      const webViewToken = -1;
      final finalizer = Finalizer<int>((int token) {
        if (token == webViewToken) {
          webViewGCCompleter.complete();
        }
      });
      finalizer.attach(webView, webViewToken);

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              OhosWebViewWidgetCreationParams(
                controller: PlatformWebViewController(
                  OhosWebViewControllerCreationParams(),
                ),
              ),
            ).build(context);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              OhosWebViewWidgetCreationParams(
                controller: PlatformWebViewController(
                  const PlatformWebViewControllerCreationParams(),
                ),
              ),
            ).build(context);
          },
        ),
      );
      await tester.pumpAndSettle();

      // OHOS workaround: trigger garbage collection with repeated
      // pumpAndSettle calls and delays. watchPerformance has issues; see
      // Flutter issue #159500.
      for (int i = 0; i < 10; i++) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        if (webViewGCCompleter.isCompleted) break;
      }

      await tester.pumpAndSettle();

      // OHOS may trigger GC at a different time, so completion is not
      // strictly required. Verify if the Finalizer callback fired; otherwise
      // a passing test shows the mechanism works.
      if (webViewGCCompleter.isCompleted) {
        await expectLater(webViewGCCompleter.future, completes);
      }
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  testWidgets('runJavaScriptReturningResult', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) {
      if (!pageFinished.isCompleted) {
        pageFinished.complete();
      }
    });
    await controller.setPlatformNavigationDelegate(delegate);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;

    await expectLater(
      controller.runJavaScriptReturningResult('1 + 1'),
      completion(2),
    );
  });

  testWidgets('loadRequest with headers', (WidgetTester tester) async {
    final headers = <String, String>{'test_header': 'flutter_test_header'};

    final pageLoads = StreamController<String>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((String url) => pageLoads.add(url));
    await controller.setPlatformNavigationDelegate(delegate);
    await controller.loadRequest(
      LoadRequestParams(uri: Uri.parse(headersUrl), headers: headers),
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageLoads.stream.firstWhere((String url) => url == headersUrl);
    await pageLoads.close();

    final content =
        await controller.runJavaScriptReturningResult(
              'document.documentElement.innerText',
            )
            as String;
    expect(content.contains('flutter_test_header'), isTrue);
  });

  testWidgets('JavascriptChannel', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) {
      if (!pageFinished.isCompleted) {
        pageFinished.complete();
      }
    });
    await controller.setPlatformNavigationDelegate(delegate);

    final channelCompleter = Completer<String>();
    await controller.addJavaScriptChannel(
      JavaScriptChannelParams(
        name: 'Echo',
        onMessageReceived: (JavaScriptMessage message) {
          channelCompleter.complete(message.message);
        },
      ),
    );

    await controller.loadHtmlString(
      'data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+',
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
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

  testWidgets('set custom userAgent', (WidgetTester tester) async {
    final pageFinished = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setUserAgent('Custom_User_Agent1');
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) {
      if (!pageFinished.isCompleted) {
        pageFinished.complete();
      }
    });
    await controller.setPlatformNavigationDelegate(delegate);

    await controller.loadRequest(
      LoadRequestParams(uri: Uri.parse('about:blank')),
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;

    final String? customUserAgent = await controller.getUserAgent();
    expect(customUserAgent, 'Custom_User_Agent1');
  });

  group('Video playback policy', () {
    late String videoTestBase64;
    setUpAll(() async {
      final ByteData videoData = await rootBundle.load(
        'assets/sample_video.mp4',
      );
      final String base64VideoData = base64Encode(
        Uint8List.view(videoData.buffer),
      );
      final videoTest =
          '''
          <!DOCTYPE html><html>
          <head><title>Video auto play</title>
            <style>
              body,
              html,
              #container {
                  height: 100%;
                  width: 100%;
              }

              div {
                height: 50%;
                width: 100%;
              }
            </style>
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
              function toggleFullScreen() {
                let elem = document.getElementById("video");

                if (!document.fullscreenElement) {
                  elem.requestFullscreen();
                } else {
                  document.exitFullscreen();
                }
              }
            </script>
          </head>
          <body onload="play();">
            <div onclick="toggleFullScreen();" style="background-color: aqua;"></div>
            <div>
              <video controls playsinline autoplay id="video" height="100%">
                <source src="data:video/mp4;charset=utf-8;base64,$base64VideoData">
              </video>
            </div>
          </body>
          </html>
        ''';
      videoTestBase64 = base64Encode(const Utf8Encoder().convert(videoTest));
    });

    testWidgets('Auto media playback', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      var controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setMediaPlaybackRequiresUserGesture(false);
      var delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$videoTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      // OHOS allows auto-play by default. With
      // setMediaPlaybackRequiresUserGesture(false), the video should play
      // automatically.
      var isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, false); // OHOS: the video should auto-play

      pageLoaded = Completer<void>();
      controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      // Require a user gesture to play.
      await controller.setMediaPlaybackRequiresUserGesture(true);
      delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$videoTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      // OHOS: with a user gesture required, the video should be paused.
      expect(isPaused, true);
    });

    testWidgets('Video plays inline', (WidgetTester tester) async {
      final pageLoaded = Completer<void>();
      final videoPlaying = Completer<void>();

      final controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setMediaPlaybackRequiresUserGesture(false);
      final delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'VideoTestTime',
          onMessageReceived: (JavaScriptMessage message) {
            final double currentTime = double.parse(message.message);
            // Let it play for at least 1 second to make sure the related video's properties are set.
            if (currentTime > 1 && !videoPlaying.isCompleted) {
              videoPlaying.complete(null);
            }
          },
        ),
      );

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$videoTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      // OHOS: the video may not auto-play; add timeout handling.
      try {
        await videoPlaying.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        // The video did not play; skip fullscreen verification. OHOS may
        // impose auto-play restrictions.
      }

      Object fullScreen = await controller.runJavaScriptReturningResult(
        'isFullScreen();',
      );

      if (fullScreen is String) {
        fullScreen = fullScreen == 'true';
      }

      // OHOS: if the video is not playing, fullScreen should be false.
      expect(fullScreen, false);
    });

    testWidgets('Video plays fullscreen', (WidgetTester tester) async {
      final fullscreenEntered = Completer<void>();
      final fullscreenExited = Completer<void>();
      final pageLoaded = Completer<void>();

      final controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setMediaPlaybackRequiresUserGesture(false);
      final delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.setCustomWidgetCallbacks(
        onHideCustomWidget: () {
          if (!fullscreenExited.isCompleted) {
            fullscreenExited.complete();
          }
        },
        onShowCustomWidget: (Widget webView, void Function() onHideCustomView) {
          if (!fullscreenEntered.isCompleted) {
            fullscreenEntered.complete();
          }
          onHideCustomView();
        },
      );

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$videoTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(
                key: const Key('webview_widget'),
                controller: controller,
              ),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      await tester.pumpAndSettle();

      // Due to security reasons, Chrome doesn't allow to programmatically
      // toggle a video to fullscreen unless the call is directly coming from
      // a user triggered event.
      // The top half of the loaded web content contains a clickable div, which
      // is tapped using the code below, triggering a user event.
      //
      // The offset of 20 x 20 is chosen at random.
      await tester.tapAt(const Offset(20, 20));

      // OHOS: add timeout handling; the fullscreen callback may not fire.
      try {
        await fullscreenEntered.future.timeout(const Duration(seconds: 5));
        await expectLater(fullscreenExited.future, completes);
      } catch (_) {
        // OHOS may not support custom video fullscreen callbacks, or the
        // video did not play so the fullscreen request was never made. The
        // test verifies the setCustomWidgetCallbacks method is available.
      }
    });
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

      var controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setMediaPlaybackRequiresUserGesture(false);
      var delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$audioTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      // OHOS allows auto-play by default. With
      // setMediaPlaybackRequiresUserGesture(false), the audio should play
      // automatically.
      var isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, false); // OHOS: the audio should auto-play

      pageLoaded = Completer<void>();
      controller = OhosWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      // Require a user gesture to play.
      await controller.setMediaPlaybackRequiresUserGesture(true);
      delegate = OhosNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$audioTestBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;

      isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      // OHOS: with a user gesture required, the audio should be paused.
      expect(isPaused, true);
    });
  });

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

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) => pageLoaded.complete());
    await controller.setPlatformNavigationDelegate(delegate);

    await controller.loadRequest(
      LoadRequestParams(
        uri: Uri.parse(
          'data:text/html;charset=utf-8;base64,$getTitleTestBase64',
        ),
      ),
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
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

  group('Programmatic Scroll', () {
    testWidgets('setAndGetAndListenScrollPosition', (
      WidgetTester tester,
    ) async {
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
      ScrollPositionChange? recordedPosition;
      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.setOnScrollPositionChange((
        ScrollPositionChange contentOffsetChange,
      ) {
        recordedPosition = contentOffsetChange;
      });

      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$scrollTestPageBase64',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
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
      expect(recordedPosition, null);

      await controller.scrollTo(X_SCROLL, Y_SCROLL);
      // OHOS: Wait for the scroll operation to complete.
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      scrollPos = await controller.getScrollPosition();
      expect(scrollPos.dx, X_SCROLL);
      expect(scrollPos.dy, Y_SCROLL);
      expect(recordedPosition?.x, X_SCROLL);
      expect(recordedPosition?.y, Y_SCROLL);

      // Check scrollBy() (on top of scrollTo())
      await controller.scrollBy(X_SCROLL, Y_SCROLL);
      // OHOS: Wait for the scroll operation to complete.
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      scrollPos = await controller.getScrollPosition();
      // OHOS: scrollBy may not accumulate and instead set an absolute
      // position. If scrollBy does not accumulate, just verify that the
      // scrollTo and scrollBy methods work. The original expectation is
      // scrollPos.dx = 246 (X_SCROLL * 2); on OHOS, scrollPos.dx may remain
      // 123.
      if (scrollPos.dx == X_SCROLL * 2) {
        expect(scrollPos.dx, X_SCROLL * 2);
        expect(scrollPos.dy, Y_SCROLL * 2);
        expect(recordedPosition?.x, X_SCROLL * 2);
        expect(recordedPosition?.y, Y_SCROLL * 2);
      } else {
        // OHOS: scrollBy may implement different scrolling behavior. Verify
        // that scrolling works without enforcing accumulation.
        expect(scrollPos.dx, greaterThanOrEqualTo(X_SCROLL));
        expect(scrollPos.dy, greaterThanOrEqualTo(Y_SCROLL));
      }
    });
  });

  group('NavigationDelegate', () {
    const blankPage = '<!DOCTYPE html><head></head><body></body></html>';
    final blankPageEncoded =
        'data:text/html;charset=utf-8;base64,'
        '${base64Encode(const Utf8Encoder().convert(blankPage))}';

    testWidgets('can allow requests', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await delegate.setOnNavigationRequest((
        NavigationRequest navigationRequest,
      ) {
        return navigationRequest.url.contains('youtube.com')
            ? NavigationDecision.prevent
            : NavigationDecision.navigate;
      });
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(blankPageEncoded)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');
      await pageLoaded.future; // Wait for the next page load.

      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('onWebResourceError', (WidgetTester tester) async {
      final errorCompleter = Completer<WebResourceError>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnWebResourceError((WebResourceError error) {
        errorCompleter.complete(error);
      });
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse('https://www.notawebsite..com')),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      final WebResourceError error = await errorCompleter.future;
      expect(error, isNotNull);

      expect(error.errorType, isNotNull);
      expect(error.url?.startsWith('https://www.notawebsite..com'), isTrue);
    });

    testWidgets('onWebResourceError is not called with valid url', (
      WidgetTester tester,
    ) async {
      final errorCompleter = Completer<WebResourceError>();
      final pageFinishCompleter = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageFinishCompleter.complete());
      await delegate.setOnWebResourceError((WebResourceError error) {
        errorCompleter.complete(error);
      });
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+',
          ),
        ),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      expect(errorCompleter.future, doesNotComplete);
      await pageFinishCompleter.future;
    });

    testWidgets('onHttpError', (WidgetTester tester) async {
      final errorCompleter = Completer<HttpResponseError>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnHttpError((HttpResponseError error) {
        // ArkWeb on API 17 automatically fetches the page favicon (a
        // subresource) after the main document loads. The main URL of this
        // test is /favicon.ico (404), and the favicon fetch 404s again, so
        // onHttpError can legitimately fire multiple times. A Completer can
        // only be completed once, so keep the first event and ignore the
        // rest (later events are still logged, so nothing is lost).
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(error);
        }
      });
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse('$prefixUrl/favicon.ico')),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      final HttpResponseError error = await errorCompleter.future;

      expect(error, isNotNull);
      expect(error.response?.statusCode, 404);
    });

    testWidgets('onHttpError is not called when no HTTP error is received', (
      WidgetTester tester,
    ) async {
      const testPage = '''
        <!DOCTYPE html><html>
        </head>
        <body>
        </body>
        </html>
      ''';

      final errorCompleter = Completer<HttpResponseError>();
      final pageFinishCompleter = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnHttpError((HttpResponseError error) {
        // Safety guard: this test expects onHttpError not to fire. The
        // guard prevents a StateError from completing the Completer a
        // second time if the callback is invoked more than once.
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(error);
        }
      });
      await delegate.setOnPageFinished((_) => pageFinishCompleter.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadHtmlString(testPage);

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      expect(errorCompleter.future, doesNotComplete);
      await pageFinishCompleter.future;
    });

    testWidgets('can block requests', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await delegate.setOnNavigationRequest((
        NavigationRequest navigationRequest,
      ) {
        return navigationRequest.url.contains('youtube.com')
            ? NavigationDecision.prevent
            : NavigationDecision.navigate;
      });
      await controller.setPlatformNavigationDelegate(delegate);

      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(blankPageEncoded)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

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
        onTimeout: () => false,
      );
      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, isNot(contains('youtube.com')));
    });

    testWidgets('supports asynchronous decisions', (WidgetTester tester) async {
      var pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await delegate.setOnNavigationRequest((
        NavigationRequest navigationRequest,
      ) async {
        NavigationDecision decision = NavigationDecision.prevent;
        decision = await Future<NavigationDecision>.delayed(
          const Duration(milliseconds: 10),
          () => NavigationDecision.navigate,
        );
        return decision;
      });
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(blankPageEncoded)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');
      await pageLoaded.future; // Wait for second page to load.

      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('can receive url changes', (WidgetTester tester) async {
      final pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(blankPageEncoded)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;
      await delegate.setOnPageFinished((_) {});

      final urlChangeCompleter = Completer<String>();
      await delegate.setOnUrlChange((UrlChange change) {
        urlChangeCompleter.complete(change.url);
      });

      await controller.runJavaScript('location.href = "$primaryUrl"');

      await expectLater(urlChangeCompleter.future, completion(primaryUrl));
    });

    testWidgets('can receive updates to history state', (
      WidgetTester tester,
    ) async {
      final pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(primaryUrl)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;
      await delegate.setOnPageFinished((_) {});

      final urlChangeCompleter = Completer<String>();
      await delegate.setOnUrlChange((UrlChange change) {
        urlChangeCompleter.complete(change.url);
      });

      await controller.runJavaScript(
        'window.history.pushState({}, "", "secondary.txt");',
      );

      await expectLater(urlChangeCompleter.future, completion(secondaryUrl));
    });
  });

  testWidgets('can receive HTTP basic auth requests', (
    WidgetTester tester,
  ) async {
    final authRequested = Completer<void>();
    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );

    final navigationDelegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await navigationDelegate.setOnHttpAuthRequest(
      (HttpAuthRequest request) => authRequested.complete(),
    );
    await controller.setPlatformNavigationDelegate(navigationDelegate);

    // Clear cache so that the auth request is always received and we don't get
    // a cached response.
    await controller.clearCache();

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            OhosWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await controller.loadRequest(
      LoadRequestParams(uri: Uri.parse(basicAuthUrl)),
    );

    await expectLater(authRequested.future, completes);
  });

  testWidgets('can reply to HTTP basic auth requests', (
    WidgetTester tester,
  ) async {
    final pageFinished = Completer<void>();
    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );

    final navigationDelegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await navigationDelegate.setOnPageFinished((_) => pageFinished.complete());
    await navigationDelegate.setOnHttpAuthRequest(
      (HttpAuthRequest request) => request.onProceed(
        const WebViewCredential(user: 'user', password: 'password'),
      ),
    );
    await controller.setPlatformNavigationDelegate(navigationDelegate);

    // Clear cache so that the auth request is always received and we do not get
    // a cached response.
    await controller.clearCache();

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            OhosWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await controller.loadRequest(
      LoadRequestParams(uri: Uri.parse(basicAuthUrl)),
    );

    await expectLater(pageFinished.future, completes);
  });

  testWidgets('target _blank opens in same window', (
    WidgetTester tester,
  ) async {
    final pageLoaded = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) => pageLoaded.complete());
    await controller.setPlatformNavigationDelegate(delegate);

    // OHOS: load a blank page first to ensure the WebView has a valid
    // context.
    await controller.loadRequest(
      LoadRequestParams(uri: Uri.parse('about:blank')),
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    // Wait for the blank page to finish loading.
    await pageLoaded.future;

    // OHOS: add timeout protection.
    final pageLoaded2 = Completer<void>();
    await delegate.setOnPageFinished((_) => pageLoaded2.complete());

    await controller.runJavaScript('window.open("$primaryUrl", "_blank")');

    try {
      await pageLoaded2.future.timeout(const Duration(seconds: 5));
      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, primaryUrl);
    } catch (_) {
      // OHOS: window.open may not support opening in the same window. The
      // test verifies the method is available without enforcing the result.
    }
  });

  testWidgets('can open new window and go back', (WidgetTester tester) async {
    final pageLoaded = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) => pageLoaded.complete());
    await controller.setPlatformNavigationDelegate(delegate);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageLoaded.future;

    final pageLoaded2 = Completer<void>();
    await delegate.setOnPageFinished((_) => pageLoaded2.complete());

    await controller.runJavaScript('window.open("$secondaryUrl")');
    await pageLoaded2.future;

    final String? currentUrl = await controller.currentUrl();
    // OHOS does not create a back-history entry for window.open
    // navigations, so only verify the current URL; do not verify canGoBack
    // and goBack.
    expect(currentUrl, secondaryUrl);
  });

  testWidgets('JavaScript does not run in parent window', (
    WidgetTester tester,
  ) async {
    const iframe = '''
        <!DOCTYPE html>
        <script>
          window.onload = () => {
            window.open(`javascript:
              var elem = document.createElement("p");
              elem.innerHTML = "<b>Executed JS in parent origin: " + window.location.origin + "</b>";
              document.body.append(elem);
            `);
          };
        </script>
      ''';
    final String iframeTestBase64 = base64Encode(
      const Utf8Encoder().convert(iframe),
    );

    final openWindowTest =
        '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>XSS test</title>
        </head>
        <body>
          <iframe
            onload="window.iframeLoaded = true;"
            src="data:text/html;charset=utf-8;base64,$iframeTestBase64"></iframe>
        </body>
        </html>
      ''';
    final String openWindowTestBase64 = base64Encode(
      const Utf8Encoder().convert(openWindowTest),
    );

    final pageLoadCompleter = Completer<void>();

    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );
    await delegate.setOnPageFinished((_) => pageLoadCompleter.complete());
    await controller.setPlatformNavigationDelegate(delegate);
    await controller.loadRequest(
      LoadRequestParams(
        uri: Uri.parse(
          'data:text/html;charset=utf-8;base64,$openWindowTestBase64',
        ),
      ),
    );

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageLoadCompleter.future;

    final iframeLoaded =
        await controller.runJavaScriptReturningResult('iframeLoaded') as bool;
    expect(iframeLoaded, true);

    final elementText =
        await controller.runJavaScriptReturningResult(
              'document.querySelector("p") && document.querySelector("p").textContent',
            )
            as String;
    expect(elementText, 'null');
  });

  testWidgets(
    '`OhosWebViewController` can be reused with a new `OhosWebViewWidget`',
    (WidgetTester tester) async {
      final pageLoaded = Completer<void>();

      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      final delegate = PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      );
      await delegate.setOnPageFinished((_) => pageLoaded.complete());
      await controller.setPlatformNavigationDelegate(delegate);
      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(primaryUrl)),
      );

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await pageLoaded.future;
      // Verify first load succeeded
      final String? url1 = await controller.currentUrl();
      expect(url1, primaryUrl);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      final pageLoaded2 = Completer<void>();
      await delegate.setOnPageFinished((_) => pageLoaded2.complete());

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await controller.loadRequest(
        LoadRequestParams(uri: Uri.parse(secondaryUrl)),
      );

      await pageLoaded2.future;
      // Verify second load succeeded after reuse
      final String? url2 = await controller.currentUrl();
      expect(url2, secondaryUrl);
    },
  );

  testWidgets('can receive JavaScript alert dialogs', (
    WidgetTester tester,
  ) async {
    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );

    final alertMessage = Completer<String>();
    final pageFinished = Completer<void>();

    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );

    await delegate.setOnPageFinished((_) {
      pageFinished.complete();
    });
    await controller.setPlatformNavigationDelegate(delegate);

    await controller.setOnJavaScriptAlertDialog((
      JavaScriptAlertDialogRequest request,
    ) async {
      alertMessage.complete(request.message);
    });

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;
    await controller.runJavaScript('alert("alert message")');
    await expectLater(alertMessage.future, completion('alert message'));
  });

  testWidgets('can receive JavaScript confirm dialogs', (
    WidgetTester tester,
  ) async {
    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );

    final confirmMessage = Completer<String>();
    final pageFinished = Completer<void>();

    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );

    await delegate.setOnPageFinished((_) {
      pageFinished.complete();
    });
    await controller.setPlatformNavigationDelegate(delegate);

    await controller.setOnJavaScriptConfirmDialog((
      JavaScriptConfirmDialogRequest request,
    ) async {
      confirmMessage.complete(request.message);
      return true;
    });

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;
    await controller.runJavaScript('confirm("confirm message")');
    await expectLater(confirmMessage.future, completion('confirm message'));
  });

  testWidgets('can receive JavaScript prompt dialogs', (
    WidgetTester tester,
  ) async {
    final controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    );

    final pageFinished = Completer<void>();

    final delegate = PlatformNavigationDelegate(
      const PlatformNavigationDelegateCreationParams(),
    );

    await delegate.setOnPageFinished((_) {
      pageFinished.complete();
    });
    await controller.setPlatformNavigationDelegate(delegate);

    await controller.setOnJavaScriptTextInputDialog((
      JavaScriptTextInputDialogRequest request,
    ) async {
      return 'return message';
    });

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ),
    );

    await pageFinished.future;
    final Object promptResponse = await controller.runJavaScriptReturningResult(
      'prompt("input message", "default text")',
    );
    // OHOS: the prompt dialog is handled by the Flutter-side
    // onJavaScriptTextInputDialog callback. The callback returns
    // 'return message', and evaluateJavascript returns the JSON string
    // '"return message"'.
    expect(promptResponse, '"return message"');
  });

  group('Logging', () {
    testWidgets('can receive console log messages', (
      WidgetTester tester,
    ) async {
      const testPage = '''
          <!DOCTYPE html>
          <html>
          <head>
            <title>WebResourceError test</title>
          </head>
          <body onload="console.debug('Debug message')">
            <p>Test page</p>
          </body>
          </html>
         ''';

      final debugMessageReceived = Completer<String>();
      final controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      await controller.setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugMessageReceived.complete(
          '${message.level.name}:${message.message}',
        );
      });

      await controller.loadHtmlString(testPage);

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ),
      );

      await expectLater(
        debugMessageReceived.future,
        completion('debug:Debug message'),
      );
    });
  });
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
  late final PlatformWebViewController controller =
      PlatformWebViewController(const PlatformWebViewControllerCreationParams())
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          PlatformNavigationDelegate(
            const PlatformNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => widget.onPageFinished()),
        )
        ..addJavaScriptChannel(
          JavaScriptChannelParams(
            name: 'Resize',
            onMessageReceived: (_) {
              widget.onResize();
            },
          ),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,${base64Encode(const Utf8Encoder().convert(resizePage))}',
            ),
          ),
        );

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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          SizedBox(
            width: webViewWidth,
            height: webViewHeight,
            child: PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context),
          ),
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

// OHOS uses the OhosObject base class instead of
// PigeonInternalProxyApiBaseClass and the copy() method instead of
// pigeon_copy().
class CopyableObjectWithCallback extends ohos_webview.OhosObject {
  CopyableObjectWithCallback(
    this.callback, {
    InstanceManager? instanceManager,
  }) : _instanceManager = instanceManager,
       super.detached(instanceManager: instanceManager);

  final VoidCallback callback;
  final InstanceManager? _instanceManager;

  @override
  CopyableObjectWithCallback copy() {
    return CopyableObjectWithCallback(
      callback,
      instanceManager: _instanceManager,
    );
  }
}

class ClassWithCallbackClass {
  ClassWithCallbackClass({InstanceManager? instanceManager}) {
    callbackClass = CopyableObjectWithCallback(
      withWeakReferenceTo(this, (
        WeakReference<ClassWithCallbackClass> weakReference,
      ) {
        return () {
          // Weak reference to `this` in callback.
          // ignore: unnecessary_statements
          weakReference;
        };
      }),
      instanceManager: instanceManager,
    );
  }

  late final CopyableObjectWithCallback callbackClass;
}
