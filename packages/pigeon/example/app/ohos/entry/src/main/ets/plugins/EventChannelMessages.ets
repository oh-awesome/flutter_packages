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
import { EventChannel, EventSink, StreamHandler } from '@ohos/flutter_ohos';


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

/* Generated class from Pigeon that represents data sent in messages.*/
export class PlatformEvent {
  constructor() {
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    return arr;
  }

  static fromList(arr: Object[]): PlatformEvent {
    return new PlatformEvent();
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class IntEvent {
  private data: number;

  public setData(data: number): void {
    this.data = data;
  }

  getData(): number {
    return this.data;
  }

  constructor(data: number) {
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
export class StringEvent {
  private data: string;

  public setData(data: string): void {
    this.data = data;
  }

  getData(): string {
    return this.data;
  }

  constructor(data: string) {
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

const PigeonMethodChannelCodec: StandardMethodCodec = new StandardMethodCodec(PigeonCodec.INSTANCE);


/**
 * Internal [StreamHandler] that delegates to a [PigeonEventChannelWrapper].
 */
class PigeonStreamHandler<T> implements StreamHandler {
  private readonly wrapper: PigeonEventChannelWrapper<T>;
  private pigeonSink: PigeonEventSink<T> | null = null;

  constructor(wrapper: PigeonEventChannelWrapper<T>) {
    this.wrapper = wrapper;
  }

  onListen(args: Object, events: EventSink): void {
    this.pigeonSink = new PigeonEventSink<T>(events);
    this.wrapper.onListen(args, this.pigeonSink!);
  }

  onCancel(args: Object): void {
    this.pigeonSink = null;
    this.wrapper.onCancel(args);
  }
}

export interface PigeonEventChannelWrapper<T> {
  onListen(args: Object, sink: PigeonEventSink<T>): void;
  onCancel(args: Object): void;
}

export class PigeonEventSink<T> {
  private readonly sink: EventSink;

  constructor(sink: EventSink) {
    this.sink = sink;
  }

  success(value: T): void {
    this.sink.success(value);
  }

  error(errorCode: string, errorMessage: string | null, errorDetails: Object | null): void {
    this.sink.error(errorCode, errorMessage, errorDetails);
  }

  endOfStream(): void {
    this.sink.endOfStream();
  }
}

export abstract class StreamEventsStreamHandler implements PigeonEventChannelWrapper<PlatformEvent> {
  static register(binaryMessenger: BinaryMessenger, streamHandler: StreamEventsStreamHandler, instanceName: string = ''): void {
    let channelName: string = 'dev.flutter.pigeon.pigeon_example_package.EventChannelMethods.streamEvents';
    if (instanceName !== '') {
      channelName += '.' + instanceName;
    }
    const internalStreamHandler: PigeonStreamHandler<PlatformEvent> =
        new PigeonStreamHandler<PlatformEvent>(streamHandler);
    const channel: EventChannel = new EventChannel(binaryMessenger, channelName, PigeonMethodChannelCodec);
    channel.setStreamHandler(internalStreamHandler);
  }

  onListen(args: Object, sink: PigeonEventSink<PlatformEvent>): void {
  }

  onCancel(args: Object): void {
  }
}


