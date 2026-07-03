# in_app_purchase_ohos

This project is based on [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## Introduction

in_app_purchase_ohos is the federated implementation of in_app_purchase for the OpenHarmony platform. It connects OpenHarmony IAP Kit to Flutter's unified in-app purchase API. For business applications, depending on in_app_purchase is usually enough because the OHOS implementation is picked up automatically during OHOS builds. Depend on in_app_purchase_ohos directly only when you need to debug the platform implementation or use platform-specific extension APIs.

## Installation

Go to your project directory and add the following dependency in pubspec.yaml. For most apps, it is recommended to depend on the app-facing package in_app_purchase first:

```yaml
dependencies:
  in_app_purchase:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase
      ref: br_in_app_purchase-v3.1.11_ohos
```

If you need to debug the OHOS platform implementation directly, or call OHOS-specific extension APIs, you can also depend on this package explicitly:

```yaml
dependencies:
  in_app_purchase_ohos:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase_ohos
      ref: br_in_app_purchase-v3.1.11_ohos
```

Run the command:

```bash
flutter pub get
```

> Only when your app depends directly on in_app_purchase_ohos do you need to manually call InAppPurchaseOhosPlatform.registerPlatform() during app startup to register the platform instance.

> Version reference rule: this repository maintains the adaptation on OHOS branches that correspond to upstream versions. Prefer actual published branches or tags, for example br_in_app_purchase-v3.1.11_ohos.

## Constraints And Limitations

### Compatibility

Tested and passed in the following versions

1. Flutter: 3.7.12-ohos-1.1.1; SDK: 5.0.2(14); IDE: DevEco Studio: 6.1.2.268; ROM: 6.1.0.117;

### Prerequisites

- You need to create products in AppGallery Connect and ensure the product IDs exactly match the IDs queried in code.
- You need to complete app signing, bundle name, payment environment, and test account configuration. Otherwise isAvailable may return false, or queryProductDetails may return notFoundIDs.
- The device must provide an available IAP Kit / AppGallery payment environment.

### Permission Requirements

The plugin module itself does not declare extra permissions in the HAR. The example app declares ohos.permission.INTERNET in the entry module. If your app does not already have network permission, add the following in entry/src/main/module.json5:

```json5
"requestPermissions": [
  {"name": "ohos.permission.INTERNET"}
]
```

## Usage Example

Use the unified in_app_purchase API. The following snippet shows the most common flow for querying products and starting a purchase:

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

If you depend on in_app_purchase_ohos directly, you can manually register the platform implementation during app startup:

```dart
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseOhosPlatform.registerPlatform();
  runApp(const Placeholder());
}
```

Example of reading OHOS platform-specific receipt data:

> The OHOS native side has not implemented `iap#refreshReceipt` or a valid receipt return path yet. `refreshPurchaseVerificationData` currently only exists as a Dart-side entry point and should not be treated as a production-ready capability. The following code is kept only to show the API shape.

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

## Usage Guide

### 1. Initialize purchase listening

Subscribe to purchaseStream as early as possible during app initialization to avoid missing purchase updates left over from a previous session. If your app depends directly on in_app_purchase_ohos, you need to call InAppPurchaseOhosPlatform.registerPlatform() first to complete platform registration.

### 2. Check the payment environment

Call isAvailable to confirm the current device payment environment is available before querying products or starting a purchase flow.

### 3. Query products

Use queryProductDetails to query product information. The product IDs must match those configured in AppGallery Connect. If productDetails is empty or notFoundIDs is not empty, first check product status, test accounts, and environment configuration.

### 4. Start and complete purchases

You can start purchases through buyNonConsumable or buyConsumable. Product querying should be completed first so the product cache is available. Consumable products now support both autoConsume = true and autoConsume = false. When autoConsume = true, the plugin auto-finishes the matching consumable transaction before emitting the purchased update; when autoConsume = false, the purchase stays pendingCompletePurchase = true until the app calls completePurchase after delivery. completePurchase now matches the specific transactionIdentifier it receives instead of finishing all unfinished orders of the same type. The OHOS implementation also recognizes ProductType.NONRENEWABLE during product querying, purchase initiation, restore, and completion flows.

### 5. Read platform extension data

InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData triggers the native iap#refreshReceipt flow and returns the latest available JWS payload as verificationData. The value is best-effort and can be empty; support for NONRENEWABLE also varies across IAP runtimes, so do not treat this as the only source of truth for production verification.

## API Reference

### API

> [!TIP]
> In the ohos Support column, yes means the interface is currently supported on OHOS, and no means it is currently unsupported.

#### Unified Interfaces

| Name | Type | Parameter Type | Return Value | ohos Support | Description |
| ---- | ---- | -------------- | ------------ | ------------ | ----------- |
| purchaseStream | Property | / | Stream<List<PurchaseDetails>> | yes | Supports update callbacks during the current purchase flow, restore callbacks, and replay of unfinished transactions from previous app sessions when the first listener attaches. |
| isAvailable() | Method | / | Future<bool> | yes | Checks whether the current device has an available payment environment. |
| queryProductDetails() | Method | Set<String> identifiers | Future<ProductDetailsResponse> | yes | Queries product information and returns ProductDetailsResponse. |
| buyNonConsumable() | Method | PurchaseParam purchaseParam | Future<bool> | yes | Starts the purchase flow for a non-consumable product; relies on product querying having populated the product cache first. |
| buyConsumable() | Method | PurchaseParam purchaseParam, bool autoConsume = true | Future<bool> | yes | Starts the purchase flow for a consumable product; supports both autoConsume = true and autoConsume = false while reusing the unified purchase path. |
| completePurchase() | Method | PurchaseDetails purchase | Future<void> | yes | Finishes the specific unfinished transaction that matches the provided transactionIdentifier. |
| restorePurchases() | Method | String? applicationUserName | Future<void> | yes | Restores non-consumables, auto-renewable subscriptions, and NONRENEWABLE purchases through purchaseStream. |

#### Platform-specific Interfaces And Types

| Name | Type | Parameter Type | Return Value | ohos Support | Description |
| ---- | ---- | -------------- | ------------ | ------------ | ----------- |
| InAppPurchaseOhosPlatform.registerPlatform() | Static method | / | void | yes | Manually registers the OHOS implementation as the default platform instance. |
| InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData() | Method | / | Future<PurchaseVerificationData?> | yes | Triggers iap#refreshReceipt and returns the latest available verificationData (best-effort, may be empty). |
| countryCode() | Method | / | Future<String> | yes | Returns i18n.System.getSystemRegion() as a best-effort country code fallback. |

## Known Issues

- Unified delivery flows for subscription upgrade and downgrade flows, and platform-specific promo-code purchase scenarios are not supported yet.
- The country code returned by ohos is inconsistent with that from other platforms. This is because the iap interface cannot obtain the billing region, so the system region is used as a fallback option.

## Others

None

## Directory Structure

```text
|---- example                     # Multi-platform example app
|     |---- integration_test      # Integration tests
|     |---- lib                   # Example source code
|     |---- ohos                  # Example OpenHarmony project
|---- lib                         # Dart entry points and platform wrappers
|     |---- src                   # Platform implementation, channels, and type definitions
|     |---- iap_kit_wrappers.dart # Unified entry for IAP Kit wrappers
|     |---- in_app_purchase_ohos.dart # Main library entry file
|---- ohos                        # OpenHarmony native adaptation code
|---- readme                      # Documentation templates and supporting materials
|---- CHANGELOG.md                # Changelog
|---- README.md                   # General documentation
|---- README.OpenHarmony.md       # English OpenHarmony documentation
|---- README.OpenHarmony_CN.md    # Chinese OpenHarmony documentation
|---- pubspec.yaml                # Configuration file
```

## Contributing

If you encounter any issues during use, feel free to submit an [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues). Pull requests are also welcome at [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls).

## License

This project is based on the [Apache 2.0 License](LICENSE).
