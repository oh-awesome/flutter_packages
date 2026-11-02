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

// 新鸿蒙test：测试 IKReceiptManager.retrieveReceiptData
// 通过 'iap#retrieveReceiptData' MethodChannel 获取收据数据。

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 重置 mock handler，避免测试间状态泄漏
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/in_app_purchase'),
      null,
    );
  });

  group('IKReceiptManager.retrieveReceiptData', () {
    test('should return receipt data from method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return 'receipt-data-123';
          }
          return null;
        },
      );

      final String receipt = await IKReceiptManager.retrieveReceiptData();

      expect(receipt, 'receipt-data-123');
    });

    test('should return empty string when method channel returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return null;
          }
          return null;
        },
      );

      final String receipt = await IKReceiptManager.retrieveReceiptData();

      expect(receipt, isEmpty);
    });

    test('should propagate PlatformException from method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#retrieveReceiptData') {
            throw PlatformException(
              code: 'receipt_error',
              message: 'no receipt available',
            );
          }
          return null;
        },
      );

      await expectLater(
        IKReceiptManager.retrieveReceiptData(),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
