// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

InternalPigeonOptions _fullOptions() {
  return InternalPigeonOptions.fromPigeonOptions(
    const PigeonOptions(
      dartOut: 'out.dart',
      arkTSOut: 'out.ets',
      arkTSOptions: ArkTSOptions(),
      kotlinOut: 'out.kt',
      kotlinOptions: KotlinOptions(),
      swiftOut: 'out.swift',
      swiftOptions: SwiftOptions(),
      javaOut: 'out.java',
      javaOptions: JavaOptions(),
      objcHeaderOut: 'out.h',
      objcSourceOut: 'out.m',
      objcOptions: ObjcOptions(),
      cppHeaderOut: 'out.h',
      cppSourceOut: 'out.cpp',
      cppOptions: CppOptions(),
      gobjectHeaderOut: 'out.h',
      gobjectSourceOut: 'out.cc',
      gobjectOptions: GObjectOptions(),
      astOut: 'out.ast',
      debugGenerators: true,
    ),
  );
}

final Root _emptyRoot = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);

void main() {
  group('GeneratorAdapter subclasses (explicit coverage)', () {
    test('AstGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const AstGeneratorAdapter adapter = AstGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('DartGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const DartGeneratorAdapter adapter = DartGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('DartTestGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const DartTestGeneratorAdapter adapter = DartTestGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('ObjcGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const ObjcGeneratorAdapter adapter = ObjcGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('JavaGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const JavaGeneratorAdapter adapter = JavaGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('SwiftGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const SwiftGeneratorAdapter adapter = SwiftGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('CppGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const CppGeneratorAdapter adapter = CppGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('GObjectGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const GObjectGeneratorAdapter adapter = GObjectGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('KotlinGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const KotlinGeneratorAdapter adapter = KotlinGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });

    test('ArkTSGeneratorAdapter shouldGenerate validate fileTypeList', () {
      const ArkTSGeneratorAdapter adapter = ArkTSGeneratorAdapter();
      final InternalPigeonOptions options = _fullOptions();
      adapter.fileTypeList;
      adapter.validate(options, _emptyRoot);
      adapter.shouldGenerate(options, FileType.na);
    });
  });
}
