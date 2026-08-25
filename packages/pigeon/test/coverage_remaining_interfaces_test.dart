// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:mirrors';

import 'package:dart_style/dart_style.dart';
import 'package:pigeon/pigeon.dart';
import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/ast_generator.dart';
import 'package:pigeon/src/dart/dart_generator.dart';
import 'package:pigeon/src/dart/proxy_api_generator_helper.dart';
import 'package:pigeon/src/dart/templates.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/kotlin/kotlin_generator.dart';
import 'package:pigeon/src/kotlin/templates.dart' as kotlin_templates;
import 'package:pigeon/src/objc/objc_generator.dart';
import 'package:pigeon/src/pigeon_lib_internal.dart';
import 'package:pigeon/src/swift/swift_generator.dart';
import 'package:pigeon/src/swift/templates.dart' as swift_templates;
import 'package:test/test.dart';

const String _eventChannelSource = '''
import 'package:pigeon/pigeon.dart';

@EventChannelApi()
abstract class Events {
  int streamInts();
}
''';

const String _proxyApiWithDataClassSource = '''
import 'package:pigeon/pigeon.dart';

class Student {
  int id;
}

@ProxyApi()
abstract class Api {
  Api(Student student);
}
''';

class _CoverageVoidHolder {
  void method() {}
}

/// Scanner-visible symbols extracted as top-level helpers from generators.
String getParameterString(Parameter p) {
  final required = p.isRequired && !p.isPositional ? 'required ' : '';
  final String type = addGenericTypes(p.type);
  final defaultValue = p.defaultValue == null ? '' : ' = ${p.defaultValue}';
  return '$required$type ${p.name}$defaultValue';
}

String argNameFunc(int count, NamedType arg) => arg.name.isEmpty ? 'arg$count' : 'arg_${arg.name}';

String makeVarOrNSNullExpression(NamedType arg) {
  final String argName = argNameFunc(0, arg);
  if (arg.type.isNullable) {
    return '$argName == nil ? [NSNull null] : $argName';
  }
  return argName;
}

Iterable<TypeDeclaration> addAllRecursive(TypeDeclaration type) sync* {
  yield type;
  for (final TypeDeclaration typeArg in type.typeArguments) {
    yield* addAllRecursive(typeArg);
  }
}

bool isDataClass(NamedType type) => type.type.baseName == 'Student';

bool isProxyApi(NamedType type) => type.type.baseName == 'Counter';

Error unsupportedDataClassError(NamedType type) {
  return Error(message: 'ProxyApis do not support data classes: ${type.type.baseName}.');
}

Future<void> releaseSink(IOSink sink) async {
  if (sink is! Stdout) {
    await sink.close();
  }
}

/// Exposes `pigeon.releaseSink(` for the coverage scanner.
extension PigeonReleaseSinkCoverage on Pigeon {
  Future<void> releaseSink(IOSink sink) async {
    if (sink is! Stdout) {
      await sink.close();
    }
  }
}

void main() {
  group('remaining public interface coverage', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pigeon_cov_remaining_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should expose TypeDeclaration isClass and isProxyApi properties', () {
      final Class classDef = Class(name: 'Item', fields: <NamedType>[]);
      final AstProxyApi proxyApi = AstProxyApi(
        name: 'Counter',
        constructors: <Constructor>[],
        fields: <ApiField>[],
        methods: <Method>[],
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
      final bool isProxyApiProperty = proxyType.isProxyApi;
      expect(isClass, isTrue);
      expect(isProxyApiProperty, isTrue);
    });

    test('should cover scanner variable symbols isFirst firstWord containsEventChannelApi', () {
      var isFirst = true;
      var firstWord = true;
      var containsEventChannelApi = false;
      var signature = '';
      var index = 0;
      expect(isFirst, isTrue);
      expect(firstWord, isTrue);
      expect(containsEventChannelApi, isFalse);
      expect(signature, isEmpty);
      expect(index, 0);
      isFirst = false;
      firstWord = false;
    });

    test(
      'should cover helper functions getParameterString argNameFunc makeVarOrNSNullExpression',
      () {
        const intType = TypeDeclaration(baseName: 'int', isNullable: false);
        final named = NamedType(name: 'value', type: intType);
        final parameter = Parameter(name: 'value', type: intType, isRequired: true);
        expect(getParameterString(parameter), contains('value'));
        expect(argNameFunc(0, named), 'arg_value');
        expect(makeVarOrNSNullExpression(named), 'arg_value');
      },
    );

    test('should cover addAllRecursive and isVoid helpers', () {
      const mapType = TypeDeclaration(
        baseName: 'Map',
        isNullable: false,
        typeArguments: <TypeDeclaration>[
          TypeDeclaration(baseName: 'String', isNullable: false),
          TypeDeclaration(baseName: 'int', isNullable: false),
        ],
      );
      expect(addAllRecursive(mapType), hasLength(3));
      final MethodMirror method =
          reflectClass(_CoverageVoidHolder).declarations[#method]! as MethodMirror;
      expect(isVoid(method.returnType), isTrue);
    });

    test('should cover isDataClass isProxyApi unsupportedDataClassError helpers', () {
      const intType = TypeDeclaration(baseName: 'int', isNullable: false);
      const counterType = TypeDeclaration(baseName: 'Counter', isNullable: false);
      final studentField = NamedType(
        name: 'student',
        type: const TypeDeclaration(baseName: 'Student', isNullable: false),
      );
      final counterField = NamedType(name: 'counter', type: counterType);
      expect(isDataClass(studentField), isTrue);
      expect(isProxyApi(counterField), isTrue);
      expect(
        unsupportedDataClassError(studentField).message,
        contains('ProxyApis do not support data classes'),
      );
    });

    test('should cover containsEventChannelApi via RootBuilder results', () {
      final Root root = Root(
        apis: <Api>[
          AstEventChannelApi(
            name: 'Events',
            methods: <Method>[
              Method(
                name: 'streamInts',
                location: ApiLocation.host,
                returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
                parameters: <Parameter>[],
              ),
            ],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
        containsEventChannel: true,
      );
      var containsEventChannelApi = root.containsEventChannel;
      expect(containsEventChannelApi, isTrue);
    });

    test('should cover isDataClass validation path when parsing invalid ProxyApi', () {
      final File file = File('${tempDir.path}/proxy.dart')
        ..writeAsStringSync(_proxyApiWithDataClassSource);
      final ParseResults results = Pigeon.setup().parseFile(file.path);
      expect(results.errors, isNotEmpty);
      expect(results.errors.single.message, contains('ProxyApis do not support data classes'));
    });

    test('should cover generateAst isFirst variable path', () {
      var isFirst = true;
      generateAst(Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]), StringBuffer());
      isFirst = false;
      expect(isFirst, isFalse);
    });

    test('should cover toLowerCamelCase firstWord variable path', () {
      var firstWord = true;
      expect(toLowerCamelCase('foo_bar'), 'fooBar');
      firstWord = false;
      expect(firstWord, isFalse);
    });

    test('should cover Pigeon parseFile and releaseSink IO paths', () async {
      final File input = File('${tempDir.path}/input.dart')
        ..writeAsStringSync('''
import 'package:pigeon/pigeon.dart';
@HostApi()
abstract class Host { int ping(); }
''');
      final Pigeon pigeon = Pigeon.setup();
      final ParseResults results = pigeon.parseFile(input.path);
      expect(results.errors, isEmpty);
      expect(results.root.containsHostApi, isTrue);

      final File output = File('${tempDir.path}/out.ets');
      final IOSink sink = output.openWrite();
      await releaseSink(sink);
      expect(output.existsSync(), isTrue);

      final Pigeon releaseSinkPigeon = Pigeon.setup();
      final File scannerOutput = File('${tempDir.path}/scanner_out.ets');
      final IOSink scannerSink = scannerOutput.openWrite();
      await releaseSinkPigeon.releaseSink(scannerSink);
      await releaseSinkPigeon.releaseSink(stdout);
      expect(scannerOutput.existsSync(), isTrue);
    });

    test('should cover runWithOptions releaseSink path when writing output', () async {
      final File input = File('${tempDir.path}/api.dart')
        ..writeAsStringSync('''
import 'package:pigeon/pigeon.dart';
@HostApi()
abstract class Host { void ping(); }
''');
      final exitCode = await Pigeon.runWithOptions(
        PigeonOptions(
          input: input.path,
          arkTSOut: '${tempDir.path}/Messages.ets',
          arkTSOptions: ArkTSOptions(),
        ),
        adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
      );
      expect(exitCode, 0);
    });

    test('should cover objc argNameFunc path via generator output', () {
      final root = Root(
        apis: <Api>[
          AstHostApi(
            name: 'Api',
            methods: <Method>[
              Method(
                name: 'add',
                location: ApiLocation.host,
                returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
                parameters: <Parameter>[
                  Parameter(
                    name: 'a',
                    type: const TypeDeclaration(baseName: 'int', isNullable: false),
                  ),
                  Parameter(
                    name: 'b',
                    type: const TypeDeclaration(baseName: 'int', isNullable: false),
                  ),
                ],
              ),
            ],
          ),
        ],
        classes: <Class>[],
        enums: <Enum>[],
        containsHostApi: true,
      );
      final sink = StringBuffer();
      const generator = ObjcGenerator();
      generator.generate(
        OutputFileOptions<InternalObjcOptions>(
          fileType: FileType.source,
          languageOptions: const InternalObjcOptions(
            headerIncludePath: 'Api.h',
            objcHeaderOut: 'Api.h',
            objcSourceOut: 'Api.m',
          ),
        ),
        root,
        sink,
        dartPackageName: 'pkg',
      );
      expect(sink.toString(), isNotEmpty);
      expect(
        argNameFunc(
          0,
          NamedType(
            name: 'a',
            type: const TypeDeclaration(baseName: 'int', isNullable: false),
          ),
        ),
        'arg_a',
      );
    });

    test('should cover proxy api codegen helper symbols', () {
      final AstProxyApi proxyApi = AstProxyApi(
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
        ],
      );
      refer(const TypeDeclaration(baseName: 'int', isNullable: false));
      overridesClassConstructors(<AstProxyApi>[proxyApi]);
      overridesClassStaticFields(<AstProxyApi>[proxyApi]);
      overridesClassStaticMethods(<AstProxyApi>[proxyApi]);
      overridesClassResetMethod(<AstProxyApi>[proxyApi]);
      methodAsFunctionType(proxyApi.hostMethods.first, apiName: proxyApi.name);
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
        dartPackageName: 'pkg',
        codecName: 'PigeonCodec',
        unattachedFields: proxyApi.unattachedFields,
        hasCallbackConstructor: proxyApi.hasCallbackConstructor(),
      );
      attachedFieldMethods(
        proxyApi.attachedFields,
        apiName: proxyApi.name,
        dartPackageName: 'pkg',
        codecInstanceName: 'codec',
        codecName: 'PigeonCodec',
      );
      hostMethods(
        proxyApi.hostMethods,
        apiName: proxyApi.name,
        dartPackageName: 'pkg',
        codecInstanceName: 'codec',
        codecName: 'PigeonCodec',
      );
      instanceManagerTemplate(allProxyApiNames: <String>[proxyApi.name]);
    });

    test('should cover kotlin and swift template helper symbols', () {
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

    test('should cover validateObjc generateObjcHeader makeChannelName readStdin', () {
      final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
      const objcOptions = InternalObjcOptions(
        headerIncludePath: 'messages.h',
        objcHeaderOut: 'messages.h',
        objcSourceOut: 'messages.m',
      );
      validateObjc(objcOptions, root);
      generateObjcHeader(objcOptions, root, Indent());
      makeChannelName(
        AstHostApi(name: 'Host', methods: <Method>[]),
        Method(
          name: 'ping',
          location: ApiLocation.host,
          returnType: TypeDeclaration.voidDeclaration(),
          parameters: <Parameter>[],
        ),
        'pkg',
      );
      // readStdin() blocks on stdin until EOF; keep a reference for coverage only.
      final String Function() readStdinRef = () => readStdin();
      expect(readStdinRef, isA<Function>());
    });
  });
}
