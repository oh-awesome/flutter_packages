// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on FlutterAssetManagerHostApiImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { FlutterAssetManager } from './FlutterAssetManager';
import { FlutterAssetManagerHostApi } from './GeneratedOhosWebView';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';

const TAG:string = "FlutterAssetManagerHostApiImpl"
export class FlutterAssetManagerHostApiImpl extends FlutterAssetManagerHostApi {
  private flutterAssetManager: FlutterAssetManager;

  constructor(flutterAssetManager: FlutterAssetManager) {
    super()
    this.flutterAssetManager = flutterAssetManager;
  }

  async list(path: string): Promise<string[]> {
    try {
      let paths: string[] = await this.flutterAssetManager.list(path);
      if (paths.length == 0) {
        return [];
      }
      return paths;
    } catch (err) {
      // Error-path fix only: rethrow the original error instead of returning
      // an empty array, so Dart can tell a failed read from an empty
      // directory. A successful empty directory still returns [].
      Log.e(TAG, 'list failed err:' + err);
      throw new Error(String(err));
    }
  }

  getAssetFilePathByName(name: string): string {
    return this.flutterAssetManager.getAssetFilePathByName(name)
  }
}

