/*
 * Copyright (c) 2026 Huawei Device Co., Ltd. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE_HW file.
 */

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { SslErrorHandlerFlutterApi, Reply } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';

/**
 * Flutter API implementation for pairing native ArkWeb SSL handlers with Dart.
 */
export class SslErrorHandlerFlutterApiImpl {
  binaryMessenger: BinaryMessenger;

  instanceManager: InstanceManager;

  api: SslErrorHandlerFlutterApi;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
    this.api = new SslErrorHandlerFlutterApi(binaryMessenger);
  }

  create(instance: ESObject, callback: Reply<void>): void {
    if (!this.instanceManager.containsInstance(instance)) {
      this.api.create(this.instanceManager.addHostCreatedInstance(instance), callback);
    } else {
      // Already paired with Dart; complete so callers can safely forward payloads.
      callback.reply(null);
    }
  }
}
