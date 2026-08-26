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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ObjToMap } from '../../../main/ets/common/TsUtil';

class ProductSnapshot {
  productId: string = '';
  count: number = 0;
  enabled: boolean = false;

  constructor(productId: string, count: number, enabled: boolean) {
    this.productId = productId;
    this.count = count;
    this.enabled = enabled;
  }
}

/** A class without any own data properties, used to exercise the empty-input branch. */
class EmptyObject {
}

export default function tsUtilTest() {
  describe('TsUtilTest', () => {
    beforeAll(() => {
    });
    beforeEach(() => {
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    it('ObjToMap_shouldConvertEveryOwnProperty', 0, () => {
      const snapshot: ProductSnapshot = new ProductSnapshot('com.example.coin', 3, true);
      const map: Map<string, Object> = ObjToMap(snapshot);
      expect(map.size).assertEqual(3);
      expect(map.get('productId')).assertEqual('com.example.coin');
      expect(map.get('count')).assertEqual(3);
      expect(map.get('enabled')).assertTrue();
    });

    it('ObjToMap_shouldReturnEmptyMapForObjectWithoutProperties', 0, () => {
      const empty: Object = new EmptyObject();
      const map: Map<string, Object> = ObjToMap(empty);
      expect(map.size).assertEqual(0);
    });
  });
}
