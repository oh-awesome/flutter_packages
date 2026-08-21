// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
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
  _Api({
    this.returnsExternalStoragePaths = true,
    this.returnsNullPaths = false,
    this.returnsEmptyCachePaths = false,
  });

  final bool returnsExternalStoragePaths;
  final bool returnsNullPaths;
  final bool returnsEmptyCachePaths;

  @override
  String? getApplicationDocumentsPath() =>
      returnsNullPaths ? null : kApplicationDocumentsPath;

  @override
  String? getApplicationSupportPath() =>
      returnsNullPaths ? null : kApplicationSupportPath;

  @override
  String? getApplicationCachePath() =>
      returnsNullPaths ? null : kApplicationCachePath;

  @override
  List<String?> getExternalCachePaths() {
    if (returnsEmptyCachePaths) {
      return <String?>[];
    }
    return <String>[kExternalCachePaths];
  }

  @override
  String? getExternalStoragePath() =>
      returnsNullPaths ? null : kExternalStoragePaths;

  @override
  List<String?> getExternalStoragePaths(messages.StorageDirectory directory) {
    return <String>[if (returnsExternalStoragePaths) kExternalStoragePaths];
  }

  @override
  String? getTemporaryPath() => returnsNullPaths ? null : kTemporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderOhos', () {
    late PathProviderOhos pathProvider;

    setUp(() async {
      pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(_Api());
    });

    tearDown(() {
      TestPathProviderApi.setup(null);
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
      expect(
        () => pathProvider.getLibraryPath(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('getApplicationDocumentsPath', () async {
      final String? path = await pathProvider.getApplicationDocumentsPath();
      expect(path, kApplicationDocumentsPath);
    });

    test('getExternalStoragePath', () async {
      final String? path = await pathProvider.getExternalStoragePath();
      expect(path, kExternalStoragePaths);
    });

    test('getExternalCachePaths succeeds', () async {
      final List<String>? result = await pathProvider.getExternalCachePaths();
      expect(result!.length, 1);
      expect(result.first, kExternalCachePaths);
    });

    for (final StorageDirectory? type in <StorageDirectory?>[
      null,
      ...StorageDirectory.values
    ]) {
      test('getExternalStoragePaths (type: $type) ohos succeeds', () async {
        final List<String>? result =
            await pathProvider.getExternalStoragePaths(type: type);
        expect(result!.length, 1);
        expect(result.first, kExternalStoragePaths);
      });
    }

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

    test('registerWith should set PathProviderPlatform.instance', () {
      PathProviderOhos.registerWith();
      expect(PathProviderPlatform.instance, isA<PathProviderOhos>());
    });
  });

  group('PathProviderOhos null and empty results', () {
    late PathProviderOhos pathProvider;

    setUp(() {
      pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(_Api(
        returnsNullPaths: true,
        returnsExternalStoragePaths: false,
        returnsEmptyCachePaths: true,
      ));
    });

    tearDown(() {
      TestPathProviderApi.setup(null);
    });

    test('getTemporaryPath returns null when platform returns null', () async {
      expect(await pathProvider.getTemporaryPath(), isNull);
    });

    test('getApplicationSupportPath returns null when platform returns null',
        () async {
      expect(await pathProvider.getApplicationSupportPath(), isNull);
    });

    test('getApplicationDocumentsPath returns null when platform returns null',
        () async {
      expect(await pathProvider.getApplicationDocumentsPath(), isNull);
    });

    test('getApplicationCachePath returns null when platform returns null',
        () async {
      expect(await pathProvider.getApplicationCachePath(), isNull);
    });

    test('getExternalStoragePath returns null when platform returns null',
        () async {
      expect(await pathProvider.getExternalStoragePath(), isNull);
    });

    test('getExternalCachePaths returns empty list when platform returns empty',
        () async {
      final List<String>? result = await pathProvider.getExternalCachePaths();
      expect(result, isEmpty);
    });

    test(
        'getExternalStoragePaths returns empty list when platform returns empty',
        () async {
      final List<String>? result = await pathProvider.getExternalStoragePaths();
      expect(result, isEmpty);
    });
  });

  group('PathProviderOhos when platform channel is unregistered', () {
    late PathProviderOhos pathProvider;

    setUp(() {
      pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(null);
    });

    test('getTemporaryPath throws PlatformException channel-error', () async {
      expect(
        pathProvider.getTemporaryPath(),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'channel-error',
          ),
        ),
      );
    });

    test('getExternalStoragePath throws PlatformException channel-error',
        () async {
      expect(
        pathProvider.getExternalStoragePath(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('PathProviderOhos concurrent calls', () {
    late PathProviderOhos pathProvider;

    setUp(() {
      pathProvider = PathProviderOhos();
      TestPathProviderApi.setup(_Api());
    });

    tearDown(() {
      TestPathProviderApi.setup(null);
    });

    test(
        'getTemporaryPath getApplicationSupportPath getExternalStoragePath '
        'return consistent results when called concurrently', () async {
      final List<String?> results = await Future.wait(<Future<String?>>[
        pathProvider.getTemporaryPath(),
        pathProvider.getApplicationSupportPath(),
        pathProvider.getApplicationDocumentsPath(),
        pathProvider.getApplicationCachePath(),
        pathProvider.getExternalStoragePath(),
      ]);
      expect(results, <String>[
        kTemporaryPath,
        kApplicationSupportPath,
        kApplicationDocumentsPath,
        kApplicationCachePath,
        kExternalStoragePaths,
      ]);
    });
  });
}
