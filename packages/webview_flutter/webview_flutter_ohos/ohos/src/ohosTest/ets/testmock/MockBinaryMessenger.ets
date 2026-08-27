/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
 
// 测试辅助：BinaryMessenger 的可观测 Mock 实现。
// 记录所有 send / setMessageHandler 调用，并对 send 立即回以 null 应答，
// 使 Pigeon 生成的 FlutterApi 回调可以被同步验证。

import {
  BinaryMessenger,
  BinaryReply,
  BinaryMessageHandler,
  TaskQueue,
  TaskQueueOptions
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import SendableBinaryMessageHandler from '@ohos/flutter_ohos/src/main/ets/plugin/common/SendableBinaryMessageHandler';

class MockTaskQueue implements TaskQueue {
}

export class MockBinaryMessenger implements BinaryMessenger {
  /** 每次 send() 的通道名（按调用顺序）。 */
  public sendChannelNames: Array<string> = [];
  /** send() 调用总次数。 */
  public sendCount: number = 0;
  /** 最近一次 send() 的通道名。 */
  public lastChannel: string = '';
  /** 最近一次 send() 的消息载荷。 */
  public lastMessage: ArrayBuffer | null = null;
  /** setMessageHandler() 注册过的通道名（按调用顺序）。 */
  public handlerChannelNames: Array<string> = [];
  /** 通过自动应答触发 reply 回调的次数。 */
  public autoReplyCount: number = 0;
  /** 通道名 -> 注册的处理器（供测试直接以原始参数数组驱动 Pigeon handler）。 */
  public handlers: Map<string, ESObject> = new Map<string, ESObject>();

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    return new MockTaskQueue();
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
    const channelName: string = `${channel}`;
    this.sendChannelNames.push(channelName);
    this.sendCount++;
    this.lastChannel = channelName;
    this.lastMessage = message;
    if (callback) {
      // 立即以 null 应答，模拟 Dart 侧返回，驱动上层 Reply 回调同步执行。
      this.autoReplyCount++;
      callback.reply(null);
    }
  }

  setMessageHandler(
    channel: String,
    handler: BinaryMessageHandler | SendableBinaryMessageHandler | null,
    taskQueue?: TaskQueue,
    ...args: Object[]
  ): void {
    this.handlerChannelNames.push(`${channel}`);
    const channelName: string = `${channel}`;
    if (handler != null) {
      this.handlers.set(channelName, handler as ESObject);
    } else {
      this.handlers.delete(channelName);
    }
  }

  /** 便捷断言辅助：是否曾向指定通道发送过消息。 */
  hasSentTo(channel: string): boolean {
    return this.sendChannelNames.indexOf(channel) !== -1;
  }

  /** 取出指定通道的处理器（未注册返回 null）。 */
  getHandler(channel: string): ESObject | null {
    return this.handlers.has(channel) ? this.handlers.get(channel) : null;
  }

  /** 便捷断言辅助：是否曾注册过指定通道的处理器。 */
  hasHandlerFor(channel: string): boolean {
    return this.handlerChannelNames.indexOf(channel) !== -1;
  }

  /**
   * 以 Pigeon 规约驱动指定通道的处理器：参数数组先经编解码器编码
   * （IncomingMessageHandler 会先 decode），应答缓冲再解码还原为数组返回。
   * 通道未注册时返回 null。
   */
  driveHandler(codec: MessageCodec<ESObject>, channel: string, args: Array<Object>): Array<Object> | null {
    const handler: ESObject | undefined = this.handlers.get(channel);
    if (handler === undefined) {
      return null;
    }
    const encoded: ArrayBuffer = codec.encodeMessage(args as ESObject);
    let replyBuffer: ArrayBuffer | null = null;
    handler.onMessage(encoded, {
      reply: (buffer: ArrayBuffer | null): void => {
        replyBuffer = buffer;
      }
    });
    if (replyBuffer === null) {
      return null;
    }
    return codec.decodeMessage(replyBuffer) as ESObject as Array<Object>;
  }

  reset(): void {
    this.sendChannelNames = [];
    this.sendCount = 0;
    this.lastChannel = '';
    this.lastMessage = null;
    this.handlerChannelNames = [];
    this.autoReplyCount = 0;
  }
}
