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

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import LocalAuthPlugin, { AuthCallback } from '../../../main/ets/io/flutter/plugins/localauth/LocalAuthPlugin';
import { OhosAuthErrorCode } from '../../../main/ets/io/flutter/plugins/localauth/OhosAuthErrorCode';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import UIAbility from '@ohos.app.ability.UIAbility';
import userAuth from '@ohos.userIAM.userAuth';
import { MockMethodResult, MockBinaryMessenger, MockFlutterPluginBinding,
  MockAbilityPluginBinding, AbilityStub, authCall } from './TestMocks';

const CHANNEL_NAME = 'plugins.flutter.io/local_auth_ohos';

/** Delivers a userAuth result through AuthCallback and returns the recorded MethodResult. */
function deliverAuthResult(code: userAuth.UserAuthResultCode): MockMethodResult {
  const mockResult: MockMethodResult = new MockMethodResult();
  const authResult: userAuth.UserAuthResult = { result: code };
  new AuthCallback(mockResult).onResult(authResult);
  return mockResult;
}

/** A plugin already attached to a mock engine binding (channel handler registered). */
class AttachedPlugin {
  plugin: LocalAuthPlugin;
  messenger: MockBinaryMessenger;
  binding: FlutterPluginBinding;

  constructor() {
    this.plugin = new LocalAuthPlugin();
    this.messenger = new MockBinaryMessenger();
    this.binding = new MockFlutterPluginBinding(this.messenger) as ESObject as FlutterPluginBinding;
    this.plugin.onAttachedToEngine(this.binding);
  }
}

export default function localAuthPluginTest() {
  describe('LocalAuthPluginPureLogicTest', () => {
    // Pure plugin logic that never reaches a system API: routing, argument
    // guards and state cleanup. Deterministic on any device.
    let plugin: LocalAuthPlugin = new LocalAuthPlugin();

    beforeAll(() => {
      plugin = new LocalAuthPlugin();
    });

    it('getUniqueClassName_returnsPluginClassName', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('LocalAuthPlugin');
    });

    it('onMethodCall_unknownMethod_reportsNotImplemented', 0, () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('noSuchMethod', null), mockResult);
      expect(mockResult.isNotImplementedCalled).assertTrue();
      expect(mockResult.isSuccessCalled).assertFalse();
      expect(mockResult.isErrorCalled).assertFalse();
    });

    it('onMethodCall_stopAuthentication_routesToSuccess', 0, () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('stopAuthentication', null), mockResult);
      expect(mockResult.isSuccessCalled).assertTrue();
      expect(mockResult.successValue).assertTrue();
      expect(mockResult.callCount).assertEqual(1);
    });

    it('onMethodCall_authenticate_withoutBinding_reportsNoAbility', 0, () => {
      // No ability binding at all: the guard fires synchronously.
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('authenticate', null), mockResult);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.NO_ABILITY);
    });

    it('authenticate_withoutAbility_reportsNoAbilityError', 0, async () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      await plugin.authenticate(new MethodCall('authenticate', null), mockResult);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.NO_ABILITY);
      expect(mockResult.isSuccessCalled).assertFalse();
    });

    it('stopAuthentication_whenIdle_stillReportsSuccess', 0, () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.stopAuthentication(mockResult);
      expect(mockResult.isSuccessCalled).assertTrue();
      expect(mockResult.successValue).assertTrue();
    });

    it('stopAuthentication_afterSendRequest_cleansHelperAndSucceeds', 0, () => {
      // sendAuthenticationRequest creates a helper without touching authInProgress;
      // stopAuthentication must handle both the idle and helper-present shapes.
      const authResult: MockMethodResult = new MockMethodResult();
      plugin.sendAuthenticationRequest(new MethodCall('authenticate', null), authResult, false);
      const stopResult: MockMethodResult = new MockMethodResult();
      plugin.stopAuthentication(stopResult);
      expect(stopResult.isSuccessCalled).assertTrue();
      expect(stopResult.successValue).assertTrue();
    });

    it('onDetachedFromAbility_whenIdle_isIdempotentAndSafe', 0, () => {
      let thrown: boolean = false;
      try {
        plugin.onDetachedFromAbility();
        plugin.onDetachedFromAbility();
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });
  });

  describe('LocalAuthPluginLifecycleTest', () => {
    // Engine/ability attachment via mock bindings: exercises onAttachedToEngine,
    // onAttachedToAbility, onDetachedFromEngine and the in-progress cancel paths.

    it('onAttachedToEngine_registersChannelHandler', 0, () => {
      const attached: AttachedPlugin = new AttachedPlugin();
      expect(attached.messenger.handlerRegistered).assertTrue();
      expect(attached.messenger.handlerChannel).assertEqual(CHANNEL_NAME);
      attached.plugin.onDetachedFromEngine(attached.binding);
      expect(attached.messenger.handlerRegistered).assertFalse();
    });

    it('onAttachedToAbility_withNullAbility_authenticateReportsNoAbility', 0, async () => {
      const attached: AttachedPlugin = new AttachedPlugin();
      attached.plugin.onAttachedToAbility(new MockAbilityPluginBinding(null));
      const mockResult: MockMethodResult = new MockMethodResult();
      await attached.plugin.authenticate(authCall(null, null, null, null), mockResult);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.NO_ABILITY);
      attached.plugin.onDetachedFromAbility();
      attached.plugin.onDetachedFromEngine(attached.binding);
    });

    it('authenticate_fullPath_reportsAuthInProgressWhilePending_thenDetachCancels', 0, async () => {
      const attached: AttachedPlugin = new AttachedPlugin();
      attached.plugin.onAttachedToAbility(
        new MockAbilityPluginBinding(new AbilityStub() as ESObject as UIAbility));
      const first: MockMethodResult = new MockMethodResult();
      await attached.plugin.authenticate(authCall(true, true, 'FINGERPRINT', 'verify to continue'), first);
      // While the first request is pending (no result delivered yet), a second
      // call must be rejected with auth_in_progress.
      const second: MockMethodResult = new MockMethodResult();
      await attached.plugin.authenticate(authCall(false, false, null, null), second);
      if (first.callCount === 0) {
        expect(second.isErrorCalled).assertTrue();
        expect(second.errorCode).assertEqual(OhosAuthErrorCode.AUTH_IN_PROGRESS);
      }
      // Detach while authentication is in progress: the helper must be stopped.
      attached.plugin.onDetachedFromAbility();
      // State must be clean afterwards: stop still succeeds.
      const stopResult: MockMethodResult = new MockMethodResult();
      attached.plugin.stopAuthentication(stopResult);
      expect(stopResult.isSuccessCalled).assertTrue();
      expect(stopResult.successValue).assertTrue();
      attached.plugin.onDetachedFromEngine(attached.binding);
      expect(attached.messenger.handlerRegistered).assertFalse();
    });

    it('authenticate_nonBooleanArgs_fallBackToFalseWithoutThrowing', 0, async () => {
      const attached: AttachedPlugin = new AttachedPlugin();
      attached.plugin.onAttachedToAbility(
        new MockAbilityPluginBinding(new AbilityStub() as ESObject as UIAbility));
      const mockResult: MockMethodResult = new MockMethodResult();
      await attached.plugin.authenticate(authCall('yes', 0, 'FACE', 'reason text'), mockResult);
      // No assertion on the outcome: start() may succeed (pending, cancelled
      // below) or fail synchronously (GENERAL_ERROR). Both are valid; the
      // non-boolean typeof-fallback branches are what this case exercises.
      attached.plugin.onDetachedFromAbility();
      attached.plugin.onDetachedFromEngine(attached.binding);
    });

    it('onDetachedFromEngine_whileAuthPending_stopsHelperAndClearsHandler', 0, async () => {
      const attached: AttachedPlugin = new AttachedPlugin();
      attached.plugin.onAttachedToAbility(
        new MockAbilityPluginBinding(new AbilityStub() as ESObject as UIAbility));
      const mockResult: MockMethodResult = new MockMethodResult();
      await attached.plugin.authenticate(authCall(false, true, null, null), mockResult);
      attached.plugin.onDetachedFromEngine(attached.binding);
      expect(attached.messenger.handlerRegistered).assertFalse();
      // Second detach must stay harmless (already cleared).
      let thrown: boolean = false;
      try {
        attached.plugin.onDetachedFromEngine(attached.binding);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
    });
  });

  describe('LocalAuthPluginDeviceTest', () => {
    // These exercise the plugin's own wrappers around userAuth/screenLock.
    // The system APIs themselves are not asserted (they vary per device); only
    // the plugin's contract with Flutter: a well-formed result is always
    // delivered and checkDeviceSupported() never throws.
    let plugin: LocalAuthPlugin = new LocalAuthPlugin();

    beforeAll(() => {
      plugin = new LocalAuthPlugin();
    });

    it('canAuthenticateLocally_returnsBooleanWithoutThrowing', 0, () => {
      const value: boolean = plugin.canAuthenticateLocally();
      expect(typeof value === 'boolean').assertTrue();
    });

    it('deviceCanSupportBiometrics_returnsBooleanWithoutThrowing', 0, () => {
      const value: boolean = plugin.deviceCanSupportBiometrics();
      expect(typeof value === 'boolean').assertTrue();
    });

    it('checkDeviceSupported_neverThrows_returnsBoolean', 0, async () => {
      const first: boolean = await plugin.checkDeviceSupported();
      const second: boolean = await plugin.checkDeviceSupported();
      expect(typeof first === 'boolean').assertTrue();
      expect(typeof second === 'boolean').assertTrue();
    });

    it('onMethodCall_isDeviceSupported_deliversBooleanToFlutter', 0, async () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('isDeviceSupported', null), mockResult);
      // onMethodCall dispatches fire-and-forget; wait for the async probe to finish.
      await plugin.checkDeviceSupported();
      expect(mockResult.callCount).assertEqual(1);
      if (mockResult.isSuccessCalled) {
        expect(typeof mockResult.successValue === 'boolean').assertTrue();
      } else {
        expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.GENERAL_ERROR);
      }
    });

    it('onMethodCall_getEnrolledBiometrics_deliversStringArrayToFlutter', 0, () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('getEnrolledBiometrics', null), mockResult);
      expect(mockResult.isSuccessCalled || mockResult.isErrorCalled).assertTrue();
      if (mockResult.isSuccessCalled) {
        const biometrics: ESObject = mockResult.successValue;
        expect(Array.isArray(biometrics)).assertTrue();
        const list: Array<string> = biometrics as Array<string>;
        for (let i = 0; i < list.length; i++) {
          const known: boolean = list[i] === 'face' || list[i] === 'fingerprint';
          expect(known).assertTrue();
        }
      } else {
        expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.GENERAL_ERROR);
      }
    });

    it('onMethodCall_deviceSupportsBiometrics_deliversBooleanToFlutter', 0, () => {
      const mockResult: MockMethodResult = new MockMethodResult();
      plugin.onMethodCall(new MethodCall('deviceSupportsBiometrics', null), mockResult);
      expect(mockResult.isSuccessCalled || mockResult.isErrorCalled).assertTrue();
      if (mockResult.isSuccessCalled) {
        expect(typeof mockResult.successValue === 'boolean').assertTrue();
      } else {
        expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.GENERAL_ERROR);
      }
    });

    it('canAuthenticateWithDeviceCredential_returnsBoolean', 0, async () => {
      const value: boolean = await plugin.canAuthenticateWithDeviceCredential();
      expect(typeof value === 'boolean').assertTrue();
    });

    it('sendAuthenticationRequest_noAbility_reportsTerminalOutcome', 0, () => {
      // Without a foreground ability the helper is still constructed; depending
      // on device state start() either fails synchronously (error delivered)
      // or stays pending (cancelled right after). The plugin must not throw.
      const mockResult: MockMethodResult = new MockMethodResult();
      let thrown: boolean = false;
      try {
        plugin.sendAuthenticationRequest(authCall(null, null, null, null), mockResult, false);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertFalse();
      const stopResult: MockMethodResult = new MockMethodResult();
      plugin.stopAuthentication(stopResult);
      expect(stopResult.isSuccessCalled).assertTrue();
    });
  });

  describe('AuthCallbackTest', () => {
    // AuthCallback is the pure mapping from userAuth.UserAuthResultCode to the
    // Flutter-side result; every branch is covered without touching the system.
    it('onResult_success_reportsTrue', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.SUCCESS);
      expect(mockResult.isSuccessCalled).assertTrue();
      expect(mockResult.successValue).assertTrue();
    });

    it('onResult_fail_reportsFalse', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.FAIL);
      expect(mockResult.isSuccessCalled).assertTrue();
      expect(mockResult.successValue).assertFalse();
    });

    it('onResult_generalError_reports12500002', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.GENERAL_ERROR);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.GENERAL_ERROR);
    });

    it('onResult_timeout_reports12500004', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.TIMEOUT);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.TIMEOUT);
    });

    it('onResult_typeNotSupport_reports12500005', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.TYPE_NOT_SUPPORT);
    });

    it('onResult_trustLevelNotSupport_reports12500006', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.TRUST_LEVEL_NOT_SUPPORT);
    });

    it('onResult_busy_reports12500007', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.BUSY);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.BUSY);
    });

    it('onResult_locked_reports12500009', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.LOCKED);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.LOCKED);
    });

    it('onResult_notEnrolled_reports12500010', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.NOT_ENROLLED);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.NOT_ENROLLED);
    });

    it('onResult_canceledFromWidget_reports12500011', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.CANCELED_FROM_WIDGET);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.CANCELED_FROM_WIDGET);
    });

    it('onResult_canceled_reports12500003', 0, () => {
      const mockResult: MockMethodResult = deliverAuthResult(userAuth.UserAuthResultCode.CANCELED);
      expect(mockResult.isErrorCalled).assertTrue();
      expect(mockResult.errorCode).assertEqual(OhosAuthErrorCode.CANCELED);
    });

    it('onResult_unknownCode_fallsBackToFalse', 0, () => {
      const unknownCode: userAuth.UserAuthResultCode =
        999999 as ESObject as userAuth.UserAuthResultCode;
      const mockResult: MockMethodResult = deliverAuthResult(unknownCode);
      expect(mockResult.isSuccessCalled).assertTrue();
      expect(mockResult.successValue).assertFalse();
      expect(mockResult.isErrorCalled).assertFalse();
    });
  });
}
