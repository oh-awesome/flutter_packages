// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on ImageResizer.java originally written by
// Copyright 2013 The Flutter Authors.

import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import ExifDataCopier from './ExifDataCopier'
import FileUtils from './FileUtils'
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG: string = 'ImageResizer';

export default class ImageResizer {
  private readonly context: common.Context;
  private readonly exifDataCopier: ExifDataCopier;

  constructor(context: common.Context, exifDataCopier: ExifDataCopier) {
    this.context = context;
    this.exifDataCopier = exifDataCopier;
  }

  async resizeImageIfNeeded(imagePath: string, maxWidth: number | null, maxHeight: number | null,
                            imageQuality: number):
    Promise<string> {
    if (imagePath == null) {
      Log.e(TAG, 'imagePath is null');
      return imagePath;
    }

    let shouldScale: boolean = (maxWidth != null || maxHeight != null || imageQuality < 100);
    if (!shouldScale) {
      return imagePath;
    }

    let imageFile: fs.File | null = null;
    let imageSource: image.ImageSource | null = null;
    let imagePixelMap: image.PixelMap | null = null;
    try {
      imageFile = fs.openSync(imagePath);
      imageSource = image.createImageSource(imageFile.fd);
      let imageInfo: image.ImageInfo = await imageSource.getImageInfo();
      if (imageInfo.size.width == -1 || imageInfo.size.height == -1) {
        return imagePath;
      }

      let targetSize: image.Size = this.calculateTargetSize(imageInfo.size.width, imageInfo.size.height, maxWidth,
        maxHeight);
      Log.d(TAG, 'Start scale image, origin w:' + imageInfo.size.width + ' origin h:' + imageInfo.size.height +
        ' target w:' + targetSize.width + ' target h:' + targetSize.height);

      let parts: string[] = imagePath.split('/', -1);
      let imageName: string = parts[parts.length - 1];
      imagePixelMap = await imageSource.createPixelMap({
        desiredSize: targetSize
      });

      // 与 Android ImageResizer 对齐：源图含透明通道（如 PNG）时输出 PNG 保留透明度，否则 JPEG。
      // Android 按 bitmap.hasAlpha() 判断；OHOS 以解码后 alphaType（PREMUL/UNPREMUL 表示含 alpha）近似
      let hasAlpha: boolean = imageInfo.alphaType == image.AlphaType.PREMUL ||
        imageInfo.alphaType == image.AlphaType.UNPREMUL;
      let outFileName = await this.createImageOnExternalDirectory(imagePixelMap, imageName, imageQuality, hasAlpha);
      await this.exifDataCopier.copyExif(imagePath, outFileName);
      return outFileName;
    } catch (e) {
      Log.e(TAG, 'Resize image failed ' + imagePath + ' err ' + e);
      return imagePath;
    } finally {
      if (imageFile != null) {
        try {
          fs.closeSync(imageFile);
        } catch (e) {
          Log.e(TAG, 'Close image failed: ' + e);
        }
      }
      if (imageSource != null) {
        await imageSource.release();
      }
      if (imagePixelMap != null) {
        await imagePixelMap.release();
      }
    }
  }

  private calculateTargetSize(originalWidth: number, originalHeight: number, maxWidth: number | null,
                              maxHeight: number | null): image.Size {
    // null 表示未设置约束（Pigeon 协议 double? 未设置即 null），保持原尺寸；
    // 非 null 时取 Math.min(原尺寸, 约束)。
    let width: number = maxWidth != null ? Math.min(originalWidth, maxWidth) : originalWidth;
    let height: number = maxHeight != null ? Math.min(originalHeight, maxHeight) : originalHeight;

    let shouldDownscaleWidth: boolean = maxWidth != null && maxWidth < originalWidth;
    let shouldDownscaleHeight: boolean = maxHeight != null && maxHeight < originalHeight;
    let shouldDownscale: boolean = shouldDownscaleWidth || shouldDownscaleHeight;

    // 与 Android calculateTargetSize 对齐：比较 heightForMaxWidth 与 height，
    // 选择不超约束的一边，保证同时设置 maxWidth/maxHeight 时两者都不溢出。
    // （例 1000x2000 + max 600x800：Android 输出 400x800，旧实现输出 600x1200 超 maxHeight）
    if (shouldDownscale) {
      let aspectRatio: number = originalWidth / originalHeight;
      let widthForMaxHeight: number = height * aspectRatio;
      let heightForMaxWidth: number = width / aspectRatio;

      if (heightForMaxWidth > height) {
        width = widthForMaxHeight;
      } else {
        height = heightForMaxWidth;
      }
    }

    return {
      width, height
    };
  }

  private async createImageOnExternalDirectory(imagePixelMap: image.PixelMap, imageName: string, imageQuality: number,
    hasAlpha: boolean): Promise<string> {
    let imagePackerApi: image.ImagePacker | null = null;
    let outFile: fs.File | null = null;
    // 缩放文件写入插件专用临时目录，随 detach 时的 cleanupTempFiles 一并清理
    let outFileName: string = FileUtils.getTempDirectory(this.context) + '/scaled_' + imageName;

    try {
      imagePackerApi = image.createImagePacker();
      // PNG 为无损编码，imageQuality 不生效（与 Android 对 PNG 忽略压缩质量一致）
      let format: string = hasAlpha ? 'image/png' : 'image/jpeg';
      let bufferData = await imagePackerApi.packing(imagePixelMap, {
        format: format, quality: imageQuality, needsPackProperties: true
      });

      outFile = fs.openSync(outFileName, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      let writLen = fs.writeSync(outFile.fd, bufferData, {
        offset: 0
      });
    } finally {
      if (imagePackerApi != null) {
        await imagePackerApi.release();
      }
      if (outFile != null) {
        try {
          fs.closeSync(outFile);
        } catch (e) {
          Log.w(TAG, 'Close out file failed');
        }
      }
    }
    return outFileName;
  }
}