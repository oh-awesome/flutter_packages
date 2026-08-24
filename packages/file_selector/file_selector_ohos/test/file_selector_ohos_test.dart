// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:file_selector_ohos/src/file_selector_ohos.dart';
import 'package:file_selector_ohos/src/file_selector_api.g.dart';
import 'package:file_selector_ohos/src/types/native_illegal_argument_exception.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'file_selector_ohos_test.mocks.dart';

@GenerateMocks(<Type>[FileSelectorApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileSelectorOhos plugin;
  late MockFileSelectorApi mockApi;

  setUp(() {
    mockApi = MockFileSelectorApi();
    plugin = FileSelectorOhos(api: mockApi);
  });

  tearDown(() {
    reset(mockApi);
  });

  test('registered instance', () {
    FileSelectorOhos.registerWith();
    expect(FileSelectorPlatform.instance, isA<FileSelectorOhos>());
  });

  group('openFile', () {
    test('passes the accepted type groups correctly', () async {
      when(
        mockApi.openFile(
          'some/path/',
          argThat(
            isA<FileTypes>()
                .having(
                  (FileTypes types) => types.mimeTypes,
                  'mimeTypes',
                  <String>['text/plain', 'image/jpg'],
                )
                .having(
                  (FileTypes types) => types.extensions,
                  'extensions',
                  <String>['txt', 'jpg'],
                ),
          ),
        ),
      ).thenAnswer(
        (_) => Future<FileResponse?>.value(
          FileResponse(
            path: 'some/path.txt',
            size: 30,
            bytes: Uint8List(0),
            name: 'name',
            mimeType: 'text/plain',
          ),
        ),
      );

      const XTypeGroup group = XTypeGroup(
        extensions: <String>['txt'],
        mimeTypes: <String>['text/plain'],
      );

      const XTypeGroup group2 = XTypeGroup(
        extensions: <String>['jpg'],
        mimeTypes: <String>['image/jpg'],
      );

      final XFile? file = await plugin.openFile(
        acceptedTypeGroups: <XTypeGroup>[group, group2],
        initialDirectory: 'some/path/',
      );

      expect(file?.path, 'some/path.txt');
      expect(file?.mimeType, 'text/plain');
      expect(await file?.length(), 30);
      expect(await file?.readAsBytes(), Uint8List(0));
    });

    test(
      'should use empty file types when acceptedTypeGroups is omitted',
      () async {
        when(mockApi.openFile(any, any)).thenAnswer(
          (_) => Future<FileResponse?>.value(
            FileResponse(
              path: 'default/path.txt',
              size: 1,
              bytes: Uint8List.fromList(<int>[1]),
              name: 'default',
              mimeType: 'text/plain',
            ),
          ),
        );

        final XFile? file = await plugin.openFile();

        expect(file?.path, 'default/path.txt');
        expect(file?.mimeType, 'text/plain');
        final VerificationResult verification = verify(
          mockApi.openFile(captureAny, captureAny),
        )..called(1);
        expect(verification.captured[0], isNull);
        final FileTypes types = verification.captured[1] as FileTypes;
        expect(types.mimeTypes, isEmpty);
        expect(types.extensions, isEmpty);
      },
    );

    test('should return null when the user cancels selection', () async {
      when(
        mockApi.openFile(any, any),
      ).thenAnswer((_) => Future<FileResponse?>.value());

      final XFile? file = await plugin.openFile(
        initialDirectory: 'some/path/',
      );

      expect(file, isNull);
    });

    test(
      'should throw ArgumentError when type group has only unsupported filters',
      () async {
        // allowsAny is false because webWildCards is set, but OHOS only
        // accepts extensions/mimeTypes - so ArgumentError is expected.
        const XTypeGroup invalidGroup = XTypeGroup(
          label: 'images',
          webWildCards: <String>['image/*'],
        );

        expect(
          () => plugin.openFile(
            acceptedTypeGroups: <XTypeGroup>[invalidGroup],
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'should throw NativeIllegalArgumentException when native returns illegalArgumentException',
      () async {
        const String errorMessage =
            'Trying to open path outside of the expected directory.';
        when(mockApi.openFile(any, any)).thenAnswer(
          (_) => Future<FileResponse?>.value(
            FileResponse(
              path: '/',
              size: 0,
              bytes: Uint8List(0),
              name: 'blocked',
              mimeType: 'application/octet-stream',
              fileSelectorNativeException: FileSelectorNativeException(
                fileSelectorExceptionCode:
                    FileSelectorExceptionCode.illegalArgumentException,
                message: errorMessage,
              ),
            ),
          ),
        );

        try {
          await plugin.openFile(initialDirectory: 'some/path/');
          fail('Expected NativeIllegalArgumentException');
        } on NativeIllegalArgumentException catch (error) {
          expect(error.message, errorMessage);
          expect(
            error.toString(),
            'NativeIllegalArgumentException($errorMessage)',
          );
        }
      },
    );

    test(
      'should ignore non-illegal native exceptions and still return the file',
      () async {
        when(mockApi.openFile(any, any)).thenAnswer(
          (_) => Future<FileResponse?>.value(
            FileResponse(
              path: 'some/path.txt',
              size: 4,
              bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
              name: 'path.txt',
              mimeType: 'text/plain',
              fileSelectorNativeException: FileSelectorNativeException(
                fileSelectorExceptionCode:
                    FileSelectorExceptionCode.securityException,
                message: 'permission denied',
              ),
            ),
          ),
        );

        final XFile? file = await plugin.openFile();

        expect(file?.path, 'some/path.txt');
        expect(await file?.length(), 4);
      },
    );

    test('should handle concurrent openFile calls independently', () async {
      when(mockApi.openFile(any, any)).thenAnswer((Invocation invocation) {
        final String? initialDirectory =
            invocation.positionalArguments[0] as String?;
        return Future<FileResponse?>.value(
          FileResponse(
            path: '${initialDirectory ?? 'default'}/a.txt',
            size: 2,
            bytes: Uint8List.fromList(<int>[9, 9]),
            name: 'a.txt',
            mimeType: 'text/plain',
          ),
        );
      });

      final List<XFile?> files = await Future.wait(<Future<XFile?>>[
        plugin.openFile(initialDirectory: 'dir-a'),
        plugin.openFile(initialDirectory: 'dir-b'),
      ]);

      expect(files[0]?.path, 'dir-a/a.txt');
      expect(files[1]?.path, 'dir-b/a.txt');
      verify(mockApi.openFile(any, any)).called(2);
    });
  });

  group('openFiles', () {
    test('passes the accepted type groups correctly', () async {
      when(
        mockApi.openFiles(
          'some/path/',
          argThat(
            isA<FileTypes>()
                .having(
                  (FileTypes types) => types.mimeTypes,
                  'mimeTypes',
                  <String>['text/plain', 'image/jpg'],
                )
                .having(
                  (FileTypes types) => types.extensions,
                  'extensions',
                  <String>['txt', 'jpg'],
                ),
          ),
        ),
      ).thenAnswer(
        (_) => Future<List<FileResponse>>.value(<FileResponse>[
          FileResponse(
            path: 'some/path.txt',
            size: 30,
            bytes: Uint8List(0),
            name: 'name',
            mimeType: 'text/plain',
          ),
          FileResponse(
            path: 'other/dir.jpg',
            size: 40,
            bytes: Uint8List(0),
            mimeType: 'image/jpg',
          ),
        ]),
      );

      const XTypeGroup group = XTypeGroup(
        extensions: <String>['txt'],
        mimeTypes: <String>['text/plain'],
      );

      const XTypeGroup group2 = XTypeGroup(
        extensions: <String>['jpg'],
        mimeTypes: <String>['image/jpg'],
      );

      final List<XFile> files = await plugin.openFiles(
        acceptedTypeGroups: <XTypeGroup>[group, group2],
        initialDirectory: 'some/path/',
      );

      expect(files[0].path, 'some/path.txt');
      expect(files[0].mimeType, 'text/plain');
      expect(await files[0].length(), 30);
      expect(await files[0].readAsBytes(), Uint8List(0));

      expect(files[1].path, 'other/dir.jpg');
      expect(files[1].mimeType, 'image/jpg');
      expect(await files[1].length(), 40);
      expect(await files[1].readAsBytes(), Uint8List(0));
    });

    test('should return an empty list when no files are selected', () async {
      when(
        mockApi.openFiles(any, any),
      ).thenAnswer((_) => Future<List<FileResponse>>.value(<FileResponse>[]));

      final List<XFile> files = await plugin.openFiles(
        initialDirectory: '',
      );

      expect(files, isEmpty);
    });

    test(
      'should throw NativeIllegalArgumentException.message from native response',
      () async {
        const String errorMessage = 'invalid cache path traversal';
        when(mockApi.openFiles(any, any)).thenAnswer(
          (_) => Future<List<FileResponse>>.value(<FileResponse>[
            FileResponse(
              path: '/',
              size: 0,
              bytes: Uint8List(0),
              fileSelectorNativeException: FileSelectorNativeException(
                fileSelectorExceptionCode:
                    FileSelectorExceptionCode.illegalArgumentException,
                message: errorMessage,
              ),
            ),
          ]),
        );

        await expectLater(
          plugin.openFiles(),
          throwsA(
            isA<NativeIllegalArgumentException>().having(
              (NativeIllegalArgumentException e) => e.message,
              'message',
              errorMessage,
            ),
          ),
        );
      },
    );

    test('should handle concurrent openFiles calls independently', () async {
      when(mockApi.openFiles(any, any)).thenAnswer(
        (_) => Future<List<FileResponse>>.value(<FileResponse>[
          FileResponse(
            path: 'a.txt',
            size: 1,
            bytes: Uint8List.fromList(<int>[1]),
            mimeType: 'text/plain',
          ),
        ]),
      );

      final List<List<XFile>> results = await Future.wait(<Future<List<XFile>>>[
        plugin.openFiles(initialDirectory: 'one'),
        plugin.openFiles(initialDirectory: 'two'),
      ]);

      expect(results[0], hasLength(1));
      expect(results[1], hasLength(1));
      verify(mockApi.openFiles(any, any)).called(2);
    });
  });

  test('getDirectoryPath', () async {
    when(
      mockApi.getDirectoryPath('some/path'),
    ).thenAnswer((_) => Future<String?>.value('some/path/chosen/'));

    final String? path = await plugin.getDirectoryPath(
      initialDirectory: 'some/path',
    );

    expect(path, 'some/path/chosen/');
  });

  group('getDirectoryPath extras', () {
    test('should return null when the user cancels directory selection', () async {
      when(
        mockApi.getDirectoryPath(any),
      ).thenAnswer((_) => Future<String?>.value());

      final String? path = await plugin.getDirectoryPath(
        initialDirectory: '',
      );

      expect(path, isNull);
    });

    test(
      'should forward a very long initialDirectory path to the native API',
      () async {
        final String longPath = 'a' * 1024;
        when(
          mockApi.getDirectoryPath(longPath),
        ).thenAnswer((_) => Future<String?>.value(longPath));

        final String? path = await plugin.getDirectoryPath(
          initialDirectory: longPath,
        );

        expect(path, longPath);
        verify(mockApi.getDirectoryPath(longPath)).called(1);
      },
    );
  });
}
