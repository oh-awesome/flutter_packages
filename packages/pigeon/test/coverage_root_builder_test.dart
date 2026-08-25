// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as dart_ast;
import 'package:pigeon/src/pigeon_lib.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

const String _pigeonSource = '''
import 'package:pigeon/pigeon.dart';

const int kAnswer = 42;

enum Status { ok }

class Item {
  int value;
}

@HostApi()
abstract class Host {
  int add(int a, int b);
}
''';

void main() {
  group('RootBuilder', () {
    late RootBuilder builder;
    late dart_ast.CompilationUnit unit;

    setUp(() {
      builder = RootBuilder(_pigeonSource);
      unit = parseString(content: _pigeonSource).unit;
    });

    test('results after explicit visit methods', () {
      for (final dart_ast.Directive directive in unit.directives) {
        if (directive is dart_ast.ImportDirective) {
          builder.visitImportDirective(directive);
        }
      }
      for (final dart_ast.AstNode declaration in unit.declarations) {
        switch (declaration) {
          case dart_ast.TopLevelVariableDeclaration node:
            builder.visitTopLevelVariableDeclaration(node);
          case dart_ast.Annotation node:
            builder.visitAnnotation(node);
          case dart_ast.ClassDeclaration node:
            builder.visitClassDeclaration(node);
          case dart_ast.MethodDeclaration node:
            builder.visitMethodDeclaration(node);
          case dart_ast.EnumDeclaration node:
            builder.visitEnumDeclaration(node);
          case dart_ast.FieldDeclaration node:
            builder.visitFieldDeclaration(node);
          case dart_ast.ConstructorDeclaration node:
            builder.visitConstructorDeclaration(node);
          default:
            break;
        }
      }
      final ParseResults results = builder.results();
      expect(results.root.apis, isNotEmpty);
      expect(results.root.constants, isNotEmpty);
      expect(results.root.enums, isNotEmpty);
      expect(results.root.classes, isNotEmpty);
      expect(results.errors, isEmpty);
    });

    test('source field is retained', () {
      expect(builder.source, _pigeonSource);
    });
  });

  group('Pigeon.parseFile', () {
    test('parses valid pigeon input from disk', () {
      final Directory dir = Directory.systemTemp.createTempSync('pigeon_cov_');
      final File file = File('${dir.path}/input.dart')..writeAsStringSync(_pigeonSource);
      try {
        final ParseResults results = Pigeon.setup().parseFile(file.path);
        expect(results.errors, isEmpty);
        expect(results.root.containsHostApi, isTrue);
        expect(results.root.constants, isNotEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('parseFile reports errors for invalid syntax', () {
      final Directory dir = Directory.systemTemp.createTempSync('pigeon_cov_');
      final File file = File('${dir.path}/bad.dart')..writeAsStringSync('class {');
      try {
        final ParseResults results = Pigeon.setup().parseFile(file.path);
        expect(results.errors, isNotEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });

  group('calculateLineNumber', () {
    test('maps byte offset to 1-based line number', () {
      expect(calculateLineNumber('a\nb\nc', 2), 2);
    });
  });
}
