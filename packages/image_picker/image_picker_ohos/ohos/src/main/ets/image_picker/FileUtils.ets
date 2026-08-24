// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on FileUtils.java originally written by
// Copyright 2013 The Flutter Authors.

import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { systemDateTime } from '@kit.BasicServicesKit';

const TAG = 'FileUtils';

export default class FileUtils {
  static getPathFromUri(context: common.Context | null, uri: string, defExtension?: string): string|null {
    Log.i(TAG, 'getPathFromUri : ' + uri);
    let inputFile: fs.File;
    try {
      inputFile = fs.openSync(uri);
    } catch (err) {
      Log.e(TAG, 'open uri file failed err:' + err)
      return null;
    }
    if (inputFile == null) {
      return null;
    }
    const uuid = util.generateRandomUUID();
    if (!context) {
      fs.closeSync(inputFile);
      return null;
    }
    {
      // 临时文件统一收敛到 cacheDir/image_picker_tmp 子目录下，便于插件 detach 时整体清理，避免缓存无限累积
      const targetDirectoryPath = FileUtils.getTempDirectory(context) + '/' + uuid;
      try {
        fs.mkdirSync(targetDirectoryPath);
        Log.i(TAG, 'mkdirSync success targetDirectoryPath:' + targetDirectoryPath);
      } catch (err) {
        Log.e(TAG, 'mkdirSync failed err:' + err);
        fs.closeSync(inputFile);
        return null;
      }

      const inputFilePath = uri.substring(uri.lastIndexOf('/') + 1);
      let inputFilePathSplits = inputFilePath.split('.');
      Log.i(TAG, 'getPathFromUri inputFilePath: ' + inputFilePath);
      let outputFileName: string = '';
      let extension: string = '';
      if (inputFilePathSplits.length === 1) {
        outputFileName = inputFilePathSplits[0];
        extension = 'jpg';
      } else if (inputFilePathSplits.length === 2) {
        outputFileName = inputFilePathSplits[0];
        extension = inputFilePathSplits[1];
      } else if (inputFilePathSplits.length > 2) {
        extension = inputFilePathSplits.pop() || '';
        outputFileName = inputFilePathSplits.join('.');
      }
      if(!outputFileName){
        outputFileName = 'image_picker';
      }
      if(!extension){
        if (defExtension) {
          extension = defExtension;
        } else {
          extension = 'jpg';
        }
      }

      let timeStamp: string = systemDateTime.getTime().toString();
      const outputFilePath = targetDirectoryPath + '/' + outputFileName + timeStamp + '.' + extension;
      let outputFile: fs.File | null = null;
      try {
        // openSync 必须放入 try：若 openSync 抛异常，finally 仍能关闭 inputFile，避免 fd 泄漏
        outputFile = fs.openSync(outputFilePath, fs.OpenMode.CREATE);
        Log.i(TAG, 'copyFileSync inputFile fd:' + inputFile.fd + ' outputFile fd:' + outputFile.fd);
        fs.copyFileSync(inputFile.fd, outputFilePath);
      } catch (err) {
        // 清理已创建的文件与目录；outputFile 由 finally 统一关闭，这里不重复 close，避免双重关闭
        Log.e(TAG, 'copyFileSync failed err:' + err);
         try {
            fs.unlinkSync(outputFilePath);
          } catch (e) {
           Log.e(TAG, 'unlinkSync failed err:' + e);}
          try {
            fs.rmdirSync(targetDirectoryPath);
          } catch (e) {
            Log.e(TAG, 'rmdirSync failed err:' + e);
          }
        return null;
      } finally {
        fs.closeSync(inputFile);
        if (outputFile != null) {
          try {
            fs.closeSync(outputFile);
          } catch (e) {
            Log.e(TAG, 'closeSync failed err:' + e);
          }
        }
      }
      return outputFilePath;
    }
  }

  // 插件专用临时目录：幂等创建 cacheDir/image_picker_tmp
  static getTempDirectory(context: common.Context): string {
    const tempDir: string = context.cacheDir + '/image_picker_tmp';
    try {
      fs.mkdirSync(tempDir);
    } catch (e) {
      // 目录已存在则忽略（mkdirSync 对已存在目录会抛错）
    }
    return tempDir;
  }

  // 插件 detach 时清理临时目录：删除 image_picker_tmp 下所有文件与子目录，防止缓存无限累积。
  // 相机拍摄产物（IMG_/VID_ 直接位于 cacheDir，非本目录）不在此清理范围。
  static cleanupTempFiles(context: common.Context | null): void {
    if (context == null) {
      return;
    }
    const tempDir: string = context.cacheDir + '/image_picker_tmp';
    FileUtils.deleteDirectoryRecursively(tempDir);
    // 兼容升级：一并清理旧版本散落在 cacheDir 根目录的临时文件
    FileUtils.cleanupLegacyTempFiles(context);
  }

  // 兼容升级清理：3.44 质量加固前，旧版本 getPathFromUri 将 URI 拷贝副本直接写入
  // cacheDir/{uuid}，新版本统一收敛到 image_picker_tmp 后，这些老目录不会被上面的删除逻辑覆盖。
  // 此处按 uuid 格式精确匹配兜底清理，避免误删宿主 App 自身的 cache 内容。
  private static cleanupLegacyTempFiles(context: common.Context): void {
    let entries: string[] = [];
    try {
      entries = fs.listFileSync(context.cacheDir);
    } catch (e) {
      // 目录不可读时静默返回
      return;
    }
    // 旧版本目录名即 util.generateRandomUUID()，格式为 8-4-4-4-12 的十六进制
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    for (let i = 0; i < entries.length; i++) {
      const name = entries[i];
      if (uuidRegex.test(name)) {
        FileUtils.deleteDirectoryRecursively(context.cacheDir + '/' + name);
      }
    }
  }

  private static deleteDirectoryRecursively(dirPath: string): void {
    let fileNames: string[] = [];
    try {
      // 当前 SDK 的 @ohos.file.fs 未提供 opendirSync/Dir（较新 API），改用 listFileSync 枚举目录项
      fileNames = fs.listFileSync(dirPath);
    } catch (e) {
      // 目录不存在、已被清理或无权限时静默返回
      return;
    }
    for (let i = 0; i < fileNames.length; i++) {
      const childPath: string = dirPath + '/' + fileNames[i];
      try {
        const stat = fs.statSync(childPath);
        if (stat.isDirectory()) {
          FileUtils.deleteDirectoryRecursively(childPath);
        } else {
          try {
            fs.unlinkSync(childPath);
          } catch (e) {
            Log.e(TAG, 'unlinkSync failed: ' + e);
          }
        }
      } catch (e) {
        Log.e(TAG, 'stat child failed: ' + e);
      }
    }
    try {
      fs.rmdirSync(dirPath);
    } catch (e) {
      // 删除目录失败（可能已被清理）时静默返回
    }
  }
}