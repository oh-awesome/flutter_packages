// Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on VideoPlayer.java originally written by
// Copyright 2013 The Flutter Authors.

import media from '@ohos.multimedia.media';
import prompt from '@ohos.promptAction';
import resourceManager from '@ohos.resourceManager';
import window from '@ohos.window';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import image from '@ohos.multimedia.image';
import { AvplayerStatus, CommonConstants, Events, SliderMode } from './constants/CommonConstants';
import { PlayConstants } from './constants/PlayConstants';

import { PlayerModel } from './PlayerModel';
import DateFormatUtil from './util/DateFormatUtil';
import { GlobalContext } from './util/GlobalContext';
import { VideoItem } from './VideoItem';
import { BusinessError } from '@ohos.base';
import { EventChannel } from '@ohos/flutter_ohos';
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { QueuingEventSink } from './QueuingEventSink';
import { ArrayList, HashMap } from '@kit.ArkTS';
import { audio } from '@kit.AudioKit';
import fs from '@ohos.file.fs';
import deviceInfo from '@ohos.deviceInfo';

const FORMAT_SS: String = 'ss';
const FORMAT_DASH: String = 'dash';
const FORMAT_HLS: String = 'hls';
const FORMAT_OTHER: String = 'other';

const OPERATE_ERROR: number = 801;
const AVPLAYER_STATE_ERROR: number = 5400102;
const AVPLAYER_IO_ERROR: number = 5400103;
const BUFFER_INFO_POLL_INTERVAL: number = 500;
const PLAYBACK_INFO_MIN_SDK: number = 12;
const PLAYBACK_INFO_BUFFER_DURATION_KEY: string = 'buffer_duration';

const TAG = 'VideoPlayer'
const ENABLE_AUDIO_TRACK_DEBUG: boolean = false;
type NativeAudioTrackValue = string | number | boolean | null;
type AudioTrackNativeMap = Map<string, NativeAudioTrackValue>;
type TrackDescriptionValue = string | number | boolean | null | undefined;
type TrackDescriptionRecord = Record<string, TrackDescriptionValue>;
// 轨道元数据键：可为鸿蒙 MediaDescriptionKey 枚举值（number）或字符串键。
type TrackDescriptionKeys = Array<string | number>;
interface AVPlayerWithPlaybackInfo {
  getPlaybackInfo(): Promise<Record<string, Object>>;
}
export class VideoPlayer {
  private avPlayer: media.AVPlayer | null = null;
  public playerModel: PlayerModel | null = null;
  private duration: number = 0;
  private status: number = -1;
  private loop: boolean = false;
  private index: number = 0;
  private rawFile?: resourceManager.RawFileDescriptor | null = {} as resourceManager.RawFileDescriptor;
  private url: string | null = null;
  private surfaceId: string = '';
  private seekTime: number = PlayConstants.PROGRESS_SEEK_TIME;
  private positionX: number = PlayConstants.POSITION_X;
  private positionY: number = PlayConstants.POSITION_Y;
  private textureEntry: SurfaceTextureEntry;
  private eventChannel: EventChannel | null = null;
  private eventSink: QueuingEventSink | null = null;
  private interruptMode: audio.InterruptMode = audio.InterruptMode.INDEPENDENT_MODE;
  private fd: number | null = null;
  // 由插件侧（getFileFdByPath）打开、通过 fd://<n> 传入的外部 fd
  // AVPlayer 不会接管其关闭，需在本播放器 release 时统一关闭，避免 fd 泄漏
  private externalFd: number | null = null;
  private headers: Record<string, string> | null;
  private playTime: number = 0;
  private bufferTimeTemp: number = 0;
  private selectedAudioTrackIndex: number = -1;
  private isWindowKeepScreenOn: boolean = false;
  // Dart 层 preventsDisplaySleepDuringVideoPlayback 透传标志，默认与主包一致为 true。
  private keepScreenOnDuringPlayback: boolean = true;
  private cachedAudioTracks: Array<AudioTrackNativeMap> | null = null;
  private tracksCacheValid: boolean = false;
  private selectedVideoTrackIndex: number = -1;
  private cachedVideoTracks: Array<AudioTrackNativeMap> | null = null;
  private videoTracksCacheValid: boolean = false;
  private isPrepared: boolean = false;
  private pendingPlay: boolean = false;
  private pendingReplayAfterSeek: boolean = false;
  private pendingSeekPosition: number | null = null;
  private isSeeking: boolean = false;
  private seekPosition: number = 0;
  private isBuffering: boolean = false;
  private isSystemBuffering: boolean = false;
  private isSeekBuffering: boolean = false;
  private bufferingInfoTimer: number = -1;
  private isPollingPlaybackInfo: boolean = false;
  private cachedRotationCorrection: number = 0;
  private actionEndTimer: number = -1;
  // 幂等保护：dispose 与引擎 detach 可能并发触发 release，避免二次释放。
  private released: boolean = false;
  // 事件订阅追踪标志：记录 AVPlayer 事件回调是否已绑定，保证 on/off 对称。
  private eventsBound: boolean = false;

  constructor(playerModel: PlayerModel, textureEntry: SurfaceTextureEntry, rawFile: resourceManager.RawFileDescriptor | null, url: string | null, eventChannel: EventChannel, AudioFocus: boolean, headers: Record<string, string> | null) {
    this.playerModel = playerModel;
    this.textureEntry = textureEntry;
    this.surfaceId = textureEntry.getSurfaceId().toString();
    this.rawFile = rawFile;
    this.url = url;
    this.eventChannel = eventChannel;
    this.headers = headers;
    try {
      this.isWindowKeepScreenOn = (GlobalContext.getContext().getObject('windowClass') as window.Window).getWindowProperties().isKeepScreenOn;
    } catch (e) {
      Log.e(TAG, 'getWindowProperties failed: ' + JSON.stringify(e));
    }
    if (AudioFocus == true) {
      this.interruptMode = audio.InterruptMode.SHARE_MODE;
      Log.i(TAG, 'set interruptMode : ' + this.interruptMode);
    }
    Log.i(TAG, 'surfaceId : ' + this.surfaceId);
  }

  /**
   * Creates a videoPlayer object.
   */
  async createAVPlayer() {
    Log.i(TAG + ':' + this.textureEntry.getTextureId(), ' createAVPlayer');
    if (this.avPlayer == null) {
      this.avPlayer = await media.createAVPlayer();
    }
    if (this.avPlayer != null) {
      this.eventSink = new QueuingEventSink();
      Log.i(TAG, 'enter setStreamHandler');
      this.eventChannel?.setStreamHandler(
        new StreamHandlerImpl(this.eventSink)
      );

      await this.bindState();

      /// 同时使用avPlayer.url和avPlayer.setMediaSource会导致直播视频无法正确播放
      if (!(this.url && this.url.startsWith('http'))) {
        try {
          if (this.url) {
            this.avPlayer.url = this.getUri();
          } else {
            this.avPlayer.fdSrc = this.rawFile!;
          }
        } catch (e) {
          Log.e(TAG, 'set url/fdSrc failed: ' + JSON.stringify(e));
          this.sendError(e instanceof Error ? e : new Error(`${e}`));
        }
      } else {
        let mediaSource: media.MediaSource = media.createMediaSourceWithUrl(this.url, this.headers);
        /// 网络直播视频必须设置之后才能正常缓存
        let playbackStrategy: media.PlaybackStrategy = { preferredWidth: 1920, preferredHeight: 1080 };
        if (deviceInfo.sdkApiVersion >= 17) {
          playbackStrategy.showFirstFrameOnPrepare = true;
        }
        // 设置媒体来源和播放策略
        await this.avPlayer.setMediaSource(mediaSource, playbackStrategy);
      }
    }
  }

  /**
   * AVPlayer binding event.
   */
  async bindState() {
    Log.i(TAG, 'enter bindState');
    if (this.avPlayer == null) {
      Log.e(TAG, 'bindState, avPlayer is null');
      return;
    }
    // 事件订阅幂等保护：避免 reset 后重复 bind 造成重复订阅。
    if (this.eventsBound) {
      Log.w(TAG, 'bindState, events already bound, skip');
      return;
    }
    this.eventsBound = true;
    this.avPlayer.on(Events.STATE_CHANGE, async (state: media.AVPlayerState) => {
      let avplayerStatus: string = state;
      Log.i(TAG, 'bindState, on avPlayer, step1');
      if (this.avPlayer == null) {
        Log.e(TAG, 'bindState, avPlayer is null, step2');
        return;
      }
      Log.i(TAG, 'bindState, on STATE_CHANGE, avplayerStatus=' + avplayerStatus);
      switch (avplayerStatus) {
        case AvplayerStatus.IDLE:
          this.cachedAudioTracks = null;
          this.tracksCacheValid = false;
          this.selectedAudioTrackIndex = -1;
          this.cachedVideoTracks = null;
          this.videoTracksCacheValid = false;
          this.selectedVideoTrackIndex = -1;
          this.isPrepared = false;
          this.pendingPlay = false;
          this.pendingSeekPosition = null;
          this.resetProgress();
          // Extract rotation before setting data source to avoid fd conflict with AVPlayer
          try {
            this.cachedRotationCorrection = await this.getRotationCorrection();
            Log.i(TAG, 'cachedRotationCorrection=' + this.cachedRotationCorrection);
          } catch (e) {
            Log.w(TAG, 'getRotationCorrection failed: ' + JSON.stringify(e));
          }
          if (this.url) {
            if (this.url.startsWith('http')) {
              // 与 createAVPlayer 保持一致：http 网络源走 setMediaSource
              // 保留 httpHeaders；reset 后重设 avPlayer.url 会丢弃这些配置
              let mediaSource: media.MediaSource = media.createMediaSourceWithUrl(this.url, this.headers);
              let playbackStrategy: media.PlaybackStrategy = { preferredWidth: 1920, preferredHeight: 1080 };
              if (deviceInfo.sdkApiVersion >= 17) {
                playbackStrategy.showFirstFrameOnPrepare = true;
              }
              this.avPlayer.setMediaSource(mediaSource, playbackStrategy).catch((e: Error) => {
                Log.e(TAG, 'setMediaSource failed: ' + JSON.stringify(e));
                this.sendError(e);
              });
            } else {
              const iUri = this.getUri();
              try {
                if (iUri) {
                  this.avPlayer.url = iUri;
                } else {
                  Log.e(TAG, 'IDLE: getUri returned empty, cannot set url for: ' + this.url);
                  this.sendError(new Error('Failed to open file: ' + this.url));
                }
              } catch (e) {
                Log.e(TAG, 'set url failed: ' + JSON.stringify(e));
                this.sendError(e instanceof Error ? e : new Error(`${e}`));
              }
            }
          } else {
            try {
              this.avPlayer.fdSrc = this.rawFile!;
            } catch (e) {
              Log.e(TAG, 'set fdSrc failed: ' + JSON.stringify(e));
              this.sendError(e instanceof Error ? e : new Error(`${e}`));
            }
          }
          break;
        case AvplayerStatus.INITIALIZED:
          this.isPrepared = false;
          try {
            this.avPlayer.surfaceId = this.surfaceId;
            await this.avPlayer.prepare();
          } catch (e) {
            Log.e(TAG, 'surfaceId/prepare failed: ' + JSON.stringify(e));
            this.sendError(e instanceof Error ? e : new Error(`${e}`));
          }
          break;
        case AvplayerStatus.PREPARED:
          this.isPrepared = true;
          this.avPlayer.videoScaleType = 0;
          this.avPlayer.audioInterruptMode = this.interruptMode;
          this.setVideoSize();
          this.sendInitialized();
          this.duration = this.avPlayer.duration;
          this.startBufferingInfoTimer();
          if (this.pendingSeekPosition !== null) {
            const seekPosition = this.pendingSeekPosition;
            this.pendingSeekPosition = null;
            try {
              await this.avPlayer.seek(seekPosition, media.SeekMode.SEEK_CLOSEST);
            } catch (e) {
              Log.e(TAG, 'seek failed: ' + JSON.stringify(e));
              this.sendError(e instanceof Error ? e : new Error(`${e}`));
            }
          }
          if (this.pendingPlay) {
            this.pendingPlay = false;
            this.play();
          }
          break;
        case AvplayerStatus.PLAYING:
          this.status = CommonConstants.STATUS_START;
          this.watchStatus();
          this.sendIsPlayingStateUpdate(true);
          break;
        case AvplayerStatus.PAUSED:
          this.status = CommonConstants.STATUS_PAUSE;
          this.watchStatus();
          this.sendIsPlayingStateUpdate(false);
          break;
        case AvplayerStatus.COMPLETED:
          if (this.playerModel != null) {
            this.playerModel.playSpeed = PlayConstants.PLAY_SPEED;
          }
          this.status = CommonConstants.STATUS_PAUSE;
          this.watchStatus();
          this.playTime = this.duration;
          this.pendingReplayAfterSeek = false;
          this.sendCompleted();
          if (!this.loop) {
            let curIndex = this.index + PlayConstants.PLAYER_NEXT;
            let globalVideoList = GlobalContext.getContext().getObject('globalVideoList') as VideoItem[];
            this.index = (curIndex === globalVideoList.length) ? PlayConstants.PLAYER_FIRST : curIndex;
            if (this.url) {
              this.url = globalVideoList[this.index].iSrc;
            } else {
              this.rawFile = globalVideoList[this.index].src;
            }
            this.cachedAudioTracks = null;
            this.tracksCacheValid = false;
            this.selectedAudioTrackIndex = -1;
          }
          break;
        case AvplayerStatus.RELEASED:
          this.status = CommonConstants.STATUS_STOP;
          this.watchStatus();
          this.cachedAudioTracks = null;
          this.tracksCacheValid = false;
          this.selectedAudioTrackIndex = -1;
          this.cachedVideoTracks = null;
          this.videoTracksCacheValid = false;
          this.selectedVideoTrackIndex = -1;
          this.isPrepared = false;
          this.pendingPlay = false;
          this.pendingSeekPosition = null;
          Log.i(TAG, '[PlayVideoModel] state released called')
          break;
        default:
          Log.i(TAG, '[PlayVideoModel] unKnown state: ' + state);
          break;
      }
    });

    this.avPlayer.on(Events.TIME_UPDATE, (time: number) => {
      if (this.isSeeking) {
        this.playTime = time;
        return;
      }
      this.initProgress(time);
      this.playTime = time;
    });

    this.avPlayer.on(Events.SEEK_DONE, async (time: number) => {
      if (this.isSeeking) {
        this.isSeeking = false;
        this.endSeekBuffering();
      }
      this.playTime = time;
      if (this.pendingReplayAfterSeek && this.avPlayer !== null) {
        this.pendingReplayAfterSeek = false;
        try {
          await this.avPlayer.play();
        } catch (e) {
          Log.e(TAG, 'play failed after seek: ' + JSON.stringify(e));
          this.sendError(e instanceof Error ? e : new Error(`${e}`));
        }
      }
    });

    this.avPlayer.on(Events.BUFFER_UPDATE, (infoType: media.BufferingInfoType, value: number) => {
      this.sendBufferingUpdate(infoType, value);
    });

    this.avPlayer.on(Events.ERROR, (err: BusinessError) => {
      if (err.code == OPERATE_ERROR) {
        // 直播落后播放窗口场景：与 Android ERROR_CODE_BEHIND_LIVE_WINDOW 一致，
        // 静默回到默认位置继续播放，不上报错误
        Log.e(TAG, 'AvPlayer Avoid Error Reporting: ' + JSON.stringify(err));
        try {
          this.avPlayer?.seekToDefaultPosition?.();
        } catch (e) {
          Log.e(TAG, 'seekToDefaultPosition failed: ' + JSON.stringify(e));
        }
        return;
      }
      Log.e(TAG, 'avPlayer Events.ERROR: ' + JSON.stringify(err));
      // 出错后播放器将被 reset，及时停止缓冲轮询，避免无效轮询直至 release
      this.stopBufferingInfoTimer();
      this.resetBufferingState();
      this.avPlayer?.reset().catch((e: Error) => {
        Log.e(TAG, 'reset failed: ' + JSON.stringify(e));
      });
      this.sendError(err);
    })
  }

  /**
   * 设置音频焦点/混音模式（对应 platform 接口 setMixWithOthers）。
   *
   * Android 参考实现：创建 ExoPlayer 时通过 AudioAttributes 设置
   * handleAudioFocus = !mixWithOthers 控制是否申请系统级音频焦点
   * （true 不申请焦点，可与其他应用音频混播；false 申请独占焦点）。
   *
   * OHOS 差异说明：AVPlayer 未暴露系统级 AudioFocusManager 接口，
   * 而是通过 player 的 audioInterruptMode 实现等价语义。
   *   - SHARE_MODE（共享模式）：等价 Android mixWithOthers=true，
   *     与其他音频会话共享，不中断其他应用播放。
   *   - INDEPENDENT_MODE（独立模式）：等价 Android mixWithOthers=false，
   *     当前播放器独占音频焦点，其他音频被暂停/弱化。
   * 注意：系统级焦点 API（audio.requestAudioFocus）需 MANAGE_SYSTEM_AUDIO_EFFECTS
   * 权限且主要面向 audio.AudioRenderer 场景，AVPlayer 场景下官方推荐的
   * 混音控制方式即为 audioInterruptMode，故此处保持 player 级实现。
   *
   * @param mixWithOthers 是否与其他音频混合播放
   *                      true: 共享模式，与其他音频混合
   *                      false: 独占模式，暂停其他音频
   */
  setAudioFocus(mixWithOthers: boolean): void {
    if (this.avPlayer == null) {
      Log.w(TAG, 'setAudioFocus: avPlayer is null, cannot set audio focus');
      return;
    }

    // 根据 mixWithOthers 参数设置中断模式
    this.interruptMode = mixWithOthers ?
      audio.InterruptMode.SHARE_MODE :
      audio.InterruptMode.INDEPENDENT_MODE;

    // 更新播放器的音频中断模式
    this.avPlayer.audioInterruptMode = this.interruptMode;

    Log.i(TAG, `setAudioFocus: mixWithOthers=${mixWithOthers}, interruptMode=${this.interruptMode}`);
  }

  /**
   * Release the video player.
   */
  async release() {
    if (this.released) {
      Log.w(TAG, 'release already done, skip duplicated release');
      return;
    }
    this.released = true;
    if (this.actionEndTimer !== -1) {
      clearTimeout(this.actionEndTimer);
      this.actionEndTimer = -1;
    }
    this.stopBufferingInfoTimer();
    this.resetBufferingState();
    // 释放时恢复窗口常亮原始状态，避免直接释放（未经过 PAUSED/COMPLETED）时亮屏残留
    this.status = CommonConstants.STATUS_STOP;
    this.watchStatus();
    try {
      if (this.avPlayer !== null) {
        // 显式取消事件订阅，避免 release 后回调仍被触发
        try {
          if (this.eventsBound) {
            this.avPlayer.off(Events.STATE_CHANGE);
            this.avPlayer.off(Events.TIME_UPDATE);
            this.avPlayer.off(Events.SEEK_DONE);
            this.avPlayer.off(Events.BUFFER_UPDATE);
            this.avPlayer.off(Events.ERROR);
            this.eventsBound = false;
          }
          await this.avPlayer.release();
        } catch (e) {
          Log.w(TAG, 'avPlayer release/off failed: ' + JSON.stringify(e));
        }
        this.avPlayer = null;
        this.eventChannel?.setStreamHandler(null);
      }
    } finally {
      // fd 由本插件打开并负责关闭（AVPlayer 不会接管），必须保证在 release
      // 的任何异常路径下都能关闭，避免 fd 泄漏（Too many open files）。
      if (this.fd != null) {
        try {
          fs.closeSync(this.fd!);
        } catch (e) {
          Log.w(TAG, 'close fd failed: ' + JSON.stringify(e));
        }
        this.fd = null;
      }
      if (this.externalFd != null) {
        try {
          fs.closeSync(this.externalFd!);
        } catch (e) {
          Log.w(TAG, 'close external fd failed: ' + JSON.stringify(e));
        }
        this.externalFd = null;
      }
    }
  }

  play() {
    if (this.avPlayer == null) {
      return;
    }
    if (!this.isPrepared) {
      this.pendingPlay = true;
      return;
    }
    if (this.shouldReplayFromStart()) {
      this.pendingReplayAfterSeek = true;
      this.prepareSeek(PlayConstants.PLAYER_DURATION);
      try {
        this.avPlayer.seek(PlayConstants.PLAYER_DURATION, media.SeekMode.SEEK_CLOSEST);
      } catch (e) {
        Log.e(TAG, 'seek failed for replay: ' + JSON.stringify(e));
        this.sendError(e instanceof Error ? e : new Error(`${e}`));
      }
      return;
    }
    this.avPlayer.play().catch((e: Error) => {
      Log.e(TAG, 'play failed: ' + JSON.stringify(e));
      this.sendError(e);
    });
  }

  /**
   * Pause Playing.
   */
  pause() {
    if (this.avPlayer !== null) {
      if (!this.isPrepared) {
        this.pendingPlay = false;
        return;
      }
      if (this.status !== CommonConstants.STATUS_START) {
        return;
      }
      this.avPlayer.pause().catch((e: Error) => {
        Log.e(TAG, 'pause failed: ' + JSON.stringify(e));
        this.sendError(e);
      });
    }
  }

  seekTo(position: number) {
    if (this.avPlayer !== null) {
      if (!this.isPrepared) {
        this.pendingSeekPosition = position;
        return;
      }
      this.prepareSeek(position);
      try {
        this.avPlayer.seek(position, media.SeekMode.SEEK_CLOSEST);
      } catch (e) {
        Log.e(TAG, 'seek failed: ' + JSON.stringify(e));
        this.sendError(e instanceof Error ? e : new Error(`${e}`));
      }
    }
  }

  private prepareSeek(position: number): void {
    this.startSeekBuffering();
    this.isSeeking = true;
    this.seekPosition = position;
  }

  private shouldReplayFromStart(): boolean {
    return this.duration > 0 && this.getPosition() >= this.duration;
  }

  getPosition(): number {
    if (this.isSeeking) {
      return this.seekPosition;
    }
    if (this.avPlayer !== null) {
      // Dart 侧以 int（毫秒）接收，取整规避 currentTime 为小数时的强转风险
      return Math.trunc(Math.max(0, this.avPlayer.currentTime));
    } else {
      return 0;
    }
  }

  async getAudioTracks(): Promise<Array<AudioTrackNativeMap>> {
    if (this.tracksCacheValid && this.cachedAudioTracks !== null) {
      return this.cachedAudioTracks;
    }
    const tracks: Array<AudioTrackNativeMap> = [];
    if(!this.avPlayer){
      return tracks;
    }
    try {
      const descriptions: Array<media.MediaDescription> = await this.avPlayer.getTrackDescription();
      let firstIncludedSelectIndex = -1;
      for (let i = 0; i < descriptions.length; i++) {
        const desc = descriptions[i];
        const trackIndex = this.getTrackIndexFromDescription(desc);
        if (trackIndex < 0) {
          continue;
        }
        const trackType = this.getTrackTypeFromDescription(desc);
        if (trackType != null && trackType !== media.MediaType.MEDIA_TYPE_AUD) {
          if (ENABLE_AUDIO_TRACK_DEBUG) {
            Log.i(TAG, `track[${i}] skip(type=${trackType} idx=${trackIndex}): ` + JSON.stringify(desc));
          }
          continue;
        }
        const rec = desc as Object as TrackDescriptionRecord;
        const selectIndex = trackIndex;
        const nativeTrack = new Map<string, NativeAudioTrackValue>();
        const label = this.pickTrackLabelFromRecord(rec);
        const language = this.getStringFromRecord(rec, ['language', 'lang', 'locale']);
        const codec = this.getStringFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_CODEC_MIME, 'codec_mime', 'codec', 'codecName', 'codecMimeType']);
        const channelCount = this.getIntFromRecord(rec, ['channel_count', 'channelCount', 'channels']);
        const sampleRate = this.getIntFromRecord(rec, ['sample_rate', 'sampleRate']);
        const bitrate = this.getIntFromRecord(rec, ['bit_rate', 'bitrate']);

        if (firstIncludedSelectIndex < 0) {
          firstIncludedSelectIndex = selectIndex;
          if (this.selectedAudioTrackIndex < 0) {
            this.selectedAudioTrackIndex = selectIndex;
          }
        }

        nativeTrack.set('id', `0_${selectIndex}`);
        nativeTrack.set('label', label);
        nativeTrack.set('language', language);
        nativeTrack.set('isSelected', this.selectedAudioTrackIndex == trackIndex);
        nativeTrack.set('bitrate', bitrate);
        nativeTrack.set('sampleRate', sampleRate);
        nativeTrack.set('channelCount', channelCount);
        nativeTrack.set('codec', codec);
        tracks.push(nativeTrack);

        if (ENABLE_AUDIO_TRACK_DEBUG) {
          Log.i(TAG, `audioTrack id=${selectIndex}
        selected=${this.selectedAudioTrackIndex == trackIndex}
        info=` + JSON.stringify(desc));
        }
      }
      this.cachedAudioTracks = tracks;
      this.tracksCacheValid = true;
    } catch (e) {
      Log.e(TAG, 'getAudioTracks exception: ' + JSON.stringify(e));
      throw new Error(e.message);
    }
    return tracks;
  }

  async selectAudioTrack(groupIndex: number, trackIndex: number): Promise<void> {
    if (this.avPlayer == null) {
      throw new Error('avPlayer is null');
    }
    if (groupIndex !== 0) {
      throw new Error(`Unsupported audio track groupIndex: ${groupIndex}`);
    }
    if (trackIndex < 0) {
      throw new Error('Invalid trackId');
    }
    try {
      await this.avPlayer.selectTrack(trackIndex);
      this.selectedAudioTrackIndex = trackIndex;
      if (this.cachedAudioTracks) {
        for (const track of this.cachedAudioTracks) {
          track.set('isSelected', track.get('id') === `0_${trackIndex}`);
        }
      }
    } catch (e) {
	    const errMsg = e instanceof Error ? e.message : String(e);
	    Log.e(TAG, 'selectAudioTrack exception: ' + errMsg);
	    throw new Error(errMsg);
    }
  }

  /**
   * Gets the available video tracks (quality variants).
   *
   * For HLS/DASH streams, this returns the different quality levels.
   * For regular videos, this returns a single video track (or empty).
   * The track id format is '{groupIndex}_{trackIndex}' to keep
   * compatibility with the platform interface.
   */
  async getVideoTracks(): Promise<Array<AudioTrackNativeMap>> {
    if (this.videoTracksCacheValid && this.cachedVideoTracks !== null) {
      return this.cachedVideoTracks;
    }
    const tracks: Array<AudioTrackNativeMap> = [];
    if (!this.avPlayer) {
      return tracks;
    }
    try {
      const descriptions: Array<media.MediaDescription> = await this.avPlayer.getTrackDescription();
      for (let i = 0; i < descriptions.length; i++) {
        const desc = descriptions[i];
        const trackIndex = this.getTrackIndexFromDescription(desc);
        if (trackIndex < 0) {
          continue;
        }
        const trackType = this.getTrackTypeFromDescription(desc);
        // 仅收集明确为视频轨的 track；类型不明时结合是否带分辨率判断，
        // 避免把音频/字幕等重复变体统计成画轨。
        const rec = desc as Object as TrackDescriptionRecord;
        const typeWidth = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_WIDTH, 'width', 'video_width']);
        const typeHeight = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_HEIGHT, 'height', 'video_height']);
        if (trackType != null && trackType !== media.MediaType.MEDIA_TYPE_VID) {
          if (ENABLE_AUDIO_TRACK_DEBUG) {
            Log.i(TAG, `videoTrack[${i}] skip(type=${trackType} idx=${trackIndex}): ` + JSON.stringify(desc));
          }
          continue;
        }
        if (trackType == null && typeWidth == null && typeHeight == null) {
          continue;
        }
        const nativeTrack = new Map<string, NativeAudioTrackValue>();
        // 优先用鸿蒙标准 MediaDescriptionKey 枚举键提取，否则取不到宽高/码率等值。
        const codec = this.getStringFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_CODEC_MIME, 'codec_mime', 'codec', 'codecName', 'codecMimeType']);
        const bitrate = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_BITRATE, 'bit_rate', 'bitrate']);
        const widthRaw = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_WIDTH, 'width', 'video_width']);
        const heightRaw = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_HEIGHT, 'height', 'video_height']);
        // 对齐 Android Format.NO_VALUE：宽高为 0/负值视为无值，避免显示 '0x0'。
        const width = widthRaw != null && widthRaw > 0 ? widthRaw : null;
        const height = heightRaw != null && heightRaw > 0 ? heightRaw : null;
        // 过滤 codec 含 'unknown' 的无效占位轨（如 track_index=16 的 0x0 轨）。
        if (codec != null && codec.toLowerCase().includes('unknown')) {
          continue;
        }
        const rawFrameRate = this.getNumberFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_FRAME_RATE, 'frame_rate', 'frameRate', 'framerate']);
        // OHOS 的 MD_KEY_FRAME_RATE 单位是"每100秒的帧数"（6000=60fps），
        // 除以 100 归一化；为 0 时视为无值。
        const frameRate = rawFrameRate != null && rawFrameRate > 0
          ? rawFrameRate / 100
          : null;
        // 画轨 label 优先用分辨率生成（'1080p'），无意义标题过滤，
        // 均缺失时置 null 交给 Dart 层显示 'Track x_y'。
        const resLabel =
          width != null && height != null ? `${height}p` : null;
        const descLabel = this.pickTrackLabelFromRecord(rec);
        const meaningfulDescLabel =
          descLabel != null && /^(video|audio|subtitle|text)$/i.test(descLabel.trim())
            ? null
            : descLabel;
        const label = resLabel ?? meaningfulDescLabel;

        if (this.selectedVideoTrackIndex < 0) {
          this.selectedVideoTrackIndex = trackIndex;
        }

        nativeTrack.set('id', `0_${trackIndex}`);
        nativeTrack.set('label', label);
        nativeTrack.set('isSelected', this.selectedVideoTrackIndex == trackIndex);
        nativeTrack.set('bitrate', bitrate);
        nativeTrack.set('width', width);
        nativeTrack.set('height', height);
        nativeTrack.set('frameRate', frameRate);
        nativeTrack.set('codec', codec);
        tracks.push(nativeTrack);

        if (ENABLE_AUDIO_TRACK_DEBUG) {
          Log.i(TAG, `videoTrack id=${trackIndex}
        selected=${this.selectedVideoTrackIndex == trackIndex}
        info=` + JSON.stringify(desc));
        }
      }
      this.cachedVideoTracks = tracks;
      this.videoTracksCacheValid = true;
    } catch (e) {
      Log.e(TAG, 'getVideoTracks exception: ' + JSON.stringify(e));
      throw new Error(e.message);
    }
    return tracks;
  }

  async selectVideoTrack(groupIndex: number, trackIndex: number): Promise<void> {
    if (this.avPlayer == null) {
      throw new Error('avPlayer is null');
    }
    if (groupIndex !== 0) {
      throw new Error(`Unsupported video track groupIndex: ${groupIndex}`);
    }
    if (trackIndex < 0) {
      throw new Error('Invalid trackId');
    }
    try {
      await this.avPlayer.selectTrack(trackIndex);
      this.selectedVideoTrackIndex = trackIndex;
      if (this.cachedVideoTracks) {
        for (const track of this.cachedVideoTracks) {
          track.set('isSelected', track.get('id') === `0_${trackIndex}`);
        }
      }
      // 切换视频轨道后分辨率可能变化，重设 surfaceId 强制渲染器刷新。
      if (this.avPlayer.surfaceId) {
        this.avPlayer.surfaceId = this.surfaceId;
      }
      // 通知 Dart 侧轨道已切换，完成选中等待并刷新 UI。
      this.sendVideoTrackChanged();
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : String(e);
      Log.e(TAG, 'selectVideoTrack exception: ' + errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * Restores the automatic/adaptive video quality selection.
   *
   * When selecting a specific video track (e.g. lock 1080p), call
   * selectVideoTrack(groupIndex, trackIndex) to lock the quality. This
   * method reverts to the player default (adaptive streaming).
   *
   * OHOS 差异说明：Android 实现通过 TrackSelector 调用
   * clearOverridesOfType(C.TRACK_TYPE_VIDEO) 清除视频轨道 override 以
   * 直接恢复自适应码流。OHOS AVPlayer 未提供等价的"清除单条视频轨道
   * 选择"接口（deselectTrack 仅支持音频/字幕轨道），因此本实现采用
   * 重新 selectTrack 初始默认轨道索引的方式恢复自适应行为，语义等价。
   */
  async enableAutoVideoQuality(): Promise<void> {
    if (this.avPlayer == null) {
      throw new Error('avPlayer is null');
    }
    try {
      // AVPlayer does not expose a dedicated API to clear a single track
      // selection; selecting the current default track index (stored during
      // getVideoTracks) restores the initial behavior.
      if (this.selectedVideoTrackIndex >= 0) {
        await this.avPlayer.selectTrack(this.selectedVideoTrackIndex);
      }
      this.selectedVideoTrackIndex = -1;
      if (this.cachedVideoTracks) {
        for (const track of this.cachedVideoTracks) {
          track.set('isSelected', false);
        }
      }
      // 恢复自适应后同样通知 Dart 侧刷新 UI（selectedTrackId 为空）。
      this.sendVideoTrackChanged();
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : String(e);
      Log.e(TAG, 'enableAutoVideoQuality exception: ' + errMsg);
      throw new Error(errMsg);
    }
  }

  private getNumberFromRecord(rec: TrackDescriptionRecord, keys: TrackDescriptionKeys): number | null {
    for (let i = 0; i < keys.length; i++) {
      const v = rec[keys[i] as string];
      if (typeof v === 'number') {
        return Number.isFinite(v) ? v : null;
      }
      if (typeof v === 'string') {
        const parsed = Number.parseFloat(v);
        if (!Number.isNaN(parsed)) {
          return parsed;
        }
      }
    }
    return null;
  }

  private getTrackIndexFromDescription(desc: media.MediaDescription): number {
    const value = desc[media.MediaDescriptionKey.MD_KEY_TRACK_INDEX];
    if (typeof value === 'number') {
      return Number.isFinite(value) ? Math.trunc(value) : -1;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseInt(value, 10);
      return Number.isNaN(parsed) ? -1 : parsed;
    }
    return -1;
  }

  private getTrackTypeFromDescription(desc: media.MediaDescription): number | null {
    const value = desc[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE];
    if (typeof value === 'number') {
      return Number.isFinite(value) ? Math.trunc(value) : null;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseInt(value, 10);
      return Number.isNaN(parsed) ? null : parsed;
    }
    return null;
  }

  private nullableString(value: string | undefined): string | null {
    if (value === undefined) {
      return null;
    }
    const trimmed = value.trim();
    return trimmed.length === 0 ? null : trimmed;
  }

  private getStringFromRecord(rec: TrackDescriptionRecord, keys: TrackDescriptionKeys): string | null {
    for (let i = 0; i < keys.length; i++) {
      const v = rec[keys[i] as string];
      if (typeof v === 'string') {
        const s = this.nullableString(v);
        if (s !== null) {
          return s;
        }
      }
    }
    return null;
  }

  private getIntFromRecord(rec: TrackDescriptionRecord, keys: TrackDescriptionKeys): number | null {
    for (let i = 0; i < keys.length; i++) {
      const v = rec[keys[i] as string];
      if (typeof v === 'number') {
        return Number.isFinite(v) ? Math.trunc(v) : null;
      }
      if (typeof v === 'string') {
        const parsed = Number.parseInt(v, 10);
        if (!Number.isNaN(parsed)) {
          return parsed;
        }
      }
    }
    return null;
  }

  private pickTrackLabelFromRecord(rec: TrackDescriptionRecord): string | null {
    return this.getStringFromRecord(rec, ['label', 'track_name', 'name']);
  }



  /**
   * Playback mode. The options are as follows: true: playing a single video; false: playing a cyclic video.
   */
  setLoop() {
    this.loop = !this.loop;
  }

  setLooping(isLooping: boolean) {
    if (this.avPlayer != null) {
      try {
        this.avPlayer.loop = isLooping;
        this.loop = isLooping;
      } catch (e) {
        Log.w(TAG, 'setLooping failed (likely live stream): ' + JSON.stringify(e));
        this.loop = false;
      }
    } else {
      this.loop = isLooping;
    }
  }


  setVolume(volume: number) {
    if (this.avPlayer != null) {
      const clampedVolume = Math.max(0.0, Math.min(1.0, volume));
      this.avPlayer.setVolume(clampedVolume);
    }
  }

  /**
   * Set the playback speed.
   *
   * @param playSpeed Current playback speed.
   */
  setSpeed(playSpeed: number) {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (CommonConstants.OPERATE_STATE.indexOf(this.avPlayer.state) === -1) {
      return;
    }
    this.playerModel.playSpeed = playSpeed;
    this.avPlayer.setSpeed(this.playerModel.playSpeed);
  }

  /**
   * Previous video.
   */
  previousVideo() {
    if (this.avPlayer == null || this.playerModel == null || this.playerModel == null) {
      return;
    }
    if (CommonConstants.OPERATE_STATE.indexOf(this.avPlayer.state) === -1) {
      return;
    }
    this.playerModel.playSpeed = PlayConstants.PLAY_SPEED;
    const globalVideoList = GlobalContext.getContext().getObject('globalVideoList') as VideoItem[];
    if (!Array.isArray(globalVideoList) || globalVideoList.length === 0) {
      Log.w(TAG, 'previousVideo: globalVideoList is empty or missing');
      return;
    }
    let curIndex = this.index - PlayConstants.CONTROL_NEXT;
    this.index = (curIndex === -PlayConstants.CONTROL_NEXT) ?
      (globalVideoList.length - PlayConstants.CONTROL_NEXT) : curIndex;
    if (this.url) {
      this.url = globalVideoList[this.index].iSrc;
    } else {
      this.rawFile = globalVideoList[this.index].src;
    }
    this.cachedAudioTracks = null;
    this.tracksCacheValid = false;
    this.selectedAudioTrackIndex = -1;
    this.cachedVideoTracks = null;
    this.videoTracksCacheValid = false;
    this.selectedVideoTrackIndex = -1;
    this.avPlayer.reset().catch((e: Error) => {
      Log.e(TAG, 'reset failed: ' + JSON.stringify(e));
      this.sendError(e);
    });
  }

  /**
   * Next video.
   */
  nextVideo() {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (CommonConstants.OPERATE_STATE.indexOf(this.avPlayer.state) === -1) {
      return;
    }
    this.playerModel.playSpeed = PlayConstants.PLAY_SPEED;
    const globalVideoList = GlobalContext.getContext().getObject('globalVideoList') as VideoItem[];
    if (!Array.isArray(globalVideoList) || globalVideoList.length === 0) {
      Log.w(TAG, 'nextVideo: globalVideoList is empty or missing');
      return;
    }
    let curIndex = this.index + PlayConstants.CONTROL_NEXT;
    this.index = (curIndex === globalVideoList.length) ?
      PlayConstants.CONTROL_FIRST : curIndex;
    if (this.url) {
      this.url = globalVideoList[this.index].iSrc;
    } else {
      this.rawFile = globalVideoList[this.index].src;
    }
    this.cachedAudioTracks = null;
    this.tracksCacheValid = false;
    this.selectedAudioTrackIndex = -1;
    this.cachedVideoTracks = null;
    this.videoTracksCacheValid = false;
    this.selectedVideoTrackIndex = -1;
    this.avPlayer.reset().catch((e: Error) => {
      Log.e(TAG, 'reset failed: ' + JSON.stringify(e));
      this.sendError(e);
    });
  }

  /**
   * Switching Between Video Play and Pause.
   */
  switchPlayOrPause() {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (this.status === CommonConstants.STATUS_START) {
      this.pause();
    } else {
      this.play();
    }
  }

  /**
   * Slide the progress bar to set the playback progress.
   *
   * @param value Value of the slider component.
   * @param mode Slider component change event.
   */
  setSeekTime(value: number, mode: SliderChangeMode) {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (mode === Number(SliderMode.MOVING)) {
      this.playerModel.progressVal = value;
      this.playerModel.currentTime = DateFormatUtil.secondToTime(Math.floor(value * this.duration /
        CommonConstants.ONE_HUNDRED / CommonConstants.A_THOUSAND));
    }
    if (mode === Number(SliderMode.END) || mode === Number(SliderMode.CLICK)) {
      this.seekTime = value * this.duration / CommonConstants.ONE_HUNDRED;
      if (this.avPlayer !== null) {
        this.prepareSeek(this.seekTime);
        try {
          this.avPlayer.seek(this.seekTime, media.SeekMode.SEEK_PREV_SYNC);
        } catch (e) {
          Log.e(TAG, 'seek failed: ' + JSON.stringify(e));
          this.sendError(e instanceof Error ? e : new Error(`${e}`));
        }
      }
    }
  }

  /**
   * Setting the brightness.
   */
  setBright() {
    if (this.playerModel == null) {
      return;
    }
    try {
      let windowClass = GlobalContext.getContext().getObject('windowClass') as window.Window;
      windowClass.setWindowBrightness(this.playerModel.bright);
    } catch (e) {
      Log.e(TAG, 'setWindowBrightness failed: ' + JSON.stringify(e));
    }
  }

  /**
   * Obtains the current video playing status.
   */
  getStatus() {
    return this.status;
  }

  /**
   * Initialization progress bar.
   *
   * @param time Current video playback time.
   */
  initProgress(time: number) {
    if (this.playerModel == null) {
      return;
    }
    let nowSeconds = Math.floor(time / CommonConstants.A_THOUSAND);
    let totalSeconds = Math.floor(this.duration / CommonConstants.A_THOUSAND);
    this.playerModel.currentTime = DateFormatUtil.secondToTime(nowSeconds);
    this.playerModel.totalTime = DateFormatUtil.secondToTime(totalSeconds);
    this.playerModel.progressVal = Math.floor(nowSeconds * CommonConstants.ONE_HUNDRED / totalSeconds);
  }

  /**
   * Reset progress bar data.
   */
  resetProgress() {
    if (this.playerModel == null) {
      return;
    }
    this.seekTime = PlayConstants.PROGRESS_SEEK_TIME;
    this.playerModel.currentTime = PlayConstants.PROGRESS_CURRENT_TIME;
    this.playerModel.progressVal = PlayConstants.PROGRESS_PROGRESS_VAL;
  }

  /**
   * Volume gesture method onActionStart.
   *
   * @param event Gesture event.
   */
  onVolumeActionStart(event?: GestureEvent) {
    if (!event) {
      return;
    }
    this.positionX = event.offsetX;
  }

  /**
   * Bright gesture method onActionStart.
   *
   * @param event Gesture event.
   */
  onBrightActionStart(event?: GestureEvent) {
    if (!event) {
      return;
    }
    this.positionY = event.offsetY;
  }

  /**
   * Gesture method onActionUpdate.
   *
   * @param event Gesture event.
   */
  onVolumeActionUpdate(event?: GestureEvent) {
    if (!event) {
      return;
    }
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (CommonConstants.OPERATE_STATE.indexOf(this.avPlayer.state) === -1) {
      return;
    }
    if (this.playerModel.brightShow === false) {
      this.playerModel.volumeShow = true;
      const screenWidth = GlobalContext.getContext().getObject('screenWidth') as number;
      if (typeof screenWidth !== 'number' || screenWidth <= 0) {
        Log.w(TAG, 'onVolumeActionUpdate: screenWidth is missing');
        return;
      }
      let changeVolume = (event.offsetX - this.positionX) / screenWidth;
      let volume: number = this.playerModel.volume;
      let currentVolume = volume + changeVolume;
      let volumeMinFlag = currentVolume <= PlayConstants.MIN_VALUE;
      let volumeMaxFlag = currentVolume > PlayConstants.MAX_VALUE;
      this.playerModel.volume = volumeMinFlag ? PlayConstants.MIN_VALUE :
        (volumeMaxFlag ? PlayConstants.MAX_VALUE : currentVolume);
      this.avPlayer.setVolume(this.playerModel.volume);
      this.positionX = event.offsetX;
    }
  }

  /**
   * Gesture method onActionUpdate.
   *
   * @param event Gesture event.
   */
  onBrightActionUpdate(event?: GestureEvent) {
    if (!event || this.playerModel == null) {
      return;
    }
    if (this.playerModel.volumeShow === false) {
      this.playerModel.brightShow = true;
      let screenHeight = GlobalContext.getContext().getObject('screenHeight') as number;
      let changeBright = (this.positionY - event.offsetY) / screenHeight;
      let bright: number = this.playerModel.bright;
      let currentBright = bright + changeBright;
      let brightMinFlag = currentBright <= PlayConstants.MIN_VALUE;
      let brightMaxFlag = currentBright > PlayConstants.MAX_VALUE;
      this.playerModel.bright = brightMinFlag ? PlayConstants.MIN_VALUE :
        (brightMaxFlag ? PlayConstants.MAX_VALUE : currentBright);
      this.setBright();
      this.positionY = event.offsetY;
    }
  }

  /**
   * Gesture method onActionEnd.
   */
  onActionEnd() {
    if (this.actionEndTimer !== -1) {
      clearTimeout(this.actionEndTimer);
      this.actionEndTimer = -1;
    }
    this.actionEndTimer = setTimeout(() => {
      if (this.playerModel) {
        this.playerModel.volumeShow = false;
        this.playerModel.brightShow = false;
      }
      this.positionX = PlayConstants.POSITION_X;
      this.positionY = PlayConstants.POSITION_Y;
      this.actionEndTimer = -1;
    }, PlayConstants.DISAPPEAR_TIME);
  }

  /**
   * Sets whether the screen is a constant based on the playback status.
   */
  watchStatus() {
    try {
      let windowClass = GlobalContext.getContext().getObject('windowClass') as window.Window;
      if (this.status === CommonConstants.STATUS_START) {
        windowClass.setWindowKeepScreenOn(this.keepScreenOnDuringPlayback); // 由平台标志驱动
      } else {
        windowClass.setWindowKeepScreenOn(this.isWindowKeepScreenOn);
      }
    } catch (e) {
      Log.e(TAG, 'setWindowKeepScreenOn failed: ' + JSON.stringify(e));
    }
  }

  setKeepScreenOnDuringPlayback(keepScreenOn: boolean): void {
    this.keepScreenOnDuringPlayback = keepScreenOn;
    // 标志变化时立即按新值刷新常亮状态，无需等待下一次状态切换。
    this.watchStatus();
  }

  /**
   * Sets the playback page size based on the video size.
   */
  setVideoSize() {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (this.avPlayer.height > this.avPlayer.width) {
      this.playerModel.videoWidth = PlayConstants.PLAY_PLAYER_HEIGHT_FULL;
      this.playerModel.videoHeight = PlayConstants.PLAY_PLAYER_HEIGHT_FULL;
      this.playerModel.videoPosition = FlexAlign.Start;
      this.playerModel.videoMargin = PlayConstants.HEIGHT;
    } else {
      this.playerModel.videoWidth = CommonConstants.FULL_PERCENT;
      this.playerModel.videoHeight = PlayConstants.PLAY_PLAYER_HEIGHT;
      this.playerModel.videoPosition = FlexAlign.Center;
      this.playerModel.videoMargin = PlayConstants.MARGIN_ZERO;
    }
  }

  /**
   * An error is reported during network video playback.
   */
  playError() {
    prompt.showToast({
      duration: PlayConstants.PLAY_ERROR_TIME,
      message: $r('app.string.link_check_address_internet')
    });
  }

  sendInitialized(): void {
    Log.i(TAG, 'sendInitialized')
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'initialized');
    event.set('duration', this.avPlayer?.duration);
    event.set('width', this.avPlayer?.width);
    event.set('height', this.avPlayer?.height);
    event.set('rotationCorrection', this.cachedRotationCorrection);
    this.eventSink?.success(event);
  }

  sendIsPlayingStateUpdate(isPlaying: boolean): void {
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'isPlayingStateUpdate');
    event.set('isPlaying', isPlaying);
    this.eventSink?.success(event);
  }

  /**
   * Sends a video track selection changed event to Dart with the selected
   * track id in '{groupIndex}_{trackIndex}' format.
   *
   * OHOS AVPlayer 无 onTracksChanged 回调，故在 selectVideoTrack /
   * enableAutoVideoQuality 成功后主动发送，供 Dart 层完成选中等待与 UI 刷新。
   */
  sendVideoTrackChanged(): void {
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'videoTrackChanged');
    if (this.selectedVideoTrackIndex < 0) {
      // 恢复自适应模式：无确定选中轨道，置空仅驱动 UI 刷新。
      event.set('selectedTrackId', '');
    } else {
      event.set('selectedTrackId', `0_${this.selectedVideoTrackIndex}`);
    }
    this.eventSink?.success(event);
  }

  private async getRotationCorrection(): Promise<number> {
    let extractor: media.AVMetadataExtractor | null = null;
    let fd: fs.File | null = null;
    try {
      extractor = await media.createAVMetadataExtractor();
      if (this.url?.startsWith('file://')) {
        fd = fs.openSync(this.url.substring(7), fs.OpenMode.READ_ONLY);
        extractor.fdSrc = { fd: fd.fd, offset: 0, length: 0 };
      } else if (this.url) {
        if (deviceInfo.sdkApiVersion < 20) {
          return 0;
        }
        extractor.setUrlSource(this.url, this.headers ?? undefined);
      } else if (this.rawFile) {
        extractor.fdSrc = this.rawFile;
      } else {
        return 0;
      }
      const metadata = await extractor.fetchMetadata();
      const orientation = metadata.videoOrientation ? parseInt(metadata.videoOrientation) : 0;
      if (orientation === 0 || orientation === 90 || orientation === 180 || orientation === 270) {
        return orientation;
      }
      return 0;
    } catch (e) {
      Log.w(TAG, 'getRotationCorrection error: ' + JSON.stringify(e));
      return 0;
    } finally {
      if (fd) {
        fs.closeSync(fd);
      }
      extractor?.release();
      extractor = null;
    }
  }

  sendCompleted(): void {
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'completed');
    this.eventSink?.success(event);
  }

  resetBufferingState(): void {
    let wasBuffering = this.isBuffering;
    this.isSystemBuffering = false;
    this.isSeekBuffering = false;
    this.isSeeking = false;
    this.seekPosition = 0;
    this.bufferTimeTemp = 0;
    if (wasBuffering) {
      this.syncBufferingState();
    } else {
      this.isBuffering = false;
    }
  }

  syncBufferingState(): void {
    let shouldBuffering = this.isSystemBuffering || this.isSeekBuffering;
    if (shouldBuffering == this.isBuffering) {
      return;
    }
    this.isBuffering = shouldBuffering;
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', shouldBuffering ? 'bufferingStart' : 'bufferingEnd');
    this.eventSink?.success(event);
  }

  startSystemBuffering(): void {
    this.isSystemBuffering = true;
    this.syncBufferingState();
  }

  endSystemBuffering(): void {
    this.isSystemBuffering = false;
    this.syncBufferingState();
  }

  startSeekBuffering(): void {
    this.isSeekBuffering = true;
    this.syncBufferingState();
  }

  endSeekBuffering(): void {
    if (!this.isSeekBuffering) {
      return;
    }
    this.isSeekBuffering = false;
    this.syncBufferingState();
  }

  startBufferingInfoTimer(): void {
    if (deviceInfo.sdkApiVersion < PLAYBACK_INFO_MIN_SDK) {
      return;
    }
    if (this.bufferingInfoTimer !== -1 || this.avPlayer == null) {
      return;
    }
    this.bufferingInfoTimer = setInterval(() => {
      this.reportBufferedPositionFromPlaybackInfo();
    }, BUFFER_INFO_POLL_INTERVAL);
  }

  stopBufferingInfoTimer(): void {
    if (this.bufferingInfoTimer === -1) {
      return;
    }
    clearInterval(this.bufferingInfoTimer);
    this.bufferingInfoTimer = -1;
    this.isPollingPlaybackInfo = false;
  }

  async reportBufferedPositionFromPlaybackInfo(): Promise<void> {
    if (this.avPlayer == null || this.isPollingPlaybackInfo) {
      return;
    }
    this.isPollingPlaybackInfo = true;
    try {
      let avPlayer = this.avPlayer as AVPlayerWithPlaybackInfo;
      let playbackInfo = await avPlayer.getPlaybackInfo();
      let bufferDurationObject = playbackInfo[PLAYBACK_INFO_BUFFER_DURATION_KEY];
      if (typeof bufferDurationObject === 'number') {
        this.sendBufferingUpdate(media.BufferingInfoType.CACHED_DURATION, bufferDurationObject * CommonConstants.A_THOUSAND);
      }
    } catch (e) {
      console.error(TAG, 'reportBufferedPositionFromPlaybackInfo error:' + JSON.stringify(e))
    } finally {
      this.isPollingPlaybackInfo = false;
    }
  }

  sendBufferingStart(): void {
    this.startSystemBuffering();
  }

  sendBufferingEnd(): void {
    this.endSystemBuffering();
  }

  sendBufferingUpdate(infoType: media.BufferingInfoType, bufferingPosition: number): void {
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    if (infoType == media.BufferingInfoType.BUFFERING_START) {
      this.sendBufferingStart();
      return;
    } else if (infoType == media.BufferingInfoType.BUFFERING_END) {
      this.sendBufferingEnd();
      return;
    } else if (infoType == media.BufferingInfoType.CACHED_DURATION) {
      event.set('event', 'bufferingUpdate');
      let bufferedDuration = this.playTime + bufferingPosition;
      if (bufferedDuration > this.bufferTimeTemp) {
        this.bufferTimeTemp = bufferedDuration;
      }
      if (this.duration !== 0 && this.bufferTimeTemp > this.duration) {
        this.bufferTimeTemp = this.duration;
      }
      let range: ArrayList<number> = new ArrayList<number>();
      range.add(0);
      range.add(this.bufferTimeTemp);
      let valuesList: ArrayList<ArrayList<number>> = new ArrayList<ArrayList<number>>();
      valuesList.add(range);
      event.set('values', valuesList);
    } else {
      event.set('event', 'unknown');
    }
    this.eventSink?.success(event);
  }

  sendError(error: Object): void {
    const errorMessage = error instanceof Error ? error.message : String(error);
    this.eventSink?.error('VideoError', `Video player had error: ${errorMessage}`, error);
  }

  getUri(): string {
    let iUrl = this.url;
    const ohosFilePrefix = 'file://';
    const fdPrefix = 'fd://';
    if (iUrl != null && iUrl.startsWith(fdPrefix)) {
      // 外部传入的 fd（插件侧 getFileFdByPath 打开），记录以便 release 时关闭
      const parsedFd = Number.parseInt(iUrl.substring(fdPrefix.length));
      if (!Number.isNaN(parsedFd) && parsedFd >= 0) {
        this.externalFd = parsedFd;
      }
    }
    if (iUrl != null && iUrl.startsWith(ohosFilePrefix)) {
      try {
        if (this.fd != null) {
          fs.closeSync(this.fd!);
          this.fd = null;
        }
        this.fd = fs.openSync(iUrl, fs.OpenMode.READ_ONLY).fd;
        iUrl = `fd://${this.fd!.toString()}`;
      } catch (e) {
        Log.e(TAG, 'getUri fs.openSync failed: ' + JSON.stringify(e));
        this.fd = null;
        return '';
      }
    }
    return iUrl ?? '';
  }
}

class StreamHandlerImpl implements StreamHandler {
  private eventSink: QueuingEventSink | null = null;

  constructor(eventSink: QueuingEventSink) {
    this.eventSink = eventSink;
  }

  onListen(args: Object, events: EventSink): void {
    this.eventSink?.setDelegate(events);
  }

  onCancel(args: Object): void {
    this.eventSink?.setDelegate(null);
  }
}
