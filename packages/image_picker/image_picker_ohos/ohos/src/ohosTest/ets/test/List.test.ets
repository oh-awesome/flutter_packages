// // Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE_ODID file.
//
// import abilityTest from './Ability.test';
//
// export default function testsuite() {
//   abilityTest();
// }
import './StringUtilsShim';
import messagesTest from './Messages.test';
import dateTimeUtilTest from './DateTimeUtil.test';
import imageResizerTest from './ImageResizer.test';
import imagePickerPluginTest from './ImagePickerPlugin.test';
import imagePickerDelegateTest from './ImagePickerDelegate.test';
import fileUtilsTest from './FileUtils.test';
import imagePickerCacheTest from './ImagePickerCache.test';
import imagePickerUtilsTest from './ImagePickerUtils.test';
import exifDataCopierTest from './ExifDataCopier.test';

export default function abilityTest() {
  messagesTest();
  dateTimeUtilTest();
  imageResizerTest();
  imagePickerPluginTest();
  imagePickerDelegateTest();
  fileUtilsTest();
  imagePickerCacheTest();
  imagePickerUtilsTest();
  exifDataCopierTest();
}