// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

import 'adapter_test_util.dart';

void main() {
  group('DartGeneratorAdapter', () {
    const DartGeneratorAdapter adapter = DartGeneratorAdapter();

    test('DartGeneratorAdapter.fileTypeList', () {
      expect(adapter.fileTypeList, isNotEmpty);
    });

    test('DartGeneratorAdapter.validate', () {
      adapter.validate(adapterTestOptions(), adapterTestEmptyRoot());
    });

    test('DartGeneratorAdapter.shouldGenerate', () {
      adapter.shouldGenerate(adapterTestOptions(), FileType.na);
    });
  });
}
