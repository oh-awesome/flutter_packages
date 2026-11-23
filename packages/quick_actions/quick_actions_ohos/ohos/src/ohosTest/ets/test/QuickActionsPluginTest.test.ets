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

import { describe, beforeEach, afterEach, it, expect } from '@ohos/hypium';
import { FlutterPluginBinding, StandardMessageCodec } from '@ohos/flutter_ohos';
import QuickActionsPlugin, { EXTRA_ACTION } from '../../../../src/main/ets/QuickActionsPlugin';

const CHANNEL_GET: string = 'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.getLaunchAction';
const CHANNEL_SET: string = 'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.setShortcutItems';
const CHANNEL_CLEAR: string = 'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.clearShortcutItems';
const CHANNEL_FLUTTER_API: string =
  'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsFlutterApi.launchAction';
const CODE_GET: string = 'quick_action_getlaunchaction_failure';
const CODE_SET: string = 'quick_action_setshortcutitems_failure';
const CODE_CLEAR: string = 'quick_action_clearshortcutitems_failure';
const CODE_DECODE: string = 'quick_action_decodeshortcutitem_failure';
const TYPE_NULL: number = 0;
const TYPE_LIST: number = 12;
const TYPE_SHORTCUT_ITEM: number = 128;

/// Records setMessageHandler/send traffic instead of talking to a real engine.
class FakeMessenger {
  handlerRegistrations: Array<string> = [];
  handlers: Map<string, Object | null> = new Map();
  nullRegistrations: Array<string> = [];
  sendNames: Array<string> = [];
  sendPayloads: Array<ArrayBuffer | null> = [];
  failSends: number = 0;

  setMessageHandler(channel: string, handler: Object | null): void {
    if (handler === null) {
      this.nullRegistrations.push(channel);
    }
    this.handlers.set(channel, handler);
    this.handlerRegistrations.push(channel);
  }

  send(channel: string, message: Object | null, callback?: Object): void {
    if (this.failSends > 0) {
      this.failSends--;
      throw new Error('messenger send failed');
    }
    this.sendNames.push(channel);
    this.sendPayloads.push(message as ArrayBuffer | null);
  }
}

/// Duck-typed FlutterPluginBinding: the plugin only calls getBinaryMessenger().
class FakeBinding {
  messenger: FakeMessenger = new FakeMessenger();

  getBinaryMessenger(): FakeMessenger {
    return this.messenger;
  }
}

/// Stands in for the engine BinaryReply; can fail the first reply to force the
/// plugin handlers down their error-reporting catch branches.
class FakeReply {
  rawReplies: Array<ArrayBuffer | null> = [];
  failFirstReplies: number = 0;

  reply(message: ArrayBuffer | null): void {
    if (this.rawReplies.length === 0 && this.failFirstReplies > 0) {
      this.failFirstReplies--;
      throw new Error('reply failed');
    }
    this.rawReplies.push(message);
  }

  lastDecoded(): Array<Object | null> {
    const raw: ArrayBuffer | null = this.rawReplies[this.rawReplies.length - 1];
    return StandardMessageCodec.INSTANCE.decodeMessage(raw) as Array<Object | null>;
  }
}

/// Structural stand-in for the non-exported ShortcutItemMessage interface.
class FakeShortcutItem {
  type: string;
  localizedTitle: string;

  constructor(type: string, localizedTitle: string) {
    this.type = type;
    this.localizedTitle = localizedTitle;
  }
}

function asBinding(binding: FakeBinding): FlutterPluginBinding {
  return binding as ESObject as FlutterPluginBinding;
}

function bytesOf(nums: Array<number>): Uint8Array {
  const out: Uint8Array = new Uint8Array(nums.length);
  for (let i = 0; i < nums.length; i++) {
    out[i] = nums[i];
  }
  return out;
}

function concatViews(parts: Array<Uint8Array>): Uint8Array {
  let total: number = 0;
  for (const part of parts) {
    total += part.length;
  }
  const out: Uint8Array = new Uint8Array(total);
  let offset: number = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function concatBytes(parts: Array<Uint8Array>): ArrayBuffer {
  return concatViews(parts).buffer;
}

function encoded(value: Object | null): Uint8Array {
  return new Uint8Array(StandardMessageCodec.INSTANCE.encodeMessage(value as ESObject));
}

/// Wire bytes for one ShortcutItemMessage: type byte 128 followed by the
/// standard encoding of the 4-element field array.
function itemWire(fields: Array<Object | null>): Uint8Array {
  return concatViews([bytesOf([TYPE_SHORTCUT_ITEM]), encoded(fields)]);
}

/// Wire bytes for the setShortcutItems message: [[item, item, ...]].
function setItemsMessage(itemWires: Array<Uint8Array>): ArrayBuffer {
  const head: Uint8Array = bytesOf([TYPE_LIST, 1, TYPE_LIST, itemWires.length]);
  const parts: Array<Uint8Array> = [head];
  for (const wire of itemWires) {
    parts.push(wire);
  }
  return concatBytes(parts);
}

function encodedNull(): ArrayBuffer {
  return concatBytes([bytesOf([TYPE_NULL])]);
}

/// Feeds raw channel bytes through the captured IncomingMessageHandler, i.e.
/// through the real codec and the real plugin handler, exactly like the engine.
function driveChannel(messenger: FakeMessenger, channel: string, message: ArrayBuffer | null,
  reply: FakeReply): void {
  const wrapper: ESObject = messenger.handlers.get(channel) as ESObject;
  wrapper.onMessage(message, reply);
}

function storedItems(plugin: QuickActionsPlugin): ESObject {
  return (plugin as ESObject)._shortcutItems as ESObject;
}

let plugin: QuickActionsPlugin = new QuickActionsPlugin();
let binding: FakeBinding = new FakeBinding();
let messenger: FakeMessenger = binding.messenger;
let attached: boolean = false;

function attachPlugin(): void {
  plugin.onAttachedToEngine(asBinding(binding));
  attached = true;
}

function detachPlugin(): void {
  plugin.onDetachedFromEngine(asBinding(binding));
  attached = false;
}

export default function QuickActionsPluginTest() {
  describe('QuickActionsPluginTest', () => {
    beforeEach(() => {
      plugin = new QuickActionsPlugin();
      binding = new FakeBinding();
      messenger = binding.messenger;
      attached = false;
    });

    afterEach(() => {
      if (attached) {
        detachPlugin();
      }
    });

    it('extraActionConstantHasStableValue', 0, () => {
      expect(EXTRA_ACTION).assertEqual('flutter_quick_action');
    });

    it('getUniqueClassNameReturnsPluginName', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('QuickActionsPlugin');
    });

    it('getInstanceIsNullBeforeAttachAndAfterDetach', 0, () => {
      expect(QuickActionsPlugin.getInstance()).assertNull();
      attachPlugin();
      expect(QuickActionsPlugin.getInstance() === plugin).assertTrue();
      detachPlugin();
      expect(QuickActionsPlugin.getInstance()).assertNull();
    });

    it('attachRegistersAllThreeChannelHandlers', 0, () => {
      attachPlugin();
      expect(messenger.handlerRegistrations.length).assertEqual(3);
      expect(messenger.handlerRegistrations[0]).assertEqual(CHANNEL_GET);
      expect(messenger.handlerRegistrations[1]).assertEqual(CHANNEL_SET);
      expect(messenger.handlerRegistrations[2]).assertEqual(CHANNEL_CLEAR);
      expect(messenger.handlers.get(CHANNEL_GET) !== null).assertTrue();
      expect(messenger.handlers.get(CHANNEL_SET) !== null).assertTrue();
      expect(messenger.handlers.get(CHANNEL_CLEAR) !== null).assertTrue();
      expect(messenger.nullRegistrations.length).assertEqual(0);
    });

    it('attachConsumesPendingLaunchActionOnce', 0, () => {
      QuickActionsPlugin.dispatchShortcutAction('cold.start.action');
      attachPlugin();
      expect(plugin.getLaunchActionValue()).assertEqual('cold.start.action');
      expect(plugin.getLaunchActionValue()).assertNull();
      detachPlugin();
      const second: QuickActionsPlugin = new QuickActionsPlugin();
      second.onAttachedToEngine(asBinding(binding));
      expect(second.getLaunchActionValue()).assertNull();
      second.onDetachedFromEngine(asBinding(binding));
    });

    it('attachIgnoresEmptyPendingLaunchAction', 0, () => {
      QuickActionsPlugin.dispatchShortcutAction('');
      attachPlugin();
      expect(plugin.getLaunchActionValue()).assertNull();
    });

    it('dispatchShortcutActionWhileAttachedSendsOnFlutterApiChannel', 0, () => {
      attachPlugin();
      QuickActionsPlugin.dispatchShortcutAction('main.action');
      expect(messenger.sendNames.length).assertEqual(1);
      expect(messenger.sendNames[0]).assertEqual(CHANNEL_FLUTTER_API);
      const payload: Array<Object | null> =
        StandardMessageCodec.INSTANCE.decodeMessage(messenger.sendPayloads[0]) as Array<Object | null>;
      expect(payload.length).assertEqual(1);
      expect(payload[0]).assertEqual('main.action');
      expect(plugin.getLaunchActionValue()).assertEqual('main.action');
      plugin.handleShortcutAction('secondary.action');
      expect(messenger.sendNames.length).assertEqual(2);
      expect(plugin.getLaunchActionValue()).assertEqual('secondary.action');
    });

    it('dispatchShortcutActionSwallowsSendFailure', 0, () => {
      attachPlugin();
      messenger.failSends = 1;
      QuickActionsPlugin.dispatchShortcutAction('still.recorded');
      expect(plugin.getLaunchActionValue()).assertEqual('still.recorded');
      QuickActionsPlugin.dispatchShortcutAction('after.recovery');
      expect(messenger.sendNames.length).assertEqual(1);
      expect(plugin.getLaunchActionValue()).assertEqual('after.recovery');
    });

    it('setShortcutItemsStoresItemsInMemory', 0, () => {
      plugin.setShortcutItems([new FakeShortcutItem('one', 'One'), new FakeShortcutItem('two', 'Two')]);
      const stored: ESObject = storedItems(plugin);
      expect(stored.length).assertEqual(2);
      expect(stored[1].localizedTitle).assertEqual('Two');
    });

    it('clearShortcutItemsClearsItemsButKeepsLaunchAction', 0, () => {
      attachPlugin();
      plugin.setShortcutItems([new FakeShortcutItem('one', 'One')]);
      plugin.handleShortcutAction('keep.me');
      plugin.clearShortcutItems();
      expect(storedItems(plugin).length).assertEqual(0);
      expect(plugin.getLaunchActionValue()).assertEqual('keep.me');
    });

    it('detachDeregistersHandlersAndClearsState', 0, () => {
      attachPlugin();
      const getWrapper: ESObject = messenger.handlers.get(CHANNEL_GET) as ESObject;
      detachPlugin();
      expect(messenger.nullRegistrations.length).assertEqual(3);
      expect(messenger.handlers.get(CHANNEL_GET)).assertNull();
      expect(QuickActionsPlugin.getInstance()).assertNull();
      expect(plugin.getLaunchActionValue()).assertNull();
      const reply: FakeReply = new FakeReply();
      getWrapper.onMessage(encodedNull(), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(3);
      expect(decoded[0]).assertEqual(CODE_GET);
      expect(decoded[1] as string).assertContain('handler detached');
    });

    it('detachTwiceIsSafe', 0, () => {
      attachPlugin();
      detachPlugin();
      detachPlugin();
      expect(messenger.nullRegistrations.length).assertEqual(3);
      expect(QuickActionsPlugin.getInstance()).assertNull();
    });

    it('getLaunchActionChannelRepliesRecordedActionOnce', 0, () => {
      attachPlugin();
      plugin.handleShortcutAction('channel.action');
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_GET, encodedNull(), reply);
      let decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(1);
      expect(decoded[0]).assertEqual('channel.action');
      driveChannel(messenger, CHANNEL_GET, encodedNull(), reply);
      decoded = reply.lastDecoded();
      expect(decoded.length).assertEqual(1);
      expect(decoded[0]).assertNull();
    });

    it('getLaunchActionChannelDecodesStandardMessageTypes', 0, () => {
      attachPlugin();
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_GET,
        StandardMessageCodec.INSTANCE.encodeMessage('ignored.payload' as ESObject), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(1);
      expect(decoded[0]).assertNull();
    });

    it('getLaunchActionChannelReportsReplyFailure', 0, () => {
      attachPlugin();
      plugin.handleShortcutAction('lost.in.failure');
      const reply: FakeReply = new FakeReply();
      reply.failFirstReplies = 1;
      driveChannel(messenger, CHANNEL_GET, encodedNull(), reply);
      expect(reply.rawReplies.length).assertEqual(1);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(3);
      expect(decoded[0]).assertEqual(CODE_GET);
      expect(decoded[1] as string).assertContain('getLaunchAction failed');
    });

    it('setShortcutItemsChannelStoresDecodedItems', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([
        itemWire(['main.one', 'Title One', 'Subtitle One', 'icon_one']),
        itemWire(['main.two', 'Title Two', null, null])
      ]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(1);
      expect(decoded[0]).assertNull();
      const stored: ESObject = storedItems(plugin);
      expect(stored.length).assertEqual(2);
      expect(stored[0].type).assertEqual('main.one');
      expect(stored[0].localizedTitle).assertEqual('Title One');
      expect(stored[0].localizedSubtitle).assertEqual('Subtitle One');
      expect(stored[0].icon).assertEqual('icon_one');
      expect(stored[1].type).assertEqual('main.two');
      expect(stored[1].localizedTitle).assertEqual('Title Two');
      expect(stored[1].localizedSubtitle === undefined).assertTrue();
      expect(stored[1].icon === undefined).assertTrue();
    });

    it('setShortcutItemsChannelDecodesNullFieldsToDefaults', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([itemWire([null, null, null, null])]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      expect(reply.lastDecoded()[0]).assertNull();
      const stored: ESObject = storedItems(plugin);
      expect(stored.length).assertEqual(1);
      expect(stored[0].type).assertEqual('');
      expect(stored[0].localizedTitle).assertEqual('');
      expect(stored[0].localizedSubtitle === undefined).assertTrue();
      expect(stored[0].icon === undefined).assertTrue();
    });

    it('setShortcutItemsChannelRejectsEmptyArgsList', 0, () => {
      attachPlugin();
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, concatBytes([bytesOf([TYPE_LIST, 0])]), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_DECODE);
      expect(decoded[1] as string).assertContain('missing items argument');
    });

    it('setShortcutItemsChannelRejectsNullItemWire', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([
        concatViews([bytesOf([TYPE_SHORTCUT_ITEM]), bytesOf([TYPE_NULL])])
      ]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_DECODE);
      expect(decoded[1] as string).assertContain('null ShortcutItemMessage');
    });

    it('setShortcutItemsChannelRejectsNonArrayItemWire', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([
        concatViews([bytesOf([TYPE_SHORTCUT_ITEM]), encoded('not.an.array')])
      ]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_DECODE);
      expect(decoded[1] as string).assertContain('null ShortcutItemMessage');
    });

    it('setShortcutItemsChannelRejectsShortArrayItemWire', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([
        concatViews([bytesOf([TYPE_SHORTCUT_ITEM]), encoded(['too.short'])])
      ]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_DECODE);
      expect(decoded[1] as string).assertContain('null ShortcutItemMessage');
    });

    it('setShortcutItemsChannelHandlesTruncatedItemWire', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([
        concatViews([bytesOf([TYPE_SHORTCUT_ITEM, TYPE_LIST, 2])])
      ]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, message, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_DECODE);
      expect(decoded[1] as string).assertContain('null ShortcutItemMessage');
    });

    it('setShortcutItemsChannelReportsNullMessage', 0, () => {
      attachPlugin();
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_SET, null, reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_SET);
      expect(decoded[1] as string).assertContain('setShortcutItems failed');
    });

    it('setShortcutItemsChannelReportsReplyFailure', 0, () => {
      attachPlugin();
      const message: ArrayBuffer = setItemsMessage([itemWire(['main.one', 'Title One', null, null])]);
      const reply: FakeReply = new FakeReply();
      reply.failFirstReplies = 1;
      driveChannel(messenger, CHANNEL_SET, message, reply);
      expect(reply.rawReplies.length).assertEqual(1);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_SET);
      expect(decoded[1] as string).assertContain('setShortcutItems failed');
    });

    it('setShortcutItemsChannelReportsDetachedHandler', 0, () => {
      attachPlugin();
      const setWrapper: ESObject = messenger.handlers.get(CHANNEL_SET) as ESObject;
      detachPlugin();
      const reply: FakeReply = new FakeReply();
      setWrapper.onMessage(encodedNull(), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_SET);
      expect(decoded[1] as string).assertContain('handler detached');
    });

    it('clearShortcutItemsChannelClearsStoredItems', 0, () => {
      attachPlugin();
      plugin.setShortcutItems([new FakeShortcutItem('one', 'One')]);
      const reply: FakeReply = new FakeReply();
      driveChannel(messenger, CHANNEL_CLEAR, encodedNull(), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded.length).assertEqual(1);
      expect(decoded[0]).assertNull();
      expect(storedItems(plugin).length).assertEqual(0);
    });

    it('clearShortcutItemsChannelReportsReplyFailure', 0, () => {
      attachPlugin();
      const reply: FakeReply = new FakeReply();
      reply.failFirstReplies = 1;
      driveChannel(messenger, CHANNEL_CLEAR, encodedNull(), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_CLEAR);
      expect(decoded[1] as string).assertContain('clearShortcutItems failed');
    });

    it('clearShortcutItemsChannelReportsDetachedHandler', 0, () => {
      attachPlugin();
      const clearWrapper: ESObject = messenger.handlers.get(CHANNEL_CLEAR) as ESObject;
      detachPlugin();
      const reply: FakeReply = new FakeReply();
      clearWrapper.onMessage(encodedNull(), reply);
      const decoded: Array<Object | null> = reply.lastDecoded();
      expect(decoded[0]).assertEqual(CODE_CLEAR);
      expect(decoded[1] as string).assertContain('handler detached');
    });

    it('deliverShortcutActionWithoutChannelStillRecordsAction', 0, () => {
      attachPlugin();
      (plugin as ESObject)._flutterApiChannel = null;
      plugin.handleShortcutAction('silent.action');
      expect(messenger.sendNames.length).assertEqual(0);
      expect(plugin.getLaunchActionValue()).assertEqual('silent.action');
    });
  });
}
