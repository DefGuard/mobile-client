import 'dart:typed_data';

import 'package:device_identity_plugin/device_identity_plugin.dart';
import 'package:device_identity_plugin/device_identity_plugin_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelDeviceIdentityPlugin();

  void answer(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, handler);

  Matcher throwsCode(IdentityErrorCode code) => throwsA(
    isA<DeviceIdentityException>().having((error) => error.code, 'code', code),
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  test(
    'generation forwards the alias and challenge and decodes the chain',
    () async {
      final challenge = Uint8List.fromList([1, 2, 3]);
      final leaf = Uint8List.fromList([4, 5]);
      final issuer = Uint8List.fromList([6, 7]);
      answer((call) async {
        expect(call.method, 'generateAttestedIdentity');
        final arguments = call.arguments as Map<Object?, Object?>;
        expect(arguments['alias'], 'identity-1');
        expect(arguments['challengeData'], orderedEquals(challenge));
        return [leaf, issuer];
      });

      final chain = await platform.generateAttestedIdentity(
        'identity-1',
        challenge,
      );

      expect(chain, hasLength(2));
      expect(chain[0], orderedEquals(leaf));
      expect(chain[1], orderedEquals(issuer));
    },
  );

  test('signing forwards exact bytes and decodes the signature', () async {
    final data = Uint8List.fromList([8, 0, 9]);
    final signature = Uint8List.fromList([10, 11, 12]);
    answer((call) async {
      expect(call.method, 'signPossession');
      final arguments = call.arguments as Map<Object?, Object?>;
      expect(arguments['alias'], 'identity-2');
      expect(arguments['data'], orderedEquals(data));
      return signature;
    });

    final result = await platform.signPossession('identity-2', data);

    expect(result, orderedEquals(signature));
  });

  test('identity lookup forwards the alias and decodes the result', () async {
    answer((call) async {
      expect(call.method, 'hasIdentity');
      expect((call.arguments as Map<Object?, Object?>)['alias'], 'identity-3');
      return true;
    });

    expect(await platform.hasIdentity('identity-3'), isTrue);
  });

  test('deletion forwards the alias', () async {
    answer((call) async {
      expect(call.method, 'deleteIdentity');
      expect((call.arguments as Map<Object?, Object?>)['alias'], 'identity-4');
      return null;
    });

    await expectLater(platform.deleteIdentity('identity-4'), completes);
  });

  test('a malformed certificate chain maps to backend failure', () async {
    answer(
      (_) async => [
        Uint8List.fromList([1]),
        'not bytes',
      ],
    );

    await expectLater(
      platform.generateAttestedIdentity('identity', Uint8List.fromList([1])),
      throwsCode(IdentityErrorCode.backendFailure),
    );
  });

  test('a malformed signature maps to backend failure', () async {
    answer((_) async => 'not bytes');

    await expectLater(
      platform.signPossession('identity', Uint8List.fromList([1])),
      throwsCode(IdentityErrorCode.backendFailure),
    );
  });

  const platformErrorCodes = <String, IdentityErrorCode>{
    'UNSPECIFIED': IdentityErrorCode.unspecified,
    'UNAVAILABLE': IdentityErrorCode.unavailable,
    'TEMPORARILY_UNAVAILABLE': IdentityErrorCode.temporarilyUnavailable,
    'TIMEOUT': IdentityErrorCode.timeout,
    'RATE_LIMITED': IdentityErrorCode.rateLimited,
    'PERMISSION_DENIED': IdentityErrorCode.permissionDenied,
    'UNSUPPORTED': IdentityErrorCode.unsupported,
    'IDENTITY_LOST': IdentityErrorCode.identityLost,
    'INVALID_CHALLENGE': IdentityErrorCode.invalidChallenge,
    'BACKEND_FAILURE': IdentityErrorCode.backendFailure,
    'INVALID_EVIDENCE': IdentityErrorCode.invalidEvidence,
    'CHALLENGE_EXPIRED': IdentityErrorCode.challengeExpired,
  };

  for (final entry in platformErrorCodes.entries) {
    test('maps ${entry.key} to ${entry.value.name}', () async {
      answer(
        (_) async => throw PlatformException(code: entry.key),
      );

      await expectLater(
        platform.hasIdentity('identity'),
        throwsCode(entry.value),
      );
    });
  }

  test('an unknown platform error maps to backend failure', () async {
    answer((_) async => throw PlatformException(code: 'UNKNOWN_NATIVE_CODE'));

    await expectLater(
      platform.hasIdentity('identity'),
      throwsCode(IdentityErrorCode.backendFailure),
    );
  });
}
