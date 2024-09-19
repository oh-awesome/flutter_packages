import 'package:pigeon/pigeon.dart';

// @ConfigurePigeon(PigeonOptions(
//   // javaOut: 'android/app/src/main/java/io/flutter/plugins/pigeon/PigeonAndroid.java',
//   // javaOptions: JavaOptions(
//   //   className: 'PigeonAndroid',
//   //   package: 'io.flutter.plugins.pigeon',
//   // ),
//   dartOut: 'lib/src/pigeonFlutter.dart',
//   dartOptions: DartOptions(),
// ))

// 枚举
enum Identity { student, teacher }

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
}

@FlutterApi()
abstract class DemoFlutterApi {
  // 平台侧调用Flutter同步方法
  String platformInvokeSync();

  // 平台侧调用Flutter异步方法
  @async
  String platformInvokeAsync();
}