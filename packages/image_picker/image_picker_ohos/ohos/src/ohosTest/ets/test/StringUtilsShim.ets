// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ohosTest 环境下 flutter_ohos 的 native 绑定（libflutter.so 的 nativeEncodeUtf8/nativeDecodeUtf8）未初始化，
// StringUtils.stringToArrayBuffer/uint8ArrayToString 会抛 'Cannot read property nativeEncodeUtf8 of undefined'，
// 导致所有经真实 codec（StandardMessageCodec → ImagePickerApiCodec）编码非空字符串的用例失败
// （空字符串在 StringUtils.stringToArrayBuffer 里走 str.length==0 提前返回，故之前那些只含数字/枚举的用例能过）。
// 本文件以 @ohos.util 的 TextEncoder/TextDecoder（语义与 native UTF-8 编解码等价）替换这两个静态方法，
// 纯测试注入、不改 main 源码。需在测试入口 List.test.ets 最前面 import，保证在任何用例执行前生效。

import util from '@ohos.util';
import StringUtils from '@ohos/flutter_ohos/src/main/ets/util/StringUtils';

const UTF8_ENCODER = new util.TextEncoder();
const UTF8_DECODER = new util.TextDecoder('utf-8');

function utf8EncodeToArrayBuffer(str: string): ArrayBuffer {
  if (str.length == 0) {
    return new ArrayBuffer(0);
  }
  // UTF-8 下单个 UTF-16 code unit 最多占 3 字节（代理对取 4 字节上限），str.length * 4 必然够用
  const dest = new Uint8Array(str.length * 4);
  const written = UTF8_ENCODER.encodeInto(str, dest).written;
  return dest.slice(0, written).buffer;
}

function utf8DecodeFromUint8Array(bytes: Uint8Array): string {
  if (bytes.length <= 0) {
    return '';
  }
  return UTF8_DECODER.decode(bytes);
}

function utf8DecodeFromArrayBuffer(buffer: ArrayBuffer): string {
  if (buffer.byteLength <= 0) {
    return '';
  }
  return UTF8_DECODER.decode(new Uint8Array(buffer));
}

// StringUtils 是 class（非 namespace），静态方法可经 ESObject 覆写（与 ImagePickerUtils 补丁同理）。
// 整个 ohosTest 进程内替换实现与 native 语义等价，无需恢复。
(StringUtils as ESObject).stringToArrayBuffer = utf8EncodeToArrayBuffer;
(StringUtils as ESObject).uint8ArrayToString = utf8DecodeFromUint8Array;
(StringUtils as ESObject).arrayBufferToString = utf8DecodeFromArrayBuffer;
