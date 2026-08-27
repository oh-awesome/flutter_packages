## video_player-v2.7.2-ohos-1.0.2-2026.8

**Fixed**
* Fix an occasional crash  where a non-`PlatformException` error emitted on the main package's event stream could make the error listener crash when casting, instead of surfacing a readable error message.