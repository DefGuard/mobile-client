import 'package:dio/dio.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/logging.dart';

const clientVersionHeader = 'defguard-client-version';
const clientPlatformHeader = 'defguard-client-platform';

// Headers are required by all proxy communication to ensure proper core responses.
class ClientHeadersInterceptor extends Interceptor {
  ClientHeadersInterceptor(this._identity);

  final ClientIdentitySource _identity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final identity = await _identity.get();
      options.headers[clientVersionHeader] = identity.version;
      options.headers[clientPlatformHeader] = identity.platformHeader;
      handler.next(options);
    } catch (e, s) {
      talker.error('Refusing to send ${options.uri} unidentified', e, s);
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: s,
          message: 'Client capability headers unavailable',
        ),
        true,
      );
    }
  }
}
