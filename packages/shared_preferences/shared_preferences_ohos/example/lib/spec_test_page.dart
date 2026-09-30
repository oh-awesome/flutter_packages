// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class SpecTestPage extends StatefulWidget {
  const SpecTestPage({
    super.key,
    required this.options,
  });

  final SharedPreferencesAsyncOhosOptions options;

  @override
  State<SpecTestPage> createState() => _SpecTestPageState();
}

class _CheckResult {
  const _CheckResult(this.title, this.pass, this.detail);

  final String title;
  final bool pass;
  final String detail;
}

class _SectionResult {
  const _SectionResult(this.name, this.checks);

  final String name;
  final List<_CheckResult> checks;
}

class _SpecTestPageState extends State<SpecTestPage> {
  static const String _legacyDoublePrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGRvdWJsZS4';
  static const String _doublePrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu';

  static const int _concurrentWriteCount = 100;

  // Isolated file for the async-API fix checks.
  static const SharedPreferencesAsyncOhosOptions _demoOptions =
      SharedPreferencesAsyncOhosOptions(
    backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
    originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
      fileName: 'spec_verify_demo',
    ),
  );

  // Points at the same preferences instance the legacy API uses, so values
  // seeded here emulate real historical data in the production file.
  static const SharedPreferencesAsyncOhosOptions _legacyFileOptions =
      SharedPreferencesAsyncOhosOptions(
    backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
    originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
      fileName: 'FlutterSharedPreferences',
    ),
  );

  // Options used by the async API-coverage checks, kept from the original
  // demo: SharedPreferences backend + a dedicated file name.
  static const SharedPreferencesAsyncOhosOptions _coverageAsyncOptions =
      SharedPreferencesAsyncOhosOptions(
    backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
    originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
      fileName: 'example_shared_preferences',
    ),
  );

  List<_SectionResult> _sections = <_SectionResult>[];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _running = true;
    });
    final List<_SectionResult> sections = <_SectionResult>[];
    try {
      final SharedPreferencesAsyncOhos asyncApi = SharedPreferencesAsyncOhos();
      sections.add(await _runOhosStoreSection());
      sections.add(await _runAsyncApiSection(asyncApi));
      sections.add(await _runLegacyApiSection());
    } catch (e, stackTrace) {
      sections.add(_SectionResult('运行异常', <_CheckResult>[
        _CheckResult('测试执行中断', false, '$e\n$stackTrace'),
      ]));
    }
    setState(() {
      _sections = sections;
      _running = false;
    });
  }

  // === SharedPreferencesOhos direct interface ===

  Future<_SectionResult> _runOhosStoreSection() async {
    final SharedPreferencesOhos ohosStore = SharedPreferencesOhos();
    const String storeStringKey = 'flutter.ohos_store_demo_string';
    const String storeIntKey = 'flutter.ohos_store_demo_int';
    const String storeDoubleKey = 'flutter.ohos_store_demo_double';
    const String storeBoolKey = 'flutter.ohos_store_demo_bool';
    const String storeListKey = 'flutter.ohos_store_demo_list';
    const String removableStoreKey = 'flutter.ohos_store_demo_remove';
    const String parameterKeepKey = 'flutter.ohos_parameter_scope_keep';
    const String parameterDeleteKey = 'flutter.ohos_parameter_scope_delete';
    const String clearPrefixKey1 = 'flutter.ohos_clear_prefix_demo_1';
    const String clearPrefixKey2 = 'flutter.ohos_clear_prefix_demo_2';
    const String clearDefaultKey = 'flutter.ohos_clear_default_demo';
    final List<_CheckResult> checks = <_CheckResult>[];

    final bool setString = await ohosStore.setValue(
      'String',
      storeStringKey,
      'via SharedPreferencesOhos',
    );
    final bool setInt = await ohosStore.setValue('Int', storeIntKey, 7);
    final bool setDouble = await ohosStore.setValue('Double', storeDoubleKey, 7.7);
    final bool setBool = await ohosStore.setValue('Bool', storeBoolKey, true);
    final bool setList = await ohosStore.setValue(
      'StringList',
      storeListKey,
      <String>['one', 'two', 'three'],
    );
    checks.add(_CheckResult(
      'setValue 写入 5 种类型（String/Int/Double/Bool/StringList）',
      setString && setInt && setDouble && setBool && setList,
      'String: $setString, Int: $setInt, Double: $setDouble, '
          'Bool: $setBool, StringList: $setList\n期望: 全部 true',
    ));

    await ohosStore.setValue('String', removableStoreKey, 'to be removed');
    await ohosStore.setValue('String', parameterKeepKey, 'keep by allowList');
    await ohosStore.setValue(
        'String', parameterDeleteKey, 'delete by allowList');
    await ohosStore.setValue('String', clearPrefixKey1, 'prefix value 1');
    await ohosStore.setValue('String', clearPrefixKey2, 'prefix value 2');
    await ohosStore.setValue('String', clearDefaultKey, 'clear default scope');

    final Map<String, Object> allData = await ohosStore.getAll();
    final Object? listInAll = allData[storeListKey];
    checks.add(_CheckResult(
      'getAll 返回 5 种类型的写入值',
      allData[storeStringKey] == 'via SharedPreferencesOhos' &&
          allData[storeIntKey] == 7 &&
          allData[storeDoubleKey] == 7.7 &&
          allData[storeBoolKey] == true &&
          listInAll is List &&
          listInAll.join(',') == 'one,two,three',
      'String: ${allData[storeStringKey]}, Int: ${allData[storeIntKey]}, '
          'Double: ${allData[storeDoubleKey]}, Bool: ${allData[storeBoolKey]}\n'
          'StringList: ${listInAll?.runtimeType} $listInAll\n期望: 与写入值一致',
    ));

    final Map<String, Object> prefixData =
        await ohosStore.getAllWithPrefix('flutter.ohos_store_demo_');
    checks.add(_CheckResult(
      'getAllWithPrefix 前缀过滤',
      prefixData.containsKey(storeStringKey) &&
          !prefixData.containsKey(parameterKeepKey),
      '命中 ${prefixData.length} 个 flutter.ohos_store_demo_ 前缀 key\n'
          '包含 $storeStringKey: ${prefixData.containsKey(storeStringKey)}\n'
          '不含作用域外 key: ${!prefixData.containsKey(parameterKeepKey)}',
    ));

    final Map<String, Object> filteredData = await ohosStore.getAllWithParameters(
      GetAllParameters(
        filter: PreferencesFilter(
          prefix: 'flutter.ohos_parameter_scope_',
          allowList: <String>{parameterKeepKey},
        ),
      ),
    );
    checks.add(_CheckResult(
      'getAllWithParameters prefix + allowList 过滤',
      filteredData.containsKey(parameterKeepKey) &&
          !filteredData.containsKey(parameterDeleteKey),
      '命中 key: ${filteredData.keys.toList()}\n'
          '期望: 仅 [$parameterKeepKey]',
    ));

    final bool removeResult = await ohosStore.remove(removableStoreKey);
    final Map<String, Object> afterRemove =
        await ohosStore.getAllWithPrefix('flutter.ohos_store_demo_');
    checks.add(_CheckResult(
      'remove 删除指定 key',
      removeResult && !afterRemove.containsKey(removableStoreKey),
      '返回: $removeResult\n删除后仍存在: ${afterRemove.containsKey(removableStoreKey)}\n'
          '期望: true 且已删除',
    ));

    final bool clearWithParametersResult = await ohosStore.clearWithParameters(
      ClearParameters(
        filter: PreferencesFilter(
          prefix: 'flutter.ohos_parameter_scope_',
          allowList: <String>{parameterDeleteKey},
        ),
      ),
    );
    final Map<String, Object> parameterDataAfterClear =
        await ohosStore.getAllWithPrefix('flutter.ohos_parameter_scope_');
    checks.add(_CheckResult(
      'clearWithParameters 只删除 allowList 命中 key',
      clearWithParametersResult &&
          !parameterDataAfterClear.containsKey(parameterDeleteKey) &&
          parameterDataAfterClear.containsKey(parameterKeepKey),
      '返回: $clearWithParametersResult\n'
          '已删 $parameterDeleteKey: ${!parameterDataAfterClear.containsKey(parameterDeleteKey)}\n'
          '保留 $parameterKeepKey: ${parameterDataAfterClear.containsKey(parameterKeepKey)}',
    ));

    final bool clearWithPrefixResult = await ohosStore.clearWithPrefix(
      'flutter.ohos_clear_prefix_demo_',
    );
    final Map<String, Object> clearPrefixAfterClear =
        await ohosStore.getAllWithPrefix('flutter.ohos_clear_prefix_demo_');
    checks.add(_CheckResult(
      'clearWithPrefix 删除指定前缀 key',
      clearWithPrefixResult && clearPrefixAfterClear.isEmpty,
      '返回: $clearWithPrefixResult\n剩余: ${clearPrefixAfterClear.keys.toList()}\n'
          '期望: true 且清空',
    ));

    final Map<String, Object> clearDefaultBeforeClear =
        await ohosStore.getAllWithPrefix('flutter.ohos_clear_default_');
    final bool clearResult = await ohosStore.clear();
    final Map<String, Object> clearDefaultAfterClear =
        await ohosStore.getAllWithPrefix('flutter.ohos_clear_default_');
    checks.add(_CheckResult(
      'clear 清空默认 flutter. 作用域',
      clearDefaultBeforeClear.containsKey(clearDefaultKey) &&
          clearResult &&
          clearDefaultAfterClear.isEmpty,
      '清理前存在 $clearDefaultKey: '
          '${clearDefaultBeforeClear.containsKey(clearDefaultKey)}\n'
          '返回: $clearResult\n清理后剩余: ${clearDefaultAfterClear.keys.toList()}',
    ));

    return _SectionResult('SharedPreferencesOhos 直连接口', checks);
  }

  // === SharedPreferencesAsyncOhos interface + #1689 / concurrent fixes ===

  Future<_SectionResult> _runAsyncApiSection(
    SharedPreferencesAsyncOhos asyncApi,
  ) async {
    const String asyncStringKey = 'ohos_async_demo_string';
    const String asyncIntKey = 'ohos_async_demo_int';
    const String asyncDoubleKey = 'ohos_async_demo_double';
    const String asyncBoolKey = 'ohos_async_demo_bool';
    const String asyncListKey = 'ohos_async_demo_list';
    const Set<String> asyncAllowList = <String>{asyncStringKey, asyncBoolKey};
    const Set<String> asyncClearAllowList = <String>{asyncBoolKey, asyncListKey};
    const String kLegacyDouble = 'spec_legacy_double';
    const String kHardenedDouble = 'spec_hardened_double';
    const String kPlainDouble = 'spec_plain_double';
    final List<_CheckResult> checks = <_CheckResult>[];

    await asyncApi.setString(
      asyncStringKey,
      'via SharedPreferencesAsyncOhos',
      _coverageAsyncOptions,
    );
    await asyncApi.setInt(
        asyncIntKey, 9223372036854775807, _coverageAsyncOptions);
    await asyncApi.setDouble(asyncDoubleKey, 100.1, _coverageAsyncOptions);
    await asyncApi.setBool(asyncBoolKey, true, _coverageAsyncOptions);
    await asyncApi.setStringList(
      asyncListKey,
      <String>['red', 'green', 'blue'],
      _coverageAsyncOptions,
    );

    final String? stringValue =
        await asyncApi.getString(asyncStringKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'getString 读回',
      stringValue == 'via SharedPreferencesAsyncOhos',
      '实际: $stringValue\n期望: via SharedPreferencesAsyncOhos',
    ));
    final int? intValue = await asyncApi.getInt(asyncIntKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'getInt 读回（超大整数）',
      intValue == 9223372036854775807,
      '实际: $intValue\n期望: 9223372036854775807',
    ));
    final double? doubleValue =
        await asyncApi.getDouble(asyncDoubleKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'getDouble 读回',
      doubleValue == 100.1,
      '实际: $doubleValue\n期望: 100.1',
    ));
    final bool? boolValue = await asyncApi.getBool(asyncBoolKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'getBool 读回',
      boolValue ?? false,
      '实际: $boolValue\n期望: true',
    ));
    final List<String>? listValue =
        await asyncApi.getStringList(asyncListKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'getStringList 读回',
      listValue != null && listValue.join(',') == 'red,green,blue',
      '实际: $listValue\n期望: [red, green, blue]',
    ));

    final Map<String, Object> allData = await asyncApi.getPreferences(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      _coverageAsyncOptions,
    );
    checks.add(_CheckResult(
      'getPreferences 全量读取',
      allData.containsKey(asyncStringKey) &&
          allData[asyncIntKey] == 9223372036854775807 &&
          allData[asyncDoubleKey] == 100.1,
      '命中 ${allData.length} 个 key，抽样 String/Int/Double 值一致\n'
          '期望: 5 个写入 key 均可读且值正确',
    ));

    final Map<String, Object> filteredData = await asyncApi.getPreferences(
      const GetPreferencesParameters(
        filter: PreferencesFilters(allowList: asyncAllowList),
      ),
      _coverageAsyncOptions,
    );
    checks.add(_CheckResult(
      'getPreferences allowList 过滤',
      filteredData.keys.toSet().containsAll(asyncAllowList) &&
          !filteredData.containsKey(asyncIntKey),
      '命中 key: ${filteredData.keys.toList()}\n期望: 仅 allowList 内的 key',
    ));

    final Set<String> keysBeforeClear = await asyncApi.getKeys(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      _coverageAsyncOptions,
    );
    checks.add(_CheckResult(
      'getKeys 全量',
      keysBeforeClear.containsAll(<String>[asyncStringKey, asyncIntKey]),
      '命中 ${keysBeforeClear.length} 个 key\n期望: 包含全部写入 key',
    ));
    final Set<String> filteredKeys = await asyncApi.getKeys(
      const GetPreferencesParameters(
        filter: PreferencesFilters(allowList: asyncAllowList),
      ),
      _coverageAsyncOptions,
    );
    checks.add(_CheckResult(
      'getKeys allowList 过滤',
      filteredKeys.toSet().containsAll(asyncAllowList) &&
          !filteredKeys.contains(asyncIntKey),
      '命中 key: ${filteredKeys.toList()}\n期望: 仅 allowList 内的 key',
    ));

    await asyncApi.clear(
      const ClearPreferencesParameters(
        filter: PreferencesFilters(allowList: asyncClearAllowList),
      ),
      _coverageAsyncOptions,
    );
    final bool? boolAfterClear =
        await asyncApi.getBool(asyncBoolKey, _coverageAsyncOptions);
    final List<String>? listAfterClear =
        await asyncApi.getStringList(asyncListKey, _coverageAsyncOptions);
    final String? stringAfterClear =
        await asyncApi.getString(asyncStringKey, _coverageAsyncOptions);
    checks.add(_CheckResult(
      'clear allowList 只删除命中 key',
      boolAfterClear == null &&
          listAfterClear == null &&
          stringAfterClear != null,
      '被删 Bool 为 null: ${boolAfterClear == null}, '
          '被删 List 为 null: ${listAfterClear == null}\n'
          '未删 String 仍可读: ${stringAfterClear != null}\n期望: 前两者 null，第三个非 null',
    ));

    // --- #1689 legacy-double fix checks (async getDouble path) ---

    // Value encoded the way pre-hardening versions did (Dart side).
    await asyncApi.setString(
      kLegacyDouble,
      '${_legacyDoublePrefix}100.1',
      _demoOptions,
    );
    final double? legacyValue = await asyncApi.getDouble(kLegacyDouble, _demoOptions);
    checks.add(_CheckResult(
      'LEGACY 前缀编码 → async getDouble 解码',
      legacyValue == 100.1,
      '写入: LEGACY_PREFIX + "100.1"\n读取: $legacyValue\n期望: 100.1',
    ));

    // Value encoded by quality-hardened v2.3.x native setDouble.
    await asyncApi.setString(
      kHardenedDouble,
      '${_doublePrefix}200.5',
      _demoOptions,
    );
    final double? hardenedValue =
        await asyncApi.getDouble(kHardenedDouble, _demoOptions);
    checks.add(_CheckResult(
      'DOUBLE 前缀编码 → async getDouble 解码',
      hardenedValue == 200.5,
      '写入: DOUBLE_PREFIX + "200.5"\n读取: $hardenedValue\n期望: 200.5',
    ));

    // getAll/getPreferences must decode the same key to a num.
    final Map<String, Object> fixAllData = await asyncApi.getPreferences(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      _demoOptions,
    );
    final Object? allValue = fixAllData[kLegacyDouble];
    checks.add(_CheckResult(
      'LEGACY 前缀编码 → getPreferences 解码为 num',
      allValue is num && allValue == 100.1,
      '实际: ${allValue.runtimeType} $allValue\n期望: num 100.1（而非编码字符串）',
    ));

    // Regression: doubles written by this version stay readable.
    await asyncApi.setDouble(kPlainDouble, 300.5, _demoOptions);
    final double? plainValue = await asyncApi.getDouble(kPlainDouble, _demoOptions);
    checks.add(_CheckResult(
      'setDouble 写入读回回归',
      plainValue == 300.5,
      '写入: setDouble 300.5\n读取: $plainValue\n期望: 300.5',
    ));

    // Documented contract: prefixed strings are not returned by
    // async getString; it throws instead.
    bool getStringThrew = false;
    Object? getStringError;
    try {
      await asyncApi.getString(kLegacyDouble, _demoOptions);
    } catch (e) {
      getStringThrew = true;
      getStringError = e;
    }
    checks.add(_CheckResult(
      'LEGACY 前缀编码 key → async getString 按约定抛出异常',
      getStringThrew,
      getStringThrew
          ? '实际: 抛出 ${getStringError.runtimeType}\n期望: 抛出（编码串不作为 String 暴露）'
          : '实际: 未抛出，返回了字符串\n期望: 抛出',
    ));

    // --- concurrent-write fix check (async path) ---

    final List<Future<void>> asyncWrites = <Future<void>>[];
    for (int i = 1; i <= _concurrentWriteCount; i++) {
      asyncWrites.add(asyncApi.setInt(
        'spec_concurrent_async_int',
        i,
        _demoOptions,
      ));
    }
    await Future.wait(asyncWrites);
    final int? asyncFinal =
        await asyncApi.getInt('spec_concurrent_async_int', _demoOptions);
    checks.add(_CheckResult(
      'async API: 100 并发 setInt 最终值 = 100',
      asyncFinal == _concurrentWriteCount,
      '最终值: $asyncFinal\n期望: 100（last write wins）',
    ));

    return _SectionResult('SharedPreferencesAsyncOhos 接口', checks);
  }

  // === legacy SharedPreferences interface + #1689 / concurrent fixes ===

  Future<_SectionResult> _runLegacyApiSection() async {
    const String legacyStringKey = 'legacy_string';
    const String legacyIntKey = 'legacy_int';
    const String legacyDoubleKey = 'legacy_double';
    const String legacyBoolKey = 'legacy_bool';
    const String legacyListKey = 'legacy_list';
    const String realScenarioKey = 'spec_v_legacy_real';
    final List<_CheckResult> checks = <_CheckResult>[];

    final SharedPreferences legacyPrefs = await SharedPreferences.getInstance();
    final bool setString = await legacyPrefs.setString(legacyStringKey, 'legacy');
    final bool setInt = await legacyPrefs.setInt(legacyIntKey, 7);
    final bool setDouble = await legacyPrefs.setDouble(legacyDoubleKey, 7.7);
    final bool setBool = await legacyPrefs.setBool(legacyBoolKey, true);
    final bool setStringList = await legacyPrefs.setStringList(
      legacyListKey,
      <String>['l1', 'l2'],
    );
    checks.add(_CheckResult(
      'set 系列 5 种类型写入',
      setString && setInt && setDouble && setBool && setStringList,
      'String: $setString, Int: $setInt, Double: $setDouble, '
          'Bool: $setBool, StringList: $setStringList\n期望: 全部 true',
    ));

    checks.add(_CheckResult(
      'getString 读回',
      legacyPrefs.getString(legacyStringKey) == 'legacy',
      '实际: ${legacyPrefs.getString(legacyStringKey)}\n期望: legacy',
    ));
    checks.add(_CheckResult(
      'getInt 读回',
      legacyPrefs.getInt(legacyIntKey) == 7,
      '实际: ${legacyPrefs.getInt(legacyIntKey)}\n期望: 7',
    ));
    checks.add(_CheckResult(
      'getDouble 读回',
      legacyPrefs.getDouble(legacyDoubleKey) == 7.7,
      '实际: ${legacyPrefs.getDouble(legacyDoubleKey)}\n期望: 7.7',
    ));
    checks.add(_CheckResult(
      'getBool 读回',
      legacyPrefs.getBool(legacyBoolKey) ?? false,
      '实际: ${legacyPrefs.getBool(legacyBoolKey)}\n期望: true',
    ));
    final List<String>? legacyList = legacyPrefs.getStringList(legacyListKey);
    checks.add(_CheckResult(
      'getStringList 读回',
      legacyList != null && legacyList.join(',') == 'l1,l2',
      '实际: $legacyList\n期望: [l1, l2]',
    ));

    checks.add(_CheckResult(
      'containsKey 判断 key 存在',
      legacyPrefs.containsKey(legacyStringKey),
      '实际: ${legacyPrefs.containsKey(legacyStringKey)}\n期望: true',
    ));
    final Set<String> legacyKeys = legacyPrefs.getKeys();
    checks.add(_CheckResult(
      'getKeys 包含写入 key',
      legacyKeys.contains(legacyStringKey),
      '命中 ${legacyKeys.length} 个 key，'
          ' 包含 $legacyStringKey: ${legacyKeys.contains(legacyStringKey)}\n期望: true',
    ));

    await legacyPrefs.reload();
    checks.add(_CheckResult(
      'reload 后数据保持',
      legacyPrefs.getString(legacyStringKey) == 'legacy',
      'reload 后 getString: ${legacyPrefs.getString(legacyStringKey)}\n期望: legacy',
    ));

    final bool removeResult = await legacyPrefs.remove(legacyStringKey);
    checks.add(_CheckResult(
      'remove 删除指定 key',
      removeResult && !legacyPrefs.containsKey(legacyStringKey),
      '返回: $removeResult, 删除后 containsKey: '
          '${legacyPrefs.containsKey(legacyStringKey)}\n期望: true 且 false',
    ));

    final bool clearResult = await legacyPrefs.clear();
    checks.add(_CheckResult(
      'clear 清空作用域',
      clearResult && legacyPrefs.getKeys().isEmpty,
      '返回: $clearResult, 清空后 key 数: ${legacyPrefs.getKeys().length}\n'
          '期望: true 且 0',
    ));

    // --- #1689 real upgrade scenario (legacy getDouble path) ---

    // Seed into the production file the legacy API reads, then read it
    // back with the legacy Dart API.
    final SharedPreferencesAsyncOhos asyncApi = SharedPreferencesAsyncOhos();
    await asyncApi.setString(
      'flutter.$realScenarioKey',
      '${_legacyDoublePrefix}400.25',
      _legacyFileOptions,
    );
    await legacyPrefs.reload();
    final double? realValue = legacyPrefs.getDouble(realScenarioKey);
    checks.add(_CheckResult(
      '真实升级场景: FlutterSharedPreferences 旧数据 → legacy getDouble',
      realValue == 400.25,
      '写入: LEGACY_PREFIX + "400.25"（flutter.$realScenarioKey）\n'
          '读取: $realValue\n期望: 400.25',
    ));
    await legacyPrefs.remove(realScenarioKey);

    // --- concurrent-write fix check (legacy path) ---

    final List<Future<bool>> legacyWrites = <Future<bool>>[];
    for (int i = 1; i <= _concurrentWriteCount; i++) {
      legacyWrites.add(legacyPrefs.setInt('spec_concurrent_int', i));
    }
    final List<bool> legacyResults = await Future.wait(legacyWrites);
    final bool legacyAllOk = legacyResults.every((bool ok) => ok);
    final int? legacyFinal = legacyPrefs.getInt('spec_concurrent_int');
    checks.add(_CheckResult(
      'legacy API: 100 并发 setInt 最终值 = 100',
      legacyAllOk && legacyFinal == _concurrentWriteCount,
      '全部成功: $legacyAllOk\n最终值: $legacyFinal\n期望: 100（last write wins）',
    ));
    await legacyPrefs.remove('spec_concurrent_int');

    return _SectionResult('legacy SharedPreferences 接口', checks);
  }

  // === UI ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spec Tests'),
        actions: <Widget>[
          if (_running)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-run',
              onPressed: _runChecks,
            ),
        ],
      ),
      body: _running && _sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildSectionList(_sections),
    );
  }

  Widget _buildSectionList(List<_SectionResult> sections) {
    final int total = sections.fold<int>(
      0,
      (int sum, _SectionResult s) => sum + s.checks.length,
    );
    final int passed = sections.fold<int>(
      0,
      (int sum, _SectionResult s) => sum + s.checks.where((_CheckResult c) => c.pass).length,
    );
    final bool allPass = total > 0 && passed == total;

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: <Widget>[
        Card(
          color: allPass ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      allPass ? Icons.check_circle : Icons.cancel,
                      color: allPass ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '通过 $passed / $total',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  allPass ? '全部检查通过' : '存在未通过的检查，请查看下方详情',
                  style: TextStyle(
                    color:
                        allPass ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final _SectionResult section in sections) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(
              section.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...section.checks.map(
            (_CheckResult c) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  c.pass ? Icons.check_circle : Icons.cancel,
                  color: c.pass ? Colors.green : Colors.red,
                ),
                title: Text(c.title),
                subtitle: Text(
                  c.detail,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
