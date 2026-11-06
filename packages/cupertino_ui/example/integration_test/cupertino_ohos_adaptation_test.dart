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

import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Device-level integration test for the OHOS adaptation of cupertino_ui.
// The upstream example has no integration tests, so per the delivery
// requirements these are supplemented from the verified OHOS behavior
// smoke scenarios. Run on an OHOS device with:
//   flutter drive --driver=test_driver/integration_test.dart
//                 --target=integration_test/cupertino_ohos_adaptation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(Platform.operatingSystem, 'ohos', reason: 'Run on an OHOS device.');
  });

  testWidgets('OHOS toolbar selects, copies, cuts and pastes without Share', (
    WidgetTester tester,
  ) async {
    const String originalText = 'Atwater Peel Sherbrooke Bonaventure';
    final TextEditingController controller = TextEditingController(
      text: originalText,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: CupertinoTextField(controller: controller)),
      ),
    );
    // The dedicated test device uses a text clipboard. Grant the example's
    // clipboard permission when prompted; no platform channel is intercepted.
    final ClipboardData? previousClipboard = await Clipboard.getData(
      Clipboard.kTextPlain,
    );
    addTearDown(() async {
      await Clipboard.setData(
        previousClipboard ?? const ClipboardData(text: ''),
      );
    });
    // Seed and verify the real clipboard used by the selection toolbar.
    await Clipboard.setData(const ClipboardData(text: 'clip'));
    expect(await Clipboard.hasStrings(), isTrue);
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, 'clip');

    // Land on the text itself: the field is wider than its left-aligned
    // content, so the center would fall past the end of the text.
    await tester.longPressAt(
      tester.getTopLeft(find.byType(CupertinoTextField)) +
          const Offset(50.0, 8.0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoButton), findsNWidgets(4));
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Share...'), findsNothing);
    expect(controller.selection.isCollapsed, isFalse);
    expect(
      controller.selection.textInside(controller.text),
      isNot(originalText),
    );
    final String selectedText = controller.selection.textInside(
      controller.text,
    );
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, selectedText);
    expect(controller.text, originalText);

    await tester.longPressAt(
      tester.getTopLeft(find.byType(CupertinoTextField)) +
          const Offset(50.0, 8.0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: originalText.length),
    );
    // Distinct clipboard contents ensure Cut must perform its own write.
    await Clipboard.setData(const ClipboardData(text: 'cut sentinel'));
    await tester.tap(find.text('Cut'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, originalText);

    await tester.longPress(find.byType(CupertinoTextField));
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Share...'), findsNothing);
    await tester.tap(find.text('Paste'));
    for (var i = 0; i < 50 && controller.text != originalText; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.text, originalText);
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: originalText.length),
    );
    expect(tester.takeException(), isNull);
  });
}
