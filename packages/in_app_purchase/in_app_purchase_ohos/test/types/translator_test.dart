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
// 此文件原测试 Translator 类的转换方法：
// convertToPlayProductType, convertToUserChoiceDetailsProduct,
// convertToUserChoiceDetails。
// 鸿蒙版没有 Translator 类，使用 IKTransactionStatusConverter 和
// AppGalleryPurchaseDetails.fromIKTransaction 进行转换。

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';
import 'package:in_app_purchase_ohos/src/iap_kit_wrappers/enum_converters.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  // 原安卓test：convertToPlayProductType
  // 改造原因：鸿蒙版没有 Translator.convertToPlayProductType 方法，
  // ProductType 在鸿蒙版中直接使用（CONSUMABLE, NONCONSUMABLE,
  // AUTORENEWABLE, NONRENEWABLE），不需要转换为 GooglePlayProductType
  // test('convertToPlayProductType', () {
  //   expect(Translator.convertToPlayProductType(ProductType.inapp),
  //       GooglePlayProductType.inapp);
  //   expect(Translator.convertToPlayProductType(ProductType.subs),
  //       GooglePlayProductType.subs);
  //   expect(GooglePlayProductType.values.length, ProductType.values.length);
  // });

  // 新鸿蒙test：测试 ProductType 枚举值映射
  group('ProductType', () {
    test('has expected enum values matching IAP Kit', () {
      expect(ProductType.values.length, 4);
      expect(ProductType.CONSUMABLE, ProductType.CONSUMABLE);
      expect(ProductType.NONCONSUMABLE, ProductType.NONCONSUMABLE);
      expect(ProductType.AUTORENEWABLE, ProductType.AUTORENEWABLE);
      expect(ProductType.NONRENEWABLE, ProductType.NONRENEWABLE);
    });
  });

  // 原安卓test：convertToUserChoiceDetailsProduct
  // 改造原因：鸿蒙版不支持替代计费/用户选择计费（UserChoiceDetails），
  // AppGallery IAP Kit不提供此功能，因此没有 Translator.convertToUserChoiceDetailsProduct
  // test('convertToUserChoiceDetailsProduct', () {
  //   const GooglePlayUserChoiceDetailsProduct expected =
  //       GooglePlayUserChoiceDetailsProduct(
  //           id: 'id', offerToken: 'offerToken',
  //           productType: GooglePlayProductType.inapp);
  //   expect(
  //       Translator.convertToUserChoiceDetailsProduct(
  //           UserChoiceDetailsProductWrapper(
  //               id: expected.id, offerToken: expected.offerToken,
  //               productType: ProductType.inapp)),
  //       expected);
  // });

  // 原安卓test：convertToUserChoiceDetails
  // 改造原因：同上，鸿蒙版不支持用户选择计费详情
  // test('convertToUserChoiceDetails', () {
  //   ...Translator.convertToUserChoiceDetails(UserChoiceDetailsWrapper(...))...
  // });

  // 新鸿蒙test：测试 IKTransactionStatusConverter.toPurchaseStatus
  // 此方法替代了安卓的 Translator 中 PurchaseStatus 转换功能
  group('IKTransactionStatusConverter toPurchaseStatus', () {
    const IKTransactionStatusConverter converter =
        IKTransactionStatusConverter();

    test('purchasing state maps to pending status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.purchasing, null),
          PurchaseStatus.pending);
    });

    test('deferred state maps to pending status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.deferred, null),
          PurchaseStatus.pending);
    });

    test('purchased state maps to purchased status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.purchased, null),
          PurchaseStatus.purchased);
    });

    test('restored state maps to restored status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.restored, null),
          PurchaseStatus.restored);
    });

    test('failed state with error code 2 maps to canceled status', () {
      const IKError error = IKError(
          code: 2, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.failed, error),
          PurchaseStatus.canceled);
    });

    test('failed state with error code 15 maps to canceled status', () {
      const IKError error = IKError(
          code: 15, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.failed, error),
          PurchaseStatus.canceled);
    });

    test('failed state with other error code maps to error status', () {
      const IKError error = IKError(
          code: 1, domain: 'SKErrorDomain', userInfo: <String, dynamic>{});
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.failed, error),
          PurchaseStatus.error);
    });

    test('failed state without error maps to error status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.failed, null),
          PurchaseStatus.error);
    });

    test('unspecified state maps to error status', () {
      expect(
          converter.toPurchaseStatus(
              IKPaymentTransactionStateWrapper.unspecified, null),
          PurchaseStatus.error);
    });
  });

  // 新鸿蒙test：测试 IKTransactionStatusConverter 的 JSON 序列化/反序列化
  group('IKTransactionStatusConverter serialization', () {
    const IKTransactionStatusConverter converter =
        IKTransactionStatusConverter();

    test('fromJson converts integer to IKPaymentTransactionStateWrapper', () {
      expect(
          converter.fromJson(0), IKPaymentTransactionStateWrapper.purchasing);
      expect(converter.fromJson(1), IKPaymentTransactionStateWrapper.purchased);
      expect(converter.fromJson(2), IKPaymentTransactionStateWrapper.failed);
      expect(converter.fromJson(3), IKPaymentTransactionStateWrapper.restored);
      expect(converter.fromJson(4), IKPaymentTransactionStateWrapper.deferred);
      expect(
          converter.fromJson(-1), IKPaymentTransactionStateWrapper.unspecified);
    });

    test('fromJson handles null by returning unspecified', () {
      expect(converter.fromJson(null),
          IKPaymentTransactionStateWrapper.unspecified);
    });

    test('toJson converts IKPaymentTransactionStateWrapper to integer', () {
      expect(converter.toJson(IKPaymentTransactionStateWrapper.purchasing), 0);
      expect(converter.toJson(IKPaymentTransactionStateWrapper.purchased), 1);
      expect(converter.toJson(IKPaymentTransactionStateWrapper.failed), 2);
      expect(converter.toJson(IKPaymentTransactionStateWrapper.restored), 3);
      expect(converter.toJson(IKPaymentTransactionStateWrapper.deferred), 4);
      expect(
          converter.toJson(IKPaymentTransactionStateWrapper.unspecified), -1);
    });
  });

  // 新鸿蒙test：测试 IKSubscriptionPeriodUnitConverter
  group('IKSubscriptionPeriodUnitConverter', () {
    const IKSubscriptionPeriodUnitConverter converter =
        IKSubscriptionPeriodUnitConverter();

    test('fromJson converts integer to IKSubscriptionPeriodUnit', () {
      expect(converter.fromJson(0), IKSubscriptionPeriodUnit.day);
      expect(converter.fromJson(1), IKSubscriptionPeriodUnit.week);
      expect(converter.fromJson(2), IKSubscriptionPeriodUnit.month);
      expect(converter.fromJson(3), IKSubscriptionPeriodUnit.year);
    });

    test('fromJson handles null by returning day', () {
      expect(converter.fromJson(null), IKSubscriptionPeriodUnit.day);
    });

    test('toJson converts IKSubscriptionPeriodUnit to integer', () {
      expect(converter.toJson(IKSubscriptionPeriodUnit.day), 0);
      expect(converter.toJson(IKSubscriptionPeriodUnit.week), 1);
      expect(converter.toJson(IKSubscriptionPeriodUnit.month), 2);
      expect(converter.toJson(IKSubscriptionPeriodUnit.year), 3);
    });
  });

  // 新鸿蒙test：测试 IKProductDiscountPaymentModeConverter
  group('IKProductDiscountPaymentModeConverter', () {
    const IKProductDiscountPaymentModeConverter converter =
        IKProductDiscountPaymentModeConverter();

    test('fromJson converts integer to IKProductDiscountPaymentMode', () {
      expect(converter.fromJson(0), IKProductDiscountPaymentMode.payAsYouGo);
      expect(converter.fromJson(1), IKProductDiscountPaymentMode.payUpFront);
      expect(converter.fromJson(2), IKProductDiscountPaymentMode.freeTrail);
      expect(converter.fromJson(-1), IKProductDiscountPaymentMode.unspecified);
    });

    test('fromJson handles null by returning payAsYouGo', () {
      expect(converter.fromJson(null), IKProductDiscountPaymentMode.payAsYouGo);
    });

    test('toJson converts IKProductDiscountPaymentMode to integer', () {
      expect(converter.toJson(IKProductDiscountPaymentMode.payAsYouGo), 0);
      expect(converter.toJson(IKProductDiscountPaymentMode.payUpFront), 1);
      expect(converter.toJson(IKProductDiscountPaymentMode.freeTrail), 2);
      expect(converter.toJson(IKProductDiscountPaymentMode.unspecified), -1);
    });
  });

  // 新鸿蒙test：测试 IKProductDiscountTypeConverter
  group('IKProductDiscountTypeConverter', () {
    const IKProductDiscountTypeConverter converter =
        IKProductDiscountTypeConverter();

    test('fromJson converts integer to IKProductDiscountType', () {
      expect(converter.fromJson(0), IKProductDiscountType.introductory);
      expect(converter.fromJson(1), IKProductDiscountType.subscription);
    });

    test('fromJson handles null by returning introductory', () {
      expect(converter.fromJson(null), IKProductDiscountType.introductory);
    });

    test('toJson converts IKProductDiscountType to integer', () {
      expect(converter.toJson(IKProductDiscountType.introductory), 0);
      expect(converter.toJson(IKProductDiscountType.subscription), 1);
    });
  });
}
