// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:example/demo_sources.dart';

void main() {
  test('SDR and HDR asset paths stay distinct', () {
    expect(DemoSources.assetPath(hdr: false), 'assets/video1.mp4');
    expect(DemoSources.assetPath(hdr: true), 'assets/video_hdr_hlg.mp4');
  });

  test('SDR remote stays the Sintel trailer', () {
    expect(
      DemoSources.remoteUrl(hdr: false),
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
    );
  });

  test('HDR remote uses trimmed override and does not invent a URL', () {
    expect(DemoSources.remoteUrl(hdr: true), isEmpty);
    expect(DemoSources.remoteUrl(hdr: true, hdrOverride: '  '), isEmpty);
    expect(
      DemoSources.remoteUrl(
        hdr: true,
        hdrOverride: ' https://example.com/hdr.mp4 ',
      ),
      'https://example.com/hdr.mp4',
    );
  });

  test('HDR asset copied to disk is labeled as a network file URI', () {
    expect(
      DemoSources.hdrAssetAsNetworkHint('/tmp/video_hdr_hlg.mp4'),
      'network file://（asset assets/video_hdr_hlg.mp4）\n/tmp/video_hdr_hlg.mp4',
    );
  });

  test('device path becomes a file URI for the network data source', () {
    expect(
      DemoSources.fileUriForPath('/data/local/tmp/video_hdr_hlg.mp4'),
      'file:///data/local/tmp/video_hdr_hlg.mp4',
    );
    expect(
      DemoSources.fileUriForPath('file:///data/local/tmp/video_hdr_hlg.mp4'),
      'file:///data/local/tmp/video_hdr_hlg.mp4',
    );
  });

  test('HDR missing-source messages tell testers how to load the clip', () {
    expect(DemoSources.missingHdrAssetMessage(), contains('video_hdr_hlg.mp4'));
    expect(DemoSources.missingHdrRemoteMessage(), contains('network'));
  });
}
