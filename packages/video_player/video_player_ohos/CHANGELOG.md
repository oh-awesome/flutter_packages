# CHANGELOG for OpenHarmony

## video_player-v2.14.0-ohos-1.0.1-2026.9

**Added**

* Support `VideoViewType.platformView` via HCPP and the same AVPlayer as texture, drawing to an XComponent surface. Requires `flutter run --enable-hcpp`. Texture remains the default. Volume, speed, HTTP headers, and track selection match the texture path.
* Example: SDR/HDR toggle so Asset, Remote, and LocalFile can compare Texture vs Platform view with the same HDR clip. Remote HDR copies `assets/video_hdr_hlg.mp4` to a temp `file://` network source when no HTTP URL is set.
* Example: ship the HLG sample as `assets/video_hdr_hlg.mp4` so HDR Asset demos run without a local copy.
* Pass `playerId`, source, `objectFit`, looping and speed to the HCPP PlatformView factory through `creationParams`.
* Fail `initialize` with `hcpp_unavailable` when `platformView` is requested but Hybrid Composition++ is not enabled, instead of creating a player that cannot be composited.
* Example: a page that plays through the app-facing `VideoPlayerController` and `VideoPlayer`, so platform view is not mounted early by `MiniController`.

**Fixed**

* Give every reader of a packaged asset its own descriptor. `getRawFd` returns one shared HAP fd per path and the media service reads it by its file offset, so two players (or a player and a metadata probe) on the same asset corrupted each other's reads and stopped about one second in. Each player and each preview/metadata probe now reopens the fd through `/proc/self/fd`, keeping the rawfile offset and length. If reopening fails, the shared descriptor is used as before.
* Remove the Platform view player record when `create` fails after the record is stored.
* Keep Flutter play/pause overlays above the HCPP surface. The platform view does not take pointer events.
* Emit the first `platformView` `initialized` from `create`, with width, height, and duration probed before the source is set so the probe and `AVPlayer` never read the file at the same time. `AVPlayer` does not report the initial `idle`, so waiting for it left `VideoPlayerController` + `VideoPlayer` black (mounted first) or on the placeholder (mounted after `isInitialized`). If probing fails, width and height stay 0 in that event, and `PREPARED` does not emit a second `initialized`.
* Hold volume, looping, and playback speed set before `prepared` and apply them once `prepared`, instead of calling `AVPlayer` in a state that raises `5400102` and resets the player. Before the first `prepared`, a Platform view `5400102` from the error callback is ignored so reset does not clear queued calls or the only `initialized` event. `prepare()` failures are still reported. Track queries and track selection wait until `prepared`, and time out instead of hanging. Opening a file tries the original `file://` string first, then a decoded sandbox path. A failed open does not create a player with `fd://-1`.
* Reset the cached playback speed when `AVPlayer` returns to `idle`, so the same speed can be applied again after a reset.
* Read `AVMetadata.duration` as milliseconds. It no longer divides values of 10,000,000 or more by 1000, which shortened videos longer than about 2.8 hours.
* Close the Dart-opened `fd://` when `platformView` create fails, the same as the texture failure path. A player that was created still closes that fd in `release()`.
* Apply `setWindowKeepScreenOn` on the Platform view path while playing; a missing window does not fail `create`.
* On engine detach, unregister a Flutter texture only for players that registered one. Platform view ids come from the same engine counter but are not registered as textures.
* Example `MiniController.dispose` no longer hangs when `create` fails (`hcpp_unavailable` / missing asset).
* Example Remote SDR auto-plays after `initialize`, matching Asset / LocalFile.
* Example Remote HDR uses the bundled HLG asset as a `file://` network source when no HTTP URL is pasted.
* Replay from the start on the Platform view path after `completed`, matching Texture `shouldReplayFromStart`.

## video_player-v2.14.0-ohos-1.0.0-2026.8

**Added**

* Add `getVideoTracks`, `selectVideoTrack`, and `enableAutoVideoQuality` to support video quality selection on HLS/DASH adaptive streams.
* Support packaged assets via the `package` parameter when playing assets.
* Generate the VideoTrack label from the resolution when the native track has no label, matching Android behavior.
* Make `dispose` asynchronous so player release is awaited before completing.

**Fixed**

* Catch sync assignment failures for `url`/`fdSrc`/`surfaceId` on the critical prepare path and report them to Flutter so the `initialized` future no longer hangs.
* Move texture registration into the create `try` block and unregister the texture on failure to avoid half-registered state.
* Throw `IllegalStateException` from `play`/`pause`/`seekTo`/`setLooping`/`setVolume`/`setPlaybackSpeed` when the player is missing, consistent with `dispose`/`position`.
* Make `release()` idempotent to guard against concurrent dispose and engine detach.
* Compensate plugin initialization order: create the API channels after engine attach when `onAttachedToAbility` ran first.
* Validate Pigeon channel arguments (array shape, length, non-null) before casting, avoiding `undefined` leaking downstream.
* Null-check `globalVideoList`/`screenWidth` from the global context before use.
* Close external `fd://` file descriptors on release to prevent fd leaks.
* Reply `notImplemented` for unknown method-channel calls so Dart futures no longer hang forever.
* Track and dispose the black background PixelMap, and recycle file descriptors opened for `file://` sources when create fails.
* Remove the cached window reference once all players are disposed.
* Stop the buffering-info polling timer on AVPlayer error and restore the original window keep-screen-on state on release.
* Re-apply `setMediaSource` (preserving http headers and format hint) for HTTP URLs after the player is reset, instead of overwriting `avPlayer.url`.
* Truncate the reported playback position to whole milliseconds to avoid double-to-int precision issues.
* Fix an occasional crash  where a non-`PlatformException` error emitted on the main package's event stream could make the error listener crash when casting, instead of surfacing a readable error message.
