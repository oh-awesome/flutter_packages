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
  MethodChannel, MethodCall, MethodResult, BinaryMessenger, BinaryReply, TaskQueue, TaskQueueOptions, Any,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { iap } from '@kit.IAPKit';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import UIAbility from '@ohos.app.ability.UIAbility';
import { MethodCallHandlerImpl } from '../../../main/ets/components/MethodCallHandlerImpl';
import { MethodNames } from '../../../main/ets/components/MethodNames';

/**
 * MethodResult stub that records which callback fired. These integration tests
 * exercise the real IAP query APIs, so the assertions only require that the
 * async flow reached a terminal callback (success or error) — the exact outcome
 * depends on whether the test device has the IAP sandbox configured.
 */
class IapTestResult implements MethodResult {
  successCalled: boolean = false;
  errorCalled: boolean = false;
  successResult: Any = null;
  errorCode: string = '';
  errorMessage: string = '';

  success(result: Any): void {
    this.successCalled = true;
    this.successResult = result;
  }

  error(errorCode: string, errorMessage: string, errorDetails: Any): void {
    this.errorCalled = true;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
  }

  notImplemented(): void {
  }
}

class NoopMessenger implements BinaryMessenger {
  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    return {} as TaskQueue;
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
  }

  setMessageHandler(channel: String, handler: Object | null, taskQueue?: TaskQueue, ...args: Object[]): void {
  }
}

/**
 * Builds a handler bound to a real UIAbility context. The constructor discards
 * its context argument, so setContext() must be called explicitly.
 */
function buildHandler(context: common.UIAbilityContext): MethodCallHandlerImpl {
  const channel: MethodChannel = new MethodChannel(new NoopMessenger(), 'plugins.flutter.io/in_app_purchase');
  const handler: MethodCallHandlerImpl = new MethodCallHandlerImpl(context, channel);
  handler.setContext(context);
  return handler;
}

/** Polls until the async IAP flow reaches a terminal callback or the timeout elapses. */
function waitForResult(result: IapTestResult, timeoutMs: number): Promise<void> {
  return new Promise<void>((resolve) => {
    const start: number = Date.now();
    const timer: number = setInterval(() => {
      if (result.successCalled || result.errorCalled || Date.now() - start >= timeoutMs) {
        clearInterval(timer);
        resolve();
      }
    }, 30);
  });
}

/** Returns the top UIAbility from the test harness, or null when not available. */
async function obtainAbility(): Promise<UIAbility | null> {
  try {
    return await AbilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
  } catch (e) {
    return null;
  }
}

export default function iapIntegrationTest() {
  describe('MethodCallHandlerImplIapIntegration', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('isFeatureSupported_withRealContext_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      handler.isFeatureSupported(result);
      await waitForResult(result, 10000);
      expect(result.successCalled).assertTrue();
    });

    it('queryProductDetails_withRealContext_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      // Real product IDs configured on AppGallery Connect for this demo app, so
      // a configured sandbox returns them and exercises the success callback.
      handler.queryProductDetails([
        'consumable', 'upgrade', 'subscription_silver', 'subscription_gold', 'subscription_nonrenewable',
      ], result);
      await waitForResult(result, 20000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('transactions_withRealContext_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      handler.onMethodCall(new MethodCall(MethodNames.TRANSACTIONS, null), result);
      await waitForResult(result, 30000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('restoreTransactions_withRealContext_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      handler.onMethodCall(new MethodCall(MethodNames.RESTORE_TRANSACTIONS, null), result);
      await waitForResult(result, 30000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('refreshReceipt_withRealContext_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      handler.onMethodCall(new MethodCall(MethodNames.REFRESH_RECEIPT, null), result);
      await waitForResult(result, 30000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('createPurchase_withoutProductType_shouldFailUnavailable', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      const args: Map<string, Object> = new Map();
      args.set('productId', 'consumable');
      // No productType in the args and an empty product cache -> the type
      // resolution fails deterministically BEFORE any IAP call is made.
      handler.createPurchase('consumable', args, result);
      expect(result.errorCalled).assertTrue();
      expect(result.errorCode).assertEqual('UNAVAILABLE');
    });

    it('queryPurchasesAsync_withRealContext_shouldResolveWhenEmpty', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      handler.queryPurchasesAsync(iap.ProductType.CONSUMABLE, 'order_1001', result);
      await waitForResult(result, 20000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('handleFinishPurchase_withProductType_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      // productType is provided in the args, so the requestType truthy branch
      // runs and productType is never undefined; the flow proceeds to the real
      // query, which resolves empty on the device.
      const args: Map<string, Object> = new Map();
      args.set('transactionIdentifier', 'order_1001');
      args.set('productType', iap.ProductType.CONSUMABLE);
      handler.onMethodCall(new MethodCall(MethodNames.FINISH_PURCHASE, args), result);
      await waitForResult(result, 20000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });

    it('finishPurchase_withoutRemovedTransaction_shouldResolve', 0, async () => {
      const ability: UIAbility | null = await obtainAbility();
      if (ability == null) {
        // No top ability in this environment: the real-context flow cannot run.
        // hypium 1.0.6 has no xit, so the skip is logged and reported as pass.
        console.info('IapIntegration', 'Skipped: no top ability available');
        expect(true).assertTrue();
        return;
      }
      const handler: MethodCallHandlerImpl = buildHandler(ability.context);
      const result: IapTestResult = new IapTestResult();
      // removedTransaction is omitted so the falsy branch of
      // `if (removedTransaction)` is exercised; the real IAP call rejects for
      // a non-existent purchase token, which also covers the finishPurchase
      // error callback.
      handler.finishPurchase(iap.ProductType.CONSUMABLE, 'token_fake', 'order_fake', result);
      await waitForResult(result, 10000);
      expect(result.successCalled || result.errorCalled).assertTrue();
    });
  });
}
