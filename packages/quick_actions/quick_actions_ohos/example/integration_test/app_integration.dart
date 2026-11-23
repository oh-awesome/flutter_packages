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

// Tests that boot the real example app and assert on its observable state.
//
// The example app's initState() calls initialize() (which queries the launch
// action) and then setShortcutItems() with action_one/action_two. When it
// finishes, the AppBar title flips from 'no action set' to 'actions ready'.
// Asserting that title proves the end-to-end startup path through the real
// platform channel on OHOS.
void appIntegrationTests() {
  group('app integration', () {
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
