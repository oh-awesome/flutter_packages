// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class OpenWithMimeTypesPage extends StatefulWidget {
  const OpenWithMimeTypesPage({super.key});

  @override
  State<OpenWithMimeTypesPage> createState() => _OpenWithMimeTypesPageState();
}

class _OpenWithMimeTypesPageState extends State<OpenWithMimeTypesPage> {
  String? _resultPath;
  int? _resultSize;

  Future<void> _pickWithMimeTypes() async {
    const XTypeGroup imagesGroup = XTypeGroup(
      label: 'images',
      mimeTypes: <String>['image/jpeg', 'image/png'],
    );

    final XFile? file = await FileSelectorPlatform.instance.openFile(
      acceptedTypeGroups: <XTypeGroup>[imagesGroup],
    );

    if (file == null) {
      return;
    }

    final int size = await file.length();
    if (!mounted) {
      return;
    }
    setState(() {
      _resultPath = file.path;
      _resultSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open with mimeTypes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Pure mimeTypes input for document picker',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
              ),
              onPressed: _pickWithMimeTypes,
              child: const Text('Pick mimeTypes(png, jpg)'),
            ),
            const SizedBox(height: 24),
            if (_resultPath != null) ...<Widget>[
              const Text(
                'Selected file:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                'path: $_resultPath',
                key: const Key('result_path'),
              ),
              SelectableText('size: ${_resultSize ?? 0} bytes'),
            ] else
              const Text(
                'No file picked yet.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
