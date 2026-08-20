/**
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following
 * disclaimer in the documentation and/or other materials provided
 * with the distribution.
 *  * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * */

import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { Result, FileTypes, FileResponse, FileSelectorApiCodec, wrapError } from './GeneratedFileSelectorApi'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import common from '@ohos.app.ability.common';
import ArrayList from '@ohos.util.ArrayList';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = "FileSelector";
export class FileSelector {

  binding: AbilityPluginBinding;

  constructor(binding: AbilityPluginBinding) {
    this.binding = binding;
  }

  openFileWithExtensions(allowedTypes: FileTypes, result: Result<FileResponse>): void {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      let file_suffix: Array<string> = [];
      if (allowedTypes.extensions != null) {
        for (let extensionType of allowedTypes.extensions) {
          file_suffix.push("." + extensionType);
        }
      }
      documentSelectOptions.fileSuffixFilters = file_suffix;
      let uris: Array<string> = [];
      const documentViewPicker = new picker.DocumentViewPicker();
      documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
        if (documentSelectResult == null || documentSelectResult.length === 0) {
          result.error(new Error("No file selected"));
          return;
        }
        uris = documentSelectResult;
        Log.i(TAG, 'documentViewPicker select file succeed and uris are:' + uris);
        let file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
        let response = new FileResponse(file.path, file.name, file.fd);
        result.success(response);
      }).catch((err: BusinessError) => {
        Log.e(TAG, 'Invoke documentPickerSelect failed with err: ' + err);
        result.error(new Error("Failed to read file: " + err.message));
      })
    } catch (err) {
      Log.e(TAG, 'documentPickerSelect select failed with err: ' + err);
      result.error(new Error("Failed to read file"));
    }
  }

  static getCodec(): MessageCodec<ESObject> {
    return FileSelectorApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, abilityPluginBinding: AbilityPluginBinding): void {
    let api = this;
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.FileSelectorApi.openFile", FileSelector.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          Log.d(TAG, 'onMessage reply:' + reply)
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const allowedTypesArg = args[0] as FileTypes;
          const resultCallback: Result<FileResponse> = new ResultBuilder((result: FileResponse): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          },(error: Error): void => {
            const wrappedError: ArrayList<ESObject> = msg.wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFileWithExtensions(allowedTypesArg, resultCallback);
        }
      });
    }
  }
}

class ResultBuilder{
  success: (result: FileResponse) => void
  error: (error: Error) => void

  constructor(success: (result: FileResponse) => void, error: (error: Error) => void) {
    this.success = success
    this.error = error
  }
}