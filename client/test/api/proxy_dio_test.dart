import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/client_headers_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

const _facts = DevicePlatformFacts(
  kind: PlatformKind.android,
  osFamily: 'android',
  osType: 'Android',
  osName: '14',
  osVersion: '14',
);

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late Dio dio;

  setUp(() {
    dio = buildProxyDio(
      identity: ClientIdentitySource(
        () async => ClientIdentity(version: '1.6.0', facts: _facts),
      ),
      adapter: _NoopAdapter(),
    );
  });

  test('the header interceptor runs before the cookie manager and logger', () {
    final header = dio.interceptors.indexWhere(
      (i) => i is ClientHeadersInterceptor,
    );
    final cookies = dio.interceptors.indexWhere((i) => i is CookieManager);
    final logger = dio.interceptors.indexWhere((i) => i is TalkerDioLogger);

    expect(header, greaterThanOrEqualTo(0));
    expect(header, lessThan(cookies));
    expect(cookies, lessThan(logger));
  });

  test('exactly one header interceptor is installed', () {
    expect(
      dio.interceptors.whereType<ClientHeadersInterceptor>(),
      hasLength(1),
    );
  });

  test('MFA requests, responses, and errors are excluded from Dio logs', () {
    final logger = dio.interceptors.whereType<TalkerDioLogger>().single;
    final settings = logger.settings;

    for (final path in [
      'https://proxy.example/api/v1/client-mfa/start',
      'https://proxy.example/api/v1/client-mfa/finish',
      'https://proxy.example/api/v1/client-mfa/finish-remote',
      'https://proxy.example/api/v1/mfa-flow/start',
      'https://proxy.example/api/v1/mfa-flow/step-start',
      'https://proxy.example/api/v1/mfa-flow/step-finish',
      'https://proxy.example/api/v1/mfa-flow/approve',
    ]) {
      final request = RequestOptions(path: path);
      expect(settings.requestFilter!(request), isFalse);
      expect(
        settings.responseFilter!(Response(requestOptions: request)),
        isFalse,
      );
      expect(
        settings.errorFilter!(DioException(requestOptions: request)),
        isFalse,
      );
    }

    final otherRequest = RequestOptions(
      path: 'https://proxy.example/api/v1/poll',
    );
    expect(settings.requestFilter!(otherRequest), isTrue);
  });

  test('base options carry no capability headers', () {
    expect(dio.options.headers.containsKey(clientVersionHeader), isFalse);
    expect(dio.options.headers.containsKey(clientPlatformHeader), isFalse);
  });
}

class _NoopAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 200);

  @override
  void close({bool force = false}) {}
}
