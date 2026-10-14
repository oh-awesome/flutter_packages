// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/fileselector/x_type_group.dart';
import 'file_selector_api.dart';

class FileSelector {
  FileSelector({ FileSelectorApi? api})
      : _api = api ?? FileSelectorApi();

  final FileSelectorApi _api;

  /// Registers this class as the implementation of the file_selector platform interface.
  // static void registerWith() {
  //   FileSelectorPlatform.instance = FileSelectorAndroid();
  // }

  @override
  /// Returns the document URI selected by the user.
  ///
  /// The plugin opens that URI itself, once for metadata and once for
  /// playback, so the two readers do not share a file offset.
  Future<String?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? confirmButtonText,
  }) async {
    final FileResponse? file = await _api.openFile(
      _fileTypesFromTypeGroups(acceptedTypeGroups),
    );
    final String? uri = file?.path.trim();
    if (uri == null || uri.isEmpty) {
      return null;
    }
    return uri;
  }



  FileTypes _fileTypesFromTypeGroups(List<XTypeGroup>? typeGroups) {
    if (typeGroups == null) {
      return FileTypes(extensions: <String>[], mimeTypes: <String>[]);
    }

    final Set<String> mimeTypes = <String>{};
    final Set<String> extensions = <String>{};

    for (final XTypeGroup group in typeGroups) {
      if (!group.allowsAny &&
          group.mimeTypes == null &&
          group.extensions == null) {
        throw ArgumentError(
          'Provided type group $group does not allow all files, but does not '
              'set any of the Android supported filter categories. At least one of '
              '"extensions" or "mimeTypes" must be non-empty for Android.',
        );
      }

      mimeTypes.addAll(group.mimeTypes ?? <String>{});
      extensions.addAll(group.extensions ?? <String>{});
    }

    return FileTypes(
      mimeTypes: mimeTypes.toList(),
      extensions: extensions.toList(),
    );
  }
}
