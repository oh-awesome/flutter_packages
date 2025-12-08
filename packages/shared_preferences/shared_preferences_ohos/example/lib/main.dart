// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, unreachable_from_main

import 'package:flutter/material.dart';
import 'package:shared_preferences_ohos/src/shared_preferences_async_ohos.dart'; // Fixed import path
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences_ohos/shared_preferences_ohos.dart';

void main() {
  runApp(const MyApp());
}

// #docregion Ohos_Options
const SharedPreferencesAsyncOhosOptions options =
    SharedPreferencesAsyncOhosOptions(
        backend: SharedPreferencesOhosBackendLibrary.SharedPreferences,
        originalSharedPreferencesOptions: OhosSharedPreferencesStoreOptions(
            fileName: 'the_name_of_a_file'));
// #enddocregion Ohos_Options

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SharedPreferences Demo',
      home: SharedPreferencesDemo(),
    );
  }
}

class SharedPreferencesDemo extends StatefulWidget {
  const SharedPreferencesDemo({super.key});

  @override
  SharedPreferencesDemoState createState() => SharedPreferencesDemoState();
}

class SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  final SharedPreferencesAsyncPlatform _prefs =
      SharedPreferencesAsyncPlatform.instance!;
  final SharedPreferencesAsyncOhosOptions options =
      const SharedPreferencesAsyncOhosOptions();
  static const String _counterKey = 'counter';
  late Future<int> _counter;

  // Store the latest test data to display in the UI.
  Map<String, Object> _testResults = <String, Object>{};

  Future<void> _incrementCounter() async {
    final int? value = await _prefs.getInt(_counterKey, options);
    final int counter = (value ?? 0) + 1;

    setState(() {
      _counter = _prefs.setInt(_counterKey, counter, options).then((_) {
        return counter;
      });
    });
  }

  Future<void> _getAndSetCounter() async {
    setState(() {
      _counter = _prefs.getInt(_counterKey, options).then((int? counter) {
        return counter ?? 0;
      });
    });
  }

  Future<void> _testGetAll() async {
    try {
      // Store test data with different types
      await _prefs.setInt('test_int64', 9223372036854775807, options);
      await _prefs.setInt('test_uint32', 2147483648, options);
      await _prefs.setInt('test_int32', 4294967296, options);
      await _prefs.setDouble('test_double', 100.1, options);
      await _prefs.setDouble('test_double_is_int', 100.0, options);
      await _prefs.setString('test_string', 'Hello OHOS', options);
      await _prefs.setBool('test_bool', true, options);

      // Build display text
      StringBuffer displayText = StringBuffer();

      // Add Set Data section
      displayText.writeln('setInt key: test_int64, value: 9223372036854775807');
      displayText.writeln('setInt key: test_uint32, value: 2147483648');
      displayText.writeln('setInt key: test_int32, value: 4294967296');
      displayText.writeln('setDouble key: test_double, value: 100.1');
      displayText.writeln('setDouble key: test_double_is_int, value: 100.0');
      displayText.writeln('setString key: test_string, value: Hello OHOS');
      displayText.writeln('setBool key: test_bool, value: true');
      displayText.writeln('*' * 50);

      // Get individual values
      displayText.writeln('getInt test_int64: ${await _prefs.getInt('test_int64', options)}');
      displayText.writeln('getInt test_uint32: ${await _prefs.getInt('test_uint32', options)}');
      displayText.writeln('getInt test_int32: ${await _prefs.getInt('test_int32', options)}');
      displayText.writeln('getDouble test_double: ${await _prefs.getDouble('test_double', options)}');
      displayText.writeln('getDouble test_double_is_int: ${await _prefs.getDouble('test_double_is_int', options)}');
      displayText.writeln('getString test_string: ${await _prefs.getString('test_string', options)}');
      displayText.writeln('getBool test_bool: ${await _prefs.getBool('test_bool', options)}');
      displayText.writeln('*' * 50);

      // Get all stored data using getPreferences
      final Map<String, Object> allData = await _prefs.getPreferences(
          const GetPreferencesParameters(filter: PreferencesFilters()),
          options);

      displayText.writeln('getAll:');

      // Add Get Data section
      allData.forEach((key, value) {
        displayText.writeln('key: $key, value: $value');
      });
      displayText.writeln('*' * 50);

      setState(() {
        _testResults = {'result': displayText.toString()};
      });
    } catch (e, stackTrace) {
      setState(() {
        _testResults = <String, Object>{'error': '$e'};
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getAndSetCounter();
    _testGetAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharedPreferences Demo'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<int>(
                future: _counter,
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    case ConnectionState.active:
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Text(
                          'Button tapped ${snapshot.data} time${snapshot.data == 1 ? '' : 's'}.\n\n'
                          'This should persist across restarts.',
                        );
                      }
                  }
                }),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTestResults(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return const Center(child: Text('No test data. Loading...'));
    }

    final String result = _testResults['result']?.toString() ?? 'No data';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          result,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
