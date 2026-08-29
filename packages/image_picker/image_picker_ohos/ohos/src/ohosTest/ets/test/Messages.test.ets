// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Messages.ets Pigeon 编解码类（toList/fromList 往返、null-guard、limit 钳制、wrapError）。

import { describe, it, expect } from '@ohos/hypium';
import ArrayList from '@ohos.util.ArrayList';
import Messages, {
  GeneralOptions,
  ImageSelectionOptions,
  VideoSelectionOptions,
  MediaSelectionOptions,
  SourceSpecification,
  SourceCamera,
  SourceType,
  CacheRetrievalError,
  CacheRetrievalErrorBuilder,
  CacheRetrievalResult,
  CacheRetrievalResultBuilder,
  CacheRetrievalType,
  ImagePickerApi,
  ImagePickerApiCodec,
  FlutterError,
  MAX_SELECT_NUMBER,
  Result
} from '../../../main/ets/image_picker/Messages';
import { BinaryMessenger, BinaryMessageHandler, BinaryReply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';

function listOf(values: ESObject[]): ArrayList<ESObject> {
  const list: ArrayList<ESObject> = new ArrayList<ESObject>();
  values.forEach((v: ESObject) => {
    list.add(v);
  });
  return list;
}

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

// 捕获 setMessageHandler 注册的 handler 的 fake messenger，用于向 Pigeon 通道注入并分发消息，
// 从而执行 ImagePickerApi.setup 中 4 个 onMessage 处理闭包（真实引擎环境下才可达的代码路径）。
// setup 按固定顺序注册 4 条通道（pickImages/pickVideos/pickMedia/retrieveLostResults），
// 故以索引方式取用，规避 ArkTS String↔string 映射键类型摩擦。
class CapturingMessenger {
  handlers: BinaryMessageHandler[] = [];
  setMessageHandlerCount: number = 0;

  send(channel: String, message: ArrayBuffer | null, callback?: BinaryReply | null): void {
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler | null): void {
    this.setMessageHandlerCount++;
    if (handler != null) {
      this.handlers.push(handler);
    }
  }
}

class FakeImagePickerApi extends ImagePickerApi {
  pickImagesCount: number = 0;
  pickVideosCount: number = 0;
  pickMediaCount: number = 0;
  retrieveLostCount: number = 0;
  // true 时 pickImages/pickVideos/pickMedia 回调 result.error，覆盖 setup 中 3 个错误回包闭包
  emitError: boolean = false;

  pickImages(source: SourceSpecification, options: ImageSelectionOptions, generalOptions: GeneralOptions,
    result: Result<ArrayList<string>>): void {
    this.pickImagesCount++;
    if (this.emitError) {
      result.error(new Error('boom'));
    } else {
      result.success(new ArrayList<string>());
    }
  }

  pickVideos(source: SourceSpecification, options: VideoSelectionOptions, generalOptions: GeneralOptions,
    result: Result<ArrayList<string>>): void {
    this.pickVideosCount++;
    if (this.emitError) {
      result.error(new Error('boom'));
    } else {
      result.success(new ArrayList<string>());
    }
  }

  pickMedia(mediaSelectionOptions: MediaSelectionOptions, generalOptions: GeneralOptions,
    result: Result<ArrayList<string>>): void {
    this.pickMediaCount++;
    if (this.emitError) {
      result.error(new Error('boom'));
    } else {
      result.success(new ArrayList<string>());
    }
  }

  retrieveLostResults(): Promise<CacheRetrievalResult> {
    this.retrieveLostCount++;
    return Promise.resolve(new CacheRetrievalResult());
  }
}

export default function messagesTest() {
  describe('MessagesCodecTest', () => {
    it('GeneralOptions_fromList_toList_round_trip', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(true);
      list.add(false);
      list.add(3);
      const restored: GeneralOptions = GeneralOptions.fromList(list);
      const out: ArrayList<ESObject> = restored.toList();
      expect(restored.getAllowMultiple()).assertTrue();
      expect(restored.getUsePhotoPicker()).assertFalse();
      expect(restored.getLimit()).assertEqual(3);
      expect(out.length).assertEqual(3);
      expect(out[0]).assertEqual(true);
      expect(out[1]).assertEqual(false);
      expect(out[2]).assertEqual(3);
    });

    it('GeneralOptions_limit_clamped_to_max', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(true);
      list.add(false);
      list.add(1000);
      const restored: GeneralOptions = GeneralOptions.fromList(list);
      expect(restored.getLimit()).assertEqual(MAX_SELECT_NUMBER);
    });

    it('GeneralOptions_null_allowMultiple_throws', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add(true);
      list.add(1);
      let threw: boolean = false;
      try {
        GeneralOptions.fromList(list);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('ImageSelectionOptions_null_constraints_round_trip', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add(null);
      list.add(80);
      const restored: ImageSelectionOptions = ImageSelectionOptions.fromList(list);
      expect(restored.getMaxWidth() == null).assertTrue();
      expect(restored.getMaxHeight() == null).assertTrue();
      expect(restored.getQuality()).assertEqual(80);
    });

    it('ImageSelectionOptions_with_constraints_round_trip', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(800.0);
      list.add(600.0);
      list.add(100);
      const restored: ImageSelectionOptions = ImageSelectionOptions.fromList(list);
      expect(restored.getMaxWidth()).assertEqual(800.0);
      expect(restored.getMaxHeight()).assertEqual(600.0);
      expect(restored.getQuality()).assertEqual(100);
    });

    it('ImageSelectionOptions_null_quality_throws', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add(null);
      list.add(null);
      let threw: boolean = false;
      try {
        ImageSelectionOptions.fromList(list);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('VideoSelectionOptions_round_trip', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(30);
      const restored: VideoSelectionOptions = VideoSelectionOptions.fromList(list);
      expect(restored.getMaxDurationSeconds()).assertEqual(30);
    });

    it('SourceSpecification_round_trip', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(SourceType.CAMERA);
      list.add(SourceCamera.FRONT);
      const restored: SourceSpecification = SourceSpecification.fromList(list);
      expect(restored.getType()).assertEqual(SourceType.CAMERA);
      expect(restored.getCamera()).assertEqual(SourceCamera.FRONT);
    });

    it('SourceSpecification_null_type_throws', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add(null);
      let threw: boolean = false;
      try {
        SourceSpecification.fromList(list);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('MediaSelectionOptions_nested_image_options_round_trip', 0, () => {
      const inner: ArrayList<ESObject> = new ArrayList<ESObject>();
      inner.add(100.0);
      inner.add(200.0);
      inner.add(90);
      const outer: ArrayList<ESObject> = new ArrayList<ESObject>();
      outer.add(inner);
      const restored: MediaSelectionOptions = MediaSelectionOptions.fromList(outer);
      const nested: ImageSelectionOptions | null = restored.getImageSelectionOptions();
      expect(nested != null).assertTrue();
      if (nested != null) {
        expect(nested.getMaxWidth()).assertEqual(100.0);
        expect(nested.getMaxHeight()).assertEqual(200.0);
        expect(nested.getQuality()).assertEqual(90);
      }
    });

    it('CacheRetrievalError_round_trip', 0, () => {
      const err: CacheRetrievalError = new CacheRetrievalError();
      err.setCode('missing_valid_video_uri');
      err.setMessage('no valid video uri');
      const list: ArrayList<ESObject> = err.toList();
      const restored: CacheRetrievalError = CacheRetrievalError.fromList(list);
      expect(restored.getCode()).assertEqual('missing_valid_video_uri');
      expect(restored.getMessage()).assertEqual('no valid video uri');
    });

    it('CacheRetrievalError_null_code_throws', 0, () => {
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add('msg');
      let threw: boolean = false;
      try {
        CacheRetrievalError.fromList(list);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('CacheRetrievalResult_round_trip_with_error_and_paths', 0, () => {
      const result: CacheRetrievalResult = new CacheRetrievalResult();
      result.setType(CacheRetrievalType.IMAGE);
      const paths: ArrayList<string> = new ArrayList<string>();
      paths.add('/a.jpg');
      result.setPaths(paths);
      const error: CacheRetrievalError = new CacheRetrievalError();
      error.setCode('no_activity');
      error.setMessage('activity is missing');
      result.setError(error);

      const list: ArrayList<ESObject> = result.toList();
      const restored: CacheRetrievalResult = CacheRetrievalResult.fromList(list);
      expect(restored.getType()).assertEqual(CacheRetrievalType.IMAGE);
      expect(restored.getPaths().length).assertEqual(1);
      expect(restored.getPaths()[0]).assertEqual('/a.jpg');
      const restoredError: CacheRetrievalError | null = restored.getError();
      expect(restoredError != null).assertTrue();
      if (restoredError != null) {
        expect(restoredError.getCode()).assertEqual('no_activity');
        expect(restoredError.getMessage()).assertEqual('activity is missing');
      }
    });

    it('CacheRetrievalResult_null_type_throws', 0, () => {
      const paths: ArrayList<ESObject> = new ArrayList<ESObject>();
      paths.add('/a.jpg');
      const list: ArrayList<ESObject> = new ArrayList<ESObject>();
      list.add(null);
      list.add(null);
      list.add(paths);
      let threw: boolean = false;
      try {
        CacheRetrievalResult.fromList(list);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('wrapError_flutter_error_returns_code_message_details', 0, () => {
      let wrapped: ArrayList<ESObject> = new ArrayList<ESObject>();
      try {
        throw new FlutterError('no_activity', 'no activity', 'details');
      } catch (err) {
        wrapped = Messages.wrapError(err);
      }
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('no_activity');
      expect(wrapped[1]).assertEqual('no activity');
      expect(wrapped[2]).assertEqual('details');
    });

    it('wrapError_plain_error_returns_name_message_stack', 0, () => {
      let wrapped: ArrayList<ESObject> = new ArrayList<ESObject>();
      try {
        throw new Error('boom');
      } catch (err) {
        wrapped = Messages.wrapError(err);
      }
      expect(wrapped.length).assertEqual(3);
      expect(wrapped[0]).assertEqual('Error');
      expect(wrapped[1]).assertEqual('boom');
    });

    it('setters_and_getters_round_trip_on_all_classes', 0, () => {
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      general.setAllowMultiple(true);
      general.setUsePhotoPicker(true);
      general.setLimit(7);
      expect(general.getAllowMultiple()).assertTrue();
      expect(general.getUsePhotoPicker()).assertTrue();
      expect(general.getLimit()).assertEqual(7);

      const image: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([null, null, 80]));
      image.setMaxWidth(500);
      image.setMaxHeight(400);
      image.setQuality(70);
      expect(image.getMaxWidth()).assertEqual(500);
      expect(image.getMaxHeight()).assertEqual(400);
      expect(image.getQuality()).assertEqual(70);

      const video: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([0]));
      video.setMaxDurationSeconds(60);
      expect(video.getMaxDurationSeconds()).assertEqual(60);

      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.CAMERA, SourceCamera.REAR]));
      source.setType(SourceType.GALLERY);
      source.setCamera(SourceCamera.FRONT);
      expect(source.getType()).assertEqual(SourceType.GALLERY);
      expect(source.getCamera()).assertEqual(SourceCamera.FRONT);

      const media: MediaSelectionOptions = new MediaSelectionOptions();
      media.setImageSelectionOptions(image);
      expect(media.getImageSelectionOptions() != null).assertTrue();

      const err: CacheRetrievalError = new CacheRetrievalError();
      err.setCode('code');
      err.setMessage('message');
      expect(err.getCode()).assertEqual('code');
      expect(err.getMessage()).assertEqual('message');

      const paths: ArrayList<string> = new ArrayList<string>();
      paths.add('/a.jpg');
      const result: CacheRetrievalResult = new CacheRetrievalResult();
      result.setType(CacheRetrievalType.VIDEO);
      result.setPaths(paths);
      const nested: CacheRetrievalError = new CacheRetrievalError();
      nested.setCode('c');
      nested.setMessage('m');
      result.setError(nested);
      expect(result.getType()).assertEqual(CacheRetrievalType.VIDEO);
      expect(result.getPaths()[0]).assertEqual('/a.jpg');
      expect(result.getError() != null).assertTrue();
    });

    it('setUsePhotoPicker_null_throws', 0, () => {
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      let threw: boolean = false;
      try {
        general.setUsePhotoPicker(null as ESObject as boolean);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('setImageSelectionOptions_null_throws', 0, () => {
      const media: MediaSelectionOptions = new MediaSelectionOptions();
      let threw: boolean = false;
      try {
        media.setImageSelectionOptions(null);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('setPaths_null_throws', 0, () => {
      const result: CacheRetrievalResult = new CacheRetrievalResult();
      let threw: boolean = false;
      try {
        result.setPaths(null as ESObject as ArrayList<string>);
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('cache_retrieval_error_builder_set_and_build', 0, () => {
      const err: CacheRetrievalError = new CacheRetrievalError();
      if (err.Builder.setCode) {
        err.Builder.setCode('missing_valid_video_uri');
      }
      if (err.Builder.setMessage) {
        err.Builder.setMessage('message');
      }
      if (err.Builder.build) {
        const built: ESObject = err.Builder.build();
        expect(built != null).assertTrue();
      }
    });

    it('cache_retrieval_result_builder_set_and_build', 0, () => {
      const result: CacheRetrievalResult = new CacheRetrievalResult();
      const paths: ArrayList<string> = new ArrayList<string>();
      paths.add('/v.mp4');
      const nested: CacheRetrievalError = new CacheRetrievalError();
      nested.setCode('c');
      if (result.Builder.setType) {
        result.Builder.setType(CacheRetrievalType.VIDEO);
      }
      if (result.Builder.setPaths) {
        result.Builder.setPaths(paths);
      }
      if (result.Builder.setError) {
        result.Builder.setError(nested);
      }
      if (result.Builder.build) {
        const built: ESObject = result.Builder.build();
        expect(built != null).assertTrue();
      }
    });

    it('builder_constructors_accept_null_handlers', 0, () => {
      const errBuilder: CacheRetrievalErrorBuilder = new CacheRetrievalErrorBuilder(null, null, null);
      expect(errBuilder != null).assertTrue();
      const resultBuilder: CacheRetrievalResultBuilder = new CacheRetrievalResultBuilder(null, null, null, null);
      expect(resultBuilder != null).assertTrue();
    });

    it('image_picker_api_getCodec_returns_codec', 0, () => {
      const codec: ESObject = ImagePickerApi.getCodec();
      expect(codec != null).assertTrue();
    });

    it('image_picker_api_setup_null_messenger_is_noop', 0, () => {
      ImagePickerApi.setup(null, null);
      expect(true).assertTrue();
    });

    it('codec_encode_decode_general_options_round_trip', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      const general: GeneralOptions = GeneralOptions.fromList(listOf([true, false, 3]));
      const buf: ArrayBuffer = codec.encodeMessage(general);
      const restored: GeneralOptions = codec.decodeMessage(buf) as ESObject as GeneralOptions;
      expect(restored.getAllowMultiple()).assertTrue();
      expect(restored.getLimit()).assertEqual(3);
    });

    it('codec_encode_decode_image_selection_options_round_trip', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      const img: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([100.0, 200.0, 90]));
      const buf: ArrayBuffer = codec.encodeMessage(img);
      const restored: ImageSelectionOptions = codec.decodeMessage(buf) as ESObject as ImageSelectionOptions;
      expect(restored.getMaxWidth()).assertEqual(100.0);
      expect(restored.getMaxHeight()).assertEqual(200.0);
      expect(restored.getQuality()).assertEqual(90);
    });

    it('codec_encode_decode_video_and_source_options_round_trip', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      const video: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([30]));
      const bufVideo: ArrayBuffer = codec.encodeMessage(video);
      const restoredVideo: VideoSelectionOptions = codec.decodeMessage(bufVideo) as ESObject as VideoSelectionOptions;
      expect(restoredVideo.getMaxDurationSeconds()).assertEqual(30);

      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.GALLERY, SourceCamera.FRONT]));
      const bufSource: ArrayBuffer = codec.encodeMessage(source);
      const restoredSource: SourceSpecification = codec.decodeMessage(bufSource) as ESObject as SourceSpecification;
      expect(restoredSource.getType()).assertEqual(SourceType.GALLERY);
      expect(restoredSource.getCamera()).assertEqual(SourceCamera.FRONT);
    });

    it('codec_encode_decode_media_selection_options_nested_round_trip', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      const inner: ArrayList<ESObject> = new ArrayList<ESObject>();
      inner.add(400.0);
      inner.add(300.0);
      inner.add(85);
      const outer: ArrayList<ESObject> = new ArrayList<ESObject>();
      outer.add(inner);
      const media: MediaSelectionOptions = MediaSelectionOptions.fromList(outer);
      const buf: ArrayBuffer = codec.encodeMessage(media);
      const restored: MediaSelectionOptions = codec.decodeMessage(buf) as ESObject as MediaSelectionOptions;
      const nested: ImageSelectionOptions | null = restored.getImageSelectionOptions();
      expect(nested != null).assertTrue();
      if (nested != null) {
        expect(nested.getMaxWidth()).assertEqual(400.0);
        expect(nested.getQuality()).assertEqual(85);
      }
    });

    it('codec_encode_decode_cache_error_and_result_round_trip', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      const err: CacheRetrievalError = new CacheRetrievalError();
      err.setCode('boom');
      err.setMessage('bad');
      const bufErr: ArrayBuffer = codec.encodeMessage(err);
      const restoredErr: CacheRetrievalError = codec.decodeMessage(bufErr) as ESObject as CacheRetrievalError;
      expect(restoredErr.getCode()).assertEqual('boom');
      expect(restoredErr.getMessage()).assertEqual('bad');

      const paths: ArrayList<string> = new ArrayList<string>();
      paths.add('/v.mp4');
      const result: CacheRetrievalResult = new CacheRetrievalResult();
      result.setType(CacheRetrievalType.VIDEO);
      result.setPaths(paths);
      const bufResult: ArrayBuffer = codec.encodeMessage(result);
      const restoredResult: CacheRetrievalResult = codec.decodeMessage(bufResult) as ESObject as CacheRetrievalResult;
      expect(restoredResult.getType()).assertEqual(CacheRetrievalType.VIDEO);
      expect(restoredResult.getPaths().length).assertEqual(1);
    });

    it('codec_decode_default_branch_reads_primitive', 0, () => {
      const codec: ImagePickerApiCodec = ImagePickerApiCodec.INSTANCE;
      // 非自定义类型走 StandardMessageCodec 默认分支
      const buf: ArrayBuffer = codec.encodeMessage(42);
      const decoded: ESObject = codec.decodeMessage(buf) as ESObject;
      expect(decoded).assertEqual(42);
    });

    it('general_options_builder_set_and_build', 0, () => {
      const g: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const b: ESObject = g.Builder;
      b.setAllowMultiple(true);
      b.setUsePhotoPicker(true);
      b.setLimit(9);
      const built: GeneralOptions = b.build() as ESObject as GeneralOptions;
      expect(built.getAllowMultiple()).assertTrue();
      expect(built.getUsePhotoPicker()).assertTrue();
      expect(built.getLimit()).assertEqual(9);
    });

    it('image_selection_options_builder_set_and_build', 0, () => {
      const img: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([null, null, 80]));
      const b: ESObject = img.Builder;
      b.setMaxWidth(300.0);
      b.setMaxHeight(200.0);
      b.setQuality(75);
      const built: ImageSelectionOptions = b.build() as ESObject as ImageSelectionOptions;
      expect(built.getMaxWidth()).assertEqual(300.0);
      expect(built.getMaxHeight()).assertEqual(200.0);
      expect(built.getQuality()).assertEqual(75);
    });

    it('media_selection_options_builder_set_and_build', 0, () => {
      const img: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([100.0, 100.0, 90]));
      const media: MediaSelectionOptions = new MediaSelectionOptions();
      const b: ESObject = media.Builder;
      b.setImageSelectionOptions(img);
      const built: MediaSelectionOptions = b.build() as ESObject as MediaSelectionOptions;
      const nested: ImageSelectionOptions | null = built.getImageSelectionOptions();
      expect(nested != null).assertTrue();
      if (nested != null) {
        expect(nested.getMaxWidth()).assertEqual(100.0);
        expect(nested.getQuality()).assertEqual(90);
      }
    });

    it('video_selection_options_builder_set_and_build', 0, () => {
      const video: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([0]));
      const b: ESObject = video.Builder;
      b.setMaxDurationSeconds(45);
      const built: VideoSelectionOptions = b.build() as ESObject as VideoSelectionOptions;
      expect(built.getMaxDurationSeconds()).assertEqual(45);
    });

    it('source_specification_builder_set_and_build', 0, () => {
      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.CAMERA, SourceCamera.REAR]));
      const b: ESObject = source.Builder;
      b.setType(SourceType.GALLERY);
      b.setCamera(SourceCamera.FRONT);
      const built: SourceSpecification = b.build() as ESObject as SourceSpecification;
      expect(built.getType()).assertEqual(SourceType.GALLERY);
      expect(built.getCamera()).assertEqual(SourceCamera.FRONT);
    });

    it('image_picker_api_setup_with_fake_messenger_null_api_registers_no_handlers', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, null);
      expect(messenger.setMessageHandlerCount).assertEqual(4);
      expect(messenger.handlers.length).assertEqual(0);
    });

    it('image_picker_api_setup_registers_four_channels_with_api', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      expect(messenger.handlers.length).assertEqual(4);
    });

    it('image_picker_api_pick_images_message_dispatch', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[0];
      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.GALLERY, SourceCamera.REAR]));
      const options: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([100.0, 100.0, 90]));
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [source, options, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickImagesCount).assertEqual(1);
    });

    it('image_picker_api_pick_videos_message_dispatch', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[1];
      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.CAMERA, SourceCamera.FRONT]));
      const options: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([30]));
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [source, options, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickVideosCount).assertEqual(1);
    });

    it('image_picker_api_pick_media_message_dispatch', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[2];
      const inner: ArrayList<ESObject> = new ArrayList<ESObject>();
      inner.add(100.0);
      inner.add(100.0);
      inner.add(90);
      const outer: ArrayList<ESObject> = new ArrayList<ESObject>();
      outer.add(inner);
      const media: MediaSelectionOptions = MediaSelectionOptions.fromList(outer);
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [media, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickMediaCount).assertEqual(1);
    });

    it('image_picker_api_retrieve_lost_results_message_dispatch', 0, async () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[3];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage([]);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      await sleep(150);
      expect(api.retrieveLostCount).assertEqual(1);
    });

    it('image_picker_api_pick_images_message_dispatch_error_callback', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      api.emitError = true;
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[0];
      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.GALLERY, SourceCamera.REAR]));
      const options: ImageSelectionOptions = ImageSelectionOptions.fromList(listOf([100.0, 100.0, 90]));
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [source, options, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickImagesCount).assertEqual(1);
    });

    it('image_picker_api_pick_videos_message_dispatch_error_callback', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      api.emitError = true;
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[1];
      const source: SourceSpecification = SourceSpecification.fromList(listOf([SourceType.CAMERA, SourceCamera.FRONT]));
      const options: VideoSelectionOptions = VideoSelectionOptions.fromList(listOf([30]));
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [source, options, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickVideosCount).assertEqual(1);
    });

    it('image_picker_api_pick_media_message_dispatch_error_callback', 0, () => {
      const messenger: CapturingMessenger = new CapturingMessenger();
      const api: FakeImagePickerApi = new FakeImagePickerApi();
      api.emitError = true;
      ImagePickerApi.setup(messenger as ESObject as BinaryMessenger, api);
      const handler: BinaryMessageHandler = messenger.handlers[2];
      const inner: ArrayList<ESObject> = new ArrayList<ESObject>();
      inner.add(100.0);
      inner.add(100.0);
      inner.add(90);
      const outer: ArrayList<ESObject> = new ArrayList<ESObject>();
      outer.add(inner);
      const media: MediaSelectionOptions = MediaSelectionOptions.fromList(outer);
      const general: GeneralOptions = GeneralOptions.fromList(listOf([false, false, 1]));
      const args: ESObject[] = [media, general];
      const encoded: ArrayBuffer = ImagePickerApiCodec.INSTANCE.encodeMessage(args);
      const reply: BinaryReply = { reply: (r: ArrayBuffer | null): void => {} } as ESObject as BinaryReply;
      handler.onMessage(encoded, reply);
      expect(api.pickMediaCount).assertEqual(1);
    });

    it('general_options_builder_constructs_from_original_instance', 0, () => {
      const g: GeneralOptions = GeneralOptions.fromList(listOf([true, true, 5]));
      const b: ESObject = g.Builder;
      const built: GeneralOptions = b.build() as ESObject as GeneralOptions;
      expect(built.getAllowMultiple()).assertTrue();
      expect(built.getLimit()).assertEqual(5);
    });
  });
}
