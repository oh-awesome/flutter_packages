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

import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import { FileTypes } from './GeneratedFileSelectorApi';
import { BusinessError } from '@kit.BasicServicesKit';
import { Log } from '@ohos/flutter_ohos';

const TAG = "FileSelectorUtil";
enum PhotoViewMIMETypes {
  IMAGE_TYPE = 'image/*',
  VIDEO_TYPE = 'video/*',
  IMAGE_VIDEO_TYPE = '*/*',
  INVALID_TYPE = ''
}


const PHOTO_VIEW_MIME_TYPE_MAP = new Map([
  [PhotoViewMIMETypes.IMAGE_TYPE, 'FILTER_MEDIA_TYPE_IMAGE'],
  [PhotoViewMIMETypes.VIDEO_TYPE, 'FILTER_MEDIA_TYPE_VIDEO'],
  [PhotoViewMIMETypes.IMAGE_VIDEO_TYPE, 'FILTER_MEDIA_TYPE_ALL'],
]);

function normalizeFileSuffix(extensionType: string): string {
  return extensionType.startsWith('.') ? extensionType : '.' + extensionType;
}


interface  ConfigText {
   action: string;
   type: string;
   parameters: ESObject;
}
export async function photoPickerSelect(option: picker.PhotoSelectOptions, context: common.UIAbilityContext): Promise<ESObject> {
  let config: ConfigText = {
    action: 'ohos.want.action.photoPicker',
    type: 'multipleselect',
    parameters: {
      uri: 'multipleselect',
      maxSelectCount: 5,
      filterMediaType: '*/*'
    },
  }

  if (option.maxSelectNumber != null && option.maxSelectNumber > 0) {
    let select = (option.maxSelectNumber === 1) ? 'singleselect' : 'multipleselect';
    config.type = select;
    config.parameters.uri = select;
    config.parameters.maxSelectCount = option.maxSelectNumber;
  }
  if (option.MIMEType != null && option.MIMEType.length > 0 && PHOTO_VIEW_MIME_TYPE_MAP.has(option.MIMEType)) {
    config.parameters.filterMediaType = PHOTO_VIEW_MIME_TYPE_MAP.get(option.MIMEType);
  }

  try {
    let result = await context.startAbilityForResult(config, {displayId: 1});
    console.log('[picker] result: ' + JSON.stringify(result));
    let uris: ESObject = null;
    let isOrigin: ESObject = null;
    if (result.want?.parameters != null) {
      uris = result.want.parameters['select-item-list'];
      isOrigin = result.want.parameters['isOriginal'];
    }
    let selectResult: ESObject  = new picker.PhotoSelectResult();
    if (result.resultCode === -1) {
      result.resultCode = 0;
      uris = [];
      selectResult = null;
    } else {
      selectResult.photoUris = uris as Array<string>;
      selectResult.isOriginalPhoto = isOrigin as boolean;
    }

    return new Promise<picker.PhotoSelectResult>((resolve, reject) => {
      if (result.resultCode === 0) {
        resolve(selectResult);
      } else {
        console.log('[picker] err: ' + result.resultCode);
        reject(result.resultCode);
      }
    })
  } catch (error) {
    console.log('[picker] error: ' + error);
  }
  return undefined;
}

interface ConfigParameters {
  action: string;
  parameters: ESObject;
}

export async function documentPickerSelect(option: picker.DocumentSelectOptions, context: common.UIAbilityContext): Promise<ESObject> {
  let config: ConfigParameters = {
    action: 'ohos.want.action.OPEN_FILE',
    parameters: {
      startMode: 'choose',
      key_file_suffix_filter: [".txt", ".json"],
      key_pick_dir_path: ''

    }
  }

  if (option.maxSelectNumber != null && option.maxSelectNumber > 0) {
    config.parameters.key_pick_num = option.maxSelectNumber;
  }

  if (option.defaultFilePathUri != null) {
      config.parameters.key_pick_dir_path = option.defaultFilePathUri;
    }

    let file_suffix: string[] = [];
    if (option.fileSuffixFilters != null) {
      for (let extensionType of option.fileSuffixFilters) {
        file_suffix.push(normalizeFileSuffix(extensionType));
      }
      config.parameters.key_file_suffix_filter = file_suffix;
    }

  try {
    let result = await context.startAbilityForResult(config, {displayId: 1});
    let select_item_list: ESObject = result.want?.parameters?.['ability.params.stream'];
    let uris: ESObject = select_item_list.valueOf();

    return new Promise<ESObject>((resolve, reject) => {
      if (result.resultCode === 0) {
        resolve(uris);
      } else {
        console.error('[picker] err: ' + result.resultCode +  "message" + result.want?.parameters?.message);
        reject(result.resultCode);
      }
    })
  } catch (err) {
    console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
  }
  return undefined;
}

/** 通配符 MIME 对应的扩展名集合 */
const IMAGE_WILDCARD_EXTENSIONS: Array<string> = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
const VIDEO_WILDCARD_EXTENSIONS: Array<string> = ['mp4', '3gp', 'webm', 'mov', 'mkv'];
const AUDIO_WILDCARD_EXTENSIONS: Array<string> = ['mp3', 'wav', 'aac', 'flac'];

 /** 文件后缀的反向映射表 */
const MIME_TO_EXTENSIONS: Map<string, Array<string>> = new Map<string, Array<string>>([
  ['image/*', IMAGE_WILDCARD_EXTENSIONS],
  ['video/*', VIDEO_WILDCARD_EXTENSIONS],
  ['audio/*', AUDIO_WILDCARD_EXTENSIONS],
  ['image/jpeg', ['jpg', 'jpeg']],
  ['image/png', ['png']],
  ['image/gif', ['gif']],
  ['image/webp', ['webp']],
  ['image/bmp', ['bmp']],
  ['image/svg+xml', ['svg']],
  ['video/mp4', ['mp4']],
  ['video/3gpp', ['3gp']],
  ['video/webm', ['webm']],
  ['video/quicktime', ['mov']],
  ['video/x-matroska', ['mkv']],
  ['audio/mpeg', ['mp3']],
  ['audio/x-wav', ['wav']],
  ['audio/aac', ['aac']],
  ['audio/flac', ['flac']],
  ['application/pdf', ['pdf']],
  ['application/msword', ['doc']],
  ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', ['docx']],
  ['application/vnd.ms-excel', ['xls']],
  ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', ['xlsx']],
  ['application/vnd.ms-powerpoint', ['ppt']],
  ['application/vnd.openxmlformats-officedocument.presentationml.presentation', ['pptx']],
  ['text/plain', ['txt', 'log']],
  ['text/csv', ['csv']],
  ['text/html', ['html', 'htm']],
  ['text/xml', ['xml']],
  ['application/json', ['json']],
  ['application/xml', ['xml']],
  ['application/zip', ['zip']],
  ['application/gzip', ['gz']],
  ['application/x-tar', ['tar']],
  ['application/x-7z-compressed', ['7z']],
  ['application/x-rar-compressed', ['rar']],
]);

const EXTENSION_TO_MIME: Map<string, string> = buildExtensionToMimeMap();

function buildExtensionToMimeMap(): Map<string, string> {
  const map: Map<string, string> = new Map<string, string>();
  MIME_TO_EXTENSIONS.forEach((exts: Array<string>, mime: string): void => {
    if (mime.endsWith('/*')) {
      return;
    }
    for (let ext of exts) {
      map.set(ext.toLowerCase(), mime);
    }
  });
  MIME_TO_EXTENSIONS.forEach((exts: Array<string>, mime: string): void => {
    if (!mime.endsWith('/*')) {
      return;
    }
    for (let ext of exts) {
      const key: string = ext.toLowerCase();
      if (!map.has(key)) {
        map.set(key, mime);
      }
    }
  });
  return map;
}

function extractFileExtension(pathOrName: string): string {
  const baseName: string = pathOrName.substring(pathOrName.lastIndexOf('/') + 1);
  const queryIndex: number = baseName.indexOf('?');
  const name: string = queryIndex >= 0 ? baseName.substring(0, queryIndex) : baseName;
  const dotIndex: number = name.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex === name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

/**
 * 根据文件路径或文件名解析 MIME 类型（优先具体类型，其次通配符类型）。
 */
export function getMimeTypeFromPath(path: string, fileName?: string): string {
  const source: string = (fileName != null && fileName.length > 0) ? fileName : path;
  const extension: string = extractFileExtension(source);
  if (extension.length === 0) {
    return 'application/octet-stream';
  }
  const mime: string | undefined = EXTENSION_TO_MIME.get(extension);
  if (mime != null) {
    return mime;
  }
  Log.w(TAG, 'Unknown extension for MIME lookup: ' + extension);
  return 'application/octet-stream';
}

 //把 mime 列表反向映射为对应的扩展名列表
export function tryConvertMimetypesToExtensions(mimeTypes: Array<string> | null): Array<string> {
  let result: Array<string> = [];
  if (mimeTypes == null || mimeTypes.length === 0) {
    return result;
  }
  let extSet: Set<string> = new Set<string>();
  for (let mime of mimeTypes) {
    let exts: Array<string> | undefined = MIME_TO_EXTENSIONS.get(mime);
    if (exts != null) {
      for (let ext of exts) {
        extSet.add(ext);
      }
    } else {
      Log.w(TAG, '[mimeTypes] MIME type "' + mime + '" is NOT in the built-in mapping on OpenHarmony. ');
    }
  }
  extSet.forEach((value: string): void => {
    result.push(value);
  });
  return result;
}

export async function filePicker(initialDirectory: string, allowedTypes: FileTypes, selectorNumber?: number): Promise<ESObject> {
  let documentSelectOptions = new picker.DocumentSelectOptions();
  documentSelectOptions.defaultFilePathUri = initialDirectory;
  if (selectorNumber != undefined) {
    documentSelectOptions.maxSelectNumber = selectorNumber;
  }
  let file_suffix_set: Set<string> = new Set<string>();
  if (allowedTypes.extensions != null) {
    for (let extensionType of allowedTypes.extensions) {
      file_suffix_set.add(normalizeFileSuffix(extensionType));
    }
  }
  if (allowedTypes.mimeTypes != null && allowedTypes.mimeTypes.length > 0) {
    let derived: Array<string> = tryConvertMimetypesToExtensions(allowedTypes.mimeTypes);
    for (let extensionType of derived) {
      file_suffix_set.add(normalizeFileSuffix(extensionType));
    }
  }
  documentSelectOptions.fileSuffixFilters = Array.from(file_suffix_set);
  try {
    const documentViewPicker = new picker.DocumentViewPicker();
    let documentSelectResult = await documentViewPicker.select(documentSelectOptions);
    Log.i(TAG, "documentViewPicker select file succeed.");
    return new Promise<ESObject> ((resolve) => {resolve(documentSelectResult)});
  } catch (err) {
    Log.e(TAG, "documentViewPicker select file failed: " + JSON.stringify(err));
    return new Promise<ESObject> ((resolve, reject) => {reject(err)});
  }
}
