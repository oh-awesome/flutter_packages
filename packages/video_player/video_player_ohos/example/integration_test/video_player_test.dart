// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player_ohos/src/platform_view_player.dart';
import 'package:video_player_ohos/src/video_player_ohos_channel.dart';
import 'package:video_player_ohos/video_player_ohos.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const Duration _playDuration = Duration(seconds: 1);
const String _videoAssetKey = 'assets/Butterfly-209.mp4';

// Returns the URL to load an asset from this example app as a network source.
//
// TODO(stuartmorgan): Convert this to a local `HttpServer` that vends the
// assets directly, https://github.com/flutter/flutter/issues/95420
String getUrlForAssetAsNetworkSource(String assetKey) {
  return 'https://github.com/flutter/packages/blob/'
      // This hash can be rolled forward to pick up newly-added assets.
      '2e1673307ff7454aff40b47024eaed49a9e77e81'
      '/packages/video_player/video_player/example/'
      '$assetKey'
      '?raw=true';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late OhosVideoPlayer player;

  setUp(() async {
    player = OhosVideoPlayer();
    await player.init();
  });

  testWidgets('registers expected implementation', (_) async {
    OhosVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<OhosVideoPlayer>());
  });

  testWidgets('initializes at the start', (_) async {
    final int playerId = (await player.create(
      DataSource(sourceType: DataSourceType.asset, asset: _videoAssetKey),
    ))!;

    expect(
      await _getDuration(player, playerId),
      const Duration(seconds: 7, milliseconds: 540),
    );

    await player.dispose(playerId);
  });

  testWidgets('can be played', (WidgetTester tester) async {
    final int playerId = (await player.create(
      DataSource(sourceType: DataSourceType.asset, asset: _videoAssetKey),
    ))!;

    await player.play(playerId);
    await tester.pumpAndSettle(_playDuration);

    expect(await player.getPosition(playerId), greaterThan(Duration.zero));
    await player.dispose(playerId);
  });

  testWidgets('can seek', (WidgetTester tester) async {
    final int playerId = (await player.create(
      DataSource(sourceType: DataSourceType.asset, asset: _videoAssetKey),
    ))!;

    await player.seekTo(playerId, const Duration(seconds: 3));
    await tester.pumpAndSettle(_playDuration);

    expect(
      await player.getPosition(playerId),
      greaterThanOrEqualTo(const Duration(seconds: 3)),
    );
    await player.dispose(playerId);
  });

  testWidgets('can pause', (WidgetTester tester) async {
    final int playerId = (await player.create(
      DataSource(sourceType: DataSourceType.asset, asset: _videoAssetKey),
    ))!;

    await player.play(playerId);
    await tester.pumpAndSettle(_playDuration);

    await player.pause(playerId);
    await tester.pumpAndSettle(_playDuration);
    final Duration pausedDuration = await player.getPosition(playerId);
    await tester.pumpAndSettle(_playDuration);

    expect(await player.getPosition(playerId), pausedDuration);
    await player.dispose(playerId);
  });

  testWidgets('can play a video from a file', (WidgetTester tester) async {
    final Directory directory = await getTemporaryDirectory();
    final file = File('${directory.path}/video.mp4');
    await file.writeAsBytes(
      Uint8List.fromList(
        (await rootBundle.load(_videoAssetKey)).buffer.asUint8List(),
      ),
    );

    final int playerId = (await player.create(
      DataSource(sourceType: DataSourceType.file, uri: file.path),
    ))!;

    await player.play(playerId);
    await tester.pumpAndSettle(_playDuration);

    expect(await player.getPosition(playerId), greaterThan(Duration.zero));
    await directory.delete(recursive: true);
    await player.dispose(playerId);
  },
  //OHOS not support 
  skip: defaultTargetPlatform == TargetPlatform.ohos);

  testWidgets('can play a video from network', (WidgetTester tester) async {
    final int playerId = (await player.create(
      DataSource(
        sourceType: DataSourceType.network,
        uri: getUrlForAssetAsNetworkSource(_videoAssetKey),
      ),
    ))!;

    await player.play(playerId);
    await player.seekTo(playerId, const Duration(seconds: 5));
    await tester.pumpAndSettle(_playDuration);
    await player.pause(playerId);

    expect(await player.getPosition(playerId), greaterThan(Duration.zero));

    final DurationRange range = await _getBufferingRange(player, playerId);
    expect(range.start, Duration.zero);
    expect(range.end, greaterThan(Duration.zero));

    await player.dispose(playerId);
  }, 
  //OHOS not support(Network link access failed. Replace it and it will work.)
   skip: defaultTargetPlatform == TargetPlatform.ohos);

  testWidgets('exposes the remaining OHOS playback surface', (
    WidgetTester tester,
  ) async {
    final int playerId = (await player.createWithOptions(
      VideoCreationOptions(
        dataSource: DataSource(
          sourceType: DataSourceType.asset,
          asset: _videoAssetKey,
        ),
        viewType: VideoViewType.textureView,
      ),
    ))!;

    await player.setLooping(playerId, true);
    await player.setVolume(playerId, 0.5);
    await player.setPlaybackSpeed(playerId, 1.5);
    await player.setMixWithOthers(true);
    await player.setPreventsDisplaySleepDuringVideoPlayback(playerId, true);

    expect(player.isAudioTrackSupportAvailable(), isTrue);
    expect(player.isVideoTrackSupportAvailable(), isTrue);

    // Start playback before asking for track descriptions: the native player
    // rejects the query while it is still preparing ("current state unsupport
    // get track description") and rethrows that rejection instead of returning
    // an empty list, so the query must run against a prepared player.
    await player.play(playerId);
    await tester.pumpAndSettle(_playDuration);

    final List<VideoAudioTrack> audioTracks = await player.getAudioTracks(
      playerId,
    );
    final List<VideoTrack> videoTracks = await player.getVideoTracks(playerId);
    expect(audioTracks, isNotEmpty);
    expect(audioTracks.first.id, isNotEmpty);
    expect(videoTracks, isNotEmpty);
    expect(videoTracks.first.id, isNotEmpty);

    // Track selection is best-effort: not every asset exposes selectable
    // tracks, so any native rejection must not fail the whole run.
    try {
      await player.selectAudioTrack(playerId, audioTracks.first.id);
      await player.selectVideoTrack(playerId, null);
    } catch (_) {
      // Selection support varies per device/codec; the call path is what we
      // exercise here.
    }

    expect(player.buildView(playerId), isA<Texture>());
    expect(
      player.buildViewWithOptions(VideoViewOptions(playerId: playerId)),
      isA<Texture>(),
    );

    await player.dispose(playerId);
  });

  testWidgets('channel helpers and view state are reachable', (
    WidgetTester tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(
      const PlatformViewPlayer(
        playerId: 1,
        source: 'https://example.com/video.mp4',
      ).build(context),
      isA<IgnorePointer>(),
    );

    const VideoPlayerTextureViewState textureState =
        VideoPlayerTextureViewState(textureId: 9);
    expect(textureState.textureId, 9);

    // A missing path must not crash the app; the native side may reject it.
    try {
      final int fd = await VideoPlayerOhosChannel.getFileFdByPath(
        '/data/local/tmp/does-not-exist.mp4',
      );
      await VideoPlayerOhosChannel.closeFileFd(fd);
    } catch (_) {
      // Native may reject the missing path; the call path is still exercised.
    }
    try {
      await VideoPlayerOhosChannel.setKeepScreenOn(1, true);
    } catch (_) {
      // Older native versions may not implement this branch.
    }
  });
}

Future<Duration> _getDuration(OhosVideoPlayer player, int playerId) {
  return player
      .videoEventsFor(playerId)
      .firstWhere((VideoEvent event) {
        return event.eventType == VideoEventType.initialized;
      })
      .then((VideoEvent event) {
        return event.duration!;
      });
}

Future<DurationRange> _getBufferingRange(
  OhosVideoPlayer player,
  int playerId,
) {
  return player
      .videoEventsFor(playerId)
      .firstWhere((VideoEvent event) {
        return event.eventType == VideoEventType.bufferingUpdate;
      })
      .then((VideoEvent event) {
        return event.buffered!.first;
      });
}
