// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_ohos/local_auth_ohos.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

Map<String, dynamic> _expectedAuthenticateArgs({
  required String localizedReason,
  required bool useErrorDialogs,
  required bool stickyAuth,
  required bool sensitiveTransaction,
  required bool biometricOnly,
  OhosAuthMessages? messages,
}) {
  return <String, dynamic>{
    'localizedReason': localizedReason,
    'useErrorDialogs': useErrorDialogs,
    'stickyAuth': stickyAuth,
    'sensitiveTransaction': sensitiveTransaction,
    'biometricOnly': biometricOnly,
  }
    ..addAll(const OhosAuthMessages().args)
    ..addAll(messages?.args ?? const <String, String>{});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAuthOhos', () {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/local_auth_ohos',
    );

    final List<MethodCall> log = <MethodCall>[];
    late LocalAuthOhos localAuthentication;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getEnrolledBiometrics':
            return Future<List<String>>.value(
              <String>['face', 'fingerprint', 'unknown'],
            );
          default:
            return Future<dynamic>.value(true);
        }
      });
      localAuthentication = LocalAuthOhos();
      log.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('registers instance', () {
      final LocalAuthPlatform original = LocalAuthPlatform.instance;
      addTearDown(() => LocalAuthPlatform.instance = original);

      LocalAuthOhos.registerWith();

      expect(LocalAuthPlatform.instance, isA<LocalAuthOhos>());
    });

    test('deviceSupportsBiometrics calls platform', () async {
      final bool result = await localAuthentication.deviceSupportsBiometrics();

      expect(
        log,
        <Matcher>[
          isMethodCall('deviceSupportsBiometrics', arguments: null),
        ],
      );
      expect(result, isTrue);
    });

    test('deviceSupportsBiometrics returns false when channel returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'deviceSupportsBiometrics') {
          return null;
        }
        return true;
      });

      expect(await localAuthentication.deviceSupportsBiometrics(), isFalse);
    });

    test('getEnrolledBiometrics calls platform', () async {
      final List<BiometricType> result =
          await localAuthentication.getEnrolledBiometrics();

      expect(
        log,
        <Matcher>[
          isMethodCall('getEnrolledBiometrics', arguments: null),
        ],
      );
      expect(result, <BiometricType>[
        BiometricType.face,
        BiometricType.fingerprint,
      ]);
    });

    test('getEnrolledBiometrics returns empty list when channel returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getEnrolledBiometrics') {
          return null;
        }
        return true;
      });

      expect(await localAuthentication.getEnrolledBiometrics(), isEmpty);
    });

    test('isDeviceSupported calls platform', () async {
      await localAuthentication.isDeviceSupported();
      expect(
        log,
        <Matcher>[
          isMethodCall('isDeviceSupported', arguments: null),
        ],
      );
    });

    test('stopAuthentication calls platform', () async {
      await localAuthentication.stopAuthentication();
      expect(
        log,
        <Matcher>[
          isMethodCall('stopAuthentication', arguments: null),
        ],
      );
    });

    group('authenticate', () {
      test('with biometricOnly and default Ohos messages', () async {
        await localAuthentication.authenticate(
          authMessages: <AuthMessages>[const OhosAuthMessages()],
          localizedReason: 'Needs secure',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'authenticate',
              arguments: _expectedAuthenticateArgs(
                localizedReason: 'Needs secure',
                useErrorDialogs: true,
                stickyAuth: false,
                sensitiveTransaction: true,
                biometricOnly: true,
                messages: const OhosAuthMessages(),
              ),
            ),
          ],
        );
      });

      test('with custom options and Ohos messages', () async {
        const OhosAuthMessages customMessages = OhosAuthMessages(
          biometricHint: 'Hint',
          cancelButton: 'Cancel',
          signInTitle: 'Sign in',
          authType: 'FACE',
        );
        await localAuthentication.authenticate(
          authMessages: <AuthMessages>[customMessages],
          localizedReason: 'Insecure',
          options: const AuthenticationOptions(
            sensitiveTransaction: false,
            useErrorDialogs: false,
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'authenticate',
              arguments: _expectedAuthenticateArgs(
                localizedReason: 'Insecure',
                useErrorDialogs: false,
                stickyAuth: true,
                sensitiveTransaction: false,
                biometricOnly: true,
                messages: customMessages,
              ),
            ),
          ],
        );
      });

      test('with default options', () async {
        await localAuthentication.authenticate(
          authMessages: <AuthMessages>[const OhosAuthMessages()],
          localizedReason: 'Needs secure',
        );
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'authenticate',
              arguments: _expectedAuthenticateArgs(
                localizedReason: 'Needs secure',
                useErrorDialogs: true,
                stickyAuth: false,
                sensitiveTransaction: true,
                biometricOnly: false,
                messages: const OhosAuthMessages(),
              ),
            ),
          ],
        );
      });

      test('returns false when channel returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            return false;
          }
          return true;
        });

        expect(
          await localAuthentication.authenticate(
            localizedReason: 'reason',
            authMessages: <AuthMessages>[],
          ),
          isFalse,
        );
      });

      test('ignores non-Ohos auth messages', () async {
        await localAuthentication.authenticate(
          authMessages: <AuthMessages>[const _UnsupportedAuthMessages()],
          localizedReason: 'reason',
        );
        final Map<dynamic, dynamic> args =
            log.single.arguments as Map<dynamic, dynamic>;
        expect(args.containsKey('ignored'), isFalse);
        expect(args['authType'], '');
      });
    });
  });
}

class _UnsupportedAuthMessages extends AuthMessages {
  const _UnsupportedAuthMessages();

  @override
  Map<String, String> get args => <String, String>{'ignored': 'ignored'};
}
