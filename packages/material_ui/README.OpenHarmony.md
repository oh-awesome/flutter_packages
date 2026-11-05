# material_ui (OpenHarmony)

This project is based on
[material_ui@1.9.0](https://pub.dev/packages/material_ui/versions/1.9.0).

## Introduction

`material_ui` provides Material Design widgets for Flutter applications. This
project adapts the package for OpenHarmony.

## Installation

Add the dependency to the pubspec.yaml of your project:

```yaml
dependencies:
  material_ui:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/material_ui"
      # Select a branch/TAG containing the adaptation for your Flutter version.
      ref: oh-3.47.7-dev
```

Run the following command to install the dependency:

```bash
flutter pub get
```

## Constraints and Limitations

### Compatibility

Use a Flutter SDK with OpenHarmony support. The package requires Flutter
`>=3.47.0` and Dart `^3.13.0`.

Adaptation environment:

| Tool or system | Version |
| --- | --- |
| Flutter | 3.47.7+ohos-0.0.1-canary1 |
| DevEco Studio | 26.0.0 Release (26.0.0.821) |
| SDK | 5.0.5(17) |
| ROM | 7.0.0.111 SP10 |

## Usage

Import the widget library in your Dart file:

```dart
import 'package:material_ui/material_ui.dart';
```

See [README.md](README.md) for widget usage and migration instructions, and
[example](example/README.md) for more examples.

## Contributing

Report problems through [Issues](https://gitcode.com/CPF-Flutter/flutter_packages/issues)
or contribute code through [PRs](https://gitcode.com/CPF-Flutter/flutter_packages/pulls).

## License

This project is licensed under the [BSD-3-Clause License](LICENSE).
