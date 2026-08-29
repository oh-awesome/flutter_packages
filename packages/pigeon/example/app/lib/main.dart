// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/messages.g.dart';
import 'src/pigeon_test.g.dart';

/// 平台侧反向调用 Flutter 时的应答实现。
class _ExampleFlutterApi implements DemoFlutterApi {
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

/// Registers host→Dart ProxyApi handlers on the engine [BinaryMessenger] (required on OHOS).
void registerPigeonProxyApiHandlers() {
  final pigeonInstanceManager = PigeonInstanceManager.instance;
  final binaryMessenger = ServicesBinding.instance.defaultBinaryMessenger;
  // Clear handlers that [_initInstance] may have registered with a null messenger.
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DemoFlutterApi.setUp(_ExampleFlutterApi());
  // PigeonInstanceManager._initInstance() fires native clear() without awaiting; wait
  // before host-create + host→Dart enum callback tests.
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

  /// 与上游 Flutter Pigeon 示例保持一致：启动时通过 ExampleHostApi.getHostLanguage()
  /// 拿到各端 native 实现里的语言名，并显示为 "Hello from {lang}"。
  /// 该字段同时被 integration_test/example_app_test.dart 用作断言锚点
  /// (`find.textContaining('Hello from')`)。
  final ExampleHostApi _exampleApi = ExampleHostApi();
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
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(top: 12.0),
      child: Center(
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
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _btn('sendNull', _sendNull),
                  //Send True
                  _btn('sendTrue', _sendTrue),
                  //Send False
                  _btn('sendFalse', _sendFalse),
                  //Send int
                  _btn('sendInt', _sendInt),
                  //Send Double
                  _btn('sendDouble', _sendDouble),
                  // 验证 ArkTS 回传 1 / 1.0 时 Dart 侧能正确解析为 double
                  _btn('verifyIntegerShapedDoubles', _verifyIntegerShapedDoubles),
                  //Send String
                  _btn('sendString', _sendString),
                  //Send Uint8List
                  _btn('sendUint8List', _sendUint8List),
                  //Send Int32List
                  _btn('sendInt32List', _sendInt32List),
                  //Send Int64List
                  _btn('sendInt64List', _sendInt64List),
                  //Send Float64List
                  _btn('sendFloat64List', _sendFloat64List),
                  //Send List
                  _btn('sendList', _sendList),
                  //Send Map
                  _btn('sendMap', _sendMap),
                  //Send Custom Class
                  _btn('sendCustomClass', _sendCustomClass),
                  //Send Nested Datatypes
                  _btn('sendNestedDatatype', _sendNestedDatatype),
                  //Send Enums
                  _btn('sendEnum', _sendEnum),
                  //Send nullable enum (sync, host return)
                  _btn('sendNullableEnum', _sendNullableEnum),
                  //Send async enum (host async enum return)
                  _btn('sendAsyncEnum', _sendAsyncEnum),
                  //FlutterApi enum round-trip (host<->flutter)
                  _btn('triggerPlatformEchoEnum', _triggerPlatformEchoEnum),
                  //FlutterApi nullable enum round-trip
                  _btn('triggerPlatformEchoNullableEnum',
                      _triggerPlatformEchoNullableEnum),
                  // ProxyApi：Dart 侧创建 EnumCounter + 枚举方法/回调
                  _btn('proxyApiDartFlow', _proxyApiDartFlow),
                  // ProxyApi：宿主创建 + pigeon_newInstance + Flutter 枚举回调
                  _btn('proxyApiHostCreate', _proxyApiHostCreate),
                  //Flutter invoking platform synchronous method
                  _btn('flutterInvokePlatformSyncMethod', _flutterInvokeSync),
                  //Flutter invoking platform asynchronous method
                  _btn('flutterInvokePlatformAsyncMethod', _flutterInvokeAsync),
                  //Error Handling
                  _btn('errorHandling', _errorHandling),
                  //Task Queue Test
                  _btn('taskQueueTest', _taskQueueTest),
                  //Platform invoking Flutter syncchronous method
                  _btn('triggerPlatformInvokeSync', _triggerPlatformInvokeSync),
                  //Plagform invoking Flutter asynchronous method
                  _btn(
                      'triggerPlatformInvokeAsync', _triggerPlatformInvokeAsync),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey.withOpacity(0.5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Text('$_methodResult'),
                ),
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

  // ===== Flutter -> Platform =====

  /// sendNull
  Future<void> _sendNull() async {
    final result = await _hostApi.sendNull(null);
    /// Received message: null
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendTrue
  Future<void> _sendTrue() async {
    final result = await _hostApi.sendTrue(true);
    /// Received message: true
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendFalse
  Future<void> _sendFalse() async {
    final result = await _hostApi.sendFalse(false);
    /// Received message: false
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendInt
  Future<void> _sendInt() async {
    final result = await _hostApi.sendInt(100);
    /// Received message: 
     String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendDouble
  Future<void> _sendDouble() async {
    final result = await _hostApi.sendDouble(123.456);
    /// Received message: 
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// 验证 ArkTS 将整型形态的 number（1、1.0）回传给 Dart 时，
  /// 不会被 StandardMessageCodec 编码为 int，从而避免 `as double` 强转失败。
  Future<void> _verifyIntegerShapedDoubles() async {
    try {
      final Object one = await _hostApi.sendDouble(1);
      final Object onePointZero = await _hostApi.sendDouble(1.0);
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

  /// sendString
  Future<void> _sendString() async {
    final result = await _hostApi.sendString('zhangsan');
    /// Received message: zhangsan
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendUint8List
  Future<void> _sendUint8List() async {
    final result = await _hostApi.sendUint8List(Uint8List.fromList([1, 2, 3]));
    /// Received message: [1, 2, 3]
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendInt32List
  Future<void> _sendInt32List() async {
    final result = await _hostApi.sendInt32List(Int32List.fromList([4, 5, 6]));
    /// Received message: 
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendInt64List：取 int64 边界附近的三个值，验证 64 位整数往返不丢精度。
  /// 实测鸿蒙 ArkTS + Pigeon 26.3.4 的 StandardMessageCodec 在 echo 透传场景下
  /// 能保留完整 int64 精度（底层用宽整数容器承载，未经过 IEEE-754 double 中转）。
  Future<void> _sendInt64List() async {
    final result = await _hostApi.sendInt64List(Int64List.fromList(
        [9223372036854775807, 9223372036854775806, 9223372036854775805]));
    /// Received message:   
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendFloat64List
  Future<void> _sendFloat64List() async {
    final result =
        await _hostApi.sendFloat64List(Float64List.fromList([12.3, 45.6, 78.9]));
    /// Received message:    
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendList
  Future<void> _sendList() async {
    final result = await _hostApi.sendList(['zhangsan', 'lisi', 'zhangwu']);
    /// Received message: 
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendMap
  Future<void> _sendMap() async {
    final result =
        await _hostApi.sendMap({'Name': 'zhangsan', 'Country': 'China'});
    /// Received message:  
    String resultStr = "Received message: $result";
    _setResult(resultStr);
  }

  /// sendCustomClass：自定义 Student 类型往返
  Future<void> _sendCustomClass() async {
    final student =
        await _hostApi.sendCustomClass(Student(name: 'zhangsan', age: 18));
    /// Received message:Student{name='zhangsan', age=18}  
    _setResult("Received message:Student{name='${student.name}', age=${student.age}}");
  }

  /// sendNestedDatatype：包含枚举字段的嵌套类型 Person 往返
  Future<void> _sendNestedDatatype() async {
    try {
      final person = await _hostApi.sendNestedDatatype(
          Person(name: 'lisi', age: 20, identity: Identity.teacher));
      /// Received message: Person{name='lisi', age=20, identity=teacher}  
      _setResult(
          "Received message:Person{name='${person.name}', age=${person.age}, identity=${person.identity}}");
    } catch (e) {
      _setResult(e);
    }
  }

  /// sendEnum
  Future<void> _sendEnum() async {
    try {
      final result = await _hostApi.sendEnum(Identity.student);
      /// Received message: Identity.student
      String resultStr = "Received message: $result";
      _setResult(resultStr);
    } catch (e) {
      _setResult(e);
    }
  }

  /// sendNullableEnum：同步可空枚举（传非空值与 null 各验一次）
  Future<void> _sendNullableEnum() async {
    try {
      final r1 = await _hostApi.sendNullableEnum(Identity.teacher);
      final r2 = await _hostApi.sendNullableEnum(null);
      _setResult('sendNullableEnum: $r1 / null -> $r2');
    } catch (e) {
      _setResult(e);
    }
  }

  /// sendAsyncEnum：异步枚举返回（验证 HostApi 异步枚举返回的伴侣包装）
  Future<void> _sendAsyncEnum() async {
    try {
      final result = await _hostApi.sendAsyncEnum(Identity.student);
      _setResult('sendAsyncEnum: $result');
    } catch (e) {
      _setResult(e);
    }
  }

  /// triggerPlatformEchoEnum：平台侧把枚举发给 Flutter 再收回（FlutterApi 枚举双向）
  Future<void> _triggerPlatformEchoEnum() async {
    try {
      final result = await _hostApi.triggerPlatformEchoEnum(Identity.teacher);
      _setResult('triggerPlatformEchoEnum (host<->flutter): $result');
    } catch (e) {
      _setResult(e);
    }
  }

  /// triggerPlatformEchoNullableEnum：FlutterApi 可空枚举双向（含 null 透传）
  Future<void> _triggerPlatformEchoNullableEnum() async {
    try {
      final r1 =
          await _hostApi.triggerPlatformEchoNullableEnum(Identity.student);
      final r2 = await _hostApi.triggerPlatformEchoNullableEnum(null);
      _setResult('triggerPlatformEchoNullableEnum: $r1 / null -> $r2');
    } catch (e) {
      _setResult(e);
    }
  }

  /// ProxyApi：Dart 创建 [EnumCounter]，走 increment/current/echoRole/可空枚举。
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

  /// ProxyApi：宿主创建 [HostEnumCounter]，走 pigeon_newInstance、echoRole、flutterEchoNullableRole。
  Future<void> _proxyApiHostCreate() async {
    try {
      final msg = await _hostApi.proxyApiHostCreateAndEcho();
      _setResult(msg);
    } catch (e) {
      _setResult(e);
    }
  }

  /// Flutter 调用平台侧同步方法
  Future<void> _flutterInvokeSync() async {
    final result = await _hostApi.flutterInvokeSync();
    _setResult(result);
  }

  /// Flutter 调用平台侧异步方法
  Future<void> _flutterInvokeAsync() async {
    final result = await _hostApi.flutterInvokeAsync();
    _setResult(result);
  }

  /// 平台侧主动抛出 FlutterError，验证错误能正确传回 Dart
  Future<void> _errorHandling() async {
    try {
      await _hostApi.errorHandling();
    } catch (e) {
      print("Unhandled Exceptoin: $e");
      _setResult(e);
    }
  }

  /// 验证 @TaskQueue(serialBackgroundThread) 注解：方法应在平台侧后台串行队列上执行
  Future<void> _taskQueueTest() async {
    final result = await _hostApi.taskQueueTest();
    _setResult(result);
  }

  // ===== Platform -> Flutter (由平台侧反向调用本进程 DemoFlutterApi) =====

  /// 触发平台侧反过来同步调用 Flutter 的 DemoFlutterApi.platformInvokeSync
  Future<void> _triggerPlatformInvokeSync() async {
    final result = await _hostApi.triggerPlatformInvokeSync();
    _setResult(result);
  }

  /// 触发平台侧反过来异步调用 Flutter 的 DemoFlutterApi.platformInvokeAsync
  Future<void> _triggerPlatformInvokeAsync() async {
    final result = await _hostApi.triggerPlatformInvokeAsync();
    _setResult(result);
  }
}
