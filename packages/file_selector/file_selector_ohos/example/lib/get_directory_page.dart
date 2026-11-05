// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen that calls `getDirectoryPath` and shows the unsupported error
/// (or unexpected success / cancel) instead of crashing.
class GetDirectoryPage extends StatelessWidget {
  /// Default Constructor
  const GetDirectoryPage({super.key});

  Future<void> _getDirectoryPath(BuildContext context) async {
    String title;
    String body;
    try {
      final String? directoryPath =
          await FileSelectorPlatform.instance.getDirectoryPath();
      if (directoryPath == null) {
        title = 'Cancelled / null';
        body = 'getDirectoryPath returned null (no PlatformException).';
      } else {
        title = 'Unexpected success';
        body = 'Selected directory: $directoryPath';
      }
    } on PlatformException catch (e) {
      title = 'PlatformException (expected)';
      body = 'code: ${e.code}\nmessage: ${e.message}\ndetails: ${e.details}';
    } catch (e) {
      title = 'Other error';
      body = e.toString();
    }

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('getDirectoryPath (unsupported)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'On OpenHarmony this should return PlatformException '
                'with code not_supported, not crash the app.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
              ),
              child: const Text('Call getDirectoryPath'),
              onPressed: () => _getDirectoryPath(context),
            ),
          ],
        ),
      ),
    );
  }
}
