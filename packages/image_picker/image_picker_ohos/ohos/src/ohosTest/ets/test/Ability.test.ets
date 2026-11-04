// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Test suite aggregation: one test file per src/main/ets source file.

import messagesTest from './Messages.test';
import dateTimeUtilTest from './DateTimeUtil.test';
import imageResizerTest from './ImageResizer.test';
import imagePickerPluginTest from './ImagePickerPlugin.test';
import imagePickerDelegateTest from './ImagePickerDelegate.test';
import fileUtilsTest from './FileUtils.test';
import imagePickerCacheTest from './ImagePickerCache.test';
import imagePickerUtilsTest from './ImagePickerUtils.test';
import exifDataCopierTest from './ExifDataCopier.test';

import { describe, it, expect } from '@ohos/hypium';

export default function abilityTest() {
  messagesTest();
  // dateTimeUtilTest();
  // imageResizerTest();
  // imagePickerPluginTest();
  // imagePickerDelegateTest();
  // fileUtilsTest();
  // imagePickerCacheTest();
  // imagePickerUtilsTest();
  // exifDataCopierTest();
  // describe('ImagePickerOhosTest', () => {
  //   it('basicTest', 0, () => {
  //     expect(1 + 1).assertEqual(2);
  //   });
  // });
}
