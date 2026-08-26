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
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';

/// 单条断言结果：label 描述 + 是否通过 + 期望/实际值（失败时用于展示差异）。
class _Check {
  const _Check({
    required this.label,
    required this.passed,
    this.actual,
    this.expected,
  });

  final String label;
  final bool passed;
  final String? actual;
  final String? expected;
}

/// 一组相关断言的测试区块。
class _TestSection {
  _TestSection({
    required this.title,
    required this.description,
    required this.checks,
  });

  final String title;
  final String description;
  final List<_Check> checks;

  bool get allPassed => checks.every((_Check c) => c.passed);
  int get passedCount => checks.where((_Check c) => c.passed).length;
}

/// 独立页面：在 demo 应用中验证本次提交（462e72a0dc）修改涉及的功能。
///
/// 以结构化断言（实际值 vs 期望值 + 绿/红判定）展示结果，便于一眼确认
/// 每个修改点是否通过：
/// 1. legacy sync setter/clear 成功回包统一为 [true]
/// 2. wrapError 非 FlutterError 回包格式（保留前缀写入被拒 → PlatformException）
/// 3. Async API 多文件读写隔离
/// 4. Async API int64 / double 极值往返
/// 5. StringList 编码往返（legacy 与 async 两条链路）
/// 6. EntryAbility 预置值读取（writePresetValues 释放后仍可读）
class ModificationTestPage extends StatefulWidget {
  const ModificationTestPage({super.key});

  @override
  State<ModificationTestPage> createState() => _ModificationTestPageState();
}

class _ModificationTestPageState extends State<ModificationTestPage> {
  List<_TestSection> _sections = <_TestSection>[];
  String? _error;
  bool _running = false;

  static const String _listPrefix =
      'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu';
  static const String _presetStringKey =
      'thisStringIsWrittenInTheExampleAppJavaCode';
  static const String _presetIntKey = 'thisIntIsWrittenInTheExampleAppJavaCode';

  SharedPreferencesAsyncOhosOptions _sharedBackendOptions(String fileName) {
    return SharedPreferencesAsyncOhosOptions(
      backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions:
          OhosSharedPreferencesStoreOptions(fileName: fileName),
    );
  }

  void _check(List<_Check> checks, String label, Object? actual, Object? expected) {
    checks.add(_Check(
      label: label,
      passed: actual == expected,
      actual: '$actual',
      expected: '$expected',
    ));
  }

  Future<void> _runModificationTests() async {
    setState(() {
      _running = true;
      _sections = <_TestSection>[];
      _error = null;
    });
    try {
      final List<_TestSection> sections = <_TestSection>[
        await _testLegacySyncReturns(),
        await _testWrapErrorPath(),
        await _testAsyncMultiFile(),
        await _testAsyncBoundaryValues(),
        await _testStringListRoundTrip(),
        await _testPresetValues(),
      ];
      setState(() {
        _sections = sections;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = '$e\n$stackTrace';
      });
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  /// 修改点 1：legacy sync setter/clear 成功回包统一为 [true]。
  Future<_TestSection> _testLegacySyncReturns() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferences legacy = await SharedPreferences.getInstance();
      const String stringKey = 'modification_legacy_string';
      const String intKey = 'modification_legacy_int';
      const String doubleKey = 'modification_legacy_double';
      const String boolKey = 'modification_legacy_bool';
      const String listKey = 'modification_legacy_list';

      final bool setString = await legacy.setString(stringKey, 'value');
      _check(checks, 'setString 回包 true', setString, true);
      final bool setInt = await legacy.setInt(intKey, 42);
      _check(checks, 'setInt 回包 true', setInt, true);
      final bool setDouble = await legacy.setDouble(doubleKey, 3.14159);
      _check(checks, 'setDouble 回包 true', setDouble, true);
      final bool setBool = await legacy.setBool(boolKey, true);
      _check(checks, 'setBool 回包 true', setBool, true);
      final bool setStringList =
          await legacy.setStringList(listKey, <String>['a', 'b']);
      _check(checks, 'setStringList 回包 true', setStringList, true);

      _check(checks, '读回 string', legacy.getString(stringKey), 'value');
      _check(checks, '读回 int', legacy.getInt(intKey), 42);
      _check(checks, '读回 double', legacy.getDouble(doubleKey), 3.14159);
      _check(checks, '读回 bool', legacy.getBool(boolKey), true);
      _check(
        checks,
        '读回 list',
        legacy.getStringList(listKey)?.toString(),
        <String>['a', 'b'].toString(),
      );

      final bool remove = await legacy.remove(stringKey);
      _check(checks, 'remove 回包 true', remove, true);
      final bool clear = await legacy.clear();
      _check(checks, 'clear 回包 true', clear, true);
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '一、legacy sync setter/clear 成功回包 [true]',
      description: 'sync setter/clear 成功回包统一改为 [true]',
      checks: checks,
    );
  }

  /// 修改点 2：wrapError 非 FlutterError 回包格式。
  Future<_TestSection> _testWrapErrorPath() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferencesOhos ohosStore = SharedPreferencesOhos();
      const String clashKey = 'modification_clash_key';
      String? platformException;
      try {
        await ohosStore.setValue('String', clashKey, '$_listPrefix some value');
      } on PlatformException catch (e) {
        platformException = 'code=${e.code}, message=${e.message}';
      }
      final Map<String, Object> residue =
          await ohosStore.getAllWithPrefix('modification_clash_');
      checks.add(_Check(
        label: '保留前缀写入被原生拒绝（PlatformException）',
        passed: platformException != null,
        actual: platformException ?? '未抛出 PlatformException',
      ));
      checks.add(_Check(
        label: '失败写入无残留',
        passed: residue.isEmpty,
        actual: residue.toString(),
        expected: '{}',
      ));
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '二、wrapError 错误回包（保留前缀写入被拒）',
      description: 'wrapError 对非 FlutterError 回传 name/toString/Cause 字段',
      checks: checks,
    );
  }

  /// 修改点 3：Async API 多文件读写隔离。
  Future<_TestSection> _testAsyncMultiFile() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferencesAsyncPlatform prefs =
          SharedPreferencesAsyncPlatform.instance!;
      const String sharedKey = 'modification_shared_key';
      await prefs.setInt(
          sharedKey, 1, _sharedBackendOptions('modification_file1'));
      await prefs.setInt(
          sharedKey, 2, _sharedBackendOptions('modification_file2'));
      final int? file1 = await prefs.getInt(
          sharedKey, _sharedBackendOptions('modification_file1'));
      final int? file2 = await prefs.getInt(
          sharedKey, _sharedBackendOptions('modification_file2'));
      _check(checks, 'file1 与 file2 同 key 数据隔离', '$file1/$file2', '1/2');

      int ok = 0;
      for (int i = 1; i <= 12; i++) {
        final String fileName = 'modification_multi_$i';
        final SharedPreferencesAsyncOhosOptions opts =
            _sharedBackendOptions(fileName);
        await prefs.setString('k', 'v$i', opts);
        final String? value = await prefs.getString('k', opts);
        if (value == 'v$i') {
          ok++;
        }
      }
      _check(checks, '12 个文件全部写入读回', ok, 12);
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '三、Async 多文件隔离',
      description: '不同 fileName 独立存储，实例按名缓存复用',
      checks: checks,
    );
  }

  /// 修改点 4：Async API int64 / double 极值往返。
  Future<_TestSection> _testAsyncBoundaryValues() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferencesAsyncPlatform prefs =
          SharedPreferencesAsyncPlatform.instance!;
      final SharedPreferencesAsyncOhosOptions opts =
          _sharedBackendOptions('modification_boundary');
      const int int64Max = 9223372036854775807;
      const int int64Min = -9223372036854775808;
      const double doubleMax = 1.7976931348623157e+308;
      const double doubleMin = 5e-324;
      await prefs.setInt('int64Max', int64Max, opts);
      await prefs.setInt('int64Min', int64Min, opts);
      await prefs.setDouble('doubleMax', doubleMax, opts);
      await prefs.setDouble('doubleMin', doubleMin, opts);
      _check(checks, 'int64 最大值往返', await prefs.getInt('int64Max', opts), int64Max);
      _check(checks, 'int64 最小值往返', await prefs.getInt('int64Min', opts), int64Min);
      _check(checks, 'double 最大值往返', await prefs.getDouble('doubleMax', opts), doubleMax);
      _check(checks, 'double 最小值往返', await prefs.getDouble('doubleMin', opts), doubleMin);
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '四、Async API int64 / double 极值往返',
      description: 'int64 最大/最小、double 最大/最小边界值往返一致',
      checks: checks,
    );
  }

  /// 修改点 5：StringList 编码往返（legacy 与 async 两条链路）。
  Future<_TestSection> _testStringListRoundTrip() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferences legacy = await SharedPreferences.getInstance();
      const String legacyListKey = 'modification_legacy_list_roundtrip';
      const List<String> legacyList = <String>['red', 'green', 'blue'];
      final bool setLegacyList =
          await legacy.setStringList(legacyListKey, legacyList);
      _check(checks, 'legacy setStringList 回包 true', setLegacyList, true);
      _check(
        checks,
        'legacy getStringList 往返',
        legacy.getStringList(legacyListKey)?.toString(),
        legacyList.toString(),
      );
      await legacy.remove(legacyListKey);

      final SharedPreferencesAsyncPlatform prefs =
          SharedPreferencesAsyncPlatform.instance!;
      final SharedPreferencesAsyncOhosOptions opts =
          _sharedBackendOptions('modification_list');
      const String asyncListKey = 'modification_async_list';
      const List<String> asyncList = <String>['x', 'y', 'z'];
      await prefs.setStringList(asyncListKey, asyncList, opts);
      final List<String>? got =
          await prefs.getStringList(asyncListKey, opts);
      _check(checks, 'async getStringList 往返', got?.toString(), asyncList.toString());
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '五、StringList 编码往返',
      description: 'legacy setStringList 走 setEncodedStringList channel，读取去前缀解码',
      checks: checks,
    );
  }

  /// 修改点 6：EntryAbility 预置值读取（writePresetValues 释放后仍可读）。
  Future<_TestSection> _testPresetValues() async {
    final List<_Check> checks = <_Check>[];
    try {
      final SharedPreferencesAsyncPlatform prefs =
          SharedPreferencesAsyncPlatform.instance!;
      const SharedPreferencesAsyncOhosOptions defaultOptions =
          SharedPreferencesAsyncOhosOptions(
        backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
      );
      _check(
        checks,
        '预置 String（release 后仍可读）',
        await prefs.getString(_presetStringKey, defaultOptions),
        'testString',
      );
      _check(
        checks,
        '预置 Int（release 后仍可读）',
        await prefs.getInt(_presetIntKey, defaultOptions),
        5,
      );
    } catch (e) {
      checks.add(_Check(label: '执行异常', passed: false, actual: '$e'));
    }
    return _TestSection(
      title: '六、EntryAbility 预置值读取',
      description: 'writePresetValues 写入后释放 Preferences 实例，仍可读',
      checks: checks,
    );
  }

  @override
  void initState() {
    super.initState();
    _runModificationTests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modification Tests'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新运行',
            onPressed: _running ? null : _runModificationTests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_running && _sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_sections.isEmpty) {
      return const Center(child: Text('暂无测试结果'));
    }

    final int total =
        _sections.fold<int>(0, (int sum, _TestSection s) => sum + s.checks.length);
    final int passed = _sections
        .fold<int>(0, (int sum, _TestSection s) => sum + s.passedCount);
    final bool allPassed = passed == total;

    return Column(
      children: <Widget>[
        _buildSummary(allPassed, passed, total),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16.0),
            itemCount: _sections.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildSection(_sections[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(bool allPassed, int passed, int total) {
    final Color color = allPassed ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      width: double.infinity,
      color: allPassed ? Colors.green.shade50 : Colors.red.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: <Widget>[
          Icon(
            allPassed ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
          const SizedBox(width: 8.0),
          Text(
            allPassed ? '全部测试通过' : '存在测试失败',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            '通过 $passed / $total',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_TestSection section) {
    final Color accent =
        section.allPassed ? Colors.green.shade700 : Colors.red.shade700;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            leading: Icon(
              section.allPassed ? Icons.check_circle : Icons.cancel,
              color: accent,
            ),
            title: Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(section.description),
            trailing: Text(
              '${section.passedCount}/${section.checks.length}',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...section.checks.map(_buildCheck),
        ],
      ),
    );
  }

  Widget _buildCheck(_Check check) {
    return ListTile(
      dense: true,
      leading: Icon(
        check.passed ? Icons.check : Icons.close,
        color: check.passed ? Colors.green : Colors.red,
        size: 18,
      ),
      title: Text(
        check.label,
        style: TextStyle(
          color: check.passed ? null : Colors.red.shade700,
        ),
      ),
      subtitle: check.passed
          ? (check.actual == null
              ? null
              : Text(
                  check.actual!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ))
          : Text(
              check.expected == null
                  ? '实际: ${check.actual ?? '（无输出）'}'
                  : '期望: ${check.expected}，实际: ${check.actual ?? '（无输出）'}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
    );
  }
}
