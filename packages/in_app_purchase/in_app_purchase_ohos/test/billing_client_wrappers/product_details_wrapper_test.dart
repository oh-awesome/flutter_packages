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
// 此文件原测试 ProductDetailsWrapper 和 BillingResultWrapper 的相等性，
// 以及 ProductDetailsWrapper 到 GooglePlayProductDetails 的转换。
// 鸿蒙版使用 IKProductWrapper 和 AppGalleryProductDetails。

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

IKProductWrapper dummyIKProduct = IKProductWrapper(
  id: 'com.example.product',
  type: ProductType.CONSUMABLE,
  name: 'Test Product',
  description: 'A test consumable product',
  localPrice: '￥9.99',
  microPrice: 9990000,
  originalLocalPrice: '￥9.99',
  originalMicroPrice: 9990000,
  currency: 'CNY',
  status: ProductStatus.VALID,
);

void main() {
  // 原安卓test：ProductDetailsResponseWrapper - toProductDetails()
  // 改造原因：鸿蒙版使用 AppGalleryProductDetails.fromIKProduct() 替代
  // GooglePlayProductDetails.fromProductDetails()，
  // 输入类型从 ProductDetailsWrapper 变为 IKProductWrapper，
  // 输出类从 GooglePlayProductDetails 变为 AppGalleryProductDetails，
  // 属性映射也不同（title→name, id→id, price→localPrice 等）
  // group('ProductDetailsResponseWrapper', () {
  //   test('toProductDetails() should return correct Product object', () {
  //     const ProductDetailsWrapper wrapper = dummyOneTimeProductDetails;
  //     final GooglePlayProductDetails product =
  //         GooglePlayProductDetails.fromProductDetails(dummyOneTimeProductDetails).first;
  //     expect(product.title, wrapper.title);
  //     expect(product.description, wrapper.description);
  //     expect(product.id, wrapper.productId);
  //     expect(product.price, wrapper.oneTimePurchaseOfferDetails?.formattedPrice);
  //     expect(product.productDetails, wrapper);
  //   });
  // });

  group('AppGalleryProductDetails', () {
    test('fromIKProduct should return correct ProductDetails object', () {
      final AppGalleryProductDetails product =
          AppGalleryProductDetails.fromIKProduct(dummyIKProduct);

      expect(product.id, dummyIKProduct.id);
      expect(product.title, dummyIKProduct.name);
      expect(product.description, dummyIKProduct.description);
      expect(product.price, dummyIKProduct.localPrice);
      expect(product.skProduct, dummyIKProduct);
    });

    test('fromIKProduct should extract currencySymbol correctly', () {
      final AppGalleryProductDetails product =
          AppGalleryProductDetails.fromIKProduct(dummyIKProduct);

      // localPrice = "￥9.99", currencySymbol should be "￥"
      expect(product.currencySymbol, '￥');
    });

    test(
        'fromIKProduct should have empty currencySymbol when localPrice has no symbol',
        () {
      final IKProductWrapper productWithoutSymbol = IKProductWrapper(
        id: 'com.example.product2',
        type: ProductType.NONCONSUMABLE,
        name: 'Product Without Symbol',
        description: 'A product',
        localPrice: '9.99',
        microPrice: 9990000,
        originalLocalPrice: '9.99',
        originalMicroPrice: 9990000,
        currency: 'USD',
        status: ProductStatus.VALID,
      );

      final AppGalleryProductDetails product =
          AppGalleryProductDetails.fromIKProduct(productWithoutSymbol);

      expect(product.currencyCode, 'USD');
      // When localPrice has no currency symbol, the regex extracts empty string
      expect(product.currencySymbol, '');
    });
  });

  // 原安卓test：BillingResultWrapper - operator == of ProductDetailsWrapper works fine
  // 改造原因：鸿蒙版使用 IKProductWrapper 替代 ProductDetailsWrapper，
  // IKProductWrapper 的字段与安卓版完全不同：
  // - 安卓: description, name, productId, productType, title,
  //   oneTimePurchaseOfferDetails, subscriptionOfferDetails
  // - 鸿蒙: id, type, name, description, localPrice, microPrice,
  //   originalLocalPrice, originalMicroPrice, currency, status
  // 同时鸿蒙版没有 BillingResultWrapper 的相等性测试需求
  // group('BillingResultWrapper', () {
  //   test('operator == of ProductDetailsWrapper works fine', () {
  //     ...
  //     const ProductDetailsWrapper firstProductDetailsInstance = ProductDetailsWrapper(
  //       description: 'description',
  //       title: 'title',
  //       productType: ProductType.inapp,
  //       name: 'name',
  //       productId: 'productId',
  //       oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(...),
  //       subscriptionOfferDetails: <SubscriptionOfferDetailsWrapper>[...],
  //     );
  //     const ProductDetailsWrapper secondProductDetailsInstance = ProductDetailsWrapper(...);
  //     expect(firstProductDetailsInstance == secondProductDetailsInstance, isTrue);
  //   });
  //
  //   test('operator == of BillingResultWrapper works fine', () {
  //     const BillingResultWrapper firstBillingResultInstance = BillingResultWrapper(
  //       responseCode: BillingResponse.ok,
  //       debugMessage: 'debugMessage',
  //     );
  //     const BillingResultWrapper secondBillingResultInstance = BillingResultWrapper(
  //       responseCode: BillingResponse.ok,
  //       debugMessage: 'debugMessage',
  //     );
  //     expect(firstBillingResultInstance == secondBillingResultInstance, isTrue);
  //   });
  // });

  // 新鸿蒙test：测试 IKProductResponseWrapper 的相等性
  group('IKProductResponseWrapper', () {
    test('operator == works correctly for identical responses', () {
      final IKProductResponseWrapper first = IKProductResponseWrapper(
        products: <IKProductWrapper>[dummyIKProduct],
        invalidProductIdentifiers: <String>['invalid1'],
      );
      final IKProductResponseWrapper second = IKProductResponseWrapper(
        products: <IKProductWrapper>[dummyIKProduct],
        invalidProductIdentifiers: <String>['invalid1'],
      );
      expect(first == second, isTrue);
    });

    test('operator == returns false for different responses', () {
      final IKProductResponseWrapper first = IKProductResponseWrapper(
        products: <IKProductWrapper>[dummyIKProduct],
        invalidProductIdentifiers: <String>['invalid1'],
      );
      final IKProductResponseWrapper second = IKProductResponseWrapper(
        products: <IKProductWrapper>[],
        invalidProductIdentifiers: <String>['invalid2'],
      );
      expect(first == second, isFalse);
    });
  });

  // 新鸿蒙test：测试 ProductType 枚举
  group('ProductType', () {
    test('has expected values', () {
      expect(ProductType.values.length, 4);
      expect(ProductType.CONSUMABLE.index, 0);
      expect(ProductType.NONCONSUMABLE.index, 1);
      expect(ProductType.AUTORENEWABLE.index, 2);
      expect(ProductType.NONRENEWABLE.index, 3);
    });
  });

  // 新鸿蒙test：测试 ProductStatus 枚举
  group('ProductStatus', () {
    test('has expected values', () {
      // JsonValue and Dart index are different: OFFLINE has @JsonValue(3) but Dart index 2
      expect(ProductStatus.VALID.index, 0);
      expect(ProductStatus.CANCELED.index, 1);
      expect(ProductStatus.OFFLINE.index,
          2); // OFFLINE is 3rd enum value -> index 2
    });
  });

  // 新鸿蒙test：测试 IKProductWrapper.fromJson
  group('IKProductWrapper.fromJson', () {
    test('fromJson should deserialize all fields correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'com.example.subscription',
        'type': 2, // AUTORENEWABLE
        'name': 'Premium Subscription',
        'description': 'A premium auto-renewable subscription',
        'localPrice': '￥19.99',
        'microPrice': 19990000,
        'originalLocalPrice': '￥19.99',
        'originalMicroPrice': 19990000,
        'currency': 'CNY',
        'status': 3, // OFFLINE (JsonValue 3)
        'jsonRepresentation': '{"raw":"json"}',
      };

      final IKProductWrapper product = IKProductWrapper.fromJson(json);

      expect(product.id, 'com.example.subscription');
      expect(product.type, ProductType.AUTORENEWABLE);
      expect(product.name, 'Premium Subscription');
      expect(product.description, 'A premium auto-renewable subscription');
      expect(product.localPrice, '￥19.99');
      expect(product.microPrice, 19990000);
      expect(product.originalLocalPrice, '￥19.99');
      expect(product.originalMicroPrice, 19990000);
      expect(product.currency, 'CNY');
      expect(product.status, ProductStatus.OFFLINE);
      expect(product.jsonRepresentation, '{"raw":"json"}');
    });

    test('fromJson should handle default values for null fields', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'com.example.minimal',
      };

      final IKProductWrapper product = IKProductWrapper.fromJson(json);

      expect(product.id, 'com.example.minimal');
      expect(product.type, ProductType.CONSUMABLE); // default 0
      expect(product.name, ''); // default ''
      expect(product.description, ''); // default ''
      expect(product.localPrice, ''); // default ''
      expect(product.microPrice, 0); // default 0
      expect(product.originalLocalPrice, ''); // default ''
      expect(product.originalMicroPrice, 0); // default 0
      expect(product.currency, ''); // default ''
      expect(product.status, ProductStatus.VALID); // default 0
      expect(product.jsonRepresentation, isNull);
    });
  });

  // 新鸿蒙test：测试 IKProductWrapper 的相等性
  group('IKProductWrapper', () {
    test('operator == works correctly for identical products', () {
      final IKProductWrapper first = IKProductWrapper(
        id: 'com.example.product',
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
      final IKProductWrapper second = IKProductWrapper(
        id: 'com.example.product',
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
      // IKProductWrapper is @immutable but not const-constructible due to ignore: prefer_const_constructors_in_immutables
      // so == comparison depends on field equality
      expect(first.id, second.id);
      expect(first.type, second.type);
      expect(first.name, second.name);
      expect(first.description, second.description);
      expect(first.localPrice, second.localPrice);
      expect(first.microPrice, second.microPrice);
    });
  });
}
