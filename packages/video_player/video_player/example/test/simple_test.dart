import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_example/basic.dart' as basic;
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerPlatform originalPlatform;
  late FakeVideoPlayerPlatform fakePlatform;

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    fakePlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakePlatform;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalPlatform;
  });

  test('VideoPlayerValue copyWith', () {
    final VideoPlayerValue value = VideoPlayerValue(
      duration: const Duration(seconds: 2),
      size: const Size(1920, 1080),
      isInitialized: true,
    );

    final VideoPlayerValue updated = value.copyWith(
      position: const Duration(milliseconds: 500),
      isPlaying: true,
    );

    expect(updated.position, const Duration(milliseconds: 500));
    expect(updated.isPlaying, isTrue);
    expect(value.isPlaying, isFalse);
  });

  group('VideoApp', () {
    testWidgets('shows video after init', (WidgetTester tester) async {
      await tester.pumpWidget(const basic.VideoApp());
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(
        fakePlatform.dataSources.single.sourceType,
        DataSourceType.network,
      );
    });

    testWidgets('toggles play/pause', (WidgetTester tester) async {
      await tester.pumpWidget(const basic.VideoApp());
      await tester.pumpAndSettle();

      final int playBefore = fakePlatform.playCount;
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(fakePlatform.playCount, playBefore + 1);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      final int pauseBefore = fakePlatform.pauseCount;
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(fakePlatform.pauseCount, pauseBefore + 1);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final List<DataSource> dataSources = <DataSource>[];
  int playCount = 0;
  int pauseCount = 0;

  final Map<int, StreamController<VideoEvent>> _streams =
      <int, StreamController<VideoEvent>>{};

  int _nextPlayerId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) {
    dataSources.add(dataSource);
    return _createInternal();
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) {
    dataSources.add(options.dataSource);
    return _createInternal();
  }

  Future<int> _createInternal() async {
    final int playerId = _nextPlayerId++;
    final StreamController<VideoEvent> controller =
        StreamController<VideoEvent>();
    _streams[playerId] = controller;
    controller.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(100, 100),
        duration: const Duration(seconds: 1),
      ),
    );
    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _streams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    await _streams[playerId]?.close();
  }

  @override
  Future<void> pause(int playerId) async {
    pauseCount++;
  }

  @override
  Future<void> play(int playerId) async {
    playCount++;
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return Duration.zero;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }
}
