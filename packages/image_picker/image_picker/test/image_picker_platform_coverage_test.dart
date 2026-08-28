// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 覆盖度补充测试：针对 AI 检视报告中 XTS 未覆盖的公开接口补用例，
// 把公开接口覆盖率拉到 100%，破除"一票否决"。
//
// 覆盖范围：
//  - ImagePicker.platform（静态属性）
//  - ImagePickerPlatform 的 10 个未覆盖方法
//  - CameraDelegatingImagePickerPlatform 的 3 个成员
//  - ImagePickerCameraDelegateOptions.maxVideoDuration
//  - LostData.isEmpty / LostDataResponse.isEmpty
//  - MethodChannelImagePicker 的全部 10 个接口
//  - PickedFileBase 的全部 4 个成员
// 同时补齐异常/边界/并发场景，并使用 BDD 风格命名 + tearDown 清理。

// ignore_for_file: deprecated_member_use
// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_platform_interface/src/method_channel/method_channel_image_picker.dart';
import 'package:image_picker_platform_interface/src/types/picked_file/base.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_picker_test.mocks.dart' as base_mock;

// 复用 Mockito 生成的 ImagePickerPlatform mock，并叠加 PlatformInterface token 校验。
class _MockImagePickerPlatform extends base_mock.MockImagePickerPlatform
    with MockPlatformInterfaceMixin {}

/// 仅依赖 ImagePickerPlatform 基类默认实现的测试平台，
/// 用于验证基类"未实现即抛 UnimplementedError"的契约。
class _BaseContractPlatform extends ImagePickerPlatform {}

/// 相机支持取决于是否设置 cameraDelegate 的委托平台。
class _TestCameraDelegatingPlatform extends CameraDelegatingImagePickerPlatform {}

/// 记录收到选项的假相机委托。
class _FakeCameraDelegate extends ImagePickerCameraDelegate {
  ImagePickerCameraDelegateOptions? lastPhotoOptions;
  ImagePickerCameraDelegateOptions? lastVideoOptions;

  @override
  Future<XFile?> takePhoto({
    ImagePickerCameraDelegateOptions options = const ImagePickerCameraDelegateOptions(),
  }) async {
    lastPhotoOptions = options;
    return XFile('/camera/photo.jpg');
  }

  @override
  Future<XFile?> takeVideo({
    ImagePickerCameraDelegateOptions options = const ImagePickerCameraDelegateOptions(),
  }) async {
    lastVideoOptions = options;
    return XFile('/camera/video.mp4');
  }
}

/// 不覆写任何成员的 PickedFileBase 子类，用于验证基类默认实现。
class _UnimplementedPickedFile extends PickedFileBase {
  const _UnimplementedPickedFile(super.path);
}

/// getMultiImage 返回 null 的平台，用于验证基类 getMultiImageWithOptions 兜底。
class _NullMultiImagePlatform extends ImagePickerPlatform {
  @override
  Future<List<XFile>?> getMultiImage({double? maxWidth, double? maxHeight, int? imageQuality}) async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/image_picker');

  late ImagePickerPlatform originalInstance;

  setUp(() {
    originalInstance = ImagePickerPlatform.instance;
  });

  tearDown(() {
    // 恢复平台实例，并清理 MethodChannel mock handler，保证测试独立。
    ImagePickerPlatform.instance = originalInstance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ImagePicker.platform', () {
    test('should expose the active platform instance', () {
      final mock = _MockImagePickerPlatform();
      ImagePickerPlatform.instance = mock;
      expect(ImagePicker.platform, same(mock));
    });
  });

  group('ImagePickerPlatform base contract', () {
    final platform = _BaseContractPlatform();

    test('should throw UnimplementedError for deprecated pickImage', () {
      expect(() => platform.pickImage(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for deprecated pickMultiImage', () {
      expect(() => platform.pickMultiImage(), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for deprecated pickVideo', () {
      expect(() => platform.pickVideo(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for deprecated retrieveLostData', () {
      expect(() => platform.retrieveLostData(), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for deprecated getImage', () {
      expect(() => platform.getImage(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for deprecated getMultiImage', () {
      expect(() => platform.getMultiImage(), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for getMedia', () {
      expect(
        () => platform.getMedia(options: MediaOptions.createAndValidate(allowMultiple: true)),
        throwsUnimplementedError,
      );
    });

    test('should throw UnimplementedError for getVideo', () {
      expect(() => platform.getVideo(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for getLostData', () {
      expect(() => platform.getLostData(), throwsUnimplementedError);
    });

    test('should throw UnimplementedError for getMultiVideoWithOptions', () {
      expect(() => platform.getMultiVideoWithOptions(), throwsUnimplementedError);
    });

    test('should support gallery and camera sources by default', () {
      expect(platform.supportsImageSource(ImageSource.gallery), isTrue);
      expect(platform.supportsImageSource(ImageSource.camera), isTrue);
    });

    test('should delegate getImageFromSource to the deprecated getImage', () {
      expect(
        () => platform.getImageFromSource(source: ImageSource.gallery),
        throwsUnimplementedError,
      );
    });

    test('should return an empty list when getMultiImage returns null', () async {
      final nullPlatform = _NullMultiImagePlatform();
      expect(await nullPlatform.getMultiImageWithOptions(), isEmpty);
    });
  });

  group('CameraDelegatingImagePickerPlatform', () {
    late _TestCameraDelegatingPlatform platform;

    setUp(() {
      platform = _TestCameraDelegatingPlatform();
    });

    test('should report camera unsupported when no delegate is set', () {
      expect(platform.supportsImageSource(ImageSource.camera), isFalse);
      expect(platform.supportsImageSource(ImageSource.gallery), isTrue);
    });

    test('should report camera supported when a delegate is set', () {
      platform.cameraDelegate = _FakeCameraDelegate();
      expect(platform.supportsImageSource(ImageSource.camera), isTrue);
    });

    test('should throw StateError when capturing video without a delegate', () {
      expect(() => platform.getVideo(source: ImageSource.camera), throwsStateError);
    });

    test('should throw StateError when capturing photo without a delegate', () {
      expect(() => platform.getImageFromSource(source: ImageSource.camera), throwsStateError);
    });

    test('should delegate camera photo capture to the cameraDelegate', () async {
      final delegate = _FakeCameraDelegate();
      platform.cameraDelegate = delegate;

      final XFile? photo = await platform.getImageFromSource(source: ImageSource.camera);

      expect(photo!.path, '/camera/photo.jpg');
      expect(delegate.lastPhotoOptions!.preferredCameraDevice, CameraDevice.rear);
    });

    test('should delegate camera video capture and pass maxVideoDuration', () async {
      final delegate = _FakeCameraDelegate();
      platform.cameraDelegate = delegate;

      final XFile? video = await platform.getVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxDuration: const Duration(seconds: 30),
      );

      expect(video!.path, '/camera/video.mp4');
      expect(delegate.lastVideoOptions!.preferredCameraDevice, CameraDevice.front);
      expect(delegate.lastVideoOptions!.maxVideoDuration, const Duration(seconds: 30));
    });

    test('should fall through to the base implementation for gallery sources', () {
      expect(() => platform.getVideo(source: ImageSource.gallery), throwsUnimplementedError);
      expect(
        () => platform.getImageFromSource(source: ImageSource.gallery),
        throwsUnimplementedError,
      );
    });
  });

  group('ImagePickerCameraDelegateOptions', () {
    test('should default to the rear camera and no duration limit', () {
      const options = ImagePickerCameraDelegateOptions();
      expect(options.preferredCameraDevice, CameraDevice.rear);
      expect(options.maxVideoDuration, isNull);
    });

    test('should carry a custom camera device and max video duration', () {
      const options = ImagePickerCameraDelegateOptions(
        preferredCameraDevice: CameraDevice.front,
        maxVideoDuration: Duration(seconds: 15),
      );
      expect(options.preferredCameraDevice, CameraDevice.front);
      expect(options.maxVideoDuration, const Duration(seconds: 15));
    });
  });

  group('Lost data', () {
    test('should report empty responses as empty', () {
      expect(LostData.empty().isEmpty, isTrue);
      expect(LostDataResponse.empty().isEmpty, isTrue);
    });

    test('should report populated responses as not empty', () {
      final lostData = LostData(file: PickedFile('/x'), type: RetrieveType.image);
      expect(lostData.isEmpty, isFalse);

      final response =
          LostDataResponse(file: XFile('/x'), type: RetrieveType.image, files: <XFile>[XFile('/x')]);
      expect(response.isEmpty, isFalse);
    });
  });

  group('MethodChannelImagePicker', () {
    late MethodChannelImagePicker picker;
    late List<MethodCall> log;
    dynamic returnValue;

    setUp(() {
      picker = MethodChannelImagePicker();
      log = <MethodCall>[];
      returnValue = '';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return returnValue;
        },
      );
    });

    test('should expose the standard image_picker channel', () {
      expect(picker.channel.name, 'plugins.flutter.io/image_picker');
    });

    test('should pick a single image through the channel', () async {
      returnValue = '/example/path';
      final PickedFile? file = await picker.pickImage(source: ImageSource.gallery);

      expect(file!.path, '/example/path');
      expect(log.single.method, 'pickImage');
    });

    test('should pick multiple images through the channel', () async {
      returnValue = <String>['/a', '/b'];
      final List<PickedFile>? files = await picker.pickMultiImage();

      expect(files, hasLength(2));
      expect(log.single.method, 'pickMultiImage');
    });

    test('should pick a video through the channel', () async {
      returnValue = '/example/video.mp4';
      final PickedFile? video = await picker.pickVideo(source: ImageSource.gallery);

      expect(video!.path, '/example/video.mp4');
      expect(log.single.method, 'pickVideo');
    });

    test('should retrieve lost data through the channel', () async {
      returnValue = <String, dynamic>{'type': 'image', 'path': '/lost'};
      final LostData lost = await picker.retrieveLostData();

      expect(lost.isEmpty, isFalse);
      expect(lost.file!.path, '/lost');
      expect(log.single.method, 'retrieve');
    });

    test('should get a single image through the channel', () async {
      returnValue = '/example/path';
      final XFile? image = await picker.getImage(source: ImageSource.camera);

      expect(image!.path, '/example/path');
      expect(log.single.method, 'pickImage');
    });

    test('should get multiple images through the channel', () async {
      returnValue = <String>['/a', '/b'];
      final List<XFile>? images = await picker.getMultiImage();

      expect(images, hasLength(2));
      expect(log.single.method, 'pickMultiImage');
    });

    test('should get mixed media through the channel', () async {
      returnValue = <String>['/a.jpg'];
      final List<XFile> media = await picker.getMedia(
        options: MediaOptions.createAndValidate(allowMultiple: true),
      );

      expect(media, hasLength(1));
      expect(log.single.method, 'pickMedia');
    });

    test('should get a video through the channel', () async {
      returnValue = '/example/video.mp4';
      final XFile? video = await picker.getVideo(source: ImageSource.camera);

      expect(video!.path, '/example/video.mp4');
      expect(log.single.method, 'pickVideo');
    });

    test('should get a lost data response through the channel', () async {
      returnValue = <String, dynamic>{
        'type': 'image',
        'path': '/lost',
        'pathList': <String>['/a', '/b'],
      };
      final LostDataResponse response = await picker.getLostData();

      expect(response.isEmpty, isFalse);
      expect(response.files, hasLength(2));
      expect(log.single.method, 'retrieve');
    });

    test('should handle a null lost-data result as empty', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async => null,
      );
      expect((await picker.retrieveLostData()).isEmpty, isTrue);
      expect((await picker.getLostData()).isEmpty, isTrue);
    });
  });

  group('PickedFileBase', () {
    test('should throw UnimplementedError from base-class defaults', () {
      const file = _UnimplementedPickedFile('/x');
      expect(() => file.path, throwsUnimplementedError);
      expect(() => file.readAsString(), throwsUnimplementedError);
      expect(() => file.readAsBytes(), throwsUnimplementedError);
      expect(() => file.openRead(), throwsUnimplementedError);
    });

    test('should read file contents through the io PickedFile implementation', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('image_picker_coverage');
      addTearDown(() => tempDir.delete(recursive: true));
      final tempFile = File('${tempDir.path}/hello.txt');
      await tempFile.writeAsString('hello');

      final picked = PickedFile(tempFile.path);

      expect(picked.path, tempFile.path);
      expect(await picked.readAsString(), 'hello');
      expect(await picked.readAsBytes(), utf8.encode('hello'));
      final List<Uint8List> chunks = await picked.openRead().toList();
      expect(chunks, <Uint8List>[utf8.encode('hello')]);
    });
  });

  group('Exception scenarios', () {
    late MethodChannelImagePicker picker;

    setUp(() {
      picker = MethodChannelImagePicker();
    });

    test('should propagate a platform permission error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async {
          throw PlatformException(code: 'camera_access_denied', message: 'no camera permission');
        },
      );

      await expectLater(
        picker.getImageFromSource(source: ImageSource.camera),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'camera_access_denied',
          ),
        ),
      );
    });

    test('should propagate a platform state error from getMedia', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async {
          throw PlatformException(code: 'plugin_error', message: 'plugin already in use');
        },
      );

      await expectLater(
        picker.getMedia(options: MediaOptions.createAndValidate(allowMultiple: true)),
        throwsA(isA<PlatformException>().having((PlatformException e) => e.code, 'code', 'plugin_error')),
      );
    });

    test('should time out when the platform never responds', () async {
      final never = Completer<dynamic>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) => never.future,
      );

      await expectLater(
        picker.getVideo(source: ImageSource.camera).timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );

      never.complete(null);
    });

    test('should throw ArgumentError for out-of-range imageQuality', () async {
      await expectLater(
        picker.pickImage(source: ImageSource.gallery, imageQuality: -1),
        throwsArgumentError,
      );
      await expectLater(
        picker.pickImage(source: ImageSource.gallery, imageQuality: 101),
        throwsArgumentError,
      );
    });
  });

  group('Boundary scenarios', () {
    late MethodChannelImagePicker picker;

    setUp(() {
      picker = MethodChannelImagePicker();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async => null,
      );
    });

    test('should accept boundary imageQuality values of 0 and 100', () async {
      expect(await picker.pickImage(source: ImageSource.gallery, imageQuality: 0), isNull);
      expect(await picker.pickImage(source: ImageSource.gallery, imageQuality: 100), isNull);
    });

    test('should accept very large maxWidth and maxHeight values', () async {
      expect(
        await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1e300,
          maxHeight: 1e300,
        ),
        isNull,
      );
    });

    test('should accept a very large limit value', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async => <String>[],
      );
      final List<XFile> images = await picker.getMultiImageWithOptions(
        options: MultiImagePickerOptions.createAndValidate(limit: 100000),
      );
      expect(images, isEmpty);
    });

    test('should reject negative dimensions', () async {
      await expectLater(
        picker.pickImage(source: ImageSource.gallery, maxWidth: -1.0),
        throwsArgumentError,
      );
      await expectLater(
        picker.pickImage(source: ImageSource.gallery, maxHeight: -1.0),
        throwsArgumentError,
      );
    });
  });

  group('Concurrency scenarios', () {
    test('should handle concurrent getImage calls independently', () async {
      final picker = MethodChannelImagePicker();
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        picker.channel,
        (MethodCall methodCall) async {
          callCount += 1;
          return '/path/$callCount';
        },
      );

      final List<XFile?> results = await Future.wait(<Future<XFile?>>[
        picker.getImageFromSource(source: ImageSource.camera),
        picker.getImageFromSource(source: ImageSource.gallery),
        picker.getImageFromSource(source: ImageSource.camera),
      ]);

      expect(results, hasLength(3));
      expect(results.every((XFile? f) => f != null), isTrue);
      expect(callCount, 3);
    });

    test('should immediately reflect a replaced platform instance', () {
      final first = _MockImagePickerPlatform();
      final second = _MockImagePickerPlatform();

      ImagePickerPlatform.instance = first;
      expect(ImagePicker.platform, same(first));

      ImagePickerPlatform.instance = second;
      expect(ImagePicker.platform, same(second));
    });
  });
}
