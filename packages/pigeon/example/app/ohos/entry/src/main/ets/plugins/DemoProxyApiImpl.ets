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
 * ProxyApi 宿主实现：EnumCounter（Dart 创建）与 HostEnumCounter（宿主创建）。
 */

import {
  FlutterError,
  PigeonApiEnumCounter,
  PigeonApiHostEnumCounter,
  PigeonProxyApiRegistrar,
  ProxyRole,
  Result,
} from './PigeonTest';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';

/** 宿主侧计数器实例（EnumCounter / HostEnumCounter 共用）。 */
export class NativeEnumCounter {
  value: number;
  role: ProxyRole;
  storedRole: ProxyRole;

  constructor(initial: number, role: ProxyRole) {
    this.value = initial;
    this.role = role;
    this.storedRole = role;
  }
}

export class PigeonApiEnumCounterImpl extends PigeonApiEnumCounter {
  pigeon_defaultConstructor(
    storedRole: ProxyRole,
    initial: number,
    role: ProxyRole,
  ): ESObject {
    const counter = new NativeEnumCounter(initial, role);
    counter.storedRole = storedRole;
    return counter;
  }

  storedRole(pigeon_instance: ESObject): ProxyRole {
    return (pigeon_instance as NativeEnumCounter).storedRole;
  }

  increment(pigeon_instance: ESObject, by: number): number {
    const counter = pigeon_instance as NativeEnumCounter;
    counter.value += by;
    return counter.value;
  }

  current(pigeon_instance: ESObject): number {
    return (pigeon_instance as NativeEnumCounter).value;
  }

  echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole {
    return value;
  }

  echoNullableRole(
    pigeon_instance: ESObject,
    value: ProxyRole | undefined,
  ): ProxyRole | undefined {
    return value;
  }
}

export class PigeonApiHostEnumCounterImpl extends PigeonApiHostEnumCounter {
  pigeon_defaultConstructor(
    storedRole: ProxyRole,
    initial: number,
    role: ProxyRole,
  ): ESObject {
    const counter = new NativeEnumCounter(initial, role);
    counter.storedRole = storedRole;
    return counter;
  }

  storedRole(pigeon_instance: ESObject): ProxyRole {
    return (pigeon_instance as NativeEnumCounter).storedRole;
  }

  increment(pigeon_instance: ESObject, by: number): number {
    const counter = pigeon_instance as NativeEnumCounter;
    counter.value += by;
    return counter.value;
  }

  current(pigeon_instance: ESObject): number {
    return (pigeon_instance as NativeEnumCounter).value;
  }

  echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole {
    return value;
  }

  echoNullableRole(
    pigeon_instance: ESObject,
    value: ProxyRole | undefined,
  ): ProxyRole | undefined {
    return value;
  }
}

export class DemoProxyApiRegistrarImpl extends PigeonProxyApiRegistrar {
  private readonly counterApi: PigeonApiEnumCounterImpl;
  private readonly hostCounterApi: PigeonApiHostEnumCounterImpl;

  constructor(binaryMessenger: BinaryMessenger) {
    super(binaryMessenger);
    this.counterApi = new PigeonApiEnumCounterImpl(this);
    this.hostCounterApi = new PigeonApiHostEnumCounterImpl(this);
  }

  getEnumCounter(): PigeonApiEnumCounter {
    return this.counterApi;
  }

  getHostEnumCounter(): PigeonApiHostEnumCounter {
    return this.hostCounterApi;
  }
}

function formatProxyRole(role: ProxyRole | null | undefined): string {
  if (role === null || role === undefined) {
    return 'null';
  }
  const name: string | undefined = ProxyRole[role as number];
  return name !== undefined ? name : String(role);
}

class ProxySmokeNullableRoleReply {
  private readonly onDone: (role: ProxyRole | undefined) => void;
  private readonly onError: (message: string) => void;

  constructor(
    onDone: (role: ProxyRole | undefined) => void,
    onError: (message: string) => void,
  ) {
    this.onDone = onDone;
    this.onError = onError;
  }

  reply(value: ESObject): void {
    if (value instanceof FlutterError) {
      const err: FlutterError = value as FlutterError;
      this.onError(`${err.code}: ${err.message}`);
      return;
    }
    this.onDone(value as ProxyRole | undefined);
  }
}

class PigeonNewInstanceVoidReply implements Reply<void> {
  private readonly onReady: () => void;
  private readonly onError: (message: string) => void;

  constructor(onReady: () => void, onError: (message: string) => void) {
    this.onReady = onReady;
    this.onError = onError;
  }

  reply(value: void): void {
    const replyValue: ESObject = value as ESObject;
    if (replyValue instanceof FlutterError) {
      const err: FlutterError = replyValue as FlutterError;
      this.onError(`${err.code}: ${err.message}`);
      return;
    }
    // Yield one event-loop turn so Dart InstanceManager is visible to the codec.
    setTimeout((): void => {
      this.onReady();
    }, 0);
  }
}

/**
 * 等待 Dart 侧完成 [HostEnumCounter] 注册（委托生成版 pigeon_newInstance 的错误处理）。
 */
function awaitHostEnumCounterOnDart(
  api: PigeonApiHostEnumCounterImpl,
  registrar: DemoProxyApiRegistrarImpl,
  native: NativeEnumCounter,
  onReady: () => void,
  onError: (stage: string, message: string) => void,
): void {
  if (registrar.ignoreCallsToDart) {
    onError('pigeon_newInstance', 'ignore-calls-to-dart');
    return;
  }
  if (registrar.instanceManager.containsInstance(native)) {
    onReady();
    return;
  }
  api.pigeon_newInstance(
    native,
    new PigeonNewInstanceVoidReply(onReady, (message: string): void => {
      onError('pigeon_newInstance', message);
    }),
  );
}

/**
 * 供 [DemoHostApiImpl.proxyApiHostCreateAndEcho] 使用：宿主创建 [HostEnumCounter]，
 * 验证 pigeon_newInstance、宿主枚举 echo、以及宿主→Flutter 可空枚举回调。
 */
export function runProxyApiHostEnumSmokeTest(
  registrar: DemoProxyApiRegistrarImpl,
  result: Result<string>,
): void {
  const api: PigeonApiHostEnumCounterImpl =
    registrar.getHostEnumCounter() as PigeonApiHostEnumCounterImpl;
  const native: NativeEnumCounter = new NativeEnumCounter(3, ProxyRole.ADMIN);
  const reportError = (stage: string, message: string): void => {
    result.error(new Error(`${stage}: ${message}`));
  };
  awaitHostEnumCounterOnDart(api, registrar, native, (): void => {
    const echoed: ProxyRole = api.echoRole(native, ProxyRole.GUEST);
    api.flutterEchoNullableRole(
      native,
      ProxyRole.ADMIN,
      new ProxySmokeNullableRoleReply((fromFlutter: ProxyRole | undefined): void => {
        result.success(
          'host-create ok; storedRole='
            + formatProxyRole(api.storedRole(native))
            + '; echoRole='
            + formatProxyRole(echoed)
            + '; flutterEchoNullableRole='
            + formatProxyRole(fromFlutter)
            + '; current='
            + api.current(native),
        );
      }, (message: string): void => {
        reportError('flutterEchoNullableRole', message);
      }) as Reply<ProxyRole | undefined>,
    );
  }, reportError);
}
