/*
* Copyright 2013 The Flutter Authors. All rights reserved.
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
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

  constructor(code: string, name: string,  message: string, stack?: string) 
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

  public setName(name:string | undefined):void {
    this.name = name;
  }

  getName(): string | undefined{
    return this.name;
  }

  private description?: string;

  public setDescription(description:string | undefined):void {
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
    this.code = code;
    this.data = data;
    this.name = name;
    this.description = description;
  }

  toList(): (Object | null)[] {
    let arr: (Object | null)[] = [];
    arr.push(this.name !== undefined ? this.name : null);
    arr.push(this.description !== undefined ? this.description : null);
    if (this.code !== undefined) {
      const codeStr = Code[this.code as number];
      arr.push(new CodeEnum(codeStr));
    } else {
      arr.push(null);
    }
    arr.push(this.data !== undefined ? this.data : null);
    return arr;
  }

  static fromList(arr: (Object | null)[]): MessageData {
    let name: string | undefined = arr[0] != null ? arr[0] as string : undefined;
    let description: string | undefined = arr[1] != null ? arr[1] as string : undefined;
    let codeRaw: Object | null = arr[2];
    const codeStr: string = codeRaw as string;
    let code: Code = Code[codeStr];
    let data: Map<string, string> = arr[3] as Map<string, string>;
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
        return MessageData.fromList(super.readValue(buffer) as (Object | null)[]);
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
  static setup(binaryMessenger: BinaryMessenger, api: ExampleHostApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.getHostLanguage", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: string = api!.getHostLanguage();
                res.push(output);
              }
 catch (error) {
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
              binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.add", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.add(args[0] as number, args[1] as number);
                res.push(output);
              }
 catch (error) {
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
              binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.sendMessage", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
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

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The codec used by MessageFlutterApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  flutterMethod(aStringArg: string, callback: Reply<string>) {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_package.MessageFlutterApi.flutterMethod';
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, MessageFlutterApi.getCodec());
    channel.send(
        [aStringArg],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr:ESObject = new FlutterError(arrFirst, arrSecond, arrThird)
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull:ESObject = new FlutterError("null-error", "Flutter api returned null value for non-null return value.", "")
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          }  else {
            let connErr:ESObject = new FlutterError('channel-error', "Unable to establish connection on channel: " + channelName + ".", "")
            callback.reply(connErr);
          } 
        });
  }
}
