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

// ZslCapabilityTest: verifies the ZSL version gate. Both the L1 gate and the
// L2 probe are injectable, so the real API 21+ symbol (PhotoQualityPrioritization)
// is never evaluated in tests and the suite stays green on pre-API 21 devices.

import { describe, it, expect } from '@ohos/hypium';
import camera from '@ohos.multimedia.camera';
import { ZslCapability } from '../../../main/ets/io/flutter/plugins/camera/ZslCapability';
import { FakeZslGate } from './TestMocks';

// Probe shell recording call count, scripted result and optional throw, so
// each L2 script runs without a real photoOutput.
class ProbePhotoOutput {
  probeCalls: number = 0;
  probeResult: boolean = true;
  throwOnProbe: boolean = false;

  isPhotoQualityPrioritizationSupported(): boolean {
    this.probeCalls++;
    if (this.throwOnProbe) {
      throw new Error('probe failed');
    }
    return this.probeResult;
  }
}

function toPhotoOutput(probe: ProbePhotoOutput): camera.PhotoOutput {
  return (probe as ESObject) as camera.PhotoOutput;
}

// Injected probe delegates to the probe shell, keep the real API 21+ enum
// reference un-evaluated on pre-API 21 runtimes.
function makeCapability(probe: ProbePhotoOutput): ZslCapability {
  return new ZslCapability(new FakeZslGate(true), (photoOutput: camera.PhotoOutput): boolean => {
    return ((photoOutput as ESObject) as ProbePhotoOutput).isPhotoQualityPrioritizationSupported();
  });
}

export default function zslCapabilityTest() {
  describe('ZslCapabilityTest', () => {
    it('versionGateFalse_shortCircuitsWithoutTouchingPhotoOutput', 0, () => {
      const probe: ProbePhotoOutput = new ProbePhotoOutput();
      const capability: ZslCapability = new ZslCapability(new FakeZslGate(false));
      // L1 short-circuit: the probe must never run, verdict cached false.
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(false);
      expect(probe.probeCalls).assertEqual(0);
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(false);
      expect(probe.probeCalls).assertEqual(0);
    });

    it('gateTrue_probeTrue_cachesTrue', 0, () => {
      const probe: ProbePhotoOutput = new ProbePhotoOutput();
      const capability: ZslCapability = makeCapability(probe);
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(true);
      expect(probe.probeCalls).assertEqual(1);
      // Cached: the second call must not touch the probe again.
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(true);
      expect(probe.probeCalls).assertEqual(1);
    });

    it('gateTrue_probeFalse_reportsUnsupported', 0, () => {
      const probe: ProbePhotoOutput = new ProbePhotoOutput();
      probe.probeResult = false;
      const capability: ZslCapability = makeCapability(probe);
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(false);
      expect(probe.probeCalls).assertEqual(1);
    });

    it('gateTrue_probeThrows_countsAsUnsupported', 0, () => {
      const probe: ProbePhotoOutput = new ProbePhotoOutput();
      probe.throwOnProbe = true;
      const capability: ZslCapability = makeCapability(probe);
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(false);
      expect(probe.probeCalls).assertEqual(1);
    });

    it('cacheSurvivesProbeScriptChange', 0, () => {
      // Gate true + probe true first, then flip the probe script to false: the cached
      // verdict must stay true, because the probe runs once per instance.
      const probe: ProbePhotoOutput = new ProbePhotoOutput();
      const capability: ZslCapability = makeCapability(probe);
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(true);
      probe.probeResult = false;
      expect(capability.isCapable(toPhotoOutput(probe))).assertEqual(true);
      expect(probe.probeCalls).assertEqual(1);
    });
  });
}
