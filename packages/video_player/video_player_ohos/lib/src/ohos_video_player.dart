// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'video_player_ohos_channel.dart';
import 'messages.g.dart';

/// An OHOS implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [OhosVideoPlayerApi].
class OhosVideoPlayer extends VideoPlayerPlatform {
  OhosVideoPlayer({OhosVideoPlayerApi? pluginApi})
    : _api = pluginApi ?? OhosVideoPlayerApi();

  final OhosVideoPlayerApi _api;

  static void registerWith() {
    VideoPlayerPlatform.instance = OhosVideoPlayer();
  }

  @override
  Future<void> init() => _api.initialize();

  @override
  Future<void> dispose(int textureId) => _api.dispose(textureId);

  @override
  Future<int?> create(DataSource dataSource) async {
    return _create(dataSource);
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    return _create(options.dataSource);
  }

  Future<int?> _create(DataSource dataSource) async {
    String? asset;
    String? uri;
    final String? packageName = dataSource.package;
    final String? formatHint = dataSource.formatHint == null
        ? null
        : _videoFormatStringMap[dataSource.formatHint];
    final httpHeaders = dataSource.httpHeaders.isEmpty
        ? null
        : Map<String?, String?>.fromEntries(dataSource.httpHeaders.entries
            .map((e) => MapEntry(e.key, e.value)));

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        break;
      case DataSourceType.network:
        uri = dataSource.uri;
        break;
      case DataSourceType.file:
        uri = dataSource.uri?.startsWith('fd://') == true
            ? dataSource.uri
            : 'fd://${await VideoPlayerOhosChannel.getFileFdByPath(dataSource.uri!)}';
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
      viewType: PlatformVideoViewType.textureView,
    );

    return _api.create(message);
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
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
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
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
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(mixWithOthers);
  }

  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int playerId) async {
    if (playerId < 0) {
      return <VideoAudioTrack>[];
    }
    final List<Object?> nativeTracks = await _api.getAudioTracks(
      playerId,
    );
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

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
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
