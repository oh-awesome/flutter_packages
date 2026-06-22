// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import { FileTypes } from './GeneratedFileSelectorApi';
import { BusinessError } from '@kit.BasicServicesKit';
import { Log } from '@ohos/flutter_ohos';

const TAG = "FileSelectorUtil";

/**
 * 规范化文件后缀：若无前导点则自动补上
 */
function normalizeFileSuffix(extensionType: string): string {
  return extensionType.startsWith('.') ? extensionType : '.' + extensionType;
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

/**
 * 根据 MIME_TO_EXTENSIONS 构建扩展名到 MIME 的反向映射表。
 * 优先使用具体 MIME（如 image/jpeg）。
 */
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

/**
 * 从文件路径或文件名中提取扩展名（不含点号，小写）。
 * 会去掉路径前缀与 URI 查询参数；无有效扩展名时返回空字符串。
 * @param pathOrName 文件路径或文件名
 * @returns 扩展名
 */
function extractFileExtension(pathOrName: string): string {
  const baseName: string = pathOrName.substring(pathOrName.lastIndexOf('/') + 1);
  const queryIndex: number = baseName.indexOf('?');
  const name: string = queryIndex >= 0 ? baseName.substring(0, queryIndex) : baseName;
  const dotIndex: number = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex === name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

/**
 * 根据文件路径或文件名解析 MIME 类型。
 * 优先匹配具体类型，其次匹配通配符类型；未知扩展名返回 application/octet-stream。
 * @param path 文件路径
 * @param fileName 可选的文件名（优先于 path 用于解析）
 * @returns MIME 类型字符串
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

/**
 * 将 mime 列表反向映射为对应的扩展名列表（去重）。
 * 未在内置映射表中的 MIME 类型会记录警告日志并跳过。
 * @param mimeTypes MIME 类型数组
 * @returns 扩展名数组
 */
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
  // Omit fileSuffixFilters when empty to allow all types, aligned with setType("*/*").
  if (file_suffix_set.size > 0) {
    documentSelectOptions.fileSuffixFilters = Array.from(file_suffix_set);
  }
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
