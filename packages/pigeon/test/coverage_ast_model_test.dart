// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:test/test.dart';

void main() {
  group('PigeonOptions', () {
    test('merge overlays non-null fields', () {
      const base = PigeonOptions(dartOut: 'a.dart', arkTSOut: 'a.ets');
      final merged = base.merge(const PigeonOptions(arkTSOut: 'b.ets', debugGenerators: true));
      expect(merged.dartOut, 'a.dart');
      expect(merged.arkTSOut, 'b.ets');
      expect(merged.debugGenerators, isTrue);
    });

    test('getPackageName returns dartPackageName', () {
      const options = PigeonOptions(dartPackageName: 'my_pkg');
      expect(options.getPackageName(), 'my_pkg');
    });
  });

  group('TypeDeclaration helpers', () {
    late Enum enumDef;
    late Class classDef;
    late AstProxyApi proxyApi;

    setUp(() {
      enumDef = Enum(name: 'Role', members: <EnumMember>[EnumMember(name: 'admin')]);
      classDef = Class(name: 'Item', fields: <NamedType>[]);
      proxyApi = AstProxyApi(
        name: 'Counter',
        constructors: <Constructor>[],
        fields: <ApiField>[],
        methods: <Method>[],
      );
    });

    test('copyWith and type predicates', () {
      const intType = TypeDeclaration(baseName: 'int', isNullable: false);
      const voidType = TypeDeclaration.voidDeclaration();
      intType.copyWithEnum(enumDef);
      intType.copyWithClass(classDef);
      intType.copyWithProxyApi(proxyApi);
      intType.copyWithTypeArguments(<TypeDeclaration>[intType]);
      expect(voidType.isVoid, isTrue);
      expect(
        TypeDeclaration(baseName: 'Role', isNullable: false, associatedEnum: enumDef).isEnum,
        isTrue,
      );
      final TypeDeclaration classType = TypeDeclaration(
        baseName: 'Item',
        isNullable: false,
        associatedClass: classDef,
      );
      final TypeDeclaration proxyType = TypeDeclaration(
        baseName: 'Counter',
        isNullable: false,
        associatedProxyApi: proxyApi,
      );
      final bool isClass = classType.isClass;
      final bool isProxyApi = proxyType.isProxyApi;
      expect(isClass, isTrue);
      expect(isProxyApi, isTrue);
    });
  });

  group('NamedType Parameter ApiField', () {
    test('copyWithType and optional metadata', () {
      const intType = TypeDeclaration(baseName: 'int', isNullable: false);
      final named = NamedType(name: 'x', type: intType, offset: 3, defaultValue: '0');
      named.copyWithType(const TypeDeclaration(baseName: 'String', isNullable: true));
      expect(named.offset, 3);
      expect(named.defaultValue, '0');
      final parameter = Parameter(name: 'x', type: intType, isOptional: true);
      parameter.copyWithType(intType);
      expect(parameter.isOptional, isTrue);
      final field = ApiField(name: 'count', type: intType);
      field.copyWithType(intType);
    });
  });

  group('Class Root Constant', () {
    test('class metadata and root flags', () {
      final child = Class(name: 'Child', fields: <NamedType>[]);
      final parent = Class(
        name: 'Parent',
        fields: <NamedType>[],
        superClassName: 'Base',
        isSealed: true,
        isReferenced: true,
        isSwiftClass: true,
      )..children = <Class>[child];
      expect(parent.superClassName, 'Base');
      expect(parent.children, contains(child));
      expect(parent.isSealed, isTrue);
      expect(parent.isReferenced, isTrue);
      expect(parent.isSwiftClass, isTrue);
      final constant = Constant(
        name: 'k',
        type: const TypeDeclaration(baseName: 'int', isNullable: false),
        value: 1,
        offset: 9,
      );
      expect(constant.offset, 9);
      final root = Root(
        apis: <Api>[
          AstProxyApi(
            name: 'Api',
            constructors: <Constructor>[],
            fields: <ApiField>[],
            methods: <Method>[],
          ),
        ],
        classes: <Class>[parent],
        enums: <Enum>[],
        containsProxyApi: true,
      );
      expect(root.containsProxyApi, isTrue);
    });
  });

  group('AstProxyApi', () {
    late Method hostMethod;
    late Method requiredFlutterMethod;
    late Method optionalFlutterMethod;
    late AstProxyApi interfaceApi;
    late AstProxyApi superApi;
    late AstProxyApi childApi;

    setUp(() {
      hostMethod = Method(
        name: 'hostEcho',
        location: ApiLocation.host,
        returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        parameters: <Parameter>[],
      );
      requiredFlutterMethod = Method(
        name: 'requiredFlutter',
        location: ApiLocation.flutter,
        returnType: const TypeDeclaration.voidDeclaration(),
        parameters: <Parameter>[],
        isRequired: true,
      );
      optionalFlutterMethod = Method(
        name: 'optionalFlutter',
        location: ApiLocation.flutter,
        returnType: const TypeDeclaration.voidDeclaration(),
        parameters: <Parameter>[],
        isRequired: false,
      );
      interfaceApi = AstProxyApi(
        name: 'Iface',
        constructors: <Constructor>[],
        fields: <ApiField>[],
        methods: <Method>[
          Method(
            name: 'ifaceFlutter',
            location: ApiLocation.flutter,
            returnType: const TypeDeclaration.voidDeclaration(),
            parameters: <Parameter>[],
            isRequired: false,
          ),
        ],
      );
      superApi = AstProxyApi(
        name: 'Super',
        constructors: <Constructor>[Constructor(name: '', parameters: <Parameter>[])],
        fields: <ApiField>[
          ApiField(
            name: 'attached',
            type: const TypeDeclaration(baseName: 'int', isNullable: false),
            isAttached: true,
          ),
        ],
        methods: <Method>[
          hostMethod,
          Method(
            name: 'superFlutter',
            location: ApiLocation.flutter,
            returnType: const TypeDeclaration.voidDeclaration(),
            parameters: <Parameter>[],
            isRequired: false,
          ),
        ],
      );
      childApi = AstProxyApi(
        name: 'Child',
        constructors: <Constructor>[],
        fields: <ApiField>[
          ApiField(
            name: 'unattached',
            type: const TypeDeclaration(baseName: 'String', isNullable: false),
            isAttached: false,
          ),
        ],
        methods: <Method>[optionalFlutterMethod],
        superClass: TypeDeclaration(
          baseName: 'Super',
          isNullable: false,
          associatedProxyApi: superApi,
        ),
        interfaces: <TypeDeclaration>{
          TypeDeclaration(
            baseName: 'Iface',
            isNullable: false,
            associatedProxyApi: interfaceApi,
          ),
        },
      );
    });

    test('flutterMethodsFromInterfaces and flutterMethodsFromSuperClasses', () {
      expect(childApi.flutterMethodsFromInterfaces(), isNotEmpty);
      expect(childApi.flutterMethodsFromSuperClasses(), isNotEmpty);
    });

    test('hasCallbackConstructor and message call flags', () {
      childApi.hasCallbackConstructor();
      expect(childApi.hasAnyHostMessageCalls(), isFalse);
      expect(childApi.hasAnyFlutterMessageCalls(), isTrue);
      expect(childApi.hasMethodsRequiringImplementation(), isTrue);
      final strictApi = AstProxyApi(
        name: 'Strict',
        constructors: <Constructor>[],
        fields: <ApiField>[],
        methods: <Method>[requiredFlutterMethod],
      );
      expect(strictApi.hasCallbackConstructor(), isFalse);
    });

    test('hostMethods flutterMethods attachedFields unattachedFields', () {
      expect(superApi.hostMethods, contains(hostMethod));
      expect(childApi.flutterMethods, contains(optionalFlutterMethod));
      expect(superApi.attachedFields, isNotEmpty);
      expect(childApi.unattachedFields, isNotEmpty);
    });
  });

  group('HostDatatype EnumeratedType Error', () {
    test('HostDatatype flags', () {
      final builtin = HostDatatype(datatype: 'int', isBuiltin: true, isNullable: false, isEnum: false);
      expect(builtin.isBuiltin, isTrue);
      expect(builtin.isEnum, isFalse);
    });

    test('EnumeratedType offset', () {
      final enumerated = EnumeratedType('T', 5, CustomTypes.customClass);
      expect(enumerated.enumeration, 5);
      expect(enumerated.offset(2), 3);
    });

    test('Error fields', () {
      final error = Error(message: 'msg', filename: 'f.dart', lineNumber: 4);
      expect(error.message, 'msg');
      expect(error.filename, 'f.dart');
      expect(error.lineNumber, 4);
    });
  });

  group('DocumentCommentSpecification', () {
    test('openCommentToken is exposed', () {
      const spec = DocumentCommentSpecification('/**');
      expect(spec.openCommentToken, '/**');
    });
  });

  group('InternalPigeonOptions debugGenerators', () {
    test('debugGenerators round-trips from PigeonOptions', () {
      final internal = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(debugGenerators: true),
      );
      expect(internal.debugGenerators, isTrue);
    });
  });

  group('Pigeon CLI surface', () {
    test('usage documents CLI flags', () {
      expect(Pigeon.usage, contains('--input'));
    });
  });
}
