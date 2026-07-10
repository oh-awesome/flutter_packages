// Copyright 2024 Huawei Device Co., Ltd.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const String _examplePackage = 'io.flutter.plugins.example';

Future<void> main() async {
  if (!(Platform.isLinux || Platform.isMacOS)) {
    print('This test must be run on a POSIX host. Skipping...');
    exit(0);
  }
  final bool hdcExists =
      Process.runSync('which', <String>['hdc']).exitCode == 0;
  if (!hdcExists) {
    print(r'This test needs HDC to exist on the $PATH. Skipping...');
    exit(0);
  }
  print('Granting camera permissions...');
  Process.runSync('hdc', <String>[
    'shell',
    'hilog',
    '-p',
    'ohos.permission.CAMERA',
  ]);
  print('Starting test.');
  final FlutterDriver driver = await FlutterDriver.connect();
  final String data = await driver.requestData(
    null,
    timeout: const Duration(minutes: 1),
  );
  await driver.close();
  print('Test finished. Revoking camera permissions...');
  Process.runSync('hdc', <String>[
    'shell',
    'hilog',
    '-p',
    'ohos.permission.CAMERA',
  ]);

  final Map<String, dynamic> result = jsonDecode(data) as Map<String, dynamic>;
  exit(result['result'] == 'true' ? 0 : 1);
}
