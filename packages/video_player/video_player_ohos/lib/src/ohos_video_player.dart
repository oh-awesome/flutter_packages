// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'messages.g.dart';
import 'platform_view_player.dart';
import 'video_player_ohos_channel.dart';

/// An OHOS implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [OhosVideoPlayerApi].
class OhosVideoPlayer extends VideoPlayerPlatform {
  OhosVideoPlayer({OhosVideoPlayerApi? pluginApi})
    : _api = pluginApi ?? OhosVideoPlayerApi();

  final OhosVideoPlayerApi _api;

  /// playerId → 出画方式。两条路径的 playerId 都由引擎全局计数器分配。
  /// 纹理路径会 registerTexture；PlatformView 只取号，不注册纹理。
  final Map<int, VideoPlayerViewState> _viewStates =
      <int, VideoPlayerViewState>{};

  // 用于在显式选择视频轨道时等待轨道切换完成，由原生侧成功切换后
  // 发送的 videoTrackChanged 事件驱动此 completer 完成。
  Completer<void>? _videoTrackSelectionCompleter;
  String? _expectedVideoTrackId;

  static void registerWith() {
    VideoPlayerPlatform.instance = OhosVideoPlayer();
  }

  @override
  Future<void> init() => _api.initialize();

  @override
  Future<void> dispose(int textureId) {
    _viewStates.remove(textureId);
    return _api.dispose(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    return _create(dataSource, viewType: VideoViewType.textureView);
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    // 透传 backBufferDurationMs（2.12.0 引入）：OHOS 侧暂不使用该字段，
    // 仅读取以确保与新版 VideoCreationOptions 序列化保持一致。
    final int? backBufferDurationMs =
        options.videoPlayerOptions?.backBufferDurationMs;
    return _create(
      options.dataSource,
      viewType: options.viewType,
      backBufferDurationMs: backBufferDurationMs,
    );
  }

  Future<int?> _create(
    DataSource dataSource, {
    required VideoViewType viewType,
    int? backBufferDurationMs,
  }) async {
    String? asset;
    String? uri;
    int? openedFd;
    final String? packageName = dataSource.package;
    final String? formatHint =
        dataSource.formatHint == null
            ? null
            : _videoFormatStringMap[dataSource.formatHint];
    final httpHeaders =
        dataSource.httpHeaders.isEmpty
            ? null
            : Map<String?, String?>.fromEntries(
              dataSource.httpHeaders.entries.map(
                (e) => MapEntry(e.key, e.value),
              ),
            );

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        break;
      case DataSourceType.network:
        uri = dataSource.uri;
        break;
      case DataSourceType.file:
        if (dataSource.uri?.startsWith('fd://') == true) {
          uri = dataSource.uri;
        } else {
          openedFd = await VideoPlayerOhosChannel.getFileFdByPath(
            dataSource.uri!,
          );
          if (openedFd < 0) {
            throw PlatformException(
              code: 'video_player_ohos',
              message: 'Failed to open file: ${dataSource.uri}',
            );
          }
          uri = 'fd://$openedFd';
        }
        break;
      default:
        uri = dataSource.uri;
    }

    final message = CreateMessage(
      httpHeaders: httpHeaders ?? <String?, String?>{},
      asset: asset,
      uri: uri,
      packageName: packageName,
      formatHint: formatHint,
      viewType: _toPlatformViewType(viewType),
      backBufferDurationMs: backBufferDurationMs,
    );

    try {
      final int playerId = await _api.create(message);
      _viewStates[playerId] =
          viewType == VideoViewType.platformView
              ? VideoPlayerPlatformViewState(source: _sourceLabel(dataSource))
              : VideoPlayerTextureViewState(textureId: playerId);
      return playerId;
    } catch (e) {
      // create 失败时播放器还没接管这个 fd（hcpp_unavailable 甚至还没构造播放器）。
      // 成功路径仍由 VideoPlayer.release() 关闭 externalFd。
      if (openedFd != null && openedFd >= 0) {
        await VideoPlayerOhosChannel.closeFileFd(openedFd);
      }
      rethrow;
    }
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    _updatePlatformViewState(
      textureId,
      (VideoPlayerPlatformViewState state) => state.copyWith(looping: looping),
    );
    return _api.setLooping(textureId, looping);
  }

  @override
  Future<void> play(int textureId) {
    return _api.play(textureId);
  }

  @override
  Future<void> pause(int textureId) {
    return _api.pause(textureId);
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return _api.setVolume(textureId, volume);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);
    _updatePlatformViewState(
      textureId,
      (VideoPlayerPlatformViewState state) => state.copyWith(speed: speed),
    );
    return _api.setPlaybackSpeed(textureId, speed);
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return _api.seekTo(textureId, position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    final int positionMs = await _api.position(textureId);
    return Duration(milliseconds: positionMs);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId).receiveBroadcastStream().map((
      dynamic event,
    ) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(
              milliseconds: (map['duration'] as num?)?.toInt() ?? 0,
            ),
            size: Size(
              (map['width'] as num?)?.toDouble() ?? 0.0,
              (map['height'] as num?)?.toDouble() ?? 0.0,
            ),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(eventType: VideoEventType.completed);
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;
          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        case 'videoTrackChanged':
          // 显式选择时等待轨道切换完成。仅当存在待完成事件且上报的
          // trackId 与等待中的一致时才完成，避免早期/无关的事件误触发。
          if (_videoTrackSelectionCompleter != null &&
              !_videoTrackSelectionCompleter!.isCompleted) {
            final String? selectedTrackId = map['selectedTrackId'] as String?;
            if (selectedTrackId == _expectedVideoTrackId) {
              _videoTrackSelectionCompleter!.complete();
            }
          }
          return VideoEvent(eventType: VideoEventType.unknown);
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    return buildViewWithOptions(VideoViewOptions(playerId: textureId));
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    final VideoPlayerViewState? viewState = _viewStates[options.playerId];
    return switch (viewState) {
      VideoPlayerTextureViewState(:final int textureId) => Texture(
        textureId: textureId,
      ),
      VideoPlayerPlatformViewState(
        :final String source,
        :final BoxFit objectFit,
        :final bool looping,
        :final double speed,
      ) =>
        PlatformViewPlayer(
          playerId: options.playerId,
          source: source,
          objectFit: objectFit,
          looping: looping,
          speed: speed,
        ),
      null => Texture(textureId: options.playerId),
    };
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(mixWithOthers);
  }

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) {
    return VideoPlayerOhosChannel.setKeepScreenOn(
      playerId,
      preventsDisplaySleepDuringVideoPlayback,
    );
  }

  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int playerId) async {
    if (playerId < 0) {
      return <VideoAudioTrack>[];
    }
    final List<Object?> nativeTracks = await _api.getAudioTracks(playerId);
    return nativeTracks
        .map(
          (Object? track) => _toVideoAudioTrack(
            (track! as Map<Object?, Object?>).cast<String, Object?>(),
          ),
        )
        .where((track) => track.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> selectAudioTrack(int playerId, String trackId) async {
    if (playerId < 0) {
      return;
    }
    final (int groupIndex, int trackIndex) = _parseTrackId(trackId);
    await _api.selectAudioTrack(playerId, groupIndex, trackIndex);
  }

  @override
  bool isAudioTrackSupportAvailable() {
    return true;
  }

  @override
  Future<List<VideoTrack>> getVideoTracks(int playerId) async {
    if (playerId < 0) {
      return <VideoTrack>[];
    }
    final List<Object?> nativeTracks = await _api.getVideoTracks(playerId);
    return nativeTracks
        .map(
          (Object? track) => _toVideoTrack(
            (track! as Map<Object?, Object?>).cast<String, Object?>(),
          ),
        )
        .where((track) => track.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> selectVideoTrack(int playerId, VideoTrack? track) async {
    if (playerId < 0) {
      return;
    }
    if (track == null) {
      // 恢复自适应/自动质量。原生侧会发送 videoTrackChanged 事件，
      // 但无确定的"选中轨道"，因此不等待具体轨道，直接返回，UI 刷新由事件驱动。
      await _api.enableAutoVideoQuality(playerId);
      return;
    }

    // 显式选择：等待原生侧上报对应 trackId 的 videoTrackChanged 事件，
    // 确保 UI 上的 isSelected 与实际切换一致。
    final (int groupIndex, int trackIndex) = _parseTrackId(track.id);
    final Completer<void> completer = Completer<void>();
    final String expectedId = track.id;
    _videoTrackSelectionCompleter = completer;
    _expectedVideoTrackId = expectedId;
    try {
      await _api.selectVideoTrack(playerId, groupIndex, trackIndex);
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            'Timed out waiting for video track selection event for track '
            '"$expectedId".',
          );
        },
      );
    } finally {
      if (identical(_videoTrackSelectionCompleter, completer)) {
        _videoTrackSelectionCompleter = null;
      }
      if (_expectedVideoTrackId == expectedId) {
        _expectedVideoTrackId = null;
      }
    }
  }

  @override
  bool isVideoTrackSupportAvailable() {
    return true;
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  void _updatePlatformViewState(
    int playerId,
    VideoPlayerPlatformViewState Function(VideoPlayerPlatformViewState) update,
  ) {
    final VideoPlayerViewState? state = _viewStates[playerId];
    if (state is VideoPlayerPlatformViewState) {
      _viewStates[playerId] = update(state);
    }
  }

  static String _sourceLabel(DataSource dataSource) {
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        final String? asset = dataSource.asset;
        if (asset == null || asset.isEmpty) {
          return '';
        }
        final String? packageName = dataSource.package;
        if (packageName != null && packageName.isNotEmpty) {
          return 'packages/$packageName/$asset';
        }
        return asset;
      case DataSourceType.network:
      case DataSourceType.file:
      case DataSourceType.contentUri:
        return dataSource.uri ?? '';
    }
  }

  static PlatformVideoViewType _toPlatformViewType(VideoViewType viewType) {
    return switch (viewType) {
      VideoViewType.textureView => PlatformVideoViewType.textureView,
      VideoViewType.platformView => PlatformVideoViewType.platformView,
    };
  }

  static const Map<VideoFormat, String> _videoFormatStringMap =
      <VideoFormat, String>{
        VideoFormat.ss: 'ss',
        VideoFormat.hls: 'hls',
        VideoFormat.dash: 'dash',
        VideoFormat.other: 'other',
      };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }

  VideoAudioTrack _toVideoAudioTrack(Map<String, dynamic> track) {
    final int? bitrate = _toInt(track['bitrate']);
    final int? sampleRate = _toInt(track['sampleRate']);
    final int? channelCount = _toInt(track['channelCount']);
    final bool isSelected = track['isSelected'] == true;
    return VideoAudioTrack(
      id: track['id']?.toString() ?? '',
      label: track['label']?.toString(),
      language: track['language']?.toString(),
      isSelected: isSelected,
      bitrate: bitrate,
      sampleRate: sampleRate,
      channelCount: channelCount,
      codec: track['codec']?.toString(),
    );
  }

  VideoTrack _toVideoTrack(Map<String, dynamic> track) {
    final int? bitrate = _toInt(track['bitrate']);
    final int? width = _toInt(track['width']);
    final int? height = _toInt(track['height']);
    final double? frameRate = _toDouble(track['frameRate']);
    final bool isSelected = track['isSelected'] == true;
    // 与 Android 实现对齐：label 缺失时根据分辨率生成（如 "1080p"）。
    final String? label =
        track['label']?.toString() ??
        (width != null && height != null ? '${height}p' : null);
    return VideoTrack(
      id: track['id']?.toString() ?? '',
      label: label,
      isSelected: isSelected,
      bitrate: bitrate,
      width: width,
      height: height,
      frameRate: frameRate,
      codec: track['codec']?.toString(),
    );
  }

  double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  (int, int) _parseTrackId(String trackId) {
    final List<String> parts = trackId.split('_');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid trackId format: "$trackId". Expected format: "groupIndex_trackIndex"',
      );
    }

    final int? groupIndex = int.tryParse(parts[0]);
    final int? trackIndex = int.tryParse(parts[1]);
    if (groupIndex == null || trackIndex == null) {
      throw ArgumentError(
        'Invalid trackId format: "$trackId". Expected format: "groupIndex_trackIndex"',
      );
    }

    return (groupIndex, trackIndex);
  }
}

/// How a player presents frames to Flutter.
sealed class VideoPlayerViewState {
  const VideoPlayerViewState();
}

/// Frames go through [TextureRegistry] and are sampled as a Flutter [Texture].
@visibleForTesting
final class VideoPlayerTextureViewState extends VideoPlayerViewState {
  /// Creates texture view state for [textureId].
  const VideoPlayerTextureViewState({required this.textureId});

  /// Engine texture handle. Equal to playerId on the OHOS texture path.
  final int textureId;
}

/// Frames go to an XComponent surface; HCPP composites that layer.
@visibleForTesting
final class VideoPlayerPlatformViewState extends VideoPlayerViewState {
  /// Creates platform-view presentation state for the HCPP hole.
  const VideoPlayerPlatformViewState({
    required this.source,
    this.objectFit = BoxFit.contain,
    this.looping = false,
    this.speed = 1.0,
  });

  /// Data source label forwarded in PlatformView [creationParams].
  final String source;

  /// Initial object-fit forwarded in PlatformView creation params.
  final BoxFit objectFit;

  /// Initial looping flag.
  final bool looping;

  /// Initial playback speed.
  final double speed;

  /// Copies this state with the given fields replaced.
  VideoPlayerPlatformViewState copyWith({
    String? source,
    BoxFit? objectFit,
    bool? looping,
    double? speed,
  }) {
    return VideoPlayerPlatformViewState(
      source: source ?? this.source,
      objectFit: objectFit ?? this.objectFit,
      looping: looping ?? this.looping,
      speed: speed ?? this.speed,
    );
  }
}
