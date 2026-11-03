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
const PREPARED_WAIT_MS: number = 15000;
const PLAYBACK_INFO_MIN_SDK: number = 12;
const PLAYBACK_INFO_BUFFER_DURATION_KEY: string = 'buffer_duration';

const TAG = 'VideoPlayer'
const ENABLE_AUDIO_TRACK_DEBUG: boolean = false;

function normalizeDurationMs(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return 0;
  }
  // AVMetadata.duration is in milliseconds; round the raw value instead of guessing the unit from magnitude.
  return Math.round(value);
}

type NativeAudioTrackValue = string | number | boolean | null;
type AudioTrackNativeMap = Map<string, NativeAudioTrackValue>;
type TrackDescriptionValue = string | number | boolean | null | undefined;
type TrackDescriptionRecord = Record<string, TrackDescriptionValue>;
// Track metadata keys: either OHOS MediaDescriptionKey enum values (number) or string keys.
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
  // Path for getRawFd. Used to call closeRawFd on release; null if never opened.
  private rawFilePath: string | null = null;
  private assetResourceManager: resourceManager.ResourceManager | null = null;
  private url: string | null = null;
  private surfaceId: string = '';
  private seekTime: number = PlayConstants.PROGRESS_SEEK_TIME;
  private positionX: number = PlayConstants.POSITION_X;
  private positionY: number = PlayConstants.POSITION_Y;
  private textureEntry: SurfaceTextureEntry | null = null;
  private pendingPrepare: boolean = false;
  // AVPlayer defaults to 1x speed. Repeated setSpeed(1x) rebuilds
  // The decoder and freezes on the first frame when starting HDR.
  private appliedPlaybackSpeed: number = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  private initializedSent: boolean = false;
  private probedDurationMs: number = 0;
  private probedWidth: number = 0;
  private probedHeight: number = 0;
  private eventChannel: EventChannel | null = null;
  private eventSink: QueuingEventSink | null = null;
  private interruptMode: audio.InterruptMode = audio.InterruptMode.INDEPENDENT_MODE;
  private fd: number | null = null;
  // External fd opened by the plugin side (getFileFdByPath) and passed in via fd://<n>.
  // AVPlayer does not take over closing it; this player must close it on release to avoid fd leaks.
  private externalFd: number | null = null;
  private headers: Record<string, string> | null;
  private playTime: number = 0;
  private bufferTimeTemp: number = 0;
  private selectedAudioTrackIndex: number = -1;
  private isWindowKeepScreenOn: boolean = false;
  // Flag passed through from Dart preventsDisplaySleepDuringVideoPlayback;
  // defaults to true, consistent with the main package.
  private keepScreenOnDuringPlayback: boolean = true;
  private cachedVideoTracks: Array<AudioTrackNativeMap> | null = null;
  private videoTracksCacheValid: boolean = false;
  private isPrepared: boolean = false;
  private cachedAudioTracks: Array<AudioTrackNativeMap> | null = null;
  private tracksCacheValid: boolean = false;
  private selectedVideoTrackIndex: number = -1;
  private hasPreparedOnce: boolean = false;
  private preparedCompleter: (() => void) | null = null;
  private preparedPromise: Promise<void> | null = null;
  private pendingPlay: boolean = false;
  private pendingVolume: number | null = null;
  private pendingSpeed: number | null = null;
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
  // Idempotency guard: dispose and engine detach may trigger release concurrently, avoiding double release.
  private released: boolean = false;
  // Event subscription tracking flag: records whether AVPlayer event callbacks are bound, keeping on/off symmetric.
  private eventsBound: boolean = false;

  constructor(
    playerModel: PlayerModel,
    textureEntry: SurfaceTextureEntry | null,
    rawFile: resourceManager.RawFileDescriptor | null,
    url: string | null,
    eventChannel: EventChannel,
    AudioFocus: boolean,
    headers: Record<string, string> | null,
    rawFilePath: string | null = null,
    assetResourceManager: resourceManager.ResourceManager | null = null
  ) {
    this.playerModel = playerModel;
    this.textureEntry = textureEntry;
    if (textureEntry != null) {
      this.surfaceId = textureEntry.getSurfaceId().toString();
    }
    this.rawFile = rawFile;
    this.rawFilePath = rawFilePath;
    this.assetResourceManager = assetResourceManager;
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
    const textureLabel = this.textureEntry != null ? this.textureEntry.getTextureId().toString() : 'platform';
    Log.i(TAG + ':' + textureLabel, ' createAVPlayer');
    if (this.avPlayer == null) {
      this.avPlayer = await media.createAVPlayer();
    }
    if (this.avPlayer != null) {
      this.eventSink = new QueuingEventSink();
      Log.i(TAG, 'enter setStreamHandler');
      this.eventChannel?.setStreamHandler(
        new StreamHandlerImpl(this.eventSink, this.eventChannel)
      );

      await this.bindState();

      // Probe before setting the data source: the extractor and AVPlayer read
      // sequentially, so they do not contend for the same file offset.
      if (!this.usesExternalTexture()) {
        this.cachedRotationCorrection = await this.getRotationCorrection();
      }

      /// Using both avPlayer.url and avPlayer.setMediaSource causes live video to play incorrectly.
      if (!(this.url && this.url.startsWith('http'))) {
        if (this.url) {
          const playable = this.getUri();
          if (!this.isUsablePlaybackUri(playable)) {
            throw new Error('Failed to open file: ' + this.url);
          }
          this.avPlayer.url = playable;
        } else {
          this.avPlayer.fdSrc = this.rawFile!;
        }
      } else {
        let mediaSource: media.MediaSource = media.createMediaSourceWithUrl(this.url, this.headers);
        /// Network live video must be set this way for caching to work properly.
        let playbackStrategy: media.PlaybackStrategy = { preferredWidth: 1920, preferredHeight: 1080 };
        if (deviceInfo.sdkApiVersion >= 17) {
          playbackStrategy.showFirstFrameOnPrepare = true;
        }
        // Set the media source and playback strategy.
        await this.avPlayer.setMediaSource(mediaSource, playbackStrategy);
      }
      // StateChange does not report idle at creation; the platformView's first initialized is sent here:
      // The texture waits for initialized before entering the tree,
      // And prepare waits for the texture. Events go into QueuingEventSink first.
      if (!this.usesExternalTexture()) {
        this.sendInitialized();
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
    // Event subscription idempotency guard: avoid duplicate subscriptions from re-binding after reset.
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
          try {
            this.cachedRotationCorrection = await this.getRotationCorrection();
            Log.i(TAG, 'cachedRotationCorrection=' + this.cachedRotationCorrection);
          } catch (e) {
            Log.w(TAG, 'getRotationCorrection failed: ' + JSON.stringify(e));
          }
          // After reset, AVPlayer returns to 1x speed.
          this.appliedPlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
          if (this.url) {
            if (this.url.startsWith('http')) {
              // Consistent with createAVPlayer: http network sources use setMediaSource
              // to preserve httpHeaders; re-setting avPlayer.url after reset would drop them.
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
          if (this.surfaceId.length === 0) {
            this.pendingPrepare = true;
            Log.i(TAG, 'INITIALIZED without surface, defer prepare');
            break;
          }
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
          this.hasPreparedOnce = true;
          this.finishPreparedWait();
          this.avPlayer.videoScaleType = 0;
          this.avPlayer.audioInterruptMode = this.interruptMode;
          if (this.pendingVolume !== null) {
            this.avPlayer.setVolume(this.pendingVolume);
            this.pendingVolume = null;
          }
          if (this.loop) {
            try {
              this.avPlayer.loop = true;
            } catch (e) {
              Log.w(TAG, 'apply pending loop failed (likely live stream): ' + JSON.stringify(e));
              this.loop = false;
            }
          }
          if (this.pendingSpeed !== null) {
            const speed = this.pendingSpeed;
            this.pendingSpeed = null;
            this.setSpeed(speed);
          }
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
            if (!Array.isArray(globalVideoList) || globalVideoList.length === 0) {
              Log.w(TAG, 'COMPLETED: globalVideoList is empty or missing');
              break;
            }
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
        // Live playback falling behind the live window: same as Android
        // ERROR_CODE_BEHIND_LIVE_WINDOW, silently return to the default position
        // and keep playing without reporting an error.
        Log.e(TAG, 'AvPlayer Avoid Error Reporting: ' + JSON.stringify(err));
        try {
          this.avPlayer?.seekToDefaultPosition?.();
        } catch (e) {
          Log.e(TAG, 'seekToDefaultPosition failed: ' + JSON.stringify(e));
        }
        return;
      }
      if (this.ignoreOperateErrorBeforePrepare(err)) {
        Log.w(TAG, 'ignore operate-not-permit before prepare: ' + JSON.stringify(err));
        return;
      }
      Log.e(TAG, 'avPlayer Events.ERROR: ' + JSON.stringify(err));
      // After an error the player will be reset; stop buffering polling promptly
      // to avoid useless polling until release.
      this.stopBufferingInfoTimer();
      this.resetBufferingState();
      this.avPlayer?.reset().catch((e: Error) => {
        Log.e(TAG, 'reset failed: ' + JSON.stringify(e));
      });
      this.sendError(err);
    })
  }

  /**
   * Sets the audio focus / mixing mode (corresponds to the platform API setMixWithOthers).
   *
   * Android reference implementation: when creating the ExoPlayer, AudioAttributes sets
   * handleAudioFocus = !mixWithOthers to control whether system-level audio focus is requested
   * (true does not request focus, allowing mixed playback with other apps; false requests exclusive focus).
   *
   * OHOS difference: AVPlayer does not expose a system-level AudioFocusManager interface,
   * but achieves equivalent semantics via the player's audioInterruptMode.
   *   - SHARE_MODE (shared mode): equivalent to Android mixWithOthers=true,
   *     shares with other audio sessions without interrupting other apps' playback.
   *   - INDEPENDENT_MODE (independent mode): equivalent to Android mixWithOthers=false,
   *     the current player holds exclusive audio focus and other audio is paused/attenuated.
   * Note: the system-level focus API (audio.requestAudioFocus) requires the
   * MANAGE_SYSTEM_AUDIO_EFFECTS permission and mainly targets audio.AudioRenderer scenarios; for AVPlayer
   * the officially recommended mixing control is audioInterruptMode, so a player-level implementation is kept here.

   * @param mixWithOthers Whether to mix with other audio playback
   *                      true: shared mode, mix with other audio
   *                      false: exclusive mode, pause other audio
   */
  setAudioFocus(mixWithOthers: boolean): void {
    if (this.avPlayer == null) {
      Log.w(TAG, 'setAudioFocus: avPlayer is null, cannot set audio focus');
      return;
    }
    // Set the interrupt mode based on the mixWithOthers parameter.
    this.interruptMode = mixWithOthers ?
          audio.InterruptMode.SHARE_MODE :
          audio.InterruptMode.INDEPENDENT_MODE;
    // Update the player's audio interrupt mode.
    this.avPlayer.audioInterruptMode = this.interruptMode;

    Log.i(TAG, `setAudioFocus: mixWithOthers=${mixWithOthers}, interruptMode=${this.interruptMode}`);
  }

  usesExternalTexture(): boolean {
    return this.textureEntry != null;
  }

  /**
   * Hands the NativeWindow to this AVPlayer once the PlatformView's XComponent is ready.
   * The texture path already has a surfaceId at construction and never reaches pendingPrepare.
   */
  setSurfaceId(surfaceId: string): void {
    if (surfaceId.length === 0) {
      return;
    }
    this.surfaceId = surfaceId;
    if (this.avPlayer == null) {
      return;
    }
    this.avPlayer.surfaceId = surfaceId;
    if (!this.pendingPrepare) {
      return;
    }
    this.pendingPrepare = false;
    this.avPlayer.prepare().catch((e: Error) => {
      Log.e(TAG, 'deferred prepare failed: ' + JSON.stringify(e));
      this.sendError(e);
    });
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
    // On release, restore the window's original always-on state to avoid
    // leftover screen-on when released directly (without PAUSED/COMPLETED)
    this.status = CommonConstants.STATUS_STOP;
    this.watchStatus();
    try {
      if (this.avPlayer !== null) {
        // Explicitly cancel event subscriptions so callbacks are not triggered after release.
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
      }
    } finally {
      this.avPlayer = null;
      this.finishPreparedWait();
      this.detachEventChannelIfIdle();
      // The plugin opened this fd and is responsible for closing it
      // (AVPlayer does not take ownership). Must close on any exception
      // path in release to avoid fd leaks (Too many open files).
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
      const rawPath = this.rawFilePath;
      const rawMgr = this.assetResourceManager;
      this.rawFilePath = null;
      this.assetResourceManager = null;
      this.rawFile = null;
      if (rawPath != null && rawMgr != null) {
        try {
          await rawMgr.closeRawFd(rawPath);
        } catch (e) {
          Log.w(TAG, 'closeRawFd failed: ' + JSON.stringify(e));
        }
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
        this.pendingReplayAfterSeek = false;
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
        // 0 means the playhead is already at the start; also clear any earlier queued seek.
        this.pendingSeekPosition = position === 0 ? null : position;
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
      // Dart receives an int (milliseconds); truncating avoids cast issues when currentTime is fractional.
      return Math.trunc(Math.max(0, this.avPlayer.currentTime));
    } else {
      return 0;
    }
  }

  async getAudioTracks(): Promise<Array<AudioTrackNativeMap>> {
    if (!this.usesExternalTexture()) {
      await this.waitUntilPrepared();
    }
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
    if (!this.usesExternalTexture()) {
      await this.waitUntilPrepared();
    }
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
    if (!this.usesExternalTexture()) {
      await this.waitUntilPrepared();
    }
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
        // Collect only tracks explicitly typed as video; when the type is unknown,
        // combine with whether a resolution is present to decide, to avoid
        // counting audio/subtitle duplicate variants as video tracks.
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
        // Prefer the OHOS standard MediaDescriptionKey enum keys; otherwise
        // width/height/bitrate values cannot be retrieved.
        const codec = this.getStringFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_CODEC_MIME, 'codec_mime', 'codec', 'codecName', 'codecMimeType']);
        const bitrate = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_BITRATE, 'bit_rate', 'bitrate']);
        const widthRaw = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_WIDTH, 'width', 'video_width']);
        const heightRaw = this.getIntFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_HEIGHT, 'height', 'video_height']);
        // Align with Android Format.NO_VALUE: width/height of 0/negative are
        // treated as no value, avoiding '0x0' display.
        const width = widthRaw != null && widthRaw > 0 ? widthRaw : null;
        const height = heightRaw != null && heightRaw > 0 ? heightRaw : null;
        // Filter out invalid placeholder tracks whose codec
        // contains 'unknown' (e.g. the 0x0 track with track_index=16).
        if (codec != null && codec.toLowerCase().includes('unknown')) {
          continue;
        }
        const rawFrameRate = this.getNumberFromRecord(rec,
          [media.MediaDescriptionKey.MD_KEY_FRAME_RATE, 'frame_rate', 'frameRate', 'framerate']);
        // OHOS MD_KEY_FRAME_RATE is in "frames per 100 seconds" (6000=60fps);
        // divide by 100 to normalize, and treat 0 as no value.
        const frameRate = rawFrameRate != null && rawFrameRate > 0
          ? rawFrameRate / 100
          : null;
        // The video track label prefers a resolution-based value ('1080p'); meaningless
        // titles are filtered out, and when both are missing it is null so the Dart
        // layer shows 'Track x_y'.
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
    if (!this.usesExternalTexture()) {
      await this.waitUntilPrepared();
    }
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
      // After switching video tracks the resolution may change; reset surfaceId to force a renderer refresh.
      if (this.avPlayer.surfaceId) {
        this.avPlayer.surfaceId = this.surfaceId;
      }
      // Notify Dart that the track has switched, completing the selection wait and refreshing the UI.
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
   * OHOS difference: the Android implementation uses TrackSelector to call
   * clearOverridesOfType(C.TRACK_TYPE_VIDEO) to clear the video track override and
   * directly restore adaptive bitrate. OHOS AVPlayer has no equivalent API to
   * "clear a single video track selection" (deselectTrack only supports audio/subtitle
   * tracks), so this restores adaptive behavior by re-selecting the initial default
   * track index, which is semantically equivalent.
   */
  async enableAutoVideoQuality(): Promise<void> {
    if (!this.usesExternalTexture()) {
      await this.waitUntilPrepared();
    }
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
    // loop can only be set after prepared; platformView sends initialized before prepare,
    // So record it here and apply at PREPARED.
    if (this.avPlayer != null && !this.isPrepared) {
      this.loop = isLooping;
      return;
    }
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
      if (!this.isPrepared) {
        this.pendingVolume = clampedVolume;
        return;
      }
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
    if (!this.isPrepared) {
      // platformView sent initialized before prepare; record it here and apply it at PREPARED.
      this.pendingSpeed = playSpeed;
      return;
    }
    if (playSpeed === this.appliedPlaybackSpeed) {
      return;
    }
    if (CommonConstants.OPERATE_STATE.indexOf(this.avPlayer.state) === -1) {
      return;
    }
    this.playerModel.playSpeed = playSpeed;
    this.avPlayer.setSpeed(playSpeed);
    this.appliedPlaybackSpeed = playSpeed;
  }

  /**
   * Previous video.
   */
  previousVideo() {
    if (this.avPlayer == null || this.playerModel == null) {
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
        windowClass.setWindowKeepScreenOn(this.keepScreenOnDuringPlayback); // driven by the platform flag
      } else {
        windowClass.setWindowKeepScreenOn(this.isWindowKeepScreenOn);
      }
    } catch (e) {
      Log.e(TAG, 'setWindowKeepScreenOn failed: ' + JSON.stringify(e));
    }
  }

  setKeepScreenOnDuringPlayback(keepScreenOn: boolean): void {
    this.keepScreenOnDuringPlayback = keepScreenOn;
    // When the flag changes,
    // Immediately refresh the always-on state with the new value without waiting for the next state change.
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
    if (this.initializedSent) {
      return;
    }
    this.initializedSent = true;
    const playerWidth = this.avPlayer != null && this.avPlayer.width > 0 ? this.avPlayer.width : 0;
    const playerHeight = this.avPlayer != null && this.avPlayer.height > 0 ? this.avPlayer.height : 0;
    const playerDuration = this.avPlayer != null && this.avPlayer.duration > 0 ? this.avPlayer.duration : 0;
    let width = playerWidth > 0 ? playerWidth : this.probedWidth;
    let height = playerHeight > 0 ? playerHeight : this.probedHeight;
    const duration = playerDuration > 0 ? playerDuration : this.probedDurationMs;
    let rotation = this.cachedRotationCorrection;
    if (!this.usesExternalTexture() && (rotation === 90 || rotation === 270)) {
      const swapped = width;
      width = height;
      height = swapped;
      rotation = 0;
    }
    Log.i(TAG, 'sendInitialized width=' + width + ' height=' + height + ' rotation=' + rotation);
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'initialized');
    event.set('duration', duration);
    event.set('width', width);
    event.set('height', height);
    event.set('rotationCorrection', rotation);
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
   * OHOS AVPlayer has no onTracksChanged callback, so this is sent proactively after
   * a successful selectVideoTrack / enableAutoVideoQuality for the Dart layer to
   * complete the selection wait and refresh the UI.
   */
  sendVideoTrackChanged(): void {
    let event: HashMap<string, Object> = new HashMap<string, Object>();
    event.set('event', 'videoTrackChanged');
    if (this.selectedVideoTrackIndex < 0) {
      // Restore adaptive mode: no specific track is selected, leaving it empty only drives a UI refresh.
      event.set('selectedTrackId', '');
    } else {
      event.set('selectedTrackId', `0_${this.selectedVideoTrackIndex}`);
    }
    this.eventSink?.success(event);
  }

  private async getRotationCorrection(): Promise<number> {
    let extractor: media.AVMetadataExtractor | null = null;
    let fd: fs.File | null = null;
    let probeRawFd: number = -1;
    try {
      extractor = await media.createAVMetadataExtractor();
      if (this.url?.startsWith('file://')) {
        // Document URIs cannot be duplicated via /proc/self/fd.
        // Open once separately here; not the same fd as the one used for playback.
        probeRawFd = this.openFileUri(this.url);
        extractor.fdSrc = this.descriptorForWholeFile(probeRawFd);
      } else if (this.url?.startsWith('fd://')) {
        // The extractor cannot share the same open file with AVPlayer; open another copy via /proc/self/fd.
        fd = fs.openSync('/proc/self/fd/' + this.url.substring(5), fs.OpenMode.READ_ONLY);
        extractor.fdSrc = { fd: fd.fd, offset: 0, length: 0 };
      } else if (this.url) {
        if (deviceInfo.sdkApiVersion < 20) {
          return 0;
        }
        extractor.setUrlSource(this.url, this.headers ?? undefined);
      } else if (this.rawFile) {
        try {
          fd = fs.openSync('/proc/self/fd/' + this.rawFile.fd, fs.OpenMode.READ_ONLY);
          extractor.fdSrc = { fd: fd.fd, offset: this.rawFile.offset, length: this.rawFile.length };
        } catch (e) {
          Log.w(TAG, 'reopen raw fd for probe failed, use shared fd: ' + JSON.stringify(e));
          extractor.fdSrc = this.rawFile;
        }
      } else {
        return 0;
      }
      const metadata = await extractor.fetchMetadata();
      this.probedWidth = metadata.videoWidth ? parseInt(metadata.videoWidth) : 0;
      this.probedHeight = metadata.videoHeight ? parseInt(metadata.videoHeight) : 0;
      this.probedDurationMs = metadata.duration ? normalizeDurationMs(parseInt(metadata.duration)) : 0;
      const orientation = metadata.videoOrientation ? parseInt(metadata.videoOrientation) : 0;
      if (orientation === 0 || orientation === 90 || orientation === 180 || orientation === 270) {
        return orientation;
      }
      return 0;
    } catch (e) {
      Log.w(TAG, 'getRotationCorrection error: ' + JSON.stringify(e));
      return 0;
    } finally {
      try {
        await extractor?.release();
      } catch (e) {
        Log.w(TAG, 'probe extractor release failed: ' + JSON.stringify(e));
      }
      extractor = null;
      if (fd) {
        fs.closeSync(fd);
      }
      if (probeRawFd >= 0) {
        try {
          fs.closeSync(probeRawFd);
        } catch (closeErr) {
          Log.w(TAG, 'close probe fd failed: ' + JSON.stringify(closeErr));
        }
      }
    }
  }

  /** Whole-file descriptor. When size is 0, length is omitted to avoid treating it as an empty file. */
  private descriptorForWholeFile(fdNumber: number): media.AVFileDescriptor {
    let length = 0;
    try {
      const size = fs.statSync(fdNumber).size;
      if (size > 0) {
        length = size;
      }
    } catch (e) {
      Log.w(TAG, 'stat probe fd failed: ' + JSON.stringify(e));
    }
    const descriptor: media.AVFileDescriptor = { fd: fdNumber, offset: 0 };
    if (length > 0) {
      descriptor.length = length;
    }
    return descriptor;
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

  private isUsablePlaybackUri(uri: string): boolean {
    if (uri.length === 0) {
      return false;
    }
    const fdPrefix = 'fd://';
    if (!uri.startsWith(fdPrefix)) {
      return true;
    }
    const parsed = Number.parseInt(uri.substring(fdPrefix.length));
    return !Number.isNaN(parsed) && parsed >= 0;
  }

  private ignoreOperateErrorBeforePrepare(error: Object): boolean {
    if (this.usesExternalTexture() || this.hasPreparedOnce) {
      return false;
    }
    return (error as BusinessError).code === AVPLAYER_STATE_ERROR;
  }

  private waitUntilPrepared(): Promise<void> {
    if (this.isPrepared || this.avPlayer == null || this.released) {
      return Promise.resolve();
    }
    if (this.preparedPromise == null) {
      this.preparedPromise = new Promise<void>((resolve: () => void) => {
        this.preparedCompleter = resolve;
      });
    }
    const waiting = this.preparedPromise;
    return new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
      const timer = setTimeout(() => {
        reject(new Error('Timed out waiting for AVPlayer prepared'));
      }, PREPARED_WAIT_MS);
      waiting.then(() => {
        clearTimeout(timer);
        resolve();
      });
    });
  }

  private finishPreparedWait(): void {
    const complete = this.preparedCompleter;
    this.preparedCompleter = null;
    this.preparedPromise = null;
    if (complete != null) {
      complete();
    }
  }

  private detachEventChannelIfIdle(): void {
    if (this.eventSink != null && this.eventSink.hasDelegate()) {
      return;
    }
    this.eventChannel?.setStreamHandler(null);
    this.eventChannel = null;
  }

  private openFileUri(fileUri: string): number {
    try {
      return fs.openSync(fileUri, fs.OpenMode.READ_ONLY).fd;
    } catch (e) {
      Log.w(TAG, 'open file uri failed, retry decoded path: ' + JSON.stringify(e));
      let sandboxPath = fileUri.substring('file://'.length);
      try {
        sandboxPath = decodeURIComponent(sandboxPath);
      } catch (decodeErr) {
        Log.w(TAG, 'decode file uri failed: ' + JSON.stringify(decodeErr));
      }
      Log.i(TAG, 'retry open sandbox path: ' + sandboxPath);
      return fs.openSync(sandboxPath, fs.OpenMode.READ_ONLY).fd;
    }
  }

  getUri(): string {
    let iUrl = this.url;
    const ohosFilePrefix = 'file://';
    const fdPrefix = 'fd://';
    if (iUrl != null && iUrl.startsWith(fdPrefix)) {
      // Externally passed fd (opened by the plugin's getFileFdByPath); record it to close on release.
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
        this.fd = this.openFileUri(iUrl);
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
  private eventChannel: EventChannel | null = null;

  constructor(eventSink: QueuingEventSink, eventChannel: EventChannel | null) {
    this.eventSink = eventSink;
    this.eventChannel = eventChannel;
  }

  onListen(args: Object, events: EventSink): void {
    this.eventSink?.setDelegate(events);
  }

  onCancel(args: Object): void {
    this.eventSink?.setDelegate(null);
    // Dart cancels before dispose. Detaching the handler early in release
    // Would make cancel unable to find the implementation.
    this.eventChannel?.setStreamHandler(null);
    this.eventChannel = null;
  }
}
