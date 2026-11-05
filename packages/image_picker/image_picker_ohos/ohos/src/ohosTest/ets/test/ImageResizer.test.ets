// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ImageResizer.ets scaling target-size algorithm tests
// (calculateTargetSize pure logic, public static for unit testing).

import { describe, it, expect } from '@ohos/hypium';
import ImageResizer from '../../../main/ets/image_picker/ImageResizer';
import ExifDataCopier from '../../../main/ets/image_picker/ExifDataCopier';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';

function realContext(): common.Context {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
}

// calculateTargetSize is a private instance method in main (not static); tests call it through an instance
// via an ESObject passthrough,
// covering its pure scaling logic without touching the main source.
function targetSize(originalWidth: number, originalHeight: number, maxWidth: number | null,
  maxHeight: number | null): image.Size {
  const resizer: ImageResizer = new ImageResizer(null as ESObject as common.Context, new ExifDataCopier());
  return (resizer as ESObject).calculateTargetSize(originalWidth, originalHeight, maxWidth, maxHeight) as image.Size;
}

// Generates a real PNG (200x100 RGBA) on the device for the scaling pipeline to decode
async function createTestPng(ctx: common.Context): Promise<string> {
  const width: number = 200;
  const height: number = 100;
  const rgba = new ArrayBuffer(width * height * 4);
  const pixelMap: image.PixelMap = await image.createPixelMap(rgba, { size: { width: width, height: height } });
  const packer: image.ImagePacker = image.createImagePacker();
  const buf: ArrayBuffer = await packer.packing(pixelMap, { format: 'image/png', quality: 90 });
  await packer.release();
  await pixelMap.release();
  const path: string = ctx.cacheDir + '/resize_src.png';
  const file: fs.File = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  fs.writeSync(file.fd, buf);
  fs.closeSync(file);
  return path;
}

export default function imageResizerTest() {
  describe('ImageResizerTest', () => {
    it('calculateTargetSize_no_constraints_keeps_original', 0, () => {
      const size: image.Size = targetSize(1000, 2000, null, null);
      expect(size.width).assertEqual(1000);
      expect(size.height).assertEqual(2000);
    });

    it('calculateTargetSize_both_constraints_stay_within_bounds', 0, () => {
      // Aligned with Android's calculateTargetSize: 1000x2000 with max 600x800 must output 400x800,
      // not 600x1200, where taking width 600 makes the height overflow maxHeight.
      const size: image.Size = targetSize(1000, 2000, 600, 800);
      expect(size.width).assertEqual(400);
      expect(size.height).assertEqual(800);
    });

    it('calculateTargetSize_maxWidth_only_keeps_aspect_ratio', 0, () => {
      const size: image.Size = targetSize(1000, 2000, 500, null);
      expect(size.width).assertEqual(500);
      expect(size.height).assertEqual(1000);
    });

    it('calculateTargetSize_maxHeight_only_keeps_aspect_ratio', 0, () => {
      const size: image.Size = targetSize(1000, 2000, null, 1000);
      expect(size.width).assertEqual(500);
      expect(size.height).assertEqual(1000);
    });

    it('calculateTargetSize_constraint_larger_than_original_no_upscale', 0, () => {
      const size: image.Size = targetSize(100, 100, 200, 200);
      expect(size.width).assertEqual(100);
      expect(size.height).assertEqual(100);
    });

    it('calculateTargetSize_landscape_fit_within_both_constraints', 0, () => {
      const size: image.Size = targetSize(2000, 1000, 800, 800);
      expect(size.width).assertEqual(800);
      expect(size.height).assertEqual(400);
    });

    it('resizeImageIfNeeded_null_path_returns_null', 0, async () => {
      const resizer: ImageResizer = new ImageResizer(null as ESObject as common.Context, new ExifDataCopier());
      const out: string = await resizer.resizeImageIfNeeded(null as ESObject as string, null, null, 100);
      expect(out == null).assertTrue();
    });

    it('resizeImageIfNeeded_no_scaling_returns_original_path', 0, async () => {
      const resizer: ImageResizer = new ImageResizer(null as ESObject as common.Context, new ExifDataCopier());
      const out: string = await resizer.resizeImageIfNeeded('/data/tmp/a.jpg', null, null, 100);
      expect(out).assertEqual('/data/tmp/a.jpg');
    });

    it('resizeImageIfNeeded_nonexistent_file_falls_back_to_original', 0, async () => {
      const resizer: ImageResizer = new ImageResizer(null as ESObject as common.Context, new ExifDataCopier());
      const out: string = await resizer.resizeImageIfNeeded('/data/tmp/nonexistent.png', 800, 600, 90);
      expect(out).assertEqual('/data/tmp/nonexistent.png');
    });

    it('real_context_resizeImageIfNeeded_scales_and_writes_output', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const resizer: ImageResizer = new ImageResizer(ctx, new ExifDataCopier());
      const out: string = await resizer.resizeImageIfNeeded(srcPath, 100, null, 80);
      expect(out != null).assertTrue();
      expect(out.indexOf('scaled_')).assertEqual(out.lastIndexOf('/') + 1);
      // The output file has been generated
      let exists: boolean = false;
      try {
        exists = fs.accessSync(out);
      } catch (e) {
        exists = false;
      }
      expect(exists).assertTrue();
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
      try {
        fs.unlinkSync(out);
      } catch (e) {
      }
    });

    it('real_context_resizeImageIfNeeded_quality_below_100_forces_rescale', 0, async () => {
      const ctx: common.Context = realContext();
      const srcPath: string = await createTestPng(ctx);
      const resizer: ImageResizer = new ImageResizer(ctx, new ExifDataCopier());
      // Even with no size constraints, quality<100 must still trigger a rescale re-encode
      const out: string = await resizer.resizeImageIfNeeded(srcPath, null, null, 60);
      expect(out != null).assertTrue();
      expect(out != srcPath).assertTrue();
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
      try {
        fs.unlinkSync(out);
      } catch (e) {
      }
    });
  });
}
