// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

class VideoPlayerOhosChannel {
  static final channel = MethodChannel('plugins.flutter.io/video_player_ohos');

  static Future<int> getFileFdByPath(String? path) async {
    int fileFd = -1;
    if (path == null) {
      return fileFd;
    }
    fileFd = await channel.invokeMethod('getFileFdByPath', {
      'filePath': path,
    });
    return fileFd;
  }

  /// 关闭由 [getFileFdByPath] 打开、但未被播放器消费的文件描述符。
  ///
  /// create 失败或未走到 fd 消费路径时，原生侧不会关闭该 fd，需要显式回收，
  /// 否则高频创建场景下会耗尽系统 fd（Too many open files）。
  static Future<void> closeFileFd(int fd) async {
    if (fd < 0) {
      return;
    }
    try {
      await channel.invokeMethod('closeFileFd', {
        'fd': fd,
      });
    } catch (_) {
      // fd 可能已被播放器释放，关闭失败无需上抛。
    }
  }

  /// 透传 preventsDisplaySleepDuringVideoPlayback 到原生，
  /// 驱动播放期屏幕常亮按平台标志控制（false 时允许播放中休眠）。
  static Future<void> setKeepScreenOn(int playerId, bool keepScreenOn) async {
    if (playerId < 0) {
      return;
    }
    try {
      await channel.invokeMethod('setKeepScreenOn', {
        'playerId': playerId,
        'keepScreenOn': keepScreenOn,
      });
    } catch (_) {
      // 原生旧版本无该分支时 notImplemented/异常均可安全忽略，保持 no-op 兼容。
    }
  }
}
