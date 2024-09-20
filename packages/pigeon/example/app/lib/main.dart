// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/pigeonFlutter.dart';


class _ExampleFlutterApi implements DemoFlutterApi {
  @override
  String flutterMethod(String? aString) {
    return aString ?? '';
  }

  @override
  Future<String> platformInvokeAsync() {
    throw UnimplementedError();
  }

  @override
  String platformInvokeSync() {
    throw UnimplementedError();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DemoFlutterApi.setUp(_ExampleFlutterApi());
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

  var _methodResult;

  @override
  void initState() {
    super.initState();
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
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendNull();
                            },
                            child: const Text('sendNull')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendTrue();
                            },
                            child: const Text('sendTrue')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendFalse();
                            },
                            child: const Text('sendFalse')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendInt();
                            },
                            child: const Text('sendInt')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendDouble();
                            },
                            child: const Text('sendDouble')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendString();
                            },
                            child: const Text('sendString')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendUint8List();
                            },
                            child: const Text('sendUint8List')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendInt32List();
                            },
                            child: const Text('sendInt32List')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendInt64List();
                            },
                            child: const Text('sendInt64List')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendFloat64List();
                            },
                            child: const Text('sendFloat64List')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendList();
                            },
                            child: const Text('sendList')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendMap();
                            },
                            child: const Text('sendMap')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendCustomClassMessage();
                            },
                            child: const Text('sendCustomClassMessage')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _sendNestedDatatypeToPlatform();
                            },
                            child: const Text('_sendNestedDatatype')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _SendEnum();
                            },
                            child: const Text('sendEnum')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _FlutterInvokeSync();
                            },
                            child: const Text('flutterInvokeSync')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _FlutterInvokeAsync();
                            },
                            child: const Text('flutterInvokeAsync')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _ErrorHandlingTest();
                            },
                            child: const Text('errorHandling')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _TaskQueueTest();
                            },
                            child: const Text('taskQueueTest')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _platformInvokeFlutterSync();
                            },
                            child: const Text('platformInvokeFlutterSync')),
                      )),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              _platformInvokeFlutterAsync();
                            },
                            child: const Text('platformInvokeFlutterAsync')),
                      )),
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
                  child: Text('$_methodResult'),
                ),
              ))
        ],
      ),
    );
  }

  ///sendNull
  Future<void> _SendNull() async {
    Object? result = await _hostApi.sendNull(null);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendTrue
  Future<void> _SendTrue() async {
    Object? result = _hostApi.sendTrue(true);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendFalse
  Future<void> _SendFalse() async {
    Object? result = _hostApi.sendFalse(false);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendInt
  Future<void> _SendInt() async {
    Object? result = _hostApi.sendInt(100);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendDouble
  Future<void> _SendDouble() async {
    Object? result = await _hostApi.sendDouble(100.256861);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendString
  Future<void> _SendString() async {
    Object? result = await _hostApi.sendString('sendStringValue');
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendUint8List
  Future<void> _SendUint8List() async {
    Object? result =
        await _hostApi.sendUint8List(Uint8List.fromList([1, 2, 3]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendInt32List
  Future<void> _SendInt32List() async {
    Object? result =
        await _hostApi.sendInt32List(Int32List.fromList([4, 5, 6]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendInt64List
  Future<void> _SendInt64List() async {
    Object? result = await _hostApi.sendInt64List(Int64List.fromList(
        [9223372036854775807, 9223372036854775806, 9223372036854775805]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendFloat64List
  Future<void> _SendFloat64List() async {
    Object? result = await _hostApi
        .sendFloat64List(Float64List.fromList([12.3, 45.6, 78.9]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendList
  Future<void> _SendList() async {
    Object? result = await _hostApi.sendList(['zhangsan', 'lisi', 'zhangwu']);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendMap
  Future<void> _SendMap() async {
    Object? result =
        await _hostApi.sendMap({'Name': 'zhangsan', 'Country': 'China'});
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  ///sendCustomClass
  Future<void> _SendCustomClassMessage() async {
    Object? result =
    await _hostApi.sendCustomClass(Student(name: "zhangsan", age: 18));
    Student student = result as Student;
    String studentStr = "Student{name='${student.name}', age=${student.age}}";
    setState(() {
      _methodResult = studentStr;
    });
  }

  ///sendNestedData
  Future<void> _sendNestedDatatypeToPlatform() async {
    try{
      Object? result = await _hostApi.sendNestedDatatype(
          Person(name: "lisi", age: 20, identity: Identity.teacher));
      Person person = result as Person;
      String personStr =
          "Person{name='${person.name}', age=${person.age}, identity=${person.identity}}";
      print(personStr);
      setState(() {
        _methodResult = personStr;
      });
    } catch (e) {
      print(e);
    }
  }

  ///sendEnum
  Future<void> _SendEnum() async {
    try {
     Object? result = await _hostApi.sendEnum(Identity.student);
      print(result);
      setState(() {
        _methodResult = result;
      });
    } catch (e) {
      print(e);
    }
  }

  ///InvokeSync
  Future<void> _FlutterInvokeSync() async {
    Object? result = await _hostApi.flutterInvokeSync();
    setState(() {
      _methodResult = result;
    });
  }

  Future<void> _FlutterInvokeAsync() async {
    Object? result = await _hostApi.flutterInvokeAsync();
    setState(() {
      _methodResult = result;
    });
  }

  ///ErrorHandling
  Future<void> _ErrorHandlingTest() async {
    try {
      await _hostApi.errorHandling();
    } catch (e) {
      setState(() {
        _methodResult = e.toString();
      });
    }
  }

  ///Deprecated
  Future<void> _TaskQueueTest() async {
    Object? result = await _hostApi.taskQueueTest();
    setState(() {
      _methodResult = result;
      _methodResult = '已废弃，不需要使用此方法了';
    });
  }

  ///platformInvokeFlutterSync
  Future<void> _platformInvokeFlutterSync() async {
    Object? result = await _hostApi.flutterInvokeSync();
    setState(() {
      _methodResult = result;
    });
  }

  ///platformInvokeFlutterAsync
  Future<void> _platformInvokeFlutterAsync() async {
    Object? result = await _hostApi.flutterInvokeAsync();
    setState(() {
      _methodResult = result;
    });
  }
}
