import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_transport.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/mfa_flow.dart' as flow;
import 'package:mobile/open/api.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];
  int statusCode = 200;
  String responseBody = '{}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    bodies.add(
      requestStream == null
          ? ''
          : utf8.decode(await requestStream.expand((chunk) => chunk).toList()),
    );
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late ProxyApi api;

  setUp(() {
    adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = adapter;
    api = ProxyApi.forTesting(dio);
  });

  test('legacy own-connect stays on the v1.7.0 routes and payloads', () async {
    adapter.responseBody = '{"token":"legacy-token","challenge":null}';
    final start = await api.startMfa(
      Uri.parse('https://proxy.example/base'),
      const StartMfaRequest(
        pubkey: 'device-pubkey',
        locationId: 11,
        method: MfaMethod.totp,
      ),
    );
    expect(start.token, 'legacy-token');
    expect(start.challenge, isNull);
    expect(adapter.requests.single.uri.path, '/base/api/v1/client-mfa/start');
    expect(
      adapter.bodies.single,
      '{"pubkey":"device-pubkey","location_id":11,"method":0,"posture_data":null}',
    );

    adapter.requests.clear();
    adapter.bodies.clear();
    adapter.responseBody = '{"preshared_key":"psk","token":null}';
    final finish = await api.finishMfa(
      Uri.parse('https://proxy.example/base'),
      const FinishMfaRequest(
        token: 'legacy-token',
        code: 'signature',
        authPubKey: 'auth-public-key',
      ),
    );
    expect(finish?.presharedKey, 'psk');
    expect(adapter.requests.single.uri.path, '/base/api/v1/client-mfa/finish');
    expect(
      adapter.bodies.single,
      '{"token":"legacy-token","code":"signature",'
      '"auth_pub_key":"auth-public-key"}',
    );
  });

  test(
    'flow start uses only the flow route and selected-method payload',
    () async {
      adapter.responseBody =
          '{"outcome":{"Accepted":{"token":"flow-token","first_step":{"step_attempt_id":"attempt-id","challenge":{"Signature":{"challenge":"challenge"}}}}}}';
      final response = await api.startMfaFlow(
        Uri.parse('https://proxy.example/base'),
        const flow.MfaFlowStartRequest(
          locationId: 11,
          pubkey: 'device-pubkey',
          selectedMethods: [MfaMethod.totp, MfaMethod.email],
        ),
      );

      expect(response.outcome, isA<flow.MfaFlowAccepted>());
      expect(
        (response.outcome as flow.MfaFlowAccepted).firstStep.stepAttemptId,
        'attempt-id',
      );
      expect(adapter.requests.single.uri.path, '/base/api/v1/mfa-flow/start');
      expect(
        adapter.bodies.single,
        '{"location_id":11,"pubkey":"device-pubkey",'
        '"posture_data":null,"selected_methods":[0,1]}',
      );
    },
  );

  test('flow step start and finish use their dedicated routes', () async {
    adapter.responseBody =
        '{"started":{"step_attempt_id":"attempt-id","challenge":{"Signature":{"challenge":"challenge"}}}}';
    final started = await api.startMfaFlowStep(
      Uri.parse('https://proxy.example/base'),
      const flow.MfaFlowStepStartRequest(
        token: 'flow-token',
        method: MfaMethod.email,
      ),
    );
    expect(started.started?.stepAttemptId, 'attempt-id');
    expect(
      adapter.requests.single.uri.path,
      '/base/api/v1/mfa-flow/step-start',
    );
    expect(adapter.bodies.single, '{"token":"flow-token","method":1}');

    adapter.requests.clear();
    adapter.bodies.clear();
    adapter.responseBody = '{"result":{"outcome":{"AwaitingExternal":{}}}}';
    final finish = await api.finishMfaFlow(
      Uri.parse('https://proxy.example/base'),
      const flow.MfaFlowStepFinishRequest(
        token: 'flow-token',
        stepAttemptId: 'attempt-id',
      ),
    );
    expect(finish.result, isA<flow.MfaFlowAwaitingExternal>());
    expect(
      adapter.requests.single.uri.path,
      '/base/api/v1/mfa-flow/step-finish',
    );
    expect(
      adapter.bodies.single,
      '{"token":"flow-token","step_attempt_id":"attempt-id",'
      '"submission":null}',
    );
  });

  test('legacy biometric transport sends both legacy proof fields', () async {
    adapter.responseBody = '{"preshared_key":"psk","token":null}';
    final transport = LegacyMfaTransport(
      Uri.parse('https://proxy.example/base'),
      api: api,
    );
    await transport.finish(
      token: 'legacy-token',
      stepAttemptId: null,
      credential: const MfaBiometricCredential(
        signature: 'signature',
        authPubKey: 'auth-public-key',
      ),
    );

    expect(adapter.requests.single.uri.path, '/base/api/v1/client-mfa/finish');
    expect(
      adapter.bodies.single,
      '{"token":"legacy-token","code":"signature",'
      '"auth_pub_key":"auth-public-key"}',
    );
  });

  test(
    'flow transport maps FIDO2 assertion bytes to the flow variant',
    () async {
      adapter.responseBody =
          '{"result":{"outcome":{"Completed":{"preshared_key":"psk"}}}}';
      final transport = MfaFlowProxyTransport(
        Uri.parse('https://proxy.example/base'),
        api: api,
      );
      final credential = MfaFido2Credential.fromAssertion(
        signature: [5, 6],
        authenticatorData: List<int>.generate(34, (index) => index),
        credentialId: [7, 8],
      );
      await transport.finish(
        token: 'flow-token',
        stepAttemptId: 'attempt-1',
        credential: credential,
      );

      expect(
        adapter.requests.single.uri.path,
        '/base/api/v1/mfa-flow/step-finish',
      );
      expect(
        jsonDecode(adapter.bodies.single),
        {
          'token': 'flow-token',
          'step_attempt_id': 'attempt-1',
          'submission': {
            'Fido2': {
              'rp_id_hash': List<int>.generate(32, (index) => index),
              'authenticator_data': List<int>.generate(34, (index) => index),
              'signature': [5, 6],
              'credential_id': [7, 8],
            },
          },
        },
      );
    },
  );

  test('legacy external approval and proof rejection stay distinct', () async {
    final transport = LegacyMfaTransport(
      Uri.parse('https://proxy.example/base'),
      api: api,
    );
    adapter.statusCode = 428;
    adapter.responseBody = '{}';
    expect(
      await transport.finish(
        token: 'legacy-token',
        stepAttemptId: null,
        credential: null,
      ),
      isA<MfaFinishAwaitingExternal>(),
    );

    adapter.statusCode = 401;
    adapter.responseBody = '{"error":"secret response body"}';
    await expectLater(
      transport.finish(
        token: 'legacy-token',
        stepAttemptId: null,
        credential: const MfaCodeCredential('123456'),
      ),
      throwsA(isA<MfaCodeRejectedException>()),
    );
  });

  test('MFA errors never retain the response body', () async {
    adapter.statusCode = 500;
    adapter.responseBody = '{"error":"secret response body"}';
    await expectLater(
      api.startMfaFlow(
        Uri.parse('https://proxy.example'),
        const flow.MfaFlowStartRequest(
          locationId: 11,
          pubkey: 'device-pubkey',
          selectedMethods: [MfaMethod.totp],
        ),
      ),
      throwsA(
        isA<MfaRequestException>().having(
          (error) => error.toString(),
          'safe error text',
          isNot(contains('secret response body')),
        ),
      ),
    );
  });
}
