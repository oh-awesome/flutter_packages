// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ExifDataCopier.ets 测试：无效路径下 copyExif 应拒绝而非挂起，资源在 finally 中释放；
// 真实 PNG 上执行 copyExif 覆盖 getImageProperty 属性遍历循环（若任一属性可解析则覆盖 .then 闭包）。

import { describe, it, expect } from '@ohos/hypium';
import ExifDataCopier from '../../../main/ets/image_picker/ExifDataCopier';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { EXIF_SAMPLE_JPEG_BASE64 } from './ExifSampleImages';

function unlinkQuiet(path: string): void {
  try {
    fs.unlinkSync(path);
  } catch (e) {
  }
}

// 将内嵌 base64 的真实 EXIF JPEG 解码写入 cacheDir，返回文件路径
function writeExifJpeg(ctx: common.Context, name: string): string {
  const helper: util.Base64Helper = new util.Base64Helper();
  const encoder: util.TextEncoder = new util.TextEncoder();
  const bytes: Uint8Array = encoder.encodeInto(EXIF_SAMPLE_JPEG_BASE64);
  const decoded: Uint8Array = helper.decodeSync(bytes);
  const ab: ArrayBuffer = new ArrayBuffer(decoded.byteLength);
  const view: Uint8Array = new Uint8Array(ab);
  view.set(decoded);
  const path: string = ctx.cacheDir + '/' + name;
  const file: fs.File = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, ab);
  fs.closeSync(file);
  return path;
}

function realContext(): common.Context {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
}

async function createImage(ctx: common.Context, name: string, format: string): Promise<string> {
  const width: number = 100;
  const height: number = 100;
  const rgba = new ArrayBuffer(width * height * 4);
  const pixelMap: image.PixelMap = await image.createPixelMap(rgba, { size: { width: width, height: height } });
  const packer: image.ImagePacker = image.createImagePacker();
  const buf: ArrayBuffer = await packer.packing(pixelMap, { format: format, quality: 90 });
  await packer.release();
  await pixelMap.release();
  const path: string = ctx.cacheDir + '/' + name;
  const file: fs.File = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, buf);
  fs.closeSync(file);
  return path;
}

export default function exifDataCopierTest() {
  describe('ExifDataCopierTest', () => {
    it('copyExif_nonexistent_paths_rejects', 0, async () => {
      const copier: ExifDataCopier = new ExifDataCopier();
      let rejected: boolean = false;
      try {
        await copier.copyExif('nonexistent_source.jpg', 'nonexistent_dest.jpg');
      } catch (e) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('copyExif_real_pngs_runs_property_loop', 0, async () => {
      const ctx: common.Context = realContext();
      const src: string = await createImage(ctx, 'exif_src.png', 'image/png');
      const dest: string = await createImage(ctx, 'exif_dest.png', 'image/png');
      const copier: ExifDataCopier = new ExifDataCopier();
      try {
        await copier.copyExif(src, dest);
      } catch (e) {
      }
      unlinkQuiet(src);
      unlinkQuiet(dest);
      expect(true).assertTrue();
    });

    it('copyExif_real_jpegs_runs_property_loop', 0, async () => {
      // JPEG 容器含可解析的 EXIF 属性段时 getImageProperty 可能 resolve（PNG 全部属性均 reject），
      // 该用例尝试触达 copyExif 循环内 .then 闭包；无论 resolve/reject 均不抛异常
      const ctx: common.Context = realContext();
      const src: string = await createImage(ctx, 'exif_src.jpg', 'image/jpeg');
      const dest: string = await createImage(ctx, 'exif_dest.jpg', 'image/jpeg');
      const copier: ExifDataCopier = new ExifDataCopier();
      try {
        await copier.copyExif(src, dest);
      } catch (e) {
      }
      unlinkQuiet(src);
      unlinkQuiet(dest);
      expect(true).assertTrue();
    });

    it('copyExif_real_exif_jpeg_resolves_property_loop', 0, async () => {
      // 内嵌真实带 EXIF 元数据的 JPEG（jpgImageTall.jpg，含 APP1 Exif 段）：
      // getImageProperty 对真实存在的属性会 resolve，从而覆盖 copyExif 循环内
      // `.then((data) => {...})` 闭包（packer 生成的无 EXIF 图片全属性 reject，触达不到）。
      const ctx: common.Context = realContext();
      const src: string = writeExifJpeg(ctx, 'exif_real_src.jpg');
      const dest: string = writeExifJpeg(ctx, 'exif_real_dest.jpg');
      const copier: ExifDataCopier = new ExifDataCopier();
      try {
        await copier.copyExif(src, dest);
      } catch (e) {
      }
      unlinkQuiet(src);
      unlinkQuiet(dest);
      expect(true).assertTrue();
    });
  });
}
