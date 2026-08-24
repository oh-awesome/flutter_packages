// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 选项类（Options）参数校验的单元测试，置于 test/unit 子目录，
// 用于组织测试目录结构并覆盖选项类的边界校验逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  group('ImageOptions.createAndValidate', () {
    test('should accept valid boundary values', () {
      expect(
        () => ImageOptions.createAndValidate(imageQuality: 0),
        returnsNormally,
      );
      expect(
        () => ImageOptions.createAndValidate(imageQuality: 100),
        returnsNormally,
      );
      expect(
        () => ImageOptions.createAndValidate(maxWidth: 0, maxHeight: 0),
        returnsNormally,
      );
    });

    test('should reject imageQuality outside 0-100', () {
      expect(() => ImageOptions.createAndValidate(imageQuality: -1), throwsArgumentError);
      expect(() => ImageOptions.createAndValidate(imageQuality: 101), throwsArgumentError);
    });

    test('should reject negative dimensions', () {
      expect(() => ImageOptions.createAndValidate(maxWidth: -1), throwsArgumentError);
      expect(() => ImageOptions.createAndValidate(maxHeight: -1), throwsArgumentError);
    });
  });

  group('MultiImagePickerOptions.createAndValidate', () {
    test('should accept a limit of 2 or more', () {
      expect(
        () => MultiImagePickerOptions.createAndValidate(limit: 2),
        returnsNormally,
      );
      expect(
        () => MultiImagePickerOptions.createAndValidate(limit: 100000),
        returnsNormally,
      );
    });

    test('should reject a limit lower than 2', () {
      expect(
        () => MultiImagePickerOptions.createAndValidate(limit: 1),
        throwsArgumentError,
      );
      expect(
        () => MultiImagePickerOptions.createAndValidate(limit: 0),
        throwsArgumentError,
      );
    });
  });

  group('MediaOptions.createAndValidate', () {
    test('should accept a valid multiple-selection config', () {
      expect(
        () => MediaOptions.createAndValidate(allowMultiple: true, limit: 5),
        returnsNormally,
      );
    });

    test('should reject a limit lower than 2', () {
      expect(
        () => MediaOptions.createAndValidate(allowMultiple: true, limit: 1),
        throwsArgumentError,
      );
    });

    test('should reject a non-null limit when allowMultiple is false', () {
      expect(
        () => MediaOptions.createAndValidate(allowMultiple: false, limit: 5),
        throwsArgumentError,
      );
    });

    test('should allow a null limit when allowMultiple is false', () {
      expect(
        () => MediaOptions.createAndValidate(allowMultiple: false),
        returnsNormally,
      );
    });
  });

  group('MultiVideoPickerOptions', () {
    test('should carry duration and limit', () {
      const options = MultiVideoPickerOptions(
        maxDuration: Duration(seconds: 30),
        limit: 5,
      );
      expect(options.maxDuration, const Duration(seconds: 30));
      expect(options.limit, 5);
    });
  });
}
