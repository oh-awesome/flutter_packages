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

enum Identity { student, teacher }

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

  Float64List sendFloat64List(Float64List data);

  List<String> sendList(List<String> data);

  Map<String, String> sendMap(Map<String, String> data);

  Student sendCustomClass(Student data);

  Person sendNestedDatatype(Person data);

  Identity sendEnum(Identity data);

  Identity? sendNullableEnum(Identity? data);

  @async
  Identity sendAsyncEnum(Identity data);

  @async
  Identity triggerPlatformEchoEnum(Identity data);

  @async
  Identity? triggerPlatformEchoNullableEnum(Identity? data);

  String flutterInvokeSync();

  @async
  String flutterInvokeAsync();

  @async
  String errorHandling();

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String taskQueueTest();

  @async
  String triggerPlatformInvokeSync();

  @async
  String triggerPlatformInvokeAsync();
}

@FlutterApi()
abstract class DemoFlutterApi {
  String platformInvokeSync();

  @async
  String platformInvokeAsync();

  Identity platformEchoEnum(Identity value);

  Identity? platformEchoNullableEnum(Identity? value);
}
