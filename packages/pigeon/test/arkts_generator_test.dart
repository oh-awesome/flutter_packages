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
<<<<<<< HEAD
      contains('return new MessageData(code, data, name, description);'),
=======
      contains(
        'abstract sendNullableEnum(data: Identity | undefined): Identity | undefined;',
      ),
    );
    expect(
      code,
      contains(
        'platformEchoNullableEnum(valueArg: Identity | undefined, callback: Reply<Identity | undefined>)',
      ),
    );
    expect(collapsed, isNot(contains('sendNull(data?:')));
    expect(collapsed, isNot(contains('sendNullableEnum(data?:')));
    expect(collapsed, isNot(contains('platformEchoNullableEnum(valueArg?:')));
  });

  test('gen one enum', () {
    final anEnum = Enum(
      name: 'Foobar',
      members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'twoThreeFour'),
        EnumMember(name: 'remoteDB'),
      ],
    );
    final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[anEnum]);
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export enum Foobar'));
    expect(code, contains('ONE,'));
    expect(code, contains('TWO_THREE_FOUR,'));
    expect(code, contains('REMOTE_DB'));
    expect(code, contains('export class FoobarEnum'));
    expect(code, contains('index: string | null = null;'));
    expect(code, contains('constructor(index: string) {'));
    expect(code, isNot(contains('string|null')));
    expect(code, isNot(contains('constructor(index: string){')));
  });

  test('gen one host api', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.host,
              parameters: <Parameter>[
                Parameter(
                  type: TypeDeclaration(
                    baseName: 'Input',
                    associatedClass: emptyClass,
                    isNullable: false,
                  ),
                  name: '',
                ),
              ],
              returnType: TypeDeclaration(
                baseName: 'Output',
                associatedClass: emptyClass,
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[
        Class(
          name: 'Input',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'input',
            ),
          ],
        ),
        Class(
          name: 'Output',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'output',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export abstract class Api'));
    expect(code, contains('abstract doSomething(: Input): Output;'));
    expect(
      code,
      contains(
        'static setup(binaryMessenger: BinaryMessenger, api: Api | null, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(code, contains('channel.setMessageHandler(null)'));
    expect(code, contains('class PigeonCodec extends StandardMessageCodec'));
  });

  test('gen one flutter api', () {
    final root = Root(
      apis: <Api>[
        AstFlutterApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.flutter,
              parameters: <Parameter>[
                Parameter(
                  type: TypeDeclaration(
                    baseName: 'Input',
                    associatedClass: emptyClass,
                    isNullable: false,
                  ),
                  name: 'input',
                ),
              ],
              returnType: TypeDeclaration(
                baseName: 'Output',
                associatedClass: emptyClass,
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[
        Class(
          name: 'Input',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'input',
            ),
          ],
        ),
        Class(
          name: 'Output',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'output',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class Api'));
    expect(code, contains('binaryMessenger: BinaryMessenger;'));
    expect(
      code,
      contains(
        'constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(code, contains('doSomething'));
    expect(code, contains('Input'));
    expect(code, contains('Output'));
    expect(code, contains('static getCodec(): MessageCodec<Object>'));
  });

  test('gen host void api', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.host,
              parameters: <Parameter>[],
              returnType: const TypeDeclaration.voidDeclaration(),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('abstract doSomething(): void;'));
  });

  test('gen flutter void return api', () {
    final root = Root(
      apis: <Api>[
        AstFlutterApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.flutter,
              parameters: <Parameter>[
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'String',
                    isNullable: false,
                  ),
                  name: 'input',
                ),
              ],
              returnType: const TypeDeclaration.voidDeclaration(),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('doSomething'));
    expect(code, contains('callback: Reply<void>'));
  });

  test('gen host void argument api', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.host,
              parameters: <Parameter>[],
              returnType: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('abstract doSomething(): string;'));
  });

  test('gen flutter void argument api', () {
    final root = Root(
      apis: <Api>[
        AstFlutterApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.flutter,
              parameters: <Parameter>[],
              returnType: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('doSomething(callback: Reply<string>)'));
  });

  test('gen list', () {
    final root = Root(
      apis: <Api>[],
      classes: <Class>[
        Class(
          name: 'Foobar',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'List', isNullable: true),
              name: 'field1',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class Foobar'));
    expect(code, contains('private field1?: Array<Object>;'));
  });

  test('gen map', () {
    final root = Root(
      apis: <Api>[],
      classes: <Class>[
        Class(
          name: 'Foobar',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'Map', isNullable: true),
              name: 'field1',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class Foobar'));
    expect(code, contains('private field1?: Map<Object, Object>;'));
  });

  test('gen nested', () {
    final classDefinition = Class(
      name: 'Outer',
      fields: <NamedType>[
        NamedType(
          type: TypeDeclaration(
            baseName: 'Nested',
            associatedClass: emptyClass,
            isNullable: true,
          ),
          name: 'nested',
        ),
      ],
    );
    final nestedClass = Class(
      name: 'Nested',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(baseName: 'int', isNullable: true),
          name: 'data',
        ),
      ],
    );
    final root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition, nestedClass],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class Outer'));
    expect(code, contains('export class Nested'));
    expect(code, contains('private nested?: Nested;'));
    expect(code, contains('private data?: number;'));
  });

  test('gen one async Host Api', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.host,
              parameters: <Parameter>[
                Parameter(
                  type: TypeDeclaration(
                    baseName: 'Input',
                    associatedClass: emptyClass,
                    isNullable: false,
                  ),
                  name: '',
                ),
              ],
              returnType: TypeDeclaration(
                baseName: 'Output',
                associatedClass: emptyClass,
                isNullable: false,
              ),
              isAsynchronous: true,
            ),
          ],
        ),
      ],
      classes: <Class>[
        Class(
          name: 'Input',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'input',
            ),
          ],
        ),
        Class(
          name: 'Output',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'output',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export interface Result<T>'));
    expect(
      code,
      contains('abstract doSomething(: Input, result: Result<Output>): void;'),
    );
    expect(code, contains('success(result: T): void;'));
    expect(code, contains('error(error: Error): void;'));
  });

  test('gen one async Flutter Api', () {
    final root = Root(
      apis: <Api>[
        AstFlutterApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.flutter,
              parameters: <Parameter>[
                Parameter(
                  type: TypeDeclaration(
                    baseName: 'Input',
                    associatedClass: emptyClass,
                    isNullable: false,
                  ),
                  name: 'input',
                ),
              ],
              returnType: TypeDeclaration(
                baseName: 'Output',
                associatedClass: emptyClass,
                isNullable: false,
              ),
              isAsynchronous: true,
            ),
          ],
        ),
      ],
      classes: <Class>[
        Class(
          name: 'Input',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'input',
            ),
          ],
        ),
        Class(
          name: 'Output',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'output',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('doSomething'));
    expect(code, contains('callback: Reply<Output>'));
  });

  test('gen one enum class', () {
    final anEnum = Enum(
      name: 'Foo',
      members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'two'),
      ],
    );
    final root = Root(
      apis: <Api>[],
      classes: <Class>[
        Class(
          name: 'Bar',
          fields: <NamedType>[
            NamedType(
              name: 'field1',
              type: TypeDeclaration(
                baseName: 'Foo',
                isNullable: false,
                associatedEnum: anEnum,
              ),
            ),
          ],
        ),
      ],
      enums: <Enum>[anEnum],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export enum Foo'));
    expect(code, contains('export class Bar'));
    expect(code, contains('private field1: Foo;'));
    expect(code, contains('constructor(field1: Foo)'));
    expect(code, contains('export class FooEnum'));
  });

  test('primitive enum host', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Bar',
          methods: <Method>[
            Method(
              name: 'bar',
              location: ApiLocation.host,
              returnType: const TypeDeclaration.voidDeclaration(),
              parameters: <Parameter>[
                Parameter(
                  name: 'foo',
                  type: TypeDeclaration(
                    baseName: 'Foo',
                    isNullable: false,
                    associatedEnum: emptyEnum,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[emptyEnum],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('abstract bar'));
    expect(code, contains('foo:'));
  });

  test('all the simple datatypes', () {
    final root = Root(
      apis: <Api>[],
      classes: <Class>[
        Class(
          name: 'Foobar',
          fields: <NamedType>[
            NamedType(
              type: const TypeDeclaration(baseName: 'bool', isNullable: true),
              name: 'aBool',
            ),
            NamedType(
              type: const TypeDeclaration(baseName: 'int', isNullable: true),
              name: 'aInt',
            ),
            NamedType(
              type: const TypeDeclaration(baseName: 'double', isNullable: true),
              name: 'aDouble',
            ),
            NamedType(
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
              name: 'aString',
            ),
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Uint8List',
                isNullable: true,
              ),
              name: 'aUint8List',
            ),
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Int32List',
                isNullable: true,
              ),
              name: 'aInt32List',
            ),
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Int64List',
                isNullable: true,
              ),
              name: 'aInt64List',
            ),
            NamedType(
              type: const TypeDeclaration(
                baseName: 'Float64List',
                isNullable: true,
              ),
              name: 'aFloat64List',
            ),
          ],
        ),
      ],
      enums: <Enum>[],
    );

    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('private aBool?: boolean;'));
    expect(code, contains('private aInt?: number;'));
    expect(code, contains('private aDouble?: number;'));
    expect(code, contains('private aString?: string;'));
    expect(code, contains('private aUint8List?: number[];'));
    expect(code, contains('private aInt32List?: number[];'));
    expect(code, contains('private aInt64List?: number[];'));
    expect(code, contains('private aFloat64List?: number[];'));
    expect(code, contains('export class PigeonInternalDoubleBox'));
    expect(
      code,
      contains(
        'arr.push((this.aDouble === null || this.aDouble === undefined ? null : new PigeonInternalDoubleBox(this.aDouble)));',
      ),
    );
    expect(code, contains('if (value instanceof PigeonInternalDoubleBox)'));
    expect(code, contains('this.writeAlignment(stream, 8);'));
    expect(
      code,
      contains(
        'stream.writeFloat64((value as PigeonInternalDoubleBox).value, true);',
      ),
    );
  });

  test('double values are boxed for codec when sending to Dart', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'echoDouble',
              location: ApiLocation.host,
              returnType: const TypeDeclaration(
                baseName: 'double',
                isNullable: false,
              ),
              parameters: <Parameter>[],
            ),
          ],
        ),
        AstFlutterApi(
          name: 'FlutterApi',
          methods: <Method>[
            Method(
              name: 'setDouble',
              location: ApiLocation.flutter,
              returnType: TypeDeclaration.voidDeclaration(),
              parameters: <Parameter>[
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'double',
                    isNullable: false,
                  ),
                  name: 'value',
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
    const generator = ArkTSGenerator();
    generator.generate(
      const InternalArkTSOptions(arkTSOut: ''),
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class PigeonInternalDoubleBox'));
    expect(
      code,
      contains('res.push(new PigeonInternalDoubleBox(output));'),
    );
    expect(code, contains('[new PigeonInternalDoubleBox(valueArg)]'));
    expect(code, contains('channelReply =>'));
  });

  test('host multiple args', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.host,
              parameters: <Parameter>[
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'String',
                    isNullable: false,
                  ),
                  name: 'arg1',
                ),
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: false,
                  ),
                  name: 'arg2',
                ),
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'bool',
                    isNullable: false,
                  ),
                  name: 'arg3',
                ),
              ],
              returnType: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('abstract doSomething(arg1: string'));
    expect(code, contains('arg2: number'));
    expect(code, contains('arg3: boolean'));
    expect(code, contains(': string;'));
  });

  test('flutter multiple args', () {
    final root = Root(
      apis: <Api>[
        AstFlutterApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doSomething',
              location: ApiLocation.flutter,
              parameters: <Parameter>[
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'String',
                    isNullable: false,
                  ),
                  name: 'arg1',
                ),
                Parameter(
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: false,
                  ),
                  name: 'arg2',
                ),
              ],
              returnType: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('doSomething'));
    expect(code, contains('arg1'));
    expect(code, contains('arg2'));
    expect(code, contains('callback: Reply<string>'));
  });

  test('copyright header', () {
    final classDefinition = Class(name: 'Foobar', fields: <NamedType>[]);
    final root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[],
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(
      arkTSOut: '',
      copyrightHeader: <String>['Copyright 2023', 'Test Header'],
    );
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('/*'));
    expect(code, contains('* Copyright 2023'));
    expect(code, contains('* Test Header'));
    expect(code, contains('*/'));
  });

  test('imports', () {
    final root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(
      code,
      contains(
        "import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';",
      ),
    );
    expect(
      code,
      contains(
        "import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';",
      ),
    );
    expect(
      code,
      contains(
        "import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';",
      ),
    );
    expect(
      code,
      contains(
        "import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';",
      ),
    );
    expect(
      code,
      contains(
        "import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';",
      ),
    );
  });

  test('codec class', () {
    final root = Root(
      apis: <Api>[AstHostApi(name: 'Api', methods: <Method>[])],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('class PigeonCodec extends StandardMessageCodec'));
    expect(
      code,
      contains('static readonly INSTANCE: PigeonCodec = new PigeonCodec();'),
    );
    expect(
      code,
      contains('readValueOfType(type: number, buffer: ByteBuffer): ESObject'),
    );
    expect(
      code,
      contains('writeValue(stream: ByteBuffer, value: ESObject): ESObject'),
    );
  });

  test('codec overflow utilities use ArkTS syntax', () {
    // Enums are enumerated before classes, so use 127 enums + 1 class to
    // force both enum and class decode paths into unwrap().
    final List<Enum> enums = List<Enum>.generate(
      totalCustomCodecKeysAllowed + 1,
      (int i) => Enum(
        name: 'OverflowEnum$i',
        members: <EnumMember>[EnumMember(name: 'one')],
      ),
    );
    final Class overflowClass = Class(
      name: 'OverflowClass',
      fields: <NamedType>[
        NamedType(
          name: 'value',
          type: const TypeDeclaration(baseName: 'int', isNullable: false),
        ),
      ],
    );
    final root = Root(
      apis: <Api>[AstHostApi(name: 'Api', methods: <Method>[])],
      classes: <Class>[overflowClass],
      enums: enums,
      containsHostApi: true,
    );
    expect(root.requiresOverflowClass, isTrue);

    final sink = StringBuffer();
    const generator = ArkTSGenerator();
    generator.generate(
      const InternalArkTSOptions(arkTSOut: ''),
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    final collapsed = code.replaceAll(RegExp(r'\s+'), ' ');

    expect(
      code,
      contains('private static final class PigeonInternalCodecOverflow'),
    );
    expect(
      collapsed,
      contains(
        'static fromList(list: Object[]): Object | null { const wrapper: PigeonInternalCodecOverflow = new PigeonInternalCodecOverflow(); wrapper.setType(list[0] as number); wrapper.setWrapped(list[1]); return wrapper.unwrap(); }',
      ),
    );
    expect(
      collapsed,
      contains(
        'case 0: return OverflowEnum${totalCustomCodecKeysAllowed}[this.wrapped as string];',
      ),
    );
    expect(
      collapsed,
      contains(
        'case 1: return OverflowClass.fromList(this.wrapped as Object[]);',
      ),
    );
    expect(code, isNot(contains('ArrayList<Object>')));
    expect(code, isNot(contains('@Nullable')));
    expect(code, isNot(contains('.values()')));
  });

  test('nullable custom enum types use | undefined in HostApi signatures', () {
    final identity = Enum(
      name: 'Identity',
      members: <EnumMember>[EnumMember(name: 'student')],
    );
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'sendNullableEnum',
              location: ApiLocation.host,
              returnType: TypeDeclaration(
                baseName: 'Identity',
                isNullable: true,
                associatedEnum: identity,
              ),
              parameters: <Parameter>[
                Parameter(
                  name: 'data',
                  type: TypeDeclaration(
                    baseName: 'Identity',
                    isNullable: true,
                    associatedEnum: identity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[identity],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const generator = ArkTSGenerator();
    generator.generate(
      const InternalArkTSOptions(arkTSOut: ''),
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(
      code,
      contains(
        'abstract sendNullableEnum(data: Identity | undefined): Identity | undefined;',
      ),
    );
  });

  test('error class', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'test',
              location: ApiLocation.host,
              returnType: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
              parameters: <Parameter>[],
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
    );
    final sink = StringBuffer();
    const arkTSOptions = InternalArkTSOptions(arkTSOut: '');
    const generator = ArkTSGenerator();
    generator.generate(
      arkTSOptions,
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('export class FlutterError implements Error'));
    expect(code, contains('public code: string;'));
    expect(code, contains('public name: string;'));
    expect(code, contains('public message: string;'));
    expect(
      code,
      contains('function wrapError(error: Error): Array<Object | null>'),
>>>>>>> 21f437ea3 (pigoen兼容浮点数的在Dart层传递的优化)
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
                  type: TypeDeclaration(
                    baseName: 'Input',
                    isNullable: false,
                    associatedClass: Class(name: 'Input', fields: <NamedType>[]),
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
}
