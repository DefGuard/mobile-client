import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/mfa.dart';

void main() {
  group('StartMfaRequest', () {
    test('sends the plan and the legacy method side by side', () {
      const request = StartMfaRequest(
        pubkey: 'device-pubkey',
        locationId: 11,
        method: MfaMethod.totp,
        selectedMethods: [MfaMethod.totp, MfaMethod.email],
      );
      expect(request.toJson(), {
        'pubkey': 'device-pubkey',
        'location_id': 11,
        'method': 0,
        'posture_data': null,
        'selected_methods': [0, 1],
      });
    });
  });

  group('StartMfaResponse', () {
    test('reads a pre-2.2 response as having no rejections', () {
      final response = StartMfaResponse.fromJson({
        'token': 'session-token',
        'challenge': null,
      });
      expect(response.token, 'session-token');
      expect(response.rejections, isEmpty);
    });

    test('reads rejections and numbers the steps for people', () {
      final response = StartMfaResponse.fromJson({
        'token': 'session-token',
        'challenge': null,
        'rejections': [
          {'step': 0, 'reason': 1},
          {'step': 1, 'reason': 2},
          {'step': 2, 'reason': 3},
          {'step': 3, 'reason': 0},
        ],
      });
      expect(
        MfaRejectedException(response.rejections).message,
        [
          "The method chosen for verification step 1 is not allowed. The "
              "location's MFA settings have changed, so pick a method again.",
          "Verification step 2 has no method available on this server. Contact "
              "your administrator.",
          "The method chosen for verification step 3 cannot be used. Set it up "
              "first, or pick a different one.",
          "The server rejected verification step 4.",
        ].join(' '),
      );
    });

    test('reads a reason added after 2.2 as unspecified', () {
      final response = StartMfaResponse.fromJson({
        'token': 'session-token',
        'challenge': null,
        'rejections': [
          {'step': 0, 'reason': 99},
        ],
      });
      expect(
        response.rejections.single.reason,
        MfaStartRejectionReason.unspecified,
      );
    });
  });

  group('FinishMfaRequest', () {
    test('omits the attempt id on the legacy path', () {
      const request = FinishMfaRequest(token: 'session-token', code: '123456');
      expect(request.toJson().containsKey('step_attempt_id'), isFalse);
    });

    test('sends the attempt id when there is one', () {
      const request = FinishMfaRequest(
        token: 'session-token',
        code: '123456',
        stepAttemptId: 'attempt-1',
      );
      expect(request.toJson()['step_attempt_id'], 'attempt-1');
    });
  });

  group('StepStartMfa', () {
    test('reads the attempt id and challenge', () {
      final response = StepStartMfaResponse.fromJson({
        'step_attempt_id': 'attempt-1',
        'challenge': 'challenge',
      });
      expect(response.stepAttemptId, 'attempt-1');
      expect(response.challenge, 'challenge');
    });

    test('sends the token and the step method', () {
      expect(
        const StepStartMfaRequest(
          token: 'session-token',
          method: MfaMethod.biometric,
        ).toJson(),
        {'token': 'session-token', 'method': 3},
      );
    });
  });

  group('FinishMfaResponse', () {
    test('reads a pre-2.2 completion', () {
      final response = FinishMfaResponse.fromJson({'preshared_key': 'psk'});
      expect(response.presharedKey, 'psk');
      expect(response.outcome, isNull);
    });

    test('reads an advance', () {
      final response = FinishMfaResponse.fromJson({
        'preshared_key': '',
        'result': {
          'outcome': {
            'Advanced': {'next_step': 1},
          },
        },
      });
      expect((response.outcome as MfaAdvanced).nextStep, 1);
    });

    test('reads a completion', () {
      final response = FinishMfaResponse.fromJson({
        'preshared_key': '',
        'result': {
          'outcome': {
            'Completed': {'preshared_key': 'psk'},
          },
        },
      });
      expect((response.outcome as MfaCompleted).presharedKey, 'psk');
    });

    test('reads a completion for a peer with no preshared key', () {
      final response = FinishMfaResponse.fromJson({
        'result': {
          'outcome': {'Completed': <String, dynamic>{}},
        },
      });
      expect((response.outcome as MfaCompleted).presharedKey, isNull);
    });

    test('reads an unresolved external factor', () {
      final response = FinishMfaResponse.fromJson({
        'result': {
          'outcome': {'AwaitingExternal': <String, dynamic>{}},
        },
      });
      expect(response.outcome, isA<MfaAwaitingExternal>());
    });

    test('reads a null or absent result as no outcome', () {
      expect(FinishMfaResponse.fromJson({'result': null}).outcome, isNull);
      expect(
        FinishMfaResponse.fromJson({
          'result': {'outcome': null},
        }).outcome,
        isNull,
      );
    });
  });

  group('parseMfaOutcome', () {
    test('accepts every plausible spelling of the variant keys', () {
      for (final key in ['Advanced', 'advanced']) {
        final outcome = parseMfaOutcome({
          'outcome': {
            key: {'nextStep': 2},
          },
        });
        expect((outcome as MfaAdvanced).nextStep, 2);
      }
      for (final key in [
        'AwaitingExternal',
        'awaiting_external',
        'awaitingExternal',
      ]) {
        expect(
          parseMfaOutcome({
            'outcome': {key: <String, dynamic>{}},
          }),
          isA<MfaAwaitingExternal>(),
        );
      }
      final completed = parseMfaOutcome({
        'outcome': {
          'Completed': {'presharedKey': 'psk'},
        },
      });
      expect((completed as MfaCompleted).presharedKey, 'psk');
    });

    test('throws with the body when the shape is not recognized', () {
      expect(
        () => parseMfaOutcome({
          'outcome': {'Rejected': <String, dynamic>{}},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.source,
            'source',
            contains('Rejected'),
          ),
        ),
      );
      expect(() => parseMfaOutcome('done'), throwsFormatException);
      expect(
        () => parseMfaOutcome({
          'outcome': {'Advanced': 1},
        }),
        throwsFormatException,
      );
      expect(
        () => parseMfaOutcome({
          'outcome': {'Advanced': <String, dynamic>{}, 'Completed': 2},
        }),
        throwsFormatException,
      );
    });
  });
}
