// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_ohos_example/main.dart';

void main() {
  testWidgets('loads path_provider_ohos example', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Path Provider'), findsOneWidget);
  });
}
