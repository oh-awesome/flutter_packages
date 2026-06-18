/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
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

import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { ExampleHostApi, MessageData } from './Messages';
import {
  IntEvent,
  StringEvent,
  PigeonCodec,
  PlatformEvent,
  PigeonEventSink,
  StreamEventsStreamHandler,
} from './EventChannelMessages';
import { DemoHostApi } from './PigeonTest';
import { DemoHostApiImpl } from './DemoHostApiImpl';
import { DemoProxyApiRegistrarImpl } from './DemoProxyApiImpl';
import { EventChannel } from '@ohos/flutter_ohos';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';

const EVENT_CHANNEL_NAME: string =
  'dev.flutter.pigeon.pigeon_example_package.EventChannelMethods.streamEvents';

/**
 * Event stream + host API logic. Extends the Pigeon-generated
 * [StreamEventsStreamHandler] so [StreamEventsStreamHandler.register] can wire
 * the channel.
 */
class HostApiImp extends StreamEventsStreamHandler {
  private eventSender: EventSender = new EventSender();
  private reconnectTimer: number | null = null;

  override onListen(args: Object, sink: PigeonEventSink<PlatformEvent>): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.eventSender.start(sink);
  }

  override onCancel(args: Object): void {
    this.stopEventStream();
  }

  /** Stops any pending or active event delivery (safe from engine detach). */
  stopEventStream(): void {
    this.eventSender.stopSendingEvents();
  }

  getHostLanguage(): string {
    return 'ArkTS';
  }

  add(a: number, b: number): number {
    return a + b;
  }

  sendMessage(message: MessageData): boolean {
    return true;
  }
}

/** ArkTS single inheritance: bridge [HostApiImp] to [ExampleHostApi.setup]. */
class ExampleHostApiAdapter extends ExampleHostApi {
  private readonly impl: HostApiImp;

  constructor(impl: HostApiImp) {
    super();
    this.impl = impl;
  }

  getHostLanguage(): string {
    return this.impl.getHostLanguage();
  }

  add(a: number, b: number): number {
    return this.impl.add(a, b);
  }

  sendMessage(message: MessageData): boolean {
    return this.impl.sendMessage(message);
  }
}

class EventSender {
  private count: number = 0;
  private timer: number | null = null;
  private startTimer: number | null = null;
  private eventSink: PigeonEventSink<PlatformEvent> | null = null;
  private isActive: boolean = false;

  start(eventSink: PigeonEventSink<PlatformEvent>): void {
    this.forceStop();
    this.eventSink = eventSink;
    this.isActive = true;
    this.count = 0;

    this.startTimer = setTimeout(() => {
      this.startTimer = null;
      if (!this.isActive || !this.eventSink) {
        return;
      }

      this.timer = setInterval(() => {
        if (!this.isActive || !this.eventSink) {
          this.forceStop();
          return;
        }

        try {
          if (this.count >= 100) {
            this.forceStop();
            return;
          }

          if (this.count % 2 === 0) {
            const intEvent = new IntEvent();
            intEvent.setData(this.count);
            this.eventSink.success(intEvent as PlatformEvent);
          } else {
            const stringEvent = new StringEvent();
            stringEvent.setData(`${this.count}`);
            this.eventSink.success(stringEvent as PlatformEvent);
          }
          this.count++;
        } catch (error) {
          this.forceStop();
        }
      }, 1000);
    }, 2000);
  }

  stopSendingEvents(): void {
    this.forceStop();
  }

  private forceStop(): void {
    if (this.startTimer !== null) {
      clearTimeout(this.startTimer);
      this.startTimer = null;
    }

    this.isActive = false;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    if (this.eventSink !== null) {
      this.eventSink.endOfStream();
      this.eventSink = null;
    }
  }

  isRunning(): boolean {
    return this.isActive;
  }
}

export default class MessagePlugin implements FlutterPlugin {
  private readonly hostApiImp: HostApiImp = new HostApiImp();
  private readonly hostApiAdapter: ExampleHostApiAdapter =
    new ExampleHostApiAdapter(this.hostApiImp);
  private proxyRegistrar: DemoProxyApiRegistrarImpl | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'MessagePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    ExampleHostApi.setup(binding.getBinaryMessenger(), this.hostApiAdapter);
    StreamEventsStreamHandler.register(binding.getBinaryMessenger(), this.hostApiImp);

    this.proxyRegistrar = new DemoProxyApiRegistrarImpl(binding.getBinaryMessenger());
    this.proxyRegistrar.setUp();
    DemoHostApi.setup(
      binding.getBinaryMessenger(),
      new DemoHostApiImpl(binding.getBinaryMessenger(), this.proxyRegistrar),
    );
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.hostApiImp.stopEventStream();
    ExampleHostApi.setup(binding.getBinaryMessenger(), null);
    DemoHostApi.setup(binding.getBinaryMessenger(), null);
    if (this.proxyRegistrar !== null) {
      this.proxyRegistrar.tearDown();
      this.proxyRegistrar = null;
    }
    const channel: EventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      EVENT_CHANNEL_NAME,
      new StandardMethodCodec(PigeonCodec.INSTANCE),
    );
    channel.setStreamHandler(null);
  }
}
