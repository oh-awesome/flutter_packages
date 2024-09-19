/*
* Copyright 2013 The Flutter Authors. All rights reserved.
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
*/
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger, TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
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

  constructor(code: string, name: string, message: string, stack?: string) {
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
  ONE,
  TWO
}

export class CodeEnum {
  index: number | null = null;
  constructor(index: number) {
    this.index = index;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class MessageData {
  private name?: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string | undefined {
    return this.name;
  }

  private description?: string;

  public setDescription(description: string): void {
    this.description = description;
  }

  getDescription(): string | undefined {
    return this.description;
  }

  private code?: CodeEnum;

  public setCode(code: CodeEnum): void {
    this.code = code;
  }

  getCode(): CodeEnum | undefined {
    return this.code;
  }

  private data?: Map<string, string>;

  public setData(data: Map<string, string>): void {
    this.data = data;
  }

  getData(): Map<string, string> | undefined {
    return this.data;
  }

  constructor(name?: string, description?: string, code?: CodeEnum, data?: Map<string, string>) {
    this.name = name;
    this.description = description;
    this.code = code;
    this.data = data;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    if (this.name !== undefined) {
      arr.push(this.name);
    }
    if (this.description !== undefined) {
      arr.push(this.description);
    }
    if (this.code !== undefined) {
      arr.push(this.code);
    }
    if (this.data !== undefined) {
      arr.push(this.data);
    }
    return arr;
  }

  static fromList(arr: Object[]): MessageData {
    let pigeonResult: MessageData = new MessageData();
    let name: Object = arr[0];
    pigeonResult.setName(name as string);
    let description: Object = arr[1];
    pigeonResult.setDescription(description as string);
    pigeonResult.setCode(new CodeEnum(arr[2]! as number));
    let data: Object = arr[3];
    pigeonResult.setData(data as Map<string, string>);
    return pigeonResult;
  }
}

class PigeonCodec extends StandardMessageCodec {
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
      case this.getByte(129): {
        let value: Object = super.readValue(buffer);
        return value == null ? null : Code[value as number];
      }
      case this.getByte(130):
        return MessageData.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof MessageData) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, (value as MessageData).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}


export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class ExampleHostApi {
  abstract getHostLanguage(): string;

  abstract add(a: number, b: number): number;

  abstract sendMessage(message: MessageData, result: Result<boolean>): void;

  abstract sendNull(data: Object): Object;

  abstract sendTrue(data: boolean): boolean;

  abstract sendFalse(data: boolean): boolean;

  abstract sendInt(data: number): number;

  abstract sendDouble(data: number): number;

  abstract sendString(data: string): string;

  abstract sendUint8List(data: number[]): number[];

  abstract sendInt32List(data: number[]): number[];

  abstract sendInt64List(data: number[]): number[];

  abstract sendFloat64List(data: number[]): number[];

  abstract sendList(data: Array<string>): Array<string>;

  abstract sendMap(data: Map<string, string>): Map<string, string>;

  abstract sendEnum(data: CodeEnum): CodeEnum;

  abstract flutterInvokeSync(): string;

  abstract flutterInvokeAsync(result: Result<string>): void;

  abstract errorHandling(result: Result<string>): void;

  abstract taskQueueTest(): string;

  /** The codec used by ExampleHostApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  /*Sets up an instance of `ExampleHostApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: ExampleHostApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.getHostLanguage",
          ExampleHostApi.getCodec());
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
          }
        });
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
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_package.ExampleHostApi.sendMessage",
          ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;

            class ResultImp implements Result<boolean> {
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
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }


    //-----------------------------------------------test---------------------------------------------------------------
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendNull", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              console.log("testFlutter-sendNull " + " ets onMessage try");
              let output: Object = api!.sendNull(args[0] as Object);
              res.push(output);
            } catch (error) {
              console.log("testFlutter-sendNull " + " ets onMessage err:" + error.name + " " + error.message);
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            console.log("testFlutter-sendNull " + " ets reply");
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendTrue", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: boolean = api!.sendTrue(args[0] as boolean);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendFalse", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: boolean = api!.sendTrue(args[0] as boolean);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendInt", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number = api!.sendInt(args[0] as number);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendDouble", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number = api!.sendDouble(args[0] as number);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendString", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: string = api!.sendString(args[0] as string);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendUint8List", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number[] = api!.sendUint8List(args[0] as number[]);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendInt32List", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number[] = api!.sendInt32List(args[0] as number[]);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendInt64List", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number[] = api!.sendInt64List(args[0] as number[]);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendFloat64List", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: number[] = api!.sendFloat64List(args[0] as number[]);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendList", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: Array<string> = api!.sendList(args[0] as Array<string>);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendMap", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: Map<string, string> = api!.sendMap(args[0] as Map<string, string>);
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }

    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.sendEnum", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: CodeEnum = api!.sendEnum(new CodeEnum(args[0] as number));
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.flutterInvokeSync", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let res: Array<Object> = [];
            try {
              let output: string = api!.flutterInvokeSync();
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.flutterInvokeAsync", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            class ResultImp implements Result<string> {
              success(result: string): void {
                let res: Array<Object> = [];
                res.push(result);
                reply.reply(res);
              }

              error(error: Error): void {
                let wrappedError: Array<Object> = wrapError(error);
                reply.reply(wrappedError);
              }
            }

            let resultCallback: Result<string> = new ResultImp();

            api!.flutterInvokeAsync(resultCallback);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.errorHandling", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            class ResultImp implements Result<string> {
              success(result: string): void {
                let res: Array<Object> = [];
                res.push(result);
                reply.reply(res);
              }

              error(error: Error): void {
                let wrappedError: Array<Object> = wrapError(error);
                reply.reply(wrappedError);
              }
            }

            let resultCallback: Result<string> = new ResultImp();

            api!.errorHandling(resultCallback);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      ///let taskQueue: TaskQueue = binaryMessenger.makeBackgroundTaskQueue();
      ///BasicMessageChannel构造中不需要taskQueue了
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_demo.MyHostApi.taskQueueTest", ExampleHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let res: Array<Object> = [];
            try {
              let output: string = api!.taskQueueTest();
              res.push(output);
            } catch (error) {
              let wrappedError: Array<Object> = wrapError(error);
              res = wrappedError;
            }
            reply.reply(res);
          }
        });
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
          let listReply: Object[] = channelReply as Object[];
          if (listReply.length > 1) {
            let arrFirst: string = listReply[0] as string;
            let arrSecond: string = listReply[1] as string;
            let arrThird: string = listReply[2] as string;
            let replyArr: string =
              'FlutterError:{"code":' + arrFirst + ',"name":' + arrSecond + ',"message":' + arrThird + '}';
            callback.reply(replyArr);
          } else if (listReply[0] == null) {
            let replyNull: string =
              'FlutterError:{"code":null-error,"name":Flutter api returned null value for non-null return value.,"message":}'
            callback.reply(replyNull);
          } else {
            let output: string = listReply[0] as string;
            callback.reply(output);
          }
        } else {
          let connErr: string =
            'FlutterError:{"code":channel-error,"name":Unable to establish connection on channel:channelName,"message":.}'
          callback.reply(connErr);
        }
      });
  }
}
