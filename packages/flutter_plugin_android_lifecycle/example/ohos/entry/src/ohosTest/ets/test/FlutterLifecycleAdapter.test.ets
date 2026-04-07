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
import UIAbility from '@ohos.app.ability.UIAbility';
import { describe, it, expect } from '@ohos/hypium';
import { AbilityPluginBinding } from '@ohos/flutter_ohos';
import {
  FlutterLifecycleAdapter,
  LifecycleState,
  OhosLifecycle
} from 'flutter_plugin_android_lifecycle';

class FakeAbilityPluginBinding {
  private readonly ability: UIAbility;

  constructor(ability: UIAbility) {
    this.ability = ability;
  }

  getAbility(): UIAbility {
    return this.ability;
  }
}

export default function flutterLifecycleAdapterTest() {
  describe('FlutterLifecycleAdapterTest', function () {
    it('getAbilityLifecycleReturnsLifecycleForBindingAbility', 0, function () {
      const ability = new UIAbility();
      const binding = new FakeAbilityPluginBinding(ability) as AbilityPluginBinding;

      const lifecycle: OhosLifecycle = FlutterLifecycleAdapter.getAbilityLifecycle(binding);

      expect(lifecycle.getAbility()).assertEqual(ability);
      expect(lifecycle.getCurrentState()).assertEqual(LifecycleState.ABILITY_CREATE);
    });
  });
}
