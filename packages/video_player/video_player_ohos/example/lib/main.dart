// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:io';

import 'package:flutter/material.dart';

import 'audio_tracks_demo.dart';
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

class _App extends StatefulWidget {
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> with RouteAware {
  final GlobalKey<_ButterFlyAssetVideoState> _assetKey =
      GlobalKey<_ButterFlyAssetVideoState>();
  final GlobalKey<_BumbleBeeRemoteVideoState> _remoteKey =
      GlobalKey<_BumbleBeeRemoteVideoState>();
  final GlobalKey<_LocalFileVideoState> _localFileKey =
      GlobalKey<_LocalFileVideoState>();
  PageRoute<dynamic>? _subscribedRoute;

  void _pauseAllPlayers() {
    _assetKey.currentState?.pauseIfPlaying();
    _remoteKey.currentState?.pauseIfPlaying();
    _localFileKey.currentState?.pauseIfPlaying();
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
    return DefaultTabController(
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
                    builder: (BuildContext context) => const AudioTracksDemo(),
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
                    builder: (BuildContext context) => const VideoTracksDemo(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.insert_drive_file),
                text: 'Asset'
              ),
              Tab(
                icon: Icon(Icons.cloud),
                text: 'Remote',
              ),
              Tab(
                icon: Icon(Icons.file_open),
                text: 'LocalFile'
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _ButterFlyAssetVideo(key: _assetKey),
            _BumbleBeeRemoteVideo(key: _remoteKey),
            _LocalFileVideo(key: _localFileKey),
          ],
        ),
      ),
    );
  }
}

class _ButterFlyAssetVideo extends StatefulWidget {
  const _ButterFlyAssetVideo({super.key});

  @override
  _ButterFlyAssetVideoState createState() => _ButterFlyAssetVideoState();
}

class _ButterFlyAssetVideoState extends State<_ButterFlyAssetVideo> {
  late MiniController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniController.asset('assets/video1.mp4');

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  @override
  void dispose() {
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
          Container(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          const Text('With assets mp4'),
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
  const _LocalFileVideo({super.key});

  @override
  _LocalFileVideoState createState() => _LocalFileVideoState();
}

class _LocalFileVideoState extends State<_LocalFileVideo> {
  late MiniController _controller;
  int? fileFd;

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
    _controller = MiniController.file(0);
  }

  void getFileFd() {
    print("getFileFd");
    selectorFile().then((value) {
      if (fileFd == null) {
        return;
      }
      _controller.dispose();
      _controller = MiniController.file(fileFd ?? 0);
      _controller.addListener(() {
        setState(() {});
      });
      _controller.initialize().whenComplete(() {
        _controller.play();
      });
    });
  }

  @override
  void dispose() {
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
          Container(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          const Text('With local file mp4'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BumbleBeeRemoteVideo extends StatefulWidget {
  const _BumbleBeeRemoteVideo({super.key});

  @override
  _BumbleBeeRemoteVideoState createState() => _BumbleBeeRemoteVideoState();
}

class _BumbleBeeRemoteVideoState extends State<_BumbleBeeRemoteVideo> {
  late MiniController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniController.network(
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.initialize();
  }

  @override
  void dispose() {
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
          const Text('With remote mp4'),
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
                onPressed: _controller.value.isPlaying
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
                child: Text(_keepScreenOn ? 'keepScreenOn: on' : 'keepScreenOn: off'),
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
          child: controller.value.isPlaying
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
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
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
