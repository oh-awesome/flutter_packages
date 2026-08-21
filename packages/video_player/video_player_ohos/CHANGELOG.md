# CHANGELOG for OpenHarmony

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
