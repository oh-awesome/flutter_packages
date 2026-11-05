// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

/**
 * @file Date/time utility
 */

const NINE: number = 9; // The number 9

export default class DateTimeUtil {
  /**
   * Hour/minute/second
   */
  getTime(): string {
    const DATETIME = new Date();
    return this.concatTime(
      DATETIME.getHours(),
      DATETIME.getMinutes(),
      DATETIME.getSeconds()
    );
  }

  /**
   * Year/month/day
   */
  getDate(): string {
    const DATETIME = new Date();
    return this.concatDate(
      DATETIME.getFullYear(),
      DATETIME.getMonth() + 1,
      DATETIME.getDate()
    );
  }

  /**
   * Zero-pad date components to 2 digits
   * @param value-Data value
   */
  fill(value: number): string {
    return (value > NINE ? '' : '0') + value;
  }

  /**
   * Year/month/day formatting
   * @param year
   * @param month
   * @param date
   */
  concatDate(year: number, month: number, date: number): string {
    return `${year}${this.fill(month)}${this.fill(date)}`;
  }

  /**
   * Avoid repetition
   * Hour/minute/second formatting
   * @param hours
   * @param minutes
   * @param seconds
   */
  concatTime(hours: number, minutes: number, seconds: number): string {
    return `${this.fill(hours)}${this.fill(minutes)}${this.fill(seconds)}`;
  }
}
