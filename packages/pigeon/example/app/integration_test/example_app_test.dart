// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pigeon_example_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gets host language', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Hello from'), findsOneWidget);
  });

  Future<void> tapAndExpectResult(
    WidgetTester tester,
    String buttonLabel,
    Pattern expected,
  ) async {
    await tester.scrollUntilVisible(
      find.text(buttonLabel),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(buttonLabel));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining(expected), findsOneWidget);
  }

  testWidgets('typed list host api round-trip', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tapAndExpectResult(
      tester,
      'sendUint8List',
      'Received message: [1, 2, 3]',
    );
    await tapAndExpectResult(
      tester,
      'sendInt32List',
      'Received message: [4, 5, 6]',
    );
    await tapAndExpectResult(
      tester,
      'sendInt64List',
      RegExp(r'Received message: \[9223372036854775807'),
    );
    await tapAndExpectResult(
      tester,
      'sendFloat64List',
      RegExp(r'Received message: \[12\.3'),
    );
  });
}
