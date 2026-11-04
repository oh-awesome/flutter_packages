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

/*
 * Sample DemoHostApi implementation: each method echoes its inputs to verify
 * generated ArkTS bridge encoding for all supported types.
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
import {
  DemoProxyApiRegistrarImpl,
  runProxyApiHostEnumSmokeTest,
} from './DemoProxyApiImpl';

export class DemoHostApiImpl extends DemoHostApi {
  private flutterApi: DemoFlutterApi;
  private proxyRegistrar: DemoProxyApiRegistrarImpl;

  constructor(
    binaryMessenger: BinaryMessenger,
    proxyRegistrar: DemoProxyApiRegistrarImpl,
    messageChannelSuffix: string = '',
  ) {
    super();
    this.flutterApi = new DemoFlutterApi(binaryMessenger, messageChannelSuffix);
    this.proxyRegistrar = proxyRegistrar;
  }

  // ===== Primitive echo =====
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

  // ===== Typed list echo =====
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

  // ===== Container echo =====
  sendList(data: Array<string>): Array<string> {
    return data;
  }

  sendMap(data: Map<string, string>): Map<string, string> {
    return data;
  }

  // ===== Custom types echo =====
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
    setTimeout(() => {
      result.success(data);
    }, 100);
  }

  // ===== Flutter -> Platform sync =====
  flutterInvokeSync(): string {
    console.log('Platform flutterInvokeSync invoked');
    return 'Received message: flutterInvokeSync() from Platform (sync).';
  }

  // ===== Flutter -> Platform async =====
  flutterInvokeAsync(result: Result<string>): void {
    setTimeout(() => {
      console.log('Platform flutterInvokeAsync invoked');
      result.success('Received message: flutterInvokeAsync() from Platform (async).');
    }, 100);
  }

  // ===== Error handling =====
  errorHandling(result: Result<string>): void {
    console.log('Platform errorHandling invoked');
    result.error(
      new FlutterError(
        'Platform',
        'errorHandling invoked',
        'Returning PlatformException',
      ),
    );
  }

  // ===== TaskQueue (serialBackgroundThread) =====
  taskQueueTest(): string {
    return 'taskQueueTest from ArkTS';
  }

  // ===== FlutterApi.platformInvokeSync (Platform -> Flutter) =====
  triggerPlatformInvokeSync(result: Result<string>): void {
    this.flutterApi.platformInvokeSync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformInvokeSync: Flutter received platform call');
        result.success(`platform got from Flutter (sync): ${reply as string}`);
      },
    });
  }

  // ===== FlutterApi.platformInvokeAsync (Platform -> Flutter) =====
  triggerPlatformInvokeAsync(result: Result<string>): void {
    this.flutterApi.platformInvokeAsync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformInvokeAsync: Flutter received platform call');
        result.success(`platform got from Flutter (async): ${reply as string}`);
      },
    });
  }

  // ===== FlutterApi.platformEchoEnum =====
  triggerPlatformEchoEnum(data: Identity, result: Result<Identity>): void {
    this.flutterApi.platformEchoEnum(data, {
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformEchoEnum echo: ' + reply);
        result.success(reply as Identity);
      },
    });
  }

  // ===== FlutterApi.platformEchoNullableEnum =====
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
        console.log('platformEchoNullableEnum echo: ' + reply);
        result.success(reply as Identity | undefined);
      },
    });
  }

  proxyApiHostCreateAndEcho(result: Result<string>): void {
    runProxyApiHostEnumSmokeTest(this.proxyRegistrar, result);
  }
}
