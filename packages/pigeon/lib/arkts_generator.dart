// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'ast.dart';
import 'functional.dart';
import 'generator.dart';
import 'generator_tools.dart';
import 'pigeon_lib.dart' show TaskQueueType;

/// Relative path tried under [PigeonOptions.basePath] when no copyright header is
/// configured for ArkTS generation.
const String defaultArkTSCopyrightHeaderRelativePath = 'pigeons/copyright.txt';

/// Built-in copyright header for generated ArkTS when no explicit header is
/// configured and [defaultArkTSCopyrightHeaderRelativePath] is not present.
const List<String> kDefaultArkTSCopyrightHeader = <String>[
  'Copyright (C) 2024 Huawei Device Co., Ltd.',
  'Licensed under the Apache License, Version 2.0 (the "License");',
  'you may not use this file except in compliance with the License.',
  'You may obtain a copy of the License at',
  '',
  '    http://www.apache.org/licenses/LICENSE-2.0',
  '',
  'Unless required by applicable law or agreed to in writing, software',
  'distributed under the License is distributed on an "AS IS" BASIS,',
  'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.',
  'See the License for the specific language governing permissions and',
  'limitations under the License.',
];

/// Documentation open symbol.
const String _docCommentPrefix = '/*';

/// Documentation continuation symbol.
const String _docCommentContinuation = '* ';

/// Documentation close symbol.
const String _docCommentSuffix = '*/';

/// Documentation comment spec.
const DocumentCommentSpecification _docCommentSpec =
    DocumentCommentSpecification(
  _docCommentPrefix,
  closeCommentToken: _docCommentSuffix,
  blockContinuationToken: _docCommentContinuation,
);

/// The standard codec for Flutter, used for any non custom codecs and extended for custom codecs.
const String _standardMessageCodec = 'StandardMessageCodec';

/// Wrapper type so custom codecs always serialize a Dart `double` as float64.
const String _doubleBoxClassName = 'PigeonInternalDoubleBox';

/// StandardMessageCodec tag for a float64 value.
const int _standardCodecFloat64Tag = 6;

/// arkts参数
class ArkTSOptions {
  /// 构造
  const ArkTSOptions({
    this.copyrightHeader,
  });

  final Iterable<String>? copyrightHeader;

  static ArkTSOptions fromMap(Map<String, Object> map) {
    final Iterable<dynamic>? copyrightHeader =
        map['copyrightHeader'] as Iterable<dynamic>?;
    return ArkTSOptions(copyrightHeader: copyrightHeader?.cast<String>());
  }

  /// 转为map对象
  Map<String, Object> toMap() {
    final Map<String, Object> result = <String, Object>{
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

/// arkts code generator
class ArkTSGenerator extends StructuredGenerator<ArkTSOptions> {
  /// Instantiates a ArkTS Generator.
  const ArkTSGenerator();

  @override
  void writeFilePrologue(
      ArkTSOptions generatorOptions, Root root, Indent indent,
      {required String dartPackageName}) {
    if (generatorOptions.copyrightHeader != null) {
      indent.writeln('/*');
      addLines(indent, generatorOptions.copyrightHeader!, linePrefix: '* ');
      indent.writeln('*/');
    }
  }

  @override
  void writeFileImports(ArkTSOptions generatorOptions, Root root, Indent indent,
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

  /// 输出枚举
  @override
  void writeEnum(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Enum anEnum, {
    required String dartPackageName,
  }) {
    String camelToSnake(String camelCase) {
      final RegExp regex = RegExp('([a-z])([A-Z]+)');
      return camelCase
          .replaceAllMapped(regex, (Match m) => '${m[1]}_${m[2]}')
          .toUpperCase();
    }

    indent.newln();
    addDocumentationComments(
        indent, anEnum.documentationComments, _docCommentSpec);

    indent.write('export enum ${anEnum.name} ');
    indent.addScoped('{', '}', () {
      enumerate(anEnum.members, (int index, final EnumMember member) {
        addDocumentationComments(
            indent, member.documentationComments, _docCommentSpec);
        indent.writeln(
            '${camelToSnake(member.name)} = $index${index == anEnum.members.length - 1 ? '' : ','}');
      });
    });
  }

  @override
  void writeDataClass(
      ArkTSOptions generatorOptions, Root root, Indent indent, Class klass,
      {required String dartPackageName}) {
    final Set<String> customClassNames =
        root.classes.map((Class x) => x.name).toSet();
    final Set<String> customEnumNames =
        root.enums.map((Enum x) => x.name).toSet();

    const List<String> generatedMessages = <String>[
      ' Generated class from Pigeon that represents data sent in messages.'
    ];
    indent.newln();
    addDocumentationComments(
        indent, klass.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('export class ${klass.name} ');
    indent.addScoped('{', '}', () {
      for (final NamedType field in getFieldsInSerializationOrder(klass)) {
        _writeClassField(generatorOptions, root, indent, field);
        indent.newln();
      }

      _writeClassBuilder(generatorOptions, root, indent, klass);
      writeClassEncode(
        generatorOptions,
        root,
        indent,
        klass,
        customClassNames,
        customEnumNames,
        dartPackageName: dartPackageName,
      );
      writeClassDecode(
        generatorOptions,
        root,
        indent,
        klass,
        customClassNames,
        customEnumNames,
        dartPackageName: dartPackageName,
      );
    });
  }

  void _writeClassField(ArkTSOptions generatorOptions, Root root, Indent indent,
      NamedType field) {
    final HostDatatype hostDatatype = getFieldHostDatatype(field, root.classes,
        root.enums, (TypeDeclaration x) => _arkTSTypeForBuiltinDartType(x));
    final String optionalMarker = field.type.isNullable ? '?' : '';
    final String getterReturnType = field.type.isNullable
        ? '${hostDatatype.datatype} | undefined'
        : hostDatatype.datatype;
    indent.writeln(
        'private ${field.name}$optionalMarker: ${hostDatatype.datatype};');
    indent.newln();
    indent.write('${_makeGetter(field)}(): $getterReturnType ');
    indent.addScoped('{', '}', () {
      indent.writeln('return this.${field.name};');
    });
  }

  /// ArkTS requires non-optional constructor parameters before optional ones.
  List<NamedType> _constructorFieldOrder(Class klass) {
    final List<NamedType> fields =
        getFieldsInSerializationOrder(klass).toList();
    return <NamedType>[
      ...fields.where((NamedType f) => !f.type.isNullable),
      ...fields.where((NamedType f) => f.type.isNullable),
    ];
  }

  /// Nullable Pigeon fields use `name?: type` in the generated constructor.
  String _arkTSTypeForOmittableConstructorParam(NamedType field) {
    if (!field.type.isNullable) {
      return _arkTSTypeForDartType(field.type);
    }
    return _arkTSTypeForDartType(
      TypeDeclaration(
        baseName: field.type.baseName,
        isNullable: false,
        typeArguments: field.type.typeArguments,
      ),
    );
  }

  /// fromList locals for nullable fields may remain undefined before assignment.
  String _arkTSTypeForFromListLocal(NamedType field) {
    final String baseType = _arkTSTypeForDartType(field.type);
    if (field.type.isNullable) {
      return '$baseType | undefined';
    }
    return baseType;
  }

  void _writeClassBuilder(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class klass,
  ) {
    indent.write('constructor');
    final List<String> argSignature = <String>[];
    for (final NamedType element in _constructorFieldOrder(klass)) {
      final String name = getSafeConstructorArgument(element.name);
      if (element.type.isNullable) {
        argSignature.add(
          '$name?: ${_arkTSTypeForOmittableConstructorParam(element)}',
        );
      } else {
        argSignature.add('$name: ${_arkTSTypeForDartType(element.type)}');
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
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class klass,
    Set<String> customClassNames,
    Set<String> customEnumNames, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.write('toList(): Array<Object | null> ');
    indent.addScoped('{', '}', () {
      indent.writeln(
          'let arr: Array<Object | null> = new Array<Object | null>();');
      for (final NamedType field in getFieldsInSerializationOrder(klass)) {
        final String fieldName = field.name;
        final HostDatatype hostDatatype = getFieldHostDatatype(
            field,
            root.classes,
            root.enums,
            (TypeDeclaration x) => _arkTSTypeForBuiltinDartType(x));
        indent.write(
          'if (this.$fieldName === undefined || this.$fieldName === null) ',
        );
        indent.addScoped('{', '} else {', () {
          indent.writeln('arr.push(null);');
        });
        indent.addScoped(null, '}', () {
          if (!hostDatatype.isBuiltin &&
              customClassNames.contains(field.type.baseName)) {
            indent.writeln('''
if (this.$fieldName instanceof Array) {
        arr.push(this.$fieldName);
      } else {
        arr.push(this.$fieldName.toList());
      }''');
          } else if (!hostDatatype.isBuiltin &&
              customEnumNames.contains(field.type.baseName)) {
            indent.writeln(
                'arr.push(${_enumToWire('this.$fieldName', nullable: field.type.isNullable)});');
          } else if (_isDartDoubleType(field.type)) {
            indent.writeln(
                'arr.push(${_encodeDoubleForCodec(field.type, 'this.$fieldName')});');
          } else {
            indent.writeln('arr.push(this.$fieldName);');
          }
        });
      }
      indent.writeln('return arr;');
    });
  }

  @override
  void writeClassDecode(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class klass,
    Set<String> customClassNames,
    Set<String> customEnumNames, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.write('static fromList(arr: Object[]): ${klass.name} ');
    indent.addScoped('{', '}', () {
      final List<NamedType> fields =
          getFieldsInSerializationOrder(klass).toList();
      enumerate(fields, (int index, NamedType field) {
        _writeFromListFieldDecode(
          indent,
          index: index,
          field: field,
          customClassNames: customClassNames,
          customEnumNames: customEnumNames,
        );
      });
      if (fields.isEmpty) {
        indent.writeln('return new ${klass.name}();');
      } else {
        final String ctorArgs = _constructorFieldOrder(klass)
            .map((NamedType f) => f.name)
            .join(', ');
        indent.writeln('return new ${klass.name}($ctorArgs);');
      }
    });
  }

  void _writeFromListFieldDecode(
    Indent indent, {
    required int index,
    required NamedType field,
    required Set<String> customClassNames,
    required Set<String> customEnumNames,
  }) {
    final String name = field.name;
    final String arktsType = _arkTSTypeForDartType(field.type);
    if (customEnumNames.contains(field.type.baseName)) {
      final String enumName = field.type.baseName;
      if (field.type.isNullable) {
        indent.writeln(
            'let $name: ${_arkTSTypeForFromListLocal(field)} = ${_intToEnum('arr[$index]', enumName, true)};');
      } else {
        indent.writeln(
            'const $name: $arktsType = ${_intToEnum('arr[$index]', enumName, false)};');
      }
    } else if (customClassNames.contains(field.type.baseName)) {
      if (field.type.isNullable) {
        indent.writeln(
            'let $name: ${_arkTSTypeForFromListLocal(field)} = undefined;');
        indent.writeScoped(
          'if (arr[$index] !== null && arr[$index] !== undefined) {',
          '}',
          () {
            indent.writeln(
                '$name = ${field.type.baseName}.fromList(arr[$index] as Object[]);');
          },
        );
      } else {
        indent.writeln(
            'const $name: $arktsType = ${field.type.baseName}.fromList(arr[$index] as Object[]);');
      }
    } else if (field.type.isNullable) {
      indent.writeln(
          'let $name: ${_arkTSTypeForFromListLocal(field)} = undefined;');
      indent.writeScoped(
        'if (arr[$index] !== null && arr[$index] !== undefined) {',
        '}',
        () {
          indent.writeln('let ${name}Object: Object = arr[$index];');
          indent.writeln(
              '$name = ${_cast('${name}Object', artTSType: arktsType)};');
        },
      );
    } else {
      indent.writeln('let ${name}Object: Object = arr[$index];');
      indent.writeln(
          'const $name: $arktsType = ${_cast('${name}Object', artTSType: arktsType)};');
    }
  }

  @override
  void writeFlutterApi(
      ArkTSOptions generatorOptions, Root root, Indent indent, Api api,
      {required String dartPackageName}) {
    assert(api.location == ApiLocation.flutter);
    if (_apiNeedsCustomCodec(api, root)) {
      _writeCodec(indent, api, root);
    }

    const List<String> generatedMessages = <String>[
      ' Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.'
    ];
    addDocumentationComments(indent, api.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('export class ${api.name} ');
    indent.addScoped('{', '}', () {
      indent.writeln('binaryMessenger: BinaryMessenger;');
      indent.writeln('private messageChannelSuffix: string;');
      indent.newln();
      indent.write(
          'constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = \'\') ');
      indent.addScoped('{', '}', () {
        indent.writeln('this.binaryMessenger = binaryMessenger;');
        indent.writeln(
            "this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';");
      });

      indent.newln();
      final String codecName = _getCodecName(api);
      indent.writeln('/** The codec used by ${api.name}. */');
      indent.write('static getCodec(): MessageCodec<Object> ');
      indent.addScoped('{', '}', () {
        indent.write('return ');
        if (_apiNeedsCustomCodec(api, root)) {
          indent.addln('$codecName.INSTANCE;');
        } else {
          indent.addln('new $_standardMessageCodec();');
        }
      });

      indent.newln();

      /// Returns an argument expression safe for the codec (enum indices, double boxing).
      String getCodecSafeArgumentExpression(int count, NamedType argument) {
        final String argName = _getArgumentName(count, argument);
        if (isEnum(root, argument.type)) {
          return _enumToWire('${argName}Arg', nullable: argument.type.isNullable);
        }
        if (_isDartDoubleType(argument.type)) {
          return _encodeDoubleForCodec(argument.type, '${argName}Arg');
        }
        return '${argName}Arg';
      }

      for (final Method func in api.methods) {
        final String channelName = makeChannelName(api, func, dartPackageName);
        final String returnType = func.returnType.isVoid
            ? 'void'
            : _arkTSTypeForDartTypeWithNullability(func.returnType);
        String sendArgument;
        addDocumentationComments(
            indent, func.documentationComments, _docCommentSpec);
        if (func.arguments.isEmpty) {
          indent.write('${func.name}(callback: Reply<$returnType>):void ');
          sendArgument = 'null';
        } else {
          final Iterable<String> argTypes = func.arguments.map(
              (NamedType e) => _arkTSTypeForDartTypeWithNullability(e.type));
          final Iterable<String> argNames =
              indexMap(func.arguments, _getSafeArgumentName);
          final Iterable<String> codecSafeArgNames =
              indexMap(func.arguments, getCodecSafeArgumentExpression);
          sendArgument = '[${codecSafeArgNames.join(', ')}]';
          final String argsSignature =
              map2(argTypes, argNames, (String x, String y) => '$y: $x')
                  .join(',');
          indent.write(
              '${func.name}($argsSignature, callback: Reply<$returnType>) ');
        }
        indent.addScoped('{', '}', () {
          const String channel = 'channel';
          indent.writeln('let $channel: BasicMessageChannel<Object> = ');
          indent.nest(2, () {
            indent.writeln('new BasicMessageChannel<Object>(');
            indent.nest(2, () {
              indent.writeln(
                  'this.binaryMessenger, "$channelName" + this.messageChannelSuffix, ${api.name}.getCodec());');
            });
          });
          indent.writeln('$channel.send(');
          indent.nest(2, () {
            indent.writeln('$sendArgument,');
            indent.write('channelReply => ');
            if (func.returnType.isVoid) {
              indent.addln('callback.reply(null));');
            } else {
              indent.addScoped('{', '});', () {
                const String output = 'output';
                if (_isBuiltinNumberType(func.returnType)) {
                  indent.writeln(
                      'let $output: $returnType = ${_numberFromWire('channelReply', func.returnType.isNullable)};');
                } else if (isEnum(root, func.returnType)) {
                  indent.writeln(
                      'let $output: $returnType = ${_intToEnum('channelReply', func.returnType.baseName, func.returnType.isNullable)};');
                } else {
                  indent.writeln(
                      'let $output: $returnType = ${_cast('channelReply', artTSType: returnType)};');
                }
                indent.writeln('callback.reply($output);');
              });
            }
          });
        });
      }
    });
  }

  @override
  void writeApis(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    if (root.apis.any((Api api) =>
        api.location == ApiLocation.host &&
        api.methods.any((Method it) => it.isAsynchronous))) {
      indent.newln();
      _writeResultInterface(indent);
    }
    super.writeApis(generatorOptions, root, indent,
        dartPackageName: dartPackageName);
  }

  @override
  void writeHostApi(
      ArkTSOptions generatorOptions, Root root, Indent indent, Api api,
      {required String dartPackageName}) {
    assert(api.location == ApiLocation.host);
    if (_apiNeedsCustomCodec(api, root)) {
      _writeCodec(indent, api, root);
    }
    const List<String> generatedMessages = <String>[
      ' Generated abstract class from Pigeon that represents a handler of messages from Flutter.'
    ];
    addDocumentationComments(indent, api.documentationComments, _docCommentSpec,
        generatorComments: generatedMessages);

    indent.write('export abstract class ${api.name} ');
    indent.addScoped('{', '}', () {
      for (final Method method in api.methods) {
        _writeInterfaceMethod(generatorOptions, root, indent, api, method);
      }
      final String codecName = _getCodecName(api);
      indent.writeln('/** The codec used by ${api.name}. */');
      indent.write('static getCodec(): MessageCodec<Object>');
      indent.addScoped('{', '}', () {
        indent.write('return ');
        if (_apiNeedsCustomCodec(api, root)) {
          indent.addln('$codecName.INSTANCE;');
        } else {
          indent.addln('new $_standardMessageCodec();');
        }
      });

      indent.writeln(
          '${_docCommentPrefix}Sets up an instance of `${api.name}` to handle messages through the `binaryMessenger`.$_docCommentSuffix');
      indent.write(
          'static setup(binaryMessenger: BinaryMessenger, api: ${api.name} | null, messageChannelSuffix: string = \'\'): void ');
      indent.addScoped('{', '}', () {
        indent.writeln(
            "const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';");
        for (final Method method in api.methods) {
          _writeMethodSetup(
            generatorOptions,
            root,
            indent,
            api,
            method,
            dartPackageName: dartPackageName,
            channelNameSuffixExpression: 'separatedMessageChannelSuffix',
          );
        }
      });
    });
  }

  /// Write a static setup function in the interface.
  /// Example:
  ///   static void setup(BinaryMessenger binaryMessenger, Foo api) {...}
  void _writeMethodSetup(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api,
    final Method method, {
    required String dartPackageName,
    String channelNameSuffixExpression = "''",
  }) {
    final String channelName = makeChannelName(api, method, dartPackageName);
    indent.write('');
    indent.addScoped('{', '}', () {
      String? taskQueue;
      if (method.taskQueueType != TaskQueueType.serial) {
        taskQueue = 'taskQueue';
        indent.writeln(
            'let taskQueue: TaskQueue = binaryMessenger.makeBackgroundTaskQueue();');
      }
      indent.writeln('let channel: BasicMessageChannel<Object> =');
      indent.nest(2, () {
        indent.writeln('new BasicMessageChannel(');
        indent.nest(2, () {
          indent.write(
              'binaryMessenger, \'$channelName\' + $channelNameSuffixExpression, ${api.name}.getCodec()');
          indent.addln(');');
        });
      });
      indent.write('if (api != null) ');
      indent.addScoped('{', '} else {', () {
        indent.writeln('channel.setMessageHandler({');
        indent.nest(2, () {
          indent.write('onMessage(message: Object, reply: Reply<Object>) ');
          indent.addScoped('{', '} });', () {
            String enumTag = '';
            final String returnType = method.returnType.isVoid
                ? 'void'
                : _arkTSTypeForDartTypeWithNullability(method.returnType);
            final List<String> methodArgument = <String>[];
            if (method.arguments.isNotEmpty) {
              indent.writeln(
                  'let args: Array<Object> = message as Array<Object>;');
              enumerate(method.arguments, (int index, NamedType arg) {
                if (isEnum(root, arg.type)) {
                  methodArgument.add(
                      _intToEnum('args[$index]', arg.type.baseName, arg.type.isNullable));
                } else {
                  methodArgument.add(
                      'args[$index] as ${_arkTSTypeForDartTypeWithNullability(arg.type)}');
                }
              });
            }
            if (method.isAsynchronous) {
              final String resultValue = method.returnType.isVoid
                  ? 'null'
                  : _isDartDoubleType(method.returnType)
                      ? _encodeDoubleForCodec(method.returnType, 'result')
                      : 'result';
              if (isEnum(root, method.returnType)) {
                enumTag = method.returnType.isNullable
                    ? ' === undefined || $resultValue === null ? null : ${_enumToWire(resultValue, nullable: false)}'
                    : ' as number';
              }
              const String resultName = 'resultCallback';
              indent.format('''
class ResultImp implements Result<$returnType>{
\t\t\tsuccess(result: $returnType): void {
\t\t\t\tlet res: Array<Object> = [];
\t\t\t\tres.push($resultValue$enumTag);
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
            final String call =
                'api!.${method.name}(${methodArgument.join(', ')})';
            // indent.writeln('$call;');
            if (method.isAsynchronous) {
              indent.writeln('$call;');
            } else {
              // indent.writeln('let res: Array<Object> = [];');
              // indent.writeln('let output: $returnType = $call;');
              // indent.writeln('res[0] = output;');
              // indent.writeln('reply.reply(res);');

              indent.writeln('let res: Array<Object> = [];');
              indent.writeScoped('try {', '} catch (error) {', () {
                if (method.returnType.isVoid) {
                  indent.writeln('$call;');
                  indent.writeln('res.push(null);');
                } else {
                  indent.writeln('let output: $returnType = $call;');
                  if (isEnum(root, method.returnType)) {
                    indent.writeln(
                        'res.push(${_enumToWire('output', nullable: method.returnType.isNullable)});');
                  } else if (_isDartDoubleType(method.returnType)) {
                    indent.writeln(
                        'res.push(${_encodeDoubleForCodec(method.returnType, 'output')});');
                  } else {
                    indent.writeln('res.push(output);');
                  }
                }
              });
              indent.addScoped(null, '}', () {
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

  /// Writes the codec class that will be used by [api].
  /// Example:
  /// private static class FooCodec extends StandardMessageCodec {...}
  void _writeCodec(Indent indent, Api api, Root root) {
    assert(_apiNeedsCustomCodec(api, root));
    final Iterable<EnumeratedClass> codecClasses = getCodecClasses(api, root);
    final String codecName = _getCodecName(api);
    indent.newln();
    indent.write('class $codecName extends $_standardMessageCodec ');
    indent.addScoped('{', '}', () {
      indent.writeln('static INSTANCE: $codecName = new $codecName();');
      indent.newln();
      _writeGetByteMethoe(indent);
      indent.newln();
      indent.write(
          'readValueOfType(type: number, buffer: ByteBuffer): ESObject ');
      indent.addScoped('{', '}', () {
        indent.write('switch (type) ');
        indent.addScoped('{', '}', () {
          for (final EnumeratedClass customClass in codecClasses) {
            indent.writeln('case this.getByte(${customClass.enumeration}):');
            indent.nest(1, () {
              indent.writeln(
                  'return ${customClass.name}.fromList(super.readValue(buffer));');
            });
          }
          indent.writeln('default:');
          indent.nest(1, () {
            indent.writeln('return super.readValueOfType(type, buffer);');
          });
        });
      });
      indent.newln();
      indent.write('writeValue(stream: ByteBuffer, value: ESObject): ESObject ');
      indent.addScoped('{', '}', () {
        if (_rootUsesDartDouble(root)) {
          indent.writeScoped(
            'if (value instanceof $_doubleBoxClassName) {',
            '} else ',
            () {
              indent.writeln(
                  'stream.writeInt8(this.getByte($_standardCodecFloat64Tag));');
              indent.writeln('this.writeAlignment(stream, 8);');
              indent.writeln(
                  'stream.writeFloat64((value as $_doubleBoxClassName).value, true);');
              indent.writeln('return;');
            },
            addTrailingNewline: false,
          );
        }
        bool firstClass = true;
        for (final EnumeratedClass customClass in codecClasses) {
          if (firstClass) {
            indent.write('');
            firstClass = false;
          }
          indent.add('if (value instanceof ${customClass.name}) ');
          indent.addScoped('{', '} else ', () {
            indent.writeln(
                'stream.writeUint8(this.getByte(${customClass.enumeration}));');
            indent.writeln(
                'this.writeValue(stream, (value as ${customClass.name}).toList());');
          }, addTrailingNewline: false);
        }
        indent.addScoped('{', '}', () {
          indent.writeln('super.writeValue(stream, value);');
        });
      });
    });
    indent.newln();
  }

  /// Write a method in the interface.
  /// Example:
  ///   int add(int x, int y);
  void _writeInterfaceMethod(ArkTSOptions generatorOptions, Root root,
      Indent indent, Api api, final Method method) {
    final String returnType = method.isAsynchronous
        ? 'void'
        : _arkTSTypeForDartTypeWithNullability(method.returnType);

    final List<String> argSignature = <String>[];
    if (method.arguments.isNotEmpty) {
      final Iterable<String> argTypes = method.arguments
          .map((NamedType e) => _arkTSTypeForDartTypeWithNullability(e.type));
      final Iterable<String> argNames =
          method.arguments.map((NamedType e) => e.name);
      argSignature
          .addAll(map2(argTypes, argNames, (String argType, String argName) {
        return '$argName: $argType';
      }));
    }
    if (method.isAsynchronous) {
      final String resultType = method.returnType.isVoid
          ? 'void'
          : _arkTSTypeForDartTypeWithNullability(method.returnType);
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
      indent.writeln('success(result: T): void;');
      indent.newln();
      indent.writeln('error(error: Error): void;');
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
          'constructor(code: string, name: string, message: string, stack: string) ');
      indent.addScoped('{', '}', () {
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

  void _writeDoubleBoxClass(Indent indent) {
    indent.writeln('/**');
    indent.writeln(
        ' * Wrapper so custom codecs always serialize a Dart `double` as float64.');
    indent.writeln(
        ' * ArkTS `number` values such as `1` or `1.0` would otherwise be encoded');
    indent.writeln(
        ' * as integers by StandardMessageCodec and fail strict Dart double casts.');
    indent.writeln(' */');
    indent.write('export class $_doubleBoxClassName ');
    indent.addScoped('{', '}', () {
      indent.writeln('value: number;');
      indent.write('constructor(value: number) ');
      indent.addScoped('{', '}', () {
        indent.writeln('this.value = value;');
      });
    });
  }

  @override
  void writeGeneralUtilities(
    ArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.newln();
    _writeErrorClass(indent);
    if (_rootUsesDartDouble(root)) {
      indent.newln();
      _writeDoubleBoxClass(indent);
    }
    indent.newln();
    _writeWrapError(indent);
  }

  /// Calculates the name of the codec that will be generated for [api].
  String _getCodecName(Api api) => '${api.name}Codec';

  /// Converts an expression that evaluates to an int on the wire to an enum.
  ///
  /// Numeric enums in ArkTS/TypeScript must not use `EnumName[index]` for
  /// decoding: that reverse-lookup returns the member name string, not the
  /// enum value. Pigeon sends enum indices on the wire, so cast directly.
  String _intToEnum(String expression, String enumName, bool nullable) =>
      nullable
          ? '$expression == null || $expression === undefined ? undefined : $expression as number as $enumName'
          : '$expression as number as $enumName';

  /// Converts an enum to its int index for the Pigeon wire format.
  String _enumToWire(String expression, {required bool nullable}) =>
      nullable
          ? '$expression === undefined || $expression === null ? null : $expression as number'
          : '$expression as number';

  /// Whether [type] is a Dart primitive that maps to ArkTS `number`.
  bool _isBuiltinNumberType(TypeDeclaration type) =>
      _arkTSTypeForBuiltinDartType(type) == 'number';

  /// Converts a codec reply value to a number for FlutterApi callbacks.
  ///
  /// Nullable Dart int/double maps to `number | undefined` in ArkTS; use
  /// `undefined` rather than `null` for absent values.
  String _numberFromWire(String expression, bool nullable) => nullable
      ? '$expression == null || $expression === undefined ? undefined : $expression as number'
      : '$expression as number';

  String _getArgumentName(int count, NamedType argument) =>
      argument.name.isEmpty ? 'arg$count' : argument.name;

  String _getSafeArgumentName(int count, NamedType argument) =>
      '${_getArgumentName(count, argument)}Arg';

  /// arkts方法参数如果是arguments，会与参数关键字冲突
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

  String _arkTSTypeForDartType(TypeDeclaration type) {
    return _arkTSTypeForBuiltinDartType(type) ?? type.baseName;
  }

  String _arkTSTypeForDartTypeWithNullability(TypeDeclaration type) {
    final String baseType = _arkTSTypeForDartType(type);
    return type.isNullable ? '$baseType | undefined' : baseType;
  }

  /// Converts a [List] of [TypeDeclaration]s to a comma separated [String] to be
  /// used in Java code.
  String _flattenTypeArguments(List<TypeDeclaration> args) {
    return args.map<String>(_arkTSTypeForDartType).join(', ');
  }

  /// 泛型转换
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
    const Map<String, String> arkTSTypeForDartTypeMap = <String, String>{
      'bool': 'boolean',
      'int': 'number',
      'String': 'string',
      'double': 'number',
      'Uint8List': 'number[]',
      'Int32List': 'number[]',
      'Int64List': 'number[]',
      'Float64List': 'number[]',
      'Float32List': 'number[]',
      'Object': 'Object',
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

  bool _isDartDoubleType(TypeDeclaration type) => type.baseName == 'double';

  bool _typeDeclarationUsesDouble(TypeDeclaration type) {
    if (type.baseName == 'double') {
      return true;
    }
    for (final TypeDeclaration typeArg in type.typeArguments) {
      if (_typeDeclarationUsesDouble(typeArg)) {
        return true;
      }
    }
    return false;
  }

  bool _apiUsesDartDouble(Api api) {
    for (final Method method in api.methods) {
      if (_typeDeclarationUsesDouble(method.returnType)) {
        return true;
      }
      for (final NamedType arg in method.arguments) {
        if (_typeDeclarationUsesDouble(arg.type)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _apiNeedsCustomCodec(Api api, Root root) =>
      getCodecClasses(api, root).isNotEmpty || _apiUsesDartDouble(api);

  bool _rootUsesDartDouble(Root root) {
    for (final Class klass in root.classes) {
      for (final NamedType field in klass.fields) {
        if (_typeDeclarationUsesDouble(field.type)) {
          return true;
        }
      }
    }
    for (final Api api in root.apis) {
      if (_apiUsesDartDouble(api)) {
        return true;
      }
    }
    return false;
  }

  /// Wraps [valueExpr] so the codec always serializes a Pigeon `double` as float64.
  String _encodeDoubleForCodec(TypeDeclaration type, String valueExpr) {
    assert(_isDartDoubleType(type));
    if (type.isNullable) {
      return '($valueExpr === null || $valueExpr === undefined ? null : new $_doubleBoxClassName($valueExpr))';
    }
    return 'new $_doubleBoxClassName($valueExpr)';
  }
}
