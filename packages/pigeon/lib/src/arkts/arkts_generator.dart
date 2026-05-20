// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import '../ast.dart';
import '../functional.dart';
import '../generator.dart';
import '../generator_tools.dart';

/// Documentation open symbol.
const String _docCommentPrefix = '/*';

/// Documentation continuation symbol.
const String _docCommentContinuation = '* ';

/// Documentation close symbol.
const String _docCommentSuffix = '*/';

/// The standard codec for Flutter, used for any non custom codecs and extended for custom codecs.
const String _codecName = 'PigeonCodec';
const String _overflowClassName = '${classNamePrefix}CodecOverflow';
// Used to create classes with type number rather than long.
const String _forceInt = '${varNamePrefix}forceInt';

///Enum companion suffix
const String _enumCompanionSuffix = 'Enum';
const String _string_Param_Suffix = 'Str';

/// Tag value matching `proxyApiCodecInstanceManagerKey`, used to mark an
/// instance reference in the wire format.
const int _proxyApiInstanceTag = proxyApiCodecInstanceManagerKey;

/// Identifier where host-allocated identifiers begin (Dart owns [0, 2^16)).
const int _minHostCreatedIdentifier = 65536;

/// Generated InstanceManager class name (ArkTS side).
const String _instanceManagerClassName =
    '${proxyApiClassNamePrefix}InstanceManager';

/// Generated InstanceManagerApi class name (ArkTS side).
const String _instanceManagerApiClassName =
    '${proxyApiClassNamePrefix}InstanceManagerApi';

/// Generated finalization listener interface name (ArkTS side).
const String _finalizationListenerInterfaceName =
    '${proxyApiClassNamePrefix}FinalizationListener';

/// Generated ProxyApi shared codec class name (ArkTS side).
const String _proxyApiBaseCodecClassName =
    '${proxyApiClassNamePrefix}ProxyApiBaseCodec';

/// Generated ProxyApi registrar class name (ArkTS side).
const String _proxyApiRegistrarClassName =
    '${proxyApiClassNamePrefix}ProxyApiRegistrar';

/// Per-ProxyApi host adapter class name (ArkTS side).
String _proxyApiHostClassName(AstProxyApi api) =>
    '$hostProxyApiPrefix${api.name}';

/// Documentation comment spec.
const DocumentCommentSpecification _docCommentSpec =
    DocumentCommentSpecification(
  _docCommentPrefix,
  closeCommentToken: _docCommentSuffix,
  blockContinuationToken: _docCommentContinuation,
);

/// Options that control how ArkTS code will be generated.
class ArkTSOptions {
  /// Creates an [ArkTSOptions] object.
  const ArkTSOptions({
    this.copyrightHeader,
  });

  /// A copyright header that will get prepended to generated code.
  final Iterable<String>? copyrightHeader;

  /// Creates [ArkTSOptions] from a Map representation where:
  /// `x = ArkTSOptions.fromMap(x.toMap())`.
  static ArkTSOptions fromMap(Map<String, Object> map) {
    final copyrightHeader =
        map['copyrightHeader'] as Iterable<dynamic>?;
    return ArkTSOptions(copyrightHeader: copyrightHeader?.cast<String>());
  }

  /// Converts [ArkTSOptions] to a Map representation where:
  /// `x = ArkTSOptions.fromMap(x.toMap())`.
  Map<String, Object> toMap() {
    final result = <String, Object>{
      if (copyrightHeader != null) 'copyrightHeader': copyrightHeader!,
    };
    return result;
  }

  /// Overrides any non-null parameters from [options] into this to make a new
  /// [ArkTSOptions].
  ArkTSOptions merge(ArkTSOptions options) {
    return ArkTSOptions.fromMap(mergeMaps(toMap(), options.toMap()));
  }
}

/// Internal ArkTS options that extend InternalOptions.
class InternalArkTSOptions extends InternalOptions {
  /// Creates an [InternalArkTSOptions] object.
  const InternalArkTSOptions({
    required this.arkTSOut,
    this.copyrightHeader,
  });

  /// Path to the ArkTS file that will be generated.
  final String arkTSOut;

  /// A copyright header that will get prepended to generated code.
  final Iterable<String>? copyrightHeader;

  /// Creates [InternalArkTSOptions] from [ArkTSOptions].
  static InternalArkTSOptions fromArkTSOptions(
    ArkTSOptions options, {
    required String arkTSOut,
    Iterable<String>? copyrightHeader,
  }) {
    return InternalArkTSOptions(
      arkTSOut: arkTSOut,
      copyrightHeader: options.copyrightHeader ?? copyrightHeader,
    );
  }
}

/// arkts code generator
class ArkTSGenerator extends StructuredGenerator<InternalArkTSOptions> {
  /// Instantiates a ArkTS Generator.
  const ArkTSGenerator();

  @override
  void writeFilePrologue(
      InternalArkTSOptions generatorOptions, Root root, Indent indent,
      {required String dartPackageName}) {
    if (generatorOptions.copyrightHeader != null) {
      indent.writeln('/*');
      addLines(indent, generatorOptions.copyrightHeader!, linePrefix: '* ');
      indent.writeln('*/');
    }
  }

  @override
  void writeFileImports(
      InternalArkTSOptions generatorOptions, Root root, Indent indent,
      {required String dartPackageName}) {
    indent.writeln(
        "import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';");
    indent.writeln(
        "import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';");
    indent.writeln(
        "import { BinaryMessenger,TaskQueue } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';");
    indent.writeln(
        "import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';");
    indent.writeln(
        "import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';");
    indent.newln();
  }

  @override
  void writeEnum(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Enum anEnum, {
    required String dartPackageName,
  }) {
    String camelToSnake(String camelCase) {
      final regex = RegExp('([a-z])([A-Z]+)');
      return camelCase
          .replaceAllMapped(regex, (Match m) => '${m[1]}_${m[2]}')
          .toUpperCase();
    }

    const generatedEnumMessages = <String>[
      ' Generated enum from Pigeon that represents data sent in messages.'
    ];
    indent.newln();
    addDocumentationComments(
        indent, anEnum.documentationComments, _docCommentSpec,
        generatorComments: generatedEnumMessages);
    indent.write('export enum ${anEnum.name} ');
    indent.addScoped('{', '}', () {
      enumerate(anEnum.members, (int index, final EnumMember member) {
        addDocumentationComments(
            indent, member.documentationComments, _docCommentSpec);
        indent.writeln(
            '${camelToSnake(member.name)}${index == anEnum.members.length - 1 ? '' : ','}');
      });
    });
    const generatedEnumCompanionMessages = <String>[
      '''
 Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed'''
    ];
    indent.newln();
    addDocumentationComments(
        indent, anEnum.documentationComments, _docCommentSpec,
        generatorComments: generatedEnumCompanionMessages);
    indent.write('export class ${anEnum.name}$_enumCompanionSuffix ');
    indent.addScoped('{', '}', () {
      indent.writeln('index: string|null = null;');
      indent.addScoped('\tconstructor(index: string){', '}', () {
        indent.writeln('this.index = index;');
      });
    });
  }

  @override
  void writeDataClass(InternalArkTSOptions generatorOptions, Root root,
      Indent indent, Class klass,
      {required String dartPackageName}) {
    const generatedMessages = <String>[
      ' Generated class from Pigeon that represents data sent in messages.'
    ];
    indent.newln();
    addDocumentationComments(
        indent, klass.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('export class ${klass.name} ');
    indent.addScoped('{', '}', () {
      for (final NamedType field in getFieldsInSerializationOrder(klass)) {
        //for里面这里不一样，可能需要改造
        _writeClassField(generatorOptions, indent, field);
        indent.newln();
      }

      _writeClassBuilder(generatorOptions, root, indent, klass);
      writeClassEncode(
        generatorOptions,
        root,
        indent,
        klass,
        dartPackageName: dartPackageName,
      );
      writeClassDecode(
        generatorOptions,
        root,
        indent,
        klass,
        dartPackageName: dartPackageName,
      );
    });
  }

  void _writeClassField(
    InternalArkTSOptions generatorOptions,
    Indent indent,
    NamedType field, {
    bool isPrimitive = false,
  }) {
    final HostDatatype hostDatatype = getFieldHostDatatype(
        field, (TypeDeclaration x) => _arkTSTypeForBuiltinDartType(x));
    if (field.type.isEnum) {
      indent.writeln('private ${field.name}?: ${hostDatatype.datatype};');
      indent.newln();
      indent.writeScoped(
          'public ${_makeSetter(field)}(${field.name}:${hostDatatype.datatype}):void {',
          '}', () {
        indent.writeln('this.${field.name} = ${field.name};');
      });
      indent.newln();
      indent.write(
          '${_makeGetter(field)}(): ${hostDatatype.datatype} | undefined');
      indent.addScoped('{', '}', () {
        indent.writeln('return this.${field.name};');
      });
    } else {
      indent.writeln('private ${field.name}?: ${hostDatatype.datatype};');
      indent.newln();
      indent.writeScoped(
          'public ${_makeSetter(field)}(${field.name}:${hostDatatype.datatype}):void {',
          '}', () {
        indent.writeln('this.${field.name} = ${field.name};');
      });
      indent.newln();
      indent.write(
          '${_makeGetter(field)}(): ${hostDatatype.datatype} | undefined');
      indent.addScoped('{', '}', () {
        indent.writeln('return this.${field.name};');
      });
    }
  }

  void _writeDataClassSignature(
    InternalArkTSOptions generatorOptions,
    Indent indent,
    Class classDefinition,
    void Function() dataClassBody, {
    bool private = false,
  }) {
    indent.write(
        '${private ? 'private' : 'public'} static final class ${classDefinition.name} ');
    indent.addScoped('{', '}', () {
      for (final NamedType field
          in getFieldsInSerializationOrder(classDefinition)) {
        _writeClassField(
          generatorOptions,
          indent,
          field,
          isPrimitive: field.type.baseName == _forceInt,
        );
        indent.newln();
      }
      dataClassBody();
    });
  }

  // 构造函数
  void _writeClassBuilder(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class klass,
  ) {
    indent.write('constructor');
    final argSignature = <String>[];
    if (klass.fields.isNotEmpty) {
      for (final NamedType element in klass.fields) {
        final String type = _arkTSTypeForDartType(element.type);
        final String name = getSafeConstructorArgument(element.name);
        if (element.type.isEnum) {
          argSignature.add('$name?: $type');
        } else {
          argSignature.add('$name?: $type');
        }
      }
    }
    indent.add('(${argSignature.join(', ')}) ');
    indent.addScoped('{', '}', () {
      for (final NamedType field in getFieldsInSerializationOrder(klass)) {
        final String value = getSafeConstructorArgument(field.name);
        indent.writeln('this.${field.name} = $value;');
      }
    });
  }

  @override
  void writeClassEncode(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.write('toList(): Object[] ');
    indent.addScoped('{', '}', () {
      indent.writeln('let arr: Object[] = new Array();');
      for (final NamedType field in getFieldsInSerializationOrder(classDefinition)) {
        final String fieldName = field.name;
        if (field.type.isEnum) {
          indent.writeScoped('if(this.$fieldName !==undefined){', '}', () {
            indent.writeln(
                'const $fieldName$_string_Param_Suffix = ${field.type.baseName}[this.$fieldName as number];');
            indent.writeln(
                'arr.push(new ${field.type.baseName}$_enumCompanionSuffix($fieldName$_string_Param_Suffix));');
          });
        } else {
          indent.writeScoped('if(this.$fieldName !==undefined){', '}', () {
            indent.writeln('arr.push(this.$fieldName);');
          });
        }
      }
      indent.writeln('return arr;');
    });
  }

  @override
  void writeClassDecode(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.write('static fromList(arr: Object[]): ${classDefinition.name} ');
    indent.addScoped('{', '}', () {
      const result = 'pigeonResult';
      indent.writeln('let $result: ${classDefinition.name} = new ${classDefinition.name}();');

      enumerate(getFieldsInSerializationOrder(classDefinition),
          (int index, final NamedType field) {
        final String fieldVariable = field.name;
        final String setter = _makeSetter(field);
        if (field.type.isEnum) {
          indent.writeln(
              'const $fieldVariable$_string_Param_Suffix: string = arr[$index]! as string;');
          indent.writeln(
              '$result.$setter(${field.type.baseName}[$fieldVariable$_string_Param_Suffix]);');
        } else {
          indent.writeln('let $fieldVariable: Object = arr[$index];');
          indent.writeln(
              '$result.$setter(${_castObject(field, fieldVariable)});');
        }
      });
      indent.writeln('return $result;');
    });
  }

  String _makeSetter(NamedType field) {
    final String uppercased =
        field.name.substring(0, 1).toUpperCase() + field.name.substring(1);
    return 'set$uppercased';
  }

  /// Casts variable named [varName] to the correct host datatype for [field].
  /// This is for use in codecs where we may have a map representation of an
  /// object.
  String _castObject(NamedType field, String varName) {
    final HostDatatype hostDatatype = getFieldHostDatatype(
        field, (TypeDeclaration x) => _arkTSTypeForDartType(x));
    return _cast(varName, artTSType: hostDatatype.datatype);
  }

  @override
  void writeFlutterApi(
      InternalArkTSOptions generatorOptions, Root root, Indent indent, Api api,
      {required String dartPackageName}) {
    String getSafeArgumentExpression(int count, NamedType argument) {
      return '${_getArgumentName(count, argument)}Arg';
    }

    const generatedMessages = <String>[
      ' Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.',
    ];
    addDocumentationComments(indent, api.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('export class ${api.name} ');

    ///MessageFlutterApi
    indent.addScoped('{', '}', () {
      indent.writeln('binaryMessenger: BinaryMessenger;');
      indent.newln();

      indent.write('constructor(binaryMessenger: BinaryMessenger) ');
      indent.addScoped('{', '}', () {
        indent.writeln('this.binaryMessenger = binaryMessenger;');
      });

      indent.newln();

      ///final String codecName = _getCodecName(api);
      indent.writeln('/** The codec used by ${api.name}. */');
      indent.write('static getCodec(): MessageCodec<Object> ');
      indent.addScoped('{', '}', () {
        indent.writeln('return $_codecName.INSTANCE;');
      });

      indent.newln();

      for (final Method func in api.methods) {
        final String returnType = func.returnType.isVoid
            ? 'void'
            : _arkTSTypeForDartType(func.returnType);
        String sendArgument;
        addDocumentationComments(
            indent, func.documentationComments, _docCommentSpec);
        if (func.parameters.isEmpty) {
          indent.write('${func.name}(callback: Reply<$returnType>):void ');
          sendArgument = 'null';
        } else {
          final Iterable<String> argTypes = func.parameters
              .map((NamedType e) => _arkTSTypeForDartType(e.type));
          final Iterable<String> argNames =
              indexMap(func.parameters, _getSafeArgumentName);
          final Iterable<String> enumSafeArgNames =
              indexMap(func.parameters, getSafeArgumentExpression);

          if (func.parameters.length == 1) {
            sendArgument = '[${enumSafeArgNames.first}]';
          } else {
            sendArgument = '[${enumSafeArgNames.join(', ')}]';
          }

          final String argsSignature =
              map2(argTypes, argNames, (String x, String y) => '$y: $x')
                  .join(',');
          indent.write(
              '${func.name}($argsSignature, callback: Reply<$returnType>) ');
        }
        indent.addScoped('{', '}', () {
          const channel = 'channel';
          indent.writeln(
              "const channelName: string = '${makeChannelName(api, func, dartPackageName)}';");
          indent.writeln('let $channel: BasicMessageChannel<Object> = ');
          indent.nest(2, () {
            indent.writeln('new BasicMessageChannel<Object>(');
            indent.nest(2, () {
              indent.writeln(
                  'this.binaryMessenger, channelName, ${api.name}.getCodec());');
            });
          });
          indent.writeln('$channel.send(');

          indent.nest(2, () {
            indent.writeln('$sendArgument,');
            indent.write('channelReply => ');

            indent.addScoped('{', '});', () {
              indent.writeScoped('if (Array.isArray(channelReply)) {', '} ',
                  () {
                indent.writeln(
                    'let listReply: ESObject[] = channelReply as ESObject[] ;');
                indent.writeScoped('if (listReply.length > 1) {', '} ', () {
                  indent
                      .writeln('let arrFirst:string = listReply[0] as string;');
                  indent.writeln(
                      'let arrSecond:string = listReply[1] as string;');
                  indent
                      .writeln('let arrThird:string = listReply[2] as string;');
                  const replyArr =
                      '\'FlutterError:{"code":\'+arrFirst+\',"name":\'+arrSecond+\',"message":\'+arrThird+\'}\';';
                  if (func.returnType.isVoid) {
                    indent.writeln('let replyArr:ESObject = new FlutterError(arrFirst, arrSecond, arrThird)');
                  } else {
                    indent.writeln('let replyArr:$returnType = $replyArr');
                  }
                  indent.writeln('callback.reply(replyArr);');
                }, addTrailingNewline: false);

                if (!func.returnType.isVoid) {
                  indent.addScoped('else if (listReply[0] == null) {', '} ',
                      () {
                    const replyNull =
                        'FlutterError:{"code":null-error,"name":Flutter api returned null value for non-null return value.,"message":}';
                    indent
                        .writeln("let replyNull:$returnType = '$replyNull'");
                    indent.writeln('callback.reply(replyNull);');
                  }, addTrailingNewline: false);
                }

                indent.addScoped('else {', '}', () {
                  if (func.returnType.isVoid) {
                    indent.writeln('callback.reply();');
                  } else {
                    const output = 'output';
                    final String outputExpression;
                    if (func.returnType.baseName == 'number') {
                      outputExpression =
                          'listReply[0] == null ? null : (listReply[0] as number).valueOf();';
                    } else {
                      outputExpression =
                          '${_cast('listReply[0]', artTSType: returnType)};';
                    }
                    indent
                        .writeln('let $output:$returnType = $outputExpression');
                    indent.writeln('callback.reply($output);');
                  }
                });
              }, addTrailingNewline: false);
              indent.addScoped(' else {', '} ', () {
                if (func.returnType.isVoid) {
                  const connErr =
                      "let connErr:ESObject = new FlutterError('channel-error', "
                      '"Unable to establish connection on channel: " + channelName + ".", "")';
                  indent.writeln(connErr);
                } else {
                  const connErr = 'FlutterError:{"code":channel-error,"name":Unable to establish connection on channel:channelName,"message":.}';
                  indent.writeln("let connErr:$returnType = '$connErr'");
                }
                indent.writeln('callback.reply(connErr);');
              });
            });
          });
        });
      }
    });
  }

  @override
  void writeApis(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    if (root.apis.any(
          (Api api) =>
        api is AstHostApi &&
            api.methods.any((Method it) => it.isAsynchronous) ||
              api is AstFlutterApi,
        ) ||
        root.apis.whereType<AstProxyApi>().any(
          (AstProxyApi api) =>
              api.hostMethods.any((Method it) => it.isAsynchronous),
        )) {
      indent.newln();
      _writeResultInterface(indent);
    }
    // ProxyApi shared codec class extends PigeonCodec, which writeGeneralCodec
    // emits just before writeApis runs.  ArkTS does NOT hoist class
    // declarations, so we cannot emit this in writeProxyApiBaseCodec; do it
    // here instead, before per-ProxyApi adapters.
    if (root.apis.any((Api api) => api is AstProxyApi)) {
      _writeProxyApiBaseCodecClass(
        generatorOptions,
        root,
        indent,
        dartPackageName: dartPackageName,
      );
    }
    super.writeApis(
      generatorOptions,
      root,
      indent,
      dartPackageName: dartPackageName,
    );
  }

  /// public interface ExampleHostApi
  @override
  void writeHostApi(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api, {
    required String dartPackageName,
  }) {
    const generatedMessages = <String>[
      ' Generated abstract class from Pigeon that represents a handler of messages from Flutter.',
    ];
    addDocumentationComments(
      indent,
      api.documentationComments,
      _docCommentSpec,
      generatorComments: generatedMessages,
    );

    indent.write('export abstract class ${api.name} ');
    indent.addScoped('{', '}', () {
      for (final Method method in api.methods) {
        _writeInterfaceMethod(generatorOptions, root, indent, api, method);
      }

      ///final String codecName = _getCodecName(api);
      indent.writeln('/** The codec used by ${api.name}. */');
      indent.write('static getCodec(): MessageCodec<Object>');
      indent.addScoped('{', '}', () {
        indent.writeln('return $_codecName.INSTANCE;');
      });

      indent.writeln(
          '${_docCommentPrefix}Sets up an instance of `${api.name}` to handle messages through the `binaryMessenger`.$_docCommentSuffix');

      indent.write(
          'static setup(binaryMessenger: BinaryMessenger, api: ${api.name} | null): void ');
      indent.addScoped('{', '}', () {
        for (final Method method in api.methods) {
          _writeMethodSetup(
            generatorOptions,
            root,
            indent,
            api,
            method,
            dartPackageName: dartPackageName,
          );
        }
      });
    });
  }

  /// Write a static setup function in the interface.
  /// Example:
  ///   static void setup(BinaryMessenger binaryMessenger, Foo api) {...}
  void _writeMethodSetup(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api,
    final Method method, {
    required String dartPackageName,
  }) {
    final String channelName = makeChannelName(api, method, dartPackageName);
    indent.write('');
    indent.addScoped('{', '}', () {
      indent.writeln('let channel: BasicMessageChannel<Object> =');
      indent.nest(2, () {
        indent.writeln('new BasicMessageChannel(');
        indent.nest(2, () {
          indent
              .write('binaryMessenger, "$channelName", ${api.name}.getCodec()');
          indent.addln(');');
        });
      });
      indent.write('if (api != null) ');
      indent.addScoped('{', '} else {', () {
        indent.writeln('channel.setMessageHandler({');
        indent.nest(2, () {
          indent.write('onMessage(message: Object ,reply: Reply<Object> ) ');
          indent.addScoped('{', '} });', () {
            final String returnType = method.returnType.isVoid
                ? 'void'
                : _arkTSTypeForDartType(method.returnType);
            final methodArgument = <String>[];
            if (method.parameters.isNotEmpty) {
              _writeArkTsPigeonListMessagePrecheck(
                indent,
                method.parameters.length,
              );
              enumerate(method.parameters, (int index, NamedType arg) {
                var argExpression =
                    'args[$index] as ${_arkTSTypeForDartType(arg.type)}';
                if (method.returnType.isEnum) {
                  argExpression =
                      'new ${_arkTSTypeForDartType(arg.type)}$_enumCompanionSuffix'
                      '${'(args[$index] as string)'}';
                }
                methodArgument.add(argExpression);
              });
            }
            if (method.isAsynchronous) {
              final resultValue =
                  method.returnType.isVoid ? 'null' : 'result';
              const resultName = 'resultCallback';
              indent.format('''
class ResultImp implements Result<$returnType>{
\t\t\tsuccess(result: $returnType): void {
\t\t\t\tlet res: Array<Object> = [];
\t\t\t\tres.push($resultValue);
\t\t\t\treply.reply(res);
\t\t\t}

\t\t\terror(error: Error): void {
\t\t\t\tlet wrappedError: Array<Object> = wrapError(error);
\t\t\t\treply.reply(wrappedError);
\t\t\t}
}
let $resultName: Result<$returnType> = new ResultImp();
''');
              methodArgument.add(resultName);
            }
            final call =
                'api!.${method.name}(${methodArgument.join(', ')})';
            // indent.writeln('$call;');
            if (method.isAsynchronous) {
              indent.writeln('$call;');
            } else {
              indent.writeln('let res: Array<Object> = [];');
              indent.write('try ');
              indent.addScoped('{', '}', () {
                if (method.returnType.isVoid) {
                  indent.writeln('$call;');
                  indent.writeln('res.push(null);');
                } else {
                  if (method.returnType.isEnum) {
                    final newCall =
                        'api!.${method.name}(args[0] as $returnType).toString()';
                    indent.writeln(
                        'let output: $returnType$_enumCompanionSuffix = new $returnType$_enumCompanionSuffix($newCall);');
                  } else {
                    indent.writeln('let output: $returnType = $call;');
                  }
                  indent.writeln('res.push(output);');
                }
              });
              indent.add(' catch (error) ');
              indent.addScoped('{', '}', () {
                indent.writeln(
                    'let wrappedError: Array<Object> = wrapError(error);');
                if (method.isAsynchronous) {
                  indent.writeln('reply.reply(wrappedError);');
                } else {
                  indent.writeln('res = wrappedError;');
                }
              });
              indent.writeln('reply.reply(res);');
            }
          });
        });
      });
      indent.addScoped(null, '}', () {
        indent.writeln('channel.setMessageHandler(null);');
      });
    });
  }

  void _writeInterfaceMethod(InternalArkTSOptions generatorOptions, Root root,
      Indent indent, Api api, final Method method) {
    final String returnType = method.isAsynchronous
        ? 'void'
        : _arkTSTypeForDartType(method.returnType);

    final argSignature = <String>[];
    if (method.parameters.isNotEmpty) {
      final Iterable<String> argTypes =
          method.parameters.map((NamedType e) => _arkTSTypeForDartType(e.type));
      final Iterable<String> argNames =
          method.parameters.map((NamedType e) => e.name);
      argSignature
          .addAll(map2(argTypes, argNames, (String argType, String argName) {
        return '$argName: $argType ';
      }));
    }
    if (method.isAsynchronous) {
      final String resultType = method.returnType.isVoid
          ? 'void'
          : _arkTSTypeForDartType(method.returnType);
      argSignature.add('result: Result<$resultType>');
    }
    if (method.documentationComments.isNotEmpty) {
      addDocumentationComments(
          indent, method.documentationComments, _docCommentSpec);
    } else {
      indent.newln();
    }
    indent.writeln(
        'abstract ${method.name}(${argSignature.join(', ')}): $returnType;');
  }

  void _writeResultInterface(Indent indent) {
    indent.write('export interface Result<T> ');
    indent.addScoped('{', '}', () {
      indent.writeln('success( result: T ): void;');
      indent.newln();
      indent.writeln('error( error: Error): void;');
    });
  }

  void _writeErrorClass(Indent indent) {
    indent.writeln(
        '/** Error class for passing custom error details to Flutter via a thrown PlatformException. */');
    indent.write('export class FlutterError implements Error ');
    indent.addScoped('{', '}', () {
      indent.newln();
      indent.writeln('/** The error code. */');
      indent.writeln('public code: string;');
      indent.newln();
      indent.writeln('/** The error name. */');
      indent.writeln('public name: string;');
      indent.newln();
      indent.writeln('/** The error message. */');
      indent.writeln('public message: string;');
      indent.writeln('/** The error stack. */');
      indent.writeln('public stack?: string;');
      indent.newln();
      indent.writeln(
          'constructor(code: string, name: string,  message: string, stack?: string) ');
      indent.writeScoped('{', '}', () {
        indent.writeln('this.code = code;');
        indent.writeln('this.name = name;');
        indent.writeln('this.message = message;');
        indent.writeln('this.stack = stack;');
      });
    });
  }

  void _writeWrapError(Indent indent) {
    indent.format('''
function wrapError(error: Error): Array<Object> {
\tlet errorList: Array<Object> = new Array<Object>(3);
\tif (error instanceof FlutterError) {
\t\tlet err: FlutterError = error as FlutterError;
\t\terrorList[0] = err.code;
\t\terrorList[1] = err.name;
\t\terrorList[2] = err.message;
\t} else {
\t\terrorList[0] = error.toString();
\t\terrorList[1] = error.name;
\t\terrorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
\t}
\treturn errorList;
}''');
  }

  void _writeGetByteMethoe(Indent indent) {
    indent.format('''
getByte(n: number): number {
\tlet byteArray = new Uint8Array(1);
\tbyteArray[0] = n;
\treturn byteArray[0] as number;
}''');
  }

  @override
  void writeGeneralUtilities(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    final bool hasHostApi = root.apis
        .whereType<AstHostApi>()
        .any((Api api) => api.methods.isNotEmpty);
    final bool hasFlutterApi = root.apis
        .whereType<AstFlutterApi>()
        .any((Api api) => api.methods.isNotEmpty);

    indent.newln();
    _writeErrorClass(indent);

    if (hasHostApi) {
      indent.newln();
      _writeWrapError(indent);
    }
    if (hasFlutterApi) {
      indent.newln();

      ///_writeCreateConnectionError(indent);
    }
  }

  /// Converts an expression that evaluates to an nullable int to an expression
  /// that evaluates to a nullable enum.
  String _intToEnum(String expression, String enumName, bool nullable) =>
      nullable
          ? '$expression == null ? null : $enumName[$expression as number]'
          : '$enumName[$expression as number]';

  String _getArgumentName(int count, NamedType argument) =>
      argument.name.isEmpty ? 'arg$count' : argument.name;

  String _getSafeArgumentName(int count, NamedType argument) =>
      '${_getArgumentName(count, argument)}Arg';
  /// Returns a constructor argument name that is safe to use in generated code.
  String getSafeConstructorArgument(String argument) {
    return (argument == 'arguments') ? 'argumentsArg' : argument;
  }

// get函数
  String _makeGetter(NamedType field) {
    final String uppercased =
        field.name.substring(0, 1).toUpperCase() + field.name.substring(1);
    return 'get$uppercased';
  }

  /// Returns an expression to cast [variable] to [artTSType].
  String _cast(String variable, {required String artTSType}) {
    // Special-case object, since casting to object doesn't do anything, and
    // causes a warning.
    return artTSType == 'Object' ? variable : '$variable as $artTSType';
  }

  /// Validates that a Pigeon codec payload on the ArkTS handler is an array long
  /// enough for the expected arguments ([minLength]); otherwise replies via
  /// [wrapError] and returns early.
  void _writeArkTsPigeonListMessagePrecheck(Indent indent, int minLength) {
    indent.writeln('if (!(Array.isArray(message))) {');
    indent.nest(2, () {
      indent.writeln(
        "reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));",
      );
      indent.writeln('return;');
    });
    indent.writeln('}');
    indent.writeln('let args: Array<Object> = message as Array<Object>;');
    indent.writeln('if (args.length < $minLength) {');
    indent.nest(2, () {
      indent.writeln(
        "reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least "
        '$minLength'
        " argument(s).')));",
      );
      indent.writeln('return;');
    });
    indent.writeln('}');
  }

  String _arkTSTypeForDartType(TypeDeclaration type) {
    return _arkTSTypeForBuiltinDartType(type) ?? type.baseName;
  }

  /// Converts a [List] of [TypeDeclaration]s to a comma separated [String] to be
  String _flattenTypeArguments(List<TypeDeclaration> args) {
    return args.map<String>(_arkTSTypeForDartType).join(', ');
  }

  String _arkTSTypeForBuiltinGenericDartType(
    TypeDeclaration type,
    int numberTypeArguments,
  ) {
    final String typeName = type.baseName == 'List' ? 'Array' : type.baseName;
    if (type.typeArguments.isEmpty) {
      return '$typeName<${repeat('Object', numberTypeArguments).join(', ')}>';
    } else {
      return '$typeName<${_flattenTypeArguments(type.typeArguments)}>';
    }
  }

  String? _arkTSTypeForBuiltinDartType(TypeDeclaration type) {
    const arkTSTypeForDartTypeMap = <String, String>{
      'bool': 'boolean',
      'int': 'number',
      'String': 'string',
      'double': 'number',
      'Uint8List': 'number[]',
      'Int32List': 'number[]',
      'Int64List': 'number[]',
      'Float64List': 'number[]',
      'Object': 'Object',
      _forceInt: 'number',
    };
    if (arkTSTypeForDartTypeMap.containsKey(type.baseName)) {
      return arkTSTypeForDartTypeMap[type.baseName];
    } else if (type.baseName == 'List') {
      return _arkTSTypeForBuiltinGenericDartType(type, 1);
    } else if (type.baseName == 'Map') {
      return _arkTSTypeForBuiltinGenericDartType(type, 2);
    } else {
      return null;
    }
  }

  @override
  void writeGeneralCodec(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    final List<EnumeratedType> enumeratedTypes = getEnumeratedTypes(
      root,
      excludeSealedClasses: true,
    ).toList();
    void writeEncodeLogic(EnumeratedType customType) {
      final isEnum = customType.type == CustomTypes.customEnum;
      final nullCheck = customType.type == CustomTypes.customEnum
          ? 'value == null ? null : '
          : '';
      var valueString = '';
      if (isEnum) {
        valueString = customType.enumeration < maximumCodecFieldKey
            ? '$nullCheck${customType.name}[value.index as string]'
            : 'wrap.toList()';
      } else {
        valueString = customType.enumeration < maximumCodecFieldKey
            ? '$nullCheck(value as ${customType.name}).toList()'
            : 'wrap.toList()';
      }

      final int enumeration = customType.enumeration < maximumCodecFieldKey
          ? customType.enumeration
          : maximumCodecFieldKey;
      final isCustom = customType.type == CustomTypes.customClass;
      if (isCustom) {
        indent.add('if (value instanceof ${customType.name}) ');
        indent.addScoped('{', '} else ', () {
          if (customType.enumeration >= maximumCodecFieldKey) {
            indent.writeln(
                'let wrap:$_overflowClassName = new $_overflowClassName();');
            indent.writeln(
                'wrap.setType(${customType.enumeration - maximumCodecFieldKey});');

            indent.writeln(
                'wrap.setWrapped($nullCheck(value as ${customType.name}).toList());',
            );
          }
          indent.writeln('stream.writeUint8(this.getByte($enumeration));');
          indent.writeln('this.writeValue(stream, $valueString);');
        }, addTrailingNewline: false);
      } else {
        indent.add(
            'if (value instanceof ${customType.name}$_enumCompanionSuffix) ');
        indent.addScoped('{', '} else ', () {
          if (customType.enumeration >= maximumCodecFieldKey) {
            indent.writeln(
                'let wrap:$_overflowClassName = new $_overflowClassName();');
            indent.writeln(
                'wrap.setType(${customType.enumeration - maximumCodecFieldKey});');
            indent.writeln(
                'wrap.setWrapped($nullCheck(value as ${customType.name}).toList());');
          }
          indent.writeln('stream.writeUint8(this.getByte($enumeration));');
          indent.writeln('this.writeValue(stream, $valueString);');
        }, addTrailingNewline: false);
      }
    }

    void writeDecodeLogic(EnumeratedType customType) {
      indent.write('case this.getByte(${customType.enumeration}):');
      if (customType.type == CustomTypes.customClass) {
        indent.newln();
        indent.nest(1, () {
          indent.writeln(
              'return ${customType.name}.fromList(super.readValue(buffer) as Object[]);');
        });
      } else if (customType.type == CustomTypes.customEnum) {
        indent.addScoped(' {', '}', () {
          indent.writeln('let value: Object= super.readValue(buffer);');
          indent
              .writeln('return ${_intToEnum('value', customType.name, true)};');
        });
      }
    }

    final overflowClass = EnumeratedType(
        _overflowClassName, maximumCodecFieldKey, CustomTypes.customClass);

    if (root.requiresOverflowClass) {
      _writeCodecOverflowUtilities(
        generatorOptions,
        root,
        indent,
        enumeratedTypes,
        dartPackageName: dartPackageName,
      );
    }
    indent.newln();
    indent.write('export class $_codecName extends StandardMessageCodec ');
    indent.addScoped('{', '}', () {
      indent.writeln(
          'static readonly INSTANCE: $_codecName  = new $_codecName();');
      indent.newln();
      _writeGetByteMethoe(indent);

      ///构造
      indent.writeScoped('private constructor() {', '}', () {
        indent.writeln('super();');
      });
      indent.newln();
      indent.writeScoped(
          'readValueOfType(type: number,  buffer: ByteBuffer): ESObject {', '}',
          () {
        indent.writeScoped('switch (type) {', '}', () {
          for (final customType in enumeratedTypes) {
            if (customType.enumeration < maximumCodecFieldKey) {
              writeDecodeLogic(customType);
            }
          }
          if (root.requiresOverflowClass) {
            writeDecodeLogic(overflowClass);
          }
          indent.writeln('default:');
          indent.nest(1, () {
            indent.writeln('return super.readValueOfType(type, buffer);');
          });
        });
      });
      indent.newln();
      indent
          .write('writeValue(stream: ByteBuffer , value: ESObject): ESObject');
      indent.addScoped('{', '}', () {
        indent.write('');
        enumeratedTypes.forEach(writeEncodeLogic);
        indent.addScoped('{', '}', () {
          indent.writeln('super.writeValue(stream, value);');
        });
      });
    });
    indent.newln();
  }

  void _writeCodecOverflowUtilities(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    List<EnumeratedType> types, {
    required String dartPackageName,
  }) {
    final overflowInteration = NamedType(
        name: 'type',
        type: const TypeDeclaration(baseName: _forceInt, isNullable: false));
    final overflowObject = NamedType(
        name: 'wrapped',
        type: const TypeDeclaration(baseName: 'Object', isNullable: true));
    final overflowFields = <NamedType>[
      overflowInteration,
      overflowObject,
    ];
    final overflowClass =
        Class(name: _overflowClassName, fields: overflowFields);

    _writeDataClassSignature(
      generatorOptions,
      indent,
      overflowClass,
      () {
        writeClassEncode(
          generatorOptions,
          root,
          indent,
          overflowClass,
          dartPackageName: dartPackageName,
        );

        indent.format('''
static @Nullable Object fromList(@NonNull ArrayList<Object> ${varNamePrefix}list) {
  $_overflowClassName wrapper = new $_overflowClassName();
  wrapper.setType((int) ${varNamePrefix}list.get(0));
  wrapper.setWrapped(${varNamePrefix}list.get(1));
  return wrapper.unwrap();
}
''');

        indent.writeScoped('@Nullable Object unwrap() {', '}', () {
          indent.format('''
if (wrapped == null) {
  return null;
}
    ''');
          indent.writeScoped('switch (type) {', '}', () {
            for (int i = totalCustomCodecKeysAllowed; i < types.length; i++) {
              indent.writeln('case ${i - totalCustomCodecKeysAllowed}:');
              indent.nest(1, () {
                if (types[i].type == CustomTypes.customClass) {
                  indent.writeln(
                      'return ${types[i].name}.fromList((ArrayList<Object>) wrapped);');
                } else if (types[i].type == CustomTypes.customEnum) {
                  indent.writeln(
                      'return ${types[i].name}.values()[(int) wrapped];');
                }
              });
            }
          });
          indent.writeln('return null;');
        });
    }, private: true);
  }

  // =====================================================================
  // ProxyApi support — MVP iteration 1.
  //
  // What is implemented in this generator:
  //   * PigeonInstanceManager           (strong-reference only, no WeakRef yet)
  //   * PigeonInstanceManagerApi        (removeStrongReference / clear / cb)
  //   * PigeonProxyApiBaseCodec         (tag 128 instance-ref handling)
  //   * PigeonProxyApiRegistrar         (per-engine coordinator, abstract)
  //   * PigeonApi<Name>                 (per-ProxyApi adapter, abstract)
  //     - constructors (default + named)
  //     - attached fields (instance + static)
  //     - host methods (sync + async, instance + static)
  //     - pigeon_newInstance (callback to register on Dart side)
  //     - flutter methods (callback-based, instance side)
  //
  // Deferred to a follow-up iteration (search "TODO(proxyapi-ohos)"):
  //   * Inheritance / interfaces between ProxyApis (extends / implements).
  //   * WeakRef + FinalizationRegistry-driven GC integration.
  //   * Cross-class containment in collection types
  //     (List<MyProxyApi> as a method argument or return value).
  //   * minApi platform gating (HarmonyOS has no analogue today).
  //
  // See doc/PROXYAPI_OHOS.md for usage details and known limitations.
  // =====================================================================

  @override
  void writeInstanceManager(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.format('''
/**
 * Maintains a 1:1 mapping between native objects and integer identifiers
 * shared with the Dart `InstanceManager`.
 *
 * NOTE (HarmonyOS MVP): Instances are held as strong references on both
 * sides until either side explicitly removes them.  Weak-reference based
 * GC integration is intentionally deferred (see PROXYAPI_OHOS.md).
 */
export class $_instanceManagerClassName {
  /** Host-allocated identifiers start at this value; Dart owns [0, $_minHostCreatedIdentifier). */
  private static readonly minHostCreatedIdentifier: number = $_minHostCreatedIdentifier;

  private readonly identifiersToInstances: Map<number, ESObject> = new Map<number, ESObject>();
  private readonly instancesToIdentifiers: Map<ESObject, number> = new Map<ESObject, number>();
  private nextIdentifier: number = $_instanceManagerClassName.minHostCreatedIdentifier;
  private finalizationListener: $_finalizationListenerInterfaceName | null = null;

  setFinalizationListener(listener: $_finalizationListenerInterfaceName | null): void {
    this.finalizationListener = listener;
  }

  /** Adds an instance instantiated from the Dart side with the given identifier. */
  addDartCreatedInstance(instance: ESObject, identifier: number): void {
    if (identifier < 0) {
      throw new Error('Identifier must be >= 0: ' + identifier);
    }
    if (this.identifiersToInstances.has(identifier)) {
      throw new Error('Identifier has already been added: ' + identifier);
    }
    this.identifiersToInstances.set(identifier, instance);
    this.instancesToIdentifiers.set(instance, identifier);
  }

  /** Adds a new instance instantiated on the host side; returns the assigned identifier. */
  addHostCreatedInstance(instance: ESObject): number {
    if (this.instancesToIdentifiers.has(instance)) {
      throw new Error('Instance has already been added.');
    }
    const identifier: number = this.nextIdentifier++;
    this.identifiersToInstances.set(identifier, instance);
    this.instancesToIdentifiers.set(instance, identifier);
    return identifier;
  }

  /** Returns the instance for [identifier], or null if not registered. */
  getInstance(identifier: number): ESObject | null {
    const value: ESObject | undefined = this.identifiersToInstances.get(identifier);
    return value === undefined ? null : value;
  }

  /** Returns the identifier associated with [instance], or null. */
  getIdentifierForStrongReference(instance: ESObject | null): number | null {
    if (instance === null || instance === undefined) {
      return null;
    }
    const value: number | undefined = this.instancesToIdentifiers.get(instance);
    return value === undefined ? null : value;
  }

  /** Whether this manager currently contains [instance]. */
  containsInstance(instance: ESObject | null): boolean {
    if (instance === null || instance === undefined) {
      return false;
    }
    return this.instancesToIdentifiers.has(instance);
  }

  /** Removes the instance with [identifier] and returns it (or null if absent). */
  remove(identifier: number): ESObject | null {
    const instance: ESObject | undefined = this.identifiersToInstances.get(identifier);
    if (instance === undefined) {
      return null;
    }
    this.identifiersToInstances.delete(identifier);
    this.instancesToIdentifiers.delete(instance);
    if (this.finalizationListener !== null) {
      this.finalizationListener.onFinalize(identifier);
    }
    return instance;
  }

  /** Removes all instances from this manager. */
  clear(): void {
    this.identifiersToInstances.clear();
    this.instancesToIdentifiers.clear();
  }
}

/** Listener invoked when an instance is removed from the manager. */
export interface $_finalizationListenerInterfaceName {
  onFinalize(identifier: number): void;
}
''');
    indent.newln();
  }

  @override
  void writeInstanceManagerApi(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    final String removeRefChannel = makeRemoveStrongReferenceChannelName(
      dartPackageName,
    );
    final String clearChannel = makeClearChannelName(dartPackageName);
    indent.format('''
/**
 * Generated API for managing the Dart and native `$_instanceManagerClassName`s.
 *
 * Set up by `$_proxyApiRegistrarClassName` in setUp() / tearDown().
 */
export class $_instanceManagerApiClassName {
  binaryMessenger: BinaryMessenger;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The shared codec used by `$_instanceManagerApiClassName`. */
  static getCodec(): MessageCodec<Object> {
    return $_codecName.INSTANCE;
  }

  /** Registers (or removes) message handlers that let Dart drive this manager. */
  static setUpMessageHandlers(
    binaryMessenger: BinaryMessenger,
    instanceManager: $_instanceManagerClassName | null,
  ): void {
    // removeStrongReference
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
        binaryMessenger,
        "$removeRefChannel",
        $_instanceManagerApiClassName.getCodec());
      if (instanceManager != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>): void {
            if (!(Array.isArray(message))) {
              reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
              return;
            }
            let args: Array<Object> = message as Array<Object>;
            if (args.length < 1) {
              reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
              return;
            }
            let identifierArg: number = args[0] as number;
            if (typeof identifierArg !== 'number') {
              reply.reply(wrapError(new Error('Invalid Pigeon message: identifier must be a number.')));
              return;
            }
            let res: Array<Object> = [];
            try {
              instanceManager!.remove(identifierArg);
              res.push(null);
            } catch (error) {
              res = wrapError(error as Error);
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    // clear
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
        binaryMessenger,
        "$clearChannel",
        $_instanceManagerApiClassName.getCodec());
      if (instanceManager != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>): void {
            let res: Array<Object> = [];
            try {
              instanceManager!.clear();
              res.push(null);
            } catch (error) {
              res = wrapError(error as Error);
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Asks the Dart-side InstanceManager to release the strong reference for
   * the identifier so that the Dart proxy object can be garbage collected.
   */
  removeStrongReference(identifierArg: number, callback: Reply<void>): void {
    const channelName: string = '$removeRefChannel';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.binaryMessenger, channelName, $_instanceManagerApiClassName.getCodec());
    channel.send([identifierArg], channelReply => {
      // Errors on the Dart side are intentionally swallowed; the worst case
      // is a Dart-side memory leak that the developer can debug if needed.
      callback.reply();
    });
  }
}
''');
    indent.newln();
  }

  @override
  void writeProxyApiBaseCodec(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
  ) {
    final Iterable<AstProxyApi> allProxyApis = root.apis
        .whereType<AstProxyApi>();
    _writeProxyApiRegistrar(
      generatorOptions,
      indent,
      allProxyApis: allProxyApis,
    );
  }

  void _writeProxyApiRegistrar(
    InternalArkTSOptions generatorOptions,
    Indent indent, {
    required Iterable<AstProxyApi> allProxyApis,
  }) {
    final getters = StringBuffer();
    final setUpBody = StringBuffer();
    final tearDownBody = StringBuffer();
    for (final api in allProxyApis) {
      final String hostName = _proxyApiHostClassName(api);
      getters.writeln(
        '  /** An implementation of [$hostName] used to register a new Dart instance of `${api.name}` with the Dart `InstanceManager`. */',
      );
      getters.writeln('  abstract get${api.name}(): $hostName;');
      getters.writeln();

      final bool hasHostHandlers =
          api.constructors.isNotEmpty ||
          api.attachedFields.isNotEmpty ||
          api.hostMethods.isNotEmpty;
      if (hasHostHandlers) {
        setUpBody.writeln(
          '    $hostName.setUpMessageHandlers(this.binaryMessenger, this.get${api.name}());',
        );
        tearDownBody.writeln(
          '    $hostName.setUpMessageHandlers(this.binaryMessenger, null);',
        );
      }
    }
    indent.format('''
/**
 * Provides implementations for each ProxyApi class and shared resources.
 *
 * Subclass this in the host plugin, override each `getXxx()` to return your
 * implementation of `$hostProxyApiPrefix<ApiName>`, then call setUp() from
 * onAttachedToEngine and tearDown() from onDetachedFromEngine.
 */
export abstract class $_proxyApiRegistrarClassName {
  public binaryMessenger: BinaryMessenger;
  public instanceManager: $_instanceManagerClassName;
  /** Whether ProxyApi calls into Dart should be suppressed (e.g. during shutdown). */
  public ignoreCallsToDart: boolean = false;
  private codecInstance: MessageCodec<Object> | null = null;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = new $_instanceManagerClassName();
    const api: $_instanceManagerApiClassName = new $_instanceManagerApiClassName(binaryMessenger);
    this.instanceManager.setFinalizationListener({
      onFinalize: (identifier: number): void => {
        api.removeStrongReference(identifier, { reply: (_value: void): void => {} } as Reply<void>);
      }
    } as $_finalizationListenerInterfaceName);
  }

  /** Returns the shared `$_proxyApiBaseCodecClassName`, lazily instantiated. */
  getCodec(): MessageCodec<Object> {
    if (this.codecInstance === null) {
      this.codecInstance = new $_proxyApiBaseCodecClassName(this);
    }
    return this.codecInstance!;
  }

${getters.toString().trimRight()}

  /** Registers all message handlers and InstanceManager handlers. */
  setUp(): void {
    $_instanceManagerApiClassName.setUpMessageHandlers(this.binaryMessenger, this.instanceManager);
${setUpBody.toString().trimRight()}
  }

  /** Tears down all message handlers from the binary messenger. */
  tearDown(): void {
    $_instanceManagerApiClassName.setUpMessageHandlers(this.binaryMessenger, null);
${tearDownBody.toString().trimRight()}
  }
}
''');
    indent.newln();
  }

  /// Writes `PigeonProxyApiBaseCodec` AFTER PigeonCodec has been written, so
  /// that `extends $_codecName` is valid at module evaluation time.
  void _writeProxyApiBaseCodecClass(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.format('''
/**
 * Codec extending `$_codecName` with support for ProxyApi instance
 * references encoded under tag $_proxyApiInstanceTag.
 *
 * Instance refs must be pre-registered with the registrar's
 * `instanceManager`; pass `pigeon_newInstance(instance, callback)` on the
 * relevant `$hostProxyApiPrefix<ApiName>` to register host-side instances
 * before transmitting them to Dart.
 */
export class $_proxyApiBaseCodecClassName extends $_codecName {
  registrar: $_proxyApiRegistrarClassName;

  constructor(registrar: $_proxyApiRegistrarClassName) {
    super();
    this.registrar = registrar;
  }

  override readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    if (type === $_proxyApiInstanceTag) {
      const identifier: number = super.readValue(buffer) as number;
      const instance: ESObject | null =
          this.registrar.instanceManager.getInstance(identifier);
      if (instance === null) {
        throw new Error(
          '$_proxyApiBaseCodecClassName: instance not found for identifier ' +
            identifier +
            '. This may indicate a version mismatch, desynchronized InstanceManager state, '
            +
            'or corrupted payload.',
        );
      }
      return instance;
    }
    return super.readValueOfType(type, buffer);
  }

  override writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    // 1. Built-ins / nulls / collections fall straight through to the parent codec.
    if (value === null
        || typeof value === 'boolean'
        || typeof value === 'number'
        || typeof value === 'string'
        || Array.isArray(value)
        || value instanceof Map) {
      return super.writeValue(stream, value);
    }

    // 2. ProxyApi instances are encoded as (tag, identifier).
    if (this.registrar.instanceManager.containsInstance(value)) {
      stream.writeInt8($_proxyApiInstanceTag);
      const identifier: number | null =
          this.registrar.instanceManager.getIdentifierForStrongReference(value);
      this.writeValue(stream, identifier as Object);
      return;
    }

    // 3. Otherwise let the parent codec attempt to serialize (custom data
    //    classes, enums) or throw with a clear error.
    return super.writeValue(stream, value);
  }
}
''');
    indent.newln();
  }

  @override
  void writeProxyApi(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    AstProxyApi api, {
    required String dartPackageName,
  }) {
    final String hostName = _proxyApiHostClassName(api);

    addDocumentationComments(
      indent,
      api.documentationComments,
      _docCommentSpec,
      generatorComments: <String>[
        ' Generated host-side adapter for ProxyApi `${api.name}`.',
        ' Subclass and override the abstract members to provide your',
        ' HarmonyOS implementation, then return your subclass from the',
        " registrar's `get${api.name}()`.",
      ],
    );
    indent.write('export abstract class $hostName ');
    indent.addScoped('{', '}', () {
      indent.writeln('pigeonRegistrar: $_proxyApiRegistrarClassName;');
      indent.newln();
      indent.write(
        'constructor(pigeonRegistrar: $_proxyApiRegistrarClassName) ',
      );
      indent.addScoped('{', '}', () {
        indent.writeln('this.pigeonRegistrar = pigeonRegistrar;');
      });
      indent.newln();

      // ----- Abstract members -----
      _writeProxyApiConstructorAbstractMethods(indent, api);
      _writeProxyApiAttachedFieldAbstractMethods(indent, api);
      _writeProxyApiHostMethodAbstractMethods(indent, api);

      // ----- setUpMessageHandlers -----
      if (api.constructors.isNotEmpty ||
          api.attachedFields.isNotEmpty ||
          api.hostMethods.isNotEmpty) {
        _writeProxyApiMessageHandlerMethod(
          indent,
          api,
          hostName: hostName,
          dartPackageName: dartPackageName,
        );
      }

      // ----- pigeon_newInstance -----
      _writeProxyApiNewInstanceMethod(
        indent,
        api,
        dartPackageName: dartPackageName,
      );

      // ----- Flutter callbacks -----
      for (final Method method in api.flutterMethods) {
        _writeProxyApiFlutterMethod(
          indent,
          api,
          method,
          dartPackageName: dartPackageName,
        );
      }
    });
    indent.newln();
  }

  void _writeProxyApiConstructorAbstractMethods(
    Indent indent,
    AstProxyApi api,
  ) {
    for (final Constructor constructor in api.constructors) {
      final String name = constructor.name.isNotEmpty
          ? constructor.name
          : '${classMemberNamePrefix}defaultConstructor';
      addDocumentationComments(
        indent,
        constructor.documentationComments,
        _docCommentSpec,
      );
      final Iterable<String> sigParts = <Parameter>[
        ...api.unattachedFields.map(
          (ApiField field) => Parameter(name: field.name, type: field.type),
        ),
        ...constructor.parameters,
      ].map(_proxyApiParamSig);
      indent.writeln('abstract $name(${sigParts.join(', ')}): ESObject;');
      indent.newln();
    }
  }

  void _writeProxyApiAttachedFieldAbstractMethods(
    Indent indent,
    AstProxyApi api,
  ) {
    for (final ApiField field in api.attachedFields) {
      addDocumentationComments(
        indent,
        field.documentationComments,
        _docCommentSpec,
      );
      final sig = <String>[
        if (!field.isStatic) '${classMemberNamePrefix}instance: ESObject',
      ];
      indent.writeln(
        'abstract ${field.name}(${sig.join(', ')}): ${_arkTSTypeOrEsObject(field.type)};',
      );
      indent.newln();
    }
  }

  void _writeProxyApiHostMethodAbstractMethods(Indent indent, AstProxyApi api) {
    for (final Method method in api.hostMethods) {
      addDocumentationComments(
        indent,
        method.documentationComments,
        _docCommentSpec,
      );
      final sig = <String>[
        if (!method.isStatic) '${classMemberNamePrefix}instance: ESObject',
        ...method.parameters.map(_proxyApiParamSig),
        if (method.isAsynchronous)
          'result: Result<${method.returnType.isVoid ? 'void' : _arkTSTypeOrEsObject(method.returnType)}>',
      ];
      final String ret = method.isAsynchronous || method.returnType.isVoid
          ? 'void'
          : _arkTSTypeOrEsObject(method.returnType);
      indent.writeln('abstract ${method.name}(${sig.join(', ')}): $ret;');
      indent.newln();
    }
  }

  void _writeProxyApiMessageHandlerMethod(
    Indent indent,
    AstProxyApi api, {
    required String hostName,
    required String dartPackageName,
  }) {
    indent.writeln('/** Wires every host-side handler for `${api.name}`. */');
    indent.write(
      'static setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: $hostName | null): void ',
    );
    indent.addScoped('{', '}', () {
      indent.writeln(
        'const codec: MessageCodec<Object> = api != null ? api.pigeonRegistrar.getCodec() : $_codecName.INSTANCE;',
      );

      // Constructors
      for (final Constructor constructor in api.constructors) {
        final String name = constructor.name.isNotEmpty
            ? constructor.name
            : '${classMemberNamePrefix}defaultConstructor';
        final String channelName = makeChannelNameWithStrings(
          apiName: api.name,
          methodName: name,
          dartPackageName: dartPackageName,
        );
        final ctorParams = <Parameter>[
          Parameter(
            name: '${classMemberNamePrefix}identifier',
            type: const TypeDeclaration(baseName: 'int', isNullable: false),
          ),
          ...api.unattachedFields.map(
            (ApiField field) => Parameter(name: field.name, type: field.type),
          ),
          ...constructor.parameters,
        ];
        _writeProxyApiHandlerBlock(
          indent,
          channelName: channelName,
          parameters: ctorParams,
          isAsync: false,
          handlerBody: (List<String> argNames) {
            final String identifierExpr = argNames.first;
            final String ctorArgs = argNames.skip(1).join(', ');
            return 'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance('
                'api!.$name($ctorArgs), $identifierExpr); res.push(null);';
      },
        );
      }

      // Attached fields
      for (final ApiField field in api.attachedFields) {
        final String channelName = makeChannelNameWithStrings(
          apiName: api.name,
          methodName: field.name,
          dartPackageName: dartPackageName,
        );
        final fieldParams = <Parameter>[
          if (!field.isStatic)
            Parameter(
              name: '${classMemberNamePrefix}instance',
              type: TypeDeclaration(
                baseName: api.name,
                isNullable: false,
                associatedProxyApi: api,
              ),
            ),
          Parameter(
            name: '${classMemberNamePrefix}identifier',
            type: const TypeDeclaration(baseName: 'int', isNullable: false),
          ),
        ];
        _writeProxyApiHandlerBlock(
          indent,
          channelName: channelName,
          parameters: fieldParams,
          isAsync: false,
          handlerBody: (List<String> argNames) {
            final String instanceArg = field.isStatic ? '' : argNames.first;
            final String identifierArg = argNames.last;
            return 'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance('
                'api!.${field.name}($instanceArg), $identifierArg); res.push(null);';
          },
        );
      }

      // Host methods
      for (final Method method in api.hostMethods) {
        final String channelName = makeChannelName(
          api,
          method,
          dartPackageName,
        );
        final methodParams = <Parameter>[
          if (!method.isStatic)
            Parameter(
              name: '${classMemberNamePrefix}instance',
              type: TypeDeclaration(
                baseName: api.name,
                isNullable: false,
                associatedProxyApi: api,
              ),
            ),
          ...method.parameters,
        ];
        _writeProxyApiHandlerBlock(
          indent,
          channelName: channelName,
          parameters: methodParams,
          isAsync: method.isAsynchronous,
          returnType: method.returnType,
          handlerBody: (List<String> argNames) {
            final call = 'api!.${method.name}(${argNames.join(', ')})';
            if (method.isAsynchronous) {
              return '$call;';
            }
            if (method.returnType.isVoid) {
              return '$call; res.push(null);';
            }
            return 'let output: ESObject = $call; res.push(output);';
          },
        );
      }
    });
    indent.newln();
  }

  /// Emits one channel + handler block following the same pattern as
  /// `_writeMethodSetup`, but parameterised for ProxyApi semantics.
  void _writeProxyApiHandlerBlock(
    Indent indent, {
    required String channelName,
    required List<Parameter> parameters,
    required bool isAsync,
    TypeDeclaration returnType = const TypeDeclaration.voidDeclaration(),
    required String Function(List<String> argNames) handlerBody,
  }) {
    final bool isVoid = returnType.isVoid;
    indent.write('');
    indent.addScoped('{', '}', () {
      indent.writeln(
        'let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "$channelName", codec);',
      );
      indent.write('if (api != null) ');
      indent.addScoped('{', '} else {', () {
        indent.writeln('channel.setMessageHandler({');
        indent.nest(2, () {
          indent.write('onMessage(message: Object, reply: Reply<Object>) ');
          indent.addScoped('{', '} });', () {
            final argNames = <String>[];
            if (parameters.isNotEmpty) {
              _writeArkTsPigeonListMessagePrecheck(indent, parameters.length);
              for (var i = 0; i < parameters.length; i++) {
                final Parameter param = parameters[i];
                final safe = '${_proxyApiSafeName(i, param)}Arg';
                argNames.add(safe);
                indent.writeln(
                  'let $safe: ${_arkTSTypeOrEsObject(param.type)} = args[$i] as ${_arkTSTypeOrEsObject(param.type)};',
                );
              }
            }
            if (isAsync) {
              final String resultType = isVoid
                  ? 'void'
                  : _arkTSTypeOrEsObject(returnType);
              indent.format('''
class ResultImp implements Result<$resultType> {
  success(result: $resultType): void {
    let res: Array<Object> = [];
    res.push(${isVoid ? 'null' : 'result'});
    reply.reply(res);
  }
  error(error: Error): void {
    reply.reply(wrapError(error));
  }
}
let resultCallback: Result<$resultType> = new ResultImp();
''');
              argNames.add('resultCallback');
              indent.writeln(handlerBody(argNames));
            } else {
              indent.writeln('let res: Array<Object> = [];');
              indent.write('try ');
              indent.addScoped('{', '}', () {
                indent.writeln(handlerBody(argNames));
              });
              indent.add(' catch (error) ');
              indent.addScoped('{', '}', () {
                indent.writeln('res = wrapError(error as Error);');
              });
              indent.writeln('reply.reply(res);');
            }
          });
        });
      });
      indent.addScoped(null, '}', () {
        indent.writeln('channel.setMessageHandler(null);');
      });
    });
  }

  void _writeProxyApiNewInstanceMethod(
    Indent indent,
    AstProxyApi api, {
    required String dartPackageName,
  }) {
    final String channelName = makeChannelNameWithStrings(
      apiName: api.name,
      methodName: '${classMemberNamePrefix}newInstance',
      dartPackageName: dartPackageName,
    );
    indent.writeln(
      '/** Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager. */',
    );
    indent.write(
      '${classMemberNamePrefix}newInstance(pigeon_instance: ESObject, callback: Reply<void>): void ',
    );
    indent.addScoped('{', '}', () {
      indent.format(
        '''
if (this.pigeonRegistrar.ignoreCallsToDart) {
  callback.reply();
  return;
}
if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
  callback.reply();
  return;
}
const pigeon_identifier: number = this.pigeonRegistrar.instanceManager.addHostCreatedInstance(pigeon_instance);''',
      );
      // Unattached field values are passed alongside the identifier when Dart
      // has a callback-style constructor.
      final sendParts = <String>['pigeon_identifier'];
      for (var i = 0; i < api.unattachedFields.length; i++) {
        final ApiField field = api.unattachedFields.elementAt(i);
        indent.writeln(
          'const ${field.name}Arg: ESObject = this.${field.name}(pigeon_instance);',
        );
        sendParts.add('${field.name}Arg');
      }
      indent.format('''
const channelName: string = '$channelName';
let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
  this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
channel.send([${sendParts.join(', ')}], channelReply => {
  callback.reply();
});''');
    });
    indent.newln();
  }

  void _writeProxyApiFlutterMethod(
    Indent indent,
    AstProxyApi api,
    Method method, {
    required String dartPackageName,
  }) {
    final String channelName = makeChannelName(api, method, dartPackageName);
    final String returnType = method.returnType.isVoid
        ? 'void'
        : _arkTSTypeOrEsObject(method.returnType);

    final sigParts = <String>[
      '${classMemberNamePrefix}instance: ESObject',
      ...indexMap(
        method.parameters,
        (int i, NamedType arg) =>
            '${_proxyApiSafeName(i, arg)}Arg: ${_arkTSTypeOrEsObject(arg.type)}',
      ),
      'callback: Reply<$returnType>',
    ];
    final sendParts = <String>[
      '${classMemberNamePrefix}instance',
      ...indexMap(
        method.parameters,
        (int i, NamedType arg) => '${_proxyApiSafeName(i, arg)}Arg',
      ),
    ];

    addDocumentationComments(
      indent,
      method.documentationComments,
      _docCommentSpec,
    );
    indent.write('${method.name}(${sigParts.join(', ')}): void ');
    indent.addScoped('{', '}', () {
      indent.format('''
const channelName: string = '$channelName';
let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
  this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
channel.send([${sendParts.join(', ')}], channelReply => {
  if (Array.isArray(channelReply)) {
    let listReply: ESObject[] = channelReply as ESObject[];
    if (listReply.length > 1) {
      let arrFirst: string = listReply[0] as string;
      let arrSecond: string = listReply[1] as string;
      let arrThird: string = listReply[2] as string;
      callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
    } else {''');
      if (method.returnType.isVoid) {
        indent.writeln('      callback.reply();');
      } else {
        indent.writeln('      callback.reply(listReply[0] as $returnType);');
      }
      indent.format('''
    }
  } else {
    callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
  }
});''');
    });
    indent.newln();
  }

  /// Maps a Pigeon type to ArkTS, falling back to `ESObject` when no direct
  /// mapping exists (e.g. ProxyApi references whose runtime type is supplied
  /// by user code).
  String _arkTSTypeOrEsObject(TypeDeclaration type) {
    final String? builtin = _arkTSTypeForBuiltinDartType(type);
    if (builtin != null) {
      return builtin;
    }
    // Enums and data classes have concrete ArkTS class names.
    if (type.isEnum || type.isClass) {
      return type.baseName;
    }
    // ProxyApi references and unknown types: use ESObject for safety.
    return 'ESObject';
  }

  String _proxyApiSafeName(int index, NamedType arg) {
    final String base = arg.name.isEmpty ? 'arg$index' : arg.name;
    return base == 'arguments' ? '${base}Var' : base;
  }

  String _proxyApiParamSig(Parameter p) {
    return '${_proxyApiSafeName(0, p)}: ${_arkTSTypeOrEsObject(p.type)}';
  }
}
