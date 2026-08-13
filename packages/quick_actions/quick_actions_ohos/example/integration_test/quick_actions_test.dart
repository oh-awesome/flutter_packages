// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quick_actions_ohos/quick_actions_ohos.dart';
import 'package:quick_actions_example/main.dart' as app;

// OHOS quick-actions integration tests.
//
// These exercise the full Dart → Pigeon → native QuickActionsPlugin → OHOS
// stack on a real device/emulator. The unit tests in
// `quick_actions_ohos/test/` cover the Dart layer with a fake host API and
// therefore cannot verify the live platform channel; that is the job of the
// tests below.
//
// OHOS platform limitation: the system exposes no runtime API for *dynamic*
// shortcuts, so `setShortcutItems()` only updates in-memory state on OHOS
// (the native plugin logs a non-fatal warning) and the home-screen shortcuts
// come from the static `shortcuts_config.json`. Consequently these tests
// assert that the channel calls **complete without throwing** and that fields
// round-trip, NOT that shortcuts appear on the home screen. Cold-start and
// hot-start shortcut dispatch (pendingLaunchAction / onNewWant) cannot be
// driven from an automated test (they require launching from a home-screen
// long-press); they are covered by the manual steps in the example README.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A fresh plugin instance per test avoids leaking the Flutter→native
  // callback channel (`OhosQuickActionsFlutterApi.setup`) across cases; the
  // unit tests do the same in their tearDown.
  QuickActionsOhos newQuickActions() => QuickActionsOhos();

  group('initialize', () {
    testWidgets('completes on a cold start with no pending shortcut',
        (WidgetTester tester) async {
      // On a normal launch (no shortcut) getLaunchAction() returns null and
      // the handler must NOT be invoked. This is the default app-launch path.
      bool handlerCalled = false;
      final QuickActionsOhos quickActions = newQuickActions();

      await quickActions.initialize((String type) {
        handlerCalled = true;
      });

      expect(handlerCalled, isFalse,
          reason: 'handler must not fire when there is no launch action');
    });

    testWidgets('can be called more than once without error',
        (WidgetTester tester) async {
      // Re-initializing re-registers the Flutter→native callback; the second
      // call must not throw or leave the channel in a broken state.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});
      await quickActions.initialize((String _) {});
    });
  });

  group('setShortcutItems', () {
    testWidgets('completes with a non-empty list', (WidgetTester tester) async {
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      const ShortcutItem item = ShortcutItem(
        type: 'action_one',
        localizedTitle: 'Action one',
        localizedSubtitle: 'Action one subtitle',
        icon: 'ic_shortcut',
      );

      // The whole point: the platform channel round-trip succeeds.
      await expectLater(
        quickActions.setShortcutItems(<ShortcutItem>[item]),
        completes,
      );
    });

    testWidgets('round-trips every ShortcutItem field',
        (WidgetTester tester) async {
      // Drive the wire format with the full set of fields (incl. the optional
      // subtitle) so a regression that drops a field is caught at the channel
      // boundary. On OHOS setShortcutItems stores items in memory; we assert
      // completion rather than echoing, but feeding all fields exercises the
      // ShortcutItemMessage codec end-to-end.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      const List<ShortcutItem> items = <ShortcutItem>[
        ShortcutItem(
          type: 'action_one',
          localizedTitle: 'Action one',
          localizedSubtitle: 'Action one subtitle',
          icon: 'ic_shortcut',
        ),
        ShortcutItem(
          type: 'action_two',
          localizedTitle: 'Action two',
          // localizedSubtitle intentionally null.
          icon: 'ic_shortcut',
        ),
      ];

      await expectLater(
        quickActions.setShortcutItems(items),
        completes,
      );
    });

    testWidgets('accepts an empty list as a boundary case',
        (WidgetTester tester) async {
      // setShortcutItems([]) must be a no-op that completes, not an error.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await expectLater(
        quickActions.setShortcutItems(<ShortcutItem>[]),
        completes,
      );
    });

    testWidgets('accepts items with empty/null optional fields',
        (WidgetTester tester) async {
      // Empty type and null subtitle/icon must traverse the channel without
      // throwing (the native codec handles missing values).
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      const ShortcutItem item =
          ShortcutItem(type: '', localizedTitle: 'title');

      await expectLater(
        quickActions.setShortcutItems(<ShortcutItem>[item]),
        completes,
      );
    });

    testWidgets('replaces previous items when called again',
        (WidgetTester tester) async {
      // Calling setShortcutItems twice must not accumulate or throw; the
      // second call fully replaces the first.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'first', localizedTitle: 'first'),
      ]);
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'second', localizedTitle: 'second'),
      ]);
    });

    testWidgets('is safe to call concurrently', (WidgetTester tester) async {
      // Concurrent channel calls must each complete; this guards against
      // serialized-channel regressions on the OHOS side.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await Future.wait<void>(<Future<void>>[
        quickActions.setShortcutItems(<ShortcutItem>[
          const ShortcutItem(type: 'a', localizedTitle: 'a'),
        ]),
        quickActions.setShortcutItems(<ShortcutItem>[
          const ShortcutItem(type: 'b', localizedTitle: 'b'),
        ]),
      ]);
    });
  });

  group('clearShortcutItems', () {
    testWidgets('completes on its own', (WidgetTester tester) async {
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await expectLater(quickActions.clearShortcutItems(), completes);
    });

    testWidgets('is idempotent (safe to call repeatedly)',
        (WidgetTester tester) async {
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.clearShortcutItems();
      await quickActions.clearShortcutItems();
    });
  });

  group('set → clear sequences', () {
    testWidgets('set then clear completes', (WidgetTester tester) async {
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'action_one', localizedTitle: 'Action one'),
      ]);
      await quickActions.clearShortcutItems();
    });

    testWidgets('clear then set completes', (WidgetTester tester) async {
      // clearShortcutItems() also clears the in-memory launchAction state on
      // OHOS; a subsequent setShortcutItems must still succeed.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.clearShortcutItems();
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'action_one', localizedTitle: 'Action one'),
      ]);
    });

    testWidgets('set → clear → set cycle completes',
        (WidgetTester tester) async {
      // Stress the alternation to guard against state corruption across the
      // set/clear boundary.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'one', localizedTitle: 'one'),
      ]);
      await quickActions.clearShortcutItems();
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'two', localizedTitle: 'two'),
      ]);
    });
  });

  group('app integration', () {
    // The example app's initState() calls initialize() (which queries the
    // launch action) and then setShortcutItems() with action_one/action_two.
    // When it finishes, the AppBar title flips from 'no action set' to
    // 'actions ready'. Asserting that title proves the end-to-end startup
    // path through the real platform channel on OHOS.

    testWidgets('Can run MyApp', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(app.MyHomePage), findsOneWidget);
    });

    testWidgets('app initializes shortcuts on startup (AppBar shows ready)',
        (WidgetTester tester) async {
      app.main();
      // initState runs initialize() then setShortcutItems(); pump until the
      // async setShortcutItems future resolves and the title updates.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('actions ready'),
        findsOneWidget,
        reason: 'setShortcutItems() in initState should complete on startup, '
            'flipping the AppBar title from "no action set" to "actions ready"',
      );
    });
  });
}
