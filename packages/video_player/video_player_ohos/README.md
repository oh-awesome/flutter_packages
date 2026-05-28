# video\_player\_ohos

This project provides the OpenHarmony adaptation of [video\_player@2.11.1](https://pub.dev/packages/video_player/versions/2.11.1).

## Introduction

`video_player_ohos` is the OpenHarmony implementation of `video_player`, with support for player creation, playback control, position synchronization, event streaming, and audio track selection. In most apps, you depend on `video_player` directly and the OHOS backend is selected automatically.

## Installation

Add dependency in your app `pubspec.yaml`:

```yaml
dependencies:
  video_player:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/video_player/video_player
      ref: br_video_player-v2.11.1_ohos
```

Install dependencies:

```bash
flutter pub get
```
## Constraints

### Compatibility

1.Flutter: 3.35.8-ohos-0.0.3; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1 Developer Beta;

2.Flutter: 3.41.10-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.1.1.268; ROM: 6.1 Developer Beta;

### Permission Requirements

For network playback, declare network permission. For local-only playback, this permission is optional.

`entry/src/main/module.json5` example:

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

`entry/src/main/resources/base/element/string.json` example:

```json
{
  "string": [
    {
      "name": "network_reason",
      "value": "Used for online video playback"
    }
  ]
}
```

> Note: If your app requests `system_basic` permissions but signature/level settings are not aligned, HAP installation may fail with `9568289`. Follow OpenHarmony permission-level requirements.

## Usage Example

The snippet below covers import, initialization, call flow, and result output:

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
    // 1) Initialize controller
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://media.w3.org/2010/05/sintel/trailer.mp4'),
    );
    // 2) Initialize and print result
    _controller.initialize().then((_) {
      debugPrint('Video initialized: ${_controller.value.size}');
      setState(() {});
      // 3) Start playback
      _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4) Render playback result
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

## Usage Notes

- This implementation renders video with `Texture` by default.
- `platformView` video rendering is not exposed at the moment. This is not because OHOS lacks native `XComponent + AVPlayer` capability, but because the current `flutter_ohos` `PlatformView` path still relies on texture-based composition and does not match the media `XComponent` video output path well enough. In practice it can lead to cases such as audio playing without visible video, so it is not documented as a stable capability.
- `DataSourceType.file` supports `fd://` file descriptor paths on OHOS.
- `setPlaybackSpeed` supports: `0.125x`, `0.25x`, `0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`, `1.75x`, `2.0x`, `3.0x`.
- Audio track APIs are supported: `getAudioTracks`, `selectAudioTrack`, `isAudioTrackSupportAvailable`.
- See [example](./example) for full demos.

## API Reference

### API Summary

> Note: In column "类型", only "方法" and "属性" are used for consistency with the Chinese README.

| 名称                                  | 类型 | 参数类型                               | 返回值                             | ohos平台支持 | 描述                                                                  |
| ----------------------------------- | -- | ---------------------------------- | ------------------------------- | -------- | ------------------------------------------------------------------- |
| init                                | 方法 | 无                                  | `Future<void>`                  | 是        | Initializes the platform channel and clears stale player instances. |
| dispose                             | 方法 | `int textureId`                    | `Future<void>`                  | 是        | Disposes resources for the specified player instance.               |
| create                              | 方法 | `DataSource`                       | `Future<int?>`                  | 是        | Creates a player and returns `textureId`.                           |
| setLooping                          | 方法 | `int textureId, bool looping`      | `Future<void>`                  | 是        | Sets whether playback loops.                                        |
| play                                | 方法 | `int textureId`                    | `Future<void>`                  | 是        | Starts playback for the target player.                              |
| pause                               | 方法 | `int textureId`                    | `Future<void>`                  | 是        | Pauses playback for the target player.                              |
| setVolume                           | 方法 | `int textureId, double volume`     | `Future<void>`                  | 是        | Sets output volume, typically from `0.0` to `1.0`.                  |
| seekTo                              | 方法 | `int textureId, Duration position` | `Future<void>`                  | 是        | Seeks playback to a target position.                                |
| getPosition                         | 方法 | `int textureId`                    | `Future<Duration>`              | 是        | Gets current playback position.                                     |
| videoEventsFor                      | 方法 | `int textureId`                    | `Stream<VideoEvent>`            | 是        | Subscribes to player event stream.                                  |
| setMixWithOthers                    | 方法 | `bool mixWithOthers`               | `Future<void>`                  | 是        | Sets whether audio mixes with other sources.                        |
| setPlaybackSpeed                    | 方法 | `int textureId, double speed`      | `Future<void>`                  | 是        | Sets playback speed, where `speed > 0`.                             |
| getAudioTracks                      | 方法 | `int playerId`                     | `Future<List<VideoAudioTrack>>` | 是        | Returns available audio tracks of the current media.                |
| selectAudioTrack                    | 方法 | `int playerId, String trackId`     | `Future<void>`                  | 是        | Switches to the specified audio track.                              |
| sourceType                          | 属性 | 无                                  | `DataSourceType`                | 是        | Defines source mode: asset/network/file/contentUri.                 |
| uri                                 | 属性 | 无                                  | `String?`                       | 是        | URI of the video source.                                            |
| formatHint                          | 属性 | 无                                  | `VideoFormat`                   | 是        | Optional format hint that overrides default format detection.       |
| asset                               | 属性 | 无                                  | `String?`                       | 是        | Name of the bundled asset.                                          |
| package                             | 属性 | 无                                  | `String?`                       | 是        | Package name that provides the asset.                               |
| httpHeaders                         | 属性 | 无                                  | `Map<String, String>`           | 是        | HTTP request headers.                                               |
| DataSourceType.asset                | 属性 | 无                                  | `enum`                          | 是        | App asset source.                                                   |
| DataSourceType.network              | 属性 | 无                                  | `enum`                          | 是        | Network source.                                                     |
| DataSourceType.file                 | 属性 | 无                                  | `enum`                          | 是        | Local file source.                                                  |
| DataSourceType.contentUri           | 属性 | 无                                  | `enum`                          | 否        | Video via contentUri, Android-only scenario.                        |
| VideoFormat.dash                    | 属性 | 无                                  | `enum`                          | 是        | Dynamic Adaptive Streaming over HTTP (MPEG-DASH).                   |
| VideoFormat.hls                     | 属性 | 无                                  | `enum`                          | 是        | HTTP Live Streaming (HLS).                                          |
| VideoFormat.ss                      | 属性 | 无                                  | `enum`                          | 否        | Smooth Streaming.                                                   |
| VideoFormat.other                   | 属性 | 无                                  | `enum`                          | 否        | Other formats.                                                      |
| eventType                           | 属性 | 无                                  | `VideoEventType`                | 是        | Event type.                                                         |
| duration                            | 属性 | 无                                  | `Duration?`                     | 是        | Video duration.                                                     |
| size                                | 属性 | 无                                  | `Size?`                         | 是        | Video size.                                                         |
| rotationCorrection                  | 属性 | 无                                  | `int?`                          | 是        | Clockwise rotation needed for correct display.                      |
| buffered                            | 属性 | 无                                  | `List<DurationRange>?`          | 是        | Buffered ranges of the video.                                       |
| isPlaying                           | 属性 | 无                                  | `bool?`                         | 是        | Whether the video is currently playing.                             |
| VideoEventType.initialized          | 属性 | 无                                  | `enum`                          | 是        | Video initialization completed.                                     |
| VideoEventType.completed            | 属性 | 无                                  | `enum`                          | 是        | Playback completed.                                                 |
| VideoEventType.bufferingUpdate      | 属性 | 无                                  | `enum`                          | 是        | Buffering state updated.                                            |
| VideoEventType.bufferingStart       | 属性 | 无                                  | `enum`                          | 是        | Buffering started.                                                  |
| VideoEventType.bufferingEnd         | 属性 | 无                                  | `enum`                          | 是        | Buffering ended.                                                    |
| VideoEventType.isPlayingStateUpdate | 属性 | 无                                  | `enum`                          | 是        | Playback state changed.                                             |
| VideoEventType.unknown              | 属性 | 无                                  | `enum`                          | 是        | Unknown event received.                                             |

## New Features

- Supports audio track listing and track switching.
- Supports local playback via OHOS file descriptor path (`fd://`).

## Known Issues

- Rendering is currently fixed to `Texture`; `platformView` mode is not exposed.
- Obtain the legacy audio track data of the audio track and the differences (language, codec, bitrate) from other platforms.
- Currently, resources of the mixed stream and separated stream types are not supported when switching audio tracks.
- `setMixWithOthers` function still does not reach the system-level focus semantics of Android/iOS and can only provide the interruption mode mapping supported by OHOS AVPlayer.

## FAQ

- Network video cannot play: verify `ohos.permission.INTERNET` is configured.
- Local file fails: verify path accessibility, or pass a valid `fd://` source.
- Playback speed has no effect: ensure the speed value is in the supported list.

## Directory Structure

```text
video_player_ohos/
├─ lib/                 # Dart-side implementation and exports
├─ ohos/                # OpenHarmony native ETS implementation
├─ pigeons/             # Pigeon message definitions
├─ example/             # Example project
├─ test/                # Dart unit tests
└─ doc/                 # Adaptation notes and feature matrix
```

## Contributing

Contributions are welcome through Issues and Pull Requests:

- Issue: <https://gitcode.com/openharmony-tpc/flutter_packages/issues>
- PR: <https://gitcode.com/openharmony-tpc/flutter_packages/pulls>

## License

Licensed under [The BSD-3-Clause License (BSD-3-Clause)](https://gitcode.com/openharmony-tpc/flutter_packages/blob/master/packages/video_player/video_player_ohos/LICENSE).
