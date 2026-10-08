import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];

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
      '{}',
      200,
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

  test(
    'flow approval posts the proxy JSON and accepts an empty response',
    () async {
      await api.approveMfaFlow(
        Uri.parse('https://proxy.example/base'),
        const MfaFlowApproveRequest(
          token: 'flow-token',
          stepAttemptId: 'attempt-id',
          proof: MfaMobileApprovalProof(
            signature: 'signature',
            authPubKey: 'auth-public-key',
          ),
        ),
      );

      expect(adapter.requests.single.uri.path, '/base/api/v1/mfa-flow/approve');
      expect(
        adapter.bodies.single,
        '{"token":"flow-token","step_attempt_id":"attempt-id",'
        '"proof":{"signature":"signature",'
        '"auth_pub_key":"auth-public-key"}}',
      );
    },
  );

  test('legacy approval keeps its existing request JSON and route', () async {
    await api.finishRemoteMfa(
      Uri.parse('https://proxy.example/base'),
      const FinishMfaRequest(
        token: 'legacy-token',
        code: 'signature',
        authPubKey: 'auth-public-key',
      ),
    );

    expect(
      adapter.requests.single.uri.path,
      '/base/api/v1/client-mfa/finish-remote',
    );
    expect(
      adapter.bodies.single,
      '{"token":"legacy-token","code":"signature",'
      '"auth_pub_key":"auth-public-key"}',
    );
  });
}
