// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_ohos/src/messages.g.dart';
import 'package:video_player_ohos/src/platform_view_player.dart';
import 'package:video_player_ohos/video_player_ohos.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  group('OhosVideoPlayer create options', () {
    test(
      'createWithOptions forwards package asset fields and backBufferDurationMs',
      () async {
        final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
        final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

        final int? playerId = await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.asset,
              asset: 'videos/demo.mp4',
              package: 'example_pkg',
            ),
            viewType: VideoViewType.textureView,
            videoPlayerOptions: VideoPlayerOptions(backBufferDurationMs: 20000),
          ),
        );

        expect(playerId, 1);
        expect(api.lastCreateMessage, isNotNull);
        expect(api.lastCreateMessage!.asset, 'videos/demo.mp4');
        expect(api.lastCreateMessage!.uri, isNull);
        expect(api.lastCreateMessage!.packageName, 'example_pkg');
        expect(api.lastCreateMessage!.formatHint, isNull);
        expect(api.lastCreateMessage!.httpHeaders, isEmpty);
        expect(
          api.lastCreateMessage!.viewType,
          PlatformVideoViewType.textureView,
        );
        expect(api.lastCreateMessage!.backBufferDurationMs, 20000);
      },
    );

    test(
      'createWithOptions forwards platformView and buildView uses PlatformViewPlayer',
      () async {
        final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
        final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

        final int? playerId = await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/hdr.mp4',
            ),
            viewType: VideoViewType.platformView,
          ),
        );

        expect(playerId, 1);
        expect(
          api.lastCreateMessage!.viewType,
          PlatformVideoViewType.platformView,
        );
        expect(
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
          isA<PlatformViewPlayer>(),
        );
        final PlatformViewPlayer view =
            player.buildViewWithOptions(VideoViewOptions(playerId: playerId))
                as PlatformViewPlayer;
        expect(view.creationParams, <String, Object>{
          'playerId': playerId,
          'source': 'https://example.com/hdr.mp4',
          'objectFit': 'contain',
          'looping': false,
          'speed': 1.0,
        });
      },
    );

    test('platformView creationParams tracks looping and speed', () async {
      final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
      final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

      final int? playerId = await player.createWithOptions(
        VideoCreationOptions(
          dataSource: DataSource(
            sourceType: DataSourceType.asset,
            asset: 'videos/demo.mp4',
            package: 'example_pkg',
          ),
          viewType: VideoViewType.platformView,
        ),
      );

      await player.setLooping(playerId!, true);
      await player.setPlaybackSpeed(playerId, 1.5);
      final PlatformViewPlayer view =
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId))
              as PlatformViewPlayer;
      expect(
        view.creationParams['source'],
        'packages/example_pkg/videos/demo.mp4',
      );
      expect(view.creationParams['looping'], isTrue);
      expect(view.creationParams['speed'], 1.5);
      expect(view.creationParams['objectFit'], 'contain');
    });

    test(
      'createWithOptions textureView still builds a Texture widget',
      () async {
        final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
        final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

        final int? playerId = await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/sdr.mp4',
            ),
            viewType: VideoViewType.textureView,
          ),
        );

        expect(playerId, 1);
        expect(
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
          isA<Texture>(),
        );
      },
    );

    test(
      'createWithOptions forwards network headers and format hint',
      () async {
        final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
        final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

        final int? playerId = await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/video.m3u8',
              formatHint: VideoFormat.hls,
              httpHeaders: const <String, String>{
                'Authorization': 'Bearer token',
              },
            ),
            viewType: VideoViewType.textureView,
          ),
        );

        expect(playerId, 1);
        expect(api.lastCreateMessage, isNotNull);
        expect(api.lastCreateMessage!.asset, isNull);
        expect(api.lastCreateMessage!.uri, 'https://example.com/video.m3u8');
        expect(api.lastCreateMessage!.packageName, isNull);
        expect(api.lastCreateMessage!.formatHint, 'hls');
        expect(api.lastCreateMessage!.httpHeaders, const <String?, String?>{
          'Authorization': 'Bearer token',
        });
        expect(
          api.lastCreateMessage!.viewType,
          PlatformVideoViewType.textureView,
        );
        expect(api.lastCreateMessage!.backBufferDurationMs, isNull);
      },
    );

    test('create keeps fd uri unchanged for file sources', () async {
      final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
      final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

      final int? playerId = await player.create(
        DataSource(sourceType: DataSourceType.file, uri: 'fd://42'),
      );

      expect(playerId, 1);
      expect(api.lastCreateMessage, isNotNull);
      expect(api.lastCreateMessage!.asset, isNull);
      expect(api.lastCreateMessage!.uri, 'fd://42');
      expect(api.lastCreateMessage!.packageName, isNull);
      expect(api.lastCreateMessage!.httpHeaders, isEmpty);
      expect(
        api.lastCreateMessage!.viewType,
        PlatformVideoViewType.textureView,
      );
    });

    test('legacy create still builds a Texture widget', () async {
      final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
      final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

      final int? playerId = await player.create(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/sdr.mp4',
        ),
      );

      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test(
      'dispose drops platformView state so later buildView is not PlatformViewPlayer',
      () async {
        final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
        final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

        final int? playerId = await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/hdr.mp4',
            ),
            viewType: VideoViewType.platformView,
          ),
        );

        expect(
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
          isA<PlatformViewPlayer>(),
        );
        await player.dispose(playerId);
        expect(
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId)),
          isA<Texture>(),
        );
      },
    );

    test(
      'PlatformViewPlayer factory name matches native registerViewFactory',
      () {
        expect(
          kVideoPlayerOhosViewType,
          'plugins.flutter.io/video_player_ohos',
        );
        const PlatformViewPlayer view = PlatformViewPlayer(
          playerId: 1000000,
          source: 'https://example.com/hdr.mp4',
        );
        expect(view.creationParams['playerId'], 1000000);
        expect(view.creationParams['source'], 'https://example.com/hdr.mp4');
        expect(view.creationParams['objectFit'], 'contain');
        expect(view.creationParams['looping'], isFalse);
        expect(view.creationParams['speed'], 1.0);
      },
    );

    test('platformView file source label is the original uri', () async {
      final _RecordingOhosVideoPlayerApi api = _RecordingOhosVideoPlayerApi();
      final OhosVideoPlayer player = OhosVideoPlayer(pluginApi: api);

      final int? playerId = await player.createWithOptions(
        VideoCreationOptions(
          dataSource: DataSource(
            sourceType: DataSourceType.file,
            uri: 'fd://7',
          ),
          viewType: VideoViewType.platformView,
        ),
      );

      final PlatformViewPlayer view =
          player.buildViewWithOptions(VideoViewOptions(playerId: playerId!))
              as PlatformViewPlayer;
      expect(view.creationParams['source'], 'fd://7');
    });
  });

  group('VideoPlayerWebOptions poster', () {
    test('defaults to null', () {
      const VideoPlayerWebOptions options = VideoPlayerWebOptions();
      expect(options.poster, isNull);
    });

    test('holds the configured poster image URL', () {
      final Uri poster = Uri.parse('https://example.com/poster.png');
      final VideoPlayerWebOptions options = VideoPlayerWebOptions(
        poster: poster,
      );
      expect(options.poster, poster);
    });
  });

  group('VideoPlayerWebOptionsControls', () {
    test('allowDownload holds the configured value', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled(allowDownload: false);
      expect(controls.allowDownload, isFalse);
    });

    test('allowFullscreen holds the configured value', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled(allowFullscreen: false);
      expect(controls.allowFullscreen, isFalse);
    });

    test('allowPlaybackRate holds the configured value', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled(allowPlaybackRate: false);
      expect(controls.allowPlaybackRate, isFalse);
    });

    test('allowPictureInPicture holds the configured value', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled(allowPictureInPicture: false);
      expect(controls.allowPictureInPicture, isFalse);
    });

    test('controlsList joins disallowed controls with a space', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled(
            allowDownload: false,
            allowFullscreen: false,
            allowPlaybackRate: false,
          );
      expect(controls.controlsList, 'nodownload nofullscreen noplaybackrate');
    });

    test('controlsList is empty when all controls are allowed', () {
      const VideoPlayerWebOptionsControls controls =
          VideoPlayerWebOptionsControls.enabled();
      expect(controls.controlsList, isEmpty);
    });
  });
}

class _RecordingOhosVideoPlayerApi extends OhosVideoPlayerApi {
  _RecordingOhosVideoPlayerApi() : super();

  CreateMessage? lastCreateMessage;

  @override
  Future<int> create(CreateMessage msg) async {
    lastCreateMessage = msg;
    return 1;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> dispose(int playerId) async {}
}
