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
import { BinaryMessenger,TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


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

  constructor(code: string, name: string, message: string, stack: string) 
{
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

function wrapError(error: Error): Array<Object> {
  let errorList: Array<Object> = new Array<Object>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.name;
    errorList[2] = err.message;
  } else {
    errorList[0] = error.toString();
    errorList[1] = error.name;
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}

export enum Code {
  ONE = 0,
  TWO = 1
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class MessageData {
  private name?: string;

  getName(): string | undefined {
    return this.name;
  }

  private description?: string;

  getDescription(): string | undefined {
    return this.description;
  }

  private code: Code;

  getCode(): Code {
    return this.code;
  }

  private data: Map<string, string>;

  getData(): Map<string, string> {
    return this.data;
  }

  constructor(code: Code, data: Map<string, string>, name?: string, description?: string) {
    this.name = name;
    this.description = description;
    this.code = code;
    this.data = data;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.description === undefined || this.description === null) {
      arr.push(null);
    } else {
      arr.push(this.description);
    }
    if (this.code === undefined || this.code === null) {
      arr.push(null);
    } else {
      arr.push(this.code as number);
    }
    if (this.data === undefined || this.data === null) {
      arr.push(null);
    } else {
      arr.push(this.data);
    }
    return arr;
  }

  static fromList(arr: Object[]): MessageData {
    let name: string | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      let nameObject: Object = arr[0];
      name = nameObject as string;
    }
    let description: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      let descriptionObject: Object = arr[1];
      description = descriptionObject as string;
    }
    const code: Code = arr[2] as number as Code;
    let dataObject: Object = arr[3];
    const data: Map<string, string> = dataObject as Map<string, string>;
    return new MessageData(code, data, name, description);
  }
}

export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}

class ExampleHostApiCodec extends StandardMessageCodec {
  static INSTANCE: ExampleHostApiCodec = new ExampleHostApiCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(128):
        return MessageData.fromList(super.readValue(buffer));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof MessageData) {
      stream.writeUint8(this.getByte(128));
      this.writeValue(stream, (value as MessageData).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class ExampleHostApi {

  abstract getHostLanguage(): string;

  abstract add(a: number, b: number): number;

  abstract sendMessage(message: MessageData, result: Result<boolean>): void;
  /** The codec used by ExampleHostApi. */
  static getCodec(): MessageCodec<Object>{
    return ExampleHostApiCodec.INSTANCE;
  }
  /*Sets up an instance of `ExampleHostApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: ExampleHostApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.getHostLanguage' + separatedMessageChannelSuffix, ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let res: Array<Object> = [];
              try {
                let output: string = api!.getHostLanguage();
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.add' + separatedMessageChannelSuffix, ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.add(args[0] as number, args[1] as number);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.sendMessage' + separatedMessageChannelSuffix, ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<boolean> = new ResultImp();

              api!.sendMessage(args[0] as MessageData, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/* Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.*/
export class MessageFlutterApi {
  binaryMessenger: BinaryMessenger;
  private messageChannelSuffix: string;

  constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = '') {
    this.binaryMessenger = binaryMessenger;
    this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
  }

  /** The codec used by MessageFlutterApi. */
  static getCodec(): MessageCodec<Object> {
    return new StandardMessageCodec();
  }

  flutterMethod(aStringArg: string | undefined, callback: Reply<string>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.MessageFlutterApi.flutterMethod" + this.messageChannelSuffix, MessageFlutterApi.getCodec());
    channel.send(
        [aStringArg],
        channelReply => {
          let output: string = channelReply as string;
          callback.reply(output);
        });
  }
}
