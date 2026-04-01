# Flutter Packages

## 仓库介绍

本仓库基于 Flutter 社区官方插件库（[flutter/packages](https://github.com/flutter/packages/)）进行扩展，新增对 OpenHarmony 平台的兼容适配。通过本仓库，开发者可在 Flutter 应用中无缝集成常用插件，通过最小化业务改动获得完整的OpenHarmony原生能力支持。

[OpenHarmony平台已适配packages三方库](#packages)

[OpenHarmony平台已适配三方库列表](https://gitcode.com/OpenHarmony-Flutter/docs/blob/main/ThirdpartyLibrarites.md)

> 三方库问题请在对应仓库提交 issue；三方库适配请求请至 [OpenHarmony-Flutter](https://gitcode.com/org/openharmony-flutter/issues) 组织提交 issue。

## 开始使用

使用本仓库插件前，请确保已完成 Flutter SDK 的 OpenHarmony 环境配置。

- **环境搭建**

  参考 [flutter_flutter](https://gitcode.com/openharmony-tpc/flutter_flutter) 仓库文档 `【环境配置】`。

- **示例参考**

  前往 [flutter_samples](https://gitcode.com/openharmony-tpc/flutter_samples) 仓库获取集成示例 Demo。
  

## 引用方式

适配了OpenHarmony的三方库需通过Git仓库引入。除必填的 `url` 外，常用参数如下：

- `path` : 库在仓库中的实际路径，否则可能找不到 `pubspec.yaml`。
- `ref`（可选） : 指定要拉取的版本，可以是 **分支名**、**标签（tag）** 或 **commit id**，不写则使用仓库默认分支。

**按分支引用（branch）:**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v21.2.0 # 分支名
```

**按标签引用（tag)：**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: gitee/pigeon-v11.0.1	# 发布标签
```

## 使用示例

### 一、工具库pigeon使用

1. 引入pigeon库，在pubspec.yaml中dev_dependencies新增配置：

   ```yaml
   dev_dependencies:
     pigeon:
       git:
         url: https://gitcode.com/openharmony-tpc/flutter_packages.git
         path: packages/pigeon
         ref: br_pigeon-v26.1.5_ohos
   ```

2. 项目根目录运行 `flutter pub get`。

3. 项目根目录运行 `flutter pub run pigeon --input <dart通信模型文件路径> --arkts_out <arkts平台方法代码输出文件路径，示例./ohos/entry/src/main/ets/xxx.ets>`，将会生成Flutter与OpenHarmony平台通信的模板代码。

4. 调用示例，参考packages/pigeon/example/app/ohos/entry/src/main/ets/plugins/MessagePlugin.ets。

### 二、 插件库使用

以 path_provider 举例：

1. 在引用的项目中，pubspec.yaml中dependencies新增配置：

    ```yaml
    dependencies:
      path_provider:
        git:
          url: https://gitcode.com/openharmony-tpc/flutter_packages.git
          path: packages/path_provider/path_provider
          ref: br_path_provider-v2.1.5_ohos
    ```
    
2. 项目根目录运行 `flutter pub get`，ohos/entry/oh-package.json5会自动添加相关插件har依赖。

3. 在业务代码中调用path_provider相关api，它会在OpenHarmony平台正常运行。

   示例：在某个Flutter兼容OpenHarmony项目中加入支持OpenHarmony平台的path_provider库依赖。

   可参考示例：[pictures_provider_demo](https://gitcode.com/openharmony-tpc/flutter_samples/tree/master/ohos/pictures_provider_demo)


## <a id='packages'>OpenHarmony平台已适配packages三方库</a>

| 序号 | 原库名                                                       | 3.7推荐使用版本                                              | 3.22推荐使用版本                                             | 3.27推荐使用版本                                             | 3.35推荐使用版本                                             | 仓库名                                                       | 状态   |      |
| ---- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------ | ---- |
| 1    | [pigeon](https://pub.dev/packages/pigeon)                    | [14.0.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pigeon) | [21.2.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon) | [25.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_pigeon-v25.3.2_ohos/packages/pigeon) | [26.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_pigeon-v26.1.5_ohos) | pigeon                                                       | 已适配 |      |
| 2    | [file_selector](https://pub.dev/packages/file_selector)      | [1.0.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos) | file_selector                                                | 已适配 |      |
| 3    | [image_picker](https://pub.dev/packages/image_picker)        | [1.0.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/image_picker) | [1.1.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker) | [1.1.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker) | [1.2.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.2.1_ohos) | image_picker                                                 | 已适配 |      |
| 4    | [animations](https://pub.dev/packages/animations)            | [2.0.8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/animations) | [2.0.8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/animations) | [2.0.11](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_animations-v2.0.11_ohos/packages/animations) | [2.0.11](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_animations-v2.0.11_ohos) | animations                                                   | 已适配 |      |
| 5    | [url_launcher](https://pub.dev/packages/url_launcher)        | [6.1.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/url_launcher) | [6.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher-v6.3.0_ohos) | [6.3.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher_v6.3.1_ohos) | [6.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher-v6.3.2_ohos) | url_launcher                                                 | 已适配 |      |
| 6    | [shared_preferences](https://pub.dev/packages/shared_preferences) | [2.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/shared_preferences) | [2.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos/packages/shared_preferences) | [2.5.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos/packages/shared_preferences) | [2.5.4](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos) | shared_preferences                                           | 已适配 |      |
| 7    | [path_provider](https://pub.dev/packages/path_provider)      | [2.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/path_provider) | [2.1.4](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.4_ohos/packages/path_provider) | [2.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider) | [2.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.5_ohos) | path_provider                                                | 已适配 |      |
| 8    | [local_auth](https://pub.dev/packages/local_auth)            | [2.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/local_auth) | [2.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth) | [2.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth) | [3.0.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v3.0.0_ohos) | local_auth                                                   | 已适配 |      |
| 9    | [camera](https://pub.dev/packages/camera)                    | [0.10.5+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/camera) | [0.11.0+2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.0+2_ohos/packages/camera) | [0.11.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.1_ohos/packages/camera) | [0.11.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.3_ohos) | camera                                                       | 已适配 |      |
| 10   | [video_player](https://pub.dev/packages/video_player)        | [2.7.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/video_player) | [2.9.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.9.2_ohos/packages/video_player) | [2.10.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.10.0_ohos/packages/video_player) | [2.10.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.10.1_ohos) | video_player                                                 | 已适配 |      |
| 11   | [webview_flutter](https://pub.dev/packages/webview_flutter)  | [4.4.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter) | [4.8.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos/packages/webview_flutter) | [4.13.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter) | [4.13.0](https://gitcode.com/openharmony-tpc/flutter_packages/commits/br_webview_flutter-v4.13.0_ohos) | webview_flutter                                              | 已适配 |      |
| 12   | [webview_flutter-v4.4.4](https://pub.dev/packages/webview_flutter) | [4.4.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter-v4.4.4) | -                                                            | -                                                            | -                                                            | webview_flutter-v4.4.4                                       | 已适配 |      |
| 13   | [in_app_purchase](https://pub.dev/packages/in_app_purchase)  | [3.1.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/in_app_purchase) | [3.2.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos/packages/in_app_purchase) | [3.2.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase) | [3.2.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase) | in_app_purchase                                              | 已适配 |      |
| 14   | [css_colors](https://pub.dev/packages/css_colors)            | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | css_colors                                                   | 未适配 |      |
| 15   | [espresso](https://pub.dev/packages/espresso)                | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | espresso                                                     | 未适配 |      |
| 16   | [extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | extension_google_sign_in_as_googleapis_auth                  | 未适配 |      |
| 17   | [flutter_adaptive_scaffold](https://pub.dev/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | flutter_adaptive_scaffold                                    | 未适配 |      |
| 18   | [flutter_image](https://pub.dev/packages/flutter_image)      | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | flutter_image                                                | 未适配 |      |
| 19   | [flutter_lints](https://pub.dev/packages/flutter_lints)      | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | flutter_lints                                                | 未适配 |      |
| 20   | [flutter_markdown](https://pub.dev/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | flutter_markdown                                             | 未适配 |      |
| 21   | [flutter_migrate](https://pub.dev/packages/flutter_migrate)  | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | flutter_migrate                                              | 未适配 |      |
| 22   | [flutter_plugin_android_lifecycle](https://pub.dev/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | flutter_plugin_android_lifecycle                             | 未适配 |      |
| 23   | [flutter_template_images](https://pub.dev/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | flutter_template_images                                      | 未适配 |      |
| 24   | [go_router](https://pub.dev/packages/go_router)              | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | go_router                                                    | 未适配 |      |
| 25   | [go_router_builder](https://pub.dev/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | go_router_builder                                            | 未适配 |      |
| 26   | [google_identity_services_web](https://pub.dev/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | google_identity_services_web                                 | 未适配 |      |
| 27   | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | google_maps_flutter                                          | 未适配 |      |
| 28   | [google_sign_in](https://pub.dev/packages/google_sign_in)    | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | google_sign_in                                               | 未适配 |      |
| 29   | [ios_platform_images](https://pub.dev/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | ios_platform_images                                          | 未适配 |      |
| 30   | [metrics_center](https://pub.dev/packages/metrics_center)    | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | metrics_center                                               | 未适配 |      |
| 31   | [multicast_dns](https://pub.dev/packages/multicast_dns)      | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | multicast_dns                                                | 未适配 |      |
| 32   | [palette_generator](https://pub.dev/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | palette_generator                                            | 未适配 |      |
| 33   | [pointer_interceptor](https://pub.dev/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | pointer_interceptor                                          | 未适配 |      |
| 34   | [rfw](https://pub.dev/packages/rfw)                          | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | rfw                                                          | 未适配 |      |
| 35   | [standard_message_codec](https://pub.dev/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | standard_message_codec                                       | 未适配 |      |
| 36   | [two_dimensional_scrollables](https://pub.dev/packages/two_dimensional_scrollables) | -                                                            | -                                                            | -                                                            | -                                                            | [two_dimensional_scrollables](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/two_dimensional_scrollables) | 未适配 |      |
| 37   | [web_benchmarks](https://pub.dev/packages/web_benchmarks)    | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | web_benchmarks                                               | 未适配 |      |
| 38   | [webview_flutter_platform_interface](https://pub.dev/packages/webview_flutter_platform_interface) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | webview_flutter_platform_interface                           | 未适配 |      |
| 39   | [xdg_directories](https://pub.dev/packages/xdg_directories)  | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | xdg_directories                                              | 未适配 |      |

## FAQ

1. 运行 `flutter pub get` 遇到 `"File name too long"` 问题。

   打开 `Git Bash` 或 `运行 cmd`（需要将git添加到环境变量中），执行以下命令：

    ``` 
      git config --global core.longpaths true
    ```

## 问题交流

- 问题反馈：欢迎在 [Flutter框架仓库](https://gitcode.com/openharmony-tpc/flutter_flutter/issues) 以及各个Flutter三方库提交issue。
