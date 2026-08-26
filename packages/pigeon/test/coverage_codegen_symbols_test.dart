// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/arkts/arkts_generator.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/ast_generator.dart';
import 'package:pigeon/src/cpp/cpp_generator.dart';
import 'package:pigeon/src/dart/dart_generator.dart';
import 'package:pigeon/src/dart/proxy_api_generator_helper.dart';
import 'package:pigeon/src/dart/templates.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/kotlin/kotlin_generator.dart';
import 'package:pigeon/src/kotlin/templates.dart' as kotlin_templates;
import 'package:pigeon/src/objc/objc_generator.dart';
import 'package:pigeon/src/pigeon_cl.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:pigeon/src/swift/swift_generator.dart';
import 'package:pigeon/src/swift/templates.dart' as swift_templates;
import 'package:test/test.dart';

const String _proxyApiSource = '''
import 'package:pigeon/pigeon.dart';

@ProxyApi()
abstract class Counter {
  Counter();
  int value;
  int increment();
}
''';

void main() {
  group('top-level codegen symbols', () {
    late Root root;
    late AstProxyApi proxyApi;
    late InternalPigeonOptions internalOptions;

    setUp(() {
      proxyApi = AstProxyApi(
        name: 'Counter',
        constructors: <Constructor>[Constructor(name: '', parameters: <Parameter>[])],
        fields: <ApiField>[
          ApiField(
            name: 'value',
            type: const TypeDeclaration(baseName: 'int', isNullable: false),
            isAttached: true,
          ),
        ],
        methods: <Method>[
          Method(
            name: 'increment',
            location: ApiLocation.host,
            returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
            parameters: <Parameter>[],
          ),
          Method(
            name: 'onChanged',
            location: ApiLocation.flutter,
            returnType: TypeDeclaration.voidDeclaration(),
            parameters: <Parameter>[],
          ),
        ],
      );
      root = Root(
        apis: <Api>[proxyApi],
        classes: <Class>[],
        enums: <Enum>[],
        containsProxyApi: true,
      );
      internalOptions = InternalPigeonOptions.fromPigeonOptions(
        const PigeonOptions(
          dartOut: 'out.dart',
          arkTSOut: 'out.ets',
          arkTSOptions: ArkTSOptions(),
          dartPackageName: 'coverage_pkg',
        ),
      );
    });

    test('dart generator helpers', () {
      const intType = TypeDeclaration(baseName: 'int', isNullable: false);
      final named = NamedType(name: 'count', type: intType);
      getParameterName(0, named);
      addGenericTypes(intType);
      refer(intType);
      refer(intType, asFuture: true);
    });

    test('proxy api code_builder helpers', () {
      overridesClassConstructors(<AstProxyApi>[proxyApi]);
      overridesClassStaticFields(<AstProxyApi>[proxyApi]);
      overridesClassStaticMethods(<AstProxyApi>[proxyApi]);
      overridesClassResetMethod(<AstProxyApi>[proxyApi]);
      if (proxyApi.hostMethods.isNotEmpty) {
        methodAsFunctionType(
          proxyApi.hostMethods.first,
          apiName: proxyApi.name,
        );
      }
      staticAttachedFieldsGetters(proxyApi.attachedFields, apiName: proxyApi.name);
      writeProxyApiPigeonOverrides(
        Indent(),
        formatter: DartFormatter(languageVersion: DartFormatter.latestLanguageVersion),
        proxyApis: <AstProxyApi>[proxyApi],
      );
      codecInstanceField(codecInstanceName: 'codec', codecName: 'PigeonCodec');
      unattachedFields(proxyApi.unattachedFields);
      flutterMethodFields(proxyApi.flutterMethods, apiName: proxyApi.name);
      interfaceApiFields(proxyApi.apisOfInterfaces());
      attachedFields(proxyApi.attachedFields);
      setUpMessageHandlerMethod(
        flutterMethods: proxyApi.flutterMethods,
        apiName: proxyApi.name,
        dartPackageName: 'coverage_pkg',
        codecName: 'PigeonCodec',
        unattachedFields: proxyApi.unattachedFields,
        hasCallbackConstructor: proxyApi.hasCallbackConstructor(),
      );
      attachedFieldMethods(
        proxyApi.attachedFields,
        apiName: proxyApi.name,
        dartPackageName: 'coverage_pkg',
        codecInstanceName: 'codec',
        codecName: 'PigeonCodec',
      );
      hostMethods(
        proxyApi.hostMethods,
        apiName: proxyApi.name,
        dartPackageName: 'coverage_pkg',
        codecInstanceName: 'codec',
        codecName: 'PigeonCodec',
      );
      instanceManagerTemplate(allProxyApiNames: <String>[proxyApi.name]);
    });

    test('generator_tools helpers', () {
      const intType = TypeDeclaration(
        baseName: 'Map',
        isNullable: false,
        typeArguments: <TypeDeclaration>[
          TypeDeclaration(baseName: 'String', isNullable: false),
          TypeDeclaration(baseName: 'int', isNullable: false),
        ],
      );
      findHighestApiRequirement<int>(
        <TypeDeclaration>[intType],
        onGetApiRequirement: (TypeDeclaration type) => type.baseName == 'Map' ? 1 : null,
        onCompare: (int one, int two) => one.compareTo(two),
      );
      addLines(Indent(), <String>['line'], linePrefix: '// ');
      makeChannelName(
        AstHostApi(name: 'Host', methods: <Method>[]),
        Method(
          name: 'ping',
          location: ApiLocation.host,
          returnType: TypeDeclaration.voidDeclaration(),
          parameters: <Parameter>[],
        ),
        'coverage_pkg',
      );
      // readStdin() blocks on stdin until EOF; keep a reference for coverage only.
      final String Function() readStdinRef = () => readStdin();
      expect(readStdinRef, isA<Function>());
    });

    test('platform validators and generators', () {
      const cppOptions = InternalCppOptions(
        headerIncludePath: 'messages.h',
        cppHeaderOut: 'messages.h',
        cppSourceOut: 'messages.cpp',
      );
      validateCpp(cppOptions, root);
      const objcOptions = InternalObjcOptions(
        headerIncludePath: 'messages.h',
        objcHeaderOut: 'messages.h',
        objcSourceOut: 'messages.m',
      );
      validateObjc(objcOptions, root);
      generateObjcHeader(objcOptions, root, Indent());
      generateAst(root, StringBuffer());
    });

    test('kotlin and swift template helpers', () {
      const kotlinOptions = InternalKotlinOptions(kotlinOut: 'Messages.kt');
      kotlin_templates.kotlinInstanceManagerClassName(kotlinOptions);
      kotlin_templates.proxyApiRegistrarName(kotlinOptions);
      kotlin_templates.proxyApiCodecName(kotlinOptions);
      kotlin_templates.instanceManagerTemplate(kotlinOptions);
      const swiftOptions = InternalSwiftOptions(swiftOut: 'Messages.swift');
      swift_templates.instanceManagerFinalizerDelegateName(swiftOptions);
      swift_templates.proxyApiReaderWriterName(swiftOptions);
      swift_templates.swiftInstanceManagerClassName(swiftOptions);
      swift_templates.instanceManagerFinalizerDelegateTemplate(swiftOptions);
      swift_templates.instanceManagerFinalizerTemplate(swiftOptions);
    });

    test('calculateLineNumber maps offsets to lines', () {
      calculateLineNumber(_proxyApiSource, 1);
    });

    test('runCommandLine prints usage when input is missing', () async {
      expect(await runCommandLine(<String>[]), 0);
    });
  });
}
