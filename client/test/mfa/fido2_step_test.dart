import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fido2_plugin/fido2_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mfa/fido2_step.dart';

class _Call {
  final String rpId;
  final Uint8List clientDataHash;
  final List<Uint8List> allowCredentials;
  final String? pin;

  const _Call(this.rpId, this.clientDataHash, this.allowCredentials, this.pin);
}

class _FakePlatform extends Fido2PluginPlatform {
  final List<_Call> calls = [];

  /// Answers for successive getAssertion calls. An assertion is returned, an
  /// exception is thrown.
  final List<Object> answers;

  _FakePlatform(this.answers);

  @override
  Future<Fido2Assertion> getAssertion({
    required String rpId,
    required Uint8List clientDataHash,
    required List<Uint8List> allowCredentials,
    String? pin,
    required Duration timeout,
  }) async {
    calls.add(_Call(rpId, clientDataHash, allowCredentials, pin));
    final answer = answers[calls.length - 1];
    if (answer is Exception) throw answer;
    return answer as Fido2Assertion;
  }

  @override
  Future<Fido2NfcStatus> nfcStatus() async => Fido2NfcStatus.enabled;

  @override
  Future<void> openNfcSettings() async {}

  @override
  Future<void> cancel() async {}
}

final _assertion = Fido2Assertion(
  authenticatorData: Uint8List.fromList([1, 2, 3]),
  signature: Uint8List.fromList([4, 5]),
  credentialId: Uint8List.fromList(utf8.encode('key-a')),
);

// base64url of "key-a" without padding, as webauthn-rs sends it.
const _keyA = 'a2V5LWE';

void main() {
  Future<(Fido2Attempt, _FakePlatform)> run(
    List<Object> answers, {
    String? pin,
  }) async {
    final platform = _FakePlatform(answers);
    Fido2PluginPlatform.instance = platform;
    final attempt = await const Fido2StepRunner().attempt(
      rpId: 'core.example',
      challenge: 'the-challenge',
      credentialIds: const [_keyA],
      pin: pin,
    );
    return (attempt, platform);
  }

  test('signs SHA-256 of the challenge with the offered keys', () async {
    final (attempt, platform) = await run([_assertion]);

    expect(attempt, isA<Fido2Success>());
    final call = platform.calls.single;
    expect(call.rpId, 'core.example');
    expect(
      call.clientDataHash,
      sha256.convert(utf8.encode('the-challenge')).bytes,
    );
    expect(call.allowCredentials.single, utf8.encode('key-a'));
    expect(call.pin, isNull);
  });

  test('no credential on a key without a PIN is the wrong key', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.noCredentials),
    ]);
    expect(attempt, isA<Fido2WrongKey>());
  });

  test('a PIN sent to a key without one says so', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.pinNotSet),
    ], pin: '1234');
    expect(attempt, isA<Fido2PinNotSet>());
  });

  test('a key demanding a PIN token asks for the PIN', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.pinRequired),
    ]);
    expect(attempt, isA<Fido2NeedsPin>());
  });

  test('no credential even with the PIN is the wrong key', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.noCredentials),
    ], pin: '1234');
    expect(attempt, isA<Fido2WrongKey>());
  });

  test('a wrong PIN reports the retries left', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.pinInvalid, pinRetries: 5),
    ], pin: '0000');
    expect(attempt, isA<Fido2PinInvalid>());
    expect((attempt as Fido2PinInvalid).retries, 5);
  });

  test('a PIN no key accepts never reaches the key', () async {
    for (final pin in ['123', 'x' * 64]) {
      final (attempt, platform) = await run([_assertion], pin: pin);
      expect(attempt, isA<Fido2PinMalformed>());
      expect(platform.calls, isEmpty);
    }
  });

  test('the PIN is passed to the key', () async {
    final (attempt, platform) = await run([_assertion], pin: '1234');

    expect(attempt, isA<Fido2Success>());
    expect(platform.calls.single.pin, '1234');
  });

  test('other plugin errors pass through', () async {
    final (attempt, _) = await run([
      const Fido2Exception(Fido2ErrorCode.timeout),
    ]);
    expect(attempt, isA<Fido2Failed>());
    expect((attempt as Fido2Failed).error.code, Fido2ErrorCode.timeout);
  });

  test('errors from outside the plugin become a failure', () async {
    final (attempt, _) = await run([const FormatException('boom')]);
    expect(attempt, isA<Fido2Failed>());
    expect((attempt as Fido2Failed).error.code, Fido2ErrorCode.unknown);
  });

  test('a malformed credential id becomes a failure', () async {
    Fido2PluginPlatform.instance = _FakePlatform([_assertion]);
    final attempt = await const Fido2StepRunner().attempt(
      rpId: 'core.example',
      challenge: 'the-challenge',
      credentialIds: const ['not base64!'],
    );
    expect(attempt, isA<Fido2Failed>());
  });

  test('credential ids decode unpadded base64url', () {
    expect(decodeCredentialId(_keyA), utf8.encode('key-a'));
  });
}
