/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_ohos/messages.g.dart' as messages;
import 'package:path_provider_ohos/path_provider_ohos.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'messages_test.g.dart';

const String kTemporaryPath = 'temporaryPath';
const String kApplicationSupportPath = 'applicationSupportPath';
const String kApplicationDocumentsPath = 'applicationDocumentsPath';
const String kApplicationCachePath = 'applicationCachePath';
const String kExternalCachePaths = 'externalCachePaths';
const String kExternalStoragePaths = 'externalStoragePaths';

class _Api implements TestPathProviderApi {
  _Api({this.returnsExternalStoragePaths = true});

  final bool returnsExternalStoragePaths;

  @override
  String? getApplicationDocumentsPath() => kApplicationDocumentsPath;

  @override
  String? getApplicationSupportPath() => kApplicationSupportPath;

  @override
  String? getApplicationCachePath() => kApplicationCachePath;

  @override
  List<String?> getExternalCachePaths() => <String>[kExternalCachePaths];

  @override
  String? getExternalStoragePath() => kExternalStoragePaths;

  @override
  List<String?> getExternalStoragePaths(messages.StorageDirectory directory) {
    return <String?>[if (returnsExternalStoragePaths) kExternalStoragePaths];
  }

  @override
  String? getTemporaryPath() => kTemporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderOhos', () {
    late PathProviderOhos pathProvider;

    setUp(() async {
      pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(_Api());
    });

    test('getTemporaryPath', () async {
      final String? path = await pathProvider.getTemporaryPath();
      expect(path, kTemporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(path, kApplicationSupportPath);
    });

    test('getApplicationCachePath', () async {
      final String? path = await pathProvider.getApplicationCachePath();
      expect(path, kApplicationCachePath);
    });

    test('getLibraryPath fails', () async {
      try {
        await pathProvider.getLibraryPath();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });

    test('getApplicationDocumentsPath', () async {
      final String? path = await pathProvider.getApplicationDocumentsPath();
      expect(path, kApplicationDocumentsPath);
    });

    test('getExternalCachePaths succeeds', () async {
      final List<String>? result = await pathProvider.getExternalCachePaths();
      expect(result!.length, 1);
      expect(result.first, kExternalCachePaths);
    });

    for (final StorageDirectory? type in <StorageDirectory?>[
      ...StorageDirectory.values
    ]) {
      test('getExternalStoragePaths (type: $type) ohos succeeds', () async {
        final List<String>? result =
            await pathProvider.getExternalStoragePaths(type: type);
        expect(result!.length, 1);
        expect(result.first, kExternalStoragePaths);
      });
    } // end of for-loop

    test('getDownloadsPath succeeds', () async {
      final String? path = await pathProvider.getDownloadsPath();
      expect(path, kExternalStoragePaths);
    });

    test(
        'getDownloadsPath returns null, when getExternalStoragePaths returns '
        'an empty list', () async {
      final PathProviderOhos pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(_Api(returnsExternalStoragePaths: false));
      final String? path = await pathProvider.getDownloadsPath();
      expect(path, null);
    });
  });
}
