import 'package:pigeon/pigeon.dart';

// 生成命令（在 example/app 目录下执行）：
//   dart run pigeon --input lib/pigeonTest.dart
// 同步生成：lib/src/pigeon_test.g.dart、ohos/entry/src/main/ets/plugins/PigeonTest.ets
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon_test.g.dart',
  dartOptions: DartOptions(),
  arkTSOut: 'ohos/entry/src/main/ets/plugins/PigeonTest.ets',
  arkTSOptions: ArkTSOptions(),
))

// 枚举
enum Identity { student, teacher }

/// ProxyApi 真机验证用枚举（与 HostApi 的 [Identity] 区分）。
enum ProxyRole { admin, guest }

// 嵌套
class Person {
  Person({required this.name, required this.age, required this.identity});
  String name;
  int age;
  Identity identity;
}

// 自定义类
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

  // 可空枚举（HostApi 同步可空枚举返回/入参）
  Identity? sendNullableEnum(Identity? data);

  // 异步枚举（HostApi 异步枚举返回）
  @async
  Identity sendAsyncEnum(Identity data);

  // 触发平台侧反向调用 Flutter 的 platformEchoEnum
  // 验证 FlutterApi 枚举：平台侧把枚举作为入参发给 Flutter、再收 Flutter 返回的枚举
  @async
  Identity triggerPlatformEchoEnum(Identity data);

  // 触发平台侧反向调用 Flutter 的 platformEchoNullableEnum（可空枚举双向）
  @async
  Identity? triggerPlatformEchoNullableEnum(Identity? data);

  // Flutter调用平台侧同步方法
  String flutterInvokeSync();

  // Flutter调用平台侧异步方法
  @async
  String flutterInvokeAsync();

  // 错误处理
  @async
  String errorHandling();

  // 任务队列
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String taskQueueTest();

  // 触发平台侧反过来同步调用 Flutter 的 DemoFlutterApi.platformInvokeSync
  @async
  String triggerPlatformInvokeSync();

  // 触发平台侧反过来异步调用 Flutter 的 DemoFlutterApi.platformInvokeAsync
  @async
  String triggerPlatformInvokeAsync();

  /// 在宿主侧创建 [HostEnumCounter] 并做枚举 echo（验证 host→Dart pigeon_newInstance、
  /// 宿主 echoRole、以及宿主→Flutter flutterEchoNullableRole）
  @async
  String proxyApiHostCreateAndEcho();
}

/// 宿主创建专用 ProxyApi：无必填 Flutter 回调，Dart 会生成 `pigeon_newInstance` 处理器。
@ProxyApi()
abstract class HostEnumCounter {
  HostEnumCounter(int initial, ProxyRole role);

  /// Unattached 枚举字段：宿主 `pigeon_newInstance` 时由宿主 abstract getter 提供。
  late ProxyRole storedRole;

  int increment(int by);

  int current();

  ProxyRole echoRole(ProxyRole value);

  ProxyRole? echoNullableRole(ProxyRole? value);

  /// 可选 Flutter 回调：宿主反向调用可空枚举路径（见 proxyApiHostCreate / main 全局 handler）。
  late ProxyRole? Function(ProxyRole? value)? flutterEchoNullableRole;
}

/// 最小 ProxyApi：构造参数含枚举、unattached 枚举字段、宿主方法枚举回显、Flutter 枚举回调。
@ProxyApi()
abstract class EnumCounter {
  EnumCounter(int initial, ProxyRole role);

  /// Unattached 枚举字段：宿主 `pigeon_newInstance` 时由宿主 abstract getter 提供。
  late ProxyRole storedRole;

  int increment(int by);

  int current();

  /// 宿主方法：枚举入参/返回（#18 编解码路径）。
  ProxyRole echoRole(ProxyRole value);

  ProxyRole? echoNullableRole(ProxyRole? value);

  /// Flutter 回调：宿主反向调用，验证 ProxyApi 的 FlutterApi 枚举路径（非空返回须非 optional 字段）。
  late ProxyRole Function(ProxyRole value) flutterEchoRole;

  late ProxyRole? Function(ProxyRole? value)? flutterEchoNullableRole;
}

@FlutterApi()
abstract class DemoFlutterApi {
  // 平台侧调用Flutter同步方法
  String platformInvokeSync();

  // 平台侧调用Flutter异步方法
  @async
  String platformInvokeAsync();

  // 平台侧反向回显枚举（验证 FlutterApi 枚举入参 + 返回的编解码）
  Identity platformEchoEnum(Identity value);

  // 平台侧反向回显可空枚举
  Identity? platformEchoNullableEnum(Identity? value);
}
