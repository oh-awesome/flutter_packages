# webview_flutter

This project is based on [webview_flutter](https://pub.dev/packages/webview_flutter/versions/4.13.1).

## Introduction

webview_flutter_ohos is the federated implementation of webview_flutter on OpenHarmony. Applications usually only need to depend on webview_flutter, and the plugin automatically registers OhosWebViewPlatform as the default backend on OpenHarmony. When you need OpenHarmony-specific capabilities, you can add webview_flutter_ohos directly and use extension APIs through types such as OhosWebViewController.

The current implementation covers the following core capabilities:

- Page loading and navigation interception
- JavaScript execution, JavaScript channels, and console message callbacks
- Cookie management, local file loading, and Flutter asset loading
- HTTP authentication and recoverable SSL certificate error callbacks
- Geolocation permission callbacks, platform permission requests, and fullscreen custom view handling

## Installation

Add the following dependency in pubspec.yaml. Applications are recommended to depend on the application-level package webview_flutter first:

```yaml
dependencies:
  webview_flutter:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/webview_flutter/webview_flutter
      ref: br_webview_flutter-v4.13.1_ohos
```

If you need to debug the OHOS platform implementation directly, or need to call platform extension APIs, you can also depend on this package directly:

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

## Constraints and Limitations

### Compatibility

Verified with the following versions:

1. Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1.0.117 SP36;

### Permission Requirements

The following permissions include the `system_basic` permission, while the default application permission level is `normal`, which means only `normal`-level permissions can be used. As a result, error **9568289** may occur when installing the HAP package. Refer to the [documentation](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/bm-tool-V5#ZH-CN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) to change the application level to `system_basic`.

#### Add permissions to module.json5 under the entry directory

Open `entry/src/main/module.json5` and add:

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

#### Add the reason for requesting the above permission under the entry directory

Open `entry/src/main/resources/base/element/string.json` and add:

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

## Usage Example

The following snippet shows the minimum example for initializing a WebView on OpenHarmony, configuring navigation callbacks, and mounting `WebViewWidget`:

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

## Usage Instructions

1. Applications should prefer depending on `webview_flutter`, and OpenHarmony will automatically use `webview_flutter_ohos` as the default implementation.
2. If you need platform extension types such as `OhosWebViewController` or `OhosSslAuthError`, explicitly add `webview_flutter_ohos` to `pubspec.yaml`.
3. It is recommended to create the controller in the `initState` of a `StatefulWidget`, and complete initialization of JavaScript mode, navigation callbacks, JavaScript channels, and permission callbacks before the first `loadRequest`.
4. During rendering, mount the WebView with `WebViewWidget(controller: controller)` or `PlatformWebViewWidget(...)`, and avoid recreating the controller in `build`.
5. If you need to enable debugging, handle SSL errors, geolocation authorization, or platform permission requests, obtain the OpenHarmony platform implementation through `controller.platform` and then call the corresponding extension APIs.
6. When integrating into an application, declare at least `ohos.permission.INTERNET` in the OpenHarmony module. If the page involves geolocation, camera, or microphone access, you also need to declare the corresponding system permissions.

## API Reference

### API

> [!TIP] In the `ohos Support` column, `yes` means the feature is supported on the OHOS platform, `no` means it is not supported, and `partially` means only part of the capability is supported. The usage is consistent across platforms, and the behavior is aligned with iOS or Android.

| Name                                                         | return                       | Description                                   | Type     | ohos Support |
| ------------------------------------------------------------ | ---------------------------- | --------------------------------------------- | -------- | ------------ |
| NavigationRequestCallback([NavigationRequest](#NavigationRequest ) navigationRequest) | FutureOr<NavigationDecision> | Signature for callbacks that report a pending navigation request | function | yes          |
| PageEventCallback(String url)                                | Future<void>                 | Signature for callbacks that report page events triggered by the native web view | function | yes          |
| ProgressCallback(int progress)                               | Future<void>                 | Signature for callbacks that report page loading progress | function | yes          |
| WebResourceErrorCallback([WebResourceError](#WebResourceError ) error) | Future<void>                 | Signature for callbacks that report resource loading errors | function | yes          |

### Properties

> [!TIP] In the `ohos Support` column, `yes` means the feature is supported on the OHOS platform, `no` means it is not supported, and `partially` means only part of the capability is supported. The usage is consistent across platforms, and the behavior is aligned with iOS or Android.

#### WebViewWidget

| Name            | Description                                       | Type              | ohos Support |
| --------------- | ------------------------------------------------- | ----------------- | ------------ |
| controller      | Controls a WebView provided by the host platform  | WebViewController | yes          |
| layoutDirection | Layout direction                                  | TextDirection     | yes          |

#### WebViewController

| Name                                                         | return            | Description                                                  | Type     | ohos Support |
| ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformCreationParams([PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) params, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | Constructs a [WebViewController] from creation parameters for a specific object | function | yes          |
| fromPlatform([PlatformWebViewController](#PlatformWebViewController) this.platform, {void Function([WebViewPermissionRequest](#WebViewPermissionRequest) request)? onPermissionRequest}) | WebViewController | Constructs a [WebViewController] from a specific platform implementation | function | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>      | Loads the file located at the specified [absoluteFilePath]   | function | yes          |
| loadFlutterAsset(String key)                                 | Future<void>      | Loads the Flutter asset specified in pubspec.yaml            | function | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>      | Loads the provided HTML string                               | function | yes          |
| loadRequest(Uri uri, { [LoadRequestMethod](#LoadRequestMethod) method = LoadRequestMethod.get,  Map<String, String> headers = const <String, String>{}, Uint8List? body}) | Future<void>      | Sends a specific HTTP request and loads the response in the WebView | function | yes          |
| currentUrl()                                                 | Future<String?>   | Returns the current URL displayed by the WebView             | function | yes          |
| canGoBack()                                                  | Future<bool>      | Checks whether there is a back history item                  | function | yes          |
| canGoForward()                                               | Future<bool>      | Checks whether there is a forward history item               | function | yes          |
| goBack()                                                     | Future<void>      | Navigates back in the history of this WebView                | function | yes          |
| goForward()                                                  | Future<void>      | Navigates forward in the history of this WebView             | function | yes          |
| reload()                                                     | Future<void>      | Reloads the current URL                                      | function | yes          |
| setNavigationDelegate([NavigationDelegate](#NavigationDelegate ) delegate) | Future<void>      | Sets the [NavigationDelegate] containing callback methods for navigation events | function | yes          |
| clearCache()                                                 | Future<void>      | Clears all caches used by the WebView                        | function | yes          |
| clearLocalStorage()                                          | Future<void>      | Clears the local storage used by the WebView                 | function | yes          |
| runJavaScript(String javaScript)                             | Future<void>      | Runs the given JavaScript in the context of the current page | function | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>    | Runs the given JavaScript in the context of the current page and returns the result | function | yes          |
| addJavaScriptChannel(String name, {required void Function(JavaScriptMessage) onMessageReceived}) | Future<void>      | Adds a new JavaScript channel to the set of enabled channels | function | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>      | Removes the JavaScript channel with the matching name from the set of enabled channels | function | yes          |
| getTitle()                                                   | Future<String?>   | Returns the title of the currently loaded page               | function | yes          |
| scrollTo(int x, int y)                                       | Future<void>      | Sets the scroll position of this view                        | function | yes          |
| scrollBy(int x, int y)                                       | Future<void>      | Moves the scroll position of this view                       | function | yes          |
| getScrollPosition()                                          | Future<Offset>    | Returns the current scroll position of this view             | function | yes          |
| enableZoom(bool enabled)                                     | Future<void>      | Controls whether zooming is supported using on-screen zoom controls and gestures | function | yes          |
| setBackgroundColor(Color color)                              | Future<void>      | Sets the current background color of this view               | function | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>      | Sets the JavaScript execution mode used by the WebView       | function | yes          |
| setUserAgent(String? userAgent)                              | Future<void>      | Sets the value used for the HTTP `User-Agent:` request header | function | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>      | Sets a callback that notifies the host application of any messages written to the JavaScript console | function | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>      | Sets a callback that notifies the host application that the page wants to display a JavaScript alert() dialog | function | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>      | Sets a callback that notifies the host application that the page wants to display a JavaScript confirm() dialog | function | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>      | Sets a callback that notifies the host application that the page wants to display a JavaScript prompt() dialog | function | yes          |
| getUserAgent()                                               | Future<String?>   | Gets the value used for the HTTP `User-Agent:` request header | function | yes          |

#### NavigationDelegate

| Name                       | Description                                                  | Type     | ohos Support |
| -------------------------- | ------------------------------------------------------------ | -------- | ------------ |
| fromPlatformCreationParams | Constructs a [NavigationDelegate] from creation parameters for a specific platform | function | yes          |
| fromPlatform               | Constructs a [NavigationDelegate] from a specific platform implementation | function | yes          |

#### HttpAuthRequest

| Name                                                         | return       | Description                            | Type     | ohos Support |
| ------------------------------------------------------------ | ------------ | -------------------------------------- | -------- | ------------ |
| onProceed([WebViewCredential](#WebViewCredential ) credential) | Future<void> | Callback used for authentication       | function | yes          |
| onCancel()                                                   | Future<void> | Callback used to cancel authentication | function | yes          |
| host                                                         |              | Host that requires authentication      | String   | yes          |
| realm                                                        |              | Realm that requires authentication     | String   | yes          |

#### JavaScriptAlertDialogRequest

| Name    | Description                                | Type   | ohos Support |
| ------- | ------------------------------------------ | ------ | ------------ |
| message | Message to display in the dialog window    | String | yes          |
| url     | URL of the page requesting the dialog      | String | yes          |

#### JavaScriptConfirmDialogRequest

| Name    | Description                                | Type   | ohos Support |
| ------- | ------------------------------------------ | ------ | ------------ |
| message | Message to display in the dialog window    | String | yes          |
| url     | URL of the page requesting the dialog      | String | yes          |

#### JavaScriptConsoleMessage

| Name    | Description                               | Type   | ohos Support |
| ------- | ----------------------------------------- | ------ | ------------ |
| level   | Severity of the JavaScript log message    | String | yes          |
| message | Message written to the console            | String | yes          |

#### JavaScriptMessage

| Name    | Description                                         | Type   | ohos Support |
| ------- | --------------------------------------------------- | ------ | ------------ |
| message | Message content sent by JavaScript code             | String | yes          |

#### JavaScriptTextInputDialogRequest

| Name        | Description                                  | Type    | ohos Support |
| ----------- | -------------------------------------------- | ------- | ------------ |
| message     | Message to display in the dialog window      | String  | yes          |
| url         | URL of the page requesting the dialog        | String  | yes          |
| defaultText | Initial text displayed in the input field    | String? | yes          |

#### NavigationRequest

| Name        | Description                                              | Type   | ohos Support |
| ----------- | -------------------------------------------------------- | ------ | ------------ |
| url         | URL of the pending navigation request                    | String | yes          |
| isMainFrame | Indicates whether the request comes from the main frame or a subframe | bool   | yes          |

#### PlatformWebViewController

| Name                                                         | return                                                  | Description                                                  | Type                                    | ohos Support |
| ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------- | ------------ |
| [PlatformWebViewControllerCreationParams](#PlatformWebViewControllerCreationParams) | [PlatformWebViewController](#PlatformWebViewController) | Parameters used to initialize [PlatformWebViewController]    | PlatformWebViewControllerCreationParams | yes          |
| loadFile(String absoluteFilePath)                            | Future<void>                                            | Throws ArgumentError if [absoluteFilePath] does not exist    | function                                | yes          |
| loadFlutterAsset(String key)                                 | Future<void>                                            | Loads the Flutter asset specified in pubspec.yaml            | function                                | yes          |
| loadHtmlString(String html, {String? baseUrl})               | Future<void>                                            | Loads the provided HTML string                               | function                                | yes          |
| loadRequest([LoadRequestParams](#LoadRequestParams) params)  | Future<void>                                            | Sends a specific HTTP request and loads the response in the WebView | function                                | yes          |
| currentUrl()                                                 | Future<void>                                            | Returns the current URL displayed by the WebView             | function                                | yes          |
| canGoBack()                                                  | Future<bool>                                            | Checks whether there is a back history item                  | function                                | yes          |
| canGoForward()                                               | Future<bool>                                            | Checks whether there is a forward history item               | function                                | yes          |
| goBack()                                                     | Future<void>                                            | Navigates back in the history of this WebView                | function                                | yes          |
| goForward()                                                  | Future<void>                                            | Navigates forward in the history of this WebView             | function                                | yes          |
| reload()                                                     | Future<void>                                            | Reloads the current URL                                      | function                                | yes          |
| clearCache()                                                 | Future<void>                                            | Clears all caches used by the WebView                        | function                                | yes          |
| clearLocalStorage()                                          | Future<void>                                            | Clears the local storage used by the WebView                 | function                                | yes          |
| setPlatformNavigationDelegate([PlatformNavigationDelegate](#PlatformNavigationDelegate ) handler) | Future<void>                                            | Sets [PlatformNavigationDelegate], which contains callback methods invoked during navigation events | function                                | yes          |
| runJavaScript(String javaScript)                             | Future<void>                                            | Runs the given JavaScript in the context of the current page | function                                | yes          |
| runJavaScriptReturningResult(String javaScript)              | Future<Object>                                          | Runs the given JavaScript in the context of the current page and returns the result | function                                | yes          |
| addJavaScriptChannel(String name, {required void Function(String  JavaScriptMessage) onMessageReceived}) | Future<void>                                            | Adds a new JavaScript channel to the set of enabled channels | function                                | yes          |
| removeJavaScriptChannel(String javaScriptChannelName)        | Future<void>                                            | Removes the JavaScript channel with the matching name from the set of enabled channels | function                                | yes          |
| getTitle()                                                   | Future<String?>                                         | Title of the currently loaded page                           | function                                | yes          |
| scrollTo(int x, int y)                                       | Future<void>                                            | Sets the scroll position of this view                        | function                                | yes          |
| scrollBy(int x, int y)                                       | Future<void>                                            | Moves the scroll position of this view                       | function                                | yes          |
| getScrollPosition()                                          | Future<Offset>                                          | Returns the current scroll position of this view             | function                                | yes          |
| enableZoom(bool enabled)                                     | Future<void>                                            | Controls whether zooming is supported using on-screen zoom controls and gestures | function                                | yes          |
| setBackgroundColor(Color color)                              | Future<void>                                            | Sets the current background color of this view               | function                                | yes          |
| setJavaScriptMode([JavaScriptMode](#JavaScriptMode ) javaScriptMode) | Future<void>                                            | Sets the JavaScript execution mode used by the WebView       | function                                | yes          |
| setUserAgent(String? userAgent)                              | Future<void>                                            | Sets the value used for the HTTP `User-Agent:` request header | function                                | yes          |
| setOnPlatformPermissionRequest(void Function(PlatformWebViewPermissionRequest request) onPermissionRequest) | Future<void>                                            | Sets a callback that notifies the host application that web content is requesting access to specific resources | function                                | yes          |
| setOnConsoleMessage(void Function([JavaScriptConsoleMessage](#JavaScriptConsoleMessage ) message) onConsoleMessage) | Future<void>                                            | Sets a callback that notifies the host application of any messages written to the JavaScript console | function                                | yes          |
| setOnScrollPositionChange(void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange) | Future<void>                                            | Sets the listener for content offset changes                 | function                                | yes          |
| setOnJavaScriptAlertDialog(Future<void> Function([JavaScriptAlertDialogRequest](#JavaScriptAlertDialogRequest ) request) onJavaScriptAlertDialog) | Future<void>                                            | Sets a callback that notifies the host application that the page wants to display a JavaScript alert() dialog | function                                | yes          |
| setOnJavaScriptConfirmDialog(Future<bool> Function([JavaScriptConfirmDialogRequest](#JavaScriptConfirmDialogRequest ) request) onJavaScriptConfirmDialog) | Future<void>                                            | Sets a callback that notifies the host application that the page wants to display a JavaScript confirm() dialog | function                                | yes          |
| setOnJavaScriptTextInputDialog(Future<String> Function([JavaScriptTextInputDialogRequest](#JavaScriptTextInputDialogRequest) request) onJavaScriptTextInputDialog) | Future<void>                                            | Sets a callback that notifies the host application that the page wants to display a JavaScript prompt() dialog | function                                | yes          |
| getUserAgent()                                               | Future<String?>                                         | Gets the value used for the HTTP `User-Agent:` request header | function                                | yes          |

#### PlatformWebViewControllerCreationParams

#### PlatformNavigationDelegateCreationParams

#### PlatformWebViewPermissionRequest

| Name  | return       | Description                            | Type                          | ohos Support |
| ----- | ------------ | -------------------------------------- | ----------------------------- | ------------ |
| types |              | All requested resources                | WebViewPermissionResourceType | yes          |
| grant | Future<void> | Grants permission for the requested resources | function                      | yes          |
| deny  | Future<void> | Denies permission for the requested resources | function                      | yes          |

#### LoadRequestParams

| Name    | Description                      | Type                | ohos Support |
| ------- | -------------------------------- | ------------------- | ------------ |
| uri     | URI of the request               | Uri                 | yes          |
| method  | HTTP method used for the request | LoadRequestMethod   | yes          |
| headers | Request headers                  | Map<String, String> | yes          |
| body    | HTTP request body                | Uint8List?          | yes          |

#### PlatformNavigationDelegate

| Name    | Description                      | Type                | ohos Support |
| ------- | -------------------------------- | ------------------- | ------------ |
| params  | URI of the request               | Uri                 | yes          |
| method  | HTTP method used for the request | LoadRequestMethod   | yes          |
| headers | Request headers                  | Map<String, String> | yes          |
| body    | HTTP request body                | Uint8List?          | yes          |

#### WebViewPermissionRequest

| Name     | return       | Description                                                  | Type                             | ohos Support |
| -------- | ------------ | ------------------------------------------------------------ | -------------------------------- | ------------ |
| platform |              | Current platform implementation of [PlatformWebViewPermissionRequest] | PlatformWebViewPermissionRequest | yes          |
| types    |              | All requested resources                                      | WebViewPermissionResourceType    | yes          |
| grant()  | Future<void> | Grants permission for the requested resources                | function                         | yes          |
| deny()   | Future<void> | Denies permission for the requested resources                | function                         | yes          |

#### PlatformWebViewWidgetCreationParams

| Name               | Description                                                  | Type                                       | ohos Support |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------ | ------------ |
| key                | Controls how one widget replaces another widget in the tree  | String                                     | yes          |
| controller         | [PlatformWebViewController] used to control the native web   | PlatformWebViewController                  | yes          |
| layoutDirection    | Layout direction for the embedded WebView                    | TextDirection                              | yes          |
| gestureRecognizers | Specifies which gestures should be consumed by the WebView   | Set<Factory<OneSequenceGestureRecognizer>> | yes          |

#### UrlChange

| Name | Description             | Type    | ohos Support |
| ---- | ----------------------- | ------- | ------------ |
| url  | New URL of the WebView  | String? | yes          |

#### WebResourceError

| Name        | Description                                                         | Type   | ohos Support |
| ----------- | ------------------------------------------------------------------- | ------ | ------------ |
| errorCode   | Integer error code, for example [WebViewClient.errorAuthentication] | int    | yes          |
| description | Description of the error                                            | String | yes          |

#### WebViewCookie

| Name       | Description          | Type   | ohos Support |
| ---------- | -------------------- | ------ | ------------ |
| name       | Cookie name          | String | yes          |
| value      | Cookie value         | String | yes          |
| domain     | Cookie domain value  | String | yes          |
| path = '/' | Cookie path value    | String | yes          |

#### WebViewCredential

| Name     | Description | Type   | ohos Support |
| -------- | ----------- | ------ | ------------ |
| user     | User name   | String | yes          |
| password | Password    | String | yes          |

#### WebViewPermissionResourceType

| Name                                     | Description                            | Type  | ohos Support |
| ---------------------------------------- | -------------------------------------- | ----- | ------------ |
| WebViewPermissionResourceType.camera     | A media device capable of capturing video | enums | yes          |
| WebViewPermissionResourceType.microphone | A media device capable of capturing audio | enums | yes          |

#### JavaScriptMode

| Name                        | Description                        | Type | ohos Support |
| --------------------------- | ---------------------------------- | ---- | ------------ |
| JavaScriptMode.disabled     | JavaScript execution is disabled   | enum | yes          |
| JavascriptMode.unrestricted | JavaScript execution is unrestricted | enum | yes          |

#### JavaScriptLogLevel

| Name                       | Description                                                       | Type | ohos Support |
| -------------------------- | ----------------------------------------------------------------- | ---- | ------------ |
| JavaScriptLogLevel.error   | Indicates an error message logged through `console.error`         | enum | yes          |
| JavaScriptLogLevel.warning | Indicates a warning message logged through `console.warning`      | enum | yes          |
| JavaScriptLogLevel.debug   | Indicates a debug message logged through `console.debug`          | enum | yes          |
| JavaScriptLogLevel.info    | Indicates an informational message logged through `console.info`  | enum | yes          |
| JavaScriptLogLevel.log     | Indicates a log message logged through `console.log`              | enum | yes          |

#### LoadRequestMethod

| Name                   | Description      | Type | ohos Support |
| ---------------------- | ---------------- | ---- | ------------ |
| LoadRequestMethod.get  | HTTP GET method  | enum | yes          |
| LoadRequestMethod.post | HTTP POST method | enum | yes          |

#### NavigationDecision

| Name                        | Description               | Type | ohos Support |
| --------------------------- | ------------------------- | ---- | ------------ |
| NavigationDecision.prevent  | Prevents navigation       | enum | yes          |
| NavigationDecision.navigate | Allows navigation         | enum | yes          |

#### WebResourceErrorType

| Name                                                   | Description                                               | Type | ohos Support |
| ------------------------------------------------------ | --------------------------------------------------------- | ---- | ------------ |
| WebResourceErrorType.authentication                    | User authentication failed on the server                  | enum | yes          |
| WebResourceErrorType.badUrl                            | Malformed URL                                             | enum | yes          |
| WebResourceErrorType.connect                           | Failed to connect to the server                           | enum | yes          |
| WebResourceErrorType.failedSslHandshake                | Failed to perform the SSL handshake                       | enum | yes          |
| WebResourceErrorType.file                              | Generic file error                                        | enum | yes          |
| WebResourceErrorType.fileNotFound                      | File not found                                            | enum | yes          |
| WebResourceErrorType.hostLookup                        | Failed to resolve the server or proxy host name           | enum | yes          |
| WebResourceErrorType.io                                | Failed to read from or write to the server                | enum | yes          |
| WebResourceErrorType.proxyAuthentication               | User authentication failed on the proxy                   | enum | yes          |
| WebResourceErrorType.redirectLoop                      | Too many redirects                                        | enum | yes          |
| WebResourceErrorType.timeout                           | Connection timed out                                      | enum | yes          |
| WebResourceErrorType.tooManyRequests                   | Too many requests during loading                          | enum | yes          |
| WebResourceErrorType.unknown                           | Generic error                                             | enum | yes          |
| WebResourceErrorType.unsafeResource                    | Resource loading was canceled by safe browsing            | enum | yes          |
| WebResourceErrorType.unsupportedAuthScheme             | Unsupported authentication scheme, not basic or digest    | enum | yes          |
| WebResourceErrorType.unsupportedScheme                 | Unsupported URI scheme                                    | enum | yes          |
| WebResourceErrorType.webContentProcessTerminated       | The web content process was terminated                    | enum | yes          |
| WebResourceErrorType.webViewInvalidated                | The WebView was invalidated                               | enum | yes          |
| WebResourceErrorType.javaScriptExceptionOccurred       | A JavaScript exception occurred                           | enum | yes          |
| WebResourceErrorType.javaScriptResultTypeIsUnsupported | The result of JavaScript execution could not be returned  | enum | yes          |

## Known Issues

None

## Others

None

## Directory Structure

```text
webview_flutter_ohos/
|---- .github/                         # Skill templates and documentation specifications
|---- example/                         # Flutter example project
|     |---- assets/                    # Example assets
|     |---- lib/                       # Example Dart code
|     |---- ohos/                      # OpenHarmony project for the example app
|     |---- pubspec.yaml               # Dependency configuration for the example project
|     |---- README.md                  # Example description
|---- lib/                             # Public Dart entry points and core implementation of the package
|     |---- src/                       # OpenHarmony controller, platform implementation, Pigeon bindings, and compatibility layer
|     |---- webview_flutter_ohos.dart  # Main entry of this package
|---- ohos/                            # OpenHarmony HAR project of this package
|     |---- src/
|     |     |---- main/
|     |           |---- ets/           # ArkTS-side entry and implementation
|     |           |---- module.json5   # HAR module configuration
|---- AUTHORS                          # Author list
|---- CHANGELOG.md                     # Version change log
|---- CHANGELOG_README.md              # README change log
|---- LICENSE                          # Open-source license
|---- pubspec.yaml                     # Package configuration file
|---- README.CN.md                     # Chinese documentation
|---- README.md                        # English documentation
|---- SKILL.md                         # Documentation skill description for this package
```

## Contributing

If you encounter any issues during use, feel free to submit an [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues); PRs are also very welcome.

## License

This project is based on the [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/br_webview_flutter-v4.13.1_ohos/packages/webview_flutter/webview_flutter/LICENSE) license. Feel free to use it and participate in the open-source community.