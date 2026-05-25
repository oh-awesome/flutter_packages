// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/src/channel.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    InAppPurchaseOhosPlatform.registerPlatform();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'restorePurchases completes when native restore returns no purchases',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'iap#startObservingTransactionQueue':
          case 'iap#stopObservingTransactionQueue':
          case 'iap#restoreTransactions':
            return null;
          case 'iap#transactions':
            return <Map<String, Object?>>[];
        }
        return null;
      });

      final Stream<List<PurchaseDetails>> purchaseStream =
          InAppPurchasePlatform.instance.purchaseStream;
      final Completer<List<PurchaseDetails>> restoreEvent =
          Completer<List<PurchaseDetails>>();
      final StreamSubscription<List<PurchaseDetails>> subscription =
          purchaseStream.listen((List<PurchaseDetails> purchases) {
        if (!restoreEvent.isCompleted) {
          restoreEvent.complete(purchases);
        }
      });
      addTearDown(subscription.cancel);

      await InAppPurchasePlatform.instance.restorePurchases().timeout(
            const Duration(seconds: 2),
          );

      expect(await restoreEvent.future, isEmpty);
    },
  );

  test('purchaseStream replays unfinished transactions on first listen',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'iap#startObservingTransactionQueue':
        case 'iap#stopObservingTransactionQueue':
          return null;
        case 'iap#transactions':
          return <Map<String, Object?>>[
            <String, Object?>{
              'payment': <String, Object?>{
                'productId': 'unfinished-order-product',
                'productType': 1,
              },
              'transactionState': 1,
              'transactionIdentifier': 'unfinished-order-id',
            },
          ];
        case 'iap#retrieveReceiptData':
          return 'receipt-data';
      }
      return null;
    });

    final Completer<PurchaseDetails> completer = Completer<PurchaseDetails>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        InAppPurchasePlatform.instance.purchaseStream.listen(
      (List<PurchaseDetails> purchases) {
        if (!completer.isCompleted && purchases.isNotEmpty) {
          completer.complete(purchases.first);
        }
      },
    );
    addTearDown(subscription.cancel);

    final PurchaseDetails purchase =
        await completer.future.timeout(const Duration(seconds: 2));

    expect(purchase.productID, 'unfinished-order-product');
    expect(purchase.status, PurchaseStatus.purchased);
    expect(purchase.pendingCompletePurchase, isTrue);
  });

  test('buyConsumable forwards manual consumable purchases', () async {
    MethodCall? createPurchaseCall;
    MethodCall? finishPurchaseCall;
    final AppGalleryProductDetails productDetails =
        AppGalleryProductDetails.fromIKProduct(
      IKProductWrapper(
        id: 'consumable-id',
        type: ProductType.CONSUMABLE,
        name: 'Consumable',
        description: 'desc',
        localPrice: r'$1.00',
        microPrice: 1000000,
        originalLocalPrice: r'$1.00',
        originalMicroPrice: 1000000,
        currency: 'USD',
      ),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'iap#createPurchase':
          createPurchaseCall = call;
          return null;
        case 'iap#finishPurchase':
          finishPurchaseCall = call;
          return null;
        case 'iap#startObservingTransactionQueue':
        case 'iap#stopObservingTransactionQueue':
          return null;
        case 'iap#retrieveReceiptData':
          return 'receipt-data';
      }
      return null;
    });

    final Completer<PurchaseDetails> completer = Completer<PurchaseDetails>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        InAppPurchasePlatform.instance.purchaseStream.listen(
      (List<PurchaseDetails> purchases) {
        if (!completer.isCompleted && purchases.isNotEmpty) {
          completer.complete(purchases.first);
        }
      },
    );
    addTearDown(subscription.cancel);

    await InAppPurchasePlatform.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
      autoConsume: false,
    );

    InAppPurchaseOhosPlatform.observer.updatedTransactions(
      transactions: <IKPaymentTransactionWrapper>[
        IKPaymentTransactionWrapper(
          payment: const IKPaymentWrapper(
            productId: 'consumable-id',
            productType: ProductType.CONSUMABLE,
          ),
          transactionState: IKPaymentTransactionStateWrapper.purchased,
          transactionIdentifier: 'manual-consumable-order',
        ),
      ],
    );

    final PurchaseDetails purchase =
        await completer.future.timeout(const Duration(seconds: 2));
    expect(createPurchaseCall?.method, 'iap#createPurchase');
    expect(finishPurchaseCall, isNull);
    expect(purchase.status, PurchaseStatus.purchased);
    expect(purchase.pendingCompletePurchase, isTrue);
  });

  test('buyConsumable auto-consumes purchased consumables', () async {
    MethodCall? finishPurchaseCall;
    final AppGalleryProductDetails productDetails =
        AppGalleryProductDetails.fromIKProduct(
      IKProductWrapper(
        id: 'auto-consumable-id',
        type: ProductType.CONSUMABLE,
        name: 'Consumable',
        description: 'desc',
        localPrice: r'$1.00',
        microPrice: 1000000,
        originalLocalPrice: r'$1.00',
        originalMicroPrice: 1000000,
        currency: 'USD',
      ),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'iap#createPurchase':
        case 'iap#startObservingTransactionQueue':
        case 'iap#stopObservingTransactionQueue':
          return null;
        case 'iap#finishPurchase':
          finishPurchaseCall = call;
          return null;
        case 'iap#retrieveReceiptData':
          return 'receipt-data';
      }
      return null;
    });

    final Completer<PurchaseDetails> completer = Completer<PurchaseDetails>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        InAppPurchasePlatform.instance.purchaseStream.listen(
      (List<PurchaseDetails> purchases) {
        if (!completer.isCompleted && purchases.isNotEmpty) {
          completer.complete(purchases.first);
        }
      },
    );
    addTearDown(subscription.cancel);

    await InAppPurchasePlatform.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
    );

    InAppPurchaseOhosPlatform.observer.updatedTransactions(
      transactions: <IKPaymentTransactionWrapper>[
        IKPaymentTransactionWrapper(
          payment: const IKPaymentWrapper(
            productId: 'auto-consumable-id',
            productType: ProductType.CONSUMABLE,
          ),
          transactionState: IKPaymentTransactionStateWrapper.purchased,
          transactionIdentifier: 'auto-consumable-order',
        ),
      ],
    );

    final PurchaseDetails purchase =
        await completer.future.timeout(const Duration(seconds: 2));
    expect(finishPurchaseCall?.method, 'iap#finishPurchase');
    expect(finishPurchaseCall?.arguments, <String, Object?>{
      'transactionIdentifier': 'auto-consumable-order',
      'productIdentifier': 'auto-consumable-id',
      'productType': 0,
    });
    expect(purchase.status, PurchaseStatus.purchased);
    expect(purchase.pendingCompletePurchase, isFalse);
  });

  test('buyNonConsumable forwards NONRENEWABLE product type', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      capturedCall = call;
      return null;
    });

    final AppGalleryProductDetails productDetails =
        AppGalleryProductDetails.fromIKProduct(
      IKProductWrapper(
        id: 'nonrenewable-id',
        type: ProductType.NONRENEWABLE,
        name: 'Nonrenewable subscription',
        description: 'desc',
        localPrice: r'$8.00',
        microPrice: 8000000,
        originalLocalPrice: r'$8.00',
        originalMicroPrice: 8000000,
        currency: 'USD',
      ),
    );

    await InAppPurchasePlatform.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: productDetails),
    );

    expect(capturedCall?.method, 'iap#createPurchase');
    expect(
      (capturedCall?.arguments as Map<dynamic, dynamic>)['productType'],
      3,
    );
  });

  test('completePurchase forwards NONRENEWABLE product type', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      capturedCall = call;
      return null;
    });

    final AppGalleryPurchaseDetails purchaseDetails =
        AppGalleryPurchaseDetails.fromIKTransaction(
      IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(
          productId: 'nonrenewable-id',
          productType: ProductType.NONRENEWABLE,
        ),
        transactionState: IKPaymentTransactionStateWrapper.purchased,
        transactionIdentifier: 'nonrenewable-order-id',
      ),
      'receipt-data',
    );

    await InAppPurchasePlatform.instance.completePurchase(purchaseDetails);

    expect(capturedCall?.method, 'iap#finishPurchase');
    expect(capturedCall?.arguments, <String, Object?>{
      'transactionIdentifier': 'nonrenewable-order-id',
      'productIdentifier': 'nonrenewable-id',
      'productType': 3,
    });
  });

  test('countryCode forwards the OHOS system region', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'iap#countryCode') {
        return 'CN';
      }
      return null;
    });

    expect(await InAppPurchasePlatform.instance.countryCode(), 'CN');
  });

  test('refreshPurchaseVerificationData forwards refresh and receipt calls',
      () async {
    MethodCall? refreshCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'iap#refreshReceipt':
          refreshCall = call;
          return null;
        case 'iap#retrieveReceiptData':
          return 'receipt-data';
      }
      return null;
    });

    final InAppPurchaseOhosPlatformAddition addition =
        InAppPurchaseOhosPlatformAddition();
    final PurchaseVerificationData? verificationData =
        await addition.refreshPurchaseVerificationData();

    expect(refreshCall?.method, 'iap#refreshReceipt');
    expect(verificationData?.localVerificationData, 'receipt-data');
    expect(verificationData?.serverVerificationData, 'receipt-data');
    expect(verificationData?.source, kIAPSource);
  });

  test('subscription product type decodes from native enum value 2', () {
    final IKProductWrapper product =
        IKProductWrapper.fromJson(<String, dynamic>{
      'id': 'sub-id',
      'type': 2,
      'name': 'Subscription',
      'description': 'desc',
      'localPrice': r'$5.00',
      'microPrice': 5000000,
      'originalLocalPrice': r'$5.00',
      'originalMicroPrice': 5000000,
      'currency': 'USD',
    });

    expect(product.type, ProductType.AUTORENEWABLE);
  });

  test('nonrenewable subscription type decodes from native enum value 3', () {
    final IKProductWrapper product =
        IKProductWrapper.fromJson(<String, dynamic>{
      'id': 'nonrenewable-id',
      'type': 3,
      'name': 'Nonrenewable subscription',
      'description': 'desc',
      'localPrice': r'$8.00',
      'microPrice': 8000000,
      'originalLocalPrice': r'$8.00',
      'originalMicroPrice': 8000000,
      'currency': 'USD',
    });

    expect(product.type, ProductType.NONRENEWABLE);
  });

  test('restored transactions require completion', () {
    final AppGalleryPurchaseDetails purchaseDetails =
        AppGalleryPurchaseDetails.fromIKTransaction(
      IKPaymentTransactionWrapper(
        payment: const IKPaymentWrapper(productId: 'product-id'),
        transactionState: IKPaymentTransactionStateWrapper.restored,
        transactionIdentifier: 'order-id',
      ),
      'receipt-data',
    );

    expect(purchaseDetails.pendingCompletePurchase, isTrue);
  });
}
