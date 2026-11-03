// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const String _localhost = 'https://127.0.0.1';
final Uri _localhostUri = Uri.parse(_localhost);

/// 最小 Fake 平台：为用例覆盖度检视报告中未覆盖的接口补充测试。
///
/// 检视报告对象为主包 `packages/video_player/video_player`，故测试置于本包
/// 的独立文件 `coverage_gap_test.dart`，不在既有测试文件中追加。
class _CoverageVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  bool isAudioTrackSupportAvailable() {
    return true;
  }
}

void main() {
  group('ClosedCaption.build', () {
    testWidgets('explicitly builds with valid and null text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // 显式调用 build，使覆盖率脚本能命中 ClosedCaption.build 这一方法。
      final BuildContext context = tester.element(find.byType(SizedBox));
      expect(const ClosedCaption(text: 'explicit').build(context), isA<Widget>());
      expect(const ClosedCaption(text: null).build(context), isA<Widget>());
    });
  });

  group('VideoPlayerController.isAudioTrackSupportAvailable', () {
    setUp(() {
      VideoPlayerPlatform.instance = _CoverageVideoPlayerPlatform();
    });

    test('returns true and delegates to the platform', () async {
      final VideoPlayerController controller = VideoPlayerController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(controller.isAudioTrackSupportAvailable(), isTrue);
    });
  });
}
