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
// Unit tests for Messages.ets: all branches of FlutterError and wrapError.

import { describe, it, expect } from '@ohos/hypium';
import { FlutterError, wrapError } from '../../../main/ets/shared_preferences/Messages';

/** Mimics the BusinessError shape (code/message only) thrown by @ohos APIs such as data_preferences. */
interface BizErrorShape {
  code: number;
  message: string;
}

export default function messagesTest(): void {
  describe('MessagesFlutterErrorTest', () => {
    it('constructorKeepsCodeMessageAndDetails', 0, () => {
      const err: FlutterError = new FlutterError('E1', 'boom', 'detail');
      expect(err.code).assertEqual('E1');
      expect(err.message).assertEqual('boom');
      expect(err.details).assertEqual('detail');
      expect(err instanceof Error).assertTrue();
    });

    it('wrapErrorKeepsFlutterErrorCodeMessageDetails', 0, () => {
      const fe: FlutterError = new FlutterError('E2', 'boom', 'detail');
      const wrapped: Object[] = wrapError(fe as ESObject as Error);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('E2');
      expect(wrapped[1]).assertEqual('boom');
      expect(wrapped[2]).assertEqual('detail');
    });

    it('wrapErrorPlainErrorUsesNameAndToString', 0, () => {
      const wrapped: Object[] = wrapError(new Error('plain failure'));
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('Error');
      expect(wrapped[1]).assertContain('plain failure');
      expect(wrapped[2]).assertContain('Cause: plain failure');
      expect(wrapped[2]).assertContain('Stacktrace');
    });

    it('wrapErrorTypedErrorKeepsSubclassAsName', 0, () => {
      const fe: FlutterError = new FlutterError('E3', 'msg', 'd');
      const wrapped: Object[] = wrapError(fe as ESObject as Error);
      // The FlutterError branch must not go through the generic fallback.
      expect(wrapped[0]).assertEqual('E3');
      expect(wrapped[2]).assertEqual('d');
    });

    it('wrapErrorBusinessErrorLikeObjectFallsBackToMessage', 0, () => {
      const biz: BizErrorShape = { code: 401, message: 'param invalid' };
      const wrapped: Object[] = wrapError(biz as ESObject as Error);
      expect(wrapped.length).assertEqual(3);
      // Object literal has no name field; the fallback uses 'Error'.
      expect(wrapped[0]).assertEqual('Error');
      // toString is '[object Object]'; the fallback takes message instead.
      expect(wrapped[1]).assertEqual('param invalid');
      expect(wrapped[2]).assertContain('Cause: param invalid');
    });

    it('wrapErrorAlwaysReturnsFreshList', 0, () => {
      const first: Object[] = wrapError(new Error('a'));
      const second: Object[] = wrapError(new Error('b'));
      expect(first === second).assertFalse();
      expect(first.length).assertEqual(3);
      expect(second.length).assertEqual(3);
    });
  });
}
