// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on ImageStreamReader.java originally written by
// Copyright 2013 The Flutter Authors.

import image from '@ohos.multimedia.image';
import { CameraCaptureProperties } from '../types/CameraCaptureProperties';
import { ArrayList, HashMap } from '@kit.ArkTS';
import { Size } from '@kit.ArkUI';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { BusinessError } from '@kit.BasicServicesKit';

export class ImageStreamReader {
  // Format reported to Dart with each frame. It is updated to the format of the selected
  // preview profile, i.e. the actual delivered buffer format (NV21 / YUV420 semi-planar,
  // V first, on current devices), and is decoupled from the ImageReceiver creation format
  // (imageFormat).
  private reportedImageFormat: number;
  private readonly imageReceiver: image.ImageReceiver;
  private imageArrivalListener: ((err: BusinessError) => void) | null = null;

  constructor(size: Size, imageFormat: number, maxImages: number, reportedImageFormat: number) {
    this.reportedImageFormat = reportedImageFormat;
    this.imageReceiver =
      image.createImageReceiver(size, imageFormat, maxImages);
  }

  public setReportedImageFormat(format: number): void {
    this.reportedImageFormat = format;
  }

  public async onImageAvailable(
    _image: image.Image,
    imgComponent: image.Component,
    captureProps: CameraCaptureProperties,
    imageStreamSink: EventSink) {
    try {
      let imageBuffer: HashMap<string, Object> = new HashMap();

      imageBuffer.set('planes', this.parsePlanes(_image, imgComponent));
      imageBuffer.set('width', _image.size.width);
      imageBuffer.set('height', _image.size.height);
      imageBuffer.set('format', this.reportedImageFormat);
      imageBuffer.set('lensAperture', captureProps.getLastLensAperture());
      imageBuffer.set('sensorExposureTime', captureProps.getLastSensorExposureTime());
      let sensorSensitivity: number = captureProps.getLastSensorSensitivity();
      imageBuffer.set('sensorSensitivity', sensorSensitivity == null ? null : sensorSensitivity);

      imageStreamSink.success(imageBuffer);
      await _image.release();

    } catch (e) {
      const err = e as BusinessError;
      imageStreamSink.error(
        'IllegalStateException',
        'Caught IllegalStateException: ' + err.message,
        null);
      await _image.release();
    }
  }

  public parsePlanes(
    _image: image.Image,
    imgComponent: image.Component): ArrayList<HashMap<string, object>> {
    let planes: ArrayList<HashMap<string, object>> = new ArrayList();

    let planeBuffer: HashMap<string, Object> = new HashMap<string, Object>();
    planeBuffer.set('bytesPerRow', imgComponent.rowStride);
    planeBuffer.set('bytesPerPixel', imgComponent.pixelStride);
    planeBuffer.set('bytes', new Uint8Array(imgComponent.byteBuffer));
    planes.add(planeBuffer);

    return planes;
  }

  public getReceivingSurfaceId() {
    return this.imageReceiver.getReceivingSurfaceId();
  }

  public async subscribeListener(captureProps: CameraCaptureProperties, imageStreamSink: EventSink) {
    // Unregister the stale listener first so repeated subscriptions do not accumulate extra 'imageArrival' callbacks.
    this.removeListener();

    this.imageArrivalListener = (err: BusinessError): void => {
      this.imageReceiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || nextImage === undefined) {
          console.error('readNextImage failed');
          return;
        }
        nextImage.getComponent(image.ComponentType.JPEG, (err: BusinessError, imgComponent: image.Component) => {
          if (err || imgComponent === undefined) {
            console.error('getComponent failed');
            // Release the native image buffer on the failure path to avoid unbounded accumulation in image stream mode.
            nextImage.release();
            return;
          }
          if (imgComponent && imgComponent.byteBuffer as ArrayBuffer) {
            // onImageAvailable already try/catches and releases the image; this .catch guards swallowed async failures.
            this.onImageAvailable(nextImage, imgComponent, captureProps, imageStreamSink)
              .catch((error: Error) => {
                console.error('onImageAvailable failed: ' + error.message);
              });
          } else {
            console.error('byteBuffer is null');
            nextImage.release();
          }
        })
      })
    };
    this.imageReceiver.on('imageArrival', this.imageArrivalListener);
  }

  public removeListener(): void {
    if (this.imageArrivalListener != null) {
      this.imageReceiver.off('imageArrival', this.imageArrivalListener);
      this.imageArrivalListener = null;
    }
  }

  public close(): void {
    // Unregister the 'imageArrival' listener first to drop closure-held captureProps/EventSink refs,
    // then release the native receiver.
    this.removeListener();
    this.imageReceiver.release()
  }
}