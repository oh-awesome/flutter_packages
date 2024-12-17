import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'camera_video_io_ohos.dart';

/// 定义插件抽象
abstract class QrcodeFlutterPlatform extends PlatformInterface {
  /// Constructs a QrcodeFlutterPlatform.
  QrcodeFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static QrcodeFlutterPlatform _instance = QRCodeFlutterIO();

  /// The default instance of [QrcodeFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelQrcodeFlutter].
  static QrcodeFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QrcodeFlutterPlatform] when
  /// they register themselves.
  static set instance(QrcodeFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Build camera widget
  Widget buildWidget();
}
