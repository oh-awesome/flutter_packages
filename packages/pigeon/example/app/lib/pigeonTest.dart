import 'package:pigeon/pigeon.dart';

// Regenerate from example/app: dart run pigeon --input lib/pigeonTest.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon_test.g.dart',
  dartOptions: DartOptions(),
  arkTSOut: 'ohos/entry/src/main/ets/plugins/PigeonTest.ets',
  arkTSOptions: ArkTSOptions(),
  copyrightHeader: 'pigeons/copyright.txt',
))

enum Identity { student, teacher }

/// ProxyApi device-test enum (distinct from HostApi [Identity]).
enum ProxyRole { admin, guest }

class Person {
  Person({required this.name, required this.age, required this.identity});
  String name;
  int age;
  Identity identity;
}

class Student {
  Student({required this.name, required this.age});
  String name;
  int age;
}

@HostApi()
abstract class DemoHostApi {
  Object? sendNull(Object? data);

  bool sendTrue(bool data);

  bool sendFalse(bool data);

  int sendInt(int data);

  double sendDouble(double data);

  String sendString(String data);

  Uint8List sendUint8List(Uint8List data);

  Int32List sendInt32List(Int32List data);

  Int64List sendInt64List(Int64List data);

  // Float32List sendFloat32List(Float32List data);

  Float64List sendFloat64List(Float64List data);

  List<String> sendList(List<String> data);

  Map<String, String> sendMap(Map<String, String> data);

  Student sendCustomClass(Student data);

  Person sendNestedDatatype(Person data);

  Identity sendEnum(Identity data);

  Identity? sendNullableEnum(Identity? data);

  @async
  Identity sendAsyncEnum(Identity data);

  /// Platform invokes Flutter [platformEchoEnum] (enum in/out over FlutterApi).
  @async
  Identity triggerPlatformEchoEnum(Identity data);

  /// Platform invokes Flutter [platformEchoNullableEnum] (nullable enum both ways).
  @async
  Identity? triggerPlatformEchoNullableEnum(Identity? data);

  String flutterInvokeSync();

  @async
  String flutterInvokeAsync();

  @async
  String errorHandling();

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String taskQueueTest();

  /// Platform calls Flutter [DemoFlutterApi.platformInvokeSync].
  @async
  String triggerPlatformInvokeSync();

  /// Platform calls Flutter [DemoFlutterApi.platformInvokeAsync].
  @async
  String triggerPlatformInvokeAsync();

  /// Host creates [HostEnumCounter] and runs enum echo (pigeon_newInstance, echoRole,
  /// flutterEchoNullableRole).
  @async
  String proxyApiHostCreateAndEcho();
}

/// Host-created ProxyApi: no required Flutter callback; Dart registers pigeon_newInstance.
@ProxyApi()
abstract class HostEnumCounter {
  HostEnumCounter(int initial, ProxyRole role);

  /// Unattached enum field supplied by host getter during pigeon_newInstance.
  late ProxyRole storedRole;

  int increment(int by);

  int current();

  ProxyRole echoRole(ProxyRole value);

  ProxyRole? echoNullableRole(ProxyRole? value);

  /// Optional Flutter callback for nullable enum host→Dart path.
  late ProxyRole? Function(ProxyRole? value)? flutterEchoNullableRole;
}

/// Minimal ProxyApi: enum ctor args, unattached enum field, host echo, Flutter callbacks.
@ProxyApi()
abstract class EnumCounter {
  EnumCounter(int initial, ProxyRole role);

  late ProxyRole storedRole;

  int increment(int by);

  int current();

  ProxyRole echoRole(ProxyRole value);

  ProxyRole? echoNullableRole(ProxyRole? value);

  late ProxyRole Function(ProxyRole value) flutterEchoRole;

  late ProxyRole? Function(ProxyRole? value)? flutterEchoNullableRole;
}

@FlutterApi()
abstract class DemoFlutterApi {
  String platformInvokeSync();

  @async
  String platformInvokeAsync();

  Identity platformEchoEnum(Identity value);

  Identity? platformEchoNullableEnum(Identity? value);
}
