/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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

import 'package:pigeon/pigeon.dart';

/// Minimal ProxyApi demonstration for the HarmonyOS (ArkTS) generator.
///
/// Generate with:
///   dart run bin/pigeon.dart \
///     --input pigeons/proxy_api_ohos_demo.dart \
///     --arkts_out tmp_proxy_out/PigeonCounter.ets \
///     --dart_out tmp_proxy_out/proxy_api_ohos_demo.g.dart \
///     --copyright_header copyright_header.txt
///
/// See doc/PROXYAPI_OHOS.md for the full usage walkthrough.

@ProxyApi()
abstract class Counter {
  Counter(int initial);

  Counter.zero();

  int increment(int by);

  int current();

  /// Pure Flutter-side callback: invoked from the host whenever `increment`
  /// completes.  Demonstrates the per-instance flutter callback path.
  ///
  /// Pigeon ProxyApi convention (see pigeons/proxy_api_tests.dart): Flutter
  /// callback fields are declared `late`; the trailing `?` marks the callback
  /// as optional. A non-nullable declaration (no `?`) would make it required.
  late void Function(int value)? onChanged;
}
