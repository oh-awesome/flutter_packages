// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/src/services/binary_messenger.dart';
import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_ohos/src/shared_preferences_async_ohos.dart';
import 'package:shared_preferences_ohos/src/messages_async.g.dart';
import 'package:shared_preferences_ohos/src/strings.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

// The reserved prefix that marks an encoded list payload; setString rejects
// raw values starting with it so list entries cannot be spoofed.
const String _reservedListPrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  SharedPreferencesAsyncOhos getPreferences(bool useDataStore) {
    final api = _FakeSharedPreferencesApi();
    final preferences = SharedPreferencesAsyncOhos(
      dataStoreApi: api,
      sharedPreferencesApi: api,
    );

    return preferences;
  }

  void runTests(bool useDataStore) {
    final backend = useDataStore ? 'DataStore' : 'SharedPreferences';

    final emptyOptions = SharedPreferencesAsyncOhosOptions(
      backend: useDataStore
          ? SharedPreferencesOhosBackendLibrary.DataStore
          : SharedPreferencesOhosBackendLibrary.SharedPreferences,
    );

    test('set and get String with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );

      await preferences.setString(stringKey, testString, emptyOptions);
      expect(await preferences.getString(stringKey, emptyOptions), testString);
    });

    test('set and get bool with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );

      await preferences.setBool(boolKey, testBool, emptyOptions);
      expect(await preferences.getBool(boolKey, emptyOptions), testBool);
    });

    test('set and get int with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );

      await preferences.setInt(intKey, testInt, emptyOptions);
      expect(await preferences.getInt(intKey, emptyOptions), testInt);
    });

    test('set and get double with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );

      await preferences.setDouble(doubleKey, testDouble, emptyOptions);
      expect(await preferences.getDouble(doubleKey, emptyOptions), testDouble);
    });

    test('set and get StringList with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );

      await preferences.setStringList(listKey, testList, emptyOptions);
      final List<String>? response = await preferences.getStringList(
        listKey,
        emptyOptions,
      );

      expect(response, testList);
    });

    test('getPreferences with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);

      final Map<String, Object?> gotAll = await preferences.getPreferences(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        emptyOptions,
      );

      expect(gotAll.length, 5);
      expect(gotAll[stringKey], testString);
      expect(gotAll[boolKey], testBool);
      expect(gotAll[intKey], testInt);
      expect(gotAll[doubleKey], testDouble);
      expect(gotAll[listKey], testList);
    });

    test('getPreferences with filter with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);

      final Map<String, Object?> gotAll = await preferences.getPreferences(
        const GetPreferencesParameters(
          filter: PreferencesFilters(allowList: <String>{stringKey, boolKey}),
        ),
        emptyOptions,
      );

      expect(gotAll.length, 2);
      expect(gotAll[stringKey], testString);
      expect(gotAll[boolKey], testBool);
    });

    test('getKeys with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);

      final Set<String> keys = await preferences.getKeys(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        emptyOptions,
      );

      expect(keys.length, 5);
      expect(keys, contains(stringKey));
      expect(keys, contains(boolKey));
      expect(keys, contains(intKey));
      expect(keys, contains(doubleKey));
      expect(keys, contains(listKey));
    });

    test('getKeys with filter with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);

      final Set<String> keys = await preferences.getKeys(
        const GetPreferencesParameters(
          filter: PreferencesFilters(allowList: <String>{stringKey, boolKey}),
        ),
        emptyOptions,
      );

      expect(keys.length, 2);
      expect(keys, contains(stringKey));
      expect(keys, contains(boolKey));
    });

    test('clear with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);
      await preferences.clear(
        const ClearPreferencesParameters(filter: PreferencesFilters()),
        emptyOptions,
      );
      expect(await preferences.getString(stringKey, emptyOptions), null);
      expect(await preferences.getBool(boolKey, emptyOptions), null);
      expect(await preferences.getInt(intKey, emptyOptions), null);
      expect(await preferences.getDouble(doubleKey, emptyOptions), null);
      expect(await preferences.getStringList(listKey, emptyOptions), null);
    });

    test('clear with filter with $backend', () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(
        useDataStore,
      );
      await Future.wait(<Future<void>>[
        preferences.setString(stringKey, testString, emptyOptions),
        preferences.setBool(boolKey, testBool, emptyOptions),
        preferences.setInt(intKey, testInt, emptyOptions),
        preferences.setDouble(doubleKey, testDouble, emptyOptions),
        preferences.setStringList(listKey, testList, emptyOptions),
      ]);
      await preferences.clear(
        const ClearPreferencesParameters(
          filter: PreferencesFilters(allowList: <String>{stringKey, boolKey}),
        ),
        emptyOptions,
      );
      expect(await preferences.getString(stringKey, emptyOptions), null);
      expect(await preferences.getBool(boolKey, emptyOptions), null);
      expect(await preferences.getInt(intKey, emptyOptions), testInt);
      expect(await preferences.getDouble(doubleKey, emptyOptions), testDouble);
      expect(await preferences.getStringList(listKey, emptyOptions), testList);
    });
  }

  runTests(true);
  runTests(false);

  test('registerWith', () {
    SharedPreferencesAsyncOhos.registerWith();
    expect(
      SharedPreferencesAsyncPlatform.instance,
      isA<SharedPreferencesAsyncOhos>(),
    );
  });

  test('convertOptionsToPigeonOptions', () {
    final SharedPreferencesAsyncOhos preferences = getPreferences(true);

    final SharedPreferencesPigeonOptions dataStoreOptions = preferences
        .convertOptionsToPigeonOptions(
          const SharedPreferencesAsyncOhosOptions(),
        );
    expect(dataStoreOptions.useDataStore, isTrue);
    expect(dataStoreOptions.fileName, isNull);

    final SharedPreferencesPigeonOptions sharedPreferencesOptions = preferences
        .convertOptionsToPigeonOptions(
          const SharedPreferencesAsyncOhosOptions(
            backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
            originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
              fileName: 'the_name_of_a_file',
            ),
          ),
        );
    expect(sharedPreferencesOptions.useDataStore, isFalse);
    expect(sharedPreferencesOptions.fileName, 'the_name_of_a_file');

    final SharedPreferencesPigeonOptions defaultOptions = preferences
        .convertOptionsToPigeonOptions(const SharedPreferencesOptions());
    expect(defaultOptions.useDataStore, isTrue);
    expect(defaultOptions.fileName, isNull);
  });

  test('getApiForBackend', () {
    final dataStoreApi = _FakeSharedPreferencesApi();
    final sharedPreferencesApi = _FakeSharedPreferencesApi();
    final SharedPreferencesAsyncOhos preferences = SharedPreferencesAsyncOhos(
      dataStoreApi: dataStoreApi,
      sharedPreferencesApi: sharedPreferencesApi,
    );

    expect(
      preferences.getApiForBackend(SharedPreferencesPigeonOptions()),
      same(dataStoreApi),
    );
    expect(
      preferences.getApiForBackend(
        SharedPreferencesPigeonOptions(useDataStore: false),
      ),
      same(sharedPreferencesApi),
    );
  });

  test(
    'setString rejects values starting with the reserved list prefix',
    () async {
      final SharedPreferencesAsyncOhos preferences = getPreferences(true);

      await expectLater(
        preferences.setString(
          stringKey,
          _reservedListPrefix,
          const SharedPreferencesOptions(),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'getInt throws TypeError when the platform reports a ClassCastException',
    () async {
      final api = _ClassCastFakeSharedPreferencesApi();
      final SharedPreferencesAsyncOhos preferences = SharedPreferencesAsyncOhos(
        dataStoreApi: api,
        sharedPreferencesApi: api,
      );

      await expectLater(
        preferences.getInt(intKey, const SharedPreferencesOptions()),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test(
    'getStringList throws TypeError when the stored payload cannot be decoded',
    () async {
      final api = _FakeSharedPreferencesApi();
      final SharedPreferencesAsyncOhos preferences = SharedPreferencesAsyncOhos(
        dataStoreApi: api,
        sharedPreferencesApi: api,
      );
      await preferences.setStringList(
        listKey,
        testList,
        const SharedPreferencesOptions(),
      );
      // Simulate a corrupted list payload written by an unknown writer.
      api.items[listKey] = '$jsonListPrefix:not-a-json-list';
      await expectLater(
        preferences.getStringList(listKey, const SharedPreferencesOptions()),
        throwsA(isA<TypeError>()),
      );
    },
  );

  test('set and get int64 boundary values', () async {
    final SharedPreferencesAsyncOhos preferences = getPreferences(true);

    const minInt64 = -9223372036854775808;
    const maxInt64 = 9223372036854775807;
    await preferences.setInt(
      'min_int64',
      minInt64,
      const SharedPreferencesOptions(),
    );
    await preferences.setInt(
      'max_int64',
      maxInt64,
      const SharedPreferencesOptions(),
    );
    expect(
      await preferences.getInt('min_int64', const SharedPreferencesOptions()),
      minInt64,
    );
    expect(
      await preferences.getInt('max_int64', const SharedPreferencesOptions()),
      maxInt64,
    );
  });

  test('set and get double boundary values', () async {
    final SharedPreferencesAsyncOhos preferences = getPreferences(true);

    const maxDouble = 1.7976931348623157e+308;
    const minDouble = 5e-324;
    await preferences.setDouble(
      'max_double',
      maxDouble,
      const SharedPreferencesOptions(),
    );
    await preferences.setDouble(
      'min_double',
      minDouble,
      const SharedPreferencesOptions(),
    );
    expect(
      await preferences.getDouble(
        'max_double',
        const SharedPreferencesOptions(),
      ),
      maxDouble,
    );
    expect(
      await preferences.getDouble(
        'min_double',
        const SharedPreferencesOptions(),
      ),
      minDouble,
    );
  });

  test('set and get an empty key and an empty String value', () async {
    final SharedPreferencesAsyncOhos preferences = getPreferences(true);

    await preferences.setString(
      stringKey,
      '',
      const SharedPreferencesOptions(),
    );
    expect(
      await preferences.getString(stringKey, const SharedPreferencesOptions()),
      '',
    );

    await preferences.setString(
      '',
      'value stored under an empty key',
      const SharedPreferencesOptions(),
    );
    expect(
      await preferences.getString('', const SharedPreferencesOptions()),
      'value stored under an empty key',
    );
  });

  test('set and get an empty StringList', () async {
    final SharedPreferencesAsyncOhos preferences = getPreferences(true);

    await preferences.setStringList(
      listKey,
      const <String>[],
      const SharedPreferencesOptions(),
    );
    expect(
      await preferences.getStringList(
        listKey,
        const SharedPreferencesOptions(),
      ),
      isEmpty,
    );
  });
}

class _FakeSharedPreferencesApi implements SharedPreferencesAsyncApi {
  final Map<String, Object> items = <String, Object>{};

  @override
  BinaryMessenger? get pigeonVar_binaryMessenger => throw UnimplementedError();

  @override
  String get pigeonVar_messageChannelSuffix => throw UnimplementedError();

  @override
  Future<bool> clear(
    List<String?>? allowList,
    SharedPreferencesPigeonOptions options,
  ) async {
    if (allowList != null) {
      items.removeWhere((String key, _) => allowList.contains(key));
    } else {
      items.clear();
    }

    return true;
  }

  @override
  Future<Map<String, Object>> getAll(
    List<String?>? allowList,
    SharedPreferencesPigeonOptions options,
  ) async {
    final filteredItems = <String, Object>{...items};
    if (allowList != null) {
      filteredItems.removeWhere((String key, _) => !allowList.contains(key));
    }
    return filteredItems;
  }

  @override
  Future<bool?> getBool(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    return items[key] as bool?;
  }

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    return items[key] as double?;
  }

  @override
  Future<int?> getInt(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    return items[key] as int?;
  }

  @override
  Future<List<String>> getKeys(
    List<String?>? allowList,
    SharedPreferencesPigeonOptions options,
  ) async {
    final List<String> filteredItems = items.keys.toList();
    if (allowList != null) {
      filteredItems.removeWhere((String key) => !allowList.contains(key));
    }
    return filteredItems;
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    return items[key] as String?;
  }

  @override
  Future<StringListResult?> getStringList(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    final Object? value = items[key];
    return value == null
        ? null
        : StringListResult(
            jsonEncodedValue: value as String?,
            type: StringListLookupResultType.jsonEncoded,
          );
  }

  @override
  Future<List<String>?> getPlatformEncodedStringList(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    return items[key] as List<String>?;
  }

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(
    String key,
    double value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(
    String key,
    int value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = value;
    return true;
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = value;
    return true;
  }

  @override
  Future<bool> setEncodedStringList(
    String key,
    String value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = '$jsonListPrefix${jsonEncode(value)}';
    return true;
  }

  @override
  Future<bool> setDeprecatedStringList(
    String key,
    List<String> value,
    SharedPreferencesPigeonOptions options,
  ) async {
    items[key] = value;
    return true;
  }
}

// Reports the ohos ClassCastException for int reads, to verify the public
// API converts it to a TypeError as the platform interface contract expects.
class _ClassCastFakeSharedPreferencesApi extends _FakeSharedPreferencesApi {
  @override
  Future<int?> getInt(
    String key,
    SharedPreferencesPigeonOptions options,
  ) async {
    throw PlatformException(code: 'ClassCastException');
  }
}
