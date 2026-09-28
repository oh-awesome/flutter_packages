// Copyright (c) 2026 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on platform_view_player.dart originally written by
// Copyright 2013 The Flutter Authors.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Factory name registered by the OHOS [VideoPlayerPlugin].
const String kVideoPlayerOhosViewType = 'plugins.flutter.io/video_player_ohos';

/// Displays a video by embedding an XComponent surface through HCPP.
///
/// [IgnorePointer] lets Flutter overlays (play button, slider) win hit testing.
/// The native surface does not need to own gestures.
class PlatformViewPlayer extends StatelessWidget {
  /// Creates a platform-view video surface.
  const PlatformViewPlayer({
    super.key,
    required this.playerId,
    required this.source,
    this.objectFit = BoxFit.contain,
    this.looping = false,
    this.speed = 1.0,
  });

  /// Native player handle returned by `create`.
  final int playerId;

  /// Data source shown to the native factory (uri, asset, or fd).
  final String source;

  /// Initial [BoxFit] forwarded in PlatformView creation params.
  final BoxFit objectFit;

  /// Initial looping flag forwarded in PlatformView creation params.
  final bool looping;

  /// Initial playback speed forwarded in PlatformView creation params.
  final double speed;

  /// Arguments decoded by [PlatformVideoViewFactory] when the HCPP hole is created.
  Map<String, Object> get creationParams => <String, Object>{
    'playerId': playerId,
    'source': source,
    'objectFit': objectFit.name,
    'looping': looping,
    'speed': speed,
  };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: PlatformViewLink(
        key: ValueKey<int>(playerId),
        viewType: kVideoPlayerOhosViewType,
        surfaceFactory: (
          BuildContext context,
          PlatformViewController controller,
        ) {
          return OhosViewSurface(
            controller: controller as OhosViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initExpensiveOhosView(
              id: params.id,
              viewType: kVideoPlayerOhosViewType,
              layoutDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      ),
    );
  }
}
