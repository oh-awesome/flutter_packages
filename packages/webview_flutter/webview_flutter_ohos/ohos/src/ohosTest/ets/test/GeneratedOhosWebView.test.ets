/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
 
// Pigeon 生成代码单元测试：错误包装、数据类构造/序列化、编解码器往返、
// FlutterApi 消息通道名。

import { describe, it, expect } from '@ohos/hypium';
import ArrayList from '@ohos.util.ArrayList';
import GeneratedOhosWebView, {
  FlutterError,
  Reply,
  FileChooserMode,
  FileChooserModeEnumData,
  ConsoleMessageLevel,
  ConsoleMessage,
  WebViewPoint,
  WebResourceErrorData,
  WebResourceRequestData,
  WebViewHostApi,
  WebViewFlutterApi,
  WebChromeClientFlutterApi,
  WebViewClientFlutterApi,
  CustomViewCallbackFlutterApi,
  ViewFlutterApi,
  DownloadListenerFlutterApi,
  FileChooserParamsFlutterApi,
  JavaScriptChannelFlutterApi,
  OhosObjectFlutterApi,
  HttpAuthHandlerFlutterApi,
  SslErrorHandlerFlutterApi,
  GeolocationPermissionsCallbackFlutterApi,
  PermissionRequestFlutterApi
} from '../../../main/ets/io.flutter.plugins/webview_flutter/GeneratedOhosWebView';
import { MockBinaryMessenger } from '../testmock/MockBinaryMessenger';
import { coerce } from '../testmock/MockInstances';

const CHANNEL_PREFIX: string = 'dev.flutter.pigeon.webview_flutter_ohos.';

export default function generatedOhosWebViewTest() {
  describe('GeneratedOhosWebViewTest', () => {
    // ---------- 错误包装 ----------
    it('wrapErrorPacksFlutterErrorFields', 0, () => {
      const flutterError: FlutterError = new FlutterError('code1', 'msg1', 'details1');
      // FlutterError 继承的是标准库 Error，ArkTS 不认用户类→内置类的名义子类型，
      // 传参需经 Object 双重断言（运行时行为不变，wrapError 内 instanceof 照常命中）。
      const wrapped: ArrayList<Object> =
        GeneratedOhosWebView.wrapError(flutterError as Object as Error);
      const arr: Array<Object> = wrapped.convertToArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(3);
      expect(`${arr[0]}`).assertEqual('code1');
      expect(`${arr[1]}`).assertEqual('msg1');
      expect(`${arr[2]}`).assertEqual('details1');
    })

    it('wrapErrorPacksPlainErrorFields', 0, () => {
      const wrapped: ArrayList<Object> = GeneratedOhosWebView.wrapError(new Error('boom'));
      const arr: Array<Object> = wrapped.convertToArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(3);
      expect(`${arr[0]}`).assertEqual('Error');
      expect(`${arr[1]}`).assertEqual('boom');
    })

    it('flutterErrorCarriesCodeAndDetails', 0, () => {
      const err: FlutterError = new FlutterError('404', 'not found', 'extra');
      expect(err.code).assertEqual('404');
      expect(err.message).assertEqual('not found');
      expect(err.details).assertEqual('extra');
      expect(err instanceof Error).assertTrue();
    })

    // ---------- 枚举 ----------
    it('fileChooserModeEnumValues', 0, () => {
      expect(FileChooserMode.OPEN).assertEqual(0);
      expect(FileChooserMode.OPEN_MULTIPLE).assertEqual(1);
      expect(FileChooserMode.SAVE).assertEqual(2);
    })

    it('consoleMessageLevelEnumValues', 0, () => {
      expect(ConsoleMessageLevel.DEBUG).assertEqual(0);
      expect(ConsoleMessageLevel.ERROR).assertEqual(1);
      expect(ConsoleMessageLevel.LOG).assertEqual(2);
      expect(ConsoleMessageLevel.TIP).assertEqual(3);
      expect(ConsoleMessageLevel.WARNING).assertEqual(4);
      expect(ConsoleMessageLevel.UNKNOWN).assertEqual(5);
    })

    // ---------- 数据类：FileChooserModeEnumData ----------
    it('fileChooserModeEnumDataBuilderAndToArray', 0, () => {
      const data: FileChooserModeEnumData =
        FileChooserModeEnumData.Builder().setValue(FileChooserMode.SAVE).build();
      expect(data.getValue()).assertEqual(FileChooserMode.SAVE);
      const arr: Array<Object> = data.toArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(1);
      expect(`${arr[0]}`).assertEqual('2');
    })

    it('fileChooserModeEnumDataFromArray', 0, () => {
      const list: Array<Object> = [FileChooserMode.OPEN_MULTIPLE];
      const data: FileChooserModeEnumData = FileChooserModeEnumData.fromArray(list);
      expect(data.getValue()).assertEqual(FileChooserMode.OPEN_MULTIPLE);
    })

    it('fileChooserModeEnumDataRejectsNullValue', 0, () => {
      const data: FileChooserModeEnumData = FileChooserModeEnumData.Builder().build();
      let threw: boolean = false;
      try {
        data.setValue(coerce<FileChooserMode>(undefined));
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- 数据类：WebViewPoint ----------
    it('webViewPointBuilderGettersAndToArray', 0, () => {
      const point: WebViewPoint = WebViewPoint.Builder().setX(7).setY(-3).build();
      expect(point.getX()).assertEqual(7);
      expect(point.getY()).assertEqual(-3);
      const arr: Array<Object> = point.toArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(2);
      expect(`${arr[0]}`).assertEqual('7');
      expect(`${arr[1]}`).assertEqual('-3');
    })

    it('webViewPointFromArray', 0, () => {
      const list: Array<Object> = [5, 6];
      const point: WebViewPoint = WebViewPoint.fromArray(list);
      expect(point.getX()).assertEqual(5);
      expect(point.getY()).assertEqual(6);
    })

    it('webViewPointRejectsNullX', 0, () => {
      const point: WebViewPoint = WebViewPoint.Builder().build();
      let threw: boolean = false;
      let message: string = '';
      try {
        point.setX(coerce<number>(undefined));
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('"x"')).assertTrue();
    })

    // ---------- 数据类：ConsoleMessage ----------
    it('consoleMessageBuilderAndToArray', 0, () => {
      const msg: ConsoleMessage = ConsoleMessage.Builder()
        .setLineNumber(10)
        .setMessage('hello')
        .setLevel(ConsoleMessageLevel.WARNING)
        .setSourceId('about:blank')
        .build();
      expect(msg.getLineNumber()).assertEqual(10);
      expect(msg.getMessage()).assertEqual('hello');
      expect(msg.getLevel()).assertEqual(ConsoleMessageLevel.WARNING);
      expect(msg.getSourceId()).assertEqual('about:blank');
      const arr: Array<Object> = msg.toArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(4);
      expect(`${arr[2]}`).assertEqual('4');
    })

    it('consoleMessageFromArray', 0, () => {
      const list: Array<Object> = [1, 'log-text', ConsoleMessageLevel.ERROR, 'src'];
      const msg: ConsoleMessage = ConsoleMessage.fromArray(list);
      expect(msg.getLineNumber()).assertEqual(1);
      expect(msg.getMessage()).assertEqual('log-text');
      expect(msg.getLevel()).assertEqual(ConsoleMessageLevel.ERROR);
      expect(msg.getSourceId()).assertEqual('src');
    })

    it('consoleMessageRejectsNullMessage', 0, () => {
      const msg: ConsoleMessage = ConsoleMessage.Builder().build();
      let threw: boolean = false;
      try {
        msg.setMessage(coerce<string>(undefined));
      } catch (err) {
        threw = true;
      }
      expect(threw).assertTrue();
    })

    // ---------- 数据类：WebResourceErrorData / WebResourceRequestData ----------
    it('webResourceErrorDataBuilderAndRoundTrip', 0, () => {
      const data: WebResourceErrorData =
        WebResourceErrorData.Builder().setErrorCode(500).setDescription('server error').build();
      const arr: Array<Object> = data.toArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(2);
      expect(`${arr[0]}`).assertEqual('500');
      expect(`${arr[1]}`).assertEqual('server error');
      const list: Array<Object> = [403, 'forbidden'];
      const parsed: WebResourceErrorData = WebResourceErrorData.fromArray(list);
      expect(parsed.getErrorCode()).assertEqual(403);
      expect(parsed.getDescription()).assertEqual('forbidden');
    })

    it('webResourceRequestDataBuilderAndRoundTrip', 0, () => {
      const headers: Map<string, string> = new Map<string, string>();
      headers.set('Accept', 'text/html');
      const data: WebResourceRequestData = WebResourceRequestData.Builder()
        .setUrl('about:blank')
        .setIsForMainFrame(true)
        .setIsRedirect(false)
        .setHasGesture(true)
        .setMethod('POST')
        .setRequestHeaders(headers)
        .build();
      expect(data.getUrl()).assertEqual('about:blank');
      expect(data.getIsForMainFrame()).assertTrue();
      expect(data.getIsRedirect()).assertFalse();
      expect(data.getHasGesture()).assertTrue();
      expect(data.getMethod()).assertEqual('POST');
      const arr: Array<Object> = data.toArray() as Object as Array<Object>;
      expect(arr.length).assertEqual(6);
      const list: Array<Object> = ['about:blank', true, false, true, 'POST', headers];
      const parsed: WebResourceRequestData = WebResourceRequestData.fromArray(list);
      expect(parsed.getUrl()).assertEqual('about:blank');
      expect(parsed.getMethod()).assertEqual('POST');
    })

    // ---------- 编解码器 ----------
    it('webViewHostApiCodecRoundTripsWebViewPoint', 0, () => {
      const point: WebViewPoint = WebViewPoint.Builder().setX(11).setY(22).build();
      const encoded: ArrayBuffer = WebViewHostApi.getCodec().encodeMessage(point as Object);
      const decoded: WebViewPoint = WebViewHostApi.getCodec().decodeMessage(encoded) as Object as WebViewPoint;
      expect(decoded.getX()).assertEqual(11);
      expect(decoded.getY()).assertEqual(22);
    })

    it('chromeClientCodecRoundTripsConsoleMessage', 0, () => {
      const msg: ConsoleMessage = ConsoleMessage.Builder()
        .setLineNumber(3)
        .setMessage('m')
        .setLevel(ConsoleMessageLevel.LOG)
        .setSourceId('s')
        .build();
      const encoded: ArrayBuffer = WebChromeClientFlutterApi.getCodec().encodeMessage(msg as Object);
      const decoded: ConsoleMessage = WebChromeClientFlutterApi.getCodec().decodeMessage(encoded) as Object as ConsoleMessage;
      expect(decoded.getLineNumber()).assertEqual(3);
      expect(decoded.getMessage()).assertEqual('m');
      expect(decoded.getLevel()).assertEqual(ConsoleMessageLevel.LOG);
      expect(decoded.getSourceId()).assertEqual('s');
    })

    it('flutterApiGetCodecsAreAvailable', 0, () => {
      expect(WebViewFlutterApi.getCodec() != null).assertTrue();
      expect(WebViewClientFlutterApi.getCodec() != null).assertTrue();
      expect(CustomViewCallbackFlutterApi.getCodec() != null).assertTrue();
      expect(ViewFlutterApi.getCodec() != null).assertTrue();
      expect(DownloadListenerFlutterApi.getCodec() != null).assertTrue();
      expect(FileChooserParamsFlutterApi.getCodec() != null).assertTrue();
      expect(JavaScriptChannelFlutterApi.getCodec() != null).assertTrue();
      expect(OhosObjectFlutterApi.getCodec() != null).assertTrue();
      expect(HttpAuthHandlerFlutterApi.getCodec() != null).assertTrue();
      expect(SslErrorHandlerFlutterApi.getCodec() != null).assertTrue();
      expect(GeolocationPermissionsCallbackFlutterApi.getCodec() != null).assertTrue();
      expect(PermissionRequestFlutterApi.getCodec() != null).assertTrue();
    })

    // ---------- FlutterApi 消息通道 ----------
    it('webViewFlutterApiCreateSendsOnPigeonChannel', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      let replied: boolean = false;
      const reply: Reply<void> = { reply: (r): void => {
        replied = true;
      } };
      new WebViewFlutterApi(messenger).create(1, reply);
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.create')).assertTrue();
      expect(messenger.sendCount).assertEqual(1);
      expect(replied).assertTrue();
    })

    it('webViewFlutterApiOnScrollChangedSendsOnPigeonChannel', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      new WebViewFlutterApi(messenger).onScrollChanged(1, 2, 3, 4, 5, { reply: (r): void => {
      } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'WebViewFlutterApi.onScrollChanged')).assertTrue();
    })

    it('customViewCallbackFlutterApiCreateSendsOnPigeonChannel', 0, () => {
      const messenger: MockBinaryMessenger = new MockBinaryMessenger();
      new CustomViewCallbackFlutterApi(messenger).create(9, { reply: (r): void => {
      } });
      expect(messenger.hasSentTo(CHANNEL_PREFIX + 'CustomViewCallbackFlutterApi.create')).assertTrue();
    })
  })
}
