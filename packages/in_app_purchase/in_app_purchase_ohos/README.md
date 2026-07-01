# in\_app\_purchase\_ohos

[`in_app_purchase`][1] 的 OpenHarmony 平台实现。

本插件使用 AppGallery Connect 提供的 IAP Kit API 来处理 OpenHarmony/HarmonyOS 平台上的应用内购买。

## 使用方式

本包是[官方认可的（endorsed）][2]实现，这意味着你只需正常使用 `in_app_purchase` 即可。当你这样做时，本包会自动包含在你的应用中，无需将其添加到 `pubspec.yaml`。

但是，如果你直接 `import` 本包以使用其中的任何 API，则需要[像往常一样将其添加到 `pubspec.yaml`][3]。

## 支持的 API

以下 `in_app_purchase` API 在 OpenHarmony 平台上受到支持：

| API | 支持 |
|-----|------|
| `purchaseStream` | 是 |
| `isAvailable` | 是 |
| `queryProductDetails` | 是 |
| `buyNonConsumable` | 是 |
| `buyConsumable` | 是 |
| `completePurchase` | 是 |
| `restorePurchases` | 是 |

> **注意：** 在 OpenHarmony 上，`buyConsumable` 总是自动消耗购买。`autoConsume` 参数必须为 `true`。

## 快速开始

本插件依赖 AppGallery Connect 在 OpenHarmony/HarmonyOS 上进行应用内购买。在使用本插件之前，你需要在 AppGallery Connect 中配置你的商品：

* [AppGallery Connect IAP 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/iap-dev-guide-V5)

在 AppGallery Connect 中配置好应用内购买后，即可开始使用本插件。有两种方式可选：

1. 通用的、符合 Flutter 风格的 API：[in_app_purchase](https://pub.dev/documentation/in_app_purchase/latest/in_app_purchase/in_app_purchase-library.html)。
   此 API 支持大多数加载商品和发起购买的用例。

2. 平台特定的 Dart API：[iap_kit_wrappers](https://pub.dev/documentation/in_app_purchase_ohos/latest/iap_kit_wrappers/iap_kit_wrappers-library.html)。
   这些 API 暴露了 IAP Kit 的特定行为，允许在需要时进行更精细的控制。但是，如果你使用此 API，你的购买处理逻辑将特定于 OpenHarmony 商店。

## 使用示例

本节包含以下任务的代码示例：

* [监听购买更新](#监听购买更新)
* [连接底层商店](#连接底层商店)
* [加载待售商品](#加载待售商品)
* [恢复之前的购买](#恢复之前的购买)
* [发起购买](#发起购买)
* [完成购买](#完成购买)
* [访问平台特定的商品或购买属性](#访问平台特定的商品或购买属性)
* [刷新购买验证数据](#刷新购买验证数据)

### 监听购买更新

在你的应用的 `initState` 方法中，订阅所有传入的购买。你应该尽早开始监听购买更新，以便能够捕获所有购买更新，包括来自上一个应用会话的更新。监听更新的方式如下：

```dart
class _MyAppState extends State<MyApp> {
  StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    final Stream purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // 在此处处理错误。
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
```

以下是如何处理购买更新的示例：

```dart
void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
  purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      _showPendingUI();
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          _deliverProduct(purchaseDetails);
        } else {
          _handleInvalidPurchase(purchaseDetails);
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance
            .completePurchase(purchaseDetails);
      }
    }
  });
}
```

### 连接底层商店

```dart
final bool available = await InAppPurchase.instance.isAvailable();
if (!available) {
  // 商店无法连接或访问。相应地更新 UI。
}
```

### 加载待售商品

```dart
const Set<String> _kIds = <String>{'product1', 'product2'};
final ProductDetailsResponse response =
    await InAppPurchase.instance.queryProductDetails(_kIds);
if (response.notFoundIDs.isNotEmpty) {
  // 处理错误。
}
List<ProductDetails> products = response.productDetails;
```

### 恢复之前的购买

恢复的购买将通过 `InAppPurchase.purchaseStream` 发出。

```dart
await InAppPurchase.instance.restorePurchases();
```

### 发起购买

消耗型和非消耗型商品分别由不同的购买方法处理。如果你使用 `InAppPurchase`，需要在此处做出区分，并为每种类型调用正确的购买方法。

```dart
final ProductDetails productDetails = ... // 之前从 queryProductDetails() 保存的。
final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
if (_isConsumable(productDetails)) {
  InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
} else {
  InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
}
// 从这里开始，购买流程将由底层商店处理。
// 更新将通过 InAppPurchase.instance.purchaseStream 传递。
```

### 完成购买

在验证购买收据并向用户交付内容之后，重要的是调用 `InAppPurchase.completePurchase` 以告诉底层商店购买已完成。调用 `InAppPurchase.completePurchase` 将通知底层商店应用已验证并处理了购买，商店可以继续完成交易。

> **警告：** 如果在购买后 3 天内未调用 `InAppPurchase.completePurchase`，将导致退款。

### 访问平台特定的商品或购买属性

函数 `InAppPurchase.instance.queryProductDetails(productIds);` 提供一个 `ProductDetailsResponse`，其中包含类型为 `List<ProductDetails>` 的可购买商品列表。`ProductDetails` 类是一个平台无关的类，包含所有官方认可平台上可用的属性。然而，在某些情况下需要访问平台特定的属性。在 OpenHarmony 上，`ProductDetails` 实例的子类型为 `AppGalleryProductDetails`。访问 `skProduct` 可以获取原始 IAP Kit 商品对象中可用的所有信息。

以下是在 OpenHarmony 上获取商品 `type` 的示例：

```dart
// 导入 AppGalleryProductDetails
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
// 导入 IKProductWrapper
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

if (productDetails is AppGalleryProductDetails) {
  IKProductWrapper ikProduct = (productDetails as AppGalleryProductDetails).skProduct;
  print(ikProduct.type); // ProductType.CONSUMABLE、NONCONSUMABLE 或 AUTORENEWABLE
}
```

`purchaseStream` 提供类型为 `PurchaseDetails` 的对象。在 OpenHarmony 上，`PurchaseDetails` 对象的子类型为 `AppGalleryPurchaseDetails`。访问 `ikPaymentTransaction` 可以获取原始 IAP Kit 交易对象中可用的所有信息。

以下是在 OpenHarmony 上获取 `transactionIdentifier` 的示例：

```dart
// 导入 AppGalleryPurchaseDetails
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';
// 导入 IKPaymentTransactionWrapper
import 'package:in_app_purchase_ohos/iap_kit_wrappers.dart';

if (purchaseDetails is AppGalleryPurchaseDetails) {
  IKPaymentTransactionWrapper transaction =
      (purchaseDetails as AppGalleryPurchaseDetails).ikPaymentTransaction;
  print(transaction.transactionIdentifier);
}
```

请注意，需要导入 `in_app_purchase_ohos` 才能访问这些平台特定的类型。

### 刷新购买验证数据

`InAppPurchaseOhosPlatformAddition` 提供了一种刷新购买验证数据的方法，当收据数据需要更新时非常有用：

```dart
// 导入 InAppPurchaseOhosPlatformAddition
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

var ohosPlatformAddition = _inAppPurchase
    .getPlatformAddition<InAppPurchaseOhosPlatformAddition>();
PurchaseVerificationData? verificationData =
    await ohosPlatformAddition.refreshPurchaseVerificationData();
```

## 平台特定 Dart API（iap_kit_wrappers）

除了符合 Flutter 风格的 API 之外，本包还通过 `iap_kit_wrappers` 库提供了平台特定的 Dart API。这让你可以直接访问 IAP Kit 对象及其属性：

* `IKPaymentQueueWrapper` - 管理支付队列和交易。
* `IKPaymentWrapper` - 表示包含商品 ID、类型、开发者载荷和促销优惠信息的支付请求。
* `IKPaymentTransactionWrapper` - 表示包含状态、时间戳和错误信息的交易。
* `IKProductWrapper` - 表示包含 ID、类型、名称、描述、价格、货币和状态的商品。
* `IKProductResponseWrapper` - 包含商品查询返回的商品列表和无效标识符。
* `IKReceiptManager` - 从平台获取收据数据。
* `IKRequestMaker` - 处理商品查询和收据刷新请求。

有关这些包装器的详细文档，请参阅 [iap_kit_wrappers API 参考](https://pub.dev/documentation/in_app_purchase_ohos/latest/iap_kit_wrappers/iap_kit_wrappers-library.html)。

## 商品类型

OpenHarmony 上的 IAP Kit 支持以下商品类型：

| 类型 | 描述 |
|------|------|
| `CONSUMABLE` | 消耗型商品，可以多次购买 |
| `NONCONSUMABLE` | 非消耗型商品，只能购买一次 |
| `AUTORENEWABLE` | 自动续期订阅商品 |

## 限制

OpenHarmony 平台实现目前有以下限制：

* 目前不支持应用内的订阅续期和支付流程。
* 不支持仅限手机的订阅功能。
* 其他高级功能（如订阅升降级、价格变更确认和优惠码兑换）尚未支持。
