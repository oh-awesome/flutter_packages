// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on test/kotlin/proxy_api_test.dart, scoped to the MVP capabilities
// declared in doc/PROXYAPI_OHOS.md.

import 'package:pigeon/src/arkts/arkts_generator.dart';
import 'package:pigeon/src/ast.dart';
import 'package:test/test.dart';

const String DEFAULT_PACKAGE_NAME = 'test_package';

/// Collapse runs of whitespace so we can assert on patterns that span
/// multiple lines and indents (mirrors the helper used by
/// test/kotlin/proxy_api_test.dart).
String _collapseWhitespace(String code) {
  return code.replaceAll(RegExp(r'\s+'), ' ');
}

String _generate(Root root) {
  final sink = StringBuffer();
  const generator = ArkTSGenerator();
  generator.generate(
    const InternalArkTSOptions(arkTSOut: ''),
    root,
    sink,
    dartPackageName: DEFAULT_PACKAGE_NAME,
  );
  return sink.toString();
}

void main() {
  group('ProxyApi (HarmonyOS ArkTS)', () {
    test('emits InstanceManager, codec, registrar and per-API adapter', () {
      final root = Root(
        apis: <Api>[
          AstProxyApi(
            name: 'Api',
            constructors: <Constructor>[
              Constructor(name: '', parameters: <Parameter>[]),
            ],
            fields: <ApiField>[],
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
      );
      final code = _generate(root);

      // Core scaffolding.
      expect(code, contains('export class PigeonInstanceManager'));
      expect(code, contains('WeakRef<ESObject>'));
      expect(code, contains('FinalizationRegistry'));
      expect(code, contains('export interface PigeonFinalizationListener'));
      expect(code, contains('export class PigeonInstanceManagerApi'));
      expect(code, contains('export abstract class PigeonProxyApiRegistrar'));
      expect(
        code,
        contains('export class PigeonProxyApiBaseCodec extends PigeonCodec'),
      );

      // Per-ProxyApi class is abstract and depends on the registrar.
      expect(code, contains('export abstract class PigeonApiApi'));
      expect(code, contains('pigeonRegistrar: PigeonProxyApiRegistrar'));
    });

    group('Constructors', () {
      test('empty-name default constructor', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[
                Constructor(name: '', parameters: <Parameter>[]),
              ],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Default constructor is exposed under the pigeon_defaultConstructor
        // name and returns ESObject (host-side opaque instance).
        expect(
          collapsed,
          contains('abstract pigeon_defaultConstructor(): ESObject;'),
        );
        // The channel name is platform-stable and matches Kotlin/Swift.
        expect(
          collapsed,
          contains(
            '"dev.flutter.pigeon.test_package.Api.pigeon_defaultConstructor"',
          ),
        );
        // The setup handler routes the call back into the user-provided
        // constructor and stores the result in the InstanceManager.
        expect(
          collapsed,
          contains(
            'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.pigeon_defaultConstructor(), pigeon_identifierArg);',
          ),
        );
      });

      test('named constructor with multiple parameters', () {
        final anEnum = Enum(
          name: 'AnEnum',
          members: <EnumMember>[EnumMember(name: 'one')],
        );
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[
                Constructor(
                  name: 'named',
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'int',
                      ),
                      name: 'validType',
                    ),
                    Parameter(
                      type: TypeDeclaration(
                        isNullable: false,
                        baseName: 'AnEnum',
                        associatedEnum: anEnum,
                      ),
                      name: 'enumType',
                    ),
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: true,
                        baseName: 'int',
                      ),
                      name: 'nullableValidType',
                    ),
                  ],
                ),
              ],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[anEnum],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Signature: number / AnEnum / number for the three params.
        expect(
          collapsed,
          contains(
            'abstract named(validType: number, enumType: AnEnum, nullableValidType: number): ESObject;',
          ),
        );
        // Handler wires args into the named constructor.
        expect(
          collapsed,
          contains(
            'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.named(validTypeArg, enumTypeArg, nullableValidTypeArg), pigeon_identifierArg);',
          ),
        );
        // Channel name follows the standard pattern.
        expect(
          collapsed,
          contains('"dev.flutter.pigeon.test_package.Api.named"'),
        );
      });
    });

    group('Fields', () {
      test('instance attached field emits an accessor handler', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[
                ApiField(
                  name: 'aField',
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: false,
                  ),
                  isAttached: true,
                ),
              ],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        expect(
          collapsed,
          contains('abstract aField(pigeon_instance: ESObject): number;'),
        );
        expect(
          collapsed,
          contains('"dev.flutter.pigeon.test_package.Api.aField"'),
        );
        // Attached fields register the resulting value with the InstanceManager.
        expect(
          collapsed,
          contains(
            'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.aField(pigeon_instanceArg), pigeon_identifierArg);',
          ),
        );
      });

      test('static attached field omits the instance parameter', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[
                ApiField(
                  name: 'aStaticField',
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: false,
                  ),
                  isAttached: true,
                  isStatic: true,
                ),
              ],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        expect(collapsed, contains('abstract aStaticField(): number;'));
        // Static field handler calls api.<field>() without an instance arg.
        expect(
          collapsed,
          contains(
            'api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.aStaticField(), pigeon_identifierArg);',
          ),
        );
      });

      test(
        'unattached field emits an abstract accessor read by newInstance',
        () {
          final root = Root(
            apis: <Api>[
              AstProxyApi(
                name: 'Api',
                constructors: <Constructor>[
                  Constructor(name: '', parameters: <Parameter>[]),
                ],
                fields: <ApiField>[
                  ApiField(
                    name: 'aValue',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: false,
                    ),
                    isAttached: false,
                  ),
                ],
                methods: <Method>[],
              ),
            ],
            classes: <Class>[],
            enums: <Enum>[],
          );
          final code = _generate(root);
          final collapsed = _collapseWhitespace(code);

          // The accessor the host subclass must implement; without it the
          // newInstance call below would target a method that does not exist.
          expect(
            collapsed,
            contains('abstract aValue(pigeon_instance: ESObject): number;'),
          );
          // newInstance reads the unattached field value from the host instance
          // via that accessor before sending it to Dart.
          expect(
            collapsed,
            contains(
              'const aValueArg: ESObject = this.aValue(pigeon_instance);',
            ),
          );
        },
      );
    });

    group('Host methods', () {
      test('sync instance method with multiple params', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[
                Method(
                  name: 'doSomething',
                  location: ApiLocation.host,
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'int',
                      ),
                      name: 'first',
                    ),
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'String',
                      ),
                      name: 'second',
                    ),
                  ],
                  returnType: const TypeDeclaration(
                    isNullable: false,
                    baseName: 'bool',
                  ),
                ),
              ],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        expect(
          collapsed,
          contains(
            'abstract doSomething(pigeon_instance: ESObject, first: number, second: string): boolean;',
          ),
        );
        expect(
          collapsed,
          contains(
            'let output: ESObject = api!.doSomething(pigeon_instanceArg, firstArg, secondArg);',
          ),
        );
        expect(
          collapsed,
          contains('"dev.flutter.pigeon.test_package.Api.doSomething"'),
        );
      });

      test('static host method has no instance parameter', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[
                Method(
                  name: 'staticEcho',
                  location: ApiLocation.host,
                  isStatic: true,
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'int',
                      ),
                      name: 'value',
                    ),
                  ],
                  returnType: const TypeDeclaration(
                    isNullable: false,
                    baseName: 'int',
                  ),
                ),
              ],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        expect(
          collapsed,
          contains('abstract staticEcho(value: number): number;'),
        );
        expect(
          collapsed,
          contains('let output: ESObject = api!.staticEcho(valueArg);'),
        );
      });

      test('async host method takes a Result<T> callback', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[
                Method(
                  name: 'asyncEcho',
                  location: ApiLocation.host,
                  isAsynchronous: true,
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'int',
                      ),
                      name: 'value',
                    ),
                  ],
                  returnType: const TypeDeclaration(
                    isNullable: false,
                    baseName: 'int',
                  ),
                ),
              ],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Async signature appends a Result<T> trailing param.
        expect(
          collapsed,
          contains(
            'abstract asyncEcho(pigeon_instance: ESObject, value: number, result: Result<number>): void;',
          ),
        );
        // Handler builds a ResultImp that bridges success/error onto reply.reply.
        expect(
          collapsed,
          contains('class ResultImp implements Result<number>'),
        );
        expect(
          collapsed,
          contains(
            'api!.asyncEcho(pigeon_instanceArg, valueArg, resultCallback);',
          ),
        );
      });
    });

    group('Flutter methods', () {
      test('callback-style flutter method sends instance+args', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[
                Method(
                  name: 'flutterEchoString',
                  location: ApiLocation.flutter,
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'String',
                      ),
                      name: 'value',
                    ),
                  ],
                  returnType: const TypeDeclaration(
                    isNullable: false,
                    baseName: 'String',
                  ),
                ),
              ],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Flutter method is a concrete instance method with Reply<T> callback.
        expect(
          collapsed,
          contains(
            'flutterEchoString(pigeon_instance: ESObject, valueArg: string, callback: Reply<string>): void',
          ),
        );
        // The send list mirrors the signature, prepending the instance handle.
        expect(
          collapsed,
          contains('channel.send([pigeon_instance, valueArg],'),
        );
        expect(
          collapsed,
          contains("'dev.flutter.pigeon.test_package.Api.flutterEchoString'"),
        );
        // FlutterError fallback is emitted on connection failures.
        expect(collapsed, contains("new FlutterError('channel-error',"));
      });
    });

    group('pigeon_newInstance', () {
      test('honors ignoreCallsToDart and skips duplicate registration', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[
                Constructor(name: '', parameters: <Parameter>[]),
              ],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        expect(
          collapsed,
          contains(
            'pigeon_newInstance(pigeon_instance: ESObject, callback: Reply<void>): void',
          ),
        );
        expect(
          collapsed,
          contains('if (this.pigeonRegistrar.ignoreCallsToDart)'),
        );
        expect(
          collapsed,
          contains(
            'if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance))',
          ),
        );
        expect(
          collapsed,
          contains(
            'this.pigeonRegistrar.instanceManager.addHostCreatedInstance(pigeon_instance)',
          ),
        );
        expect(
          collapsed,
          contains("'dev.flutter.pigeon.test_package.Api.pigeon_newInstance'"),
        );
      });
    });

    group('InstanceManager / Codec', () {
      test('InstanceManager exposes the documented public surface', () {
        // Use any ProxyApi to trigger InstanceManager emission.
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        for (final method in <String>[
          'addDartCreatedInstance',
          'addHostCreatedInstance',
          'getInstance',
          'getIdentifierForStrongReference',
          'containsInstance',
          'remove',
          'clear',
        ]) {
          expect(
            collapsed,
            contains(method),
            reason: 'PigeonInstanceManager missing public method `$method`',
          );
        }
      });

      test(
        'PigeonInstanceManagerApi wires removeStrongReference / clear handlers',
        () {
          final root = Root(
            apis: <Api>[
              AstProxyApi(
                name: 'Api',
                constructors: <Constructor>[],
                fields: <ApiField>[],
                methods: <Method>[],
              ),
            ],
            classes: <Class>[],
            enums: <Enum>[],
          );
          final code = _generate(root);

          expect(
            code,
            contains(
              'dev.flutter.pigeon.test_package.PigeonInternalInstanceManager.removeStrongReference',
            ),
          );
          expect(
            code,
            contains(
              'dev.flutter.pigeon.test_package.PigeonInternalInstanceManager.clear',
            ),
          );
          // Flutter direction: removeStrongReference is callable from host.
          expect(
            code,
            contains(
              'removeStrongReference(identifierArg: number, callback: Reply<void>): void',
            ),
          );
        },
      );

      test('PigeonProxyApiBaseCodec implements tag 128 instance ref I/O', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Api',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
          ],
          classes: <Class>[],
          enums: <Enum>[],
        );
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Read path: tag 128 hands back the registered instance.
        expect(collapsed, contains('if (type === 128)'));
        expect(
          collapsed,
          contains('this.registrar.instanceManager.getInstance(identifier)'),
        );
        // Write path: instance refs are encoded as tag 128 + identifier.
        expect(collapsed, contains('stream.writeInt8(128);'));
        expect(
          collapsed,
          contains(
            'this.registrar.instanceManager.getIdentifierForStrongReference(value)',
          ),
        );
      });
    });

    group('Registrar', () {
      test('setUp / tearDown wires every ProxyApi adapter', () {
        final root = Root(
          apis: <Api>[
            AstProxyApi(
              name: 'Counter',
              constructors: <Constructor>[
                Constructor(name: '', parameters: <Parameter>[]),
              ],
              fields: <ApiField>[],
              methods: <Method>[],
            ),
            AstProxyApi(
              name: 'Logger',
              constructors: <Constructor>[],
              fields: <ApiField>[],
              methods: <Method>[
                Method(
                  name: 'log',
                  location: ApiLocation.host,
                  parameters: <Parameter>[
                    Parameter(
                      type: const TypeDeclaration(
                        isNullable: false,
                        baseName: 'String',
                      ),
                      name: 'msg',
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
        final code = _generate(root);
        final collapsed = _collapseWhitespace(code);

        // Abstract getters for every ProxyApi.
        expect(collapsed, contains('abstract getCounter(): PigeonApiCounter;'));
        expect(collapsed, contains('abstract getLogger(): PigeonApiLogger;'));

        // setUp() registers each adapter.
        expect(
          collapsed,
          contains(
            'PigeonApiCounter.setUpMessageHandlers(this.binaryMessenger, this.getCounter());',
          ),
        );
        expect(
          collapsed,
          contains(
            'PigeonApiLogger.setUpMessageHandlers(this.binaryMessenger, this.getLogger());',
          ),
        );

        // tearDown() removes each adapter.
        expect(
          collapsed,
          contains(
            'PigeonApiCounter.setUpMessageHandlers(this.binaryMessenger, null);',
          ),
        );
        expect(
          collapsed,
          contains(
            'PigeonApiLogger.setUpMessageHandlers(this.binaryMessenger, null);',
          ),
        );
      });
    });
  });
}
