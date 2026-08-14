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

import 'package:flutter/foundation.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

import 'src/messages.g.dart';

export 'package:quick_actions_platform_interface/types/types.dart';

late QuickActionHandler _handler;

/// An implementation of [QuickActionsPlatform] for OpenHarmony (OHOS).
class QuickActionsOhos extends QuickActionsPlatform {
  /// Creates a new plugin implementation instance.
  QuickActionsOhos({
    @visibleForTesting OhosQuickActionsApi? api,
  }) : _hostApi = api ?? OhosQuickActionsApi();

  final OhosQuickActionsApi _hostApi;

  /// Registers this class as the default instance of [QuickActionsPlatform].
  static void registerWith() {
    QuickActionsPlatform.instance = QuickActionsOhos();
  }

  @override
  Future<void> initialize(QuickActionHandler handler) async {
    final _QuickActionHandlerApi quickActionsHandlerApi =
        _QuickActionHandlerApi();
    OhosQuickActionsFlutterApi.setup(quickActionsHandlerApi);
    _handler = handler;
    final String? action = await _hostApi.getLaunchAction();
    if (action != null) {
      _handler(action);
    }
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    await _hostApi.setShortcutItems(
      items.map(_shortcutItemToShortcutItemMessage).toList(),
    );
  }

  @override
  Future<void> clearShortcutItems() => _hostApi.clearShortcutItems();

  ShortcutItemMessage _shortcutItemToShortcutItemMessage(ShortcutItem item) {
    return ShortcutItemMessage(
      type: item.type,
      localizedTitle: item.localizedTitle,
      localizedSubtitle: item.localizedSubtitle,
      icon: item.icon,
    );
  }
}

class _QuickActionHandlerApi extends OhosQuickActionsFlutterApi {
  @override
  void launchAction(String action) {
    _handler(action);
  }
}
