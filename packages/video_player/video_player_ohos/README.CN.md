# video_player_ohos

本项目基于 [video_player](https://pub.dev/packages/video_player) 进行 OpenHarmony 适配开发。

## 简介

`video_player_ohos` 是 `video_player` 的 OpenHarmony 平台实现，提供视频创建、播放控制、进度同步、事件回调、音轨与画质轨选择能力。应用侧通常直接依赖 `video_player`，OHOS 实现会在平台层自动接管。

## 下载安装

应用侧直接使用 `video_player` 主包 API，同时依赖主包与 OHOS 实现包（缺一不可）：

```yaml
dependencies:
  video_player: ^2.14.0
  video_player_ohos:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/video_player/video_player"
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG  # Select a TAG from the TAG version mapping table below
```

执行依赖安装命令：

```bash
flutter pub get
```

> 说明：业务代码统一 `import 'package:video_player/video_player.dart'`，`video_player_ohos` 在平台层自动接管，无需直接 import。

**TAG 版本对应表**

| Flutter 框架版本 | TAG 名称 | 分支名 |
|---|---|---|
| 3.44 | video_player-v2.14.0-ohos-1.0.0 | oh-3.44.9-dev |

> TAG 命名规则：`原库版本-ohos-版本号`。

**版本升级与迁移（v2.11.1 → v2.14.0，Flutter 3.35 → 3.44）**

1. 更新 Flutter SDK 到 3.44.9-ohos-1.0.0（含配套 DevEco Studio 6.1.1.268、SDK 5.0.0(12)）。
2. 将 `pubspec.yaml` 中 `video_player_ohos` 的 `ref` 从 `video_player-v2.11.1-ohos-1.0.0` 改为 `video_player-v2.14.0-ohos-1.0.0`，`video_player` 主包同步升到 `^2.14.0`。
3. 执行 `flutter pub get` 后重新构建 HAP。主包 2.12.0 起 `VideoPlayerController` 构造新增 `VideoPlayerOptions.backBufferDurationMs`，OHOS 侧当前忽略该参数，升级无需改业务代码。
4. 若旧工程使用 `br_video_player-v2.11.1_ohos` 分支，请切换到 `oh-3.44.9-dev` 分支后重新拉取。

## 约束与限制

### 兼容性

1. Flutter: 3.44.9-ohos-1.0.0, DevEco Studio: 6.1.1.268, SDK: 5.0.5(17), ROM: 6.1 Developer Beta;

### 权限要求

网络播放场景需声明网络权限；仅使用本地资源播放时可不配置。

`entry/src/main/module.json5` 示例：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

对应 `entry/src/main/resources/base/element/string.json`：

```json5
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

### OHOS 环境搭建步骤

1. 安装 DevEco Studio 6.1.1.268，并通过 `File > Settings > SDK` 安装 OpenHarmony SDK 5.0.0(12)。
2. 获取 Flutter OHOS SDK（如 3.44.9-ohos-1.0.0），设置环境变量 `PUB_HOSTED_URL`、`FLUTTER_STORAGE_BASE_URL` 为镜像地址后执行 `flutter doctor` 确认环境就绪。
3. 业务工程执行 `flutter pub get`，随后 `flutter build hap --debug`（或直接在 DevEco Studio 中打开工程 `ohos/` 目录运行）完成 HAP 编译与安装。
4. 运行真机需在 DevEco Studio 中配置签名（`File > Project Structure > Signing Configs`）。

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
    // 2) 初始化完成输出结果
    _controller.initialize().then((_) {
      debugPrint('Video initialized: ${_controller.value.size}');
      setState(() {});
      // 3) 开始播放
      _controller.play();
    });
  }

  // 4) 页面销毁时释放播放器资源
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
```

## 使用说明

- 本实现默认使用 `Texture` 渲染视频画面。
- 当前未开放 `platformView` 视频渲染选项。原因不是 OHOS 原生 `XComponent + AVPlayer` 能力缺失，而是当前 `flutter_ohos` 的 `PlatformView` 仍走纹理合成承载路径，和媒体 `XComponent` 的视频输出链路不完全匹配，实测会出现“有声音无画面”等问题，因此暂不作为正式能力开放。
- `DataSourceType.asset` 支持通过 `package` 参数访问其他包（插件）内打包的资源，实际读取路径为 `flutter_assets/packages/<package>/<asset>`。
- `DataSourceType.file` 在 OHOS 下支持 `fd://` 形式文件描述符路径；传入普通路径时插件侧自动打开文件并转换为 `fd://`，播放器释放时会一并关闭该文件描述符。
- `formatHint` 当前支持：`VideoFormat.hls`、`VideoFormat.dash`。ArkTS 原生层会把它们映射到 `MediaSource.setMimeType`。
- `VideoFormat.ss` 当前为“尽力而为”：插件不会主动拦截，但若系统侧不存在可用的 MIME 映射或协议解析能力，播放可能失败并返回媒体不支持相关错误。
- `setPlaybackSpeed` 在 OHOS 支持倍速：`0.125x`、`0.25x`、`0.5x`、`0.75x`、`1.0x`、`1.25x`、`1.5x`、`1.75x`、`2.0x`、`3.0x`。
  - **与 Android 的差异**：Android 的 `ExoPlayer` 对播放速率的容忍度更高，通常支持 `0.25x ~ 4.0x` 的连续范围；而 OHOS 的 `AVPlayer` 仅支持离散的预设档位。若传入值不在 OHOS 支持列表中，插件会将其就近映射到支持的最接近档位。
  - **OHOS 播放速率映射表**：

    | 传入值范围 | 实际生效速率 | 说明 |
    | :--- | :--- | :--- |
    | `(0, 0.125]` | `0.125x` | 低于最小档位时取最小值 |
    | `(0.125, 0.4]` | `0.25x` | 就近映射到 `0.25x` |
    | `(0.4, 0.6]` | `0.5x` | 就近映射到 `0.5x` |
    | `(0.6, 0.8]` | `0.75x` | 就近映射到 `0.75x` |
    | `(0.8, 1.1]` | `1.0x` | 正常速率 |
    | `(1.1, 1.4]` | `1.25x` | 就近映射到 `1.25x` |
    | `(1.4, 1.6]` | `1.5x` | 就近映射到 `1.5x` |
    | `(1.6, 1.8]` | `1.75x` | 就近映射到 `1.75x` |
    | `(1.8, 2.0]` | `2.0x` | 就近映射到 `2.0x` |
    | `> 2.0` | `3.0x` | 超过 `2.0x` 时取最大值 |
- 支持音轨能力查询与切换：`getAudioTracks`、`selectAudioTrack`、`isAudioTrackSupportAvailable`。
- `selectAudioTrack` 内部直接调用 `AVPlayer.selectTrack` 并 `await` 返回；不存在“等待 trackChange 事件 + 5 秒超时”机制。
- 支持画质轨能力查询与切换：`getVideoTracks`、`selectVideoTrack`、`enableAutoVideoQuality`（传 `null` 恢复自适应画质）、`isVideoTrackSupportAvailable`。
  - **关于恢复自适应画质的限制**：OHOS AVPlayer 未提供清除单条视频轨道选择（deselect）的等价接口，传 `null` 恢复自适应时，实现会重新 `selectTrack` 默认轨道来近似模拟。因此该操作无法真正做到"真正的自适应码流"，只能回退到某一条固定轨道；若此前锁定过画质轨，回退目标是默认轨道而非继续自适应，功能语义上不等价于 Android/iOS 的"清除 override 恢复自适应"。上层如有对该契约的强依赖，请知悉此差异。
- `setMixWithOthers` 在 OHOS 映射为 AVPlayer 的 `audioInterruptMode`。这更接近播放器实例级中断模式，而不是 Android/iOS 的系统级音频焦点/共享会话语义；同应用与跨应用场景可能存在行为差异。
- `setPreventsDisplaySleepDuringVideoPlayback` 在 OHOS 上已支持：该标志会透传到原生侧，播放期间按标志控制屏幕常亮（停止时恢复窗口原始配置）；为 `false` 时允许播放过程中屏幕休眠。
- `backBufferDurationMs`（2.12.0 引入）在 OHOS 暂不支持：AVPlayer 无回放缓冲时长控制能力，该参数会被忽略，不影响正常播放。
- `getAudioTracks`/`getVideoTracks` 的 `isSelected` 为近似值：AVPlayer `getTrackDescription` 未暴露真实选中轨道，实现按“首条轨道即默认选中”上报；多音轨组（混流）场景下轨道 ID 采用 `groupIndex=0` 展平，`selectAudioTrack` 不支持选择 `groupIndex != 0` 的轨道。
- 以下主包 Widget 为平台无关组件，OHOS 上与 Android/iOS 行为一致：`VideoPlayer`、`VideoProgressIndicator`、`VideoProgressColors`、`VideoScrubber`、`ClosedCaption`（含 `ClosedCaptionFile`、`Caption`、`SubRipCaptionFile`、`WebVTTCaptionFile` 字幕解析）。
- 主包 `VideoPlayerController` 的事件流错误监听做了防二次崩溃守卫：当原生事件流的错误并非 `PlatformException`（例如解析事件时抛出的 `TypeError`）时，不再因强转类型而二次崩溃导致偶现闪退，而是透出可读的错误信息（见主包 `video_player` 2.14.1 变更）。
- 示例工程见 [example](./example)。

### 进阶用法示例

**音轨查询与切换**

```dart
if (controller.isAudioTrackSupportAvailable()) {
  final audioTracks = await controller.getAudioTracks();
  if (audioTracks.length > 1) {
    // 切换到第二条音轨（参数为 trackId）
    await controller.selectAudioTrack(audioTracks[1].trackId);
  }
}
```

**画质轨查询与切换**

```dart
if (controller.isVideoTrackSupportAvailable()) {
  final videoTracks = await controller.getVideoTracks();
  if (videoTracks.length > 1) {
    // 切换到指定画质轨；传 null 恢复自动选择
    await controller.selectVideoTrack(videoTracks[1]);
    // await controller.selectVideoTrack(null); // 自适应
  }
}
```

**倍速播放**

```dart
await _controller.setPlaybackSpeed(1.5); // OHOS 支持的离散档位见上方映射表
```

**fd:// 文件描述符播放**

```dart
// 传入普通文件路径时插件自动打开并转换为 fd://，释放时自动关闭
final controller = VideoPlayerController.file(File('/data/storage/el2/base/haps/entry/files/video.mp4'));
```

若通过平台接口层（`video_player_platform_interface`）直接构造 `DataSource`，也支持传入 `fd://<n>` 形式的 URI，此时插件不会重复打开文件。

## 接口说明

### 属性

| 名称 | 描述 | 参数类型 | 必填 | OpenHarmony平台支持 |
|-----|-----|---------|--------|---------------|
| sourceType | 指定数据源类型（asset/network/file/contentUri） | `DataSourceType` | 是 | 是 |
| uri | 视频文件的 URI | `String?` | 否 | 是 |
| formatHint | 使用该格式提示覆盖默认格式识别 | `VideoFormat` | 否 | 是 |
| asset | 资源名称 | `String?` | 否 | 是 |
| package | 资源所属包名 | `String?` | 否 | 是 |
| httpHeaders | HTTP 请求头 | `Map<String, String>` | 否 | 是 |
| DataSourceType.asset | 应用资源文件 | `enum` | - | 是 |
| DataSourceType.network | 网络资源 | `enum` | - | 是 |
| DataSourceType.file | 本地文件 | `enum` | - | 是 |
| DataSourceType.contentUri | 通过 contentUri 访问，仅适用于 Android | `enum` | - | 否 |
| VideoFormat.dash | HTTP 动态自适应流（MPEG-DASH） | `enum` | - | 是 |
| VideoFormat.hls | HTTP 实时流媒体（HLS） | `enum` | - | 是 |
| VideoFormat.ss | 平滑流媒体 | `enum` | - | 否 |
| VideoFormat.other | 其他格式 | `enum` | - | 否 |
| eventType | 事件类型 | `VideoEventType` | - | 是 |
| duration | 视频时长 | `Duration?` | - | 是 |
| size | 视频大小 | `Size?` | - | 是 |
| rotationCorrection | 视频顺时针旋转角度，用于确保正确显示 | `int?` | - | 是 |
| buffered | 视频已缓冲区间 | `List<DurationRange>?` | - | 是 |
| isPlaying | 当前视频是否正在播放 | `bool?` | - | 是 |
| VideoEventType.initialized | 视频初始化完成 | `enum` | - | 是 |
| VideoEventType.completed | 播放结束 | `enum` | - | 是 |
| VideoEventType.bufferingUpdate | 缓冲状态更新 | `enum` | - | 是 |
| VideoEventType.bufferingStart | 开始缓冲 | `enum` | - | 是 |
| VideoEventType.bufferingEnd | 停止缓冲 | `enum` | - | 是 |
| VideoEventType.isPlayingStateUpdate | 视频播放状态变化 | `enum` | - | 是 |
| VideoEventType.unknown | 收到未知事件 | `enum` | - | 是 |

### API

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|-----|-----|---------|----------|---------|---------|-------------|
| init | 初始化平台通道并清理历史播放器实例 | 方法 | 无 | `Future<void>` | 否 | 是 |
| dispose | 释放指定播放器实例关联资源 | 方法 | `int textureId` | `Future<void>` | 否 | 是 |
| create | 创建播放器并返回 `textureId` | 方法 | `DataSource` | `Future<int?>` | 否 | 是 |
| setLooping | 设置是否循环播放 | 方法 | `int textureId, bool looping` | `Future<void>` | 否 | 是 |
| play | 播放指定视频 | 方法 | `int textureId` | `Future<void>` | 否 | 是 |
| pause | 暂停指定视频 | 方法 | `int textureId` | `Future<void>` | 否 | 是 |
| setVolume | 设置音量，范围通常为 `0.0` 到 `1.0` | 方法 | `int textureId, double volume` | `Future<void>` | 否 | 是 |
| seekTo | 跳转到指定时间点 | 方法 | `int textureId, Duration position` | `Future<void>` | 否 | 是 |
| getPosition | 获取当前播放进度 | 方法 | `int textureId` | `Future<Duration>` | 否 | 是 |
| videoEventsFor | 订阅播放器事件流 | 方法 | `int textureId` | `Stream<VideoEvent>` | 否 | 是 |
| setMixWithOthers | 设置是否与其他音源混音播放 | 方法 | `bool mixWithOthers` | `Future<void>` | 否 | 是 |
| setPlaybackSpeed | 设置播放速度，`speed > 0` | 方法 | `int textureId, double speed` | `Future<void>` | 否 | 是 |
| getAudioTracks | 获取当前视频可用音轨列表 | 方法 | `int playerId` | `Future<List<VideoAudioTrack>>` | 否 | 是 |
| selectAudioTrack | 切换到指定音轨 | 方法 | `int playerId, String trackId` | `Future<void>` | 否 | 是 |
| isAudioTrackSupportAvailable | 返回音轨能力是否可用 | 方法 | 无 | `bool` | 否 | 是 |
| getVideoTracks | 获取当前视频可用画质轨列表 | 方法 | `int playerId` | `Future<List<VideoTrack>>` | 否 | 是 |
| selectVideoTrack | 切换到指定画质轨，传 `null` 恢复自适应 | 方法 | `int playerId, VideoTrack? track` | `Future<void>` | 否 | 是（传 `null` 仅近似恢复自适应，见"使用说明"） |
| isVideoTrackSupportAvailable | 返回画质轨能力是否可用 | 方法 | 无 | `bool` | 否 | 是 |

## 新增特性

- 支持音轨列表读取与音轨切换能力。
- 支持画质轨列表读取、切换与自适应画质恢复。
- 支持 OHOS 文件描述符模式（`fd://`）本地文件播放，播放器释放时自动关闭插件侧打开的文件描述符。
- 支持打包资源（`package` 参数）形式的 asset 播放。

## 遗留问题

- 当前实现固定使用 `Texture` 渲染，未开放 `platformView` 渲染选项。
- 获取到的音轨数据与其它平台存在差异（`language`、`codec`、`bitrate` 字段取决于系统 `getTrackDescription` 能提供的信息）。
- 切换音轨时混合流加分离流类型的资源目前不支持。
- `setMixWithOthers` 仍未达到 Android/iOS 的系统级焦点语义，只能提供 OHOS AVPlayer 可支持的中断模式映射。
- 画质轨"恢复自适应"（`selectVideoTrack(null)`）为近似实现：OHOS AVPlayer 无清除单条画质轨选择的接口，只能回退到默认轨道，无法真正做到 Android/iOS 的"清除 override 恢复自适应"。

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
└─ test/                # Dart 单元测试
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/CPF-Flutter/flutter_packages/issues) ，当然，也非常欢迎发 [PR](https://gitcode.com/CPF-Flutter/flutter_packages/pulls) 共建。

## 开源协议

本项目基于 [The BSD-3-Clause License (BSD-3-Clause)](https://github.com/flutter/packages/blob/main/packages/video_player/video_player/LICENSE) ，请自由地享受和参与开源。
