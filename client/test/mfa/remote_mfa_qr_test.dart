import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/proxy/mfa.dart';

void main() {
  const legacyJson = {
    'instance_id': 'instance-id',
    'token': 'legacy-token',
    'challenge': 'challenge',
  };

  test('decodes a legacy QR and ignores unknown keys', () {
    final qr = RemoteMfaQr.fromJson({...legacyJson, 'future_field': true});

    expect(qr, isA<LegacyRemoteMfaQr>());
    expect(qr.instanceId, 'instance-id');
    expect(qr.token, 'legacy-token');
    expect(qr.challenge, 'challenge');
  });

  test('decodes a flow QR by its step attempt id', () {
    final qr = RemoteMfaQr.fromJson({
      ...legacyJson,
      'step_attempt_id': 'attempt-id',
    });

    expect(qr, isA<MfaFlowRemoteMfaQr>());
    expect((qr as MfaFlowRemoteMfaQr).stepAttemptId, 'attempt-id');
  });

  test('rejects malformed legacy QR fields', () {
    expect(
      () => RemoteMfaQr.fromJson({'instance_id': 'instance-id'}),
      throwsFormatException,
    );
  });

  test('does not treat an invalid flow attempt id as a legacy QR', () {
    for (final stepAttemptId in [null, '', 7]) {
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
