/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:url_launcher_ohos/url_launcher_ohos.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

Future<void> _closeWebViewWithRetry(UrlLauncherOhos launcher) async {
  const Duration interval = Duration(milliseconds: 500);
  const int attempts = 10;
  for (int i = 0; i < attempts; i++) {
    await launcher.closeWebView();
    await Future<void>.delayed(interval);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Hold the concrete OHOS implementation (equivalent to what registerWith
  // installs as UrlLauncherPlatform.instance) so every call below exercises
  // the class under test through the real platform channels.
  final UrlLauncherOhos launcher = UrlLauncherOhos();

  group('url_launcher_ohos-registration', () {
    testWidgets('registerWith installs the OHOS implementation as the platform instance',
        (WidgetTester _) async {
      UrlLauncherOhos.registerWith();
      expect(UrlLauncherPlatform.instance, isA<UrlLauncherOhos>());
    });

    testWidgets('linkDelegate is null on OHOS', (WidgetTester _) async {
      // OHOS has no Link-based implementation, so the delegate stays null.
      expect(launcher.linkDelegate, isNull);
    });
  });

  group('url_launcher_ohos-canLaunch', () {
    testWidgets('returns true for built-in scheme urls', (WidgetTester _) async {
      // These schemes pass either the dynamic canOpenLink check or the
      // built-in scheme prefix fallback on OHOS.
      expect(await launcher.canLaunch('tel:10086'), isTrue);
      expect(await launcher.canLaunch('sms:10086?body=hello'), isTrue);
      expect(await launcher.canLaunch('mailto:flutter@example.com'), isTrue);
      expect(await launcher.canLaunch('file:///data/storage/files/tmp.txt'), isTrue);
    });

    testWidgets('returns true for https urls', (WidgetTester _) async {
      expect(await launcher.canLaunch('https://flutter.dev'), isTrue);
    });

    testWidgets('returns false for urls no app can handle', (WidgetTester _) async {
      // The pre-existing canLaunch case covers a scheme-less string; this
      // exercises an unknown scheme and an empty url, which must both be
      // reported as not launchable.
      expect(await launcher.canLaunch('randomstring://nothing/registered/here'), isFalse);
      expect(await launcher.canLaunch(''), isFalse);
    });
  });

  group('url_launcher_ohos-supportsMode', () {
    testWidgets('returns true for the supported launch modes', (WidgetTester _) async {
      expect(await launcher.supportsMode(PreferredLaunchMode.platformDefault), isTrue);
      expect(await launcher.supportsMode(PreferredLaunchMode.inAppWebView), isTrue);
      expect(await launcher.supportsMode(PreferredLaunchMode.inAppBrowserView), isTrue);
      expect(await launcher.supportsMode(PreferredLaunchMode.externalApplication), isTrue);
    });

    testWidgets('returns false for externalNonBrowserApplication', (WidgetTester _) async {
      expect(await launcher.supportsMode(PreferredLaunchMode.externalNonBrowserApplication), isFalse);
    });
  });

  group('url_launcher_ohos-supportsCloseForMode', () {
    testWidgets('returns true only for the in-app modes', (WidgetTester _) async {
      expect(await launcher.supportsCloseForMode(PreferredLaunchMode.inAppWebView), isTrue);
      expect(await launcher.supportsCloseForMode(PreferredLaunchMode.inAppBrowserView), isTrue);
    });

    testWidgets('returns false for the non-in-app modes', (WidgetTester _) async {
      expect(await launcher.supportsCloseForMode(PreferredLaunchMode.platformDefault), isFalse);
      expect(await launcher.supportsCloseForMode(PreferredLaunchMode.externalApplication), isFalse);
      expect(
          await launcher.supportsCloseForMode(PreferredLaunchMode.externalNonBrowserApplication),
          isFalse);
    });
  });

  group('url_launcher_ohos-launchUrl-errors', () {
    testWidgets('throws ACTIVITY_NOT_FOUND when no app can handle the scheme',
        (WidgetTester _) async {
      await expectLater(
        launcher.launchUrl(
          'randomstring://nothing/registered/here',
          const LaunchOptions(mode: PreferredLaunchMode.externalApplication),
        ),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'ACTIVITY_NOT_FOUND')),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('inAppWebView without harmony_browser_page header throws MISSING_CONFIG',
        (WidgetTester _) async {
      // OHOS-specific contract: the in-app web view is a host-side route, so
      // its page path must be passed via the harmony_browser_page header.
      await expectLater(
        launcher.launchUrl(
          'https://flutter.dev',
          const LaunchOptions(mode: PreferredLaunchMode.inAppWebView),
        ),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'MISSING_CONFIG')),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('platformDefault for https without headers also routes to the in-app web view',
        (WidgetTester _) async {
      // platformDefault sends http/https urls to the in-app web view, so the
      // same harmony_browser_page contract applies.
      await expectLater(
        launcher.launchUrl('https://flutter.dev', const LaunchOptions()),
        throwsA(isA<PlatformException>().having(
            (PlatformException e) => e.code, 'code', 'MISSING_CONFIG')),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('url_launcher_ohos-inAppWebView', () {
    testWidgets('opens the in-app browser page with harmony_browser_page header and closes it',
        (WidgetTester _) async {
      const Map<String, String> browserPageHeader = <String, String>{
        'harmony_browser_page': 'pages/LaunchInAppPage',
      };
      final bool opened = await launcher.launchUrl(
        'https://flutter.dev',
        const LaunchOptions(
          mode: PreferredLaunchMode.inAppWebView,
          webViewConfiguration: InAppWebViewConfiguration(headers: browserPageHeader),
        ),
      );
      expect(opened, isTrue);

      await _closeWebViewWithRetry(launcher);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('closeWebView completes when no in-app web view is open', (WidgetTester _) async {
      await expectLater(launcher.closeWebView(), completes);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('url_launcher_ohos-launch-legacy', () {
    testWidgets('launch with useWebView true opens and closes the in-app browser page',
        (WidgetTester _) async {
      final bool opened = await launcher.launch(
        'https://flutter.dev',
        useSafariVC: false,
        useWebView: true,
        enableJavaScript: true,
        enableDomStorage: true,
        universalLinksOnly: false,
        headers: const <String, String>{'harmony_browser_page': 'pages/LaunchInAppPage'},
      );
      expect(opened, isTrue);
      await _closeWebViewWithRetry(launcher);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('url_launcher_ohos-externalApplication', () {
    // Kept last: launching an external app moves this app to the background,
    // and a suspended app can stall the test runner, so nothing else in this
    // file runs after this case.
    testWidgets('launchUrl with externalApplication mode returns true for an https url',
        (WidgetTester _) async {
      final bool launched = await launcher.launchUrl(
        'https://flutter.dev',
        const LaunchOptions(mode: PreferredLaunchMode.externalApplication),
      );
      expect(launched, isTrue);
      // Give the external browser a moment to take the foreground.
      await Future<void>.delayed(const Duration(seconds: 2));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
