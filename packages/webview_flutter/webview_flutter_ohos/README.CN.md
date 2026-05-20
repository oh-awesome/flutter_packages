
# webview_flutter

本项目基于 [webview_flutter](https://pub.dev/packages/webview_flutter/versions/4.13.0) 开发。

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
      ref: br_webview_flutter-v4.13.1_ohos
```

如果需要直接调试 OHOS 平台实现，或需要调用平台扩展 API，也可以直接依赖当前包：：

```yaml
dependencies:
  webview_flutter_ohos:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/webview_flutter/webview_flutter_ohos
      ref: br_webview_flutter-v4.13.1_ohos
```

```bash
flutter pub get
```

## 约束与限制

### 兼容性

在以下版本中已测试通过

1. Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;

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
    if (platformController is OhosWebViewController) {
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
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript alert（）对话框 | function | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript confirm（）对话框 | function | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>      | 设置一个回调，通知宿主应用程序网页要显示JavaScript prompt（）对话框 | function | yes          |
| getUserAgent()                                               | Future<String?>   | 获取用于HTTP“User-Agent:”请求标头的值                        | function | yes          |

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
| realm                                                        |              | 需要身份验证的领域 | String   | yes          |

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
| level   | JavaScript日志消息的严重性 | String | yes          |
| message | 写入控制台的消息           | String | yes          |

#### JavaScriptMessage

| Name    | Description                  | Type   | ohos Support |
| ------- | ---------------------------- | ------ | ------------ |
| message | JavaScript代码发送的消息内容 | String | yes          |

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
| loadFlutterAsset(String key)                                 | Future<void>                                            | 加载pubspec.yaml文件中指定的Flutter资源                      | function                                | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                            | 加载提供的HTML字符串                                         | function                                | yes          |
| loadRequest([LoadRequestParams](#LoadRequestParams) params)  | Future<void>                                            | 发出特定的HTTP请求并在Web视图中加载响应                      | function                                | yes          |
| currentUrl()                                                 | Future<void>                                            | 返回WebView正在显示的当前URL                                 | function                                | yes          |
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
| addJavaScriptChannel(String name, {required void Function(String  JavaScriptMessage) onMessageReceived}) | Future<void>                                            | 将新的JavaScript频道添加到已启用的频道集中                   | function                                | yes          |
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
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript alert（）对话框 | function                                | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript confirm（）对话框 | function                                | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>                                            | 设置一个回调，通知宿主应用程序网页要显示JavaScript prompt（）对话框 | function                                | yes          |
| getUserAgent()                                               | Future<String?>                                         | 获取用于HTTP“User-Agent:”请求标头的值                        | function                                | yes          |

#### PlatformWebViewControllerCreationParams

#### PlatformNavigationDelegateCreationParams

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

#### PlatformNavigationDelegate

| Name    | Description            | Type                | ohos Support |
| ------- | ---------------------- | ------------------- | ------------ |
| params  | 请求的URI              | Uri                 | yes          |
| method  | 用于发出请求的HTTP方法 | LoadRequestMethod   | yes          |
| headers | 请求的标头             | Map<String, String> | yes          |
| body    | 请求的HTTP正文         | Uint8List?          | yes          |

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
| key                | IControl控制一个控件如何替换树中的另一个控件 | String                                     | yes          |
| controller         | 允许控制本机web的[PlatformWebViewController] | PlatformWebViewController                  | yes          |
| layoutDirection    | 用于嵌入式WebView的布局方向                  | TextDirection                              | yes          |
| gestureRecognizers | “手势识别器”指定web视图应使用哪些手势        | Set<Factory<OneSequenceGestureRecognizer>> | yes          |

#### UrlChange

| Name | Description    | Type    | ohos Support |
| ---- | -------------- | ------- | ------------ |
| url  | web视图的新url | String? | yes          |

#### WebResourceError

| Name        | Description                                             | Type   | ohos Support |
| ----------- | ------------------------------------------------------- | ------ | ------------ |
| errorCode   | 错误的整数代码（例如[WebViewClient.errorAuthentication] | int    | yes          |
| description | 描述错误                                                | String | yes          |

#### WebViewCookie

| Name       | Description    | Type   | ohos Support |
| ---------- | -------------- | ------ | ------------ |
| name       | cookie的名称   | String | yes          |
| value      | cookie的值     | String | yes          |
| domain     | cookie的域值   | String | yes          |
| path = '/' | cookie的路径值 | String | yes          |

#### WebViewCredential

| Name     | Description | Type   | ohos Support |
| -------- | ----------- | ------ | ------------ |
| user     | 用户名      | String | yes          |
| password | 密码        | String | yes          |

#### WebViewPermissionResourceType

| Name                                     | Description                | Type  | ohos Support |
| ---------------------------------------- | -------------------------- | ----- | ------------ |
| WebViewPermissionResourceType.camera     | 一种可以捕获视频的媒体设备 | enums | yes          |
| WebViewPermissionResourceType.microphone | 一种可以捕获音频的媒体设备 | enums | yes          |

#### JavaScriptMode

| Name                        | Description              | Type | ohos Support |
| --------------------------- | ------------------------ | ---- | ------------ |
| JavaScriptMode.disabled     | JavaScript执行已禁用     | enum | yes          |
| JavascriptMode.unrestricted | JavaScript的执行不受限制 | enum | yes          |

#### JavaScriptLogLevel

| Name                       | Description                                            | Type | ohos Support |
| -------------------------- | ------------------------------------------------------ | ---- | ------------ |
| JavaScriptLogLevel.error   | 表示通过`console.error`方法的“error”事件记录了错误消息 | enum | yes          |
| JavaScriptLogLevel.warning | 表示使用`console.twarning`方法记录了警告消息           | enum | yes          |
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
| WebResourceErrorType.file                              | Generic file error.                  | enum | yes          |
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
|---- CHANGELOG_README.md              # README 变更记录
|---- LICENSE                          # 开源协议
|---- pubspec.yaml                     # 包配置文件
|---- README.CN.md                     # 中文说明文档
|---- README.md                        # 英文说明文档
|---- SKILL.md                         # 当前库文档技能说明
```

##  贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues)；当然，也非常欢迎发 [PR](https://gitcode.com/openharmony-tpc/flutter_packages/pulls) 共建。

##  开源协议

本项目基于 [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/br_webview_flutter-v4.13.1_ohos/packages/webview_flutter/webview_flutter/LICENSE) ，请自由地享受和参与开源。

