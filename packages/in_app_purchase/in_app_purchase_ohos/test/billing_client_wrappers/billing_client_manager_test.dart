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
// 此文件原测试 BillingClientManager 的连接管理、重连、dispose等逻辑。
// 鸿蒙版使用 IKPaymentQueueWrapper + _TransactionObserver 模式，
// 不存在 BillingClientManager，因此原安卓test全部无法直接适配，
// 改为测试 IKPaymentQueueWrapper 的对应功能。

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IKPaymentQueueWrapper paymentQueue;

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    paymentQueue = IKPaymentQueueWrapper();
  });

  // 原安卓test：connects on initialization
  // 改造原因：鸿蒙版不使用BillingClientManager的startConnection连接机制，
  // 而是通过 IKPaymentQueueWrapper.setTransactionObserver + startObservingTransactionQueue
  // 初始化连接，逻辑完全不同，无法直接映射
  // group('BillingClientWrapper', () {
  //   test('connects on initialization', () {
  //     verify(mockApi.startConnection(any, any, any)).called(1);
  //   });
  // });

  // 新鸿蒙test：测试 IKPaymentQueueWrapper 的观察者设置和连接
  group('IKPaymentQueueWrapper', () {
    test('setTransactionObserver should set observer and handler', () async {
      final TestTransactionObserver observer = TestTransactionObserver();
      paymentQueue.setTransactionObserver(observer);

      // 验证观察者已设置，通过模拟回调验证
      expect(
          () => paymentQueue.handleObserverCallbacks(
              const MethodCall('updatedTransactions', <dynamic>[])),
          returnsNormally);
    });

    test('startObservingTransactionQueue invokes method channel', () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      await paymentQueue.startObservingTransactionQueue();
      expect(log, hasLength(1));
      expect(log.first.method, 'iap#startObservingTransactionQueue');
    });

    test('stopObservingTransactionQueue invokes method channel', () async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      await paymentQueue.stopObservingTransactionQueue();
      expect(log, hasLength(1));
      expect(log.first.method, 'iap#stopObservingTransactionQueue');
    });
  });

  // 新鸿蒙test：测试 IKPaymentQueueWrapper.handleObserverCallbacks with actual data
  group('IKPaymentQueueWrapper.handleObserverCallbacks', () {
    late TestTransactionObserver observer;

    setUp(() {
      observer = TestTransactionObserver();
      paymentQueue.setTransactionObserver(observer);
    });

    test('updatedTransactions should call observer with parsed transactions',
        () async {
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
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

      final MethodCall call = MethodCall(
        'updatedTransactions',
        transactionData,
      );

      await paymentQueue.handleObserverCallbacks(call);

      expect(observer.updatedTransactionsList, hasLength(1));
      expect(observer.updatedTransactionsList.first.payment.productId,
          'com.example.consumable');
      expect(observer.updatedTransactionsList.first.transactionState,
          IKPaymentTransactionStateWrapper.purchased);
      expect(observer.updatedTransactionsList.first.transactionIdentifier,
          'txn001');
    });

    test('removedTransactions should call observer with parsed transactions',
        () async {
      final List<Map<String, dynamic>> transactionData = <Map<String, dynamic>>[
        <String, dynamic>{
          'payment': <String, dynamic>{
            'productId': 'com.example.consumable',
            'productType': 0,
          },
          'transactionState': 1,
          'transactionIdentifier': 'txn002',
        },
      ];

      final MethodCall call = MethodCall(
        'removedTransactions',
        transactionData,
      );

      await paymentQueue.handleObserverCallbacks(call);

      expect(observer.removedTransactionsList, hasLength(1));
      expect(observer.removedTransactionsList.first.transactionIdentifier,
          'txn002');
    });

    test('unknown method should throw PlatformException', () async {
      final MethodCall call = MethodCall('unknownCallback', null);

      expect(
        () => paymentQueue.handleObserverCallbacks(call),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'no_such_callback')),
      );
    });
  });

  // 新鸿蒙test：测试 IKProductResponseWrapper.fromJson
  group('IKProductResponseWrapper.fromJson', () {
    test('fromJson should deserialize products and invalidProductIdentifiers',
        () {
      final Map<String, dynamic> json = <String, dynamic>{
        'products': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'com.example.product1',
            'type': 0,
            'name': 'Product 1',
            'description': 'Desc 1',
            'localPrice': '￥9.99',
            'microPrice': 9990000,
            'originalLocalPrice': '￥9.99',
            'originalMicroPrice': 9990000,
            'currency': 'CNY',
            'status': 0,
          },
          <String, dynamic>{
            'id': 'com.example.product2',
            'type': 1,
            'name': 'Product 2',
            'description': 'Desc 2',
            'localPrice': '\$4.99',
            'microPrice': 4990000,
            'originalLocalPrice': '\$4.99',
            'originalMicroPrice': 4990000,
            'currency': 'USD',
            'status': 0,
          },
        ],
        'invalidProductIdentifiers': <String>['invalid1', 'invalid2'],
      };

      final IKProductResponseWrapper response =
          IKProductResponseWrapper.fromJson(json);

      expect(response.products, hasLength(2));
      expect(response.products.first.id, 'com.example.product1');
      expect(response.products.first.type, ProductType.CONSUMABLE);
      expect(response.products[1].id, 'com.example.product2');
      expect(response.products[1].type, ProductType.NONCONSUMABLE);
      expect(
          response.invalidProductIdentifiers, <String>['invalid1', 'invalid2']);
    });

    test('fromJson should handle empty products and invalid identifiers', () {
      final Map<String, dynamic> json = <String, dynamic>{};

      final IKProductResponseWrapper response =
          IKProductResponseWrapper.fromJson(json);

      expect(response.products, isEmpty);
      expect(response.invalidProductIdentifiers, isEmpty);
    });
  });

  // 原安卓test：waits for connection before executing the operations
  // 改造原因：鸿蒙版没有 BillingClientManager.runWithClient/runWithClientNonRetryable
  // 这种"等待连接后执行"的模式，鸿蒙版使用 IKPaymentQueueWrapper 的直接调用，
  // 不需要重连逻辑
  // test('waits for connection before executing the operations', () async {
  //   ...
  // });

  // 原安卓test：re-connects when client sends onBillingServiceDisconnected
  // 改造原因：鸿蒙版不使用 BillingClient 的 onBillingServiceDisconnected 重连机制，
  // IAP Kit 通过平台侧自动管理连接状态，Dart层无需重连逻辑
  // test('re-connects when client sends onBillingServiceDisconnected', () async {
  //   ...
  // });

  // 原安卓test：re-connects when host calls reconnectWithBillingChoiceMode
  // 改造原因：鸿蒙版不支持 BillingChoiceMode（替代计费/用户选择计费模式），
  // AppGallery IAP Kit 不提供此功能
  // test('re-connects when host calls reconnectWithBillingChoiceMode', () async {
  //   ...
  // });

  // 原安卓test：re-connects when host calls reconnectWithPendingPurchasesParams
  // 改造原因：鸿蒙版不支持 PendingPurchasesParams，AppGallery IAP Kit
  // 没有预付费计划的待处理购买参数概念
  // test('re-connects when host calls reconnectWithPendingPurchasesParams', () async {
  //   ...
  // });

  // 原安卓test：re-connects when operation returns BillingResponse.serviceDisconnected
  // 改造原因：鸿蒙版没有 BillingResponse.serviceDisconnected 自动重连机制，
  // IAP Kit 不在 Dart 层处理断线重连
  // test('re-connects when operation returns BillingResponse.serviceDisconnected', () async {
  //   ...
  // });

  // 原安卓test：does not re-connect when disposed
  // 改造原因：鸿蒙版 IKPaymentQueueWrapper 是单例模式，
  // 不存在 dispose/endConnection 的概念
  // test('does not re-connect when disposed', () {
  //   ...
  // });

  // 原安卓test：Emits UserChoiceDetailsWrapper when onUserChoiceAlternativeBilling is called
  // 改造原因：鸿蒙版不支持替代计费（alternative billing）和用户选择计费，
  // AppGallery IAP Kit 不提供此功能
  // test('Emits UserChoiceDetailsWrapper when onUserChoiceAlternativeBilling is called', () async {
  //   ...
  // });
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
