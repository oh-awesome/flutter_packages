import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Singleton.dart';
import 'camera_flutter_platform_interface_ohos.dart';

class QRCodeFlutterIO extends QrcodeFlutterPlatform {
  MethodChannel? _methodChannel;

  void _onPlatformViewCreated(int id) {
    _methodChannel = MethodChannel('plugins/qr_capture/method_$id');
    _methodChannel?.setMethodCallHandler((MethodCall call) async {});
  }

  @override
  Widget buildWidget() => _QrCodeView(
        qrCodeFlutterIO: this,
        url: '',
      );
}

class _QrCodeView extends StatefulWidget {
  final String url;
  final QRCodeFlutterIO qrCodeFlutterIO;

  const _QrCodeView(
      {Key? key, required this.qrCodeFlutterIO, required this.url})
      : super(key: key);

  set urlId(int urlId) {}

  @override
  State<_QrCodeView> createState() => __QrCodeViewState();
}

class __QrCodeViewState extends State<_QrCodeView> {
  @override
  Widget build(BuildContext context) {
    return OhosView(
        key: ValueKey(Singleton.getInstance().getData()),
        viewType: 'plugins/qr_capture_view',
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          widget.qrCodeFlutterIO._onPlatformViewCreated(id);
        });
  }
}
