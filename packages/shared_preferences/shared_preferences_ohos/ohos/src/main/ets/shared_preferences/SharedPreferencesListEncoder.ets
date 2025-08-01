// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

/**
 * An interface used to provide conversion logic between Array<string> and string for
 * SharedPreferencesPlugin.
 */
export interface SharedPreferencesListEncoder {
  /** Converts list to String for storing in shared preferences. */
  encode(list: Array<string>): string;
  /** Converts stored String representing List<String> to List. */
  decode(listString: string): ESObject;
}