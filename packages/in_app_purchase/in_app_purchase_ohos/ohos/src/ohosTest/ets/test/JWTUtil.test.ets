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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { util } from '@kit.ArkTS';
import { JWTUtil } from '../../../main/ets/common/JWTUtil';

const base64Helper: util.Base64Helper = new util.Base64Helper();
const textEncoder: util.TextEncoder = new util.TextEncoder();

/**
 * Encodes a UTF-8 string into a JWT-style base64url string (no padding,
 * '-' instead of '+', '_' instead of '/'). This mirrors the encoding used by
 * AppGallery Connect when it signs JWS purchase data.
 */
function toBase64Url(input: string): string {
  const bytes: Uint8Array = textEncoder.encodeInto(input);
  let encoded: string = base64Helper.encodeToStringSync(bytes);
  encoded = encoded.replace(/\+/g, '-');
  encoded = encoded.replace(/\//g, '_');
  encoded = encoded.replace(/=+$/g, '');
  return encoded;
}

/** Builds a three-segment JWT string from a payload, like the ones returned by IAP. */
function buildJwt(payload: string): string {
  const header: string = toBase64Url('{"alg":"HS256","typ":"JWT"}');
  const body: string = toBase64Url(payload);
  const signature: string = toBase64Url('fake-signature');
  return header + '.' + body + '.' + signature;
}

export default function jwtUtilTest() {
  describe('JWTUtilTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('decodeJwtObj_shouldReturnPayloadOfValidJwt', 0, () => {
      const payload: string = '{"productId":"com.example.coin","productType":0,"purchaseOrderId":"order_1001"}';
      const jwt: string = buildJwt(payload);
      expect(JWTUtil.decodeJwtObj(jwt)).assertEqual(payload);
    });

    it('decodeJwtObj_shouldHandleUrlSafeAndPadding', 0, () => {
      // The '-', '_' and '.' characters inside the payload make the base64url
      // encoding exercise the '-' -> '+' / '_' -> '/' translation as well as the
      // padding restoration inside JWTUtil.
      const payload: string = '{"purchaseOrderId":"ab-cd_ef.gh","price":0.99}';
      const jwt: string = buildJwt(payload);
      expect(JWTUtil.decodeJwtObj(jwt)).assertEqual(payload);
    });

    it('decodeJwtObj_shouldReturnEmptyForMalformedJwt', 0, () => {
      expect(JWTUtil.decodeJwtObj('')).assertEqual('');
      expect(JWTUtil.decodeJwtObj('header.payload')).assertEqual('');
      expect(JWTUtil.decodeJwtObj('onlyOneSegment')).assertEqual('');
    });

    it('decodeJwtObj_shouldNotThrowOnInvalidBase64Payload', 0, () => {
      // A valid three-segment JWT whose payload is not valid base64url should not
      // throw; JWTUtil catches the decode error and returns an empty string.
      const malformed: string = 'eyJhbGciOiJIUzI1NiJ9.' + '###invalid-base64###' + '.sig';
      const decoded: string = JWTUtil.decodeJwtObj(malformed);
      // The call must not throw: JWTUtil swallows the decode error and still
      // returns a string (which may be empty or a best-effort decode).
      expect(typeof decoded === 'string').assertTrue();
    });

    it('base64Decode_shouldDecodeStandardBase64', 0, () => {
      // "Man" base64-encodes to "TWFu".
      expect(JWTUtil.base64Decode('TWFu')).assertEqual('Man');
    });

    it('base64Decode_shouldDecodePaddedInput', 0, () => {
      // "hi" base64-encodes to "aGk="; the '=' padding must be handled.
      expect(JWTUtil.base64Decode('aGk=')).assertEqual('hi');
    });
  });
}
