/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import web_webview from '@ohos.web.webview'
import  PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { WebViewPlatformView } from './WebViewHostApiImpl';
import { Any } from '@ohos/flutter_ohos';
import { commonEventManager } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';

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

  aboutToAppear() {
    this.webView.getWebSettings().onTextZoomChanged((ratio: number) => {
      this.textZoomRatio = ratio;
    });
    this.webView.setOnDisposeCallback(() => {
      this.disposed = true;
    });

    commonEventManager.createSubscriber(
      { events: ["usual.event.CLICK_STATUSBAR"] }, (err, subscriber) => {
      this.subscriber = subscriber
      if(subscriber !== null) {
        commonEventManager.subscribe(subscriber, (err, data) => {
          this.throttle(() => {
            this.webView.waitControllerAttached().then(() => {
              this.controller?.scrollTo(0, 0, 1000);
            })
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
    commonEventManager.unsubscribe(this.subscriber);
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
            event.handler.setWebController(newWebViewController);
          })
          .onSslErrorEventReceive((event) => {
            if (deviceInfo.sdkApiVersion >= 20) {
              event.handler.handleCancel(true);
            } else {
              event.handler.handleCancel();
            }
          })
          .onHttpAuthRequest(this.webView.onHttpAuthRequest)
          .onAlert(this.webView.onJsAlert)
          .onConfirm(this.webView.onJsConfirm)
          .onPrompt(this.webView.onJsPrompt)
          .mixedMode(MixedMode.All)
          .onOverrideUrlLoading(this.webView.onOverrideUrlLoading)
          .gesture(
            PinchGesture({ fingers: 2 })
              .onActionUpdate((event: GestureEvent) => {
                if (event && this.webView.getWebSettings().getSupportZoom()) {
                  this.controller.zoom(event.scale);
                }
              })
          )
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