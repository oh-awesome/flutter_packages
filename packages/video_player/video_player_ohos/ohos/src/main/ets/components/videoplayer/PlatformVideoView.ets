// Copyright (c) 2026 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.

import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { VideoPlayer } from './VideoPlayer';

const TAG = 'PlatformVideoView';

/**
 * HCPP shell around an existing VideoPlayer.
 * dispose only drops the view. AVPlayer is released by controller.dispose().
 */
export class PlatformVideoView extends PlatformView {
  private player: VideoPlayer;
  private playerId: number;

  constructor(player: VideoPlayer, playerId: number) {
    super();
    this.player = player;
    this.playerId = playerId;
  }

  getPlayer(): VideoPlayer {
    return this.player;
  }

  getPlayerId(): number {
    return this.playerId;
  }

  attachSurface(surfaceId: string): void {
    this.player.setSurfaceId(surfaceId);
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(VideoSurfaceBuilder);
  }

  dispose(): void {
    Log.i(TAG, 'dispose platform view wrapper, playerId=' + this.playerId);
  }
}

@Builder
export function VideoSurfaceBuilder(params: Params) {
  VideoSurface({
    platformView: params.platformView as PlatformVideoView
  })
}

@Component
struct VideoSurface {
  platformView: PlatformVideoView = undefined as ESObject as PlatformVideoView;
  private xComponentController: XComponentController = new XComponentController();
  private xComponentId: string = '';

  aboutToAppear(): void {
    this.xComponentId = 'video_player_ohos_' + this.platformView.getPlayerId().toString();
  }

  build() {
    XComponent({
      id: this.xComponentId,
      type: XComponentType.SURFACE,
      controller: this.xComponentController
    })
      .hitTestBehavior(HitTestMode.None)
      .width('100%')
      .height('100%')
      .onLoad(() => {
        const surfaceId = this.xComponentController.getXComponentSurfaceId();
        Log.i(TAG, 'XComponent onLoad playerId=' + this.platformView.getPlayerId() +
          ' surfaceId=' + surfaceId);
        this.platformView.attachSurface(surfaceId);
      })
  }
}
