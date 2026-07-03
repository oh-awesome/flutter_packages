// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
