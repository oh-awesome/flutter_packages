/*
 * Copyright (c) 2026 Huawei Device Co., Ltd. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE_HW file.
 */

import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { SslErrorHandlerHostApi, SslErrorHandler } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';

/**
 * Host api implementation for ArkWeb SSL error responses (paired Dart [SslErrorHandler]).
 */
export class SslErrorHandlerHostApiImpl extends SslErrorHandlerHostApi {
  binaryMessenger: BinaryMessenger;

  instanceManager: InstanceManager;

  constructor(binaryMessenger: BinaryMessenger, instanceManager: InstanceManager) {
    super();
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = instanceManager;
  }

  cancel(instanceId: number): void {
    this.getSslErrorHandler(instanceId).cancel();
    this.releaseHandler(instanceId);
  }

  proceed(instanceId: number): void {
    this.getSslErrorHandler(instanceId).proceed();
    this.releaseHandler(instanceId);
  }

  private getSslErrorHandler(instanceId: number): SslErrorHandler {
    // Failure-path diagnostics only: fail with a descriptive error instead
    // of returning undefined when the handler was already released. A live
    // instance takes the exact same cancel/proceed path as before.
    const sslErrorHandler: SslErrorHandler = this.instanceManager.getInstance(instanceId);
    if (!sslErrorHandler) {
      throw new Error('SslErrorHandler instance not found, id = ' + instanceId);
    }
    return sslErrorHandler;
  }

  // Leak fix (port hardening): the native handler completes exactly one
  // decision, matching Android SslErrorHandler semantics. Drop it from the
  // instance table afterwards so the retained native handler is released
  // instead of accumulating for every certificate error.
  private releaseHandler(instanceId: number): void {
    this.instanceManager.remove(instanceId);
  }
}
