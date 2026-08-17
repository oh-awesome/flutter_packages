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

/**
 * Wrapper so custom codecs always serialize a Dart `double` as float64.
 * ArkTS `number` values such as `1` or `1.0` would otherwise be encoded
 * as integers by StandardMessageCodec and fail strict Dart double casts.
 */
export class PigeonInternalDoubleBox {
  value: number;
  constructor(value: number) {
    this.value = value;
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

export enum Identity {
  STUDENT = 0,
  TEACHER = 1
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Person {
  private name: string;

  getName(): string {
    return this.name;
  }

  private age: number;

  getAge(): number {
    return this.age;
  }

  private identity: Identity;

  getIdentity(): Identity {
    return this.identity;
  }

  constructor(name: string, age: number, identity: Identity) {
    this.name = name;
    this.age = age;
    this.identity = identity;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.age === undefined || this.age === null) {
      arr.push(null);
    } else {
      arr.push(this.age);
    }
    if (this.identity === undefined || this.identity === null) {
      arr.push(null);
    } else {
      arr.push(this.identity as number);
    }
    return arr;
  }

  static fromList(arr: Object[]): Person {
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let ageObject: Object = arr[1];
    const age: number = ageObject as number;
    const identity: Identity = arr[2] as number as Identity;
    return new Person(name, age, identity);
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Student {
  private name: string;

  getName(): string {
    return this.name;
  }

  private age: number;

  getAge(): number {
    return this.age;
  }

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.age === undefined || this.age === null) {
      arr.push(null);
    } else {
      arr.push(this.age);
    }
    return arr;
  }

  static fromList(arr: Object[]): Student {
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let ageObject: Object = arr[1];
    const age: number = ageObject as number;
    return new Student(name, age);
  }
}

export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}

class DemoHostApiCodec extends StandardMessageCodec {
  static INSTANCE: DemoHostApiCodec = new DemoHostApiCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(128):
        return Person.fromList(super.readValue(buffer));
      case this.getByte(129):
        return Student.fromList(super.readValue(buffer));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof PigeonInternalDoubleBox) {
      stream.writeInt8(this.getByte(6));
      this.writeAlignment(stream, 8);
      stream.writeFloat64((value as PigeonInternalDoubleBox).value, true);
      return;
    } else     if (value instanceof Person) {
      stream.writeUint8(this.getByte(128));
      this.writeValue(stream, (value as Person).toList());
    } else if (value instanceof Student) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, (value as Student).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class DemoHostApi {

  abstract sendNull(data: Object | undefined): Object | undefined;

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

  abstract sendNullableEnum(data: Identity | undefined): Identity | undefined;

  abstract sendAsyncEnum(data: Identity, result: Result<Identity>): void;

  abstract triggerPlatformEchoEnum(data: Identity, result: Result<Identity>): void;

  abstract triggerPlatformEchoNullableEnum(data: Identity | undefined, result: Result<Identity | undefined>): void;

  abstract flutterInvokeSync(): string;

  abstract flutterInvokeAsync(result: Result<string>): void;

  abstract errorHandling(result: Result<string>): void;

  abstract taskQueueTest(): string;

  abstract triggerPlatformInvokeSync(result: Result<string>): void;

  abstract triggerPlatformInvokeAsync(result: Result<string>): void;
  /** The codec used by DemoHostApi. */
  static getCodec(): MessageCodec<Object>{
    return DemoHostApiCodec.INSTANCE;
  }
  /*Sets up an instance of `DemoHostApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: DemoHostApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNull' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Object | undefined = api!.sendNull(args[0] as Object | undefined);
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
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendTrue' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFalse' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendDouble' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.sendDouble(args[0] as number);
                res.push(new PigeonInternalDoubleBox(output));
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
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendString' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendUint8List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt32List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt64List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFloat64List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendList' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendMap' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendCustomClass' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNestedDatatype' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Identity = api!.sendEnum(args[0] as number as Identity);
                res.push(output as number);
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
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNullableEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Identity | undefined = api!.sendNullableEnum(args[0] == null || args[0] === undefined ? undefined : args[0] as number as Identity);
                res.push(output === undefined || output === null ? null : output as number);
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
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendAsyncEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<Identity>{
                    success(result: Identity): void {
                      let res: Array<Object> = [];
                      res.push(result as number);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity> = new ResultImp();

              api!.sendAsyncEnum(args[0] as number as Identity, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformEchoEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<Identity>{
                    success(result: Identity): void {
                      let res: Array<Object> = [];
                      res.push(result as number);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity> = new ResultImp();

              api!.triggerPlatformEchoEnum(args[0] as number as Identity, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformEchoNullableEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<Identity | undefined>{
                    success(result: Identity | undefined): void {
                      let res: Array<Object> = [];
                      res.push(result === undefined || result === null ? null : result as number);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity | undefined> = new ResultImp();

              api!.triggerPlatformEchoNullableEnum(args[0] == null || args[0] === undefined ? undefined : args[0] as number as Identity, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeSync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeAsync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              class ResultImp implements Result<string>{
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.errorHandling' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              class ResultImp implements Result<string>{
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let taskQueue: TaskQueue = binaryMessenger.makeBackgroundTaskQueue();
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.taskQueueTest' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
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
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformInvokeSync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              class ResultImp implements Result<string>{
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

              api!.triggerPlatformInvokeSync(resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformInvokeAsync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              class ResultImp implements Result<string>{
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

              api!.triggerPlatformInvokeAsync(resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/* Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.*/
export class DemoFlutterApi {
  binaryMessenger: BinaryMessenger;
  private messageChannelSuffix: string;

  constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = '') {
    this.binaryMessenger = binaryMessenger;
    this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
  }

  /** The codec used by DemoFlutterApi. */
  static getCodec(): MessageCodec<Object> {
    return new StandardMessageCodec();
  }

  platformInvokeSync(callback: Reply<string>):void {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeSync" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        null,
        channelReply => {
          let output: string = channelReply as string;
          callback.reply(output);
        });
  }
  platformInvokeAsync(callback: Reply<string>):void {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeAsync" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        null,
        channelReply => {
          let output: string = channelReply as string;
          callback.reply(output);
        });
  }
  platformEchoEnum(valueArg: Identity, callback: Reply<Identity>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoEnum" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        [valueArg as number],
        channelReply => {
          let output: Identity = channelReply as number as Identity;
          callback.reply(output);
        });
  }
  platformEchoNullableEnum(valueArg: Identity | undefined, callback: Reply<Identity | undefined>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoNullableEnum" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        [valueArg === undefined || valueArg === null ? null : valueArg as number],
        channelReply => {
          let output: Identity | undefined = channelReply == null || channelReply === undefined ? undefined : channelReply as number as Identity;
          callback.reply(output);
        });
  }
}
