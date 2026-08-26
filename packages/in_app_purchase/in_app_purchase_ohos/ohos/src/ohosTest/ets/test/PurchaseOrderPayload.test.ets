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
import {
  PurchaseOrderPayload,
  PurchaseSubGroupStatusPayload,
  PurchaseSubscriptionStatus,
} from '../../../main/ets/components/PurchaseOrderPayload';
import { PurchaseData } from '../../../main/ets/components/PurchaseData';

export default function purchaseOrderPayloadTest() {
  describe('PurchaseOrderPayloadTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('PurchaseOrderPayload_shouldHaveEmptyDefaults', 0, () => {
      const payload: PurchaseOrderPayload = new PurchaseOrderPayload();
      expect(payload.applicationId).assertEqual('');
      expect(payload.countryCode).assertEqual('');
      expect(payload.environment).assertEqual('');
      expect(payload.payOrderId).assertEqual('');
      expect(payload.price).assertEqual(0);
      expect(payload.productId).assertEqual('');
      expect(payload.productType).assertEqual(0);
      expect(payload.purchaseOrderId).assertEqual('');
      expect(payload.purchaseTime).assertEqual(0);
      expect(payload.purchaseToken).assertEqual('');
      expect(payload.signedTime).assertEqual(0);
    });

    it('PurchaseOrderPayload_shouldParseFromJwsPayloadJson', 0, () => {
      // This mirrors the JSON payload that AppGallery Connect embeds in the
      // JWS purchase order (JWTUtil.decodeJwtObj -> JSON.parse).
      const json: string = '{"applicationId":"com.example.app","countryCode":"CN",'
        + '"environment":"1","payOrderId":"pay_001","price":699,'
        + '"productId":"com.example.coin","productType":0,'
        + '"purchaseOrderId":"order_1001","purchaseTime":1722500000000,'
        + '"purchaseToken":"token_abc","signedTime":1722499999000}';
      const payload: PurchaseOrderPayload = JSON.parse(json) as PurchaseOrderPayload;
      expect(payload.applicationId).assertEqual('com.example.app');
      expect(payload.countryCode).assertEqual('CN');
      expect(payload.environment).assertEqual('1');
      expect(payload.payOrderId).assertEqual('pay_001');
      expect(payload.price).assertEqual(699);
      expect(payload.productId).assertEqual('com.example.coin');
      expect(payload.productType).assertEqual(0);
      expect(payload.purchaseOrderId).assertEqual('order_1001');
      expect(payload.purchaseTime).assertEqual(1722500000000);
      expect(payload.purchaseToken).assertEqual('token_abc');
      expect(payload.signedTime).assertEqual(1722499999000);
    });

    it('PurchaseSubGroupStatusPayload_shouldHaveEmptyDefaults', 0, () => {
      const payload: PurchaseSubGroupStatusPayload = new PurchaseSubGroupStatusPayload();
      expect(payload.environment).assertEqual('');
      expect(payload.applicationId).assertEqual('');
      expect(payload.packageName).assertEqual('');
      expect(payload.subGroupId).assertEqual('');
      expect(payload.lastSubscriptionStatus).assertUndefined();
      expect(payload.historySubscriptionStatusList?.length).assertEqual(0);
    });

    it('PurchaseSubGroupStatusPayload_shouldParseLastSubscriptionStatus', 0, () => {
      const json: string = '{"subGroupId":"subgroup_1",'
        + '"lastSubscriptionStatus":{"subscriptionId":"com.example.sub","purchaseToken":"token_sub",'
        + '"expiresTime":1722586400000,'
        + '"lastPurchaseOrder":{"productId":"com.example.sub","purchaseOrderId":"order_sub",'
        + '"purchaseTime":1722500000000}}}';
      const payload: PurchaseSubGroupStatusPayload = JSON.parse(json) as PurchaseSubGroupStatusPayload;
      expect(payload.subGroupId).assertEqual('subgroup_1');
      expect(payload.lastSubscriptionStatus).not().assertUndefined();
      const status: PurchaseSubscriptionStatus | undefined = payload.lastSubscriptionStatus;
      expect(status?.subscriptionId).assertEqual('com.example.sub');
      expect(status?.purchaseToken).assertEqual('token_sub');
      expect(status?.expiresTime).assertEqual(1722586400000);
    });

    it('PurchaseSubscriptionStatus_shouldHaveEmptyDefaults', 0, () => {
      const status: PurchaseSubscriptionStatus = new PurchaseSubscriptionStatus();
      expect(status.subGroupGenerationId).assertEqual('');
      expect(status.subscriptionId).assertEqual('');
      expect(status.purchaseToken).assertEqual('');
      expect(status.status).assertEqual('');
      expect(status.expiresTime).assertEqual(0);
    });

    it('PurchaseData_shouldParsePurchaseOrderPayload', 0, () => {
      // The outer purchase data wrapper returned by IAP query APIs carries the
      // JWS purchase order under jwsPurchaseOrder for non-subscription products.
      const json: string = '{"type":0,"jwsPurchaseOrder":"eyJhbGciOiJIUzI1NiJ9.payload.signature"}';
      const data: PurchaseData = JSON.parse(json) as PurchaseData;
      expect(data.type).assertEqual(0);
      expect(data.jwsPurchaseOrder).assertContain('eyJhbGciOiJIUzI1NiJ9');
      expect(data.jwsSubscriptionStatus).assertUndefined();
    });

    it('PurchaseData_shouldParseSubscriptionStatusPayload', 0, () => {
      // Subscription purchases carry the JWS subscription status instead.
      const json: string = '{"type":2,"jwsSubscriptionStatus":"eyJhbGciOiJIUzI1NiJ9.sub.payload.sig"}';
      const data: PurchaseData = JSON.parse(json) as PurchaseData;
      expect(data.type).assertEqual(2);
      expect(data.jwsPurchaseOrder).assertUndefined();
      expect(data.jwsSubscriptionStatus).assertContain('sub.payload');
    });
  });
}
