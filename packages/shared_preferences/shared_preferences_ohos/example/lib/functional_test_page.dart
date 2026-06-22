// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// 独立的功能测试页面，覆盖 ohos 实现的所有 Legacy 和 Async API
class FunctionalTestPage extends StatefulWidget {
  const FunctionalTestPage({super.key});

  @override
  State<FunctionalTestPage> createState() => _FunctionalTestPageState();
}

class _FunctionalTestPageState extends State<FunctionalTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OHOS 功能测试'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Legacy API'),
            Tab(text: 'Async API'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LegacyTestTab(),
          _AsyncTestTab(),
        ],
      ),
    );
  }
}

// ============================================================
// Legacy API 测试页
// ============================================================

class _LegacyTestTab extends StatefulWidget {
  const _LegacyTestTab();

  @override
  State<_LegacyTestTab> createState() => _LegacyTestTabState();
}

class _LegacyTestTabState extends State<_LegacyTestTab> {
  final SharedPreferencesStorePlatform _prefs = SharedPreferencesStorePlatform.instance;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _log('SharedPreferencesStorePlatform 实例: ${_prefs.runtimeType}');
  }

  void _log(String msg) {
    setState(() {
      _logs.add(msg);
    });
    debugPrint(msg);
  }

  Future<void> _clearLogs() async {
    setState(() { _logs.clear(); });
  }

  // ---------- Legacy API 测试方法 ----------

  Future<void> _testSetBool() async {
    _log('--- 测试 setBool ---');
    final result = await _prefs.setValue('Bool', 'test.legacy.bool', true);
    _log('setValue Bool key=test.legacy.bool value=true => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    _log('读取回值: ${all['test.legacy.bool']} (预期: true)');
    _log(all['test.legacy.bool'] == true ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetInt() async {
    _log('--- 测试 setInt ---');
    final result = await _prefs.setValue('Int', 'test.legacy.int', 42);
    _log('setValue Int key=test.legacy.int value=42 => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    _log('读取回值: ${all['test.legacy.int']} (预期: 42)');
    _log(all['test.legacy.int'] == 42 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetDouble() async {
    _log('--- 测试 setDouble ---');
    const double testVal = 3.14159;
    final result = await _prefs.setValue('Double', 'test.legacy.double', testVal);
    _log('setValue Double key=test.legacy.double value=$testVal => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    final readVal = all['test.legacy.double'];
    _log('读取回值: $readVal (预期: $testVal)');
    _log(readVal is double && (readVal - testVal).abs() < 0.0001 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetString() async {
    _log('--- 测试 setString ---');
    const String testVal = 'Hello OHOS';
    final result = await _prefs.setValue('String', 'test.legacy.string', testVal);
    _log('setValue String key=test.legacy.string value="$testVal" => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    _log('读取回值: ${all['test.legacy.string']} (预期: $testVal)');
    _log(all['test.legacy.string'] == testVal ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetStringList() async {
    _log('--- 测试 setStringList ---');
    const List<String> testVal = <String>['foo', 'bar', 'baz'];
    final result = await _prefs.setValue('StringList', 'test.legacy.stringlist', testVal);
    _log('setValue StringList key=test.legacy.stringlist value=$testVal => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    final readVal = all['test.legacy.stringlist'];
    _log('读取回值: $readVal (预期: $testVal)');
    _log(readVal is List && _listEquals(readVal as List, testVal) ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testRemove() async {
    _log('--- 测试 remove ---');
    await _prefs.setValue('String', 'test.legacy.remove_me', 'to_be_removed');
    _log('已存入 key=test.legacy.remove_me');
    final result = await _prefs.remove('test.legacy.remove_me');
    _log('remove key=test.legacy.remove_me => $result');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.legacy.')),
    );
    _log('移除后读取: ${all['test.legacy.remove_me']} (预期: null)');
    _log(all['test.legacy.remove_me'] == null ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testGetAllWithPrefix() async {
    _log('--- 测试 getAllWithPrefix ---');
    // 先清空
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    // 写入不同前缀的数据
    await _prefs.setValue('String', 'prefix_a.key1', 'value_a1');
    await _prefs.setValue('String', 'prefix_a.key2', 'value_a2');
    await _prefs.setValue('String', 'prefix_b.key1', 'value_b1');
    // 使用 deprecated API 以覆盖测试
    // ignore: deprecated_member_use
    final result = await _prefs.getAllWithPrefix('prefix_a.');
    _log('getAllWithPrefix("prefix_a.") => $result');
    _log(result.length == 2 ? '✅ PASS' : '❌ FAIL (预期2条, 实际${result.length}条)');
  }

  Future<void> _testGetAllWithParameters() async {
    _log('--- 测试 getAllWithParameters ---');
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    await _prefs.setValue('String', 'test.p1', 'v1');
    await _prefs.setValue('String', 'test.p2', 'v2');
    await _prefs.setValue('String', 'other.p3', 'v3');
    // 无 allowList
    var result = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.')),
    );
    _log('getAllWithParameters(prefix="test.") => $result');
    _log(result.length == 2 ? '✅ PASS (2条)' : '❌ FAIL (${result.length}条)');
    // 有 allowList
    result = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.', allowList: <String>{'test.p1'})),
    );
    _log('getAllWithParameters(prefix="test.", allowList={"test.p1"}) => $result');
    _log(result.length == 1 ? '✅ PASS (1条)' : '❌ FAIL (${result.length}条)');
  }

  Future<void> _testClearWithParameters() async {
    _log('--- 测试 clearWithParameters ---');
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    await _prefs.setValue('String', 'clear_a.key1', 'v1');
    await _prefs.setValue('String', 'clear_b.key2', 'v2');
    // 清除 clear_a 前缀
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: 'clear_a.')),
    );
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: '')),
    );
    _log('clear(prefix="clear_a.") 后所有数据: $all');
    _log(all['clear_a.key1'] == null && all['clear_b.key2'] == 'v2'
        ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testClearWithAllowList() async {
    _log('--- 测试 clearWithParameters + allowList ---');
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    await _prefs.setValue('String', 'test.k1', 'v1');
    await _prefs.setValue('String', 'test.k2', 'v2');
    await _prefs.setValue('String', 'test.k3', 'v3');
    // 仅清除 k1 和 k2
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(
        prefix: 'test.',
        allowList: <String>{'test.k1', 'test.k2'},
      )),
    );
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: 'test.')),
    );
    _log('clear(allowList={k1,k2}) 后: $all');
    _log(all['test.k1'] == null && all['test.k2'] == null && all['test.k3'] == 'v3'
        ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testStringPrefixClash() async {
    _log('--- 测试 setString 特殊前缀拒绝 ---');
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    const List<String> specialPrefixes = <String>[
      'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu',
      'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu',
    ];
    int passCount = 0;
    for (final String prefix in specialPrefixes) {
      try {
        await _prefs.setValue('String', 'clash_key', '${prefix}test_value');
        _log('setValue 以特殊前缀开头: 未被拒绝 ❌ FAIL');
      } on PlatformException catch (e) {
        _log('setValue 以特殊前缀开头: 正确抛出 PlatformException ✅ ($e)');
        passCount++;
      }
    }
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: '')),
    );
    _log('特殊前缀数据未被存入: ${all['clash_key'] == null ? "✅ PASS" : "❌ FAIL"}');
    _log(passCount == specialPrefixes.length ? '✅ ALL PASS' : '❌ SOME FAILED');
  }

  Future<void> _testSimultaneousWrites() async {
    _log('--- 测试并发写入 ---');
    await _prefs.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: '')),
    );
    const int writeCount = 100;
    final List<Future<bool>> writes = <Future<bool>>[];
    for (int i = 1; i <= writeCount; i++) {
      writes.add(_prefs.setValue('Int', 'test.legacy.concurrent', i));
    }
    final results = await Future.wait(writes, eagerError: true);
    final failCount = results.where((bool e) => !e).length;
    _log('并发写入 $writeCount 次, 失败 $failCount 次');
    final all = await _prefs.getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: '')),
    );
    _log('最终值: ${all['test.legacy.concurrent']} (预期: $writeCount)');
    _log(all['test.legacy.concurrent'] == writeCount ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testRunAllLegacy() async {
    _clearLogs();
    await _testSetBool();
    await _testSetInt();
    await _testSetDouble();
    await _testSetString();
    await _testSetStringList();
    await _testRemove();
    await _testGetAllWithPrefix();
    await _testGetAllWithParameters();
    await _testClearWithParameters();
    await _testClearWithAllowList();
    await _testStringPrefixClash();
    await _testSimultaneousWrites();
    _log('========== Legacy 全部测试完成 ==========');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 按钮区
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildAction('全部测试', _testRunAllLegacy, highlighted: true),
              _buildAction('setBool', _testSetBool),
              _buildAction('setInt', _testSetInt),
              _buildAction('setDouble', _testSetDouble),
              _buildAction('setString', _testSetString),
              _buildAction('setStringList', _testSetStringList),
              _buildAction('remove', _testRemove),
              _buildAction('getAllWithPrefix', _testGetAllWithPrefix),
              _buildAction('getAllWithParams', _testGetAllWithParameters),
              _buildAction('clearWithParams', _testClearWithParameters),
              _buildAction('clear+allowList', _testClearWithAllowList),
              _buildAction('前缀拒绝', _testStringPrefixClash),
              _buildAction('并发写入', _testSimultaneousWrites),
              _buildAction('清空日志', _clearLogs, highlighted: false),
            ],
          ),
        ),
        const Divider(height: 1),
        // 日志区
        Expanded(
          child: _buildLogView(),
        ),
      ],
    );
  }

  Widget _buildAction(String label, Future<void> Function() action, {bool highlighted = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlighted ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: highlighted ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: action,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildLogView() {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (BuildContext context, int index) {
        final String log = _logs[index];
        final TextStyle style;
        if (log.contains('✅ PASS')) {
          style = const TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'monospace');
        } else if (log.contains('❌ FAIL')) {
          style = const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace');
        } else if (log.startsWith('---')) {
          style = const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace');
        } else if (log.startsWith('=')) {
          style = const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace');
        } else {
          style = const TextStyle(fontSize: 12, fontFamily: 'monospace');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Text(log, style: style),
        );
      },
    );
  }
}

// ============================================================
// Async API 测试页
// ============================================================

class _AsyncTestTab extends StatefulWidget {
  const _AsyncTestTab();

  @override
  State<_AsyncTestTab> createState() => _AsyncTestTabState();
}

class _AsyncTestTabState extends State<_AsyncTestTab> {
  final SharedPreferencesAsyncPlatform _asyncPrefs = SharedPreferencesAsyncPlatform.instance!;
  final SharedPreferencesAsyncOhosOptions _options = SharedPreferencesAsyncOhosOptions();

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _log('SharedPreferencesAsyncPlatform 实例: ${_asyncPrefs.runtimeType}');
  }

  void _log(String msg) {
    setState(() {
      _logs.add(msg);
    });
    debugPrint(msg);
  }

  Future<void> _clearLogs() async {
    setState(() { _logs.clear(); });
  }

  Future<void> _ensureClean() async {
    await _asyncPrefs.clear(
      const ClearPreferencesParameters(filter: PreferencesFilters()),
      _options,
    );
  }

  Future<void> _testSetGetString() async {
    _log('--- 测试 setString / getString ---');
    await _ensureClean();
    await _asyncPrefs.setString('a_str', 'hello_ohos', _options);
    final result = await _asyncPrefs.getString('a_str', _options);
    _log('setString("a_str", "hello_ohos") => getString => $result');
    _log(result == 'hello_ohos' ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetGetBool() async {
    _log('--- 测试 setBool / getBool ---');
    await _ensureClean();
    await _asyncPrefs.setBool('a_bool', true, _options);
    final result = await _asyncPrefs.getBool('a_bool', _options);
    _log('setBool("a_bool", true) => getBool => $result');
    _log(result == true ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetGetInt() async {
    _log('--- 测试 setInt / getInt ---');
    await _ensureClean();
    await _asyncPrefs.setInt('a_int', 42, _options);
    final result = await _asyncPrefs.getInt('a_int', _options);
    _log('setInt("a_int", 42) => getInt => $result');
    _log(result == 42 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetGetDouble() async {
    _log('--- 测试 setDouble / getDouble ---');
    await _ensureClean();
    const double testVal = 3.14159;
    await _asyncPrefs.setDouble('a_double', testVal, _options);
    final result = await _asyncPrefs.getDouble('a_double', _options);
    _log('setDouble("a_double", $testVal) => getDouble => $result');
    _log(result != null && (result! - testVal).abs() < 0.0001 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testSetGetStringList() async {
    _log('--- 测试 setStringList / getStringList ---');
    await _ensureClean();
    const List<String> testVal = <String>['foo', 'bar', 'baz'];
    await _asyncPrefs.setStringList('a_list', testVal, _options);
    final result = await _asyncPrefs.getStringList('a_list', _options);
    _log('setStringList("a_list", $testVal) => getStringList => $result');
    _log(result != null && _listEquals(result!, testVal) ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testStringListMutable() async {
    _log('--- 测试 getStringList 返回可变列表 ---');
    await _ensureClean();
    const List<String> testVal = <String>['a', 'b'];
    await _asyncPrefs.setStringList('mutable_list', testVal, _options);
    final result = await _asyncPrefs.getStringList('mutable_list', _options);
    result?.add('c');
    _log('原长度 ${testVal.length}, 添加后长度 ${result?.length}');
    _log(result?.length == testVal.length + 1 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testGetPreferences() async {
    _log('--- 测试 getPreferences ---');
    await _ensureClean();
    await _asyncPrefs.setString('k_str', 'val', _options);
    await _asyncPrefs.setBool('k_bool', true, _options);
    await _asyncPrefs.setInt('k_int', 99, _options);
    await _asyncPrefs.setDouble('k_double', 1.23, _options);
    await _asyncPrefs.setStringList('k_list', <String>['x'], _options);
    final result = await _asyncPrefs.getPreferences(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      _options,
    );
    _log('getPreferences() => ${result.length} 条记录');
    _log(result.length == 5 ? '✅ PASS' : '❌ FAIL (${result.length}条, 预期5条)');
  }

  Future<void> _testGetPreferencesWithFilter() async {
    _log('--- 测试 getPreferences + allowList ---');
    await _ensureClean();
    await _asyncPrefs.setString('f_str', 'val', _options);
    await _asyncPrefs.setBool('f_bool', true, _options);
    await _asyncPrefs.setInt('f_int', 1, _options);
    final result = await _asyncPrefs.getPreferences(
      const GetPreferencesParameters(
        filter: PreferencesFilters(allowList: <String>{'f_str', 'f_bool'}),
      ),
      _options,
    );
    _log('getPreferences(allowList={f_str,f_bool}) => ${result.length} 条');
    _log(result.length == 2 && result.containsKey('f_str') && result.containsKey('f_bool')
        ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testGetKeys() async {
    _log('--- 测试 getKeys ---');
    await _ensureClean();
    await _asyncPrefs.setString('g_str', 'val', _options);
    await _asyncPrefs.setBool('g_bool', false, _options);
    final result = await _asyncPrefs.getKeys(
      const GetPreferencesParameters(filter: PreferencesFilters()),
      _options,
    );
    _log('getKeys() => $result');
    _log(result.length == 2 && result.contains('g_str') && result.contains('g_bool')
        ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testGetKeysWithFilter() async {
    _log('--- 测试 getKeys + allowList ---');
    await _ensureClean();
    await _asyncPrefs.setString('h1', 'val', _options);
    await _asyncPrefs.setString('h2', 'val', _options);
    await _asyncPrefs.setBool('h3', true, _options);
    final result = await _asyncPrefs.getKeys(
      const GetPreferencesParameters(filter: PreferencesFilters(allowList: <String>{'h1'})),
      _options,
    );
    _log('getKeys(allowList={h1}) => $result');
    _log(result.length == 1 && result.contains('h1') ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testClear() async {
    _log('--- 测试 clear ---');
    await _ensureClean();
    await _asyncPrefs.setString('c_str', 'val', _options);
    await _asyncPrefs.setBool('c_bool', true, _options);
    await _asyncPrefs.clear(
      const ClearPreferencesParameters(filter: PreferencesFilters()),
      _options,
    );
    final str = await _asyncPrefs.getString('c_str', _options);
    final bool_ = await _asyncPrefs.getBool('c_bool', _options);
    _log('clear() 后 getString=$str, getBool=$bool_');
    _log(str == null && bool_ == null ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testClearWithFilter() async {
    _log('--- 测试 clear + allowList ---');
    await _ensureClean();
    await _asyncPrefs.setString('d_str', 'val', _options);
    await _asyncPrefs.setBool('d_bool', true, _options);
    await _asyncPrefs.setInt('d_int', 7, _options);
    await _asyncPrefs.clear(
      const ClearPreferencesParameters(
        filter: PreferencesFilters(allowList: <String>{'d_str', 'd_bool'}),
      ),
      _options,
    );
    final str = await _asyncPrefs.getString('d_str', _options);
    final bool_ = await _asyncPrefs.getBool('d_bool', _options);
    final int_ = await _asyncPrefs.getInt('d_int', _options);
    _log('clear(allowList={d_str,d_bool}) 后: str=$str, bool=$bool_, int=$int_');
    _log(str == null && bool_ == null && int_ == 7 ? '✅ PASS' : '❌ FAIL');
  }

  Future<void> _testTypeMismatch() async {
    _log('--- 测试类型不匹配 ---');
    await _ensureClean();
    await _asyncPrefs.setBool('tm_key', true, _options);
    try {
      await _asyncPrefs.getString('tm_key', _options);
      _log('用 getString 读 bool 值: 未抛出异常 ❌ FAIL');
    } catch (e) {
      _log('用 getString 读 bool 值: 正确抛出异常 ✅ ($e)');
    }
  }

  Future<void> _testRunAllAsync() async {
    _clearLogs();
    await _testSetGetString();
    await _testSetGetBool();
    await _testSetGetInt();
    await _testSetGetDouble();
    await _testSetGetStringList();
    await _testStringListMutable();
    await _testGetPreferences();
    await _testGetPreferencesWithFilter();
    await _testGetKeys();
    await _testGetKeysWithFilter();
    await _testClear();
    await _testClearWithFilter();
    await _testTypeMismatch();
    _log('========== Async 全部测试完成 ==========');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildAction('全部测试', _testRunAllAsync, highlighted: true),
              _buildAction('set/getString', _testSetGetString),
              _buildAction('set/getBool', _testSetGetBool),
              _buildAction('set/getInt', _testSetGetInt),
              _buildAction('set/getDouble', _testSetGetDouble),
              _buildAction('set/getStringList', _testSetGetStringList),
              _buildAction('StringList可变', _testStringListMutable),
              _buildAction('getPreferences', _testGetPreferences),
              _buildAction('getPreferences+filter', _testGetPreferencesWithFilter),
              _buildAction('getKeys', _testGetKeys),
              _buildAction('getKeys+filter', _testGetKeysWithFilter),
              _buildAction('clear', _testClear),
              _buildAction('clear+filter', _testClearWithFilter),
              _buildAction('类型不匹配', _testTypeMismatch),
              _buildAction('清空日志', _clearLogs, highlighted: false),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildLogView(),
        ),
      ],
    );
  }

  Widget _buildAction(String label, Future<void> Function() action, {bool highlighted = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlighted ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: highlighted ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: action,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildLogView() {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (BuildContext context, int index) {
        final String log = _logs[index];
        final TextStyle style;
        if (log.contains('✅ PASS')) {
          style = const TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'monospace');
        } else if (log.contains('❌ FAIL')) {
          style = const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace');
        } else if (log.startsWith('---')) {
          style = const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace');
        } else if (log.startsWith('=')) {
          style = const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace');
        } else {
          style = const TextStyle(fontSize: 12, fontFamily: 'monospace');
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Text(log, style: style),
        );
      },
    );
  }
}

// ============================================================
// 工具方法
// ============================================================

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
