
# webview_flutter

本项目基于 [webview_flutter](https://pub.dev/packages/webview_flutter/versions/4.14.1) 开发。

## 简介

webview_flutter_ohos 是 webview_flutter 在 OpenHarmony 平台上的联合实现。业务工程通常只需依赖 webview_flutter，插件会在 OpenHarmony 上自动注册 OhosWebViewPlatform 作为默认后端；当需要访问 OpenHarmony 专属能力时，可直接引入 webview_flutter_ohos 并通过 OhosWebViewController 等类型使用扩展 API。

当前实现覆盖以下核心能力：

- 页面加载与导航拦截
- JavaScript 执行、JavaScript Channel、控制台消息回调
- Cookie 管理、本地文件与 Flutter 资源加载
- HTTP 认证、可恢复 SSL 证书错误回调
- 地理位置权限回调、平台权限请求、全屏自定义视图处理

## 下载安装

进入工程目录并在 pubspec.yaml 中添加以下依赖，推荐业务应用优先依赖应用层包 webview_flutter：

```yaml
dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/webview_flutter/webview_flutter
      ref: TAG # 根据下方表格选择不同框架适配的TAG版本
```

如果需要直接调试 OHOS 平台实现，或需要调用平台扩展 API，也可以直接依赖当前包：

```yaml
dependencies:
  webview_flutter_ohos:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/webview_flutter/webview_flutter_ohos
      ref: TAG # 根据下方表格选择不同框架适配的TAG版本
```

```bash
flutter pub get
```


> TAG 命名规则：`原库版本-ohos-版本号-betax`，不同 TAG 之间的变更详见 `CHANGELOG.md`。
 
| Flutter 框架版本 | TAG 名称 | 分支名 |
| ----------------| ----------------------- | ---- |
| 3.47            | webview_flutter-v4.14.1-ohos-1.0.1 | oh-3.47.7 |

## 约束与限制

### 兼容性

在以下版本中已测试通过

1. Flutter: 3.47.7+ohos-0.0.1-canary1; SDK: 5.0.5(17); IDE: DevEco Studio: 26.0.0.621, ROM: 6.1.0.135 SP8;


### 权限要求

以下权限中有`system_basic` 权限，而默认的应用权限是 `normal` ，只能使用 `normal` 等级的权限，所以可能会在安装hap包时报错**9568289**，请参考 [文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#ZH-CN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) 修改应用等级为 `system_basic`

####  在 entry 目录下的module.json5中添加权限

打开 `entry/src/main/module.json5`，添加：

```yaml
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when":"inuse"
    }
  },
]
```

####  在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

```
{
  "string": [
    {
      "name": "network_reason",
      "value": "使用网络"
    },
  ]
}
```

## 使用示例
以下片段展示了在 OpenHarmony 上初始化 WebView、配置导航回调并挂载 `WebViewWidget` 的最小示例：

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';

class SimpleWebViewPage extends StatefulWidget {
  const SimpleWebViewPage({super.key});

  @override
  State<SimpleWebViewPage> createState() => _SimpleWebViewPageState();
}

class _SimpleWebViewPageState extends State<SimpleWebViewPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    // 使用OHOS创建参数，在不改变跨平台控制器 API 的前提下传入OHOS专属配置。
    controller = WebViewController.fromPlatformCreationParams(
      OhosWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint(message.message);
        },
      )
      ..loadRequest(Uri.parse('https://flutter.dev'));

    final PlatformWebViewController platformController = controller.platform;
    // 同一份 Dart 代码可能运行在其余平台，因此转换前必须先判断平台类型。
    if (platformController is OhosWebViewController) {
      // ArkWeb 详细调试日志仅建议在开发环境开启。
      OhosWebViewController.enableDebugging(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: controller),
    );
  }
}
```

以下扩展示例均基于上方示例中的 `controller`，可在初始化阶段（如 `initState` 或异步初始化方法内）调用，用于覆盖 SSL 证书错误处理、地理位置授权与全屏自定义视图等 OHOS 扩展场景。

### 扩展示例：SSL 证书错误处理

ArkWeb 遇到可恢复的证书错误时会触发 `onSSlAuthError` 回调，每个错误必须调用 `proceed()`（继续通信）或 `cancel()`（终止通信）之一；未注册回调时插件默认执行 cancel，不会静默放行证书错误：

```dart
final PlatformWebViewController platformController = controller.platform;
// 同一份 Dart 代码可能运行在其余平台，因此转换前必须先判断平台类型。
if (platformController is OhosWebViewController) {
  final OhosNavigationDelegate ohosDelegate =
      OhosNavigationDelegate(PlatformNavigationDelegateCreationParams());
  await ohosDelegate.setOnSSlAuthError((PlatformSslAuthError error) async {
    // 仅对明确可信的站点调用 proceed()，其余一律 cancel() 终止通信。
    if (error is OhosSslAuthError &&
        error.url.startsWith('https://trusted.example.com')) {
      await error.proceed();
    } else {
      await error.cancel();
    }
  });
  await platformController.setPlatformNavigationDelegate(ohosDelegate);
}
```

### 扩展示例：地理位置授权

网页调用 Geolocation API 且无既有权限状态时触发 `onShowPrompt` 回调，应用以 `GeolocationPermissionsResponse` 返回授权结果（仅安全源（如 https）会触发；非安全源自动拒绝）：

```dart
final PlatformWebViewController platformController = controller.platform;
// 同一份 Dart 代码可能运行在其余平台，因此转换前必须先判断平台类型。
if (platformController is OhosWebViewController) {
  await platformController.setGeolocationPermissionsPromptCallbacks(
    onShowPrompt: (GeolocationPermissionsRequestParams request) async {
      // allow：本次是否授权；retain：是否跨页面保留该授权。
      return GeolocationPermissionsResponse(allow: true, retain: false);
    },
    // 页面取消地理位置请求时回调，可在此关闭自定义授权弹窗。
    onHidePrompt: () {},
  );
}
```

### 扩展示例：全屏视频（自定义视图）

网页（如视频）进入/退出全屏时分别触发 `onShowCustomWidget`/`onHideCustomWidget` 回调；回调给出的 `widget` 即 `OhosCustomViewWidget`，不能手动实例化，只能在该回调中使用：

```dart
// 在 State 中声明字段，用于保存进入全屏时的自定义视图：
// Widget? fullscreenWidget;

final PlatformWebViewController platformController = controller.platform;
// 同一份 Dart 代码可能运行在其余平台，因此转换前必须先判断平台类型。
if (platformController is OhosWebViewController) {
  await platformController.setCustomWidgetCallbacks(
    // 网页进入全屏时回调，保存并展示自定义视图。
    onShowCustomWidget: (Widget widget, void Function() onCustomWidgetHidden) {
      setState(() => fullscreenWidget = widget);
    },
    // 网页退出全屏时回调，移除自定义视图、恢复 WebViewWidget 展示。
    onHideCustomWidget: () {
      setState(() => fullscreenWidget = null);
    },
  );
}

// build 中按需切换全屏视图与普通 WebView：
// body: fullscreenWidget ?? WebViewWidget(controller: controller),
```

## 使用说明
1. 业务应用优先依赖 `webview_flutter`，OpenHarmony 平台会自动使用 `webview_flutter_ohos` 作为默认实现。
2. 如果需要使用 `OhosWebViewController`、`OhosSslAuthError` 等平台扩展类型，再额外在 `pubspec.yaml` 中显式引入 `webview_flutter_ohos`。
3. 建议在 `StatefulWidget` 的 `initState` 中创建 controller，并在首次 `loadRequest` 之前完成 JavaScript 模式、导航回调、JavaScript Channel 和权限回调等初始化。
4. 页面展示阶段使用 `WebViewWidget(controller: controller)` 或 `PlatformWebViewWidget(...)` 挂载 WebView，不要在 `build` 中重复创建 controller。
5. 如需开启调试、处理 SSL 错误、地理位置授权或平台权限请求，可通过 `controller.platform` 获取 OpenHarmony 平台实现后调用对应扩展 API。
6. 业务工程接入时至少需要在 OpenHarmony 模块中声明 `ohos.permission.INTERNET`；若页面涉及定位、摄像头或麦克风，还需要同步声明对应系统权限。

## 接口说明
###  API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                                                         | return                       | Description                                   | Type     | ohos Support |
| ------------------------------------------------------------ | ---------------------------- | --------------------------------------------- | -------- | ------------ |
| NavigationRequestCallback([NavigationRequest](#NavigationRequest ) navigationRequest) | FutureOr<NavigationDecision> | 报告待处理导航请求的回调签名                  | function | yes          |
| PageEventCallback(String url)                                | Future<void>                 | 用于报告由本机web视图触发的页面事件的回调签名 | function | yes          |
| ProgressCallback(int progress)                               | Future<void>                 | 报告页面加载进度的回调签名                    | function | yes          |
| WebResourceErrorCallback([WebResourceError](#WebResourceError ) error) | Future<void>                 | 报告资源加载错误的回调的签名                  | function | yes          |

###  属性

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

#### WebViewWidget

| Name            | Description               | Type              | ohos Support |
| --------------- | ------------------------- | ----------------- | ------------ |
| controller      | 控制宿主平台提供的WebView | WebViewController | yes          |
| layoutDirection | 布局方向                  | TextDirection     | yes          |

#### WebViewController

| Name                                                         | return            | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformCreationParams([PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) params, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | 根据创建参数为特定对象构造一个[WebViewController]            | function | yes          |
| fromPlatform([PlatformWebViewController](#PlatformWebViewController) this.platform, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | 从特定平台实现构建[WebViewController]                        | function | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>      | 加载位于指定[绝对文件路径]上的文件                           | function | yes          |
| loadFlutterAsset(String key)                                 | Future<void>      | 加载pubspec.yaml文件中指定的Flutter资源                      | function | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>      | 加载提供的HTML字符串                                         | function | yes          |
| loadRequest(Uri uri, { [LoadRequestMethod](#LoadRequestMethod) method = LoadRequestMethod.get,  Map<String, String> headers = const <String, String>{}, Uint8List? body}) | Future<void>      | 发出特定的HTTP请求并在Web视图中加载响应                      | function | yes          |
| currentUrl()                                                 | Future<String?>   | 返回WebView正在显示的当前URL                                 | function | yes          |
| canGoBack()                                                  | Future<bool>      | 检查是否有历史记录项                                         | function | yes          |
| canGoForward()                                               | Future<bool>      | 检查是否有转发历史记录项                                     | function | yes          |
| goBack()                                                     | Future<void>      | 回到这个WebView的历史                                        | function | yes          |
| goForward()                                                  | Future<void>      | 在这个WebView的历史中前进                                    | function | yes          |
| reload()                                                     | Future<void>      | 重新加载当前URL                                              | function | yes          |
| setNavigationDelegate([NavigationDelegate](#NavigationDelegate ) delegate) | Future<void>      | 设置包含以下回调方法的[NavigationDelegate]                   | function | yes          |
| clearCache()                                                 | Future<void>      | 清除WebView使用的所有缓存                                    | function | yes          |
| clearLocalStorage()                                          | Future<void>      | 清除WebView使用的本地存储                                    | function | yes          |
| runJavaScript(String javaScript)                             | Future<void>      | 在当前页面的上下文中运行给定的JavaScript                     | function | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>    | 在当前页面的上下文中运行给定的JavaScript，并返回结果         | function | yes          |
| addJavaScriptChannel(String name, {required void Function(JavaScriptMessage) onMessageReceived}) | Future<void>      | 将新的JavaScript频道添加到已启用的频道集中                   | function | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>      | 从已启用的频道集中删除具有匹配名称的JavaScript频道           | function | yes          |
| getTitle()                                                   | Future<String?>   | 当前加载页面的标题                                           | function | yes          |
| scrollTo(int x, int y)                                       | Future<void>      | 设置此视图的滚动位置                                         | function | yes          |
| scrollBy(int x, int y)                                       | Future<void>      | 移动此视图的滚动位置                                         | function | yes          |
| getScrollPosition()                                          | Future<Offset>    | 返回此视图的当前滚动位置                                     | function | yes          |
| enableZoom(bool enabled)                                     | Future<void>      | 是否支持使用屏幕上的缩放控件和手势进行缩放                   | function | yes          |
| setBackgroundColor(Color color)                              | Future<void>      | 设置此视图的当前背景颜色                                     | function | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>      | 设置WebView使用的JavaScript执行模式                          | function | yes          |
| setUserAgent(String? userAgent)                              | Future<void>      | 设置用于HTTP“User-Agent:”请求标头的值                        | function | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>      | 设置一个回调，通知主机应用程序写入JavaScript控制台的任何日志消息 | function | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript alert() 对话框 | function | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript confirm() 对话框 | function | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript prompt() 对话框 | function | yes          |
| getUserAgent()                                               | Future<String?>   | 获取用于HTTP“User-Agent:”请求标头的值                        | function | yes          |
| setVerticalScrollBarEnabled(bool enabled)                    | Future<void>      | 控制是否绘制竖向滚动条。ArkWeb 未提供滚动条显隐 API，在 OpenHarmony 上调用会抛出 `UnimplementedError` | function | no           |
| setHorizontalScrollBarEnabled(bool enabled)                  | Future<void>      | 控制是否绘制横向滚动条。ArkWeb 未提供滚动条显隐 API，在 OpenHarmony 上调用会抛出 `UnimplementedError` | function | no           |
| supportsSetScrollBarsEnabled()                               | Future<bool>      | 报告当前平台是否实现滚动条开关方法；在 OpenHarmony 上返回 `false` | function | no           |
| setOverScrollMode([WebViewOverScrollMode](#WebViewOverScrollMode) mode) | Future<void> | 设置过度滚动模式。ArkWeb 仅支持 `never` 和 `always`，`ifContentScrolls` 会映射为 `never`（见已知问题） | function | partially    |

#### NavigationDelegate

| Name                       | Description                                        | Type     | ohos Support |
| -------------------------- | -------------------------------------------------- | -------- | ------------ |
| fromPlatformCreationParams | 根据特定平台的创建参数构造一个[NavigationDelegate] | function | yes          |
| fromPlatform               | 从特定的平台实现构造一个[NavigationDelegate]       | function | yes          |

#### HttpAuthRequest

| Name                                                         | return       | Description        | Type     | ohos Support |
| ------------------------------------------------------------ | ------------ | ------------------ | -------- | ------------ |
| onProceed([WebViewCredential](#WebViewCredential ) credential) | Future<void> | 用于身份验证的回调 | function | yes          |
| onCancel()                                                   | Future<void> | 取消身份验证的回调 | function | yes          |
| host                                                         |              | 需要身份验证的主机 | String   | yes          |
| realm                                                        |              | 需要身份验证的可选领域 | String? | yes          |

#### HttpResponseError

| Name | Description | Type | ohos Support |
| --- | --- | --- | --- |
| request | 与 HTTP 错误关联的请求（如可用） | WebResourceRequest? | yes |
| response | 包含失败状态码的 HTTP 响应 | WebResourceResponse? | yes |

#### WebResourceRequest

| Name | Description | Type | ohos Support |
| --- | --- | --- | --- |
| uri | 请求资源的 URI | Uri | yes |

#### WebResourceResponse

| Name | Description | Type | ohos Support |
| --- | --- | --- | --- |
| uri | 与响应关联的 URI（如可用） | Uri? | yes |
| statusCode | 服务端返回的 HTTP 状态码 | int | yes |

#### JavaScriptAlertDialogRequest

| Name    | Description           | Type   | ohos Support |
| ------- | --------------------- | ------ | ------------ |
| message | 要在窗口中显示的消息  | String | yes          |
| url     | 请求对话框的页面的URL | String | yes          |

#### JavaScriptConfirmDialogRequest

| Name    | Description           | Type   | ohos Support |
| ------- | --------------------- | ------ | ------------ |
| message | 要在窗口中显示的消息  | String | yes          |
| url     | 请求对话框的页面的URL | String | yes          |

#### JavaScriptConsoleMessage

| Name    | Description                | Type   | ohos Support |
| ------- | -------------------------- | ------ | ------------ |
| level   | JavaScript日志消息的严重性 | JavaScriptLogLevel | yes          |
| message | 写入控制台的消息           | String | yes          |

#### JavaScriptMessage

| Name    | Description                  | Type   | ohos Support |
| ------- | ---------------------------- | ------ | ------------ |
| message | JavaScript代码发送的消息内容 | String | yes          |

#### JavaScriptChannelParams

传给 `WebViewController.addJavaScriptChannel`（以及平台层
`PlatformWebViewController.addJavaScriptChannel`）的参数。

| Name              | Description                                   | Type      | ohos Support |
| ----------------- | -------------------------------------- | -------- | ------------ |
| name              | 通道暴露给 JavaScript 的名称           | String   | yes          |
| onMessageReceived | JavaScript 每次调用 `postMessage` 时触发的回调 | Function | yes          |

#### JavaScriptTextInputDialogRequest

| Name        | Description                      | Type    | ohos Support |
| ----------- | -------------------------------- | ------- | ------------ |
| message     | 要在窗口中显示的消息             | String  | yes          |
| url         | 请求对话框的页面的URL            | String  | yes          |
| defaultText | 要在文本输入字段中显示的初始文本 | String? | yes          |

#### NavigationRequest

| Name        | Description                                | Type   | ohos Support |
| ----------- | ------------------------------------------ | ------ | ------------ |
| url         | 待处理导航请求的URL                        | String | yes          |
| isMainFrame | 指示请求是在网站的主框架还是子框架中发出的 | bool   | yes          |

#### PlatformWebViewController

| Name                                                         | return                                                  | Description                                                  | Type                                    | ohos Support |
| ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------- | ------------ |
| [PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) | [PlatformWebViewController](#PlatformWebViewController) | 用于初始化[PlatformWebViewController]的参数                  | PlatformWebViewControllerCreationParams | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>                                            | 如果[absoluteFilePath]不存在，则抛出ArgumentError            | function                                | yes          |
| loadFileWithParams([LoadFileParams](#LoadFileParams) params) | Future<void>                                            | 加载 [params] 描述的本地文件；OpenHarmony 扩展 `OhosLoadFileParams` 额外携带请求头 | function                                | yes          |
| loadFlutterAsset(String key)                                 | Future<void>                                            | 加载pubspec.yaml文件中指定的Flutter资源                      | function                                | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                            | 加载提供的HTML字符串                                         | function                                | yes          |
| loadRequest([LoadRequestParams](#LoadRequestParams) params)  | Future<void>                                            | 发出特定的HTTP请求并在Web视图中加载响应                      | function                                | yes          |
| currentUrl()                                                 | Future<String?>                                         | 返回WebView正在显示的当前URL                                 | function                                | yes          |
| canGoBack()                                                  | Future<bool>                                            | 检查是否有历史记录项                                         | function                                | yes          |
| canGoForward()                                               | Future<bool>                                            | 检查是否有转发历史记录项                                     | function                                | yes          |
| goBack()                                                     | Future<void>                                            | 回到这个WebView的历史                                        | function                                | yes          |
| goForward()                                                  | Future<void>                                            | 在这个WebView的历史中前进                                    | function                                | yes          |
| reload()                                                     | Future<void>                                            | 重新加载当前URL                                              | function                                | yes          |
| clearCache()                                                 | Future<void>                                            | 清除WebView使用的所有缓存                                    | function                                | yes          |
| clearLocalStorage()                                          | Future<void>                                            | 清除WebView使用的本地存储                                    | function                                | yes          |
| setPlatformNavigationDelegate([PlatformNavigationDelegate](#PlatformNavigationDelegate ) handler) | Future<void>                                            | 设置[PlatformNavigationDelegate]，其中包含在导航事件期间调用的回调方法 | function                                | yes          |
| runJavaScript(String javaScript)                             | Future<void>                                            | 在当前页面的上下文中运行给定的JavaScript                     | function                                | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>                                          | 在当前页面的上下文中运行给定的JavaScript，并返回结果         | function                                | yes          |
| addJavaScriptChannel(String name, {required void Function(JavaScriptMessage) onMessageReceived}) | Future<void>                                            | 将新的JavaScript频道添加到已启用的频道集中                   | function                                | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>                                            | 从已启用的频道集中删除具有匹配名称的JavaScript频道           | function                                | yes          |
| getTitle()                                                   | Future<String?>                                         | 当前加载页面的标题                                           | function                                | yes          |
| scrollTo(int x, int y)                                       | Future<void>                                            | 设置此视图的滚动位置                                         | function                                | yes          |
| scrollBy(int x, int y)                                       | Future<void>                                            | 移动此视图的滚动位置                                         | function                                | yes          |
| getScrollPosition()                                          | Future<Offset>                                          | 返回此视图的当前滚动位置                                     | function                                | yes          |
| enableZoom(bool enabled)                                     | Future<void>                                            | 是否支持使用屏幕上的缩放控件和手势进行缩放                   | function                                | yes          |
| setBackgroundColor(Color color)                              | Future<void>                                            | 设置此视图的当前背景颜色                                     | function                                | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>                                            | 设置WebView使用的JavaScript执行模式                          | function                                | yes          |
| setUserAgent(String? userAgent)                              | Future<void>                                            | 设置用于HTTP“User-Agent:”请求标头的值                        | function                                | yes          |
| setOnPlatformPermissionRequest(void Function(PlatformWebViewPermissionRequest request) onPermissionRequest) | Future<void>                                            | 设置一个回调，通知宿主应用程序web内容正在请求访问指定资源的权限 | function                                | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>                                            | 设置一个回调，通知主机应用程序写入JavaScript控制台的任何日志消息 | function                                | yes          |
| setOnScrollPositionChange(void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange) | Future<void>                                            | 设置内容偏移更改的侦听器                                     | function                                | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript alert() 对话框 | function                                | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript confirm() 对话框 | function                                | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript prompt() 对话框 | function                                | yes          |
| getUserAgent()                                               | Future<String?>                                         | 获取用于HTTP“User-Agent:”请求标头的值                        | function                                | yes          |
| setVerticalScrollBarEnabled(bool enabled)                    | Future<void>                                            | OpenHarmony 上未实现；ArkWeb 未提供滚动条显隐 API，基类实现抛出 `UnimplementedError` | function                                | no           |
| setHorizontalScrollBarEnabled(bool enabled)                  | Future<void>                                            | OpenHarmony 上未实现；ArkWeb 未提供滚动条显隐 API，基类实现抛出 `UnimplementedError` | function                                | no           |
| supportsSetScrollBarsEnabled()                               | bool                                                    | 在 OpenHarmony 上返回 `false` | function                                | no           |
| setOverScrollMode([WebViewOverScrollMode](#WebViewOverScrollMode) mode) | Future<void>                                  | 支持 `never` 和 `always`；`ifContentScrolls` 会映射为 `never`（见已知问题） | function                    | partially    |

#### PlatformWebViewControllerCreationParams

`PlatformWebViewController` 的基类创建参数。该类不声明任何跨平台字段：
它是为平台实现通过子类提供平台专属参数而保留的扩展点。OpenHarmony 实现扩展了
`OhosWebViewControllerCreationParams.isAllowFullScreenRotate`（见
[OpenHarmony 扩展 API](#openharmony-扩展-api)）。应用通常构造当前平台的
子类并传给 `WebViewController.fromPlatformCreationParams`。

#### PlatformNavigationDelegateCreationParams

`PlatformNavigationDelegate` 的基类创建参数。与
`PlatformWebViewControllerCreationParams` 一样不声明跨平台字段；OpenHarmony 实现直接
接受默认实例。将该实例传给 `NavigationDelegate.fromPlatformCreationParams` 即可。

### OpenHarmony 扩展 API

以下扩展 API 通过 `controller.platform`（`OhosWebViewController`）或平台导航代理（`OhosNavigationDelegate`）调用，仅存在于 OpenHarmony 平台实现中；基础能力仍通过跨平台的 `WebViewController`/`NavigationDelegate` 使用。

| Name | return | Description | Type |
| ---- | ------ | ----------- | ---- |
| OhosWebViewController.enableDebugging(bool enabled) | void | 开启/关闭 ArkWeb 调试日志 | static function |
| OhosWebViewController.setOnShowFileSelector(Future<List<String>> Function([FileSelectorParams](#FileSelectorParams) params)? onShowFileSelector) | Future<void> | 注册网页文件选择回调，回调返回值回传给网页所选文件的 URI 列表 | function |
| OhosWebViewController.setGeolocationPermissionsPromptCallbacks({onShowPrompt, onHidePrompt}) | Future<void> | 注册地理位置权限弹窗回调（见 [GeolocationPermissionsRequestParams](#GeolocationPermissionsRequestParams)） | function |
| OhosWebViewController.setCustomWidgetCallbacks({onShowCustomWidget, onHideCustomWidget}) | Future<void> | 注册全屏自定义视图（如视频全屏）回调，回调参数中的 Widget 为 [OhosCustomViewWidget](#OhosCustomViewWidget) | function |
| OhosWebViewController.isWebViewFeatureSupported([WebViewFeatureType](#WebViewFeatureType) featureType) | Future<bool> | 查询设备是否支持指定 WebView 特性 | function |
| OhosWebViewController.setPaymentRequestEnabled(bool enabled) | Future<void> | 设置是否启用 Payment Request API；ArkWeb 暂无真实后端，调用前应先经 `isWebViewFeatureSupported` 确认 | function |
| OhosWebViewController.setMixedContentMode(MixedContentMode mode) | Future<void> | 设置混合内容（HTTP/HTTPS）处理策略 | function |
| OhosWebViewController.setTextZoom(int textZoom) | Future<void> | 设置页面文本缩放百分比 | function |
| OhosNavigationDelegate.setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) | Future<void> | 注册可恢复 SSL 证书错误回调，错误对象为 OhosSslAuthError | function |

### WebViewPlatform

`WebViewPlatform.instance` 表示当前注册的平台后端，并负责创建平台控制器、导航
代理、Cookie 管理器和平台视图。业务通常应使用 `WebViewController` 与
`WebViewWidget` 公共封装；只有访问平台扩展前才需要判断平台实例类型。

#### WebViewOverScrollMode

| Name | Description | ohos Support  |
| --- | --- | --- |
| `always` | 允许过度滚动效果 | 映射为 ArkWeb `always` |
| `ifContentScrolls` | 仅在内容可滚动时启用 | ArkWeb 无等价值，映射为 `never` |
| `never` | 禁用过度滚动效果 | 映射为 ArkWeb `never` |

平台异步操作返回 `Future`，调用方应等待完成并处理平台异常。SSL、权限、身份验证
和 JavaScript 对话框回调必须明确执行接受、拒绝、取消或完成操作。

#### PlatformWebViewPermissionRequest

| Name  | return       | Description          | Type                          | ohos Support |
| ----- | ------------ | -------------------- | ----------------------------- | ------------ |
| types |              | 已请求访问所有资源   | WebViewPermissionResourceType | yes          |
| grant | Future<void> | 为请求的资源授予权限 | function                      | yes          |
| deny  | Future<void> | 拒绝所请求资源的权限 | function                      | yes          |

#### LoadRequestParams

| Name    | Description            | Type                | ohos Support |
| ------- | ---------------------- | ------------------- | ------------ |
| uri     | 请求的URI              | Uri                 | yes          |
| method  | 用于发出请求的HTTP方法 | LoadRequestMethod   | yes          |
| headers | 请求的标头             | Map<String, String> | yes          |
| body    | 请求的HTTP正文         | Uint8List?          | yes          |

#### LoadFileParams

`WebViewController.loadFileWithParams` 的参数。

| Name             | Description                   | Type   | ohos Support |
| ---------------- | ---------------------- | ------ | ------------ |
| absoluteFilePath | 要加载的本地 HTML 文件路径 | String | yes          |

#### PlatformNavigationDelegate

| Name | Description | return | ohos Support |
| --- | --- | --- | --- |
| setOnNavigationRequest | 设置导航决策回调 | Future<void> | yes |
| setOnPageStarted | 设置页面开始回调 | Future<void> | yes |
| setOnPageFinished | 设置页面完成回调 | Future<void> | yes |
| setOnHttpError | 设置 HTTP 响应错误回调 | Future<void> | yes |
| setOnProgress | 设置加载进度回调 | Future<void> | yes |
| setOnWebResourceError | 设置资源错误回调 | Future<void> | yes |
| setOnUrlChange | 设置 URL 变化回调 | Future<void> | yes |
| setOnHttpAuthRequest | 设置 HTTP 回调 | Future<void> | yes |
| setOnSSlAuthError | 设置可恢复 SSL 错误回调 | Future<void> | yes |

#### WebViewPermissionRequest

| Name     | return       | Description                                      | Type                             | ohos Support |
| -------- | ------------ | ------------------------------------------------ | -------------------------------- | ------------ |
| platform |              | 当前平台的[PlatformWebViewPermissionRequest]实现 | PlatformWebViewPermissionRequest | yes          |
| types    |              | 已请求访问所有资源                               | WebViewPermissionResourceType    | yes          |
| grant()  | Future<void> | 为请求的资源授予权限                             | function                         | yes          |
| deny()   | Future<void> | 拒绝所请求资源的权限                             | function                         | yes          |

#### PlatformWebViewWidgetCreationParams

| Name               | Description                                  | Type                                       | ohos Support |
| ------------------ | -------------------------------------------- | ------------------------------------------ | ------------ |
| key                | Key 控制一个控件如何替换树中的另一个控件     | Key?                                       | yes          |
| controller         | 允许控制本机web的[PlatformWebViewController] | PlatformWebViewController                  | yes          |
| layoutDirection    | 用于嵌入式WebView的布局方向                  | TextDirection                              | yes          |
| gestureRecognizers | “手势识别器”指定web视图应使用哪些手势        | Set<Factory<OneSequenceGestureRecognizer>> | yes          |

#### UrlChange

| Name | Description    | Type    | ohos Support |
| ---- | -------------- | ------- | ------------ |
| url  | web视图的新url | String? | yes          |

#### ScrollPositionChange

`NavigationDelegate.setOnScrollPositionChange` 回调接收的值。

| Name | Description                   | Type | ohos Support |
| ---- | ---------------------- | ---- | ------------ |
| x    | WebView 的水平滚动偏移 | int  | yes          |
| y    | WebView 的垂直滚动偏移 | int  | yes          |

#### WebResourceError

| Name           | Description                            | Type                  | ohos Support |
| -------------- | -------------------------------------- | --------------------- | --------- |
| errorCode      | 错误的整数代码                         | int                   | yes       |
| description    | 错误描述                               | String                | yes       |
| errorType      | 可确定时返回跨平台错误类别             | WebResourceErrorType? | yes       |
| isForMainFrame | 失败请求是否属于主框架                 | bool?                 | yes       |
| url            | 加载失败的 URL（如可用）               | String?               | yes       |

#### WebViewCookie

| Name       | Description    | Type   | ohos Support |
| ---------- | -------------- | ------ | ------------ |
| name       | cookie的名称   | String | yes          |
| value      | cookie的值     | String | yes          |
| domain     | cookie的域值   | String | yes          |
| path = '/' | cookie的路径值 | String | yes          |

#### WebViewCookieManager

| Name | return | Description | Type | ohos Support |
| --- | --- | --- | --- | --- |
| WebViewCookieManager() | WebViewCookieManager | 构造绑定当前平台实现的 Cookie 管理器 | function | yes |
| clearCookies() | Future<bool> | 清除进程级 ArkWeb Cookie 存储的全部 Cookie，并返回是否有 Cookie 被移除 | function | yes |
| setCookie([WebViewCookie](#WebViewCookie) cookie) | Future<void> | 保存给定 Cookie；`path` 不合法时在写入前抛出 `ArgumentError` | function | yes |
| getCookies(Uri url) | Future<List<WebViewCookie>> | 返回给定 URL 的 Cookie。ArkWeb 不支持 Cookie 枚举，在 OpenHarmony 上调用会抛出 `UnimplementedError` | function | no |

#### SslAuthError

| Name | return | Description | Type | ohos Support |
| --- | --- | --- | --- | --- |
| platform |  | 当前平台的 [PlatformSslAuthError] 实现 | PlatformSslAuthError | yes |
| certificate |  | 与错误关联的证书；ArkWeb 不提供证书链字节 | X509Certificate? | partially |
| description |  | 原生回调提供的证书错误可读描述 | String | yes |
| cancel() | Future<void> | 指示 WebView 终止与服务端的通信 | function | yes |
| proceed() | Future<void> | 指示 WebView 忽略错误并继续通信 | function | yes |

`cancel()`/`proceed()` 会将决策透传到原生 ArkWeb SSL 错误处理器；每个错误
只能调用其中一个。未注册 `onSSlAuthError` 回调时，插件默认执行 cancel，
未处理的证书错误不会被静默放行。ArkWeb 不提供证书链字节，`certificate`
保持为 `null`，证书颁发者以提示形式附加在 `description` 中。详见
[已知问题](#已知问题)。

#### X509Certificate

附加到 [SslAuthError] 的证书数据。

| Name | Description                                  | Type       | ohos Support |
| ---- | ------------------------------------- | ---------- | ------------ |
| data | DER 编码的证书字节；ArkWeb 不提供证书链字节，OHOS 上为 `null` | Uint8List? | partially |

#### WebViewCredential

| Name     | Description | Type   | ohos Support |
| -------- | ----------- | ------ | ------------ |
| user     | 用户名      | String | yes          |
| password | 密码        | String | yes          |

#### GeolocationPermissionsRequestParams

`OhosWebViewController.setGeolocationPermissionsPromptCallbacks` 的 `onShowPrompt` 回调接收的请求参数。

| Name   | Description                                                      | Type   | ohos Support |
| ------ | ---------------------------------------------------------------- | ------ | ------------ |
| origin | 发起地理位置权限请求的页面源（origin）；仅安全源（如 https）会触发该回调 | String | yes          |

#### GeolocationPermissionsResponse

`onShowPrompt` 回调需要返回的应答，用于告知 WebView 本次地理位置请求的处理结果。

| Name                                                            | return | Description                                                | Type     | ohos Support |
| --------------------------------------------------------------- | ------ | ---------------------------------------------------------- | -------- | ------------ |
| GeolocationPermissionsResponse({required allow, required retain}) | GeolocationPermissionsResponse | 构造应答：`allow` 本次是否授权，`retain` 是否跨页面保留权限 | function | yes          |
| allow                                                            |        | 是否允许该源使用 Geolocation API                           | bool     | yes          |
| retain                                                           |        | 权限是否保留到当前页面生命周期之后                         | bool     | yes          |

#### FileSelectorMode

文件选择器的选择模式，见 `OhosWebViewController.setOnShowFileSelector`。

| Name         | Description                            | Type | ohos Support |
| ------------ | -------------------------------------- | ---- | ------------ |
| open         | 选择单个已存在的文件                   | enum | yes          |
| openMultiple | 与 `open` 类似，但允许同时选择多个文件 | enum | yes          |
| save         | 允许选择一个尚不存在的文件并保存       | enum | yes          |

#### FileSelectorParams

`OhosWebViewController.setOnShowFileSelector` 回调接收的文件选择参数。

| Name             | Description                                | Type             | ohos Support |
| ---------------- | ------------------------------------------ | ---------------- | ------------ |
| isCaptureEnabled | 是否优先使用摄像头/麦克风等直接采集媒体   | bool             | yes          |
| acceptTypes      | 可接受的 MIME 类型列表                     | List<String>     | yes          |
| filenameHint     | 默认文件名提示（如页面指定，否则为 null） | String?          | yes          |
| mode             | 文件选择模式                               | FileSelectorMode | yes          |

#### WebViewFeatureType

`OhosWebViewController.isWebViewFeatureSupported` 查询的 WebView 特性类型。

| Name            | Description                                                                                              | Type | ohos Support |
| --------------- | -------------------------------------------------------------------------------------------------------- | ---- | ------------ |
| paymentRequest | Payment Request API 特性；当前 OHOS 实现固定返回不支持（ArkWeb 暂未提供公开的 Payment Request 能力接口） | enum | yes          |

#### OhosWebViewWidgetCreationParams

`OhosWebViewWidget`（OHOS 平台 `PlatformWebViewWidget` 实现）的创建参数；基类字段（key、controller、layoutDirection、gestureRecognizers）见 [PlatformWebViewWidgetCreationParams](#PlatformWebViewWidgetCreationParams)。

| Name                                                       | return | Description                                  | Type                       | ohos Support |
| ---------------------------------------------------------- | ------ | -------------------------------------------- | -------------------------- | ------------ |
| displayWithHybridComposition                               |        | 是否以混合合成模式渲染 WebView，默认 `false` | bool                       | yes          |
| platformViewsServiceProxy                                  |        | 平台视图服务代理（仅测试用途）               | PlatformViewsServiceProxy | yes          |
| fromPlatformWebViewWidgetCreationParams(params)            | OhosWebViewWidgetCreationParams | 由平台基类创建参数构造 OHOS 创建参数         | function                   | yes          |

#### OhosCustomViewWidget

网页进入全屏（如视频全屏）时承载原生视图的 Widget。该类型不能手动实例化，仅由 `OhosWebViewController.setCustomWidgetCallbacks` 的 `onShowCustomWidget` 回调提供给应用，外部只应将其作为普通 `Widget` 使用。

| Name                      | return | Description                                  | Type                      | ohos Support |
| ------------------------- | ------ | -------------------------------------------- | ------------------------- | ------------ |
| customView                |        | 全屏展示的原生视图                           | ohos_webview.View         | yes          |
| controller                |        | 控制原生 WebView 的平台控制器                | PlatformWebViewController | yes          |
| platformViewsServiceProxy |        | 平台视图服务代理（仅测试用途）               | PlatformViewsServiceProxy | yes          |
| build(context)            | Widget | 构建承载原生视图的平台视图                   | function                  | yes          |

#### OhosWebViewCookieManagerCreationParams

`OhosWebViewCookieManager`（OHOS 平台 Cookie 管理器实现）的创建参数。

| Name                                                       | return | Description                                                  | Type     | ohos Support |
| ---------------------------------------------------------- | ------ | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformWebViewCookieManagerCreationParams(params)      | OhosWebViewCookieManagerCreationParams | 由平台基类 `PlatformWebViewCookieManagerCreationParams` 构造 OHOS 创建参数 | function | yes          |

#### WebViewPermissionResourceType

| Name                                     | Description                | Type  | ohos Support |
| ---------------------------------------- | -------------------------- | ----- | ------------ |
| WebViewPermissionResourceType.camera     | 一种可以捕获视频的媒体设备 | enums | yes          |
| WebViewPermissionResourceType.microphone | 一种可以捕获音频的媒体设备 | enums | yes          |

#### JavaScriptMode

| Name                        | Description              | Type | ohos Support |
| --------------------------- | ------------------------ | ---- | ------------ |
| JavaScriptMode.disabled     | JavaScript执行已禁用     | enum | yes          |
| JavaScriptMode.unrestricted | JavaScript的执行不受限制 | enum | yes          |

#### JavaScriptLogLevel

| Name                       | Description                                            | Type | ohos Support |
| -------------------------- | ------------------------------------------------------ | ---- | ------------ |
| JavaScriptLogLevel.error   | 表示通过`console.error`方法的“error”事件记录了错误消息 | enum | yes          |
| JavaScriptLogLevel.warning | 表示使用`console.warning`方法记录了警告消息            | enum | yes          |
| JavaScriptLogLevel.debug   | 表示使用`console.debug `方法记录了调试消息             | enum | yes          |
| JavaScriptLogLevel.info    | 表示使用`console.info`方法记录了一条信息性消息         | enum | yes          |
| JavaScriptLogLevel.log     | 表示使用`console.log `方法记录了日志消息               | enum | yes          |

#### LoadRequestMethod

| Name                   | Description   | Type | ohos Support |
| ---------------------- | ------------- | ---- | ------------ |
| LoadRequestMethod.get  | HTTP GET方法  | enum | yes          |
| LoadRequestMethod.post | HTTP POST方法 | enum | yes          |

#### NavigationDecision

| Name                        | Description  | Type | ohos Support |
| --------------------------- | ------------ | ---- | ------------ |
| NavigationDecision.prevent  | 阻止导航发生 | enum | yes          |
| NavigationDecision.navigate | 允许导航发生 | enum | yes          |

#### WebResourceErrorType

| Name                                                   | Description                          | Type | ohos Support |
| ------------------------------------------------------ | ------------------------------------ | ---- | ------------ |
| WebResourceErrorType.authentication                    | 服务器上的用户身份验证失败           | enum | yes          |
| WebResourceErrorType.badUrl                            | URL格式错误                          | enum | yes          |
| WebResourceErrorType.connect                           | 无法连接到服务器                     | enum | yes          |
| WebResourceErrorType.failedSslHandshake                | 执行SSL握手失败                      | enum | yes          |
| WebResourceErrorType.file                              | 通用文件错误                          | enum | yes          |
| WebResourceErrorType.fileNotFound                      | 通用文件错误                         | enum | yes          |
| WebResourceErrorType.hostLookup                        | 服务器或代理主机名查找失败           | enum | yes          |
| WebResourceErrorType.io                                | 无法读取或写入服务器                 | enum | yes          |
| WebResourceErrorType.proxyAuthentication               | 代理上的用户身份验证失败             | enum | yes          |
| WebResourceErrorType.redirectLoop                      | 重定向太多                           | enum | yes          |
| WebResourceErrorType.timeout                           | 连接超时                             | enum | yes          |
| WebResourceErrorType.tooManyRequests                   | 加载期间请求太多                     | enum | yes          |
| WebResourceErrorType.unknown                           | 一般错误                             | enum | yes          |
| WebResourceErrorType.unsafeResource                    | 安全浏览取消了资源加载               | enum | yes          |
| WebResourceErrorType.unsupportedAuthScheme             | 不支持的身份验证方案（非基本或摘要） | enum | yes          |
| WebResourceErrorType.unsupportedScheme                 | 不支持的URI方案                      | enum | yes          |
| WebResourceErrorType.webContentProcessTerminated       | web内容进程已终止                    | enum | yes          |
| WebResourceErrorType.webViewInvalidated                | web视图已无效                        | enum | yes          |
| WebResourceErrorType.javaScriptExceptionOccurred       | 发生JavaScript异常                   | enum | yes          |
| WebResourceErrorType.javaScriptResultTypeIsUnsupported | 无法返回JavaScript执行的结果         | enum | yes          |

## 遗留问题

无

## 其他

无

## 目录结构

```text
webview_flutter_ohos/
|---- .github/                         # 技能模板与文档规范
|---- example/                         # Flutter 示例工程
|     |---- assets/                    # 示例资源
|     |---- lib/                       # 示例 Dart 代码
|     |---- ohos/                      # 示例应用的 OpenHarmony 工程
|     |---- pubspec.yaml               # 示例工程依赖配置
|     |---- README.md                  # 示例说明
|---- lib/                             # 包对外导出的 Dart 入口与核心实现
|     |---- src/                       # OpenHarmony 控制器、平台实现、Pigeon 绑定与兼容层
|     |---- webview_flutter_ohos.dart  # 当前包主入口
|---- ohos/                            # 当前包的 OpenHarmony HAR 工程
|     |---- src/
|     |     |---- main/
|     |           |---- ets/           # ArkTS 侧入口与实现
|     |           |---- module.json5   # HAR 模块配置
|---- AUTHORS                          # 作者列表
|---- CHANGELOG.md                     # 版本变更记录
|---- LICENSE                          # 开源协议
|---- pubspec.yaml                     # 包配置文件
|---- README.CN.md                     # 中文说明文档
|---- README.md                        # 英文说明文档
|---- SKILL.md                         # 当前库文档技能说明
```

##  贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues)；当然，也非常欢迎发 [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) 共建。

##  开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/CPF-Flutter/flutter_packages/blob/oh-3.47.7/packages/webview_flutter/webview_flutter/LICENSE) ，请自由地享受和参与开源。

