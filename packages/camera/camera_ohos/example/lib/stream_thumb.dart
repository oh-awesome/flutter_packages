// Example overlay for the camera preview. Samples one frame from the image
// stream every 10 seconds, converts the NV21 buffer to RGBA (honoring the
// reported row stride) and renders it so the streamed data can be checked.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'camera_controller.dart';

/// A small overlay that samples the latest frame from the camera image stream
/// every 10 seconds, converts the NV21 buffer to RGBA in Dart (honoring the
/// reported row stride) and renders it, proving the streamed data is usable.
class StreamThumb extends StatefulWidget {
  const StreamThumb({super.key, required this.controller, required this.cameraId});

  final CameraController controller;

  /// Snapshot of the controller's cameraId at widget construction time.
  /// The controller is rebuilt in place on camera switches (same instance,
  /// new cameraId), so comparing live controller.cameraId in
  /// didUpdateWidget would always compare the current value against itself.
  final int cameraId;

  @override
  State<StreamThumb> createState() => _StreamThumbState();
}

class _StreamThumbState extends State<StreamThumb> {
  StreamSubscription<CameraImageData>? _sub;
  Timer? _timer;
  CameraImageData? _latest;
  ui.Image? _thumb;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_subscribe());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _grab());
  }

  Future<void> _subscribe() async {
    // The platform layer tears the old stream down asynchronously
    // (onCancel -> native stopImageStream and a shared frame controller);
    // awaiting the cancel keeps the new startImageStream strictly after the
    // old teardown, otherwise the new stream can be killed by the stale
    // cleanup when switching cameras.
    await _sub?.cancel();
    // cancel yields to the event loop; the widget may already be removed
    // (camera page popped while a camera switch was in flight).
    if (!mounted) {
      return;
    }
    _sub = CameraPlatform.instance
        .onStreamedFrameAvailable(widget.cameraId)
        .listen((CameraImageData frame) {
      _latest = frame;
      // (keep only the reference; heavy work happens on the 10s tick)
    }, onError: (Object e) {
      debugPrint('StreamThumb stream error: $e');
    });
  }

  Future<void> _grab() async {
    final CameraImageData? frame = _latest;
    if (!mounted || frame == null || frame.planes.isEmpty) {
      return;
    }
    final ui.Image? decoded = await _decodeNv21(frame);
    // Decode spans several awaits; the widget may have been removed
    // (camera switch or controller dispose) before this resumes.
    if (!mounted) {
      decoded?.dispose();
      return;
    }
    if (decoded != null) {
      setState(() {
        _thumb?.dispose();
        _thumb = decoded;
        _count++;
      });
      debugPrint('StreamThumb: decoded frame #$_count');
    }
    _latest = null;
  }

  /// NV21 (single buffer, VU byte order) -> RGBA8888 [ui.Image], sampling the
  /// Y plane row by row with the reported stride and the interleaved VU plane
  /// from its start offset (yStride * height).
  Future<ui.Image?> _decodeNv21(CameraImageData frame) async {
    final CameraImagePlane plane = frame.planes.first;
    final Uint8List bytes = plane.bytes;
    final int width = frame.width;
    final int height = frame.height;
    final int yStride = plane.bytesPerRow;
    final int ySize = yStride * height;
    // UV rows use the same stride as Y, including alignment padding.
    final int minLen = ySize + yStride * (height >> 1);
    if (bytes.length < minLen) {
      debugPrint(
          'StreamThumb: frame too short len=${bytes.length} need=$minLen');
      return null;
    }
    // Pixel conversion is O(width * height). Run it off the UI isolate;
    // dart:ui image creation stays on this isolate.
    final Uint8List rgba = await compute(
      _nv21ToRgba,
      _Nv21Frame(bytes, width, height, yStride),
    );
    return _rgbaToImage(rgba, width, height);
  }

  Future<ui.Image?> _rgbaToImage(
      Uint8List rgba, int width, int height) async {
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(rgba);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      codec = await descriptor.instantiateCodec();
      final ui.FrameInfo info = await codec.getNextFrame();
      return info.image;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant StreamThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraId != widget.cameraId) {
      unawaited(_subscribe());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _thumb?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: Colors.white70, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: _thumb == null
          ? const Center(
              child: Text(
                'waiting\nstream...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: RawImage(
                      image: _thumb,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  '#$_count',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
    );
  }
}

/// Arguments for [_nv21ToRgba]. Sent by value into a worker isolate.
class _Nv21Frame {
  const _Nv21Frame(this.bytes, this.width, this.height, this.yStride);

  final Uint8List bytes;
  final int width;
  final int height;
  final int yStride;
}

/// NV21 (VU byte order) -> RGBA8888. Must stay free of dart:ui so [compute]
/// can run it off the UI isolate.
Uint8List _nv21ToRgba(_Nv21Frame frame) {
  final Uint8List bytes = frame.bytes;
  final int width = frame.width;
  final int height = frame.height;
  final int yStride = frame.yStride;
  final int ySize = yStride * height;
  final Uint8List rgba = Uint8List(width * height * 4);
  int o = 0;
  for (int row = 0; row < height; row++) {
    final int yRow = row * yStride;
    final int uvRow = ySize + (row >> 1) * yStride;
    for (int col = 0; col < width; col++) {
      final int y = bytes[yRow + col];
      final int uvIndex = uvRow + (col >> 1) * 2;
      final int v = bytes[uvIndex] - 128; // NV21: V comes first
      final int u = bytes[uvIndex + 1] - 128;
      final int r = y + (1402 * v) ~/ 1000;
      final int g =
          y - (344136 * u) ~/ 1000000 - (714136 * v) ~/ 1000000;
      final int b = y + (1772 * u) ~/ 1000;
      rgba[o++] = r.clamp(0, 255);
      rgba[o++] = g.clamp(0, 255);
      rgba[o++] = b.clamp(0, 255);
      rgba[o++] = 255;
    }
  }
  return rgba;
}
