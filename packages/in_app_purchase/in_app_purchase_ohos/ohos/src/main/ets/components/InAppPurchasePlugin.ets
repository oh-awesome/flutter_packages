/*
* Copyright (c) 2024 SwanLink (Jiangsu) Technology Development Co., LTD.
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
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  BinaryMessenger,
  Log,
  MethodChannel,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { MethodCallHandlerImpl } from './MethodCallHandlerImpl';

const TAG = "InAppPurchasePlugin"

export class InAppPurchasePlugin implements FlutterPlugin, AbilityAware {
  private methodChannel: MethodChannel | null = null
  private methodCallHandler: MethodCallHandlerImpl | null = null
  private context: common.UIAbilityContext | null = null

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    try {
      this.setUpMethodChannel(binding.getBinaryMessenger(), binding.getApplicationContext());
    } catch (e) {
      Log.e(TAG, `Failed to set up method channel on engine attach. err: ${JSON.stringify(e)}`);
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.teardownMethodChannel();
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context
    this.methodCallHandler?.setContext(this.context)
  }

  onDetachedFromAbility(): void {
    this.methodCallHandler?.setContext(null)
    // Clear cached product/receipt state so a re-attached ability does not
    // reuse stale data. The observer is intentionally NOT stopped here:
    // the Dart purchaseStream stays subscribed across ability re-attach and
    // would stop receiving transaction updates if the observer were nulled.
    this.methodCallHandler?.clearCache()
    this.context = null
  }

  getUniqueClassName(): string {
    return TAG
  }

  setUpMethodChannel(messenger: BinaryMessenger, context: common.Context) {
    this.methodChannel = new MethodChannel(messenger, "plugins.flutter.io/in_app_purchase");
    this.methodCallHandler =
      new MethodCallHandlerImpl(context, this.methodChannel);
    this.methodChannel.setMethodCallHandler(this.methodCallHandler);
  }

  teardownMethodChannel() {
    // Release resources in order: stop the observer, clear caches, then
    // unregister the handler and drop references.
    this.methodCallHandler?.stopObserver();
    this.methodCallHandler?.clearCache();
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.methodCallHandler = null;
    this.context = null;
  }
}
