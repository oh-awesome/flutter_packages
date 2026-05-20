// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_ohos/webview_flutter_ohos.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Example function for README demonstration of Payment Request API.
Future<void> enablePaymentRequest() async {
  final controller = PlatformWebViewController(
    OhosWebViewControllerCreationParams(),
  );
  final ohosController = controller as OhosWebViewController;
  // #docregion payment_request_example
  final bool paymentRequestEnabled = await ohosController
      .isWebViewFeatureSupported(WebViewFeatureType.paymentRequest);

  if (paymentRequestEnabled) {
    await ohosController.setPaymentRequestEnabled(true);
  }
  // #enddocregion payment_request_example
}

/// Example function for README demonstration of geolocation permissions for
/// a use case where the content is always trusted (for example, it only shows
/// content from a domain controlled by the app developer) and geolocation
/// should always be allowed.
Future<void> setGeolocationPermissionsPrompt() async {
  final controller = PlatformWebViewController(
    OhosWebViewControllerCreationParams(),
  );
  final ohosController = controller as OhosWebViewController;
  // #docregion geolocation_example
  await ohosController.setGeolocationPermissionsPromptCallbacks(
    onShowPrompt: (GeolocationPermissionsRequestParams request) async {
      return const GeolocationPermissionsResponse(allow: true, retain: true);
    },
  );
  // #enddocregion geolocation_example
}
