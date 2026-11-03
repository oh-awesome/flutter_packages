// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on PermissionRequestHostApi.java originally written by
// Copyright 2013 The Flutter Authors.

import {InstanceManager} from './InstanceManager'
import {BinaryMessenger} from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import {PermissionRequestHostApi} from "./GeneratedOhosWebView"
export class PermissionRequestHostApiImpl extends PermissionRequestHostApi {

  private binaryMessenger:BinaryMessenger ;

  private instanceManager:InstanceManager;

  constructor(binaryMessenger:BinaryMessenger, instanceManager:InstanceManager) {
    super()
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  grant(instanceId:number,resources:string[]):void{
    this.getPermissionRequestInstance(instanceId).grant(resources);
  }

  deny(instanceId:number):void{
    this.getPermissionRequestInstance(instanceId).deny();
  }

  private getPermissionRequestInstance(identifier:number):PermissionRequest{
    const permissionRequest: PermissionRequest = this.instanceManager.getInstance(identifier);
    // Defensive check: fail fast with a readable error instead of an
    // undefined-reference crash when the identifier is unknown or already
    // disposed. Valid identifiers follow exactly the same path as before.
    if (!permissionRequest) {
      throw new Error('PermissionRequest instance not found, id = ' + identifier);
    }
    return permissionRequest;
  }
}
