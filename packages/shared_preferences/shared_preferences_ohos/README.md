<p align="center">
  <h1 align="center"> <code>shared_preferences</code> </h1>
</p>

本项目基于 [shared_preferences@2.3.2](https://pub.dev/packages/shared_preferences/versions/2.3.2) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  shared_preferences:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/shared_preferences/shared_preferences
      # ref: shared_preferences-v2.3.2-ohos-1.0.1
      ref: TAG  #   请根据下方TAG版本对应表选择TAG
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG 版本对应表**

| Flutter 框架版本 | TAG1 | TAG2 | 分支 |
| :--- | :--- | :--- | :--- |
| 3.41 | `shared_preferences-v2.5.4-ohos-1.0.0` | `shared_preferences-v2.5.4-ohos-1.0.1` | `br_shared_preferences-v2.5.4_ohos` |
| 3.35 | `shared_preferences-v2.5.4-ohos-1.0.0` | `shared_preferences-v2.5.4-ohos-1.0.1` | `br_shared_preferences-v2.5.4_ohos` |
| 3.27 | `shared_preferences-v2.5.3-ohos-1.0.0` | `shared_preferences-v2.5.3-ohos-1.0.1` | `br_shared_preferences-v2.5.3_ohos` |
| 3.22 | `shared_preferences-v2.3.2-ohos-1.0.0` | `shared_preferences-v2.3.2-ohos-1.0.1` | `br_shared_preferences-v2.3.2_ohos` |
| 3.7 | `shared_preferences-v2.2.2-ohos-1.0.0` | `shared_preferences-v2.2.2-ohos-1.0.1` | `master` |

## 1.2 使用案例

使用案例详见 [ohos/example](./example/)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| setInt(String key, int value)                                | Future<bool>                                          | 将 int 值关联到指定 key。      | function | yes          |
| setDouble(String key, double value)                          | Future<bool>                                          | 将 double 值关联到指定 key。     | function | yes          |
| setBool(String key, bool value)                              | Future<bool>                                          | 将 bool 值关联到指定 key。        | function | yes          |
| setString(String key, String value)                          | Future<bool>                                          | 将 String 值关联到指定 key。     | function | yes          |
| setStringList(String key, List<String> value)                | Future<bool>                                          | 将字符串列表关联到指定 key。 | function | yes          |
| getInt(String key)                                           | int?                                                  | 读取指定 key 的 int 值。 | function | yes          |
| getDouble(String key)                                        | double?                                               | 读取指定 key 的 double 值。   | function | yes          |
| getBool(String key)                                          | bool?                                                 | 读取指定 key 的 bool 值。      | function | yes          |
| getString(String key)                                        | String?                                               | 读取指定 key 的 String 值。     | function | yes          |
| getStringList(String key)                                    | List<String>?                                         | 读取指定 key 的字符串列表。 | function | yes          |
| remove(String key)                                           | Future<bool>                                          | 移除指定 key。      | function | yes          |
| clear()                                                      | Future<bool>                                          | 清除所有首选项。           | function | yes          |
| containsKey(String key)                                      | bool                                                  | 判断是否包含指定 key。      | function | yes          |
| reload()                                                     | Future<void>                                          | 重新加载首选项。    | function | yes          |

## 4. 遗留问题

## 5. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/shared_preferences/shared_preferences/LICENSE)，请自由地享受和参与开源。

> 模板版本: v0.0.1
