// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_ohos/local_auth_ohos.dart';

const MethodChannel _channel = MethodChannel(
  'plugins.flutter.io/local_auth_ohos',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OhosAuthMessages.args', () {
    test('returns every default value when no message is provided', () {
      expect(const OhosAuthMessages().args, <String, String>{
        'biometricHint': ohosBiometricHint,
        'biometricNotRecognized': ohosBiometricNotRecognized,
        'biometricSuccess': ohosBiometricSuccess,
        'biometricRequired': ohosBiometricRequiredTitle,
        'cancelButton': ohosCancelButton,
        'deviceCredentialsRequired': ohosDeviceCredentialsRequiredTitle,
        'deviceCredentialsSetupDescription':
            ohosDeviceCredentialsSetupDescription,
        'goToSetting': goToSettings,
        'goToSettingDescription': ohosGoToSettingsDescription,
        'signInTitle': ohosSignInTitle,
        'authType': '',
      });
    });

    test('uses provided values for every field', () {
      expect(
        const OhosAuthMessages(
          biometricHint: 'custom hint',
          biometricNotRecognized: 'custom not recognized',
          biometricRequiredTitle: 'custom biometric required',
          biometricSuccess: 'custom success',
          cancelButton: 'custom cancel',
          deviceCredentialsRequiredTitle: 'custom credentials required',
          deviceCredentialsSetupDescription: 'custom setup description',
          goToSettingsButton: 'custom go to settings',
          goToSettingsDescription: 'custom settings description',
          signInTitle: 'custom sign in',
          authType: 'FACE',
        ).args,
        <String, String>{
          'biometricHint': 'custom hint',
          'biometricNotRecognized': 'custom not recognized',
          'biometricRequired': 'custom biometric required',
          'biometricSuccess': 'custom success',
          'cancelButton': 'custom cancel',
          'deviceCredentialsRequired': 'custom credentials required',
          'deviceCredentialsSetupDescription': 'custom setup description',
          'goToSetting': 'custom go to settings',
          'goToSettingDescription': 'custom settings description',
          'signInTitle': 'custom sign in',
          'authType': 'FACE',
        },
      );
    });

    test('biometricRequiredTitle overrides biometricRequired', () {
      expect(
        const OhosAuthMessages(
          biometricRequiredTitle: 'Biometric hardware required',
        ).args['biometricRequired'],
        'Biometric hardware required',
      );
    });

    test(
      'deviceCredentialsRequiredTitle overrides deviceCredentialsRequired',
      () {
        expect(
          const OhosAuthMessages(
            deviceCredentialsRequiredTitle: 'Set a screen lock first',
          ).args['deviceCredentialsRequired'],
          'Set a screen lock first',
        );
      },
    );

    test('goToSettingsButton overrides goToSetting', () {
      expect(
        const OhosAuthMessages(
          goToSettingsButton: 'Open settings',
        ).args['goToSetting'],
        'Open settings',
      );
    });

    test('goToSettingsDescription overrides goToSettingDescription', () {
      expect(
        const OhosAuthMessages(
          goToSettingsDescription: 'Enroll a fingerprint in Settings',
        ).args['goToSettingDescription'],
        'Enroll a fingerprint in Settings',
      );
    });

    test('only the overridden field differs from the defaults', () {
      final Map<String, String> defaultArgs = const OhosAuthMessages().args;
      final Map<String, String> overriddenArgs = const OhosAuthMessages(
        biometricRequiredTitle: 'Biometric hardware required',
        deviceCredentialsRequiredTitle: 'Set a screen lock first',
        goToSettingsButton: 'Open settings',
        goToSettingsDescription: 'Enroll a fingerprint in Settings',
      ).args;

      expect(overriddenArgs.keys, unorderedEquals(defaultArgs.keys));
      for (final MapEntry<String, String> entry in defaultArgs.entries) {
        final String? overridden = overriddenArgs[entry.key];
        if (const <String>{
          'biometricRequired',
          'deviceCredentialsRequired',
          'goToSetting',
          'goToSettingDescription',
        }.contains(entry.key)) {
          expect(overridden, isNot(entry.value));
        } else {
          expect(overridden, entry.value);
        }
      }
    });
  });

  group('OhosAuthMessages equality', () {
    const OhosAuthMessages base = OhosAuthMessages(
      biometricHint: 'hint',
      biometricNotRecognized: 'not recognized',
      biometricRequiredTitle: 'biometric required',
      biometricSuccess: 'success',
      cancelButton: 'cancel',
      deviceCredentialsRequiredTitle: 'credentials required',
      deviceCredentialsSetupDescription: 'setup description',
      goToSettingsButton: 'go to settings',
      goToSettingsDescription: 'settings description',
      signInTitle: 'sign in',
      authType: 'FACE',
    );

    test('is equal to an identically configured instance', () {
      const OhosAuthMessages equal = OhosAuthMessages(
        biometricHint: 'hint',
        biometricNotRecognized: 'not recognized',
        biometricRequiredTitle: 'biometric required',
        biometricSuccess: 'success',
        cancelButton: 'cancel',
        deviceCredentialsRequiredTitle: 'credentials required',
        deviceCredentialsSetupDescription: 'setup description',
        goToSettingsButton: 'go to settings',
        goToSettingsDescription: 'settings description',
        signInTitle: 'sign in',
        authType: 'FACE',
      );

      expect(base, equals(equal));
      expect(base.hashCode, equal.hashCode);
    });

    test('is equal to itself (identical instance)', () {
      expect(base == base, isTrue);
    });

    test('is not equal to other types', () {
      expect(base == Object(), isFalse);
    });

    test('differs when any single field differs', () {
      const List<OhosAuthMessages> variants = <OhosAuthMessages>[
        OhosAuthMessages(
          biometricHint: 'other hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'other not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'other biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'other success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'other cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'other credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'other setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'other go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'other settings description',
          signInTitle: 'sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'other sign in',
          authType: 'FACE',
        ),
        OhosAuthMessages(
          biometricHint: 'hint',
          biometricNotRecognized: 'not recognized',
          biometricRequiredTitle: 'biometric required',
          biometricSuccess: 'success',
          cancelButton: 'cancel',
          deviceCredentialsRequiredTitle: 'credentials required',
          deviceCredentialsSetupDescription: 'setup description',
          goToSettingsButton: 'go to settings',
          goToSettingsDescription: 'settings description',
          signInTitle: 'sign in',
          authType: 'FINGERPRINT',
        ),
      ];

      expect(variants, hasLength(11));
      for (final OhosAuthMessages variant in variants) {
        expect(base == variant, isFalse, reason: '$variant should differ');
        // Every field participates in the hash, so each variant must hash
        // differently from the base instance.
        expect(variant.hashCode, isNot(base.hashCode));
      }
    });

    test('default instances are equal and share a hash code', () {
      const OhosAuthMessages first = OhosAuthMessages();
      const OhosAuthMessages second = OhosAuthMessages();

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });
  });

  group('authenticate forwards OhosAuthMessages', () {
    test('passes every customized message value to the channel', () async {
      Map<dynamic, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        expect(call.method, 'authenticate');
        capturedArgs = call.arguments as Map<dynamic, dynamic>;
        return true;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, null);
      });

      final LocalAuthOhos plugin = LocalAuthOhos();
      final bool result = await plugin.authenticate(
        localizedReason: 'reason',
        authMessages: <AuthMessages>[
          const OhosAuthMessages(
            biometricHint: 'forwarded hint',
            biometricNotRecognized: 'forwarded not recognized',
            biometricRequiredTitle: 'forwarded biometric required',
            biometricSuccess: 'forwarded success',
            cancelButton: 'forwarded cancel',
            deviceCredentialsRequiredTitle: 'forwarded credentials required',
            deviceCredentialsSetupDescription: 'forwarded setup description',
            goToSettingsButton: 'forwarded go to settings',
            goToSettingsDescription: 'forwarded settings description',
            signInTitle: 'forwarded sign in',
            authType: 'FACE',
          ),
        ],
      );

      expect(result, isTrue);
      expect(capturedArgs, isNotNull);
      expect(capturedArgs!['biometricHint'], 'forwarded hint');
      expect(capturedArgs!['biometricNotRecognized'], 'forwarded not recognized');
      expect(capturedArgs!['biometricRequired'], 'forwarded biometric required');
      expect(capturedArgs!['biometricSuccess'], 'forwarded success');
      expect(capturedArgs!['cancelButton'], 'forwarded cancel');
      expect(
        capturedArgs!['deviceCredentialsRequired'],
        'forwarded credentials required',
      );
      expect(
        capturedArgs!['deviceCredentialsSetupDescription'],
        'forwarded setup description',
      );
      expect(capturedArgs!['goToSetting'], 'forwarded go to settings');
      expect(
        capturedArgs!['goToSettingDescription'],
        'forwarded settings description',
      );
      expect(capturedArgs!['signInTitle'], 'forwarded sign in');
      expect(capturedArgs!['authType'], 'FACE');
    });
  });
}
