// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';

InternalPigeonOptions adapterTestOptions() {
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
    ),
  );
}

Root adapterTestEmptyRoot() => Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);

void exerciseNamedAdapter(GeneratorAdapter adapter) {
  final InternalPigeonOptions options = adapterTestOptions();
  final Root root = adapterTestEmptyRoot();
  adapter.fileTypeList;
  adapter.validate(options, root);
  adapter.shouldGenerate(options, FileType.na);
}
