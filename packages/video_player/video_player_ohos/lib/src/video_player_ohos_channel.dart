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

  /// Close a file descriptor opened by [getFileFdByPath] but not consumed by the
  /// player.
  ///
  /// When create fails or the fd-consumption path is not reached, the native side
  /// will not close this fd, so it must be reclaimed explicitly; otherwise frequent
  /// creation would exhaust the system fds (Too many open files).
  static Future<void> closeFileFd(int fd) async {
    if (fd < 0) {
      return;
    }
    try {
      await channel.invokeMethod('closeFileFd', {
        'fd': fd,
      });
    } catch (_) {
      // The fd may already have been released by the player; a close failure does
      // not need to be rethrown.
    }
  }

  /// Pass preventsDisplaySleepDuringVideoPlayback through to the native side,
  /// driving the keep-screen-on-during-playback behavior per the platform flag
  /// (false allows sleeping while playing).
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
      // On older native versions that lack this branch, both notImplemented and
      // other exceptions can be safely ignored to stay no-op compatible.
    }
  }
}
