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
// 此文件原测试 InAppPurchaseAndroidPlatformAddition 的各种方法：
// consumePurchase, getCountryCode, setBillingChoice,
// isAlternativeBillingOnlyAvailable, showAlternativeBillingOnlyInformationDialog,
// queryPastPurchases, isFeatureSupported, userChoiceDetails。
// 鸿蒙版对应的是 InAppPurchaseOhosPlatformAddition，仅有
// refreshPurchaseVerificationData 方法。

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InAppPurchaseOhosPlatformAddition addition;

  setUp(() {
    addition = InAppPurchaseOhosPlatformAddition();
  });

  // 原安卓test：consume purchases - consume purchase async success
  // 改造原因：鸿蒙版不支持consumePurchase API，
  // AppGallery IAP Kit通过finishTransaction完成消费型商品的消耗，
  // 与安卓的consumeAsync不同
  // group('consume purchases', () {
  //   test('consume purchase async success', () async { ... });
  // });

  // 原安卓test：billingConfig - getCountryCode success
  // 改造原因：鸿蒙版InAppPurchaseOhosPlatformAddition不提供getCountryCode方法，
  // 此功能在InAppPurchaseOhosPlatform.countryCode()上
  // group('billingConfig', () {
  //   test('getCountryCode success', () async { ... });
  // });

  // 原安卓test：setBillingChoice - setAlternativeBillingOnlyState / setPlayBillingState
  // 改造原因：鸿蒙版不支持BillingChoiceMode（替代计费/用户选择计费模式），
  // AppGallery IAP Kit不提供此功能
  // group('setBillingChoice', () {
  //   test('setAlternativeBillingOnlyState', () async { ... });
  //   test('setPlayBillingState', () async { ... });
  // });

  // 原安卓test：isAlternativeBillingOnlyAvailable
  // 改造原因：鸿蒙版不支持替代计费（alternative billing only），
  // AppGallery IAP Kit不提供此功能
  // group('isAlternativeBillingOnlyAvailable', () {
  //   test('isAlternativeBillingOnlyAvailable success', () async { ... });
  // });

  // 原安卓test：showAlternativeBillingOnlyInformationDialog
  // 改造原因：鸿蒙版不支持替代计费信息对话框，
  // AppGallery IAP Kit不提供此功能
  // group('showAlternativeBillingOnlyInformationDialog', () {
  //   test('showAlternativeBillingOnlyInformationDialog success', () async { ... });
  // });

  // 原安卓test：queryPastPurchase - queryPurchaseDetails
  // 改造原因：鸿蒙版不支持queryPastPurchases API，
  // AppGallery IAP Kit不提供此功能
  // group('queryPastPurchase', () {
  //   group('queryPurchaseDetails', () {
  //     test('returns ProductDetailsResponseWrapper', () async { ... });
  //     test('should store platform exception in the response', () async { ... });
  //   });
  // });

  // 原安卓test：isFeatureSupported
  // 改造原因：鸿蒙版不支持isFeatureSupported API，
  // AppGallery IAP Kit不提供此功能
  // group('isFeatureSupported', () {
  //   test('isFeatureSupported returns false', () async { ... });
  //   test('isFeatureSupported returns true', () async { ... });
  // });

  // 原安卓test：userChoiceDetails
  // 改造原因：鸿蒙版不支持用户选择计费详情（UserChoiceDetails），
  // AppGallery IAP Kit不提供此功能
  // group('userChoiceDetails', () {
  //   test('called', () async { ... });
  // });

  // 新鸿蒙test：测试 InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData
  group('InAppPurchaseOhosPlatformAddition', () {
    test(
        'refreshPurchaseVerificationData should return verification data on success',
        () async {
      const String receiptData = 'testReceiptData';
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#retrieveReceiptData') {
            return receiptData;
          }
          if (methodCall.method == 'iap#refreshReceipt') {
            return null;
          }
          return null;
        },
      );

      final PurchaseVerificationData? result =
          await addition.refreshPurchaseVerificationData();

      expect(result, isNotNull);
      expect(result!.localVerificationData, receiptData);
      expect(result.serverVerificationData, receiptData);
      expect(result.source, kIAPSource);
    });

    test('refreshPurchaseVerificationData should return null on error',
        () async {
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/in_app_purchase'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'iap#refreshReceipt') {
            return null;
          }
          if (methodCall.method == 'iap#retrieveReceiptData') {
            throw PlatformException(code: 'error', message: 'receipt error');
          }
          return null;
        },
      );

      final PurchaseVerificationData? result =
          await addition.refreshPurchaseVerificationData();

      expect(result, isNull);
    });
  });

  // 新鸿蒙test：测试 AppGalleryPurchaseParam
  group('AppGalleryPurchaseParam', () {
    test('should have default quantity of 1', () {
      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable',
        type: ProductType.CONSUMABLE,
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

      final AppGalleryPurchaseParam param = AppGalleryPurchaseParam(
        productDetails: productDetails,
        applicationUserName: 'testUser',
      );

      expect(param.quantity, 1);
      expect(param.productDetails.id, 'com.example.consumable');
      expect(param.applicationUserName, 'testUser');
    });

    test('should allow custom quantity', () {
      final IKProductWrapper product = IKProductWrapper(
        id: 'com.example.consumable',
        type: ProductType.CONSUMABLE,
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

      final AppGalleryPurchaseParam param = AppGalleryPurchaseParam(
        productDetails: productDetails,
        quantity: 5,
      );

      expect(param.quantity, 5);
    });
  });
}

/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
