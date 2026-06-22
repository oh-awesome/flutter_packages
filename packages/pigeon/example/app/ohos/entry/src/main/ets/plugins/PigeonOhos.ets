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


/* Generated enum from Pigeon that represents data sent in messages.*/
export enum Identity {
  STUDENT,
  TEACHER
}

/* Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed*/
export class IdentityEnum {
  index: string | null = null;

  constructor(index: string) {
    this.index = index;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Person {
  private name?: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string | undefined {
    return this.name;
  }

  private age?: number;

  public setAge(age: number): void {
    this.age = age;
  }

  getAge(): number | undefined {
    return this.age;
  }

  private identity?: Identity;

  public setIdentity(identity: Identity): void {
    this.identity = identity;
  }

  getIdentity(): Identity | undefined {
    return this.identity;
  }

  constructor(name?: string, age?: number, identity?: Identity) {
    this.name = name;
    this.age = age;
    this.identity = identity;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    if (this.name !== undefined) {
      arr.push(this.name);
    }
    if (this.age !== undefined) {
      arr.push(this.age);
    }
    if (this.identity !== undefined) {
      const identityStr = Identity[this.identity as number];
      arr.push(new IdentityEnum(identityStr));
    }
    return arr;
  }

  static fromList(arr: Object[]): Person {
    let pigeonResult: Person = new Person();
    let name: Object = arr[0];
    pigeonResult.setName(name as string);
    let age: Object = arr[1];
    pigeonResult.setAge(age as number);
    const identityStr: string = arr[2]! as string;
    pigeonResult.setIdentity(Identity[identityStr]);
    return pigeonResult;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Student {
  private name?: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string | undefined {
    return this.name;
  }

  private age?: number;

  public setAge(age: number): void {
    this.age = age;
  }

  getAge(): number | undefined {
    return this.age;
  }

  constructor(name?: string, age?: number) {
    this.name = name;
    this.age = age;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    if (this.name !== undefined) {
      arr.push(this.name);
    }
    if (this.age !== undefined) {
      arr.push(this.age);
    }
    return arr;
  }

  static fromList(arr: Object[]): Student {
    let pigeonResult: Student = new Student();
    let name: Object = arr[0];
    pigeonResult.setName(name as string);
    let age: Object = arr[1];
    pigeonResult.setAge(age as number);
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
        return value == null ? null : Identity[value as number];
      }
      case this.getByte(130):
        return Person.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(131):
        return Student.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof IdentityEnum) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, value == null ? null : Identity[value.index as string]);
    } else if (value instanceof Person) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, (value as Person).toList());
    } else if (value instanceof Student) {
      stream.writeUint8(this.getByte(131));
      this.writeValue(stream, (value as Student).toList());
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
export abstract class DemoHostApi {
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

  abstract sendCustomClass(data: Student): Student;

  abstract sendNestedDatatype(data: Person): Person;

  abstract sendEnum(data: Identity): Identity;

  abstract flutterInvokeSync(): string;

  abstract flutterInvokeAsync(result: Result<string>): void;

  abstract errorHandling(result: Result<string>): void;

  abstract taskQueueTest(): string;

  /** The codec used by DemoHostApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  /*Sets up an instance of `DemoHostApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: DemoHostApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNull", DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: Object = api!.sendNull(args[0] as Object);
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendTrue", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFalse", DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: boolean = api!.sendFalse(args[0] as boolean);
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendDouble", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendString", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendUint8List", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt32List", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt64List", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFloat64List", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendList", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendMap", DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendCustomClass", DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: Student = api!.sendCustomClass(args[0] as Student);
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNestedDatatype",
          DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: Person = api!.sendNestedDatatype(args[0] as Person);
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendEnum", DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>) {
            let args: Array<Object> = message as Array<Object>;
            let res: Array<Object> = [];
            try {
              let output: IdentityEnum = new IdentityEnum(api!.sendEnum(args[0] as Identity).toString());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeSync",
          DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeAsync",
          DemoHostApi.getCodec());
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
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.errorHandling", DemoHostApi.getCodec());
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
      let channel: BasicMessageChannel<Object> =
        new BasicMessageChannel(
          binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoHostApi.taskQueueTest", DemoHostApi.getCodec());
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
export class DemoFlutterApi {
  binaryMessenger: BinaryMessenger;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The codec used by DemoFlutterApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  platformInvokeSync(callback: Reply<string>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeSync';
    let channel: BasicMessageChannel<Object> =
      new BasicMessageChannel<Object>(
        this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
      null,
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

  platformInvokeAsync(callback: Reply<string>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeAsync';
    let channel: BasicMessageChannel<Object> =
      new BasicMessageChannel<Object>(
        this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
      null,
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
