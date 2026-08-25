// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, specify_nonobvious_local_variable_types

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/event_channel_messages.g.dart';
import 'src/messages.g.dart';
import 'src/pigeon_test.g.dart';

// #docregion main-dart-flutter
class _ExampleFlutterApi implements MessageFlutterApi {
  @override
  String flutterMethod(String? aString) {
    return aString ?? '';
  }
}

// #enddocregion main-dart-flutter

/// Platform-side reverse calls into Flutter ([DemoFlutterApi]).
class _DemoFlutterApiImpl implements DemoFlutterApi {
  @override
  String platformInvokeSync() {
    return 'platformInvokeSync from Flutter';
  }

  @override
  Future<String> platformInvokeAsync() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'platformInvokeAsync from Flutter';
  }

  @override
  Identity platformEchoEnum(Identity value) => value;

  @override
  Identity? platformEchoNullableEnum(Identity? value) => value;
}

/// Registers host→Dart ProxyApi handlers on the engine [BinaryMessenger] (OHOS).
void registerPigeonProxyApiHandlers() {
  final pigeonInstanceManager = PigeonInstanceManager.instance;
  final binaryMessenger = ServicesBinding.instance.defaultBinaryMessenger;
  HostEnumCounter.pigeon_setUpMessageHandlers(
    pigeon_clearHandlers: true,
    pigeon_binaryMessenger: binaryMessenger,
    pigeon_instanceManager: pigeonInstanceManager,
  );
  EnumCounter.pigeon_setUpMessageHandlers(
    pigeon_clearHandlers: true,
    pigeon_binaryMessenger: binaryMessenger,
    pigeon_instanceManager: pigeonInstanceManager,
  );
  HostEnumCounter.pigeon_setUpMessageHandlers(
    pigeon_binaryMessenger: binaryMessenger,
    pigeon_instanceManager: pigeonInstanceManager,
    flutterEchoNullableRole: (_, ProxyRole? value) => value,
  );
  EnumCounter.pigeon_setUpMessageHandlers(
    pigeon_binaryMessenger: binaryMessenger,
    pigeon_instanceManager: pigeonInstanceManager,
    flutterEchoRole: (_, ProxyRole value) => value,
    flutterEchoNullableRole: (_, ProxyRole? value) => value,
  );
}

// #docregion main-dart
final ExampleHostApi _api = ExampleHostApi();

/// Calls host method `add` with provided arguments.
Future<int> add(int a, int b) async {
  try {
    return await _api.add(a, b);
  } catch (e) {
    // handle error.
    return 0;
  }
}

/// Sends message through host api using `MessageData` class
/// and api `sendMessage` method.
Future<bool> sendMessage(String messageText) {
  final message = MessageData(
    code: Code.one,
    data: <String, String>{'header': 'this is a header'},
    messageDescription: 'uri text',
  );
  try {
    return _api.sendMessage(message);
  } catch (e) {
    // handle error.
    return Future<bool>(() => true);
  }
}

// #enddocregion main-dart

// #docregion main-dart-event
Stream<String> getEventStream() async* {
  final Stream<PlatformEvent> events = streamEvents();
  await for (final PlatformEvent event in events) {
    switch (event) {
      case IntEvent():
        final int intData = event.data;
        yield '$intData, ';
      case StringEvent():
        final String stringData = event.data;
        yield '$stringData, ';
    }
  }
}

// #enddocregion main-dart-event

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // #docregion main-dart-flutter
  MessageFlutterApi.setUp(_ExampleFlutterApi());
  // #enddocregion main-dart-flutter
  DemoFlutterApi.setUp(_DemoFlutterApiImpl());
  // PigeonInstanceManager._initInstance() may register handlers before messenger
  // is ready; wait before ProxyApi host-create tests.
  // ignore: unnecessary_statements
  PigeonInstanceManager.instance;
  await Future<void>.delayed(const Duration(milliseconds: 500));
  registerPigeonProxyApiHandlers();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pigeon Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pigeon Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DemoHostApi _hostApi = DemoHostApi();
  final ExampleHostApi _exampleApi = ExampleHostApi();

  /// Shown at startup; integration_test looks for `Hello from`.
  String? _hostLanguage;
  Object? _methodResult;

  @override
  void initState() {
    super.initState();
    _loadHostLanguage();
  }

  Future<void> _loadHostLanguage() async {
    String text;
    try {
      final lang = await _exampleApi.getHostLanguage();
      text = 'Hello from $lang';
    } catch (e) {
      text = 'Hello from <unknown> ($e)';
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _hostLanguage = text;
    });
  }

  Widget _btn(String label, Future<void> Function() onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: onTap, child: Text(label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              _hostLanguage ?? 'Hello from ...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (!kIsWeb)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<String>(
                  stream: getEventStream(),
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasError) {
                      return Text('EventChannel: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Text('EventChannel: ${snapshot.data}');
                  },
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  _btn('ExampleHostApi.add(1, 2)', _exampleAdd),
                  _btn('ExampleHostApi.sendMessage (success)', _exampleSendMessageSuccess),
                  _btn('ExampleHostApi.sendMessage (error)', _exampleSendMessageError),
                  _btn('sendNull', _sendNull),
                  _btn('sendTrue', _sendTrue),
                  _btn('sendFalse', _sendFalse),
                  _btn('sendInt', _sendInt),
                  //Send Double
                  _btn('sendDouble', _sendDouble),
                  // 验证 ArkTS 回传 1 / 1.0 时 Dart 侧能正确解析为 double
                  _btn('verifyIntegerShapedDoubles', _verifyIntegerShapedDoubles),
                  _btn('sendString', _sendString),
                  _btn('sendUint8List', _sendUint8List),
                  _btn('sendInt32List', _sendInt32List),
                  _btn('sendInt64List', _sendInt64List),
                  _btn('sendFloat64List', _sendFloat64List),
                  _btn('sendList', _sendList),
                  _btn('sendMap', _sendMap),
                  _btn('sendCustomClass', _sendCustomClass),
                  _btn('sendNestedDatatype', _sendNestedDatatype),
                  _btn('sendEnum', _sendEnum),
                  _btn('sendNullableEnum', _sendNullableEnum),
                  _btn('sendAsyncEnum', _sendAsyncEnum),
                  _btn('triggerPlatformEchoEnum', _triggerPlatformEchoEnum),
                  _btn(
                    'triggerPlatformEchoNullableEnum',
                    _triggerPlatformEchoNullableEnum,
                  ),
                  _btn('proxyApiDartFlow', _proxyApiDartFlow),
                  _btn('proxyApiHostCreate', _proxyApiHostCreate),
                  _btn('flutterInvokePlatformSyncMethod', _flutterInvokeSync),
                  _btn('flutterInvokePlatformAsyncMethod', _flutterInvokeAsync),
                  _btn('errorHandling', _errorHandling),
                  _btn('taskQueueTest', _taskQueueTest),
                  _btn('triggerPlatformInvokeSync', _triggerPlatformInvokeSync),
                  _btn('triggerPlatformInvokeAsync', _triggerPlatformInvokeAsync),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.blueGrey.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text('$_methodResult'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setResult(Object? value) {
    debugPrint('result: $value');
    setState(() {
      _methodResult = value;
    });
  }

  Future<void> _exampleAdd() async {
    final result = await add(1, 2);
    _setResult('ExampleHostApi.add(1, 2) = $result');
  }

  Future<void> _exampleSendMessageSuccess() async {
    try {
      final message = MessageData(
        code: Code.two,
        data: <String, String>{'header': 'this is a header'},
        messageDescription: 'uri text',
      );
      final result = await _exampleApi.sendMessage(message);
      _setResult('ExampleHostApi.sendMessage (success) = $result');
    } catch (e) {
      _setResult('ExampleHostApi.sendMessage (success) = $e');
    }
  }

  Future<void> _exampleSendMessageError() async {
    try {
      final message = MessageData(
        code: Code.one,
        data: <String, String>{'header': 'this is a header'},
        messageDescription: 'uri text',
      );
      await _exampleApi.sendMessage(message);
      _setResult('ExampleHostApi.sendMessage (error) unexpectedly succeeded');
    } catch (e) {
      _setResult('ExampleHostApi.sendMessage (error) = $e');
    }
  }

  Future<void> _sendNull() async {
    final result = await _hostApi.sendNull(null);
    _setResult('Received message: $result');
  }

  Future<void> _sendTrue() async {
    final result = await _hostApi.sendTrue(true);
    _setResult('Received message: $result');
  }

  Future<void> _sendFalse() async {
    final result = await _hostApi.sendFalse(false);
    _setResult('Received message: $result');
  }

  Future<void> _sendInt() async {
    final result = await _hostApi.sendInt(100);
    _setResult('Received message: $result');
  }

  Future<void> _sendDouble() async {
    final result = await _hostApi.sendDouble(123.456);
    _setResult('Received message: $result');
  }

  /// 验证 ArkTS 将整型形态的 number（如 1、1.0）回传给 Dart 时，
  /// 不会被 StandardMessageCodec 编码为 int，从而避免 `as double` 强转失败。
  Future<void> _verifyIntegerShapedDoubles() async {
    try {
      final double one = await _hostApi.sendDouble(1);
      final double onePointZero = await _hostApi.sendDouble(1.0);
      final bool ok = one is double && onePointZero is double;
      _setResult(
        ok
            ? 'verifyIntegerShapedDoubles OK: '
                '1 -> $one (${one.runtimeType}), '
                '1.0 -> $onePointZero (${onePointZero.runtimeType})'
            : 'verifyIntegerShapedDoubles FAIL: unexpected runtime types '
                '1 -> ${one.runtimeType}, 1.0 -> ${onePointZero.runtimeType}',
      );
    } catch (e, st) {
      _setResult('verifyIntegerShapedDoubles FAIL: $e\n$st');
    }
  }

  Future<void> _sendString() async {
    final result = await _hostApi.sendString('zhangsan');
    _setResult('Received message: $result');
  }

  Future<void> _sendUint8List() async {
    try {
      final result = await _hostApi.sendUint8List(Uint8List.fromList(<int>[1, 2, 3]));
      _setResult('Received message: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendInt32List() async {
    try {
      final result = await _hostApi.sendInt32List(Int32List.fromList(<int>[4, 5, 6]));
      _setResult('Received message: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendInt64List() async {
    try {
      final result = await _hostApi.sendInt64List(
        Int64List.fromList(<int>[9223372036854775807, 9223372036854775806, 9223372036854775805]),
      );
      _setResult('Received message: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendFloat64List() async {
    try {
      final result = await _hostApi.sendFloat64List(Float64List.fromList(<double>[12.3, 45.6, 78.9]));
      _setResult('Received message: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendList() async {
    final result = await _hostApi.sendList(<String>['zhangsan', 'lisi', 'zhangwu']);
    _setResult('Received message: $result');
  }

  Future<void> _sendMap() async {
    final result = await _hostApi.sendMap(<String, String>{'Name': 'zhangsan', 'Country': 'China'});
    _setResult('Received message: $result');
  }

  Future<void> _sendCustomClass() async {
    final student = await _hostApi.sendCustomClass(Student(name: 'zhangsan', age: 18));
    _setResult("Received message:Student{name='${student.name}', age=${student.age}}");
  }

  Future<void> _sendNestedDatatype() async {
    try {
      final person = await _hostApi.sendNestedDatatype(
        Person(name: 'lisi', age: 20, identity: Identity.teacher),
      );
      _setResult(
        "Received message:Person{name='${person.name}', age=${person.age}, identity=${person.identity}}",
      );
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendEnum() async {
    try {
      final result = await _hostApi.sendEnum(Identity.student);
      _setResult('Received message: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendNullableEnum() async {
    try {
      final r1 = await _hostApi.sendNullableEnum(Identity.teacher);
      final r2 = await _hostApi.sendNullableEnum(null);
      _setResult('sendNullableEnum: $r1 / null -> $r2');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _sendAsyncEnum() async {
    try {
      final result = await _hostApi.sendAsyncEnum(Identity.student);
      _setResult('sendAsyncEnum: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _triggerPlatformEchoEnum() async {
    try {
      final result = await _hostApi.triggerPlatformEchoEnum(Identity.teacher);
      _setResult('triggerPlatformEchoEnum (host<->flutter): $result');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _triggerPlatformEchoNullableEnum() async {
    try {
      final r1 = await _hostApi.triggerPlatformEchoNullableEnum(Identity.student);
      final r2 = await _hostApi.triggerPlatformEchoNullableEnum(null);
      _setResult('triggerPlatformEchoNullableEnum: $r1 / null -> $r2');
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _proxyApiDartFlow() async {
    try {
      final counter = EnumCounter(
        initial: 10,
        role: ProxyRole.admin,
        storedRole: ProxyRole.admin,
        flutterEchoRole: (_, ProxyRole value) => value,
        flutterEchoNullableRole: (_, ProxyRole? value) => value,
      );
      final afterInc = await counter.increment(5);
      final cur = await counter.current();
      final echoed = await counter.echoRole(ProxyRole.guest);
      final echoedNull = await counter.echoNullableRole(null);
      _setResult(
        'proxyApiDart: inc=$afterInc cur=$cur echo=$echoed nullEcho=$echoedNull',
      );
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _proxyApiHostCreate() async {
    try {
      final msg = await _hostApi.proxyApiHostCreateAndEcho();
      _setResult(msg);
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _flutterInvokeSync() async {
    final result = await _hostApi.flutterInvokeSync();
    _setResult(result);
  }

  Future<void> _flutterInvokeAsync() async {
    final result = await _hostApi.flutterInvokeAsync();
    _setResult(result);
  }

  Future<void> _errorHandling() async {
    try {
      await _hostApi.errorHandling();
    } catch (e) {
      _setResult(e);
    }
  }

  Future<void> _taskQueueTest() async {
    final result = await _hostApi.taskQueueTest();
    _setResult(result);
  }

  Future<void> _triggerPlatformInvokeSync() async {
    final result = await _hostApi.triggerPlatformInvokeSync();
    _setResult(result);
  }

  Future<void> _triggerPlatformInvokeAsync() async {
    final result = await _hostApi.triggerPlatformInvokeAsync();
    _setResult(result);
  }
}
