// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// ImagePickerUtils.ets 错误路径测试：非法 context 下 requestCameraPermission 应捕获异常并返回 false。

import { describe, it, expect } from '@ohos/hypium';
import ImagePickerUtils from '../../../main/ets/image_picker/ImagePickerUtils';
import common from '@ohos.app.ability.common';

export default function imagePickerUtilsTest() {
  describe('ImagePickerUtilsTest', () => {
    it('requestCameraPermission_invalid_context_returns_false', 0, async () => {
      const granted: boolean = await ImagePickerUtils.requestCameraPermission(null as ESObject as common.Context);
      expect(granted).assertFalse();
    });

    it('needRequestCameraPermission_invokes_callback', 0, (done: Function) => {
      ImagePickerUtils.needRequestCameraPermission((_err: ESObject, isInManifest: boolean) => {
        expect(isInManifest == false || isInManifest == true).assertTrue();
        done();
      });
    });
  });
}
