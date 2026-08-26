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
import {
  FlutterError,
  wrapError,
  WebViewOptions,
  BrowserOptions,
  UrlLauncherApiCodec
} from '../../../../index';

/**
 * Messages.ets 单元测试（数据类、wrapError、Codec 纯逻辑分支）
 */
export default function messagesTest() {
  describe('MessagesTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    // ---------- FlutterError ----------
    it('flutterError_properties', 0, () => {
      let err = new FlutterError('CODE', 'message', 'detail');
      expect(err.code).assertEqual('CODE');
      expect(err.message).assertEqual('message');
      expect(err.details).assertEqual('detail');
    });

    it('flutterError_is_error_instance', 0, () => {
      let err = new FlutterError('CODE', 'message', null);
      expect(err instanceof Error).assertTrue();
    });

    // ---------- wrapError ----------
    it('wrapError_flutterError_returns_code_message_details', 0, () => {
      let err = new FlutterError('INVALID_URL', 'url empty', 'extra');
      let wrapped = wrapError(err as ESObject);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('INVALID_URL');
      expect(wrapped[1]).assertEqual('url empty');
      expect(wrapped[2]).assertEqual('extra');
    });

    it('wrapError_plainError_returns_name_message_stacktrace', 0, () => {
      let err = new Error('boom');
      let wrapped = wrapError(err as ESObject);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('Error');
      expect(wrapped[1]).assertEqual('boom');
      expect((wrapped[2] as string).startsWith('Stacktrace: ')).assertTrue();
    });

    // ---------- WebViewOptions ----------
    it('webViewOptions_fromList_sets_fields', 0, () => {
      let headers = new Map<string, string>();
      headers.set('k', 'v');
      let options = WebViewOptions.fromList([true, false, headers] as Array<Object>);
      expect(options.getEnableJavaScript()).assertTrue();
      expect(options.getEnableDomStorage()).assertFalse();
      expect(options.getHeaders().get('k')).assertEqual('v');
    });

    it('webViewOptions_fromList_null_throws', 0, () => {
      let caught: Error | null = null;
      try {
        WebViewOptions.fromList(null as ESObject as Array<Object>);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught !== null).assertTrue();
    });

    it('webViewOptions_fromList_too_short_throws', 0, () => {
      let caught: Error | null = null;
      try {
        WebViewOptions.fromList([true] as Array<Object>);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught !== null).assertTrue();
    });

    it('webViewOptions_toList_roundtrip', 0, () => {
      let headers = new Map<string, string>();
      headers.set('k', 'v');
      let options = WebViewOptions.fromList([true, true, headers]);
      let list: Array<ESObject> = options.toList();
      expect(list.length).assertEqual(3);
      expect(list[0]).assertTrue();
      expect(list[1]).assertTrue();
      let restored = WebViewOptions.fromList(list as Array<Object>);
      expect(restored.getEnableJavaScript()).assertTrue();
      expect(restored.getEnableDomStorage()).assertTrue();
      expect(restored.getHeaders().get('k')).assertEqual('v');
    });

    it('webViewOptions_setEnableJavaScript_null_throws', 0, () => {
      let options = WebViewOptions.fromList([false, false, new Map<string, string>()] as Array<Object>);
      let caught: Error | null = null;
      try {
        options.setEnableJavaScript(null as ESObject as boolean);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught instanceof ReferenceError).assertTrue();
    });

    it('webViewOptions_setEnableDomStorage_null_throws', 0, () => {
      let empty = new Map<string, string>();
      let options = WebViewOptions.fromList([false, false, empty] as Array<Object>);
      let caught: Error | null = null;
      try {
        options.setEnableDomStorage(null as ESObject as boolean);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught instanceof ReferenceError).assertTrue();
    });

    it('webViewOptions_setHeaders_null_throws', 0, () => {
      let empty = new Map<string, string>();
      let options = WebViewOptions.fromList([false, false, empty] as Array<Object>);
      let caught: Error | null = null;
      try {
        options.setHeaders(null as ESObject as Map<string, string>);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught instanceof ReferenceError).assertTrue();
    });

    it('webViewOptions_setHeaders_filters_null_entries', 0, () => {
      // Dart 侧 Pigeon 生成 Map<String?, String?> 允许 null key/value，
      // setHeaders 应过滤 null entry 避免运行时异常
      let raw = new Map<string, string>();
      raw.set('valid', 'v');
      raw.set('nullValue' as string, null as ESObject as string);
      let options = WebViewOptions.fromList([false, false, new Map<string, string>()]);
      options.setHeaders(raw);
      expect(options.getHeaders().size).assertEqual(1);
      expect(options.getHeaders().get('valid')).assertEqual('v');
    });

    // ---------- BrowserOptions ----------
    it('browserOptions_fromList_sets_field', 0, () => {
      let options = BrowserOptions.fromList([true]);
      expect(options.getShowTitle()).assertTrue();
    });

    it('browserOptions_fromList_null_throws', 0, () => {
      let caught: Error | null = null;
      try {
        BrowserOptions.fromList(null as ESObject as Array<Object>);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught !== null).assertTrue();
    });

    it('browserOptions_fromList_empty_throws', 0, () => {
      let caught: Error | null = null;
      try {
        BrowserOptions.fromList([]);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught !== null).assertTrue();
    });

    it('browserOptions_toList_roundtrip', 0, () => {
      let options = BrowserOptions.fromList([false]);
      let list: Array<ESObject> = options.toList();
      expect(list.length).assertEqual(1);
      expect(list[0]).assertFalse();
      let restored = BrowserOptions.fromList(list as Array<Object>);
      expect(restored.getShowTitle()).assertFalse();
    });

    it('browserOptions_setShowTitle_null_throws', 0, () => {
      let options = BrowserOptions.fromList([true]);
      let caught: Error | null = null;
      try {
        options.setShowTitle(null as ESObject as boolean);
      } catch (e) {
        caught = e as Error;
      }
      expect(caught instanceof ReferenceError).assertTrue();
    });

    // ---------- UrlLauncherApiCodec ----------
    it('codec_instance_is_singleton', 0, () => {
      expect(UrlLauncherApiCodec.INSTANCE !== null).assertTrue();
      expect(UrlLauncherApiCodec.INSTANCE).assertEqual(UrlLauncherApiCodec.INSTANCE);
    });

    it('codec_decodeMessage_null_returns_null', 0, () => {
      // 二进制解码入口的 null 守卫（不触碰 @ohos.util 编解码器）
      expect(UrlLauncherApiCodec.INSTANCE.decodeMessage(null)).assertNull();
    });

    // ---------- Codec 编解码往返（真机 ByteBuffer/StandardMessageCodec 可用） ----------
    it('codec_webViewOptions_roundtrip', 0, () => {
      // writeValue(WebViewOptions) → [128, ...toList]；decodeMessage → readValueOfType(128) → fromList
      let headers = new Map<string, string>();
      headers.set('k', 'v');
      let options = WebViewOptions.fromList([true, true, headers]);
      let encoded = UrlLauncherApiCodec.INSTANCE.encodeMessage(options);
      expect(encoded !== null).assertTrue();
      let decoded = UrlLauncherApiCodec.INSTANCE.decodeMessage(encoded) as WebViewOptions;
      expect(decoded instanceof WebViewOptions).assertTrue();
      expect(decoded.getEnableJavaScript()).assertTrue();
      expect(decoded.getEnableDomStorage()).assertTrue();
      expect(decoded.getHeaders().get('k')).assertEqual('v');
    });

    it('codec_browserOptions_roundtrip', 0, () => {
      let options = BrowserOptions.fromList([true]);
      let encoded = UrlLauncherApiCodec.INSTANCE.encodeMessage(options);
      let decoded = UrlLauncherApiCodec.INSTANCE.decodeMessage(encoded) as BrowserOptions;
      expect(decoded instanceof BrowserOptions).assertTrue();
      expect(decoded.getShowTitle()).assertTrue();
    });

    it('codec_primitive_values_fallthrough', 0, () => {
      // 基础类型走 super.writeValue / super.readValueOfType 默认分支
      let encoded: ArrayBuffer = UrlLauncherApiCodec.INSTANCE.encodeMessage('hello');
      let decoded: ESObject = UrlLauncherApiCodec.INSTANCE.decodeMessage(encoded);
      expect(decoded).assertEqual('hello');
      let encodedBool: ArrayBuffer = UrlLauncherApiCodec.INSTANCE.encodeMessage(true);
      expect(UrlLauncherApiCodec.INSTANCE.decodeMessage(encodedBool)).assertTrue();
      let encodedNull: ArrayBuffer = UrlLauncherApiCodec.INSTANCE.encodeMessage(null as ESObject);
      expect(UrlLauncherApiCodec.INSTANCE.decodeMessage(encodedNull)).assertNull();
    });
  });
}
