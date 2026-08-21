/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import userAuth from '@ohos.userIAM.userAuth';
import common from '@ohos.app.ability.common';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { AuthCallback } from './LocalAuthPlugin';
import { OhosAuthErrorCode } from './OhosAuthErrorCode';

/**
 * Authenticates the user with biometrics and sends corresponding response back to Flutter.
 *
 * <p>One instance per call is generated to ensure readable separation of executable paths across
 * method calls.
 */

const TAG = 'AuthenticationHelper';

export class AuthenticationHelper {
  private binding: AbilityPluginBinding | null = null;
  private authCallback: userAuth.IAuthCallback | null = null;
  private authParam : userAuth.AuthParam = {
    challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
    authType: [
      userAuth.UserAuthType.PIN,
      userAuth.UserAuthType.FINGERPRINT
    ],
    authTrustLevel: userAuth.AuthTrustLevel.ATL1,
  };
  private widgetParam :userAuth.WidgetParam = {
    title: '请输入锁屏密码',
  }

  private userAuthInstance: userAuth.UserAuthInstance | null = null;

  constructor(abilityPluginBinding: AbilityPluginBinding | null,
              call: MethodCall,
              allowCredentials: boolean) {
    this.binding = abilityPluginBinding;
    if (allowCredentials) {
      this.authParam = {
        challenge: new Uint8Array([49, 49, 49, 49, 49, 49]),
        authType: [],
        authTrustLevel: userAuth.AuthTrustLevel.ATL1,
      };
      const argAuthTypeRaw: ESObject = call.argument('authType');
      const argAuthType: string = (argAuthTypeRaw != null && typeof argAuthTypeRaw === 'string')
        ? argAuthTypeRaw as string
        : '';
      switch (argAuthType) {
        case 'FACE':
          this.authParam.authType.push(userAuth.UserAuthType.FACE);
          break;
        case 'FINGERPRINT':
          this.authParam.authType.push(userAuth.UserAuthType.FINGERPRINT);
          break;
        case 'PIN':
          this.authParam.authType.push(userAuth.UserAuthType.PIN);
          break;
        default:
          this.authParam.authType = [
            userAuth.UserAuthType.FINGERPRINT,
            userAuth.UserAuthType.FACE,
            userAuth.UserAuthType.PIN
          ];
          break;
      }
      const localizedReasonRaw: ESObject = call.argument('localizedReason');
      const localizedReason: string = (localizedReasonRaw != null && typeof localizedReasonRaw === 'string')
      ? localizedReasonRaw as string : 'Authentication required';
      this.widgetParam = {
        title: localizedReason,
      }
    }
    this.userAuthInstance = userAuth.getUserAuthInstance(this.authParam, this.widgetParam);
    Log.i(TAG, 'get userAuth instance success');
  }

  getContext(): common.UIAbilityContext | undefined {
    return this.binding?.getAbility().context;
  }

  /**
   * Start the biometric listener.
   *
   * onComplete (optional) is invoked once after the terminal auth result is delivered and
   * resources are released, so the caller can drop its reference to this helper. It is also
   * invoked on the synchronous start() failure path, so the caller can treat both terminal
   * cases uniformly.
   */
  authenticate(methodResult: MethodResult, onComplete?: () => void): void {
    try {
      let callback = new AuthCallback(methodResult);
      this.authCallback = callback;
      let instance = this.userAuthInstance;
      let helper = this;
      instance?.on('result', {
        onResult(result: userAuth.UserAuthResult): void {
          // Deliver the terminal result to Flutter first.
          callback.onResult(result);
          // The auth result is terminal (fired exactly once). Break the reference chain
          // UserAuthInstance -> this listener -> AuthCallback -> MethodResult so the
          // MethodResult (and its underlying reply callback) is not retained after auth
          // completes. Cleanup errors must not affect the already-delivered result.
          try {
            instance?.off('result');
            helper.authCallback = null;
            helper.userAuthInstance = null;
          } catch (e) {
            Log.e(TAG, 'auth result cleanup error: ' + JSON.stringify(e));
          } finally {
            if (onComplete) {
              onComplete();
            }
          }
        }
      });

      instance?.start();
      Log.i(TAG, 'auth start success');
    } catch (error) {
      // start() failed synchronously: the on('result') listener registered above is still
      // attached. If we leave it, UserAuthInstance retains the listener (memory leak) and a
      // later result event would invoke the callback with an already-consumed MethodResult.
      // Remove the listener and drop references before reporting the error to Flutter.
      Log.e(TAG, 'auth catch error: ' + JSON.stringify(error));
      try {
        this.userAuthInstance?.off('result');
      } catch (e) {
        Log.e(TAG, 'auth start cleanup error: ' + JSON.stringify(e));
      }
      this.userAuthInstance = null;
      this.authCallback = null;
      methodResult.error(OhosAuthErrorCode.GENERAL_ERROR, 'Failed to start authentication: ' + JSON.stringify(error), null);
      if (onComplete) {
        onComplete();
      }
    }
  }

  /** Cancels the biometric authentication. */
  stopAuthentication(): void {
    try {
      this.userAuthInstance?.cancel();
      Log.i(TAG, 'auth cancel success');
      this.userAuthInstance = null;
      this.authCallback = null;
    } catch (error) {
      Log.e(TAG, 'auth catch error: ' + JSON.stringify(error));
      this.userAuthInstance = null;
      this.authCallback = null;
    }
  }
}