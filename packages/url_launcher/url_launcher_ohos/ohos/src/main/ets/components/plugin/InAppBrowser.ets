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
import web_webview from '@ohos.web.webview';
import router from '@ohos.router';
import { ValueType } from '@kit.ArkData';
import { emitter } from '@kit.BasicServicesKit';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';

class WebHeaderItem {
  headerKey: string = '';
  headerValue: string = '';
}

class BrowserRouterParams {
  url: string = '';
  options: Record<string, ValueType> = {};
  headers: Record<string, string> = {};
  browserOptions: Record<string, ValueType> = {};
}

@Entry
@Component
export struct InAppBrowser {
  // Nullable so it can be set to null in aboutToDisappear to release the Web kernel reference early
  webviewController: web_webview.WebviewController | null = new web_webview.WebviewController()

  private url?: string;
  private headers: Record<string, string> = {};
  private enableJavaScript: boolean = true;
  private enableDomStorage: boolean = true;
  private showTitle: boolean = false;
  private pageTitle: string = '';
  @State statusBarHeight: number = 32;
  // Component alive flag: prevents async callbacks from accessing a destroyed component
  private isAlive: boolean = true;
  // Keep the callback reference so emitter.off can remove it precisely; nullable so it can
  // be set to null on destroy to release the reference
  private closeWebViewCallback: (() => void) | null = () => {
    console.info('closeWebView');
    router.back();
  };
  // emitter subscription tracking flag: avoids calling off before subscribing, or double subscribing
  private isEmitterSubscribed: boolean = false;

  aboutToDisappear() {
    this.isAlive = false;
    // Only call off when subscribed, to avoid warnings from unsubscribing without a subscription
    if (this.isEmitterSubscribed && this.closeWebViewCallback !== null) {
      emitter.off('closeWebView', this.closeWebViewCallback);
      this.isEmitterSubscribed = false;
    }
    // Release the Web kernel resources held by the WebviewController
    try {
      this.webviewController?.clearHistory();
    } catch (e) {
      // The controller may already be invalid during component teardown; ignore
    }
    // Explicitly clear the component-held references to break the potential
    // InAppBrowser -> Web component -> callback -> InAppBrowser reference cycle
    this.url = undefined;
    this.headers = {};
    this.pageTitle = '';
    this.closeWebViewCallback = null;
    // Release the Web kernel reference so the GC can reclaim the WebviewController early
    this.webviewController = null;
  }

  aboutToAppear(){
    // router.getParams() may return null (e.g. navigating to the route without params); guard with optional chaining
    let params = router.getParams() as BrowserRouterParams | null;
    this.url = params?.url ?? '';
    this.enableJavaScript = (params?.options?.['enableJavaScript'] as boolean) ?? true;
    this.enableDomStorage = (params?.options?.['enableDomStorage'] as boolean) ?? true;
    if (params?.headers !== undefined && params?.headers !== null) {
      this.headers = params.headers;
    }
    this.showTitle = (params?.browserOptions?.['showTitle'] as boolean) ?? false;
    if (this.closeWebViewCallback !== null && !this.isEmitterSubscribed) {
      emitter.once('closeWebView', this.closeWebViewCallback);
      this.isEmitterSubscribed = true;
    }
    // Declare an explicit self reference to clarify what the closure captures
    // (ArkTS arrow functions capture this automatically; the isAlive flag mitigates
    // racing async callbacks after the component is destroyed)
    const self = this;
    try {
      let context = getContext(self) as common.UIAbilityContext;
      window.getLastWindow(context).then((win) => {
        // Skip state updates when the component is already destroyed, to avoid racing access
        if (!self.isAlive) {
          return;
        }
        let avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        let height = px2vp(avoidArea.topRect.height);
        if (height > 0) {
          self.statusBarHeight = height;
        }
      }).catch((err: Error) => {
        console.error('InAppBrowser: Failed to get last window: ' + JSON.stringify(err));
      });
    } catch (e) {
      console.error('InAppBrowser: Failed to get status bar height: ' + JSON.stringify(e));
    }
  }
  build() {
    Column() {
      Row() {
        if (this.showTitle) {
          Text(this.pageTitle || 'Loading...')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 16 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Web({ src: '', controller: this.webviewController! })
        .javaScriptAccess(this.enableJavaScript)
        .domStorageAccess(this.enableDomStorage)
        .layoutWeight(1)
        .width('100%')
        .onTitleReceive((event) => {
          if (this.showTitle) {
            this.pageTitle = event.title;
          }
        })
        .onControllerAttached(() => {
          if (!this.url || this.url.length === 0) {
            console.error('InAppBrowser: url is empty, skip loadUrl');
            return;
          }
          // webviewController is set to null in aboutToDisappear; a null check is required here
          if (this.webviewController === null) {
            console.error('InAppBrowser: webviewController is null, skip loadUrl');
            return;
          }
          let headerKeys = Object.keys(this.headers);
          if (headerKeys.length > 0) {
            let headerArray: Array<WebHeaderItem> = [];
            headerKeys.forEach((key: string) => {
              let item = new WebHeaderItem();
              item.headerKey = key;
              item.headerValue = this.headers[key];
              headerArray.push(item);
            });
            this.webviewController.loadUrl(this.url, headerArray);
          } else {
            this.webviewController.loadUrl(this.url);
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarHeight })
  }
}
