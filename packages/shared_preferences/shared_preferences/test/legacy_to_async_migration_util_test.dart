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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stringKey = 'testString';
  const boolKey = 'testBool';
  const intKey = 'testInt';
  const doubleKey = 'testDouble';
  const listKey = 'testList';
  const migrationCompletedKey = 'migrationCompleted';

  late SharedPreferences legacyPreferences;
  late SharedPreferencesAsync asyncPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      boolKey: true,
      intKey: 42,
      doubleKey: 3.14159,
      stringKey: 'hello world',
      listKey: <String>['foo', 'bar'],
    });
    legacyPreferences = await SharedPreferences.getInstance();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    asyncPreferences = SharedPreferencesAsync();
  });

  tearDown(() {
    SharedPreferences.resetStatic();
    SharedPreferencesAsyncPlatform.instance = null;
  });

  Future<void> runMigration() {
    return migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacyPreferences,
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: migrationCompletedKey,
    );
  }

  test('data is successfully transferred to new system', () async {
    await runMigration();

    expect(await asyncPreferences.getBool(boolKey), true);
    expect(await asyncPreferences.getInt(intKey), 42);
    expect(await asyncPreferences.getDouble(doubleKey), 3.14159);
    expect(await asyncPreferences.getString(stringKey), 'hello world');
    expect(await asyncPreferences.getStringList(listKey), <String>[
      'foo',
      'bar',
    ]);
  });

  test('migrationCompleted key is set to true', () async {
    await runMigration();

    expect(await asyncPreferences.getBool(migrationCompletedKey), true);
  });

  test('re-running migration tool does not overwrite data', () async {
    await runMigration();

    // Simulate new data written through the async system after the migration.
    await asyncPreferences.setString(stringKey, 'new value');

    // Change the legacy value to prove the re-run skips the transfer.
    await legacyPreferences.setString(stringKey, 'stale legacy value');
    await runMigration();

    expect(await asyncPreferences.getString(stringKey), 'new value');
    expect(await asyncPreferences.getBool(migrationCompletedKey), true);
  });
}
