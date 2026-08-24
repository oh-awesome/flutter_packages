// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on WebSettingsHostApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.


import { WebSettingsHostApi } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';
import { WebViewPlatformView } from './WebViewHostApiImpl';

export interface WebSettings {
  setDomStorageEnabled(flag: boolean): void;

  getDomStorageEnabled(): boolean;

  setJavaScriptCanOpenWindowsAutomatically(flag: boolean): void;

  getJavaScriptCanOpenWindowsAutomatically(): boolean;

  setSupportMultipleWindows(support: boolean): void;

  getSupportMultipleWindows(): boolean;

  setBackgroundColor(color: number): void;

  getBackgroundColor(): string;

  setJavaScriptEnabled(flag: boolean): void;

  getJavaScriptEnabled(): boolean;

  setUserAgentString(userAgentString: string): void;

  setMediaPlaybackRequiresUserGesture(require: boolean): void;

  getMediaPlaybackRequiresUserGesture(): boolean;

  setSupportZoom(support: boolean): void;

  getSupportZoom(): boolean;

  setLoadWithOverviewMode(overview: boolean): void;

  getLoadWithOverviewMode(): boolean;

  setUseWideViewPort(use: boolean): void;

  getUseWideViewPort(): boolean;

  setDisplayZoomControls(enabled: boolean): void;

  setBuiltInZoomControls(enabled: boolean): void;

  setAllowFileAccess(enabled: boolean): void;

  getAllowFileAccess(): boolean;

  setTextZoom(textZoom: number): void;

  getTextZoom(): number;

  getUserAgentString(): Promise<string>;
  
  onTextZoomChanged(callback: (ratio: number) => void): void;

  clearOnTextZoomChanged(): void;

  releaseWebView(): void;

  setAllowFullScreenRotate(enabled: boolean): void;
  
  getAllowFullScreenRotate(): boolean;

  setPaymentRequestEnabled(enabled: boolean): void;

  setMixedContentMode(mode: number): void;

  getMixedMode(): number;

  setOverScrollMode(mode: number): void;

  getOverScrollMode(): number;
}

export class WebSettingsCreator {
  createWebSettings(webView: WebViewPlatformView): WebSettings {
    return webView.getWebSettings();
  }
}

export class WebSettingsHostApiImpl extends WebSettingsHostApi {
  private instanceManager: InstanceManager;

  private webSettingsCreator: WebSettingsCreator;

  constructor(instanceManager: InstanceManager, webSettingsCreator: WebSettingsCreator) {
    super();
    this.instanceManager = instanceManager;
    this.webSettingsCreator = webSettingsCreator;
  }

  create(instanceId: number, webViewInstanceId: number) {
    const webView: WebViewPlatformView = this.instanceManager.getInstance(webViewInstanceId);
    // Defensive check: fail fast with a readable error instead of creating
    // settings bound to an unknown WebView. Valid identifiers follow exactly
    // the same path as before.
    if (!webView) {
      throw new Error('WebView instance not found for WebSettings, id = ' + webViewInstanceId);
    }
    this.instanceManager.addDartCreatedInstance(this.webSettingsCreator.createWebSettings(webView), instanceId);
  }

  // Defensive check: fail fast with a readable error instead of an
  // undefined-reference crash when the identifier is unknown or already
  // disposed. Valid identifiers follow exactly the same path as before.
  private requireWebSettingsInstance(identifier: number): WebSettings {
    const webSettings: WebSettings = this.instanceManager.getInstance(identifier);
    if (!webSettings) {
      throw new Error('WebSettings instance not found, id = ' + identifier);
    }
    return webSettings;
  }

  setDomStorageEnabled(instanceId: number, flag: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setDomStorageEnabled(flag);
  }

  setJavaScriptCanOpenWindowsAutomatically(instanceId: number, flag: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setJavaScriptCanOpenWindowsAutomatically(flag);
  }

  setSupportMultipleWindows(instanceId: number, support: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setSupportMultipleWindows(support);
  }

  setBackgroundColor(instanceId: number, color: number) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setBackgroundColor(color);
  }

  setJavaScriptEnabled(instanceId: number, flag: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setJavaScriptEnabled(flag);
  }

  setUserAgentString(instanceId: number, userAgentString: string) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setUserAgentString(userAgentString);
  }

  setMediaPlaybackRequiresUserGesture(instanceId: number, require: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setMediaPlaybackRequiresUserGesture(require);
  }

  setSupportZoom(instanceId: number, support: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setSupportZoom(support);
  }

  setLoadWithOverviewMode(instanceId: number, overview: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setLoadWithOverviewMode(overview);
  }

  setUseWideViewPort(instanceId: number, use: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setUseWideViewPort(use);
  }

  setDisplayZoomControls(instanceId: number, enabled: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setDisplayZoomControls(enabled);
  }

  setBuiltInZoomControls(instanceId: number, enabled: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setBuiltInZoomControls(enabled);
  }

  setAllowFileAccess(instanceId: number, enabled: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setAllowFileAccess(enabled);
  }

  setTextZoom(instanceId: number, textZoom: number) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setTextZoom(textZoom);
  }

  getUserAgentString(instanceId: number): Promise<string> {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    return webSettings.getUserAgentString();
  }

  setAllowFullScreenRotate(instanceId: number, enabled: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setAllowFullScreenRotate(enabled);
  }

  setPaymentRequestEnabled(instanceId: number, enabled: boolean) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setPaymentRequestEnabled(enabled);
  }

  setMixedContentMode(instanceId: number, mode: number) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setMixedContentMode(mode);
  }

  setOverScrollMode(instanceId: number, mode: number) {
    const webSettings:WebSettings = this.requireWebSettingsInstance(instanceId);
    webSettings.setOverScrollMode(mode);
  }
}