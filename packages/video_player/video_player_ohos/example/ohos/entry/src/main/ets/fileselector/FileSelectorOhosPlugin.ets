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

import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { FileSelector } from './FileSelector'

const TAG = "FileSelectorOhosPlugin"

export default class FileSelectorOhosPlugin implements FlutterPlugin, AbilityAware {

  private pluginBinding: FlutterPluginBinding | null = null;
  private fileSelectorApi: FileSelector | null = null;

  getUniqueClassName(): string {
    return "FileSelectorOhosPlugin"
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.fileSelectorApi = new FileSelector(binding);
    if (this.pluginBinding != null) {
      this.fileSelectorApi.setup(this.pluginBinding.getBinaryMessenger(), binding);
    }
  }

  onDetachedFromAbility(): void {
    // 注销消息通道，避免残留 handler 持有已失效的 binding。
    if (this.fileSelectorApi != null && this.pluginBinding != null) {
      this.fileSelectorApi.teardown(this.pluginBinding.getBinaryMessenger());
    }
    this.fileSelectorApi = null;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    console.debug(TAG, 'onAttachedToEngine file selector  ')
    this.pluginBinding = binding;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
  }
}