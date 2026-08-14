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
import { AbilityConstant, Want } from '@kit.AbilityKit';
import QuickActionsPlugin, { EXTRA_ACTION } from 'quick_actions_ohos';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);
    this.handleShortcutWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParam);
    this.handleShortcutWant(want);
  }

  private handleShortcutWant(want: Want): void {
    console.info(`QuickActions: handleShortcutWant called, action=${want.action}, bundleName=${want.bundleName}`);
    if (want.parameters) {
      const keys = Object.keys(want.parameters);
      console.info(`QuickActions: want.parameters keys=[${keys.join(', ')}]`);
      for (const key of keys) {
        console.info(`QuickActions: param[${key}]=${want.parameters[key]}`);
      }
    } else {
      console.info('QuickActions: want.parameters is null/undefined');
    }

    // Check if launched from a shortcut action.
    const candidateKeys: string[] = [
      EXTRA_ACTION,
      'ohos.extra.param.key.shortcutId',
      'shortcutId',
      'ohos.shortcut.id',
    ];

    for (const key of candidateKeys) {
      const value = want.parameters?.[key] as string | undefined;
      if (value && value.length > 0) {
        console.info(`QuickActions: Found shortcut action by key=${key}, value=${value}`);
        QuickActionsPlugin.dispatchShortcutAction(value);
        return;
      }
    }
  }
}
