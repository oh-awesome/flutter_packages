/*
* Copyright 2013 The Flutter Authors. All rights reserved.
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
*/
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger,TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error name. */
  public name: string;

  /** The error message. */
  public message: string;
  /** The error stack. */
  public stack?: string;

  constructor(code: string, name: string,  message: string, stack: string) 
  {
    this.code = code;
    this.name = name;
    this.message = message;
    this.stack = stack;
  }
}

function wrapError(error: Error): Array<Object> {
  let errorList: Array<Object> = new Array<Object>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.name;
    errorList[2] = err.message;
  } else {
    errorList[0] = error.toString();
    errorList[1] = error.name;
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}

/* Pigeon equivalent of [CameraLensDirection].*/
export enum PlatformCameraLensDirection {
  front,
  back,
  external
}

/* Pigeon equivalent of [DeviceOrientation].*/
export enum PlatformDeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight
}

/* Pigeon equivalent of [ExposureMode].*/
export enum PlatformExposureMode {
  auto,
  locked
}

/* Pigeon equivalent of [FocusMode].*/
export enum PlatformFocusMode {
  auto,
  locked
}

/* Pigeon equivalent of [ResolutionPreset].*/
export enum PlatformResolutionPreset {
  low,
  medium,
  high,
  veryHigh,
  ultraHigh,
  max
}

/* Pigeon equivalent of [ImageFormatGroup].*/
export enum PlatformImageFormatGroup {
  /* The default for Android.*/
  yuv420,
  jpeg,
  nv21
}

/* Pigeon equivalent of [FlashMode].*/
export enum PlatformFlashMode {
  off,
  auto,
  always,
  torch
}

/*
*  Pigeon equivalent of [CameraDescription].
* 
*  Generated class from Pigeon that represents data sent in messages.
*/
export class PlatformCameraDescription {
  private name: string;

  getName(): string {
    return this.name;
  }

  private lensDirection: PlatformCameraLensDirection;

  getLensDirection(): PlatformCameraLensDirection {
    return this.lensDirection;
  }

  private sensorOrientation: number;

  getSensorOrientation(): number {
    return this.sensorOrientation;
  }

  constructor(name: string, lensDirection: PlatformCameraLensDirection, sensorOrientation: number) {
    this.name = name;
    this.lensDirection = lensDirection;
    this.sensorOrientation = sensorOrientation;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    arr.push(this.name);
    arr.push(this.lensDirection);
    arr.push(this.sensorOrientation);
    return arr;
  }

  static fromList(arr: Object[]): PlatformCameraDescription {
    let instance: PlatformCameraDescription = new PlatformCameraDescription(arr[0] as string, PlatformCameraLensDirection[PlatformCameraLensDirection[arr[1] as number]], arr[2] as number);
    return instance;
  }
}

/*
*  Data needed for [CameraInitializedEvent].
* 
*  Generated class from Pigeon that represents data sent in messages.
*/
export class PlatformCameraState {
  private previewSize: PlatformSize | null;

  getPreviewSize(): PlatformSize | null {
    return this.previewSize;
  }

  private exposureMode: PlatformExposureMode;

  getExposureMode(): PlatformExposureMode {
    return this.exposureMode;
  }

  private focusMode: PlatformFocusMode;

  getFocusMode(): PlatformFocusMode {
    return this.focusMode;
  }

  private exposurePointSupported: boolean;

  getExposurePointSupported(): boolean {
    return this.exposurePointSupported;
  }

  private focusPointSupported: boolean;

  getFocusPointSupported(): boolean {
    return this.focusPointSupported;
  }

  constructor(previewSize: PlatformSize | null, exposureMode: PlatformExposureMode, focusMode: PlatformFocusMode, exposurePointSupported: boolean, focusPointSupported: boolean) {
    this.previewSize = previewSize;
    this.exposureMode = exposureMode;
    this.focusMode = focusMode;
    this.exposurePointSupported = exposurePointSupported;
    this.focusPointSupported = focusPointSupported;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    if (this.previewSize === null) {
      arr.push(-1);
    } else if (this.previewSize instanceof Array) {
      arr.push(this.previewSize);
    } else {
      arr.push(this.previewSize.toList());
    }
    arr.push(this.exposureMode);
    arr.push(this.focusMode);
    arr.push(this.exposurePointSupported);
    arr.push(this.focusPointSupported);
    return arr;
  }

  static fromList(arr: Object[]): PlatformCameraState {
    let previewSize: PlatformSize | null = null;
    if (arr[0] !== -1 && arr[0] instanceof Array) {
      previewSize = PlatformSize.fromList(arr[0] as Object[]);
    }
    let instance: PlatformCameraState = new PlatformCameraState(
      previewSize, 
      PlatformExposureMode[PlatformExposureMode[arr[1] as number]], 
      PlatformFocusMode[PlatformFocusMode[arr[2] as number]], 
      arr[3] as boolean, 
      arr[4] as boolean
    );
    return instance;
  }
}

/*
*  Pigeon equivalent of [Size].
* 
*  Generated class from Pigeon that represents data sent in messages.
*/
export class PlatformSize {
  private width: number;

  getWidth(): number {
    return this.width;
  }

  private height: number;

  getHeight(): number {
    return this.height;
  }

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    arr.push(Math.round(this.width));
    arr.push(Math.round(this.height));
    return arr;
  }

  static fromList(arr: Object[]): PlatformSize {
    let instance: PlatformSize = new PlatformSize(
      Math.round(arr[0] as number),
      Math.round(arr[1] as number)
    );
    return instance;
  }
}

/*
*  Pigeon equivalent of [Point].
* 
*  Generated class from Pigeon that represents data sent in messages.
*/
export class PlatformPoint {
  private x: number;

  getX(): number {
    return this.x;
  }

  private y: number;

  getY(): number {
    return this.y;
  }

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    arr.push(Math.round(this.x));
    arr.push(Math.round(this.y));
    return arr;
  }

  static fromList(arr: Object[]): PlatformPoint {
    let instance: PlatformPoint = new PlatformPoint(
      Math.round(arr[0] as number),
      Math.round(arr[1] as number)
    );
    return instance;
  }
}

/*
*  Pigeon equivalent of [MediaSettings].
* 
*  Generated class from Pigeon that represents data sent in messages.
*/
export class PlatformMediaSettings {
  private resolutionPreset: PlatformResolutionPreset;

  getResolutionPreset(): PlatformResolutionPreset {
    return this.resolutionPreset;
  }

  private fps: number;

  getFps(): number {
    return this.fps;
  }

  private videoBitrate: number;

  getVideoBitrate(): number {
    return this.videoBitrate;
  }

  private audioBitrate: number;

  getAudioBitrate(): number {
    return this.audioBitrate;
  }

  private enableAudio: boolean;

  getEnableAudio(): boolean {
    return this.enableAudio;
  }

  constructor(resolutionPreset: PlatformResolutionPreset, fps: number, videoBitrate: number, audioBitrate: number, enableAudio: boolean) {
    this.resolutionPreset = resolutionPreset;
    this.fps = fps;
    this.videoBitrate = videoBitrate;
    this.audioBitrate = audioBitrate;
    this.enableAudio = enableAudio;
  }

  toList(): Object[] {
    let arr: Object[] = new Array();
    arr.push(this.resolutionPreset);
    arr.push(this.fps);
    arr.push(this.videoBitrate);
    arr.push(this.audioBitrate);
    arr.push(this.enableAudio);
    return arr;
  }

  static fromList(arr: Object[]): PlatformMediaSettings {
    let instance: PlatformMediaSettings = new PlatformMediaSettings(PlatformResolutionPreset[PlatformResolutionPreset[arr[0] as number]], arr[1] as number, arr[2] as number, arr[3] as number, arr[4] as boolean);
    return instance;
  }
}

export interface Result<T> {
  success( result: T ): void;

  error( error: Error): void;
}

class CameraApiCodec extends StandardMessageCodec {
  static INSTANCE: CameraApiCodec = new CameraApiCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(128):
        return PlatformCameraDescription.fromList(super.readValue(buffer));
      case this.getByte(129):
        return PlatformMediaSettings.fromList(super.readValue(buffer));
      case this.getByte(130):
        return PlatformPoint.fromList(super.readValue(buffer));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof PlatformCameraDescription) {
      stream.writeUint8(this.getByte(128));
      this.writeValue(stream, (value as PlatformCameraDescription).toList());
    } else if (value instanceof PlatformMediaSettings) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, (value as PlatformMediaSettings).toList());
    } else if (value instanceof PlatformPoint) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, (value as PlatformPoint).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/*
*  Handles calls from Dart to the native side.
* 
*  Generated abstract class from Pigeon that represents a handler of messages from Flutter.
*/
export abstract class CameraApi {
  /* Returns the list of available cameras.*/
  abstract getAvailableCameras(): Array<PlatformCameraDescription>;
  /* Creates a new camera with the given name and settings and returns its ID.*/
  abstract create(cameraName: string , mediaSettings: PlatformMediaSettings , result: Result<number>): void;
  /* Initializes the camera with the given ID for the given image format.*/
  abstract initialize(imageFormat: PlatformImageFormatGroup ): void;
  /* Disposes of the camera with the given ID.*/
  abstract dispose(): void;
  /* Locks the camera with the given ID to the given orientation.*/
  abstract lockCaptureOrientation(orientation: PlatformDeviceOrientation ): void;
  /* Unlocks the orientation for the camera with the given ID.*/
  abstract unlockCaptureOrientation(): void;
  /*
  *  Takes a picture on the camera with the given ID and returns a path to the
  *  resulting file.
  */
  abstract takePicture(result: Result<string>): void;
  /* Starts recording a video on the camera with the given ID.*/
  abstract startVideoRecording(enableStream: boolean ): void;
  /*
  *  Ends video recording on the camera with the given ID and returns the path
  *  to the resulting file.
  */
  abstract stopVideoRecording(): string;
  /* Pauses video recording on the camera with the given ID.*/
  abstract pauseVideoRecording(): void;
  /* Resumes previously paused video recording on the camera with the given ID.*/
  abstract resumeVideoRecording(): void;
  /* Begins streaming frames from the camera.*/
  abstract startImageStream(): void;
  /* Stops streaming frames from the camera.*/
  abstract stopImageStream(): void;
  /* Sets the flash mode of the camera with the given ID.*/
  abstract setFlashMode(flashMode: PlatformFlashMode , result: Result<void>): void;
  /* Sets the exposure mode of the camera with the given ID.*/
  abstract setExposureMode(exposureMode: PlatformExposureMode , result: Result<void>): void;
  /*
  *  Sets the exposure point of the camera with the given ID.
  * 
  *  A null value resets to the default exposure point.
  */
  abstract setExposurePoint(point: PlatformPoint , result: Result<void>): void;
  /* Returns the minimum exposure offset of the camera with the given ID.*/
  abstract getMinExposureOffset(): number;
  /* Returns the maximum exposure offset of the camera with the given ID.*/
  abstract getMaxExposureOffset(): number;
  /* Returns the exposure step size of the camera with the given ID.*/
  abstract getExposureOffsetStepSize(): number;
  /*
  *  Sets the exposure offset of the camera with the given ID and returns the
  *  actual exposure offset.
  */
  abstract setExposureOffset(offset: number , result: Result<number>): void;
  /* Sets the focus mode of the camera with the given ID.*/
  abstract setFocusMode(focusMode: PlatformFocusMode ): void;
  /*
  *  Sets the focus point of the camera with the given ID.
  * 
  *  A null value resets to the default focus point.
  */
  abstract setFocusPoint(point: PlatformPoint , result: Result<void>): void;
  /* Returns the maximum zoom level of the camera with the given ID.*/
  abstract getMaxZoomLevel(): number;
  /* Returns the minimum zoom level of the camera with the given ID.*/
  abstract getMinZoomLevel(): number;
  /* Sets the zoom level of the camera with the given ID.*/
  abstract setZoomLevel(zoom: number , result: Result<void>): void;
  /* Pauses streaming of preview frames.*/
  abstract pausePreview(): void;
  /* Resumes previously paused streaming of preview frames.*/
  abstract resumePreview(): void;
  /*
  *  Changes the camera while recording video.
  * 
  *  This should be called only while video recording is active.
  */
  abstract setDescriptionWhileRecording(description: string ): void;
  /** The codec used by CameraApi. */
  static getCodec(): MessageCodec<Object>{
    return CameraApiCodec.INSTANCE;
  }
  /*Sets up an instance of `CameraApi` to handle messages through the `binaryMessenger`.*/
  static setUp(binaryMessenger: BinaryMessenger, api: CameraApi | null): void {
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getAvailableCameras", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: Array<PlatformCameraDescription> = api!.getAvailableCameras();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.create", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<number>{
                    success(result: number): void {
                      let res: Array<Object> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<number> = new ResultImp();

              api!.create(args[0] as string, args[1] as PlatformMediaSettings, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.initialize", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.initialize(args[0] as PlatformImageFormatGroup);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.dispose", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.dispose();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.lockCaptureOrientation", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.lockCaptureOrientation(args[0] as PlatformDeviceOrientation);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.unlockCaptureOrientation", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.unlockCaptureOrientation();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.takePicture", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              api!.takePicture(resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.startVideoRecording", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.startVideoRecording(args[0] as boolean);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.stopVideoRecording", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: string = api!.stopVideoRecording();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.pauseVideoRecording", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.pauseVideoRecording();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.resumeVideoRecording", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.resumeVideoRecording();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.startImageStream", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.startImageStream();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.stopImageStream", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.stopImageStream();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setFlashMode", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.setFlashMode(args[0] as PlatformFlashMode, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setExposureMode", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.setExposureMode(args[0] as PlatformExposureMode, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setExposurePoint", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.setExposurePoint(args[0] as PlatformPoint, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getMinExposureOffset", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: number = api!.getMinExposureOffset();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getMaxExposureOffset", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: number = api!.getMaxExposureOffset();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getExposureOffsetStepSize", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: number = api!.getExposureOffsetStepSize();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setExposureOffset", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<number>{
                    success(result: number): void {
                      let res: Array<Object> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<number> = new ResultImp();

              api!.setExposureOffset(args[0] as number, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setFocusMode", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setFocusMode(args[0] as PlatformFocusMode);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setFocusPoint", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.setFocusPoint(args[0] as PlatformPoint, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getMaxZoomLevel", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: number = api!.getMaxZoomLevel();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.getMinZoomLevel", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                let output: number = api!.getMinZoomLevel();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setZoomLevel", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              class ResultImp implements Result<void>{
                    success(result: void): void {
                      let res: Array<Object> = [];
                      res.push(null);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<void> = new ResultImp();

              api!.setZoomLevel(args[0] as number, resultCallback);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.pausePreview", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.pausePreview();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.resumePreview", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object> = [];
              try {
                api!.resumePreview();
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraApi.setDescriptionWhileRecording", CameraApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let args: Array<Object> = message as Array<Object>;
              let res: Array<Object> = [];
              try {
                api!.setDescriptionWhileRecording(args[0] as string);
                res.push(null);
              }
 catch (error) {
                let wrappedError: Array<Object> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/*
*  Handles calls from native side to Dart that are not camera-specific.
* 
*  Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.
*/
export class CameraGlobalEventApi {
  binaryMessenger: BinaryMessenger;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The codec used by CameraGlobalEventApi. */
  static getCodec(): MessageCodec<Object> {
    return new StandardMessageCodec();
  }

  /* Called when the device's physical orientation changes.*/
  deviceOrientationChanged(orientationArg: PlatformDeviceOrientation, callback: Reply<void>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraGlobalEventApi.deviceOrientationChanged", CameraGlobalEventApi.getCodec());
    channel.send(
        [orientationArg],
        channelReply => callback.reply(null));
  }
}

class CameraEventApiCodec extends StandardMessageCodec {
  static INSTANCE: CameraEventApiCodec = new CameraEventApiCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }

  readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(128):
        return PlatformCameraState.fromList(super.readValue(buffer));
      case this.getByte(129):
        return PlatformSize.fromList(super.readValue(buffer));
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value instanceof PlatformCameraState) {
      stream.writeUint8(this.getByte(128));
      this.writeValue(stream, (value as PlatformCameraState).toList());
    } else if (value instanceof PlatformSize) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, (value as PlatformSize).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}

/*
*  Handles device-specific calls from native side to Dart.
* 
*  Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.
*/
export class CameraEventApi {
  binaryMessenger: BinaryMessenger;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The codec used by CameraEventApi. */
  static getCodec(): MessageCodec<Object> {
    return CameraEventApiCodec.INSTANCE;
  }

  /* Called when the camera is initialized.*/
  initialized(initialStateArg: PlatformCameraState, callback: Reply<void>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraEventApi.initialized", CameraEventApi.getCodec());
    channel.send(
        [initialStateArg],
        channelReply => callback.reply(null));
  }
  /* Called when an error occurs in the camera.*/
  error(messageArg: string, callback: Reply<void>) {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraEventApi.error", CameraEventApi.getCodec());
    channel.send(
        [messageArg],
        channelReply => callback.reply(null));
  }
  /* Called when the camera closes.*/
  closed(callback: Reply<void>):void {
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, "dev.flutter.pigeon.camera_ohos.CameraEventApi.closed", CameraEventApi.getCodec());
    channel.send(
        null,
        channelReply => callback.reply(null));
  }
}
