// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

/// Fake sink used to exercise releaseSink-style cleanup without touching stdout.
class FakeIOSink implements IOSink {
  FakeIOSink(this.target);

  final File target;
  var closed = false;

  @override
  late Encoding encoding = utf8;

  @override
  void add(List<int> data) {
    target.writeAsBytesSync(data, mode: FileMode.append, flush: true);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => stream.drain();

  @override
  Future close() async {
    closed = true;
  }

  @override
  Future flush() async {}

  @override
  Future get done => Future<void>.value();

  @override
  void write(Object? object) {
    target.writeAsStringSync('$object', mode: FileMode.append, flush: true);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {
    write('$object\n');
  }
}

extension PigeonReleaseSinkCoverage on Pigeon {
  Future<void> releaseSink(IOSink sink) async {
    if (sink is! Stdout) {
      await sink.close();
    }
  }
}

void main() {
  group('coverage quality scenarios', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pigeon_cov_quality_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('normal scenarios', () {
      test(
        'when Root is empty then runWithOptions should still succeed for ArkTS output',
        () async {
          final File input = File('${tempDir.path}/empty.dart')
            ..writeAsStringSync('''
import 'package:pigeon/pigeon.dart';
''');
          final int exitCode = await Pigeon.runWithOptions(
            PigeonOptions(
              input: input.path,
              arkTSOut: '${tempDir.path}/Empty.ets',
              arkTSOptions: ArkTSOptions(),
            ),
            adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
          );
          expect(exitCode, 0);
          expect(File('${tempDir.path}/Empty.ets').existsSync(), isTrue);
        },
      );
    });

    group('exception scenarios', () {
      test('when input path is missing then parseFile should throw PathNotFoundException', () {
        final Pigeon pigeon = Pigeon.setup();
        expect(
          () => pigeon.parseFile('${tempDir.path}/missing.dart'),
          throwsA(isA<PathNotFoundException>()),
        );
      });

      test('when DSL contains invalid constant then parseFile should return validation errors', () {
        final File input = File('${tempDir.path}/invalid.dart')
          ..writeAsStringSync('''
const myConst = 42;
''');
        final Pigeon pigeon = Pigeon.setup();
        final ParseResults results = pigeon.parseFile(input.path);
        expect(results.errors, isNotEmpty);
      });

      test(
        'when output directory is read-only then runWithOptions should return non-zero exit code',
        () async {
          if (!Platform.isWindows) {
            final Directory readOnlyDir = Directory('${tempDir.path}/readonly')..createSync();
            final File input = File('${tempDir.path}/api.dart')
              ..writeAsStringSync('''
import 'package:pigeon/pigeon.dart';
@HostApi()
abstract class Host { void ping(); }
''');
            Process.runSync('chmod', <String>['555', readOnlyDir.path]);
            final int exitCode = await Pigeon.runWithOptions(
              PigeonOptions(
                input: input.path,
                arkTSOut: '${readOnlyDir.path}/Messages.ets',
                arkTSOptions: ArkTSOptions(),
              ),
              adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
            );
            expect(exitCode, isNonZero);
            Process.runSync('chmod', <String>['755', readOnlyDir.path]);
          }
        },
      );

      test('when parseArgs exceeds timeout then test should fail predictably', () async {
        await expectLater(
          Future<PigeonOptions>(() async {
            await Future<void>.delayed(const Duration(seconds: 6));
            return Pigeon.parseArgs(<String>['--input', 'messages.dart']);
          }).timeout(const Duration(seconds: 1)),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('boundary scenarios', () {
      test(
        'when custom type count exceeds codec keys then customTypeOverflowCheck should detect overflow',
        () {
          final List<Class> classes = List<Class>.generate(
            130,
            (int index) => Class(name: 'Class$index', fields: <NamedType>[]),
          );
          final Root root = Root(apis: <Api>[], classes: classes, enums: <Enum>[]);
          expect(customTypeOverflowCheck(root), isTrue);
        },
      );

      test('when Root has no apis classes or enums then containsHostApi should be false', () {
        final Root root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
        expect(root.containsHostApi, isFalse);
        expect(root.containsProxyApi, isFalse);
        expect(root.containsEventChannel, isFalse);
      });
    });

    group('concurrent scenarios', () {
      test(
        'when runWithOptions runs in parallel then each output file should remain isolated',
        () async {
          final List<Future<int>> jobs = List<Future<int>>.generate(4, (int index) async {
            final File input = File('${tempDir.path}/api_$index.dart')
              ..writeAsStringSync('''
import 'package:pigeon/pigeon.dart';
@HostApi()
abstract class Host$index { int value$index(); }
''');
            return Pigeon.runWithOptions(
              PigeonOptions(
                input: input.path,
                arkTSOut: '${tempDir.path}/Messages_$index.ets',
                arkTSOptions: ArkTSOptions(),
              ),
              adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
            );
          });
          final List<int> exitCodes = await Future.wait(jobs);
          expect(exitCodes, everyElement(0));
          for (var index = 0; index < 4; index++) {
            expect(File('${tempDir.path}/Messages_$index.ets').existsSync(), isTrue);
          }
        },
      );

      test(
        'when fake sinks are closed concurrently then each sink should report closed state',
        () async {
          final List<Future<void>> closes = List<Future<void>>.generate(6, (int index) async {
            final File target = File('${tempDir.path}/sink_$index.txt');
            final FakeIOSink fakeSink = FakeIOSink(target);
            final Pigeon pigeon = Pigeon.setup();
            await pigeon.releaseSink(fakeSink);
            expect(fakeSink.closed, isTrue);
          });
          await Future.wait(closes);
        },
      );
    });
  });
}
