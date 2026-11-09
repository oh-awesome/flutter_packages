// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final kind in <PointerDeviceKind>[PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('OHOS TextField records $kind in its input configuration', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Material(child: TextField())));
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
        kind: kind,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      final client = tester.state(find.byType(TextField)) as AutofillClient;
      expect(client.textInputConfiguration.deviceKind, kind);

      tester.testTextInput.log.clear();
      final PointerDeviceKind nextKind = kind == PointerDeviceKind.touch
          ? PointerDeviceKind.mouse
          : PointerDeviceKind.touch;
      final TestGesture nextGesture = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
        kind: nextKind,
      );
      await nextGesture.up();
      await tester.pumpAndSettle();
      expect(client.textInputConfiguration.deviceKind, nextKind);
      expect(
        tester.testTextInput.log.where((call) => call.method == 'TextInput.show'),
        hasLength(1),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.ohos));
  }
}
