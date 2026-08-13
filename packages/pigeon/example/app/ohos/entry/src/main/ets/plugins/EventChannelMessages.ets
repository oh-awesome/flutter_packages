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
 
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import EventChannel, { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error name. */
  public name: string;

  /** The error message. */
  public message: string;
  /** The error stack. */
  public stack?: string;

  constructor(code: string, name: string, message: string, stack?: string) {
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

/*
*  Generated class from Pigeon that represents data sent in messages.
*  This class should not be extended by any user class outside of the generated file.
*/
export abstract class PlatformEvent {
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class IntEvent extends PlatformEvent {
  private data: number;

  public setData(data: number): void {
    this.data = data;
  }

  getData(): number {
    return this.data;
  }

  constructor(data: number) {
    super();
    this.data = data;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.data === undefined || this.data === null) {
      arr.push(null);
    } else {
      arr.push(this.data);
    }
    return arr;
  }

  static fromList(arr: Object[]): IntEvent {
    let dataObject: Object = arr[0];
    const data: number = dataObject as number;
    return new IntEvent(data);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class StringEvent extends PlatformEvent {
  private data: string;

  public setData(data: string): void {
    this.data = data;
  }

  getData(): string {
    return this.data;
  }

  constructor(data: string) {
    super();
    this.data = data;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.data === undefined || this.data === null) {
      arr.push(null);
    } else {
      arr.push(this.data);
    }
    return arr;
  }

  static fromList(arr: Object[]): StringEvent {
    let dataObject: Object = arr[0];
    const data: string = dataObject as string;
    return new StringEvent(data);
  }
}

export class PigeonCodec extends StandardMessageCodec {
  static readonly INSTANCE: PigeonCodec = new PigeonCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }
  private constructor() {
    super();
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(129):
        return IntEvent.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(130):
        return StringEvent.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof IntEvent) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, (value as IntEvent).toList());
    } else if (value instanceof StringEvent) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, (value as StringEvent).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

const EventChannelMessagesPigeonMethodChannelCodec: StandardMethodCodec = new StandardMethodCodec(PigeonCodec.INSTANCE);


class EventChannelMessagesPigeonStreamHandler<T> implements StreamHandler {
  private readonly wrapper: EventChannelMessagesPigeonEventChannelWrapper<T>;
  private pigeonSink: PigeonEventSink<T> | null = null;

  constructor(wrapper: EventChannelMessagesPigeonEventChannelWrapper<T>) {
    this.wrapper = wrapper;
  }

  onListen(args: Object | undefined, events: EventSink): void {
    this.pigeonSink = new PigeonEventSink<T>(events);
    this.wrapper.onListen(args, this.pigeonSink!);
  }

  onCancel(args: Object | undefined): void {
    this.pigeonSink = null;
    this.wrapper.onCancel(args);
  }
}

export abstract class EventChannelMessagesPigeonEventChannelWrapper<T> {
  abstract onListen(args: Object | undefined, sink: PigeonEventSink<T>): void;
  onCancel(args: Object | undefined): void {
  }
}

export class PigeonEventSink<T> {
  private readonly sink: EventSink;

  constructor(sink: EventSink) {
    this.sink = sink;
  }

  success(value: T): void {
    this.sink.success(value);
  }

  error(errorCode: string, errorMessage: string | null, errorDetails: ESObject | null): void {
    this.sink.error(errorCode, errorMessage, errorDetails);
  }

  endOfStream(): void {
    this.sink.endOfStream();
  }
}

export abstract class StreamEventsStreamHandler extends EventChannelMessagesPigeonEventChannelWrapper<PlatformEvent> {
  static register(messenger: BinaryMessenger, streamHandler: StreamEventsStreamHandler, instanceName: string = ""): void {
    let channelName: string = "dev.flutter.pigeon.pigeon_example_package.EventChannelMethods.streamEvents";
    if (instanceName !== "") {
      channelName += "." + instanceName;
    }
    const internalStreamHandler = new EventChannelMessagesPigeonStreamHandler<PlatformEvent>(streamHandler);
    const channel = new EventChannel(messenger, channelName, EventChannelMessagesPigeonMethodChannelCodec);
    channel.setStreamHandler(internalStreamHandler);
  }

  abstract onListen(args: Object | undefined, sink: PigeonEventSink<PlatformEvent>): void;

  onCancel(args: Object | undefined): void {
  }
}

