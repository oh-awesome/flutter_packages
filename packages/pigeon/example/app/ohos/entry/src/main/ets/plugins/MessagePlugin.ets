/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
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
import { DemoHostApi, IdentityEnum,FlutterError, Result, Person, Student } from './PigeonOhos';


class HostApiImp extends DemoHostApi {
  sendCustomClass(data: Student): Student {
    return data;
  }

  sendNestedDatatype(data: Person): Person {
    return data;
  }
  getHostLanguage(): string {
    return 'ArkTS';
  }

  add(a: number, b: number): number {
    return a + b;
  }

  sendNull(data: Object): Object {
    return data;
  }

  sendTrue(data: boolean): boolean {
    return data;
  }

  sendFalse(data: boolean): boolean {
    return data;
  }

  sendInt(data: number): number {
    return data;
  }

  sendDouble(data: number): number {
    return data;
  }

  sendString(data: string): string {
    return data;
  }

  sendUint8List(data: number[]): number[] {
    return data;
  }

  sendInt32List(data: number[]): number[] {
    return data;
  }

  sendInt64List(data: number[]): number[] {
    return data;
  }

  sendFloat64List(data: number[]): number[] {
    return data;
  }

  sendList(data: string[]): string[] {
    return data;
  }

  sendMap(data: Map<string, string>): Map<string, string> {
    let mapStr: string = '{';
    data.forEach((value, key, data) => {
      mapStr += key + ':' + value + ', ';
    });
    mapStr.slice(0, -1);
    mapStr += '}'
    return data;
  }

  sendEnum(data: IdentityEnum): IdentityEnum {
    return data;
  }

  flutterInvokeSync(): string {
    return "This is flutterInvokeSync() from Platform.同步方法被调用";
  }

  flutterInvokeAsync(result: Result<string>) {
    result.success("This is flutterInvokeAsync() from Platform.异步方法被调用");
  }

  errorHandling(result: Result<string>) {
    let flutterError: Error = new FlutterError("Platform", "Platform errorHandling方法被调用 message",
      "Platform errorHandling方法被调用 stack");
    result.error(flutterError);
  }

  taskQueueTest(): string {
    return "This is taskQueueTest() from Platform. 方法被调用！";
  }
}

export default class MessagePlugin implements FlutterPlugin {
  constructor() {
  }

  getUniqueClassName(): string {
    return 'MessagePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding) {
    DemoHostApi.setup(binding.getBinaryMessenger(), new HostApiImp());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding) {
    DemoHostApi.setup(binding.getBinaryMessenger(), null);
  }
}