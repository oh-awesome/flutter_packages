// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pigeon_cov_scenarios_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('concurrent CLI usage', () {
    test('when parseArgs runs in parallel then each result should stay independent', () async {
      final List<PigeonOptions> results = await Future.wait(
        List<Future<PigeonOptions>>.generate(8, (_) async {
          return Pigeon.parseArgs(<String>['--input', 'messages.dart', '--dart_out', 'out.dart']);
        }),
      );
      for (final PigeonOptions options in results) {
        expect(options.input, 'messages.dart');
        expect(options.dartOut, 'out.dart');
      }
    });
  });

  group('empty API boundary', () {
    test('when adapters validate an empty root then they should return a list', () {
      const adapter = ArkTSGeneratorAdapter();
      final options = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(arkTSOut: 'out.ets', arkTSOptions: ArkTSOptions()),
      );
      expect(adapter.validate(options, Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[])), isA<List<Error>>());
    });
  });

  group('timeout and IO error scenarios', () {
    test('when parseArgs completes within timeout then options should be returned', () async {
      final PigeonOptions options = await Future<PigeonOptions>(() {
        return Pigeon.parseArgs(<String>['--input', 'messages.dart', '--dart_out', 'out.dart']);
      }).timeout(const Duration(seconds: 5));
      expect(options.input, 'messages.dart');
    });

    test('when parseFile reads invalid syntax then errors should be reported', () {
      final File file = File('${tempDir.path}/bad.dart')..writeAsStringSync('class {');
      final ParseResults results = Pigeon.setup().parseFile(file.path);
      expect(results.errors, isNotEmpty);
    });
  });
}
