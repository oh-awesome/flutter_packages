## in_app_purchase-v3.0.0-ohos-1.0.0 - 2026.8

### Added

* All four product types (CONSUMABLE / NONCONSUMABLE / AUTORENEWABLE / NONRENEWABLE) are now supported uniformly across product query, purchase, restore and finish-purchase flows.
* Adds OHOS native unit tests (`ohos/src/ohosTest`) and Dart unit tests (+1423 lines / 9 files).

### Changed

* Aligns with upstream `in_app_purchase` 3.3.0 and the Flutter 3.44.9-ohos toolchain.
* Adds the `IAP_` error-code prefix to native error callbacks; `createPurchase` now replies with an explicit error on failure.
* Adds null-context / empty-`productId` guards and try/catch fallbacks.
* Clears cached state on `onDetachedFromAbility`, releases resources in order on `teardownMethodChannel`; removes Dart debug code.
* Rewrites README_CN and the IAP Kit docs.

### Fixed

* `START/STOP_OBSERVING_TRANSACTION_QUEUE` now reply correctly instead of hanging.

## 1.0.0

* Updates flutter dependences.

## 0.1.0

* Initial open-source release.
