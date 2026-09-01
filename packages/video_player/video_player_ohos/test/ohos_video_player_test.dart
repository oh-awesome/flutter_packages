// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player_ohos/src/messages.g.dart';
// import 'package:video_player_ohos/src/platform_view_player.dart';
import 'package:video_player_ohos/video_player_ohos.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'ohos_video_player_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<OhosVideoPlayerApi>(),
  // MockSpec<VideoPlayerInstanceApi>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide dummy values for audio track types
  // provideDummy<NativeAudioTrackData>(
  //   NativeAudioTrackData(exoPlayerTracks: <ExoPlayerAudioTrackData>[]),
  // );
  // provideDummy<Future<NativeAudioTrackData>>(
  //   Future<NativeAudioTrackData>.value(
  //     NativeAudioTrackData(exoPlayerTracks: <ExoPlayerAudioTrackData>[]),
  //   ),
  // );
  provideDummy<Future<void>>(Future<void>.value());

  (OhosVideoPlayer, MockOhosVideoPlayerApi)
  setUpMockPlayer({required int playerId, int? textureId}) {
    final pluginApi = MockOhosVideoPlayerApi();
    // final instanceApi = MockVideoPlayerInstanceApi();
    final player = OhosVideoPlayer(
      pluginApi: pluginApi,
  //     playerApiProvider: (_) => instanceApi,
    );
  //   player.ensurePlayerInitialized(
  //     playerId,
  //     textureId == null
  //         ? const VideoPlayerPlatformViewState()
  //         : VideoPlayerTextureViewState(textureId: textureId),
  //   );
    return (player, pluginApi);
  }

  // (
  //   OhosVideoPlayer,
  //   MockOhosVideoPlayerApi,
  //   MockVideoPlayerInstanceApi,
  //   StreamController<PlatformVideoEvent>,
  // )
  // setUpMockPlayerWithStream({required int playerId, int? textureId}) {
  //   final pluginApi = MockOhosVideoPlayerApi();
  //   final instanceApi = MockVideoPlayerInstanceApi();
  //   final streamController = StreamController<PlatformVideoEvent>();
  //   final player = OhosVideoPlayer(
  //     pluginApi: pluginApi,
  //     playerApiProvider: (_) => instanceApi,
  //     videoEventStreamProvider: (_) =>
  //         streamController.stream.asBroadcastStream(),
  //   );
  //   player.ensurePlayerInitialized(
  //     playerId,
  //     textureId == null
  //         ? const VideoPlayerPlatformViewState()
  //         : VideoPlayerTextureViewState(textureId: textureId),
  //   );
  //   return (player, pluginApi, instanceApi, streamController);
  // }

  test('registration', () async {
    OhosVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<OhosVideoPlayer>());
  });

  group('OhosVideoPlayer', () {
    test('init', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer(playerId: 1);
      await player.init();

      verify(api.initialize());
    });

    test('dispose', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer(playerId: 1);
      await player.dispose(1);

      verify(api.dispose(1));
    });

    // test('create with asset', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const asset = 'someAsset';
    //   const package = 'somePackage';
    //   const assetKey = 'resultingAssetKey';
    //   when(
    //     api.getLookupKeyForAsset(asset, package),
    //   ).thenAnswer((_) async => assetKey);

    //   final int? playerId = await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.asset,
    //       asset: asset,
    //       package: package,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, 'asset:///$assetKey');
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('create with network', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const uri = 'https://example.com';
    //   final int? playerId = await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.network,
    //       uri: uri,
    //       formatHint: VideoFormat.dash,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, uri);
    //   expect(creationOptions.formatHint, PlatformVideoFormat.dash);
    //   expect(creationOptions.httpHeaders, <String, String>{});
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('create with network passes headers', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   const headers = <String, String>{'Authorization': 'Bearer token'};
    //   await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.network,
    //       uri: 'https://example.com',
    //       httpHeaders: headers,
    //     ),
    //   );
    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.httpHeaders, headers);
    // });

    // test('create with network sets a default user agent', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.network,
    //       uri: 'https://example.com',
    //       httpHeaders: <String, String>{},
    //     ),
    //   );
    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.userAgent, 'ExoPlayer');
    // });

    // test('create with network uses user agent from headers', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   const userAgent = 'Test User Agent';
    //   const headers = <String, String>{'User-Agent': userAgent};
    //   await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.network,
    //       uri: 'https://example.com',
    //       httpHeaders: headers,
    //     ),
    //   );
    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.userAgent, userAgent);
    // });

    // test('create with file', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   const fileUri = 'file:///foo/bar';
    //   final int? playerId = await player.create(
    //     DataSource(sourceType: DataSourceType.file, uri: fileUri),
    //   );
    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, fileUri);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('create with file passes headers', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   const fileUri = 'file:///foo/bar';
    //   const headers = <String, String>{'Authorization': 'Bearer token'};
    //   await player.create(
    //     DataSource(
    //       sourceType: DataSourceType.file,
    //       uri: fileUri,
    //       httpHeaders: headers,
    //     ),
    //   );
    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.httpHeaders, headers);
    // });

    // test('createWithOptions with asset', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const asset = 'someAsset';
    //   const package = 'somePackage';
    //   const assetKey = 'resultingAssetKey';
    //   when(
    //     api.getLookupKeyForAsset(asset, package),
    //   ).thenAnswer((_) async => assetKey);

    //   final int? playerId = await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(
    //         sourceType: DataSourceType.asset,
    //         asset: asset,
    //         package: package,
    //       ),
    //       viewType: VideoViewType.textureView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, 'asset:///$assetKey');
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('createWithOptions with network', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const uri = 'https://example.com';
    //   final int? playerId = await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(
    //         sourceType: DataSourceType.network,
    //         uri: uri,
    //         formatHint: VideoFormat.dash,
    //       ),
    //       viewType: VideoViewType.textureView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, uri);
    //   expect(creationOptions.formatHint, PlatformVideoFormat.dash);
    //   expect(creationOptions.httpHeaders, <String, String>{});
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('createWithOptions with network passes headers', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const headers = <String, String>{'Authorization': 'Bearer token'};
    //   final int? playerId = await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(
    //         sourceType: DataSourceType.network,
    //         uri: 'https://example.com',
    //         httpHeaders: headers,
    //       ),
    //       viewType: VideoViewType.textureView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.httpHeaders, headers);
    //   expect(playerId, newPlayerId);
    // });

    // test('createWithOptions with file', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   const newPlayerId = 2;
    //   when(api.createForTextureView(any)).thenAnswer(
    //     (_) async => TexturePlayerIds(playerId: newPlayerId, textureId: 100),
    //   );

    //   const fileUri = 'file:///foo/bar';
    //   final int? playerId = await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(sourceType: DataSourceType.file, uri: fileUri),
    //       viewType: VideoViewType.textureView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, fileUri);
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<Texture>(),
    //   );
    // });

    // test('createWithOptions with file passes headers', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1, textureId: 100);
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));

    //   const fileUri = 'file:///foo/bar';
    //   const headers = <String, String>{'Authorization': 'Bearer token'};
    //   await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(
    //         sourceType: DataSourceType.file,
    //         uri: fileUri,
    //         httpHeaders: headers,
    //       ),
    //       viewType: VideoViewType.textureView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForTextureView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.httpHeaders, headers);
    // });

    // test('createWithOptions with platform view', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) =
    //       setUpMockPlayer(playerId: 1);
    //   const newPlayerId = 2;
    //   when(api.createForPlatformView(any)).thenAnswer((_) async => newPlayerId);

    //   const uri = 'file:///foo/bar';
    //   final int? playerId = await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(sourceType: DataSourceType.file, uri: uri),
    //       viewType: VideoViewType.platformView,
    //     ),
    //   );

    //   final VerificationResult verification = verify(
    //     api.createForPlatformView(captureAny),
    //   );
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.uri, uri);
    //   expect(playerId, newPlayerId);
    //   expect(
    //     player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
    //     isA<PlatformViewPlayer>(),
    //   );
    // });
    // OHOS 不支持以下两个 backBufferDurationMs 用例：
    // 原因：OHOS 的 OhosVideoPlayerApi 没有 createForTextureView /
    // createForPlatformView 方法（只有单一的 create(CreateMessage)），
    // 也不存在 CreationOptions / TexturePlayerIds 类。
    // 此外 setUpMockPlayer 返回二元组，而非 Android 的三元组。
    //
    // test('createWithOptions passes backBufferDurationMs for texture view', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) = setUpMockPlayer(
    //     playerId: 1,
    //     textureId: 100,
    //   );
    //   when(
    //     api.createForTextureView(any),
    //   ).thenAnswer((_) async => TexturePlayerIds(playerId: 2, textureId: 100));
    //
    //   await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(sourceType: DataSourceType.network, uri: 'https://example.com'),
    //       viewType: VideoViewType.textureView,
    //       videoPlayerOptions: VideoPlayerOptions(backBufferDurationMs: 20000),
    //     ),
    //   );
    //
    //   final VerificationResult verification = verify(api.createForTextureView(captureAny));
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.backBufferDurationMs, 20000);
    // });
    //
    // test('createWithOptions passes backBufferDurationMs for platform view', () async {
    //   final (OhosVideoPlayer player, MockOhosVideoPlayerApi api, _) = setUpMockPlayer(
    //     playerId: 1,
    //   );
    //   when(api.createForPlatformView(any)).thenAnswer((_) async => 2);
    //
    //   await player.createWithOptions(
    //     VideoCreationOptions(
    //       dataSource: DataSource(sourceType: DataSourceType.network, uri: 'https://example.com'),
    //       viewType: VideoViewType.platformView,
    //       videoPlayerOptions: VideoPlayerOptions(backBufferDurationMs: 20000),
    //     ),
    //   );
    //
    //   final VerificationResult verification = verify(api.createForPlatformView(captureAny));
    //   final creationOptions = verification.captured[0] as CreationOptions;
    //   expect(creationOptions.backBufferDurationMs, 20000);
    // });

    test('setLooping', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      await player.setLooping(1, true);

      verify(playerApi.setLooping(1, true));
    });

    test('play', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      await player.play(1);

      verify(playerApi.play(1));
    });

    test('pause', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      await player.pause(1);

      verify(playerApi.pause(1));
    });

    group('setMixWithOthers', () {
      test('passes true', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer(playerId: 1);
        await player.setMixWithOthers(true);

        verify(api.setMixWithOthers(true));
      });

      test('passes false', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer(playerId: 1);
        await player.setMixWithOthers(false);

        verify(api.setMixWithOthers(false));
      });
    });

    test('setVolume', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      const volume = 0.7;
      await player.setVolume(1, volume);

      verify(playerApi.setVolume(1, volume));
    });

    test('setPlaybackSpeed', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      const speed = 1.5;
      await player.setPlaybackSpeed(1, speed);

      verify(playerApi.setPlaybackSpeed(1, speed));
    });

    test('seekTo', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      const positionMilliseconds = 12345;
      await player.seekTo(
        1,
        const Duration(milliseconds: positionMilliseconds),
      );

      verify(playerApi.seekTo(1, positionMilliseconds));
    });

    test('getPosition', () async {
      final (
        OhosVideoPlayer player,
        MockOhosVideoPlayerApi playerApi,
      ) = setUpMockPlayer(
        playerId: 1,
      );
      const positionMilliseconds = 12345;
      when(
        playerApi.position(1),
      ).thenAnswer((_) async => positionMilliseconds);

      final Duration position = await player.getPosition(1);
      expect(position, const Duration(milliseconds: positionMilliseconds));
    });

    group('videoEventsFor', () {
      const EventChannel eventChannel = EventChannel(
        'flutter.io/videoPlayer/videoEvents1',
      );

      // Emits the given raw event maps on the mocked native event stream.
      void mockEventStream(List<Object?> events) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink sink) {
              for (final Object? event in events) {
                sink.success(event);
              }
            },
          ),
        );
      }

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
      });

      test(
          'initialized event with null duration does not throw '
          '(live stream with undefined duration)', () async {
        mockEventStream(<Object?>[
          <String, Object?>{
            'event': 'initialized',
            // Live streams may report an undefined duration, which arrives
            // as null. This must not throw a TypeError.
            'duration': null,
            'width': 480,
            'height': 270,
            'rotationCorrection': 0,
          },
        ]);

        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);
        final List<Object?> received = <Object?>[];
        final StreamSubscription<VideoEvent> subscription = player
            .videoEventsFor(1)
            .listen(received.add, onError: (Object e) => received.add(e));
        await pumpEventQueue();

        expect(received, hasLength(1));
        expect(received.single, isA<VideoEvent>());
        final VideoEvent event = received.single as VideoEvent;
        expect(event.eventType, VideoEventType.initialized);
        expect(event.duration, Duration.zero);
        expect(event.size, const Size(480, 270));
        expect(event.rotationCorrection, 0);

        await subscription.cancel();
      });

      test('initialized event with int duration parses normally', () async {
        mockEventStream(<Object?>[
          <String, Object?>{
            'event': 'initialized',
            'duration': 98765,
            'width': 1920,
            'height': 1080,
            'rotationCorrection': 90,
          },
        ]);

        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);
        final List<VideoEvent> events = <VideoEvent>[];
        final StreamSubscription<VideoEvent> subscription = player
            .videoEventsFor(1)
            .listen(events.add);
        await pumpEventQueue();

        expect(events, hasLength(1));
        expect(events.single.eventType, VideoEventType.initialized);
        expect(events.single.duration, const Duration(milliseconds: 98765));
        expect(events.single.size, const Size(1920, 1080));
        expect(events.single.rotationCorrection, 90);

        await subscription.cancel();
      });
    });

    // group('video events', () {
      // Sets up a mock player that emits the given event structure as a success
      // callback on the internal platform channel event stream, and returns
      // the player's videoEventsFor(...) stream.
      // Stream<VideoEvent> mockPlayerEmitingEvents(
      //   List<PlatformVideoEvent> events,
      // ) {
      //   const playerId = 1;
      //   final (
      //     OhosVideoPlayer player,
      //     _,
      //     _,
      //     StreamController<PlatformVideoEvent> streamController,
      //   ) = setUpMockPlayerWithStream(
      //     playerId: playerId,
      //   );

      //   events.forEach(streamController.add);

      //   return player.videoEventsFor(playerId);
      // }

    //   test('initialize', () async {
    //     final Stream<VideoEvent> eventStream =
    //         mockPlayerEmitingEvents(<PlatformVideoEvent>[
    //           InitializationEvent(
    //             duration: 98765,
    //             width: 1920,
    //             height: 1080,
    //             rotationCorrection: 90,
    //           ),
    //         ]);

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(
    //           eventType: VideoEventType.initialized,
    //           duration: const Duration(milliseconds: 98765),
    //           size: const Size(1920, 1080),
    //           rotationCorrection: 90,
    //         ),
    //       ]),
    //     );
    //   });

    //   test('initialization triggers buffer update polling', () async {
    //     final Stream<VideoEvent> eventStream =
    //         mockPlayerEmitingEvents(<PlatformVideoEvent>[
    //           InitializationEvent(
    //             duration: 98765,
    //             width: 1920,
    //             height: 1080,
    //             rotationCorrection: 90,
    //           ),
    //         ]);

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(
    //           eventType: VideoEventType.initialized,
    //           duration: const Duration(milliseconds: 98765),
    //           size: const Size(1920, 1080),
    //           rotationCorrection: 90,
    //         ),
    //         VideoEvent(
    //           eventType: VideoEventType.bufferingUpdate,
    //           buffered: <DurationRange>[
    //             DurationRange(Duration.zero, Duration.zero),
    //           ],
    //         ),
    //       ]),
    //     );
    //   });

    //   test('completed', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.ended),
    //       ],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(eventType: VideoEventType.completed),
    //       ]),
    //     );
    //   });

    //   test('buffering start', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.buffering),
    //       ],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(eventType: VideoEventType.bufferingStart),
    //         // A buffer start should trigger a buffer update as well.
    //         VideoEvent(
    //           eventType: VideoEventType.bufferingUpdate,
    //           buffered: <DurationRange>[
    //             DurationRange(Duration.zero, Duration.zero),
    //           ],
    //         ),
    //       ]),
    //     );
    //   });

    //   test('buffering end for ready', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[
    //         // Trigger a start first, since end is only emitted if it's
    //         // started.
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.buffering),
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.ready),
    //       ],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         // Emitted by buffering.
    //         VideoEvent(eventType: VideoEventType.bufferingStart),
    //         VideoEvent(
    //           eventType: VideoEventType.bufferingUpdate,
    //           buffered: <DurationRange>[
    //             DurationRange(Duration.zero, Duration.zero),
    //           ],
    //         ),
    //         // Emitted by ready.
    //         VideoEvent(eventType: VideoEventType.bufferingEnd),
    //       ]),
    //     );
    //   });

    //   test('buffering end for idle', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[
    //         // Trigger a start first, since end is only emitted if it's
    //         // started.
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.buffering),
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.idle),
    //       ],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         // Emitted by buffering.
    //         VideoEvent(eventType: VideoEventType.bufferingStart),
    //         VideoEvent(
    //           eventType: VideoEventType.bufferingUpdate,
    //           buffered: <DurationRange>[
    //             DurationRange(Duration.zero, Duration.zero),
    //           ],
    //         ),
    //         // Emitted by ready.
    //         VideoEvent(eventType: VideoEventType.bufferingEnd),
    //       ]),
    //     );
    //   });

    //   test('buffering end for ended', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[
    //         // Trigger a start first, since end is only emitted if it's
    //         // started.
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.buffering),
    //         PlaybackStateChangeEvent(state: PlatformPlaybackState.ended),
    //       ],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         // Emitted by buffering.
    //         VideoEvent(eventType: VideoEventType.bufferingStart),
    //         VideoEvent(
    //           eventType: VideoEventType.bufferingUpdate,
    //           buffered: <DurationRange>[
    //             DurationRange(Duration.zero, Duration.zero),
    //           ],
    //         ),
    //         // Emitted by ended.
    //         VideoEvent(eventType: VideoEventType.completed),
    //         VideoEvent(eventType: VideoEventType.bufferingEnd),
    //       ]),
    //     );
    //   });

    //   test('playback start', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[IsPlayingStateEvent(isPlaying: true)],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(
    //           eventType: VideoEventType.isPlayingStateUpdate,
    //           isPlaying: true,
    //         ),
    //       ]),
    //     );
    //   });

    //   test('playback stop', () async {
    //     final Stream<VideoEvent> eventStream = mockPlayerEmitingEvents(
    //       <PlatformVideoEvent>[IsPlayingStateEvent(isPlaying: false)],
    //     );

    //     expect(
    //       eventStream,
    //       emitsInOrder(<dynamic>[
    //         VideoEvent(
    //           eventType: VideoEventType.isPlayingStateUpdate,
    //           isPlaying: false,
    //         ),
    //       ]),
    //     );
    //   });
    // });

    group('audio tracks', () {
      test('isAudioTrackSupportAvailable returns true', () {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(playerId: 1);

        expect(player.isAudioTrackSupportAvailable(), true);
      });

      // test('getAudioTracks returns empty list when no tracks', () async {
      //   final (OhosVideoPlayer player, _, MockVideoPlayerInstanceApi api) =
      //       setUpMockPlayer(playerId: 1);
      //   when(api.getAudioTracks()).thenAnswer(
      //     (_) async => NativeAudioTrackData(
      //       exoPlayerTracks: <ExoPlayerAudioTrackData>[],
      //     ),
      //   );

      //   final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

      //   expect(tracks, isEmpty);
      //   verify(api.getAudioTracks());
      // });

      // test(
      //   'getAudioTracks converts native tracks to VideoAudioTrack',
      //   () async {
      //     final (OhosVideoPlayer player, _, MockVideoPlayerInstanceApi api) =
      //         setUpMockPlayer(playerId: 1);
      //     when(api.getAudioTracks()).thenAnswer(
      //       (_) async => NativeAudioTrackData(
      //         exoPlayerTracks: <ExoPlayerAudioTrackData>[
      //           ExoPlayerAudioTrackData(
      //             groupIndex: 0,
      //             trackIndex: 1,
      //             label: 'English',
      //             language: 'en',
      //             isSelected: true,
      //             bitrate: 128000,
      //             sampleRate: 44100,
      //             channelCount: 2,
      //             codec: 'mp4a.40.2',
      //           ),
      //           ExoPlayerAudioTrackData(
      //             groupIndex: 0,
      //             trackIndex: 2,
      //             label: 'Spanish',
      //             language: 'es',
      //             isSelected: false,
      //             bitrate: 128000,
      //             sampleRate: 44100,
      //             channelCount: 2,
      //             codec: 'mp4a.40.2',
      //           ),
      //         ],
      //       ),
      //     );

      //     final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

      //     expect(tracks.length, 2);

      //     expect(tracks[0].id, '0_1');
      //     expect(tracks[0].label, 'English');
      //     expect(tracks[0].language, 'en');
      //     expect(tracks[0].isSelected, true);
      //     expect(tracks[0].bitrate, 128000);
      //     expect(tracks[0].sampleRate, 44100);
      //     expect(tracks[0].channelCount, 2);
      //     expect(tracks[0].codec, 'mp4a.40.2');

      //     expect(tracks[1].id, '0_2');
      //     expect(tracks[1].label, 'Spanish');
      //     expect(tracks[1].language, 'es');
      //     expect(tracks[1].isSelected, false);
      //   },
      // );

      // test('getAudioTracks handles null exoPlayerTracks', () async {
      //   final (OhosVideoPlayer player, _, MockVideoPlayerInstanceApi api) =
      //       setUpMockPlayer(playerId: 1);
      //   when(
      //     api.getAudioTracks(),
      //   ).thenAnswer((_) async => NativeAudioTrackData());

      //   final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

      //   expect(tracks, isEmpty);
      // });

      // test('selectAudioTrack parses trackId and calls API', () async {
      //   final (
      //     OhosVideoPlayer player,
      //     _,
      //     MockVideoPlayerInstanceApi api,
      //     StreamController<PlatformVideoEvent> streamController,
      //   ) = setUpMockPlayerWithStream(
      //     playerId: 1,
      //   );
      //   when(api.selectAudioTrack(2, 3)).thenAnswer((_) async {});

      //   // Start the selection and immediately send the track changed event
      //   final Future<void> selectionFuture = player.selectAudioTrack(1, '2_3');
      //   streamController.add(AudioTrackChangedEvent());
      //   await selectionFuture;

      //   verify(api.selectAudioTrack(2, 3));
      // });

      test('selectAudioTrack throws on invalid trackId format', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(playerId: 1);

        expect(
          () => player.selectAudioTrack(1, 'invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('selectAudioTrack throws on trackId with too many parts', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(playerId: 1);

        expect(
          () => player.selectAudioTrack(1, '1_2_3'),
          throwsA(isA<ArgumentError>()),
        );
      });

      // test('selectAudioTrack completes on AudioTrackChangedEvent', () async {
      //   final (
      //     OhosVideoPlayer player,
      //     _,
      //     MockVideoPlayerInstanceApi api,
      //     StreamController<PlatformVideoEvent> streamController,
      //   ) = setUpMockPlayerWithStream(
      //     playerId: 1,
      //   );
      //   when(api.selectAudioTrack(0, 1)).thenAnswer((_) async {});

      //   // Start selection
      //   final Future<void> selectionFuture = player.selectAudioTrack(1, '0_1');

      //   // Simulate the track changed event from ExoPlayer
      //   streamController.add(AudioTrackChangedEvent());

      //   // Should complete without timeout
      //   await selectionFuture;

      //   verify(api.selectAudioTrack(0, 1));
      // });
    });

    group('video tracks', () {
      // ---- OHOS 已实现、经简单替换后即可运行的用例 ----

      // 桥接 OHOS EventChannel 与测试可控的事件流。
      // OHOS 的 selectVideoTrack 依赖外部订阅 videoEventsFor(textureId) 来
      // 接收 videoTrackChanged 事件并完成等待；这里用 StreamController 桥接，
      // 测试可在任意时机 add 事件，从而精确控制 completer 的完成时机（避免 5s 超时）。
      //
      // 返回 controller：测试需先调用 controller.stream 以激活订阅，
      // 再在需要的时机向 controller.add(eventMap) 下发事件。
      StreamController<Object?> mockVideoTrackStream() {
        final StreamController<Object?> controller = StreamController<Object?>();
        final EventChannel eventChannel = EventChannel(
          'flutter.io/videoPlayer/videoEvents1',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink sink) {
              controller.stream.listen(
                (Object? event) => sink.success(event),
                onError: sink.error,
                onDone: sink.endOfStream,
              );
            },
          ),
        );
        return controller;
      }

      test('isVideoTrackSupportAvailable returns true', () {
        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);

        expect(player.isVideoTrackSupportAvailable(), true);
      });

      test('getVideoTracks returns empty list when no tracks', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.getVideoTracks(1)).thenAnswer((_) async => <Object?>[]);

        final List<VideoTrack> tracks = await player.getVideoTracks(1);

        expect(tracks, isEmpty);
      });

      test('getVideoTracks converts native tracks to VideoTrack', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        // OHOS 通过 List<Object?>（弱类型 Map）传递视频轨道数据，
        // 字段与 Android 的 ExoPlayerVideoTrackData 一一对应。
        when(api.getVideoTracks(1)).thenAnswer(
          (_) async => <Object?>[
            <String, Object?>{
              'id': '0_0',
              'label': '1080p',
              'isSelected': true,
              'bitrate': 5000000,
              'width': 1920,
              'height': 1080,
              'frameRate': 30.0,
              'codec': 'avc1.64001f',
            },
            <String, Object?>{
              'id': '0_1',
              'label': '720p',
              'isSelected': false,
              'bitrate': 2500000,
              'width': 1280,
              'height': 720,
              'frameRate': 30.0,
              'codec': 'avc1.64001f',
            },
          ],
        );

        final List<VideoTrack> tracks = await player.getVideoTracks(1);

        expect(tracks.length, 2);

        expect(tracks[0].id, '0_0');
        expect(tracks[0].label, '1080p');
        expect(tracks[0].isSelected, true);
        expect(tracks[0].bitrate, 5000000);
        expect(tracks[0].width, 1920);
        expect(tracks[0].height, 1080);
        expect(tracks[0].frameRate, 30.0);
        expect(tracks[0].codec, 'avc1.64001f');

        expect(tracks[1].id, '0_1');
        expect(tracks[1].label, '720p');
        expect(tracks[1].isSelected, false);
        expect(tracks[1].bitrate, 2500000);
        expect(tracks[1].width, 1280);
        expect(tracks[1].height, 720);
      });

      test('getVideoTracks handles null exoPlayerTracks', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.getVideoTracks(1)).thenAnswer((_) async => <Object?>[]);

        final List<VideoTrack> tracks = await player.getVideoTracks(1);

        expect(tracks, isEmpty);
      });

      test('selectVideoTrack with null clears override (auto quality)', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.enableAutoVideoQuality(1)).thenAnswer((_) async {});

        await player.selectVideoTrack(1, null);

        verify(api.enableAutoVideoQuality(1));
      });

      test('selectVideoTrack parses track id and calls API', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.selectVideoTrack(1, 0, 2)).thenAnswer((_) async {});
        // 激活事件流并下发所选轨道的切换事件，使 selectVideoTrack 的
        // Completer 提前完成（避免 5s 超时）。
        final StreamController<Object?> streamController = mockVideoTrackStream();
        player.videoEventsFor(1).listen((_) {});

        const track = VideoTrack(id: '0_2', isSelected: false);
        final Future<void> selectionFuture = player.selectVideoTrack(1, track);
        // 等原生调用完成（微任务）后下发事件，再等待 completer 完成。
        await Future<void>.delayed(Duration.zero);
        streamController.add(<String, Object?>{
          'event': 'videoTrackChanged',
          'selectedTrackId': '0_2',
        });
        await selectionFuture;

        verify(api.selectVideoTrack(1, 0, 2));
      });

      test('selectVideoTrack throws on invalid track id format', () async {
        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);

        const track = VideoTrack(id: 'invalid', isSelected: false);
        expect(() => player.selectVideoTrack(1, track), throwsA(isA<ArgumentError>()));
      });

      test('selectVideoTrack throws on track id with too many parts', () async {
        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);

        const track = VideoTrack(id: '1_2_3', isSelected: false);
        expect(() => player.selectVideoTrack(1, track), throwsA(isA<ArgumentError>()));
      });

      test('selectVideoTrack throws on non-numeric track id parts', () async {
        final (OhosVideoPlayer player, _) = setUpMockPlayer(playerId: 1);

        const track = VideoTrack(id: 'zero_2', isSelected: false);
        expect(() => player.selectVideoTrack(1, track), throwsA(isA<ArgumentError>()));
      });

      // ---- OHOS 无法实现的用例（依赖 Android 特有语义，注释保留） ----

      test('getVideoTracks generates label from resolution if not provided', () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        // OHOS 与 Android 行为一致：label 缺失时根据分辨率生成（"1080p"）。
        when(api.getVideoTracks(1)).thenAnswer(
          (_) async => <Object?>[
            <String, Object?>{
              'id': '0_0',
              'isSelected': true,
              'width': 1920,
              'height': 1080,
            },
          ],
        );

        final List<VideoTrack> tracks = await player.getVideoTracks(1);

        expect(tracks.length, 1);
        expect(tracks[0].label, '1080p');
      });

      // ---- OHOS 已实现对应机制、可运行的用例（与 Android 对齐） ----

      testWidgets('selectVideoTrack logs when track change event times out', (
        WidgetTester tester,
      ) async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        // 原生 selectVideoTrack 立即返回，但不触发任何 videoTrackChanged
        // 事件，因此 completer 会等到 5s 超时并打印 debugPrint 日志。
        when(api.selectVideoTrack(1, 0, 2)).thenAnswer((_) async {});

        const track = VideoTrack(id: '0_2', isSelected: false);
        final logMessages = <String>[];
        final DebugPrintCallback oldDebugPrint = debugPrint;
        var completed = false;

        try {
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) {
              logMessages.add(message);
            }
          };

          unawaited(
            player.selectVideoTrack(1, track).then((_) {
              completed = true;
            }),
          );

          await tester.pump();
          expect(logMessages, isEmpty);

          // 推进虚拟时间跨过 5s 超时阈值。
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();

          expect(completed, isTrue);
          expect(
            logMessages,
            contains(
              'Timed out waiting for video track selection event for track '
              '"0_2".',
            ),
          );
        } finally {
          debugPrint = oldDebugPrint;
        }
      });

      test('concurrent selectVideoTrack calls do not clobber each other', () async {
        // 语义对齐：验证并发调用时，较早调用失败后其 finally 不会清空
        // 较晚调用仍在等待的 completer/expected-id（OHOS 用 identical 判断
        // 字段归属，与 Android 一致）。
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        // 让 call 1 快速失败，从而在 call 2 仍在等待时执行其 finally。
        when(api.selectVideoTrack(1, 0, 1))
            .thenAnswer((_) async => throw StateError('boom'));
        when(api.selectVideoTrack(1, 0, 2)).thenAnswer((_) async {});

        const trackA = VideoTrack(id: '0_1', isSelected: false);
        const trackB = VideoTrack(id: '0_2', isSelected: false);

        final StreamController<Object?> streamController = mockVideoTrackStream();
        player.videoEventsFor(1).listen((_) {});

        // 同时启动两个调用，并把错误匹配器先绑定到 call 1，避免其
        // StateError 被当作未处理的异步错误上报。
        final Future<void> firstFuture = player.selectVideoTrack(1, trackA);
        final Future<void> firstAssertion = expectLater(
          firstFuture,
          throwsA(isA<StateError>()),
        );
        final Future<void> secondFuture = player.selectVideoTrack(1, trackB);

        // 让微任务（被 await 的原生调用）settle，使 call 1 的 finally 先执行。
        await Future<void>.delayed(Duration.zero);

        // 为 call 2 下发匹配事件。
        streamController.add(<String, Object?>{
          'event': 'videoTrackChanged',
          'selectedTrackId': '0_2',
        });

        // call 2 应在匹配事件到达时立即完成。
        await secondFuture;
        await firstAssertion;

        verify(api.selectVideoTrack(1, 0, 1));
        verify(api.selectVideoTrack(1, 0, 2));
      });

      test('selectVideoTrack(null) resolves without waiting for a track event', () async {
        // 语义对齐：验证 auto/自适应选择自行完成（清除 override），
        // 不依赖任何 videoTrackChanged 事件；若依赖事件，此处会挂起至超时。
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.enableAutoVideoQuality(1)).thenAnswer((_) async {});

        await player
            .selectVideoTrack(1, null)
            .timeout(
              const Duration(seconds: 1),
              onTimeout: () =>
                  fail('selectVideoTrack(null) should not wait for a track event'),
            );

        verify(api.enableAutoVideoQuality(1));
      });

      test('consecutive selectVideoTrack calls both complete', () async {
        // 语义对齐：验证两次连续调用都正确路由到原生并完成。
        // OHOS 的 selectVideoTrack 会等待 videoTrackChanged 事件，
        // 每次调用前需激活事件流并下发对应轨道的切换事件，避免 5s 超时。
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.selectVideoTrack(1, 0, 1)).thenAnswer((_) async {});
        when(api.selectVideoTrack(1, 0, 2)).thenAnswer((_) async {});

        const trackA = VideoTrack(id: '0_1', isSelected: false);
        const trackB = VideoTrack(id: '0_2', isSelected: false);

        final StreamController<Object?> streamController = mockVideoTrackStream();
        player.videoEventsFor(1).listen((_) {});

        final Future<void> firstFuture = player.selectVideoTrack(1, trackA);
        await Future<void>.delayed(Duration.zero);
        streamController.add(<String, Object?>{
          'event': 'videoTrackChanged',
          'selectedTrackId': '0_1',
        });
        await firstFuture;

        final Future<void> secondFuture = player.selectVideoTrack(1, trackB);
        await Future<void>.delayed(Duration.zero);
        streamController.add(<String, Object?>{
          'event': 'videoTrackChanged',
          'selectedTrackId': '0_2',
        });
        await secondFuture;

        verify(api.selectVideoTrack(1, 0, 1));
        verify(api.selectVideoTrack(1, 0, 2));
      });

      test("selectVideoTrack(null) is not completed by a prior selection's event",
          () async {
        // 语义对齐：验证先前显式选择的切换事件不会误匹配后续 auto 选择，
        // 且 auto 选择自身不等待任何事件（立即完成）。
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) = setUpMockPlayer(
          playerId: 1,
        );
        when(api.selectVideoTrack(1, 0, 1)).thenAnswer((_) async {});
        when(api.enableAutoVideoQuality(1)).thenAnswer((_) async {});

        const trackA = VideoTrack(id: '0_1', isSelected: false);

        final StreamController<Object?> streamController = mockVideoTrackStream();
        player.videoEventsFor(1).listen((_) {});

        // 启动一个尚未完成（事件未到达）的显式选择。
        var explicitCompleted = false;
        final Future<void> explicitFuture = player.selectVideoTrack(1, trackA).then((_) {
          explicitCompleted = true;
        });
        await Future<void>.delayed(Duration.zero);

        // 切换到 auto：应自行完成，不等待任何事件。
        await player.selectVideoTrack(1, null);
        verify(api.enableAutoVideoQuality(1));

        // 下发较早的显式选择（'0_1'）的切换事件，它只应完成该显式 future，
        // 不会误触发已完成的 auto 调用。
        streamController.add(<String, Object?>{
          'event': 'videoTrackChanged',
          'selectedTrackId': '0_1',
        });
        await explicitFuture;

        expect(explicitCompleted, isTrue);
        verify(api.selectVideoTrack(1, 0, 1));
      });
    });
  });
}
