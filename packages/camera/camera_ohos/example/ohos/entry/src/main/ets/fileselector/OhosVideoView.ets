/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { scanBarcode, customScan } from '@kit.ScanKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { MethodResult } from '@ohos/flutter_ohos';
import { BusinessError } from '@kit.BasicServicesKit';
import QrCaptureView from './VideoView';
import { fileUri } from '@kit.CoreFileKit';
import { fileIo as fs, Filter, ListFileOptions } from '@kit.CoreFileKit';

const TAG: string = '[OhosView]: '

@Component
export struct OhosVideoView {
  @State cacheDir: string = getContext(this).cacheDir
  @Prop params: Params;
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isAutoPlay: boolean = true
  @State showControls: boolean = false
  @State path: string = ''
  @State uri: string = ''
  @State isVideo: boolean = false
  @State videoBorderWidth: number = 0
  controller: VideoController = new VideoController()

  async aboutToAppear() {
    let listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {
        suffix: [".jpg", ".mp4"],
      }
    }
    let listFile: Array<string> = await fs.listFile(this.cacheDir, listFileOption)
    this.path = listFile[listFile.length-1]
    if (this.isMp4File(this.path)) {
      this.isVideo = true
      this.videoBorderWidth = 1
    }
    this.uri = fileUri.getUriFromPath(this.cacheDir + "/" + this.path)
  }

  aboutToDisappear() {
  }

  isMp4File(filename: string): boolean {
    // 确保文件名不为空并且以 .mp4 结尾（忽略大小写）
    return filename.trim().toLowerCase().endsWith('.mp4');
  }

  build() {
    Stack() {
      Column() {
        if (this.isVideo) {
          Video({
            src: this.uri,
            currentProgressRate: this.curRate,
            controller: this.controller
          })
            .height(64)
            .width(35)
            .autoPlay(this.isAutoPlay)
            .controls(this.showControls)
            .loop(true)
        } else {
          Image(this.uri).height(64).width(35)
        }
      }
      .border({ color: Color.Red, width: this.videoBorderWidth })
      .height(64)
      .width(64)
      .position({ x: 0, y: 0 })
    }
    .width('100%')
    .height('100%')
  }
}

@Builder
export function buildOhosView(params: Params) {
  OhosVideoView({
    params: params
  })
}