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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { UrlLauncher } from '../../../../index';
import { BinaryMessenger, TaskQueue, BinaryMessageHandler, BinaryReply } from '@ohos/flutter_ohos';

/**
 * FakeBinaryMessenger: captures the handlers registered by setMessageHandler
 */
class FakeBinaryMessenger implements BinaryMessenger {
  public registered: Map<string, BinaryMessageHandler | null> = new Map();

  makeBackgroundTaskQueue(options?: TaskQueue): TaskQueue {
    return new EmptyTaskQueue();
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | null,
    taskQueue?: TaskQueue, ...args: Object[]): void {
    this.registered.set(channel.toString(), handler);
  }
}

class EmptyTaskQueue implements TaskQueue {
}

const CH_CAN_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl';
const CH_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.launchUrl';
const CH_OPEN_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView';
const CH_CLOSE_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.closeWebView';

/**
 * UrlLauncher.setup() unit tests (self-contained, no src/mock dependency)
 *
 * Coverage: registration/deregistration/null-argument guards for the 4 Pigeon channels.
 * The message codec path (the onMessage binary protocol) depends on flutter_ohos
 * StandardMessageCodec → @ohos.util / libflutter.so, which belongs to on-device/ohosTest scope.
 */
export default function urlLauncherSetupTest() {
  describe('UrlLauncherSetupTest', () => {
    let messenger: FakeBinaryMessenger;
    let launcher: UrlLauncher;

    beforeAll(() => {
      messenger = new FakeBinaryMessenger();
      launcher = new UrlLauncher(null as ESObject);
      launcher.setup(messenger as ESObject, launcher as ESObject);
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    // ---------- Channel registration ----------
    it('setup_registers_canLaunchUrl_channel', 0, () => {
      expect(messenger.registered.get(CH_CAN_LAUNCH) !== null).assertTrue();
    });

    it('setup_registers_launchUrl_channel', 0, () => {
      expect(messenger.registered.get(CH_LAUNCH) !== null).assertTrue();
    });

    it('setup_registers_openUrlInWebView_channel', 0, () => {
      expect(messenger.registered.get(CH_OPEN_WEBVIEW) !== null).assertTrue();
    });

    it('setup_registers_closeWebView_channel', 0, () => {
      expect(messenger.registered.get(CH_CLOSE_WEBVIEW) !== null).assertTrue();
    });

    it('setup_registers_exactly_four_channels', 0, () => {
      expect(messenger.registered.size).assertEqual(4);
    });

    // ---------- null-argument guards ----------
    it('setup_null_messenger_is_noop', 0, () => {
      // A null messenger returns directly without touching any registration state
      // (the existing 4 registered channels stay untouched)
      let before: number = messenger.registered.size;
      launcher.setup(null as ESObject, launcher as ESObject);
      expect(messenger.registered.size).assertEqual(before);
      expect(messenger.registered.get(CH_CAN_LAUNCH) !== null).assertTrue();
    });

    it('setup_null_api_deregisters_all_four_channels', 0, () => {
      let m2 = new FakeBinaryMessenger();
      m2.registered.set(CH_CAN_LAUNCH, {} as BinaryMessageHandler);
      m2.registered.set(CH_LAUNCH, {} as BinaryMessageHandler);
      m2.registered.set(CH_OPEN_WEBVIEW, {} as BinaryMessageHandler);
      m2.registered.set(CH_CLOSE_WEBVIEW, {} as BinaryMessageHandler);
      launcher.setup(m2 as ESObject, null as ESObject);
      expect(m2.registered.get(CH_CAN_LAUNCH)).assertNull();
      expect(m2.registered.get(CH_LAUNCH)).assertNull();
      expect(m2.registered.get(CH_OPEN_WEBVIEW)).assertNull();
      expect(m2.registered.get(CH_CLOSE_WEBVIEW)).assertNull();
    });

    it('setup_undefined_api_deregisters_all_channels', 0, () => {
      // The api != null && api != undefined guard: undefined also takes the deregistration branch
      let m3 = new FakeBinaryMessenger();
      m3.registered.set(CH_CAN_LAUNCH, {} as BinaryMessageHandler);
      m3.registered.set(CH_LAUNCH, {} as BinaryMessageHandler);
      m3.registered.set(CH_OPEN_WEBVIEW, {} as BinaryMessageHandler);
      m3.registered.set(CH_CLOSE_WEBVIEW, {} as BinaryMessageHandler);
      launcher.setup(m3 as ESObject, undefined as ESObject);
      expect(m3.registered.get(CH_CAN_LAUNCH)).assertNull();
      expect(m3.registered.get(CH_LAUNCH)).assertNull();
      expect(m3.registered.get(CH_OPEN_WEBVIEW)).assertNull();
      expect(m3.registered.get(CH_CLOSE_WEBVIEW)).assertNull();
    });

    // ---------- Repeated setup overwrites ----------
    it('setup_reregistration_keeps_channel_set_stable', 0, () => {
      let m4 = new FakeBinaryMessenger();
      launcher.setup(m4 as ESObject, launcher as ESObject);
      launcher.setup(m4 as ESObject, launcher as ESObject);
      // Channel names are fixed; after repeated setup all 4 channels remain actively registered
      // (Map keys overwritten, nothing added or lost)
      expect(m4.registered.size).assertEqual(4);
      expect(m4.registered.get(CH_CAN_LAUNCH) !== null).assertTrue();
      expect(m4.registered.get(CH_LAUNCH) !== null).assertTrue();
      expect(m4.registered.get(CH_OPEN_WEBVIEW) !== null).assertTrue();
      expect(m4.registered.get(CH_CLOSE_WEBVIEW) !== null).assertTrue();
    });
  });
}
