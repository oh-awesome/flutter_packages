// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { OhosObjectHostApi as OhosObjectHostApi } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';
import { WebViewPlatformView } from './WebViewHostApiImpl';

export class OhosObjectHostApiImpl extends OhosObjectHostApi {
  private instanceManager: InstanceManager;

  /**
   * Constructs a {@link OhosObjectHostApiImpl}.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   */
  constructor(instanceManager: InstanceManager) {
    super()
    this.instanceManager = instanceManager;
  }

  dispose(identifier: number) {
    // Dart-side instance release: the Dart weak reference was dropped, so no
    // controller can re-attach this instance anymore. Run the WebView's full
    // end-of-life teardown (polling intervals, display listeners, JavaScript
    // proxies, dialogs, reference cycles) before dropping the strong
    // reference. WebViewPlatformView.dispose() alone is intentionally minimal
    // because the embedding also calls it on transient widget removal, where
    // the instance must stay reusable by a new widget.
    const webView: WebViewPlatformView =
      this.instanceManager.getInstance(identifier) as WebViewPlatformView;
    if (webView instanceof WebViewPlatformView) {
      webView.release();
    }
    this.instanceManager.remove(identifier);
  }
}
