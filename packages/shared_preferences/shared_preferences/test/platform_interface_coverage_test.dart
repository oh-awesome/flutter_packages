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
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

const MethodChannel _kChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> channelLog;

  setUp(() {
    channelLog = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kChannel, (MethodCall call) async {
          channelLog.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kChannel, null);
  });

  group('MethodChannelSharedPreferencesStore', () {
    late MethodChannelSharedPreferencesStore store;

    setUp(() {
      store = MethodChannelSharedPreferencesStore();
    });

    test('remove sends the key over the method channel', () async {
      expect(await store.remove('someKey'), isTrue);
      expect(
        channelLog.single,
        isMethodCall('remove', arguments: <String, dynamic>{'key': 'someKey'}),
      );
    });

    test('setValue encodes the value type into the channel method name',
        () async {
      expect(await store.setValue('String', 'someKey', 'someValue'), isTrue);
      expect(
        channelLog.single,
        isMethodCall('setString', arguments: <String, dynamic>{
          'key': 'someKey',
          'value': 'someValue',
        }),
      );
    });

    test('clear sends a bare clear request over the method channel', () async {
      expect(await store.clear(), isTrue);
      expect(channelLog.single, isMethodCall('clear', arguments: null));
    });

    test('clearWithPrefix forwards the prefix to clearWithParameters',
        () async {
      // ignore: deprecated_member_use
      expect(await store.clearWithPrefix('flutter.'), isTrue);
      expect(
        channelLog.single,
        isMethodCall('clearWithParameters', arguments: <String, dynamic>{
          'prefix': 'flutter.',
          'allowList': null,
        }),
      );
    });

    test('clearWithParameters forwards the filter to the method channel',
        () async {
      expect(
        await store.clearWithParameters(
          ClearParameters(
            filter: PreferencesFilter(
              prefix: 'custom.',
              allowList: <String>{'a', 'b'},
            ),
          ),
        ),
        isTrue,
      );
      expect(
        channelLog.single,
        isMethodCall('clearWithParameters', arguments: <String, dynamic>{
          'prefix': 'custom.',
          'allowList': <String>['a', 'b'],
        }),
      );
    });

    test('platform exceptions thrown by the channel are propagated', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_kChannel, (MethodCall call) async {
            throw PlatformException(code: 'boom');
          });
      await expectLater(
        store.clear(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('a platform call that never completes times out', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_kChannel, (MethodCall call) {
            return Completer<Object?>().future;
          });
      await expectLater(
        store.clear().timeout(const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('SharedPreferencesAsyncPlatform', () {
    const SharedPreferencesOptions options = SharedPreferencesOptions();
    const stringKey = 'testString';
    const boolKey = 'testBool';
    const intKey = 'testInt';
    const doubleKey = 'testDouble';
    const listKey = 'testList';
    const testString = 'hello world';
    const testBool = true;
    const testInt = 42;
    const testDouble = 3.14159;
    const testList = <String>['foo', 'bar'];

    test('all five value types round-trip through the platform interface',
        () async {
      final SharedPreferencesAsyncPlatform platform =
          _RecordingAsyncPlatform();
      await platform.setString(stringKey, testString, options);
      await platform.setBool(boolKey, testBool, options);
      await platform.setInt(intKey, testInt, options);
      await platform.setDouble(doubleKey, testDouble, options);
      await platform.setStringList(listKey, testList, options);

      expect(await platform.getString(stringKey, options), testString);
      expect(await platform.getBool(boolKey, options), testBool);
      expect(await platform.getInt(intKey, options), testInt);
      expect(await platform.getDouble(doubleKey, options), testDouble);
      expect(await platform.getStringList(listKey, options), testList);
    });

    test('clear and getKeys respect the allowList filter', () async {
      final SharedPreferencesAsyncPlatform platform =
          _RecordingAsyncPlatform();
      await platform.setString(stringKey, testString, options);
      await platform.setInt(intKey, testInt, options);

      expect(
        await platform.getKeys(
          GetPreferencesParameters(
            filter: PreferencesFilters(allowList: <String>{stringKey}),
          ),
          options,
        ),
        <String>{stringKey},
      );

      await platform.clear(
        ClearPreferencesParameters(
          filter: PreferencesFilters(allowList: <String>{stringKey}),
        ),
        options,
      );

      expect(await platform.getString(stringKey, options), isNull);
      expect(await platform.getInt(intKey, options), testInt);
    });

    test('getPreferences returns the full preference map', () async {
      final SharedPreferencesAsyncPlatform platform =
          _RecordingAsyncPlatform();
      await platform.setString(stringKey, testString, options);
      await platform.setInt(intKey, testInt, options);

      expect(
        await platform.getPreferences(
          GetPreferencesParameters(filter: PreferencesFilters()),
          options,
        ),
        <String, Object>{stringKey: testString, intKey: testInt},
      );
    });
  });

  group('SharedPreferencesStorePlatform', () {
    test('a store implementing the legacy interface reports isMock=false', () {
      final SharedPreferencesStorePlatform storePlatform = _RecordingStore();
      expect(storePlatform.isMock, isFalse);
    });

    test('setValue, remove and clear mutate the store', () async {
      final SharedPreferencesStorePlatform storePlatform = _RecordingStore();
      expect(
        await storePlatform.setValue('String', 'someKey', 'someValue'),
        isTrue,
      );
      expect(await storePlatform.remove('someKey'), isTrue);
      expect(await storePlatform.clear(), isTrue);
    });

    test('getAll returns all stored values', () async {
      final SharedPreferencesStorePlatform storePlatform = _RecordingStore();
      await storePlatform.setValue('String', 'flutter.someKey', 'someValue');
      expect(
        await storePlatform.getAll(),
        <String, Object>{'flutter.someKey': 'someValue'},
      );
    });

    test('clearWithPrefix only clears keys under the given prefix', () async {
      final SharedPreferencesStorePlatform storePlatform = _RecordingStore();
      await storePlatform.setValue('String', 'flutter.a', '1');
      await storePlatform.setValue('String', 'custom.b', '2');
      // ignore: deprecated_member_use
      expect(await storePlatform.clearWithPrefix('flutter.'), isTrue);
      expect(
        await storePlatform.getAllWithParameters(
          GetAllParameters(filter: PreferencesFilter(prefix: '')),
        ),
        <String, Object>{'custom.b': '2'},
      );
    });

    test('clearWithParameters honors an allowList', () async {
      final SharedPreferencesStorePlatform storePlatform = _RecordingStore();
      await storePlatform.setValue('String', 'flutter.a', '1');
      await storePlatform.setValue('String', 'flutter.b', '2');
      expect(
        await storePlatform.clearWithParameters(
          ClearParameters(
            filter: PreferencesFilter(
              prefix: 'flutter.',
              allowList: <String>{'flutter.a'},
            ),
          ),
        ),
        isTrue,
      );
      expect(
        await storePlatform.getAllWithParameters(
          GetAllParameters(filter: PreferencesFilter(prefix: '')),
        ),
        <String, Object>{'flutter.b': '2'},
      );
    });
  });

  group('InMemorySharedPreferencesStore', () {
    late InMemorySharedPreferencesStore memoryStore;

    setUp(() {
      memoryStore = InMemorySharedPreferencesStore.withData(<String, Object>{
        'flutter.a': 1,
        'flutter.b': 2,
        'custom.c': 3,
      });
    });

    test('clearWithPrefix removes only the keys matching the prefix',
        () async {
      // ignore: deprecated_member_use
      expect(await memoryStore.clearWithPrefix('flutter.'), isTrue);
      expect(
        await memoryStore.getAllWithParameters(
          GetAllParameters(filter: PreferencesFilter(prefix: '')),
        ),
        <String, Object>{'custom.c': 3},
      );
    });
  });
}

base class _RecordingAsyncPlatform extends SharedPreferencesAsyncPlatform {
  _RecordingAsyncPlatform() : delegate = InMemorySharedPreferencesAsync.empty();

  // Typed as the base class so every delegate call below exercises a
  // SharedPreferencesAsyncPlatform method.
  final SharedPreferencesAsyncPlatform delegate;

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    return delegate.setString(key, value, options);
  }

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) {
    return delegate.setBool(key, value, options);
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) {
    return delegate.setDouble(key, value, options);
  }

  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) {
    return delegate.setInt(key, value, options);
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) {
    return delegate.setStringList(key, value, options);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    return delegate.getString(key, options);
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) {
    return delegate.getBool(key, options);
  }

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) {
    return delegate.getDouble(key, options);
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) {
    return delegate.getInt(key, options);
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) {
    return delegate.getStringList(key, options);
  }

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    return delegate.clear(parameters, options);
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    return delegate.getPreferences(parameters, options);
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    return delegate.getKeys(parameters, options);
  }
}

class _RecordingStore extends SharedPreferencesStorePlatform {
  _RecordingStore() : delegate = InMemorySharedPreferencesStore.empty();

  // Typed as the base class so every delegate call below exercises a
  // SharedPreferencesStorePlatform method.
  final SharedPreferencesStorePlatform delegate;

  @override
  Future<bool> remove(String key) {
    return delegate.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    return delegate.setValue(valueType, key, value);
  }

  @override
  Future<bool> clear() {
    return delegate.clear();
  }

  @override
  Future<bool> clearWithPrefix(String prefix) {
    // ignore: deprecated_member_use
    return delegate.clearWithPrefix(prefix);
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) {
    return delegate.clearWithParameters(parameters);
  }

  @override
  Future<Map<String, Object>> getAll() {
    return delegate.getAll();
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) {
    return delegate.getAllWithParameters(parameters);
  }
}
