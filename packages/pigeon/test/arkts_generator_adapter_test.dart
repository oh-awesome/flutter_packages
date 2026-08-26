// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

void main() {
  group('ArkTSGeneratorAdapter', () {
    const adapter = ArkTSGeneratorAdapter();

    test('fileTypeList exposes FileType.na', () {
      expect(adapter.fileTypeList, equals(const <FileType>[FileType.na]));
    });

    test('validate returns no errors for supported ArkTS IDL', () {
      final root = Root(
        apis: <Api>[
          AstHostApi(
            name: 'Host',
            methods: <Method>[
              Method(
                name: 'ping',
                location: ApiLocation.host,
                returnType: TypeDeclaration.voidDeclaration(),
                parameters: <Parameter>[],
              ),
            ],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
        containsHostApi: true,
      );
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(arkTSOut: 'out.ets', arkTSOptions: ArkTSOptions()),
      );
      expect(adapter.validate(options, root), isEmpty);
    });

    test('validate allows ProxyApi names that differ only in case from reserved words', () {
      final root = Root(
        apis: <Api>[
          AstProxyApi(
            name: 'Class',
            constructors: <Constructor>[Constructor(name: '', parameters: <Parameter>[])],
            fields: <ApiField>[],
            methods: <Method>[],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
      );
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(arkTSOut: 'out.ets', arkTSOptions: ArkTSOptions()),
      );
      expect(adapter.validate(options, root), isEmpty);
    });

    test('validate rejects ProxyApi names that are ArkTS reserved words', () {
      final root = Root(
        apis: <Api>[
          AstProxyApi(
            name: 'class',
            constructors: <Constructor>[Constructor(name: '', parameters: <Parameter>[])],
            fields: <ApiField>[],
            methods: <Method>[],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
      );
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(arkTSOut: 'out.ets', arkTSOptions: ArkTSOptions()),
      );
      final errors = adapter.validate(options, root);
      expect(errors, hasLength(1));
      expect(
        errors.single.message,
        contains('ProxyApi name "class" conflicts with a reserved keyword'),
      );
    });

    test('shouldGenerate returns null when arkTSOut is unset', () {
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(dartOut: 'out.dart'),
      );
      expect(adapter.shouldGenerate(options, FileType.na), isNull);
    });

    test('generate writes ArkTS when arkTSOut is configured', () {
      final root = Root(
        apis: <Api>[
          AstHostApi(
            name: 'Host',
            methods: <Method>[
              Method(
                name: 'ping',
                location: ApiLocation.host,
                returnType: TypeDeclaration.voidDeclaration(),
                parameters: <Parameter>[],
              ),
            ],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
        containsHostApi: true,
      );
      final buffer = StringBuffer();
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(arkTSOut: 'out.ets', arkTSOptions: ArkTSOptions()),
      );
      adapter.generate(buffer, options, root, FileType.na);
      expect(buffer.toString(), contains('abstract class Host'));
    });

    test('generate is a no-op when arkTSOptions is null', () {
      final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
      final buffer = StringBuffer();
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(dartOut: 'out.dart'),
      );
      adapter.generate(buffer, options, root, FileType.na);
      expect(buffer.toString(), isEmpty);
    });
  });
}
