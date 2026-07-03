// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testexample/main.dart' as app;

const String _homePageTitle = 'File Selector Demo Home Page';

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  expect(find.text(_homePageTitle), findsOneWidget);
}

Future<void> _navigateBackToHome(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  expect(find.text(_homePageTitle), findsOneWidget);
}

Future<void> _openPageFromHome(
  WidgetTester tester,
  String homeButtonLabel,
) async {
  await tester.tap(find.text(homeButtonLabel));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example app launches', (WidgetTester tester) async {
    await _launchApp(tester);
  });

  testWidgets('home page shows all navigation buttons',
      (WidgetTester tester) async {
    await _launchApp(tester);
    expect(find.text('Open a text file'), findsOneWidget);
    expect(find.text('Open an image'), findsOneWidget);
    expect(find.text('Open multiple images'), findsOneWidget);
    expect(find.text('Open with mimeTypes'), findsOneWidget);
  });

  testWidgets('navigates to open text page', (WidgetTester tester) async {
    await _launchApp(tester);
    await _openPageFromHome(tester, 'Open a text file');
    expect(find.text('Open a text file'), findsWidgets);
    expect(
      find.text('Press to open a text file (json, txt)'),
      findsOneWidget,
    );
    await _navigateBackToHome(tester);
  });

  testWidgets('navigates to open image page', (WidgetTester tester) async {
    await _launchApp(tester);
    await _openPageFromHome(tester, 'Open an image');
    expect(find.text('Open an image'), findsWidgets);
    expect(
      find.text('Press to open an image file(png, jpg)'),
      findsOneWidget,
    );
    await _navigateBackToHome(tester);
  });

  testWidgets('navigates to open multiple images page',
      (WidgetTester tester) async {
    await _launchApp(tester);
    await _openPageFromHome(tester, 'Open multiple images');
    expect(find.text('Open multiple images'), findsWidgets);
    expect(
      find.text('Press to open multiple images (png, jpg)'),
      findsOneWidget,
    );
    await _navigateBackToHome(tester);
  });

  testWidgets('navigates to open with mimeTypes page',
      (WidgetTester tester) async {
    await _launchApp(tester);
    await _openPageFromHome(tester, 'Open with mimeTypes');
    expect(find.text('Open with mimeTypes'), findsWidgets);
    expect(
      find.text('Pure mimeTypes input for document picker'),
      findsOneWidget,
    );
    expect(find.text('Pick mimeTypes(png, jpg)'), findsOneWidget);
    expect(find.text('No file picked yet.'), findsOneWidget);
    await _navigateBackToHome(tester);
  });
}
