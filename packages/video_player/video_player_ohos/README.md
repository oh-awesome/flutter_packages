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

## HDR Video Playback Integration

OpenHarmony `video_player` supports ordinary video playback through the default
texture path. This path renders decoded frames through Flutter's texture, so
10-bit, BT.2020, PQ, and HLG content is converted to SDR during composition.
To preserve HDR output, request `VideoViewType.platformView` and enable the
engine's Hybrid Composition++ (HCPP). The same `AVPlayer` is used, but frames
are drawn to an ArkUI `XComponent` surface that the engine keeps in a DISPLAY
system layer instead of sampling through a Flutter texture.

| Rendering path | Application setting | Output | Notes |
| --- | --- | --- | --- |
| **Texture (default)** | Omit `viewType` | `AVPlayer` + Flutter texture | Existing applications keep working; HDR is converted to SDR. |
| **PlatformView + HCPP** | Set `viewType: VideoViewType.platformView` and enable HCPP | `AVPlayer` + `XComponent` surface + DISPLAY layer | Volume, speed, headers, audio tracks, and video tracks use the same implementation as the texture path. |

### Select PlatformView

Use an OHOS `video_player` main package that supports
`VideoViewType.platformView`, its matching `video_player_ohos` implementation,
and an OHOS engine that includes HCPP. Select dependency refs from the release
notes for your Flutter OH SDK. Network playback also requires the
[network permission](#permission-requirements). Keep the main-package import
and `VideoPlayer` widget from the usage example above.

The controller must be created with the platform view type; it cannot be
changed after `initialize()`. To switch rendering paths, dispose the controller
and create a new one:

```dart
final controller = VideoPlayerController.networkUrl(
  uri,
  viewType: VideoViewType.platformView,
);
await controller.initialize();
await controller.play();
```

The same option is available for assets and local files:

```dart
VideoPlayerController.asset(
  'videos/demo.mp4',
  viewType: VideoViewType.platformView,
);
VideoPlayerController.file(
  file,
  viewType: VideoViewType.platformView,
);
```

`VideoPlayer` must be mounted in the widget tree. `initialize()` may complete
before the `XComponent` is loaded and the AVPlayer is prepared, so calls such
as `play`, `setVolume`, `setPlaybackSpeed`, and looping are queued until the
surface is attached and the player enters `prepared`. The deprecated
`VideoPlayerPlatform.create(DataSource)` API
still creates a texture player; use `VideoPlayerController` to select the HDR
path.

### Enable HCPP

HCPP is disabled by default. The two supported ways to enable it are:

```bash
flutter run --enable-hcpp
```

For a packaged application, merge the following configuration into
`ohos/entry/src/main/resources/rawfile/buildinfo.json5`, preserving existing
entries in the `string` array:

```json5
{
  "string": [
    {
      "name": "enable_ohos_hybrid_composition",
      "value": "true"
    }
  ]
}
```

The command-line option is written into `buildinfo.json5` during the build.
After changing the option, perform a full rebuild; hot restart does not update
the packaged configuration. In 3.44 toolchain revisions that preserve manual
HCPP configuration, `flutter run` without `--enable-hcpp` keeps an existing
value. Other SDK revisions may behave differently; check the final packaged
HAP. A missing file, invalid JSON, missing entry, or a value other than
`"true"` is treated as disabled. The
plugin reads this file to check HCPP, and the engine uses it to set the startup
argument. The CLI, buildinfo, and engine names are
`--enable-hcpp`, `enable_ohos_hybrid_composition`, and
`--enable-ohos-hybrid-composition`, respectively.

If HCPP is not enabled, `initialize()` fails with
`PlatformException(code: hcpp_unavailable)`. The plugin does not silently fall
back to a texture view, because that would make an application appear to use
HDR while producing SDR output. Fix the HCPP configuration instead of catching
this error and silently switching to texture. Internally, the plugin uses
`initExpensiveOhosView` to retain the `RENDER_TYPE_DISPLAY` layer;
`initSurfaceOhosView` would rasterize the native view back into a texture and
lose HDR. Applications do not need to call either engine API.

### PlatformView behavior and troubleshooting

The PlatformView path uses the same AVPlayer capabilities as the texture path:

| Capability | PlatformView behavior |
| --- | --- |
| Play, pause, seek, position | Supported; `play` and seek requested before `prepared` are queued. |
| Volume, speed, looping | Supported; values set before `prepared` are applied when preparation completes. |
| HTTP headers, audio tracks, video tracks | Supported. Track operations wait for `prepared` and may take up to 15 seconds. |
| `formatHint`, `contentUri`, `backBufferDurationMs` | Not mapped to AVPlayer on either rendering path. |

The main differences from the texture path are:

- There is no texture first-frame placeholder; the image appears after the
  `XComponent` produces its first frame.
- Duration and dimensions come from metadata probing before the source is set.
  If probing fails, they can remain `0` and the aspect ratio becomes `1.0`.
  HTTP/HTTPS metadata probing is skipped on API levels below 20. The
  `initialized` event is sent only once, so the metadata is not updated after
  `prepared`; use the texture path when accurate duration and aspect ratio are
  required.
- Removing `VideoPlayer` from the tree only detaches the surface. Call
  `controller.dispose()` to release the AVPlayer.
- The native surface ignores pointer events so Flutter controls remain above
  the video (`IgnorePointer` and `HitTestMode.None`). Do not wrap it in another
  native view that captures those events.
- If no window is available, PlatformView creation still succeeds, but
  keep-screen-on has no effect. Texture player creation fails in that case.

| Symptom | Cause and action |
| --- | --- |
| `hcpp_unavailable` | Enable HCPP with `--enable-hcpp` or set `enable_ohos_hybrid_composition` to `"true"`, then rebuild the HAP. |
| HDR looks like SDR | Confirm both `viewType: VideoViewType.platformView` and HCPP are enabled, and perform a full rebuild. |
| The example reports a missing HDR asset | Read the following `PlatformException`; `hcpp_unavailable` indicates that HCPP is not enabled. |
| No public HDR URL is available | Copy a sample to the device and pass a local `file://` URI to `networkUrl` to validate the network-source entry point. This does not test HTTP/HTTPS streaming. |
| `initialize()` completes but no frame appears | Mount `VideoPlayer` so that `XComponent.onLoad` can provide a surface. Queued `play()` calls then proceed. |
| Controls do not respond | Ensure the PlatformView is not wrapped by another native view that intercepts touch events. |
| Playback restarts after a list item returns | Removing the widget only detaches the `XComponent`; keep the controller and dispose it only when the player is no longer needed. |
| Duration stays at zero or the video is square | Metadata probing failed; use the texture path when accurate initial metadata is required. |
| Multiple players show the wrong image | Check each controller's `playerId`; texture and PlatformView players share the engine's monotonically increasing ID source. |

### HDR acceptance check

Use a physical device with HEVC/HLG decoding and an HDR display, along with the
bundled [HLG sample](./example/assets/video_hdr_hlg.mp4) (HEVC / BT.2020 / HLG).
From the plugin's `example` directory, run:

```bash
flutter pub get
flutter run --enable-hcpp
```

1. Select **HDR**, open **Asset**, and switch between **Texture view** and
   **Platform view** to compare the same source. The SDR/HDR source toggle does
   not replace this rendering-path comparison.
2. Platform view should display frames and respond to play, pause, seek, and
   Flutter overlay controls. In `hdc hilog` or DevEco Studio logs, confirm
   `HCPP pre-check enable_ohos_hybrid_composition=true` and
   `XComponent onLoad playerId=...` with a valid `surfaceId`, with no
   `hcpp_unavailable` error.
3. `display hdrFormats=...` only reports the display's advertised capabilities.
   Confirm actual HDR output using the target device's HDR status or display
   diagnostics, and record the device, system version, source, and result.
   Brightness differences, successful initialization, and these logs alone do
   not prove HDR output. If output status cannot be inspected, record actual
   HDR output as pending device verification.

## Usage Notes

- This implementation renders video with `Texture` by default.
- `VideoViewType.platformView` uses the same `AVPlayer` as the texture path, drawing into an `XComponent` surface through Hybrid Composition++ (DISPLAY layer, not Flutter Texture). Volume, speed, mix-with-others, HTTP headers, and audio/video track selection match the texture path. Enable HCPP with `flutter run --enable-hcpp`, or set `enable_ohos_hybrid_composition: true` in the app `buildinfo.json5`. Without HCPP, `initialize` fails with `PlatformException(code: hcpp_unavailable)` and does not fall back to a texture view.
- `DataSourceType.file` supports `fd://` file descriptor paths on OHOS. Both the texture path and `platformView` close the fd when the player is released.
- `setPlaybackSpeed` supports: `0.125x`, `0.25x`, `0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`, `1.75x`, `2.0x`, `3.0x`.
  - **Difference from Android**: Android's `ExoPlayer` tolerates a wider continuous range (typically `0.25x ~ 4.0x`), while OHOS `AVPlayer` only supports discrete preset speed levels. If the requested value is not in the OHOS supported list, the plugin will **map it to the nearest supported level**.
  - **OHOS Playback Speed Mapping Table**:

    | Input Range | Effective Speed | Notes |
    | :--- | :--- | :--- |
    | `< 0.125` | `0.125x` | Falls back to the minimum level |
    | `0.125 ~ 0.25` | `0.25x` | Maps to `0.25x` |
    | `0.25 ~ 0.5` | `0.5x` | Maps to `0.5x` |
    | `0.5 ~ 0.75` | `0.75x` | Maps to `0.75x` |
    | `0.75 ~ 1.0` | `1.0x` | Normal speed |
    | `1.0 ~ 1.25` | `1.25x` | Maps to `1.25x` |
    | `1.25 ~ 1.5` | `1.5x` | Maps to `1.5x` |
    | `1.5 ~ 1.75` | `1.75x` | Maps to `1.75x` |
    | `1.75 ~ 2.0` | `2.0x` | Maps to `2.0x` |
    | `2.0 ~ 3.0` | `3.0x` | Maps to `3.0x` |
    | `> 3.0` | `3.0x` | Falls back to the maximum level |
  - The table applies to both the texture path and `platformView`. Both call `AVPlayer.setSpeed`.
- Audio and video track APIs (`getAudioTracks`, `selectAudioTrack`, `getVideoTracks`, `selectVideoTrack`) use the same AVPlayer implementation on both paths.
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
| formatHint                          | 属性 | 无                                  | `VideoFormat`                   | 未映射      | Optional format hint. Neither path writes it to `setMimeType`.      |
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
- Supports `VideoViewType.platformView` (requires engine Hybrid Composition++).

## Known Issues

- Obtain the legacy audio track data of the audio track and the differences (language, codec, bitrate) from other platforms.
- Currently, resources of the mixed stream and separated stream types are not supported when switching audio tracks.
- `setMixWithOthers` function still does not reach the system-level focus semantics of Android/iOS and can only provide the interruption mode mapping supported by OHOS AVPlayer. Both the texture path and `platformView` use that mapping.

## FAQ

- `initialize` throws `hcpp_unavailable`: `platformView` requires Hybrid Composition++. Use an engine that includes HCPP, and run with `--enable-hcpp` (or set `enable_ohos_hybrid_composition` to `true` in `buildinfo.json5`).
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
