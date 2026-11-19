/**
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following
 * disclaimer in the documentation and/or other materials provided
 * with the distribution.
 *  * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * */

import { describe, it, expect } from '@ohos/hypium';
import { VideoPlayerApiImpl } from '../../../main/ets/components/videoplayer/VideoPlayerApiImpl';
import { TextureMessage } from '../../../main/ets/components/videoplayer/Messages';
import HashMap from '@ohos.util.HashMap';
import { image } from '@kit.ImageKit';

// Test double that records release() calls. VideoPlayerApiImpl tracks its
// background PixelMaps in a private map with no public seam, so the double is
// injected through ESObject and typed as image.PixelMap to reuse the
// production lookup paths.
class FakePixelMap {
  public releaseCount: number = 0;

  release(): void {
    this.releaseCount++;
  }
}

function asPixelMap(fake: FakePixelMap): image.PixelMap {
  return fake as ESObject as image.PixelMap;
}

// Reach the private pixelMaps field to seed it with the tracked test doubles.
function pixelMapsOf(impl: VideoPlayerApiImpl): HashMap<string, image.PixelMap> {
  return (impl as ESObject).pixelMaps as HashMap<string, image.PixelMap>;
}

/**
 * Unit tests for the background PixelMap lifecycle of VideoPlayerApiImpl.
 * They guard the memory leak fix: every tracked background PixelMap must be
 * released on initialize/detach/dispose and when the first video frame
 * supersedes the black background frame.
 */
export default function videoPlayerTest() {
  describe('VideoPlayerTest', () => {
    it('videoPlayerApiImpl_pixelMapRelease_releasesEveryTrackedPixelMap', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const first = new FakePixelMap();
      const second = new FakePixelMap();
      maps.set('1', asPixelMap(first));
      maps.set('2', asPixelMap(second));

      impl.pixelMapRelease();

      expect(first.releaseCount).assertEqual(1);
      expect(second.releaseCount).assertEqual(1);
      expect(maps.length).assertEqual(0);
    })

    it('videoPlayerApiImpl_pixelMapReleaseById_releasesOnlyTheGivenId', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const target = new FakePixelMap();
      const other = new FakePixelMap();
      maps.set('1', asPixelMap(target));
      maps.set('2', asPixelMap(other));

      impl.pixelMapReleaseById(1);

      expect(target.releaseCount).assertEqual(1);
      expect(other.releaseCount).assertEqual(0);
      expect(maps.hasKey('1')).assertFalse();
      expect(maps.hasKey('2')).assertTrue();
    })

    it('videoPlayerApiImpl_releaseSupersededPixelMap_releasesSupersededAndKeepsCurrent', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const background = new FakePixelMap();
      const firstFrame = new FakePixelMap();
      maps.set('1', asPixelMap(background));

      // Mirror create(): the map is switched to the first video frame before
      // the superseded background frame is released.
      const superseded = maps.get('1');
      maps.set('1', asPixelMap(firstFrame));
      impl.releaseSupersededPixelMap(superseded);
      impl.releaseSupersededPixelMap(undefined);

      expect(background.releaseCount).assertEqual(1);
      expect(firstFrame.releaseCount).assertEqual(0);
      expect(maps.hasKey('1')).assertTrue();
    })

    it('videoPlayerApiImpl_initialize_releasesTrackedPixelMaps', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const tracked = new FakePixelMap();
      maps.set('1', asPixelMap(tracked));

      impl.initialize();

      expect(tracked.releaseCount).assertEqual(1);
      expect(maps.length).assertEqual(0);
    })

    it('videoPlayerApiImpl_detach_releasesTrackedPixelMaps', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const tracked = new FakePixelMap();
      maps.set('1', asPixelMap(tracked));

      impl.detach();

      expect(tracked.releaseCount).assertEqual(1);
      expect(maps.length).assertEqual(0);
    })

    it('videoPlayerApiImpl_dispose_releasesPixelMapOfTheGivenTexture', 0, () => {
      const impl = new VideoPlayerApiImpl(null, null);
      const maps = pixelMapsOf(impl);
      const disposed = new FakePixelMap();
      const kept = new FakePixelMap();
      maps.set('1', asPixelMap(disposed));
      maps.set('2', asPixelMap(kept));
      const textureMessage = new TextureMessage();
      textureMessage.setTextureId(1);

      impl.dispose(textureMessage);

      expect(disposed.releaseCount).assertEqual(1);
      expect(kept.releaseCount).assertEqual(0);
      expect(maps.hasKey('1')).assertFalse();
      expect(maps.hasKey('2')).assertTrue();
    })
  })
}
