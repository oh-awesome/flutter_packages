// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import web_webview from '@ohos.web.webview'
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { WebViewPlatformView } from './WebViewHostApiImpl';
import { Any } from '@ohos/flutter_ohos';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { commonEventManager } from '@kit.BasicServicesKit';

const TAG: string = 'OhosWebView';

@Observed
export declare class Params {
  direction: Direction
  platformView: PlatformView
}

@Component
export struct OhosWebView {
  @ObjectLink params: Params;
  webView: WebViewPlatformView = this.params.platformView as WebViewPlatformView;
  controller: web_webview.WebviewController = this.webView.getController();
  lastExecTime = 0;

  @State textZoomRatio: number = this.webView.getWebSettings().getTextZoom();
  @State disposed: boolean = false;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  // Lifecycle guard: set as soon as aboutToDisappear() runs, so a subscriber
  // whose createSubscriber() completes afterwards is released immediately
  // instead of being stored on (and leaked by) a component that is gone.
  private isDisappeared: boolean = false;

  aboutToAppear() {
    this.webView.getWebSettings().onTextZoomChanged((ratio: number) => {
      this.textZoomRatio = ratio;
    });
    this.webView.setOnDisposeCallback(() => {
      this.disposed = true;
    });

    commonEventManager.createSubscriber(
      { events: ['usual.event.CLICK_STATUSBAR'] }, (err, subscriber) => {
      if (err) {
        // Observation only: a failed subscription leaves `subscriber` null and
        // the branch below is skipped, exactly as before this log was added.
        Log.e(TAG, 'createSubscriber err = ' + err);
      }
      // Race fix: the component disappeared while createSubscriber() was in
      // flight. Release the late subscriber right away and never store it;
      // subscribing here would leak a system subscription no one unwinds.
      if (this.isDisappeared) {
        if (subscriber !== null) {
          commonEventManager.unsubscribe(subscriber);
        }
        return;
      }
      this.subscriber = subscriber
      if(subscriber !== null) {
        commonEventManager.subscribe(subscriber, (err, data) => {
          // Failure-path guard only: an errored subscription delivery carries
          // no event data, so scrolling is skipped; the throttle interval,
          // coordinates and duration are unchanged.
          if (err) {
            Log.e(TAG, 'statusbar subscribe err = ' + err);
            return;
          }
          this.throttle(() => {
            this.webView.waitControllerAttached().then(() => {
              this.controller?.scrollTo(0, 0, 1000);
            }).catch((attachErr: Error) => {
              // Observation only: consume the rejection with a log instead of
              // leaving an unhandled Promise rejection when the wait fails.
              Log.e(TAG, 'statusbar scroll attach err = ' + attachErr);
            });
          }, 1000)
        })
      }
    });
  }

  throttle(func: Function, delay: number) {
    const currentTime = Date.now();
    if (currentTime - this.lastExecTime >= delay) {
      func();
      this.lastExecTime = currentTime;
    }
  }

  aboutToDisappear() {
    this.isDisappeared = true;
    // Resource cleanup: SDK @ohos.commonEventManager.d.ts declares the
    // subscriber parameter of unsubscribe() as mandatory; calling it with a
    // null subscriber (subscription never created or already released)
    // throws a parameter error, so only unsubscribe when one is held.
    if (this.subscriber !== null) {
      commonEventManager.unsubscribe(this.subscriber);
      // Break the component -> system subscriber reference chain.
      this.subscriber = null;
    }
    // Resource cleanup: drop the text zoom callback registered in
    // aboutToAppear() so the settings object no longer captures this view.
    // Runs only after the component disappears; live behavior is unchanged.
    this.webView.getWebSettings().clearOnTextZoomChanged();
  }

  getMixedModeValue(): MixedMode {
    const mode: number = this.webView.getWebSettings().getMixedMode();
    switch (mode) {
      case 0:
        return MixedMode.All;
      case 1:
        return MixedMode.Compatible;
      case 2:
        return MixedMode.None;
      default:
        return MixedMode.All;
    }
  }

  getOverScrollModeValue(): OverScrollMode {
    const mode: number = this.webView.getWebSettings().getOverScrollMode();
    switch (mode) {
      case 0:
        return OverScrollMode.NEVER;
      case 1:
        return OverScrollMode.ALWAYS;
      default:
        return OverScrollMode.NEVER;
    }
  }

  build() {
    Column() {
      if (!this.disposed) {
        Web(
          {
            src: this.webView.getUrl(),
            controller: this.controller
          })
          .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_VISUAL)
          .backgroundColor(this.webView.getWebSettings().getBackgroundColor())
          .onDownloadStart(this.webView.onDownloadStart)
          .onPageBegin(this.webView.onPageBegin)
          .onPageEnd(this.webView.onPageEnd)
          .onErrorReceive(this.webView.onErrorReceive)
          .onHttpErrorReceive(this.webView.onHttpErrorReceive)
          .onRefreshAccessedHistory(this.webView.onRefreshAccessedHistory)
          .onProgressChange(this.webView.onProgressChange)
          .onGeolocationShow(this.webView.onGeolocationShow)
          .onGeolocationHide(this.webView.onGeolocationHide)
          .onShowFileSelector(this.webView.onShowFileSelector)
          .onPermissionRequest(this.webView.onPermissionRequest)
          .onConsole(this.webView.onConsoleMessage)
          .onWindowExit(this.webView.onWindowExit)
          .domStorageAccess(this.webView.getWebSettings().getDomStorageEnabled())
          .allowWindowOpenMethod(this.webView.getWebSettings().getJavaScriptCanOpenWindowsAutomatically())
          .multiWindowAccess(false)
          .javaScriptAccess(this.webView.getWebSettings().getJavaScriptEnabled())
          .mediaPlayGestureAccess(this.webView.getWebSettings().getMediaPlaybackRequiresUserGesture())
          .zoomAccess(this.webView.getWebSettings().getSupportZoom())
          .overviewModeAccess(this.webView.getWebSettings().getLoadWithOverviewMode())
          .wideViewModeAccess(this.webView.getWebSettings().getUseWideViewPort())
          .fileAccess(this.webView.getWebSettings().getAllowFileAccess())
          .textZoomRatio(this.textZoomRatio)
          .onScroll(this.webView.onScroll)
          .onControllerAttached(this.webView.onControllerAttached)
          .onWindowNew((event: Any) => {
            let newWebViewController: web_webview.WebviewController = new web_webview.WebviewController();
            let dialogController: CustomDialogController = new CustomDialogController({
              builder: NewWebView({ webViewController: newWebViewController })
            })
            dialogController.open();
            // Resource-release fix: track the opened dialog on the owning
            // platform view so dispose() can close it; previously the
            // controller stayed a local variable and could leak a ghost
            // dialog after the WebView was destroyed.
            this.webView.setDialogController(dialogController);
            event.handler.setWebController(newWebViewController);
          })
          .onSslErrorEventReceive(this.webView.onSslErrorReceive)
          .onHttpAuthRequest(this.webView.onHttpAuthRequest)
          .onAlert(this.webView.onJsAlert)
          .onConfirm(this.webView.onJsConfirm)
          .onPrompt(this.webView.onJsPrompt)
          .mixedMode(this.getMixedModeValue())
          .overScrollMode(this.getOverScrollModeValue())
          .onOverrideUrlLoading(this.webView.onOverrideUrlLoading)
          .onFullScreenEnter(this.webView.onFullScreenEnter)
          .onFullScreenExit(this.webView.onFullScreenExit)
      }
    }
  }
}

@Builder
export function WebBuilder(params: Params) {
  OhosWebView({
    params: params,
    webView: params.platformView as WebViewPlatformView,
    controller: (params.platformView as WebViewPlatformView).getController()
  }).backgroundColor(Color.Transparent)
}

@CustomDialog
struct NewWebView {
  controller?: CustomDialogController
  webViewController: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Web({ src: "", controller: this.webViewController })
      .javaScriptAccess(true)
      .multiWindowAccess(false)
      .onWindowExit(
        () => {
          if (this.controller) {
            this.controller.close();
          }
        }
      )
  }
}