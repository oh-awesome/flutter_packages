// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

void main() {
  final Root emptyRoot = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);

  final List<GeneratorAdapter> adapters = <GeneratorAdapter>[
    const ArkTSGeneratorAdapter(),
    const KotlinGeneratorAdapter(),
    const SwiftGeneratorAdapter(),
    const JavaGeneratorAdapter(),
    const ObjcGeneratorAdapter(),
    const CppGeneratorAdapter(),
    const GObjectGeneratorAdapter(),
    const DartGeneratorAdapter(),
    const DartTestGeneratorAdapter(),
    const AstGeneratorAdapter(),
  ];

  group('GeneratorAdapter implementations', () {
    for (final GeneratorAdapter adapter in adapters) {
      final String name = adapter.runtimeType.toString();

      test('$name exposes fileTypeList', () {
        expect(adapter.fileTypeList, isNotEmpty);
      });

      test('$name validate returns a list', () {
        final InternalPigeonOptions options = InternalPigeonOptions.fromPigeonOptions(
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
          ),
        );
        expect(adapter.validate(options, emptyRoot), isA<List<Error>>());
      });

      test('$name shouldGenerate is callable', () {
        final InternalPigeonOptions options = InternalPigeonOptions.fromPigeonOptions(
          const PigeonOptions(dartOut: 'out.dart'),
        );
        adapter.shouldGenerate(options, FileType.na);
      });
    }
  });
}
