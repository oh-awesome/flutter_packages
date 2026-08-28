// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// DateTimeUtil 日期/时间格式化工具测试。

import { describe, it, expect } from '@ohos/hypium';
import DateTimeUtil from '../../../main/ets/image_picker/DateTimeUtil';

export default function dateTimeUtilTest() {
  describe('DateTimeUtilTest', () => {
    it('fill_pads_single_digit_with_zero', 0, () => {
      const util: DateTimeUtil = new DateTimeUtil();
      expect(util.fill(0)).assertEqual('00');
      expect(util.fill(9)).assertEqual('09');
      expect(util.fill(10)).assertEqual('10');
      expect(util.fill(23)).assertEqual('23');
    });

    it('concatDate_formats_year_month_day', 0, () => {
      const util = new DateTimeUtil();
      expect(util.concatDate(2024, 1, 5)).assertEqual('20240105');
      expect(util.concatDate(2024, 11, 25)).assertEqual('20241125');
      expect(util.concatDate(2023, 12, 31)).assertEqual('20231231');
    });

    it('concatTime_formats_hours_minutes_seconds', 0, () => {
      const util = new DateTimeUtil();
      expect(util.concatTime(9, 5, 3)).assertEqual('090503');
      expect(util.concatTime(12, 34, 56)).assertEqual('123456');
      expect(util.concatTime(0, 0, 0)).assertEqual('000000');
    });

    it('getDate_and_getTime_are_padded', 0, () => {
      const util = new DateTimeUtil();
      const date = util.getDate();
      const time = util.getTime();
      expect(date.length).assertEqual(8);
      expect(time.length).assertEqual(6);
    });
  });
}
