/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of 'main_test.dart';

// Tests for the three QuickActionsOhos lifecycle APIs: initialize,
// setShortcutItems and clearShortcutItems.
void initializeTests() {
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
      // Re-initializing re-registers the Flutter->native callback; the second
      // call must not throw or leave the channel in a broken state.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});
      await quickActions.initialize((String _) {});
    });
  });
}

void setShortcutItemsTests() {
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

    testWidgets('completes with every ShortcutItem field populated',
        (WidgetTester tester) async {
      // Drive the wire format with the full set of fields (incl. the optional
      // subtitle) so the ShortcutItemMessage codec is exercised end-to-end.
      // Only regressions that make the channel throw are caught here; field
      // level correctness is verified on the native side by the ArkTS unit
      // test setShortcutItemsChannelStoresDecodedItems.
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

    testWidgets('completes when called again with a new list',
        (WidgetTester tester) async {
      // Calling setShortcutItems twice must not throw or leave the channel in
      // a broken state. The in-memory replacement semantics (second call fully
      // replaces the first) is verified on the native side by the ArkTS unit
      // tests; here we only assert that both calls succeed.
      final QuickActionsOhos quickActions = newQuickActions();
      await quickActions.initialize((String _) {});

      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'first', localizedTitle: 'first'),
      ]);
      await quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(type: 'second', localizedTitle: 'second'),
      ]);
    });

    testWidgets('completes when called concurrently',
        (WidgetTester tester) async {
      // Concurrent channel calls must each complete without error; this
      // guards against serialized-channel regressions on the OHOS side.
      // Native state integrity under concurrency is not observable from the
      // public Dart API and is covered by the ArkTS unit tests.
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
}

void clearShortcutItemsTests() {
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
}

void shortcutItemSequenceTests() {
  group('set -> clear sequences', () {
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

    testWidgets('set -> clear -> set cycle completes',
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
}
