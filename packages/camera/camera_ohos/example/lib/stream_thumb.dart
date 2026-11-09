// TEMPORARY demo feature (do not commit without review): renders a frame
// sampled from the camera image stream every 10 seconds, to verify that the
// streamed NV21 data is decodable and usable.

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
    ui.Image? decoded;
    try {
      decoded = await _decodeNv21(frame);
    } catch (e, st) {
      debugPrint('StreamThumb: decode failed: $e\n$st');
      _latest = null;
      return;
    }
    // Timer.cancel does not abort an in-flight await; re-check after resume.
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
    // UV rows are addressed with the same stride as Y; require a full stride
    // for each chroma row so padding cannot pass the length check then OOB.
    final int minLen = ySize + ((height + 1) >> 1) * yStride;
    if (bytes.length < minLen) {
      debugPrint(
          'StreamThumb: frame too short len=${bytes.length} need=$minLen');
      return null;
    }
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
        final int g = y - (344136 * u) ~/ 1000000 -
            (714136 * v) ~/ 1000000;
        final int b = y + (1772 * u) ~/ 1000;
        rgba[o++] = r.clamp(0, 255);
        rgba[o++] = g.clamp(0, 255);
        rgba[o++] = b.clamp(0, 255);
        rgba[o++] = 255;
      }
    }
    return _rgbaToImage(rgba, width, height);
  }

  Future<ui.Image?> _rgbaToImage(
      Uint8List rgba, int width, int height) async {
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(rgba);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo info = await codec.getNextFrame();
    final ui.Image image = info.image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return image;
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
