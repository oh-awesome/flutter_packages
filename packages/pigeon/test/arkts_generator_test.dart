// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/arkts_generator.dart';
import 'package:pigeon/ast.dart';
import 'package:pigeon/generator_tools.dart';
import 'package:pigeon/pigeon_lib.dart';
import 'package:test/test.dart';

const String _defaultPackageName = 'test_package';

void main() {
  test('generates data class with nullable field slots', () {
    final Class classDefinition = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(baseName: 'int', isNullable: true),
          name: 'field1',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(code, contains('export class Foobar'));
    expect(code, contains('private field1?: number;'));
    expect(code, contains('toList(): Array<Object | null>'));
    expect(code, contains('arr.push(null);'));
    expect(code, contains('static fromList(arr: Object[]): Foobar'));
  });

  test('MessageData constructor and wire format align with Android', () {
    final Enum codeEnum = Enum(
      name: 'Code',
      members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'two'),
      ],
    );
    final Class classDefinition = Class(
      name: 'MessageData',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(baseName: 'String', isNullable: true),
          name: 'name',
        ),
        NamedType(
          type: const TypeDeclaration(baseName: 'String', isNullable: true),
          name: 'description',
        ),
        NamedType(
          type: const TypeDeclaration(baseName: 'Code', isNullable: false),
          name: 'code',
        ),
        NamedType(
          type: const TypeDeclaration(
            baseName: 'Map',
            isNullable: false,
            typeArguments: <TypeDeclaration>[
              TypeDeclaration(baseName: 'String', isNullable: false),
              TypeDeclaration(baseName: 'String', isNullable: false),
            ],
          ),
          name: 'data',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[codeEnum],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(code, contains('private code: Code;'));
    expect(code, contains('private name?: string;'));
    expect(
      code,
      contains(
        'constructor(code: Code, data: Map<string, string>, name?: string, description?: string)',
      ),
    );
    expect(
      code,
      contains(
        'const code: Code = arr[2] as number as Code;',
      ),
    );
    expect(code, contains('let name: string | undefined = undefined;'));
    expect(
      code,
      contains('return new MessageData(code, data, name, description);'),
    );
  });

  test('messageChannelSuffix on HostApi and FlutterApi', () {
    final Api hostApi = Api(
      name: 'Host',
      location: ApiLocation.host,
      methods: <Method>[
        Method(
          name: 'ping',
          returnType:
              const TypeDeclaration(baseName: 'String', isNullable: false),
          arguments: <NamedType>[],
        ),
      ],
    );
    final Api flutterApi = Api(
      name: 'FlutterSide',
      location: ApiLocation.flutter,
      methods: <Method>[
        Method(
          name: 'pong',
          returnType:
              const TypeDeclaration(baseName: 'void', isNullable: false),
          arguments: <NamedType>[],
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[hostApi, flutterApi],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(
      code,
      contains(
        'static setup(binaryMessenger: BinaryMessenger, api: Host | null, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(
      code,
      contains(
        'constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(code, contains('this.messageChannelSuffix'));
    expect(code, contains('separatedMessageChannelSuffix'));
  });

  test('FlutterApi nullable number return uses undefined for absent values', () {
    final Api flutterApi = Api(
      name: 'FlutterSide',
      location: ApiLocation.flutter,
      methods: <Method>[
        Method(
          name: 'readCount',
          returnType:
              const TypeDeclaration(baseName: 'int', isNullable: true),
          arguments: <NamedType>[],
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[flutterApi],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(
      code,
      contains(
        'let output: number | undefined = channelReply == null || channelReply === undefined ? undefined : channelReply as number;',
      ),
    );
  });

  test('Float32List maps to number[]', () {
    final Class classDefinition = Class(
      name: 'FloatHolder',
      fields: <NamedType>[
        NamedType(
          type:
              const TypeDeclaration(baseName: 'Float32List', isNullable: false),
          name: 'values',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    expect(sink.toString(), contains('private values: number[];'));
  });

  test('host api method signatures and handlers use consistent spacing', () {
    final Root root = Root(
      apis: <Api>[
        Api(
          name: 'Api',
          location: ApiLocation.host,
          methods: <Method>[
            Method(
              name: 'add',
              returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
              arguments: <NamedType>[
                NamedType(
                  name: 'a',
                  type: const TypeDeclaration(baseName: 'int', isNullable: false),
                ),
                NamedType(
                  name: 'b',
                  type: const TypeDeclaration(baseName: 'int', isNullable: false),
                ),
              ],
            ),
            Method(
              name: 'sendMessage',
              isAsynchronous: true,
              arguments: <NamedType>[
                NamedType(
                  name: 'message',
                  type: const TypeDeclaration(
                    baseName: 'Input',
                    isNullable: false,
                  ),
                ),
              ],
              returnType: const TypeDeclaration(baseName: 'bool', isNullable: false),
            ),
          ],
        ),
      ],
      classes: <Class>[Class(name: 'Input', fields: <NamedType>[])],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(code, contains('abstract add(a: number, b: number): number;'));
    expect(code, contains('abstract sendMessage(message: Input, result: Result<boolean>): void;'));
    expect(code, contains('onMessage(message: Object, reply: Reply<Object>)'));
    expect(code, contains('success(result: T): void;'));
    expect(code, isNot(contains('number , b')));
  });

  test('double fields are boxed in toList and codec writeValue', () {
    final Class classDefinition = Class(
      name: 'AllTypes',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(baseName: 'double', isNullable: true),
          name: 'aDouble',
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(code, contains('export class PigeonInternalDoubleBox'));
    expect(
      code,
      contains(
        'arr.push((this.aDouble === null || this.aDouble === undefined ? null : new PigeonInternalDoubleBox(this.aDouble)));',
      ),
    );
  });

  test('double values are boxed for codec when sending to Dart', () {
    final Api hostApi = Api(
      name: 'Api',
      location: ApiLocation.host,
      methods: <Method>[
        Method(
          name: 'echoDouble',
          returnType: const TypeDeclaration(
            baseName: 'double',
            isNullable: false,
          ),
          arguments: <NamedType>[],
        ),
      ],
    );
    final Api flutterApi = Api(
      name: 'FlutterSide',
      location: ApiLocation.flutter,
      methods: <Method>[
        Method(
          name: 'setDouble',
          returnType: TypeDeclaration.voidDeclaration(),
          arguments: <NamedType>[
            NamedType(
              type: const TypeDeclaration(
                baseName: 'double',
                isNullable: false,
              ),
              name: 'value',
            ),
          ],
        ),
      ],
    );
    final Root root = Root(
      apis: <Api>[hostApi, flutterApi],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    const ArkTSGenerator generator = ArkTSGenerator();
    generator.generate(
      const ArkTSOptions(),
      root,
      sink,
      dartPackageName: _defaultPackageName,
    );
    final String code = sink.toString();
    expect(code, contains('export class PigeonInternalDoubleBox'));
    expect(code, contains('class ApiCodec extends StandardMessageCodec'));
    expect(code, contains('res.push(new PigeonInternalDoubleBox(output));'));
    expect(code, contains('[new PigeonInternalDoubleBox(valueArg)]'));
    expect(code, contains('if (value instanceof PigeonInternalDoubleBox)'));
    expect(code, contains('this.writeAlignment(stream, 8);'));
    expect(
      code,
      contains(
        'stream.writeFloat64((value as PigeonInternalDoubleBox).value, true);',
      ),
    );
  });
}
