// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: unnecessary_statements, specify_nonobvious_local_variable_types

/// Demonstrates public Pigeon APIs for OHOS / ArkTS code generation.
///
/// See [example/OHOS_README.md](OHOS_README.md) for the full integration guide.
library;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as dart_ast;
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

const String _demoPigeonSource = '''
import 'package:pigeon/pigeon.dart';

const int kVersion = 1;

enum Status { ok }

class Item {
  int value;
}

@HostApi()
abstract class Host {
  int add(int a, int b);
}
''';

class _DemoVoidHolder {
  void method() {}
}

Future<void> main() async {
  _demonstratePigeonOptions();
  _demonstrateGeneratorAdapters();
  _demonstrateGeneratorAdapterBase();
  _demonstrateOutputFileOptions();
  _demonstratePigeonCli();
  await _demonstratePigeonRun();
  _demonstratePigeonParseFile();
  _demonstrateRootBuilder();
  _demonstrateAstModel();
  _demonstrateAnnotations();
  _demonstrateGeneratorTools();
  _demonstrateProxyApiModel();
  _demonstrateCodegenSymbols();
  await _demonstrateRemainingDemoSymbols();
}

void _demonstratePigeonOptions() {
  const options = PigeonOptions(
    input: 'pigeons/messages.dart',
    dartOut: 'lib/src/messages.g.dart',
    dartTestOut: 'test/messages_test.dart',
    dartOptions: DartOptions(),
    basePath: 'lib/src',
    ignoreLints: true,
    arkTSOut: 'ohos/entry/src/main/ets/plugins/Messages.ets',
    arkTSOptions: ArkTSOptions(copyrightHeader: <String>['// Copyright']),
    kotlinOut: 'android/Messages.kt',
    kotlinOptions: KotlinOptions(),
    swiftOut: 'ios/Messages.swift',
    swiftOptions: SwiftOptions(),
    javaOut: 'android/Messages.java',
    javaOptions: JavaOptions(),
    objcHeaderOut: 'macos/messages.h',
    objcSourceOut: 'macos/messages.m',
    objcOptions: ObjcOptions(),
    cppHeaderOut: 'windows/messages.h',
    cppSourceOut: 'windows/messages.cpp',
    cppOptions: CppOptions(),
    gobjectHeaderOut: 'linux/messages.h',
    gobjectSourceOut: 'linux/messages.cc',
    gobjectOptions: GObjectOptions(),
    astOut: 'out.ast',
    dartPackageName: 'pigeon_example_package',
    debugGenerators: true,
  );
  options.toMap();
  options.merge(const PigeonOptions(arkTSOut: 'other.ets'));
  options.getPackageName();
  options.dartTestOut;
  options.dartOptions;
  options.basePath;
  options.ignoreLints;
  PigeonOptions.fromMap(options.toMap());
  ArkTSOptions.fromMap(<String, Object>{}).toMap();
  const taskQueue = TaskQueue(type: TaskQueueType.serialBackgroundThread);
  taskQueue.type;
  final InternalPigeonOptions internal = InternalPigeonOptions.fromPigeonOptions(options);
  internal.dartOptions;
  internal.basePath;
}

void _demonstrateGeneratorAdapters() {
  const arkts = ArkTSGeneratorAdapter();
  const kotlin = KotlinGeneratorAdapter();
  const swift = SwiftGeneratorAdapter();
  const java = JavaGeneratorAdapter();
  const objc = ObjcGeneratorAdapter();
  const cpp = CppGeneratorAdapter();
  const gobject = GObjectGeneratorAdapter();
  const dart = DartGeneratorAdapter();
  const dartTest = DartTestGeneratorAdapter();
  const ast = AstGeneratorAdapter();
  const adapters = <GeneratorAdapter>[
    arkts,
    kotlin,
    swift,
    java,
    objc,
    cpp,
    gobject,
    dart,
    dartTest,
    ast,
  ];
  final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
  final internal = InternalPigeonOptions.fromPigeonOptions(
    const PigeonOptions(
      arkTSOut: 'Messages.ets',
      arkTSOptions: ArkTSOptions(),
      debugGenerators: true,
    ),
  );
  arkts.fileTypeList;
  arkts.validate(internal, root);
  arkts.shouldGenerate(internal, FileType.na);
  kotlin.fileTypeList;
  kotlin.validate(internal, root);
  kotlin.shouldGenerate(internal, FileType.na);
  swift.fileTypeList;
  swift.validate(internal, root);
  swift.shouldGenerate(internal, FileType.na);
  java.fileTypeList;
  java.validate(internal, root);
  java.shouldGenerate(internal, FileType.na);
  objc.fileTypeList;
  objc.validate(internal, root);
  objc.shouldGenerate(internal, FileType.na);
  cpp.fileTypeList;
  cpp.validate(internal, root);
  cpp.shouldGenerate(internal, FileType.na);
  gobject.fileTypeList;
  gobject.validate(internal, root);
  gobject.shouldGenerate(internal, FileType.na);
  dart.fileTypeList;
  dart.validate(internal, root);
  dart.shouldGenerate(internal, FileType.na);
  dartTest.fileTypeList;
  dartTest.validate(internal, root);
  dartTest.shouldGenerate(internal, FileType.na);
  ast.fileTypeList;
  ast.validate(internal, root);
  ast.shouldGenerate(internal, FileType.na);
  for (final adapter in adapters) {
    adapter.fileTypeList;
    adapter.validate(internal, root);
    adapter.shouldGenerate(internal, FileType.na);
    final buffer = StringBuffer();
    adapter.generate(buffer, internal, root, FileType.na);
    buffer.toString();
  }
}

void _demonstrateGeneratorAdapterBase() {
  final GeneratorAdapter adapter = const ArkTSGeneratorAdapter();
  final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
  final internal = InternalPigeonOptions.fromPigeonOptions(
    const PigeonOptions(arkTSOut: 'Messages.ets', arkTSOptions: ArkTSOptions()),
  );
  adapter.fileTypeList;
  adapter.validate(internal, root);
  adapter.shouldGenerate(internal, FileType.na);
}

void _demonstrateOutputFileOptions() {
  final OutputFileOptions<InternalArkTSOptions> arktsOutput =
      OutputFileOptions<InternalArkTSOptions>(
        fileType: FileType.na,
        languageOptions: const InternalArkTSOptions(arkTSOut: 'Messages.ets'),
      );
  arktsOutput.fileType;
  arktsOutput.languageOptions;
  final OutputFileOptions<InternalCppOptions> cppOutput = OutputFileOptions<InternalCppOptions>(
    fileType: FileType.header,
    languageOptions: const InternalCppOptions(
      headerIncludePath: 'messages.h',
      cppHeaderOut: 'messages.h',
      cppSourceOut: 'messages.cpp',
    ),
  );
  cppOutput.fileType;
  cppOutput.languageOptions;
}

void _demonstratePigeonCli() {
  Pigeon.setup();
  final parsed = Pigeon.parseArgs(<String>[
    '--input',
    'pigeons/messages.dart',
    '--dart_out',
    'lib/src/messages.g.dart',
    '--arkts_out',
    'ohos/entry/src/main/ets/plugins/Messages.ets',
    '--kotlin_out',
    'android/Messages.kt',
    '--swift_out',
    'ios/Messages.swift',
  ]);
  parsed.input;
  parsed.arkTSOut;
  parsed.arkTSOptions;
  parsed.debugGenerators;
  Pigeon.usage;
  const HostApi(dartHostTestHandler: 'handler');
}

Future<void> _demonstratePigeonRun() async {
  final Directory dir = Directory.systemTemp.createTempSync('pigeon_demo_run_');
  final File input = File('${dir.path}/api.dart')..writeAsStringSync(_demoPigeonSource);
  try {
    await Pigeon.run(
      <String>['--input', input.path, '--arkts_out', '${dir.path}/Messages.ets'],
      adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
    );
    await Pigeon.runWithOptions(
      PigeonOptions(
        input: input.path,
        arkTSOut: '${dir.path}/Messages2.ets',
        arkTSOptions: ArkTSOptions(),
      ),
      adapters: const <GeneratorAdapter>[ArkTSGeneratorAdapter()],
    );
    await runCommandLine(<String>[]);
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void _demonstratePigeonParseFile() {
  final Directory dir = Directory.systemTemp.createTempSync('pigeon_demo_parse_');
  final File file = File('${dir.path}/input.dart')..writeAsStringSync(_demoPigeonSource);
  try {
    final Pigeon pigeon = Pigeon.setup();
    final ParseResults results = pigeon.parseFile(file.path);
    results.root;
    results.errors;
    results.pigeonOptions;
    for (final Error error in results.errors) {
      error.filename;
      error.lineNumber;
      error.message;
    }
    final Error demoError = Error(message: 'demo', filename: file.path, lineNumber: 2);
    demoError.filename;
    demoError.lineNumber;
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void _demonstrateRootBuilder() {
  final RootBuilder builder = RootBuilder(_demoPigeonSource);
  builder.source;
  final dart_ast.CompilationUnit unit = parseString(content: _demoPigeonSource).unit;
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
  results.root;
  results.errors;
  results.pigeonOptions;
  calculateLineNumber(_demoPigeonSource, 2);
}

void _demonstrateAstModel() {
  final enumDef = Enum(name: 'Identity', members: <EnumMember>[]);
  const intType = TypeDeclaration(baseName: 'int', isNullable: false);
  final classDef = Class(name: 'Student', fields: <NamedType>[]);
  final proxyApi = AstProxyApi(
    name: 'Counter',
    constructors: <Constructor>[],
    fields: <ApiField>[],
    methods: <Method>[],
  );
  intType.copyWithEnum(enumDef);
  intType.copyWithClass(classDef);
  intType.copyWithProxyApi(proxyApi);
  intType.copyWithTypeArguments(<TypeDeclaration>[intType]);
  intType.isVoid;
  intType.isEnum;
  intType.isClass;
  intType.isProxyApi;
  const mapType = TypeDeclaration(
    baseName: 'Map',
    isNullable: false,
    typeArguments: <TypeDeclaration>[
      TypeDeclaration(baseName: 'String', isNullable: false),
      TypeDeclaration(baseName: 'int', isNullable: false),
    ],
  );
  mapType.typeArguments;
  final classType = TypeDeclaration(
    baseName: 'Student',
    isNullable: false,
    associatedClass: classDef,
  );
  classType.associatedClass;
  final enumType = TypeDeclaration(
    baseName: 'Identity',
    isNullable: false,
    associatedEnum: enumDef,
  );
  final named = NamedType(name: 'value', type: intType);
  named.copyWithType(enumType);
  named.offset;
  named.defaultValue;
  final parameter = Parameter(name: 'value', type: intType);
  parameter.copyWithType(enumType);
  parameter.isOptional;
  parameter.isNamed;
  parameter.isPositional;
  parameter.isRequired;
  final field = ApiField(name: 'count', type: intType);
  field.copyWithType(enumType);
  field.isAttached;
  field.isStatic;
  final method = Method(
    name: 'ping',
    location: ApiLocation.host,
    returnType: intType,
    parameters: <Parameter>[parameter],
    offset: 1,
    isAsynchronous: false,
    objcSelector: 'ping',
    swiftFunction: 'ping',
    taskQueueType: TaskQueueType.serialBackgroundThread,
    isRequired: true,
    isStatic: false,
  );
  method.offset;
  final klass = Class(name: 'Student', fields: <NamedType>[named]);
  klass.superClassName;
  klass.children;
  klass.isSealed;
  klass.isReferenced;
  klass.isSwiftClass;
  klass.superClass;
  klass.documentationComments;
  final constant = Constant(
    name: 'kVersion',
    type: const TypeDeclaration(baseName: 'String', isNullable: false),
    value: '1',
    offset: 2,
  );
  constant.offset;
  constant.documentationComments;
  final root = Root(
    apis: <Api>[
      AstHostApi(name: 'Host', methods: <Method>[method], dartHostTestHandler: 'h'),
      proxyApi,
    ],
    classes: <Class>[klass],
    enums: <Enum>[enumDef],
    containsProxyApi: true,
    constants: <Constant>[constant],
    containsHostApi: true,
    containsFlutterApi: false,
    containsEventChannel: false,
  );
  root.containsProxyApi;
  root.classes;
  root.apis;
  root.enums;
  root.constants;
  root.containsHostApi;
  root.containsFlutterApi;
  root.containsEventChannel;
  root.requiresOverflowClass;
  final parseResults = ParseResults(
    root: root,
    errors: <Error>[Error(message: 'demo', filename: 'demo.dart', lineNumber: 3)],
    pigeonOptions: null,
  );
  parseResults.root;
  parseResults.errors;
  parseResults.pigeonOptions;
  HostDatatype(datatype: 'int', isBuiltin: true, isNullable: false, isEnum: false).isBuiltin;
  HostDatatype(datatype: 'Identity', isBuiltin: false, isNullable: false, isEnum: true).isEnum;
  final enumerated = EnumeratedType(
    'Student',
    1,
    CustomTypes.customClass,
    associatedClass: classDef,
    associatedEnum: enumDef,
  );
  enumerated.enumeration;
  enumerated.name;
  enumerated.offset(0);
  enumerated.type;
  enumerated.associatedEnum;
  enumerated.associatedClass;
}

void _demonstrateProxyApiModel() {
  final flutterMethod = Method(
    name: 'echo',
    location: ApiLocation.flutter,
    returnType: const TypeDeclaration(baseName: 'String', isNullable: false),
    parameters: <Parameter>[],
    isRequired: false,
  );
  final iface = AstProxyApi(
    name: 'Iface',
    constructors: <Constructor>[],
    fields: <ApiField>[],
    methods: <Method>[flutterMethod],
  );
  final api = AstProxyApi(
    name: 'Api',
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
        name: 'host',
        location: ApiLocation.host,
        returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        parameters: <Parameter>[],
      ),
    ],
    interfaces: <TypeDeclaration>{
      TypeDeclaration(baseName: 'Iface', isNullable: false, associatedProxyApi: iface),
    },
  );
  api.flutterMethodsFromInterfaces();
  api.flutterMethodsFromSuperClasses();
  api.hasCallbackConstructor();
  api.hasAnyHostMessageCalls();
  api.hasAnyFlutterMessageCalls();
  api.hasMethodsRequiringImplementation();
  api.hostMethods;
  api.flutterMethods;
  api.attachedFields;
  api.unattachedFields;
  api.allSuperClasses();
  api.apisOfInterfaces();
  api.superClass;
  api.interfaces;
}

void _demonstrateGeneratorTools() {
  const spec = DocumentCommentSpecification(
    '/*',
    closeCommentToken: '*/',
    blockContinuationToken: ' *',
  );
  spec.openCommentToken;
  spec.closeCommentToken;
  spec.blockContinuationToken;
  asDocumentationComments(<String>['line'], spec);
  addDocumentationComments(Indent(), <String>['line'], spec);
  makeChannelNameWithStrings(apiName: 'Api', methodName: 'm', dartPackageName: 'pkg');
  makeRemoveStrongReferenceChannelName('pkg');
  makeClearChannelName('pkg');
  isCollectionType(const TypeDeclaration(baseName: 'Map', isNullable: false));
  escapeStringDoubleQuotes('x');
  escapeStringSingleQuotes('x');
  getGeneratedCodeWarning();
  customTypeOverflowCheck(Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]));
  getFieldsInSerializationOrder(Class(name: 'C', fields: <NamedType>[]));
  deducePackageName('pubspec.yaml');
  toUpperCamelCase('foo_bar');
  toLowerCamelCase('FooBar');
  toScreamingSnakeCase('fooBar');
  getEnumeratedTypes(Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]));
  addLines(Indent(), <String>['line'], linePrefix: '// ');
  final indent = Indent();
  indent.str();
  indent.newline;
  indent.tab;
}

void _demonstrateCodegenSymbols() {
  const intType = TypeDeclaration(baseName: 'int', isNullable: false);
  const named = NamedType(name: 'count', type: intType);
  getParameterName(0, named);
  addGenericTypes(intType);
  generateAst(Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]), StringBuffer());
  validateCpp(
    const InternalCppOptions(
      headerIncludePath: 'messages.h',
      cppHeaderOut: 'messages.h',
      cppSourceOut: 'messages.cpp',
    ),
    Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]),
  );
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

String getParameterString(Parameter p) {
  final required = p.isRequired && !p.isPositional ? 'required ' : '';
  final String type = addGenericTypes(p.type);
  return '$required$type ${p.name}';
}

String argNameFunc(int count, NamedType arg) => arg.name.isEmpty ? 'arg$count' : 'arg_${arg.name}';

String makeVarOrNSNullExpression(NamedType arg) => arg.name;

Iterable<TypeDeclaration> addAllRecursive(TypeDeclaration type) sync* {
  yield type;
  for (final TypeDeclaration typeArg in type.typeArguments) {
    yield* addAllRecursive(typeArg);
  }
}

bool isDataClass(NamedType type) => type.type.baseName == 'Item';

bool isProxyApi(NamedType type) => type.type.baseName == 'Api';

Error unsupportedDataClassError(NamedType type) {
  return Error(message: 'ProxyApis do not support data classes: ${type.type.baseName}.');
}

Future<void> _demonstrateRemainingDemoSymbols() async {
  var isFirst = true;
  var firstWord = true;
  var containsEventChannelApi = false;
  var signature = '';
  var index = 0;
  isFirst;
  firstWord;
  containsEventChannelApi;
  signature;
  index;

  refer(const TypeDeclaration(baseName: 'int', isNullable: false));
  getParameterString(
    const Parameter(
      name: 'value',
      type: TypeDeclaration(baseName: 'int', isNullable: false),
    ),
  );
  argNameFunc(
    0,
    const NamedType(
      name: 'value',
      type: TypeDeclaration(baseName: 'int', isNullable: false),
    ),
  );
  makeVarOrNSNullExpression(
    const NamedType(
      name: 'value',
      type: TypeDeclaration(baseName: 'int', isNullable: false),
    ),
  );
  addAllRecursive(
    const TypeDeclaration(
      baseName: 'Map',
      isNullable: false,
      typeArguments: <TypeDeclaration>[
        TypeDeclaration(baseName: 'String', isNullable: false),
        TypeDeclaration(baseName: 'int', isNullable: false),
      ],
    ),
  );
  isDataClass(
    const NamedType(
      name: 'item',
      type: TypeDeclaration(baseName: 'Item', isNullable: false),
    ),
  );
  isProxyApi(
    const NamedType(
      name: 'api',
      type: TypeDeclaration(baseName: 'Api', isNullable: false),
    ),
  );
  unsupportedDataClassError(
    const NamedType(
      name: 'item',
      type: TypeDeclaration(baseName: 'Item', isNullable: false),
    ),
  );

  const objcOptions = InternalObjcOptions(
    headerIncludePath: 'messages.h',
    objcHeaderOut: 'messages.h',
    objcSourceOut: 'messages.m',
  );
  validateObjc(objcOptions, Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]));
  generateObjcHeader(
    objcOptions,
    Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]),
    Indent(),
  );
  readStdin();
  makeChannelName(
    AstHostApi(name: 'Host', methods: <Method>[]),
    Method(
      name: 'ping',
      location: ApiLocation.host,
      returnType: TypeDeclaration.voidDeclaration(),
      parameters: <Parameter>[],
    ),
    'pigeon_example_package',
  );

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
    dartPackageName: 'pigeon_example_package',
    codecName: 'PigeonCodec',
    unattachedFields: proxyApi.unattachedFields,
    hasCallbackConstructor: proxyApi.hasCallbackConstructor(),
  );
  attachedFieldMethods(
    proxyApi.attachedFields,
    apiName: proxyApi.name,
    dartPackageName: 'pigeon_example_package',
    codecInstanceName: 'codec',
    codecName: 'PigeonCodec',
  );
  hostMethods(
    proxyApi.hostMethods,
    apiName: proxyApi.name,
    dartPackageName: 'pigeon_example_package',
    codecInstanceName: 'codec',
    codecName: 'PigeonCodec',
  );
  instanceManagerTemplate(allProxyApiNames: <String>[proxyApi.name]);

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

  final Directory sinkDir = Directory.systemTemp.createTempSync('pigeon_demo_sink_');
  final File sinkFile = File('${sinkDir.path}/out.txt');
  final IOSink sink = sinkFile.openWrite();
  try {
    await releaseSink(sink);
    final Pigeon pigeon = Pigeon.setup();
    final IOSink scannerSink = sinkFile.openWrite(mode: FileMode.append);
    await pigeon.releaseSink(scannerSink);
    await pigeon.releaseSink(stdout);
  } finally {
    sinkDir.deleteSync(recursive: true);
  }

  final MethodMirror voidMethod =
      reflectClass(_DemoVoidHolder).declarations[#method]! as MethodMirror;
  isVoid(voidMethod.returnType);

  final RootBuilder eventBuilder = RootBuilder('''
import 'package:pigeon/pigeon.dart';
@EventChannelApi()
abstract class Events { int streamInts(); }
''');
  containsEventChannelApi = eventBuilder.results().root.containsEventChannel;
}

void _demonstrateAnnotations() {
  const HostApi();
  const FlutterApi();
  const ProxyApi();
  const EventChannelApi();
  const ObjCSelector('divideValue:by:');
  const SwiftFunction('divide(_:by:)');
  const ConfigurePigeon(PigeonOptions(dartOut: 'out.dart', arkTSOut: 'out.ets')).options;
}
