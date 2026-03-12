## Warehouse introduction

This repository is an extension of the Flutter community’s official plugin library ([flutter/packages](vscode-file://vscode-app/e:/Microsoft VS Code/resources/app/out/vs/code/electron-browser/workbench/workbench.html)), adding compatibility and adaptation for the OpenHarmony platform. With this repository, developers can seamlessly integrate commonly used plugins into Flutter applications and gain full support for OpenHarmony native capabilities with minimal business changes.

## Getting Started

Before using the plugins from this repository, please ensure that you have completed the OpenHarmony environment setup for the Flutter SDK.

- **Environment Setup**

  Refer to the documentation in the [flutter_flutter](https://gitcode.com/openharmony-tpc/flutter_flutter) repository under the section “Environment Configuration”.

- **Example Reference**

  Visit the  [flutter_samples](https://gitcode.com/openharmony-tpc/flutter_samples) repository to find integration demo examples.

## Dependency Reference

Third-party libraries adapted for OpenHarmony should be imported via Git repository. In addition to the required `url` field, commonly used parameters are as follows:

- `path`: The actual path to the library within the repository; otherwise, `pubspec.yaml` may not be found.
- `ref` (optional): Specifies the version to fetch, which can be a **branch name**, **tag**, or **commit ID**. If omitted, the repository's default branch will be used.



**Reference by Branch:**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: pigeon-v21.2.0 # Branch name
```

**Reference by Tag**：

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: gitee/pigeon-v11.0.1	# Release tag
```

**Reference by Commit ID (Recommended for precise version locking)：**

```yaml
dev_dependencies:
  pigeon:
    git:
      url: https://gitcode.com/openharmony-tpc/flutter_packages.git
      path: packages/pigeon
      ref: f5a64d90e140a378ffc18962590f57c8d81bff9c	# commit ID
```

> **Tip**: Using a **commit ID** precisely pins a specific commit, making it immune to subsequent branch or tag changes—ideal for production dependencies requiring high stability. Tags are suitable for semantic versioning, while branches are appropriate for tracking active development branches.



## Usage Examples

### 1. Use of tool library pigeon

1. Introduce the pigeon library and add new configuration to dev_dependencies in pubspec.yaml:

    ```yaml
    dependencies:
      pigeon:
        git:
          url: https://gitcode.com/openharmony-tpc/flutter_packages.git
          path: packages/pigeon
    ```
    
2. Run `flutter pub get` in the project root directory;

3. Run `flutter pub run pigeon in the project root directory --input <dart communication model file path> --arkts_out <arkts platform method code output file path, example./ohos/entry/src/main/ets/xxx.ets> `

The template code for communication between Flutter and the OpenHarmony platform will be generated;

4. For calling examples, refer to packages/pigeon/example/app/ohos/entry/src/main/ets/plugins/MessagePlugin.ets

### 2. Use of plug-in library

Take path_provider as an example:
1. In the referenced project, add new dependencies configuration in pubspec.yaml:

   ```yaml
   dependencies:
     path_provider:
       git:
         url: https://gitcode.com/openharmony-tpc/flutter_packages.git
         path: packages/path_provider/path_provider
   ```
   
2. Run `flutter pub get` in the project root directory; (ohos/entry/oh-package.json5 will automatically add related plug-in har dependencies)

3. Call the path_provider related API in the business code, and it will run normally on the OpenHarmony platform.

Example: Add the path_provider library dependency that supports the OpenHarmony platform to a Flutter-compatible OpenHarmony project;

Reference examples: https://gitcode.com/openharmony-tpc/flutter_samples/tree/master/ohos/pictures_provider_demo.


## OpenHarmony platform has compatible with third-party libraries and packages.

| No | Initial Warehouse Name                                 | 3.7 Recommended Version                       | 3.22 Recommended Version                     | 3.27 Recommended Version                     | 3.35 Recommended Version                                     | Warehouse Name                                               | Is Compatible                      |      |
| ---- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------ | ---- |
| 1    | [pigeon](https://pub.dev/packages/pigeon)                    | [14.0.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pigeon) | [21.2.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/pigeon-v21.2.0/packages/pigeon) | [25.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_pigeon-v25.3.2_ohos/packages/pigeon) | [26.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_pigeon-v26.1.5_ohos) | pigeon                                                       | Yes |      |
| 2    | [file_selector](https://pub.dev/packages/file_selector)      | [1.0.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos/packages/file_selector) | [1.0.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_file_selector-v1.0.3_ohos) | file_selector                                                | Yes |      |
| 3    | [image_picker](https://pub.dev/packages/image_picker)        | [1.0.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/image_picker) | [1.1.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker) | [1.1.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.1.2_ohos/packages/image_picker) | [1.2.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_image_picker-v1.2.1_ohos) | image_picker                                                 | Yes |      |
| 4    | [animations](https://pub.dev/packages/animations)            | [2.0.8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/animations) | [2.0.8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/animations) | [2.0.11](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_animations-v2.0.11_ohos/packages/animations) | [2.0.11](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_animations-v2.0.11_ohos) | animations                                                   | Yes |      |
| 5    | [url_launcher](https://pub.dev/packages/url_launcher)        | [6.1.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/url_launcher) | [6.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher-v6.3.0_ohos) | [6.3.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher_v6.3.1_ohos) | [6.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_url_launcher-v6.3.2_ohos) | url_launcher                                                 | Yes |      |
| 6    | [shared_preferences](https://pub.dev/packages/shared_preferences) | [2.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/shared_preferences) | [2.3.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.3.2_ohos/packages/shared_preferences) | [2.5.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.5.3_ohos/packages/shared_preferences) | [2.5.4](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_shared_preferences-v2.5.4_ohos) | shared_preferences                                           | Yes |      |
| 7    | [path_provider](https://pub.dev/packages/path_provider)      | [2.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/path_provider) | [2.1.4](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.4_ohos/packages/path_provider) | [2.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.5_ohos/packages/path_provider) | [2.1.5](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_path_provider-v2.1.5_ohos) | path_provider                                                | Yes |      |
| 8    | [local_auth](https://pub.dev/packages/local_auth)            | [2.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/local_auth) | [2.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth) | [2.3.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v2.3.0_ohos/packages/local_auth) | [3.0.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_local_auth-v3.0.0_ohos) | local_auth                                                   | Yes |      |
| 9    | [camera](https://pub.dev/packages/camera)                    | [0.10.5+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/camera) | [0.11.0+2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.0+2_ohos/packages/camera) | [0.11.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.1_ohos/packages/camera) | [0.11.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_camera-v0.11.3_ohos) | camera                                                       | Yes |      |
| 10   | [video_player](https://pub.dev/packages/video_player)        | [2.7.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/video_player) | [2.9.2](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.9.2_ohos/packages/video_player) | [2.10.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.10.0_ohos/packages/video_player) | [2.10.1](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_video_player-v2.10.1_ohos) | video_player                                                 | Yes |      |
| 11   | [webview_flutter](https://pub.dev/packages/webview_flutter)  | [4.4.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter) | [4.8.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_webview_flutter-v4.8.0_ohos/packages/webview_flutter) | [4.13.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_webview_flutter-v4.13.0_ohos/packages/webview_flutter) | [4.13.0](https://gitcode.com/openharmony-tpc/flutter_packages/commits/br_webview_flutter-v4.13.0_ohos) | webview_flutter                                              | Yes |      |
| 12   | [webview_flutter-v4.4.4](https://pub.dev/packages/webview_flutter) | [4.4.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter-v4.4.4) | -                                                            | -                                                            | -                                                            | webview_flutter-v4.4.4                                       | Yes |      |
| 13   | [in_app_purchase](https://pub.dev/packages/in_app_purchase)  | [3.1.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/in_app_purchase) | [3.2.0](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.0_ohos/packages/in_app_purchase) | [3.2.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase) | [3.2.3](https://gitcode.com/openharmony-tpc/flutter_packages/tree/br_in_app_purchase-v3.2.3_ohos/packages/in_app_purchase) | in_app_purchase                                              | Yes |      |
| 14   | [css_colors](https://pub.dev/packages/css_colors)            | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | [1.1.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/css_colors) | css_colors                                                   | No |      |
| 15   | [espresso](https://pub.dev/packages/espresso)                | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | [0.3.0+6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/espresso) | espresso                                                     | No |      |
| 16   | [extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | [2.0.11](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/extension_google_sign_in_as_googleapis_auth) | extension_google_sign_in_as_googleapis_auth                  | No |      |
| 17   | [flutter_adaptive_scaffold](https://pub.dev/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | [0.1.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_adaptive_scaffold) | flutter_adaptive_scaffold                                    | No |      |
| 18   | [flutter_image](https://pub.dev/packages/flutter_image)      | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | [4.1.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_image) | flutter_image                                                | No |      |
| 19   | [flutter_lints](https://pub.dev/packages/flutter_lints)      | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | [2.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_lints) | flutter_lints                                                | No |      |
| 20   | [flutter_markdown](https://pub.dev/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | [0.6.15](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_markdown) | flutter_markdown                                             | No |      |
| 21   | [flutter_migrate](https://pub.dev/packages/flutter_migrate)  | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | [0.1.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_migrate) | flutter_migrate                                              | No |      |
| 22   | [flutter_plugin_android_lifecycle](https://pub.dev/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | [2.0.17](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_plugin_android_lifecycle) | flutter_plugin_android_lifecycle                             | No |      |
| 23   | [flutter_template_images](https://pub.dev/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | [4.2.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/flutter_template_images) | flutter_template_images                                      | No |      |
| 24   | [go_router](https://pub.dev/packages/go_router)              | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | [12.1.1](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router) | go_router                                                    | No |      |
| 25   | [go_router_builder](https://pub.dev/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | [2.3.4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/go_router_builder) | go_router_builder                                            | No |      |
| 26   | [google_identity_services_web](https://pub.dev/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | [0.2.2](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_identity_services_web) | google_identity_services_web                                 | No |      |
| 27   | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | [2.3.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_maps_flutter) | google_maps_flutter                                          | No |      |
| 28   | [google_sign_in](https://pub.dev/packages/google_sign_in)    | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | [6.1.6](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/google_sign_in) | google_sign_in                                               | No |      |
| 29   | [ios_platform_images](https://pub.dev/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | [0.2.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/ios_platform_images) | ios_platform_images                                          | No |      |
| 30   | [metrics_center](https://pub.dev/packages/metrics_center)    | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | [1.0.12](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/metrics_center) | metrics_center                                               | No |      |
| 31   | [multicast_dns](https://pub.dev/packages/multicast_dns)      | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | [0.3.2+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/multicast_dns) | multicast_dns                                                | No |      |
| 32   | [palette_generator](https://pub.dev/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | [0.3.3+3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/palette_generator) | palette_generator                                            | No |      |
| 33   | [pointer_interceptor](https://pub.dev/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | [0.9.3+5](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/pointer_interceptor) | pointer_interceptor                                          | No |      |
| 34   | [rfw](https://pub.dev/packages/rfw)                          | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | [1.0.9](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/rfw) | rfw                                                          | No |      |
| 35   | [standard_message_codec](https://pub.dev/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | [0.0.1+4](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/standard_message_codec) | standard_message_codec                                       | No |      |
| 36   | [two_dimensional_scrollables](https://pub.dev/packages/two_dimensional_scrollables) | -                                                            | -                                                            | -                                                            | -                                                            | [two_dimensional_scrollables](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/two_dimensional_scrollables) | No |      |
| 37   | [web_benchmarks](https://pub.dev/packages/web_benchmarks)    | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | [0.1.0+8](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/web_benchmarks) | web_benchmarks                                               | No |      |
| 38   | [webview_flutter_platform_interface](https://pub.dev/packages/webview_flutter_platform_interface) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | [2.6.0](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/webview_flutter_platform_interface-v2.10.0) | webview_flutter_platform_interface                           | No |      |
| 39   | [xdg_directories](https://pub.dev/packages/xdg_directories)  | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | [1.0.3](https://gitcode.com/openharmony-sig/flutter_packages/tree/master/packages/xdg_directories) | xdg_directories                                              | No |      |


## OpenHarmony platform has compatible third-party libraries

[See](https://gitcode.com/OpenHarmony-Flutter/docs/blob/main/ThirdpartyLibrarites.en.md)

## FAQ

### 1. Run `flutter pub get` displayed `"File name too long"` error

Open the `Git Bash` or `cmd.exe`(you need to have git as an environment variable) and execute the following command:
``` 
  git config --global core.longpaths true
```
