// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in <PointerDeviceKind>[PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('OHOS CupertinoTextField records $kind in its input configuration', (tester) async {
      await tester.pumpWidget(const CupertinoApp(home: CupertinoTextField()));
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(CupertinoTextField)),
        kind: kind,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      final client = tester.state(find.byType(CupertinoTextField)) as AutofillClient;
      expect(client.textInputConfiguration.deviceKind, kind);

      tester.testTextInput.log.clear();
      final PointerDeviceKind nextKind = kind == PointerDeviceKind.touch
          ? PointerDeviceKind.mouse
          : PointerDeviceKind.touch;
      final TestGesture nextGesture = await tester.startGesture(
        tester.getCenter(find.byType(CupertinoTextField)),
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

  testWidgets('Focused CupertinoTextField requests the keyboard once per tap', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(CupertinoApp(home: CupertinoTextField(focusNode: focusNode)));
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    tester.testTextInput.log.clear();
    await tester.tap(find.byType(CupertinoTextField));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.log.where((call) => call.method == 'TextInput.show'), hasLength(1));
  }, variant: TargetPlatformVariant.all());
}
