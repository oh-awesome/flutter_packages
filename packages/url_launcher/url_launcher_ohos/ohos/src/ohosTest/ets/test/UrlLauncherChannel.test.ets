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

/** 捕获注册 handler 的 fake messenger */
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

/** 捕获二进制回包 */
class ReplyCaptor implements BinaryReply {
  public replyValue: ArrayBuffer | null = null;

  reply(reply: ArrayBuffer | null): void {
    this.replyValue = reply;
  }
}

/** fake context：startAbility 可注入成败并记录 Want */
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
 * 以 StandardMessageCodec 语义手工构造消息字节流。
 * 字节布局：type(1B) + payload；LIST=12, STRING=7, NULL=0, TRUE=1, FALSE=2, MAP=13。
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
    // MAP = key + value 交替
    stream.writeInt8(13); // MAP
    let map: Map<ESObject, ESObject> = value as Map<ESObject, ESObject>;
    writeStandardSize(stream, map.size);
    map.forEach((v: ESObject, k: ESObject) => {
      writeStandardValue(stream, k);
      writeStandardValue(stream, v);
    });
  } else if (value instanceof WebViewOptions) {
    // 自定义类型 128：payload 为标准 LIST 编码（与 Pigeon writeValue(toList()) 一致）
    stream.writeInt8(128);
    let opts: WebViewOptions = value as WebViewOptions;
    let list: Array<ESObject> = [opts.getEnableJavaScript(), opts.getEnableDomStorage(), opts.getHeaders()];
    writeStandardValue(stream, list);
  } else if (value instanceof BrowserOptions) {
    // 自定义类型 129：payload 为标准 LIST 编码
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

/** 解码回包：仅取第一个顶层元素（TRUE/FALSE/NULL/LIST） */
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

/** 驱动某一通道 handler 并返回解码后的回包（同步 reply 场景） */
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
 * 驱动异步通道（launchUrl / openUrlInWebView）：handler 内部起 Promise.then，
 * 需 await 若干微任务循环让 reply 落地。
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

    // ---------- canLaunchUrl 通道 ----------
    it('channel_canLaunchUrl_success_replies_true', 0, () => {
      // http 前缀：canOpenLink 未命中时回退前缀判断 → true
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, ['http://example.com']);
      // Pigeon 成功回包为 [result] 单元素列表
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
    });

    it('channel_canLaunchUrl_unsupported_scheme_replies_false', 0, () => {
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, ['ftp://example.com']);
      // Pigeon 成功回包为 [result] 单元素列表
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    it('channel_canLaunchUrl_empty_args_replies_false', 0, () => {
      // args 为空：args[0] 为 undefined，canLaunchUrl 前缀判断不命中 → 成功回包 [false]
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, []);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    it('channel_canLaunchUrl_null_url_replies_false', 0, () => {
      // url 为 null：encodeURI(null)='null' 前缀判断不命中 → 成功回包 [false]
      let reply: ESObject = invokeChannel(messenger, CH_CAN_LAUNCH, [null]);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertFalse();
    });

    // ---------- launchUrl 通道（异步） ----------
    it('channel_launchUrl_web_success_replies_true_and_starts_ability', 0, async () => {
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['https://example.com', []]);
      // Pigeon 成功回包为 [result] 单元素列表
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
      expect(ctx.wants.length).assertEqual(1);
      expect(ctx.wants[0]['uri']).assertEqual('https://example.com');
    });

    it('channel_launchUrl_missing_headers_replies_typeerror', 0, async () => {
      // 参数不足（仅 1 个元素）：args[1] 为 undefined → rawHeaders.forEach 抛 TypeError
      // → wrapError 普通错误回包 [name, message, stacktrace]
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
      // headers 非空 Map → 匿名回调内 forEach 过滤分支执行
      let headers: Map<string, string> = new Map<string, string>();
      headers.set('X-Token', 'abc');
      let reply: ESObject = await invokeChannelAsync(messenger, CH_LAUNCH, ['https://example.com', headers]);
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0]).assertTrue();
      expect(ctx.wants.length).assertEqual(1);
    });

    // ---------- openUrlInWebView 通道（异步） ----------
    it('channel_openUrlInWebView_with_options_replies_result', 0, async () => {
      // 完整 3 参数（url + WebViewOptions(128) + BrowserOptions(129)）→ 参数解析与 then 回调执行
      let headers: Map<string, string> = new Map<string, string>();
      headers.set('harmony_browser_page', 'pages/NotExists');
      let opts: WebViewOptions = WebViewOptions.fromList([true, true, headers]);
      let browserOpts: BrowserOptions = BrowserOptions.fromList([true]);
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com', opts, browserOpts]);
      // pushUrl 失败 → wrapError 三元素列表
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr[0]).assertEqual('LAUNCH_ERROR');
    });

    it('channel_openUrlInWebView_null_options_replies_typeerror', 0, async () => {
      // args[1] 为 null：options.getHeaders() 抛 TypeError（async 函数内同步抛出 → Promise 拒绝）
      // → wrapError 普通错误回包 [name, message, stacktrace]
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com', null, null]);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr.length).assertEqual(3);
      expect(arr[0]).assertEqual('TypeError');
    });

    it('channel_openUrlInWebView_missing_options_replies_typeerror', 0, async () => {
      // args 不足（仅 url）：args[1]/args[2] 为 undefined → options.getHeaders() 抛 TypeError
      // → wrapError 普通错误回包 [name, message, stacktrace]
      let reply: ESObject = await invokeChannelAsync(messenger, CH_OPEN_WEBVIEW, ['https://example.com']);
      let arr: Array<ESObject> = reply as Array<ESObject>;
      expect(arr.length).assertEqual(3);
      expect(arr[0]).assertEqual('TypeError');
    });

    // ---------- closeWebView 通道 ----------
    it('channel_closeWebView_success_replies_null', 0, () => {
      // emitter.emit('closeWebView') 无订阅者时正常返回，wrapped=[null]
      let reply: ESObject = invokeChannel(messenger, CH_CLOSE_WEBVIEW, []);
      // Pigeon void 回包为 [null] 单元素列表
      let wrapped: Array<ESObject> = reply as Array<ESObject>;
      expect(wrapped.length).assertEqual(1);
      expect(wrapped[0] === null).assertTrue();
    });
  });
}
