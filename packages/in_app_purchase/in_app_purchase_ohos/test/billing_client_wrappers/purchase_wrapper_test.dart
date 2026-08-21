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

// 原安卓test内容（注释保留）：
// 此文件原测试 PurchaseWrapper 到 GooglePlayPurchaseDetails 的转换。
// 鸿蒙版使用 IKPaymentTransactionWrapper 到 AppGalleryPurchaseDetails 的转换。

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

// 原安卓test使用 PurchaseWrapper，字段为:
// orderId, packageName, purchaseTime, signature, products, purchaseToken,
// isAutoRenewing, originalJson, developerPayload, isAcknowledged,
// purchaseState, obfuscatedAccountId, obfuscatedProfileId
// 鸿蒙版使用 IKPaymentTransactionWrapper，字段为:
// payment(IKPaymentWrapper), transactionState, originalTransaction,
// transactionTimeStamp, transactionIdentifier, error(IKError)

// const PurchaseWrapper dummyPurchase = PurchaseWrapper(
//   orderId: 'orderId',
//   packageName: 'packageName',
//   purchaseTime: 0,
//   signature: 'signature',
//   products: <String>['product'],
//   purchaseToken: 'purchaseToken',
//   isAutoRenewing: false,
//   originalJson: '',
//   developerPayload: 'dummy payload',
//   isAcknowledged: true,
//   purchaseState: PurchaseStateWrapper.purchased,
//   obfuscatedAccountId: 'Account101',
//   obfuscatedProfileId: 'Profile103',
// );

IKPaymentTransactionWrapper dummyTransaction = IKPaymentTransactionWrapper(
  payment: const IKPaymentWrapper(
    productId: 'com.example.consumable',
    productType: ProductType.CONSUMABLE,
  ),
  transactionState: IKPaymentTransactionStateWrapper.purchased,
  transactionIdentifier: 'txn001',
  transactionTimeStamp: 1700000000.0,
);

IKPaymentTransactionWrapper dummyFailedTransaction =
    IKPaymentTransactionWrapper(
  payment: const IKPaymentWrapper(
    productId: 'com.example.consumable',
    productType: ProductType.CONSUMABLE,
  ),
  transactionState: IKPaymentTransactionStateWrapper.failed,
  transactionIdentifier: 'txn002',
  error: const IKError(
      code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{}),
);

void main() {
  // 原安卓test：PurchaseWrapper - fromPurchase() should return correct PurchaseDetail object
  // 改造原因：鸿蒙版使用 AppGalleryPurchaseDetails.fromIKTransaction() 替代
  // GooglePlayPurchaseDetails.fromPurchase()，
  // 输入类型从 PurchaseWrapper 变为 IKPaymentTransactionWrapper + receiptData，
  // 输出类从 GooglePlayPurchaseDetails 变为 AppGalleryPurchaseDetails，
  // 属性映射也不同：
  // - purchaseID: orderId → transactionIdentifier
  // - productID: products[0] → payment.productId
  // - transactionDate: purchaseTime.toString() → (transactionTimeStamp * 1000).toInt().toString()
  // - verificationData: originalJson/purchaseToken → receiptData
  // - billingClientPurchase: PurchaseWrapper → ikPaymentTransaction
  // group('PurchaseWrapper', () {
  //   test('fromPurchase() should return correct PurchaseDetail object', () {
  //     final List<GooglePlayPurchaseDetails> details =
  //         GooglePlayPurchaseDetails.fromPurchase(dummyMultipleProductsPurchase);
  //     expect(details[0].purchaseID, dummyMultipleProductsPurchase.orderId);
  //     expect(details[0].productID, dummyMultipleProductsPurchase.products[0]);
  //     expect(details[0].transactionDate, dummyMultipleProductsPurchase.purchaseTime.toString());
  //     expect(details[0].verificationData, isNotNull);
  //     expect(details[0].verificationData.source, kIAPSource);
  //     expect(details[0].verificationData.localVerificationData, dummyMultipleProductsPurchase.originalJson);
  //     expect(details[0].verificationData.serverVerificationData, dummyMultipleProductsPurchase.purchaseToken);
  //     expect(details[0].billingClientPurchase, dummyMultipleProductsPurchase);
  //     expect(details[0].pendingCompletePurchase, false);
  //   });
  // });

  group('AppGalleryPurchaseDetails', () {
    test(
        'fromIKTransaction should return correct PurchaseDetails for purchased transaction',
        () {
      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        dummyTransaction,
        receiptData,
      );

      expect(purchase.productID, dummyTransaction.payment.productId);
      expect(purchase.purchaseID, dummyTransaction.transactionIdentifier);
      expect(purchase.status, PurchaseStatus.purchased);
      expect(purchase.verificationData.localVerificationData, receiptData);
      expect(purchase.verificationData.serverVerificationData, receiptData);
      expect(purchase.verificationData.source, kIAPSource);
      expect(purchase.ikPaymentTransaction, dummyTransaction);
      expect(purchase.pendingCompletePurchase, isTrue);
    });

    test(
        'fromIKTransaction should set correct transactionDate from transactionTimeStamp',
        () {
      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        dummyTransaction,
        receiptData,
      );

      // transactionTimeStamp is in seconds, transactionDate is in milliseconds
      final String expectedDate =
          (dummyTransaction.transactionTimeStamp! * 1000).toInt().toString();
      expect(purchase.transactionDate, expectedDate);
    });

    test('fromIKTransaction should handle null transactionTimeStamp', () {
      final IKPaymentTransactionWrapper transactionNoTimestamp =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(
          productId: 'com.example.product',
        ),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn003',
        transactionTimeStamp: null,
      );

      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        transactionNoTimestamp,
        receiptData,
      );

      expect(purchase.transactionDate, isNull);
    });

    // 原安卓test：fromPurchase() should set pendingCompletePurchase to true for unacknowledged purchase
    // 改造原因：鸿蒙版的 pendingCompletePurchase 逻辑不同：
    // - 安卓版：isAcknowledged == false 时 pendingCompletePurchase = true
    // - 鸿蒙版：status == purchased || restored 时 pendingCompletePurchase = true
    // 两者判定逻辑不同，无法直接映射
    // test('fromPurchase() should set pendingCompletePurchase to true for unacknowledged purchase', () {
    //   final GooglePlayPurchaseDetails details =
    //       GooglePlayPurchaseDetails.fromPurchase(dummyUnacknowledgedPurchase).first;
    //   expect(details.pendingCompletePurchase, true);
    // });

    test(
        'fromIKTransaction should set pendingCompletePurchase true for purchased status',
        () {
      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        dummyTransaction,
        receiptData,
      );

      expect(purchase.pendingCompletePurchase, isTrue);
    });

    test(
        'fromIKTransaction should set pendingCompletePurchase true for restored status',
        () {
      final IKPaymentTransactionWrapper restoredTransaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(
          productId: 'com.example.product',
        ),
        transactionState: IKPaymentTransactionStateWrapper.restored,
        transactionIdentifier: 'txn004',
      );

      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        restoredTransaction,
        receiptData,
      );

      expect(purchase.status, PurchaseStatus.restored);
      expect(purchase.pendingCompletePurchase, isTrue);
    });

    test(
        'fromIKTransaction should set canceled status for failed transaction with error code 2',
        () {
      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        dummyFailedTransaction,
        receiptData,
      );

      expect(purchase.status, PurchaseStatus.canceled);
      expect(purchase.error, isNotNull);
      expect(purchase.error!.source, kIAPSource);
      expect(purchase.error!.code, kPurchaseErrorCode);
    });

    test(
        'fromIKTransaction should set error status for failed transaction with other error code',
        () {
      final IKPaymentTransactionWrapper failedTransaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(
          productId: 'com.example.product',
        ),
        transactionState: IKPaymentTransactionStateWrapper.failed,
        transactionIdentifier: 'txn005',
        error: const IKError(
            code: 1, domain: 'SKErrorDomain', userInfo: <String, dynamic>{}),
      );

      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        failedTransaction,
        receiptData,
      );

      expect(purchase.status, PurchaseStatus.error);
      expect(purchase.error, isNotNull);
    });

    // 新鸿蒙test：测试 markCompletePurchaseHandled
    test(
        'markCompletePurchaseHandled should set pendingCompletePurchase to false',
        () {
      const String receiptData = 'base64ReceiptData';
      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(
        dummyTransaction,
        receiptData,
      );

      expect(purchase.pendingCompletePurchase, isTrue);
      purchase.markCompletePurchaseHandled();
      expect(purchase.pendingCompletePurchase, isFalse);
    });
  });

  // 新鸿蒙test：测试 IKPaymentTransactionStateWrapper 枚举值
  group('IKPaymentTransactionStateWrapper', () {
    test('has expected enum values', () {
      expect(IKPaymentTransactionStateWrapper.values.length, 6);
      expect(IKPaymentTransactionStateWrapper.purchasing.index, 0);
      expect(IKPaymentTransactionStateWrapper.purchased.index, 1);
      expect(IKPaymentTransactionStateWrapper.failed.index, 2);
      expect(IKPaymentTransactionStateWrapper.restored.index, 3);
      expect(IKPaymentTransactionStateWrapper.deferred.index, 4);
      expect(IKPaymentTransactionStateWrapper.unspecified.index, 5);
    });
  });

  // 新鸿蒙test：测试 IKPaymentTransactionWrapper.fromJson
  group('IKPaymentTransactionWrapper.fromJson', () {
    test('fromJson should deserialize basic transaction correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'payment': <String, dynamic>{
          'productId': 'com.example.consumable',
          'productType': 0,
        },
        'transactionState': 1, // purchased
        'transactionIdentifier': 'txn001',
        'transactionTimeStamp': 1700000000.0,
      };

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper.fromJson(json);

      expect(transaction.payment.productId, 'com.example.consumable');
      expect(transaction.payment.productType, ProductType.CONSUMABLE);
      expect(transaction.transactionState,
          IKPaymentTransactionStateWrapper.purchased);
      expect(transaction.transactionIdentifier, 'txn001');
      expect(transaction.transactionTimeStamp, 1700000000.0);
    });

    test('fromJson should deserialize transaction with error', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'payment': <String, dynamic>{
          'productId': 'com.example.product',
          'productType': 0,
        },
        'transactionState': 2, // failed
        'transactionIdentifier': 'txn002',
        'error': <String, dynamic>{
          'code': 2,
          'domain': 'SKErrorDomain',
          'userInfo': <String, dynamic>{},
        },
      };

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper.fromJson(json);

      expect(transaction.transactionState,
          IKPaymentTransactionStateWrapper.failed);
      expect(transaction.error, isNotNull);
      expect(transaction.error!.code, 2);
      expect(transaction.error!.domain, 'SKErrorDomain');
    });

    test('fromJson should deserialize transaction with originalTransaction',
        () {
      final Map<String, dynamic> json = <String, dynamic>{
        'payment': <String, dynamic>{
          'productId': 'com.example.subscription',
          'productType': 2, // AUTORENEWABLE
        },
        'transactionState': 3, // restored
        'transactionIdentifier': 'txn003',
        'transactionTimeStamp': 1700000000.0,
        'originalTransaction': <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.subscription',
            'productType': 2,
          },
          'transactionState': 1,
          'transactionIdentifier': 'original_txn',
          'transactionTimeStamp': 1600000000.0,
        },
      };

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper.fromJson(json);

      expect(transaction.transactionState,
          IKPaymentTransactionStateWrapper.restored);
      expect(transaction.originalTransaction, isNotNull);
      expect(transaction.originalTransaction!.transactionIdentifier,
          'original_txn');
    });

    test('fromJson should handle null optional fields', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'payment': <String, dynamic>{
          'productId': 'com.example.product',
        },
        'transactionState': 0, // purchasing
        'transactionIdentifier': null,
        'transactionTimeStamp': null,
        'error': null,
        'originalTransaction': null,
      };

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper.fromJson(json);

      expect(transaction.transactionIdentifier, isNull);
      expect(transaction.transactionTimeStamp, isNull);
      expect(transaction.error, isNull);
      expect(transaction.originalTransaction, isNull);
    });
  });

  // 新鸿蒙test：测试 IKProductSubscriptionPeriodWrapper.fromJson
  group('IKProductSubscriptionPeriodWrapper', () {
    test('fromJson should deserialize numberOfUnits and unit correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'numberOfUnits': 3,
        'unit': 2, // month
      };

      final IKProductSubscriptionPeriodWrapper period =
          IKProductSubscriptionPeriodWrapper.fromJson(json);

      expect(period.numberOfUnits, 3);
      expect(period.unit, IKSubscriptionPeriodUnit.month);
    });

    test('fromJson should handle null map with defaults', () {
      final IKProductSubscriptionPeriodWrapper period =
          IKProductSubscriptionPeriodWrapper.fromJson(null);

      expect(period.numberOfUnits, 0);
      expect(period.unit, IKSubscriptionPeriodUnit.day);
    });

    test('fromJson should handle missing fields with defaults', () {
      final Map<String, dynamic> json = <String, dynamic>{};

      final IKProductSubscriptionPeriodWrapper period =
          IKProductSubscriptionPeriodWrapper.fromJson(json);

      expect(period.numberOfUnits, 0);
      expect(period.unit, IKSubscriptionPeriodUnit.day); // null -> day default
    });
  });

  // 新鸿蒙test：测试 IKPaymentTransactionWrapper.toFinishMap 序列化
  group('IKPaymentTransactionWrapper.toFinishMap', () {
    test('serializes correctly for finishing transaction', () {
      final Map<String, Object?> map = dummyTransaction.toFinishMap();

      expect(map['transactionIdentifier'], 'txn001');
      expect(map['productIdentifier'], 'com.example.consumable');
      expect(map['productType'], 0); // CONSUMABLE = 0
    });

    test('serializes each product type to its numeric value', () {
      final List<(ProductType?, int?)> cases = <(ProductType?, int?)>[
        (ProductType.CONSUMABLE, 0),
        (ProductType.NONCONSUMABLE, 1),
        (ProductType.AUTORENEWABLE, 2),
        (ProductType.NONRENEWABLE, 3),
        (null, null),
      ];
      for (final (ProductType? type, int? expected) in cases) {
        final IKPaymentTransactionWrapper transaction =
            IKPaymentTransactionWrapper(
          payment: IKPaymentWrapper(
            productId: 'com.example.product',
            productType: type,
          ),
          transactionState: IKPaymentTransactionStateWrapper.purchased,
          transactionIdentifier: 'txn_type',
        );
        expect(transaction.toFinishMap()['productType'], expected);
      }
    });
  });

  // 新鸿蒙test：测试 IKPaymentTransactionWrapper 的相等性、hashCode 与 toString
  group('IKPaymentTransactionWrapper equality, hash and toString', () {
    test('== should return false for transactions with different fields', () {
      final IKPaymentTransactionWrapper first = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
      );
      final IKPaymentTransactionWrapper second = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn2',
      );
      expect(first == second, isFalse);
    });

    test('== should return false when compared with another runtime type', () {
      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
      );
      expect(transaction == Object(), isFalse);
    });

    test('hashCode should be consistent for equal transactions', () {
      final IKPaymentTransactionWrapper first = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
        transactionTimeStamp: 1700000000.0,
      );
      final IKPaymentTransactionWrapper second = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
        transactionTimeStamp: 1700000000.0,
      );
      expect(first.hashCode, second.hashCode);
    });

    test('toString should contain the serialized transaction data', () {
      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
      );
      expect(transaction.toString(), contains('com.example.product'));
      expect(transaction.toString(), contains('txn1'));
    });
  });
}
