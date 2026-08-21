// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_ohos/local_auth_ohos.dart';
import 'package:local_auth_ohos/types/ohos_auth_error_code.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

const MethodChannel _channel = MethodChannel(
  'plugins.flutter.io/local_auth_ohos',
);

class _UnsupportedAuthMessages extends AuthMessages {
  const _UnsupportedAuthMessages();

  @override
  Map<String, String> get args => <String, String>{'ignored': 'ignored'};
}

void _setMockHandler(Future<dynamic> Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void _clearMockHandler() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthOhos plugin;

  setUp(() {
    plugin = LocalAuthOhos();
    _clearMockHandler();
    addTearDown(_clearMockHandler);
  });

  test('registers instance', () {
    final LocalAuthPlatform original = LocalAuthPlatform.instance;
    addTearDown(() => LocalAuthPlatform.instance = original);

    LocalAuthOhos.registerWith();

    expect(LocalAuthPlatform.instance, isA<LocalAuthOhos>());
  });

  group('deviceSupportsBiometrics', () {
    test('returns true', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'deviceSupportsBiometrics');
        return true;
      });

      expect(await plugin.deviceSupportsBiometrics(), isTrue);
    });

    test('returns false when the channel returns null', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'deviceSupportsBiometrics');
        return null;
      });

      expect(await plugin.deviceSupportsBiometrics(), isFalse);
    });
  });

  group('isDeviceSupported', () {
    test('returns true', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'isDeviceSupported');
        return true;
      });

      expect(await plugin.isDeviceSupported(), isTrue);
    });

    test('returns false', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'isDeviceSupported');
        return false;
      });

      expect(await plugin.isDeviceSupported(), isFalse);
    });
  });

  group('stopAuthentication', () {
    test('returns true', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'stopAuthentication');
        return true;
      });

      expect(await plugin.stopAuthentication(), isTrue);
    });

    test('returns false', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'stopAuthentication');
        return false;
      });

      expect(await plugin.stopAuthentication(), isFalse);
    });
  });

  group('getEnrolledBiometrics', () {
    test('maps known values and ignores unknown values', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'getEnrolledBiometrics');
        return <String>['face', 'fingerprint', 'unknown'];
      });

      expect(await plugin.getEnrolledBiometrics(), <BiometricType>[
        BiometricType.face,
        BiometricType.fingerprint,
      ]);
    });

    test('returns an empty list when the channel returns null', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'getEnrolledBiometrics');
        return null;
      });

      expect(await plugin.getEnrolledBiometrics(), isEmpty);
    });
  });

  group('authenticate', () {
    Future<Map<dynamic, dynamic>> captureAuthenticateArguments({
      required Iterable<AuthMessages> authMessages,
      AuthenticationOptions options = const AuthenticationOptions(),
      String localizedReason = 'reason',
    }) async {
      final List<MethodCall> calls = <MethodCall>[];
      _setMockHandler((MethodCall call) async {
        calls.add(call);
        return true;
      });

      expect(
        await plugin.authenticate(
          localizedReason: localizedReason,
          authMessages: authMessages,
          options: options,
        ),
        isTrue,
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'authenticate');
      return calls.single.arguments as Map<dynamic, dynamic>;
    }

    Future<void> expectAuthenticateException({
      required String code,
      String? message,
      required LocalAuthExceptionCode expectedCode,
      String? expectedDescription,
    }) async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'authenticate');
        throw PlatformException(code: code, message: message);
      });

      await expectLater(
        plugin.authenticate(
          localizedReason: 'reason',
          authMessages: <AuthMessages>[],
        ),
        throwsA(
          isA<LocalAuthException>()
              .having((LocalAuthException e) => e.code, 'code', expectedCode)
              .having(
                (LocalAuthException e) => e.description,
                'description',
                expectedDescription,
              ),
        ),
      );
    }

    test('passes default Ohos values when no messages are provided', () async {
      final Map<dynamic, dynamic> args = await captureAuthenticateArguments(
        authMessages: <AuthMessages>[],
      );

      expect(args['localizedReason'], 'reason');
      expect(args['stickyAuth'], isFalse);
      expect(args['sensitiveTransaction'], isTrue);
      expect(args['biometricOnly'], isFalse);
      expect(args['biometricHint'], ohosBiometricHint);
      expect(args['biometricNotRecognized'], ohosBiometricNotRecognized);
      expect(args['biometricSuccess'], ohosBiometricSuccess);
      expect(args['biometricRequired'], ohosBiometricRequiredTitle);
      expect(args['cancelButton'], ohosCancelButton);
      expect(
        args['deviceCredentialsRequired'],
        ohosDeviceCredentialsRequiredTitle,
      );
      expect(
        args['deviceCredentialsSetupDescription'],
        ohosDeviceCredentialsSetupDescription,
      );
      expect(args['goToSetting'], goToSettings);
      expect(args['goToSettingDescription'], ohosGoToSettingsDescription);
      expect(args['signInTitle'], ohosSignInTitle);
      expect(args['authType'], '');
    });

    test(
      'passes provided Ohos values and ignores unsupported messages',
      () async {
        final Map<dynamic, dynamic> args = await captureAuthenticateArguments(
          localizedReason: 'custom reason',
          authMessages: <AuthMessages>[
            const OhosAuthMessages(
              biometricHint: 'Hint',
              cancelButton: 'Cancel',
              signInTitle: 'Sign in',
              authType: 'FACE',
            ),
            const _UnsupportedAuthMessages(),
          ],
          options: const AuthenticationOptions(
            biometricOnly: true,
            sensitiveTransaction: false,
            stickyAuth: true,
          ),
        );

        expect(args['localizedReason'], 'custom reason');
        expect(args['biometricHint'], 'Hint');
        expect(args['cancelButton'], 'Cancel');
        expect(args['signInTitle'], 'Sign in');
        expect(args['authType'], 'FACE');
        expect(args['biometricSuccess'], ohosBiometricSuccess);
        expect(args['stickyAuth'], isTrue);
        expect(args['sensitiveTransaction'], isFalse);
        expect(args['biometricOnly'], isTrue);
        expect(args.containsKey('ignored'), isFalse);
      },
    );

    test('returns false when the channel returns false', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'authenticate');
        return false;
      });

      expect(
        await plugin.authenticate(
          localizedReason: 'reason',
          authMessages: <AuthMessages>[],
        ),
        isFalse,
      );
    });

    test('maps canceled to userCanceled', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.canceled,
        expectedCode: LocalAuthExceptionCode.userCanceled,
      );
    });

    test('maps canceledFromWidget to userCanceled', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.canceledFromWidget,
        expectedCode: LocalAuthExceptionCode.userCanceled,
      );
    });

    test('maps timeout to timeout', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.timeout,
        expectedCode: LocalAuthExceptionCode.timeout,
      );
    });

    test(
      'maps generalError to unknownError with the platform message',
      () async {
        await expectAuthenticateException(
          code: OhosAuthErrorCode.generalError,
          message: 'boom',
          expectedCode: LocalAuthExceptionCode.unknownError,
          expectedDescription: 'boom',
        );
      },
    );

    test('maps typeNotSupport to noBiometricHardware', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.typeNotSupport,
        expectedCode: LocalAuthExceptionCode.noBiometricHardware,
      );
    });

    test('maps trustLevelNotSupport to noBiometricHardware', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.trustLevelNotSupport,
        expectedCode: LocalAuthExceptionCode.noBiometricHardware,
      );
    });

    test('maps busy to authInProgress', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.busy,
        expectedCode: LocalAuthExceptionCode.authInProgress,
      );
    });

    test('maps locked to temporaryLockout', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.locked,
        expectedCode: LocalAuthExceptionCode.temporaryLockout,
      );
    });

    test('maps notEnrolled to noBiometricsEnrolled', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.notEnrolled,
        expectedCode: LocalAuthExceptionCode.noBiometricsEnrolled,
      );
    });

    test('maps authInProgress to authInProgress', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.authInProgress,
        expectedCode: LocalAuthExceptionCode.authInProgress,
      );
    });

    test('maps noAbility to uiUnavailable', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.noAbility,
        expectedCode: LocalAuthExceptionCode.uiUnavailable,
        expectedDescription: 'No Ability available',
      );
    });

    test('maps notAvailable to noCredentialsSet', () async {
      await expectAuthenticateException(
        code: OhosAuthErrorCode.notAvailable,
        expectedCode: LocalAuthExceptionCode.noCredentialsSet,
        expectedDescription: 'Required security features not enabled',
      );
    });

    test('maps unknown errors to unknownError', () async {
      await expectAuthenticateException(
        code: 'unexpected',
        expectedCode: LocalAuthExceptionCode.unknownError,
        expectedDescription: 'Unknown error: unexpected',
      );
    });

    group('argument validation', () {
      test('asserts when localizedReason is empty', () async {
        // The plugin guards a non-empty reason with an assert. In test mode asserts
        // throw AssertionError, which surfaces as a failing assert rather than a
        // silent success.
        _setMockHandler((MethodCall call) async => true);

        await expectLater(
          plugin.authenticate(
            localizedReason: '',
            authMessages: <AuthMessages>[],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts all options set to non-default values', () async {
        final List<MethodCall> calls = <MethodCall>[];
        _setMockHandler((MethodCall call) async {
          calls.add(call);
          return false;
        });

        final bool result = await plugin.authenticate(
          localizedReason: 'reason',
          authMessages: <AuthMessages>[const OhosAuthMessages()],
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            sensitiveTransaction: false,
            useErrorDialogs: false,
          ),
        );

        expect(result, isFalse);
        final Map<dynamic, dynamic> args =
            calls.single.arguments as Map<dynamic, dynamic>;
        expect(args['stickyAuth'], isTrue);
        expect(args['biometricOnly'], isTrue);
        expect(args['sensitiveTransaction'], isFalse);
      });

      test('falls back to defaults when only required args are provided',
          () async {
        final List<MethodCall> calls = <MethodCall>[];
        _setMockHandler((MethodCall call) async {
          calls.add(call);
          return true;
        });

        await plugin.authenticate(
          localizedReason: 'reason',
          authMessages: <AuthMessages>[const OhosAuthMessages()],
        );

        final Map<dynamic, dynamic> args =
            calls.single.arguments as Map<dynamic, dynamic>;
        // AuthenticationOptions defaults.
        expect(args['stickyAuth'], isFalse);
        expect(args['biometricOnly'], isFalse);
        expect(args['sensitiveTransaction'], isTrue);
        // Default Ohos authType.
        expect(args['authType'], '');
      });
    });
  });

  group('permission and availability errors', () {
    test(
      'authenticate maps notAvailable when security features are not enabled',
      () async {
        _setMockHandler((MethodCall call) async {
          expect(call.method, 'authenticate');
          throw PlatformException(
            code: OhosAuthErrorCode.notAvailable,
            message: 'Required security features not enabled',
          );
        });

        await expectLater(
          plugin.authenticate(
            localizedReason: 'reason',
            authMessages: <AuthMessages>[],
          ),
          throwsA(
            isA<LocalAuthException>()
                .having(
                  (LocalAuthException e) => e.code,
                  'code',
                  LocalAuthExceptionCode.noCredentialsSet,
                )
                .having(
                  (LocalAuthException e) => e.description,
                  'description',
                  'Required security features not enabled',
                ),
          ),
        );
      },
    );

    test(
      'authenticate maps noAbility when no foreground ability is available',
      () async {
        _setMockHandler((MethodCall call) async {
          expect(call.method, 'authenticate');
          throw PlatformException(
            code: OhosAuthErrorCode.noAbility,
            message: 'local_auth plugin requires a foreground ability',
          );
        });

        await expectLater(
          plugin.authenticate(
            localizedReason: 'reason',
            authMessages: <AuthMessages>[],
          ),
          throwsA(
            isA<LocalAuthException>().having(
              (LocalAuthException e) => e.code,
              'code',
              LocalAuthExceptionCode.uiUnavailable,
            ),
          ),
        );
      },
    );

    test('authenticate surfaces a missing-plugin error when no handler is set',
        () async {
      // With no mock handler, the channel has nothing to respond and the invoke
      // fails before any LocalAuthException mapping can occur. This documents the
      // "missing backend" / unregistered-permission path: a MissingPluginException
      // escapes unchanged (it is not a PlatformException, so it bypasses mapping).
      _clearMockHandler();

      await expectLater(
        plugin.authenticate(
          localizedReason: 'reason',
          authMessages: <AuthMessages>[],
        ),
        throwsA(isA<MissingPluginException>()),
      );
    });
  });

  group('boundary scenarios', () {
    test('deviceSupportsBiometrics throws on a non-bool result type', () async {
      // invokeMethod<bool> casts the result; a non-bool (e.g. a String) fails the
      // `as bool?` cast before the `?? false` fallback can apply. This documents the
      // boundary behavior when the OHOS side returns an unexpected runtime type.
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'deviceSupportsBiometrics');
        return 'unsupported';
      });

      await expectLater(
        plugin.deviceSupportsBiometrics(),
        throwsA(isA<TypeError>()),
      );
    });

    test('isDeviceSupported returns false on a null result', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'isDeviceSupported');
        return null;
      });

      expect(await plugin.isDeviceSupported(), isFalse);
    });

    test('getEnrolledBiometrics handles an empty list', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'getEnrolledBiometrics');
        return <String>[];
      });

      expect(await plugin.getEnrolledBiometrics(), isEmpty);
    });

    test('getEnrolledBiometrics handles a large list with mixed values',
        () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'getEnrolledBiometrics');
        return <String>[
          'face',
          'fingerprint',
          'face', // duplicate
          'unknown', // ignored
          'fingerprint',
        ];
      });

      expect(
        await plugin.getEnrolledBiometrics(),
        <BiometricType>[
          BiometricType.face,
          BiometricType.fingerprint,
          BiometricType.face,
          BiometricType.fingerprint,
        ],
      );
    });

    test('repeated calls keep returning fresh results', () async {
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'deviceSupportsBiometrics');
        return true;
      });

      expect(await plugin.deviceSupportsBiometrics(), isTrue);
      expect(await plugin.deviceSupportsBiometrics(), isTrue);
      expect(await plugin.deviceSupportsBiometrics(), isTrue);
    });
  });

  group('concurrency', () {
    test('runs multiple authenticate calls concurrently', () async {
      // Concurrent invokes should each receive their own result. The mock returns
      // per-call based on the localizedReason so we can tell them apart.
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'authenticate');
        final Map<dynamic, dynamic> args =
            call.arguments as Map<dynamic, dynamic>;
        return args['localizedReason'] == 'ok';
      });

      final List<Future<bool>> futures = <Future<bool>>[
        plugin.authenticate(
          localizedReason: 'ok',
          authMessages: <AuthMessages>[],
        ),
        plugin.authenticate(
          localizedReason: 'no',
          authMessages: <AuthMessages>[],
        ),
        plugin.authenticate(
          localizedReason: 'ok',
          authMessages: <AuthMessages>[],
        ),
      ];

      final List<bool> results = await Future.wait(futures);
      expect(results, <bool>[true, false, true]);
    });

    test('mixed concurrent queries across different methods', () async {
      _setMockHandler((MethodCall call) {
        switch (call.method) {
          case 'isDeviceSupported':
            return Future<bool>.value(true);
          case 'deviceSupportsBiometrics':
            return Future<bool>.value(false);
          case 'getEnrolledBiometrics':
            return Future<List<String>>.value(<String>['face']);
          case 'stopAuthentication':
            return Future<bool>.value(true);
          default:
            return Future<dynamic>.value();
        }
      });

      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          plugin.isDeviceSupported(),
          plugin.deviceSupportsBiometrics(),
          plugin.getEnrolledBiometrics(),
          plugin.stopAuthentication(),
          plugin.isDeviceSupported(),
        ],
      );

      expect(results, <dynamic>[
        true,
        false,
        <BiometricType>[BiometricType.face],
        true,
        true,
      ]);
    });

    test('concurrent authenticate calls preserve per-call args', () async {
      final List<Map<dynamic, dynamic>> captured = <Map<dynamic, dynamic>>[];
      _setMockHandler((MethodCall call) async {
        expect(call.method, 'authenticate');
        captured.add(call.arguments as Map<dynamic, dynamic>);
        return true;
      });

      await Future.wait(<Future<bool>>[
        plugin.authenticate(
          localizedReason: 'first',
          authMessages: <AuthMessages>[const OhosAuthMessages(authType: 'FACE')],
        ),
        plugin.authenticate(
          localizedReason: 'second',
          authMessages: <AuthMessages>[
            const OhosAuthMessages(authType: 'FINGERPRINT'),
          ],
        ),
      ]);

      expect(captured, hasLength(2));
      expect(captured[0]['localizedReason'], 'first');
      expect(captured[0]['authType'], 'FACE');
      expect(captured[1]['localizedReason'], 'second');
      expect(captured[1]['authType'], 'FINGERPRINT');
    });
  });
}
