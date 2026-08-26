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

import { describe, it, expect } from '@ohos/hypium';
import { AuthenticationHelper } from '../../../main/ets/io/flutter/plugins/localauth/AuthenticationHelper';
import { OhosAuthErrorCode } from '../../../main/ets/io/flutter/plugins/localauth/OhosAuthErrorCode';
import { MockMethodResult, authCall } from './TestMocks';

export default function authenticationHelperTest() {
  describe('AuthenticationHelperTest', () => {
    // The helper's constructor parses the Dart-side arguments (authType /
    // localizedReason) into userAuth parameters and grabs a UserAuthInstance.
    // The system API itself is not asserted; these tests pin down the
    // argument-parsing branches and the cleanup paths.

    it('constructor_defaultParams_buildsInstanceWithoutThrowing', 0, () => {
      let thrown: boolean = false;
      let helper: AuthenticationHelper | null = null;
      try {
        helper = new AuthenticationHelper(null, authCall(null, null, null, null), false);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
      expect(helper !== null).assertTrue();
    });

    it('constructor_allowCredentials_eachAuthType_noThrow', 0, () => {
      const authTypes: Array<string | null> = ['FACE', 'FINGERPRINT', 'PIN', 'UNKNOWN_KIND', null];
      for (let i = 0; i < authTypes.length; i++) {
        let thrown: boolean = false;
        try {
          const helper: AuthenticationHelper =
            new AuthenticationHelper(null, authCall(null, null, authTypes[i], 'reason text'), true);
          helper.stopAuthentication();
        } catch (e) {
          thrown = true;
        }
        expect(thrown).assertFalse();
      }
    });

    it('constructor_allowCredentials_missingLocalizedReason_noThrow', 0, () => {
      let thrown: boolean = false;
      try {
        const helper: AuthenticationHelper =
          new AuthenticationHelper(null, authCall(null, null, 'FACE', null), true);
        helper.stopAuthentication();
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });

    it('getContext_withoutBinding_returnsUndefined', 0, () => {
      const helper: AuthenticationHelper =
        new AuthenticationHelper(null, authCall(null, null, null, null), false);
      expect(helper.getContext()).assertUndefined();
    });

    it('stopAuthentication_whenIdle_isSafeToCallTwice', 0, () => {
      const helper: AuthenticationHelper =
        new AuthenticationHelper(null, authCall(null, null, null, null), false);
      let thrown: boolean = false;
      try {
        helper.stopAuthentication();
        helper.stopAuthentication();
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });

    it('authenticate_syncFailure_reportsErrorAndNotifiesOnComplete', 0, () => {
      // start() may fail synchronously (e.g. no enrolled credentials / no
      // hardware). The contract then is: GENERAL_ERROR delivered, listener
      // released and onComplete fired. If start() succeeds on this device the
      // request stays pending and is cancelled right after; nothing asserted.
      const helper: AuthenticationHelper =
        new AuthenticationHelper(null, authCall(null, null, null, null), false);
      const mockResult: MockMethodResult = new MockMethodResult();
      let onCompleteCalled: boolean = false;
      let thrown: boolean = false;
      try {
        helper.authenticate(mockResult, (): void => {
          onCompleteCalled = true;
        });
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
      if (mockResult.isErrorCalled) {
        expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.GENERAL_ERROR);
        expect(onCompleteCalled).assertTrue();
      }
      // Cleanup: cancel any pending request so the suite leaves no auth prompt.
      helper.stopAuthentication();
    });

    it('authenticate_syncFailure_thenStopAuthentication_staysSafe', 0, () => {
      const helper: AuthenticationHelper =
        new AuthenticationHelper(null, authCall(null, null, 'FINGERPRINT', 'verify yourself'), true);
      const mockResult: MockMethodResult = new MockMethodResult();
      let thrown: boolean = false;
      try {
        helper.authenticate(mockResult, undefined);
        helper.stopAuthentication();
        helper.stopAuthentication();
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });
  });
}
