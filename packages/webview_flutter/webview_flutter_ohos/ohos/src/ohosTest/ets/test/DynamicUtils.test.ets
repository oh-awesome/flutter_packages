/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// DynamicUtils / DVModelJson 单元测试：动态参数读写与视图描述模型构造。

import { describe, it, expect } from '@ohos/hypium';
import {
  DynamicUtils,
  DVModelJson
} from '../../../main/ets/io.flutter.plugins/webview_flutter/DynamicUtils';
import {
  DVModelParameters
} from '@ohos/flutter_ohos/src/main/ets/view/DynamicView/dynamicView';
import { newDvModel } from '../testmock/MockInstances';

export default function dynamicUtilsTest() {
  describe('DynamicUtilsTest', () => {
    it('setParamsThenGetParamsReturnsValue', 0, () => {
      const params: DVModelParameters = new DVModelParameters();
      DynamicUtils.setParams(params, 'url', 'about:blank');
      expect(`${DynamicUtils.getParams(params, 'url')}`).assertEqual('about:blank');
    })

    it('getParamsMissingKeyReturnsUndefined', 0, () => {
      const params: DVModelParameters = new DVModelParameters();
      expect(DynamicUtils.getParams(params, 'not_set')).assertUndefined();
    })

    it('setParamsOverwritesExistingValue', 0, () => {
      const params: DVModelParameters = new DVModelParameters();
      DynamicUtils.setParams(params, 'level', '1');
      DynamicUtils.setParams(params, 'level', '2');
      expect(`${DynamicUtils.getParams(params, 'level')}`).assertEqual('2');
    })

    it('setParamsSupportsMultipleKeys', 0, () => {
      const params: DVModelParameters = new DVModelParameters();
      DynamicUtils.setParams(params, 'key_string', 'text');
      DynamicUtils.setParams(params, 'key_number', 99);
      expect(`${DynamicUtils.getParams(params, 'key_string')}`).assertEqual('text');
      expect(`${DynamicUtils.getParams(params, 'key_number')}`).assertEqual('99');
    })

    it('dvModelJsonStoresFieldsWithoutBuild', 0, () => {
      const attributes: Record<string, Object> = { 'width': '100' };
      const events: Record<string, Object> = { 'onClick': 'handleClick' };
      const json: DVModelJson = newDvModel('img', attributes, events);
      expect(json.compType).assertEqual('img');
      expect(json.children.length).assertEqual(0);
      expect(json.build).assertUndefined();
    })

    it('dvModelJsonStoresFieldsWithBuild', 0, () => {
      const attributes: Record<string, Object> = {};
      const events: Record<string, Object> = {};
      const build: Record<string, Object> = { 'builderId': 1 };
      const json: DVModelJson = newDvModel('list', attributes, events, build);
      expect(json.compType).assertEqual('list');
      expect(json.build).assertEqual(build);
    })
  })
}
