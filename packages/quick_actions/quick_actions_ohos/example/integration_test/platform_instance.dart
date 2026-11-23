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

// Tests for the federated entry point `QuickActionsPlatform.instance`.
//
// On an OHOS host the generated plugin registrant calls
// `QuickActionsOhos.registerWith()` during engine startup, so client code
// that goes through the platform interface (as the app-facing
// `quick_actions` package does) must land in the OHOS implementation, not in
// the default method-channel stub.
void platformInstanceTests() {
  group('QuickActionsPlatform.instance', () {
    testWidgets('resolves to the OHOS implementation on device',
        (WidgetTester tester) async {
      final QuickActionsPlatform platform = QuickActionsPlatform.instance;

      expect(platform, isA<QuickActionsOhos>(),
          reason: 'the generated plugin registrant must register '
              'QuickActionsOhos as the default instance on OHOS');
    });

    testWidgets('routes calls through the federated instance',
        (WidgetTester tester) async {
      // Drive initialize/set/clear through the platform-interface default
      // instance exactly like the app-facing QuickActions facade does; every
      // call must reach the OHOS implementation and complete over the live
      // channel.
      await QuickActionsPlatform.instance.initialize((String _) {});

      await QuickActionsPlatform.instance.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'via_instance',
          localizedTitle: 'Via instance',
          localizedSubtitle: 'Via instance subtitle',
          icon: 'ic_shortcut',
        ),
      ]);

      await QuickActionsPlatform.instance.clearShortcutItems();
    });
  });
}
