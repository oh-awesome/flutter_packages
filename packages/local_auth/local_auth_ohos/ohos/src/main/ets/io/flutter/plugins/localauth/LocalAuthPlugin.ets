/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodChannel from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import userAuth from '@ohos.userIAM.userAuth';
import { AuthenticationHelper } from './AuthenticationHelper';
import screenLock from '@ohos.screenLock';
import { BusinessError } from '@ohos.base';
import { OhosAuthErrorCode } from './OhosAuthErrorCode';

const TAG = 'LocalAuthPlugin';
const CHANNEL_NAME = 'plugins.flutter.io/local_auth_ohos';

/**
 * Flutter plugin providing access to local authentication.
 *
 * <p>Instantiate this in an add to app scenario to gracefully handle activity and context changes.
 */

export default class LocalAuthPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private authHelper: AuthenticationHelper | null = null;
  private abilityPluginBinding: AbilityPluginBinding | null = null;

  private channel: MethodChannel | null = null;
  // Per-instance flag so concurrent Flutter engines don't share auth state. Each plugin
  // instance tracks its own authentication in-progress state independently.
  private authInProgress: boolean = false;

  getUniqueClassName(): string {
    return 'LocalAuthPlugin';
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    this.abilityPluginBinding = binding;
    this.channel?.setMethodCallHandler(this);
  }

  onDetachedFromAbility() {
    Log.d(TAG, 'onDetachedFromAbility')
    if (this.authHelper != null) {
    this.authHelper.stopAuthentication();
    this.authHelper = null;
    }
    this.authInProgress = false;
    this.abilityPluginBinding = null;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.d(TAG, 'onAttachedToEngine local auth');
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.d(TAG, 'onDetachedFromEngine')
    if (this.authHelper != null) {
    this.authHelper.stopAuthentication();
    this.authHelper = null;
    }
    this.authInProgress = false;
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.abilityPluginBinding = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    Log.d(TAG, 'onMethodCall step in')
    switch (call.method) {
      case 'authenticate':
        this.authenticate(call, result);
        break;
      case 'getEnrolledBiometrics':
        this.getEnrolledBiometrics(result);
        break;
      case 'isDeviceSupported':
        this.isDeviceSupported(result);
        break;
      case 'stopAuthentication':
        this.stopAuthentication(result);
        break;
      case 'deviceSupportsBiometrics':
        this.deviceSupportsBiometrics(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }


  async isDeviceSupported(result: MethodResult): Promise<void> {
    Log.d(TAG, 'isDeviceSupported start');
    try {
      let isDeviceSupported: boolean = await this.checkDeviceSupported();
      Log.d(TAG, `isDeviceSupported, ${isDeviceSupported}`);
      result.success(isDeviceSupported);
    } catch (error) {
      Log.e(TAG, 'isDeviceSupported error: ' + JSON.stringify(error));
      result.error(OhosAuthErrorCode.GENERAL_ERROR, 'Failed to check device support: ' + JSON.stringify(error), null);
    }
  }

  /**
   * Probes whether the device can run a local authentication flow.
   *
   * This helper is self-contained: it never throws. isDeviceSecure() already turns its
   * async rejection into false, but a synchronous throw from screenLock.isSecureMode()
   * could still escape; any such failure is logged and reported as "not supported" so
   * every caller (isDeviceSupported, authenticate) gets a clear boolean regardless of
   * which sub-check failed.
   */
  async checkDeviceSupported(): Promise<boolean> {
    try {
      if (this.canAuthenticateLocally()) {
        return true;
      }
      return await isDeviceSecure();
    } catch (error) {
      Log.e(TAG, 'checkDeviceSupported error: ' + JSON.stringify(error));
      return false;
    }
  }

  getEnrolledBiometrics(result: MethodResult) {
    Log.d(TAG, 'getEnrolledBiometrics start');
    try {
      let biometrics: Array<string> = new Array<string>();
      if (this.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1)) {
        biometrics.push("face");
      }
      if (this.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1)) {
        biometrics.push("fingerprint");
      }
      Log.d(TAG, `getEnrolledBiometrics, ${biometrics}`);
      result.success(biometrics);
    } catch (error) {
      Log.e(TAG, 'getEnrolledBiometrics error: ' + JSON.stringify(error));
      result.error(OhosAuthErrorCode.GENERAL_ERROR, 'Failed to get enrolled biometrics: ' + JSON.stringify(error), null);
    }
  }

  deviceSupportsBiometrics(result: MethodResult) {
    Log.d(TAG, 'deviceSupportsBiometrics start')
    try {
      let deviceCanSupportBiometrics: boolean = this.deviceCanSupportBiometrics();
      Log.d(TAG, `deviceCanSupportBiometrics: ${deviceCanSupportBiometrics}`);
      result.success(deviceCanSupportBiometrics);
    } catch (error) {
      Log.e(TAG, 'deviceSupportsBiometrics error: ' + JSON.stringify(error));
      result.error(OhosAuthErrorCode.GENERAL_ERROR, 'Failed to check device biometrics support: ' + JSON.stringify(error), null);
    }
  }

  /**
   * Cancels in-progress authentication.
   *
   * <p>Returns true only if authentication was in progress, and was successfully cancelled.
   */
  stopAuthentication(result: MethodResult): void {
    try {
      if (this.authHelper != null && this.authInProgress) {
        this.authHelper.stopAuthentication();
        this.authHelper = null;
      }
      this.authInProgress = false;
      result.success(true);
    } catch (e) {
      Log.e(TAG, 'stopAuthentication error: ' + JSON.stringify(e));
      result.error(OhosAuthErrorCode.GENERAL_ERROR, 'Failed to stop authentication: ' + JSON.stringify(e), null);
    }
  }


  canAuthenticateLocally(): boolean {
    Log.i(TAG, `canAuthenticateLocally`);
    return this.getAvailableStatus(userAuth.UserAuthType.PIN, userAuth.AuthTrustLevel.ATL1)
      || this.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1)
      || this.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1);
  }

  private getAvailableStatus(authType: userAuth.UserAuthType, authTrustLevel: userAuth.AuthTrustLevel): boolean {
    try {
      Log.i(TAG, `getAvailableStatus start, authType: ${authType}, authTrustLevel: ${authTrustLevel}`);
      userAuth.getAvailableStatus(authType, authTrustLevel);
    } catch (err) {
      Log.e(TAG, `Failed to getAvailableStatus, Code: ${err?.code}, message: ${err?.message}`);
      return false;
    }
    Log.d(TAG, `getAvailableStatus success, authType: ${authType}, authTrustLevel: ${authTrustLevel}`);
    return true;
  }

  /**
   * Returns true if this device can support biometric authentication, whether biometrics are
   * enrolled or not.
   */
  deviceCanSupportBiometrics(): boolean  {
    return this.supportHardware(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL1)
      || this.supportHardware(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL1);
  }

  private supportHardware(authType: userAuth.UserAuthType, authTrustLevel: userAuth.AuthTrustLevel): boolean {
    try {
      Log.i(TAG, `supportHardware start, authType: ${authType}, authTrustLevel: ${authTrustLevel}`);
      userAuth.getAvailableStatus(authType, authTrustLevel);
    } catch (err) {
      Log.e(TAG, `Failed to getAvailableStatus, Code: ${err?.code}, message: ${err?.message}`);
      return err?.code != userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT;
    }
    Log.d(TAG, `supportHardware success, authType: ${authType}, authTrustLevel: ${authTrustLevel}`);
    return true;
  }

  /**
   * Attempts to authenticate the user with the provided [options], and using [strings] for
   * UI.
   *
   * Supported options:
   *  - biometricOnly: when true, only biometric auth is offered (no device credential).
   *  - stickyAuth: accepted and honored on OHOS, but no manual restart is needed. Unlike
   *    Android (where the biometric prompt is dismissed on Activity pause and must be re-shown
   *    on resume), the OHOS userAuth component is system-managed and persists across a
   *    temporary app backgrounding; the AbilityAware surface from flutter_ohos exposes only
   *    onAttachedToAbility/onDetachedFromAbility plus a window-focus listener (no
   *    onPause/onResume). Re-issuing start() on focus regain would risk duplicate prompts and
   *    callback corruption, so authentication is left to persist at the system level. See the
   *    inline note where the parameter is read.
   */
  async authenticate(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      if (this.authInProgress) {
        result.error(OhosAuthErrorCode.AUTH_IN_PROGRESS, "Authentication in progress", null);
        return;
      }

      if (this.abilityPluginBinding?.getAbility() == null) {
        result.error(OhosAuthErrorCode.NO_ABILITY, "local_auth plugin requires a foreground ability", null);
        return;
      }

      let isDeviceSupported: boolean = await this.checkDeviceSupported();
      if (!isDeviceSupported) {
        this.authInProgress = false;
        result.error(OhosAuthErrorCode.NOT_AVAILABLE, "Required security features not enabled", null);
        return;
      }
      this.authInProgress = true;
      const biometricOnlyRaw: ESObject = call.argument("biometricOnly");
      let isBiometricOnly: boolean = (biometricOnlyRaw != null && typeof biometricOnlyRaw === 'boolean')
        ? biometricOnlyRaw as boolean
        : false;
      // stickyAuth: whether authentication should resume after the app is sent to background.
      //
      // Platform behavior note (OHOS / HarmonyOS):
      // On Android, the BiometricPrompt is dismissed as "user cancelled" when the Activity is
      // paused, so the plugin must manually re-show the prompt on Activity resume when
      // stickyAuth is true. OHOS is different: the userAuth security component is managed by
      // the system. When the UIAbility is temporarily backgrounded and then returned to the
      // foreground, the in-progress authentication surface is preserved/managed by the system
      // rather than being cancelled by this plugin layer. The AbilityAware surface exposed by
      // flutter_ohos only provides onAttachedToAbility/onDetachedFromAbility and a window-focus
      // listener (no onPause/onResume), and re-issuing userAuthInstance.start() on focus regain
      // would risk duplicate prompts and callback corruption. Therefore stickyAuth is accepted
      // here so the parameter is honored and observable (logged), but no manual restart is
      // performed — the authentication already persists across backgrounding at the system level.
      const stickyAuthRaw: ESObject = call.argument("stickyAuth");
      let isStickyAuth: boolean = (stickyAuthRaw != null && typeof stickyAuthRaw === 'boolean')
        ? stickyAuthRaw as boolean
        : false;
      Log.d(TAG, `authenticate, stickyAuth: ${isStickyAuth}, biometricOnly: ${isBiometricOnly}`);
      let allowCredentials: boolean = isBiometricOnly && await this.canAuthenticateWithDeviceCredential();
      this.sendAuthenticationRequest(call, result, allowCredentials);
    } catch (error) {
      this.authInProgress = false;
      Log.e(TAG, 'authenticate error: ' + JSON.stringify(error));
      result.error(OhosAuthErrorCode.GENERAL_ERROR, "Authentication failed: " + JSON.stringify(error), null);
    }
  }

  sendAuthenticationRequest(call: MethodCall,
                            result: MethodResult,
                            allowCredentials: boolean ): void {
    this.authHelper = new AuthenticationHelper(this.abilityPluginBinding, call, allowCredentials);
    let plugin = this;
    this.authHelper.authenticate(result, () => {
      // Terminal cleanup: the auth result has been delivered (or start() failed). Reset this
      // instance's auth state and drop the helper reference so the AuthenticationHelper /
      // UserAuthInstance are not retained until the next authenticate() call or detach.
      // Safe because stopAuthentication() only acts when authInProgress is true, and we reset
      // it here, so a subsequent cancel is a no-op either way.
      plugin.authInProgress = false;
      plugin.authHelper = null;
    });
  }

  async canAuthenticateWithDeviceCredential(): Promise<boolean> {
    return await isDeviceSecure();
  }
}

async function isDeviceSecure(): Promise<boolean> {
  Log.i(TAG, `isDeviceSecure`);
  let result = await screenLock.isSecureMode().then((data: boolean) => {
    console.info(`Succeeded in Obtaining whether the device is in secure mode. result: ${data}`);
    return data as boolean;
  }).catch((err: BusinessError) => {
    console.error(`Failed to obtain whether the device is in secure mode, Code: ${err.code}, message: ${err.message}`);
    return false;
  });
  return result;
}


export class AuthCallback implements userAuth.IAuthCallback {
  private result: MethodResult;

  constructor(result: MethodResult) {
    this.result = result;
  }

  onResult(result: userAuth.UserAuthResult): void {
    switch (result.result) {
      case userAuth.UserAuthResultCode.SUCCESS:
        this.result.success(true);
        break;
      case userAuth.UserAuthResultCode.FAIL:
        this.result.success(false);
        break;
      case userAuth.UserAuthResultCode.GENERAL_ERROR:
        this.result.error(OhosAuthErrorCode.GENERAL_ERROR, "General error occurred.", null);
        break;
      case userAuth.UserAuthResultCode.TIMEOUT:
        this.result.error(OhosAuthErrorCode.TIMEOUT, "This operation is time out.", null);
        break;
      case userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT:
        this.result.error(OhosAuthErrorCode.TYPE_NOT_SUPPORT, "Security credentials not available.", null);
        break;
      case userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT:
        this.result.error(OhosAuthErrorCode.TRUST_LEVEL_NOT_SUPPORT, "Unsupported authentication level.", null);
        break;
      case userAuth.UserAuthResultCode.BUSY:
        this.result.error(OhosAuthErrorCode.BUSY, "The device is busy.", null);
        break;
      case userAuth.UserAuthResultCode.LOCKED:
        this.result.error(OhosAuthErrorCode.LOCKED, "The operation was canceled because the API is locked out" +
          " due to too many attempts. This occurs after 5 failed attempts, and lasts for 60 seconds.", null);
        break;
      case userAuth.UserAuthResultCode.NOT_ENROLLED:
        this.result.error(OhosAuthErrorCode.NOT_ENROLLED, "No Biometrics enrolled on this device.", null);
        break;
      case userAuth.UserAuthResultCode.CANCELED_FROM_WIDGET:
        this.result.error(OhosAuthErrorCode.CANCELED_FROM_WIDGET, "The operation was cancelled by the user from the widget.", null);
        break;
      case userAuth.UserAuthResultCode.CANCELED:
        this.result.error(OhosAuthErrorCode.CANCELED, "The operation was cancelled by the user.", null);
        break;
      default:
        this.result.success(false);
    }
  }
}
