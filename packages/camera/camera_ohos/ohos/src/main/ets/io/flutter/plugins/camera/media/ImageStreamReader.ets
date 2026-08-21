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
  private readonly dartImageFormat: number;
  private readonly imageReceiver: image.ImageReceiver;
  private imageArrivalListener: ((err: BusinessError) => void) | null = null;

  constructor(size: Size, imageFormat: number, maxImages: number) {
    this.dartImageFormat = imageFormat;
    this.imageReceiver =
      image.createImageReceiver(size, imageFormat, maxImages);
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
      imageBuffer.set('format', this.dartImageFormat);
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
    // 先注销旧监听，防止重复订阅时累积多个 'imageArrival' 回调
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
            // 失败路径释放原生图像缓冲，避免图像流模式下无界累积
            nextImage.release();
            return;
          }
          if (imgComponent && imgComponent.byteBuffer as ArrayBuffer) {
            // onImageAvailable 内部已 try/catch 并释放图像；此处 .catch 防御异步异常被吞
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
    // 先注销 'imageArrival' 监听，释放闭包持有的 captureProps/EventSink 引用，再释放原生接收器
    this.removeListener();
    this.imageReceiver.release()
  }
}