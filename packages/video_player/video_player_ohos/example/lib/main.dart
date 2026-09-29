// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'audio_tracks_demo.dart';
import 'main_package_platform_view_page.dart';
import 'demo_sources.dart';
import 'fileselector/file_selector.dart';
import 'fileselector/x_type_group.dart';
import 'mini_controller.dart';
import 'mix_with_others_demo.dart';
import 'video_tracks_demo.dart';

final RouteObserver<PageRoute<dynamic>> _routeObserver =
    RouteObserver<PageRoute<dynamic>>();

void main() {
  runApp(
    MaterialApp(
      home: _App(),
      navigatorObservers: <NavigatorObserver>[_routeObserver],
    ),
  );
}

String _viewTypeCaption(VideoViewType viewType) {
  return viewType == VideoViewType.platformView
      ? '出画：Platform view（AVPlayer / HCPP）'
      : '出画：Texture view（默认）';
}

class _App extends StatefulWidget {
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> with RouteAware {
  final _PlayerPauseRegistry _pauseRegistry = _PlayerPauseRegistry();
  PageRoute<dynamic>? _subscribedRoute;
  bool _hdr = true;

  void _pauseAllPlayers() {
    _pauseRegistry.pauseAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        _routeObserver.unsubscribe(this);
      }
      _routeObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      _routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPushNext() {
    _pauseAllPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return _PlayerPauseRegistryScope(
      registry: _pauseRegistry,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          key: const ValueKey<String>('home_page'),
          appBar: AppBar(
            title: const Text('Video player example'),
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('mix_with_others_demo'),
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Mix With Others Demo',
                onPressed: () {
                  Navigator.push<MixWithOthersDemo>(
                    context,
                    MaterialPageRoute<MixWithOthersDemo>(
                      builder:
                          (BuildContext context) => const MixWithOthersDemo(),
                    ),
                  );
                },
              ),
              IconButton(
                key: const ValueKey<String>('audio_tracks_demo'),
                icon: const Icon(Icons.audiotrack),
                tooltip: 'Audio Tracks Demo',
                onPressed: () {
                  Navigator.push<AudioTracksDemo>(
                    context,
                    MaterialPageRoute<AudioTracksDemo>(
                      builder:
                          (BuildContext context) => const AudioTracksDemo(),
                    ),
                  );
                },
              ),
              IconButton(
                key: const ValueKey<String>('main_package_platform_view'),
                icon: const Icon(Icons.fact_check),
                tooltip: '主包 Platform view',
                onPressed: () {
                  Navigator.push<MainPackagePlatformViewPage>(
                    context,
                    MaterialPageRoute<MainPackagePlatformViewPage>(
                      builder: (BuildContext context) =>
                          const MainPackagePlatformViewPage(),
                    ),
                  );
                },
              ),
              IconButton(
                key: const ValueKey<String>('video_tracks_demo'),
                icon: const Icon(Icons.high_quality),
                tooltip: 'Video Tracks Demo',
                onPressed: () {
                  Navigator.push<VideoTracksDemo>(
                    context,
                    MaterialPageRoute<VideoTracksDemo>(
                      builder:
                          (BuildContext context) => const VideoTracksDemo(),
                    ),
                  );
                },
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(icon: Icon(Icons.insert_drive_file), text: 'Asset'),
                Tab(icon: Icon(Icons.cloud), text: 'Remote'),
                Tab(icon: Icon(Icons.file_open), text: 'LocalFile'),
              ],
            ),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SegmentedButton<bool>(
                  key: const ValueKey<String>('hdr_toggle'),
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('SDR'),
                      icon: Icon(Icons.tv),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('HDR'),
                      icon: Icon(Icons.hdr_on),
                    ),
                  ],
                  selected: <bool>{_hdr},
                  onSelectionChanged: (Set<bool> next) {
                    setState(() {
                      _hdr = next.first;
                    });
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _ViewTypeTabBar(
                      hdr: _hdr,
                      builder:
                          (VideoViewType viewType) => _ButterFlyAssetVideo(
                            key: ValueKey<String>(
                              'asset_${_hdr}_${viewType.name}',
                            ),
                            viewType: viewType,
                            hdr: _hdr,
                          ),
                    ),
                    _ViewTypeTabBar(
                      hdr: _hdr,
                      builder:
                          (VideoViewType viewType) => _BumbleBeeRemoteVideo(
                            key: ValueKey<String>(
                              'remote_${_hdr}_${viewType.name}',
                            ),
                            viewType: viewType,
                            hdr: _hdr,
                          ),
                    ),
                    _ViewTypeTabBar(
                      hdr: _hdr,
                      builder:
                          (VideoViewType viewType) => _LocalFileVideo(
                            key: ValueKey<String>(
                              'local_${_hdr}_${viewType.name}',
                            ),
                            viewType: viewType,
                            hdr: _hdr,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerPauseRegistry {
  final List<VoidCallback> _pausers = <VoidCallback>[];

  void add(VoidCallback pause) => _pausers.add(pause);

  void remove(VoidCallback pause) => _pausers.remove(pause);

  void pauseAll() {
    for (final VoidCallback pause in List<VoidCallback>.from(_pausers)) {
      pause();
    }
  }
}

class _PlayerPauseRegistryScope extends InheritedWidget {
  const _PlayerPauseRegistryScope({
    required this.registry,
    required super.child,
  });

  final _PlayerPauseRegistry registry;

  static _PlayerPauseRegistry? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PlayerPauseRegistryScope>()
        ?.registry;
  }

  @override
  bool updateShouldNotify(_PlayerPauseRegistryScope oldWidget) {
    return registry != oldWidget.registry;
  }
}

class _ViewTypeTabBar extends StatefulWidget {
  const _ViewTypeTabBar({required this.builder, required this.hdr});

  final Widget Function(VideoViewType) builder;
  final bool hdr;

  @override
  State<_ViewTypeTabBar> createState() => _ViewTypeTabBarState();
}

class _ViewTypeTabBarState extends State<_ViewTypeTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.texture), text: 'Texture view'),
            Tab(icon: Icon(Icons.layers), text: 'Platform view'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${widget.hdr ? '片源：HDR HLG / BT.2020' : '片源：SDR'}。'
            'Platform view 需要 flutter run --enable-hcpp，否则 initialize 会失败。',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              widget.builder(VideoViewType.textureView),
              widget.builder(VideoViewType.platformView),
            ],
          ),
        ),
      ],
    );
  }
}

class _ButterFlyAssetVideo extends StatefulWidget {
  const _ButterFlyAssetVideo({
    super.key,
    required this.viewType,
    required this.hdr,
  });

  final VideoViewType viewType;
  final bool hdr;

  @override
  _ButterFlyAssetVideoState createState() => _ButterFlyAssetVideoState();
}

class _ButterFlyAssetVideoState extends State<_ButterFlyAssetVideo> {
  late MiniController _controller;
  _PlayerPauseRegistry? _pauseRegistry;
  late final VoidCallback _pauseCallback;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pauseCallback = pauseIfPlaying;
    _controller = MiniController.asset(
      DemoSources.assetPath(hdr: widget.hdr),
      viewType: widget.viewType,
    );

    _controller.addListener(() {
      setState(() {});
    });
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    if (widget.hdr) {
      try {
        await rootBundle.load(DemoSources.hdrAsset);
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _loadError = DemoSources.missingHdrAssetMessage();
        });
        return;
      }
    }
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      await _controller.play();
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError =
            widget.hdr
                ? '${DemoSources.missingHdrAssetMessage()}\n$error'
                : error.toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _PlayerPauseRegistry? registry = _PlayerPauseRegistryScope.maybeOf(
      context,
    );
    if (registry != _pauseRegistry) {
      _pauseRegistry?.remove(_pauseCallback);
      _pauseRegistry = registry;
      _pauseRegistry?.add(_pauseCallback);
    }
  }

  @override
  void dispose() {
    _pauseRegistry?.remove(_pauseCallback);
    _controller.dispose();
    super.dispose();
  }

  void pauseIfPlaying() {
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          Text(widget.hdr ? 'With assets HDR mp4' : 'With assets mp4'),
          Text(_viewTypeCaption(widget.viewType)),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller),
                ],
              ),
            ),
          ),
          _ApiCoveragePanel(controller: _controller),
        ],
      ),
    );
  }
}

class _LocalFileVideo extends StatefulWidget {
  const _LocalFileVideo({super.key, required this.viewType, required this.hdr});

  final VideoViewType viewType;
  final bool hdr;

  @override
  _LocalFileVideoState createState() => _LocalFileVideoState();
}

class _LocalFileVideoState extends State<_LocalFileVideo> {
  late MiniController _controller;
  int? fileFd;
  _PlayerPauseRegistry? _pauseRegistry;
  late final VoidCallback _pauseCallback;
  String _sourceHint = '未选择本地文件';

  Future<void> selectorFile() async {
    print("selectorFile");
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'video',
      extensions: <String>['mp4'],
      uniformTypeIdentifiers: <String>['public.video'],
    );
    final FileSelector instance = FileSelector();
    fileFd = await instance.openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );
  }

  @override
  void initState() {
    super.initState();
    _pauseCallback = pauseIfPlaying;
    _controller = MiniController.file(0, viewType: widget.viewType);
    _controller.addListener(() {
      setState(() {});
    });
    if (widget.hdr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryLoadPushedHdr(auto: true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _PlayerPauseRegistry? registry = _PlayerPauseRegistryScope.maybeOf(
      context,
    );
    if (registry != _pauseRegistry) {
      _pauseRegistry?.remove(_pauseCallback);
      _pauseRegistry = registry;
      _pauseRegistry?.add(_pauseCallback);
    }
  }

  void getFileFd() {
    print("getFileFd");
    selectorFile().then((value) {
      if (fileFd == null) {
        return;
      }
      _attachController(
        MiniController.file(fileFd ?? 0, viewType: widget.viewType),
        sourceHint: '文件选择器 fd://$fileFd',
      );
    });
  }

  Future<void> _tryLoadPushedHdr({bool auto = false}) async {
    final bool loadedAsset = await _showThenInitialize(
      MiniController.asset(
        'assets/video_hdr_hlg.mp4',
        viewType: widget.viewType,
      ),
      sourceHint: 'HDR HLG / BT.2020 (asset)',
      timeout: const Duration(seconds: 12),
    );
    if (loadedAsset || !mounted) {
      return;
    }

    final List<String> candidates = <String>[];
    for (final String path in DemoSources.pushedHdrPaths) {
      if (await File(path).exists()) {
        candidates.add(path);
      }
    }
    if (candidates.isEmpty && !auto) {
      candidates.addAll(DemoSources.pushedHdrPaths);
    }
    for (final String path in candidates) {
      final bool loaded = await _showThenInitialize(
        MiniController.filePath(path, viewType: widget.viewType),
        sourceHint: 'HDR HLG / BT.2020\n$path',
        timeout: const Duration(seconds: 8),
      );
      if (loaded || !mounted) {
        return;
      }
    }
    if (!auto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '未找到 HDR 片。请 hdc 将 example/assets/video_hdr_hlg.mp4\n'
            '推送到 /data/local/tmp 或应用 files 目录。',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  /// PlatformView 的 surface 由当前这个控制器的 Widget 创建。
  /// 必须先显示它再 initialize，否则 XComponent 不会 onLoad，prepare 不会发生。
  Future<bool> _showThenInitialize(
    MiniController next, {
    required String sourceHint,
    required Duration timeout,
  }) async {
    final MiniController previous = _controller;
    _controller = next;
    _sourceHint = sourceHint;
    next.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    setState(() {});
    try {
      await next.initialize().timeout(timeout);
    } catch (_) {
      await next.dispose();
      if (mounted && identical(_controller, next)) {
        _controller = previous;
        setState(() {});
      }
      return false;
    }
    if (!mounted) {
      await next.dispose();
      return false;
    }
    await previous.dispose();
    await next.play();
    setState(() {});
    return true;
  }

  void _attachController(MiniController next, {required String sourceHint}) {
    _controller.dispose();
    _controller = next;
    _sourceHint = sourceHint;
    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize().whenComplete(() {
      if (mounted) {
        _controller.play();
        setState(() {});
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _pauseRegistry?.remove(_pauseCallback);
    _controller.dispose();
    super.dispose();
  }

  void pauseIfPlaying() {
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.blue,
      backgroundColor: Colors.white,
    );
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('With local file mp4'),
          Text(_viewTypeCaption(widget.viewType)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _sourceHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller),
                ],
              ),
            ),
          ),
          _ApiCoveragePanel(controller: _controller),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: style,
                  child: const Text('Open a video file'),
                  onPressed: () => {getFileFd()},
                ),
                const SizedBox(height: 8),
                if (widget.hdr)
                  ElevatedButton(
                    style: style,
                    child: const Text('加载推送的 HDR (HLG)'),
                    onPressed: () {
                      _tryLoadPushedHdr();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BumbleBeeRemoteVideo extends StatefulWidget {
  const _BumbleBeeRemoteVideo({
    super.key,
    required this.viewType,
    required this.hdr,
  });

  final VideoViewType viewType;
  final bool hdr;

  @override
  _BumbleBeeRemoteVideoState createState() => _BumbleBeeRemoteVideoState();
}

class _BumbleBeeRemoteVideoState extends State<_BumbleBeeRemoteVideo> {
  late MiniController _controller;
  _PlayerPauseRegistry? _pauseRegistry;
  late final VoidCallback _pauseCallback;
  final TextEditingController _urlController = TextEditingController();
  String _sourceHint = '';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _pauseCallback = pauseIfPlaying;
    _controller = MiniController.network(
      DemoSources.remoteUrl(hdr: widget.hdr),
      viewType: widget.viewType,
    );
    _controller.addListener(() {
      setState(() {});
    });
    if (widget.hdr) {
      _sourceHint = 'network 源待选择';
      _tryLoadHdrNetwork();
    } else {
      _playCurrent(hint: DemoSources.sdrRemote);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _PlayerPauseRegistry? registry = _PlayerPauseRegistryScope.maybeOf(
      context,
    );
    if (registry != _pauseRegistry) {
      _pauseRegistry?.remove(_pauseCallback);
      _pauseRegistry = registry;
      _pauseRegistry?.add(_pauseCallback);
    }
  }

  @override
  void dispose() {
    _pauseRegistry?.remove(_pauseCallback);
    _urlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void pauseIfPlaying() {
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  Future<String?> _firstExistingPushedHdrPath() async {
    for (final String path in DemoSources.pushedHdrPaths) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  Future<void> _tryLoadHdrNetwork() async {
    final String overrideUrl = DemoSources.remoteUrl(
      hdr: true,
      hdrOverride: _urlController.text,
    );
    if (overrideUrl.isNotEmpty) {
      await _attachNetwork(overrideUrl, hint: overrideUrl);
      return;
    }
    final String? copiedAsset = await _copyHdrAssetForNetwork();
    if (copiedAsset != null) {
      await _attachNetwork(
        DemoSources.fileUriForPath(copiedAsset),
        hint: DemoSources.hdrAssetAsNetworkHint(copiedAsset),
      );
      return;
    }
    final String? path = await _firstExistingPushedHdrPath();
    if (path != null) {
      await _attachNetwork(
        DemoSources.fileUriForPath(path),
        hint: 'network file://（推送 HDR）\n$path',
      );
      return;
    }
    if (mounted) {
      setState(() {
        _loadError = DemoSources.missingHdrRemoteMessage();
      });
    }
  }

  /// Copy the bundled HLG sample to temp so Remote can use DataSourceType.network.
  Future<String?> _copyHdrAssetForNetwork() async {
    try {
      final ByteData data = await rootBundle.load(DemoSources.hdrAsset);
      final File dest = File.fromUri(
        Directory.systemTemp.uri.resolve(DemoSources.hdrFileName),
      );
      final int expected = data.lengthInBytes;
      if (!await dest.exists() || await dest.length() != expected) {
        await dest.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, expected),
          flush: true,
        );
      }
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playCurrent({required String hint}) async {
    _sourceHint = hint;
    _loadError = null;
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      await _controller.play();
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.toString();
      });
    }
  }

  Future<void> _attachNetwork(String url, {required String hint}) async {
    final MiniController next = MiniController.network(
      url,
      viewType: widget.viewType,
    );
    await _controller.dispose();
    _controller = next;
    _sourceHint = hint;
    _loadError = null;
    _controller.addListener(() {
      setState(() {});
    });
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      await _controller.play();
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.blue,
      backgroundColor: Colors.white,
    );
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          Text(widget.hdr ? 'With remote HDR mp4' : 'With remote mp4'),
          Text(_viewTypeCaption(widget.viewType)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _sourceHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller),
                ],
              ),
            ),
          ),
          _ApiCoveragePanel(controller: _controller),
          if (widget.hdr)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'HDR URL（http 或 file://）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        style: style,
                        onPressed: () {
                          _tryLoadHdrNetwork();
                        },
                        child: const Text('播放 URL'),
                      ),
                      ElevatedButton(
                        style: style,
                        onPressed: () async {
                          _urlController.clear();
                          await _tryLoadHdrNetwork();
                        },
                        child: const Text('用推送 HDR 走 network'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ApiCoveragePanel extends StatefulWidget {
  const _ApiCoveragePanel({required this.controller});

  final MiniController controller;

  @override
  State<_ApiCoveragePanel> createState() => _ApiCoveragePanelState();
}

class _ApiCoveragePanelState extends State<_ApiCoveragePanel> {
  Duration? _queriedPosition;
  bool _mixWithOthers = false;
  bool _allowBackgroundPlayback = false;
  bool _keepScreenOn = true;
  String? _lastApiError;

  MiniController get _controller => widget.controller;

  Future<void> _showCurrentPosition() async {
    final Duration? position = await _controller.position;
    if (!mounted) {
      return;
    }
    setState(() {
      _queriedPosition = position;
    });
  }

  Future<void> _seekBy(Duration offset) async {
    final Duration? current = await _controller.position;
    if (current == null) {
      return;
    }
    await _controller.seekTo(current + offset);
  }

  String _formatDuration(Duration? value) {
    if (value == null) {
      return '--:--:--';
    }
    final String hours = value.inHours.toString().padLeft(2, '0');
    final String minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Text(
            'position(接口): ${_formatDuration(_queriedPosition)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (_lastApiError != null)
            Text(
              'lastError: $_lastApiError',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: _showCurrentPosition,
                child: const Text('读取position'),
              ),
              OutlinedButton(
                onPressed: () => _controller.seekTo(Duration.zero),
                child: const Text('seekTo开头'),
              ),
              OutlinedButton(
                onPressed: () => _seekBy(const Duration(seconds: -10)),
                child: const Text('seekTo-10s'),
              ),
              OutlinedButton(
                onPressed: () => _seekBy(const Duration(seconds: 10)),
                child: const Text('seekTo+10s'),
              ),
              OutlinedButton(
                onPressed:
                    _controller.value.isPlaying
                        ? _controller.pause
                        : _controller.play,
                child: Text(_controller.value.isPlaying ? 'pause' : 'play'),
              ),
              OutlinedButton(
                onPressed: () {
                  _controller.setLooping(!_controller.value.isLooping);
                },
                child: Text(
                  _controller.value.isLooping ? 'loop: on' : 'loop: off',
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  final bool next = !_keepScreenOn;
                  setState(() {
                    _keepScreenOn = next;
                  });
                  _controller.setPreventsDisplaySleepDuringVideoPlayback(next);
                },
                child: Text(
                  _keepScreenOn ? 'keepScreenOn: on' : 'keepScreenOn: off',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text('volume'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _controller.value.volume,
                  min: 0,
                  max: 1,
                  onChanged: (double value) {
                    _controller.setVolume(value);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<double> _examplePlaybackRates = <double>[
    0.75,
    1.0,
    1.25,
    1.75,
    2.0,
  ];

  final MiniController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child:
              controller.value.isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 100.0,
                        semanticLabel: 'Play',
                      ),
                    ),
                  ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(value: speed, child: Text('${speed}x')),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
