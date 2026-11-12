// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:camera_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

/// UI-driven integration test for the camera example app.
///
/// Importing main.dart brings the example app code into the coverage report
/// (the upstream camera_test.dart never imports any example file, which is
/// why the lcov output used to be empty), and driving the real demo UI on the
/// device exercises the app-side wiring end to end.
///
/// Deliberately no tester.pump/pumpAndSettle anywhere: pumping hangs the live
/// camera preview under the integration test binding, so every wait is a
/// real-time poll with Future.delayed.

/// Polls [condition] in real time until it turns true.
Future<void> waitUntil(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 20),
  required String reason,
}) async {
  final stopwatch = Stopwatch()..start();
  while (true) {
    if (await condition()) {
      return;
    }
    if (stopwatch.elapsed > timeout) {
      fail('$reason (timed out after ${stopwatch.elapsed.inSeconds}s)');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Whether a text containing [pattern] is rendered (snackbar or elsewhere).
bool hasText(String pattern) => find.textContaining(pattern).evaluate().isNotEmpty;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The default frame policy only renders frames on explicit pumps, which
  // freezes the UI after pumpWidget: camera-driven setState calls never
  // become visible. fullyLive keeps real frames flowing on the device.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('camera demo app coverage drive', (WidgetTester tester) async {
    // ------------------------------------------------------------------
    // Stage 1: launch the app and bring the back-camera preview up.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 1: launch');
    await waitUntil(
      () async {
        try {
          if (cameras.isEmpty) {
            cameras.addAll(await availableCameras());
          }
        } on CameraException {
          // Runtime permission dialog may appear; retry until granted.
        }
        return cameras.isNotEmpty;
      },
      timeout: const Duration(seconds: 60),
      reason:
          'availableCameras() returned no cameras '
          '(permissions not granted by the host?)',
    );
    // Orchestration window: the host grants the camera and microphone runtime
    // permissions via "hdc shell atm perm -g" while this fixed wait runs.
    debugPrint('COVERAGE_TEST waiting for host to grant permissions');
    await Future<void>.delayed(const Duration(seconds: 15));
    await tester.pumpWidget(const CameraApp());
    await waitUntil(
      () async => find.byType(RadioListTile<CameraDescription>).hitTestable().evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30),
      reason: 'camera radio buttons never became tappable',
    );
    // Diagnostics for the tap-coordinate pipeline under the live binding.
    debugPrint(
      'COVERAGE_TEST view: physical=${tester.view.physicalSize} '
      'dpr=${tester.view.devicePixelRatio}',
    );
    debugPrint(
      'COVERAGE_TEST radio rect: '
      '${tester.getRect(find.byType(RadioListTile<CameraDescription>).first)}',
    );
    await tester.tap(find.byType(RadioListTile<CameraDescription>).first);
    await waitUntil(
      () async => find.byType(CameraPreview).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
      reason: 'back-camera preview never appeared after selecting a camera',
    );
    debugPrint('COVERAGE_TEST stage 1 done');

    // ------------------------------------------------------------------
    // Stage 2: take a picture snackbar + thumbnail.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 2: take picture');
    await tester.tap(find.byIcon(Icons.camera_alt));
    await waitUntil(
      () async => hasText('Picture saved to'),
      timeout: const Duration(seconds: 30),
      reason: 'no "Picture saved to" snackbar after tapping the shutter',
    );
    await waitUntil(
      () async => find.byType(Image).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 10),
      reason: 'image thumbnail never appeared after taking a picture',
    );
    debugPrint('COVERAGE_TEST stage 2 done');

    // ------------------------------------------------------------------
    // Stage 3: record a video, stop it, and verify the video thumbnail.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 3: record video');
    await tester.tap(find.byIcon(Icons.videocam));
    await waitUntil(
      () async {
        final Finder stopButton = find.ancestor(
          of: find.byIcon(Icons.stop),
          matching: find.byType(IconButton),
        );
        if (stopButton.evaluate().isEmpty) {
          return false;
        }
        return tester.widget<IconButton>(stopButton).onPressed != null;
      },
      timeout: const Duration(seconds: 30),
      reason: 'stop button never became enabled after starting recording',
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.stop));
    await waitUntil(
      () async => hasText('Video recorded to'),
      timeout: const Duration(seconds: 30),
      reason: 'no "Video recorded to" snackbar after stopping recording',
    );
    await waitUntil(
      () async => find.byType(VideoPlayer).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30),
      reason: 'video player thumbnail never appeared after stopping',
    );
    debugPrint('COVERAGE_TEST stage 3 done');

    // ------------------------------------------------------------------
    // Stage 4: cycle all four flash modes via the flash panel.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 4: flash modes');
    await tester.tap(find.byIcon(Icons.flash_on).first);
    await waitUntil(
      () async => find.byIcon(Icons.flash_off).hitTestable().evaluate().isNotEmpty,
      timeout: const Duration(seconds: 10),
      reason: 'flash panel never expanded',
    );
    await tester.tap(find.byIcon(Icons.flash_off));
    await waitUntil(
      () async => hasText('Flash mode set to off'),
      reason: 'flash off snackbar missing',
    );
    await tester.tap(find.byIcon(Icons.flash_auto));
    await waitUntil(
      () async => hasText('Flash mode set to auto'),
      reason: 'flash auto snackbar missing',
    );
    // The panel "always" button reuses the flash_on icon; the mode row toggle
    // is the first match and the panel button is the last one.
    await tester.tap(find.byIcon(Icons.flash_on).last);
    await waitUntil(
      () async => hasText('Flash mode set to always'),
      reason: 'flash always snackbar missing',
    );
    await tester.tap(find.byIcon(Icons.highlight));
    await waitUntil(
      () async => hasText('Flash mode set to torch'),
      reason: 'flash torch snackbar missing',
    );
    debugPrint('COVERAGE_TEST stage 4 done');

    // ------------------------------------------------------------------
    // Stage 5: exposure and focus mode panels.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 5: exposure and focus panels');
    await tester.tap(find.byIcon(Icons.exposure));
    await waitUntil(
      () async => find.text('Exposure Mode').hitTestable().evaluate().isNotEmpty,
      timeout: const Duration(seconds: 10),
      reason: 'exposure panel never expanded',
    );
    // 'AUTO'/'LOCKED' exist in both panels; the exposure panel is built
    // before the focus panel, so .first targets the exposure row.
    await tester.tap(find.text('AUTO').first);
    await waitUntil(
      () async => hasText('Exposure mode set to auto'),
      reason: 'exposure auto snackbar missing',
    );
    await tester.tap(find.text('LOCKED').first);
    await waitUntil(
      () async => hasText('Exposure mode set to locked'),
      reason: 'exposure locked snackbar missing',
    );
    debugPrint('COVERAGE_TEST stage 5 done');

    // ------------------------------------------------------------------
    // Stage 6: drag the exposure offset slider, then reset it.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 6: exposure slider');
    await tester.tap(find.byIcon(Icons.exposure));
    await waitUntil(
      () async {
        final Finder sliders = find.byType(Slider);
        if (sliders.evaluate().isEmpty) {
          return false;
        }
        // Reading widget data does not need hit-testability, and dropping
        // hitTestable avoids a race with the panel expand animation.
        return tester.widget<Slider>(sliders.first).onChanged != null;
      },
      timeout: const Duration(seconds: 10),
      reason: 'exposure slider never became draggable (min==max?)',
    );
    final double valueBefore = tester.widget<Slider>(find.byType(Slider).first).value;
    await tester.drag(find.byType(Slider).first, const Offset(60, 0));
    await waitUntil(
      () async {
        final double value = tester.widget<Slider>(find.byType(Slider).first).value;
        return value != valueBefore;
      },
      timeout: const Duration(seconds: 10),
      reason: 'slider value stayed at $valueBefore after dragging',
    );
    // RESET OFFSET only forwards setExposureOffset(0.0) to the platform and
    // never updates the slider state (main.dart wires onPressed directly to
    // controller.setExposureOffset without setState), so the slider value
    // intentionally stays where the drag left it. The button press is still
    // exercised to cover the call path; recorded as a demo-code quirk.
    await tester.tap(find.text('RESET OFFSET'));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    debugPrint('COVERAGE_TEST stage 6 done');

    // ------------------------------------------------------------------
    // Stage 7: toggle the capture orientation lock; the demo shows a
    // snackbar and swaps the icon between rotation states.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 7: orientation lock');
    await tester.tap(find.byIcon(Icons.screen_rotation));
    await waitUntil(
      () async => hasText('Capture orientation locked to'),
      reason: 'orientation lock snackbar missing',
    );
    await waitUntil(
      () async => find.byIcon(Icons.screen_lock_rotation).hitTestable().evaluate().isNotEmpty,
      reason: 'orientation icon did not switch to the locked icon',
    );
    await tester.tap(find.byIcon(Icons.screen_lock_rotation));
    await waitUntil(
      () async => hasText('Capture orientation unlocked'),
      reason: 'orientation unlock snackbar missing',
    );
    debugPrint('COVERAGE_TEST stage 7 done');

    // ------------------------------------------------------------------
    // Stage 8: pause/resume preview; the pause button turns red while the
    // preview is paused (main.dart color rule) and blue otherwise.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 8: pause preview');
    await tester.tap(find.byIcon(Icons.pause_presentation));
    await waitUntil(() async {
      final IconButton button = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.pause_presentation), matching: find.byType(IconButton)),
      );
      return button.color == Colors.red;
    }, reason: 'pause-preview button did not turn red while paused');
    await tester.tap(find.byIcon(Icons.pause_presentation));
    await waitUntil(() async {
      final IconButton button = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.pause_presentation), matching: find.byType(IconButton)),
      );
      return button.color == Colors.blue;
    }, reason: 'pause-preview button did not turn back blue after resume');
    debugPrint('COVERAGE_TEST stage 8 done');

    // ------------------------------------------------------------------
    // Stage 9: switch to the front camera; the demo reuses the controller
    // via setDescription and the preview must recover without errors.
    // ------------------------------------------------------------------
    debugPrint('COVERAGE_TEST stage 9: camera switch');
    if (cameras.length >= 2) {
      await tester.tap(find.byType(RadioListTile<CameraDescription>).last);
      await waitUntil(
        () async => find.byType(CameraPreview).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 60),
        reason: 'front-camera preview never recovered after the switch',
      );
      await waitUntil(
        () async => !hasText('Camera error'),
        reason: 'camera error snackbar visible after the switch',
      );
      debugPrint('COVERAGE_TEST stage 9 done');
    } else {
      debugPrint('COVERAGE_TEST stage 9 skipped: only one camera');
    }
    // Stage 10 (pinch zoom) is intentionally not implemented: setZoomLevel
    // has no observable UI effect in the demo and a two-pointer gesture on
    // the live preview binding is brittle. Recorded in the final report.
  });
}
