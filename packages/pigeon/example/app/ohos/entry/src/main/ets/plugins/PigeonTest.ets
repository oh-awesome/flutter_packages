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

<<<<<<< HEAD
  constructor(code: string, name: string, message: string, stack: string) 
{
=======
  constructor(code: string, name: string, message: string, stack?: string) {
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

<<<<<<< HEAD
function wrapError(error: Error): Array<Object> {
  let errorList: Array<Object> = new Array<Object>(3);
=======
/**
 * Wrapper so PigeonCodec always serializes a Dart `double` as float64.
 * ArkTS `number` values such as `1` or `1.0` would otherwise be encoded
 * as integers by StandardMessageCodec and fail strict Dart double casts.
 */
export class PigeonInternalDoubleBox {
  value: number;
  constructor(value: number) {
    this.value = value;
  }
}

function wrapError(error: Error): Array<Object | null> {
  let errorList: Array<Object | null> = new Array<Object | null>(3);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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

<<<<<<< HEAD
export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}

class DemoHostApiCodec extends StandardMessageCodec {
  static INSTANCE: DemoHostApiCodec = new DemoHostApiCodec();
=======
export class PigeonCodec extends StandardMessageCodec {
  static readonly INSTANCE: PigeonCodec = new PigeonCodec();
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
<<<<<<< HEAD
      case this.getByte(128):
        return Person.fromList(super.readValue(buffer));
      case this.getByte(129):
        return Student.fromList(super.readValue(buffer));
=======
      case this.getByte(129): {
        let value: Object = super.readValue(buffer);
        return value == null ? null : Identity[value as number];
      }
      case this.getByte(130): {
        let value: Object = super.readValue(buffer);
        return value == null ? null : ProxyRole[value as number];
      }
      case this.getByte(131):
        return Person.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(132):
        return Student.fromList(super.readValue(buffer) as Object[]);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
<<<<<<< HEAD
    if (value instanceof Person) {
      stream.writeUint8(this.getByte(128));
=======
    if (value instanceof PigeonInternalDoubleBox) {
      stream.writeInt8(this.getByte(6));
      this.writeAlignment(stream, 8);
      stream.writeFloat64((value as PigeonInternalDoubleBox).value, true);
      return;
    } else     if (value instanceof IdentityEnum) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, value == null ? null : Identity[value.index as string]);
    } else if (value instanceof ProxyRoleEnum) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, value == null ? null : ProxyRole[value.index as string]);
    } else if (value instanceof Person) {
      stream.writeUint8(this.getByte(131));
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
      this.writeValue(stream, (value as Person).toList());
    } else if (value instanceof Student) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, (value as Student).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

<<<<<<< HEAD
=======

export interface Result<T> {
  success(result: T): void;

  error(error: Error): void;
}
/**
 * Codec extending `PigeonCodec` with ProxyApi instance
 * references (tag 128). Host-created
 * instances must be registered via `pigeon_newInstance` before encoding.
 */
export class PigeonProxyApiBaseCodec extends PigeonCodec {
  registrar: PigeonProxyApiRegistrar;

  constructor(registrar: PigeonProxyApiRegistrar) {
    super();
    this.registrar = registrar;
  }

  override readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    if (type === 128) {
      const identifier: number = super.readValue(buffer) as number;
      const instance: ESObject | null = this.registrar.instanceManager.getInstance(identifier);
      if (instance === null) {
        throw new Error('PigeonProxyApiBaseCodec: instance not found for identifier ' + identifier + '. ' + this.registrar.instanceManager.getDebugInfo());
      }
      return instance;
    }
    return super.readValueOfType(type, buffer);
  }

  override writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value === null || typeof value === 'boolean' || typeof value === 'number' || typeof value === 'string' || Array.isArray(value) || value instanceof Map) {
      return super.writeValue(stream, value);
    }

    if (this.registrar.instanceManager.containsInstance(value)) {
      const identifier: number | null = this.registrar.instanceManager.getIdentifierForStrongReference(value);
      if (identifier === null) {
        throw new Error('PigeonProxyApiBaseCodec: no identifier for registered instance. ' + this.registrar.instanceManager.getDebugInfo());
      }
      stream.writeInt8(128);
      return this.writeValue(stream, identifier as Object);
    }

    return super.writeValue(stream, value);
  }
}

>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
  static getCodec(): MessageCodec<Object>{
    return DemoHostApiCodec.INSTANCE;
=======
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Object | undefined = api!.sendNull(args[0] as Object | undefined);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: boolean = api!.sendTrue(args[0] as boolean);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: boolean = api!.sendFalse(args[0] as boolean);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.sendInt(args[0] as number);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number = api!.sendDouble(args[0] as number);
<<<<<<< HEAD
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
=======
                res.push(new PigeonInternalDoubleBox(output));
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: string = api!.sendString(args[0] as string);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number[] = api!.sendUint8List(args[0] as number[]);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number[] = api!.sendInt32List(args[0] as number[]);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number[] = api!.sendInt64List(args[0] as number[]);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: number[] = api!.sendFloat64List(args[0] as number[]);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Array<string> = api!.sendList(args[0] as Array<string>);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Map<string, string> = api!.sendMap(args[0] as Map<string, string>);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Student = api!.sendCustomClass(args[0] as Student);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                let output: Person = api!.sendNestedDatatype(args[0] as Person);
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
<<<<<<< HEAD
                let output: Identity = api!.sendEnum(args[0] as number as Identity);
                res.push(output as number);
              } catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
=======
                let pigeonEnumResult: Identity = api!.sendEnum(Identity[args[0] as string]);
                let output: ESObject = pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new IdentityEnum(Identity[pigeonEnumResult as number]);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
<<<<<<< HEAD
                let output: Identity | undefined = api!.sendNullableEnum(args[0] == null || args[0] === undefined ? undefined : args[0] as number as Identity);
                res.push(output === undefined || output === null ? null : output as number);
              } catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
=======
                let pigeonEnumResult: Identity | undefined = api!.sendNullableEnum((args[0] == null ? null : Identity[args[0] as string]));
                let output: ESObject = pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new IdentityEnum(Identity[pigeonEnumResult as number]);
                res.push(output);
              } catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
=======
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
              let res: Array<Object> = [];
=======
              let res: Array<Object | null> = [];
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              try {
                let output: string = api!.flutterInvokeSync();
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
              let res: Array<Object> = [];
=======
              let res: Array<Object | null> = [];
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
              try {
                let output: string = api!.taskQueueTest();
                res.push(output);
              } catch (error) {
<<<<<<< HEAD
                let wrappedError: Array<Object> = wrapError(error);
=======
                let wrappedError: Array<Object | null> = wrapError(error);
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
  }
}
=======
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.proxyApiHostCreateAndEcho' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.proxyApiHostCreateAndEcho(resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/*
*  宿主创建专用 ProxyApi：无必填 Flutter 回调，Dart 会生成 `pigeon_newInstance` 处理器。
* 
*  Generated host-side adapter for ProxyApi `HostEnumCounter`.
*  Subclass and override the abstract members to provide your
*  HarmonyOS implementation, then return your subclass from the
*  registrar's `getHostEnumCounter()`.
*/
export abstract class PigeonApiHostEnumCounter {
  pigeonRegistrar: PigeonProxyApiRegistrar;

  constructor(pigeonRegistrar: PigeonProxyApiRegistrar) {
    this.pigeonRegistrar = pigeonRegistrar;
  }

  abstract pigeon_defaultConstructor(storedRole: ProxyRole, initial: number, role: ProxyRole): ESObject;

  /* Unattached 枚举字段：宿主 `pigeon_newInstance` 时由宿主 abstract getter 提供。*/
  abstract storedRole(pigeon_instance: ESObject): ProxyRole;

  abstract increment(pigeon_instance: ESObject, by: number): number;

  abstract current(pigeon_instance: ESObject): number;

  abstract echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole;

  abstract echoNullableRole(pigeon_instance: ESObject, value: ProxyRole | undefined): ProxyRole | undefined;

  /** Wires every host-side handler for `HostEnumCounter`. */
  static setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: PigeonApiHostEnumCounter | null): void {
    const codec: MessageCodec<Object> = api != null ? api.pigeonRegistrar.getCodec() : PigeonCodec.INSTANCE;
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.pigeon_defaultConstructor", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let pigeon_identifierArg: number = args[0] as number;
              let storedRoleArg: ESObject = ProxyRole[args[1] as string];
              let initialArg: number = args[2] as number;
              let roleArg: ESObject = ProxyRole[args[3] as string];
              let res: Array<Object | null> = [];
              try {
                api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.pigeon_defaultConstructor(storedRoleArg, initialArg, roleArg), pigeon_identifierArg); res.push(null);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.increment", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let byArg: number = args[1] as number;
              let res: Array<Object | null> = [];
              try {
                let output: ESObject = api!.increment(pigeon_instanceArg, byArg); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.current", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let res: Array<Object | null> = [];
              try {
                let output: ESObject = api!.current(pigeon_instanceArg); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.echoRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let valueArg: ESObject = ProxyRole[args[1] as string];
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: ESObject = api!.echoRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.echoNullableRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let valueArg: ESObject = (args[1] == null ? null : ProxyRole[args[1] as string]);
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: ESObject = api!.echoNullableRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager.
   *
   * Any unattached field values are read synchronously from this host adapter via its
   * own field methods (local calls, not channel round-trips) and are sent together with
   * the identifier in a single newInstance message. Exactly one platform channel message
   * is sent regardless of the number of fields.
   */
  pigeon_newInstance(pigeon_instance: ESObject, callback: Reply<void>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply();
      return;
    }
    const pigeon_identifier: number = this.pigeonRegistrar.instanceManager.addHostCreatedInstance(pigeon_instance);
    const storedRoleArg: ESObject = this.storedRole(pigeon_instance);
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.pigeon_newInstance';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_identifier, (storedRoleArg === null || storedRoleArg === undefined ? null : new ProxyRoleEnum(ProxyRole[storedRoleArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply();
        }
      } else {
        callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
      }
    });
  }

  /* 可选 Flutter 回调：宿主反向调用可空枚举路径（见 proxyApiHostCreate / main 全局 handler）。*/
  flutterEchoNullableRole(pigeon_instance: ESObject, valueArg: ProxyRole | undefined, callback: Reply<ProxyRole | undefined>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.flutterEchoNullableRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply((listReply[0] == null ? null : ProxyRole[listReply[0] as string]));
        }
      } else {
        callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
      }
    });
  }

}

/*
*  最小 ProxyApi：构造参数含枚举、unattached 枚举字段、宿主方法枚举回显、Flutter 枚举回调。
* 
*  Generated host-side adapter for ProxyApi `EnumCounter`.
*  Subclass and override the abstract members to provide your
*  HarmonyOS implementation, then return your subclass from the
*  registrar's `getEnumCounter()`.
*/
export abstract class PigeonApiEnumCounter {
  pigeonRegistrar: PigeonProxyApiRegistrar;

  constructor(pigeonRegistrar: PigeonProxyApiRegistrar) {
    this.pigeonRegistrar = pigeonRegistrar;
  }

  abstract pigeon_defaultConstructor(storedRole: ProxyRole, initial: number, role: ProxyRole): ESObject;

  abstract increment(pigeon_instance: ESObject, by: number): number;

  abstract current(pigeon_instance: ESObject): number;

  /* 宿主方法：枚举入参/返回（#18 编解码路径）。*/
  abstract echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole;

  abstract echoNullableRole(pigeon_instance: ESObject, value: ProxyRole | undefined): ProxyRole | undefined;

  /** Wires every host-side handler for `EnumCounter`. */
  static setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: PigeonApiEnumCounter | null): void {
    const codec: MessageCodec<Object> = api != null ? api.pigeonRegistrar.getCodec() : PigeonCodec.INSTANCE;
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.pigeon_defaultConstructor", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let pigeon_identifierArg: number = args[0] as number;
              let storedRoleArg: ESObject = ProxyRole[args[1] as string];
              let initialArg: number = args[2] as number;
              let roleArg: ESObject = ProxyRole[args[3] as string];
              let res: Array<Object | null> = [];
              try {
                api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.pigeon_defaultConstructor(storedRoleArg, initialArg, roleArg), pigeon_identifierArg); res.push(null);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.increment", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let byArg: number = args[1] as number;
              let res: Array<Object | null> = [];
              try {
                let output: ESObject = api!.increment(pigeon_instanceArg, byArg); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.current", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let res: Array<Object | null> = [];
              try {
                let output: ESObject = api!.current(pigeon_instanceArg); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.echoRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let valueArg: ESObject = ProxyRole[args[1] as string];
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: ESObject = api!.echoRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.echoNullableRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let pigeon_instanceArg: ESObject = args[0] as ESObject;
              let valueArg: ESObject = (args[1] == null ? null : ProxyRole[args[1] as string]);
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: ESObject = api!.echoNullableRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              } catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager.
   *
   * Any unattached field values are read synchronously from this host adapter via its
   * own field methods (local calls, not channel round-trips) and are sent together with
   * the identifier in a single newInstance message. Exactly one platform channel message
   * is sent regardless of the number of fields.
   */
  pigeon_newInstance(pigeon_instance: ESObject, callback: Reply<void>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply();
      return;
    }
    callback.reply(new FlutterError('new-instance-error', 'Attempting to create a new Dart instance of EnumCounter, but the class has a nonnull callback method.', '') as ESObject);
  }

  /* Flutter 回调：宿主反向调用，验证 ProxyApi 的 FlutterApi 枚举路径（非空返回须非 optional 字段）。*/
  flutterEchoRole(pigeon_instance: ESObject, valueArg: ProxyRole, callback: Reply<ProxyRole>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.EnumCounter.flutterEchoRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          if (listReply[0] == null) {
            callback.reply(new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '') as ESObject);
          } else {
            callback.reply(ProxyRole[listReply[0] as string]);
          }
        }
      } else {
        callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
      }
    });
  }

  flutterEchoNullableRole(pigeon_instance: ESObject, valueArg: ProxyRole | undefined, callback: Reply<ProxyRole | undefined>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.EnumCounter.flutterEchoNullableRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply((listReply[0] == null ? null : ProxyRole[listReply[0] as string]));
        }
      } else {
        callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
      }
    });
  }

}

>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
<<<<<<< HEAD
          let output: string = channelReply as string;
          callback.reply(output);
=======
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
        });
  }
  platformInvokeAsync(callback: Reply<string>):void {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeAsync" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        null,
        channelReply => {
<<<<<<< HEAD
          let output: string = channelReply as string;
          callback.reply(output);
=======
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
        });
  }
  platformEchoEnum(valueArg: Identity, callback: Reply<Identity>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoEnum" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        [valueArg as number],
        channelReply => {
<<<<<<< HEAD
          let output: Identity = channelReply as number as Identity;
          callback.reply(output);
=======
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
              callback.reply(replyNull);
            } else {
              let output: ESObject = listReply[0] == null ? null : Identity[listReply[0] as string];
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
        });
  }
  platformEchoNullableEnum(valueArg: Identity | undefined, callback: Reply<Identity | undefined>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoNullableEnum" + this.messageChannelSuffix, DemoFlutterApi.getCodec());
    channel.send(
        [valueArg === undefined || valueArg === null ? null : valueArg as number],
        channelReply => {
<<<<<<< HEAD
          let output: Identity | undefined = channelReply == null || channelReply === undefined ? undefined : channelReply as number as Identity;
          callback.reply(output);
=======
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[];
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              let output: ESObject = listReply[0] == null ? null : Identity[listReply[0] as string];
              callback.reply(output);
            }
          } else {
            let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');
            callback.reply(connErr);
          } 
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
        });
  }
}
