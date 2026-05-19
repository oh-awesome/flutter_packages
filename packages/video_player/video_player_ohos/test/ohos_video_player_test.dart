// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_ohos/src/messages.g.dart';
import 'package:video_player_ohos/video_player_ohos.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const String _apiPrefix =
    'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.';
const MethodChannel _fileChannel = MethodChannel(
  'plugins.flutter.io/video_player_ohos',
);

BasicMessageChannel<Object?> _apiChannel(String method) {
  return BasicMessageChannel<Object?>(
    '$_apiPrefix$method',
    OhosVideoPlayerApi.codec,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestDefaultBinaryMessenger messenger;
  late OhosVideoPlayer player;
  late Set<String> mockedApiMethods;
  late bool mockedFileChannel;
  late Set<int> mockedEventPlayerIds;

  setUp(() {
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    player = OhosVideoPlayer();
    mockedApiMethods = <String>{};
    mockedFileChannel = false;
    mockedEventPlayerIds = <int>{};
  });

  tearDown(() {
    for (final String method in mockedApiMethods) {
      messenger.setMockDecodedMessageHandler<Object?>(
        _apiChannel(method),
        null,
      );
    }
    if (mockedFileChannel) {
      messenger.setMockMethodCallHandler(_fileChannel, null);
    }
    for (final int playerId in mockedEventPlayerIds) {
      messenger.setMockStreamHandler(
        EventChannel('flutter.io/videoPlayer/videoEvents$playerId'),
        null,
      );
    }
  });

  Future<void> mockVoidReply(
    String method, {
    void Function(Object? message)? onMessage,
  }) async {
    mockedApiMethods.add(method);
    messenger.setMockDecodedMessageHandler<Object?>(_apiChannel(method), (
      Object? message,
    ) async {
      onMessage?.call(message);
      return <Object?>[];
    });
  }

  Future<void> mockValueReply(
    String method,
    Object? reply, {
    void Function(Object? message)? onMessage,
  }) async {
    mockedApiMethods.add(method);
    messenger.setMockDecodedMessageHandler<Object?>(_apiChannel(method), (
      Object? message,
    ) async {
      onMessage?.call(message);
      return <Object?>[reply];
    });
  }

  Future<(int?, CreateMessage)> captureCreate(
    Future<int?> Function() invoke,
  ) async {
    CreateMessage? captured;
    await mockValueReply(
      'create',
      2,
      onMessage: (Object? message) {
        final List<Object?> args = message! as List<Object?>;
        captured = args.single! as CreateMessage;
      },
    );
    final int? playerId = await invoke();
    return (playerId, captured!);
  }

  void mockFileFd(int fd, {List<MethodCall>? calls}) {
    mockedFileChannel = true;
    messenger.setMockMethodCallHandler(_fileChannel, (MethodCall call) async {
      calls?.add(call);
      if (call.method == 'getFileFdByPath') {
        return fd;
      }
      fail('Unexpected file channel call: ${call.method}');
    });
  }

  Stream<VideoEvent> mockVideoEventsFor(
    int playerId,
    List<Map<String, Object?>> events,
  ) {
    mockedEventPlayerIds.add(playerId);
    messenger.setMockStreamHandler(
      EventChannel('flutter.io/videoPlayer/videoEvents$playerId'),
      MockStreamHandler.inline(
        onListen: (_, MockStreamHandlerEventSink sink) {
          for (final Map<String, Object?> event in events) {
            sink.success(event);
          }
          sink.endOfStream();
        },
      ),
    );
    return player.videoEventsFor(playerId);
  }

  test('registration', () async {
    OhosVideoPlayer.registerWith();
    expect(VideoPlayerPlatform.instance, isA<OhosVideoPlayer>());
  });

  group('OhosVideoPlayer', () {
    test('init', () async {
      bool called = false;
      await mockVoidReply(
        'initialize',
        onMessage: (Object? message) {
          called = true;
          expect(message, isNull);
        },
      );

      await player.init();

      expect(called, isTrue);
    });

    test('dispose', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'dispose',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.dispose(1);

      expect(capturedMessage, <Object?>[1]);
    });

    test('create with asset', () async {
      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.asset,
            asset: 'someAsset',
            package: 'somePackage',
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.asset, 'someAsset');
      expect(message.packageName, 'somePackage');
      expect(message.uri, isNull);
      expect(message.httpHeaders, <String?, String?>{});
      expect(message.viewType, PlatformVideoViewType.textureView);
      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test('create with network', () async {
      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com',
            formatHint: VideoFormat.dash,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.uri, 'https://example.com');
      expect(message.formatHint, 'dash');
      expect(message.httpHeaders, <String?, String?>{});
      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test('create with network passes formatHint correctly', () async {
      final (_, CreateMessage dashMessage) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.mpd',
            formatHint: VideoFormat.dash,
          ),
        ),
      );
      expect(dashMessage.formatHint, 'dash');

      final (_, CreateMessage hlsMessage) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.m3u8',
            formatHint: VideoFormat.hls,
          ),
        ),
      );
      expect(hlsMessage.formatHint, 'hls');

      final (_, CreateMessage ssMessage) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.ism',
            formatHint: VideoFormat.ss,
          ),
        ),
      );
      expect(ssMessage.formatHint, 'ss');
    });

    test('create with network handles null formatHint', () async {
      final (_, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com',
          ),
        ),
      );

      expect(message.formatHint, isNull);
    });

    test('create with network passes headers', () async {
      const headers = <String, String>{'Authorization': 'Bearer token'};
      final (_, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com',
            httpHeaders: headers,
          ),
        ),
      );

      expect(message.httpHeaders, <String?, String?>{
        'Authorization': 'Bearer token',
      });
    });

    test('create with network sets a default user agent', () async {
      final (_, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com',
            httpHeaders: <String, String>{},
          ),
        ),
      );

      expect(message.httpHeaders.containsKey('User-Agent'), isFalse);
    });

    test('create with network uses user agent from headers', () async {
      const headers = <String, String>{'User-Agent': 'Test User Agent'};
      final (_, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com',
            httpHeaders: headers,
          ),
        ),
      );

      expect(message.httpHeaders, <String?, String?>{
        'User-Agent': 'Test User Agent',
      });
    });

    test('create with file', () async {
      final List<MethodCall> calls = <MethodCall>[];
      mockFileFd(42, calls: calls);

      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(sourceType: DataSourceType.file, uri: 'file:///foo/bar'),
        ),
      );

      expect(playerId, 2);
      expect(calls.single.method, 'getFileFdByPath');
      expect(calls.single.arguments, <String, String>{
        'filePath': 'file:///foo/bar',
      });
      expect(message.uri, 'fd://42');
      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test('create with file passes headers', () async {
      mockFileFd(7);

      const headers = <String, String>{'Authorization': 'Bearer token'};
      final (_, CreateMessage message) = await captureCreate(
        () => player.create(
          DataSource(
            sourceType: DataSourceType.file,
            uri: 'file:///foo/bar',
            httpHeaders: headers,
          ),
        ),
      );

      expect(message.uri, 'fd://7');
      expect(message.httpHeaders, <String?, String?>{
        'Authorization': 'Bearer token',
      });
    });

    group('create error handling', () {
      test('create throws PlatformException on handler exception', () async {
        mockedApiMethods.add('create');
        messenger.setMockDecodedMessageHandler<Object?>(_apiChannel('create'), (
          Object? message,
        ) async {
          throw PlatformException(
            code: 'channel-error',
            message: 'Unable to establish connection',
          );
        });

        await expectLater(
          player.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
            ),
          ),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException e) => e.code,
              'code',
              'channel-error',
            ),
          ),
        );
      });

      test('create throws PlatformException on channel-error', () async {
        mockedApiMethods.add('create');
        messenger.setMockDecodedMessageHandler<Object?>(
          _apiChannel('create'),
          (Object? message) async => null,
        );

        await expectLater(
          player.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
            ),
          ),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException e) => e.code,
              'code',
              'channel-error',
            ),
          ),
        );
      });

      test('create throws PlatformException on null result', () async {
        mockedApiMethods.add('create');
        messenger.setMockDecodedMessageHandler<Object?>(
          _apiChannel('create'),
          (Object? message) async => <Object?>[null],
        );

        await expectLater(
          player.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
            ),
          ),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException e) => e.code,
              'code',
              'null-error',
            ),
          ),
        );
      });

      test('create throws PlatformException on host error reply', () async {
        mockedApiMethods.add('create');
        messenger.setMockDecodedMessageHandler<Object?>(
          _apiChannel('create'),
          (Object? message) async => <Object?>[
            'create-failed',
            'Failed to create player',
            null,
          ],
        );

        await expectLater(
          player.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
            ),
          ),
          throwsA(
            isA<PlatformException>()
                .having(
                  (PlatformException e) => e.code,
                  'code',
                  'create-failed',
                )
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  'Failed to create player',
                ),
          ),
        );
      });

      test('create throws TypeError when file uri is null', () async {
        await expectLater(
          player.create(DataSource(sourceType: DataSourceType.file)),
          throwsA(isA<TypeError>()),
        );
      });

      test('create passes null fields and surfaces host error', () async {
        mockedApiMethods.add('create');
        messenger.setMockDecodedMessageHandler<Object?>(_apiChannel('create'), (
          Object? message,
        ) async {
          final List<Object?> args = message! as List<Object?>;
          final CreateMessage msg = args.single! as CreateMessage;
          expect(msg.uri, isNull);
          return <Object?>['invalid-argument', 'uri is null', null];
        });

        await expectLater(
          player.create(DataSource(sourceType: DataSourceType.network)),
          throwsA(
            isA<PlatformException>().having(
              (PlatformException e) => e.code,
              'code',
              'invalid-argument',
            ),
          ),
        );
      });
    });

    test('createWithOptions with asset', () async {
      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.asset,
              asset: 'someAsset',
              package: 'somePackage',
            ),
            viewType: VideoViewType.textureView,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.asset, 'someAsset');
      expect(message.packageName, 'somePackage');
    });

    test('createWithOptions with network', () async {
      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
              formatHint: VideoFormat.dash,
            ),
            viewType: VideoViewType.textureView,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.uri, 'https://example.com');
      expect(message.formatHint, 'dash');
    });

    test('createWithOptions with network passes headers', () async {
      const headers = <String, String>{'Authorization': 'Bearer token'};
      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com',
              httpHeaders: headers,
            ),
            viewType: VideoViewType.textureView,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.httpHeaders, <String?, String?>{
        'Authorization': 'Bearer token',
      });
    });

    test('createWithOptions with file', () async {
      mockFileFd(88);

      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.file,
              uri: 'file:///foo/bar',
            ),
            viewType: VideoViewType.textureView,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.uri, 'fd://88');
      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test('createWithOptions with file passes headers', () async {
      mockFileFd(66);

      const headers = <String, String>{'Authorization': 'Bearer token'};
      final (_, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.file,
              uri: 'file:///foo/bar',
              httpHeaders: headers,
            ),
            viewType: VideoViewType.textureView,
          ),
        ),
      );

      expect(message.uri, 'fd://66');
      expect(message.httpHeaders, <String?, String?>{
        'Authorization': 'Bearer token',
      });
    });

    test('createWithOptions with platform view', () async {
      mockFileFd(99);

      final (int? playerId, CreateMessage message) = await captureCreate(
        () => player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.file,
              uri: 'file:///foo/bar',
            ),
            viewType: VideoViewType.platformView,
          ),
        ),
      );

      expect(playerId, 2);
      expect(message.uri, 'fd://99');
      // OHOS currently falls back to the texture rendering path.
      expect(message.viewType, PlatformVideoViewType.textureView);
      expect(
        player.buildViewWithOptions(VideoViewOptions(playerId: playerId!)),
        isA<Texture>(),
      );
    });

    test('setLooping', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'setLooping',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.setLooping(1, true);

      expect(capturedMessage, <Object?>[1, true]);
    });

    test('play', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'play',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.play(1);

      expect(capturedMessage, <Object?>[1]);
    });

    test('pause', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'pause',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.pause(1);

      expect(capturedMessage, <Object?>[1]);
    });

    group('setMixWithOthers', () {
      test('passes true', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'setMixWithOthers',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.setMixWithOthers(true);

        expect(capturedMessage, <Object?>[true]);
      });

      test('passes false', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'setMixWithOthers',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.setMixWithOthers(false);

        expect(capturedMessage, <Object?>[false]);
      });
    });

    test('setVolume', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'setVolume',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.setVolume(1, 0.7);

      expect(capturedMessage, <Object?>[1, 0.7]);
    });

    test('setPlaybackSpeed', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'setPlaybackSpeed',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.setPlaybackSpeed(1, 1.5);

      expect(capturedMessage, <Object?>[1, 1.5]);
    });

    test('seekTo', () async {
      Object? capturedMessage;
      await mockVoidReply(
        'seekTo',
        onMessage: (Object? message) => capturedMessage = message,
      );

      await player.seekTo(1, const Duration(milliseconds: 12345));

      expect(capturedMessage, <Object?>[1, 12345]);
    });

    test('getPosition', () async {
      Object? capturedMessage;
      await mockValueReply(
        'position',
        12345,
        onMessage: (Object? message) => capturedMessage = message,
      );

      final Duration position = await player.getPosition(1);

      expect(capturedMessage, <Object?>[1]);
      expect(position, const Duration(milliseconds: 12345));
    });

    group('video events', () {
      test('initialize', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{
              'event': 'initialized',
              'duration': 98765,
              'width': 1920,
              'height': 1080,
              'rotationCorrection': 90,
            },
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>()
                .having(
                  (VideoEvent event) => event.eventType,
                  'eventType',
                  VideoEventType.initialized,
                )
                .having(
                  (VideoEvent event) => event.duration,
                  'duration',
                  const Duration(milliseconds: 98765),
                )
                .having(
                  (VideoEvent event) => event.size,
                  'size',
                  const Size(1920, 1080),
                )
                .having(
                  (VideoEvent event) => event.rotationCorrection,
                  'rotationCorrection',
                  90,
                ),
            emitsDone,
          ]),
        );
      });

      test('initialization triggers buffer update polling', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{
              'event': 'initialized',
              'duration': 98765,
              'width': 1920,
              'height': 1080,
              'rotationCorrection': 90,
            },
            <String, Object?>{
              'event': 'bufferingUpdate',
              'values': <List<int>>[
                <int>[0, 0],
              ],
            },
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.initialized,
            ),
            isA<VideoEvent>()
                .having(
                  (VideoEvent event) => event.eventType,
                  'eventType',
                  VideoEventType.bufferingUpdate,
                )
                .having(
                  (VideoEvent event) => event.buffered,
                  'buffered',
                  <DurationRange>[DurationRange(Duration.zero, Duration.zero)],
                ),
            emitsDone,
          ]),
        );
      });

      test('completed', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{'event': 'completed'},
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.completed,
            ),
            emitsDone,
          ]),
        );
      });

      test('buffering start', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{'event': 'bufferingStart'},
            <String, Object?>{
              'event': 'bufferingUpdate',
              'values': <List<int>>[
                <int>[0, 0],
              ],
            },
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingStart,
            ),
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingUpdate,
            ),
            emitsDone,
          ]),
        );
      });

      test('buffering end for ready', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{'event': 'bufferingStart'},
            <String, Object?>{'event': 'bufferingEnd'},
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingStart,
            ),
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingEnd,
            ),
            emitsDone,
          ]),
        );
      });

      test('buffering end for idle', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{'event': 'bufferingStart'},
            <String, Object?>{'event': 'bufferingEnd'},
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingStart,
            ),
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingEnd,
            ),
            emitsDone,
          ]),
        );
      });

      test('buffering end for ended', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{'event': 'bufferingStart'},
            <String, Object?>{'event': 'completed'},
            <String, Object?>{'event': 'bufferingEnd'},
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingStart,
            ),
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.completed,
            ),
            isA<VideoEvent>().having(
              (VideoEvent event) => event.eventType,
              'eventType',
              VideoEventType.bufferingEnd,
            ),
            emitsDone,
          ]),
        );
      });

      test('playback start', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{
              'event': 'isPlayingStateUpdate',
              'isPlaying': true,
            },
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>()
                .having(
                  (VideoEvent event) => event.eventType,
                  'eventType',
                  VideoEventType.isPlayingStateUpdate,
                )
                .having(
                  (VideoEvent event) => event.isPlaying,
                  'isPlaying',
                  isTrue,
                ),
            emitsDone,
          ]),
        );
      });

      test('playback stop', () async {
        expect(
          mockVideoEventsFor(1, <Map<String, Object?>>[
            <String, Object?>{
              'event': 'isPlayingStateUpdate',
              'isPlaying': false,
            },
          ]),
          emitsInOrder(<Object>[
            isA<VideoEvent>()
                .having(
                  (VideoEvent event) => event.eventType,
                  'eventType',
                  VideoEventType.isPlayingStateUpdate,
                )
                .having(
                  (VideoEvent event) => event.isPlaying,
                  'isPlaying',
                  isFalse,
                ),
            emitsDone,
          ]),
        );
      });
    });

    group('audio tracks', () {
      test('isAudioTrackSupportAvailable returns true', () {
        expect(player.isAudioTrackSupportAvailable(), isTrue);
      });

      test('getAudioTracks returns empty list when no tracks', () async {
        await mockValueReply('getAudioTracks', <Map<String?, Object?>>[]);

        final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

        expect(tracks, isEmpty);
      });

      test(
        'getAudioTracks converts native tracks to VideoAudioTrack',
        () async {
          await mockValueReply('getAudioTracks', <Map<String?, Object?>>[
            <String?, Object?>{
              'id': '1',
              'label': 'English',
              'language': 'en',
              'isSelected': true,
              'bitrate': 128000,
              'sampleRate': 44100,
              'channelCount': 2,
              'codec': 'mp4a.40.2',
            },
            <String?, Object?>{
              'id': '2',
              'label': 'Spanish',
              'language': 'es',
              'isSelected': false,
              'bitrate': 128000,
              'sampleRate': 44100,
              'channelCount': 2,
              'codec': 'mp4a.40.2',
            },
          ]);

          final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

          expect(tracks, <VideoAudioTrack>[
            const VideoAudioTrack(
              id: '1',
              label: 'English',
              language: 'en',
              isSelected: true,
              bitrate: 128000,
              sampleRate: 44100,
              channelCount: 2,
              codec: 'mp4a.40.2',
            ),
            const VideoAudioTrack(
              id: '2',
              label: 'Spanish',
              language: 'es',
              isSelected: false,
              bitrate: 128000,
              sampleRate: 44100,
              channelCount: 2,
              codec: 'mp4a.40.2',
            ),
          ]);
        },
      );

      test('getAudioTracks handles null exoPlayerTracks', () async {
        await mockValueReply('getAudioTracks', <Map<String?, Object?>>[
          <String?, Object?>{},
        ]);

        final List<VideoAudioTrack> tracks = await player.getAudioTracks(1);

        expect(tracks, isEmpty);
      });

      test('selectAudioTrack parses trackId and calls API', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'selectAudioTrack',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.selectAudioTrack(1, '2_3');

        expect(capturedMessage, <Object?>[1, '2_3']);
      });

      test('selectAudioTrack throws on invalid trackId format', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'selectAudioTrack',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.selectAudioTrack(1, 'invalid');

        expect(capturedMessage, <Object?>[1, 'invalid']);
      });

      test('selectAudioTrack throws on trackId with too many parts', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'selectAudioTrack',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.selectAudioTrack(1, '1_2_3');

        expect(capturedMessage, <Object?>[1, '1_2_3']);
      });

      test('selectAudioTrack completes on AudioTrackChangedEvent', () async {
        Object? capturedMessage;
        await mockVoidReply(
          'selectAudioTrack',
          onMessage: (Object? message) => capturedMessage = message,
        );

        await player.selectAudioTrack(1, '0_1');

        expect(capturedMessage, <Object?>[1, '0_1']);
      });
    });
  });
}
