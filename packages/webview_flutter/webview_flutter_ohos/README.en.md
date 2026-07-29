<p align="center">
  <h1 align="center"> <code>webview_flutter</code> </h1>
</p>

This project is based on [webview_flutter@4.8.0](https://pub.dev/packages/webview_flutter/versions/4.8.0).

## 1. Installation & Usage

### 1.1 Installation

In your project directory, add the following dependency to `pubspec.yaml`:

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/webview_flutter/webview_flutter
      # ref: webview_flutter-v4.8.0-ohos-1.0.1
      ref: TAG  #   Select a TAG according to the TAG version table below
...
```

Run the command

```bash
flutter pub get
```

<!-- tabs:end -->

**TAG Version Table**

| Flutter Version | TAG1 | TAG2 | Branch |
| :--- | :--- | :--- | :--- |
| 3.41 | `-` | `webview_flutter-v4.13.1-ohos-1.0.0` | `br_webview_flutter-v4.13.1_ohos` |
| 3.35 | `webview_flutter-v4.13.0-ohos-1.0.0` | `webview_flutter-v4.13.0-ohos-1.0.1` | `br_webview_flutter-v4.13.0_ohos` |
| 3.27 | `webview_flutter-v4.13.0-ohos-1.0.0` | `webview_flutter-v4.13.0-ohos-1.0.1` | `br_webview_flutter-v4.13.0_ohos` |
| 3.22 | `webview_flutter-v4.8.0-ohos-1.0.0` | `webview_flutter-v4.8.0-ohos-1.0.1` | `br_webview_flutter-v4.8.0_ohos` |
| 3.7 | `webview_flutter-v4.4.2-ohos-1.0.0` | `webview_flutter-v4.4.2-ohos-1.0.1` | `master` |

## 1.2 Example

For usage examples, see [ohos/example](./example/).

## 2. Constraints & Limitations

### 2.1 Compatibility

Tested with the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] An "ohos Support" value of `yes` means the property is supported on the ohos platform; `no` means not supported; `partially` means partially supported. Usage is cross-platform consistent, and the behavior is aligned with iOS or Android.

| Name                                                         | return value                                          | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| WebViewController()                                           | WebViewController                                      | Controller for the WebView.       | class    | yes          |
| loadRequest(Uri uri, {LoadRequestMethod method = LoadRequestMethod.get, Map<String, String> headers = const <String, String>{}, Uint8List? body}) | Future<void>                                          | Loads the specified URL request. | function | yes          |
| loadFlutterAsset(String key)                                | Future<void>                                          | Loads an HTML file from the Flutter assets.     | function | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                          | Loads the specified HTML string.     | function | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>                                          | Loads a local file. | function | yes          |
| runJavaScript(String javaScript)                             | Future<void>                                          | Runs the given JavaScript in the context of the current page. | function | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>                                        | Runs the given JavaScript and returns the result. | function | yes          |
| canGoBack()                                                  | Future<bool>                                          | Whether it is possible to go back.      | function | yes          |
| canGoForward()                                               | Future<bool>                                          | Whether it is possible to go forward.      | function | yes          |
| goBack()                                                     | Future<void>                                          | Goes back in the history. | function | yes          |
| goForward()                                                  | Future<void>                                          | Goes forward in the history. | function | yes          |
| reload()                                                     | Future<void>                                          | Reloads the current page. | function | yes          |
| currentUrl()                                                 | Future<String?>                                       | Gets the current URL. | function | yes          |
| getTitle()                                                   | Future<String?>                                       | Gets the title of the current page. | function | yes          |
| setJavaScriptMode(JavaScriptMode mode)                       | Future<void>                                          | Sets the JavaScript execution mode. | function | yes          |
| setBackgroundColor(Color color)                              | Future<void>                                          | Sets the background color. | function | yes          |
| enableZoom(bool enabled)                                    | Future<void>                                          | Sets whether zoom is supported. | function | yes          |
| WebViewWidget({required WebViewController controller,})       | Widget                                                | A widget for displaying the WebView. | class    | yes          |

## 4. Known Issues

## 5. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/webview_flutter/webview_flutter/LICENSE). Feel free to use and contribute.

> Template version: v0.0.1
