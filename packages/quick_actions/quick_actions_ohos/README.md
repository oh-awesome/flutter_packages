# quick\_actions\_ohos

The OpenHarmony (OHOS) implementation of [`quick_actions`][1].

## Usage

This package is [endorsed][2], which means you can simply use `quick_actions`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

## Shortcut Icons

To use custom icons, add resource files under `resources/base/media/` in your
OHOS module. Reference them by name (without extension) in the `icon` field of
`ShortcutItem`.

[1]: https://pub.dev/packages/quick_actions
[2]: https://flutter.dev/to/endorsed-federated-plugin
