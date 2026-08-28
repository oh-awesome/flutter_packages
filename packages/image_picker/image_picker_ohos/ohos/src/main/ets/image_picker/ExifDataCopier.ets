// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on ExifDataCopier.java originally written by
// Copyright 2013 The Flutter Authors.

import image from '@ohos.multimedia.image'
import fs from '@ohos.file.fs';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG = 'ExifDataCopier';

export default class ExifDataCopier {
  async copyExif(filePathOri: string, filePathDest: string): Promise<void> {
    // 与 Android ExifDataCopier 对齐，覆盖其复制的全部 Category II（拍摄条件）/ Category III（其他信息）
    // 与 GPS 标签；Orientation 是唯一被复制的 Category I 标签（缩放不会使其失效且对显示至关重要）。
    // OHOS @ohos.multimedia.image 的 PropertyKey 覆盖了 Android 所用键（含 Make/Model/Software/DateTime
    // /DateTimeDigitized/FocalLengthIn35mmFilm 等），仅 InteroperabilityIndex 在 OHOS 中不存在故不列入；
    // ISOSpeed 与 ISOSpeedRatings 在 OHOS 中共用同一键值 'ISOSpeedRatings'（列表已含 ISOSpeedRatings），故不重复列入。
    // 逐个属性 try-catch：原图无该属性或不支持写入时自动跳过，不影响整体复制。
    const attributes = [
      // Category II - 拍摄条件（Shooting condition）
      'ExposureTime',
      'FNumber',
      'ExposureProgram',
      'SpectralSensitivity',
      'PhotographicSensitivity',
      'ISOSpeedRatings',
      'OECF',
      'SensitivityType',
      'StandardOutputSensitivity',
      'RecommendedExposureIndex',
      'ISOSpeedLatitudeyyy',
      'ISOSpeedLatitudezzz',
      'ExifVersion',
      'DateTimeOriginal',
      'DateTimeDigitized',
      'OffsetTime',
      'OffsetTimeOriginal',
      'OffsetTimeDigitized',
      'ShutterSpeedValue',
      'ApertureValue',
      'BrightnessValue',
      'ExposureBiasValue',
      'MaxApertureValue',
      'SubjectDistance',
      'MeteringMode',
      'LightSource',
      'Flash',
      'FocalLength',
      'MakerNote',
      'UserComment',
      'SubsecTime',
      'SubsecTimeOriginal',
      'SubsecTimeDigitized',
      'FlashpixVersion',
      'FlashEnergy',
      'SpatialFrequencyResponse',
      'FocalPlaneXResolution',
      'FocalPlaneYResolution',
      'FocalPlaneResolutionUnit',
      'ExposureIndex',
      'SensingMethod',
      'FileSource',
      'SceneType',
      'CFAPattern',
      'CustomRendered',
      'ExposureMode',
      'WhiteBalance',
      'DigitalZoomRatio',
      'FocalLengthIn35mmFilm',
      'SceneCaptureType',
      'GainControl',
      'Contrast',
      'Saturation',
      'Sharpness',
      'DeviceSettingDescription',
      'SubjectDistanceRange',
      'ImageUniqueID',
      'CameraOwnerName',
      'BodySerialNumber',
      'LensSpecification',
      'LensMake',
      'LensModel',
      'LensSerialNumber',
      // Category III - 其他信息（Metadata storing other information）
      'ImageDescription',
      'Make',
      'Model',
      'Software',
      'DateTime',
      'Artist',
      'Copyright',
      // GPS
      'GPSVersionID',
      'GPSLatitudeRef',
      'GPSLatitude',
      'GPSLongitudeRef',
      'GPSLongitude',
      'GPSAltitudeRef',
      'GPSAltitude',
      'GPSTimeStamp',
      'GPSSatellites',
      'GPSStatus',
      'GPSMeasureMode',
      'GPSDOP',
      'GPSSpeedRef',
      'GPSSpeed',
      'GPSTrackRef',
      'GPSTrack',
      'GPSImgDirectionRef',
      'GPSImgDirection',
      'GPSMapDatum',
      'GPSDestLatitudeRef',
      'GPSDestLatitude',
      'GPSDestLongitudeRef',
      'GPSDestLongitude',
      'GPSDestBearingRef',
      'GPSDestBearing',
      'GPSDestDistanceRef',
      'GPSDestDistance',
      'GPSProcessingMethod',
      'GPSAreaInformation',
      'GPSDateStamp',
      'GPSDifferential',
      'GPSHPositioningError',
      // Orientation（Category I 例外，缩放不会使其失效）
      'Orientation'];

    let oldImageFile: fs.File | null = null;
    let newImageFile: fs.File | null = null;
    let oldImage: image.ImageSource | null = null;
    let newImage: image.ImageSource | null = null;
    try {
      oldImageFile = fs.openSync(filePathOri);
      newImageFile = fs.openSync(filePathDest);
      oldImage = image.createImageSource(oldImageFile.fd);
      newImage = image.createImageSource(newImageFile.fd);
      for (let copyAttribute of attributes) {
        try {
          await oldImage.getImageProperty(copyAttribute).then(async (data) => {
            if (data != null && newImage) {
              await newImage.modifyImageProperty(copyAttribute, data.toString());
            }
          });
        } catch (e) {
          Log.e(TAG, 'Copy ' + copyAttribute + ' data failed.' + e);
        }
      }
    } finally {
      if (oldImage != null) {
        await oldImage.release();
      }
      if (newImage != null) {
        await newImage.release();
      }
      this.closeFile(oldImageFile);
      this.closeFile(newImageFile);
    }
  }

  private closeFile(file: fs.File | null): void {
    if (file == null) {
      return;
    }

    try {
      fs.closeSync(file);
    } catch (e) {
      Log.e(TAG, 'Close file failed ' + e);
    }
  }
}