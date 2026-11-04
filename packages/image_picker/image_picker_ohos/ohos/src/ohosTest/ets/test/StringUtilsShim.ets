// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Under ohosTest, flutter_ohos's native bindings
// (libflutter.so's nativeEncodeUtf8/nativeDecodeUtf8) are not initialized,
// so StringUtils.stringToArrayBuffer/uint8ArrayToString throw 'Cannot read property nativeEncodeUtf8 of undefined',
// making every case that encodes a non-empty string through the real codec
// (StandardMessageCodec → ImagePickerApiCodec) fail
// (empty strings take the str.length==0 early return in StringUtils.stringToArrayBuffer,
// which is why the earlier numeric/enum-only cases passed).
// This file replaces those two static methods with @ohos.util's TextEncoder/TextDecoder
// (semantically equivalent to the native UTF-8 codec),
// a pure test-side injection that does not touch the main source.
// It must be imported first in the test entry List.test.ets so it takes effect before any case runs.

import util from '@ohos.util';
import StringUtils from '@ohos/flutter_ohos/src/main/ets/util/StringUtils';

const UTF8_ENCODER = new util.TextEncoder();
const UTF8_DECODER = new util.TextDecoder('utf-8');

function utf8EncodeToArrayBuffer(str: string): ArrayBuffer {
  if (str.length == 0) {
    return new ArrayBuffer(0);
  }
  // Under UTF-8 a single UTF-16 code unit takes at most 3 bytes (surrogate pairs use the 4-byte upper bound),
  // so str.length * 4 is always enough
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

// StringUtils is a class (not a namespace), so its static methods can be overridden via ESObject
// (same approach as the ImagePickerUtils patch).
// Replacing the implementation for the whole ohosTest process is semantically equivalent to the native one,
// so no restore is needed.
(StringUtils as ESObject).stringToArrayBuffer = utf8EncodeToArrayBuffer;
(StringUtils as ESObject).uint8ArrayToString = utf8DecodeFromUint8Array;
(StringUtils as ESObject).arrayBufferToString = utf8DecodeFromArrayBuffer;
