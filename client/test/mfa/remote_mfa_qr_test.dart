import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/proxy/mfa.dart';

void main() {
  const instanceId = '0f8fad5b-d9cb-469f-a165-70867728950e';
  const challenge = 'Q7xk2LmP9vRt4WzA8nHc3JbY6uFd1GsE5oKiXqVpNwMa';
  const legacyJson = {
    'instance_id': instanceId,
    'token': 'aB3dE5gH7jK9mN1pQ3sT5vW7yZ9bC1dF',
    'challenge': challenge,
  };
  const attemptId = 'Zx8Cv7Bn6Ml5Kj4Hg3Fd2Sa1Qw9Er8Ty';

  test('decodes a legacy QR and ignores unknown keys', () {
    final qr = RemoteMfaQr.fromJson({...legacyJson, 'future_field': true});

    expect(qr, isA<LegacyRemoteMfaQr>());
    expect(qr.instanceId, instanceId);
    expect(qr.token, legacyJson['token']);
    expect(qr.challenge, challenge);
  });

  test('accepts a pre-2.2 JWT token', () {
    const jwt =
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZpY2UifQ.c2lnbmF0dXJlLXZhbHVl_-x';
    final qr = RemoteMfaQr.fromJson({...legacyJson, 'token': jwt});

    expect(qr.token, jwt);
  });

  test('decodes a flow QR by its step attempt id', () {
    final qr = RemoteMfaQr.fromJson({
      ...legacyJson,
      'step_attempt_id': attemptId,
    });

    expect(qr, isA<MfaFlowRemoteMfaQr>());
    expect((qr as MfaFlowRemoteMfaQr).stepAttemptId, attemptId);
  });

  test('rejects malformed legacy QR fields', () {
    expect(
      () => RemoteMfaQr.fromJson({'instance_id': instanceId}),
      throwsFormatException,
    );
  });

  test('rejects fields outside the expected format or size', () {
    final invalid = <Map<String, Object?>>[
      {...legacyJson, 'instance_id': 'instance-id'},
      {...legacyJson, 'token': ''},
      {...legacyJson, 'token': 'token with spaces'},
      {...legacyJson, 'token': 'a' * 4097},
      {...legacyJson, 'challenge': 'chal.lenge'},
      {...legacyJson, 'challenge': 'a' * 129},
    ];
    for (final json in invalid) {
      expect(() => RemoteMfaQr.fromJson(json), throwsFormatException);
    }
  });

  test('does not treat an invalid flow attempt id as a legacy QR', () {
    for (final stepAttemptId in [null, '', 7, 'attempt-id', 'a' * 129]) {
      expect(
        () => RemoteMfaQr.fromJson({
          ...legacyJson,
          'step_attempt_id': stepAttemptId,
        }),
        throwsFormatException,
      );
    }
  });
}
