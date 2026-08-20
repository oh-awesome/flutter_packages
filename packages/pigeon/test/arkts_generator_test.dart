// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/src/ast.dart';
import 'package:pigeon/src/arkts/arkts_generator.dart';
import 'package:pigeon/src/generator_tools.dart';
import 'package:pigeon/src/types/task_queue.dart';
import 'package:test/test.dart';

const String DEFAULT_PACKAGE_NAME = 'test_package';

final Class emptyClass = Class(
  name: 'className',
  fields: <NamedType>[
    NamedType(
      name: 'namedTypeName',
      type: const TypeDeclaration(baseName: 'baseName', isNullable: false),
    ),
  ],
);

final Enum emptyEnum = Enum(
  name: 'enumName',
  members: <EnumMember>[EnumMember(name: 'enumMemberName')],
);

void main() {
  test('gen one class', () {
    final classDefinition = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
          type: const TypeDeclaration(baseName: 'int', isNullable: true),
          name: 'field1',
        ),
      ],
    );
    final root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
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
    expect(code, contains('private field1?: number;'));
    expect(code, contains('toList(): Array<Object | null>'));
    expect(code, contains('static fromList(arr: Object[]): Foobar'));
  });

  test('data class distinguishes required and nullable fields', () {
    final codeEnum = Enum(
      name: 'Code',
      members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'two'),
      ],
    );
    final classDefinition = Class(
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
          type: TypeDeclaration(
            baseName: 'Code',
            associatedEnum: codeEnum,
            isNullable: false,
          ),
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
    final root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[codeEnum],
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
    final collapsed = code.replaceAll(RegExp(r'\s+'), ' ');

    expect(code, contains('private name?: string;'));
    expect(code, contains('private description?: string;'));
    expect(code, contains('private code: Code;'));
    expect(code, contains('private data: Map<string, string>;'));
    expect(code, contains('getName(): string | undefined'));
    expect(code, contains('getCode(): Code'));
    expect(
      code,
      contains(
        'constructor(code: Code, data: Map<string, string>, name?: string, description?: string)',
      ),
    );
    expect(code, contains('public setName(name: string | undefined): void'));
    // Nullable fields guard before decode; required fields decode directly.
    expect(
      collapsed,
      contains(
        'let name: string | undefined = undefined; if (arr[0] !== null && arr[0] !== undefined) { let nameObject: Object = arr[0]; name = nameObject as string | undefined; }',
      ),
    );
    expect(
      collapsed,
      contains(
        'const codeStr: string = arr[2] as string; const code: Code = Code[codeStr];',
      ),
    );
    expect(
      collapsed,
      contains(
        'let dataObject: Object = arr[3]; const data: Map<string, string> = dataObject as Map<string, string>; return new MessageData(code, data, name, description);',
      ),
    );
    expect(collapsed, isNot(contains('string | undefined | undefined')));
  });

  test(
    'Dart String? field maps to omit-able constructor and nullable setter',
    () {
      final root = Root(
        apis: <Api>[],
        classes: <Class>[
          Class(
            name: 'Record',
            fields: <NamedType>[
              NamedType(
                name: 'id',
                type: const TypeDeclaration(baseName: 'int', isNullable: false),
              ),
              NamedType(
                name: 'label',
                type: const TypeDeclaration(
                  baseName: 'String',
                  isNullable: true,
                ),
              ),
            ],
          ),
        ],
        enums: <Enum>[],
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

      // Dart `{this.label}` for `String? label`: omit-able + nullable.
      expect(code, contains('constructor(id: number, label?: string)'));
      expect(code, contains('private label?: string;'));
      expect(code, contains('getLabel(): string | undefined'));
      expect(
        code,
        contains('public setLabel(label: string | undefined): void'),
      );
    },
  );

  test('nullable enum fromList local uses single | undefined', () {
    final testEnum = Enum(
      name: 'TestEnum',
      members: <EnumMember>[EnumMember(name: 'head')],
    );
    final classDefinition = Class(
      name: 'WithEnum',
      fields: <NamedType>[
        NamedType(
          type: TypeDeclaration(
            baseName: 'TestEnum',
            associatedEnum: testEnum,
            isNullable: true,
          ),
          name: 'head',
        ),
      ],
    );
    final root = Root(
      apis: <Api>[],
      classes: <Class>[classDefinition],
      enums: <Enum>[testEnum],
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
    final collapsed = code.replaceAll(RegExp(r'\s+'), ' ');

    expect(code, contains('constructor(head?: TestEnum)'));
    expect(
      collapsed,
      contains(
        'let head: TestEnum | undefined = undefined; if (arr[0] !== null && arr[0] !== undefined) { const headStr: string = arr[0] as string; head = TestEnum[headStr]; }',
      ),
    );
    expect(collapsed, isNot(contains('TestEnum | undefined | undefined')));
  });

  test('nullable Dart types map to ArkTS optional semantics by API kind', () {
    final identity = Enum(
      name: 'Identity',
      members: <EnumMember>[EnumMember(name: 'student')],
    );
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'DemoHostApi',
          methods: <Method>[
            Method(
              name: 'sendNull',
              location: ApiLocation.host,
              returnType: const TypeDeclaration(
                baseName: 'Object',
                isNullable: true,
              ),
              parameters: <Parameter>[
                Parameter(
                  name: 'data',
                  type: const TypeDeclaration(
                    baseName: 'Object',
                    isNullable: true,
                  ),
                ),
              ],
            ),
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
        AstFlutterApi(
          name: 'DemoFlutterApi',
          methods: <Method>[
            Method(
              name: 'platformEchoNullableEnum',
              location: ApiLocation.flutter,
              returnType: TypeDeclaration(
                baseName: 'Identity',
                isNullable: true,
                associatedEnum: identity,
              ),
              parameters: <Parameter>[
                Parameter(
                  name: 'value',
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
      classes: <Class>[
        Class(
          name: 'MessageData',
          fields: <NamedType>[
            NamedType(
              name: 'code',
              type: const TypeDeclaration(baseName: 'int', isNullable: false),
            ),
            NamedType(
              name: 'name',
              type: const TypeDeclaration(baseName: 'String', isNullable: true),
            ),
          ],
        ),
      ],
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
    final collapsed = code.replaceAll(RegExp(r'\s+'), ' ');

    // Data class: nullable fields become omit-able constructor params (`?`).
    expect(code, contains('constructor(code: number, name?: string)'));
    expect(code, contains('public setName(name: string | undefined): void'));
    expect(code, isNot(contains('constructor(name?: string, code:')));

    // HostApi / FlutterApi: nullable means `| undefined` on the type; params are
    // still required at the call site (Pigeon always passes every slot).
    expect(
      code,
      contains(
        'abstract sendNull(data: Object | undefined ): Object | undefined;',
      ),
    );
    expect(
      code,
      contains(
        'abstract sendNullableEnum(data: Identity | undefined ): Identity | undefined;',
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
    expect(code, contains('index: string|null = null;'));
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
    expect(code, contains('abstract doSomething(: Input ): Output;'));
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
      contains('abstract doSomething(: Input , result: Result<Output>): void;'),
    );
    expect(code, contains('success( result: T ): void;'));
    expect(code, contains('error( error: Error): void;'));
    final collapsed = code.replaceAll(RegExp(r'\s+'), ' ');
    expect(collapsed, contains('try { api!.doSomething('));
    expect(
      collapsed,
      isNot(contains(
        'let resultCallback: Result<Output> = new ResultImp(); api!.doSomething(',
      )),
    );
    expect(
      collapsed,
      contains('} catch (error) { reply.reply(wrapError(error as Error)); }'),
    );
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
      contains('static readonly INSTANCE: PigeonCodec  = new PigeonCodec();'),
    );
    expect(
      code,
      contains('readValueOfType(type: number,  buffer: ByteBuffer): ESObject'),
    );
    expect(
      code,
      contains('writeValue(stream: ByteBuffer , value: ESObject): ESObject'),
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
        'abstract sendNullableEnum(data: Identity | undefined ): Identity | undefined;',
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
    );
  });

  test('messageChannelSuffix on HostApi and FlutterApi', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Host',
          methods: <Method>[
            Method(
              name: 'doit',
              location: ApiLocation.host,
              returnType: TypeDeclaration.voidDeclaration(),
              parameters: <Parameter>[],
            ),
          ],
        ),
        AstFlutterApi(
          name: 'Flutter',
          methods: <Method>[
            Method(
              name: 'callback',
              location: ApiLocation.flutter,
              returnType: TypeDeclaration.voidDeclaration(),
              parameters: <Parameter>[],
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsHostApi: true,
      containsFlutterApi: true,
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
        'static setup(binaryMessenger: BinaryMessenger, api: Host | null, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(code, contains('separatedMessageChannelSuffix'));
    expect(
      code,
      contains(
        'constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = \'\')',
      ),
    );
    expect(code, contains('this.messageChannelSuffix'));
  });

  test('TaskQueue serialBackgroundThread uses 3-arg BasicMessageChannel', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'doit',
              location: ApiLocation.host,
              returnType: TypeDeclaration.voidDeclaration(),
              parameters: <Parameter>[],
              taskQueueType: TaskQueueType.serialBackgroundThread,
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
    expect(code, isNot(contains('makeBackgroundTaskQueue()')));
    expect(code, contains('Api.getCodec())'));
  });

  test('EventChannelApi scaffold', () {
    final root = Root(
      apis: <Api>[
        AstEventChannelApi(
          name: 'Events',
          methods: <Method>[
            Method(
              name: 'streamInts',
              location: ApiLocation.host,
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: false,
              ),
              parameters: <Parameter>[],
            ),
          ],
        ),
      ],
      classes: <Class>[],
      enums: <Enum>[],
      containsEventChannel: true,
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
    expect(code, contains('import StandardMethodCodec'));
    expect(code, contains('EventChannel'));
    expect(code, contains('PigeonMethodChannelCodec'));
    expect(code, contains('StreamIntsStreamHandler'));
    expect(code, contains('static register(binaryMessenger: BinaryMessenger'));
  });

  test('Float32List maps to number[]', () {
    final root = Root(
      apis: <Api>[
        AstHostApi(
          name: 'Api',
          methods: <Method>[
            Method(
              name: 'send',
              location: ApiLocation.host,
              returnType: const TypeDeclaration(
                baseName: 'Float32List',
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
    const generator = ArkTSGenerator();
    generator.generate(
      const InternalArkTSOptions(arkTSOut: ''),
      root,
      sink,
      dartPackageName: DEFAULT_PACKAGE_NAME,
    );
    final code = sink.toString();
    expect(code, contains('send(): number[]'));
  });
}
