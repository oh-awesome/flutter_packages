/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Shared mocks and helpers for the camera_ohos ArkTS unit test suites.
// Mock classes only record calls; system types reached through test-only code are
// approximated with empty shells cast via ESObject, mirroring upstream plugin tests.

import { BinaryMessenger, BinaryReply, BinaryMessageHandler, TaskQueue, TaskQueueOptions } from
  '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import SendableBinaryMessageHandler from
  '@ohos/flutter_ohos/src/main/ets/plugin/common/SendableBinaryMessageHandler';
import Any from '@ohos/flutter_ohos/src/main/ets/plugin/common/Any';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import Ability from '@ohos.app.ability.Ability';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import camera from '@ohos.multimedia.camera';
import image from '@ohos.multimedia.image';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import {
  AbilityPluginBinding,
  NewWantListener,
  WindowFocusChangedListener,
  OnSaveStateListener
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { FlutterPluginBinding, FlutterAssets } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import FlutterEngine from '@ohos/flutter_ohos/src/main/ets/embedding/engine/FlutterEngine';
import { TextureRegistry, SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { CameraProperties } from '../../../main/ets/io/flutter/plugins/camera/CameraProperties';
import { CameraCaptureStateListener } from
  '../../../main/ets/io/flutter/plugins/camera/CameraCaptureCallback';
import { FlutterError, Result } from '../../../main/ets/io/flutter/plugins/camera/Messages';

export const PIGEON_CAMERA_API_PREFIX: string = 'dev.flutter.pigeon.camera_ohos.CameraApi.';
export const PIGEON_GLOBAL_EVENT_PREFIX: string =
  'dev.flutter.pigeon.camera_ohos.CameraGlobalEventApi.';

class MockTaskQueue implements TaskQueue {
}

export class MockBinaryMessenger implements BinaryMessenger {
  handlers: Map<string, BinaryMessageHandler | SendableBinaryMessageHandler> = new Map();
  sentChannels: Array<string> = new Array<string>();
  sendCount: number = 0;
  lastPayload: ArrayBuffer | null = null;

  makeBackgroundTaskQueue(_options?: TaskQueueOptions): TaskQueue {
    return new MockTaskQueue();
  }

  send(channel: String, message: ArrayBuffer | null, _callback?: BinaryReply | null): void {
    this.sendCount++;
    this.sentChannels.push(channel.toString());
    if (message != null) {
      this.lastPayload = message;
    }
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | SendableBinaryMessageHandler |
    null, _taskQueue?: TaskQueue, ..._args: Object[]): void {
    const key: string = channel.toString();
    if (handler == null) {
      this.handlers.delete(key);
    } else {
      this.handlers.set(key, handler);
    }
  }

  countPigeonHandlers(): number {
    let count: number = 0;
    this.handlers.forEach((_value: BinaryMessageHandler | SendableBinaryMessageHandler,
      key: string): void => {
      if (key.startsWith(PIGEON_CAMERA_API_PREFIX)) {
        count++;
      }
    });
    return count;
  }

  hasHandler(channelName: string): boolean {
    return this.handlers.has(channelName);
  }

  countTotalHandlers(): number {
    return this.handlers.size;
  }
}

// Do-nothing handler used as a sentinel when verifying channel teardown.
export class StubBinaryMessageHandler implements BinaryMessageHandler {
  onMessage(_message: ArrayBuffer, _reply: BinaryReply): void {
  }
}

export class StubVoidReply implements Reply<void> {
  replyCallCount: number = 0;

  reply: (reply: void) => void = (_reply: void): void => {
    this.replyCallCount++;
  };
}

export class MockMethodResult implements MethodResult {
  successArgs: Array<Any> = new Array<Any>();
  errorCodes: Array<string> = new Array<string>();
  errorMessages: Array<string> = new Array<string>();
  errorDetails: Array<Any> = new Array<Any>();
  notImplementedCount: number = 0;

  success: (result: Any) => void = (result: Any): void => {
    this.successArgs.push(result);
  };

  error: (errorCode: string, errorMessage: string, errorDetails: Any) => void =
    (errorCode: string, errorMessage: string, errorDetails: Any): void => {
      this.errorCodes.push(errorCode);
      this.errorMessages.push(errorMessage);
      this.errorDetails.push(errorDetails);
    };

  notImplemented: () => void = (): void => {
    this.notImplementedCount++;
  };
}

// Records Pigeon Result<T> callbacks; the guard suites assert the captured
// FlutterError.code through the raw Error reference (FlutterError carries a
// public code field).
export class StubPigeonResult<T> implements Result<T> {
  successCount: number = 0;
  errors: Array<Error> = new Array<Error>();

  success(_result: T): void {
    this.successCount++;
  }

  error(error: Error): void {
    this.errors.push(error);
  }

  firstErrorCode(): string {
    if (this.errors.length == 0) {
      return '(no error captured)';
    }
    return (this.errors[0] as FlutterError).code;
  }
}

export class StubCameraProperties implements CameraProperties {
  public cameraName: string = 'emulated';
  public lensFacing: number = camera.CameraPosition.CAMERA_POSITION_BACK;
  public sensorOrientationValue: number = 90;
  public maxRegionsAutoExposure: number = 1;
  public maxRegionsAutoFocus: number = 1;

  getCameraName(): string {
    return this.cameraName;
  }

  getControlMaxRegionsAutoExposure(): number {
    return this.maxRegionsAutoExposure;
  }

  getControlMaxRegionsAutoFocus(): number {
    return this.maxRegionsAutoFocus;
  }

  getLensFacing(): number {
    return this.lensFacing;
  }

  getSensorOrientation(): number {
    return this.sensorOrientationValue;
  }
}

class ContextShell {
}

class ApplicationContextShell extends ContextShell {
  getApplicationContext(): common.Context {
    return (new ContextShell() as ESObject) as common.Context;
  }
}

export function makeFakeContext(): common.Context {
  return (new ContextShell() as ESObject) as common.Context;
}

class AbilityShell {
}

export function makeFakeAbility(): Ability {
  return (new AbilityShell() as ESObject) as Ability;
}

class UIAbilityShell {
  context: ApplicationContextShell = new ApplicationContextShell();
}

export class MockAbilityBinding implements AbilityPluginBinding {
  getAbility(): UIAbility {
    return (new UIAbilityShell() as ESObject) as UIAbility;
  }

  addOnNewWantListener(_listener: NewWantListener): void {
  }

  removeOnNewWantListener(_listener: NewWantListener): void {
  }

  addOnWindowFocusChangedListener(_listener: WindowFocusChangedListener): void {
  }

  removeOnWindowFocusChangedListener(_listener: WindowFocusChangedListener): void {
  }

  addOnSaveStateListener(_listener: OnSaveStateListener): void {
  }

  removeOnSaveStateListener(_listener: OnSaveStateListener): void {
  }
}

class EngineShell {
}

class AssetsShell {
}

class TextureRegistryShell {
}

export function createMockPluginBinding(messenger: BinaryMessenger): FlutterPluginBinding {
  const engine: FlutterEngine = (new EngineShell() as ESObject) as FlutterEngine;
  const assets: FlutterAssets = (new AssetsShell() as ESObject) as FlutterAssets;
  const textureRegistry: TextureRegistry =
    (new TextureRegistryShell() as ESObject) as TextureRegistry;
  return new FlutterPluginBinding(makeFakeContext(), engine, messenger, assets, textureRegistry);
}

export function makeFakeTextureRegistry(): TextureRegistry {
  return (new TextureRegistryShell() as ESObject) as TextureRegistry;
}

class SurfaceTextureEntryShell {
}

export function makeFakeSurfaceTextureEntry(): SurfaceTextureEntry {
  return (new SurfaceTextureEntryShell() as ESObject) as SurfaceTextureEntry;
}

export function makeProfile(width: number, height: number): camera.Profile {
  const size: camera.Size = { width: width, height: height };
  const profile: camera.Profile = { format: 1003, size: size };
  return profile;
}

// Builds a VideoProfile literal; when minFps/maxFps are omitted the frameRateRange
// field stays undefined so callers can exercise the null-range branches.
export function makeVideoProfile(width: number, height: number, minFps?: number,
  maxFps?: number): camera.VideoProfile {
  const size: camera.Size = { width: width, height: height };
  if (minFps === undefined || maxFps === undefined) {
    return ({ format: 1003, size: size } as ESObject) as camera.VideoProfile;
  }
  const range: camera.FrameRateRange = { min: minFps, max: maxFps };
  return ({ format: 1003, size: size, frameRateRange: range } as ESObject) as camera.VideoProfile;
}

export const CAMERA_POSITION_BACK_VALUE: number = 1;
export const CAMERA_POSITION_FRONT_VALUE: number = 2;

class FakeCameraManagerShell {
  private readonly devices: Array<camera.CameraDevice>;

  constructor(devices: Array<camera.CameraDevice>) {
    this.devices = devices;
  }

  getSupportedCameras(): Array<camera.CameraDevice> {
    return this.devices;
  }
}

export class ThrowingCameraManagerShell {
  getSupportedCameras(): Array<camera.CameraDevice> {
    throw new Error('camera service unavailable');
  }
}

export function makeFakeCameraManager(devices: Array<camera.CameraDevice>): camera.CameraManager {
  return (new FakeCameraManagerShell(devices) as ESObject) as camera.CameraManager;
}

export function makeThrowingCameraManager(): camera.CameraManager {
  return (new ThrowingCameraManagerShell() as ESObject) as camera.CameraManager;
}

export function makeFakeDevice(cameraId: string, position: number, orientation: number):
  camera.CameraDevice {
  return ({
    cameraId: cameraId,
    connectionType: 0,
    cameraPosition: position,
    cameraOrientation: orientation,
    deviceType: 0,
    connectionId: 0
  } as ESObject) as camera.CameraDevice;
}

export function sleepMs(ms: number): Promise<void> {
  return new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, ms);
  });
}

export async function waitUntil(predicate: () => boolean, timeoutMs: number): Promise<boolean> {
  const started: number = Date.now();
  while (!predicate()) {
    if (Date.now() - started >= timeoutMs) {
      return false;
    }
    await sleepMs(20);
  }
  return true;
}

// ---------------------------------------------------------------------------
// Session shells: CameraUtils and several features only dereference a handful
// of query methods on their PhotoSession/VideoSession parameters, so concrete
// shells providing just those methods suffice when cast through ESObject.
// ---------------------------------------------------------------------------

class RangesSessionShell {
  private readonly zoomRange: Array<number>;
  private readonly biasRange: Array<number>;

  constructor(zoomRange: Array<number>, biasRange: Array<number>) {
    this.zoomRange = zoomRange;
    this.biasRange = biasRange;
  }

  getZoomRatioRange(): Array<number> {
    return this.zoomRange;
  }

  getExposureBiasRange(): Array<number> {
    return this.biasRange;
  }
}

export function makeQuerySession(zoomRange: Array<number>, biasRange: Array<number>): camera.PhotoSession {
  return (new RangesSessionShell(zoomRange, biasRange) as ESObject) as camera.PhotoSession;
}

export class ThrowingRangesSessionShell {
  getZoomRatioRange(): Array<number> {
    throw new Error('zoom query failed');
  }

  getExposureBiasRange(): Array<number> {
    throw new Error('bias query failed');
  }
}

export function makeThrowingQuerySession(): camera.PhotoSession {
  return (new ThrowingRangesSessionShell() as ESObject) as camera.PhotoSession;
}

class FlashSessionShell {
  readonly hasFlashValue: boolean;
  readonly flashModeSupported: boolean;
  readonly exposureModeSupported: boolean;

  constructor(hasFlashValue: boolean, flashModeSupported: boolean, exposureModeSupported: boolean) {
    this.hasFlashValue = hasFlashValue;
    this.flashModeSupported = flashModeSupported;
    this.exposureModeSupported = exposureModeSupported;
  }

  hasFlash(): boolean {
    return this.hasFlashValue;
  }

  isFlashModeSupported(_mode: camera.FlashMode): boolean {
    return this.flashModeSupported;
  }

  isExposureModeSupported(_mode: camera.ExposureMode): boolean {
    return this.exposureModeSupported;
  }
}

export function makeFlashSession(hasFlash: boolean, flashModeSupported: boolean,
  exposureModeSupported: boolean): camera.PhotoSession {
  const shell: FlashSessionShell =
    new FlashSessionShell(hasFlash, flashModeSupported, exposureModeSupported);
  return (shell as ESObject) as camera.PhotoSession;
}

export class CrashingFlashSessionShell {
  hasFlash(): boolean {
    throw new Error('hasFlash failed');
  }
}

export function makeCrashingFlashSession(): camera.PhotoSession {
  return (new CrashingFlashSessionShell() as ESObject) as camera.PhotoSession;
}

// Records every stabilization mode applied, so tests can assert which level of
// the fallback chain (direct -> AUTO -> OFF) updateBuilder settled on.
class VideoSessionShell {
  private readonly supported: Array<camera.VideoStabilizationMode>;

  constructor(supported: Array<camera.VideoStabilizationMode>) {
    this.supported = supported;
  }

  isVideoStabilizationModeSupported(mode: camera.VideoStabilizationMode): boolean {
    return this.supported.indexOf(mode) >= 0;
  }

  setVideoStabilizationMode(mode: camera.VideoStabilizationMode): void {
    shellAppliedModes.push(mode);
  }
}

export const shellAppliedModes: Array<camera.VideoStabilizationMode> =
  new Array<camera.VideoStabilizationMode>();

export function makeFakeVideoSession(supported: Array<camera.VideoStabilizationMode>): camera.Session {
  shellAppliedModes.length = 0;
  return (new VideoSessionShell(supported) as ESObject) as camera.Session;
}

// Session whose every stabilization call throws; updateBuilder must swallow it.
export class CrashingVideoSessionShell {
  isVideoStabilizationModeSupported(_mode: camera.VideoStabilizationMode): boolean {
    throw new Error('stabilization query failed');
  }
}

export function makeCrashingVideoSession(): camera.Session {
  shellAppliedModes.length = 0;
  return (new CrashingVideoSessionShell() as ESObject) as camera.Session;
}

// ---------------------------------------------------------------------------
// EventSink / image shells for ImageStreamReader parameter-injected methods.
// ---------------------------------------------------------------------------

export class StubEventSink implements EventSink {
  successEvents: Array<Any> = new Array<Any>();
  errorCodes: Array<string> = new Array<string>();
  errorMessages: Array<string> = new Array<string>();
  endOfStreamCount: number = 0;

  success(event: Any): void {
    this.successEvents.push(event);
  }

  error(errorCode: string, errorMessage: string, _errorDetails: Any): void {
    this.errorCodes.push(errorCode);
    this.errorMessages.push(errorMessage);
  }

  endOfStream(): void {
    this.endOfStreamCount++;
  }
}

export class FakeImageComponent {
  // Field names must match the image.Component interface: parsePlanes reads
  // rowStride/pixelStride/byteBuffer off the cast shell at runtime.
  readonly rowStride: number;
  readonly pixelStride: number;
  readonly byteBuffer: ArrayBuffer;

  constructor(rowStride: number, pixelStride: number, bufferLength: number) {
    this.rowStride = rowStride;
    this.pixelStride = pixelStride;
    this.byteBuffer = new ArrayBuffer(bufferLength);
  }
}

export function makeFakeComponent(rowStride: number, pixelStride: number,
  bufferLength: number): image.Component {
  const shell: FakeImageComponent = new FakeImageComponent(rowStride, pixelStride, bufferLength);
  return (shell as ESObject) as image.Component;
}

export class FakeImageShell {
  // Field name must match image.Image: onImageAvailable reads _image.size.
  readonly size: image.Size;
  releaseCount: number = 0;

  constructor(width: number, height: number) {
    this.size = { width: width, height: height };
  }

  async release(): Promise<void> {
    this.releaseCount++;
  }
}

export function makeFakeImage(width: number, height: number): image.Image {
  return (new FakeImageShell(width, height) as ESObject) as image.Image;
}

export function fakeImageReleaseCount(fake: image.Image): number {
  return ((fake as ESObject) as FakeImageShell).releaseCount;
}

// ---------------------------------------------------------------------------
// CameraCaptureCallback listener stub.
// ---------------------------------------------------------------------------

export class StubCaptureStateListener implements CameraCaptureStateListener {
  convergedCount: number = 0;
  precaptureCount: number = 0;

  onConverged(): void {
    this.convergedCount++;
  }

  onPrecapture(): void {
    this.precaptureCount++;
  }
}
