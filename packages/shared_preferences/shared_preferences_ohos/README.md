
<p align="center">
  <h1 align="center"> <code>shared_preferences</code> </h1>
</p>

This project is based on [shared_preferences@2.2.0](https://pub.dev/packages/shared_preferences/versions/2.2.0).

`shared_preferences_ohos` is the OpenHarmony platform implementation of `shared_preferences`. It provides persistent key-value storage for lightweight data on OpenHarmony devices. Through the federated plugin architecture, this implementation is automatically registered when you add `shared_preferences` as a dependency, so you do not need to reference this package directly in your code.

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  shared_preferences:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences"
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

#### Basic Usage

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Obtain a SharedPreferences instance
final prefs = await SharedPreferences.getInstance();

// Write data
await prefs.setString('username', 'Alice');
await prefs.setInt('age', 25);
await prefs.setDouble('score', 95.5);
await prefs.setBool('is_logged_in', true);
await prefs.setStringList('tags', ['flutter', 'ohos', 'mobile']);

// Read data
final username = prefs.getString('username');       // 'Alice'
final age = prefs.getInt('age');                   // 25
final score = prefs.getDouble('score');             // 95.5
final loggedIn = prefs.getBool('is_logged_in');     // true
final tags = prefs.getStringList('tags');           // ['flutter', 'ohos', 'mobile']

// Check if a key exists
final hasKey = prefs.containsKey('username');       // true

// Get all keys
final allKeys = prefs.getKeys();                    // Set containing all stored keys

// Remove a specific key
await prefs.remove('age');

// Clear all stored data (only keys with 'flutter.' prefix)
await prefs.clear();

// Reload data from disk
await prefs.reload();
```

#### Data Persistence Example

The following example demonstrates how to persist data across app restarts using `SharedPreferences`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SharedPreferences Demo',
      home: CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  // Load persisted counter value
  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
    });
  }

  // Increment counter and persist the new value
  Future<void> _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
    });
    await prefs.setInt('counter', _counter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Demo')),
      body: Center(
        child: Text('Button pressed $_counter times.\nThis value persists across restarts.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

#### Using SharedPreferencesOhos Directly

If you need to use the platform implementation directly (e.g., for testing or advanced scenarios), you can instantiate `SharedPreferencesOhos`:

```dart
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

// Create an instance of SharedPreferencesOhos
final SharedPreferencesOhos prefs = SharedPreferencesOhos();

// Write values using setValue
await prefs.setValue('String', 'flutter.username', 'Alice');
await prefs.setValue('Int', 'flutter.age', 25);
await prefs.setValue('Double', 'flutter.score', 95.5);
await prefs.setValue('Bool', 'flutter.is_logged_in', true);
await prefs.setValue('StringList', 'flutter.tags', ['flutter', 'ohos']);

// Read all values with a specific prefix
final Map<String, Object> values = await prefs.getAllWithParameters(
  GetAllParameters(filter: PreferencesFilter(prefix: 'flutter.')),
);
print(values); // {flutter.username: Alice, flutter.age: 25, ...}

// Clear values with a specific prefix
await prefs.clearWithParameters(
  ClearParameters(filter: PreferencesFilter(prefix: 'flutter.')),
);

// Clear with allow list (only remove specific keys)
await prefs.clearWithParameters(
  ClearParameters(
    filter: PreferencesFilter(
      prefix: 'flutter.',
      allowList: {'flutter.username', 'flutter.age'},
    ),
  ),
);

// Register as the default platform implementation (normally done automatically)
SharedPreferencesOhos.registerWith();
```

For more use cases, see [shared_preferences_ohos/example](./example).

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 Key Prefix Behavior

- The `SharedPreferences.getInstance()` API uses `'flutter.'` as the default prefix for all keys. For example, when you call `prefs.setInt('counter', 5)`, the key is internally stored as `'flutter.counter'`.
- The `clear()` method only removes keys that start with the `'flutter.'` prefix. Keys with other prefixes are not affected.
- When using `SharedPreferencesOhos` directly, you can specify any prefix (including an empty prefix `''`) via `getAllWithParameters` / `clearWithParameters`.

## 3. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

#### Storage type

| Name         | Description                 | Type   | **ohos Support** |
| ------------ | --------------------------- | ------ | ---------------- |
| String       | Store string values         | String | yes              |
| int          | Store integer values        | int    | yes              |
| double       | Store floating-point values | double | yes              |
| bool         | Store boolean values        | bool   | yes              |
| List<String> | Store string lists          | List   | yes              |

## 4. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### SharedPreferences (User-facing API)

These are the APIs provided by the `shared_preferences` package that developers typically use. The ohos platform implementation supports all of these methods.

| Name            | **return value**          | Description                          | **ohos Support** |
| --------------- | ------------------------- | ------------------------------------ | ---------------- |
| getInstance()   | Future<SharedPreferences> | Returns a SharedPreferences instance. The ohos platform implementation is automatically selected on OpenHarmony devices. | yes |
| getString()     | String?                   | Reads a string value for the given key. Returns `null` if the key does not exist. | yes |
| getInt()        | int?                      | Reads an integer value for the given key. Returns `null` if the key does not exist. | yes |
| getDouble()     | double?                   | Reads a double value for the given key. Returns `null` if the key does not exist. | yes |
| getBool()       | bool?                     | Reads a boolean value for the given key. Returns `null` if the key does not exist. | yes |
| getStringList() | List<String>?             | Reads a string list for the given key. Returns `null` if the key does not exist. | yes |
| setString()     | Future<bool>              | Writes a string value. Returns `true` if the value was committed successfully, `false` otherwise. | yes |
| setInt()        | Future<bool>              | Writes an integer value. Returns `true` if the value was committed successfully, `false` otherwise. | yes |
| setDouble()     | Future<bool>              | Writes a double value. Returns `true` if the value was committed successfully, `false` otherwise. | yes |
| setBool()       | Future<bool>              | Writes a boolean value. Returns `true` if the value was committed successfully, `false` otherwise. | yes |
| setStringList() | Future<bool>              | Writes a string list. Returns `true` if the value was committed successfully, `false` otherwise. | yes |
| remove()        | Future<bool>              | Removes the value associated with the given key. Returns `true` if the key was removed successfully. | yes |
| clear()         | Future<bool>              | Removes all keys that start with the `'flutter.'` prefix. Keys with other prefixes are not affected. Returns `true` on success. | yes |
| reload()        | Future<bool>              | Reloads the preferences from disk. Useful when preferences may have been modified by another process. Returns `true` on success. | yes |
| containsKey()   | bool                      | Checks whether the given key exists in preferences. | yes |
| getKeys()       | Set<String>               | Returns all keys currently stored in preferences (only those with the `'flutter.'` prefix). | yes |

#### Method Parameters

##### getInstance()

No parameters.

```dart
final prefs = await SharedPreferences.getInstance();
```

##### getString(key)

| Parameter | Type     | Description                            | Required |
| --------- | -------- | -------------------------------------- | -------- |
| key       | String   | The key used to store the string value | Yes      |

```dart
final value = prefs.getString('username');
```

##### getInt(key)

| Parameter | Type     | Description                            | Required |
| --------- | -------- | -------------------------------------- | -------- |
| key       | String   | The key used to store the integer value | Yes     |

```dart
final value = prefs.getInt('age');
```

##### getDouble(key)

| Parameter | Type     | Description                            | Required |
| --------- | -------- | -------------------------------------- | -------- |
| key       | String   | The key used to store the double value | Yes      |

```dart
final value = prefs.getDouble('score');
```

##### getBool(key)

| Parameter | Type     | Description                            | Required |
| --------- | -------- | -------------------------------------- | -------- |
| key       | String   | The key used to store the boolean value | Yes     |

```dart
final value = prefs.getBool('is_logged_in');
```

##### getStringList(key)

| Parameter | Type     | Description                            | Required |
| --------- | -------- | -------------------------------------- | -------- |
| key       | String   | The key used to store the string list  | Yes      |

```dart
final value = prefs.getStringList('tags');
```

##### setString(key, value)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key to associate with the string     | Yes      |
| value     | String   | The string value to store                | Yes      |

```dart
await prefs.setString('username', 'Alice');
```

##### setInt(key, value)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key to associate with the integer    | Yes      |
| value     | int      | The integer value to store               | Yes      |

```dart
await prefs.setInt('age', 25);
```

##### setDouble(key, value)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key to associate with the double     | Yes      |
| value     | double   | The double value to store                | Yes      |

```dart
await prefs.setDouble('score', 95.5);
```

##### setBool(key, value)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key to associate with the boolean    | Yes      |
| value     | bool     | The boolean value to store               | Yes      |

```dart
await prefs.setBool('is_logged_in', true);
```

##### setStringList(key, value)

| Parameter | Type          | Description                              | Required |
| --------- | ------------- | ---------------------------------------- | -------- |
| key       | String        | The key to associate with the string list | Yes     |
| value     | List<String>  | The string list to store                 | Yes      |

```dart
await prefs.setStringList('tags', ['flutter', 'ohos']);
```

##### remove(key)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key whose value should be removed    | Yes      |

```dart
await prefs.remove('username');
```

##### clear()

No parameters. Removes all keys with the `'flutter.'` prefix.

```dart
await prefs.clear();
```

##### reload()

No parameters. Reloads preferences data from disk.

```dart
await prefs.reload();
```

##### containsKey(key)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key to check for existence           | Yes      |

```dart
final exists = prefs.containsKey('username'); // true or false
```

##### getKeys()

No parameters. Returns all keys with the `'flutter.'` prefix.

```dart
final keys = prefs.getKeys(); // Set<String> of all stored keys
```

### SharedPreferencesOhos (Platform Implementation API)

These are the APIs provided by the `SharedPreferencesOhos` platform implementation class. Most developers should use the `SharedPreferences` user-facing API above. Use these only if you need direct access to the platform implementation.

| Name                       | **return value**        | Description                                                                 | **ohos Support** |
| -------------------------- | ----------------------- | --------------------------------------------------------------------------- | ---------------- |
| registerWith()             | void                    | Registers this class as the default instance of SharedPreferencesStorePlatform. Called automatically by the plugin registration mechanism. | yes |
| setValue(valueType, key, value) | Future<bool>      | Writes a value. `valueType` must be one of `'String'`, `'Bool'`, `'Int'`, `'Double'`, or `'StringList'`. Returns `true` on success. | yes |
| remove(key)                | Future<bool>            | Removes the value for the given key. Returns `true` on success.             | yes              |
| clear()                    | Future<bool>            | Removes all keys with the `'flutter.'` prefix. Returns `true` on success.   | yes              |
| clearWithPrefix(prefix)    | Future<bool>            | Removes all keys that start with the given prefix. Returns `true` on success. | yes           |
| clearWithParameters(parameters) | Future<bool>      | Removes keys based on ClearParameters (prefix + optional allowList). Returns `true` on success. | yes |
| getAll()                   | Future<Map<String, Object>> | Returns all key-value pairs with the `'flutter.'` prefix.              | yes              |
| getAllWithPrefix(prefix)   | Future<Map<String, Object>> | Returns all key-value pairs that start with the given prefix.           | yes              |
| getAllWithParameters(parameters) | Future<Map<String, Object>> | Returns key-value pairs based on GetAllParameters (prefix + optional allowList). | yes |

#### SharedPreferencesOhos Method Parameters

##### registerWith()

No parameters. Called automatically by Flutter's plugin registration system.

```dart
SharedPreferencesOhos.registerWith();
```

##### setValue(valueType, key, value)

| Parameter  | Type     | Description                                                              | Required |
| ---------- | -------- | ------------------------------------------------------------------------ | -------- |
| valueType  | String   | The type identifier: `'String'`, `'Bool'`, `'Int'`, `'Double'`, or `'StringList'` | Yes |
| key        | String   | The key to associate with the value                                      | Yes      |
| value      | Object   | The value to store. Type must match `valueType`                          | Yes      |

```dart
await prefs.setValue('String', 'flutter.username', 'Alice');
await prefs.setValue('Int', 'flutter.age', 25);
await prefs.setValue('Double', 'flutter.score', 95.5);
await prefs.setValue('Bool', 'flutter.is_logged_in', true);
await prefs.setValue('StringList', 'flutter.tags', ['flutter', 'ohos']);
```

##### remove(key)

| Parameter | Type     | Description                              | Required |
| --------- | -------- | ---------------------------------------- | -------- |
| key       | String   | The key whose value should be removed    | Yes      |

```dart
await prefs.remove('flutter.username');
```

##### clear()

No parameters. Removes all keys with the `'flutter.'` prefix.

```dart
await prefs.clear();
```

##### clearWithPrefix(prefix)

| Parameter | Type     | Description                                           | Required |
| --------- | -------- | ----------------------------------------------------- | -------- |
| prefix    | String   | The prefix filter. Only keys starting with this prefix will be removed. Use `''` to remove all keys. | Yes |

```dart
await prefs.clearWithPrefix('flutter.');
await prefs.clearWithPrefix('');  // clears all keys regardless of prefix
```

##### clearWithParameters(parameters)

| Parameter   | Type             | Description                          | Required |
| ----------- | ---------------- | ------------------------------------ | -------- |
| parameters  | ClearParameters  | Contains a PreferencesFilter with prefix and optional allowList | Yes |

**ClearParameters**

| Field   | Type              | Description                                                              | Required |
| ------- | ----------------- | ------------------------------------------------------------------------ | -------- |
| filter  | PreferencesFilter | Filter specifying which keys to clear                                     | Yes      |

**PreferencesFilter**

| Field     | Type          | Description                                                              | Required |
| --------- | ------------- | ------------------------------------------------------------------------ | -------- |
| prefix    | String        | Only keys starting with this prefix will be considered                   | Yes      |
| allowList | Set<String>?  | Optional whitelist of specific keys to clear. If null, all matching keys are cleared. | No |

```dart
// Clear all keys with 'flutter.' prefix
await prefs.clearWithParameters(
  ClearParameters(filter: PreferencesFilter(prefix: 'flutter.')),
);

// Clear only specific keys within 'flutter.' prefix
await prefs.clearWithParameters(
  ClearParameters(
    filter: PreferencesFilter(
      prefix: 'flutter.',
      allowList: {'flutter.username', 'flutter.age'},
    ),
  ),
);

// Clear all keys regardless of prefix
await prefs.clearWithParameters(
  ClearParameters(filter: PreferencesFilter(prefix: '')),
);
```

##### getAll()

No parameters. Returns all key-value pairs with the `'flutter.'` prefix.

```dart
final Map<String, Object> values = await prefs.getAll();
```

##### getAllWithPrefix(prefix)

| Parameter | Type     | Description                                           | Required |
| --------- | -------- | ----------------------------------------------------- | -------- |
| prefix    | String   | The prefix filter. Only keys starting with this prefix will be returned. Use `''` to get all keys. | Yes |

```dart
final Map<String, Object> values = await prefs.getAllWithPrefix('flutter.');
final Map<String, Object> allValues = await prefs.getAllWithPrefix('');
```

##### getAllWithParameters(parameters)

| Parameter   | Type              | Description                          | Required |
| ----------- | ----------------- | ------------------------------------ | -------- |
| parameters  | GetAllParameters  | Contains a PreferencesFilter with prefix and optional allowList | Yes |

**GetAllParameters**

| Field   | Type              | Description                                                              | Required |
| ------- | ----------------- | ------------------------------------------------------------------------ | -------- |
| filter  | PreferencesFilter | Filter specifying which keys to retrieve                                  | Yes      |

**PreferencesFilter**

| Field     | Type          | Description                                                              | Required |
| --------- | ------------- | ------------------------------------------------------------------------ | -------- |
| prefix    | String        | Only keys starting with this prefix will be considered                   | Yes      |
| allowList | Set<String>?  | Optional whitelist of specific keys to retrieve. If null, all matching keys are returned. | No |

```dart
// Get all keys with 'flutter.' prefix
final Map<String, Object> values = await prefs.getAllWithParameters(
  GetAllParameters(filter: PreferencesFilter(prefix: 'flutter.')),
);

// Get only specific keys within 'flutter.' prefix
final Map<String, Object> values = await prefs.getAllWithParameters(
  GetAllParameters(
    filter: PreferencesFilter(
      prefix: 'flutter.',
      allowList: {'flutter.username', 'flutter.age'},
    ),
  ),
);

// Get all keys regardless of prefix
final Map<String, Object> allValues = await prefs.getAllWithParameters(
  GetAllParameters(filter: PreferencesFilter(prefix: '')),
);
```

## 5. Known Issues

- Strings that start with the special internal prefix (`VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGRvdWJsZS4`) cannot be stored via `setValue('String', ...)` because it is used internally to encode `double` values. Attempting to store such a string will throw a `PlatformException`.

## 6. Others

## 7. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/shared_preferences/shared_preferences/LICENSE)

> Template version: v0.0.1.
