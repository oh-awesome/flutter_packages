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

import { describe, beforeAll, beforeEach, it, expect } from '@ohos/hypium';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import common from '@ohos.app.ability.common';
import PathUtils from '@ohos/flutter_ohos/src/main/ets/util/PathUtils';
import {
  BinaryMessenger,
  BinaryMessageHandler,
  BinaryReply,
  TaskQueue,
  TaskQueueOptions
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import SendableBinaryMessageHandler from '@ohos/flutter_ohos/src/main/ets/plugin/common/SendableBinaryMessageHandler';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import {
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { PathProviderApi, StorageDirectory } from '../../../main/ets/io/flutter/plugins/pathprovider/Messages';
import PathProviderPlugin from '../../../main/ets/io/flutter/plugins/pathprovider/PathProviderPlugin';

class FakeBinaryMessenger implements BinaryMessenger {
  handlers: Map<string, BinaryMessageHandler | null> = new Map();

  makeBackgroundTaskQueue(options?: TaskQueueOptions): TaskQueue {
    return {} as TaskQueue;
  }

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | SendableBinaryMessageHandler | null,
    taskQueue?: TaskQueue, ...args: Object[]): void {
    this.handlers.set(channel.toString(), handler as BinaryMessageHandler | null);
  }

  getHandler(channel: string): BinaryMessageHandler | null | undefined {
    return this.handlers.get(channel);
  }
}

class FakeFlutterPluginBinding {
  private messenger: BinaryMessenger;
  private context: common.Context;

  constructor(messenger: BinaryMessenger, context: common.Context) {
    this.messenger = messenger;
    this.context = context;
  }

  getBinaryMessenger(): BinaryMessenger {
    return this.messenger;
  }

  getApplicationContext(): common.Context {
    return this.context;
  }
}

function invokeChannel(messenger: FakeBinaryMessenger, channel: string, message: Object | null): Object | null {
  const handler: BinaryMessageHandler | null | undefined = messenger.getHandler(channel);
  expect(handler !== null && handler !== undefined).assertTrue();
  const codec: MessageCodec<Object> = PathProviderApi.getCodec() as MessageCodec<Object>;
  let decoded: Object | null = null;
  const encoded: ArrayBuffer = codec.encodeMessage(message);
  const replyCallback: BinaryReply = {
    reply: (reply: ArrayBuffer | null): void => {
      decoded = codec.decodeMessage(reply) as Object | null;
    }
  };
  handler!.onMessage(encoded, replyCallback);
  return decoded;
}

function firstReplyValue(result: Object | null): Object | null {
  if (result === null) {
    return null;
  }
  const arr: Array<Object> = result as Array<Object>;
  return arr[0];
}

export default function pathProviderPluginTest() {
  describe('PathProviderPluginTest', () => {
    let plugin: PathProviderPlugin;

    beforeEach(() => {
      plugin = new PathProviderPlugin();
    });

    it('getUniqueClassName_should_return_correct_value', 0, () => {
      expect(plugin.getUniqueClassName()).assertEqual('PathProviderPlugin');
    });

    it('registerWith_doesNotThrow', 0, () => {
      PathProviderPlugin.registerWith();
      expect(true).assertTrue();
    });

    it('getTemporaryPath_should_return_empty_string_without_context', 0, () => {
      expect(plugin.getTemporaryPath()).assertEqual('');
    });

    it('getApplicationSupportPath_should_return_empty_string_without_context', 0, () => {
      expect(plugin.getApplicationSupportPath()).assertEqual('');
    });

    it('getApplicationDocumentsPath_should_return_empty_string_without_context', 0, () => {
      expect(plugin.getApplicationDocumentsPath()).assertEqual('');
    });

    it('getApplicationCachePath_should_return_empty_string_without_context', 0, () => {
      expect(plugin.getApplicationCachePath()).assertEqual('');
    });

    it('getExternalStoragePath_should_return_empty_string_without_context', 0, () => {
      expect(plugin.getExternalStoragePath()).assertEqual('');
    });

    it('getExternalCachePaths_should_return_empty_array_without_context', 0, () => {
      expect(plugin.getExternalCachePaths().length).assertEqual(0);
    });

    it('getExternalStoragePaths_music_should_return_empty_array_without_context', 0, () => {
      expect(plugin.getExternalStoragePaths(StorageDirectory.MUSIC).length).assertEqual(0);
    });

    it('channel_returns_empty_paths_without_context', 0, () => {
      const messenger: FakeBinaryMessenger = new FakeBinaryMessenger();
      PathProviderApi.setup(messenger, plugin);

      const temporary: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getTemporaryPath', null);
      expect(firstReplyValue(temporary) as string).assertEqual('');

      const support: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getApplicationSupportPath', null);
      expect(firstReplyValue(support) as string).assertEqual('');

      const externalCache: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getExternalCachePaths', null);
      const cachePaths: Array<string> = firstReplyValue(externalCache) as Array<string>;
      expect(cachePaths.length).assertEqual(0);
    });

    it('onAttachedToAbility_doesNotThrow', 0, () => {
      plugin.onAttachedToAbility({} as AbilityPluginBinding);
      expect(plugin.getUniqueClassName()).assertEqual('PathProviderPlugin');
    });

    it('onDetachedFromAbility_doesNotThrow_without_context', 0, () => {
      plugin.onDetachedFromAbility();
      expect(plugin.getUniqueClassName()).assertEqual('PathProviderPlugin');
    });
  });

  describe('PathProviderPluginWithContextTest', () => {
    let plugin: PathProviderPlugin;
    let context: common.Context;
    let messenger: FakeBinaryMessenger;

    beforeAll(() => {
      const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
      context = delegator.getAppContext() as common.Context;
    });

    beforeEach(() => {
      plugin = new PathProviderPlugin(context);
      messenger = new FakeBinaryMessenger();
    });

    it('getTemporaryPath_should_return_cacheDir_with_context', 0, () => {
      expect(plugin.getTemporaryPath()).assertEqual(context.cacheDir);
    });

    it('getApplicationCachePath_should_return_cacheDir_with_context', 0, () => {
      expect(plugin.getApplicationCachePath()).assertEqual(context.cacheDir);
    });

    it('getApplicationDocumentsPath_should_return_dataDirectory_with_context', 0, () => {
      const expected = PathUtils.getDataDirectory(context) ?? '';
      expect(plugin.getApplicationDocumentsPath()).assertEqual(expected);
    });

    it('getApplicationSupportPath_should_return_filesDir_from_PathUtils', 0, () => {
      expect(plugin.getApplicationSupportPath()).assertEqual(PathUtils.getFilesDir(context));
    });

    it('getExternalCachePaths_should_return_array_with_cacheDir', 0, () => {
      const paths = plugin.getExternalCachePaths();
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.cacheDir);
    });

    it('getExternalStoragePath_should_return_filesDir', 0, () => {
      expect(plugin.getExternalStoragePath()).assertEqual(context.filesDir);
    });

    it('getExternalStoragePaths_root_should_return_filesDir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.ROOT);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir);
    });

    it('getExternalStoragePaths_music_should_return_music_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.MUSIC);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/music');
    });

    it('getExternalStoragePaths_existing_music_dir_returns_path', 0, () => {
      // First call may create the directory; second call hits the accessible branch.
      plugin.getExternalStoragePaths(StorageDirectory.MUSIC);
      const paths = plugin.getExternalStoragePaths(StorageDirectory.MUSIC);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/music');
    });

    it('getExternalStoragePaths_podcasts_should_return_podcasts_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.PODCASTS);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/podcasts');
    });

    it('getExternalStoragePaths_ringtones_should_return_ringtones_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.RINGTONES);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/ringtones');
    });

    it('getExternalStoragePaths_alarms_should_return_alarms_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.ALARMS);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/alarms');
    });

    it('getExternalStoragePaths_notifications_should_return_notifications_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.NOTIFICATIONS);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/notifications');
    });

    it('getExternalStoragePaths_pictures_should_return_pictures_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.PICTURES);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/pictures');
    });

    it('getExternalStoragePaths_movies_should_return_movies_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.MOVIES);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/movies');
    });

    it('getExternalStoragePaths_downloads_should_return_downloads_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.DOWNLOADS);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/downloads');
    });

    it('getExternalStoragePaths_dcim_should_return_dcim_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.DCIM);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/dcim');
    });

    it('getExternalStoragePaths_documents_should_return_documents_subdir', 0, () => {
      const paths = plugin.getExternalStoragePaths(StorageDirectory.DOCUMENTS);
      expect(paths.length).assertEqual(1);
      expect(paths[0]).assertEqual(context.filesDir + '/documents');
    });

    it('getExternalStoragePaths_unrecognized_directory_throws', 0, () => {
      let threw = false;
      try {
        plugin.getExternalStoragePaths(999 as StorageDirectory);
      } catch (err) {
        threw = true;
        expect(`${err}`.indexOf('Unrecognized directory') >= 0).assertTrue();
      }
      expect(threw).assertTrue();
    });

    it('channel_handles_all_path_methods_with_real_context', 0, () => {
      plugin.setup(messenger, context);

      const temporary: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getTemporaryPath', null);
      expect(firstReplyValue(temporary) as string).assertEqual(context.cacheDir);

      const support: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getApplicationSupportPath', null);
      expect(firstReplyValue(support) as string).assertEqual(PathUtils.getFilesDir(context));

      const documents: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getApplicationDocumentsPath', null);
      expect(firstReplyValue(documents) as string).assertEqual(PathUtils.getDataDirectory(context) ?? '');

      const cache: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getApplicationCachePath', null);
      expect(firstReplyValue(cache) as string).assertEqual(context.cacheDir);

      const external: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getExternalStoragePath', null);
      expect(firstReplyValue(external) as string).assertEqual(context.filesDir);

      const externalCache: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getExternalCachePaths', null);
      const cachePaths: Array<string> = firstReplyValue(externalCache) as Array<string>;
      expect(cachePaths.length).assertEqual(1);
      expect(cachePaths[0]).assertEqual(context.cacheDir);

      const args: Array<Object> = [StorageDirectory.MUSIC];
      const externalStorage: Object | null = invokeChannel(
        messenger,
        'dev.flutter.pigeon.PathProviderApi.getExternalStoragePaths',
        args
      );
      const storagePaths: Array<string> = firstReplyValue(externalStorage) as Array<string>;
      expect(storagePaths.length).assertEqual(1);
      expect(storagePaths[0]).assertEqual(context.filesDir + '/music');
    });

    it('channel_setup_null_api_clears_handlers', 0, () => {
      plugin.setup(messenger, context);
      PathProviderApi.setup(messenger, null);
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getTemporaryPath')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getApplicationSupportPath')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getApplicationDocumentsPath')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getApplicationCachePath')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getExternalStoragePath')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getExternalCachePaths')).assertNull();
      expect(messenger.getHandler('dev.flutter.pigeon.PathProviderApi.getExternalStoragePaths')).assertNull();
    });

    it('channel_getExternalStoragePaths_unrecognized_directory_returns_wrapped_error', 0, () => {
      plugin.setup(messenger, context);
      const args: Array<Object> = [999 as StorageDirectory];
      const result: Object | null = invokeChannel(
        messenger,
        'dev.flutter.pigeon.PathProviderApi.getExternalStoragePaths',
        args
      );
      const wrapped: Array<ESObject> = result as Array<ESObject>;
      expect(wrapped.length).assertEqual(3);
      expect(`${wrapped[1]}`.indexOf('Unrecognized directory') >= 0).assertTrue();
    });

    it('channel_getExternalStoragePaths_null_directory_returns_wrapped_error', 0, () => {
      plugin.setup(messenger, context);
      const args: Array<Object | null> = [null];
      const result: Object | null = invokeChannel(
        messenger,
        'dev.flutter.pigeon.PathProviderApi.getExternalStoragePaths',
        args as Object
      );
      const wrapped: Array<ESObject> = result as Array<ESObject>;
      expect(wrapped.length).assertEqual(3);
      expect(`${wrapped[1]}`.indexOf('Unrecognized directory') >= 0).assertTrue();
    });

    it('onAttachedToEngine_and_onDetachedFromEngine_lifecycle', 0, () => {
      const binding: FlutterPluginBinding =
        new FakeFlutterPluginBinding(messenger, context) as Object as FlutterPluginBinding;
      plugin.onAttachedToEngine(binding);
      expect(messenger.handlers.get('dev.flutter.pigeon.PathProviderApi.getTemporaryPath') !== null).assertTrue();

      const temporary: Object | null =
        invokeChannel(messenger, 'dev.flutter.pigeon.PathProviderApi.getTemporaryPath', null);
      expect(firstReplyValue(temporary) as string).assertEqual(context.cacheDir);

      plugin.onDetachedFromEngine(binding);
      expect(messenger.handlers.get('dev.flutter.pigeon.PathProviderApi.getTemporaryPath')).assertNull();
      expect(plugin.getTemporaryPath()).assertEqual('');
    });

    it('onDetachedFromAbility_doesNotThrow', 0, () => {
      plugin.onDetachedFromAbility();
      expect(plugin.getUniqueClassName()).assertEqual('PathProviderPlugin');
    });

    it('onAttachedToAbility_doesNotThrow_with_context', 0, () => {
      plugin.onAttachedToAbility({} as AbilityPluginBinding);
      expect(plugin.getUniqueClassName()).assertEqual('PathProviderPlugin');
    });
  });
}
