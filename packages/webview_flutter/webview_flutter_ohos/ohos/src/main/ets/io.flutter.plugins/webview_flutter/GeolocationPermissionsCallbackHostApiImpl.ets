// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import {InstanceManager} from './InstanceManager'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import {GeolocationPermissionsCallbackHostApi} from "./GeneratedOhosWebView"
export class GeolocationPermissionsCallbackHostApiImpl extends GeolocationPermissionsCallbackHostApi {
  private binaryMessenger:BinaryMessenger ;

  private instanceManager:InstanceManager;

  constructor(binaryMessenger:BinaryMessenger, instanceManager:InstanceManager) {
    super()
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  invoke(instanceId:number,origin:string,allow:boolean,retain:boolean):void {
    this.getGeolocationPermissionsCallbackInstance(instanceId).invoke(origin, allow, retain);
  }

  private getGeolocationPermissionsCallbackInstance(identifier:number):JsGeolocation{
    return this.instanceManager.getInstance(identifier);
  }
}
