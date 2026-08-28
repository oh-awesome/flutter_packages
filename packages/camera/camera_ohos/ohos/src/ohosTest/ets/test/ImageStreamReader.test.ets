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

// ImageStreamReader's parameter-injected surface: onImageAvailable payload
// assembly and parsePlanes. The constructor does call createImageReceiver for
// real (the subscription pipeline itself stays covered by the integration
// tests); every case degrades to an explicit failure with the environment
// reason if that native call is unavailable in the test process.

import { describe, it, expect } from '@ohos/hypium';
import image from '@ohos.multimedia.image';
import { ArrayList, HashMap } from '@kit.ArkTS';
import { Size } from '@kit.ArkUI';
import { ImageStreamReader } from
  '../../../main/ets/io/flutter/plugins/camera/media/ImageStreamReader';
import { CameraCaptureProperties } from
  '../../../main/ets/io/flutter/plugins/camera/types/CameraCaptureProperties';
import {
  StubEventSink,
  makeFakeImage,
  makeFakeComponent,
  fakeImageReleaseCount
} from './TestMocks';

let factoryFailureMessage: string = '';

// Returns null (and records why) when createImageReceiver is unavailable.
function tryMakeReader(): ImageStreamReader | null {
  try {
    const size: Size = { width: 16, height: 16 };
    return new ImageStreamReader(size, image.ImageFormat.JPEG, 3);
  } catch (e) {
    factoryFailureMessage = (e as Error).message;
    return null;
  }
}

export default function imageStreamReaderTest() {
  describe('ImageStreamReaderTest', () => {
    it('constructor_createsReceiverInTestProcess', 0, () => {
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
    });

    it('parsePlanes_extractsStrideAndBytes', 0, () => {
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
      if (reader == null) {
        return;
      }
      const img: image.Image = makeFakeImage(16, 16);
      const planes: ArrayList<HashMap<string, object>> =
        reader.parsePlanes(img, makeFakeComponent(64, 1, 8));
      expect(planes.length).assertEqual(1);
      // ArrayList's indexed accessor is not reachable through a cast here;
      // iterate instead (containers support for-of on device).
      for (const plane of planes) {
        expect(plane.get('bytesPerRow')).assertEqual(64);
        expect(plane.get('bytesPerPixel')).assertEqual(1);
        const bytes: Uint8Array = (plane.get('bytes') as ESObject) as Uint8Array;
        expect(bytes.length).assertEqual(8);
      }
    });

    it('onImageAvailable_payloadAssemblesAllKeys', 0, async (): Promise<void> => {
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
      if (reader == null) {
        return;
      }
      const props: CameraCaptureProperties = new CameraCaptureProperties();
      props.setLastLensAperture(1.8);
      props.setLastSensorExposureTime(25000);
      props.setLastSensorSensitivity(400);

      const sink: StubEventSink = new StubEventSink();
      const img: image.Image = makeFakeImage(1920, 1080);
      await reader.onImageAvailable(img, makeFakeComponent(64, 1, 8), props, sink);

      expect(sink.successEvents.length).assertEqual(1);
      expect(sink.errorCodes.length).assertEqual(0);
      const payload: HashMap<string, Object> =
        (sink.successEvents[0] as ESObject) as HashMap<string, Object>;
      expect(payload.get('width')).assertEqual(1920);
      expect(payload.get('height')).assertEqual(1080);
      expect(payload.get('format')).assertEqual(image.ImageFormat.JPEG);
      expect(payload.get('lensAperture')).assertEqual(1.8);
      expect(payload.get('sensorExposureTime')).assertEqual(25000);
      expect(payload.get('sensorSensitivity')).assertEqual(400);
      const planes: ArrayList<HashMap<string, object>> =
        (payload.get('planes') as ESObject) as ArrayList<HashMap<string, object>>;
      expect(planes.length).assertEqual(1);
    });

    it('onImageAvailable_defaultSensitivityZeroPassesThrough', 0, async (): Promise<void> => {
      // Capture metadata is 0 until Camera.ets feeds it; the reader must not
      // rewrite the default into null (the null branch is only for explicit nulls).
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
      if (reader == null) {
        return;
      }
      const sink: StubEventSink = new StubEventSink();
      await reader.onImageAvailable(makeFakeImage(16, 16), makeFakeComponent(8, 1, 4),
        new CameraCaptureProperties(), sink);
      const payload: HashMap<string, Object> =
        (sink.successEvents[0] as ESObject) as HashMap<string, Object>;
      expect(payload.get('lensAperture')).assertEqual(0);
      expect(payload.get('sensorExposureTime')).assertEqual(0);
      expect(payload.get('sensorSensitivity')).assertEqual(0);
    });

    it('onImageAvailable_explicitNullSensitivityStaysNull', 0, async (): Promise<void> => {
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
      if (reader == null) {
        return;
      }
      const props: CameraCaptureProperties = new CameraCaptureProperties();
      props.setLastSensorSensitivity((null as ESObject) as number);
      const sink: StubEventSink = new StubEventSink();
      await reader.onImageAvailable(makeFakeImage(16, 16), makeFakeComponent(8, 1, 4),
        props, sink);
      const payload: HashMap<string, Object> =
        (sink.successEvents[0] as ESObject) as HashMap<string, Object>;
      expect(payload.get('sensorSensitivity') == null).assertTrue();
    });

    it('onImageAvailable_releasesImageExactlyOnceOnSuccess', 0, async (): Promise<void> => {
      const reader: ImageStreamReader | null = tryMakeReader();
      expect(reader != null).assertTrue();
      if (reader == null) {
        return;
      }
      const img: image.Image = makeFakeImage(16, 16);
      await reader.onImageAvailable(img, makeFakeComponent(8, 1, 4),
        new CameraCaptureProperties(), new StubEventSink());
      expect(fakeImageReleaseCount(img)).assertEqual(1);
    });

    it('onImageAvailable_errorPathReportsSinkErrorAndStillReleases', 0,
      async (): Promise<void> => {
        const reader: ImageStreamReader | null = tryMakeReader();
        expect(reader != null).assertTrue();
        if (reader == null) {
          return;
        }
        // A missing component makes parsePlanes throw inside the try block;
        // the catch must route to sink.error and still release the image.
        const brokenComponent: image.Component = (null as ESObject) as image.Component;
        const sink: StubEventSink = new StubEventSink();
        const img: image.Image = makeFakeImage(16, 16);
        await reader.onImageAvailable(img, brokenComponent,
          new CameraCaptureProperties(), sink);
        expect(sink.errorCodes.length).assertEqual(1);
        expect(sink.errorCodes[0]).assertEqual('IllegalStateException');
        expect(sink.errorMessages[0]).assertContain('Caught IllegalStateException');
        expect(fakeImageReleaseCount(img)).assertEqual(1);
        expect(sink.successEvents.length).assertEqual(0);
      });
  });
}
