/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
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

import { describe, it, expect } from '@ohos/hypium';
import Messages, {
  StorageDirectory,
  FlutterError,
  PathProviderApi
} from '../../../main/ets/io/flutter/plugins/pathprovider/Messages';

export default function messagesTest() {
  describe('MessagesTest', () => {
    it('StorageDirectory_ROOT_should_be_0', 0, () => {
      expect(StorageDirectory.ROOT).assertEqual(0);
    });
    it('StorageDirectory_MUSIC_should_be_1', 0, () => {
      expect(StorageDirectory.MUSIC).assertEqual(1);
    });
    it('StorageDirectory_PODCASTS_should_be_2', 0, () => {
      expect(StorageDirectory.PODCASTS).assertEqual(2);
    });
    it('StorageDirectory_RINGTONES_should_be_3', 0, () => {
      expect(StorageDirectory.RINGTONES).assertEqual(3);
    });
    it('StorageDirectory_ALARMS_should_be_4', 0, () => {
      expect(StorageDirectory.ALARMS).assertEqual(4);
    });
    it('StorageDirectory_NOTIFICATIONS_should_be_5', 0, () => {
      expect(StorageDirectory.NOTIFICATIONS).assertEqual(5);
    });
    it('StorageDirectory_PICTURES_should_be_6', 0, () => {
      expect(StorageDirectory.PICTURES).assertEqual(6);
    });
    it('StorageDirectory_MOVIES_should_be_7', 0, () => {
      expect(StorageDirectory.MOVIES).assertEqual(7);
    });
    it('StorageDirectory_DOWNLOADS_should_be_8', 0, () => {
      expect(StorageDirectory.DOWNLOADS).assertEqual(8);
    });
    it('StorageDirectory_DCIM_should_be_9', 0, () => {
      expect(StorageDirectory.DCIM).assertEqual(9);
    });
    it('StorageDirectory_DOCUMENTS_should_be_10', 0, () => {
      expect(StorageDirectory.DOCUMENTS).assertEqual(10);
    });

    it('FlutterError_should_have_correct_code', 0, () => {
      const error: FlutterError = new FlutterError('test_code', 'test_message', null);
      expect(error.code).assertEqual('test_code');
    });
    it('FlutterError_should_have_correct_message', 0, () => {
      const error: FlutterError = new FlutterError('test_code', 'test_message', null);
      expect(error.message).assertEqual('test_message');
    });
    it('FlutterError_should_have_correct_details', 0, () => {
      const error: FlutterError = new FlutterError('test_code', 'test_message', 'test_details');
      expect(error.details).assertEqual('test_details');
    });
    it('FlutterError_should_be_instance_of_Error', 0, () => {
      const error: FlutterError = new FlutterError('test_code', 'test_message', null);
      expect(error instanceof Error).assertTrue();
    });
    it('FlutterError_with_null_details', 0, () => {
      const error: FlutterError = new FlutterError('test_code', 'test_message', null);
      expect(error.details).assertNull();
    });

    it('wrapError_should_wrap_FlutterError_correctly', 0, () => {
      const error: FlutterError = new FlutterError('custom_code', 'custom_message', 'custom_details');
      const wrapped: Array<ESObject> = Messages.wrapError(error as Error);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('custom_code');
      expect(wrapped[1]).assertEqual('custom_message');
      expect(wrapped[2]).assertEqual('custom_details');
    });
    it('wrapError_should_wrap_regular_Error_correctly', 0, () => {
      const error: Error = new Error('regular_error_message');
      const wrapped: Array<ESObject> = Messages.wrapError(error);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual(error.name);
      expect(wrapped[1]).assertEqual('regular_error_message');
      if (error.stack !== undefined) {
        expect(wrapped[2]).assertEqual(error.stack);
      }
    });
    it('wrapError_should_handle_FlutterError_with_null_details', 0, () => {
      const error: FlutterError = new FlutterError('code', 'message', null);
      const wrapped: Array<ESObject> = Messages.wrapError(error as Error);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('code');
      expect(wrapped[1]).assertEqual('message');
      expect(wrapped[2]).assertNull();
    });
    it('wrapError_should_handle_Error_with_undefined_stack', 0, () => {
      const error: Error = new Error('no-stack');
      error.stack = undefined;
      const wrapped: Array<ESObject> = Messages.wrapError(error);
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual(error.name);
      expect(wrapped[1]).assertEqual('no-stack');
      expect(wrapped[2]).assertUndefined();
    });

    it('getCodec_returnsUsableInstance', 0, () => {
      expect(PathProviderApi.getCodec() !== null).assertTrue();
    });
  });
}
