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
  private headers: Record<string, string> | null;
  private playTime: number = 0;
  private bufferTimeTemp: number = 0;
  private selectedAudioTrackIndex: number = -1;
  private isWindowKeepScreenOn: boolean = false;
  private cachedAudioTracks: Array<AudioTrackNativeMap> | null = null;
  private tracksCacheValid: boolean = false;
  private isPrepared: boolean = false;
  private pendingPlay: boolean = false;
  private pendingSeekPosition: number | null = null;
  private isSeeking: boolean = false;
  private isBuffering: boolean = false;
  private isSystemBuffering: boolean = false;
  private isSeekBuffering: boolean = false;
  private bufferingInfoTimer: number = -1;
  private isPollingPlaybackInfo: boolean = false;
  private cachedRotationCorrection: number = 0;

  constructor(playerModel: PlayerModel, textureEntry: SurfaceTextureEntry, rawFile: resourceManager.RawFileDescriptor | null, url: string | null, eventChannel: EventChannel, AudioFocus: Boolean, headers: Record<string, string> | null) {
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
      Log.i(TAG, "set interruptMode : " + this.interruptMode);
    }
    Log.i(TAG, "surfaceId : " + this.surfaceId);
  }

  /**
   * Creates a videoPlayer object.
   */
  async createAVPlayer() {
    Log.i(TAG + ":" + this.textureEntry.getTextureId(), " createAVPlayer");
    if (this.avPlayer == null) {
      this.avPlayer = await media.createAVPlayer();
    }
    if (this.avPlayer != null) {
      this.eventSink = new QueuingEventSink();
      Log.i(TAG, "enter setStreamHandler");
      this.eventChannel?.setStreamHandler(
        new StreamHandlerImpl(this.eventSink)
      );

      await this.bindState();

      /// 同时使用avPlayer.url和avPlayer.setMediaSource会导致直播视频无法正确播放
      if (!(this.url && this.url.startsWith('http'))) {
        if (this.url) {
          this.avPlayer.url = this.getIUri();
        } else {
          this.avPlayer.fdSrc = this.rawFile!;
        }
      } else {
        let mediaSource: media.MediaSource = media.createMediaSourceWithUrl(this.url, this.headers);
        /// 网络直播视频必须设置之后才能正常缓存
        let playbackStrategy:media.PlaybackStrategy | undefined = undefined;
        if (deviceInfo.sdkApiVersion >= 17) {
          playbackStrategy = { showFirstFrameOnPrepare:true } as media.PlaybackStrategy;
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
    Log.i(TAG, "enter bindState");
    if (this.avPlayer == null) {
      Log.e(TAG, "bindState, avPlayer is null");
      return;
    }
    this.avPlayer.on(Events.STATE_CHANGE, async (state: media.AVPlayerState) => {
      let avplayerStatus: string = state;
      Log.i(TAG, "bindState, on avPlayer, step1");
      if (this.avPlayer == null) {
        Log.e(TAG, "bindState, avPlayer is null, step2");
        return;
      }
      Log.i(TAG, "bindState, on STATE_CHANGE, avplayerStatus=" + avplayerStatus);
      switch (avplayerStatus) {
        case AvplayerStatus.IDLE:
          this.cachedAudioTracks = null;
          this.tracksCacheValid = false;
          this.selectedAudioTrackIndex = -1;
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
            const iUri = this.getIUri();
            if (iUri) {
              this.avPlayer.url = iUri;
            } else {
              Log.e(TAG, 'IDLE: getIUri returned empty, cannot set url for: ' + this.url);
              // 可选择上报错误给Flutter层
              this.sendError(new Error('Failed to open file: ' + this.url));
            }
          } else {
            this.avPlayer.fdSrc = this.rawFile!;
          }
          break;
        case AvplayerStatus.INITIALIZED:
          this.isPrepared = false;
          this.avPlayer.surfaceId = this.surfaceId;
          this.avPlayer.prepare();
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
            this.avPlayer.seek(this.pendingSeekPosition, media.SeekMode.SEEK_CLOSEST);
            this.pendingSeekPosition = null;
          }
          if (this.pendingPlay) {
            this.pendingPlay = false;
            this.avPlayer.play();
          }
          break;
        case AvplayerStatus.PLAYING:
          this.status = CommonConstants.STATUS_START;
          this.watchStatus();
          break;
        case AvplayerStatus.PAUSED:
          this.status = CommonConstants.STATUS_PAUSE;
          this.watchStatus();
          break;
        case AvplayerStatus.COMPLETED:
          if (this.playerModel != null) {
            this.playerModel.playSpeed = PlayConstants.PLAY_SPEED;
          }
          this.sendCompleted();
          this.duration = PlayConstants.PLAYER_DURATION;
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
        this.isSeeking = false;
        this.endSeekBuffering();
      }
      this.initProgress(time);
      this.playTime = time;
    });

    this.avPlayer.on(Events.BUFFER_UPDATE, (infoType: media.BufferingInfoType, value: number) => {
      this.sendBufferingUpdate(infoType, value);
    });

    this.avPlayer.on(Events.ERROR, (err: BusinessError) => {
      if (err.code == OPERATE_ERROR) {
        Log.e(TAG, "AvPlayer Avoid Error Reporting: " + JSON.stringify(err));
        return;
      }
      Log.e(TAG, "avPlayer Events.ERROR: " + JSON.stringify(err));
      this.resetBufferingState();
      this.avPlayer?.reset();
      this.sendError(err);
    })
  }

  /**
   * 设置音频焦点模式
   *
   * @param mixWithOthers 是否与其他音频混合播放
   *                      true: 共享模式，与其他音频混合
   *                      false: 独占模式，暂停其他音频
   */
  setAudioFocus(mixWithOthers: boolean): void {
    if (this.avPlayer == null) {
      Log.w(TAG, "setAudioFocus: avPlayer is null, cannot set audio focus");
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
    this.stopBufferingInfoTimer();
    this.resetBufferingState();
    if (this.avPlayer !== null) {
      await this.avPlayer.release();
      this.avPlayer = null;
      this.eventChannel?.setStreamHandler(null);
    }
    if (this.fd != null) {
      fs.closeSync(this.fd!);
      this.fd = null;
    }
  }


  play() {
    if (this.avPlayer !== null) {
      if (!this.isPrepared) {
        this.pendingPlay = true;
        return;
      }
      this.avPlayer.play();
    }
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
      this.avPlayer.pause();
    }
  }

  seekTo(position: number) {
    if (this.avPlayer !== null) {
      if (!this.isPrepared) {
        this.pendingSeekPosition = position;
        return;
      }
      this.prepareSeek();
      this.avPlayer.seek(position, media.SeekMode.SEEK_CLOSEST);
    }
  }

  private prepareSeek(): void {
    if (this.status === CommonConstants.STATUS_START) {
      this.startSeekBuffering();
    }
    this.isSeeking = true;
  }

  getPosition(): number {
    if (this.avPlayer !== null) {
      return Math.max(0, this.avPlayer.currentTime);
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
        const codec = this.getStringFromRecord(rec, ['codec_mime', 'codec', 'codecName', 'codecMimeType']);
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

  private getStringFromRecord(rec: TrackDescriptionRecord, keys: Array<string>): string | null {
    for (let i = 0; i < keys.length; i++) {
      const v = rec[keys[i]];
      if (typeof v === 'string') {
        const s = this.nullableString(v);
        if (s !== null) {
          return s;
        }
      }
    }
    return null;
  }

  private getIntFromRecord(rec: TrackDescriptionRecord, keys: Array<string>): number | null {
    for (let i = 0; i < keys.length; i++) {
      const v = rec[keys[i]];
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
    let globalVideoList = GlobalContext.getContext().getObject('globalVideoList') as VideoItem[];
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
    this.avPlayer.reset();
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
    let globalVideoList = GlobalContext.getContext().getObject('globalVideoList') as VideoItem[];
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
    this.avPlayer.reset();
  }

  /**
   * Switching Between Video Play and Pause.
   */
  switchPlayOrPause() {
    if (this.avPlayer == null || this.playerModel == null) {
      return;
    }
    if (this.status === CommonConstants.STATUS_START) {
      this.avPlayer.pause();
    } else {
      this.avPlayer.play();
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
        this.prepareSeek();
        this.avPlayer.seek(this.seekTime, media.SeekMode.SEEK_PREV_SYNC);
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
    let windowClass = GlobalContext.getContext().getObject('windowClass') as window.Window;
    windowClass.setWindowBrightness(this.playerModel.bright);
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
      let screenWidth = GlobalContext.getContext().getObject('screenWidth') as number;
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
    setTimeout(() => {
      if (this.playerModel) {
        this.playerModel.volumeShow = false;
        this.playerModel.brightShow = false;
      }
      this.positionX = PlayConstants.POSITION_X;
      this.positionY = PlayConstants.POSITION_Y;
    }, PlayConstants.DISAPPEAR_TIME);
  }

  /**
   * Sets whether the screen is a constant based on the playback status.
   */
  watchStatus() {
    let windowClass = GlobalContext.getContext().getObject('windowClass') as window.Window;
    if (this.status === CommonConstants.STATUS_START) {
      windowClass.setWindowKeepScreenOn(true);
    } else {
      windowClass.setWindowKeepScreenOn(this.isWindowKeepScreenOn);
    }
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
    Log.i(TAG, "sendInitialized")
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set("event", "initialized");
    event.set("duration", this.avPlayer?.duration);
    event.set("width", this.avPlayer?.width);
    event.set("height", this.avPlayer?.height);
    event.set("rotationCorrection", this.cachedRotationCorrection);
    this.eventSink?.success(event);
  }

  private async getRotationCorrection(): Promise<number> {
    let extractor: media.AVMetadataExtractor | null = null;
    let fd: fs.File | null = null;
    try {
      extractor = await media.createAVMetadataExtractor();
      if (this.url?.startsWith("file://")) {
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
      orientation
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
    event.set("event", "completed");
    this.eventSink?.success(event);
  }

  resetBufferingState(): void {
    let wasBuffering = this.isBuffering;
    this.isSystemBuffering = false;
    this.isSeekBuffering = false;
    this.isSeeking = false;
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
    event.set("event", shouldBuffering ? "bufferingStart" : "bufferingEnd");
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
      console.error(TAG, "reportBufferedPositionFromPlaybackInfo error:" + JSON.stringify(e))
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
      event.set("event", "bufferingUpdate");
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
      event.set("values", valuesList);
    } else {
      event.set("event", "unknown");
    }
    this.eventSink?.success(event);
  }

  sendError(error: Object): void {
    const errorMessage = error instanceof Error ? error.message : String(error);
    this.eventSink?.error("VideoError", `Video player had error: ${errorMessage}`, error);
  }

  getIUri(): string {
    let iUrl = this.url;
    const ohosFilePrefix = 'file://';
    if (iUrl != null && iUrl.startsWith(ohosFilePrefix)) {
      try {
        if (this.fd != null) {
          fs.closeSync(this.fd!);
          this.fd = null;
        }
        this.fd = fs.openSync(iUrl, fs.OpenMode.READ_ONLY).fd;
        iUrl = `fd://${this.fd!.toString()}`;
      } catch (e) {
        Log.e(TAG, 'getIUri fs.openSync failed: ' + JSON.stringify(e));
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
