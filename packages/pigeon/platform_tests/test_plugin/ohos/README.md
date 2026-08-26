# OHOS platform tests for `test_plugin`

HarmonyOS platform integration tests for Pigeon-generated ArkTS code are maintained under:

- `packages/pigeon/example/app/ohos/entry/src/ohosTest/` — Hypium unit tests for the example app plugin
- `packages/pigeon/example/app/ohos/entry/src/main/ets/plugins/` — reference HostApi / ProxyApi / EventChannel implementations

Upstream `platform_tests/test_plugin` ships native unit tests for Android (`android/src/test`), Darwin (`darwin/`), Linux, and Windows. A full duplicate OHOS `test_plugin` module is not yet checked in because it requires a DevEco Studio project per platform target; OHOS coverage is provided by the example app Hypium suite and the Dart generator tests in `packages/pigeon/test/arkts/`.

When adding OHOS-specific regression tests, mirror the Android layout:

```
platform_tests/test_plugin/ohos/
  entry/src/ohosTest/ets/test/
  entry/src/main/ets/plugins/   # generated + hand-written impls
```

Regenerate ArkTS from `platform_tests/shared_test_plugin_code/pigeons/` with `--arkts_out` before running Hypium tests.
