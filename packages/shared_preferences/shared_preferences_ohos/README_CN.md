<p align="center">
  <h1 align="center"> <code>shared_preferences</code> </h1>
</p>

本项目基于 [shared_preferences@2.5.5](https://pub.dev/packages/shared_preferences/versions/2.5.5) 的 OpenHarmony 平台实现开发。

## 简介

`shared_preferences_ohos` 为 `shared_preferences` 提供 OpenHarmony 平台存储实现，支持在设备本地持久化以下基础类型数据：

- `String`
- `int`
- `double`
- `bool`
- `List<String>`

> 注意：该插件用于轻量级键值持久化，不适合存储关键业务数据。

## 下载安装

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

```yaml
dependencies:
  shared_preferences:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences"
      ref: "shared_preferences-v2.5.5-ohos-1.0.0"
```

执行命令

```bash
flutter pub get
```

> TAG 命名规则：`原库版本-ohos-版本号-betax`，不同 TAG 之间的变更详见 `CHANGELOG.md`。

| Flutter 框架版本 | TAG 名称 | 分支名 |
| ----------------| ----------------------- | ---- |
| 3.35            | shared_preferences-v2.5.5-ohos-1.0.0 | oh-3.44.9-dev |
| 3.41            | shared_preferences-v2.5.5-ohos-1.0.0 | oh-3.44.9-dev |
| 3.44            | shared_preferences-v2.5.5-ohos-1.0.0 | oh-3.44.9-dev |

## 约束与限制

### 兼容性

在以下版本中已测试通过

1. Flutter: 3.35.8-ohos-0.0.3; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;
2. Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;
3. Flutter: 3.44.9+ohos-0.0.1-canary1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;

### 升级与迁移

- **插件升级**：将 `pubspec.yaml` 中的 `ref` 改为目标 TAG 或分支（见上方版本对应关系表），执行 `flutter pub get`（跨大版本切换时建议先 `flutter clean`）。ohos 各版本落盘存储格式保持不变，升级插件后已持久化的数据可直接继续使用。
- **API 迁移**：legacy `SharedPreferences` 接口已被上游标记弃用。如需把存量数据迁到新的 `SharedPreferencesAsync` 体系，在启动时调用一次 `migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary` 即可（示例见下文）。该函数可幂等执行：只要 `migrationCompletedKey` 未被修改或删除，重复执行不会覆盖新接口写入的数据。
- **`setPrefix` 迁移**：`SharedPreferences.setPrefix` 不会迁移已存储的数据，切换前缀前需自行完成数据拷贝。

### 权限要求

无。

### 平台差异与注意事项

- 数据类型：仅支持 `String/int/double/bool/List<String>`（与 upstream 行为一致）。
- Async 过滤能力：Async API 仅支持 `allowList` 过滤（`getPreferences/getKeys/clear`），不支持 prefix 过滤（属设计如此，非 OHOS 特有）。
- Async 默认存储名：当使用 Async `SharedPreferences` backend 且未指定 `fileName` 时，OHOS 默认使用 `${bundleName}_preferences` 作为存储名，以避免与 legacy `FlutterSharedPreferences`（固定存储名）发生读写互相覆盖；如需跨平台一致性，建议显式指定 `fileName`。
- StringList 存储协议：JSON 编码的 `List<String>` 会以 `jsonListPrefix + jsonEncode(list)` 的字符串形式落库；读取时会被还原为 `List<String>`。同时兼容历史 platformEncoded 的 list 格式用于迁移/回归。
- double 存储格式：legacy `SharedPreferences` API 下，Android 将 `double` 以 `DOUBLE_PREFIX` 字符串编码（`"VGhpcyBpcyB0aGUgcHJlZml4IGZvciBkb3VibGUu"` + 值）落库，而 OHOS 以原生 `number` 落库；Async API 在两端均以原生 `double` 存储。若将 legacy 数据从 Android 迁移到 OHOS（例如直接拷贝落盘 preferences 文件），Android 侧写入的 legacy `double` 需按 `DOUBLE_PREFIX` 字符串格式解码。
- 数据安全：本插件不提供加密能力，数据以明文方式持久化，请勿存储敏感信息。

## 使用示例

### 1. Legacy API（`SharedPreferences`）

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> legacyUsage() async {
  // 获取单例；OHOS 上所有键默认附加 'flutter.' 前缀读写，
  // 与其他平台的数据保持兼容。
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 保存各类支持的基础类型数据。
  await prefs.setInt('counter', 10);
  await prefs.setBool('repeat', true);
  await prefs.setDouble('decimal', 1.5);
  await prefs.setString('action', 'Start');
  await prefs.setStringList('items', <String>['Earth', 'Moon', 'Sun']);

  // 读取数据；键不存在时返回 null。
  final int? counter = prefs.getInt('counter');

  // 删除单个键。
  await prefs.remove('counter');
}
```

### 2. Async API 与后端选项（OpenHarmony 已支持）

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';

Future<void> asyncUsage() async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  // OHOS 专属选项：选择 'SharedPreferences' 后端并显式指定文件名，
  // 保证存储文件跨平台稳定。
  const SharedPreferencesAsyncOhosOptions options =
      SharedPreferencesAsyncOhosOptions(
    backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
    originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
      fileName: 'the_name_of_a_file',
    ),
  );

  await prefs.setString('action', 'Start', options: options);
  final String? action = await prefs.getString('action', options: options);
  print('action=$action');
}
```

### 3. WithCache API（内存缓存支撑的同步读取）

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> withCacheUsage() async {
  // allowList 限定可缓存、可读写的键；不在 allowList 内的键会抛出
  // ArgumentError。OHOS 上缓存来自与 Async API 相同的后端存储。
  final SharedPreferencesWithCache prefs =
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: <String>{'repeat', 'action'},
        ),
      );

  await prefs.setBool('repeat', true);

  // 读取是同步的，直接命中缓存。
  final bool? repeat = prefs.getBool('repeat');

  // 若存储可能被其他途径修改，可刷新缓存。
  await prefs.reloadCache();
}
```

### 4. 将 legacy 数据迁移到 Async API

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

Future<void> migrate() async {
  final SharedPreferences legacy = await SharedPreferences.getInstance();

  // 将 legacy 数据一次性拷贝到 Async 体系；完成标记可防止覆盖新数据，
  // 因此每次启动调用都是安全的。
  await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
    legacySharedPreferencesInstance: legacy,
    sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
    migrationCompletedKey: 'migrationCompleted',
  );
}
```

## 使用说明

- `SharedPreferencesAsyncOhos`：`SharedPreferencesAsyncPlatform` 的 OpenHarmony 实现。
- 过滤能力：Async 接口当前支持 `allowList` 过滤（`getPreferences`、`clear`、`getKeys` 等）。
- 后端选项：`SharedPreferencesAsyncOhosOptions.backend` 定义了 `DataStore` 与 `SharedPreferences` 两个选项。

## 接口说明

### API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性，no 则表示不支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

#### SharedPreferencesOptions

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `SharedPreferencesOptions()` | 构造函数 | `SharedPreferencesOptions options = const SharedPreferencesOptions()` | - | yes | 创建供 `SharedPreferencesAsync`/`SharedPreferencesWithCache` 使用的默认选项；各平台专属选项类均继承自它 |

#### SharedPreferencesAsync

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `SharedPreferencesAsync()` | 构造函数 | `SharedPreferencesOptions options = const SharedPreferencesOptions()` | - | yes | 创建实例；未注册平台实现时抛出 `StateError` |
| `getKeys()` | 方法 | `Set<String>? allowList` | `Future<Set<String>>` | yes | 返回所有键，可按 `allowList` 过滤；忽略值类型不兼容的键 |
| `getAll()` | 方法 | `Set<String>? allowList` | `Future<Map<String, Object?>>` | yes | 返回所有键值对，可按 `allowList` 过滤 |
| `getBool()` | 方法 | `String key` | `Future<bool?>` | yes | 读取布尔值；存储值不是 `bool` 时抛出 `TypeError` |
| `getInt()` | 方法 | `String key` | `Future<int?>` | yes | 读取整型值；存储值不是 `int` 时抛出 `TypeError` |
| `getDouble()` | 方法 | `String key` | `Future<double?>` | yes | 读取浮点值；存储值不是 `double` 时抛出 `TypeError` |
| `getString()` | 方法 | `String key` | `Future<String?>` | yes | 读取字符串；存储值不是 `String` 时抛出 `TypeError` |
| `getStringList()` | 方法 | `String key` | `Future<List<String>?>` | yes | 读取字符串列表；存储值不是 `List<String>` 时抛出 `TypeError` |
| `containsKey()` | 方法 | `String key` | `Future<bool>` | yes | 判断平台是否包含指定键 |
| `setBool()` | 方法 | `String key, bool value` | `Future<void>` | yes | 写入布尔值 |
| `setInt()` | 方法 | `String key, int value` | `Future<void>` | yes | 写入整型值 |
| `setDouble()` | 方法 | `String key, double value` | `Future<void>` | yes | 写入浮点值 |
| `setString()` | 方法 | `String key, String value` | `Future<void>` | yes | 写入字符串 |
| `setStringList()` | 方法 | `String key, List<String> value` | `Future<void>` | yes | 写入字符串列表 |
| `remove()` | 方法 | `String key` | `Future<void>` | yes | 删除指定键的条目 |
| `clear()` | 方法 | `Set<String>? allowList` | `Future<void>` | yes | 清除全部偏好，或仅清除匹配 `allowList` 的部分；强烈建议传入 `allowList` |

#### SharedPreferencesWithCacheOptions

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `SharedPreferencesWithCacheOptions()` | 构造函数 | `Set<String>? allowList` | - | yes | 创建缓存选项；allowList 为 `null` 时缓存全部数据，为空集合时禁止所有键 |
| `allowList` | 属性 | `Set<String>?` | `Set<String>?` | yes | 限定可缓存、可读写以及 `clear()` 可清除的数据范围 |

#### SharedPreferencesWithCache

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `create()` | 静态方法 | `SharedPreferencesOptions sharedPreferencesOptions, SharedPreferencesWithCacheOptions cacheOptions, Map<String, Object?>? cache` | `Future<SharedPreferencesWithCache>` | yes | 创建实例并从平台数据重载缓存 |
| `keys` | getter | `-` | `Set<String>` | yes | 返回缓存中的所有键 |
| `reloadCache()` | 方法 | `-` | `Future<void>` | yes | 用平台最新数据刷新缓存 |
| `containsKey()` | 方法 | `String key` | `bool` | yes | 判断缓存是否包含该键；键不在 allowList 内时抛出 `ArgumentError` |
| `get()` | 方法 | `String key` | `Object?` | yes | 从缓存读取任意类型的值；键不在 allowList 内时抛出 `ArgumentError` |
| `getBool()` | 方法 | `String key` | `bool?` | yes | 读取布尔值；过滤不匹配抛 `ArgumentError`，类型不匹配抛 `TypeError` |
| `getInt()` | 方法 | `String key` | `int?` | yes | 读取整型值；过滤不匹配抛 `ArgumentError`，类型不匹配抛 `TypeError` |
| `getDouble()` | 方法 | `String key` | `double?` | yes | 读取浮点值；过滤不匹配抛 `ArgumentError`，类型不匹配抛 `TypeError` |
| `getString()` | 方法 | `String key` | `String?` | yes | 读取字符串；过滤不匹配抛 `ArgumentError`，类型不匹配抛 `TypeError` |
| `getStringList()` | 方法 | `String key` | `List<String>?` | yes | 读取字符串列表（返回副本）；过滤不匹配抛 `ArgumentError`，类型不匹配抛 `TypeError` |
| `setBool()` | 方法 | `String key, bool value` | `Future<void>` | yes | 向缓存和平台写入布尔值；键不在 allowList 内时抛出 `ArgumentError` |
| `setInt()` | 方法 | `String key, int value` | `Future<void>` | yes | 向缓存和平台写入整型值；键不在 allowList 内时抛出 `ArgumentError` |
| `setDouble()` | 方法 | `String key, double value` | `Future<void>` | yes | 向缓存和平台写入浮点值；键不在 allowList 内时抛出 `ArgumentError` |
| `setString()` | 方法 | `String key, String value` | `Future<void>` | yes | 向缓存和平台写入字符串；键不在 allowList 内时抛出 `ArgumentError` |
| `setStringList()` | 方法 | `String key, List<String> value` | `Future<void>` | yes | 向缓存和平台写入字符串列表；键不在 allowList 内时抛出 `ArgumentError` |
| `remove()` | 方法 | `String key` | `Future<void>` | yes | 从缓存和平台删除指定键；键不在 allowList 内时抛出 `ArgumentError` |
| `clear()` | 方法 | `-` | `Future<void>` | yes | 清除缓存及平台上匹配 allowList 的偏好 |

#### SharedPreferences（遗留 API）

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `getInstance()` | 静态函数 | `-` | `Future<SharedPreferences>` | yes | 从磁盘加载偏好并返回单例实例 |
| `setPrefix()` | 静态函数 | `String prefix, Set<String>? allowList` | `void` | yes | 设置所有键附加的前缀（默认 `flutter.`）；必须在 `getInstance` 之前调用，否则抛出 `StateError` |
| `getKeys()` | 函数 | `-` | `Set<String>` | yes | 返回当前 `SharedPreferences` 作用域内的全部键集合 |
| `get()` | 函数 | `String key` | `Object?` | yes | 读取当前作用域内任意类型的值 |
| `getString()` | 函数 | `String key` | `String?` | yes | 获取当前 `SharedPreferences` 作用域内已存储的字符串；类型不符抛出 `TypeError` |
| `getInt()` | 函数 | `String key` | `int?` | yes | 获取当前 `SharedPreferences` 作用域内已存储的整型值；类型不符抛出 `TypeError` |
| `getDouble()` | 函数 | `String key` | `double?` | yes | 获取当前 `SharedPreferences` 作用域内已存储的浮点值；类型不符抛出 `TypeError` |
| `getBool()` | 函数 | `String key` | `bool?` | yes | 获取当前 `SharedPreferences` 作用域内已存储的布尔值；类型不符抛出 `TypeError` |
| `getStringList()` | 函数 | `String key` | `List<String>?` | yes | 获取当前 `SharedPreferences` 作用域内已存储的字符串列表；类型不符抛出 `TypeError` |
| `containsKey()` | 函数 | `String key` | `bool` | yes | 检查当前 `SharedPreferences` 作用域内是否存在该键 |
| `setString()` | 函数 | `String key, String value` | `Future<bool>` | yes | 存储字符串 |
| `setInt()` | 函数 | `String key, int value` | `Future<bool>` | yes | 存储整型值 |
| `setDouble()` | 函数 | `String key, double value` | `Future<bool>` | yes | 存储浮点值 |
| `setBool()` | 函数 | `String key, bool value` | `Future<bool>` | yes | 存储布尔值 |
| `setStringList()` | 函数 | `String key, List<String> value` | `Future<bool>` | yes | 存储字符串列表 |
| `remove()` | 函数 | `String key` | `Future<bool>` | yes | 删除指定键值 |
| `commit()` | 函数 | `-` | `Future<bool>` | yes | 已弃用的空操作，恒返回 `true`，新代码不应调用 |
| `clear()` | 函数 | `-` | `Future<bool>` | yes | 清除当前 `SharedPreferences` 作用域内的全部键值 |
| `reload()` | 函数 | `-` | `Future<void>` | yes | 从磁盘重新加载当前 `SharedPreferences` 作用域内的数据 |

#### migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary()` | 函数 | `SharedPreferences legacySharedPreferencesInstance, SharedPreferencesOptions sharedPreferencesAsyncOptions, String migrationCompletedKey` | `Future<void>` | yes | 将 legacy 数据一次性拷贝到 Async 体系；可重复执行，跳过包含非 `String` 元素的列表 |

#### SharedPreferencesOhos

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `remove()` | 方法 | `String key` | `Future<bool>` | yes | 删除指定键值 |
| `setValue()` | 方法 | `String valueType, String key, Object value` | `Future<bool>` | yes | 按类型写入 `String`、`int`、`double`、`bool`、`List<String>` |
| `clear()` | 方法 | `-` | `Future<bool>` | yes | 清除默认 legacy 前缀 `flutter.` 作用域内的数据 |
| `clearWithPrefix()` | 方法 | `String prefix` | `Future<bool>` | yes | 按指定前缀清除数据 |
| `clearWithParameters()` | 方法 | `ClearParameters parameters` | `Future<bool>` | yes | 按 legacy 过滤参数清除数据 |
| `getAll()` | 方法 | `-` | `Future<Map<String, Object>>` | yes | 获取默认 legacy 前缀 `flutter.` 作用域内的全部数据 |
| `getAllWithPrefix()` | 方法 | `String prefix` | `Future<Map<String, Object>>` | yes | 获取指定前缀作用域内的全部数据 |
| `getAllWithParameters()` | 方法 | `GetAllParameters parameters` | `Future<Map<String, Object>>` | yes | 按 legacy 过滤参数获取全部数据 |

#### SharedPreferencesAsyncOhos

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `getKeys()` | 方法 | `GetPreferencesParameters parameters, SharedPreferencesOptions options` | `Future<Set<String>>` | yes | 获取 Async 接口作用域内的键集合，当前支持 `allowList` 过滤 |
| `setString()` | 方法 | `String key, String value, SharedPreferencesOptions options` | `Future<void>` | yes | 写入字符串 |
| `setInt()` | 方法 | `String key, int value, SharedPreferencesOptions options` | `Future<void>` | yes | 写入整型值 |
| `setDouble()` | 方法 | `String key, double value, SharedPreferencesOptions options` | `Future<void>` | yes | 写入浮点值 |
| `setBool()` | 方法 | `String key, bool value, SharedPreferencesOptions options` | `Future<void>` | yes | 写入布尔值 |
| `setStringList()` | 方法 | `String key, List<String> value, SharedPreferencesOptions options` | `Future<void>` | yes | 将字符串列表编码后写入 |
| `getString()` | 方法 | `String key, SharedPreferencesOptions options` | `Future<String?>` | yes | 获取字符串 |
| `getInt()` | 方法 | `String key, SharedPreferencesOptions options` | `Future<int?>` | yes | 获取整型值 |
| `getDouble()` | 方法 | `String key, SharedPreferencesOptions options` | `Future<double?>` | yes | 获取浮点值 |
| `getBool()` | 方法 | `String key, SharedPreferencesOptions options` | `Future<bool?>` | yes | 获取布尔值 |
| `getStringList()` | 方法 | `String key, SharedPreferencesOptions options` | `Future<List<String>?>` | yes | 获取字符串列表，兼容 JSON 编码与平台编码结果 |
| `clear()` | 方法 | `ClearPreferencesParameters parameters, SharedPreferencesOptions options` | `Future<void>` | yes | 按 Async 过滤参数清理数据，当前支持 `allowList` |
| `getPreferences()` | 方法 | `GetPreferencesParameters parameters, SharedPreferencesOptions options` | `Future<Map<String, Object>>` | yes | 按 Async 过滤参数获取全部数据，当前支持 `allowList` |

#### SharedPreferencesAsyncOhosOptions

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `backend` | 属性 | `SharedPreferencesOhosBackendLibrary` | `SharedPreferencesOhosBackendLibrary` | yes | Async 接口后端选项，定义 `DataStore` 与 `SharedPreferences` 两个枚举值 |
| `originalSharedPreferencesOptions` | 属性 | `OhosSharedPreferencesStoreOptions?` | `OhosSharedPreferencesStoreOptions?` | yes | 当选择 `SharedPreferences` 后端时使用的附加配置 |

#### OhosSharedPreferencesStoreOptions

| 名称 | 类型 | 参数类型 | 返回值 | OHOS 平台支持 | 描述 |
| --- | --- | --- | --- | --- | --- |
| `fileName` | 属性 | `String?` | `String?` | yes | 指定 `SharedPreferences` 后端使用的存储文件名 |

#### 异常说明

| 异常 | 抛出接口 | 触发条件 |
| --- | --- | --- |
| `TypeError` | 遗留 API 的类型化 getter（`getBool`/`getInt`/`getDouble`/`getString`/`getStringList`）、Async API 与 `SharedPreferencesWithCache` 的类型化 getter | 存储值与请求的类型不匹配 |
| `ArgumentError` | `SharedPreferencesWithCache` 的 get/set/`containsKey`；遗留 API 的 setter | 键不在 allowList 内，或 setter 传入 `null` 值 |
| `StateError` | `SharedPreferencesAsync` 构造函数；`SharedPreferences.setPrefix` | 未注册平台实现，或在 `getInstance` 之后调用 `setPrefix` |
| `UnimplementedError` | 设置自定义前缀后的 `SharedPreferences.getInstance`/`clear` | 当前平台存储实现不支持前缀过滤 |

#### 存储类型

| 名称 | 描述 | 类型 | OHOS 平台支持 |
| --- | --- | --- | --- |
| String | 存储字符串值 | String | yes |
| int | 存储整数值 | int | yes |
| double | 存储浮点数值 | double | yes |
| bool | 存储布尔值 | bool | yes |
| List<String> | 存储字符串列表 | List | yes |

#### 参数

| 名称 | 描述 | 类型 | OHOS 平台支持 |
| --- | --- | --- | --- |
| key | 存储值的唯一标识符 | String | yes |
| value | 要存储的值（String、int、double、bool 或 List<String>） | dynamic | yes |
| prefix | legacy `SharedPreferences` 接口默认使用 `flutter.` 作为键前缀，用于限定 `clear()`、`getKeys()`、`containsKey()`、`reload()` 等作用范围 | String | yes |

## 目录结构

```text
shared_preferences_ohos/
├─ lib/
│  ├─ shared_preferences_ohos.dart
│  └─ src/
│     ├─ shared_preferences_ohos.dart
│     └─ shared_preferences_async_ohos.dart
├─ ohos/
├─ example/
├─ test/
└─ pubspec.yaml
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues) ，当然，也非常欢迎发 [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) 共建。

## 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/br_shared_preferences-v2.5.4_ohos/packages/shared_preferences/shared_preferences/LICENSE)，请自由地享受和参与开源。

> 模板版本: v0.0.1
