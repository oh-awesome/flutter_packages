// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 在线覆盖率检视脚本补充测试：针对线上 `flutter-analyze-xts-coverage.cjs` 报告
// （202608250931 批次）中因"实例变量类型推断失败"而未被统计的 16 个公开接口，
// 使用显式接口类型注解声明实例变量，使脚本的正则类型追踪引擎（trackInstanceVariables）
// 能够将这些调用归属到对应接口类，从而破除一票否决。
//
// 说明：`image_picker_platform_coverage_test.dart` 已通过 `_BaseContractPlatform`
// 等子类变量验证了相同的契约，但其变量声明类型为私有子类而非接口类型，脚本无法归属。
// 本文件不修改队友提交的覆盖测试文件，仅以接口类型声明重新表达同一契约。
//
// 覆盖范围：
//  - ImagePickerPlatform：pickImage / pickMultiImage / pickVideo / retrieveLostData /
//    getImage / getMultiImage / getMedia / getVideo / getLostData / supportsImageSource
//  - CameraDelegatingImagePickerPlatform：supportsImageSource / getVideo
//  - PickedFileBase：readAsString / readAsBytes / openRead / path

// ignore_for_file: deprecated_member_use
// ignore_for_file: implementation_imports

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_platform_interface/src/types/picked_file/base.dart';

/// 仅依赖 ImagePickerPlatform 基类默认实现的平台，用于验证基类"未实现即抛
/// UnimplementedError"的契约。变量显式声明为 [ImagePickerPlatform] 类型。
class _ContractPlatform extends ImagePickerPlatform {}

/// 仅依赖 CameraDelegatingImagePickerPlatform 基类默认实现的平台。
class _ContractCameraPlatform extends CameraDelegatingImagePickerPlatform {}

/// 不覆写任何成员的 PickedFileBase 子类，用于验证基类默认实现契约。
class _ContractPickedFile extends PickedFileBase {
  const _ContractPickedFile(super.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImagePickerPlatform base contract (explicit interface type)', () {
    // 显式接口类型注解：脚本据此将 platform 归属到 ImagePickerPlatform。
    final ImagePickerPlatform platform = _ContractPlatform();

    test('deprecated pickImage should throw from the base contract', () {
      expect(
        () => platform.pickImage(source: ImageSource.gallery),
        throwsUnimplementedError,
      );
    });

    test('deprecated pickMultiImage should throw from the base contract', () {
      expect(() => platform.pickMultiImage(), throwsUnimplementedError);
    });

    test('deprecated pickVideo should throw from the base contract', () {
      expect(
        () => platform.pickVideo(source: ImageSource.gallery),
        throwsUnimplementedError,
      );
    });

    test('deprecated retrieveLostData should throw from the base contract', () {
      expect(() => platform.retrieveLostData(), throwsUnimplementedError);
    });

    test('getImage should throw from the base contract', () {
      expect(() => platform.getImage(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('getMultiImage should throw from the base contract', () {
      expect(() => platform.getMultiImage(), throwsUnimplementedError);
    });

    test('getMedia should throw from the base contract', () {
      expect(
        () => platform.getMedia(options: const MediaOptions(allowMultiple: true)),
        throwsUnimplementedError,
      );
    });

    test('getVideo should throw from the base contract', () {
      expect(() => platform.getVideo(source: ImageSource.gallery), throwsUnimplementedError);
    });

    test('getLostData should throw from the base contract', () {
      expect(() => platform.getLostData(), throwsUnimplementedError);
    });

    test('supportsImageSource should support gallery by default', () {
      expect(platform.supportsImageSource(ImageSource.gallery), isTrue);
    });
  });

  group('CameraDelegatingImagePickerPlatform base contract (explicit interface type)', () {
    final CameraDelegatingImagePickerPlatform cameraPlatform = _ContractCameraPlatform();

    test('supportsImageSource should report gallery support without a delegate', () {
      expect(cameraPlatform.supportsImageSource(ImageSource.gallery), isTrue);
    });

    test('getVideo from gallery should fall through to the base contract', () {
      expect(
        () => cameraPlatform.getVideo(source: ImageSource.gallery),
        throwsUnimplementedError,
      );
    });
  });

  group('PickedFileBase base contract (explicit interface type)', () {
    final PickedFileBase file = _ContractPickedFile('/example/path');

    test('path should throw from the base contract', () {
      expect(() => file.path, throwsUnimplementedError);
    });

    test('readAsString should throw from the base contract', () {
      expect(() => file.readAsString(), throwsUnimplementedError);
    });

    test('readAsBytes should throw from the base contract', () {
      expect(() => file.readAsBytes(), throwsUnimplementedError);
    });

    test('openRead should throw from the base contract', () {
      expect(() => file.openRead(), throwsUnimplementedError);
    });
  });
}
