/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

import fs from '@ohos.file.fs';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { Result, FileSelectorApiCodec, wrapError } from './GeneratedFileSelectorApi';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { AbilityPluginBinding } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';

const TAG = 'FileSelector';
export class FileSelector {

  binding: AbilityPluginBinding;
  // 保存通道引用，供 dispose() 注销 handler 时使用
  private channel: BasicMessageChannel<ESObject> | null = null;
  private closeChannel: BasicMessageChannel<ESObject> | null = null;
  // Descriptors handed to the Dart side: the player keeps reading them during playback,
  // so they must stay open until the consumer closes them via closeFileByFd(); dispose()
  // closes any still-registered ones as a fallback.
  private deliveredFds: Set<number> = new Set();

  constructor(binding: AbilityPluginBinding) {
    this.binding = binding;
  }

  async openFileByPath(path: string, result: Result<number>): Promise<void> {
    try {
      const file = await fs.open(path);
      // The descriptor is handed to the Dart-side player, which keeps reading it during
      // playback, so it must stay open until the consumer closes it via closeFileByFd()
      // (or in dispose() as a fallback); closing it here would break playback.
      this.deliveredFds.add(file.fd);
      result.success(file.fd);
    } catch (err) {
      Log.e(TAG, 'open file failed with err: ' + err);
      result.error(new Error('Failed to read file'));
    }
  }

  async closeFileByFd(fd: number, result: Result<boolean>): Promise<void> {
    let closed = false;
    try {
      // Close only fds this instance opened; closing an unknown fd could hit an
      // unrelated handle. Close first, then deregister, so a failed close stays
      // registered for the dispose() fallback.
      if (this.deliveredFds.has(fd)) {
        fs.closeSync(fd);
        this.deliveredFds.delete(fd);
        closed = true;
      } else {
        Log.w(TAG, 'closeFileByFd: fd not opened by this plugin: ' + fd);
      }
      result.success(closed);
    } catch (err) {
      Log.e(TAG, 'closeFileByFd failed with err: ' + err);
      result.error(new Error('Failed to close file'));
    }
  }

  static getCodec(): MessageCodec<ESObject> {
    return FileSelectorApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, abilityPluginBinding: AbilityPluginBinding): void {
    let api = this;
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, 'dev.flutter.FileSelectorApi.openFileByPath', FileSelector.getCodec());
      this.channel = channel;
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          Log.d(TAG, 'onMessage reply:' + reply)
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const path = args[0] as string;
          const resultCallback: Result<number> = new ResultBuilder((result: number): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          },(error: Error): void => {
            const wrappedError: Array<ESObject> = wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFileByPath(path, resultCallback);
        }
      });

      const closeChannel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, 'dev.flutter.FileSelectorApi.closeFileByFd', FileSelector.getCodec());
      this.closeChannel = closeChannel;
      closeChannel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const args: Array<ESObject> = msg as Array<ESObject>;
          const fd = args[0] as number;
          const resultCallback: Result<boolean> = new ResultBuilder((result: boolean): void => {
            const wrapped: Array<ESObject> = new Array<ESObject>();
            wrapped.push(result);
            reply.reply(wrapped);
          }, (error: Error): void => {
            const wrappedError: Array<ESObject> = wrapError(error);
            reply.reply(wrappedError);
          })
          api.closeFileByFd(fd, resultCallback);
        }
      });
    }
  }

  // 注销通道 handler，切断闭包对 FileSelector 实例的引用链（对齐 CameraPlugin detach 的防御性释
  // 放）
  dispose(): void {
    if (this.channel != null) {
      this.channel.setMessageHandler(null);
      this.channel = null;
    }
    if (this.closeChannel != null) {
      this.closeChannel.setMessageHandler(null);
      this.closeChannel = null;
    }
    // Best-effort fallback: release descriptors the consumer never closed via
    // closeFileByFd(), so they are not held until process exit.
    for (const fd of this.deliveredFds) {
      try {
        fs.closeSync(fd);
      } catch (err) {
        Log.e(TAG, 'dispose: failed to close fd ' + fd + ' err: ' + err);
      }
    }
    this.deliveredFds.clear();
  }
}

class ResultBuilder<T> {
  success: (result: T) => void
  error: (error: Error) => void

  constructor(success: (result: T) => void, error: (error: Error) => void) {
    this.success = success
    this.error = error
  }
}