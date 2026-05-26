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
// 此文件原提供安卓pigeon转换工具方法：
// convertToPigeonResult, convertToPigeonPurchase, convertToPigeonProductDetails,
// convertToPigeonSubscriptionOfferDetails, convertToPigeonPricingPhase 等。
// 鸿蒙版不使用pigeon，这些转换方法不再需要。
//
// 原安卓test_conversion_utils.dart 内容：
// import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// import 'package:in_app_purchase_android/src/messages.g.dart';
// import 'package:in_app_purchase_android/src/pigeon_converters.dart';
//
// PlatformBillingResult convertToPigeonResult(BillingResultWrapper targetResult) {
//   return PlatformBillingResult(
//     responseCode: billingResponseFromWrapper(targetResult.responseCode),
//     debugMessage: targetResult.debugMessage!,
//   );
// }
//
// PlatformPurchase convertToPigeonPurchase(PurchaseWrapper purchase) {
//   return PlatformPurchase(
//       orderId: purchase.orderId,
//       packageName: purchase.packageName,
//       purchaseTime: purchase.purchaseTime,
//       purchaseToken: purchase.purchaseToken,
//       signature: purchase.signature,
//       products: purchase.products,
//       isAutoRenewing: purchase.isAutoRenewing,
//       originalJson: purchase.originalJson,
//       developerPayload: purchase.developerPayload ?? '',
//       isAcknowledged: purchase.isAcknowledged,
//       purchaseState: _convertToPigeonPurchaseState(purchase.purchaseState),
//       quantity: 99,
//       accountIdentifiers: purchase.obfuscatedAccountId != null ||
//               purchase.obfuscatedProfileId != null
//           ? PlatformAccountIdentifiers(
//               obfuscatedAccountId: purchase.obfuscatedAccountId,
//               obfuscatedProfileId: purchase.obfuscatedProfileId,
//             )
//           : null);
// }
//
// PlatformProductDetails convertToPigeonProductDetails(ProductDetailsWrapper details) { ... }
// PlatformSubscriptionOfferDetails convertToPigeonSubscriptionOfferDetails(SubscriptionOfferDetailsWrapper details) { ... }
// PlatformPricingPhase convertToPigeonPricingPhase(PricingPhaseWrapper phase) { ... }
// PlatformOneTimePurchaseOfferDetails? _convertToPigeonOneTimePurchaseOfferDetails(OneTimePurchaseOfferDetailsWrapper? offer) { ... }
// PlatformPurchaseState _convertToPigeonPurchaseState(PurchaseStateWrapper state) { ... }
// PlatformRecurrenceMode _convertToPigeonRecurrenceMode(RecurrenceMode mode) { ... }
//
// 改造原因：鸿蒙版不使用pigeon通信机制，使用MethodChannel直接通信，
// 不需要将Wrapper对象转换为Platform对象。测试中直接使用MethodChannel的
// setMockMethodCallHandler模拟平台响应，因此这些转换方法不再需要。
// 此文件保留为空。

// 如需后续添加鸿蒙版测试工具方法，可在此处添加。
