# video_player_example

`video_player_ohos` 示例工程。

## 运行

```bash
cd packages/video_player/video_player_ohos/example
flutter run --enable-hcpp
```

`platformView` 依赖引擎 Hybrid Composition++。也可在 `ohos/entry/src/main/resources/rawfile/buildinfo.json5` 中设置 `enable_ohos_hybrid_composition: true`。

未开启 HCPP 时，Texture view 可正常出画；Platform view 的 `initialize` 会以 `hcpp_unavailable` 失败。

## HDR 对比

首页顶部 **SDR | HDR** 默认 HDR。下面三个源 Tab（Asset / Remote / LocalFile）各带 Texture view | Platform view，用来对照同一条 HLG 片。

HDR 样片已放入 `assets/video_hdr_hlg.mp4`（HEVC / BT.2020 / HLG）。

1. **Asset**：直接播放仓库内 `assets/video_hdr_hlg.mp4`。

2. **Remote**：没有稳定的公开 HDR HTTP 地址。默认把 `assets/video_hdr_hlg.mp4` 拷到临时目录，用 `MiniController.network` + `file://` 走网络数据源（和 Asset 同一条 HLG 片）。仍可改填 http(s) URL，或 hdc 推送后点「用推送 HDR 走 network」。

3. **LocalFile**：自动找沙箱 `files/` 或 `/data/local/tmp/`，也可文件选择器。

```bash
hdc file send packages/video_player/video_player_ohos/example/assets/video_hdr_hlg.mp4 /data/local/tmp/video_hdr_hlg.mp4
hdc file send packages/video_player/video_player_ohos/example/assets/video_hdr_hlg.mp4 /data/app/el2/100/base/<bundleName>/haps/entry/files/video_hdr_hlg.mp4
```

`bundleName` 以 `ohos/AppScope/app.json5` 为准。切回 **SDR** 时 Asset 仍是 `video1.mp4`，Remote 仍是 Sintel trailer。
