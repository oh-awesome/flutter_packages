// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.

// OhosVideoPlayer 异常、边界与并发场景的单元测试。
// 复用 ohos_video_player_test.dart 生成的 MockOhosVideoPlayerApi。

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player_ohos/src/messages.g.dart';
import 'package:video_player_ohos/src/video_player_ohos_channel.dart';
import 'package:video_player_ohos/video_player_ohos.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'ohos_video_player_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  provideDummy<Future<void>>(Future<void>.value());

  (OhosVideoPlayer, MockOhosVideoPlayerApi) setUpMockPlayer() {
    final api = MockOhosVideoPlayerApi();
    final player = OhosVideoPlayer(pluginApi: api);
    return (player, api);
  }

  group('exception scenarios', () {
    test('create propagates platform exception from native side', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();
      when(api.create(any)).thenThrow(
        PlatformException(code: 'create_failed', message: 'native error'),
      );

      await expectLater(
        player.create(
          DataSource(sourceType: DataSourceType.network, uri: 'https://x.mp4'),
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('create with file source and null uri throws', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();
      when(api.create(any)).thenAnswer((_) async => 1);

      // DataSourceType.file 且 uri 为 null 时，内部 uri! 抛出空指针检查错误。
      await expectLater(
        player.create(DataSource(sourceType: DataSourceType.file)),
        throwsA(isA<TypeError>()),
      );
      verifyNever(api.create(any));
    });

    testWidgets('create with file path converts to fd uri via channel', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();
      when(api.create(any)).thenAnswer((_) async => 1);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        VideoPlayerOhosChannel.channel,
        (MethodCall call) async {
          expect(call.method, 'getFileFdByPath');
          expect(call.arguments['filePath'], '/data/local/tmp/a.mp4');
          return 42;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          VideoPlayerOhosChannel.channel,
          null,
        );
      });

      final int? playerId = await player.create(
        DataSource(
          sourceType: DataSourceType.file,
          uri: '/data/local/tmp/a.mp4',
        ),
      );

      expect(playerId, 1);
      final CreateMessage message =
          verify(api.create(captureAny)).captured.single as CreateMessage;
      expect(message.uri, 'fd://42');
    });

    testWidgets('create with file path when channel returns -1 keeps fd://-1', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();
      when(api.create(any)).thenAnswer((_) async => 1);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        VideoPlayerOhosChannel.channel,
        (MethodCall call) async => -1,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          VideoPlayerOhosChannel.channel,
          null,
        );
      });

      await player.create(
        DataSource(sourceType: DataSourceType.file, uri: '/missing.mp4'),
      );

      final CreateMessage message =
          verify(api.create(captureAny)).captured.single as CreateMessage;
      expect(message.uri, 'fd://-1');
    });
  });

  group('event stream decoding', () {
    const textureId = 7;

    // 注册原生事件流 mock，返回可注入事件的 sink。
    Future<MockStreamHandlerEventSink?> Function() registerStreamMock(
      WidgetTester tester,
    ) {
      MockStreamHandlerEventSink? sink;
      final EventChannel channel = EventChannel(
        'flutter.io/videoPlayer/videoEvents$textureId',
      );
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (Object? arguments, MockStreamHandlerEventSink events) {
            sink = events;
          },
        ),
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockStreamHandler(
          channel,
          null,
        );
      });
      return () async => sink;
    }

    testWidgets('unknown event maps to VideoEventType.unknown', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, _) = setUpMockPlayer();
      final getSink = registerStreamMock(tester);

      final List<VideoEvent> events = <VideoEvent>[];
      player.videoEventsFor(textureId).listen(events.add);
      await tester.pump(const Duration(milliseconds: 100));
      (await getSink())!.success(<String, Object>{'event': 'somethingOdd'});
      await tester.pump(const Duration(milliseconds: 100));

      expect(events.single.eventType, VideoEventType.unknown);
    });

    testWidgets('initialized event maps duration, size and rotation', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, _) = setUpMockPlayer();
      final getSink = registerStreamMock(tester);

      final List<VideoEvent> events = <VideoEvent>[];
      player.videoEventsFor(textureId).listen(events.add);
      await tester.pump(const Duration(milliseconds: 100));
      (await getSink())!.success(<String, Object>{
        'event': 'initialized',
        'duration': 60000,
        'width': 16,
        'height': 9,
        'rotationCorrection': 90,
      });
      await tester.pump(const Duration(milliseconds: 100));

      final VideoEvent event = events.single;
      expect(event.eventType, VideoEventType.initialized);
      expect(event.duration, const Duration(minutes: 1));
      expect(event.size, const Size(16, 9));
      expect(event.rotationCorrection, 90);
    });

    testWidgets('bufferingUpdate event maps buffered ranges', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, _) = setUpMockPlayer();
      final getSink = registerStreamMock(tester);

      final List<VideoEvent> events = <VideoEvent>[];
      player.videoEventsFor(textureId).listen(events.add);
      await tester.pump(const Duration(milliseconds: 100));
      (await getSink())!.success(<String, Object>{
        'event': 'bufferingUpdate',
        'values': <List<int>>[
          <int>[0, 500],
          <int>[100, 900],
        ],
      });
      await tester.pump(const Duration(milliseconds: 100));

      final VideoEvent event = events.single;
      expect(event.eventType, VideoEventType.bufferingUpdate);
      expect(event.buffered!.length, 2);
      expect(event.buffered![0].start, Duration.zero);
      expect(event.buffered![0].end, const Duration(milliseconds: 500));
      expect(event.buffered![1].end, const Duration(milliseconds: 900));
    });

    testWidgets('isPlayingStateUpdate event maps isPlaying flag', (
      WidgetTester tester,
    ) async {
      final (OhosVideoPlayer player, _) = setUpMockPlayer();
      final getSink = registerStreamMock(tester);

      final List<VideoEvent> events = <VideoEvent>[];
      player.videoEventsFor(textureId).listen(events.add);
      await tester.pump(const Duration(milliseconds: 100));
      (await getSink())!.success(<String, Object>{
        'event': 'isPlayingStateUpdate',
        'isPlaying': true,
      });
      await tester.pump(const Duration(milliseconds: 100));

      final VideoEvent event = events.single;
      expect(event.eventType, VideoEventType.isPlayingStateUpdate);
      expect(event.isPlaying, isTrue);
    });
  });

  group('boundary scenarios', () {
    test(
      'getAudioTracks with negative playerId returns empty without api call',
      () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer();

        expect(await player.getAudioTracks(-1), isEmpty);
        verifyNever(api.getAudioTracks(-1));
      },
    );

    test(
      'getVideoTracks with negative playerId returns empty without api call',
      () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer();

        expect(await player.getVideoTracks(-1), isEmpty);
        verifyNever(api.getVideoTracks(-1));
      },
    );

    test('selectAudioTrack with negative playerId is a no-op', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();

      await player.selectAudioTrack(-1, '0_1');
      verifyNever(api.selectAudioTrack(-1, 0, 1));
    });

    test('selectVideoTrack with negative playerId is a no-op', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();

      await player.selectVideoTrack(-1, null);
      verifyNever(api.enableAutoVideoQuality(-1));
    });
  });

  group('concurrency scenarios', () {
    test(
      'concurrent control commands on same player are all forwarded',
      () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer();
        const playerId = 3;
        when(api.play(any)).thenAnswer((_) async {});
        when(api.pause(any)).thenAnswer((_) async {});
        when(api.seekTo(any, any)).thenAnswer((_) async {});
        when(api.setVolume(any, any)).thenAnswer((_) async {});

        await Future.wait(<Future<void>>[
          player.play(playerId),
          player.pause(playerId),
          player.seekTo(playerId, const Duration(seconds: 1)),
          player.setVolume(playerId, 0.5),
        ]);

        verify(api.play(playerId)).called(1);
        verify(api.pause(playerId)).called(1);
        verify(api.seekTo(playerId, 1000)).called(1);
        verify(api.setVolume(playerId, 0.5)).called(1);
      },
    );

    test(
      'concurrent getVideoTracks and selectVideoTrack complete independently',
      () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer();
        const playerId = 2;
        when(api.getVideoTracks(any)).thenAnswer(
          (_) async => <Object?>[
            <String, Object?>{
              'id': '0_1',
              'isSelected': false,
              'width': 1280,
              'height': 720,
            },
          ],
        );
        when(api.selectVideoTrack(any, any, any)).thenAnswer((_) async {});

        final Future<List<VideoTrack>> tracksFuture = player.getVideoTracks(
          playerId,
        );
        final Future<void> selectFuture = player.selectVideoTrack(
          playerId,
          const VideoTrack(id: '0_1', isSelected: false),
        );

        final List<VideoTrack> tracks = await tracksFuture;
        await selectFuture;

        // 同时验证 label 缺失时按分辨率回退生成（与 Android 行为一致）。
        expect(tracks.single.label, '720p');
        verify(api.selectVideoTrack(playerId, 0, 1)).called(1);
      },
    );

    test('rapid sequential create and dispose cycles all complete', () async {
      final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
          setUpMockPlayer();
      when(api.create(any)).thenAnswer((_) async => 1);
      when(api.dispose(any)).thenAnswer((_) async {});

      const cycles = 5;
      final List<Future<void>> futures = <Future<void>>[];
      for (var i = 0; i < cycles; i++) {
        futures.add(
          player
              .create(
                DataSource(
                  sourceType: DataSourceType.network,
                  uri: 'https://example.com/c$i.mp4',
                ),
              )
              .then((_) => player.dispose(i)),
        );
      }
      await Future.wait(futures);

      verify(api.create(any)).called(cycles);
      verify(api.dispose(any)).called(cycles);
    });

    test(
      'parallel creates for different sources keep messages independent',
      () async {
        final (OhosVideoPlayer player, MockOhosVideoPlayerApi api) =
            setUpMockPlayer();
        when(api.create(any)).thenAnswer((_) async => 1);

        await Future.wait(<Future<int?>>[
          player.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://a.mp4',
            ),
          ),
          player.create(
            DataSource(sourceType: DataSourceType.asset, asset: 'videos/b.mp4'),
          ),
        ]);

        final List<CreateMessage> messages =
            verify(api.create(captureAny)).captured.cast<CreateMessage>();
        expect(messages.length, 2);
        expect(
          messages.map((CreateMessage m) => m.uri).whereType<String>().toSet(),
          <String>{'https://a.mp4'},
        );
        expect(
          messages
              .map((CreateMessage m) => m.asset)
              .whereType<String>()
              .toSet(),
          <String>{'videos/b.mp4'},
        );
      },
    );
  });
}
