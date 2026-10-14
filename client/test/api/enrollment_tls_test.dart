import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/api.dart';

class _PlatformError implements Exception {
  final String text;

  const _PlatformError(this.text);

  @override
  String toString() => text;
}

class _FailingAdapter implements HttpClientAdapter {
  final Object error;

  _FailingAdapter(this.error);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw error;

  @override
  void close({bool force = false}) {}
}

String _cronet(String netError, int internalCode) =>
    'NetworkClientException: Exception in CronetUrlRequest: $netError, '
    'ErrorCode=11, InternalErrorCode=$internalCode, Retryable=false, '
    'uri=https://proxy.example/api/v1/enrollment/start, errorCode=11, '
    'cronetInternalErrorCode=$internalCode, immediatelyRetryable=false';

String _nsError(int code) =>
    'NSErrorClientException: An SSL error has occurred '
    '[domain=NSURLErrorDomain, code=$code], '
    'uri=https://proxy.example/api/v1/enrollment/start';

void main() {
  Future<void> startEnrollment(String platformError) {
    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = _FailingAdapter(_PlatformError(platformError));
    return ProxyApi.forTesting(dio).startEnrollment(
      Uri.parse('https://proxy.example'),
      EnrollmentStartRequest(token: 'token'),
    );
  }

  Matcher throwsTls(ProxyTlsFailure failure) => throwsA(
    isA<ProxyTlsException>().having((e) => e.failure, 'failure', failure),
  );

  test('Android certificate errors are classified', () async {
    await expectLater(
      startEnrollment(_cronet('net::ERR_CERT_AUTHORITY_INVALID', -202)),
      throwsTls(.untrusted),
    );
    await expectLater(
      startEnrollment(_cronet('net::ERR_CERT_DATE_INVALID', -201)),
      throwsTls(.expired),
    );
    await expectLater(
      startEnrollment(_cronet('net::ERR_CERT_COMMON_NAME_INVALID', -200)),
      throwsTls(.hostnameMismatch),
    );
    await expectLater(
      startEnrollment(_cronet('net::ERR_CERT_REVOKED', -206)),
      throwsTls(.other),
    );
    await expectLater(
      startEnrollment(_cronet('net::ERR_SSL_PROTOCOL_ERROR', -107)),
      throwsTls(.other),
    );
  });

  test('iOS certificate errors are classified', () async {
    await expectLater(startEnrollment(_nsError(-1202)), throwsTls(.untrusted));
    await expectLater(startEnrollment(_nsError(-1203)), throwsTls(.untrusted));
    await expectLater(startEnrollment(_nsError(-1201)), throwsTls(.expired));
    await expectLater(startEnrollment(_nsError(-1204)), throwsTls(.expired));
    await expectLater(startEnrollment(_nsError(-1200)), throwsTls(.other));
  });

  test('the platform error is kept for logging', () async {
    await expectLater(
      startEnrollment(_nsError(-1202)),
      throwsA(
        isA<ProxyTlsException>().having(
          (e) => e.toString(),
          'toString',
          contains('code=-1202'),
        ),
      ),
    );
  });

  test('other connection errors are rethrown unchanged', () async {
    await expectLater(
      startEnrollment(_cronet('net::ERR_NAME_NOT_RESOLVED', -105)),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      startEnrollment(_nsError(-1005)),
      throwsA(isA<DioException>()),
    );
  });
}
