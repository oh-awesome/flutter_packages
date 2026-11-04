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
    // Aligned with Android's ExifDataCopier: covers all the Category II (shooting condition) / Category III
    // (other information) and GPS tags it copies; Orientation is the only Category I tag copied (scaling does
    // not invalidate it and it is essential for display). OHOS @ohos.multimedia.image's PropertyKey covers the
    // keys Android uses (including Make/Model/Software/DateTime/DateTimeDigitized/FocalLengthIn35mmFilm etc.);
    // only InteroperabilityIndex does not exist on OHOS, so it is omitted; ISOSpeed and ISOSpeedRatings share
    // the same key 'ISOSpeedRatings' on OHOS (the list already includes ISOSpeedRatings), so it is not listed
    // twice. Per-property try-catch: attributes missing from the original image or unsupported for writing are
    // skipped automatically, without affecting the overall copy.
    const attributes = [
      // Category II - Shooting condition
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
      // Category III - Metadata storing other information
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
      // Orientation (Category I exception: scaling does not invalidate it)
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