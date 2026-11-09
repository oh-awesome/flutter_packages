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

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Regression test for the OHOS dropdown touch focus dismissal:
// on OHOS, selecting a dropdown item in touch mode unfocuses the button so
// the on-screen keyboard is dismissed; in traditional (keyboard) mode the
// focus is preserved for accessibility. This behavior is ported verbatim
// from the OHOS Flutter framework (dropdown.dart:1517-1520).
void main() {
  late FocusNode focusNode;

  setUp(() {
    focusNode = FocusNode();
  });

  tearDown(() {
    focusNode.dispose();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget buildFrame() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: DropdownButton<String>(
            focusNode: focusNode,
            value: 'one',
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'one', child: Text('one')),
              DropdownMenuItem<String>(value: 'two', child: Text('two')),
              DropdownMenuItem<String>(value: 'three', child: Text('three')),
            ],
            onChanged: (String? value) {},
          ),
        ),
      ),
    );
  }

  Future<void> openAndSelect(WidgetTester tester) async {
    await tester.pumpWidget(buildFrame());
    // Focus the button first so we can observe the unfocus.
    focusNode.requestFocus();
    await tester.pump();

    // Open the dropdown menu.
    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish menu animation

    // Select an item.
    await tester.tap(find.text('two').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish menu animation
  }

  testWidgets('OHOS dropdown selection in touch mode unfocuses the button', (
    WidgetTester tester,
  ) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    await openAndSelect(tester);
    expect(
      focusNode.hasFocus,
      isFalse,
      reason: 'OHOS touch selection should unfocus the dropdown button',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('OHOS dropdown selection in keyboard mode preserves focus', (
    WidgetTester tester,
  ) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await openAndSelect(tester);
    expect(
      focusNode.hasFocus,
      isTrue,
      reason: 'keyboard navigation should preserve focus for accessibility',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));

  testWidgets('non-OHOS platforms do not unfocus on touch selection', (WidgetTester tester) async {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    await openAndSelect(tester);
    expect(
      focusNode.hasFocus,
      isTrue,
      reason: 'focus dismissal is OHOS-specific; other platforms keep focus',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
