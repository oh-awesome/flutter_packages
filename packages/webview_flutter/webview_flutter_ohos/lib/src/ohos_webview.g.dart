// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

/// Mode of how to select files for a file chooser.
enum FileChooserMode {
  /// Open single file and requires that the file exists before allowing the
  /// user to pick it.
  open,

  /// Similar to [open] but allows multiple files to be selected.
  openMultiple,

  /// Allows picking a nonexistent file and saving it.
  save,
}

/// Indicates the type of message logged to the console.
///
/// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel.
enum ConsoleMessageLevel {
  /// Indicates a message is logged for debugging.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#DEBUG.
  debug,

  /// Indicates a message is provided as an error.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#ERROR.
  error,

  /// Indicates a message is provided as a basic log message.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#LOG.
  log,

  /// Indicates a message is provided as a tip.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#TIP.
  tip,

  /// Indicates a message is provided as a warning.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#WARNING.
  warning,

  /// Indicates a message with an unknown level.
  ///
  /// This does not represent an actual value provided by the platform and only
  /// indicates a value was provided that isn't currently supported.
  unknown,
}

class WebResourceRequestData {
  WebResourceRequestData({
    required this.url,
    required this.isForMainFrame,
    this.isRedirect,
    required this.hasGesture,
    required this.method,
    required this.requestHeaders,
  });

  String url;

  bool isForMainFrame;

  bool? isRedirect;

  bool hasGesture;

  String method;

  Map<String?, String?> requestHeaders;

  Object encode() {
    return <Object?>[
      url,
      isForMainFrame,
      isRedirect,
      hasGesture,
      method,
      requestHeaders,
    ];
  }

  static WebResourceRequestData decode(Object result) {
    result as List<Object?>;
    return WebResourceRequestData(
      url: result[0]! as String,
      isForMainFrame: result[1]! as bool,
      isRedirect: result[2] as bool?,
      hasGesture: result[3]! as bool,
      method: result[4]! as String,
      requestHeaders:
          (result[5] as Map<Object?, Object?>?)!.cast<String?, String?>(),
    );
  }
}

class WebResourceErrorData {
  WebResourceErrorData({
    required this.errorCode,
    required this.description,
  });

  int errorCode;

  String description;

  Object encode() {
    return <Object?>[
      errorCode,
      description,
    ];
  }

  static WebResourceErrorData decode(Object result) {
    result as List<Object?>;
    return WebResourceErrorData(
      errorCode: result[0]! as int,
      description: result[1]! as String,
    );
  }
}

class WebViewPoint {
  WebViewPoint({
    required this.x,
    required this.y,
  });

  int x;

  int y;

  Object encode() {
    return <Object?>[
      x,
      y,
    ];
  }

  static WebViewPoint decode(Object result) {
    result as List<Object?>;
    return WebViewPoint(
      x: result[0]! as int,
      y: result[1]! as int,
    );
  }
}

/// Represents a JavaScript console message from WebCore.
///
/// See https://developer.android.com/reference/android/webkit/ConsoleMessage
class ConsoleMessage {
  ConsoleMessage({
    required this.lineNumber,
    required this.message,
    required this.level,
    required this.sourceId,
  });

  int lineNumber;

  String message;

  ConsoleMessageLevel level;

  String sourceId;

  Object encode() {
    return <Object?>[
      lineNumber,
      message,
      level.index,
      sourceId,
    ];
  }

  static ConsoleMessage decode(Object result) {
    result as List<Object?>;
    return ConsoleMessage(
      lineNumber: result[0]! as int,
      message: result[1]! as String,
      level: ConsoleMessageLevel.values[result[2]! as int],
      sourceId: result[3]! as String,
    );
  }
}

/// Host API for managing the native `InstanceManager`.
class InstanceManagerHostApi {
  /// Constructor for [InstanceManagerHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  InstanceManagerHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  /// Clear the native `InstanceManager`.
  ///
  /// This is typically only used after a hot restart.
  Future<void> clear() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.InstanceManagerHostApi.clear',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

/// Handles methods calls to the native TS Object class.
///
/// Also handles calls to remove the reference to an instance with `dispose`.
class OhosObjectHostApi {
  /// Constructor for [OhosObjectHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  OhosObjectHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<void> dispose(int arg_identifier) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.OhosObjectHostApi.dispose',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_identifier]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

/// Handles callbacks methods for the native TS Object class.
abstract class OhosObjectFlutterApi {
  static const MessageCodec<Object?> codec = StandardMessageCodec();

  void dispose(int identifier);

  static void setup(OhosObjectFlutterApi? api,
      {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.OhosObjectFlutterApi.dispose',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.OhosObjectFlutterApi.dispose was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_identifier = (args[0] as int?);
          assert(arg_identifier != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.OhosObjectFlutterApi.dispose was null, expected non-null int.');
          api.dispose(arg_identifier!);
          return;
        });
      }
    }
  }
}

/// Host API for `CookieManager`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
class CookieManagerHostApi {
  /// Constructor for [CookieManagerHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  CookieManagerHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  /// Handles attaching `CookieManager.instance` to a native instance.
  Future<void> attachInstance(int arg_instanceIdentifier) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.attachInstance',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceIdentifier]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// Handles Dart method `CookieManager.setCookie`.
  Future<void> setCookie(
      int arg_identifier, String arg_url, String arg_value) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.setCookie',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_identifier, arg_url, arg_value]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// Handles Dart method `CookieManager.removeAllCookies`.
  Future<bool> removeAllCookies(int arg_identifier) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.removeAllCookies',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_identifier]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  /// Handles Dart method `CookieManager.setAcceptThirdPartyCookies`.
  Future<void> setAcceptThirdPartyCookies(
      int arg_identifier, int arg_webViewIdentifier, bool arg_accept) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.CookieManagerHostApi.setAcceptThirdPartyCookies',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
            .send(<Object?>[arg_identifier, arg_webViewIdentifier, arg_accept])
        as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

class _WebViewHostApiCodec extends StandardMessageCodec {
  const _WebViewHostApiCodec();

  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is WebViewPoint) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return WebViewPoint.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class WebViewHostApi {
  /// Constructor for [WebViewHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  WebViewHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _WebViewHostApiCodec();

  Future<void> create(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.create', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> loadData(int arg_instanceId, String arg_data,
      String? arg_mimeType, String? arg_encoding) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadData',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel.send(
            <Object?>[arg_instanceId, arg_data, arg_mimeType, arg_encoding])
        as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> loadDataWithBaseUrl(
      int arg_instanceId,
      String? arg_baseUrl,
      String arg_data,
      String? arg_mimeType,
      String? arg_encoding,
      String? arg_historyUrl) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadDataWithBaseUrl',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel.send(<Object?>[
      arg_instanceId,
      arg_baseUrl,
      arg_data,
      arg_mimeType,
      arg_encoding,
      arg_historyUrl
    ]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> loadUrl(int arg_instanceId, String arg_url,
      Map<String?, String?> arg_headers) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.loadUrl', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_url, arg_headers])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> postUrl(
      int arg_instanceId, String arg_url, Uint8List arg_data) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.postUrl', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_url, arg_data]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<String?> getUrl(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getUrl', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return (replyList[0] as String?);
    }
  }

  Future<bool> canGoBack(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.canGoBack',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  Future<bool> canGoForward(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.canGoForward',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as bool?)!;
    }
  }

  Future<void> goBack(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.goBack', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> goForward(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.goForward',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> reload(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.reload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> clearCache(int arg_instanceId, bool arg_includeDiskFiles) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.clearCache',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_includeDiskFiles])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<String?> evaluateJavascript(
      int arg_instanceId, String arg_javascriptString) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.evaluateJavascript',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_javascriptString])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return (replyList[0] as String?);
    }
  }

  Future<String?> getTitle(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getTitle',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return (replyList[0] as String?);
    }
  }

  Future<void> scrollTo(int arg_instanceId, int arg_x, int arg_y) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollTo',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_x, arg_y]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> scrollBy(int arg_instanceId, int arg_x, int arg_y) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.scrollBy',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_x, arg_y]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<int> getScrollX(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollX',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as int?)!;
    }
  }

  Future<int> getScrollY(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollY',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as int?)!;
    }
  }

  Future<WebViewPoint> getScrollPosition(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.getScrollPosition',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as WebViewPoint?)!;
    }
  }

  Future<void> setWebContentsDebuggingEnabled(bool arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebContentsDebuggingEnabled',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setWebViewClient(
      int arg_instanceId, int arg_webViewClientInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebViewClient',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
            .send(<Object?>[arg_instanceId, arg_webViewClientInstanceId])
        as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> addJavaScriptChannel(
      int arg_instanceId, int arg_javaScriptChannelInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.addJavaScriptChannel',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
            .send(<Object?>[arg_instanceId, arg_javaScriptChannelInstanceId])
        as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> removeJavaScriptChannel(
      int arg_instanceId, int arg_javaScriptChannelInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.removeJavaScriptChannel',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
            .send(<Object?>[arg_instanceId, arg_javaScriptChannelInstanceId])
        as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setDownloadListener(
      int arg_instanceId, int? arg_listenerInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setDownloadListener',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_listenerInstanceId])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setWebChromeClient(
      int arg_instanceId, int? arg_clientInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewHostApi.setWebChromeClient',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_clientInstanceId])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

/// Flutter API for `WebView`.
///
/// This class may handle instantiating and adding Dart instances that are
/// attached to a native instance or receiving callback methods from an
/// overridden native class.
abstract class WebViewFlutterApi {
  static const MessageCodec<Object?> codec = StandardMessageCodec();

  /// Create a new Dart instance and add it to the `InstanceManager`.
  void create(int identifier);

  void onScrollChanged(
      int webViewInstanceId, int left, int top, int oldLeft, int oldTop);

  static void setup(WebViewFlutterApi? api,
      {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.create',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.create was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_identifier = (args[0] as int?);
          assert(arg_identifier != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.create was null, expected non-null int.');
          api.create(arg_identifier!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_webViewInstanceId = (args[0] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null, expected non-null int.');
          final int? arg_left = (args[1] as int?);
          assert(arg_left != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null, expected non-null int.');
          final int? arg_top = (args[2] as int?);
          assert(arg_top != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null, expected non-null int.');
          final int? arg_oldLeft = (args[3] as int?);
          assert(arg_oldLeft != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null, expected non-null int.');
          final int? arg_oldTop = (args[4] as int?);
          assert(arg_oldTop != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewFlutterApi.onScrollChanged was null, expected non-null int.');
          api.onScrollChanged(arg_webViewInstanceId!, arg_left!, arg_top!,
              arg_oldLeft!, arg_oldTop!);
          return;
        });
      }
    }
  }
}

class WebSettingsHostApi {
  /// Constructor for [WebSettingsHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  WebSettingsHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<void> create(int arg_instanceId, int arg_webViewInstanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.create',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId, arg_webViewInstanceId])
            as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setDomStorageEnabled(int arg_instanceId, bool arg_flag) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setDomStorageEnabled',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_flag]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setJavaScriptCanOpenWindowsAutomatically(
      int arg_instanceId, bool arg_flag) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setJavaScriptCanOpenWindowsAutomatically',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_flag]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setSupportMultipleWindows(
      int arg_instanceId, bool arg_support) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setSupportMultipleWindows',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_support]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setBackgroundColor(int arg_instanceId, int arg_color) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setBackgroundColor',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_color]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setJavaScriptEnabled(int arg_instanceId, bool arg_flag) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setJavaScriptEnabled',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_flag]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setUserAgentString(
      int arg_instanceId, String? arg_userAgentString) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setUserAgentString',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_userAgentString]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setMediaPlaybackRequiresUserGesture(
      int arg_instanceId, bool arg_require) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setMediaPlaybackRequiresUserGesture',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_require]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setSupportZoom(int arg_instanceId, bool arg_support) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setSupportZoom',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_support]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setLoadWithOverviewMode(
      int arg_instanceId, bool arg_overview) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setLoadWithOverviewMode',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_overview]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setUseWideViewPort(int arg_instanceId, bool arg_use) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setUseWideViewPort',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_use]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setDisplayZoomControls(
      int arg_instanceId, bool arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setDisplayZoomControls',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setBuiltInZoomControls(
      int arg_instanceId, bool arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setBuiltInZoomControls',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setAllowFileAccess(int arg_instanceId, bool arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setAllowFileAccess',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setTextZoom(int arg_instanceId, int arg_textZoom) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setTextZoom',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_textZoom]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<String> getUserAgentString(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.getUserAgentString',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as String?)!;
    }
  }

  Future<void> setAllowFullScreenRotate(int arg_instanceId, bool arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebSettingsHostApi.setAllowFullScreenRotate',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

class JavaScriptChannelHostApi {
  /// Constructor for [JavaScriptChannelHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  JavaScriptChannelHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<void> create(int arg_instanceId, String arg_channelName) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelHostApi.create',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_channelName]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

abstract class JavaScriptChannelFlutterApi {
  static const MessageCodec<Object?> codec = StandardMessageCodec();

  void postMessage(int instanceId, String message);

  static void setup(JavaScriptChannelFlutterApi? api,
      {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelFlutterApi.postMessage',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelFlutterApi.postMessage was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelFlutterApi.postMessage was null, expected non-null int.');
          final String? arg_message = (args[1] as String?);
          assert(arg_message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.JavaScriptChannelFlutterApi.postMessage was null, expected non-null String.');
          api.postMessage(arg_instanceId!, arg_message!);
          return;
        });
      }
    }
  }
}

class WebViewClientHostApi {
  /// Constructor for [WebViewClientHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  WebViewClientHostApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = StandardMessageCodec();

  Future<void> create(int arg_instanceId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.create',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_instanceId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setSynchronousReturnValueForShouldOverrideUrlLoading(
      int arg_instanceId, bool arg_value) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientHostApi.setSynchronousReturnValueForShouldOverrideUrlLoading',
        codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList = await channel
        .send(<Object?>[arg_instanceId, arg_value]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

class _WebViewClientFlutterApiCodec extends StandardMessageCodec {
  const _WebViewClientFlutterApiCodec();

  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is WebResourceErrorData) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is WebResourceRequestData) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return WebResourceErrorData.decode(readValue(buffer)!);
      case 129:
        return WebResourceRequestData.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class WebViewClientFlutterApi {
  static const MessageCodec<Object?> codec = _WebViewClientFlutterApiCodec();

  void onPageStarted(int instanceId, int webViewInstanceId, String url);

  void onPageFinished(int instanceId, int webViewInstanceId, String url);

  void onReceivedRequestError(int instanceId, int webViewInstanceId,
      WebResourceRequestData request, WebResourceErrorData error);

  void onReceivedError(int instanceId, int webViewInstanceId, int errorCode,
      String description, String failingUrl);

  void requestLoading(
      int instanceId, int webViewInstanceId, WebResourceRequestData request);

  void urlLoading(int instanceId, int webViewInstanceId, String url);

  void doUpdateVisitedHistory(
      int instanceId, int webViewInstanceId, String url, bool isReload);

  void onReceivedHttpAuthRequest(int instanceId, int webViewInstanceId,
      int httpAuthHandlerInstanceId, String host, String realm);

  static void setup(WebViewClientFlutterApi? api,
      {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageStarted',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageStarted was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageStarted was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageStarted was null, expected non-null int.');
          final String? arg_url = (args[2] as String?);
          assert(arg_url != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageStarted was null, expected non-null String.');
          api.onPageStarted(arg_instanceId!, arg_webViewInstanceId!, arg_url!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageFinished',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageFinished was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageFinished was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageFinished was null, expected non-null int.');
          final String? arg_url = (args[2] as String?);
          assert(arg_url != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onPageFinished was null, expected non-null String.');
          api.onPageFinished(arg_instanceId!, arg_webViewInstanceId!, arg_url!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError was null, expected non-null int.');
          final WebResourceRequestData? arg_request =
              (args[2] as WebResourceRequestData?);
          assert(arg_request != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError was null, expected non-null WebResourceRequestData.');
          final WebResourceErrorData? arg_error =
              (args[3] as WebResourceErrorData?);
          assert(arg_error != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedRequestError was null, expected non-null WebResourceErrorData.');
          api.onReceivedRequestError(arg_instanceId!, arg_webViewInstanceId!,
              arg_request!, arg_error!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null, expected non-null int.');
          final int? arg_errorCode = (args[2] as int?);
          assert(arg_errorCode != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null, expected non-null int.');
          final String? arg_description = (args[3] as String?);
          assert(arg_description != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null, expected non-null String.');
          final String? arg_failingUrl = (args[4] as String?);
          assert(arg_failingUrl != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedError was null, expected non-null String.');
          api.onReceivedError(arg_instanceId!, arg_webViewInstanceId!,
              arg_errorCode!, arg_description!, arg_failingUrl!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.requestLoading',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.requestLoading was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.requestLoading was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.requestLoading was null, expected non-null int.');
          final WebResourceRequestData? arg_request =
              (args[2] as WebResourceRequestData?);
          assert(arg_request != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.requestLoading was null, expected non-null WebResourceRequestData.');
          api.requestLoading(
              arg_instanceId!, arg_webViewInstanceId!, arg_request!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.urlLoading',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.urlLoading was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.urlLoading was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.urlLoading was null, expected non-null int.');
          final String? arg_url = (args[2] as String?);
          assert(arg_url != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.urlLoading was null, expected non-null String.');
          api.urlLoading(arg_instanceId!, arg_webViewInstanceId!, arg_url!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory was null, expected non-null int.');
          final String? arg_url = (args[2] as String?);
          assert(arg_url != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory was null, expected non-null String.');
          final bool? arg_isReload = (args[3] as bool?);
          assert(arg_isReload != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.doUpdateVisitedHistory was null, expected non-null bool.');
          api.doUpdateVisitedHistory(
              arg_instanceId!, arg_webViewInstanceId!, arg_url!, arg_isReload!);
          return;
        });
      }
    }
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest',
          codec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_instanceId = (args[0] as int?);
          assert(arg_instanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null, expected non-null int.');
          final int? arg_webViewInstanceId = (args[1] as int?);
          assert(arg_webViewInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null, expected non-null int.');
          final int? arg_httpAuthHandlerInstanceId = (args[2] as int?);
          assert(arg_httpAuthHandlerInstanceId != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null, expected non-null int.');
          final String? arg_host = (args[3] as String?);
          assert(arg_host != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null, expected non-null String.');
          final String? arg_realm = (args[4] as String?);
          assert(arg_realm != null,
              'Argument for dev.flutter.pigeon.webview_flutter_ohos.WebViewClientFlutterApi.onReceivedHttpAuthRequest was null, expected non-null String.');
          api.onReceivedHttpAuthRequest(arg_instanceId!, arg_webViewInstanceId!,
              arg_httpAuthHandlerInstanceId!, arg_host!, arg_realm!);
          return;
        });
      }
    }
  }
}
