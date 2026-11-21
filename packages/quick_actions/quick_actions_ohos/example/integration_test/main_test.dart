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

// Entry point for the quick_actions_ohos integration tests.
//
// These exercise the full Dart -> Pigeon -> native QuickActionsPlugin -> OHOS
// stack on a real device. The unit tests in `quick_actions_ohos/test/` cover
// the Dart layer with a fake host API and therefore cannot verify the live
// platform channel; that is the job of the tests below.
//
// OHOS platform limitation: the system exposes no runtime API for *dynamic*
// shortcuts, so `setShortcutItems()` only updates in-memory state on OHOS
// (the native plugin logs a non-fatal warning) and the home-screen shortcuts
// come from the static `shortcuts_config.json`. Consequently these tests
// assert that the channel calls complete without throwing and that fields
// round-trip, NOT that shortcuts appear on the home screen. Cold-start and
// hot-start shortcut dispatch (pendingLaunchAction / onNewWant) cannot be
// driven from an automated test (they require launching from a home-screen
// long-press); they are covered by the manual steps in the example README.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quick_actions_example/main.dart' as app;
import 'package:quick_actions_ohos/quick_actions_ohos.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

part 'app_integration.dart';
part 'platform_instance.dart';
part 'quick_actions_api.dart';

// The plugin only ships a native implementation for OHOS; the tests assert
// the OHOS implementation and drive its Pigeon channel directly, which have
// no handler on any other host, so skip the whole suite there.
final bool shouldSkip = kIsWeb || defaultTargetPlatform != TargetPlatform.ohos;

// A fresh plugin instance per test avoids leaking the Flutter->native
// callback channel (`OhosQuickActionsFlutterApi.setup`) across cases; the
// unit tests do the same in their tearDown.
QuickActionsOhos newQuickActions() => QuickActionsOhos();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('quick_actions_ohos', () {
    platformInstanceTests();
    initializeTests();
    setShortcutItemsTests();
    clearShortcutItemsTests();
    shortcutItemSequenceTests();
    appIntegrationTests();
  }, skip: shouldSkip);
}
