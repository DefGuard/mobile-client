import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/mfa_flow.dart' as flow;

// Captured from the proxy's generated Prost types with serde_json::to_string.
const _accepted =
    r'{"outcome":{"Accepted":{"token":"flow-token","first_step":{"step_attempt_id":"attempt-id","challenge":{"Signature":{"challenge":"challenge"}}}}}}';
const _rejected =
    r'{"outcome":{"Rejected":{"rejections":[{"step":0,"reason":1}]}}}';
const _fido2Step =
    r'{"started":{"step_attempt_id":"attempt-id","challenge":{"Fido2":{"challenge":"fido-challenge","credential_ids":["a2V5LWE"]}}}}';
const _advanced = r'{"result":{"outcome":{"Advanced":{"next_step":1}}}}';
const _completed =
    r'{"result":{"outcome":{"Completed":{"preshared_key":"psk"}}}}';
const _awaiting = r'{"result":{"outcome":{"AwaitingExternal":{}}}}';
const _legacyStartRequest =
    r'{"location_id":11,"pubkey":"device-pubkey","method":0,"posture_data":null}';
const _legacyFinishRequest =
    r'{"token":"legacy-token","code":"signature","auth_pub_key":"auth-public-key"}';
const _flowStartRequest =
    r'{"location_id":11,"pubkey":"device-pubkey","posture_data":null,"selected_methods":[0,1]}';
const _flowStepStartRequest = r'{"token":"flow-token","method":1}';
const _flowCodeFinishRequest =
    r'{"token":"flow-token","step_attempt_id":"attempt-id","submission":{"Code":{"code":"123456"}}}';
const _flowBiometricFinishRequest =
    r'{"token":"flow-token","step_attempt_id":"attempt-id","submission":{"Biometric":{"signature":"signature"}}}';
const _flowFido2FinishRequest =
    r'{"token":"flow-token","step_attempt_id":"attempt-id","submission":{"Fido2":{"rp_id_hash":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31],"authenticator_data":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33],"signature":[5,6],"credential_id":[7,8]}}}';
const _legacyStart = r'{"token":"legacy-token","challenge":null}';
const _legacyFinish = r'{"preshared_key":"legacy-psk","token":null}';

Map<String, dynamic> _fixture(String value) =>
    jsonDecode(value) as Map<String, dynamic>;

void main() {
  group('legacy DTOs', () {
    test('start request keeps the v1.7.0 shape', () {
      const request = StartMfaRequest(
        pubkey: 'device-pubkey',
        locationId: 11,
        method: MfaMethod.totp,
      );
      expect(request.toJson(), _fixture(_legacyStartRequest));
    });

    test('finish request keeps nullable legacy fields', () {
      expect(
        const FinishMfaRequest(token: 'legacy-token').toJson(),
        {'token': 'legacy-token', 'code': null, 'auth_pub_key': null},
      );
      expect(
        const FinishMfaRequest(
          token: 'legacy-token',
          code: 'signature',
          authPubKey: 'auth-public-key',
        ).toJson(),
        _fixture(_legacyFinishRequest),
      );
    });

    test('start and finish responses retain their released fields', () {
      expect(
        const StartMfaResponse(token: 'legacy-token', challenge: null).toJson(),
        {'token': 'legacy-token', 'challenge': null},
      );
      expect(
        StartMfaResponse.fromJson(_fixture(_legacyStart)).token,
        'legacy-token',
      );
      expect(
        const FinishMfaResponse(presharedKey: 'psk').toJson(),
        {'preshared_key': 'psk'},
      );
      expect(
        FinishMfaResponse.fromJson(_fixture(_legacyFinish)).presharedKey,
        'legacy-psk',
      );
    });
  });

  group('flow start', () {
    test('serializes selected methods separately from the legacy request', () {
      const request = flow.MfaFlowStartRequest(
        locationId: 11,
        pubkey: 'device-pubkey',
        selectedMethods: [MfaMethod.totp, MfaMethod.email],
      );
      expect(request.toJson(), _fixture(_flowStartRequest));
    });

    test('reads the accepted response and first step', () {
      final response = flow.MfaFlowStartResponse.fromJson(_fixture(_accepted));
      final accepted = response.outcome as flow.MfaFlowAccepted;
      expect(accepted.token, 'flow-token');
      expect(accepted.firstStep.stepAttemptId, 'attempt-id');
      expect(
        (accepted.firstStep.challenge as flow.MfaSignatureChallenge).challenge,
        'challenge',
      );
    });

    test('reads start rejections and unknown reasons safely', () {
      final response = flow.MfaFlowStartResponse.fromJson(_fixture(_rejected));
      final rejected = response.outcome as flow.MfaFlowRejected;
      expect(
        rejected.rejections.single.reason,
        flow.MfaStartRejectionReason.methodNotInStep,
      );
      expect(rejected.rejections.single.message, contains('step 1'));
      final unknown =
          flow.MfaFlowStartResponse.fromJson({
                'outcome': {
                  'Rejected': {
                    'rejections': [
                      {'step': 1, 'reason': 99},
                    ],
                  },
                },
              }).outcome
              as flow.MfaFlowRejected;
      expect(
        unknown.rejections.single.reason,
        flow.MfaStartRejectionReason.unspecified,
      );
    });

    test('keeps an unknown start variant explicit', () {
      final response = flow.MfaFlowStartResponse.fromJson({
        'outcome': {'FutureVariant': <String, dynamic>{}},
      });
      expect(response.outcome, isA<flow.MfaFlowStartUnknown>());
    });
  });

  group('flow step start', () {
    test('serializes the selected method', () {
      const request = flow.MfaFlowStepStartRequest(
        token: 'flow-token',
        method: MfaMethod.email,
      );
      expect(request.toJson(), _fixture(_flowStepStartRequest));
    });

    test('reads FIDO2 challenges and credentials', () {
      final response = flow.MfaFlowStepStartResponse.fromJson(
        _fixture(_fido2Step),
      );
      final started = response.started!;
      expect(started.stepAttemptId, 'attempt-id');
      final challenge = started.challenge as flow.MfaFido2Challenge;
      expect(challenge.challenge, 'fido-challenge');
      expect(challenge.credentialIds, ['a2V5LWE']);
    });

    test('keeps unknown challenge variants explicit', () {
      final started = flow.MfaFlowStepStartResponse.fromJson({
        'started': {
          'step_attempt_id': 'attempt-2',
          'challenge': {'FutureChallenge': <String, dynamic>{}},
        },
      }).started!;
      expect(started.challenge, isA<flow.MfaUnknownChallenge>());
    });
  });

  group('flow step finish', () {
    test('serializes typed submissions to proxy fixtures', () {
      expect(
        const flow.MfaFlowStepFinishRequest(
          token: 'flow-token',
          stepAttemptId: 'attempt-id',
          submission: flow.MfaFlowCodeSubmission('123456'),
        ).toJson(),
        _fixture(_flowCodeFinishRequest),
      );
      expect(
        const flow.MfaFlowStepFinishRequest(
          token: 'flow-token',
          stepAttemptId: 'attempt-id',
          submission: flow.MfaFlowBiometricSubmission('signature'),
        ).toJson(),
        _fixture(_flowBiometricFinishRequest),
      );
      final fido2 = flow.MfaFlowStepFinishRequest(
        token: 'flow-token',
        stepAttemptId: 'attempt-id',
        submission: flow.MfaFlowFido2Submission(
          rpIdHash: List<int>.generate(32, (index) => index),
          authenticatorData: List<int>.generate(34, (index) => index),
          signature: [5, 6],
          credentialId: [7, 8],
        ),
      );
      expect(fido2.toJson(), _fixture(_flowFido2FinishRequest));
      expect(
        const flow.MfaFlowStepFinishRequest(
          token: 'flow-token',
          stepAttemptId: 'attempt-id',
        ).toJson()['submission'],
        isNull,
      );
    });

    test('reads each known result outcome', () {
      final advanced = flow.MfaFlowStepFinishResponse.fromJson(
        _fixture(_advanced),
      ).result;
      expect((advanced as flow.MfaFlowAdvanced).nextStep, 1);

      final completed = flow.MfaFlowStepFinishResponse.fromJson(
        _fixture(_completed),
      ).result;
      expect((completed as flow.MfaFlowCompleted).presharedKey, 'psk');

      final awaiting = flow.MfaFlowStepFinishResponse.fromJson(
        _fixture(_awaiting),
      ).result;
      expect(awaiting, isA<flow.MfaFlowAwaitingExternal>());
    });

    test('keeps unknown outcomes explicit without retaining the body', () {
      final result = flow.MfaFlowStepFinishResponse.fromJson({
        'result': {
          'outcome': {
            'FutureResult': {'secret': 'not retained'},
          },
        },
      }).result;
      expect(result, isA<flow.MfaFlowResultUnknown>());
      expect(result.toString(), isNot(contains('not retained')));
    });
  });
}
