// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { WebViewFeatureHostApi } from './GeneratedOhosWebView';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'WebViewFeatureHostApiImpl';

// ArkWeb does not currently expose a public Payment Request capability query,
// so the OHOS plugin must report this feature as unsupported.
export class WebViewFeatureHostApiImpl extends WebViewFeatureHostApi {
  isFeatureSupported(feature: string): boolean {
    switch (feature) {
      case 'PAYMENT_REQUEST':
        // Keep this aligned with the native capability surface: the current
        // OHOS implementation only provides API compatibility shims and does
        // not have a real ArkWeb payment request backend to enable.
        return false;
      default:
        Log.w(TAG, 'ArkWeb does not expose a capability query for feature: ' + feature);
        return false;
    }
  }
}
