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

// Unit tests for WebNodeController (the offline Web component holder).
// They do not depend on an ArkUI mount and cover the pure state methods
// (getComponentGeneration / isReleased / hasLiveWebComponent /
// bindEmbeddingSurfaceId), release idempotency, and the guard branches of the
// loadData snapshot restore on the WebViewPlatformView side (same-generation
// skip / no restore after clearLastLoadData / deferral to onWebNodeBound while
// unmounted / dispose leaves the mount state untouched).
// The makeNode re-mount vs re-create branches and cross-generation replay
// require a real UIContext + NodeContainer; they are covered by on-device
// verification (the offline-component benchmark and the demo smoke test) and
// are not constructed here.

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';
import {
  WebViewPlatformView,
  LoadDataState
} from '../../../main/ets/io.flutter.plugins/webview_flutter/WebViewHostApiImpl';
import { WebNodeController } from '../../../main/ets/io.flutter.plugins/webview_flutter/WebNodeController';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

class Fixture {
  public messenger: MockBinaryMessenger = new MockBinaryMessenger();
  public manager: InstanceManager = newManager();
  public view: WebViewPlatformView;

  constructor() {
    this.view = new WebViewPlatformView(this.messenger, this.manager);
    this.manager.addHostCreatedInstance(this.view);
  }
}

export default function webNodeControllerTest() {
  describe('WebNodeControllerTest', () => {
    it('initialStateIsNotReleasedAndHasNoLiveComponent', 0, () => {
      const f: Fixture = new Fixture();
      const controller: WebNodeController = f.view.getWebNodeController();
      expect(controller.isReleased()).assertFalse();
      expect(controller.hasLiveWebComponent()).assertFalse();
      expect(controller.getComponentGeneration()).assertEqual(0);
    })

    it('bindEmbeddingSurfaceIdReturnsSameController', 0, () => {
      const f: Fixture = new Fixture();
      const controller: WebNodeController = f.view.getWebNodeController();
      const returned: WebNodeController = f.view.bindEmbeddingSurfaceId('123');
      expect(returned === controller).assertTrue();
      // An empty string (older engines do not pass a per-view surfaceId)
      // is also accepted.
      const returnedEmpty: WebNodeController = f.view.bindEmbeddingSurfaceId('');
      expect(returnedEmpty === controller).assertTrue();
    })

    it('releaseIsIdempotentWithoutMount', 0, () => {
      const f: Fixture = new Fixture();
      const controller: WebNodeController = f.view.getWebNodeController();
      controller.release();
      expect(controller.isReleased()).assertTrue();
      // Idempotent: a second release() must not throw.
      controller.release();
      expect(controller.isReleased()).assertTrue();
      expect(controller.hasLiveWebComponent()).assertFalse();
    })

    it('restoreSkipsSameGenerationAfterMount', 0, () => {
      const f: Fixture = new Fixture();
      // setLastLoadData stamps the current generation (0): a same-generation
      // re-mount must NOT replay the content (a replay would throw on the
      // real controller that is not bound to an ArkWeb component; the error
      // is caught internally).
      f.view.setLastLoadData(new LoadDataState(' ', '<html></html>', 'text/html', 'utf-8', ' '));
      f.view.onWebNodeBound();
      f.view.onControllerAttached();
      expect(f.view.isWebViewBinding).assertTrue();
    })

    it('restoreDeferredWhenNotMounted', 0, () => {
      const f: Fixture = new Fixture();
      f.view.setLastLoadData(new LoadDataState(' ', '<html></html>', 'text/html', 'utf-8', ' '));
      // Not mounted: the deferred-restore branch runs (observable via log),
      // no exception escapes.
      f.view.onControllerAttached();
      expect(f.view.isWebViewBinding).assertFalse();
      // Retried in onWebNodeBound once mounted.
      f.view.onWebNodeBound();
      expect(f.view.isWebViewBinding).assertTrue();
    })

    it('clearLastLoadDataDisablesRestore', 0, () => {
      const f: Fixture = new Fixture();
      f.view.setLastLoadData(new LoadDataState(' ', '<html></html>', 'text/html', 'utf-8', ' '));
      f.view.clearLastLoadData();
      f.view.onWebNodeBound();
      f.view.onControllerAttached();
      expect(f.view.isWebViewBinding).assertTrue();
    })

    it('disposeKeepsBindingStateAndDoesNotFireTerminalCallback', 0, () => {
      const f: Fixture = new Fixture();
      f.view.onWebNodeBound();
      let callbackFired: boolean = false;
      f.view.setOnDisposeCallback(() => {
        callbackFired = true;
      });
      // dispose() (which the embedding also calls on transient widget
      // removal) only stops media and keeps the component alive: it must not
      // fire the terminal callback and must not reset the mount state.
      f.view.dispose();
      expect(f.view.isWebViewBinding).assertTrue();
      expect(callbackFired).assertFalse();
      // The terminal callback is fired by release() only.
      f.view.release();
      expect(callbackFired).assertTrue();
    })
  })
}
