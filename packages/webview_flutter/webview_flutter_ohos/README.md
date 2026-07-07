<p align="center">
  <h1 align="center"> <code>webview_flutter</code> </h1>
</p>

本项目基于 [webview_flutter@4.8.0](https://pub.dev/packages/webview_flutter/versions/4.8.0) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/webview_flutter/webview_flutter
      # ref: webview_flutter-v4.8.0-ohos-1.0.0
      ref: TAG  #   请根据下方TAG版本对应表选择TAG
...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG 版本对应表**

| Flutter 框架版本 | TAG | 分支 |
| :--- | :--- | :--- |
| 3.35 | `webview_flutter-v4.13.0-ohos-1.0.0` | `br_webview_flutter-v4.13.0_ohos` |
| 3.27 | `webview_flutter-v4.13.0-ohos-1.0.0` | `br_webview_flutter-v4.13.0_ohos` |
| 3.22 | `webview_flutter-v4.8.0-ohos-1.0.0` | `br_webview_flutter-v4.8.0_ohos` |
| 3.7 | `webview_flutter-v4.4.2-ohos-1.0.0` | `master` |

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
| WebViewController()                                           | WebViewController                                      | 控制 WebView 的控制器。       | class    | yes          |
| loadRequest(Uri uri, {LoadRequestMethod method = LoadRequestMethod.get, Map<String, String> headers = const <String, String>{}, Uint8List? body}) | Future<void>                                          | 加载指定的 URL 请求。 | function | yes          |
| loadFlutterAsset(String key)                                | Future<void>                                          | 加载 Flutter 资源中的 HTML 文件。     | function | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                          | 加载指定的 HTML 字符串。     | function | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>                                          | 加载本地文件。 | function | yes          |
| runJavaScript(String javaScript)                             | Future<void>                                          | 在当前页面上下文中执行 JavaScript 代码。 | function | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>                                        | 执行 JavaScript 并返回结果。 | function | yes          |
| canGoBack()                                                  | Future<bool>                                          | 判断是否可以后退。      | function | yes          |
| canGoForward()                                               | Future<bool>                                          | 判断是否可以前进。      | function | yes          |
| goBack()                                                     | Future<void>                                          | 后退到上一页。 | function | yes          |
| goForward()                                                  | Future<void>                                          | 前进到下一页。 | function | yes          |
| reload()                                                     | Future<void>                                          | 重新加载当前页面。 | function | yes          |
| currentUrl()                                                 | Future<String?>                                       | 获取当前 URL。 | function | yes          |
| getTitle()                                                   | Future<String?>                                       | 获取当前页面标题。 | function | yes          |
| setJavaScriptMode(JavaScriptMode mode)                       | Future<void>                                          | 设置 JavaScript 执行模式。 | function | yes          |
| setBackgroundColor(Color color)                              | Future<void>                                          | 设置背景颜色。 | function | yes          |
| enableZoom(bool enabled)                                    | Future<void>                                          | 设置是否支持缩放。 | function | yes          |
| WebViewWidget({required WebViewController controller,})       | Widget                                                | 用于显示 WebView 的 Widget。 | class    | yes          |

## 4. 遗留问题

## 5. 开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/webview_flutter/webview_flutter/LICENSE)，请自由地享受和参与开源。

> 模板版本: v0.0.1
