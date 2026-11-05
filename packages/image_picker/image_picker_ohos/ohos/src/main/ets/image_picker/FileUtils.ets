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
      // Temp files are consolidated into the cacheDir/image_picker_tmp subdirectory so they can be
      // cleaned up in one pass on plugin detach, preventing unbounded cache growth
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
        // openSync must be inside the try: if openSync throws, finally can still close inputFile, avoiding an fd leak
        outputFile = fs.openSync(outputFilePath, fs.OpenMode.CREATE);
        Log.i(TAG, 'copyFileSync inputFile fd:' + inputFile.fd + ' outputFile fd:' + outputFile.fd);
        fs.copyFileSync(inputFile.fd, outputFilePath);
      } catch (err) {
        // Clean up the created file and directory; outputFile is closed in finally, so it is not
        // closed again here, avoiding a double close
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

  // Plugin-specific temp directory: idempotently creates cacheDir/image_picker_tmp
  static getTempDirectory(context: common.Context): string {
    const tempDir: string = context.cacheDir + '/image_picker_tmp';
    try {
      fs.mkdirSync(tempDir);
    } catch (e) {
      // Ignore if the directory already exists (mkdirSync throws on an existing directory)
    }
    return tempDir;
  }

  // Clean up the temp directory on plugin detach: delete all files and subdirectories under
  // image_picker_tmp to prevent unbounded cache growth.
  // Camera capture outputs (IMG_/VID_ files located directly in cacheDir, not this directory) are
  // not covered by this cleanup.
  static cleanupTempFiles(context: common.Context | null): void {
    if (context == null) {
      return;
    }
    const tempDir: string = context.cacheDir + '/image_picker_tmp';
    FileUtils.deleteDirectoryRecursively(tempDir);
    // Upgrade compatibility: also clean up temp files scattered in the cacheDir root by older versions
    FileUtils.cleanupLegacyTempFiles(context);
  }

  // Upgrade-compatibility cleanup: before the 3.44 quality hardening, the old getPathFromUri wrote URI copy
  // directories directly to cacheDir/{uuid}; once the new version consolidated them into image_picker_tmp, those
  // old directories were no longer covered by the deletion logic above. They are matched here by exact uuid
  // format as a fallback cleanup, to avoid mistakenly deleting the host app's own cache contents.
  private static cleanupLegacyTempFiles(context: common.Context): void {
    let entries: string[] = [];
    try {
      entries = fs.listFileSync(context.cacheDir);
    } catch (e) {
      // Return silently if the directory cannot be read
      return;
    }
    // The old version's directory name is util.generateRandomUUID(), hexadecimal in 8-4-4-4-12 format
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
      // The current SDK's @ohos.file.fs does not provide opendirSync/Dir (newer APIs); use
      // listFileSync to enumerate directory entries instead
      fileNames = fs.listFileSync(dirPath);
    } catch (e) {
      // Return silently if the directory does not exist, has already been cleaned up, or access is denied
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
      // Return silently if directory deletion fails (it may already have been cleaned up)
    }
  }
}