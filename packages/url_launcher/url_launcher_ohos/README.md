<p align="center">
  <h1 align="center"> <code>url_launcher</code> </h1>
</p>

This project is based on [url_launcher@6.1.12](https://pub.dev/packages/url_launcher/versions/6.1.12).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  url_launcher:
   git:
     url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
     path: "packages/url_launcher/url_launcher"

...
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

## 2. Constraints

For use cases [packages/url_launcher/url_launcher_ohos/example](./example)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3.

### 2.2 **Permission Requirements**

The following permissions include the `system_basic` permission, but the default application permission is `normal`. Only the `normal` permission can be used. Therefore, the error **9568289** may be reported during the installation of the HAP package. For details, see [Document](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/bm-tool-V5#EN_TOPIC_0000001884757326__%E5%AE%89%E8%A3%85hap%E6%97%B6%E6%8F%90%E7%A4%BAcode9568289-error-install-failed-due-to-grant-request-permissions-failed) Change the application level to `system_basic`.

####  2.2.1 **Add permissions to the module.json5 file in the entry directory.**

Open  `entry/src/main/module.json5` and add the following information:

```yaml
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
          "EntryAbility"
      ],
      "when": "inuse"
    }
  },
]
```

#### 2.2.2 **Add the reason for applying for the preceding permission to the entry directory.**

Open  `entry/src/main/resources/base/element/string.json` and add the following information:

```yaml
{
  "string": [
    {
      "name": "network_reason",
      "value": "use network"
    }
  ]
}
```

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name  | return value  | Description  | Type       | ohos Support |
|-----------|----------|-------|----------|--------------------|
| canLaunch(String url) | Future<bool>  | Returns `true` if this platform is able to launch [url].   | function  | yes               |
| launch(String url, {required bool useSafariVC,required bool useWebView,required bool enableJavaScript,required bool enableDomStorage,required bool universalLinksOnly,required Map<String, String> headers,String? webOnlyWindowName,})    | Future<bool>  | Passes [url] to the underlying platform for handling. | function   | yes               |
| launchUrl(String url, LaunchOptions options) | Future<bool>  |Passes [url] to the underlying platform for handling. | function  | yes               |
| closeWebView() | Future<void>   |Closes the WebView, if one was opened earlier by [launch]. | function | yes               |


### Parameters

| Name  | Description  | Type       | ohos Support |
|---------------------|-------|----------|--------------------|
| url                | Jump address | String   | yes      |
| useSafariVC        | Whether or not to open the URL in the Safari view controller   | bool  | yes    |
| useWebView         | If set to null or false, open the URL in the device's default browser; otherwise, launch the URL in the WebView. | bool     | yes     |
| enableJavaScript   | If set to true, JavaScript is enabled in the WebView | bool  | yes       | 
| enableDomStorage   | When this value is set to true, the WebView enables DOM storage  | bool    | yes       | 
| universalLinksOnly | Used to control whether web pages are opened only through Universal Links  | bool                       | yes       |
| headers            | The request header parameter when opening a URL on a web page | Map<String, String> headers             | yes       |
| webOnlyWindowName  | Default behaviour when unset should be to open the url in a new tab. | String?            | yes       | 

### LaunchOptions

| Name  | Description  | Type       | ohos Support |
|---------------------|-------|----------|--------------------|
| mode                | The requested launch mode. | [PreferredLaunchMode](#PreferredLaunchMode)   | yes      |
| webViewConfiguration | Configuration for the web view in [PreferredLaunchMode.inAppWebView] mode. | [InAppWebViewConfiguration](#InAppWebViewConfiguration) | yes       | 
| webOnlyWindowName    | Default behaviour when unset should be to open the url in a new tab. | String? | yes       | 

### PreferredLaunchMode

| Name            | Description  | Type | ohos Support |
|-----------------|--------------|------|-------------|
| PreferredLaunchMode.platformDefault    |  Leaves the decision of how to launch the URL to the platform | enum | yes  |
| PreferredLaunchMode.inAppWebView | Loads the URL in an in-app web view | enum | yes  |
| PreferredLaunchMode.externalApplication  | Passes the URL to the OS to be handled by another application. | enum | yes  |
| PreferredLaunchMode.externalNonBrowserApplication  | Passes the URL to the OS to be handled by another non-browser application. | enum | yes  |

### InAppWebViewConfiguration

| Name            | Description  | Type | ohos Support |
|-----------------|--------------|------|-------------|
| enableJavaScript   | If set to true, JavaScript is enabled in the WebView | bool  | yes       | 
| enableDomStorage   | When this value is set to true, the WebView enables DOM storage  | bool    | yes       | 
| headers            | The request header parameter when opening a URL on a web page | Map<String, String> | yes       |

## 4. Known Issues

## 5. Others

## 6. License

This project is licensed under [BSD-3-Clause](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/url_launcher/url_launcher/LICENSE)

> 模板版本: v0.0.1