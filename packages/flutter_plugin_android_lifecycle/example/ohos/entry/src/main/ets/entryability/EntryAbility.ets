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
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos';
import {
  FlutterLifecycleAdapter,
  LifecycleObserver,
  LifecycleState,
  OhosLifecycle
} from 'flutter_plugin_android_lifecycle';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';

const TAG = 'TestPlugin';

export default class EntryAbility extends FlutterAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    await super.onCreate(want, launchParam);
  }

  async configureFlutterEngine(flutterEngine: FlutterEngine): Promise<void> {
    await super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(new TestPlugin());
  }

  async onDestroy(): Promise<void> {
    await super.onDestroy();
  }
}

class TestPlugin implements FlutterPlugin, AbilityAware {
  private lifecycle: OhosLifecycle | null = null;
  private readonly lifecycleObserver: LifecycleObserver = (state: LifecycleState): void => {
    console.info(TAG + ' Lifecycle changed: ' + state);
  };

  getUniqueClassName(): string {
    return 'TestPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.lifecycle = FlutterLifecycleAdapter.getAbilityLifecycle(binding);
    this.lifecycle.addObserver(this.lifecycleObserver);
    console.info(
      TAG + ' Successfully obtained Lifecycle, state=' + this.lifecycle.getCurrentState()
    );
  }

  onDetachedFromAbility(): void {
    if (this.lifecycle != null) {
      this.lifecycle.removeObserver(this.lifecycleObserver);
      this.lifecycle.dispose();
      this.lifecycle = null;
    }
  }
}
