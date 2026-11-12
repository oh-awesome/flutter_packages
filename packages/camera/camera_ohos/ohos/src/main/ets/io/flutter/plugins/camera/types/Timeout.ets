// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Timeout.java originally written by
// Copyright 2013 The Flutter Authors.

export class Timeout {
  private timeoutMs: number;
  private timeStarted: number;

  static create(timeoutMs: number): Timeout {
    return new Timeout(timeoutMs)
  }

  constructor(timeoutMs: number) {
    this.timeoutMs = timeoutMs;
    this.timeStarted = Date.now();
  }

  getIsExpired(): boolean {
    return (Date.now() - this.timeStarted) > this.timeoutMs;
  }
}