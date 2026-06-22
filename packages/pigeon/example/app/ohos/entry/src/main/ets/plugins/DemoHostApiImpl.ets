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

import {
  DemoFlutterApi,
  DemoHostApi,
  FlutterError,
  Identity,
  Person,
  Result,
  Student,
} from './PigeonTest';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';

export class DemoHostApiImpl extends DemoHostApi {
  private flutterApi: DemoFlutterApi;

  constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = '') {
    super();
    this.flutterApi = new DemoFlutterApi(binaryMessenger, messageChannelSuffix);
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

  sendList(data: Array<string>): Array<string> {
    return data;
  }

  sendMap(data: Map<string, string>): Map<string, string> {
    return data;
  }

  sendCustomClass(data: Student): Student {
    return data;
  }

  sendNestedDatatype(data: Person): Person {
    return data;
  }

  sendEnum(data: Identity): Identity {
    return data;
  }

  sendNullableEnum(data: Identity | undefined): Identity | undefined {
    return data;
  }

  sendAsyncEnum(data: Identity, result: Result<Identity>): void {
    result.success(data);
  }

  flutterInvokeSync(): string {
    return 'Received message: This is flutterInvokeSync() from Platform.同步调用返回';
  }

  flutterInvokeAsync(result: Result<string>): void {
    setTimeout(() => {
      result.success(
        'Received message: This is flutterInvokeAsync() from Platform.异步调用返回',
      );
    }, 100);
  }

  errorHandling(result: Result<string>): void {
    result.error(
      new FlutterError(
        'Platform',
        'errorHandling测试',
        '测试PlatformException',
        '',
      ),
    );
  }

  taskQueueTest(): string {
    return 'taskQueueTest from ArkTS';
  }

  triggerPlatformInvokeSync(result: Result<string>): void {
    this.flutterApi.platformInvokeSync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        result.success(`platform got from Flutter (sync): ${reply as string}`);
      },
    });
  }

  triggerPlatformInvokeAsync(result: Result<string>): void {
    this.flutterApi.platformInvokeAsync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        result.success(`platform got from Flutter (async): ${reply as string}`);
      },
    });
  }

  triggerPlatformEchoEnum(data: Identity, result: Result<Identity>): void {
    this.flutterApi.platformEchoEnum(data, {
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        result.success(reply as Identity);
      },
    });
  }

  triggerPlatformEchoNullableEnum(
    data: Identity | undefined,
    result: Result<Identity | undefined>,
  ): void {
    this.flutterApi.platformEchoNullableEnum(data, {
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        result.success(reply as Identity | undefined);
      },
    });
  }
}
