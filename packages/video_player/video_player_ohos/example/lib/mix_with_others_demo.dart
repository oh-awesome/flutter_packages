// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'mini_controller.dart';

class MixWithOthersDemo extends StatefulWidget {
  const MixWithOthersDemo({super.key});

  @override
  State<MixWithOthersDemo> createState() => _MixWithOthersDemoState();
}

class _MixWithOthersDemoState extends State<MixWithOthersDemo> {
  static const _PlayerSpec _playerA = _PlayerSpec(
    label: '播放器 A',
    asset: 'assets/Butterfly-209.mp4',
    description: '先启动 A，再启动 B，观察 A 是否被打断。',
  );
  static const _PlayerSpec _playerB = _PlayerSpec(
    label: '播放器 B',
    asset: 'assets/video1.mp4',
    description: '先启动 B，再启动 A，观察 B 是否被打断。',
  );

  MiniController? _controllerA;
  MiniController? _controllerB;
  bool _mixWithOthers = true;
  bool _isRebuilding = false;
  String? _error;
  String _status = '推荐验证顺序：先切换开关并重建，再执行“先播 A 再播 B”或“先播 B 再播 A”。';
  int _rebuildToken = 0;

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void dispose() {
    _controllerA?.removeListener(_onControllerChanged);
    _controllerB?.removeListener(_onControllerChanged);
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  Future<void> _safeDispose(MiniController? controller) async {
    if (controller == null) {
      return;
    }
    controller.removeListener(_onControllerChanged);
    try {
      await controller.pause().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await controller.dispose().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> _pauseAndDisposeCurrentControllers() async {
    final MiniController? oldA = _controllerA;
    final MiniController? oldB = _controllerB;
    if (mounted) {
      setState(() {
        _controllerA = null;
        _controllerB = null;
      });
    }
    await _safeDispose(oldA);
    await _safeDispose(oldB);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  bool _areBothInitialized(
    MiniController? controllerA,
    MiniController? controllerB,
  ) {
    return controllerA?.value.isInitialized == true &&
        controllerB?.value.isInitialized == true;
  }

  void _applyReadyState({
    required MiniController controllerA,
    required MiniController controllerB,
    String? statusOverride,
  }) {
    _controllerA = controllerA;
    _controllerB = controllerB;
    _error = null;
    _status =
        statusOverride ??
        '已重建完成，当前开关: ${_mixWithOthers ? 'true(共享焦点模式)' : 'false(独立焦点模式)'}。';
  }

  Future<MiniController> _createInitializedController(
    _PlayerSpec spec, {
    required int token,
    required String stepLabel,
  }) async {
    final MiniController controller = MiniController.asset(spec.asset);
    controller.addListener(_onControllerChanged);
    try {
      if (stepLabel == 'A') {
        await controller.setMixWithOthers(_mixWithOthers);
      }
      await controller.initialize();
      if (token != _rebuildToken) {
        throw StateError('播放器重建已被新的请求替换。');
      }
      return controller;
    } catch (_) {
      await _safeDispose(controller);
      rethrow;
    }
  }

  Future<void> _rebuildControllers() async {
    if (_isRebuilding) {
      return;
    }
    final int token = ++_rebuildToken;
    MiniController? nextA;
    MiniController? nextB;
    try {
      setState(() {
        _isRebuilding = true;
        _error = null;
        _status = '正在顺序重建播放器：先释放旧实例...';
      });
      await _pauseAndDisposeCurrentControllers();
      if (!mounted) {
        return;
      }

      setState(() {
        _status = '正在顺序重建播放器：初始化 A...';
      });
      nextA = await _createInitializedController(
        _playerA,
        token: token,
        stepLabel: 'A',
      );

      if (!mounted || token != _rebuildToken) {
        await _safeDispose(nextA);
        return;
      }

      setState(() {
        _status = 'A 已完成，正在初始化 B...';
      });
      nextB = await _createInitializedController(
        _playerB,
        token: token,
        stepLabel: 'B',
      );

      if (!mounted || token != _rebuildToken) {
        await _safeDispose(nextA);
        await _safeDispose(nextB);
        return;
      }

      setState(() {
        _applyReadyState(controllerA: nextA!, controllerB: nextB!);
      });
    } catch (e) {
      await _safeDispose(nextA);
      await _safeDispose(nextB);
      if (!mounted || token != _rebuildToken) {
        return;
      }
      const String limitHint =
          '若该提示总是在第二个播放器初始化阶段出现，说明当前设备或底层实现可能限制同应用同时保有 2 个活跃播放器。';
      setState(() {
        _error = '重建播放器失败: $e';
        _status = '重建失败，请查看错误信息。$limitHint';
      });
    } finally {
      if (mounted && token == _rebuildToken) {
        setState(() {
          _isRebuilding = false;
        });
      }
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        if (_error != null && _areBothInitialized(_controllerA, _controllerB)) {
          _error = null;
          if (_status == '重建失败，请查看错误信息。') {
            _status =
                '播放器已可用，当前开关: ${_mixWithOthers ? 'true(共享焦点模式)' : 'false(独立焦点模式)'}。';
          }
        }
      });
    }
  }

  Future<void> _pauseBoth() async {
    final MiniController? controllerA = _controllerA;
    final MiniController? controllerB = _controllerB;
    if (controllerA == null || controllerB == null) {
      return;
    }
    await controllerA.pause();
    await controllerB.pause();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = '已暂停两个播放器。';
    });
  }

  Future<void> _playSingle(
    MiniController? controller,
    String label,
    String detail,
  ) async {
    if (controller == null) {
      return;
    }
    await controller.play();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = '$label 已开始播放。$detail';
    });
  }

  Future<void> _playSequence({
    required MiniController? first,
    required MiniController? second,
    required String firstLabel,
    required String secondLabel,
  }) async {
    if (first == null || second == null) {
      return;
    }
    await _pauseBoth();
    await first.seekTo(Duration.zero);
    await second.seekTo(Duration.zero);
    await first.play();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await second.play();
    if (!mounted) {
      return;
    }
    setState(() {
      _status =
          '已执行“先播 $firstLabel 再播 $secondLabel”。'
          '若开关为 true，两个播放器应更容易共存；若为 false，后启动播放器更可能打断先启动播放器。';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('setMixWithOthers 验证页')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildIntroCard(),
          const SizedBox(height: 12),
          _buildConfigCard(),
          const SizedBox(height: 12),
          _buildActionCard(),
          const SizedBox(height: 12),
          _PlayerCard(
            spec: _playerA,
            controller: _controllerA,
            onPlay:
                () => _playSingle(
                  _controllerA,
                  _playerA.label,
                  '然后再点“先播 A 再播 B”或直接启动 B 观察差异。',
                ),
            onPause: () => _controllerA?.pause(),
          ),
          const SizedBox(height: 12),
          _PlayerCard(
            spec: _playerB,
            controller: _controllerB,
            onPlay:
                () => _playSingle(
                  _controllerB,
                  _playerB.label,
                  '然后再点“先播 B 再播 A”或直接启动 A 观察差异。',
                ),
            onPause: () => _controllerB?.pause(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('页面用途', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('这个页面只验证“同一 App 内两个播放器”的音频焦点差异，不用它判断外部音乐 App 是否会被打断。'),
            const SizedBox(height: 8),
            Text(
              '当前预期: ${_mixWithOthers ? 'true -> 尽量允许 A/B 共存' : 'false -> 后启动播放器更可能打断先启动播放器'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('重建策略: 先释放旧播放器，再按 A -> B 顺序创建，避免重建时短时并发持有过多实例。'),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('setMixWithOthers'),
              subtitle: const Text('切换后请点“按当前开关重建播放器”再开始测试。'),
              value: _mixWithOthers,
              onChanged:
                  _isRebuilding
                      ? null
                      : (bool value) {
                        setState(() {
                          _mixWithOthers = value;
                          _status = '开关已切到 $value，但还未生效。请点击“按当前开关重建播放器”。';
                        });
                      },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isRebuilding ? null : _rebuildControllers,
                child: Text(_isRebuilding ? '重建中...' : '按当前开关重建播放器'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    final bool canOperate =
        !_isRebuilding &&
        _controllerA?.value.isInitialized == true &&
        _controllerB?.value.isInitialized == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('推荐操作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed:
                      canOperate
                          ? () => _playSequence(
                            first: _controllerA,
                            second: _controllerB,
                            firstLabel: 'A',
                            secondLabel: 'B',
                          )
                          : null,
                  child: const Text('先播 A 再播 B'),
                ),
                OutlinedButton(
                  onPressed:
                      canOperate
                          ? () => _playSequence(
                            first: _controllerB,
                            second: _controllerA,
                            firstLabel: 'B',
                            secondLabel: 'A',
                          )
                          : null,
                  child: const Text('先播 B 再播 A'),
                ),
                OutlinedButton(
                  onPressed: canOperate ? _pauseBoth : null,
                  child: const Text('暂停两个播放器'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('状态: $_status', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.spec,
    required this.controller,
    required this.onPlay,
    required this.onPause,
  });

  final _PlayerSpec spec;
  final MiniController? controller;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final MiniController? current = controller;
    final bool isReady = current?.value.isInitialized ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(spec.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(spec.description),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: isReady ? current!.value.aspectRatio : 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child:
                    isReady
                        ? VideoPlayer(current!)
                        : const Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isReady
                  ? 'isPlaying=${current!.value.isPlaying}  volume=${current.value.volume.toStringAsFixed(2)}'
                  : '播放器初始化中...',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: isReady ? onPlay : null,
                  child: const Text('播放'),
                ),
                OutlinedButton(
                  onPressed: isReady ? onPause : null,
                  child: const Text('暂停'),
                ),
                OutlinedButton(
                  onPressed:
                      isReady ? () => current!.seekTo(Duration.zero) : null,
                  child: const Text('回到开头'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSpec {
  const _PlayerSpec({
    required this.label,
    required this.asset,
    required this.description,
  });

  final String label;
  final String asset;
  final String description;
}
