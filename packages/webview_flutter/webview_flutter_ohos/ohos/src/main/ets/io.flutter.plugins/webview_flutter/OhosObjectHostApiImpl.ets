// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import { OhosObjectHostApi as OhosObjectHostApi } from './GeneratedOhosWebView';
import { InstanceManager } from './InstanceManager';
import { WebViewPlatformView } from './WebViewHostApiImpl';

export class OhosObjectHostApiImpl extends OhosObjectHostApi {
  private instanceManager: InstanceManager;

  /**
   * Constructs a {@link OhosObjectHostApiImpl}.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   */
  constructor(instanceManager: InstanceManager) {
    super()
    this.instanceManager = instanceManager;
  }

  dispose(identifier: number) {
    this.instanceManager.remove(identifier);
  }
}
