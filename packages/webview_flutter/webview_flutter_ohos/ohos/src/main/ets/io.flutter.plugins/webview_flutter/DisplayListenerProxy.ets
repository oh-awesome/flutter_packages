// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on DisplayListenerProxy.java originally written by
// Copyright 2013 The Flutter Authors.

import display from '@ohos.display';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

export class DisplayListenerProxy {
  private static TAG = 'DisplayListenerProxy';

  private listenersBeforeWebView: mDisplay[] = new Array<mDisplay>();

  private registeredListeners: Array<RegisteredDisplayListener> = [];

  private hasCleanedUp: boolean = false;

  async onPreWebViewInitialization(): Promise<void> {
    try {
      this.listenersBeforeWebView = (await this.yoinkDisplayListeners()) as mDisplay[];
    } catch (error) {
      Log.e(DisplayListenerProxy.TAG, 'onPreWebViewInitialization err = ' + error);
      throw new Error(String(error));
    }
  }

  private async yoinkDisplayListeners(): Promise<display.Display[]> {
    const res = await display.getAllDisplays()
    return res
  }

  async onPostWebViewInitialization() {
    // Skip re-registration after cleanup or while a registration is already
    // active, so repeated create() calls cannot stack display listeners.
    if (this.hasCleanedUp || this.registeredListeners.length > 0) {
      return;
    }
    let webViewListeners: mDisplay[];
    try {
      webViewListeners = (await this.yoinkDisplayListeners()) as mDisplay[];
    } catch (error) {
      Log.e(DisplayListenerProxy.TAG, 'onPostWebViewInitialization err = ' + error);
      throw new Error(String(error));
    }

    webViewListeners = webViewListeners.filter((item: ESObject) => this.listenersBeforeWebView.indexOf(item) === -1)

    if (webViewListeners.length === 0) {
      return;
    }

    const onDisplayAdded = (displayId: number) => {
      for (let display of webViewListeners) {
        display.addCallback(displayId);
      }
    }

    const onDisplayRemoved = (displayId: number) => {
      for (let display of webViewListeners) {
        display.removeCallback(displayId);
      }
    }

    const onDisplayChanged = (displayId: number) => {
      if (webViewListeners.filter(item => item.id === displayId).length === 0) {
        return;
      }
      for (let display of webViewListeners) {
        display.changeCallback(displayId);
      }
    }

    for (let display of webViewListeners) {
      display.changeCallback = onDisplayChanged;
      display.addCallback = onDisplayAdded;
      display.removeCallback = onDisplayRemoved
    }

    for (let display of webViewListeners) {
      // Defect fix (leak/correctness): the previous code called
      // display.off('remove'/'add'/'change') with no callback here. Per SDK
      // @ohos.display.d.ts an omitted callback removes EVERY listener of
      // that event type, so these three calls unregistered display
      // listeners owned by other modules before registering ours. They are
      // deleted: this proxy owns nothing at this point, and its own
      // listeners are removed precisely in cleanup() below.
      display.on("remove", onDisplayRemoved)
      display.on("add", onDisplayAdded)
      display.on("change", onDisplayChanged)

      const registered: RegisteredDisplayListener = {
        display: display,
        onRemove: onDisplayRemoved,
        onAdd: onDisplayAdded,
        onChange: onDisplayChanged
      };
      this.registeredListeners.push(registered);
    }
  }

  // Resource cleanup: unregister the display listeners registered by
  // onPostWebViewInitialization() using the exact callback references that
  // were passed to display.on(). Runs only during disposal and is idempotent;
  // live WebView behavior is unchanged. Each off() is isolated so one
  // failure cannot prevent the remaining listeners from being released.
  cleanup(): void {
    if (this.hasCleanedUp) {
      return;
    }
    for (let registered of this.registeredListeners) {
      try {
        registered.display.off('remove', registered.onRemove);
      } catch (error) {
        Log.e(DisplayListenerProxy.TAG, 'cleanup off remove err = ' + error);
      }
      try {
        registered.display.off('add', registered.onAdd);
      } catch (error) {
        Log.e(DisplayListenerProxy.TAG, 'cleanup off add err = ' + error);
      }
      try {
        registered.display.off('change', registered.onChange);
      } catch (error) {
        Log.e(DisplayListenerProxy.TAG, 'cleanup off change err = ' + error);
      }
    }
    this.registeredListeners = [];
    // Resource release: also drop the baseline snapshot taken in
    // onPreWebViewInitialization(), so cleanup leaves both collections empty
    // and no display reference is retained after disposal.
    this.listenersBeforeWebView = [];
    this.hasCleanedUp = true;
  }
}

interface RegisteredDisplayListener {
  display: mDisplay;
  onRemove: (displayId: number) => void;
  onAdd: (displayId: number) => void;
  onChange: (displayId: number) => void;
}

interface mDisplay extends display.Display {
  on: ESObject,
  off: ESObject,
  changeCallback,
  removeCallback,
  addCallback,
}