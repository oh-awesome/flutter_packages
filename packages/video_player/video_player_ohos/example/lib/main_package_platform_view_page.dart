// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'demo_sources.dart';

enum _ClipSource { asset, network, file }

enum _MountStyle { alreadyInTree, afterInitialized }

/// Uses the app-facing [VideoPlayerController], which does not notify after
/// `create`. The platform view appears only once `initialized` updates `value`.
class MainPackagePlatformViewPage extends StatefulWidget {
  /// Creates the main-package platform view check page.
  const MainPackagePlatformViewPage({super.key});

  @override
  State<MainPackagePlatformViewPage> createState() =>
      _MainPackagePlatformViewPageState();
}

class _MainPackagePlatformViewPageState
    extends State<MainPackagePlatformViewPage> {
  _ClipSource _source = _ClipSource.asset;
  _MountStyle _mount = _MountStyle.alreadyInTree;
  final TextEditingController _filePath = TextEditingController(
    text: DemoSources.pushedHdrPaths.first,
  );
  VideoPlayerController? _controller;
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _filePath.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final VideoPlayerController? previous = _controller;
    setState(() {
      _error = null;
      _opening = true;
      _controller = null;
    });
    await previous?.dispose();

    final VideoPlayerController next = _createController();
    next.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    if (!mounted) {
      await next.dispose();
      return;
    }
    setState(() {
      _controller = next;
    });
    try {
      await next.initialize();
      await next.play();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  VideoPlayerController _createController() {
    const VideoViewType viewType = VideoViewType.platformView;
    switch (_source) {
      case _ClipSource.asset:
        return VideoPlayerController.asset(
          DemoSources.sdrAsset,
          viewType: viewType,
        );
      case _ClipSource.network:
        return VideoPlayerController.networkUrl(
          Uri.parse(DemoSources.sdrRemote),
          viewType: viewType,
        );
      case _ClipSource.file:
        return VideoPlayerController.file(
          File(_filePath.text.trim()),
          viewType: viewType,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    final VideoPlayerValue? value = controller?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('主包 Platform view')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            '使用 video_player 的 VideoPlayerController。'
            'create 之后不会 notifyListeners，洞要等 initialized。',
          ),
          const SizedBox(height: 12),
          SegmentedButton<_ClipSource>(
            segments: const <ButtonSegment<_ClipSource>>[
              ButtonSegment<_ClipSource>(
                value: _ClipSource.asset,
                label: Text('Asset'),
              ),
              ButtonSegment<_ClipSource>(
                value: _ClipSource.network,
                label: Text('网络'),
              ),
              ButtonSegment<_ClipSource>(
                value: _ClipSource.file,
                label: Text('文件'),
              ),
            ],
            selected: <_ClipSource>{_source},
            onSelectionChanged: (Set<_ClipSource> next) {
              setState(() {
                _source = next.first;
              });
              _open();
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<_MountStyle>(
            segments: const <ButtonSegment<_MountStyle>>[
              ButtonSegment<_MountStyle>(
                value: _MountStyle.alreadyInTree,
                label: Text('先挂在树上'),
              ),
              ButtonSegment<_MountStyle>(
                value: _MountStyle.afterInitialized,
                label: Text('initialized 后再挂'),
              ),
            ],
            selected: <_MountStyle>{_mount},
            onSelectionChanged: (Set<_MountStyle> next) {
              setState(() {
                _mount = next.first;
              });
              _open();
            },
          ),
          if (_source == _ClipSource.file) ...<Widget>[
            const SizedBox(height: 8),
            TextField(
              controller: _filePath,
              decoration: const InputDecoration(
                labelText: '本地路径',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _open(),
            ),
          ],
          const SizedBox(height: 12),
          Text(_statusLine(value)),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: value?.aspectRatio ?? 1,
            child: ColoredBox(
              color: Colors.black,
              child: _buildPlayer(controller, value),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: controller == null || _opening
                ? null
                : () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
            child: Text(value?.isPlaying ?? false ? '暂停' : '播放'),
          ),
        ],
      ),
    );
  }

  String _statusLine(VideoPlayerValue? value) {
    if (_opening && value == null) {
      return '正在创建…';
    }
    if (value == null) {
      return '未创建';
    }
    if (value.hasError) {
      return value.errorDescription!;
    }
    if (!value.isInitialized) {
      return '等待 initialized… 洞还不会出现在「initialized 后再挂」里';
    }
    final Size size = value.size;
    return 'initialized  '
        'size ${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)}  '
        'duration ${value.duration.inMilliseconds} ms  '
        'aspect ${value.aspectRatio.toStringAsFixed(3)}';
  }

  Widget _buildPlayer(
    VideoPlayerController? controller,
    VideoPlayerValue? value,
  ) {
    if (controller == null) {
      return const SizedBox.shrink();
    }
    if (_mount == _MountStyle.afterInitialized &&
        !(value?.isInitialized ?? false)) {
      return const Center(
        child: Text(
          '占位：等 initialized 才放入 VideoPlayer',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return VideoPlayer(controller);
  }
}
