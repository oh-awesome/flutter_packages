/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import camera from '@ohos.multimedia.camera';
import deviceInfo from '@ohos.deviceInfo';

// Probe type: returns whether the photoOutput supports ZSL (SPEED quality priority).
export type ZslProbe = (photoOutput: camera.PhotoOutput) => boolean;

// L1 version gate for the zero-shutter-lag (ZSL) feature. The PhotoQualityPrioritization
// symbols only exist on API 21+ runtimes; on pre-21 runtimes touching them throws. The
// gate interface is injectable so ohosTest can fake API<21 without a real low-API device.
export interface ZslVersionGate {
  isVersionSupported(): boolean;
}

// Production gate: sdkApiVersion >= 21 (PhotoQualityPrioritization introduced in API 21).
// sdkApiVersion is a system property, constant for the process lifetime, so read it once.
export class DeviceZslVersionGate implements ZslVersionGate {
  private cached: boolean | null = null;

  isVersionSupported(): boolean {
    if (this.cached === null) {
      this.cached = deviceInfo.sdkApiVersion >= 21;
    }
    return this.cached;
  }
}

// L1 && L2 combined with Camera-instance-level caching. The probe result depends on the
// device+camera capability, which does not change while photoOutput is rebuilt within one
// Camera instance; a recreated Camera instance simply starts with an unset cache. When
// isCapable returns false, callers must short-circuit and never touch photoOutput symbols.
export class ZslCapability {
  private versionGate: ZslVersionGate;
  private probe: ZslProbe;
  private capable: boolean | null = null; // null = not probed yet

  // The probe is injectable so the L2 logic can be scripted without touching the
  // real API 21+ symbols: the PhotoQualityPrioritization enum is only evaluated
  // inside the default probe's body, which production reaches only after the L1
  // gate passed (API 21+). Injected probes (tests) keep that reference
  // un-evaluated, so the suite stays green on pre-API 21 devices as well.
  constructor(gate: ZslVersionGate = new DeviceZslVersionGate(), probe?: ZslProbe) {
    this.versionGate = gate;
    this.probe = probe ?? ((photoOutput: camera.PhotoOutput): boolean =>
      photoOutput.isPhotoQualityPrioritizationSupported(camera.PhotoQualityPrioritization.SPEED));
  }

  // True guarantees the PhotoQualityPrioritization symbols exist on photoOutput, so the
  // caller may probe/set directly. False means the caller must short-circuit. The probe
  // runs once per instance; repeated calls hit the cache and never touch photoOutput.
  isCapable(photoOutput: camera.PhotoOutput): boolean {
    if (this.capable !== null) {
      return this.capable;
    }
    if (!this.versionGate.isVersionSupported()) {
      this.capable = false;
      return false; // L1 short-circuit: never touch photoOutput symbols.
    }
    try {
      this.capable = this.probe(photoOutput);
    } catch (e) {
      // Probe failure on an API21+ runtime counts as device-unsupported and is cached
      // so the failing probe is not repeated on every call.
      this.capable = false;
    }
    return this.capable;
  }
}
