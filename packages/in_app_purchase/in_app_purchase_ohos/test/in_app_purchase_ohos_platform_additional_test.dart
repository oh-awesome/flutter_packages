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

// 补充 InAppPurchaseOhosPlatform 的异常场景、边界场景与并发场景测试：
// - restorePurchases 失败/成功
// - 监听 purchaseStream 时回放平台已有交易（syncTransactions）
// - retrieveReceiptData 失败时的兜底
// - 恢复购买期间收到 restored 交易的内部状态流转
// - completePurchase / countryCode 的平台异常传播
// - buyNonConsumable 使用普通 PurchaseParam（productType 为空）
// - 多监听者并发接收购买流事件

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.flutter.io/in_app_purchase');

  setUp(() {
    InAppPurchaseOhosPlatform.registerPlatform();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('InAppPurchaseOhosPlatform.restorePurchases', () {
    test('should propagate a PlatformException when restoreTransactions fails',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#restoreTransactions') {
            throw PlatformException(code: 'restore_error', message: 'restore failed');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();

      await expectLater(
        platform.restorePurchases(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('should complete normally when restoreTransactions succeeds',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#restoreTransactions') {
            return null;
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();

      await expectLater(platform.restorePurchases(), completes);
    });
  });

  group('InAppPurchaseOhosPlatform.purchaseStream', () {
    test(
        'should replay unobserved platform transactions when the stream is listened to',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#transactions':
              return <Map<String, dynamic>>[
                <String, dynamic>{
                  'payment': <String, dynamic>{
                    'productId': 'com.example.replay',
                    'productType': 1, // NONCONSUMABLE
                  },
                  'transactionState': 1, // purchased
                  'transactionIdentifier': 'txn_replay_001',
                  'transactionTimeStamp': 1700000000.0,
                },
              ];
            case 'iap#retrieveReceiptData':
              return 'receipt_replay';
            case 'iap#startObservingTransactionQueue':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription = platform.purchaseStream.listen((List<PurchaseDetails> details) {
        if (!completer.isCompleted) {
          completer.complete(details);
          subscription.cancel();
        }
      });

      final List<PurchaseDetails> result =
          await completer.future.timeout(const Duration(seconds: 3));

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.replay');
      expect(result.first.status, PurchaseStatus.purchased);
      expect(result.first.pendingCompletePurchase, isTrue);
    });

    test('should deliver purchase updates to multiple listeners', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#retrieveReceiptData':
              return 'receipt_multi';
            case 'iap#startObservingTransactionQueue':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final List<List<PurchaseDetails>> events = <List<PurchaseDetails>>[];
      final StreamSubscription<List<PurchaseDetails>> first =
          platform.purchaseStream.listen(events.add);
      final StreamSubscription<List<PurchaseDetails>> second =
          platform.purchaseStream.listen(events.add);

      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.multi',
            'productType': 1,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn_multi_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];
      await IKPaymentQueueWrapper()
          .handleObserverCallbacks(MethodCall('updatedTransactions', transactionData));
      await pumpEventQueue();

      expect(events.length, 2);
      expect(events.first.first.productID, 'com.example.multi');

      await first.cancel();
      await second.cancel();
    });
  });

  group('InAppPurchaseOhosPlatform transaction updates', () {
    test('should use an empty receipt when retrieveReceiptData fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#retrieveReceiptData':
              throw PlatformException(code: 'receipt_error', message: 'no receipt');
            case 'iap#startObservingTransactionQueue':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        if (!completer.isCompleted) {
          completer.complete(details);
          subscription.cancel();
        }
      });

      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.receipt_fail',
            'productType': 1,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn_receipt_fail_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];
      await IKPaymentQueueWrapper()
          .handleObserverCallbacks(MethodCall('updatedTransactions', transactionData));

      final List<PurchaseDetails> result =
          await completer.future.timeout(const Duration(seconds: 3));

      expect(result.first.productID, 'com.example.receipt_fail');
      expect(result.first.verificationData.localVerificationData, '');
      expect(result.first.verificationData.serverVerificationData, '');
    });

    test(
        'should track restored transactions received while a restore is in flight',
        () async {
      final Completer<Object?> restoreGate = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#restoreTransactions':
              // Keep the restore in flight so the observer stays in the
              // "waiting for transactions" state while we push a restored txn.
              return restoreGate.future;
            case 'iap#retrieveReceiptData':
              return 'receipt_restore';
            case 'iap#startObservingTransactionQueue':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        if (!completer.isCompleted) {
          completer.complete(details);
          subscription.cancel();
        }
      });

      final Future<void> restoreFuture = platform.restorePurchases();

      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.restore',
            'productType': 1,
          },
          'transactionState': 3, // restored
          'transactionIdentifier': 'txn_restore_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];
      await IKPaymentQueueWrapper()
          .handleObserverCallbacks(MethodCall('updatedTransactions', transactionData));

      final List<PurchaseDetails> result =
          await completer.future.timeout(const Duration(seconds: 3));
      expect(result.first.status, PurchaseStatus.restored);

      restoreGate.complete();
      await expectLater(restoreFuture, completes);
    });
  });

  group('InAppPurchaseOhosPlatform.completePurchase', () {
    test('should propagate a PlatformException from finishTransaction',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#finishPurchase') {
            throw PlatformException(code: 'finish_error', message: 'finish failed');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final IKPaymentTransactionWrapper transaction = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn_finish_fail_001',
      );
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(transaction, 'receipt');

      await expectLater(
        platform.completePurchase(purchase),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('InAppPurchaseOhosPlatform.countryCode', () {
    test('should propagate a PlatformException from the method channel',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#countryCode') {
            throw PlatformException(code: 'country_error', message: 'no country');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();

      await expectLater(
        platform.countryCode(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('InAppPurchaseOhosPlatform.buyNonConsumable', () {
    test('should serialize a plain PurchaseParam with a null product type',
        () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'iap#createPurchase') {
            return null;
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final ProductDetails details = ProductDetails(
        id: 'com.example.plain',
        title: 'Plain Product',
        description: 'A product without AppGallery details',
        price: r'$1.00',
        rawPrice: 1.0,
        currencyCode: 'USD',
      );
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: details);

      final bool result =
          await platform.buyNonConsumable(purchaseParam: purchaseParam);

      expect(result, isTrue);
      final Map<Object?, Object?> args = Map<Object?, Object?>.from(
        log.firstWhere((MethodCall call) => call.method == 'iap#createPurchase')
            .arguments as Map,
      );
      expect(args['productId'], 'com.example.plain');
      expect(args['productType'], isNull);
      expect(args['applicationUserName'], isNull);
    });
  });

  group('InAppPurchaseOhosPlatform state/timeout/permission exceptions', () {
    PurchaseParam buildConsumableParam(String productId) {
      final IKProductWrapper product = IKProductWrapper(
        id: productId,
        type: ProductType.CONSUMABLE,
        name: 'Consumable',
        description: 'A consumable',
        localPrice: '￥1.00',
        microPrice: 1000000,
        originalLocalPrice: '￥1.00',
        originalMicroPrice: 1000000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      return PurchaseParam(
        productDetails: AppGalleryProductDetails.fromIKProduct(product),
      );
    }

    test('isAvailable should propagate a PlatformException for a state error',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            // 模拟设备断连/服务不可用
            throw PlatformException(
                code: 'IAP_1', message: 'service disconnected');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();

      await expectLater(
        platform.isAvailable(),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'IAP_1')),
      );
    });

    test('buyConsumable should return false on a permission-denied error',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            // 模拟 IAP 权限缺失
            throw PlatformException(
                code: 'IAP_3', message: 'permission denied');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final bool result = await platform.buyConsumable(
        purchaseParam: buildConsumableParam('com.example.permission'),
        autoConsume: true,
      );

      expect(result, isFalse);
    });

    test('buyConsumable should return false on a timeout error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            // 模拟 MethodChannel 调用超时
            throw PlatformException(
                code: 'timeout', message: 'request timed out');
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final bool result = await platform.buyConsumable(
        purchaseParam: buildConsumableParam('com.example.timeout'),
        autoConsume: true,
      );

      expect(result, isFalse);
    });
  });

  group('InAppPurchaseOhosPlatform concurrency', () {
    PurchaseParam buildConsumableParam(String productId) {
      final IKProductWrapper product = IKProductWrapper(
        id: productId,
        type: ProductType.CONSUMABLE,
        name: 'Consumable',
        description: 'A concurrent consumable',
        localPrice: '￥1.00',
        microPrice: 1000000,
        originalLocalPrice: '￥1.00',
        originalMicroPrice: 1000000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      return PurchaseParam(
        productDetails: AppGalleryProductDetails.fromIKProduct(product),
      );
    }

    test('should handle concurrent buyConsumable calls', () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'iap#createPurchase') {
            return null;
          }
          return null;
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final List<bool> results = await Future.wait(<Future<bool>>[
        platform.buyConsumable(
            purchaseParam:
                buildConsumableParam('com.example.concurrent_a'),
            autoConsume: true),
        platform.buyConsumable(
            purchaseParam:
                buildConsumableParam('com.example.concurrent_b'),
            autoConsume: true),
        platform.buyConsumable(
            purchaseParam:
                buildConsumableParam('com.example.concurrent_c'),
            autoConsume: true),
      ]);

      expect(results, everyElement(isTrue));
      expect(
        log.where((MethodCall call) => call.method == 'iap#createPurchase'),
        hasLength(3),
      );
    });

    test(
        'should auto-consume when an observer callback races with buyConsumable',
        () async {
      final List<MethodCall> finishLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#finishPurchase':
              finishLog.add(methodCall);
              return null;
            case 'iap#retrieveReceiptData':
              return 'raceReceipt';
            case 'iap#startObservingTransactionQueue':
              return null;
            case 'iap#createPurchase':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        if (!completer.isCompleted) {
          completer.complete(details);
          subscription.cancel();
        }
      });

      const String productId = 'com.example.race';
      // 先发起购买但不等其完成，让 observer 回调插入在 addPayment 完成之前
      final Future<bool> buyFuture = platform.buyConsumable(
          purchaseParam: buildConsumableParam(productId), autoConsume: true);

      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': productId,
            'productType': 0, // CONSUMABLE
          },
          'transactionState': 1, // purchased
          'transactionIdentifier': 'txn_race_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];
      await IKPaymentQueueWrapper().handleObserverCallbacks(
          MethodCall('updatedTransactions', transactionData));

      final List<PurchaseDetails> result =
          await completer.future.timeout(const Duration(seconds: 3));
      final bool buyResult = await buyFuture;

      expect(buyResult, isTrue);
      expect(result, hasLength(1));
      expect(result.first.productID, productId);
      expect(result.first.status, PurchaseStatus.purchased);
      // 竞态期间 auto-consume 应执行完成购买
      expect(finishLog, isNotEmpty);
      expect(result.first.pendingCompletePurchase, isFalse);
    });

    test('should auto-consume concurrent purchases with distinct products',
        () async {
      final List<MethodCall> finishLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'iap#finishPurchase':
              finishLog.add(methodCall);
              return null;
            case 'iap#retrieveReceiptData':
              return 'multiReceipt';
            case 'iap#startObservingTransactionQueue':
              return null;
            case 'iap#createPurchase':
              return null;
            default:
              return null;
          }
        },
      );

      final InAppPurchaseOhosPlatform platform = InAppPurchaseOhosPlatform();
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        if (!completer.isCompleted) {
          completer.complete(details);
          subscription.cancel();
        }
      });

      const String productA = 'com.example.multi_a';
      const String productB = 'com.example.multi_b';
      final List<Future<bool>> buyFutures = <Future<bool>>[
        platform.buyConsumable(
            purchaseParam: buildConsumableParam(productA), autoConsume: true),
        platform.buyConsumable(
            purchaseParam: buildConsumableParam(productB), autoConsume: true),
      ];

      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': productA,
            'productType': 0,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn_multi_a_001',
          'transactionTimeStamp': 1700000000.0,
        },
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': productB,
            'productType': 0,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn_multi_b_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];
      await IKPaymentQueueWrapper().handleObserverCallbacks(
          MethodCall('updatedTransactions', transactionData));

      final List<PurchaseDetails> result =
          await completer.future.timeout(const Duration(seconds: 3));
      await Future.wait(buyFutures);

      expect(result, hasLength(2));
      expect(result.map((PurchaseDetails p) => p.productID),
          containsAll(<String>[productA, productB]));
      expect(result.every(
          (PurchaseDetails p) => p.pendingCompletePurchase == false), isTrue);
      expect(finishLog, hasLength(2));
    });
  });
}
