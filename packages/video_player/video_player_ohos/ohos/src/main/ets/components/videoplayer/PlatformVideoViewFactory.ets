// Copyright (c) 2026 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.

import common from '@ohos.app.ability.common';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import { VideoPlayer } from './VideoPlayer';
import { PlatformVideoView } from './PlatformVideoView';

const TAG = 'PlatformVideoViewFactory';

class PlatformViewCreateArgs {
  public playerId: number = -1;
  public source: string = '';
  public objectFit: string = 'contain';
  public looping: boolean = false;
  public speed: number = 1.0;
}

export class PlatformVideoViewFactory extends PlatformViewFactory {
  private playerLookup: (playerId: number) => VideoPlayer | null;

  constructor(playerLookup: (playerId: number) => VideoPlayer | null) {
    super(StandardMessageCodec.INSTANCE);
    this.playerLookup = playerLookup;
  }

  create(context: common.Context, viewId: number, args: ESObject): PlatformView {
    const parsed = parseCreateArgs(args);
    Log.i(TAG, 'create viewId=' + viewId + ' playerId=' + parsed.playerId);
    if (parsed.playerId < 0) {
      throw new Error('PlatformVideoView requires a playerId.');
    }
    const player = this.playerLookup(parsed.playerId);
    if (player == null) {
      throw new Error('Unable to find VideoPlayer: ' + parsed.playerId);
    }
    return new PlatformVideoView(player, parsed.playerId);
  }
}

function parseCreateArgs(args: ESObject): PlatformViewCreateArgs {
  const parsed = new PlatformViewCreateArgs();
  if (typeof args === 'number') {
    parsed.playerId = args as number;
    return parsed;
  }
  parsed.playerId = asNumber(readArg(args, 'playerId'), -1);
  parsed.source = asString(readArg(args, 'source'));
  const objectFit = asString(readArg(args, 'objectFit'));
  if (objectFit.length > 0) {
    parsed.objectFit = objectFit;
  }
  parsed.looping = asBool(readArg(args, 'looping'), false);
  parsed.speed = asNumber(readArg(args, 'speed'), 1.0);
  return parsed;
}

function readArg(args: ESObject, key: string): Object | undefined {
  if (args == null) {
    return undefined;
  }
  const maybeMap = args as Map<string, Object>;
  if (maybeMap != null && typeof maybeMap.get === 'function') {
    return maybeMap.get(key);
  }
  const rec = args as Record<string, Object>;
  return rec[key];
}

function asString(value: Object | undefined): string {
  return value == null ? '' : `${value}`;
}

function asNumber(value: Object | undefined, fallback: number): number {
  if (typeof value === 'number') {
    return value as number;
  }
  if (typeof value === 'string' && value.length > 0) {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function asBool(value: Object | undefined, fallback: boolean): boolean {
  if (typeof value === 'boolean') {
    return value as boolean;
  }
  return fallback;
}
