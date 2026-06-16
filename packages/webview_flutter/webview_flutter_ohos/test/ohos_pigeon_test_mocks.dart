// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_ohos/src/ohos_webview.g.dart' as pigeon;

/// Records platform channel method calls for verification in tests.
class PlatformChannelCallRecord {
  final String channelName;
  final List<dynamic> arguments;
  final DateTime timestamp;

  PlatformChannelCallRecord({
    required this.channelName,
    required this.arguments,
    required this.timestamp,
  });

  @override
  String toString() => 'PlatformChannelCallRecord($channelName, args: $arguments)';
}

/// Helper class to mock Pigeon platform channels for OHOS tests.
///
/// This class sets up mock message handlers for all the Pigeon API channels
/// used by the OHOS webview implementation, allowing tests to run without
/// actual platform communication.
///
/// It also records all platform channel calls, enabling tests to verify
/// that the correct parameters were sent to the platform.
class OhosPigeonTestMocks {
  /// All recorded platform channel calls.
  static final List<PlatformChannelCallRecord> _callRecords = [];

  /// Returns all recorded calls. Call `clearRecords()` before each test.
  static List<PlatformChannelCallRecord> get callRecords => _callRecords;

  /// Clears all recorded calls. Should be called in setUp or beforeEach.
  static void clearRecords() {
    _callRecords.clear();
  }

  /// Returns calls for a specific channel.
  static List<PlatformChannelCallRecord> getCallsForChannel(String channelName) {
    return _callRecords.where((r) => r.channelName == channelName).toList();
  }

  /// Returns the last call for a specific channel, or null if no calls.
  static PlatformChannelCallRecord? getLastCallForChannel(String channelName) {
    final calls = getCallsForChannel(channelName);
    return calls.isEmpty ? null : calls.last;
  }

  /// Verifies that a channel was called with specific arguments.
  static bool wasChannelCalledWith(String channelName, List<dynamic> expectedArgs) {
    final calls = getCallsForChannel(channelName);
    return calls.any((call) => _argsMatch(call.arguments, expectedArgs));
  }

  static bool _argsMatch(List<dynamic> actual, List<dynamic> expected) {
    if (actual.length != expected.length) return false;
    for (int i = 0; i < actual.length; i++) {
      // Handle special matching for complex types
      if (expected[i] == any) continue; // 'any' matcher
      if (actual[i] != expected[i]) return false;
    }
    return true;
  }

  /// A matcher that matches any value.
  static const dynamic any = _AnyMatcher();

  /// Sets up mock handlers for all Pigeon Host API channels.
  static void setUpMocks() {
    final binaryMessenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // InstanceManager
    _mockChannel(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.InstanceManagerHostApi.clear');

    // OhosObject
    _mockChannel(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.OhosObjectHostApi.dispose');

    // WebView - 核心方法，需要记录参数供验证
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.create');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadData');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadDataWithBaseUrl');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadUrl');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.postUrl');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getUrl', returnValue: 'https://flutter.dev');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.canGoBack', returnValue: true);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.canGoForward', returnValue: true);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.goBack');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.goForward');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.reload');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.clearCache');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.evaluateJavascript', returnValue: 'result');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getTitle', returnValue: 'Page Title');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollTo');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollBy');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollX', returnValue: 100);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollY', returnValue: 200);
    // getScrollPosition 使用自定义 Pigeon 类型 WebViewPoint，需要使用专用 codec
    _mockGetScrollPosition(binaryMessenger, x: 100, y: 200);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebContentsDebuggingEnabled');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebViewClient');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.addJavaScriptChannel');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.removeJavaScriptChannel');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setDownloadListener');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebChromeClient');

    // WebSettings
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.create');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setDomStorageEnabled');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setJavaScriptCanOpenWindowsAutomatically');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setSupportMultipleWindows');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setBackgroundColor');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setJavaScriptEnabled');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setUserAgentString');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setMediaPlaybackRequiresUserGesture');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setSupportZoom');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setLoadWithOverviewMode');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setUseWideViewPort');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setDisplayZoomControls');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setBuiltInZoomControls');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setAllowFileAccess');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setTextZoom');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.getUserAgentString', returnValue: 'Mozilla/5.0');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setAllowFullScreenRotate');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setPaymentRequestEnabled');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setMixedContentMode');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setOverScrollMode');

    // WebViewFeature
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewFeatureHostApi.isFeatureSupported', returnValue: false);

    // JavaScriptChannel
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelHostApi.create');

    // WebViewClient
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.create');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.setSynchronousReturnValueForShouldOverrideUrlLoading');

    // DownloadListener
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.DownloadListenerHostApi.create');

    // WebChromeClient
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.create');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.setSynchronousReturnValueForOnShowFileChooser');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.setSynchronousReturnValueForOnConsoleMessage');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.setSynchronousReturnValueForOnJsAlert');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.setSynchronousReturnValueForOnJsConfirm');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.setSynchronousReturnValueForOnJsPrompt');

    // FlutterAssetManager - 需要动态响应以支持资产存在性检查
    _setupFlutterAssetManagerMocks(binaryMessenger);

    // WebStorage
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebStorageHostApi.create');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.WebStorageHostApi.deleteAllData');

    // PermissionRequest
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.PermissionRequestHostApi.grant');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.PermissionRequestHostApi.deny');

    // CustomViewCallback
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.CustomViewCallbackHostApi.onCustomViewHidden');

    // GeolocationPermissionsCallback
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.GeolocationPermissionsCallbackHostApi.invoke');

    // HttpAuthHandler
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.HttpAuthHandlerHostApi.useHttpAuthUsernamePassword', returnValue: false);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.HttpAuthHandlerHostApi.cancel');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.HttpAuthHandlerHostApi.proceed');

    // CookieManager
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.attachInstance');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.setCookie');
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.removeAllCookies', returnValue: true);
    _mockChannelWithRecording(binaryMessenger, 'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.setAcceptThirdPartyCookies');
  }

  /// Clears all mock handlers.
  static void tearDownMocks() {
    final binaryMessenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final channels = <String>[
      'dev.flutter.pigeon.webview_flutter_ohos.InstanceManagerHostApi.clear',
      'dev.flutter.pigeon.webview_flutter_ohos.OhosObjectHostApi.dispose',
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.DownloadListenerHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.WebChromeClientHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.WebStorageHostApi.create',
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadUrl',
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadData',
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadDataWithBaseUrl',
    ];

    for (final channel in channels) {
      binaryMessenger.setMockMessageHandler(channel, null);
    }

    _callRecords.clear();
  }

  static void _mockChannel(
    BinaryMessenger binaryMessenger,
    String channelName,
    {dynamic returnValue}
  ) {
    binaryMessenger.setMockMessageHandler(
      channelName,
      (ByteData? message) async {
        return _encodeSuccessResponse(returnValue);
      },
    );
  }

  static void _setupFlutterAssetManagerMocks(BinaryMessenger binaryMessenger) {
    // 存在的资产列表
    const existingAssets = ['test.html', 'index.html', 'app.js'];

    // getAssetFilePathByName - 根据输入返回对应的路径
    binaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.webview_flutter_ohos.FlutterAssetManagerHostApi.getAssetFilePathByName',
      (ByteData? message) async {
        if (message != null) {
          final args = _decodeMessage(message);
          final assetName = args.isNotEmpty ? args[0] as String? : '';
          _callRecords.add(PlatformChannelCallRecord(
            channelName: 'dev.flutter.pigeon.webview_flutter_ohos.FlutterAssetManagerHostApi.getAssetFilePathByName',
            arguments: args,
            timestamp: DateTime.now(),
          ));
          // 返回基于资产名称的路径
          final path = 'assets/$assetName';
          return _encodeSuccessResponse(path);
        }
        return _encodeSuccessResponse('assets/default.html');
      },
    );

    // list - 返回存在的资产列表
    binaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.webview_flutter_ohos.FlutterAssetManagerHostApi.list',
      (ByteData? message) async {
        if (message != null) {
          final args = _decodeMessage(message);
          _callRecords.add(PlatformChannelCallRecord(
            channelName: 'dev.flutter.pigeon.webview_flutter_ohos.FlutterAssetManagerHostApi.list',
            arguments: args,
            timestamp: DateTime.now(),
          ));
        }
        return _encodeSuccessResponse(existingAssets);
      },
    );
  }

  static void _mockGetScrollPosition(
    BinaryMessenger binaryMessenger,
    {required int x, required int y}
  ) {
    // 使用 OHOS 专用的 WebViewHostApi codec 来正确编码 WebViewPoint
    const codec = pigeon.WebViewHostApi.codec;
    binaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollPosition',
      (ByteData? message) async {
        if (message != null) {
          final args = _decodeMessage(message);
          _callRecords.add(PlatformChannelCallRecord(
            channelName: 'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollPosition',
            arguments: args,
            timestamp: DateTime.now(),
          ));
        }
        // 创建 WebViewPoint 并使用正确的 codec 编码
        // _WebViewHostApiCodec 继承 StandardMessageCodec，需要强制类型转换
        final webViewPoint = pigeon.WebViewPoint(x: x, y: y);
        final writeBuffer = WriteBuffer();
        (codec as StandardMessageCodec).writeValue(writeBuffer, <Object?>[webViewPoint]);
        return writeBuffer.done();
      },
    );
  }

  static void _mockChannelWithRecording(
    BinaryMessenger binaryMessenger,
    String channelName,
    {dynamic returnValue}
  ) {
    binaryMessenger.setMockMessageHandler(
      channelName,
      (ByteData? message) async {
        // 解码消息并记录调用
        if (message != null) {
          final args = _decodeMessage(message);
          _callRecords.add(PlatformChannelCallRecord(
            channelName: channelName,
            arguments: args,
            timestamp: DateTime.now(),
          ));
        }
        return _encodeSuccessResponse(returnValue);
      },
    );
  }

  /// Decodes a Pigeon message to extract arguments.
  static List<dynamic> _decodeMessage(ByteData message) {
    try {
      final codec = StandardMessageCodec();
      final decoded = codec.readValue(ReadBuffer(message));
      if (decoded is List) {
        return decoded;
      }
      return [decoded];
    } catch (e) {
      // 如果解码失败，返回空列表
      return [];
    }
  }

  /// Encodes a successful response for Pigeon APIs.
  static ByteData? _encodeSuccessResponse(dynamic value) {
    final codec = StandardMessageCodec();
    final writeBuffer = WriteBuffer();
    codec.writeValue(writeBuffer, <Object?>[value]);
    return writeBuffer.done();
  }
}

/// Marker class for matching any value in argument verification.
class _AnyMatcher {
  const _AnyMatcher();
}