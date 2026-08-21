// Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { FlutterPlugin, FlutterPluginBinding} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { FlutterRenderer } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/renderer/FlutterRenderer';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { VideoPlayer } from './VideoPlayer';
import { VideoPlayerApi } from './VideoPlayerApi';
import { CommonConstants } from './constants/CommonConstants';
import { CreateMessage, wrapError, OhosVideoPlayerApi, PlatformVideoViewType, FlutterError } from './Messages';
import { PlayerModel } from './PlayerModel';
import HashMap from '@ohos.util.HashMap';
import { VideoPlayerApiCodec } from './VideoPlayerApiCodec';
import { FlutterState } from './VideoPlayerPlugin';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
import { media } from '@kit.MediaKit';
import { EventChannel } from '@ohos/flutter_ohos';
import { GlobalContext } from './util/GlobalContext';
import { window } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';

const TAG: string = 'VideoPlayerApiImpl';
const BLACK_COLOR = 0xFF000000;

function mapPlaybackSpeed(speed: number): media.PlaybackSpeed {
  if (speed > 0 && speed <= 0.125) {
    //x0.125
    return media.PlaybackSpeed.SPEED_FORWARD_0_125_X;
  } else if (speed > 0.125 && speed <= 0.4) {
    //x0.25
    return media.PlaybackSpeed.SPEED_FORWARD_0_25_X;
  } else if (speed > 0.4 && speed <= 0.6) {
    //x0.5
    return media.PlaybackSpeed.SPEED_FORWARD_0_50_X;
  } else if (speed > 0.6 && speed <= 0.8) {
    //x0.75
    return media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
  } else if (speed > 0.8 && speed <= 1.1) {
    //x1
    return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  } else if (speed > 1.1 && speed <= 1.4) {
    //x1.25
    return media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
  } else if (speed > 1.4 && speed <= 1.6) {
    //x1.5
    return media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
  } else if (speed > 1.6 && speed <= 1.8) {
    //x1.75
    return media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
  } else if (speed > 1.8 && speed <= 2.0) {
    //x2.0
    return media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
  } else if (speed > 2.0) {
    return media.PlaybackSpeed.SPEED_FORWARD_3_00_X;
  }
  return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
}

function illegalStateException(message: string): Error {
  const err = new Error(message);
  err.name = 'IllegalStateException';
  return err;
}

/**
 * 校验 Pigeon 通道消息参数：msg 必须为数组且包含至少 expectedCount 个非空元素，
 * 避免 `as number` 等强转产生 undefined 继而污染下游调用链。
 */
function requireChannelArgs(msg: Object, methodName: string, expectedCount: number): Array<Object> {
  if (!Array.isArray(msg)) {
    throw illegalStateException(`Invalid arguments for ${methodName}: expected an array`);
  }
  const args = msg as Array<Object>;
  if (args.length < expectedCount) {
    throw illegalStateException(`Invalid arguments for ${methodName}: expected ${expectedCount}, got ${args.length}`);
  }
  for (let i = 0; i < expectedCount; i++) {
    if (args[i] === null || args[i] === undefined) {
      throw illegalStateException(`Invalid arguments for ${methodName}: argument ${i} is null`);
    }
  }
  return args;
}

export class VideoPlayerApiImpl extends OhosVideoPlayerApi{
  private videoPlayers: HashMap<number, VideoPlayer> = new HashMap<number, VideoPlayer>();
  private flutterState: FlutterState | null = null;
  private binding: AbilityPluginBinding | null = null;
  private audioFocus: boolean = false;
  private pixelMaps: HashMap<string, image.PixelMap> = new HashMap();

  constructor(flutterState: FlutterState | null, binding: AbilityPluginBinding | null) {
    super();
    this.flutterState = flutterState;
    this.binding = binding;
  }

  disposeAllPlayers(): void {
    this.videoPlayers.forEach((videoPlayer, key) => {
      const releasePromise = videoPlayer?.release();
      if (releasePromise) {
        releasePromise.then(() => {
          if (this.flutterState) {
            this.flutterState.getTextureRegistry().unregisterTexture(key);
          }
        }, () => {
          if (this.flutterState) {
            this.flutterState.getTextureRegistry().unregisterTexture(key);
          }
        });
      } else {
        if (this.flutterState) {
          this.flutterState.getTextureRegistry().unregisterTexture(key);
        }
      }
      if (key !== undefined) {
        this.pixelMapReleaseById(key);
      }
    });
    this.videoPlayers.clear();
    this.pixelMapRelease();
    GlobalContext.getContext().clear();
  }

  initialize(): void {
    Log.i(TAG, 'enter initialize')
    this.disposeAllPlayers();
  }

  detach(): void {
    Log.i(TAG, 'enter detach')
    this.disposeAllPlayers();
  }

  getContext(): common.UIAbilityContext {
    if (this.binding == null) {
      throw Error('Illegal binding or context state.');
    }
    return this.binding.getAbility().context;
  }

  async createBlackPixelMap(width: number, height: number): Promise<image.PixelMap> {
    const pixels32 = new Uint32Array(width * height);
    pixels32.fill(BLACK_COLOR);
    const opts: image.InitializationOptions = {
      editable: true,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      size: { width, height }
    };
    return image.createPixelMap(pixels32.buffer, opts);
  }

  async create(arg: CreateMessage): Promise<number> {
    let windowClass: window.Window;
    try {
      windowClass = await window.getLastWindow(this.getContext());
    } catch (e) {
      throw new Error(`getLastWindow failed: ${e}`);
    }
    GlobalContext.getContext().setObject('windowClass', windowClass)
    Log.i(TAG, 'enter create');
    if (this.flutterState == null) {
      throw new Error('Illegal flutterState null.');
    }
    let playerModel = new PlayerModel();
    let flutterRenderer = this.flutterState.getTextureRegistry();
    let uri: string = arg.getUri();
    let asset: string = arg.getAsset();
     // packaged asset 的实际资源路径为 packages/<packageName>/<asset>，与 Android 对齐。
    const packageName: string | null = arg.getPackageName()?.toString() || null;
    const assetKey: string = asset != null && packageName != null
      ? `packages/${packageName}/${asset}`
      : asset;
    // backBufferDurationMs：OHOS 暂不支持，忽略即可。
    const backBufferDurationMs = arg.getBackBufferDurationMs();
    if (backBufferDurationMs != null) {
      Log.i(TAG, 'create with backBufferDurationMs=' + backBufferDurationMs + ' (not supported on OHOS)');
    }
    let header: Record<string, string> | null = null;
    arg.getHttpHeaders().forEach((value, key) => {
      if (!header) {
        header = {}
      }
      header[key.toString()] = value.toString();
    })
    let textureId: number = flutterRenderer.getTextureId();
    let playerId: number = textureId;
    Log.i(TAG, 'enter getRawFd, textureId=' + textureId);
    let videoPlayer: VideoPlayer | null = null;
    try {
      let surfaceTextureEntry: SurfaceTextureEntry = flutterRenderer.registerTexture(textureId);
      let windowProperties = windowClass.getWindowProperties();
      const width = windowProperties.windowRect.width;
      const height = windowProperties.windowRect.height;
      // 背景帧 PixelMap 同样纳入 pixelMaps 追踪，保证失败/替换路径均可显式释放。
      const blackPixelMap = await this.createBlackPixelMap(width, height);
      this.pixelMaps.set(textureId.toString(), blackPixelMap);
      flutterRenderer.setTextureBackGroundPixelMap(textureId, blackPixelMap);
      if (asset != null) {
        Log.i(TAG, 'asset create called, asset is' + asset);
        let avMetaExtractor: media.AVMetadataExtractor | null = null;
        let avImageGenerator: media.AVImageGenerator | null = null;
        try {
          avMetaExtractor = await media.createAVMetadataExtractor();
          avMetaExtractor.fdSrc = await this.getContext().resourceManager.getRawFd('flutter_assets/' + assetKey);
          let mateData = await avMetaExtractor.fetchMetadata();
          if (mateData.hasVideo == CommonConstants.YES) {
            avImageGenerator = await media.createAVImageGenerator();
            Log.i(TAG, 'asset video create');
            avImageGenerator.fdSrc = await this.getContext().resourceManager.getRawFd('flutter_assets/' + assetKey);
            let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
              width: -1,
              height: -1
            });
            // 显式释放被首帧替换的黑色背景 PixelMap，避免覆盖路径泄漏原生位图。
            this.releaseSupersededPixelMap(textureId);
            this.pixelMaps.set(textureId.toString(), pixelMap);
            flutterRenderer.setTextureBackGroundPixelMap(textureId, this.pixelMaps.get(textureId.toString()));
          }
        } finally {
          avImageGenerator?.release();
          avImageGenerator = null;
          avMetaExtractor?.release();
          avMetaExtractor = null;
        }
      } else if (uri != null && uri.startsWith('fd://')) {
        Log.i(TAG, 'local create called, file is' + uri);
        let avMetaExtractor: media.AVMetadataExtractor | null = null;
        let avImageGenerator: media.AVImageGenerator | null = null;
        try {
          avMetaExtractor = await media.createAVMetadataExtractor();
          avMetaExtractor.fdSrc = {
            fd: Number.parseInt(uri.replace('fd://', ''))
          };
          let mateData = await avMetaExtractor.fetchMetadata();
          if (mateData.hasVideo == CommonConstants.YES) {
            avImageGenerator = await media.createAVImageGenerator();
            Log.i(TAG, 'local video create');
            avImageGenerator.fdSrc = {
              fd: Number.parseInt(uri.replace('fd://', ''))
            };
            let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
              width: -1,
              height: -1
            });
            // 显式释放被首帧替换的黑色背景 PixelMap，避免覆盖路径泄漏原生位图。
            this.releaseSupersededPixelMap(textureId);
            this.pixelMaps.set(textureId.toString(), pixelMap);
            flutterRenderer.setTextureBackGroundPixelMap(textureId, this.pixelMaps.get(textureId.toString()));
          }
        } finally {
          avImageGenerator?.release();
          avImageGenerator = null;
          avMetaExtractor?.release();
          avMetaExtractor = null;
        }
      }
      let eventChannel: EventChannel = new EventChannel(this.flutterState.getBinaryMessenger(), 'flutter.io/videoPlayer/videoEvents' + textureId.toString());
      if (asset != null) {
        let rawFileDescriptor: resourceManager.RawFileDescriptor = await this.getContext().resourceManager.getRawFd('flutter_assets/' + assetKey);
        videoPlayer = new VideoPlayer(playerModel, surfaceTextureEntry, rawFileDescriptor, null, eventChannel, this.audioFocus, null);
      } else if (uri != null) {
        videoPlayer = new VideoPlayer(playerModel, surfaceTextureEntry, null, uri, eventChannel, this.audioFocus, header);
      } else {
        throw new Error('Invalid video source');
      }
      this.videoPlayers.set(playerId, videoPlayer);
      await videoPlayer.createAVPlayer();
      
      Log.i(TAG, `The player was created successfully,ID: ${playerId}`);
      return playerId;
    } catch (e) {
      // 创建失败时清理已分配资源（纹理、PixelMap、AVPlayer），避免泄漏。
      Log.e(TAG, 'create failed, clean up resources. error=' + e);
      try {
        flutterRenderer.unregisterTexture(playerId);
      } catch (cleanupErr) {
        Log.w(TAG, 'unregisterTexture failed during cleanup: ' + cleanupErr);
      }
      this.pixelMapReleaseById(playerId);
      if (videoPlayer) {
        try {
          await videoPlayer.release();
        } catch (releaseErr) {
          Log.w(TAG, 'release failed during cleanup: ' + releaseErr);
        }
        this.videoPlayers.remove(playerId);
      }
      if (e instanceof Error) {
        throw e;
      }
      throw new Error(`${e}`);
    }
  }

  pixelMapRelease() {
    for (let pixelMap of this.pixelMaps.values()) {
      if (pixelMap && typeof pixelMap.release === 'function') {
        pixelMap.release();
      }
    }
    this.pixelMaps.clear();
  }

  /**
   * 释放指定播放器对应的 PixelMap（以 textureId/playerId 为 key）。
   */
  pixelMapReleaseById(playerId: number) {
    const key = playerId.toString();
    const pixelMap = this.pixelMaps.get(key);
    if (pixelMap && typeof pixelMap.release === 'function') {
      pixelMap.release();
    }
    this.pixelMaps.remove(key);
  }

  /**
   * 释放即将被新 PixelMap 替换的旧背景帧（如黑色背景被视频首帧覆盖）。
   * 仅 release 不删 entry，随后调用方会以新帧覆盖同 key。
   */
  releaseSupersededPixelMap(textureId: number) {
    const key = textureId.toString();
    const pixelMap = this.pixelMaps.get(key);
    if (pixelMap && typeof pixelMap.release === 'function') {
      pixelMap.release();
    }
  }

  async dispose(playerId:number): Promise<void> {
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      try {
        // 等待 release 完成后再释放纹理，避免异步释放未完成时的竞态。
        await videoPlayer.release();
      } finally {
        if (this.flutterState) {
          this.flutterState.getTextureRegistry().unregisterTexture(playerId);
        }
        // 释放并删除该播放器对应的 PixelMap，避免内存泄漏。
        this.pixelMapReleaseById(playerId);
        this.videoPlayers.remove(playerId);
        // 所有播放器释放后不再持有窗口引用，避免静态单例长期持有 window.Window。
        if (this.videoPlayers.length === 0) {
          GlobalContext.getContext().removeObject('windowClass');
        }
        Log.i(TAG, `Release player resources: ${playerId}`);
      }
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  setLooping(playerId: number, looping: boolean) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'setLooping, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      videoPlayer.setLooping(looping);
      Log.d(TAG, `Set up the player: ${playerId} loop: ${looping}`);
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  setVolume(playerId: number, volume: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'setVolume, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      videoPlayer.setVolume(volume);
      Log.d(TAG, `Set up the player: ${playerId} volume: ${volume}`);
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  setPlaybackSpeed(playerId: number, speed: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'setPlaybackSpeed, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      const enumSpeed = mapPlaybackSpeed(speed);
      videoPlayer.setSpeed(enumSpeed);
      Log.d(TAG, `Set up the player: ${playerId} speed: ${speed}`);
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  play(playerId: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'play, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer != null) {
      videoPlayer.play();
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  position(playerId: number): number {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'position, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      const position = videoPlayer.getPosition();
      Log.d(TAG, `get the player,id=${playerId} position: ${position}`);
      return position;
    }
    throw illegalStateException(`No player found with playerId <${playerId}>`);
  }

  seekTo(playerId: number, position: number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'seekTo, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      videoPlayer.seekTo(position);
      Log.d(TAG, `videoPlayer,id=${playerId} seekTo: ${position}`);
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  pause(playerId:number) {
    const videoPlayer = this.videoPlayers.get(playerId);
    Log.d(TAG, 'pause, id=' + playerId + ', videoPlayer=' + videoPlayer);
    if (videoPlayer) {
      videoPlayer.pause();
      Log.d(TAG, `Pause: ${playerId}`);
    } else {
      throw illegalStateException(`No player found with playerId <${playerId}>`);
    }
  }

  setMixWithOthers(mixWithOthers: boolean) {
    Log.d(TAG, 'set MixWithOthers:' + mixWithOthers);
    this.audioFocus = mixWithOthers;
     this.videoPlayers.forEach((videoPlayer:VideoPlayer) => {
      videoPlayer.setAudioFocus(mixWithOthers);
    });
  }

  setKeepScreenOn(playerId: number, keepScreenOn: boolean): void {
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      videoPlayer.setKeepScreenOnDuringPlayback(keepScreenOn);
    } else {
      Log.w(TAG, `setKeepScreenOn: The player does not exist: ${playerId}`);
    }
  }

  async getAudioTracks(playerId: number): Promise<Array<Map<string, string | number | boolean | null>>> {
    if (playerId < 0) {
      return [];
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      return await videoPlayer.getAudioTracks();
    }
    throw illegalStateException(`No player found with playerId <${playerId}>`);
  }

  async selectAudioTrack(playerId: number, groupIndex: number, trackIndex: number): Promise<void> {
    if (playerId < 0) {
      return;
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      await videoPlayer.selectAudioTrack(groupIndex, trackIndex);
      return;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
  }

  async getVideoTracks(playerId: number): Promise<Array<Map<string, string | number | boolean | null>>> {
    if (playerId < 0) {
      return [];
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      return await videoPlayer.getVideoTracks();
    }
    throw illegalStateException(`No player found with playerId <${playerId}>`);
  }

  async selectVideoTrack(playerId: number, groupIndex: number, trackIndex: number): Promise<void> {
    if (playerId < 0) {
      return;
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      await videoPlayer.selectVideoTrack(groupIndex, trackIndex);
      return;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
  }

  async enableAutoVideoQuality(playerId: number): Promise<void> {
    if (playerId < 0) {
      return;
    }
    const videoPlayer = this.videoPlayers.get(playerId);
    if (videoPlayer) {
      await videoPlayer.enableAutoVideoQuality();
      return;
    }
    Log.w(TAG, `The player does not exist: ${playerId}`);
  }

  setup(binaryMessenger: BinaryMessenger): void {
    Log.i(TAG, '设置消息通道处理程序');
    
    // 为每个方法设置消息通道
    this.setupInitializeChannel(binaryMessenger);
    this.setupCreateChannel(binaryMessenger);
    this.setupDisposeChannel(binaryMessenger);
    this.setupSetLoopingChannel(binaryMessenger);
    this.setupSetVolumeChannel(binaryMessenger);
    this.setupSetPlaybackSpeedChannel(binaryMessenger);
    this.setupPlayChannel(binaryMessenger);
    this.setupPositionChannel(binaryMessenger);
    this.setupSeekToChannel(binaryMessenger);
    this.setupPauseChannel(binaryMessenger);
    this.setupSetMixWithOthersChannel(binaryMessenger);
    this.setupGetAudioTracksChannel(binaryMessenger);
    this.setupSelectAudioTrackChannel(binaryMessenger);
    this.setupGetVideoTracksChannel(binaryMessenger);
    this.setupSelectVideoTrackChannel(binaryMessenger);
    this.setupEnableAutoVideoQualityChannel(binaryMessenger);
  }

  teardown(binaryMessenger: BinaryMessenger): void {
    const codec = OhosVideoPlayerApi.getCodec();
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.initialize', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.create', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.dispose', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setLooping', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setVolume', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setPlaybackSpeed', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.play', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.position', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.seekTo', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.pause', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setMixWithOthers', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getAudioTracks', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectAudioTrack', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getVideoTracks', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectVideoTrack', codec).setMessageHandler(null);
    new BasicMessageChannel<Object>(binaryMessenger, 'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.enableAutoVideoQuality', codec).setMessageHandler(null);
  }

  // 初始化通道设置
  private setupInitializeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.initialize', 
      OhosVideoPlayerApi.getCodec() // 使用抽象类的编解码器
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          this.initialize();
          // 返回空数组表示成功，无返回值
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 创建通道设置
  private setupCreateChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.create', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'create', 1);
          const createMsg = args[0] as CreateMessage;
          this.create(createMsg).then((playerId: number) => {
            // 返回包含playerId的数组
            reply.reply([playerId]);
          }).catch((err:Error) => {
            reply.reply(wrapError(err));
          });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 释放通道设置
  private setupDisposeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.dispose', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'dispose', 1);
          const playerId = args[0] as number;

          this.dispose(playerId).then(() => {
            // 返回空数组表示成功
            reply.reply([]);
          }).catch((err: Error) => {
            reply.reply(wrapError(err));
          });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 设置循环播放通道
  private setupSetLoopingChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setLooping', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'setLooping', 2);
          const playerId = args[0] as number;
          const looping = args[1] as boolean;

          this.setLooping(playerId, looping);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 设置音量通道
  private setupSetVolumeChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setVolume', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'setVolume', 2);
          const playerId = args[0] as number;
          const volume = args[1] as number;

          this.setVolume(playerId, volume);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 设置播放速度通道
  private setupSetPlaybackSpeedChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setPlaybackSpeed', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'setPlaybackSpeed', 2);
          const playerId = args[0] as number;
          const speed = args[1] as number;

          this.setPlaybackSpeed(playerId, speed);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 播放通道
  private setupPlayChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.play', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'play', 1);
          const playerId = args[0] as number;

          this.play(playerId);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 获取位置通道
  private setupPositionChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.position', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'position', 1);
          const playerId = args[0] as number;

          const position = this.position(playerId);
          // 返回包含位置的数组
          reply.reply([position]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 跳转通道
  private setupSeekToChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.seekTo', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'seekTo', 2);
          const playerId = args[0] as number;
          const position = args[1] as number;

          this.seekTo(playerId, position);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 暂停通道
  private setupPauseChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.pause', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'pause', 1);
          const playerId = args[0] as number;

          this.pause(playerId);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }
  
  // 设置音频混合通道
  private setupSetMixWithOthersChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger, 
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.setMixWithOthers', 
      OhosVideoPlayerApi.getCodec()
    );
    
    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'setMixWithOthers', 1);
          const mixWithOthers = args[0] as boolean;

          this.setMixWithOthers(mixWithOthers);
          // 返回空数组表示成功
          reply.reply([]);
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 获取音轨通道
  private setupGetAudioTracksChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getAudioTracks',
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'getAudioTracks', 1);
          const playerId = args[0] as number;
          this.getAudioTracks(playerId)
            .then((tracks: Array<Map<string, string | number | boolean | null>>) => {
              reply.reply([tracks]);
            })
            .catch((err: Error) => {
              reply.reply(wrapError(err));
            });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 选择音轨通道
  private setupSelectAudioTrackChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectAudioTrack',
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'selectAudioTrack', 3);
          const playerId = args[0] as number;
          const groupIndex = args[1] as number;
          const trackIndex = args[2] as number;
          this.selectAudioTrack(playerId, groupIndex, trackIndex)
            .then(() => {
              reply.reply([]);
            })
            .catch((err: Error) => {
              reply.reply(wrapError(err));
            });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 获取视频音轨
  private setupGetVideoTracksChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.getVideoTracks',
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'getVideoTracks', 1);
          const playerId = args[0] as number;
          this.getVideoTracks(playerId)
            .then((tracks: Array<Map<string, string | number | boolean | null>>) => {
              reply.reply([tracks]);
            })
            .catch((err: Error) => {
              reply.reply(wrapError(err));
            });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 选择视频音轨
  private setupSelectVideoTrackChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.selectVideoTrack',
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'selectVideoTrack', 3);
          const playerId = args[0] as number;
          const groupIndex = args[1] as number;
          const trackIndex = args[2] as number;
          this.selectVideoTrack(playerId, groupIndex, trackIndex)
            .then(() => {
              reply.reply([]);
            })
            .catch((err: Error) => {
              reply.reply(wrapError(err));
            });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

  // 恢复自动视频质量（自适应）通道
  private setupEnableAutoVideoQualityChannel(binaryMessenger: BinaryMessenger): void {
    const channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      binaryMessenger,
      'dev.flutter.pigeon.video_player_ohos.OhosVideoPlayerApi.enableAutoVideoQuality',
      OhosVideoPlayerApi.getCodec()
    );

    channel.setMessageHandler({
      onMessage: (msg: Object, reply: Reply<Object>): void => {
        try {
          const args = requireChannelArgs(msg, 'enableAutoVideoQuality', 1);
          const playerId = args[0] as number;
          this.enableAutoVideoQuality(playerId)
            .then(() => {
              reply.reply([]);
            })
            .catch((err: Error) => {
              reply.reply(wrapError(err));
            });
        } catch (err) {
          reply.reply(wrapError(err));
        }
      }
    });
  }

}
