// Copyright (c) 2026 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.

import { FlutterError } from './Messages';

export const HCPP_UNAVAILABLE_CODE: string = 'hcpp_unavailable';

const HCPP_FLAG_NAME: string = 'enable_ohos_hybrid_composition';

interface BuildinfoStringEntry {
  name: string;
  value: string;
}

interface BuildinfoRoot {
  string: BuildinfoStringEntry[];
}

/**
 * Parses app `rawfile/buildinfo.json5` text.
 * Missing file, invalid JSON, or a value other than true means HCPP is off.
 */
export function isOhosHybridCompositionEnabled(buildinfoText: string | null): boolean {
  if (buildinfoText == null || buildinfoText.length === 0) {
    return false;
  }
  let parsed: Object;
  try {
    parsed = JSON.parse(stripJson5Comments(buildinfoText)) as Object;
  } catch (_e) {
    return false;
  }
  if (parsed == null) {
    return false;
  }
  const root = parsed as BuildinfoRoot;
  if (!Array.isArray(root.string)) {
    return false;
  }
  const entries: BuildinfoStringEntry[] = root.string;
  for (let i = 0; i < entries.length; i++) {
    const item: BuildinfoStringEntry = entries[i];
    if (item == null) {
      continue;
    }
    if (`${item.name}` === HCPP_FLAG_NAME) {
      return `${item.value}`.trim() === 'true';
    }
  }
  return false;
}

export function requireHcppAvailable(enabled: boolean): void {
  if (!enabled) {
    throw new FlutterError(
      HCPP_UNAVAILABLE_CODE,
      'HcppUnavailable',
      'VideoViewType.platformView requires Hybrid Composition++. ' +
        'Run with flutter run --enable-hcpp, or set enable_ohos_hybrid_composition ' +
        'to true in buildinfo.json5.',
      ''
    );
  }
}

function stripJson5Comments(text: string): string {
  return text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
}
