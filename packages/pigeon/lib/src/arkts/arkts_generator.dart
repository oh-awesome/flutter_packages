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
  const ArkTSOptions({this.copyrightHeader});

  /// A copyright header that will get prepended to generated code.
  final Iterable<String>? copyrightHeader;

  /// Creates [ArkTSOptions] from a Map representation where:
  /// `x = ArkTSOptions.fromMap(x.toMap())`.
  static ArkTSOptions fromMap(Map<String, Object> map) {
    final copyrightHeader = map['copyrightHeader'] as Iterable<dynamic>?;
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
  const InternalArkTSOptions({required this.arkTSOut, this.copyrightHeader});

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
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    if (generatorOptions.copyrightHeader != null) {
      indent.writeln('/*');
      addLines(indent, generatorOptions.copyrightHeader!, linePrefix: '* ');
      indent.writeln('*/');
    }
  }

  @override
  void writeFileImports(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent, {
    required String dartPackageName,
  }) {
    indent.writeln(
      "import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';",
    );
    indent.writeln(
      "import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';",
    );
    indent.writeln(
      "import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';",
    );
    indent.writeln(
      "import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';",
    );
    indent.writeln(
      "import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';",
    );
    if (root.containsEventChannel) {
      indent.writeln(
        "import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';",
      );
      indent.writeln(
        "import { EventChannel, EventSink, StreamHandler } from '@ohos/flutter_ohos';",
      );
    }
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
      ' Generated enum from Pigeon that represents data sent in messages.',
    ];
    indent.newln();
    addDocumentationComments(
      indent,
      anEnum.documentationComments,
      _docCommentSpec,
      generatorComments: generatedEnumMessages,
    );
    indent.write('export enum ${anEnum.name} ');
    indent.addScoped('{', '}', () {
      enumerate(anEnum.members, (int index, final EnumMember member) {
        addDocumentationComments(
          indent,
          member.documentationComments,
          _docCommentSpec,
        );
        indent.writeln(
          '${camelToSnake(member.name)}${index == anEnum.members.length - 1 ? '' : ','}',
        );
      });
    });
    const generatedEnumCompanionMessages = <String>[
      '''
 Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed''',
    ];
    indent.newln();
    addDocumentationComments(
      indent,
      anEnum.documentationComments,
      _docCommentSpec,
      generatorComments: generatedEnumCompanionMessages,
    );
    indent.write('export class ${anEnum.name}$_enumCompanionSuffix ');
    indent.addScoped('{', '}', () {
      indent.writeln('index: string|null = null;');
      indent.addScoped('\tconstructor(index: string){', '}', () {
        indent.writeln('this.index = index;');
      });
    });
  }

  @override
  void writeDataClass(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class klass, {
    required String dartPackageName,
  }) {
    const generatedMessages = <String>[
      ' Generated class from Pigeon that represents data sent in messages.',
    ];
    indent.newln();
    addDocumentationComments(
      indent,
      klass.documentationComments,
      _docCommentSpec,
      generatorComments: generatedMessages,
    );

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
      field,
      (TypeDeclaration x) => _arkTSTypeForBuiltinDartType(x),
    );
    final String fieldType = hostDatatype.datatype;
    final String optionalMarker = field.type.isNullable ? '?' : '';
    final String getterReturnType = field.type.isNullable
        ? '$fieldType | undefined'
        : fieldType;
    indent.writeln('private ${field.name}$optionalMarker: $fieldType;');
    indent.newln();
    final String setterParamType = _arkTSTypeForDartType(field.type);
    indent.writeScoped(
      'public ${_makeSetter(field)}(${field.name}: $setterParamType): void {',
      '}',
      () {
        indent.writeln('this.${field.name} = ${field.name};');
      },
    );
    indent.newln();
    indent.write('${_makeGetter(field)}(): $getterReturnType');
    indent.addScoped('{', '}', () {
      indent.writeln('return this.${field.name};');
    });
  }

  void _writeDataClassSignature(
    InternalArkTSOptions generatorOptions,
    Indent indent,
    Class classDefinition,
    void Function() dataClassBody, {
    bool private = false,
  }) {
    indent.write(
      '${private ? 'private' : 'public'} static final class ${classDefinition.name} ',
    );
    indent.addScoped('{', '}', () {
      for (final NamedType field in getFieldsInSerializationOrder(
        classDefinition,
      )) {
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

  /// ArkTS requires non-optional constructor parameters before optional ones.
  /// Serialization order is unchanged; only the public constructor reorders.
  List<NamedType> _constructorFieldOrder(Class klass) {
    final List<NamedType> fields = getFieldsInSerializationOrder(
      klass,
    ).toList();
    return <NamedType>[
      ...fields.where((NamedType f) => !f.type.isNullable),
      ...fields.where((NamedType f) => f.type.isNullable),
    ];
  }

  /// ArkTS optional constructor parameter type for a nullable Pigeon field.
  ///
  /// Dart `String? name` is nullable and omit-able in the generated constructor
  /// (`{this.name}` without `required`). The ArkTS equivalent is `name?: string`:
  /// `?` marks the parameter optional; the value may be `undefined` when omitted.
  String _arkTSTypeForOmittableConstructorParam(NamedType field) {
    if (!field.type.isNullable) {
      return _arkTSTypeForDartType(field.type);
    }
    return _arkTSTypeForDartType(
      TypeDeclaration(
        baseName: field.type.baseName,
        isNullable: false,
        associatedEnum: field.type.associatedEnum,
        associatedClass: field.type.associatedClass,
        associatedProxyApi: field.type.associatedProxyApi,
        typeArguments: field.type.typeArguments,
      ),
    );
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
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    indent.newln();
    // The list holds a positional slot for every field, including `null` for
    // absent/nullable ones (see loop below). ArkTS forbids assigning `null` to
    // a non-nullable `Object`, so the element type must be `Object | null`.
    indent.write('toList(): Array<Object | null> ');
    indent.addScoped('{', '}', () {
      indent.writeln(
        'let arr: Array<Object | null> = new Array<Object | null>();',
      );
      for (final NamedType field in getFieldsInSerializationOrder(
        classDefinition,
      )) {
        final String fieldName = field.name;
        // Every field must occupy its positional slot (null when absent) so the
        // produced list lines up with fromList() and the Dart side's positional
        // decode. Conditionally skipping absent fields would shift every later
        // field's index and corrupt decoding.
        indent.write(
          'if (this.$fieldName === undefined || this.$fieldName === null) ',
        );
        indent.addScoped('{', '} else {', () {
          indent.writeln('arr.push(null);');
        });
        indent.addScoped(null, '}', () {
          if (field.type.isEnum) {
            indent.writeln(
              'const $fieldName$_string_Param_Suffix = ${field.type.baseName}[this.$fieldName as number];',
            );
            indent.writeln(
              'arr.push(new ${field.type.baseName}$_enumCompanionSuffix($fieldName$_string_Param_Suffix));',
            );
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
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Class classDefinition, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.write('static fromList(arr: Object[]): ${classDefinition.name} ');
    indent.addScoped('{', '}', () {
      final List<NamedType> fields = getFieldsInSerializationOrder(
        classDefinition,
      ).toList();
      enumerate(fields, (int index, final NamedType field) {
        _writeFromListFieldDecode(indent, index: index, field: field);
      });
      if (fields.isEmpty) {
        indent.writeln('return new ${classDefinition.name}();');
      } else {
        final String ctorArgs = _constructorFieldOrder(
          classDefinition,
        ).map((NamedType f) => f.name).join(', ');
        indent.writeln('return new ${classDefinition.name}($ctorArgs);');
      }
    });
  }

  /// Emits a local decode for one positional [arr] slot in [fromList].
  void _writeFromListFieldDecode(
    Indent indent, {
    required int index,
    required NamedType field,
  }) {
    final String name = field.name;
    final String arktsType = _arkTSTypeForDartType(field.type);
    if (field.type.isEnum) {
      if (field.type.isNullable) {
        indent.writeln('let $name: $arktsType = undefined;');
        indent.writeScoped(
          'if (arr[$index] !== null && arr[$index] !== undefined) {',
          '}',
          () {
            indent.writeln('const ${name}Str: string = arr[$index] as string;');
            indent.writeln('$name = ${field.type.baseName}[${name}Str];');
          },
        );
      } else {
        indent.writeln('const ${name}Str: string = arr[$index] as string;');
        indent.writeln(
          'const $name: $arktsType = ${field.type.baseName}[${name}Str];',
        );
      }
    } else if (field.type.isNullable) {
      indent.writeln('let $name: $arktsType = undefined;');
      indent.writeScoped(
        'if (arr[$index] !== null && arr[$index] !== undefined) {',
        '}',
        () {
          indent.writeln('let ${name}Object: Object = arr[$index];');
          indent.writeln('$name = ${_castObject(field, '${name}Object')};');
        },
      );
    } else {
      indent.writeln('let ${name}Object: Object = arr[$index];');
      indent.writeln(
        'const $name: $arktsType = ${_castObject(field, '${name}Object')};',
      );
    }
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
      field,
      (TypeDeclaration x) => _arkTSTypeForDartType(x),
    );
    return _cast(varName, artTSType: hostDatatype.datatype);
  }

  @override
  void writeFlutterApi(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api, {
    required String dartPackageName,
  }) {
    String getSafeArgumentExpression(int count, NamedType argument) {
      return '${_getArgumentName(count, argument)}Arg';
    }

    const generatedMessages = <String>[
      ' Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.',
    ];
    addDocumentationComments(
      indent,
      api.documentationComments,
      _docCommentSpec,
      generatorComments: generatedMessages,
    );

    indent.write('export class ${api.name} ');

    ///MessageFlutterApi
    indent.addScoped('{', '}', () {
      indent.writeln('binaryMessenger: BinaryMessenger;');
      indent.writeln('private messageChannelSuffix: string;');
      indent.newln();

      indent.write(
        'constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = \'\') ',
      );
      indent.addScoped('{', '}', () {
        indent.writeln('this.binaryMessenger = binaryMessenger;');
        indent.writeln(
          "this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';",
        );
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
          indent,
          func.documentationComments,
          _docCommentSpec,
        );
        if (func.parameters.isEmpty) {
          indent.write('${func.name}(callback: Reply<$returnType>):void ');
          sendArgument = 'null';
        } else {
          final Iterable<String> argTypes = func.parameters.map(
            (NamedType e) => _arkTSTypeForDartType(e.type),
          );
          final Iterable<String> argNames = indexMap(
            func.parameters,
            _getSafeArgumentName,
          );
          // Enum arguments must be wrapped in the codec's companion type before
          // being sent; a bare enum value (number) would not match
          // `instanceof <Enum>Enum` and would be encoded as a plain int without
          // the enum type tag.
          final List<String> sendArgParts = indexMap(func.parameters, (
            int i,
            NamedType arg,
          ) {
            final String argName = getSafeArgumentExpression(i, arg);
            if (arg.type.isEnum) {
              final String enumName = _arkTSCustomTypeName(arg.type);
              return arg.type.isNullable
                  ? '($argName == null ? null : new $enumName$_enumCompanionSuffix($enumName[$argName as number]))'
                  : 'new $enumName$_enumCompanionSuffix($enumName[$argName as number])';
            }
            return argName;
          }).toList();

          sendArgument = '[${sendArgParts.join(', ')}]';

          final String argsSignature = map2(
            argTypes,
            argNames,
            (String x, String y) => '$y: $x',
          ).join(',');
          indent.write(
            '${func.name}($argsSignature, callback: Reply<$returnType>) ',
          );
        }
        indent.addScoped('{', '}', () {
          const channel = 'channel';
          indent.writeln(
            "const channelName: string = '${makeChannelName(api, func, dartPackageName)}' + this.messageChannelSuffix;",
          );
          indent.writeln('let $channel: BasicMessageChannel<Object> = ');
          indent.nest(2, () {
            indent.writeln('new BasicMessageChannel<Object>(');
            indent.nest(2, () {
              indent.writeln(
                'this.binaryMessenger, channelName, ${api.name}.getCodec());',
              );
            });
          });
          indent.writeln('$channel.send(');

          indent.nest(2, () {
            indent.writeln('$sendArgument,');
            indent.write('channelReply => ');

            indent.addScoped('{', '});', () {
              indent.writeScoped(
                'if (Array.isArray(channelReply)) {',
                '} ',
                () {
                  indent.writeln(
                    'let listReply: ESObject[] = channelReply as ESObject[] ;',
                  );
                  indent.writeScoped('if (listReply.length > 1) {', '} ', () {
                    indent.writeln(
                      'let arrFirst:string = listReply[0] as string;',
                    );
                    indent.writeln(
                      'let arrSecond:string = listReply[1] as string;',
                    );
                    indent.writeln(
                      'let arrThird:string = listReply[2] as string;',
                    );
                    // A 3-element reply is an error envelope; reconstruct a real
                    // FlutterError object (not a string assigned to the return
                    // type, which never matched the declared type).
                    indent.writeln(
                      'let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);',
                    );
                    indent.writeln('callback.reply(replyArr);');
                  }, addTrailingNewline: false);

                  // Only a NON-nullable return treats a null payload as a
                  // contract violation. For a nullable return, null is a valid
                  // value and must fall through to the decode branch below
                  // (matches the Kotlin/Swift FlutterApi and the ProxyApi path).
                  if (!func.returnType.isVoid && !func.returnType.isNullable) {
                    indent.addScoped(
                      'else if (listReply[0] == null) {',
                      '} ',
                      () {
                        indent.writeln(
                          "let replyNull: ESObject = new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');",
                        );
                        indent.writeln('callback.reply(replyNull);');
                      },
                      addTrailingNewline: false,
                    );
                  }

                  indent.addScoped('else {', '}', () {
                    if (func.returnType.isVoid) {
                      indent.writeln('callback.reply();');
                    } else {
                      const output = 'output';
                      if (func.returnType.isEnum) {
                        // Decoded enum arrives as its member-name string; convert
                        // back to the enum value the callback expects (mirrors the
                        // data-class fromList enum handling).
                        indent.writeln(
                          'let $output: ESObject = listReply[0] == null ? null : ${_arkTSCustomTypeName(func.returnType)}[listReply[0] as string];',
                        );
                      } else {
                        final String outputExpression;
                        if (func.returnType.baseName == 'number') {
                          outputExpression =
                              'listReply[0] == null ? null : (listReply[0] as number).valueOf();';
                        } else {
                          outputExpression =
                              '${_cast('listReply[0]', artTSType: returnType)};';
                        }
                        indent.writeln(
                          'let $output:$returnType = $outputExpression',
                        );
                      }
                      indent.writeln('callback.reply($output);');
                    }
                  });
                },
                addTrailingNewline: false,
              );
              indent.addScoped(' else {', '} ', () {
                indent.writeln(
                  "let connErr: ESObject = new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '');",
                );
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
        '${_docCommentPrefix}Sets up an instance of `${api.name}` to handle messages through the `binaryMessenger`.$_docCommentSuffix',
      );

      indent.write(
        'static setup(binaryMessenger: BinaryMessenger, api: ${api.name} | null, messageChannelSuffix: string = \'\'): void ',
      );
      indent.addScoped('{', '}', () {
        indent.writeln(
          "const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';",
        );
        // flutter_ohos BasicMessageChannel currently accepts three arguments
        // only (binaryMessenger, name, codec). @TaskQueue is honored at the
        // IDL level but cannot bind a queue into the channel constructor yet.
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
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api,
    final Method method, {
    required String dartPackageName,
    String channelNameSuffixExpression = "''",
  }) {
    final String baseChannelName = makeChannelName(
      api,
      method,
      dartPackageName,
    );
    indent.write('');
    indent.addScoped('{', '}', () {
      indent.writeln('let channel: BasicMessageChannel<Object> =');
      indent.nest(2, () {
        indent.writeln('new BasicMessageChannel(');
        indent.nest(2, () {
          indent.write(
            'binaryMessenger, \'$baseChannelName\' + $channelNameSuffixExpression, ${api.name}.getCodec()',
          );
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
                String argExpression;
                if (arg.type.isEnum) {
                  // The codec decodes an enum to its member-name string; convert
                  // it back to the enum value the abstract method expects
                  // (mirrors the data-class fromList enum handling). Keyed off
                  // the PARAMETER type, not the method return type.
                  final String enumName = _arkTSCustomTypeName(arg.type);
                  argExpression = arg.type.isNullable
                      ? '(args[$index] == null ? null : $enumName[args[$index] as string])'
                      : '$enumName[args[$index] as string]';
                } else {
                  argExpression =
                      'args[$index] as ${_arkTSTypeForDartType(arg.type)}';
                }
                methodArgument.add(argExpression);
              });
            }
            if (method.isAsynchronous) {
              // Encode an enum result into its codec companion before replying,
              // exactly like the sync path / data-class toList. Without this an
              // async enum return would push the raw enum value and the codec
              // (which keys off `instanceof <Enum>Enum`) would mis-serialize it.
              final resultValue = method.returnType.isVoid
                  ? 'null'
                  : (method.returnType.isEnum
                        ? '(result === null || result === undefined ? null : new ${_arkTSCustomTypeName(method.returnType)}$_enumCompanionSuffix(${_arkTSCustomTypeName(method.returnType)}[result as number]))'
                        : 'result');
              const resultName = 'resultCallback';
              indent.format('''
class ResultImp implements Result<$returnType>{
\t\t\tsuccess(result: $returnType): void {
\t\t\t\tlet res: Array<Object | null> = [];
\t\t\t\tres.push($resultValue);
\t\t\t\treply.reply(res);
\t\t\t}

\t\t\terror(error: Error): void {
\t\t\t\tlet wrappedError: Array<Object | null> = wrapError(error);
\t\t\t\treply.reply(wrappedError);
\t\t\t}
}
let $resultName: Result<$returnType> = new ResultImp();
''');
              methodArgument.add(resultName);
            }
            final call = 'api!.${method.name}(${methodArgument.join(', ')})';
            // indent.writeln('$call;');
            if (method.isAsynchronous) {
              indent.writeln('$call;');
            } else {
              indent.writeln('let res: Array<Object | null> = [];');
              indent.write('try ');
              indent.addScoped('{', '}', () {
                if (method.returnType.isVoid) {
                  indent.writeln('$call;');
                  indent.writeln('res.push(null);');
                } else {
                  if (method.returnType.isEnum) {
                    final String enumName = _arkTSCustomTypeName(
                      method.returnType,
                    );
                    // Encode the returned enum the same way the codec/data-class
                    // path does: convert the enum value to its member-name
                    // string and wrap it in the companion type. Uses the full
                    // argument list (not a hardcoded args[0]).
                    indent.writeln(
                      'let pigeonEnumResult: $returnType = $call;',
                    );
                    indent.writeln(
                      'let output: ESObject = pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ${enumName}$_enumCompanionSuffix($enumName[pigeonEnumResult as number]);',
                    );
                  } else {
                    indent.writeln('let output: $returnType = $call;');
                  }
                  indent.writeln('res.push(output);');
                }
              });
              indent.add(' catch (error) ');
              indent.addScoped('{', '}', () {
                indent.writeln(
                  'let wrappedError: Array<Object | null> = wrapError(error);',
                );
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

  void _writeInterfaceMethod(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    Api api,
    final Method method,
  ) {
    final String returnType = method.isAsynchronous
        ? 'void'
        : _arkTSTypeForDartType(method.returnType);

    final argSignature = <String>[];
    if (method.parameters.isNotEmpty) {
      final Iterable<String> argTypes = method.parameters.map(
        (NamedType e) => _arkTSTypeForDartType(e.type),
      );
      final Iterable<String> argNames = method.parameters.map(
        (NamedType e) => e.name,
      );
      argSignature.addAll(
        map2(argTypes, argNames, (String argType, String argName) {
          return '$argName: $argType ';
        }),
      );
    }
    if (method.isAsynchronous) {
      final String resultType = method.returnType.isVoid
          ? 'void'
          : _arkTSTypeForDartType(method.returnType);
      argSignature.add('result: Result<$resultType>');
    }
    if (method.documentationComments.isNotEmpty) {
      addDocumentationComments(
        indent,
        method.documentationComments,
        _docCommentSpec,
      );
    } else {
      indent.newln();
    }
    indent.writeln(
      'abstract ${method.name}(${argSignature.join(', ')}): $returnType;',
    );
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
      '/** Error class for passing custom error details to Flutter via a thrown PlatformException. */',
    );
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
        'constructor(code: string, name: string, message: string, stack?: string) {',
      );
      indent.addScoped(null, '}', () {
        indent.writeln('this.code = code;');
        indent.writeln('this.name = name;');
        indent.writeln('this.message = message;');
        indent.writeln('this.stack = stack;');
      });
    });
  }

  void _writeWrapError(Indent indent) {
    indent.format('''
function wrapError(error: Error): Array<Object | null> {
\tlet errorList: Array<Object | null> = new Array<Object | null>(3);
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
    final bool hasHostApi = root.apis.whereType<AstHostApi>().any(
      (Api api) => api.methods.isNotEmpty,
    );

    indent.newln();
    _writeErrorClass(indent);

    if (hasHostApi) {
      indent.newln();
      _writeWrapError(indent);
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

  String? _arkTSTypeForProxyApiType(TypeDeclaration type) {
    // Host ProxyApi instances are user-defined classes (e.g. NativeEnumCounter);
    // the IDL name (e.g. EnumCounter) is not a compile-time ArkTS type.
    if (type.isProxyApi) {
      return 'ESObject';
    }
    return null;
  }

  String _arkTSTypeForDartType(TypeDeclaration type) {
    final String baseType;
    final String? builtin = _arkTSTypeForBuiltinDartType(type);
    if (builtin != null) {
      baseType = builtin;
    } else {
      final String? proxyApiType = _arkTSTypeForProxyApiType(type);
      if (proxyApiType != null) {
        baseType = proxyApiType;
      } else {
        baseType = type.baseName;
      }
    }
    if (type.isNullable) {
      return '$baseType | undefined';
    }
    return baseType;
  }

  /// Custom enum/class identifier for generated expressions (member lookup,
  /// companion types). Signatures use [_arkTSTypeForDartType] / [_arkTSTypeOrEsObject].
  String _arkTSCustomTypeName(TypeDeclaration type) => type.baseName;

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
      'Float32List': 'number[]',
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
    // Sealed (parent) classes are not serialized directly -- only their
    // concrete subclasses are -- so they are excluded from the codec's
    // enumerated custom types. This intentionally matches the Kotlin and Swift
    // generators (see writeGeneralCodec in kotlin_generator.dart /
    // swift_generator.dart), which pass the same flag to getEnumeratedTypes.
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
              'let wrap:$_overflowClassName = new $_overflowClassName();',
            );
            indent.writeln(
              'wrap.setType(${customType.enumeration - maximumCodecFieldKey});',
            );

            indent.writeln(
              'wrap.setWrapped($nullCheck(value as ${customType.name}).toList());',
            );
          }
          indent.writeln('stream.writeUint8(this.getByte($enumeration));');
          indent.writeln('this.writeValue(stream, $valueString);');
        }, addTrailingNewline: false);
      } else {
        indent.add(
          'if (value instanceof ${customType.name}$_enumCompanionSuffix) ',
        );
        indent.addScoped('{', '} else ', () {
          if (customType.enumeration >= maximumCodecFieldKey) {
            indent.writeln(
              'let wrap:$_overflowClassName = new $_overflowClassName();',
            );
            indent.writeln(
              'wrap.setType(${customType.enumeration - maximumCodecFieldKey});',
            );
            indent.writeln(
              'wrap.setWrapped($nullCheck((value as ${customType.name}$_enumCompanionSuffix).index));',
            );
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
            'return ${customType.name}.fromList(super.readValue(buffer) as Object[]);',
          );
        });
      } else if (customType.type == CustomTypes.customEnum) {
        indent.addScoped(' {', '}', () {
          indent.writeln('let value: Object= super.readValue(buffer);');
          indent.writeln(
            'return ${_intToEnum('value', customType.name, true)};',
          );
        });
      }
    }

    final overflowClass = EnumeratedType(
      _overflowClassName,
      maximumCodecFieldKey,
      CustomTypes.customClass,
    );

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
        'static readonly INSTANCE: $_codecName  = new $_codecName();',
      );
      indent.newln();
      _writeGetByteMethoe(indent);

      // When ProxyApi is present, PigeonProxyApiBaseCodec subclasses $_codecName
      // and must call super(); ArkTS forbids extending a class whose sole
      // constructor is private (arkts-subclassing-restrictions).
      final bool hasProxyApi = root.apis.any((Api api) => api is AstProxyApi);
      indent.writeScoped(
        hasProxyApi ? 'constructor() {' : 'private constructor() {',
        '}',
        () {
          indent.writeln('super();');
        },
      );
      indent.newln();
      indent.writeScoped(
        'readValueOfType(type: number,  buffer: ByteBuffer): ESObject {',
        '}',
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
        },
      );
      indent.newln();
      indent.write(
        'writeValue(stream: ByteBuffer , value: ESObject): ESObject',
      );
      indent.addScoped('{', '}', () {
        indent.write('');
        enumeratedTypes.forEach(writeEncodeLogic);
        indent.addScoped('{', '}', () {
          indent.writeln('super.writeValue(stream, value);');
        });
      });
    });
    indent.newln();
    if (root.containsEventChannel) {
      indent.writeln(
        'const PigeonMethodChannelCodec: StandardMethodCodec = new StandardMethodCodec($_codecName.INSTANCE);',
      );
      indent.newln();
    }
  }

  @override
  void writeEventChannelApi(
    InternalArkTSOptions generatorOptions,
    Root root,
    Indent indent,
    AstEventChannelApi api, {
    required String dartPackageName,
  }) {
    indent.newln();
    indent.format('''
/**
 * Internal [StreamHandler] that delegates to a [PigeonEventChannelWrapper].
 */
class PigeonStreamHandler<T> implements StreamHandler {
  private readonly wrapper: PigeonEventChannelWrapper<T>;
  private pigeonSink: PigeonEventSink<T> | null = null;

  constructor(wrapper: PigeonEventChannelWrapper<T>) {
    this.wrapper = wrapper;
  }

  onListen(args: Object, events: EventSink): void {
    this.pigeonSink = new PigeonEventSink<T>(events);
    this.wrapper.onListen(args, this.pigeonSink!);
  }

  onCancel(args: Object): void {
    this.pigeonSink = null;
    this.wrapper.onCancel(args);
  }
}

export interface PigeonEventChannelWrapper<T> {
  onListen(args: Object, sink: PigeonEventSink<T>): void;
  onCancel(args: Object): void;
}

export class PigeonEventSink<T> {
  private readonly sink: EventSink;

  constructor(sink: EventSink) {
    this.sink = sink;
  }

  success(value: T): void {
    this.sink.success(value);
  }

  error(errorCode: string, errorMessage: string | null, errorDetails: Object | null): void {
    this.sink.error(errorCode, errorMessage, errorDetails);
  }

  endOfStream(): void {
    this.sink.endOfStream();
  }
}
''');
    addDocumentationComments(
      indent,
      api.documentationComments,
      _docCommentSpec,
    );
    for (final Method func in api.methods) {
      final String returnType = _arkTSTypeForDartType(func.returnType);
      final String handlerName = toUpperCamelCase(func.name);
      indent.format('''
export abstract class ${handlerName}StreamHandler implements PigeonEventChannelWrapper<$returnType> {
  static register(binaryMessenger: BinaryMessenger, streamHandler: ${handlerName}StreamHandler, instanceName: string = ''): void {
    let channelName: string = '${makeChannelName(api, func, dartPackageName)}';
    if (instanceName !== '') {
      channelName += '.' + instanceName;
    }
    const internalStreamHandler: PigeonStreamHandler<$returnType> =
        new PigeonStreamHandler<$returnType>(streamHandler);
    const channel: EventChannel = new EventChannel(binaryMessenger, channelName, PigeonMethodChannelCodec);
    channel.setStreamHandler(internalStreamHandler);
  }

  onListen(args: Object, sink: PigeonEventSink<$returnType>): void {
  }

  onCancel(args: Object): void {
  }
}
''');
      indent.newln();
    }
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
      type: const TypeDeclaration(baseName: _forceInt, isNullable: false),
    );
    final overflowObject = NamedType(
      name: 'wrapped',
      type: const TypeDeclaration(baseName: 'Object', isNullable: true),
    );
    final overflowFields = <NamedType>[overflowInteration, overflowObject];
    final overflowClass = Class(
      name: _overflowClassName,
      fields: overflowFields,
    );

    _writeDataClassSignature(generatorOptions, indent, overflowClass, () {
      writeClassEncode(
        generatorOptions,
        root,
        indent,
        overflowClass,
        dartPackageName: dartPackageName,
      );

      indent.format('''
static fromList(list: Object[]): Object | null {
  const wrapper: $_overflowClassName = new $_overflowClassName();
  wrapper.setType(list[0] as number);
  wrapper.setWrapped(list[1]);
  return wrapper.unwrap();
}
''');

      indent.write('unwrap(): Object | null ');
      indent.addScoped('{', '}', () {
        indent.writeln(
          'if (this.wrapped === null || this.wrapped === undefined) {',
        );
        indent.nest(1, () {
          indent.writeln('return null;');
        });
        indent.writeScoped('switch (this.type) {', '}', () {
          for (int i = totalCustomCodecKeysAllowed; i < types.length; i++) {
            indent.writeln('case ${i - totalCustomCodecKeysAllowed}:');
            indent.nest(1, () {
              if (types[i].type == CustomTypes.customClass) {
                indent.writeln(
                  'return ${types[i].name}.fromList(this.wrapped as Object[]);',
                );
              } else if (types[i].type == CustomTypes.customEnum) {
                indent.writeln(
                  'return ${types[i].name}[this.wrapped as string];',
                );
              }
            });
          }
        });
        indent.writeln('return null;');
      });
    }, private: true);
  }

  // =====================================================================
  // ProxyApi support for HarmonyOS ArkTS.
  //
  // Implemented:
  //   * PigeonInstanceManager (WeakRef + FinalizationRegistry GC)
  //   * PigeonInstanceManagerApi (removeStrongReference / clear / cb)
  //   * PigeonProxyApiBaseCodec (tag 128 + pigeon_newInstance dispatch)
  //   * PigeonProxyApiRegistrar (per-engine coordinator, abstract)
  //   * PigeonApi<Name> adapters (constructors, fields, host/flutter methods)
  //   * ProxyApi inheritance/interface registrar getters
  //   * List<ProxyApi> typing via _arkTSTypeForProxyApiType
  //   * minApi recorded for IDL parity (not enforced on OHOS — see PigeonMinApi)
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
 * Memory management mirrors Kotlin/Swift: each instance is tracked with a
 * [WeakRef] and a strong reference. [remove] drops the strong reference; when
 * the weak reference is garbage collected, [FinalizationRegistry] notifies the
 * [finalizationListener]. [getIdentifierForStrongReference] re-creates a strong
 * reference when needed to pass an identifier to Dart.
 *
 * Thread safety: synchronous, single-threaded platform channel thread (see
 * Kotlin `InstanceManager` rationale).
 */
export class $_instanceManagerClassName {
  private static readonly minHostCreatedIdentifier: number = $_minHostCreatedIdentifier;

  private readonly weakInstances: Map<number, WeakRef<ESObject>> = new Map<number, WeakRef<ESObject>>();
  private readonly strongInstances: Map<number, ESObject> = new Map<number, ESObject>();
  private readonly finalizationRegistry: FinalizationRegistry<number>;
  private readonly instancesHeldForFinalization: Set<ESObject> = new Set<ESObject>();
  private nextIdentifier: number = $_instanceManagerClassName.minHostCreatedIdentifier;
  private finalizationListener: $_finalizationListenerInterfaceName | null = null;
  private finalizationListenerStopped: boolean = false;

  constructor() {
    this.finalizationRegistry = new FinalizationRegistry<number>((identifier: number) => {
      if (this.finalizationListenerStopped) {
        return;
      }
      if (this.strongInstances.has(identifier)) {
        return;
      }
      this.weakInstances.delete(identifier);
      if (this.finalizationListener !== null) {
        this.finalizationListener.onFinalize(identifier);
      }
    });
  }

  setFinalizationListener(listener: $_finalizationListenerInterfaceName | null): void {
    this.finalizationListener = listener;
  }

  stopFinalizationListener(): void {
    this.finalizationListenerStopped = true;
    this.instancesHeldForFinalization.forEach((instance: ESObject) => {
      this.finalizationRegistry.unregister(instance);
    });
    this.instancesHeldForFinalization.clear();
  }

  hasFinalizationListenerStopped(): boolean {
    return this.finalizationListenerStopped;
  }

  private findIdentifierForInstance(instance: ESObject): number | null {
    let found: number | null = null;
    this.strongInstances.forEach((strong: ESObject, identifier: number) => {
      if (found === null && strong === instance) {
        found = identifier;
      }
    });
    if (found !== null) {
      return found;
    }
    this.weakInstances.forEach((weakRef: WeakRef<ESObject>, identifier: number) => {
      if (found !== null) {
        return;
      }
      const deref: ESObject | undefined = weakRef.deref();
      if (deref !== undefined && deref === instance) {
        found = identifier;
      }
    });
    return found;
  }

  private addInstance(instance: ESObject, identifier: number): void {
    if (identifier < 0) {
      throw new Error('Identifier must be >= 0: ' + identifier);
    }
    if (this.weakInstances.has(identifier)) {
      throw new Error('Identifier has already been added: ' + identifier);
    }
    const weakRef: WeakRef<ESObject> = new WeakRef(instance);
    this.weakInstances.set(identifier, weakRef);
    this.strongInstances.set(identifier, instance);
    this.finalizationRegistry.register(instance, identifier, instance);
    this.instancesHeldForFinalization.add(instance);
  }

  addDartCreatedInstance(instance: ESObject, identifier: number): void {
    this.addInstance(instance, identifier);
  }

  addHostCreatedInstance(instance: ESObject): number {
    if (this.findIdentifierForInstance(instance) !== null) {
      throw new Error('Instance has already been added.');
    }
    const identifier: number = this.nextIdentifier++;
    this.addInstance(instance, identifier);
    return identifier;
  }

  getInstance(identifier: number): ESObject | null {
    const strong: ESObject | undefined = this.strongInstances.get(identifier);
    if (strong !== undefined) {
      return strong;
    }
    const weak: WeakRef<ESObject> | undefined = this.weakInstances.get(identifier);
    if (weak === undefined) {
      return null;
    }
    const deref: ESObject | undefined = weak.deref();
    return deref === undefined ? null : deref;
  }

  getIdentifierForStrongReference(instance: ESObject | null): number | null {
    if (instance === null || instance === undefined) {
      return null;
    }
    const identifier: number | null = this.findIdentifierForInstance(instance);
    if (identifier !== null) {
      this.strongInstances.set(identifier, instance);
    }
    return identifier;
  }

  containsInstance(instance: ESObject | null): boolean {
    if (instance === null || instance === undefined) {
      return false;
    }
    return this.findIdentifierForInstance(instance) !== null;
  }

  remove(identifier: number): ESObject | null {
    const instance: ESObject | undefined = this.strongInstances.get(identifier);
    if (instance === undefined) {
      return null;
    }
    this.strongInstances.delete(identifier);
    this.weakInstances.delete(identifier);
    this.instancesHeldForFinalization.delete(instance);
    this.finalizationRegistry.unregister(instance);
    return instance;
  }

  clear(): void {
    this.instancesHeldForFinalization.forEach((instance: ESObject) => {
      this.finalizationRegistry.unregister(instance);
    });
    this.instancesHeldForFinalization.clear();
    this.weakInstances.clear();
    this.strongInstances.clear();
  }

  getDebugInfo(): string {
    const idParts: string[] = [];
    this.weakInstances.forEach((_weakRef: WeakRef<ESObject>, identifier: number) => {
      idParts.push(identifier.toString());
    });
    const registeredIdentifiers: string = idParts.join(', ');
    return '$_instanceManagerClassName state: instanceCount='
      + this.weakInstances.size
      + ', strongCount=' + this.strongInstances.size
      + ', nextIdentifier=' + this.nextIdentifier
      + ', registeredIdentifiers=[' + registeredIdentifiers + ']';
  }
}

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
            let res: Array<Object | null> = [];
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
            let res: Array<Object | null> = [];
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

  // NOTE: despite the `writeProxyApiBaseCodec` name (fixed by the
  // StructuredGenerator hook), this only emits the ProxyApi *registrar*. The
  // base codec *class* ($_proxyApiBaseCodecClassName) is emitted later by
  // `_writeProxyApiBaseCodecClass` from `writeApis`, because ArkTS does not
  // hoist class declarations and it must appear after `$_codecName` (which it
  // extends). See the matching comment in `writeApis`.
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
 * No-op [Reply] for fire-and-forget InstanceManager callbacks.
 * ArkTS rejects untyped object literals for interface-typed parameters
 * (arkts-no-untyped-obj-literals).
 */
class PigeonNoOpVoidReply implements Reply<void> {
  reply(_value: void): void {
  }
}

class PigeonRegistrarFinalizationListener implements $_finalizationListenerInterfaceName {
  private readonly api: $_instanceManagerApiClassName;

  constructor(api: $_instanceManagerApiClassName) {
    this.api = api;
  }

  onFinalize(identifier: number): void {
    this.api.removeStrongReference(identifier, new PigeonNoOpVoidReply());
  }
}

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
    this.instanceManager.setFinalizationListener(new PigeonRegistrarFinalizationListener(api));
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
    this.ignoreCallsToDart = true;
    this.instanceManager.stopFinalizationListener();
    this.instanceManager.clear();
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
    indent.writeln('/**');
    indent.writeln(' * Codec extending `$_codecName` with ProxyApi instance');
    indent.writeln(' * references (tag $_proxyApiInstanceTag). Host-created');
    indent.writeln(
      ' * instances must be registered via `pigeon_newInstance` before encoding.',
    );
    indent.writeln(' */');
    indent.write(
      'export class $_proxyApiBaseCodecClassName extends $_codecName ',
    );
    indent.addScoped('{', '}', () {
      indent.writeln('registrar: $_proxyApiRegistrarClassName;');
      indent.newln();
      indent.write('constructor(registrar: $_proxyApiRegistrarClassName) ');
      indent.addScoped('{', '}', () {
        indent.writeln('super();');
        indent.writeln('this.registrar = registrar;');
      });
      indent.newln();
      indent.write(
        'override readValueOfType(type: number, buffer: ByteBuffer): ESObject ',
      );
      indent.addScoped('{', '}', () {
        indent.writeScoped('if (type === $_proxyApiInstanceTag) {', '}', () {
          indent.writeln(
            'const identifier: number = super.readValue(buffer) as number;',
          );
          indent.writeln(
            'const instance: ESObject | null = this.registrar.instanceManager.getInstance(identifier);',
          );
          indent.writeScoped('if (instance === null) {', '}', () {
            indent.writeln(
              "throw new Error('$_proxyApiBaseCodecClassName: instance not found for identifier ' + identifier + '. ' + this.registrar.instanceManager.getDebugInfo());",
            );
          });
          indent.writeln('return instance;');
        });
        indent.writeln('return super.readValueOfType(type, buffer);');
      });
      indent.newln();
      indent.write(
        'override writeValue(stream: ByteBuffer, value: ESObject): ESObject ',
      );
      indent.addScoped('{', '}', () {
        indent.writeScoped(
          'if (value === null || typeof value === \'boolean\' || typeof value === \'number\' || typeof value === \'string\' || Array.isArray(value) || value instanceof Map) {',
          '}',
          () {
            indent.writeln('return super.writeValue(stream, value);');
          },
        );
        indent.newln();
        indent.writeScoped(
          'if (this.registrar.instanceManager.containsInstance(value)) {',
          '}',
          () {
            indent.writeln(
              'const identifier: number | null = this.registrar.instanceManager.getIdentifierForStrongReference(value);',
            );
            indent.writeScoped('if (identifier === null) {', '}', () {
              indent.writeln(
                "throw new Error('$_proxyApiBaseCodecClassName: no identifier for registered instance. ' + this.registrar.instanceManager.getDebugInfo());",
              );
            });
            indent.writeln('stream.writeInt8($_proxyApiInstanceTag);');
            indent.writeln(
              'return this.writeValue(stream, identifier as Object);',
            );
          },
        );
        indent.newln();
        indent.writeln('return super.writeValue(stream, value);');
      });
    });
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
      if (api.hasCallbackConstructor()) {
        _writeProxyApiUnattachedFieldAbstractMethods(indent, api);
      }
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

      _writeProxyApiInheritedApiMethods(indent, api);

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

  void _writeProxyApiInheritedApiMethods(Indent indent, AstProxyApi api) {
    final inheritedApiNames = <String>{
      if (api.superClass != null) api.superClass!.baseName,
      ...api.interfaces.map((TypeDeclaration type) => type.baseName),
    };
    for (final name in inheritedApiNames) {
      final String hostName = '$hostProxyApiPrefix$name';
      indent.writeln(
        '/** An implementation of [$hostName] used to access callback methods. */',
      );
      indent.format('''
${classMemberNamePrefix}get$hostName(): $hostName {
  return this.pigeonRegistrar.get$name();
}
''');
      indent.newln();
    }
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

  // Unattached fields are plain (non-ProxyApi) values that Dart's callback-style
  // constructor expects. `pigeon_newInstance` reads each one from the host
  // instance via `this.<field>(pigeon_instance)`, so an abstract accessor must
  // be emitted for the host subclass to implement (mirrors the Kotlin
  // generator's `_writeProxyApiUnattachedFieldAbstractMethods`). Without this,
  // generated code would call a method that does not exist.
  void _writeProxyApiUnattachedFieldAbstractMethods(
    Indent indent,
    AstProxyApi api,
  ) {
    for (final ApiField field in api.unattachedFields) {
      addDocumentationComments(
        indent,
        field.documentationComments,
        _docCommentSpec,
      );
      indent.writeln(
        'abstract ${field.name}(${classMemberNamePrefix}instance: ESObject): ${_arkTSTypeOrEsObject(field.type)};',
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
            if (method.returnType.isEnum) {
              // Wrap the enum value in its codec companion before pushing
              // (matches the data-class toList enum handling).
              return 'let pigeonEnumResult: ESObject = $call; '
                  'let output: ESObject = ${_proxyApiEncodeEnum(method.returnType, 'pigeonEnumResult')}; '
                  'res.push(output);';
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
              // Type-safety contract (intentionally matches the regular HostApi
              // handler path and the Kotlin/Swift/Dart generators): the message
              // shape is validated structurally by the precheck below (it must
              // be a List of the expected arity), and individual argument types
              // are guaranteed by the typed Codec plus the matched generated
              // code on both sides. The `as` casts are NOT erasure like in
              // TypeScript -- ArkTS checks them at runtime and throws on a
              // mismatch, which the surrounding try/catch (sync handlers)
              // surfaces as a wrapped error reply. ProxyApi instance arguments
              // are resolved by the tag-128 codec, which throws if the
              // identifier is unknown. Per-parameter `typeof` checks are
              // therefore not emitted: they would diverge from every other
              // path, miss most types (enums/lists/maps/custom/instances), and
              // would have to assign null to non-nullable targets.
              _writeArkTsPigeonListMessagePrecheck(indent, parameters.length);
              for (var i = 0; i < parameters.length; i++) {
                final Parameter param = parameters[i];
                final safe = '${_proxyApiSafeName(i, param)}Arg';
                argNames.add(safe);
                if (param.type.isEnum) {
                  // The codec decodes an enum to its member-name string; convert
                  // back to the enum value the handler call expects. Held as
                  // ESObject to stay tolerant of null (nullable enums).
                  indent.writeln(
                    'let $safe: ESObject = ${_proxyApiDecodeEnum(param.type, 'args[$i]')};',
                  );
                } else {
                  indent.writeln(
                    'let $safe: ${_arkTSTypeOrEsObject(param.type)} = args[$i] as ${_arkTSTypeOrEsObject(param.type)};',
                  );
                }
              }
            }
            if (isAsync) {
              final String resultType = isVoid
                  ? 'void'
                  : _arkTSTypeOrEsObject(returnType);
              // Encode an enum result into its codec companion before replying
              // (matches the data-class toList enum handling).
              final String successPush = isVoid
                  ? 'null'
                  : (returnType.isEnum
                        ? _proxyApiEncodeEnum(returnType, 'result')
                        : 'result');
              indent.format('''
class ResultImp implements Result<$resultType> {
  success(result: $resultType): void {
    let res: Array<Object | null> = [];
    res.push($successPush);
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
              indent.writeln('let res: Array<Object | null> = [];');
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
    indent.writeln('/**');
    indent.writeln(
      ' * Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager.',
    );
    indent.writeln(' *');
    indent.writeln(
      ' * Any unattached field values are read synchronously from this host adapter via its',
    );
    indent.writeln(
      ' * own field methods (local calls, not channel round-trips) and are sent together with',
    );
    indent.writeln(
      ' * the identifier in a single newInstance message. Exactly one platform channel message',
    );
    indent.writeln(' * is sent regardless of the number of fields.');
    indent.writeln(' */');
    indent.write(
      '${classMemberNamePrefix}newInstance(pigeon_instance: ESObject, callback: Reply<void>): void ',
    );
    indent.addScoped('{', '}', () {
      indent.format('''
if (this.pigeonRegistrar.ignoreCallsToDart) {
  callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
  return;
}
if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
  callback.reply();
  return;
}''');
      if (api.hasCallbackConstructor()) {
        indent.format(
          '''
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
          final String argRef = '${field.name}Arg';
          sendParts.add(
            field.type.isEnum
                ? _proxyApiEncodeEnum(field.type, argRef)
                : argRef,
          );
        }
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
    } else {
      callback.reply();
    }
  } else {
    callback.reply(new FlutterError('channel-error', 'Unable to establish connection on channel: ' + channelName + '.', '') as ESObject);
  }
});''');
      } else {
        indent.format(
          '''
callback.reply(new FlutterError('new-instance-error', 'Attempting to create a new Dart instance of ${api.name}, but the class has a nonnull callback method.', '') as ESObject);''',
        );
      }
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
      ...indexMap(method.parameters, (int i, NamedType arg) {
        final String argName = '${_proxyApiSafeName(i, arg)}Arg';
        // Enum arguments must travel as their codec companion, not the raw
        // enum value (matches the data-class toList enum handling).
        return arg.type.isEnum
            ? _proxyApiEncodeEnum(arg.type, argName)
            : argName;
      }),
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
      } else if (!method.returnType.isNullable) {
        // Non-null return: a null payload from Dart is a contract violation,
        // so surface it as a FlutterError (matches the Kotlin/Swift ProxyApi
        // generators and the regular FlutterApi path).
        final String replyExpr = method.returnType.isEnum
            ? '${_arkTSCustomTypeName(method.returnType)}[listReply[0] as string]'
            : 'listReply[0] as $returnType';
        indent.format('''
      if (listReply[0] == null) {
        callback.reply(new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '') as ESObject);
      } else {
        callback.reply($replyExpr);
      }''');
      } else {
        // Nullable return: decode an enum member-name string back to its value
        // when applicable (mirrors the data-class fromList enum handling).
        final String replyExpr = method.returnType.isEnum
            ? _proxyApiDecodeEnum(method.returnType, 'listReply[0]')
            : 'listReply[0] as $returnType';
        indent.writeln('      callback.reply($replyExpr);');
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
    final String? proxyApiType = _arkTSTypeForProxyApiType(type);
    if (proxyApiType != null) {
      return proxyApiType;
    }
    // Enums and data classes have concrete ArkTS class names.
    if (type.isEnum || type.isClass) {
      if (type.isNullable) {
        return '${type.baseName} | undefined';
      }
      return type.baseName;
    }
    return 'ESObject';
  }

  String _proxyApiSafeName(int index, NamedType arg) {
    final String base = arg.name.isEmpty ? 'arg$index' : arg.name;
    return base == 'arguments' ? '${base}Var' : base;
  }

  /// Converts a codec-decoded enum (a member-name string) back to the enum
  /// value that generated signatures expect. [valueExpr] yields the raw value.
  /// Mirrors the data-class `fromList` enum handling (`Enum[str]`).
  String _proxyApiDecodeEnum(TypeDeclaration type, String valueExpr) {
    final String enumName = _arkTSCustomTypeName(type);
    return type.isNullable
        ? '($valueExpr == null ? null : $enumName[$valueExpr as string])'
        : '$enumName[$valueExpr as string]';
  }

  /// Wraps an enum value in its codec companion for encoding, with a null
  /// guard. [valueExpr] yields the enum value. Mirrors the data-class `toList`
  /// enum handling (`new <Enum>Enum(<Enum>[value as number])`). Always
  /// parenthesised so it is safe inside arrays / argument lists.
  String _proxyApiEncodeEnum(TypeDeclaration type, String valueExpr) {
    final String enumName = _arkTSCustomTypeName(type);
    return '($valueExpr === null || $valueExpr === undefined ? null '
        ': new $enumName$_enumCompanionSuffix($enumName[$valueExpr as number]))';
  }

  String _proxyApiParamSig(Parameter p) {
    return '${_proxyApiSafeName(0, p)}: ${_arkTSTypeOrEsObject(p.type)}';
  }
}
