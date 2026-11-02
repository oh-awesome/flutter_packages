# iap_kit_wrappers

This library exposes Dart endpoints to the underlying OpenHarmony IAP Kit APIs,
and is used by the platform implementation of
[in_app_purchase](https://pub.dev/packages/in_app_purchase).

It offers functionality as an alternative to directly talking to the
[in_app_purchase](/packages/in_app_purchase/in_app_purchase/README.md)
platform interface. Most applications never need to use these wrappers
directly; they are exposed for debugging and advanced scenarios.

Key classes:

- `IKPaymentQueueWrapper` — singleton payment queue (query environment status,
  add/finish/restore transactions, observe the transaction queue).
- `IKPaymentTransactionWrapper` / `IKPaymentWrapper` / `IKError` — data models
  for transactions, payment requests and transaction errors.
- `IKProductResponseWrapper` / `IKProductWrapper` — product information returned
  by IAP Kit.
- `IKRequestMaker` — product requests and receipt refresh requests.
- `IKReceiptManager` — static receipt retrieval.
- Enum converters — serialize/deserialize IAP Kit enums over JSON.
