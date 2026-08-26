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
import { iap } from '@kit.IAPKit';
import { MethodNames } from '../../../main/ets/components/MethodNames';
import { TransactionState } from '../../../main/ets/components/TransactionState';
import { ProductType } from '../../../main/ets/components/ProductType';

export default function constantsTest() {
  describe('ConstantsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
    });

    it('MethodNames_shouldMatchChannelProtocol', 0, () => {
      expect(MethodNames.QUERY_ENVIRONMENT_STATUS).assertEqual('iap#queryEnvironmentStatus');
      expect(MethodNames.COUNTRY_CODE).assertEqual('iap#countryCode');
      expect(MethodNames.QUERY_PRODUCTS).assertEqual('iap#queryProducts');
      expect(MethodNames.CREATE_PURCHASE).assertEqual('iap#createPurchase');
      expect(MethodNames.START_OBSERVING_TRANSACTION_QUEUE).assertEqual('iap#startObservingTransactionQueue');
      expect(MethodNames.STOP_OBSERVING_TRANSACTION_QUEUE).assertEqual('iap#stopObservingTransactionQueue');
      expect(MethodNames.RETRIEVE_RECEIPT_DATA).assertEqual('iap#retrieveReceiptData');
      expect(MethodNames.REFRESH_RECEIPT).assertEqual('iap#refreshReceipt');
      expect(MethodNames.TRANSACTIONS).assertEqual('iap#transactions');
      expect(MethodNames.FINISH_PURCHASE).assertEqual('iap#finishPurchase');
      expect(MethodNames.RESTORE_TRANSACTIONS).assertEqual('iap#restoreTransactions');
    });

    it('TransactionState_shouldUseIapConvention', 0, () => {
      expect(TransactionState.purchasing).assertEqual(0);
      expect(TransactionState.purchased).assertEqual(1);
      expect(TransactionState.failed).assertEqual(2);
      expect(TransactionState.restored).assertEqual(3);
      expect(TransactionState.deferred).assertEqual(4);
      expect(TransactionState.unspecified).assertEqual(-1);
    });

    it('ProductType_shouldCoverAllIapTypes', 0, () => {
      expect(ProductType.length).assertEqual(4);
      expect(ProductType[0]).assertEqual(iap.ProductType.CONSUMABLE);
      expect(ProductType[1]).assertEqual(iap.ProductType.NONCONSUMABLE);
      expect(ProductType[2]).assertEqual(iap.ProductType.AUTORENEWABLE);
      expect(ProductType[3]).assertEqual(iap.ProductType.NONRENEWABLE);
    });
  });
}
