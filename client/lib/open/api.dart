import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/config.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/mfa_flow.dart' as wire;
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/open/client_headers_interceptor.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../logging.dart';

const _apiV1Segments = ['api', 'v1'];
final enrollmentPathSegments = ['api', 'v1', 'enrollment'];
final mfaPathSegments = ['api', 'v1', 'client-mfa'];
final mfaFlowPathSegments = [..._apiV1Segments, 'mfa-flow'];
final posturePathSegments = ['api', 'v1', 'posture'];

const _iosConnectionLostCode = '-1005';

bool _isMfaEndpoint(Uri uri) =>
    uri.pathSegments.contains(mfaPathSegments.last) ||
    uri.pathSegments.contains(mfaFlowPathSegments.last);

class PostureCheckException implements Exception {
  final String message;

  const PostureCheckException(this.message);

  @override
  String toString() => 'Posture error: $message';
}

class MfaMethodNotAvailableException implements Exception {
  final MfaMethod method;

  const MfaMethodNotAvailableException(this.method);

  @override
  String toString() =>
      'Requested MFA method is not available on the account: ${method.toReadableString()}';
}

enum MfaRequestFailure {
  network,
  policyDenied,
  attemptLimit,
  sessionExpired,
  staleAttempt,
  notReady,
  server,
}

class MfaRequestException implements Exception {
  final String operation;
  final int? statusCode;
  final MfaRequestFailure failure;

  const MfaRequestException(
    this.operation, {
    this.statusCode,
    this.failure = MfaRequestFailure.server,
  });

  bool get isNetworkError => failure == MfaRequestFailure.network;

  @override
  String toString() => statusCode == null
      ? '$operation failed'
      : '$operation failed. Status: $statusCode';
}

MfaRequestFailure? _mfaResponseFailure(DioException error) {
  final response = error.response;
  final data = response?.data;
  final message = data is Map ? data['error'] : null;

  if (response?.statusCode == 400 && message == 'login session not found') {
    return MfaRequestFailure.sessionExpired;
  }
  if (response?.statusCode == 401 && message == 'invalid token') {
    return MfaRequestFailure.sessionExpired;
  }
  if (response?.statusCode == 400 && message == 'stale MFA attempt') {
    return MfaRequestFailure.staleAttempt;
  }
  if (response?.statusCode == 403 &&
      message == 'Too many failed MFA attempts. Please try connecting again.') {
    return MfaRequestFailure.attemptLimit;
  }
  return null;
}

MfaRequestException _mfaRequestException(
  String operation,
  DioException error, {
  Map<int, MfaRequestFailure> statusFailures = const {},
  bool classifyResponse = false,
}) {
  final statusCode = error.response?.statusCode;
  final networkError =
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          (error.error?.toString().contains(_iosConnectionLostCode) ?? false) ||
          (error.message?.contains(_iosConnectionLostCode) ?? false));
  return MfaRequestException(
    operation,
    statusCode: statusCode,
    failure: networkError
        ? MfaRequestFailure.network
        : (classifyResponse ? _mfaResponseFailure(error) : null) ??
              statusFailures[statusCode] ??
              MfaRequestFailure.server,
  );
}

enum ProxyTlsFailure { untrusted, expired, hostnameMismatch, other }

class ProxyTlsException implements Exception {
  final ProxyTlsFailure failure;
  final Object? cause;

  const ProxyTlsException(this.failure, {this.cause});

  @override
  String toString() =>
      'TLS connection to proxy failed (${failure.name}): $cause';
}

final _nsUrlErrorCode = RegExp(r'domain=NSURLErrorDomain, code=(-\d+)');

ProxyTlsFailure? _tlsFailure(DioException error) {
  if (error.response != null) return null;
  final cause = error.error?.toString() ?? '';

  if (cause.contains('net::ERR_CERT_AUTHORITY_INVALID')) {
    return .untrusted;
  }
  if (cause.contains('net::ERR_CERT_DATE_INVALID')) {
    return .expired;
  }
  if (cause.contains('net::ERR_CERT_COMMON_NAME_INVALID')) {
    return .hostnameMismatch;
  }
  if (cause.contains('net::ERR_CERT_') ||
      cause.contains('net::ERR_SSL_') ||
      cause.contains('net::ERR_BAD_SSL_CLIENT_AUTH_CERT')) {
    return .other;
  }

  // iOS reports a hostname mismatch as -1202 too
  return switch (_nsUrlErrorCode.firstMatch(cause)?.group(1)) {
    '-1202' || '-1203' => .untrusted,
    '-1201' || '-1204' => .expired,
    '-1200' || '-1205' || '-1206' => .other,
    _ => null,
  };
}

const _startFailures = {
  403: MfaRequestFailure.policyDenied,
  428: MfaRequestFailure.notReady,
};

/// The only sanctioned path to the proxy. Every request through this Dio is
/// held by [ClientHeadersInterceptor] until the client identity is known.
@visibleForTesting
Dio buildProxyDio({
  required ClientIdentitySource identity,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      responseType: ResponseType.json,
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 60),
    ),
  );
  dio.httpClientAdapter = adapter ?? NativeAdapter();
  dio.interceptors.addAll([
    ClientHeadersInterceptor(identity),
    CookieManager(CookieJar()),
    TalkerDioLogger(
      talker: talker,
      settings: TalkerDioLoggerSettings(
        printRequestHeaders: !kReleaseMode,
        printResponseData: !kReleaseMode,
        printErrorData: !kReleaseMode,
        requestFilter: (request) => !_isMfaEndpoint(request.uri),
        responseFilter: (response) =>
            !_isMfaEndpoint(response.requestOptions.uri),
        errorFilter: (error) => !_isMfaEndpoint(error.requestOptions.uri),
      ),
    ),
  ]);
  return dio;
}

class ProxyApi {
  static final ProxyApi _instance = ProxyApi._internal();

  factory ProxyApi() => _instance;

  final Dio _dio;

  ProxyApi._internal() : _dio = buildProxyDio(identity: clientIdentity);

  @visibleForTesting
  ProxyApi.forTesting(this._dio);

  Future<(ConfigurationPollResponse?, int?, Headers?)> pollConfiguration(
    String proxyUrl,
    String authToken,
  ) async {
    talker.debug("Polling configuration from $proxyUrl");
    try {
      final proxyUri = Uri.parse(proxyUrl);
      final endpoint = proxyUri.replace(
        pathSegments: [...proxyUri.pathSegments, ..._apiV1Segments, 'poll'],
      );
      final Map<String, dynamic> data = {'token': authToken};
      final response = await _dio.postUri(
        endpoint,
        data: data,
        options: Options(
          validateStatus: (status) =>
              status! < 500, // Don't throw for 4xx errors
        ),
      );
      final status = response.statusCode;
      if (status == 402) {
        return (null, 402, response.headers);
      }
      final responseData = InstanceInfoResponse.fromJson(response.data);
      return (responseData.deviceConfig, status, response.headers);
    } on DioException catch (e) {
      talker.error(
        'Failed to poll configuration. Status: ${e.response?.statusCode}',
      );
    } catch (_) {
      talker.error('Failed to parse configuration response');
    }
    return (null, null, null);
  }

  Future<EnrollmentStartResponse> startEnrollment(
    Uri url,
    EnrollmentStartRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...enrollmentPathSegments, 'start'],
    );
    try {
      final requestBody = data.toJson();
      final response = await _dio.postUri(endpoint, data: requestBody);
      return EnrollmentStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw HttpException(
          'Failed to start enrollment. Status: ${e.response?.statusCode} Body: ${e.response?.data}',
        );
      }
      if (_tlsFailure(e) case final failure?) {
        throw ProxyTlsException(failure, cause: e.error);
      }
      rethrow;
    } catch (e) {
      throw FormatException(
        "Invalid JSON sent by start enrollment endpoint! Error: $e",
      );
    }
  }

  Future<CreateDeviceResponse> createDevice(
    Uri url,
    CreateDeviceRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [
        ...url.pathSegments,
        ...enrollmentPathSegments,
        'create_device',
      ],
    );

    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return CreateDeviceResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw HttpException(
          "Failed to create device. Status: ${e.response?.statusCode} Body: ${e.response?.data}",
        );
      }
      if (_tlsFailure(e) case final failure?) {
        throw ProxyTlsException(failure, cause: e.error);
      }
      rethrow;
    } catch (e) {
      throw FormatException(
        "Invalid JSON sent by create device endpoint! Error: $e",
      );
    }
  }

  Future<StartMfaResponse> startMfa(Uri url, StartMfaRequest data) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaPathSegments, 'start'],
    );

    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return StartMfaResponse.fromJson(response.data);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final dataError = responseData is Map<String, dynamic>
          ? responseData['error']
          : null;
      if (dataError is String &&
          dataError.toLowerCase().trim() ==
              'selected mfa method not available') {
        throw MfaMethodNotAvailableException(data.method);
      }
      throw _mfaRequestException(
        'MFA start',
        e,
        statusFailures: _startFailures,
      );
    } catch (e) {
      talker.error('Invalid MFA start response: ${e.runtimeType}');
      throw const FormatException('Invalid MFA start response');
    }
  }

  Future<wire.MfaFlowStartResponse> startMfaFlow(
    Uri url,
    wire.MfaFlowStartRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaFlowPathSegments, 'start'],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _mfaRequestException(
        'MFA flow start',
        e,
        statusFailures: _startFailures,
      );
    } catch (e) {
      talker.error('Invalid MFA flow start response: ${e.runtimeType}');
      throw const FormatException('Invalid MFA flow start response');
    }
  }

  Future<PostureConnectResponse> postureConnect(
    Uri url,
    PostureConnectRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...posturePathSegments, 'connect'],
    );

    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return PostureConnectResponse.fromJson(response.data);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (e.response?.statusCode == 403 &&
          responseData is Map<String, dynamic>) {
        final error = responseData['error'] ?? responseData['message'];
        if (error is String) {
          throw PostureCheckException(error);
        }
      }
      if (e.response != null) {
        throw HttpException(
          'Failed to perform posture check. Status: ${e.response?.statusCode} Body: ${e.response?.data}',
        );
      }
      rethrow;
    } catch (e) {
      throw FormatException(
        'Invalid JSON sent by posture check endpoint! Error: $e',
      );
    }
  }

  Future<wire.MfaFlowStepStartResponse> startMfaFlowStep(
    Uri url,
    wire.MfaFlowStepStartRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaFlowPathSegments, 'step-start'],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStepStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _mfaRequestException(
        'MFA flow step start',
        e,
        statusFailures: const {428: MfaRequestFailure.notReady},
      );
    } catch (e) {
      talker.error('Invalid MFA flow step start response: ${e.runtimeType}');
      throw const FormatException('Invalid MFA flow step start response');
    }
  }

  Future<FinishMfaResponse?> finishMfa(
    Uri url,
    FinishMfaRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaPathSegments, 'finish'],
    );
    try {
      final response = await _dio.postUri(
        endpoint,
        data: data.toJson(),
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 400 || status == 428),
        ),
      );
      if (response.statusCode == 428) return null;
      return FinishMfaResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && _mfaResponseFailure(e) == null) {
        throw const MfaCodeRejectedException();
      }
      throw _mfaRequestException('MFA finish', e, classifyResponse: true);
    } catch (e) {
      talker.error('Invalid MFA finish response: ${e.runtimeType}');
      throw const FormatException('Invalid MFA finish response');
    }
  }

  Future<wire.MfaFlowStepFinishResponse> finishMfaFlow(
    Uri url,
    wire.MfaFlowStepFinishRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [
        ...url.pathSegments,
        ...mfaFlowPathSegments,
        'step-finish',
      ],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStepFinishResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && _mfaResponseFailure(e) == null) {
        throw const MfaCodeRejectedException();
      }
      throw _mfaRequestException(
        'MFA flow step finish',
        e,
        classifyResponse: true,
      );
    } catch (e) {
      talker.error('Invalid MFA flow step finish response: ${e.runtimeType}');
      throw const FormatException('Invalid MFA flow step finish response');
    }
  }

  Future<void> finishRemoteMfa(Uri url, FinishMfaRequest data) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaPathSegments, 'finish-remote'],
    );
    try {
      await _dio.postUri(endpoint, data: data.toJson());
    } on DioException catch (e) {
      throw _mfaRequestException('Remote MFA finish', e);
    }
  }

  Future<void> approveMfaFlow(Uri url, MfaFlowApproveRequest data) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaFlowPathSegments, 'approve'],
    );
    try {
      await _dio.postUri(endpoint, data: data.toJson());
    } on DioException catch (e) {
      throw _mfaRequestException('MFA flow approval', e);
    }
  }

  Future<NetworkInfoResponse> networkInfo(Uri url, String pubKey) async {
    final endpoint = url.replace(
      pathSegments: [
        ...url.pathSegments,
        ..._apiV1Segments,
        'enrollment',
        'network_info',
      ],
    );
    final body = {'pubkey': pubKey};
    final response = await _dio.postUri(endpoint, data: body);
    return NetworkInfoResponse.fromJson(response.data);
  }

  Future<void> registerMobileAuth(
    Uri proxyUrl,
    String authPubKey,
    String devicePubKey,
  ) async {
    final endpoint = proxyUrl.replace(
      pathSegments: [
        ...proxyUrl.pathSegments,
        ..._apiV1Segments,
        'enrollment',
        'register_mobile',
      ],
    );
    final requestData = RegisterMobileAuth(
      authPubKey: authPubKey,
      devicePubKey: devicePubKey,
    );
    await _dio.postUri(endpoint, data: requestData.toJson());
  }
}

final proxyApi = ProxyApi();
