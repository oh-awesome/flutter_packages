/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
// 补充用例覆盖度检视报告指出的缺失场景：
//  - 边界场景：空字符串 key、超长 key/value、特殊字符 key
//  - 异常场景：参数异常、状态异常（平台实例被替换）、权限异常、超时异常
//  - 并发场景：并发读写交叉、并发 clear+get、多实例并发访问
//
// 仅新增测试，不修改上游原有测试用例。

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  // Reset the global platform instance so tests don't leak state into each other.
  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  group('边界场景 coverage', () {
    test('should round-trip an empty-string key', () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      await preferences.setString('', 'empty-key-value');
      expect(await preferences.getString(''), 'empty-key-value');
      expect(await preferences.getKeys(), contains(''));
      expect(
        await preferences.getAll(),
        <String, Object?>{'': 'empty-key-value'},
      );
    });

    test('should round-trip very long keys and values', () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      final String longKey = 'k' * 1000;
      final String longValue = 'v' * 10000;
      await preferences.setString(longKey, longValue);
      expect(await preferences.getString(longKey), longValue);

      final List<String> longList = List<String>.generate(
        100,
        (int index) => 'item-$index',
      );
      await preferences.setStringList('longList', longList);
      expect(await preferences.getStringList('longList'), longList);
    });

    test('should round-trip keys and values with special characters', () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      const List<String> specialKeys = <String>[
        '中文键',
        'emoji-😀🚀',
        'line\nbreak',
        'tab\tseparated',
        'dash-space_underscore',
        'unicode-é中文',
      ];
      for (int i = 0; i < specialKeys.length; i++) {
        await preferences.setString(specialKeys[i], 'value-$i');
      }
      for (int i = 0; i < specialKeys.length; i++) {
        expect(await preferences.getString(specialKeys[i]), 'value-$i');
      }
    });
  });

  group('异常场景 coverage', () {
    test('should throw StateError when no platform instance is set', () {
      expect(() => SharedPreferencesAsync(), throwsStateError);
    });

    test('should treat an explicit null allowList as no filter', () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      await preferences.setString('a', '1');
      await preferences.setString('b', '2');

      final Map<String, Object?> all = await preferences.getAll(allowList: null);
      expect(all.length, 2);
    });

    test('should throw ArgumentError for a key not in the allowList',
        () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesWithCache preferences =
          await SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions(
              allowList: <String>{'known'},
            ),
          );

      expect(() => preferences.get(''), throwsArgumentError);
      expect(() => preferences.containsKey(''), throwsArgumentError);
      expect(
        () async => preferences.setString('', 'value'),
        throwsArgumentError,
      );
    });

    test('should keep operating on the original platform after the instance '
        'is replaced', () async {
      final storeA = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = storeA;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      await preferences.setString('key', 'value-from-a');

      // 模拟平台实例被意外替换。
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      // 原实例继续操作构造时绑定的平台，不受替换影响。
      expect(await preferences.getString('key'), 'value-from-a');

      // 新实例看不到旧平台的数据。
      final SharedPreferencesAsync newPreferences = SharedPreferencesAsync();
      expect(await newPreferences.getString('key'), isNull);
    });

    test('should propagate a permission-denied PlatformException', () async {
      final store = _PermissionDeniedPlatform();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      await expectLater(
        preferences.setString('key', 'value'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        preferences.getString('key'),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        preferences.getAll(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('should surface a TimeoutException when the platform never completes',
        () async {
      final store = _NeverCompletingPlatform();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      await expectLater(
        preferences
            .getString('key')
            .timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('并发场景 coverage', () {
    test('concurrent interleaved reads and writes stay consistent', () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      await preferences.setString('keyA', 'initial');

      // 对同一 key 并发写入与读取交叉进行，另并发写入其它 key。
      await Future.wait(<Future<dynamic>>[
        preferences.setString('keyA', 'a1'),
        preferences.getString('keyA'),
        preferences.setString('keyA', 'a2'),
        preferences.setString('keyB', 'b1'),
        preferences.getString('keyB'),
        preferences.getKeys(),
      ]);

      // 最终值必须是某个合法写入值，不允许出现交错损坏。
      final String? valueA = await preferences.getString('keyA');
      expect(<String?>['initial', 'a1', 'a2'], contains(valueA));
      expect(await preferences.getString('keyB'), 'b1');
    });

    test('concurrent clear and getAll never expose a partially cleared store',
        () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();

      for (int i = 0; i < 10; i++) {
        await preferences.setString('key$i', 'value$i');
      }

      await Future.wait(<Future<dynamic>>[
        preferences.clear(),
        preferences.getAll(),
        preferences.clear(),
        preferences.getAll(),
        preferences.setString('after', 'value'),
      ]);

      // clear 与 setString 并发完成后，最终状态必须是完整清空或只保留
      // 最后一次写入；不允许出现部分残留导致的数据损坏。
      final Map<String, Object?> all = await preferences.getAll();
      expect(all.length, lessThanOrEqualTo(1));
      if (all.isNotEmpty) {
        expect(all['after'], 'value');
      }
    });

    test('multiple cache instances can access the platform concurrently',
        () async {
      final store = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = store;

      final SharedPreferencesWithCache cacheA =
          await SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions(),
          );
      final SharedPreferencesWithCache cacheB =
          await SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions(),
          );

      // 两个实例并发写入各自的 key。
      await Future.wait(<Future<void>>[
        cacheA.setString('fromA', 'a'),
        cacheB.setString('fromB', 'b'),
        cacheA.setInt('numA', 1),
        cacheB.setInt('numB', 2),
      ]);

      // 每个实例的缓存包含自己写入的数据。
      expect(cacheA.getString('fromA'), 'a');
      expect(cacheB.getString('fromB'), 'b');

      // reloadCache 后两个实例都能看到对方写入的数据（平台层共享）。
      await cacheA.reloadCache();
      expect(cacheA.getString('fromB'), 'b');
      await cacheB.reloadCache();
      expect(cacheB.getString('fromA'), 'a');
    });
  });
}

/// 平台层抛权限错误（PlatformException），验证异常能传播到调用方。
base class _PermissionDeniedPlatform extends InMemorySharedPreferencesAsync {
  _PermissionDeniedPlatform() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    return Future<bool>.error(
      PlatformException(
        code: 'preferences_permission_denied',
        message: 'write permission denied',
      ),
    );
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    return Future<String?>.error(
      PlatformException(
        code: 'preferences_permission_denied',
        message: 'read permission denied',
      ),
    );
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    return Future<Map<String, Object>>.error(
      PlatformException(
        code: 'preferences_permission_denied',
        message: 'read permission denied',
      ),
    );
  }
}

/// 永不完成的平台，配合 .timeout() 验证超时异常。
base class _NeverCompletingPlatform extends InMemorySharedPreferencesAsync {
  _NeverCompletingPlatform() : super.empty();

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    return Completer<String?>().future;
  }
}
