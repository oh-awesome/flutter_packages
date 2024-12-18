import 'package:flutter/widgets.dart';
import 'camera_flutter_platform_interface_ohos.dart';

class QRCaptureController {
  final QrcodeFlutterPlatform _platform = QrcodeFlutterPlatform.instance;
  QRCaptureController();
  Widget _buildWidget() {
    return _platform.buildWidget();
  }
}

/// 使用Platform View展示相机，可在Flutter View中自定义相机显示位置
/// Camera view
class QRCaptureView extends StatelessWidget {
  /// 控制器
  final QRCaptureController controller;
  /// key for Widget
  /// controller 相机控制器
  const QRCaptureView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return controller._buildWidget();
  }
}
