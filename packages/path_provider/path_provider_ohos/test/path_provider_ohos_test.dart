// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_ohos/src/ffi_bindings.dart';
import 'package:path_provider_ohos/src/path_provider_ohos_real.dart';
import 'package:path_provider_ohos/src/path_provider_ohos_stub.dart' as stub;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakeAbilityRuntimeBindings implements AbilityRuntimeBindings {
  _FakeAbilityRuntimeBindings({this.cacheDir, this.tempDir, this.filesDir});

  final String? cacheDir;
  final String? tempDir;
  final String? filesDir;

  @override
  bool get isAvailable => true;

  @override
  String? getCacheDir() => cacheDir;

  @override
  String? getTempDir() => tempDir;

  @override
  String? getFilesDir() => filesDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    abilityRuntimeBindingsOverride = null;
  });

  test('registered instance', () {
    abilityRuntimeBindingsOverride = _FakeAbilityRuntimeBindings(
      cacheDir: '/cache',
      tempDir: '/temp',
      filesDir: '/files',
    );
    PathProviderOhos.registerWith();
    expect(PathProviderPlatform.instance, isA<PathProviderOhos>());
  });

  test('getLibraryPath is unimplemented', () {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(),
    );
    expect(() => plugin.getLibraryPath(), throwsA(isA<UnimplementedError>()));
  });

  test('cache and support paths are null when bindings return null', () async {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(),
    );

    expect(await plugin.getTemporaryPath(), isNull);
    expect(await plugin.getApplicationCachePath(), isNull);
    expect(await plugin.getApplicationSupportPath(), isNull);
  });

  test('getTemporaryPath uses cacheDir', () async {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(
        tempDir: '/data/storage/el2/base/temp',
        cacheDir: '/data/storage/el2/base/cache',
      ),
    );
    expect(await plugin.getTemporaryPath(), '/data/storage/el2/base/cache');
  });

  test('getApplicationCachePath', () async {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(cacheDir: '/data/storage/el2/base/cache'),
    );
    expect(await plugin.getApplicationCachePath(), '/data/storage/el2/base/cache');
  });

  test('getApplicationSupportPath returns filesDir without creating it', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_support_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getApplicationSupportPath(), filesDir);
    expect(Directory(filesDir).existsSync(), isFalse);
  });

  test('getApplicationDocumentsPath uses app_flutter beside filesDir', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_docs_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    final String expected = path.join(root.path, 'app_flutter');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getApplicationDocumentsPath(), expected);
    expect(Directory(expected).existsSync(), isTrue);
    expect(Directory(filesDir).existsSync(), isFalse);
  });

  test('getApplicationDocumentsPath returns null when filesDir is unavailable', () async {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(),
    );

    expect(await plugin.getApplicationDocumentsPath(), isNull);
  });

  test('getApplicationDocumentsPath keeps an existing app_flutter directory', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_docs_exists_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    final String expected = path.join(root.path, 'app_flutter');
    await Directory(expected).create();

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getApplicationDocumentsPath(), expected);
    expect(Directory(expected).existsSync(), isTrue);
  });

  test('getApplicationDocumentsPath returns the path when app_flutter cannot be created', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_docs_fail_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'missing', 'files');
    final String expected = path.join(root.path, 'missing', 'app_flutter');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getApplicationDocumentsPath(), expected);
    expect(Directory(expected).existsSync(), isFalse);
  });

  test('getExternalStoragePath creates filesDir', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_ext_root_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePath(), filesDir);
    expect(Directory(filesDir).existsSync(), isTrue);
  });

  test('external storage paths are empty when the root directory is unavailable', () async {
    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(),
    );

    expect(await plugin.getExternalStoragePath(), isNull);
    expect(await plugin.getExternalCachePaths(), isNull);
    expect(await plugin.getExternalStoragePaths(), isEmpty);
    expect(await plugin.getDownloadsPath(), isNull);
  });

  test('getExternalCachePaths returns cacheDir without creating it', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_cache_');
    addTearDown(() => root.delete(recursive: true));
    final String cacheDir = path.join(root.path, 'cache');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(cacheDir: cacheDir),
    );

    expect(await plugin.getExternalCachePaths(), <String>[cacheDir]);
    expect(Directory(cacheDir).existsSync(), isFalse);
  });

  test('getExternalStoragePaths creates Environment subdirectory under filesDir', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_ext_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    // Legacy mkdirSync is non-recursive; filesDir exists in production.
    await Directory(filesDir).create();
    final String expected = path.join(filesDir, 'Pictures');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePaths(type: StorageDirectory.pictures), <String>[
      expected,
    ]);
    expect(Directory(expected).existsSync(), isTrue);
  });

  test('getExternalStoragePaths with null type creates filesDir', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_root_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePaths(), <String>[filesDir]);
    expect(Directory(filesDir).existsSync(), isTrue);
  });

  test('getExternalStoragePaths returns empty when parent filesDir is missing', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'path_provider_ohos_missing_parent_',
    );
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    final String pictures = path.join(filesDir, 'Pictures');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePaths(type: StorageDirectory.pictures), isEmpty);
    expect(Directory(pictures).existsSync(), isFalse);
  });

  test('getExternalStoragePath returns null when filesDir cannot be created', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_ext_fail_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'missing', 'files');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePath(), isNull);
    expect(await plugin.getExternalStoragePaths(), isEmpty);
  });

  test('storage paths succeed when the directory already exists', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_exists_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    await Directory(filesDir).create();
    final String downloads = path.join(filesDir, 'Download');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getExternalStoragePaths(), <String>[filesDir]);
    expect(await plugin.getExternalStoragePath(), filesDir);
    expect(await plugin.getDownloadsPath(), downloads);
    expect(await plugin.getDownloadsPath(), downloads);
    expect(Directory(downloads).existsSync(), isTrue);
  });

  test('getExternalStoragePaths maps every StorageDirectory', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_types_');
    addTearDown(() => root.delete(recursive: true));
    const Map<StorageDirectory, String> directoryNames = <StorageDirectory, String>{
      StorageDirectory.music: 'Music',
      StorageDirectory.podcasts: 'Podcasts',
      StorageDirectory.ringtones: 'Ringtones',
      StorageDirectory.alarms: 'Alarms',
      StorageDirectory.notifications: 'Notifications',
      StorageDirectory.pictures: 'Pictures',
      StorageDirectory.movies: 'Movies',
      StorageDirectory.downloads: 'Download',
      StorageDirectory.dcim: 'DCIM',
      StorageDirectory.documents: 'Documents',
    };

    for (final StorageDirectory type in StorageDirectory.values) {
      final String filesDir = path.join(root.path, type.name);
      await Directory(filesDir).create();
      final PathProviderPlatform plugin = PathProviderOhos.private(
        bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
      );
      final String expected = path.join(filesDir, directoryNames[type]!);

      expect(await plugin.getExternalStoragePaths(type: type), <String>[expected]);
      expect(Directory(expected).existsSync(), isTrue);
    }
  });

  test('getDownloadsPath returns null when Download cannot be created', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_dl_fail_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getDownloadsPath(), isNull);
    expect(Directory(path.join(filesDir, 'Download')).existsSync(), isFalse);
  });

  test('getDownloadsPath uses Download subdirectory', () async {
    final Directory root = await Directory.systemTemp.createTemp('path_provider_ohos_dl_');
    addTearDown(() => root.delete(recursive: true));
    final String filesDir = path.join(root.path, 'files');
    await Directory(filesDir).create();
    final String expected = path.join(filesDir, 'Download');

    final PathProviderPlatform plugin = PathProviderOhos.private(
      bindings: _FakeAbilityRuntimeBindings(filesDir: filesDir),
    );

    expect(await plugin.getDownloadsPath(), expected);
    expect(Directory(expected).existsSync(), isTrue);
  });

  test('stub registerWith is a no-op', () {
    stub.PathProviderOhos.registerWith();
  });

  test('open failure leaves ability runtime bindings unavailable', () {
    final AbilityRuntimeBindingsImpl bindings = AbilityRuntimeBindingsImpl();

    expect(bindings.isAvailable, isFalse);
    expect(bindings.getCacheDir(), isNull);
    expect(bindings.getTempDir(), isNull);
    expect(bindings.getFilesDir(), isNull);
  });

  test('missing symbols leave ability runtime bindings unavailable', () {
    final AbilityRuntimeBindingsImpl bindings = AbilityRuntimeBindingsImpl(library: _hostLibrary());

    expect(bindings.isAvailable, isFalse);
    expect(bindings.getCacheDir(), isNull);
    expect(bindings.getTempDir(), isNull);
    expect(bindings.getFilesDir(), isNull);
  });
}

DynamicLibrary _hostLibrary() {
  if (Platform.isWindows) {
    return DynamicLibrary.open('kernel32.dll');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
  }
  return DynamicLibrary.open('libc.so.6');
}
