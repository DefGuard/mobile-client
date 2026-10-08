import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_screen.dart';

void main() {
  test(
    'flow callback includes the current attempt ID as a query parameter',
    () {
      final uri = buildOpenIdMfaUri(
        proxyUrl: 'https://proxy.example/base/',
        token: 'session+token',
        stepAttemptId: 'attempt/1',
      );

      expect(uri.path, '/base/openid/mfa');
      expect(uri.queryParameters, {
        'token': 'session+token',
        'step_attempt_id': 'attempt/1',
      });
    },
  );

  test('legacy callback does not add a flow-only attempt ID', () {
    final uri = buildOpenIdMfaUri(
      proxyUrl: 'https://proxy.example/base/',
      token: 'legacy-token',
    );

    expect(uri.path, '/base/openid/mfa');
    expect(uri.queryParameters, {'token': 'legacy-token'});
  });
}
