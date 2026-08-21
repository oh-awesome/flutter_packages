# in_app_purchase_ohos

本项目基于 [in_app_purchase](https://pub.dev/packages/in_app_purchase) 开发。

## 简介

in_app_purchase_ohos 是 in_app_purchase 在 OpenHarmony 平台上的 federated implementation。插件底层对接 OpenHarmony IAP Kit，并将购买能力映射为 Flutter 统一的内购接口。对业务应用来说，通常只需要依赖 in_app_purchase，在 OHOS 平台构建时会自动接入当前实现；只有在调试平台实现或需要使用平台扩展 API 时，才需要直接依赖 in_app_purchase_ohos。

## 下载安装

进入到工程目录并在 pubspec.yaml 中添加以下依赖，推荐业务应用优先依赖应用层包 in_app_purchase：

```yaml
dependencies:
  in_app_purchase:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG
```

如果需要直接调试 OHOS 平台实现，或需要调用平台扩展 API，也可以直接依赖当前包：

```yaml
dependencies:
  in_app_purchase_ohos:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/in_app_purchase/in_app_purchase_ohos
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG
```

执行命令

```bash
flutter pub get
```

> 仅在直接依赖 in_app_purchase_ohos 时，才需要在应用启动阶段手动调用 InAppPurchaseOhosPlatform.registerPlatform() 注册平台实例。

> 版本引用规则：当前仓库使用与上游版本对应的 OHOS 分支维护适配实现，推荐优先使用实际发布的分支或标签，例如 br_in_app_purchase-v3.2.3_ohos。Flutter 版本、包版本与分支的对应关系参见[版本兼容表](#版本兼容)。

### 搭建 OHOS 开发环境

1. 安装 DevEco Studio。本插件已在 DevEco Studio 6.1.1.268 上验证通过（见[兼容性](#兼容性)），兼容的更新版本亦可使用。
2. 使用支持 OHOS 的 Flutter 工具链（例如 `flutter-ohos` SDK，如 `3.41.10-ohos-0.0.1`），并通过 `flutter create --platforms=ohos .` 为应用生成 OHOS 平台工程骨架。
3. OHOS entry 模块声明了 `ohos.permission.INTERNET`。若应用未具备联网权限，请参考[权限要求](#权限要求)进行添加。
4. 通过 DevEco Studio（**Build → Build Hap(s)/APP(s)**）或命令行 `hvigorw` 构建 HAP，插件的原生代码会随 entry 模块一起编译。

## 约束与限制

### 兼容性

在以下版本中已测试通过

1. Flutter: 3.44.9+ohos-0.0.1-canary1; SDK: 5.0.2(14); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117;

### 版本兼容

下表给出 Flutter 框架版本与包版本（TAG）及承载适配实现的 OHOS 分支之间的对应关系。

| Flutter 框架版本 | 包版本（TAG） | 分支 |
| --------------- | ------------- | ---- |
| 3.44.9+ohos-0.0.1-canary1 | in_app_purchase-v3.0.0-ohos-1.0.0 | oh-3.44.9 |

> 请选择与工程所用 flutter-ohos SDK 版本匹配的包版本；无法确定时，优先使用最新发布的分支或标签。

### 升级迁移说明

跨版本升级时请注意以下事项：

- 修改 pubspec.yaml 中的依赖 `ref` 后，重新执行 `flutter pub get`，并确认解析到的版本与[版本兼容](#版本兼容)表一致。
- 自 in_app_purchase-v3.0.0-ohos-1.0.0 起：消耗型商品同时支持 `autoConsume = true` 与 `autoConsume = false`；`completePurchase` 精确结束与传入 `transactionIdentifier` 匹配的订单，而不再结束同类型的全部未完成订单；商品查询、购买、恢复与完成购买链路均支持 `ProductType.NONRENEWABLE`。从早期版本升级时请重新审视完成购买的逻辑。
- OHOS 上 `countryCode()` 返回的国家码来自系统地区（`i18n.System.getSystemRegion()`），可能与别的平台不一致，请勿用于计费地区判断。

### 前置条件

- 需要在 AppGallery Connect 中创建商品，并保证商品 ID 与代码中的查询 ID 完全一致。
- 需要完成应用签名、包名、支付环境和测试账号配置，否则 isAvailable 可能返回 false，或 queryProductDetails 返回 notFoundIDs。
- 需要设备具备可用的 IAP Kit / AppGallery 支付环境。

### 权限要求

插件模块本身未在 HAR 中声明额外权限；示例应用在 entry module 中声明了 ohos.permission.INTERNET。业务应用如果未具备联网权限，请在 entry/src/main/module.json5 中添加：

```json5
"requestPermissions": [
  {"name": "ohos.permission.INTERNET"}
]
```

## 使用示例

通过 in_app_purchase 使用统一接口，以下片段展示了最常见的商品查询与发起购买流程：

```dart
import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

final InAppPurchase _inAppPurchase = InAppPurchase.instance;
late final StreamSubscription<List<PurchaseDetails>> _subscription;

Future<void> initIap() async {
  // 遗留的未完成订单，因此请在主界面构建前完成订阅。
  _subscription = _inAppPurchase.purchaseStream.listen(
    (List<PurchaseDetails> purchases) {
      for (final PurchaseDetails purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased &&
            purchase.pendingCompletePurchase) {
          // OHOS 上 completePurchase 精确结束与 purchase.transactionIdentifier
          // 匹配的交易。
          _inAppPurchase.completePurchase(purchase);
        }
      }
    },
  );

  // OHOS 上 isAvailable 检查设备 IAP Kit 支付环境是否可用。
  final bool available = await _inAppPurchase.isAvailable();
  if (!available) {
    return;
  }

  // 商品 ID 必须与 AppGallery Connect 中配置一致；发起购买前必须先完成商品查询。
  final ProductDetailsResponse response =
      await _inAppPurchase.queryProductDetails({'consumable', 'upgrade'});
  if (response.productDetails.isEmpty) {
    return;
  }

  final ProductDetails product = response.productDetails.first;
  // 消耗型商品默认 autoConsume = true。当 autoConsume = false 时，购买结果会以
  // pendingCompletePurchase = true 返回，待发货后再自行调用 completePurchase。
  await _inAppPurchase.buyConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
  );
}
```

如果直接依赖 in_app_purchase_ohos，可在应用启动阶段手动注册平台实现。仅在这种直接依赖场景下需要手动注册；依赖 in_app_purchase 时，OHOS 平台构建会自动接入当前实现：

```dart
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 将 InAppPurchaseOhosPlatform 注册为默认平台实例，使统一内购接口
  // 路由到 OHOS 实现。
  InAppPurchaseOhosPlatform.registerPlatform();
  runApp(const Placeholder());
}
```

读取 OHOS 平台扩展收据数据示例：

> 当前 OHOS 原生侧尚未实现 `iap#refreshReceipt` 与有效收据返回，`refreshPurchaseVerificationData` 目前仅保留 Dart 层入口，不能视为可用的生产能力。以下代码仅用于说明接口形态。

```dart
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_ohos/in_app_purchase_ohos.dart';

Future<void> refreshReceipt() async {
  // refreshPurchaseVerificationData 是 OHOS 平台扩展接口，只能通过平台扩展实例访问。
  final InAppPurchaseOhosPlatformAddition addition =
      InAppPurchasePlatformAddition.instance
          as InAppPurchaseOhosPlatformAddition;
  // 收据刷新/获取失败时返回 null。
  final PurchaseVerificationData? data =
      await addition.refreshPurchaseVerificationData();
  if (data == null) {
    return;
  }
  print(data.serverVerificationData);
}
```

## 使用说明

### 1. 初始化购买监听

在应用初始化阶段尽早订阅 purchaseStream，避免漏掉前一会话残留的购买更新。若应用直接依赖 in_app_purchase_ohos，则需要先调用 InAppPurchaseOhosPlatform.registerPlatform() 完成平台注册。

### 2. 检查支付环境

调用 isAvailable 确认当前设备支付环境可用后，再执行商品查询和购买流程。

### 3. 查询商品

使用 queryProductDetails 查询商品详情，传入的商品 ID 必须与 AppGallery Connect 中配置保持一致；若返回 productDetails 为空或 notFoundIDs 非空，请优先检查商品状态、测试账号和环境配置。

### 4. 发起与完成购买

可通过 buyNonConsumable 或 buyConsumable 发起购买。购买前应先完成商品查询以建立商品缓存。消耗型商品现已支持 autoConsume = true 和 autoConsume = false 两条路径；当 autoConsume = true 时，插件会在分发 purchased 更新前自动 finish 对应消耗型交易；当 autoConsume = false 时，购买结果会以 pendingCompletePurchase = true 的状态返回，待业务完成发货后再调用 completePurchase。completePurchase 现在会按传入的 transactionIdentifier 精确匹配并结束对应未完成订单。OHOS 实现同时已经识别 ProductType.NONRENEWABLE，并将其贯通到商品查询、购买、恢复和完成购买链路。

### 5. 读取平台扩展数据

InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData 会触发 OHOS 原生侧的 iap#refreshReceipt，刷新并返回最近一次可用的 JWS 载荷作为 verificationData。该返回值为 best-effort，可能为空，且在不同 IAP 运行时对 NONRENEWABLE 的支持存在差异，因此不应作为生产环境验签的唯一依据。

## 接口说明

> [!TIP]
> OHOS Support 列为 yes 表示当前 OHOS 平台支持该接口，no 表示当前未支持。

### 统一接口

| 名称 | 类型 | 参数类型 | 返回值 | OHOS Support | 描述 |
| ---- | ---- | -------- | ------ | ------------ | ---- |
| purchaseStream | 属性 | / | Stream<List<PurchaseDetails>> | yes | 支持当前购买流程更新、恢复回调，并会在首个监听器建立时回放上一应用会话遗留的未完成订单。 |
| isAvailable() | 方法 | / | Future<bool> | yes | 检查当前设备是否具备可用支付环境。 |
| queryProductDetails() | 方法 | Set<String> identifiers | Future<ProductDetailsResponse> | yes | 查询商品信息并返回 ProductDetailsResponse。 |
| buyNonConsumable() | 方法 | PurchaseParam purchaseParam | Future<bool> | yes | 发起非消耗型商品购买；依赖已完成商品查询并建立商品缓存。 |
| buyConsumable() | 方法 | PurchaseParam purchaseParam, bool autoConsume = true | Future<bool> | yes | 发起消耗型商品购买；支持 autoConsume = true 和 autoConsume = false，两者共用统一下单链路。 |
| completePurchase() | 方法 | PurchaseDetails purchase | Future<void> | yes | 精确结束与传入 transactionIdentifier 匹配的未完成交易。 |
| restorePurchases() | 方法 | String? applicationUserName | Future<void> | yes | 通过 purchaseStream 恢复非消耗型、自动续期订阅和 NONRENEWABLE 订单。 |
| countryCode() | 方法 | / | Future<String> | yes | 返回 i18n.System.getSystemRegion() 作为 best-effort 国家码兜底值。 |

### 平台扩展接口与类型

| 名称 | 类型 | 参数类型 | 返回值 | OHOS Support | 描述 |
| ---- | ---- | -------- | ------ | ------------ | ---- |
| InAppPurchaseOhosPlatform.registerPlatform() | 静态方法 | / | void | yes | 手动将 OHOS 平台实现注册为默认实例。 |
| InAppPurchaseOhosPlatformAddition.refreshPurchaseVerificationData() | 方法 | / | Future<PurchaseVerificationData?> | yes | 触发 iap#refreshReceipt 并返回最新可用的 verificationData（best-effort，可能为空）。 |

### OHOS 特有类型

- **AppGalleryProductDetails**（继承 `ProductDetails`）— OHOS 商品信息。通过 `AppGalleryProductDetails.fromIKProduct(IKProductWrapper)` 创建。新增 `skProduct` 属性（底层 [IKProductWrapper](#iap-kit-封装)）；继承 `id`、`title`、`description`、`price`、`rawPrice`、`currencyCode`、`currencySymbol`。
- **AppGalleryPurchaseDetails**（继承 `PurchaseDetails`）— OHOS 购买信息。通过 `AppGalleryPurchaseDetails.fromIKTransaction(IKPaymentTransactionWrapper, String base64EncodedReceipt)` 创建。新增 `ikPaymentTransaction` 属性与 `markCompletePurchaseHandled()` 方法；`pendingCompletePurchase` 在 `purchased`/`restored` 状态为 `true`，其余状态为 `false`。
- **AppGalleryPurchaseParam**（继承 `PurchaseParam`）— OHOS 购买参数。新增 `quantity`（`int`，默认 `1`）。
- **IAPError** — 捕获底层购买平台的错误。字段：`source`、`code`、`message`，以及可选 `details`（平台相关附加数据）。
- **InAppPurchaseException** — 与插件交互操作失败时抛出。字段：`code`、可选 `message`、`source`。

### IAP Kit 封装

以下类封装底层 IAP Kit API。业务应用通常只需使用上述统一接口；封装类用于调试与高级使用场景。

| 类 | 作用 |
| -- | ---- |
| IKPaymentQueueWrapper | 支付队列单例：`queryEnvironmentStatus()`、`addPayment()`、`finishTransaction()`、`restoreTransactions()`、`transactions()`、`startObservingTransactionQueue()`、`stopObservingTransactionQueue()`、`setTransactionObserver()`。 |
| IKPaymentWrapper | 传给 `addPayment()` 的支付请求；字段包括 `productId`、`productType`、`developerPayload`、`applicationUserName`、`jwsRepresentation`。 |
| IKPaymentTransactionWrapper | 队列中的交易：`payment`、`transactionState`、`transactionIdentifier`、`transactionTimeStamp`、`originalTransaction`、`error`。 |
| IKError | 交易错误详情：`code`、`domain`、`userInfo`。 |
| IKTransactionObserverWrapper | 观察者接口，包含 `updatedTransactions()` 与 `removedTransactions()`。 |
| IKProductResponseWrapper | `startProductRequest()` 的返回结果：`products`、`invalidProductIdentifiers`。 |
| IKProductWrapper | IAP Kit 返回的商品信息：`id`、`type`、`name`、`description`、`localPrice`、`microPrice`、`currency`、`status`。 |
| IKProductSubscriptionPeriodWrapper | 订阅周期：`numberOfUnits`、`unit`。 |
| IKReceiptManager | 静态方法 `retrieveReceiptData()`。 |
| IKRequestMaker | `startProductRequest()` 与 `startRefreshReceiptRequest()`。 |

### 枚举

| 枚举 | 取值 |
| ---- | ---- |
| ProductType | CONSUMABLE、NONCONSUMABLE、AUTORENEWABLE、NONRENEWABLE |
| ProductStatus | VALID、CANCELED、OFFLINE |
| IKPaymentTransactionStateWrapper | purchasing、purchased、failed、restored、deferred、unspecified |
| IKSubscriptionPeriodUnit | day、week、month、year |
| IKProductDiscountPaymentMode | payAsYouGo、payUpFront、freeTrail、unspecified |
| IKProductDiscountType | introductory、subscription |

### 常量

| 常量 | 取值 | 说明 |
| ---- | ---- | ---- |
| kPurchaseErrorCode | `'purchase_error'` | 购买失败时的 `IAPError.code`。 |
| kAutoConsumeErrorCode | `'consume_purchase_error'` | 自动消耗失败时的 `IAPError.code`。 |
| kIAPSource | `'app_gallery'` | AppGallery 购买验证数据来源。 |

## 遗留问题

- 订阅升级降级、兑换码等平台特有购买场景暂未支持。
- OHOS 侧 countryCode 返回的国家码和其它平台来源不一致，因为 IAP 接口无法获取计费地区，因此使用系统地区作为兜底。

## 其他

无

## 目录结构

```text
|---- example                     # 多平台示例应用
|     |---- integration_test      # 集成测试
|     |---- lib                   # 示例代码
|     |---- ohos                  # 示例 OpenHarmony 工程
|---- lib                         # Dart 入口与平台封装
|     |---- src                   # 平台实现、通道与类型定义
|     |---- iap_kit_wrappers.dart # IAP Kit 封装统一入口
|     |---- in_app_purchase_ohos.dart # 库主入口文件
|---- ohos                        # OpenHarmony 原生适配代码
|---- CHANGELOG.md                # 更新日志
|---- README.OpenHarmony.md       # 英文 OpenHarmony 说明文档
|---- README.OpenHarmony_CN.md    # 中文 OpenHarmony 说明文档
|---- pubspec.yaml                # 配置文件
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues)，也欢迎提交 [PR](https://gitcode.com/openharmony-tpc/flutter_packages/pulls) 共建。

## 开源协议

本项目基于 [Apache 2.0 License](LICENSE)。
