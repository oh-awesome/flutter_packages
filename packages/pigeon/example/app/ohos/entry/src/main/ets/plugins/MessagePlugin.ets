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
import { ExampleHostApi, MessageData, Result } from './Messages';
import { DemoHostApi } from './PigeonTest';
import { DemoHostApiImpl } from './DemoHostApiImpl';

class ExampleHostApiAdapter extends ExampleHostApi {
  getHostLanguage(): string {
    return 'ArkTS';
  }

  add(a: number, b: number): number {
    return a + b;
  }

  sendMessage(message: MessageData, result: Result<boolean>): void {
    result.success(true);
  }
}

export default class MessagePlugin implements FlutterPlugin {
  getUniqueClassName(): string {
    return 'MessagePlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding) {
    const binaryMessenger = binding.getBinaryMessenger();
    ExampleHostApi.setup(binaryMessenger, new ExampleHostApiAdapter());
    DemoHostApi.setup(binaryMessenger, new DemoHostApiImpl(binaryMessenger));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding) {
    const binaryMessenger = binding.getBinaryMessenger();
    ExampleHostApi.setup(binaryMessenger, null);
    DemoHostApi.setup(binaryMessenger, null);
  }
}
