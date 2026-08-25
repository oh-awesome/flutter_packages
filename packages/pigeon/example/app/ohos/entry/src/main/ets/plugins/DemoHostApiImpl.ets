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

/*
 * 样板实现：DemoHostApi 的每个方法都原样 echo 回入参，
 * 用于验证 pigeon 自动生成的 ArkTS 桥接代码各类型数据是否都能正确往返。
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
  private isAttached: boolean = true;

  constructor(
    binaryMessenger: BinaryMessenger,
    proxyRegistrar: DemoProxyApiRegistrarImpl,
    messageChannelSuffix: string = '',
  ) {
    super();
    this.flutterApi = new DemoFlutterApi(binaryMessenger, messageChannelSuffix);
    this.proxyRegistrar = proxyRegistrar;
  }

  setAttached(attached: boolean): void {
    this.isAttached = attached;
  }

  private replyWhenAttached<T>(result: Result<T>, value: T): void {
    if (!this.isAttached) {
      return;
    }
    try {
      result.success(value);
    } catch (error) {
      // Engine may already be detached; ignore reply failures.
    }
  }

  // ===== 基本类型 echo =====
  sendNull(data: Object | undefined): Object | undefined {
    return data;
  }

  sendTrue(data: boolean): boolean {
    if (typeof data !== 'boolean') {
      throw new FlutterError('invalid-argument', 'sendTrue expects a boolean.', null);
    }
    return data;
  }

  sendFalse(data: boolean): boolean {
    if (typeof data !== 'boolean') {
      throw new FlutterError('invalid-argument', 'sendFalse expects a boolean.', null);
    }
    return data;
  }

  sendInt(data: number): number {
    if (typeof data !== 'number' || !Number.isFinite(data)) {
      throw new FlutterError('invalid-argument', 'sendInt expects a finite number.', null);
    }
    return data;
  }

  sendDouble(data: number): number {
    if (typeof data !== 'number' || !Number.isFinite(data)) {
      throw new FlutterError('invalid-argument', 'sendDouble expects a finite number.', null);
    }
    return data;
  }

  sendString(data: string): string {
    if (typeof data !== 'string') {
      throw new FlutterError('invalid-argument', 'sendString expects a string.', null);
    }
    return data;
  }

  // ===== typed list echo =====
  // Codec may deliver Uint8Array/typed buffers rather than plain JS Array;
  // echo through without Array.isArray check (aligned with v26.3.4_ohos_dev).
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

  // ===== 容器 echo =====
  sendList(data: Array<string>): Array<string> {
    return data;
  }

  sendMap(data: Map<string, string>): Map<string, string> {
    return data;
  }

  // ===== 自定义类型 echo =====
  sendCustomClass(data: Student): Student {
    return data;
  }

  sendNestedDatatype(data: Person): Person {
    return data;
  }

  sendEnum(data: Identity): Identity {
    return data;
  }

  // 同步可空枚举 echo
  sendNullableEnum(data: Identity | undefined): Identity | undefined {
    return data;
  }

  // 异步枚举 echo（验证 HostApi 异步枚举返回的伴侣包装）
  sendAsyncEnum(data: Identity, result: Result<Identity>): void {
    setTimeout(() => {
      this.replyWhenAttached(result, data);
    }, 100);
  }

  // ===== Flutter -> Platform 同步调用 =====
  flutterInvokeSync(): string {
    console.log('Platform flutterInvokeSync方法被调用');
    return 'Received message: This is flutterInvokeSync() from Platform.同步方法被调用';
  }

  // ===== Flutter -> Platform 异步调用 =====
  flutterInvokeAsync(result: Result<string>): void {
    setTimeout(() => {
      if (!this.isAttached) {
        return;
      }
      try {
        console.log('Platform flutterInvokeAsync方法被调用');
        result.success('Received message: This is flutterInvokeAsync() from Platform.异步方法被调用');
      } catch (error) {
        // Engine may already be detached; ignore reply failures.
      }
    }, 100);
  }

  // ===== 错误处理 =====
  errorHandling(result: Result<string>): void {
    console.log('Platform errorHandling被调用');
    result.error(
      new FlutterError(
        'Platform',
        'errorHandling被调用',
        '返回PlatformException',
      ),
    );
  }

  // ===== TaskQueue（serialBackgroundThread） =====
  taskQueueTest(): string {
    return 'taskQueueTest from ArkTS';
  }

  // ===== 反向调用 Flutter：DemoFlutterApi.platformInvokeSync =====
  triggerPlatformInvokeSync(result: Result<string>): void {
    this.flutterApi.platformInvokeSync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformInvokeSync成功调用:Flutter侧收到平台侧platformInvokeSync方法调用');
        result.success(`platform got from Flutter (sync): ${reply as string}`);
      },
    });
  }

  // ===== 反向调用 Flutter：DemoFlutterApi.platformInvokeAsync =====
  triggerPlatformInvokeAsync(result: Result<string>): void {
    this.flutterApi.platformInvokeAsync({
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformInvokeAsync成功调用:Flutter侧收到平台侧platformInvokeAsync方法调用');
        result.success(`platform got from Flutter (async): ${reply as string}`);
      },
    });
  }

  // ===== 反向调用 Flutter：回显枚举（验证 FlutterApi 枚举入参 + 返回）=====
  triggerPlatformEchoEnum(data: Identity, result: Result<Identity>): void {
    this.flutterApi.platformEchoEnum(data, {
      reply: (reply: ESObject): void => {
        if (reply instanceof FlutterError) {
          result.error(reply as FlutterError);
          return;
        }
        console.log('platformEchoEnum 回显:' + reply);
        result.success(reply as Identity);
      },
    });
  }

  // ===== 反向调用 Flutter：回显可空枚举 =====
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
        console.log('platformEchoNullableEnum 回显:' + reply);
        result.success(reply as Identity | undefined);
      },
    });
  }

  proxyApiHostCreateAndEcho(result: Result<string>): void {
    runProxyApiHostEnumSmokeTest(this.proxyRegistrar, result);
  }
}
