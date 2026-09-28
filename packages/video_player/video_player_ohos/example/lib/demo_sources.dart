// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Shared SDR/HDR clip selection for the example app.
class DemoSources {
  DemoSources._();

  static const String sdrAsset = 'assets/video1.mp4';
  static const String hdrAsset = 'assets/video_hdr_hlg.mp4';
  static const String sdrRemote =
      'https://media.w3.org/2010/05/sintel/trailer.mp4';
  static const String hdrFileName = 'video_hdr_hlg.mp4';

  /// Sandbox files/ then hdc `/data/local/tmp`.
  static const List<String> pushedHdrPaths = <String>[
    '/data/storage/el2/base/haps/entry/files/$hdrFileName',
    '/data/local/tmp/$hdrFileName',
  ];

  static String assetPath({required bool hdr}) {
    return hdr ? hdrAsset : sdrAsset;
  }

  /// HDR has no stable public HTTP URL. Demo falls back to copying [hdrAsset]
  /// to disk and playing it as a `file://` network source.
  static String remoteUrl({required bool hdr, String? hdrOverride}) {
    if (!hdr) {
      return sdrRemote;
    }
    return hdrOverride?.trim() ?? '';
  }

  static String hdrAssetAsNetworkHint(String path) {
    return 'network file://（asset $hdrAsset）\n$path';
  }

  static String fileUriForPath(String path) {
    final String trimmed = path.trim();
    if (trimmed.startsWith('file:')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return 'file://$trimmed';
    }
    return Uri.file(trimmed).toString();
  }

  static String missingHdrAssetMessage() {
    return '未找到 HDR asset assets/video_hdr_hlg.mp4。'
        '请确认 pubspec.yaml 已声明该资源后重新运行。';
  }

  static String missingHdrRemoteMessage() {
    return '未设置 HDR URL，也无法从 $hdrAsset 转出 file:// 网络源。\n'
        '填写 URL，或 hdc file send 后点「用推送 HDR 走 network」。';
  }
}
