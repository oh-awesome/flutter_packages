import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';

class SpecTestPage extends StatefulWidget {
  const SpecTestPage({
    super.key,
    required this.options,
  });

  final SharedPreferencesAsyncOhosOptions options;

  @override
  State<SpecTestPage> createState() => _SpecTestPageState();
}

class _SpecTestPageState extends State<SpecTestPage> {
  static const String _lineEndMarker = '  <END>';

  Map<String, Object> _testResults = <String, Object>{};

  void _writeSection(StringBuffer buffer, String title, String description) {
    buffer.writeln('=== $title ===');
    buffer.writeln('说明: $description');
  }

  void _writeGroup(StringBuffer buffer, String title, String description) {
    buffer.writeln('[$title]');
    buffer.writeln('用途: $description');
  }

  void _writeLine(StringBuffer buffer, String content) {
    buffer.writeln('$content$_lineEndMarker');
  }

  void _writeDivider(StringBuffer buffer) {
    buffer.writeln('*' * 50);
  }

  Future<void> _testGetAll() async {
    try {
      StringBuffer displayText = StringBuffer();

      _writeSection(
        displayText,
        '一、SharedPreferencesOhos 接口与属性验证',
        '本节聚焦 README 中 `SharedPreferencesOhos` 列出的全部接口，并补充说明其默认作用域、支持的 valueType，以及前缀过滤/参数过滤的行为。',
      );
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
      final bool storeSetString = await ohosStore.setValue(
        'String',
        storeStringKey,
        'via SharedPreferencesOhos',
      );
      final bool storeSetInt = await ohosStore.setValue('Int', storeIntKey, 7);
      final bool storeSetDouble = await ohosStore.setValue(
        'Double',
        storeDoubleKey,
        7.7,
      );
      final bool storeSetBool = await ohosStore.setValue(
        'Bool',
        storeBoolKey,
        true,
      );
      final bool storeSetList = await ohosStore.setValue(
        'StringList',
        storeListKey,
        <String>['one', 'two', 'three'],
      );
      await ohosStore.setValue('String', removableStoreKey, 'to be removed');
      await ohosStore.setValue('String', parameterKeepKey, 'keep by allowList');
      await ohosStore.setValue(
        'String',
        parameterDeleteKey,
        'delete by allowList',
      );
      await ohosStore.setValue('String', clearPrefixKey1, 'prefix value 1');
      await ohosStore.setValue('String', clearPrefixKey2, 'prefix value 2');
      await ohosStore.setValue('String', clearDefaultKey, 'clear default scope');
      final Map<String, Object> storeAllData = await ohosStore.getAll();
      final Map<String, Object> storePrefixData =
          await ohosStore.getAllWithPrefix('flutter.ohos_store_demo_');
      final Map<String, Object> parameterFilteredData =
          await ohosStore.getAllWithParameters(
        GetAllParameters(
          filter: PreferencesFilter(
            prefix: 'flutter.ohos_parameter_scope_',
            allowList: <String>{parameterKeepKey},
          ),
        ),
      );
      final bool removeResult = await ohosStore.remove(removableStoreKey);
      final Map<String, Object> storeAfterRemove =
          await ohosStore.getAllWithPrefix('flutter.ohos_store_demo_');
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
      final bool clearWithPrefixResult = await ohosStore.clearWithPrefix(
        'flutter.ohos_clear_prefix_demo_',
      );
      final Map<String, Object> clearPrefixAfterClear =
          await ohosStore.getAllWithPrefix('flutter.ohos_clear_prefix_demo_');
      final Map<String, Object> clearDefaultBeforeClear =
          await ohosStore.getAllWithPrefix('flutter.ohos_clear_default_');
      final bool clearResult = await ohosStore.clear();
      final Map<String, Object> clearDefaultAfterClear =
          await ohosStore.getAllWithPrefix('flutter.ohos_clear_default_');
      _writeGroup(
        displayText,
        '1. 类与作用域说明',
        'README 中 `SharedPreferencesOhos` 没有独立属性，但有默认 legacy 作用域和 valueType 约束；这里先说明类本身、默认前缀和支持的存储类型。',
      );
      _writeLine(displayText, 'class type: ${ohosStore.runtimeType}');
      _writeLine(displayText, 'default legacy scope prefix: flutter.');
      _writeLine(
        displayText,
        'README valueType support: String / Int / Double / Bool / StringList',
      );
      _writeDivider(displayText);
      _writeGroup(
        displayText,
        '2. setValue 与读取类接口',
        '验证 README 中 `setValue` 支持的 5 种 valueType，同时通过 `getAll` / `getAllWithPrefix` / `getAllWithParameters` 观察写入结果。',
      );
      _writeLine(displayText, 'setValue(String, $storeStringKey): $storeSetString');
      _writeLine(displayText, 'setValue(Int, $storeIntKey): $storeSetInt');
      _writeLine(displayText, 'setValue(Double, $storeDoubleKey): $storeSetDouble');
      _writeLine(displayText, 'setValue(Bool, $storeBoolKey): $storeSetBool');
      _writeLine(displayText, 'setValue(StringList, $storeListKey): $storeSetList');
      _writeLine(displayText, 'getAll flutter. scope: $storeAllData');
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_store_demo_: $storePrefixData',
      );
      _writeLine(
        displayText,
        'getAllWithParameters prefix=flutter.ohos_parameter_scope_, allowList=[$parameterKeepKey]: $parameterFilteredData',
      );
      _writeDivider(displayText);
      _writeGroup(
        displayText,
        '3. 删除与清理接口',
        '验证 README 中 `remove`、`clearWithParameters`、`clearWithPrefix`、`clear` 的行为差异：按 key 删除、按 allowList 删除、按 prefix 删除，以及清空默认 flutter. 作用域。',
      );
      _writeLine(
        displayText,
        'remove key: $removableStoreKey, result: $removeResult',
      );
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_store_demo_ after remove: $storeAfterRemove',
      );
      _writeLine(
        displayText,
        'clearWithParameters prefix=flutter.ohos_parameter_scope_, allowList=[$parameterDeleteKey]: $clearWithParametersResult',
      );
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_parameter_scope_ after clearWithParameters: $parameterDataAfterClear',
      );
      _writeLine(
        displayText,
        'clearWithPrefix flutter.ohos_clear_prefix_demo_: $clearWithPrefixResult',
      );
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_clear_prefix_demo_ after clearWithPrefix: $clearPrefixAfterClear',
      );
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_clear_default_ before clear: $clearDefaultBeforeClear',
      );
      _writeLine(
        displayText,
        'clear default flutter. scope result: $clearResult',
      );
      _writeLine(
        displayText,
        'getAllWithPrefix flutter.ohos_clear_default_ after clear: $clearDefaultAfterClear',
      );
      displayText.writeln(
        '结果说明: `setValue` 的 `valueType` 只是类型选择器，不会作为结果值返回；`getAll*` 系列返回的是键值映射。'
        '`remove` 只删除单个 key；`clearWithParameters` 只删除命中 allowList 的 key；`clearWithPrefix` 只影响指定前缀；`clear()` 会清理默认 `flutter.` legacy 作用域。',
      );
      _writeDivider(displayText);

      _writeSection(
        displayText,
        '二、SharedPreferencesAsyncOhos 接口与属性验证',
        '本节聚焦 README 中 `SharedPreferencesAsyncOhos`、`SharedPreferencesAsyncOhosOptions`、`OhosSharedPreferencesStoreOptions` 列出的属性和方法，分别说明 backend/fileName 配置及 async 读写行为。',
      );
      final SharedPreferencesAsyncOhos ohosAsync = SharedPreferencesAsyncOhos();
      const SharedPreferencesAsyncOhosOptions dataStoreAsyncOptions =
          SharedPreferencesAsyncOhosOptions();
      const OhosSharedPreferencesStoreOptions sharedBackendStoreOptions =
          OhosSharedPreferencesStoreOptions(
        fileName: 'example_shared_preferences',
      );
      const SharedPreferencesAsyncOhosOptions sharedBackendAsyncOptions =
          SharedPreferencesAsyncOhosOptions(
        backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: sharedBackendStoreOptions,
      );
      const SharedPreferencesOptions asyncExecutionOptions =
          sharedBackendAsyncOptions;
      const String asyncStringKey = 'ohos_async_demo_string';
      const String asyncIntKey = 'ohos_async_demo_int';
      const String asyncDoubleKey = 'ohos_async_demo_double';
      const String asyncBoolKey = 'ohos_async_demo_bool';
      const String asyncListKey = 'ohos_async_demo_list';
      const Set<String> asyncAllowList = <String>{asyncStringKey, asyncBoolKey};
      const Set<String> asyncClearAllowList = <String>{asyncBoolKey, asyncListKey};
      await ohosAsync.setString(
        asyncStringKey,
        'via SharedPreferencesAsyncOhos',
        asyncExecutionOptions,
      );
      await ohosAsync.setInt(asyncIntKey, 9223372036854775807, asyncExecutionOptions);
      await ohosAsync.setDouble(asyncDoubleKey, 100.1, asyncExecutionOptions);
      await ohosAsync.setBool(asyncBoolKey, true, asyncExecutionOptions);
      await ohosAsync.setStringList(
        asyncListKey,
        <String>['red', 'green', 'blue'],
        asyncExecutionOptions,
      );
      final String? asyncStringValue =
          await ohosAsync.getString(asyncStringKey, asyncExecutionOptions);
      final int? asyncIntValue =
          await ohosAsync.getInt(asyncIntKey, asyncExecutionOptions);
      final double? asyncDoubleValue =
          await ohosAsync.getDouble(asyncDoubleKey, asyncExecutionOptions);
      final bool? asyncBoolValue =
          await ohosAsync.getBool(asyncBoolKey, asyncExecutionOptions);
      final List<String>? asyncListValue =
          await ohosAsync.getStringList(asyncListKey, asyncExecutionOptions);
      final Map<String, Object> asyncAllData = await ohosAsync.getPreferences(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        asyncExecutionOptions,
      );
      final Map<String, Object> asyncFilteredData = await ohosAsync.getPreferences(
        const GetPreferencesParameters(
          filter: PreferencesFilters(allowList: asyncAllowList),
        ),
        asyncExecutionOptions,
      );
      final Set<String> asyncKeysBeforeClear = await ohosAsync.getKeys(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        asyncExecutionOptions,
      );
      final Set<String> asyncFilteredKeys = await ohosAsync.getKeys(
        const GetPreferencesParameters(
          filter: PreferencesFilters(allowList: asyncAllowList),
        ),
        asyncExecutionOptions,
      );
      await ohosAsync.clear(
        const ClearPreferencesParameters(
          filter: PreferencesFilters(allowList: asyncClearAllowList),
        ),
        asyncExecutionOptions,
      );
      final Set<String> asyncKeysAfterClear = await ohosAsync.getKeys(
        const GetPreferencesParameters(filter: PreferencesFilters()),
        asyncExecutionOptions,
      );
      final bool? asyncBoolAfterClear =
          await ohosAsync.getBool(asyncBoolKey, asyncExecutionOptions);
      final List<String>? asyncListAfterClear =
          await ohosAsync.getStringList(asyncListKey, asyncExecutionOptions);
      _writeGroup(
        displayText,
        '1. 类与属性说明',
        '这一组覆盖 README 中 `SharedPreferencesAsyncOhosOptions.backend`、`originalSharedPreferencesOptions`、`OhosSharedPreferencesStoreOptions.fileName` 等属性。',
      );
      _writeLine(displayText, 'class type: ${ohosAsync.runtimeType}');
      _writeLine(displayText, 'default options backend: ${dataStoreAsyncOptions.backend}');
      _writeLine(
        displayText,
        'default options originalSharedPreferencesOptions: ${dataStoreAsyncOptions.originalSharedPreferencesOptions}',
      );
      _writeLine(
        displayText,
        'shared_preferences options backend: ${sharedBackendAsyncOptions.backend}',
      );
      _writeLine(
        displayText,
        'shared_preferences options fileName: ${sharedBackendAsyncOptions.originalSharedPreferencesOptions?.fileName}',
      );
      _writeLine(displayText, 'actual execution backend: ${sharedBackendAsyncOptions.backend}');
      _writeDivider(displayText);
      _writeGroup(
        displayText,
        '2. 基础读写接口',
        '这一组覆盖 README 中的 `setString/setInt/setDouble/setBool/setStringList` 与对应的 `getString/getInt/getDouble/getBool/getStringList`。',
      );
      _writeLine(displayText, 'setString $asyncStringKey: done');
      _writeLine(displayText, 'setInt $asyncIntKey: done');
      _writeLine(displayText, 'setDouble $asyncDoubleKey: done');
      _writeLine(displayText, 'setBool $asyncBoolKey: done');
      _writeLine(displayText, 'setStringList $asyncListKey: done');
      _writeLine(displayText, 'getString $asyncStringKey: $asyncStringValue');
      _writeLine(displayText, 'getInt $asyncIntKey: $asyncIntValue');
      _writeLine(displayText, 'getDouble $asyncDoubleKey: $asyncDoubleValue');
      _writeLine(displayText, 'getBool $asyncBoolKey: $asyncBoolValue');
      _writeLine(displayText, 'getStringList $asyncListKey: $asyncListValue');
      _writeDivider(displayText);
      _writeGroup(
        displayText,
        '3. 批量读取与清理接口',
        '这一组覆盖 README 中的 `getPreferences`、`getKeys`、`clear`，并演示 allowList 过滤在 Async 场景下的效果。',
      );
      _writeLine(displayText, 'getPreferences all: $asyncAllData');
      _writeLine(
        displayText,
        'getPreferences allowList=$asyncAllowList: $asyncFilteredData',
      );
      _writeLine(displayText, 'getKeys before clear: $asyncKeysBeforeClear');
      _writeLine(displayText, 'getKeys allowList=$asyncAllowList: $asyncFilteredKeys');
      _writeLine(displayText, 'clear allowList=$asyncClearAllowList: done');
      _writeLine(displayText, 'getKeys after clear: $asyncKeysAfterClear');
      _writeLine(displayText, 'getBool $asyncBoolKey after clear: $asyncBoolAfterClear');
      _writeLine(
        displayText,
        'getStringList $asyncListKey after clear: $asyncListAfterClear',
      );
      displayText.writeln(
        '结果说明: 这里实际演示的是 `SharedPreferencesAsyncOhos` 直连调用；默认 options 的 backend 是 `DataStore`，但本段为了同时覆盖 README 中的 `backend` 和 `fileName` 属性，实际执行使用了 `SharedPreferences` backend + `fileName=example_shared_preferences`。'
        'Async 侧当前主要支持 `allowList` 过滤；被加入 clear allowList 的 key 会被删除，删除后的读取结果为 null 属于正常现象。',
      );
      _writeDivider(displayText);

      _writeSection(
        displayText,
        '三、SharedPreferences 接口与功能验证',
        '本节聚焦 README 中 legacy `SharedPreferences` 列出的全部公开接口，按“实例获取 -> 写入 -> 读取 -> 判断/重载 -> 删除/清理”的顺序展示。',
      );
      _writeGroup(
        displayText,
        '1. 实例、写入与读取接口',
        '覆盖 README 中的 `getInstance`、`setString/setInt/setDouble/setBool/setStringList`、`getString/getInt/getDouble/getBool/getStringList`。',
      );
      final SharedPreferences legacyPrefs = await SharedPreferences.getInstance();
      const String legacyStringKey = 'legacy_string';
      const String legacyIntKey = 'legacy_int';
      const String legacyDoubleKey = 'legacy_double';
      const String legacyBoolKey = 'legacy_bool';
      const String legacyListKey = 'legacy_list';
      _writeLine(displayText, 'legacy getInstance: ${legacyPrefs.runtimeType}');
      final bool legacySetString = await legacyPrefs.setString(legacyStringKey, 'legacy');
      final bool legacySetInt = await legacyPrefs.setInt(legacyIntKey, 7);
      final bool legacySetDouble = await legacyPrefs.setDouble(legacyDoubleKey, 7.7);
      final bool legacySetBool = await legacyPrefs.setBool(legacyBoolKey, true);
      final bool legacySetStringList =
          await legacyPrefs.setStringList(legacyListKey, <String>['l1', 'l2']);
      _writeLine(displayText, 'legacy setString: $legacySetString');
      _writeLine(displayText, 'legacy setInt: $legacySetInt');
      _writeLine(displayText, 'legacy setDouble: $legacySetDouble');
      _writeLine(displayText, 'legacy setBool: $legacySetBool');
      _writeLine(displayText, 'legacy setStringList: $legacySetStringList');
      _writeLine(displayText, 'legacy getString: ${legacyPrefs.getString(legacyStringKey)}');
      _writeLine(displayText, 'legacy getInt: ${legacyPrefs.getInt(legacyIntKey)}');
      _writeLine(displayText, 'legacy getDouble: ${legacyPrefs.getDouble(legacyDoubleKey)}');
      _writeLine(displayText, 'legacy getBool: ${legacyPrefs.getBool(legacyBoolKey)}');
      _writeLine(
        displayText,
        'legacy getStringList: ${legacyPrefs.getStringList(legacyListKey)}',
      );
      _writeDivider(displayText);
      _writeGroup(
        displayText,
        '2. 判断、重载、删除与清理接口',
        '覆盖 README 中的 `containsKey`、`getKeys`、`reload`、`remove`、`clear`。',
      );
      _writeLine(
        displayText,
        'legacy containsKey: ${legacyPrefs.containsKey(legacyStringKey)}',
      );
      _writeLine(displayText, 'legacy getKeys: ${legacyPrefs.getKeys()}');
      await legacyPrefs.reload();
      final bool legacyRemoveResult = await legacyPrefs.remove(legacyStringKey);
      final bool legacyClearResult = await legacyPrefs.clear();
      _writeLine(displayText, 'legacy reload: done');
      _writeLine(displayText, 'legacy remove($legacyStringKey): $legacyRemoveResult');
      _writeLine(displayText, 'legacy clear(): $legacyClearResult');
      _writeLine(displayText, 'legacy getKeys after clear: ${legacyPrefs.getKeys()}');
      displayText.writeln(
        '结果说明: 这一组覆盖 README 中 legacy `SharedPreferences` 的全部公开接口。'
        '`getKeys`/`containsKey` 反映当前实例作用域内的数据；`reload()` 负责从磁盘重新同步；`remove()` 删除单个 key；`clear()` 清空当前 legacy 作用域。',
      );
      _writeDivider(displayText);
      displayText.writeln('===== 页面输出结束 =====');

      setState(() {
        _testResults = {'result': displayText.toString()};
      });
    } catch (e, stackTrace) {
      setState(() {
        _testResults = <String, Object>{
          'error': '$e\n$stackTrace',
        };
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _testGetAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spec Tests')),
      body: _testResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Card(
              margin: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    (_testResults['result'] ?? _testResults['error']).toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
    );
  }
}

