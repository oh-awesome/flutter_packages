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
  // 声明为可空类型，以便 aboutToDisappear 时置 null 尽早释放 Web 内核资源引用
  webviewController: web_webview.WebviewController | null = new web_webview.WebviewController()

  private url?: string;
  private headers: Record<string, string> = {};
  private enableJavaScript: boolean = true;
  private enableDomStorage: boolean = true;
  private showTitle: boolean = false;
  private pageTitle: string = '';
  @State statusBarHeight: number = 32;
  // 组件存活标志位，防止异步回调访问已销毁组件
  private isAlive: boolean = true;
  // 保存回调引用，emitter.off 时传入实现精确移除；可空类型以便销毁时置 null 释放引用
  private closeWebViewCallback: (() => void) | null = () => {
    console.info('closeWebView');
    router.back();
  };
  // emitter 订阅状态追踪标志位，避免未订阅时调用 off 或重复订阅
  private isEmitterSubscribed: boolean = false;

  aboutToDisappear() {
    this.isAlive = false;
    // 仅在已订阅时执行 off，避免未订阅时调用 off 产生警告
    if (this.isEmitterSubscribed && this.closeWebViewCallback !== null) {
      emitter.off('closeWebView', this.closeWebViewCallback);
      this.isEmitterSubscribed = false;
    }
    // 释放 WebviewController 持有的 Web 内核资源
    try {
      this.webviewController?.clearHistory();
    } catch (e) {
      // 组件销毁阶段控制器可能已失效，忽略
    }
    // 显式清理组件持有的引用，打破 InAppBrowser → Web 组件 → 回调 → InAppBrowser 潜在循环引用链
    this.url = undefined;
    this.headers = {};
    this.pageTitle = '';
    this.closeWebViewCallback = null;
    // 释放 Web 内核资源引用，尽早让 GC 回收 WebviewController
    this.webviewController = null;
  }

  aboutToAppear(){
    // router.getParams() 可能返回 null（如直接通过路由跳转未传 params），需可选链防护
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
    // 显式声明 self 引用，提高闭包捕获意图可读性（ArkTS 箭头函数自动捕获 this，
    // isAlive 标志位已缓解组件销毁后异步回调竞态访问）
    const self = this;
    try {
      let context = getContext(self) as common.UIAbilityContext;
      window.getLastWindow(context).then((win) => {
        // 组件已销毁则不再更新状态，避免竞态访问
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
          // webviewController 在 aboutToDisappear 后置 null，此处需非空检查
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
