/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';

type ResultCallback = (errCode: string | null, errDesc: string | null) => void;

const CameraPermission: Array<Permissions> = ['ohos.permission.CAMERA'];

export const AudioPermission: Array<Permissions> = ['ohos.permission.MICROPHONE'];

async function checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // 获取应用程序的accessTokenID
  let tokenId: number = 0;
  try {
    let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
  }

  // 校验应用是否被授予权限
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
  }

  return grantStatus;
}

async function checkPermissions(permissions: Array<Permissions>): Promise<boolean> {
  let grantStatus: abilityAccessCtrl.GrantStatus = await checkAccessToken(permissions[0]);
  return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}

export class CameraPermissions {
  async requestPermissions(
    context: Context,
    enableAudio: boolean,
    callback: ResultCallback
  ) {
    const hasCameraPermission: boolean = await checkPermissions(CameraPermission);
    const hasAudioPermission: boolean = await checkPermissions(AudioPermission);

    if (!hasCameraPermission || (enableAudio && !hasAudioPermission)) {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

      atManager.requestPermissionsFromUser(context,
        enableAudio ? [...CameraPermission, ...AudioPermission] : CameraPermission)
        .then((data: PermissionRequestResult) => {
          const permissions = data.permissions;
          const authResults = data.authResults;
          for (let i = 0; i < permissions.length; i++) {
            if (permissions[i] === 'ohos.permission.CAMERA' && authResults[i] !== 0) {
              // 未授权相机权限
              return callback('CameraAccessDenied', '');
            }
            if (permissions[i] === 'ohos.permission.MICROPHONE' && authResults[i] !== 0) {
              // 未授权录音权限
              return callback('AudioAccessDenied', '');
            }
          }
          callback(null, null);
        }).catch((err: BusinessError) => {
        console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
        callback(String(err.code), err.message);
      })
    } else {
      // Permissions already exist. Call the callback with success.
      callback(null, null);
    }
  }

  async checkPermissions(permission: Array<Permissions>): Promise<boolean> {
    const hasPermission: boolean = await checkPermissions(permission);
    return hasPermission;
  }
}