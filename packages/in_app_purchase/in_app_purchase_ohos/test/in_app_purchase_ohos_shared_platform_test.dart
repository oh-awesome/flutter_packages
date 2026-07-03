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
// 此文件原测试 InAppPurchaseAndroidPlatform 的各种方法：
// connection management, isAvailable, queryProductDetails,
// restorePurchases, make payment (buyNonConsumable/buyConsumable),
// complete purchase, billingConfig。
// 鸿蒙版对应的是 InAppPurchaseOhosPlatform。

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InAppPurchaseOhosPlatform platform;

  setUp(() {
    platform = InAppPurchaseOhosPlatform();
  });

  // 原安卓test：connection management - connects on initialization
  // 改造原因：鸿蒙版不使用BillingClientManager的startConnection连接机制，
  // IKPaymentQueueWrapper是单例且通过平台侧自动管理连接
  // group('connection management', () {
  //   test('connects on initialization', () { ... });
  // });

  // 原安卓test：connection management - re-connects when client sends onBillingServiceDisconnected
  // 改造原因：鸿蒙版不使用BillingClient的onBillingServiceDisconnected重连机制
  // test('re-connects when client sends onBillingServiceDisconnected', () { ... });

  // 原安卓test：connection management - re-connects when operation returns BillingResponse.clientDisconnected
  // 改造原因：鸿蒙版没有BillingResponse.serviceDisconnected自动重连机制
  // test('re-connects when operation returns BillingResponse.clientDisconnected', () async { ... });

  // 原安卓test：isAvailable
  // 改造原因：鸿蒙版使用IKPaymentQueueWrapper.queryEnvironmentStatus()判断可用性，
  // 与安卓的BillingClient.isReady()实现完全不同
  // group('isAvailable', () {
  //   test('true', () async { ... });
  //   test('false', () async { ... });
  // });

  group('isAvailable', () {
    test('returns true when environment status is available', () async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );

      expect(await platform.isAvailable(), isTrue);
    });

    test('returns false when environment status is unavailable', () async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return false;
          }
          return null;
        },
      );

      expect(await platform.isAvailable(), isFalse);
    });
  });

  // 原安卓test：queryProductDetails
  // 改造原因：鸿蒙版使用IKRequestMaker.startProductRequest()查询商品，
  // 返回IKProductResponseWrapper转换为ProductDetailsResponse，
  // 与安卓的ProductDetailsResponseWrapper + BillingResultWrapper不同，
  // notFoundIDs的判定逻辑也不同
  // group('queryProductDetails', () {
  //   test('handles empty productDetails', () async { ... });
  //   test('should get correct product details', () async { ... });
  //   test('should get the correct notFoundIDs', () async { ... });
  //   test('should have error stored in the response when platform exception is thrown', () async { ... });
  // });

  group('queryProductDetails', () {
    test('should return ProductDetailsResponse on successful query', () async {
      const String productId = 'com.example.consumable';
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
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

      final ProductDetailsResponse response =
          await platform.queryProductDetails(<String>{productId});

      expect(response.productDetails, isNotEmpty);
      expect(response.notFoundIDs, isEmpty);
      expect(response.error, isNull);
      expect(response.productDetails.first.id, productId);
    });

    test('should return notFoundIDs on empty result', () async {
      const String invalidId = 'invalid_product';
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
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

      final ProductDetailsResponse response =
          await platform.queryProductDetails(<String>{invalidId});

      expect(response.productDetails, isEmpty);
      expect(response.notFoundIDs, contains(invalidId));
    });

    test(
        'should have error stored in response when platform exception is thrown',
        () async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#queryProducts') {
            throw PlatformException(
              code: 'error_code',
              message: 'error_message',
              details: <String, dynamic>{'info': 'error_info'},
            );
          }
          return null;
        },
      );

      final ProductDetailsResponse response =
          await platform.queryProductDetails(<String>{'invalid'});

      expect(response.notFoundIDs, <String>['invalid']);
      expect(response.productDetails, isEmpty);
      expect(response.error, isNotNull);
      expect(response.error!.source, kIAPSource);
      expect(response.error!.code, 'error_code');
      expect(response.error!.message, 'error_message');
      expect(response.error!.details, <String, dynamic>{'info': 'error_info'});
    });
  });

  // 原安卓test：restorePurchases
  // 改造原因：鸿蒙版的恢复购买通过IKPaymentQueueWrapper.restoreTransactions()完成，
  // 与安卓的BillingClient.queryPurchases() + 过滤逻辑不同
  // group('restorePurchases', () {
  //   test('should store platform exception in the response', () async { ... });
  //   test('returns ProductDetailsResponseWrapper', () async { ... });
  // });

  // 原安卓test：make payment系列（8个test）
  // 改造原因：鸿蒙版使用IKPaymentQueueWrapper.addPayment()发起购买，
  // 参数为IKPaymentWrapper，与安卓的BillingFlowParams不同，
  // 且安卓版有onPurchasesUpdated回调模式，鸿蒙版使用
  // IKTransactionObserverWrapper.updatedTransactions回调
  // group('make payment', () {
  //   test('buy non consumable, serializes and deserializes data', () async { ... });
  //   test('handles an error with an empty purchases list', () async { ... });
  //   test('buy consumable with auto consume, serializes and deserializes data', () async { ... });
  //   test('buyNonConsumable propagates failures to launch the billing flow', () async { ... });
  //   test('buyConsumable propagates failures to launch the billing flow', () async { ... });
  //   test('adds consumption failures to PurchaseDetails objects', () async { ... });
  //   test('buy consumable without auto consume, consume api should not receive calls', () async { ... });
  //   test('should get canceled purchase status when response code is BillingResponse.userCanceled', () async { ... });
  //   test('should get purchased purchase status when upgrading subscription by deferred proration mode', () async { ... });
  // });

  // 原安卓test：complete purchase success
  // 改造原因：鸿蒙版使用IKPaymentQueueWrapper.finishTransaction()完成购买，
  // 与安卓的acknowledgePurchase不同
  // group('complete purchase', () {
  //   test('complete purchase success', () async { ... });
  // });

  // 原安卓test：billingConfig - getCountryCode success
  // 改造原因：鸿蒙版通过MethodChannel 'iap#countryCode'获取国家代码，
  // 与安卓的BillingConfigWrapper.countryCode不同
  // group('billingConfig', () {
  //   test('getCountryCode success', () async { ... });
  // });

  group('countryCode', () {
    test('should return country code from method channel', () async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#countryCode') {
            return 'CN';
          }
          return null;
        },
      );

      final String code = await platform.countryCode();
      expect(code, 'CN');
    });

    test('should return empty string when country code is not available',
        () async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#countryCode') {
            return null;
          }
          return null;
        },
      );

      final String code = await platform.countryCode();
      expect(code, '');
    });
  });

  // 新鸿蒙test：测试 InAppPurchaseOhosPlatform.buyNonConsumable
  group('buyNonConsumable', () {
    test('should invoke addPayment and return true on success', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            return null; // success
          }
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );

      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.nonconsumable',
        type: ProductType.NONCONSUMABLE,
        name: 'Test Product',
        description: 'A test product',
        localPrice: '￥9.99',
        microPrice: 9990000,
        originalLocalPrice: '￥9.99',
        originalMicroPrice: 9990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: 'testUser',
      );

      final bool result =
          await platform.buyNonConsumable(purchaseParam: purchaseParam);

      expect(result, isTrue);
    });

    test('should return false on PlatformException', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            throw PlatformException(code: 'error', message: 'purchase failed');
          }
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );

      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.nonconsumable',
        type: ProductType.NONCONSUMABLE,
        name: 'Test Product',
        description: 'A test product',
        localPrice: '￥9.99',
        microPrice: 9990000,
        originalLocalPrice: '￥9.99',
        originalMicroPrice: 9990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool result =
          await platform.buyNonConsumable(purchaseParam: purchaseParam);

      expect(result, isFalse);
    });
  });

  // 新鸿蒙test：测试 InAppPurchaseOhosPlatform.buyConsumable
  group('buyConsumable', () {
    test('should invoke addPayment and return true on success', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            return null;
          }
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );

      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable',
        type: ProductType.CONSUMABLE,
        name: 'Test Consumable',
        description: 'A test consumable',
        localPrice: '￥1.99',
        microPrice: 1990000,
        originalLocalPrice: '￥1.99',
        originalMicroPrice: 1990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool result = await platform.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: true);

      expect(result, isTrue);
    });

    test('should return false on PlatformException', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#createPurchase') {
            throw PlatformException(code: 'error', message: 'purchase failed');
          }
          if (methodCall.method == 'iap#queryEnvironmentStatus') {
            return true;
          }
          return null;
        },
      );

      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable',
        type: ProductType.CONSUMABLE,
        name: 'Test Consumable',
        description: 'A test consumable',
        localPrice: '￥1.99',
        microPrice: 1990000,
        originalLocalPrice: '￥1.99',
        originalMicroPrice: 1990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool result =
          await platform.buyConsumable(purchaseParam: purchaseParam);

      expect(result, isFalse);
    });
  });

  // 新鸿蒙test：测试 InAppPurchaseOhosPlatform.completePurchase
  group('completePurchase', () {
    test('should invoke finishTransaction via method channel', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'iap#finishPurchase') {
            return null;
          }
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
        transactionIdentifier: 'txn001',
      );

      final AppGalleryPurchaseDetails purchase =
          AppGalleryPurchaseDetails.fromIKTransaction(transaction, 'receipt');

      await platform.completePurchase(purchase);

      expect(log.any((MethodCall call) => call.method == 'iap#finishPurchase'),
          isTrue);
    });
  });

  // 新鸿蒙test：测试 InAppPurchaseOhosPlatform.restorePurchases
  group('restorePurchases', () {
    test('should invoke restoreTransactions method channel', () async {
      InAppPurchaseOhosPlatform.registerPlatform();
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'iap#restoreTransactions') {
            return null;
          }
          return null;
        },
      );

      await platform.restorePurchases();

      expect(
          log.any(
              (MethodCall call) => call.method == 'iap#restoreTransactions'),
          isTrue);
    });
  });

  // 新鸿蒙test：测试 purchaseStream
  group('purchaseStream', () {
    test('should be a broadcast stream', () {
      // Need to register platform so _observer is initialized
      InAppPurchaseOhosPlatform.registerPlatform();
      // purchaseStream returns StreamController.broadcast().stream
      expect(platform.purchaseStream.isBroadcast, isTrue);
    });
  });

  // ============================================================================
  // _TransactionObserver 端到端功能测试
  // 通过 IKPaymentQueueWrapper.handleObserverCallbacks 模拟原生回调，
  // 验证 _TransactionObserver 内部逻辑（updatedTransactions →
  // _handleTransactionUpdates → _maybeAutoConsumePurchase → purchaseStream）
  // ============================================================================

  group('_TransactionObserver end-to-end', () {
    setUp(() {
      InAppPurchaseOhosPlatform.registerPlatform();
      // 模拟所有 MethodChannel 调用
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
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
            case 'iap#retrieveReceiptData':
              return 'testReceiptData';
            case 'iap#finishPurchase':
              return null;
            case 'iap#createPurchase':
              return null;
            case 'iap#restoreTransactions':
              return null;
            case 'iap#refreshReceipt':
              return null;
            case 'iap#countryCode':
              return 'CN';
            case 'iap#queryProducts':
              return <String, dynamic>{
                'products': <Map<String, dynamic>>[],
                'invalidProductIdentifiers': <String>[],
              };
            default:
              return null;
          }
        },
      );
    });

    test(
        'updatedTransactions with purchased non-consumable should emit on purchaseStream',
        () async {
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 updatedTransactions 回调
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.nonconsumable',
            'productType': 1, // NONCONSUMABLE
          },
          'transactionState': 1, // purchased
          'transactionIdentifier': 'txn_nonconsumable_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.nonconsumable');
      expect(result.first.purchaseID, 'txn_nonconsumable_001');
      expect(result.first.status, PurchaseStatus.purchased);
      expect(result.first.pendingCompletePurchase, isTrue);
    });

    test(
        'updatedTransactions with purchased consumable (autoConsume) should auto finishTransaction',
        () async {
      final List<MethodCall> finishLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#finishPurchase') {
            finishLog.add(methodCall);
            return null;
          }
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return 'testReceiptData';
          }
          if (methodCall.method == 'iap#startObservingTransactionQueue') {
            return null;
          }
          return null;
        },
      );

      // 先 buyConsumable 让 productId 加入 _productIdsToAutoConsume
      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable',
        type: ProductType.CONSUMABLE,
        name: 'Test Consumable',
        description: 'A test consumable',
        localPrice: '￥1.99',
        microPrice: 1990000,
        originalLocalPrice: '￥1.99',
        originalMicroPrice: 1990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      await platform.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: true);

      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 updatedTransactions 回调（消耗型购买成功）
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.consumable',
            'productType': 0, // CONSUMABLE
          },
          'transactionState': 1, // purchased
          'transactionIdentifier': 'txn_consumable_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.consumable');
      expect(result.first.status, PurchaseStatus.purchased);
      // autoConsume: finishTransaction 应被自动调用
      expect(finishLog, isNotEmpty);
      expect(finishLog.first.method, 'iap#finishPurchase');
      // autoConsume 后 pendingCompletePurchase 应被 markCompletePurchaseHandled 设为 false
      expect(result.first.pendingCompletePurchase, isFalse);
    });

    test(
        'updatedTransactions with purchased consumable (no autoConsume) should NOT finishTransaction',
        () async {
      final List<MethodCall> finishLog = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#finishPurchase') {
            finishLog.add(methodCall);
            return null;
          }
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return 'testReceiptData';
          }
          if (methodCall.method == 'iap#startObservingTransactionQueue') {
            return null;
          }
          if (methodCall.method == 'iap#createPurchase') {
            return null;
          }
          return null;
        },
      );

      // buyConsumable with autoConsume=false，productId 不应加入 _productIdsToAutoConsume
      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable_no_auto',
        type: ProductType.CONSUMABLE,
        name: 'Test Consumable No Auto',
        description: 'A test consumable without auto consume',
        localPrice: '￥1.99',
        microPrice: 1990000,
        originalLocalPrice: '￥1.99',
        originalMicroPrice: 1990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      await platform.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: false);

      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 updatedTransactions 回调
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.consumable_no_auto',
            'productType': 0, // CONSUMABLE
          },
          'transactionState': 1, // purchased
          'transactionIdentifier': 'txn_no_auto_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.consumable_no_auto');
      expect(result.first.status, PurchaseStatus.purchased);
      // no autoConsume: finishTransaction 不应被调用
      expect(finishLog, isEmpty);
      // pendingCompletePurchase 应为 true（未自动完成）
      expect(result.first.pendingCompletePurchase, isTrue);
    });

    test(
        'updatedTransactions with canceled transaction should emit canceled status on purchaseStream',
        () async {
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 failed + error.code=2 (user canceled) 的交易
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.canceled',
            'productType': 0,
          },
          'transactionState': 2, // failed
          'transactionIdentifier': 'txn_canceled_001',
          'error': <String, dynamic>{
            'code': 2,
            'domain': 'SKErrorDomain',
            'userInfo': <String, dynamic>{},
          },
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.canceled');
      expect(result.first.status, PurchaseStatus.canceled);
      expect(result.first.error, isNotNull);
      expect(result.first.pendingCompletePurchase, isFalse);
    });

    test(
        'updatedTransactions with error transaction should emit error status on purchaseStream',
        () async {
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 failed + error.code=1 (generic error)
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.error',
            'productType': 0,
          },
          'transactionState': 2, // failed
          'transactionIdentifier': 'txn_error_001',
          'error': <String, dynamic>{
            'code': 1,
            'domain': 'SKErrorDomain',
            'userInfo': <String, dynamic>{},
          },
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.error');
      expect(result.first.status, PurchaseStatus.error);
      expect(result.first.error, isNotNull);
      expect(result.first.pendingCompletePurchase, isFalse);
    });

    test(
        'updatedTransactions with restored transaction should emit restored status on purchaseStream',
        () async {
      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 restored 交易
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.restored',
            'productType': 1, // NONCONSUMABLE
          },
          'transactionState': 3, // restored
          'transactionIdentifier': 'txn_restored_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      expect(result.first.productID, 'com.example.restored');
      expect(result.first.status, PurchaseStatus.restored);
      expect(result.first.pendingCompletePurchase, isTrue);
    });

    test(
        'autoConsume failure should set purchase status to error with kAutoConsumeErrorCode',
        () async {
      // 模拟 finishPurchase 抛 PlatformException（自动消耗失败）
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#finishPurchase') {
            throw PlatformException(
                code: 'consume_error', message: 'auto consume failed');
          }
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return 'testReceiptData';
          }
          if (methodCall.method == 'iap#startObservingTransactionQueue') {
            return null;
          }
          return null;
        },
      );

      // buyConsumable 让 productId 加入 _productIdsToAutoConsume
      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable_fail',
        type: ProductType.CONSUMABLE,
        name: 'Test Consumable Fail',
        description: 'A test consumable that fails auto consume',
        localPrice: '￥1.99',
        microPrice: 1990000,
        originalLocalPrice: '￥1.99',
        originalMicroPrice: 1990000,
        currency: 'CNY',
        status: ProductStatus.VALID,
      );
      final AppGalleryProductDetails productDetails =
          AppGalleryProductDetails.fromIKProduct(product);
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      await platform.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: true);

      final Completer<List<PurchaseDetails>> completer =
          Completer<List<PurchaseDetails>>();
      late StreamSubscription<List<PurchaseDetails>> subscription;
      subscription =
          platform.purchaseStream.listen((List<PurchaseDetails> details) {
        completer.complete(details);
        subscription.cancel();
      });

      // 模拟原生推送 purchased 交易 → _maybeAutoConsumePurchase 尝试自动消耗但失败
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.consumable_fail',
            'productType': 0, // CONSUMABLE
          },
          'transactionState': 1, // purchased
          'transactionIdentifier': 'txn_consume_fail_001',
          'transactionTimeStamp': 1700000000.0,
        },
      ];

      final MethodCall call =
          MethodCall('updatedTransactions', transactionData);
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);

      final List<PurchaseDetails> result = await completer.future;

      expect(result, hasLength(1));
      // 自动消耗失败 → status 应为 error
      expect(result.first.status, PurchaseStatus.error);
      expect(result.first.error, isNotNull);
      expect(result.first.error!.code, kAutoConsumeErrorCode);
      expect(result.first.error!.source, kIAPSource);
    });

    test(
        'removedTransactions callback should call observer.removedTransactions',
        () async {
      // 模拟 removedTransactions 回调
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.removed',
            'productType': 0,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn_removed_001',
        },
      ];

      final MethodCall call =
          MethodCall('removedTransactions', transactionData);
      // removedTransactions 只调用 observer.removedTransactions，
      // 不会向 purchaseStream 发射数据，所以不应抛异常
      await IKPaymentQueueWrapper().handleObserverCallbacks(call);
      // 测试不挂掉即可（removedTransactions 逻辑是 _forgetTransactions，内部操作）
    });
  });
}
