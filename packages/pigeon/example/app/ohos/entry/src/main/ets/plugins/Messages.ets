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

import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error message. */
  public message: string;

  /** The error details. Must be a datatype supported by the api codec. */
  public details: Object | null;

  /** Error name for the Error interface. */
  public name: string = 'FlutterError';
  /** The error stack. */
  public stack?: string;

  constructor(code: string, message: string, details: Object | null, stack?: string) {
    this.code = code;
    this.message = message;
    this.details = details;
    this.stack = stack;
  }
}

function wrapError(error: Error): Array<Object | null> {
  let errorList: Array<Object | null> = new Array<Object | null>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.message;
    errorList[2] = err.details;
  } else {
    errorList[0] = error.name;
    errorList[1] = error.toString();
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}

function createConnectionError(channelName: string): FlutterError {
  return new FlutterError('channel-error', 'Unable to establish connection on channel: \'' + channelName + '\'.', '');
}

function createNullReplyError(): FlutterError {
  return new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
}

/* Generated enum from Pigeon that represents data sent in messages.*/
export enum Code {
  ONE,
  TWO
}

/* Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed*/
export class CodeEnum {
  index: string|null = null;
	constructor(index: string){
    this.index = index;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class MessageData {
  private name?: string;

  public setName(name:string):void {
    this.name = name;
  }

  getName(): string | undefined{
    return this.name;
  }

  private description?: string;

  public setDescription(description:string):void {
    this.description = description;
  }

  getDescription(): string | undefined{
    return this.description;
  }

  private code: Code;

  public setCode(code:Code):void {
    this.code = code;
  }

  getCode(): Code{
    return this.code;
  }

  private data: Map<string, string>;

  public setData(data:Map<string, string>):void {
    this.data = data;
  }

  getData(): Map<string, string>{
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
      const codeStr = Code[this.code as number];
      arr.push(new CodeEnum(codeStr));
    }
    if (this.data === undefined || this.data === null) {
      arr.push(null);
    } else {
      arr.push(this.data);
    }
    return arr;
  }

  static fromList(arr: Object[]): MessageData {
    if (arr == null || arr.length < 4) {
      throw new Error('Invalid MessageData: expected at least 4 elements.');
    }
    let name: string | undefined = undefined;
    if (arr[0] !== null && arr[0] !== undefined) {
      if (typeof arr[0] !== 'string') {
        throw new Error('Invalid MessageData: name must be a string.');
      }
      name = arr[0] as string;
    }
    let description: string | undefined = undefined;
    if (arr[1] !== null && arr[1] !== undefined) {
      if (typeof arr[1] !== 'string') {
        throw new Error('Invalid MessageData: description must be a string.');
      }
      description = arr[1] as string;
    }
    if (typeof arr[2] !== 'string') {
      throw new Error('Invalid MessageData: code must be a string.');
    }
    const codeStr: string = arr[2] as string;
    const code: Code = Code[codeStr];
    if (code === undefined) {
      throw new Error('Invalid MessageData: unknown code value.');
    }
    if (arr[3] === null || arr[3] === undefined) {
      throw new Error('Invalid MessageData: data must not be null.');
    }
    const data: Map<string, string> = arr[3] as Map<string, string>;
    return new MessageData(code, data, name, description);
  }
}

export class PigeonCodec extends StandardMessageCodec {
  static readonly INSTANCE: PigeonCodec  = new PigeonCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }
  private constructor() {
    super();
  }

  readValueOfType(type: number,  buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(129): {
        let value: Object= super.readValue(buffer);
        return value == null ? null : Code[value as number];
      }
      case this.getByte(130):
        return MessageData.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer , value: ESObject): ESObject{
    if (value instanceof CodeEnum) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, value == null ? null : Code[value.index as string]);
    } else if (value instanceof MessageData) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, (value as MessageData).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}


export interface Result<T> {
  success( result: T ): void;

  error( error: Error): void;
}
/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class ExampleHostApi {

  abstract getHostLanguage(): string;

  abstract add(a: number , b: number ): number;

  abstract sendMessage(message: MessageData , result: Result<boolean>): void;
  /** The codec used by ExampleHostApi. */
  static getCodec(): MessageCodec<Object>{
    return PigeonCodec.INSTANCE;
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
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.getHostLanguage();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
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
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number = api!.add(args[0] as number, args[1] as number);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
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
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              class ResultImp implements Result<boolean>{
                    success(result: boolean): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
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
    return PigeonCodec.INSTANCE;
  }

  flutterMethod(aStringArg: string | undefined, callback: Reply<string>) {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_package.MessageFlutterApi.flutterMethod' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, MessageFlutterApi.getCodec());
    channel.send(
        [aStringArg === undefined ? null : aStringArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = createNullReplyError();
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          }  else {
            let connErr: ESObject = createConnectionError(channelName);
            callback.reply(connErr);
          } 
        });
  }
}
