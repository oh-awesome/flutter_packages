# url_launcher_ohos

This project is developed based on [url_launcher](https://pub.dev/packages/url_launcher).

## Introduction

url_launcher_ohos is the OpenHarmony platform implementation of the url_launcher plugin, used to launch URLs in OpenHarmony applications. It supports opening web links in the system browser or in-app WebView, and also supports system functions such as making phone calls, sending SMS, and opening the app store.

## Installation

Navigate to your project directory and add the following dependency to your pubspec.yaml:

```yaml
dependencies:
  url_launcher_ohos:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages
      path: packages/url_launcher/url_launcher_ohos
```

Run the command:

```bash
flutter pub get
```

## Constraints and Limitations

### Compatibility

Tested and passed in the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.0.830; ROM: 6.1.0.117 SP6;

### Permission Requirements

This plugin requires the following permissions:

**Add permissions in module.json5 under the entry directory**

Open `entry/src/main/module.json5` and add:

```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"  // Replace with your app's actual entry Ability name
      ],
      "when": "inuse"
    }
  }
]
```

**Add the reason for requesting the above permissions under the entry directory**

Open `entry/src/main/resources/base/element/string.json` and add:

```json
{
  "string": [
    {
      "name": "network_reason",
      "value": "Use network to access web pages"
    }
  ]
}
```

## Usage Example

The following example shows how to use url_launcher to open a web link in the browser:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Launcher Demo',
      home: const UrlLaunchDemo(),
    );
  }
}

class UrlLaunchDemo extends StatefulWidget {
  const UrlLaunchDemo({super.key});

  @override
  State<UrlLaunchDemo> createState() => _UrlLaunchDemoState();
}

class _UrlLaunchDemoState extends State<UrlLaunchDemo> {
  final Uri _url = Uri.parse('https://www.openharmony.cn');

  /// Open URL in system browser
  Future<void> _launchInBrowser() async {
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      // Show a friendly error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open link: $_url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Launcher Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchInBrowser,
          child: const Text('Open in Browser'),
        ),
      ),
    );
  }
}
```

## Usage Instructions

### 1. Open URL in System Browser

Use the `launchUrl` method with `mode: LaunchMode.externalApplication` to open the link in the system browser:

```dart
await launchUrl(
  Uri.parse('https://www.openharmony.cn'),
  mode: LaunchMode.externalApplication,
);
```

### 2. Open URL in In-App WebView

Set `mode: LaunchMode.inAppWebView` to open the link in an in-app WebView:

```dart
await launchUrl(
  Uri.parse('https://www.openharmony.cn'),
  mode: LaunchMode.inAppWebView,
  webViewConfiguration: InAppWebViewConfiguration(
    enableJavaScript: true,
    enableDomStorage: true,
    headers: {
      'harmony_browser_page': 'pages/LaunchInAppPage' // OHOS-specific: specify the in-app WebView page path
    },
  ),
);
```

> **Note:** On the OHOS platform, when using WebView mode, you must add the `harmony_browser_page` key in `headers` to specify the in-app WebView page path, and create the corresponding page in the OHOS project and configure the route.

### 3. Check if URL Can Be Launched

Before launching a URL, you can use the `canLaunchUrl` method to check if the device supports handling that URL:

```dart
if (await canLaunchUrl(Uri.parse('https://www.openharmony.cn'))) {
  await launchUrl(Uri.parse('https://www.openharmony.cn'));
}
```

### 4. Close WebView

When a URL is opened in WebView mode, you can call the `closeInAppWebView` method to close the WebView:

```dart
await closeInAppWebView();
```

### 5. Make a Phone Call

Use the `tel:` protocol to launch the system dialer interface:

```dart
await launchUrl(Uri(scheme: 'tel', path: '1234567890'));
```

### 6. Send SMS

Use the `sms:` protocol to launch the SMS application:

```dart
await launchUrl(Uri(scheme: 'sms', path: '5555555555'));
```

### 7. Open App Store

Use the `store:` protocol to open the AppGallery:

```dart
await launchUrl(
  Uri.parse('AppGallery Url'),
  mode: LaunchMode.externalApplication,
);
```

### 8. Send Email

Use the `mailto:` protocol to launch the email application:

```dart
await launchUrl(Uri(scheme: 'mailto', path: 'example@example.com'));
```

### Supported URL Schemes

| Scheme | Description |
|--------|-------------|
| `http:` / `https:` | Open web page in system browser |
| `tel:` | Launch dialer interface |
| `sms:` | Launch SMS application |
| `mailto:` | Launch email application |
| `file:` | Open local file (sandbox path only) |
| `store:` | Open app store |
| `store://enterprise` | Enterprise installation |

> For custom URL schemes (e.g., `amapuri://`), you need to add the corresponding scheme to `querySchemes` in `module.json5` for `canLaunchUrl` to work correctly.

## API Reference

> [!TIP] "ohos Support" column: yes means the ohos platform supports this property; no means not supported; partially means partially supported. The usage method is consistent across platforms, and the effect is benchmarked against iOS or Android.

#### UrlLauncherPlatform

| Name | Type | Parameter Type | Return Value | OHOS Support | Description |
|------|------|----------------|--------------|--------------|-------------|
| canLaunch() | method | String url | Future\<bool\> | yes | Check if the device can launch a specific URL scheme |
| launch | method | String url,<br/>required bool useSafariVC,<br/>required bool useWebView,<br/>required bool enableJavaScript,<br/>required bool enableDomStorage,<br/>required bool universalLinksOnly,<br/>required Map\<String, String\> headers,<br/>String? webOnlyWindowName | Future\<bool\> | yes | Specify jump parameters and URL path |
| launchUrl() | method | String url,<br/>[LaunchOptions](#LaunchOptions) options | Future\<bool\> | yes | Specify the browser to jump to and open the URL |
| closeWebView() | method | / | Future\<void\> | yes | Close the WebView page |

#### LaunchOptions

| Name | Type | Parameter Type | Return Value | OHOS Support | Description |
|------|------|----------------|--------------|--------------|-------------|
| mode | property | / | [PreferredLaunchMode](#PreferredLaunchMode) | yes | The mode required to launch the URL |
| webViewConfiguration | property | / | [InAppWebViewConfiguration](#InAppWebViewConfiguration) | yes | Configure the web view in [PreferredLaunchMode.inAppWebView] mode |
| webOnlyWindowName | property | / | String? | yes | The default behavior when unset should be to open the URL in a new tab |

#### PreferredLaunchMode

| Name | Type | Parameter Type | Return Value | OHOS Support | Description |
|------|------|----------------|--------------|--------------|-------------|
| platformDefault | enum value | / | enum | yes | Launch mode is determined by the platform |
| inAppWebView | enum value | / | enum | yes | Load into inAppWebView |
| externalApplication | enum value | / | enum | yes | Pass the URL to be handled by other applications |
| externalNonBrowserApplication | enum value | / | enum | yes | Pass the URL to be handled by another non-browser application |

#### InAppWebViewConfiguration

| Name | Type | Parameter Type | Return Value | OHOS Support | Description |
|------|------|----------------|--------------|--------------|-------------|
| enableJavaScript | property | / | bool | yes | If set to true, enable JavaScript in WebView |
| enableDomStorage | property | / | bool | yes | When set to true, WebView enables DOM storage |
| headers | property | / | Map\<String, String\> | yes | Request header parameters when opening URL in web page. On OHOS platform, use this to pass `harmony_browser_page` to specify the WebView page path |

#### launch Method Parameters

| Name | Type | Parameter Type | Return Value | OHOS Support | Description |
|------|------|----------------|--------------|--------------|-------------|
| url | parameter | String | / | yes | Jump address |
| useSafariVC | parameter | bool | / | yes | Whether to open the URL in Safari view controller |
| useWebView | parameter | bool | / | yes | If set to false, open the URL in the device's default browser; otherwise, launch the URL in WebView |
| enableJavaScript | parameter | bool | / | yes | If set to true, enable JavaScript in WebView |
| enableDomStorage | parameter | bool | / | yes | When set to true, WebView enables DOM storage |
| universalLinksOnly | parameter | bool | / | yes | Used to control whether to open web pages only through Universal Links |
| headers | parameter | Map\<String, String\> | / | yes | Request header parameters when opening URL in web page |
| webOnlyWindowName | parameter | String? | / | yes | The default behavior when unset should be to open the URL in a new tab |

## Known Issues

None

## Directory Structure

```
flutter_packages/
└── packages/
    └── url_launcher/
        └── url_launcher_ohos/
            ├── lib/                          # Dart code directory
            │   ├── src/
            │   │   └── messages.g.dart       # Platform channel message definitions
            │   └── url_launcher_ohos.dart    # Plugin main entry
            ├── ohos/                         # OpenHarmony native code directory
            │   ├── index.ets                 # Native plugin export entry
            │   └── src/main/ets/components/plugin/
            │       ├── InAppBrowser.ets      # In-app browser implementation
            │       ├── Messages.ets          # Message handling
            │       ├── UrlLauncher.ets       # URL launcher implementation
            │       └── UrlLauncherPlugin.ets # Plugin entry
            ├── example/                      # Example application
            │   ├── lib/main.dart             # Example code
            │   └── ohos/                     # Example application native code
            ├── test/                         # Unit tests
            ├── test_driver/                  # Integration test driver
            ├── integration_test/             # Integration tests
            ├── pubspec.yaml                  # Package configuration file
            ├── README_CN.md                  # Chinese documentation
            └── README.md                     # English documentation
```

## Contributing

If you encounter any issues during use, you can submit an [Issue](https://gitcode.com/openharmony-tpc/flutter_packages/issues). Of course, [PRs](https://gitcode.com/openharmony-tpc/flutter_packages/pulls) are also very welcome for co-construction.


## License

This project is licensed under [BSD-3-Clause](LICENSE), please enjoy and participate in open source freely.
