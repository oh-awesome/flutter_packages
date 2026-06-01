
/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { Result, FileTypes, FileResponse, FileSelectorApiCodec, wrapError } from './GeneratedFileSelectorApi'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import common from '@ohos.app.ability.common';
import { photoPickerSelect, documentPickerSelect, filePicker, getMimeTypeFromPath } from './FIleSelectorUtil'
import ArrayList from '@ohos.util.ArrayList';
import List from '@ohos.util.List';

const TAG = "FileSelectorApiImpl";
const DOCUMENT = "Document";
const TEXT_MIME_TYPE = "text/*";
const MIME_TYPE = "*/*";
const PICTURE = "Picture";
const TEXT = "Text";
export class FileSelectorApiImpl {

  binding: AbilityPluginBinding;

  constructor(binding: AbilityPluginBinding) {
    this.binding = binding;
  }

  openFileWithExtensions(initialDirectory: string, allowedTypes: FileTypes, result: Result<FileResponse>): void {
    Log.d(TAG, 'openFile types:' + allowedTypes.extensions + ' dir:' + initialDirectory)
    filePicker(initialDirectory, allowedTypes, 1).then(async (filePickerResult: ESObject) => {
      if (filePickerResult == undefined) {
        Log.i(TAG, 'documentPickerSelect cancelled or no file selected');
        result.success(null);
        return;
      }
      const uris = filePickerResult as string[];
      if (uris.length === 0) {
        Log.i(TAG, 'documentPickerSelect cancelled with empty selection');
        result.success(null);
        return;
      }
      try {
        let fileUris = await this.getUrisForPaths(uris);
        if (fileUris.length !== uris.length || fileUris.length === 0) {
          result.error(new Error('Failed to copy selected file to cache directory.'));
          return;
        }
        let uri: string = fileUris[0];
        const fileName: string = uri.substring(uri.lastIndexOf('/') + 1);
        Log.i(TAG, 'documentPickerSelect select file successfully, documentPicker uri: ' + uri);
        FileSelectorApiImpl.toFileResponse(uri, fileName)
          .then((file) => {
            result.success(file);
          }).catch((err: ESObject) => {
          Log.e(TAG, 'documentPickerSelect select file failed with err: ' + err);
          result.error(err);
        });
      } catch (err) {
        Log.e(TAG, 'Failed to prepare selected file: ' + JSON.stringify(err));
        result.error(new Error('Failed to prepare selected file.'));
      }
    }).catch((err: ESObject) => {
      Log.e(TAG, 'filePicker failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open file picker.'));
    });
  }

  openFilesWithExtensions(initialDirectory: string, allowedTypes: FileTypes, result: Result<Array<FileResponse>>): void {
    Log.d(TAG, 'openFiles mimeTypes:' + allowedTypes.mimeTypes
      + ' extensions:' + allowedTypes.extensions + ' dir:' + initialDirectory);

    filePicker(initialDirectory, allowedTypes).then((filePickerResult: ESObject) => {
      if (filePickerResult == undefined) {
        Log.i(TAG, 'documentPickerSelect cancelled or no files selected');
        result.success([]);
        return;
      }
      const uris = filePickerResult as string[];
      if (uris.length === 0) {
        Log.i(TAG, 'documentPickerSelect cancelled with empty selection');
        result.success([]);
        return;
      }
      Log.i(TAG, 'documentPickerSelect select files successfully, documentPicker uris: ' + filePickerResult);
      FileSelectorApiImpl.toFileListResponse(uris)
        .then((file) => {
          result.success(file);
        }).catch((err: ESObject) => {
        Log.e(TAG, 'documentPickerSelect select files failed with err: ' + err);
        result.error(err);
      });
    }).catch((err: ESObject) => {
      Log.e(TAG, 'filePicker failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open file picker.'));
    });
  }

  openFile(initialDirectory: string, allowedTypes: FileTypes, result: Result<FileResponse>): void {
    if (allowedTypes.getMimeTypes().length == 0) {
      allowedTypes.setMimeTypes(tryConvertExtensionsToMimetypes(allowedTypes.getExtensions()));
    }
    Log.d(TAG, 'openFile types:' + allowedTypes.mimeTypes + ' dir:' + initialDirectory)
    for (let type of allowedTypes.getMimeTypes()) {
      Log.d(TAG, 'openFile type:' + type)
      switch (type) {
        case picker.PhotoViewMIMETypes.IMAGE_TYPE:
        case picker.PhotoViewMIMETypes.VIDEO_TYPE:
        case picker.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE:
          try {
            let PhotoSelectOptions = new picker.PhotoSelectOptions();
            PhotoSelectOptions.MIMEType = type;
            PhotoSelectOptions.maxSelectNumber = 1;
            photoPickerSelect(PhotoSelectOptions, this.getContext()).then((PhotoSelectResult: picker.PhotoSelectResult) => {
              console.info('PhotoViewPicker.select successfully, PhotoSelectResult uri: ' + JSON.stringify(PhotoSelectResult));
              let res: picker.PhotoSelectResult = PhotoSelectResult;
              const photoUri: string = res.photoUris[0];
              const photoName: string = photoUri.substring(photoUri.lastIndexOf('/') + 1);
              FileSelectorApiImpl.toFileResponse(photoUri, photoName)
                .then((file) => {
                  result.success(file);
              }).catch((err: ESObject) => {
                  Log.e(TAG, 'PhotoViewPicker.select failed with err: ' + err);
                  result.error(err);
              });
            }).catch((err: ESObject) => {
              Log.e(TAG, 'PhotoViewPicker.select failed with err: ' + err);
              result.error(new Error("Failed to read file, err: " + err));
            });
          } catch (err) {
            console.error('PhotoViewPicker failed with err: ' + err);
            result.error(new Error("Failed to read file: " + initialDirectory));
          }
          break;
        case DOCUMENT:
          try {
            let documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.maxSelectNumber = 1;
            documentPickerSelect(documentSelectOptions, this.getContext()).then((documentPickerResult: ESObject) => {
              if (Number.isNaN(Number(documentPickerResult))) {
                let uri: string = documentPickerResult[0];
                const docName: string = uri.substring(uri.lastIndexOf('/') + 1);
                Log.i(TAG,'documentPickerSelect select successfully, documentPicker uri: ' + uri);
                FileSelectorApiImpl.toFileResponse(uri, docName)
                  .then((file) => {
                    result.success(file);
                  }).catch((err: ESObject) => {
                  Log.e(TAG, 'documentPickerSelect select failed with err: ' + err);
                  result.error(err);
                });
              } else {
                Log.e(TAG, 'documentPickerSelect select failed with errCode: ' + documentPickerResult);
                result.error(new Error("Failed to select file with errCode: " + documentPickerResult))
              }
            });
          } catch (err) {
            Log.e(TAG, 'documentPickerSelect select failed with err: ' + err);
            result.error(new Error("Failed to read file: " + initialDirectory));
          }
          break;
        default :
          break;
      }
    }
  }

  getContext(): common.UIAbilityContext {
    return this.binding.getAbility().context;
  }

  openFiles(initialDirectory: string, allowedTypes: FileTypes, result: Result<Array<FileResponse>>): void {
    if (allowedTypes.getMimeTypes().length == 0) {
      allowedTypes.setMimeTypes(tryConvertExtensionsToMimetypes(allowedTypes.getExtensions()));
    }
    for (let type of allowedTypes.getMimeTypes()) {
      Log.d(TAG, 'openFiles type:' + type)
      switch (type) {
        case picker.PhotoViewMIMETypes.IMAGE_TYPE:
        case picker.PhotoViewMIMETypes.VIDEO_TYPE:
        case picker.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE:
          try {
            let PhotoSelectOptions = new picker.PhotoSelectOptions();
            PhotoSelectOptions.MIMEType = type;
            PhotoSelectOptions.maxSelectNumber = 5;
            photoPickerSelect(PhotoSelectOptions, this.getContext()).then((PhotoSelectResult: picker.PhotoSelectResult) => {
              Log.i(TAG, 'PhotoViewPicker.select successfully, PhotoSelectResult uri: ' + JSON.stringify(PhotoSelectResult));
              const res: picker.PhotoSelectResult = PhotoSelectResult;
              FileSelectorApiImpl.toFileListResponse(res.photoUris)
                .then((files) => {
                  Log.i(TAG, 'PhotoViewPicker.select successfully, uri: ' + JSON.stringify(PhotoSelectResult));
                  result.success(files);
                }).catch((err: ESObject) => {
                  Log.e(TAG, 'PhotoViewPicker.select failed with err: ' + err);
                  result.error(err);
              });
            }).catch((err: ESObject) => {
              Log.e(TAG, 'PhotoViewPicker.select failed with err: ' + err);
              result.error(new Error("Failed to read file, err: " + err));
            });
          } catch (err) {
            Log.e(TAG, 'PhotoViewPicker failed with err: ' + err);
            result.error(new Error("Failed to read file: " + initialDirectory));
          }
          break;
        case DOCUMENT:
          try {
            let documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.maxSelectNumber = 5;
            documentPickerSelect(documentSelectOptions, this.getContext()).then((documentPickerResult: ESObject) => {
              if (Number.isNaN(Number(documentPickerResult))) {
                let pickerResult = documentPickerResult as Array<string>;
                Log.i(TAG,'documentPickerSelect select successfully, documentPicker uris: ' + pickerResult.toString());
                FileSelectorApiImpl.toFileListResponse(pickerResult)
                  .then((files) => {
                    result.success(files);
                  }).catch((err: ESObject) => {
                  Log.e(TAG, 'documentPickerSelect select failed with err: ' + err);
                  result.error(err);
                });
              } else {
                Log.e(TAG, 'documentPickerSelect select failed with errCode: ' + documentPickerResult);
                result.error(new Error("Failed to select file with errCode: " + documentPickerResult))
              }
            });
          } catch (err) {
            Log.e(TAG, 'documentPickerSelect select failed with err: ' + err);
            result.error(new Error("Failed to read file: " + initialDirectory));
          }
          break;
        default :
          break;
      }
    }
  }

  getDirectoryPath(initialDirectory: string, result: Result<string>): void {
    throw new Error('Method not implemented.')
  }

  async getUrisForPaths(paths: string[]): Promise<Array<string>> {
    Log.i(TAG, 'getUrisForPaths, count: ' + paths.length);
    const uris: Array<string> = [];
    if (paths.length === 0) {
      return uris;
    }
    const folder: string = this.getContext().cacheDir;
    if (!fs.accessSync(folder)) {
      fs.mkdirSync(folder);
    }
    try {
      for (let i = 0; i < paths.length; i++) {
        const path: string = paths[i];
        const oldFile: fs.File = fs.openSync(path);
        try {
          const newFile: string = folder + '/' + oldFile.name;
          fs.copyFileSync(oldFile.fd, newFile);
          uris.push(newFile);
        } finally {
          fs.closeSync(oldFile);
        }
      }
      return uris;
    } catch (err) {
      Log.e(TAG, 'Failed to getUrisForPaths: ' + JSON.stringify(err));
      for (let i = 0; i < uris.length; i++) {
        const copiedUri: string = uris[i];
        try {
          fs.unlinkSync(copiedUri);
        } catch (cleanupErr) {
          Log.w(TAG, 'Failed to cleanup copied file: ' + copiedUri + ', err: ' + JSON.stringify(cleanupErr));
        }
      }
      throw new Error('Failed to copy selected files to cache directory.');
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
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openFile", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          Log.d(TAG, 'onMessage reply:' + reply)
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const allowedTypesArg = args[1] as FileTypes;
          const resultCallback: Result<FileResponse> = new ResultBuilder((result: FileResponse | null): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          },(error: Error): void => {
            const wrappedError: ArrayList<ESObject> = msg.wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFileWithExtensions(initialDirectoryArg, allowedTypesArg, resultCallback);
        }
      });
    }
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject>  = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openFiles", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          Log.d(TAG, 'onMessage reply:' + reply)
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const allowedTypesArg = args[1] as FileTypes;
          const resultCallback: Result<Array<FileResponse>> = new ResultsBuilder((result: Array<FileResponse> | null): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          },(error: Error): void => {
            const wrappedError: ArrayList<ESObject> = msg.wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFilesWithExtensions(initialDirectoryArg, allowedTypesArg, resultCallback);
        }
      });
    }
  }

  static async toFileResponse(uri: string, name: string): Promise<FileResponse> {
    const mimeType: string = getMimeTypeFromPath(uri, name);
    let file = fs.openSync(uri);
    try {
      let stat = fs.statSync(file.fd);
      let size = stat.size;
      let buffer = new ArrayBuffer(size);
      fs.readSync(file.fd, buffer, {offset: 0, length: size});
      let byteArray = new Uint8Array(buffer);
      let response = new FileResponse(uri, mimeType, name, size, byteArray);
      return new Promise((resolve) => {
        resolve(response);
      })
    } finally {
      fs.closeSync(file);
    }
  }

  static async toFileListResponse(uris: string[]): Promise<Array<FileResponse>> {
    let files = new Array<FileResponse>();
    for (let i = 0; i < uris.length; i++) {
      const uri: string = uris[i];
      const name: string = uri.substring(uri.lastIndexOf('/') + 1);
      try {
        const mimeType: string = getMimeTypeFromPath(uri, name);
        let file = fs.openSync(uri);
        try {
          let stat = fs.statSync(file.fd);
          let size = stat.size;
          let buffer = new ArrayBuffer(size);
          fs.readSync(file.fd, buffer, {offset: 0, length: size});
          let byteArray = new Uint8Array(buffer);
          let response = new FileResponse(uri, mimeType, name, size, byteArray);
          files.push(response);
        } finally {
          fs.closeSync(file);
        }
      } catch (err) {
        Log.e(TAG, 'Skip unreadable file uri: ' + uri + ', err: ' + JSON.stringify(err));
      }
    }

    return new Promise((resolve) => {
      resolve(files);
    })
  }
}

function tryConvertExtensionsToMimetypes(list: Array<string>): Array<string> | null {
  if (list == undefined || list.length == 0) {
    Log.w(TAG, 'list is empty')
    return null;
  }
  let mimeTypes = new Array<string>()
  for (let str of list) {
    switch (str) {
      case 'png':
      case 'jpg':
      case 'jpeg':
        if (mimeTypes.indexOf(picker.PhotoViewMIMETypes.IMAGE_TYPE) == -1) {
          mimeTypes.push(picker.PhotoViewMIMETypes.IMAGE_TYPE)
        }
        break;
      case 'txt':
      case 'json':
      default :
        if (mimeTypes.indexOf(DOCUMENT) == -1) {
          mimeTypes.push(DOCUMENT);
        }
        break;
    }
  }
  return mimeTypes;
}

class ResultBuilder{
  success : (result: FileResponse | null)=>void
  error: (error: Error) =>void

  constructor(success:ESObject , error:ESObject) {
    this.success = success
    this.error = error
  }
}
class ResultsBuilder{
  success : (result: Array<FileResponse> | null)=>void
  error: (error: Error) =>void

  constructor(success:ESObject , error:ESObject) {
    this.success = success
    this.error = error
  }
}
