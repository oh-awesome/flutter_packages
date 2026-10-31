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
import { OhosAuthErrorCode } from '../../../main/ets/io/flutter/plugins/localauth/OhosAuthErrorCode';

export default function ohosAuthErrorCodeTest() {
  describe('OhosAuthErrorCodeTest', () => {
    // Error code constants are the contract with the Dart side; pin them all.
    it('systemApiCodes_matchUserAuthResultCodes', 0, () => {
      expect(OhosAuthErrorCode.GENERAL_ERROR).assertEqual('12500002');
      expect(OhosAuthErrorCode.CANCELED).assertEqual('12500003');
      expect(OhosAuthErrorCode.TIMEOUT).assertEqual('12500004');
      expect(OhosAuthErrorCode.TYPE_NOT_SUPPORT).assertEqual('12500005');
      expect(OhosAuthErrorCode.TRUST_LEVEL_NOT_SUPPORT).assertEqual('12500006');
      expect(OhosAuthErrorCode.BUSY).assertEqual('12500007');
      expect(OhosAuthErrorCode.LOCKED).assertEqual('12500009');
      expect(OhosAuthErrorCode.NOT_ENROLLED).assertEqual('12500010');
      expect(OhosAuthErrorCode.CANCELED_FROM_WIDGET).assertEqual('12500011');
    });

    it('pluginFlowCodes_areDistinctStrings', 0, () => {
      const flowCodes: Array<string> = [
        OhosAuthErrorCode.AUTH_IN_PROGRESS,
        OhosAuthErrorCode.NO_ABILITY,
        OhosAuthErrorCode.NOT_AVAILABLE
      ];
      expect(flowCodes[0]).assertEqual('auth_in_progress');
      expect(flowCodes[1]).assertEqual('no_ability');
      expect(flowCodes[2]).assertEqual('NotAvailable');
      expect(new Set<string>(flowCodes).size).assertEqual(3);
    });
  });
}
