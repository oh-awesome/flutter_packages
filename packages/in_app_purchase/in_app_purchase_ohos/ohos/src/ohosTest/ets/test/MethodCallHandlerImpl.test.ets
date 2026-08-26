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
  MethodChannel, MethodCall, MethodResult, BinaryMessenger, BinaryReply, TaskQueue, TaskQueueOptions,
  StandardMethodCodec, Any,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { iap } from '@kit.IAPKit';
import { util } from '@kit.ArkTS';
import { MethodCallHandlerImpl } from '../../../main/ets/components/MethodCallHandlerImpl';
import { MethodNames } from '../../../main/ets/components/MethodNames';

/**
 * A MethodResult stub that records the callback that the handler invoked,
 * so tests can assert on the success/error/notImplemented outcome.
 */
class MockMethodResult implements MethodResult {
  successCalled: boolean = false;
  errorCalled: boolean = false;
  notImplementedCalled: boolean = false;
  successResult: Any = null;
  errorCode: string = '';
  errorMessage: string = '';
  errorDetails: Any = null;

  success(result: Any): void {
    this.successCalled = true;
    this.successResult = result;
  }

  error(errorCode: string, errorMessage: string, errorDetails: Any): void {
    this.errorCalled = true;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.errorDetails = errorDetails;
  }

  notImplemented(): void {
    this.notImplementedCalled = true;
  }
}

/**
 * A BinaryMessenger stub that records outgoing method-call messages so tests
 * can assert that the handler notified the Flutter observer channel.
 */
class RecordingBinaryMessenger implements BinaryMessenger {
  sendCount: number = 0;
  lastMessage: ArrayBuffer | null = null;

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    return {} as TaskQueue;
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
    this.sendCount += 1;
    this.lastMessage = message;
  }

  setMessageHandler(channel: String, handler: Object | null, taskQueue?: TaskQueue, ...args: Object[]): void {
  }
}

/**
 * Returns a typed null for a non-nullable parameter. ArkTS rejects `null as T`,
 * `null as unknown as T` and inline `null -> T | null -> T` casts because the
 * compiler narrows the null literal back to `null`. `nullable()` keeps the
 * declared `Object | null` return type, which is not narrowed, so it can be
 * narrowed to the target type.
 */
function nullContext(): common.Context {
  return nullable() as common.Context;
}

/**
 * Returns a null value whose static type is `Object | null`. A null literal that
 * is assigned to a variable or cast inline is narrowed back to `null` by ArkTS,
 * which then rejects `null -> T`. Returning null from a function keeps the
 * declared return type, so callers can narrow it to any class/interface type.
 */
function nullable(): Object | null {
  return null;
}

/**
 * Builds a handler with no context attached. Many of the handler's public
 * methods short-circuit to a deterministic 'UNAVAILABLE' error when the
 * context is null, which lets us exercise the method-call routing and error
 * handling without needing a real IAP sandbox on the test device.
 */
function createHandler(messenger?: BinaryMessenger): MethodCallHandlerImpl {
  const m: BinaryMessenger = messenger ?? new RecordingBinaryMessenger();
  const channel: MethodChannel = new MethodChannel(m, 'plugins.flutter.io/in_app_purchase');
  const context: common.Context = nullContext();
  return new MethodCallHandlerImpl(context, channel);
}

function createPurchaseArgs(productId: string, productType?: number): Map<string, Object> {
  const args: Map<string, Object> = new Map();
  args.set('productId', productId);
  if (productType !== undefined) {
    args.set('productType', productType);
  }
  return args;
}

const testBase64: util.Base64Helper = new util.Base64Helper();
const testTextEncoder: util.TextEncoder = new util.TextEncoder();

function testToBase64Url(input: string): string {
  const bytes: Uint8Array = testTextEncoder.encodeInto(input);
  let encoded: string = testBase64.encodeToStringSync(bytes);
  encoded = encoded.replace(/\+/g, '-');
  encoded = encoded.replace(/\//g, '_');
  encoded = encoded.replace(/=+$/g, '');
  return encoded;
}

/** Builds a JWS-style purchase order string that mirrors AppGallery Connect output. */
function buildJwsPurchaseOrder(): string {
  const header: string = testToBase64Url('{"alg":"HS256","typ":"JWT"}');
  const payload: string = testToBase64Url('{"applicationId":"com.example.app","productId":"com.example.coin",'
    + '"productType":0,"purchaseOrderId":"order_1001","purchaseToken":"token_abc",'
    + '"purchaseTime":1722500000000}');
  const signature: string = testToBase64Url('fake-signature');
  return header + '.' + payload + '.' + signature;
}

/** Builds a JWS-style subscription status string for AUTORENEWABLE products. */
function buildJwsSubscriptionStatus(): string {
  const header: string = testToBase64Url('{"alg":"HS256","typ":"JWT"}');
  const payload: string = testToBase64Url('{"subGroupId":"subgroup_1",'
    + '"lastSubscriptionStatus":{"subscriptionId":"com.example.sub","purchaseToken":"token_sub",'
    + '"lastPurchaseOrder":{"productId":"com.example.sub","productType":2,'
    + '"purchaseOrderId":"order_sub","purchaseTime":1722500000000}}}');
  const signature: string = testToBase64Url('fake-signature');
  return header + '.' + payload + '.' + signature;
}

/** Builds a three-segment JWT with an arbitrary payload, for malformed purchase-data tests. */
function buildJwtFromPayload(payload: string): string {
  const header: string = testToBase64Url('{"alg":"HS256","typ":"JWT"}');
  const signature: string = testToBase64Url('fake-signature');
  return header + '.' + testToBase64Url(payload) + '.' + signature;
}

/** Polls until the condition holds or the timeout elapses, so async callbacks can be asserted. */
function waitUntil(condition: () => boolean, timeoutMs: number): Promise<void> {
  return new Promise<void>((resolve) => {
    const start: number = Date.now();
    const timer: number = setInterval(() => {
      if (condition() || Date.now() - start >= timeoutMs) {
        clearInterval(timer);
        resolve();
      }
    }, 20);
  });
}

export default function methodCallHandlerTest() {
  describe('MethodCallHandlerImplTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('isFeatureSupported_withoutContext_shouldResolveFalse', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.isFeatureSupported(result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult).assertFalse();
      expect(result.errorCalled).assertFalse();
    });

    it('queryProductDetails_withoutContext_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.queryProductDetails(['com.example.coin'], result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('purchaseGoods_withEmptyProductId_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = createPurchaseArgs('');
      handler.purchaseGoods(args, result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('productId');
    });

    it('purchaseGoods_withValidId_shouldNotifyObserverThenFailUnavailable', 0, () => {
      const messenger: RecordingBinaryMessenger = new RecordingBinaryMessenger();
      const handler: MethodCallHandlerImpl = createHandler(messenger);
      handler.startObserver();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = createPurchaseArgs('com.example.coin', iap.ProductType.CONSUMABLE);
      handler.purchaseGoods(args, result);
      // The observer must be notified with the 'purchasing' transaction state first.
      expect(messenger.sendCount).assertEqual(1);
      const call: MethodCall = StandardMethodCodec.INSTANCE.decodeMethodCall(messenger.lastMessage as ArrayBuffer);
      expect(call.method).assertEqual('updatedTransactions');
      // Then createPurchase fails because there is no context.
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      handler.stopObserver();
    });

    it('createPurchase_withoutContext_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = createPurchaseArgs('com.example.coin', iap.ProductType.CONSUMABLE);
      handler.createPurchase('com.example.coin', args, result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('handlePurchaseError_shouldNotifyObserverWithFailedState', 0, () => {
      const messenger: RecordingBinaryMessenger = new RecordingBinaryMessenger();
      const handler: MethodCallHandlerImpl = createHandler(messenger);
      handler.startObserver();
      const args: Map<string, Object> = createPurchaseArgs('com.example.coin', iap.ProductType.CONSUMABLE);
      const err: BusinessError = { code: 401, message: 'purchase failed' } as BusinessError;
      handler.handlePurchaseError(args, err);
      expect(messenger.sendCount).assertEqual(1);
      const call: MethodCall = StandardMethodCodec.INSTANCE.decodeMethodCall(messenger.lastMessage as ArrayBuffer);
      expect(call.method).assertEqual('updatedTransactions');
      handler.stopObserver();
    });

    it('finishPurchase_withoutContext_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.finishPurchase(iap.ProductType.CONSUMABLE, 'token_abc', 'order_1001', result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('transactions_withoutContext_shouldResolveEmptyList', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.TRANSACTIONS, null), result);
      expect(result.successCalled).assertTrue();
      const list: Array<Object> = result.successResult as Array<Object>;
      expect(list.length).assertEqual(0);
    });

    it('restoreTransactions_withoutContext_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.RESTORE_TRANSACTIONS, null), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('refreshReceipt_withoutContext_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.REFRESH_RECEIPT, null), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('retrieveReceiptData_shouldResolveEmptyByDefault', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.RETRIEVE_RECEIPT_DATA, null), result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult).assertEqual('');
    });

    it('countryCode_shouldResolveSystemRegion', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.COUNTRY_CODE, null), result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult !== null && result.successResult !== undefined).assertTrue();
    });

    it('queryEnvironmentStatus_shouldResolveFalseWithoutContext', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.QUERY_ENVIRONMENT_STATUS, null), result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult).assertFalse();
    });

    it('queryProducts_shouldFailUnavailableWithoutContext', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.QUERY_PRODUCTS, ['com.example.coin']), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('createPurchase_shouldFailUnavailableWithoutContext', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = createPurchaseArgs('com.example.coin', iap.ProductType.CONSUMABLE);
      handler.onMethodCall(new MethodCall(MethodNames.CREATE_PURCHASE, args), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('finishPurchase_withoutTransactionIdentifier_shouldFailUnavailable', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = new Map();
      handler.onMethodCall(new MethodCall(MethodNames.FINISH_PURCHASE, args), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('transactionIdentifier');
    });

    it('finishPurchase_withUnknownProduct_shouldFailUnavailable', 0, () => {
      // No productType in the args and the product is not in the product cache
      // (nothing was ever queried) -> the productDetailsMap lookup fails.
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const args: Map<string, Object> = new Map();
      args.set('transactionIdentifier', 'order_1001');
      args.set('productIdentifier', 'com.example.unknown');
      handler.onMethodCall(new MethodCall(MethodNames.FINISH_PURCHASE, args), result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('product');
    });

    it('purchaseGoods_withInvalidArgs_shouldFailWithIapError', 0, () => {
      // Non-Map args make map.get() throw; the try/catch wraps it in an IAP error.
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const badArgs: Array<string> = ['not', 'a', 'map'];
      handler.purchaseGoods(badArgs, result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode.indexOf('IAP_')).assertEqual(0);
    });

    it('queryPurchasesAsync_withoutContext_shouldFailWithIapError', 0, async () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.queryPurchasesAsync(iap.ProductType.CONSUMABLE, 'order_1001', result);
      // queryPurchasesAsync hits the real IAP kit which rejects for a null context.
      await waitUntil(() => result.errorCalled || result.successCalled, 2000);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode.indexOf('IAP_')).assertEqual(0);
    });

    it('purchaseCompletionByTypeProcessing_shouldFinishMatchingPurchase', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const purchaseData: string = '{"type":0,"jwsPurchaseOrder":"' + buildJwsPurchaseOrder() + '"}';
      handler.purchaseCompletionByTypeProcessing([purchaseData], 'order_1001', result);
      // The matched order flows into finishPurchase(), which fails on a null context.
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('purchaseCompletionByTypeProcessing_shouldFinishMatchingSubscription', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const purchaseData: string = '{"type":2,"jwsSubscriptionStatus":"' + buildJwsSubscriptionStatus() + '"}';
      handler.purchaseCompletionByTypeProcessing([purchaseData], 'order_sub', result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
      expect(result.errorMessage).assertContain('context is null');
    });

    it('purchaseCompletionByTypeProcessing_noMatch_shouldResolveNull', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      const purchaseData: string = '{"type":0,"jwsPurchaseOrder":"' + buildJwsPurchaseOrder() + '"}';
      handler.purchaseCompletionByTypeProcessing([purchaseData], 'non-existent-order', result);
      expect(result.successCalled).assertTrue();
      expect(result.errorCalled).assertFalse();
    });

    it('purchaseCompletionByTypeProcessing_invalidSubscription_shouldSkip', 0, () => {
      // Each malformed subscription purchase data hits a different validation
      // branch inside the AUTORENEWABLE extraction and is skipped via continue.
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      // missing jwsSubscriptionStatus
      handler.purchaseCompletionByTypeProcessing(['{"type":2}'], 'order', result);
      // lastSubscriptionStatus missing from the decoded payload
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":2,"jwsSubscriptionStatus":"' + buildJwtFromPayload('{"subGroupId":"x"}') + '"}'], 'order', result);
      // purchaseToken missing on lastSubscriptionStatus
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":2,"jwsSubscriptionStatus":"' + buildJwtFromPayload('{"lastSubscriptionStatus":{"lastPurchaseOrder":{"purchaseOrderId":"o"}}}') + '"}'],
        'order', result);
      // lastPurchaseOrder missing on lastSubscriptionStatus
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":2,"jwsSubscriptionStatus":"' + buildJwtFromPayload('{"lastSubscriptionStatus":{"purchaseToken":"t"}}') + '"}'],
        'order', result);
      // purchaseOrderId missing on lastPurchaseOrder
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":2,"jwsSubscriptionStatus":"' + buildJwtFromPayload('{"lastSubscriptionStatus":{"purchaseToken":"t","lastPurchaseOrder":{}}}') + '"}'],
        'order', result);
      expect(result.successCalled).assertTrue();
    });

    it('purchaseCompletionByTypeProcessing_invalidPurchaseOrder_shouldSkip', 0, () => {
      // Each malformed non-subscription purchase data hits a different
      // validation branch inside the non-AUTORENEWABLE extraction.
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      // missing jwsPurchaseOrder
      handler.purchaseCompletionByTypeProcessing(['{"type":0}'], 'order', result);
      // purchaseToken missing from the decoded payload
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":0,"jwsPurchaseOrder":"' + buildJwtFromPayload('{"productId":"x","purchaseOrderId":"o"}') + '"}'],
        'order', result);
      // purchaseOrderId missing from the decoded payload
      handler.purchaseCompletionByTypeProcessing(
        ['{"type":0,"jwsPurchaseOrder":"' + buildJwtFromPayload('{"productId":"x","purchaseToken":"t"}') + '"}'],
        'order', result);
      expect(result.successCalled).assertTrue();
    });

    it('handlePurchaseError_withNullError_shouldUseDefaults', 0, () => {
      const messenger: RecordingBinaryMessenger = new RecordingBinaryMessenger();
      const handler: MethodCallHandlerImpl = createHandler(messenger);
      handler.startObserver();
      const args: Map<string, Object> = createPurchaseArgs('com.example.coin', iap.ProductType.CONSUMABLE);
      handler.handlePurchaseError(args, nullable() as BusinessError);
      // The observer must be notified with an updatedTransactions message whose
      // error map carries the default code=0 and empty domain for a null error.
      expect(messenger.sendCount).assertEqual(1);
      const call: MethodCall = StandardMethodCodec.INSTANCE.decodeMethodCall(messenger.lastMessage as ArrayBuffer);
      expect(call.method).assertEqual('updatedTransactions');
      const transactions: Array<Map<string, Object>> = call.args as Array<Map<string, Object>>;
      const errorMap: Map<string, Object> = transactions[0].get('error') as Map<string, Object>;
      expect(errorMap.get('code')).assertEqual(0);
      expect(errorMap.get('domain')).assertEqual('');
      handler.stopObserver();
    });

    it('setContext_shouldBeSafeAndKeepNullContext', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      handler.setContext(null);
      const result: MockMethodResult = new MockMethodResult();
      handler.isFeatureSupported(result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult).assertFalse();
    });

    it('startAndStopObserver_shouldNotThrow', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.START_OBSERVING_TRANSACTION_QUEUE, null), result);
      expect(result.successCalled).assertTrue();
      handler.onMethodCall(new MethodCall(MethodNames.STOP_OBSERVING_TRANSACTION_QUEUE, null), result);
      expect(result.successCalled).assertTrue();
    });

    it('unknownMethod_shouldBeNotImplemented', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall('iap#unknownMethod', null), result);
      expect(result.notImplementedCalled).assertTrue();
      expect(result.successCalled).assertFalse();
      expect(result.errorCalled).assertFalse();
    });

    it('clearCache_shouldBeSafeAndPreserveState', 0, () => {
      const handler: MethodCallHandlerImpl = createHandler();
      handler.clearCache();
      const result: MockMethodResult = new MockMethodResult();
      handler.onMethodCall(new MethodCall(MethodNames.RETRIEVE_RECEIPT_DATA, null), result);
      expect(result.successCalled).assertTrue();
      expect(result.successResult).assertEqual('');
    });
  });
}
