/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
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
import { Code, ExampleHostApi, FlutterError, MessageData, Result } from './Messages';
import {
  IntEvent,
  StringEvent,
  PigeonCodec,
  PlatformEvent,
  PigeonEventSink,
  PigeonStreamHandler,
  StreamEventsStreamHandler,
} from './EventChannelMessages';
import { DemoHostApi } from './PigeonTest';
import { DemoHostApiImpl } from './DemoHostApiImpl';
import { DemoProxyApiRegistrarImpl } from './DemoProxyApiImpl';
import { EventChannel } from '@ohos/flutter_ohos';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';

const EVENT_CHANNEL_NAME: string =
  'dev.flutter.pigeon.pigeon_example_package.EventChannelMethods.streamEvents';

/**
 * Event stream + host API logic. Extends the Pigeon-generated
 * [StreamEventsStreamHandler] so [StreamEventsStreamHandler.register] can wire
 * the channel.
 */
class HostApiImp extends StreamEventsStreamHandler {
  private eventSender: EventSender = new EventSender();

  override onListen(args: Object, sink: PigeonEventSink<PlatformEvent>): void {
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
    if (a < 0 || b < 0) {
      throw new FlutterError('code', 'message', 'details');
    }
    return a + b;
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

  sendMessage(message: MessageData, result: Result<boolean>): void {
    if (message.getCode() === Code.ONE) {
      result.error(new FlutterError('code', 'message', 'details'));
      return;
    }
    result.success(true);
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

    this.startTimer = setTimeout(this.handleStartDelay.bind(this), 2000);
  }

  private handleStartDelay(): void {
    this.startTimer = null;
    if (!this.isActive || !this.eventSink) {
      return;
    }
    this.timer = setInterval(this.handleIntervalTick.bind(this), 1000);
  }

  private handleIntervalTick(): void {
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
  private hostApiImp: HostApiImp | null = new HostApiImp();
  private hostApiAdapter: ExampleHostApiAdapter | null =
    new ExampleHostApiAdapter(this.hostApiImp!);
  private proxyRegistrar: DemoProxyApiRegistrarImpl | null = null;
  private demoHostApiImpl: DemoHostApiImpl | null = null;
  private eventChannel: EventChannel | null = null;
  private binaryMessenger: BinaryMessenger | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'MessagePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    try {
      const messenger = binding.getBinaryMessenger();
      this.binaryMessenger = messenger;
      ExampleHostApi.setup(messenger, this.hostApiAdapter!);

      const streamHandler: PigeonStreamHandler<PlatformEvent> =
        new PigeonStreamHandler<PlatformEvent>(this.hostApiImp!);
      this.eventChannel = new EventChannel(
        messenger,
        EVENT_CHANNEL_NAME,
        new StandardMethodCodec(PigeonCodec.INSTANCE),
      );
      this.eventChannel.setStreamHandler(streamHandler);

      this.proxyRegistrar = new DemoProxyApiRegistrarImpl(messenger);
      this.proxyRegistrar.setUp();
      this.demoHostApiImpl = new DemoHostApiImpl(messenger, this.proxyRegistrar);
      DemoHostApi.setup(messenger, this.demoHostApiImpl);
    } catch (error) {
      console.error(`MessagePlugin setup failed: ${error}`);
      this.cleanupPartialSetup();
    }
  }

  private cleanupPartialSetup(): void {
    if (this.binaryMessenger !== null) {
      ExampleHostApi.setup(this.binaryMessenger, null);
      DemoHostApi.setup(this.binaryMessenger, null);
    }
    if (this.proxyRegistrar !== null) {
      this.proxyRegistrar.tearDown();
      this.proxyRegistrar = null;
    }
    if (this.eventChannel !== null) {
      this.eventChannel.setStreamHandler(null);
      this.eventChannel = null;
    }
    this.demoHostApiImpl = null;
    if (this.hostApiImp !== null) {
      this.hostApiImp.stopEventStream();
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.demoHostApiImpl !== null) {
      this.demoHostApiImpl.setAttached(false);
    }
    if (this.hostApiImp !== null) {
      this.hostApiImp.stopEventStream();
    }
    ExampleHostApi.setup(binding.getBinaryMessenger(), null);
    DemoHostApi.setup(binding.getBinaryMessenger(), null);
    this.demoHostApiImpl = null;
    if (this.proxyRegistrar !== null) {
      this.proxyRegistrar.tearDown();
      this.proxyRegistrar = null;
    }
    if (this.eventChannel !== null) {
      this.eventChannel.setStreamHandler(null);
      this.eventChannel = null;
    }
    this.hostApiAdapter = null;
    this.hostApiImp = null;
    this.binaryMessenger = null;
  }
}
