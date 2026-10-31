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
import { UrlLauncher, FlutterError, WebViewOptions, BrowserOptions } from '../../../../index';
import {
  BinaryMessenger,
  TaskQueue,
  BinaryMessageHandler,
  BinaryReply,
  TaskQueueOptions
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';

const CH_CAN_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl';
const CH_LAUNCH = 'dev.flutter.pigeon.UrlLauncherApi.launchUrl';
const CH_OPEN_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView';
const CH_CLOSE_WEBVIEW = 'dev.flutter.pigeon.UrlLauncherApi.closeWebView';

/** Fake messenger that captures registered handlers */
class FakeBinaryMessenger implements BinaryMessenger {
  public registered: Map<string, BinaryMessageHandler | null> = new Map();

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
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

/** Captures binary replies */
class ReplyCaptor implements BinaryReply {
  public replyValue: ArrayBuffer | null = null;

  reply(reply: ArrayBuffer | null): void {
    this.replyValue = reply;
  }
}

/** Fake context: startAbility success/failure is injectable and the Want is recorded */
class FakeContext {
  behavior: string = 'success';
  failCode: number = 16000001;
  wants: Array<Record<string, Object>> = [];

  startAbility(want: Record<string, Object>): Promise<void> {
    this.wants.push(want);
    if (this.behavior === 'fail') {
      return Promise.reject({ code: this.failCode, message: 'fail' });
    }
    return Promise.resolve();
  }
}

/**
 * Builds message byte streams by hand following StandardMessageCodec semantics.
 * Byte layout: type(1B) + payload; LIST=12, STRING=7, NULL=0, TRUE=1, FALSE=2, MAP=13.
 */
function encodeStandardMessage(value: ESObject): ArrayBuffer {
  let stream = ByteBuffer.from(new ArrayBuffer(1024));
  writeStandardValue(stream, value);
  return stream.buffer;
}

function writeStandardValue(stream: ByteBuffer, value: ESObject): void {
  if (value === null || value === undefined) {
    stream.writeInt8(0); // NULL
  } else if (typeof value === 'boolean') {
    stream.writeInt8(value ? 1 : 2); // TRUE / FALSE
  } else if (typeof value === 'string') {
    stream.writeInt8(7); // STRING
    let bytes: Uint8Array = new Uint8Array(1024);
    let len = 0;
    for (let i = 0; i < (value as string).length; i++) {
      bytes[len++] = (value as string).charCodeAt(i) & 0xff;
    }
    writeStandardSize(stream, len);
    for (let i = 0; i < len; i++) {
      stream.writeUint8(bytes[i]);
    }
  } else if (value instanceof Array) {
    stream.writeInt8(12); // LIST
    writeStandardSize(stream, value.length);
    for (let i = 0; i < value.length; i++) {
      writeStandardValue(stream, value[i]);
    }
  } else if (value instanceof Map) {
    // MAP = alternating key + value
    stream.writeInt8(13); // MAP
    let map: Map<ESObject, ESObject> = value as Map<ESObject, ESObject>;
    writeStandardSize(stream, map.size);
    map.forEach((v: ESObject, k: ESObject) => {
      writeStandardValue(stream, k);
      writeStandardValue(stream, v);
    });
  } else if (value instanceof WebViewOptions) {
    // Custom type 128: the payload is a standard LIST encoding (matching Pigeon writeValue(toList()))
    stream.writeInt8(128);
    let opts: WebViewOptions = value as WebViewOptions;
    let list: Array<ESObject> = [opts.getEnableJavaScript(), opts.getEnableDomStorage(), opts.getHeaders()];
    writeStandardValue(stream, list);
  } else if (value instanceof BrowserOptions) {
    // Custom type 129: the payload is a standard LIST encoding
    stream.writeInt8(129);
    let opts: BrowserOptions = value as BrowserOptions;
    let list: Array<ESObject> = [opts.getShowTitle()];
    writeStandardValue(stream, list);
  } else {
    throw new Error('unsupported encode type');
  }
}

function writeStandardSize(stream: ByteBuffer, value: number): void {
  if (value < 254) {
    stream.writeUint8(value);
  } else {
    throw new Error('size too large for test');
  }
}

/** Decodes a reply: takes only the first top-level element (TRUE/FALSE/NULL/LIST) */
function decodeStandardMessage(message: ArrayBuffer | null): ESObject {
  if (message === null || message === undefined) {
    return null;
  }
  let buffer = ByteBuffer.from(message);
  return readStandardValue(buffer);
}

function readStandardValue(buffer: ByteBuffer): ESObject {
  let type = buffer.readUint8();
  if (type === 0) {
    return null;
  }
  if (type === 1) {
    return true;
  }
  if (type === 2) {
    return false;
  }
  if (type === 7) { // STRING
    let len = buffer.readUint8();
    let str = '';
    for (let i = 0; i < len; i++) {
      str += String.fromCharCode(buffer.readUint8());
    }
    return str;
  }
  if (type === 12) { // LIST
    let len = buffer.readUint8();
    let arr: Array<ESObject> = [];
    for (let i = 0; i < len; i++) {
      arr.push(readStandardValue(buffer));
    }
    return arr;
  }
  throw new Error('unsupported decode type: ' + type);
}

/** Drives a channel handler and returns the decoded reply (synchronous reply scenario) */
function invokeChannel(messenger: FakeBinaryMessenger, channel: string, message: Array<ESObject>): ESObject {
  let handler = messenger.registered.get(channel);
  if (handler === null || handler === undefined) {
    throw new Error('handler not registered: ' + channel);
  }
  let captor = new ReplyCaptor();
  handler.onMessage(encodeStandardMessage(message), captor);
  return decodeStandardMessage(captor.replyValue);
}

/**
 * Drives an async channel (launchUrl / openUrlInWebView): the handler starts a Promise.then
 * internally, so several microtask cycles must be awaited before the reply lands.
 */
async function invokeChannelAsync(messenger: FakeBinaryMessenger, channel: string,
  message: Array<ESObject>): Promise<ESObject> {
  let handler = messenger.registered.get(channel);
  if (handler === null || handler === undefined) {
    throw new Error('handler not registered: ' + channel);
  }
  let captor = new ReplyCaptor();
  handler.onMessage(encodeStandardMessage(message), captor);
  for (let i = 0; i < 20; i++) {
    await Promise.resolve();
    if (captor.replyValue !== null) {
      break;
    }
  }
  return decodeStandardMessage(captor.replyValue);
}

export default function urlLauncherChannelTest() {
  describe('UrlLauncherChannelTest', () => {
    let launcher: UrlLauncher = new UrlLauncher(null as ESObject);
    let ctx: FakeContext = new FakeContext();
    let messenger: FakeBinaryMessenger = new FakeBinaryMessenger();

    beforeAll(() => {
      ctx = new FakeContext();
      launcher = new UrlLauncher(ctx as ESObject);
      messenger = new FakeBinaryMessenger();
      launcher.setup(messenger as ESObject, launcher as ESObject);
    });
    beforeEach(() => {
      ctx.behavior = 'success';
      ctx.wants = [];
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    // ---------- canLaunchUrl channel ----------
    it('channel_canLaunchUrl_success_replies_true', 0, () => {
      // http prefix: canOpenLink misses and falls back to the prefix check → true
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, ['http://example.com']);
      // A Pigeon success reply is a single-element [result] list
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
    });

    it('channel_canLaunchUrl_unsupported_scheme_replies_false', 0, () => {
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, ['ftp://example.com']);
      // A Pigeon success reply is a single-element [result] list
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    it('channel_canLaunchUrl_empty_args_replies_false', 0, () => {
      // Empty args: args[0] is undefined, the canLaunchUrl prefix check misses → success reply [false]
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, []);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    it('channel_canLaunchUrl_null_url_replies_false', 0, () => {
      // url is null: encodeURI(null)='null', the prefix check misses → success reply [false]
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, [null]);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    // ---------- launchUrl channel (async) ----------
    it('channel_launchUrl_web_success_replies_true_and_starts_ability', 0, async () => {
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['https://example.com', []]);
      // A Pigeon success reply is a single-element [result] list
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
      expect(ctx.wants.length).assertEqual(1);
      expect(ctx.wants[0]['uri']).assertEqual('https://example.com');
    });

    it('channel_launchUrl_missing_headers_replies_typeerror', 0, async () => {
      // Insufficient args (only 1 element): args[1] is undefined → rawHeaders.forEach throws TypeError
      // → wrapError plain-error reply [name, message, stacktrace]
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['https://example.com']);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr.length).assertEqual(3);
      expect(arr[0]).assertEqual('TypeError');
    });

    it('channel_launchUrl_startAbility_fail_replies_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      ctx.failCode = 16000019;
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['mailto:a@b.c', []]);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr[0]).assertEqual('LAUNCH_ERROR');
      expect(arr[2]).assertEqual('16000019');
    });

    it('channel_launchUrl_with_headers_map_success_replies_true', 0, async () => {
      // A non-empty headers Map → the forEach filtering branch inside the anonymous callback runs
      let headers: Map<string, string> = new Map<string, string>();
      headers.set('X-Token', 'abc');
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['https://example.com', headers]);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
      expect(ctx.wants.length).assertEqual(1);
    });

    // ---------- openUrlInWebView channel (async) ----------
    it('channel_openUrlInWebView_with_options_replies_result', 0, async () => {
      // Full 3 args (url + WebViewOptions(128) + BrowserOptions(129)) → argument parsing and the then callback run
      let headers: Map<string, string> = new Map<string, string>();
      headers.set('harmony_browser_page', 'pages/NotExists');
      let opts: WebViewOptions = WebViewOptions.fromList([true, true, headers]);
      let browserOpts: BrowserOptions = BrowserOptions.fromList([true]);
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com', opts, browserOpts]);
      // pushUrl fails → wrapError three-element list
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr[0]).assertEqual('LAUNCH_ERROR');
    });

    it('channel_openUrlInWebView_null_options_replies_typeerror', 0, async () => {
      // args[1] is null: options.getHeaders() throws TypeError (thrown synchronously inside the
      // async function → Promise rejection)
      // → wrapError plain-error reply [name, message, stacktrace]
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com', null, null]);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr.length).assertEqual(3);
      expect(arr[0]).assertEqual('TypeError');
    });

    it('channel_openUrlInWebView_missing_options_replies_typeerror', 0, async () => {
      // Insufficient args (url only): args[1]/args[2] are undefined → options.getHeaders() throws TypeError
      // → wrapError plain-error reply [name, message, stacktrace]
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com']);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr.length).assertEqual(3);
      expect(arr[0]).assertEqual('TypeError');
    });

    // ---------- closeWebView channel ----------
    it('channel_closeWebView_success_replies_null', 0, () => {
      // emitter.emit('closeWebView') returns normally with no subscribers, wrapped=[null]
      let reply: ESObject = invokeChannel(messenger, CH_CLOSE_WEBVIEW, []);
      // A Pigeon void reply is a single-element [null] list
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0] === null).assertTrue();
    });
  });
}
