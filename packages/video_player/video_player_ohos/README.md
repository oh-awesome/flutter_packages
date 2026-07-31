# video\_player\_ohos

本项目基于 [video\_player@2.11.1](https://pub.dev/packages/video_player/versions/2.11.1) 进行 OpenHarmony 适配开发。

## 简介

`video_player_ohos` 是 `video_player` 的 OpenHarmony 平台实现，提供视频创建、播放控制、进度同步、事件回调与音轨选择能力。应用侧通常直接依赖 `video_player`，本仓库中的 OHOS 实现会在平台层自动接管。

## 下载安装

在业务工程 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  video_player:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_packages.git
      path: packages/video_player/video_player
      # ref: video_player-v2.11.1-ohos-1.0.1
      ref: TAG  #   请根据下方TAG版本对应表选择TAG
```

执行依赖安装命令：

```bash
flutter pub get
```

**TAG 版本对应表**

| Flutter 框架版本 | TAG1 | TAG2 | 分支 |
| :--- | :--- | :--- | :--- |
| 3.41 | `-` | `video_player-v2.11.1-ohos-1.0.0` | `br_video_player-v2.11.1_ohos` |
| 3.35 | `-` | `video_player-v2.10.1-ohos-1.0.1` | `br_video_player-v2.10.1_ohos` |
| 3.27 | `video_player-v2.10.0-ohos-1.0.0` | `video_player-v2.10.0-ohos-1.0.1` | `br_video_player-v2.10.0_ohos` |
| 3.22 | `video_player-v2.9.2-ohos-1.0.0` | `video_player-v2.9.2-ohos-1.0.1` | `br_video_player-v2.9.2_ohos` |
| 3.7 | `video_player-v2.7.2-ohos-1.0.0` | `video_player-v2.7.2-ohos-1.0.1` | `master` |


## 约束与限制

### 兼容性

1.Flutter: 3.35.8-ohos-0.0.3; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1 Developer Beta;

2.Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1 Developer Beta;

### 权限要求

网络播放场景需声明网络权限。若仅使用本地资源播放，可不配置该权限。

`entry/src/main/module.json5` 示例：

```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when": "inuse"
    }
  }
]
```

`entry/src/main/resources/base/element/string.json` 示例：

```json
{
  "string": [
    {
      "name": "network_reason",
      "value": "用于在线播放视频"
    }
  ]
}
```

> 注意：若应用声明了 `system_basic` 级权限但签名或等级不匹配，安装 HAP 时可能报错 `9568289`。请按 OpenHarmony 应用权限等级规范进行配置。

## 使用示例

以下示例展示导入、初始化、调用与结果输出四个关键步骤：

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DemoVideoPage extends StatefulWidget {
  const DemoVideoPage({super.key});

  @override
  State<DemoVideoPage> createState() => _DemoVideoPageState();
}

class _DemoVideoPageState extends State<DemoVideoPage> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // 1) 初始化控制器
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://media.w3.org/2010/05/sintel/trailer.mp4'),
    );
    // 2) 调用初始化并输出结果
    _controller.initialize().then((_) {
      debugPrint('Video initialized: ${_controller.value.size}');
      setState(() {});
      // 3) 开始播放
      _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4) 渲染播放结果
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 使用说明

- 本实现默认使用 `Texture` 渲染视频画面。
- 当前未开放 `platformView` 视频渲染选项。原因不是 OHOS 原生 `XComponent + AVPlayer` 能力缺失，而是当前 `flutter_ohos` 的 `PlatformView` 仍走纹理合成承载路径，和媒体 `XComponent` 的视频输出链路不完全匹配，实测会出现“有声音无画面”等问题，因此暂不作为正式能力开放。
- `DataSourceType.file` 在 OHOS 下支持 `fd://` 形式文件描述符路径。
- `formatHint` 当前支持：`VideoFormat.hls`、`VideoFormat.dash`。其中 ArkTS 原生层会把它们映射到 `MediaSource.setMimeType`。
- `VideoFormat.ss` 当前为“尽力而为”：插件不会主动拦截，但若系统侧不存在可用的 MIME 映射或协议解析能力，播放可能失败并返回媒体不支持相关错误。
- `setPlaybackSpeed` 在 OHOS 支持倍速：`0.125x`、`0.25x`、`0.5x`、`0.75x`、`1.0x`、`1.25x`、`1.5x`、`1.75x`、`2.0x`、`3.0x`。
  - **与 Android 的差异**：Android 的 `ExoPlayer` 对播放速率的容忍度更高，通常支持 `0.25x ~ 4.0x` 的连续范围；而 OHOS 的 `AVPlayer` 仅支持离散的预设档位。若传入值不在 OHOS 支持列表中，插件会将其**就近映射**到支持的最接近档位。
  - **OHOS 播放速率映射表**：

    | 传入值范围 | 实际生效速率 | 说明 |
    | :--- | :--- | :--- |
    | `< 0.125` | `0.125x` | 低于最小档位时取最小值 |
    | `0.125 ~ 0.25` | `0.25x` | 就近映射到 `0.25x` |
    | `0.25 ~ 0.5` | `0.5x` | 就近映射到 `0.5x` |
    | `0.5 ~ 0.75` | `0.75x` | 就近映射到 `0.75x` |
    | `0.75 ~ 1.0` | `1.0x` | 正常速率 |
    | `1.0 ~ 1.25` | `1.25x` | 就近映射到 `1.25x` |
    | `1.25 ~ 1.5` | `1.5x` | 就近映射到 `1.5x` |
    | `1.5 ~ 1.75` | `1.75x` | 就近映射到 `1.75x` |
    | `1.75 ~ 2.0` | `2.0x` | 就近映射到 `2.0x` |
    | `2.0 ~ 3.0` | `3.0x` | 高于 `2.0x` 时取 `3.0x` |
    | `> 3.0` | `3.0x` | 超过最大档位时取最大值 |
- 支持音轨能力查询与切换：`getAudioTracks`、`selectAudioTrack`、`isAudioTrackSupportAvailable`。
- `selectAudioTrack` 当前会等待 AVPlayer `trackChange` 事件确认后再完成 `Future<void>`；若 5 秒内未收到确认事件，则会显式超时失败。
- `setMixWithOthers` 在 OHOS 映射为 AVPlayer 的 `audioInterruptMode`。这更接近播放器实例级中断模式，而不是 Android/iOS 的系统级音频焦点/共享会话语义；同应用与跨应用场景可能存在行为差异。
- 示例工程见 [example](./example)。

## 接口说明

### 接口汇总

> 说明：下表中的“类型”仅使用“方法”“属性”。

| 名称                                  | 类型 | 参数类型                               | 返回值                             | ohos平台支持 | 描述                                      |
| ----------------------------------- | -- | ---------------------------------- | ------------------------------- | -------- | --------------------------------------- |
| init                                | 方法 | 无                                  | `Future<void>`                  | 是        | 初始化平台通道并清理历史播放器实例。                      |
| dispose                             | 方法 | `int textureId`                    | `Future<void>`                  | 是        | 释放指定播放器实例关联资源。                          |
| create                              | 方法 | `DataSource`                       | `Future<int?>`                  | 是        | 创建播放器并返回 `textureId`。                   |
| setLooping                          | 方法 | `int textureId, bool looping`      | `Future<void>`                  | 是        | 设置是否循环播放。                               |
| play                                | 方法 | `int textureId`                    | `Future<void>`                  | 是        | 播放指定视频。                                 |
| pause                               | 方法 | `int textureId`                    | `Future<void>`                  | 是        | 暂停指定视频。                                 |
| setVolume                           | 方法 | `int textureId, double volume`     | `Future<void>`                  | 是        | 设置音量，范围通常为 `0.0` 到 `1.0`。               |
| seekTo                              | 方法 | `int textureId, Duration position` | `Future<void>`                  | 是        | 跳转到指定时间点。                               |
| getPosition                         | 方法 | `int textureId`                    | `Future<Duration>`              | 是        | 获取当前播放进度。                               |
| videoEventsFor                      | 方法 | `int textureId`                    | `Stream<VideoEvent>`            | 是        | 订阅播放器事件流。                               |
| setMixWithOthers                    | 方法 | `bool mixWithOthers`               | `Future<void>`                  | 是        | 设置是否与其他音源混音播放。                          |
| setPlaybackSpeed                    | 方法 | `int textureId, double speed`      | `Future<void>`                  | 是        | 设置播放速度，`speed > 0`。                     |
| getAudioTracks                      | 方法 | `int playerId`                     | `Future<List<VideoAudioTrack>>` | 是        | 获取当前视频可用音轨列表。                           |
| selectAudioTrack                    | 方法 | `int playerId, String trackId`     | `Future<void>`                  | 是        | 切换到指定音轨。                                |
| sourceType                          | 属性 | 无                                  | `DataSourceType`                | 是        | 指定数据源类型（asset/network/file/contentUri）。 |
| uri                                 | 属性 | 无                                  | `String?`                       | 是        | 视频文件的 URI。                              |
| formatHint                          | 属性 | 无                                  | `VideoFormat`                   | 是        | 使用该格式提示覆盖默认格式识别。                        |
| asset                               | 属性 | 无                                  | `String?`                       | 是        | 资源名称。                                   |
| package                             | 属性 | 无                                  | `String?`                       | 是        | 资源所属包名。                                 |
| httpHeaders                         | 属性 | 无                                  | `Map<String, String>`           | 是        | HTTP 请求头。                               |
| DataSourceType.asset                | 属性 | 无                                  | `enum`                          | 是        | 应用资源文件。                                 |
| DataSourceType.network              | 属性 | 无                                  | `enum`                          | 是        | 网络资源。                                   |
| DataSourceType.file                 | 属性 | 无                                  | `enum`                          | 是        | 本地文件。                                   |
| DataSourceType.contentUri           | 属性 | 无                                  | `enum`                          | 否        | 视频通过 contentUri 访问，仅适用于 Android。        |
| VideoFormat.dash                    | 属性 | 无                                  | `enum`                          | 是        | HTTP 动态自适应流（MPEG-DASH）。                 |
| VideoFormat.hls                     | 属性 | 无                                  | `enum`                          | 是        | HTTP 实时流媒体（HLS）。                        |
| VideoFormat.ss                      | 属性 | 无                                  | `enum`                          | 否        | 平滑流媒体。                                  |
| VideoFormat.other                   | 属性 | 无                                  | `enum`                          | 否        | 其他格式。                                   |
| eventType                           | 属性 | 无                                  | `VideoEventType`                | 是        | 事件类型。                                   |
| duration                            | 属性 | 无                                  | `Duration?`                     | 是        | 视频时长。                                   |
| size                                | 属性 | 无                                  | `Size?`                         | 是        | 视频大小。                                   |
| rotationCorrection                  | 属性 | 无                                  | `int?`                          | 是        | 视频顺时针旋转角度，用于确保正确显示。                     |
| buffered                            | 属性 | 无                                  | `List<DurationRange>?`          | 是        | 视频已缓冲区间。                                |
| isPlaying                           | 属性 | 无                                  | `bool?`                         | 是        | 当前视频是否正在播放。                             |
| VideoEventType.initialized          | 属性 | 无                                  | `enum`                          | 是        | 视频初始化完成。                                |
| VideoEventType.completed            | 属性 | 无                                  | `enum`                          | 是        | 播放结束。                                   |
| VideoEventType.bufferingUpdate      | 属性 | 无                                  | `enum`                          | 是        | 缓冲状态更新。                                 |
| VideoEventType.bufferingStart       | 属性 | 无                                  | `enum`                          | 是        | 开始缓冲。                                   |
| VideoEventType.bufferingEnd         | 属性 | 无                                  | `enum`                          | 是        | 停止缓冲。                                   |
| VideoEventType.isPlayingStateUpdate | 属性 | 无                                  | `enum`                          | 是        | 视频播放状态变化。                               |
| VideoEventType.unknown              | 属性 | 无                                  | `enum`                          | 是        | 收到未知事件。                                 |

## 新增特性

- 支持音轨列表读取与音轨切换能力。
- 支持 OHOS 文件描述符模式（`fd://`）本地文件播放。

## 遗留问题

- 当前实现固定使用 `Texture` 渲染，未开放 `platformView` 渲染选项。
- 获取音轨遗留音轨数据与其他平台差异(language、codec、bitrate)。
- 切换音轨时混合流加分离流类型的资源目前不支持。
- `setMixWithOthers` 仍未达到 Android/iOS 的系统级焦点语义，只能提供 OHOS AVPlayer 可支持的中断模式映射。

## 常见问题

- 网络视频无法播放：检查是否已配置 `ohos.permission.INTERNET`。
- 本地文件无法播放：确认文件路径可访问，或改用 `fd://` 形式输入。
- 倍速设置不生效：确认输入倍速属于当前实现支持范围。
- `formatHint` 使用建议：优先使用 `hls/dash`。`ss` 若播放失败，通常是系统底层协议解析能力或 MIME 映射缺失导致。

## 目录结构

```text
video_player_ohos/
├─ lib/                 # Dart 侧平台实现与导出入口
├─ ohos/                # OpenHarmony 原生 ETS 实现
├─ pigeons/             # Pigeon 消息定义
├─ example/             # 示例工程
├─ test/                # Dart 单元测试
└─ doc/                 # 适配说明与能力矩阵
```

## 贡献代码

欢迎提交 Issue 或 Pull Request 参与共建：

- Issue: <https://gitcode.com/openharmony-tpc/flutter_packages/issues>
- PR: <https://gitcode.com/openharmony-tpc/flutter_packages/pulls>

## 开源协议

本项目基于 [The BSD-3-Clause License (BSD-3-Clause)](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/video_player/video_player_ohos/LICENSE) 开源发布。
