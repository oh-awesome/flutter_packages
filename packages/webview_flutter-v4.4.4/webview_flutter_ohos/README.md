# webview_flutter_ohos

[`webview_flutter`][1] 的 OpenHarmony 平台实现。

## 用法

这个包是[endorsed][2]实现，直接用 `webview_flutter` 就行，本包会自动带上，不用手动加到 `pubspec.yaml`。

如果你要 `import` 本包直接调它的 API，那就得自己加依赖了。

### 平台特定功能

想用 OHOS 特有的功能，先加依赖：

```yaml
dependencies:
  webview_flutter_ohos: ^3.13.2
```

然后 import：

```dart
import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
```

访问平台额外功能有两种方式：

1. 通过 `fromPlatformCreationParams` 构造函数传入平台创建参数
2. 通过 `.platform` 字段拿到平台实现来调方法

举个例子，给 `WebViewController` 设置 OHOS 特定参数：

```dart
late final PlatformWebViewControllerCreationParams params;
if (WebViewPlatform.instance is OhosWebViewPlatform) {
  params = OhosWebViewControllerCreationParams();
} else {
  params = const PlatformWebViewControllerCreationParams();
}

final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

if (controller.platform is OhosWebViewController) {
  OhosWebViewController.enableDebugging(true);
  (controller.platform as OhosWebViewController)
      .setMediaPlaybackRequiresUserGesture(false);
}
```

## 显示模式

插件支持两种平台视图显示模式。默认模式以后可能会换，不算破坏性变更，想用哪种就显式指定。

### Surface 层模式（默认）

当前默认，用纹理层渲染，性能好，但因为是渲染到 OHOS SurfaceTexture，会有一些限制。

### 混合合成模式（Hybrid Composition）

WebView 显示和交互更准确，但性能稍差。用 `OhosWebViewWidgetCreationParams.displayWithHybridComposition` 开启：

```dart
WebViewWidget(
  WebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
    PlatformWebViewWidgetCreationParams(controller: controller),
    displayWithHybridComposition: true,
  ),
);
```

## OHOS 特定 API

### 调试

开 WebView 调试：

```dart
OhosWebViewController.enableDebugging(true);
```

### 地理位置权限

处理网页的地理位置权限请求：

```dart
OhosWebViewController ohosController = controller.platform as OhosWebViewController;
ohosController.setGeolocationPermissionsPromptCallbacks(
  onShowPrompt: (GeolocationPermissionsRequestParams request) async {
    return GeolocationPermissionsResponse(allow: true, retain: true);
  },
  onHidePrompt: () {
    // 障地理位置权限 UI
  },
);
```

### 全屏视频

全屏视频需要自己处理，用 `setCustomWidgetCallbacks`：

```dart
ohosController.setCustomWidgetCallbacks(
  onShowCustomWidget: (Widget widget, OnHideCustomWidgetCallback callback) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => widget,
      fullscreenDialog: true,
    ));
  },
  onHideCustomWidget: () {
    Navigator.of(context).pop();
  },
);
```

### 文件选择器

处理网页文件选择（比如表单上传）：

```dart
ohosController.setOnShowFileSelector(
  (FileSelectorParams params) async {
    // 返回选的文件路径
    return <String>[];
  },
);
```

### 权限请求

处理网页权限请求（摄像头、麦克风等）：

```dart
ohosController.setOnPlatformPermissionRequest(
  (PlatformWebViewPermissionRequest request) {
    request.grant();
  },
);
```

### 控制台消息

收 JS 控制台日志：

```dart
ohosController.setOnConsoleMessage(
  (JavaScriptConsoleMessage consoleMessage) {
    debugPrint('JS ${consoleMessage.level.name}: ${consoleMessage.message}');
  },
);
```

### 文本缩放

设页面文字缩放（默认100）：

```dart
ohosController.setTextZoom(120);
```

### 第三方 Cookie

```dart
OhosWebViewCookieManager cookieManager = OhosWebViewCookieManager(
  const PlatformWebViewCookieManagerCreationParams(),
);
cookieManager.setAcceptThirdPartyCookies(ohosController, true);
```
