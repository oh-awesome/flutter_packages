// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/messages.g.dart';

// #docregion main-dart-flutter
class _ExampleFlutterApi implements MessageFlutterApi {
  @override
  String flutterMethod(String? aString) {
    return aString ?? '';
  }
}
// #enddocregion main-dart-flutter

void main() {
  WidgetsFlutterBinding.ensureInitialized();
// #docregion main-dart-flutter
  MessageFlutterApi.setUp(_ExampleFlutterApi());
// #enddocregion main-dart-flutter
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
  final ExampleHostApi _hostApi = ExampleHostApi();
  String? _hostCallResult;
  var _methodResult;

  /// Calls host method `add` with provided arguments.
  Future<int> add(int a, int b) async {
    try {
      return await _hostApi.add(a, b);
    } catch (e) {
      // handle error.
      return 0;
    }
  }

  /// Sends message through host api using `MessageData` class
  /// and api `sendMessage` method.
  Future<bool> sendMessage(String messageText) {
    final MessageData message = MessageData(
      code: Code.one,
      data: <String?, String?>{'header': 'this is a header'},
      description: 'uri text',
    );
    try {
      return _hostApi.sendMessage(message);
    } catch (e) {
      // handle error.
      return Future<bool>(() => true);
    }
  }
  // #enddocregion main-dart

  @override
  void initState() {
    super.initState();
    _getHostLanguage();
  }

  void _getHostLanguage() {
    _hostApi.getHostLanguage().then((String response) {
      setState(() {
        _hostCallResult = 'Hello from $response!';
      });
    }).onError<PlatformException>((PlatformException error, StackTrace _) {
      setState(() {
        _hostCallResult = 'Failed to get host language: ${error.message}';
      });
    });
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
                    child: Text(
                      _hostCallResult ?? 'Waiting for host language...',
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  if (_hostCallResult == null)
                    const CircularProgressIndicator(),
                  Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              add(3, 4).then((onValue) {
                                setState(() {
                                  _methodResult = '$onValue';
                                });
                              });
                            },
                            child: const Text('add')),
                      )),
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

  //sendNull
  Future<void> _SendNull() async {
    Object? result = await _hostApi.sendNull(null);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendTrue
  Future<void> _SendTrue() async {
    Object? result = _hostApi.sendTrue(true);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendFalse

  Future<void> _SendFalse() async {
    Object? result = _hostApi.sendFalse(false);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendInt
  Future<void> _SendInt() async {
    Object? result = _hostApi.sendInt(100);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendDouble
  Future<void> _SendDouble() async {
    Object? result = await _hostApi.sendDouble(100.256861);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendString
  Future<void> _SendString() async {
    Object? result = await _hostApi.sendString('sendStringValue');
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendUint8List
  Future<void> _SendUint8List() async {
    Object? result =
        await _hostApi.sendUint8List(Uint8List.fromList([1, 2, 3]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendInt32List
  Future<void> _SendInt32List() async {
    Object? result =
        await _hostApi.sendInt32List(Int32List.fromList([4, 5, 6]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendInt64List
  Future<void> _SendInt64List() async {
    Object? result = await _hostApi.sendInt64List(Int64List.fromList(
        [9223372036854775807, 9223372036854775806, 9223372036854775805]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  //sendFloat64List
  Future<void> _SendFloat64List() async {
    Object? result = await _hostApi
        .sendFloat64List(Float64List.fromList([12.3, 45.6, 78.9]));
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  Future<void> _SendList() async {
    Object? result = await _hostApi.sendList(['zhangsan', 'lisi', 'zhangwu']);
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  Future<void> _SendMap() async {
    Object? result =
        await _hostApi.sendMap({'Name': 'zhangsan', 'Country': 'China'});
    print(result);
    setState(() {
      _methodResult = result;
    });
  }

  Future<void> _SendCustomClassMessage() async {
    final MessageData message = MessageData(
      code: Code.one,
      data: <String?, String?>{'header': 'this is a header'},
      description: 'uri text',
    );
    try {
      Object? result = await _hostApi.sendMessage(message);
      setState(() {
        _methodResult = result;
      });
    } catch (e) {
      // handle error.
    }
  }

  Future<void> _SendEnum() async {
    try {
      Object? result = await _hostApi.sendEnum(Code.one);
      print(result);
      setState(() {
        _methodResult = result;
      });
    } catch (e) {}
  }

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

  Future<void> _ErrorHandlingTest() async {
    try {
      await _hostApi.errorHandling();
    } catch (e) {
      setState(() {
        _methodResult = e.toString();
      });
    }
  }

  Future<void> _TaskQueueTest() async {
    Object? result = await _hostApi.taskQueueTest();
    setState(() {
      _methodResult = result;
    });
  }
}
