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
// 此文件原测试 BillingClient 的各种API：isReady, startConnection, endConnection,
// queryProductDetails, launchBillingFlow, queryPurchases, queryPurchaseHistory,
// consumeAsync, acknowledgePurchase, isFeatureSupported, billingConfig,
// isAlternativeBillingOnlyAvailable, createAlternativeBillingOnlyReportingDetails,
// showAlternativeBillingOnlyInformationDialog。
// 鸿蒙版对应的是 IKPaymentQueueWrapper，API结构完全不同。

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IKPaymentQueueWrapper paymentQueue;

  setUp(() {
    paymentQueue = IKPaymentQueueWrapper();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/in_app_purchase'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'iap#queryEnvironmentStatus':
            return true;
          case 'iap#startObservingTransactionQueue':
            return null;
          case 'iap#stopObservingTransactionQueue':
            return null;
          case 'iap#transactions':
            return <dynamic>[];
          default:
            return null;
        }
      },
    );
  });

  // 重置 mock handler，避免测试间状态泄漏
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/in_app_purchase'),
      null,
    );
  });

  // 原安卓test：isReady true/false
  // 改造原因：鸿蒙版使用 IKPaymentQueueWrapper.queryEnvironmentStatus()
  // 替代 BillingClient.isReady()，方法名和语义不同
  group('queryEnvironmentStatus', () {
    // // 原安卓test：
    // test('true', () async {
    //   when(mockApi.isReady()).thenAnswer((_) async => true);
    //   expect(await billingClient.isReady(), isTrue);
    // });
    test('returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );
      expect(await IKPaymentQueueWrapper.queryEnvironmentStatus(), isTrue);
    });

    // // 原安卓test：
    // test('false', () async {
    //   when(mockApi.isReady()).thenAnswer((_) async => false);
    //   expect(await billingClient.isReady(), isFalse);
    // });
    test('returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return false;
          }
          return null;
        },
      );
      expect(await IKPaymentQueueWrapper.queryEnvironmentStatus(), isFalse);
    });
  });

  // 原安卓test：startConnection系列
  // 改造原因：鸿蒙版不使用 BillingClient.startConnection() 的连接机制，
  // 而是通过 IKPaymentQueueWrapper.startObservingTransactionQueue() 启动，
  // 没有 BillingResultWrapper 返回值，也没有 BillingChoiceMode/PendingPurchasesParams
  // // 原安卓test：
  // group('startConnection', () {
  //   test('returns BillingResultWrapper', () async { ... });
  //   test('passes default values to onBillingServiceDisconnected', () async { ... });
  //   test('passes billingChoiceMode alternativeBillingOnly when set', () async { ... });
  //   test('passes billingChoiceMode userChoiceBilling when set', () async { ... });
  //   test('passes pendingPurchasesParams when set', () async { ... });
  // });

  // 原安卓test：endConnection
  // 改造原因：鸿蒙版 IKPaymentQueueWrapper 是单例，不支持 endConnection，
  // 使用 stopObservingTransactionQueue 替代
  // test('endConnection', () async {
  //   verifyNever(mockApi.endConnection());
  //   await billingClient.endConnection();
  //   verify(mockApi.endConnection()).called(1);
  // });

  // 原安卓test：queryProductDetails系列
  // 改造原因：鸿蒙版使用 IKRequestMaker.startProductRequest() 查询商品，
  // 返回 IKProductResponseWrapper（包含 IKProductWrapper 列表和无效ID列表），
  // 与安卓 ProductDetailsResponseWrapper 结构完全不同
  // group('queryProductDetails', () {
  //   test('handles empty productDetails', () async { ... });
  //   test('returns ProductDetailsResponseWrapper', () async { ... });
  // });

  // 新鸿蒙test：测试 IKRequestMaker.startProductRequest
  group('IKRequestMaker startProductRequest', () {
    test('returns IKProductResponseWrapper with products', () async {
      const String productId = 'com.example.product';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryProducts') {
            return <String, dynamic>{
              'products': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': productId,
                  'type': 0,
                  'name': 'Test Product',
                  'description': 'A test product',
                  'localPrice': '￥9.99',
                  'microPrice': 9990000,
                  'originalLocalPrice': '￥9.99',
                  'originalMicroPrice': 9990000,
                  'currency': 'CNY',
                  'status': 0,
                },
              ],
              'invalidProductIdentifiers': <String>[],
            };
          }
          return null;
        },
      );

      final IKRequestMaker requestMaker = IKRequestMaker();
      final IKProductResponseWrapper response =
          await requestMaker.startProductRequest(<String>[productId]);

      expect(response.products, isNotEmpty);
      expect(response.products.first.id, productId);
      expect(response.invalidProductIdentifiers, isEmpty);
    });

    test('returns IKProductResponseWrapper with invalid identifiers', () async {
      const String invalidId = 'invalid_product';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryProducts') {
            return <String, dynamic>{
              'products': <Map<String, dynamic>>[],
              'invalidProductIdentifiers': <String>[invalidId],
            };
          }
          return null;
        },
      );

      final IKRequestMaker requestMaker = IKRequestMaker();
      final IKProductResponseWrapper response =
          await requestMaker.startProductRequest(<String>[invalidId]);

      expect(response.products, isEmpty);
      expect(response.invalidProductIdentifiers, contains(invalidId));
    });
  });

  // 原安卓test：launchBillingFlow系列
  // 改造原因：鸿蒙版使用 IKPaymentQueueWrapper.addPayment() 发起支付，
  // 参数为 IKPaymentWrapper（productId, productType, developerPayload等），
  // 与安卓 BillingFlowParams（product, accountId, obfuscatedProfileId,
  // oldProduct, purchaseToken, replacementMode）结构不同
  // group('launchBillingFlow', () {
  //   test('serializes and deserializes data', () async { ... });
  //   test('Change subscription throws assertion error', () async { ... });
  //   test('serializes and deserializes data on change subscription without proration', () async { ... });
  //   test('serializes and deserializes data on change subscription with proration', () async { ... });
  //   test('serializes and deserializes data when using immediateAndChargeFullPrice', () async { ... });
  //   test('handles null accountId', () async { ... });
  // });

  // 新鸿蒙test：测试 IKPaymentWrapper.toMap 序列化
  group('IKPaymentWrapper serialization', () {
    test('toMap should serialize all fields correctly', () {
      const IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.consumable',
        productType: ProductType.CONSUMABLE,
        developerPayload: 'testPayload',
        applicationUserName: 'testUser',
      );

      final Map<String, dynamic> map = payment.toMap();

      expect(map['productId'], 'com.example.consumable');
      expect(map['productType'], 0); // CONSUMABLE = 0
      expect(map['developerPayload'], 'testPayload');
      expect(map['applicationUserName'], 'testUser');
    });

    test('toMap should handle null optional fields', () {
      const IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.nonconsumable',
      );

      final Map<String, dynamic> map = payment.toMap();

      expect(map['productId'], 'com.example.nonconsumable');
      expect(map['productType'], isNull);
      expect(map['developerPayload'], isNull);
      expect(map['reservedInfo'], isNull);
      expect(map['promotionalOfferId'], isNull);
      expect(map['applicationUserName'], isNull);
      expect(map['jwsRepresentation'], isNull);
    });
  });

  // 原安卓test：queryPurchases系列
  // 改造原因：鸿蒙版使用 IKPaymentQueueWrapper.transactions() 获取交易列表，
  // 返回 List<IKPaymentTransactionWrapper>，与安卓的
  // PurchasesResultWrapper（包含 billingResult + purchasesList）结构不同
  // group('queryPurchases', () {
  //   test('serializes and deserializes data', () async { ... });
  //   test('handles empty purchases', () async { ... });
  // });

  // 原安卓test：queryPurchaseHistory系列
  // 改造原因：鸿蒙版不支持 queryPurchaseHistory API，
  // AppGallery IAP Kit 没有此功能
  // group('queryPurchaseHistory', () {
  //   test('handles empty purchases', () async { ... });
  // });

  // 原安卓test：consume purchases - consumeAsync
  // 改造原因：鸿蒙版不使用 consumeAsync API，消费型商品的消耗通过
  // IKPaymentQueueWrapper.finishTransaction 完成，与安卓的 consumeAsync 不同
  // group('consume purchases', () {
  //   test('consume purchase async success', () async { ... });
  // });

  // 新鸿蒙test：测试 finishTransaction
  group('finishTransaction', () {
    test('finishTransaction invokes method channel correctly', () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(
          productId: 'com.example.consumable',
          productType: ProductType.CONSUMABLE,
        ),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'transaction123',
      );

      await paymentQueue.finishTransaction(transaction);

      expect(log, hasLength(1));
      expect(log.first.method, 'iap#finishPurchase');
      expect(log.first.arguments['transactionIdentifier'], 'transaction123');
      expect(
          log.first.arguments['productIdentifier'], 'com.example.consumable');
      expect(log.first.arguments['productType'], 0);
    });
  });

  // 原安卓test：acknowledge purchases - acknowledgePurchase
  // 改造原因：鸿蒙版不使用 acknowledgePurchase API，
  // 确认购买通过 IKPaymentQueueWrapper.finishTransaction 完成，
  // 与安卓的 acknowledgePurchase 不同
  // group('acknowledge purchases', () {
  //   test('acknowledge purchase success', () async { ... });
  // });

  // 原安卓test：isFeatureSupported系列
  // 改造原因：鸿蒙版不支持 isFeatureSupported API，
  // AppGallery IAP Kit 没有此功能
  // group('isFeatureSupported', () {
  //   test('isFeatureSupported returns false', () async { ... });
  //   test('isFeatureSupported returns true', () async { ... });
  // });

  // 原安卓test：billingConfig - getBillingConfig
  // 改造原因：鸿蒙版使用 InAppPurchaseOhosPlatform.countryCode()
  // 通过 MethodChannel 获取国家代码，与安卓的 BillingConfigWrapper 结构不同
  // group('billingConfig', () {
  //   test('billingConfig returns object', () async { ... });
  // });

  // 原安卓test：isAlternativeBillingOnlyAvailable
  // 改造原因：鸿蒙版不支持替代计费（alternative billing only），
  // AppGallery IAP Kit 不提供此功能
  // group('isAlternativeBillingOnlyAvailable', () {
  //   test('returns object', () async { ... });
  // });

  // 原安卓test：createAlternativeBillingOnlyReportingDetails
  // 改造原因：鸿蒙版不支持替代计费报告详情，
  // AppGallery IAP Kit 不提供此功能
  // group('createAlternativeBillingOnlyReportingDetails', () {
  //   test('returns object', () async { ... });
  // });

  // 原安卓test：showAlternativeBillingOnlyInformationDialog
  // 改造原因：鸿蒙版不支持替代计费信息对话框，
  // AppGallery IAP Kit 不提供此功能
  // group('showAlternativeBillingOnlyInformationDialog', () {
  //   test('returns object', () async { ... });
  // });

  // 新鸿蒙test：测试 IKError 的相等性
  group('IKError', () {
    test('operator == works correctly', () {
      const IKError first = IKError(
          code: 2,
          domain: 'SKErrorDomain',
          userInfo: <String, dynamic>{'key': 'value'});
      const IKError second = IKError(
          code: 2,
          domain: 'SKErrorDomain',
          userInfo: <String, dynamic>{'key': 'value'});
      expect(first == second, isTrue);
    });

    test('operator == returns false for different errors', () {
      const IKError first = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      const IKError second = IKError(
          code: 3, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      expect(first == second, isFalse);
    });
  });

  // 新鸿蒙test：测试 IKPaymentWrapper 的相等性
  group('IKPaymentWrapper', () {
    test('operator == works correctly for identical payments', () {
      const IKPaymentWrapper first = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.CONSUMABLE,
      );
      const IKPaymentWrapper second = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.CONSUMABLE,
      );
      expect(first == second, isTrue);
    });

    test('operator == returns false for different payments', () {
      const IKPaymentWrapper first = IKPaymentWrapper(
        productId: 'com.example.product1',
      );
      const IKPaymentWrapper second = IKPaymentWrapper(
        productId: 'com.example.product2',
      );
      expect(first == second, isFalse);
    });
  });

  // 新鸿蒙test：测试 IKPaymentQueueWrapper.addPayment
  group('IKPaymentQueueWrapper.addPayment', () {
    test('addPayment invokes iap#createPurchase method channel', () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      // addPayment requires observer to be set
      final TestTransactionObserver observer = TestTransactionObserver();
      paymentQueue.setTransactionObserver(observer);

      const IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.consumable',
        productType: ProductType.CONSUMABLE,
        developerPayload: 'testPayload',
      );

      await paymentQueue.addPayment(payment);

      expect(log, hasLength(1));
      expect(log.first.method, 'iap#createPurchase');
      expect(log.first.arguments['productId'], 'com.example.consumable');
      expect(log.first.arguments['productType'], 0);
      expect(log.first.arguments['developerPayload'], 'testPayload');
    });
  });

  // 新鸿蒙test：测试 IKPaymentQueueWrapper.transactions
  group('IKPaymentQueueWrapper.transactions', () {
    test('transactions invokes iap#transactions and returns parsed list',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#transactions') {
            return <Map<String, dynamic>>[
              <String, dynamic>{
                'payment': <String, dynamic>{
                  'productId': 'com.example.consumable',
                  'productType': 0,
                },
                'transactionState': 1, // purchased
                'transactionIdentifier': 'txn001',
                'transactionTimeStamp': 1700000000.0,
              },
            ];
          }
          return null;
        },
      );

      final List<IKPaymentTransactionWrapper> transactions =
          await paymentQueue.transactions();

      expect(transactions, hasLength(1));
      expect(transactions.first.payment.productId, 'com.example.consumable');
      expect(transactions.first.transactionState,
          IKPaymentTransactionStateWrapper.purchased);
      expect(transactions.first.transactionIdentifier, 'txn001');
    });
  });

  // 新鸿蒙test：测试 IKPaymentQueueWrapper.restoreTransactions
  group('IKPaymentQueueWrapper.restoreTransactions', () {
    test('restoreTransactions invokes iap#restoreTransactions method channel',
        () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      await paymentQueue.restoreTransactions(applicationUserName: 'testUser');

      expect(log, hasLength(1));
      expect(log.first.method, 'iap#restoreTransactions');
      expect(log.first.arguments, 'testUser');
    });
  });

  // 新鸿蒙test：测试 IKRequestMaker.startRefreshReceiptRequest
  group('IKRequestMaker.startRefreshReceiptRequest', () {
    test('startRefreshReceiptRequest invokes iap#refreshReceipt method channel',
        () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final IKRequestMaker requestMaker = IKRequestMaker();
      await requestMaker.startRefreshReceiptRequest();

      expect(log, hasLength(1));
      expect(log.first.method, 'iap#refreshReceipt');
    });
  });

  // 新鸿蒙test：测试 IKPaymentWrapper.fromJson
  group('IKPaymentWrapper.fromJson', () {
    test('fromJson should deserialize all fields correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'productId': 'com.example.product',
        'productType': 1, // NONCONSUMABLE
        'developerPayload': 'payload',
        'reservedInfo': '{"key":"value"}',
        'promotionalOfferId': 'offer123',
        'applicationUserName': 'user1',
        'jwsRepresentation': 'jws_data',
      };

      final IKPaymentWrapper payment = IKPaymentWrapper.fromJson(json);

      expect(payment.productId, 'com.example.product');
      expect(payment.productType, ProductType.NONCONSUMABLE);
      expect(payment.developerPayload, 'payload');
      expect(payment.reservedInfo, '{"key":"value"}');
      expect(payment.promotionalOfferId, 'offer123');
      expect(payment.applicationUserName, 'user1');
      expect(payment.jwsRepresentation, 'jws_data');
    });

    test('fromJson should handle default values for missing fields', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'productId': 'com.example.minimal',
      };

      final IKPaymentWrapper payment = IKPaymentWrapper.fromJson(json);

      expect(payment.productId, 'com.example.minimal');
      expect(payment.productType, ProductType.CONSUMABLE); // default 0
      expect(payment.developerPayload, isNull);
      expect(payment.reservedInfo, isNull);
      expect(payment.promotionalOfferId, isNull);
      expect(payment.applicationUserName, isNull);
      expect(payment.jwsRepresentation, isNull);
    });
  });

  // 新鸿蒙test：测试 IKError.fromJson
  group('IKError.fromJson', () {
    test('fromJson should deserialize all fields correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'code': 2,
        'domain': 'SKErrorDomain',
        'userInfo': <String, dynamic>{'key': 'value'},
      };

      final IKError error = IKError.fromJson(json);

      expect(error.code, 2);
      expect(error.domain, 'SKErrorDomain');
      expect(error.userInfo, <String, dynamic>{'key': 'value'});
    });

    test('fromJson should handle default values for missing fields', () {
      final Map<String, dynamic> json = <String, dynamic>{};

      final IKError error = IKError.fromJson(json);

      expect(error.code, 0);
      expect(error.domain, '');
      expect(error.userInfo, <String, dynamic>{});
    });
  });

  // 新鸿蒙test：测试 IKPaymentTransactionStateWrapper 的相等性
  group('IKPaymentTransactionWrapper', () {
    test('operator == works correctly', () {
      final IKPaymentTransactionWrapper first = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
      );
      final IKPaymentTransactionWrapper second = IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn1',
      );
      expect(first == second, isTrue);
    });
  });

  // 新鸿蒙test：补充 IKError 的 hashCode、toString 与跨类型比较
  group('IKError equality and hash', () {
    test('== returns false when compared with another runtime type', () {
      const IKError error = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      expect(error == Object(), isFalse);
    });

    test('== returns false when only the userInfo differs', () {
      const IKError first = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{'a': 1});
      const IKError second = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{'b': 2});
      expect(first == second, isFalse);
    });

    test('hashCode is consistent for equal errors', () {
      const IKError first = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{'a': 1});
      const IKError second = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{'a': 1});
      expect(first.hashCode, second.hashCode);
    });
  });

  // 新鸿蒙test：补充 IKPaymentWrapper 的相等性、hashCode 与 toString
  group('IKPaymentWrapper equality, hash and toString', () {
    test('== compares every field for non-identical instances', () {
      final IKPaymentWrapper first = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.CONSUMABLE,
        developerPayload: 'payload',
        reservedInfo: 'reserved',
        promotionalOfferId: 'offer',
        applicationUserName: 'user',
        jwsRepresentation: 'jws',
      );
      final IKPaymentWrapper second = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.CONSUMABLE,
        developerPayload: 'payload',
        reservedInfo: 'reserved',
        promotionalOfferId: 'offer',
        applicationUserName: 'user',
        jwsRepresentation: 'jws',
      );
      expect(first == second, isTrue);
    });

    test('== returns false when a single optional field differs', () {
      final IKPaymentWrapper first = IKPaymentWrapper(
        productId: 'com.example.product',
        developerPayload: 'payload',
      );
      final IKPaymentWrapper second = IKPaymentWrapper(
        productId: 'com.example.product',
        developerPayload: 'different',
      );
      expect(first == second, isFalse);
    });

    test('== returns false when compared with another runtime type', () {
      final IKPaymentWrapper payment =
          IKPaymentWrapper(productId: 'com.example.product');
      expect(payment == Object(), isFalse);
    });

    test('hashCode is consistent for equal payments', () {
      final IKPaymentWrapper first = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.AUTORENEWABLE,
        developerPayload: 'payload',
      );
      final IKPaymentWrapper second = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.AUTORENEWABLE,
        developerPayload: 'payload',
      );
      expect(first.hashCode, second.hashCode);
    });

    test('toString serializes the payment fields', () {
      final IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.product',
        productType: ProductType.CONSUMABLE,
      );
      expect(payment.toString(), contains('com.example.product'));
      expect(payment.toString(), contains('productType'));
    });
  });

  // 新鸿蒙test：补充 IKPaymentWrapper.fromJson 对订阅类型的解析
  group('IKPaymentWrapper.fromJson product types', () {
    test('fromJson parses an AUTORENEWABLE product type', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'productId': 'com.example.subscription',
        'productType': 2,
      };

      final IKPaymentWrapper payment = IKPaymentWrapper.fromJson(json);

      expect(payment.productType, ProductType.AUTORENEWABLE);
    });

    test('fromJson parses a NONRENEWABLE product type', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'productId': 'com.example.nonrenewable',
        'productType': 3,
      };

      final IKPaymentWrapper payment = IKPaymentWrapper.fromJson(json);

      expect(payment.productType, ProductType.NONRENEWABLE);
    });
  });

  // 新鸿蒙test：补充 IKRequestMaker.startProductRequest 无响应的异常路径
  group('IKRequestMaker.startProductRequest no response', () {
    test('should throw a PlatformException when the platform returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryProducts') {
            return null;
          }
          return null;
        },
      );

      final IKRequestMaker requestMaker = IKRequestMaker();

      await expectLater(
        requestMaker.startProductRequest(<String>['com.example.product']),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  // 新鸿蒙test：补充 IKPaymentQueueWrapper 异常场景
  group('IKPaymentQueueWrapper.addPayment failure', () {
    test('should propagate a PlatformException when createPurchase fails',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            throw PlatformException(code: 'IAP_3', message: 'create failed');
          }
          return null;
        },
      );

      final TestTransactionObserver observer = TestTransactionObserver();
      paymentQueue.setTransactionObserver(observer);
      const IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.consumable',
      );

      await expectLater(
        paymentQueue.addPayment(payment),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'IAP_3')),
      );
    });

    test(
        'should propagate a timeout PlatformException when createPurchase '
        'times out', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            throw PlatformException(
                code: 'timeout', message: 'request timed out');
          }
          return null;
        },
      );

      final TestTransactionObserver observer = TestTransactionObserver();
      paymentQueue.setTransactionObserver(observer);
      const IKPaymentWrapper payment = IKPaymentWrapper(
        productId: 'com.example.consumable',
      );

      await expectLater(
        paymentQueue.addPayment(payment),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'timeout')),
      );
    });
  });

  group('IKPaymentQueueWrapper.transactions edge cases', () {
    test('should return an empty list when the platform returns no transactions',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#transactions') {
            return <dynamic>[];
          }
          return null;
        },
      );

      final List<IKPaymentTransactionWrapper> transactions =
          await paymentQueue.transactions();

      expect(transactions, isEmpty);
    });

    test('should propagate a PlatformException when the platform errors',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#transactions') {
            throw PlatformException(
                code: 'IAP_1', message: 'service disconnected');
          }
          return null;
        },
      );

      await expectLater(
        paymentQueue.transactions(),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'IAP_1')),
      );
    });
  });

  group('IKPaymentQueueWrapper.restoreTransactions failure', () {
    test('should propagate a PlatformException when restore fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#restoreTransactions') {
            throw PlatformException(code: 'IAP_6', message: 'restore failed');
          }
          return null;
        },
      );

      await expectLater(
        paymentQueue.restoreTransactions(applicationUserName: 'user1'),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'IAP_6')),
      );
    });
  });

  group('IKPaymentQueueWrapper.finishTransaction edge cases', () {
    test('should send a null transactionIdentifier without crashing',
        () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: null,
      );

      await paymentQueue.finishTransaction(transaction);

      expect(log, hasLength(1));
      expect(log.first.arguments['transactionIdentifier'], isNull);
    });

    test('should propagate a PlatformException when finish fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#finishPurchase') {
            throw PlatformException(
                code: 'IAP_4', message: 'purchase not found');
          }
          return null;
        },
      );

      final IKPaymentTransactionWrapper transaction =
          IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'com.example.product'),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'txn001',
      );

      await expectLater(
        paymentQueue.finishTransaction(transaction),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'IAP_4')),
      );
    });
  });
}

class TestTransactionObserver implements IKTransactionObserverWrapper {
  final List<IKPaymentTransactionWrapper> updatedTransactionsList = [];
  final List<IKPaymentTransactionWrapper> removedTransactionsList = [];

  @override
  void updatedTransactions(
      {required List<IKPaymentTransactionWrapper> transactions}) {
    updatedTransactionsList.addAll(transactions);
  }

  @override
  void removedTransactions(
      {required List<IKPaymentTransactionWrapper> transactions}) {
    removedTransactionsList.addAll(transactions);
  }
}
