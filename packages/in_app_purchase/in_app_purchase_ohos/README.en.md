# in_app_purchase_ohos

This project is developed based on [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## Introduction

in_app_purchase_ohos is the federated implementation of in_app_purchase on the OpenHarmony platform. The plugin integrates with the OpenHarmony IAP Kit at the bottom layer and maps purchase capabilities to Flutter's unified in-app purchase interface. For business apps, typically you only need to depend on in_app_purchase; the OHOS platform build will automatically include this implementation. You only need to directly depend on in_app_purchase_ohos when debugging the platform implementation or using platform extension APIs.

## Installation

Navigate to your project directory and add the following dependency to `pubspec.yaml`. Business apps are recommended to prefer the app-layer package in_app_purchase:

```yaml
dependencies:
  in_app_purchase:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase
      # ref: in_app_purchase_v3.1.11-ohos-1.0.1
      ref: TAG  #   Select a TAG according to the TAG version table below
```

If you need to directly debug the OHOS platform implementation, or call platform extension APIs, you can also depend on this package directly:

```yaml
dependencies:
  in_app_purchase_ohos:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase_ohos
      # ref: in_app_purchase_v3.1.11-ohos-1.0.1
      ref: TAG  #   Select a TAG according to the TAG version table below
```

Run the command:

```bash
flutter pub get
```

**TAG Version Table**

| Flutter Version | TAG1 | TAG2 | Branch |
| :--- | :--- | :--- | :--- |
| 3.41 | `-` | `in_app_purchase_v3.2.3-ohos-1.0.1` | `br_in_app_purchase-v3.2.3_ohos` |
| 3.35 | `-` | `in_app_purchase_v3.2.3-ohos-1.0.1` | `br_in_app_purchase-v3.2.3_ohos` |
| 3.27 | `-` | `in_app_purchase_v3.2.3-ohos-1.0.1` | `br_in_app_purchase-v3.2.3_ohos` |
| 3.22 | `-` | `in_app_purchase_v3.2.0-ohos-1.0.1` | `br_in_app_purchase-v3.2.0_ohos` |
| 3.7 | `-` | `in_app_purchase_v3.1.11-ohos-1.0.1` | `master` |

## Constraints and Limitations

### Compatibility

Tested and passed on the following versions:

1. Flutter: 3.7.12-ohos-1.1.1; SDK: 5.0.2(14); IDE: DevEco Studio: 6.1.2.268; ROM: 6.1.0.117;

### Prerequisites

- Products must be created in AppGallery Connect, and the product IDs must exactly match the query IDs in code.
- App signing, package name, payment environment, and test account configuration must be completed; otherwise isAvailable may return false, or queryProductDetails may return notFoundIDs.
- The device must have a usable IAP Kit / AppGallery payment environment.

### Permission Requirements

The plugin module itself does not declare additional permissions in the HAR; the example app declares ohos.permission.INTERNET in the entry module. If your business app does not have network permission, add it in entry/src/main/module.json5:

```json5
"requestPermissions": [
  {"name": "ohos.permission.INTERNET"}
]
```

## Usage Example

Use the unified interface via in_app_purchase. The following snippet shows the most common product query and purchase flow:

```dart
import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

final InAppPurchase _inAppPurchase = InAppPurchase.instance;
late final StreamSubscription<List<PurchaseDetails>> _subscription;

Future<void> initIap() async {
  _subscription = _inAppPurchase.purchaseStream.listen(
    (List<PurchaseDetails> purchases) {
      for (final PurchaseDetails purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased &&
            purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
      }
    },
  );

  final bool available = await _inAppPurchase.isAvailable();
  if (!available) {
    return;
  }

  final ProductDetailsResponse response =
      await _inAppPurchase.queryProductDetails({'consumable', 'upgrade'});
  if (response.productDetails.isEmpty) {
    return;
  }

  final ProductDetails product = response.productDetails.first;
  await _inAppPurchase.buyConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
  );
}
```

If you depend on in_app_purchase_ohos directly, you can manually register the platform implementation at app startup:

```dart
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseOhosPlatform.registerPlatform();
  runApp(const Placeholder());
}
```

Example for reading OHOS platform extension receipt data:

> The OHOS native side has not yet implemented `iap#refreshReceipt` and valid receipt return. `refreshPurchaseVerificationData` currently only retains the Dart-layer entry and cannot be considered a usable production capability. The following code only illustrates the interface shape.

```dart
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

Future<void> refreshReceipt() async {
  final InAppPurchaseOhosPlatformAddition addition =
      InAppPurchasePlatformAddition.instance
          as InAppPurchaseOhosPlatformAddition;
  final PurchaseVerificationData? data =
      await addition.refreshPurchaseVerificationData();
  if (data == null) {
    return;
  }
  print(data.serverVerificationData);
}
```

## Usage Instructions

### 1. Initialize purchase listener

Subscribe to purchaseStream early at app initialization to avoid missing leftover purchase updates from the previous session. If the app depends on in_app_purchase_ohos directly, call InAppPurchaseOhosPlatform.registerPlatform() first to complete platform registration.

### 2. Check payment environment

Call isAvailable to confirm the current device's payment environment is ready before performing product queries and purchases.

### 3. Query products

Use queryProductDetails to query product details. The passed product IDs must match those configured in AppGallery Connect. If the returned productDetails is empty or notFoundIDs is non-empty, check product status, test accounts, and environment configuration first.

### 4. Initiate and complete purchases

Use buyNonConsumable or buyConsumable to initiate purchases. Complete product queries before purchasing to build the product cache. Consumable products now support both autoConsume = true and autoConsume = false paths. When autoConsume = true, the plugin automatically finishes the corresponding consumable transaction before dispatching the purchased update; when autoConsume = false, the purchase result is returned with pendingCompletePurchase = true, and the business calls completePurchase after delivery. completePurchase now precisely matches and closes the unfinished order by the passed transactionIdentifier. The OHOS implementation also recognizes ProductType.NONRENEWABLE and threads it through product query, purchase, restore, and complete-purchase flows.

### 5. Read platform extension data

InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData triggers iap#refreshReceipt on the OHOS native side, refreshing and returning the most recent available JWS payload as verificationData. This return value is best-effort and may be empty; support for NONRENEWABLE varies across IAP runtimes, so it should not be the sole basis for production-environment signature verification.

## API Reference

### API

> [!TIP]
> An **ohos Support** value of **yes** means the OHOS platform currently supports the API; **no** means it is not currently supported.

#### Unified interface

| Name | Type | Parameter Type | Return Value | ohos Support | Description |
| ---- | ---- | -------- | ------ | ------------ | ---- |
| purchaseStream | Property | / | Stream<List<PurchaseDetails>> | yes | Supports current purchase-flow updates and restore callbacks, and replays leftover unfinished orders from the previous app session when the first listener is established. |
| isAvailable() | Method | / | Future<bool> | yes | Checks whether the current device has a usable payment environment. |
| queryProductDetails() | Method | Set<String> identifiers | Future<ProductDetailsResponse> | yes | Queries product information and returns ProductDetailsResponse. |
| buyNonConsumable() | Method | PurchaseParam purchaseParam | Future<bool> | yes | Initiates a non-consumable product purchase; depends on completed product queries and a product cache. |
| buyConsumable() | Method | PurchaseParam purchaseParam, bool autoConsume = true | Future<bool> | yes | Initiates a consumable product purchase; supports both autoConsume = true and autoConsume = false via a unified ordering path. |
| completePurchase() | Method | PurchaseDetails purchase | Future<void> | yes | Precisely closes the unfinished transaction matching the passed transactionIdentifier. |
| restorePurchases() | Method | String? applicationUserName | Future<void> | yes | Restores non-consumable, auto-renewable subscription, and NONRENEWABLE orders via purchaseStream. |

#### Platform extension interfaces and types

| Name | Type | Parameter Type | Return Value | ohos Support | Description |
| ---- | ---- | -------- | ------ | ------------ | ---- |
| InAppPurchaseOhosPlatform.registerPlatform() | Static method | / | void | yes | Manually registers the OHOS platform implementation as the default instance. |
| InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData() | Method | / | Future<PurchaseVerificationData?> | yes | Triggers iap#refreshReceipt and returns the latest available verificationData (best-effort, may be empty). |
| countryCode() | Method | / | Future<String> | yes | Returns i18n.System.getSystemRegion() as a best-effort country code fallback. |

## Known Issues

- Platform-specific purchase scenarios such as subscription upgrade/downgrade and redemption codes are not yet supported.
- The country code returned by countryCode on the OHOS side comes from a different source than other platforms. Because the iap interface cannot obtain the billing region, the system region is used as a fallback.

## Directory Structure

```text
|---- example                     # Multi-platform example app
|     |---- integration_test      # Integration tests
|     |---- lib                   # Example code
|     |---- ohos                  # Example OpenHarmony project
|---- lib                         # Dart entry and platform facade
|     |---- src                   # Platform implementation, channels, and type definitions
|     |---- iap_kit_wrappers.dart # IAP Kit wrapper unified entry
|     |---- in_app_purchase_ohos.dart # Library main entry
|---- ohos                        # OpenHarmony native adaptation code
|---- readme                      # Documentation templates and reference materials
|---- CHANGELOG.md                # Changelog
|---- README.md                   # Chinese documentation
|---- README.en.md                # English documentation
|---- pubspec.yaml                # Configuration file
```

## Contributing

If you find any issues during use, please submit an [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues). PRs are also welcome.

## License

This project is licensed under [Apache 2.0 License](LICENSE).
