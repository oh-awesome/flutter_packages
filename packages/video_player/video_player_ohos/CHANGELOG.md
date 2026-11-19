## video_player-v2.11.1-ohos-1.0.2 - 2026.11

**Fixed**
* Fix a memory leak where the background PixelMap of a video texture was never released, causing memory usage to grow as players were created and disposed.

## video_player-v2.11.1-ohos-1.0.1-2026.8

**Fixed**
* Fix an occasional crash  where a non-`PlatformException` error emitted on the main package's event stream could make the error listener crash when casting, instead of surfacing a readable error message.
