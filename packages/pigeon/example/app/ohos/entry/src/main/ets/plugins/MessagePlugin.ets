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
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { ExampleHostApi, MessageData } from './Messages';
import { DemoHostApi } from './PigeonTest';
import { DemoHostApiImpl } from './DemoHostApiImpl';
import { DemoProxyApiRegistrarImpl } from './DemoProxyApiImpl';

class HostApiImp {
  getHostLanguage(): string {
    return 'ArkTS';
  }

  add(a: number, b: number): number {
    return a + b;
  }

  sendMessage(message: MessageData): boolean {
    return true;
  }
}

/** ArkTS single inheritance: bridge [HostApiImp] to [ExampleHostApi.setup]. */
class ExampleHostApiAdapter extends ExampleHostApi {
  private readonly impl: HostApiImp;

  constructor(impl: HostApiImp) {
    super();
    this.impl = impl;
  }

  getHostLanguage(): string {
    return this.impl.getHostLanguage();
  }

  add(a: number, b: number): number {
    return this.impl.add(a, b);
  }

  sendMessage(message: MessageData): boolean {
    return this.impl.sendMessage(message);
  }
}

export default class MessagePlugin implements FlutterPlugin {
  private readonly hostApiImp: HostApiImp = new HostApiImp();
  private readonly hostApiAdapter: ExampleHostApiAdapter =
    new ExampleHostApiAdapter(this.hostApiImp);
  private proxyRegistrar: DemoProxyApiRegistrarImpl | null = null;

  getUniqueClassName(): string {
    return 'MessagePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    ExampleHostApi.setup(binding.getBinaryMessenger(), this.hostApiAdapter);

    this.proxyRegistrar = new DemoProxyApiRegistrarImpl(binding.getBinaryMessenger());
    this.proxyRegistrar.setUp();
    DemoHostApi.setup(
      binding.getBinaryMessenger(),
      new DemoHostApiImpl(binding.getBinaryMessenger(), this.proxyRegistrar),
    );
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    ExampleHostApi.setup(binding.getBinaryMessenger(), null);
    DemoHostApi.setup(binding.getBinaryMessenger(), null);
    if (this.proxyRegistrar !== null) {
      this.proxyRegistrar.tearDown();
      this.proxyRegistrar = null;
    }
  }
}
