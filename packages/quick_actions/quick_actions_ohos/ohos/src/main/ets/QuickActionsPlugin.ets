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

import {
  FlutterPlugin,
  FlutterPluginBinding,
  BasicMessageChannel,
  StandardMessageCodec,
  Reply,
  ByteBuffer,
} from '@ohos/flutter_ohos';

/// Represents a shortcut item message sent from Dart.
interface ShortcutItemMessage {
  type: string;
  localizedTitle: string;
  /// Optional localized subtitle. OHOS does not render a subtitle for static
  /// shortcuts, but the field is kept for parity with the iOS implementation so
  /// that data is not silently dropped when crossing the platform channel.
  localizedSubtitle?: string;
  icon?: string;
}

/// Minimum number of elements the wire format must contain.
/// Wire format (matches the Dart ShortcutItemMessage.encode):
/// [type, localizedTitle, localizedSubtitle, icon]
const SHORTCUT_ITEM_WIRE_LENGTH: number = 4;

/// Decodes a ShortcutItemMessage from its wire format.
///
/// Returns null when the input is malformed (null, not an array, or too short)
/// instead of throwing, so a single bad message cannot crash the codec or the
/// message handler. Callers must handle the null case.
function decodeShortcutItemMessage(value: Object | null): ShortcutItemMessage | null {
  if (value === null || !Array.isArray(value)) {
    console.error('QuickActionsPlugin: invalid ShortcutItemMessage wire format, expected an array');
    return null;
  }
  const result: Array<Object | null> = value as Array<Object | null>;
  if (result.length < SHORTCUT_ITEM_WIRE_LENGTH) {
    console.error(`QuickActionsPlugin: ShortcutItemMessage array too short (${result.length}), expected ≥ ${SHORTCUT_ITEM_WIRE_LENGTH}`);
    return null;
  }
  const message: ShortcutItemMessage = {
    type: (result[0] as string) ?? '',
    localizedTitle: (result[1] as string) ?? '',
    icon: (result[3] as string | null) ?? undefined,
  };
  const subtitle: string | undefined = (result[2] as string | null) ?? undefined;
  if (subtitle !== undefined) {
    message.localizedSubtitle = subtitle;
  }
  return message;
}

/// Specific error codes mirroring the Android implementation, so that callers
/// can branch on a stable identifier instead of parsing a free-form message.
const ERROR_CODE_GET_LAUNCH_ACTION: string = 'quick_action_getlaunchaction_failure';
const ERROR_CODE_SET_SHORTCUT_ITEMS: string = 'quick_action_setshortcutitems_failure';
const ERROR_CODE_CLEAR_SHORTCUT_ITEMS: string = 'quick_action_clearshortcutitems_failure';
const ERROR_CODE_DECODE_SHORTCUT_ITEM: string = 'quick_action_decodeshortcutitem_failure';

/// Builds a diagnostic error message that preserves the cause together with the
/// operation context, matching the verbosity of the Android/iOS error paths.
function describeError(operation: string, error: Object): string {
  const detail: string = (error as Error)?.message ?? String(error);
  return `QuickActionsPlugin ${operation} failed: ${detail}`;
}

/// Custom codec for encoding/decoding ShortcutItemMessage.
///
/// The decode path is wrapped in try-catch because it runs inside the codec
/// layer, outside any handler's try-catch; a malformed message must not crash
/// the channel. On failure it logs and returns null.
class QuickActionsCodec extends StandardMessageCodec {
  readValueOfType(type: number, buffer: ByteBuffer): Object | null {
    if (type === 128) {
      try {
        return decodeShortcutItemMessage(super.readValue(buffer));
      } catch (e) {
        console.error(`QuickActionsCodec: failed to decode ShortcutItemMessage: ${e}`);
        return null;
      }
    }
    return super.readValueOfType(type, buffer);
  }
}

/// Key used in Want parameters to pass the shortcut action type.
export const EXTRA_ACTION: string = 'flutter_quick_action';

/// Common interface for channel handlers so the plugin can clear their plugin
/// reference uniformly on detach, breaking the plugin→channel→handler→plugin
/// reference cycle while the engine is attached.
interface ShortcutHandler {
  /// Releases the held plugin reference. Safe to call multiple times.
  clear(): void;
}

class GetLaunchActionHandler implements ShortcutHandler {
  private _plugin: QuickActionsPlugin | null;

  constructor(plugin: QuickActionsPlugin) {
    this._plugin = plugin;
  }

  clear(): void {
    this._plugin = null;
  }

  onMessage(_message: Object | null, reply: Reply<Object>): void {
    const plugin: QuickActionsPlugin | null = this._plugin;
    if (plugin === null) {
      reply.reply([ERROR_CODE_GET_LAUNCH_ACTION, 'QuickActionsPlugin getLaunchAction failed: handler detached', null] as Object);
      return;
    }
    try {
      reply.reply([plugin.getLaunchActionValue()] as Object);
    } catch (error) {
      reply.reply([ERROR_CODE_GET_LAUNCH_ACTION, describeError('getLaunchAction', error), null] as Object);
    }
  }
}

class SetShortcutItemsHandler implements ShortcutHandler {
  private _plugin: QuickActionsPlugin | null;

  constructor(plugin: QuickActionsPlugin) {
    this._plugin = plugin;
  }

  clear(): void {
    this._plugin = null;
  }

  onMessage(message: Object | null, reply: Reply<Object>): void {
    const plugin: QuickActionsPlugin | null = this._plugin;
    if (plugin === null) {
      reply.reply([ERROR_CODE_SET_SHORTCUT_ITEMS, 'QuickActionsPlugin setShortcutItems failed: handler detached', null] as Object);
      return;
    }
    try {
      const args: Array<Object | null> = message as Array<Object | null>;
      if (args.length < 1) {
        reply.reply([ERROR_CODE_DECODE_SHORTCUT_ITEM, 'QuickActionsPlugin setShortcutItems failed: missing items argument', null] as Object);
        return;
      }
      // Each list element is already decoded into a ShortcutItemMessage by the
      // QuickActionsCodec (type 128) before this handler runs, so it must NOT be
      // decoded again — re-decoding an object would treat it as a malformed array.
      const rawItems: Array<Object | null> = args[0] as Array<Object | null>;
      const items: Array<ShortcutItemMessage> = [];
      for (const item of rawItems) {
        if (item === null) {
          reply.reply([ERROR_CODE_DECODE_SHORTCUT_ITEM, 'QuickActionsPlugin setShortcutItems failed: null ShortcutItemMessage', null] as Object);
          return;
        }
        items.push(item as ShortcutItemMessage);
      }
      plugin.setShortcutItems(items);
      // OHOS has no runtime dynamic-shortcut API; surface the platform limit as
      // an explicit warning instead of failing silently so callers can detect it.
      reply.reply([null] as Object);
    } catch (error) {
      reply.reply([ERROR_CODE_SET_SHORTCUT_ITEMS, describeError('setShortcutItems', error), null] as Object);
    }
  }
}

class ClearShortcutItemsHandler implements ShortcutHandler {
  private _plugin: QuickActionsPlugin | null;

  constructor(plugin: QuickActionsPlugin) {
    this._plugin = plugin;
  }

  clear(): void {
    this._plugin = null;
  }

  onMessage(_message: Object | null, reply: Reply<Object>): void {
    const plugin: QuickActionsPlugin | null = this._plugin;
    if (plugin === null) {
      reply.reply([ERROR_CODE_CLEAR_SHORTCUT_ITEMS, 'QuickActionsPlugin clearShortcutItems failed: handler detached', null] as Object);
      return;
    }
    try {
      plugin.clearShortcutItems();
      reply.reply([null] as Object);
    } catch (error) {
      reply.reply([ERROR_CODE_CLEAR_SHORTCUT_ITEMS, describeError('clearShortcutItems', error), null] as Object);
    }
  }
}

/**
 * QuickActionsPlugin implements Flutter quick actions for OpenHarmony.
 *
 * This plugin handles setting, clearing, and launching shortcut items
 * on the OpenHarmony platform.
 *
 * Threading note: the static fields `_instance` and `_pendingLaunchAction`,
 * as well as the instance state, are only accessed on the Flutter platform/UI
 * thread (engine lifecycle callbacks and `dispatchShortcutAction` invoked from
 * the Ability all run on that thread). No explicit locking is therefore
 * required; if a future change introduces worker-thread access, guard these
 * fields accordingly.
 */
export default class QuickActionsPlugin implements FlutterPlugin {
  private static _instance: QuickActionsPlugin | null = null;
  private static _pendingLaunchAction: string | null = null;

  private _getLaunchActionChannel: BasicMessageChannel<Object> | null = null;
  private _setShortcutItemsChannel: BasicMessageChannel<Object> | null = null;
  private _clearShortcutItemsChannel: BasicMessageChannel<Object> | null = null;
  private _flutterApiChannel: BasicMessageChannel<Object> | null = null;
  private _binding: FlutterPluginBinding | null = null;
  private _launchAction: string | null = null;
  private _shortcutItems: ShortcutItemMessage[] = [];
  // Retained so their plugin reference can be cleared on detach, breaking the
  // plugin→channel→handler→plugin reference cycle.
  private _handlers: ShortcutHandler[] = [];

  /**
   * Returns the singleton instance of QuickActionsPlugin.
   *
   * Must be called after the plugin has been attached to the engine.
   *
   * @returns The current plugin instance, or null if not attached.
   */
  static getInstance(): QuickActionsPlugin | null {
    return QuickActionsPlugin._instance;
  }

  /**
   * Returns the unique class name of this plugin.
   *
   * @returns The string 'QuickActionsPlugin'.
   */
  getUniqueClassName(): string {
    return 'QuickActionsPlugin';
  }

  /**
   * Attaches the plugin to the Flutter engine.
   *
   * Registers message handlers for all platform channels (getLaunchAction,
   * setShortcutItems, clearShortcutItems) and sets up the Flutter API channel
   * for sending launch actions back to Dart. Consumes any shortcut action that
   * arrived before attach (cold start).
   *
   * @param binding - The FlutterPluginBinding providing engine context.
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    QuickActionsPlugin._instance = this;
    this._binding = binding;
    const codec: QuickActionsCodec = new QuickActionsCodec();
    const messenger = binding.getBinaryMessenger();

    // Set up getLaunchAction channel
    const getLaunchActionHandler: GetLaunchActionHandler = new GetLaunchActionHandler(this);
    this._getLaunchActionChannel = new BasicMessageChannel(
      messenger,
      'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.getLaunchAction',
      codec
    );
    this._getLaunchActionChannel.setMessageHandler(getLaunchActionHandler);

    // Set up setShortcutItems channel
    const setShortcutItemsHandler: SetShortcutItemsHandler = new SetShortcutItemsHandler(this);
    this._setShortcutItemsChannel = new BasicMessageChannel(
      messenger,
      'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.setShortcutItems',
      codec
    );
    this._setShortcutItemsChannel.setMessageHandler(setShortcutItemsHandler);

    // Set up clearShortcutItems channel
    const clearShortcutItemsHandler: ClearShortcutItemsHandler = new ClearShortcutItemsHandler(this);
    this._clearShortcutItemsChannel = new BasicMessageChannel(
      messenger,
      'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsApi.clearShortcutItems',
      codec
    );
    this._clearShortcutItemsChannel.setMessageHandler(clearShortcutItemsHandler);

    this._handlers = [getLaunchActionHandler, setShortcutItemsHandler, clearShortcutItemsHandler];

    // Set up the Flutter API channel for sending launch actions back to Dart
    this._flutterApiChannel = new BasicMessageChannel(
      messenger,
      'dev.flutter.pigeon.quick_actions_ohos.OhosQuickActionsFlutterApi.launchAction',
      StandardMessageCodec.INSTANCE
    );

    if (QuickActionsPlugin._pendingLaunchAction) {
      this._launchAction = QuickActionsPlugin._pendingLaunchAction;
      QuickActionsPlugin._pendingLaunchAction = null;
    }
  }

  /**
   * Detaches the plugin from the Flutter engine.
   *
   * Cancels all registered message handlers, breaks the handler→plugin
   * reference cycle, releases channel/engine references, and clears all
   * in-memory and static state so nothing lingers after detach.
   *
   * @param binding - The FlutterPluginBinding (unused, retained for interface compatibility).
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // 1. Cancel all message handlers.
    if (this._getLaunchActionChannel) {
      this._getLaunchActionChannel.setMessageHandler(null);
      this._getLaunchActionChannel = null;
    }
    if (this._setShortcutItemsChannel) {
      this._setShortcutItemsChannel.setMessageHandler(null);
      this._setShortcutItemsChannel = null;
    }
    if (this._clearShortcutItemsChannel) {
      this._clearShortcutItemsChannel.setMessageHandler(null);
      this._clearShortcutItemsChannel = null;
    }
    this._flutterApiChannel = null;
    this._binding = null;

    // 2. Break the handler→plugin reference cycle.
    for (const handler of this._handlers) {
      handler.clear();
    }
    this._handlers = [];

    // 3. Clear in-memory state.
    this._shortcutItems = [];
    this._launchAction = null;

    // 4. Clear static state.
    QuickActionsPlugin._instance = null;
    QuickActionsPlugin._pendingLaunchAction = null;
  }

  /**
   * Returns the currently recorded launch action value, consuming it.
   *
   * Mirrors the Android implementation's consume-on-read semantics
   * (intent.removeExtra(EXTRA_ACTION) after reading), so repeated
   * getLaunchAction() calls deliver the shortcut action only once.
   *
   * @returns The shortcut action string if one was recorded, or null if none. Subsequent
   *          calls return null until a new action is recorded.
   */
  getLaunchActionValue(): string | null {
    const action: string | null = this._launchAction;
    this._launchAction = null;
    return action;
  }

  /**
   * Records a shortcut action even if the plugin is not yet attached.
   *
   * This is required for cold starts where the EntryAbility receives the
   * launch Want before Flutter has created and registered the plugin.
   *
   * @param action - The shortcut action type string received from the launch Want.
   */
  static dispatchShortcutAction(action: string): void {
    if (QuickActionsPlugin._instance) {
      QuickActionsPlugin._instance.deliverShortcutAction(action);
      return;
    }
    QuickActionsPlugin._pendingLaunchAction = action;
  }

  /**
   * Sets the shortcut items for the application.
   *
   * Note: OHOS does not provide a public API for dynamic shortcuts like Android's
   * ShortcutManagerCompat.setDynamicShortcuts(). Shortcuts on OHOS must be configured
   * statically via shortcuts_config.json in resources/base/profile/, referenced by
   * the "ohos.ability.shortcuts" metadata in module.json5.
   *
   * This method stores the shortcut items for reference but cannot register them
   * dynamically with the system. Ensure your shortcuts_config.json matches the
   * items you intend to display.
   *
   * @param items - The shortcut items to store; each is a decoded ShortcutItemMessage.
   */
  setShortcutItems(items: ShortcutItemMessage[]): void {
    this._shortcutItems = items;
    // OHOS has no public API for dynamic shortcuts. Surface a runtime warning so
    // callers are aware the in-memory update has no system-side effect; the
    // actual home-screen shortcuts must still be declared in shortcuts_config.json.
    console.warn(`QuickActionsPlugin: setShortcutItems received ${items.length} item(s), ` +
      `but OHOS does not support runtime dynamic shortcuts. ` +
      `Configure static shortcuts via resources/base/profile/shortcuts_config.json instead.`);
  }

  /**
   * Clears all shortcut items.
   *
   * Note: This only clears the in-memory shortcut items. Static shortcuts configured via
   * shortcuts_config.json cannot be removed at runtime on OHOS. The launch action is
   * intentionally NOT cleared here, matching Android/iOS where clearing shortcuts does
   * not touch the pending launch action (its lifecycle is consume-on-read).
   */
  clearShortcutItems(): void {
    this._shortcutItems = [];
    // Mirrors setShortcutItems: warn that static shortcuts configured via
    // shortcuts_config.json cannot be removed at runtime on OHOS.
    console.warn('QuickActionsPlugin: clearShortcutItems cleared in-memory state only. ' +
      'Static shortcuts declared in shortcuts_config.json are not affected on OHOS.');
  }

  /**
   * Delivers a shortcut action to the Flutter side via the Flutter API channel.
   *
   * Records the action as the current launch action and, when the channel is
   * available, sends it to Dart. The send is wrapped in try-catch so a channel
   * failure cannot propagate out to the calling Ability.
   *
   * @param action - The shortcut action type string to deliver.
   */
  private deliverShortcutAction(action: string): void {
    this._launchAction = action;
    if (this._flutterApiChannel) {
      try {
        this._flutterApiChannel.send([action]);
      } catch (e) {
        console.error(`QuickActionsPlugin: deliverShortcutAction send failed: ${e}`);
      }
    }
  }

  /**
   * Handles a shortcut action by delivering it to the Flutter side.
   *
   * This is the public entry point mirroring `dispatchShortcutAction` for an
   * already-attached instance.
   *
   * @param action - The shortcut action type string to deliver.
   */
  handleShortcutAction(action: string): void {
    this.deliverShortcutAction(action);
  }
}