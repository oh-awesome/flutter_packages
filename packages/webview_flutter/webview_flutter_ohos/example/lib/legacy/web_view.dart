// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:webview_flutter_ohos/src/webview_flutter_ohos_legacy.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import 'navigation_decision.dart';
import 'navigation_request.dart';

/// Optional callback invoked when a web view is first created. [controller] is
/// the [WebViewController] for the created web view.
typedef WebViewCreatedCallback = void Function(WebViewController controller);

/// Decides how to handle a specific navigation request.
///
/// The returned [NavigationDecision] determines how the navigation described by
/// `navigation` should be handled.
///
/// See also: [WebView.navigationDelegate].
typedef NavigationDelegate = FutureOr<NavigationDecision> Function(
    NavigationRequest navigation);

/// Signature for when a [WebView] has started loading a page.
typedef PageStartedCallback = void Function(String url);

/// Signature for when a [WebView] has finished loading a page.
typedef PageFinishedCallback = void Function(String url);

/// Signature for when a [WebView] is loading a page.
typedef PageLoadingCallback = void Function(int progress);

/// Signature for when a [WebView] has failed to load a resource.
typedef WebResourceErrorCallback = void Function(WebResourceError error);

/// A web view widget for showing html content.
///
/// The [WebView] widget wraps around the [OhosWebView] class and acts like a
/// facade which makes it easier to inject an [OhosWebView] control into the
/// widget hierarchy.
///
/// The [WebView] widget is controlled using the [WebViewController] which is
/// provided through the `onWebViewCreated` callback.
///
/// In this example project it's main purpose is to facilitate integration
/// testing of the `webview_flutter_ohos` package.
class WebView extends StatefulWidget {
  /// Creates a new web view.
  const WebView({
    super.key,
    this.onWebViewCreated,
    this.initialUrl,
    this.initialCookies = const <WebViewCookie>[],
    this.javascriptMode = JavascriptMode.disabled,
    this.javascriptChannels,
    this.navigationDelegate,
    this.gestureRecognizers,
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onWebResourceError,
    this.debuggingEnabled = false,
    this.gestureNavigationEnabled = false,
    this.userAgent,
    this.zoomEnabled = true,
    this.initialMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
    this.allowsInlineMediaPlayback = false,
    this.backgroundColor,
  });

  /// The WebView platform that's used by this WebView.
  ///
  /// The default value is [OhosWebView].
  static WebViewPlatform platform = OhosWebView();

  /// If not null invoked once the web view is created.
  final WebViewCreatedCallback? onWebViewCreated;

  /// Which gestures should be consumed by the web view.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// The initial URL to load.
  final String? initialUrl;

  /// The initial cookies to set.
  final List<WebViewCookie> initialCookies;

  /// Whether JavaScript execution is enabled.
  final JavascriptMode javascriptMode;

  /// The set of [JavascriptChannel]s available to JavaScript code running in the web view.
  final Set<JavascriptChannel>? javascriptChannels;

  /// A delegate function that decides how to handle navigation actions.
  final NavigationDelegate? navigationDelegate;

  /// Controls whether inline playback of HTML5 videos is allowed.
  final bool allowsInlineMediaPlayback;

  /// Invoked when a page starts loading.
  final PageStartedCallback? onPageStarted;

  /// Invoked when a page has finished loading.
  final PageFinishedCallback? onPageFinished;

  /// Invoked when a page is loading.
  final PageLoadingCallback? onProgress;

  /// Invoked when a web resource has failed to load.
  final WebResourceErrorCallback? onWebResourceError;

  /// Controls whether WebView debugging is enabled.
  final bool debuggingEnabled;

  /// A Boolean value indicating whether horizontal swipe gestures will trigger back-forward list navigations.
  final bool gestureNavigationEnabled;

  /// A Boolean value indicating whether the WebView should support zooming.
  final bool zoomEnabled;

  /// The value used for the HTTP User-Agent: request header.
  final String? userAgent;

  /// Which restrictions apply on automatic media playback.
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  /// The background color of the [WebView].
  final Color? backgroundColor;

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late final JavascriptChannelRegistry _javascriptChannelRegistry;
  late final _PlatformCallbacksHandler _platformCallbacksHandler;

  @override
  void initState() {
    super.initState();
    _platformCallbacksHandler = _PlatformCallbacksHandler(widget);
    _javascriptChannelRegistry =
        JavascriptChannelRegistry(widget.javascriptChannels);
  }

  @override
  void didUpdateWidget(WebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.future.then((WebViewController controller) {
      controller.updateWidget(widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebView.platform.build(
      context: context,
      onWebViewPlatformCreated:
          (WebViewPlatformController? webViewPlatformController) {
        final WebViewController controller = WebViewController(
          widget,
          webViewPlatformController!,
          _javascriptChannelRegistry,
        );
        _controller.complete(controller);

        if (widget.onWebViewCreated != null) {
          widget.onWebViewCreated!(controller);
        }
      },
      webViewPlatformCallbacksHandler: _platformCallbacksHandler,
      creationParams: CreationParams(
        initialUrl: widget.initialUrl,
        webSettings: _webSettingsFromWidget(widget),
        javascriptChannelNames:
            _javascriptChannelRegistry.channels.keys.toSet(),
        autoMediaPlaybackPolicy: widget.initialMediaPlaybackPolicy,
        userAgent: widget.userAgent,
        backgroundColor: widget.backgroundColor,
        cookies: widget.initialCookies,
      ),
      javascriptChannelRegistry: _javascriptChannelRegistry,
    );
  }
}

class _PlatformCallbacksHandler implements WebViewPlatformCallbacksHandler {
  _PlatformCallbacksHandler(this._webView);

  final WebView _webView;

  @override
  FutureOr<bool> onNavigationRequest({
    required String url,
    required bool isForMainFrame,
  }) async {
    if (_webView.navigationDelegate != null) {
      final NavigationDecision decision = await _webView.navigationDelegate!(
        NavigationRequest(url: url, isForMainFrame: isForMainFrame),
      );
      return decision == NavigationDecision.navigate;
    }
    return true;
  }

  @override
  void onPageStarted(String url) {
    if (_webView.onPageStarted != null) {
      _webView.onPageStarted!(url);
    }
  }

  @override
  void onPageFinished(String url) {
    if (_webView.onPageFinished != null) {
      _webView.onPageFinished!(url);
    }
  }

  @override
  void onProgress(int progress) {
    if (_webView.onProgress != null) {
      _webView.onProgress!(progress);
    }
  }

  @override
  void onWebResourceError(WebResourceError error) {
    if (_webView.onWebResourceError != null) {
      _webView.onWebResourceError!(error);
    }
  }
}

/// Controls a [WebView].
///
/// A [WebViewController] instance can be obtained by setting the [WebView.onWebViewCreated]
/// callback for a [WebView] widget.
class WebViewController {
  /// Creates a [WebViewController] which can be used to control the provided
  /// [WebView] widget.
  WebViewController(
    this._widget,
    this._webViewPlatformController,
    this._javascriptChannelRegistry,
  ) {
    _settings = _webSettingsFromWidget(_widget);
  }

  final JavascriptChannelRegistry _javascriptChannelRegistry;

  final WebViewPlatformController _webViewPlatformController;

  late WebSettings _settings;

  WebView _widget;

  /// Loads the file located on the specified [absoluteFilePath].
  Future<void> loadFile(String absoluteFilePath) {
    return _webViewPlatformController.loadFile(absoluteFilePath);
  }

  /// Loads the Flutter asset specified in the pubspec.yaml file.
  Future<void> loadFlutterAsset(String key) {
    return _webViewPlatformController.loadFlutterAsset(key);
  }

  /// Loads the supplied HTML string.
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    return _webViewPlatformController.loadHtmlString(html, baseUrl: baseUrl);
  }

  /// Loads the specified URL.
  Future<void> loadUrl(String url, {Map<String, String>? headers}) async {
    _validateUrlString(url);
    return _webViewPlatformController.loadUrl(url, headers);
  }

  /// Loads a page by making the specified request.
  Future<void> loadRequest(WebViewRequest request) async {
    return _webViewPlatformController.loadRequest(request);
  }

  /// Accessor to the current URL that the WebView is displaying.
  Future<String?> currentUrl() {
    return _webViewPlatformController.currentUrl();
  }

  /// Checks whether there's a back history item.
  Future<bool> canGoBack() {
    return _webViewPlatformController.canGoBack();
  }

  /// Checks whether there's a forward history item.
  Future<bool> canGoForward() {
    return _webViewPlatformController.canGoForward();
  }

  /// Goes back in the history of this WebView.
  Future<void> goBack() {
    return _webViewPlatformController.goBack();
  }

  /// Goes forward in the history of this WebView.
  Future<void> goForward() {
    return _webViewPlatformController.goForward();
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return _webViewPlatformController.reload();
  }

  /// Clears all caches used by the [WebView].
  Future<void> clearCache() async {
    await _webViewPlatformController.clearCache();
    return reload();
  }

  /// Update the widget managed by the [WebViewController].
  Future<void> updateWidget(WebView widget) async {
    _widget = widget;
    await _updateSettings(_webSettingsFromWidget(widget));
    await _updateJavascriptChannels(
        _javascriptChannelRegistry.channels.values.toSet());
  }

  Future<void> _updateSettings(WebSettings newSettings) {
    final WebSettings update =
        _clearUnchangedWebSettings(_settings, newSettings);
    _settings = newSettings;
    return _webViewPlatformController.updateSettings(update);
  }

  Future<void> _updateJavascriptChannels(
      Set<JavascriptChannel>? newChannels) async {
    final Set<String> currentChannels =
        _javascriptChannelRegistry.channels.keys.toSet();
    final Set<String> newChannelNames = _extractChannelNames(newChannels);
    final Set<String> channelsToAdd =
        newChannelNames.difference(currentChannels);
    final Set<String> channelsToRemove =
        currentChannels.difference(newChannelNames);
    if (channelsToRemove.isNotEmpty) {
      await _webViewPlatformController
          .removeJavascriptChannels(channelsToRemove);
    }
    if (channelsToAdd.isNotEmpty) {
      await _webViewPlatformController.addJavascriptChannels(channelsToAdd);
    }
    _javascriptChannelRegistry.updateJavascriptChannelsFromSet(newChannels);
  }

  @visibleForTesting
  // ignore: public_member_api_docs
  Future<String> evaluateJavascript(String javascriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.'));
    }
    return _webViewPlatformController.evaluateJavascript(javascriptString);
  }

  /// Runs the given JavaScript in the context of the current page.
  Future<void> runJavascript(String javaScriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<void>.error(FlutterError(
          'Javascript mode must be enabled/unrestricted when calling runJavascript.'));
    }
    return _webViewPlatformController.runJavascript(javaScriptString);
  }

  /// Runs the given JavaScript in the context of the current page, and returns the result.
  Future<String> runJavascriptReturningResult(String javaScriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'Javascript mode must be enabled/unrestricted when calling runJavascriptReturningResult.'));
    }
    return _webViewPlatformController
        .runJavascriptReturningResult(javaScriptString);
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() {
    return _webViewPlatformController.getTitle();
  }

  /// Sets the WebView's content scroll position.
  Future<void> scrollTo(int x, int y) {
    return _webViewPlatformController.scrollTo(x, y);
  }

  /// Move the scrolled position of this view.
  Future<void> scrollBy(int x, int y) {
    return _webViewPlatformController.scrollBy(x, y);
  }

  /// Return the horizontal scroll position, in WebView pixels, of this view.
  Future<int> getScrollX() {
    return _webViewPlatformController.getScrollX();
  }

  /// Return the vertical scroll position, in WebView pixels, of this view.
  Future<int> getScrollY() {
    return _webViewPlatformController.getScrollY();
  }

  // This method assumes that no fields in `currentValue` are null.
  WebSettings _clearUnchangedWebSettings(
      WebSettings currentValue, WebSettings newValue) {
    assert(currentValue.javascriptMode != null);
    assert(currentValue.hasNavigationDelegate != null);
    assert(currentValue.hasProgressTracking != null);
    assert(currentValue.debuggingEnabled != null);
    assert(newValue.javascriptMode != null);
    assert(newValue.hasNavigationDelegate != null);
    assert(newValue.debuggingEnabled != null);
    assert(newValue.zoomEnabled != null);

    JavascriptMode? javascriptMode;
    bool? hasNavigationDelegate;
    bool? hasProgressTracking;
    bool? debuggingEnabled;
    WebSetting<String?> userAgent = const WebSetting<String?>.absent();
    bool? zoomEnabled;
    if (currentValue.javascriptMode != newValue.javascriptMode) {
      javascriptMode = newValue.javascriptMode;
    }
    if (currentValue.hasNavigationDelegate != newValue.hasNavigationDelegate) {
      hasNavigationDelegate = newValue.hasNavigationDelegate;
    }
    if (currentValue.hasProgressTracking != newValue.hasProgressTracking) {
      hasProgressTracking = newValue.hasProgressTracking;
    }
    if (currentValue.debuggingEnabled != newValue.debuggingEnabled) {
      debuggingEnabled = newValue.debuggingEnabled;
    }
    if (currentValue.userAgent != newValue.userAgent) {
      userAgent = newValue.userAgent;
    }
    if (currentValue.zoomEnabled != newValue.zoomEnabled) {
      zoomEnabled = newValue.zoomEnabled;
    }

    return WebSettings(
      javascriptMode: javascriptMode,
      hasNavigationDelegate: hasNavigationDelegate,
      hasProgressTracking: hasProgressTracking,
      debuggingEnabled: debuggingEnabled,
      userAgent: userAgent,
      zoomEnabled: zoomEnabled,
    );
  }

  Set<String> _extractChannelNames(Set<JavascriptChannel>? channels) {
    final Set<String> channelNames = channels == null
        ? <String>{}
        : channels.map((JavascriptChannel channel) => channel.name).toSet();
    return channelNames;
  }

  // Throws an ArgumentError if `url` is not a valid URL string.
  void _validateUrlString(String url) {
    try {
      final Uri uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        throw ArgumentError('Missing scheme in URL string: "$url"');
      }
    } on FormatException catch (e) {
      throw ArgumentError(e);
    }
  }
}

WebSettings _webSettingsFromWidget(WebView widget) {
  return WebSettings(
    javascriptMode: widget.javascriptMode,
    hasNavigationDelegate: widget.navigationDelegate != null,
    hasProgressTracking: widget.onProgress != null,
    debuggingEnabled: widget.debuggingEnabled,
    gestureNavigationEnabled: widget.gestureNavigationEnabled,
    allowsInlineMediaPlayback: widget.allowsInlineMediaPlayback,
    userAgent: WebSetting<String?>.of(widget.userAgent),
    zoomEnabled: widget.zoomEnabled,
  );
}

/// App-facing cookie manager that exposes the correct platform implementation.
class WebViewCookieManager extends WebViewCookieManagerPlatform {
  WebViewCookieManager._();

  /// Returns an instance of the cookie manager for the current platform.
  static WebViewCookieManagerPlatform get instance {
    if (WebViewCookieManagerPlatform.instance == null) {
      if (Platform.isAndroid || defaultTargetPlatform == TargetPlatform.ohos) {
        WebViewCookieManagerPlatform.instance = WebViewOhosCookieManager();
      } else {
        throw AssertionError(
            'This platform is currently unsupported for webview_flutter_ohos.');
      }
    }
    return WebViewCookieManagerPlatform.instance!;
  }
}
