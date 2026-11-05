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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// Device-level integration test for the OHOS adaptation of material_ui.
// The upstream example has no integration tests, so per the delivery
// requirements these are supplemented from the verified OHOS behavior
// smoke scenarios. Run on an OHOS device with:
//   flutter drive --driver=test_driver/integration_test.dart
//                 --target=integration_test/ohos_adaptation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(Platform.operatingSystem, 'ohos', reason: 'Run on an OHOS device.');
  });

  testWidgets('default page transition builder for ohos is OpenRightwards', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = ThemeData();
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.ohos],
      isA<OpenRightwardsPageTransitionsBuilder>(),
    );
  });

  testWidgets('pushed page slides in from the right and settles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: const Text('home page')));

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const Text('target page')),
    );
    await tester.pump();

    // While the transition is running the entering page has not fully
    // arrived, and it settles at the origin afterwards.
    await tester.pump(const Duration(milliseconds: 75));
    final double earlyLeft = tester.getTopLeft(find.text('target page')).dx;
    await tester.pump(const Duration(milliseconds: 75));
    final double middleLeft = tester.getTopLeft(find.text('target page')).dx;
    expect(earlyLeft, greaterThan(middleLeft));
    expect(middleLeft, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('target page')).dx, 0.0);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('target page'), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AlertDialog is scrollable by default on ohos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('title'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(
                    80,
                    (int index) => Text('content $index'),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ok'),
                  ),
                ],
              ),
            ),
            child: const Text('show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(find.text('content 79').hitTestable(), findsNothing);
    await tester.scrollUntilVisible(
      find.text('content 79'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.text('content 79').hitTestable(), findsOneWidget);
    expect(find.text('ok').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('ok'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('OHOS toolbar selects, copies, cuts and pastes without Share', (
    WidgetTester tester,
  ) async {
    const String originalText = 'hello ohos toolbar';
    final TextEditingController controller = TextEditingController(
      text: originalText,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: TextField(controller: controller)),
        ),
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

    await tester.longPressAt(tester.getCenter(find.text(originalText)));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('Share'), findsNothing);

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: originalText.length),
    );

    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, originalText);
    expect(controller.text, originalText);

    await tester.longPressAt(tester.getCenter(find.text(originalText)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    // Distinct clipboard contents ensure Cut must perform its own write.
    await Clipboard.setData(const ClipboardData(text: 'cut sentinel'));
    await tester.tap(find.text('Cut'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, originalText);

    await tester.longPress(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
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

  testWidgets('splash factory on ohos is InkRipple', (
    WidgetTester tester,
  ) async {
    expect(ThemeData().splashFactory, equals(InkRipple.splashFactory));
  });
}
