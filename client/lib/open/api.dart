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
final posturePathSegments = ['api', 'v1', 'posture'];

bool _isMfaEndpoint(Uri uri) =>
    uri.pathSegments.contains('client-mfa') ||
    uri.pathSegments.contains('mfa-flow');

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

class MfaRequestException implements Exception {
  final String operation;
  final int? statusCode;
  final bool isNetworkError;

  const MfaRequestException(
    this.operation, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => statusCode == null
      ? '$operation failed'
      : '$operation failed. Status: $statusCode';
}

MfaRequestException _mfaRequestException(String operation, DioException error) {
  final networkError =
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          (error.error?.toString().contains('-1005') ?? false) ||
          (error.message?.contains('-1005') ?? false));
  return MfaRequestException(
    operation,
    statusCode: error.response?.statusCode,
    isNetworkError: networkError,
  );
}

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
      if (e.response?.statusCode == 403) {
        throw HttpException('MFA start rejected by the proxy');
      }
      throw _mfaRequestException('MFA start', e);
    } catch (_) {
      throw const FormatException('Invalid MFA start response');
    }
  }

  Future<wire.MfaFlowStartResponse> startMfaFlow(
    Uri url,
    wire.MfaFlowStartRequest data,
  ) async {
    final endpoint = url.replace(
      pathSegments: [
        ...url.pathSegments,
        ..._apiV1Segments,
        'mfa-flow',
        'start',
      ],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _mfaRequestException('MFA flow start', e);
    } catch (_) {
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
      pathSegments: [
        ...url.pathSegments,
        ..._apiV1Segments,
        'mfa-flow',
        'step-start',
      ],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStepStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _mfaRequestException('MFA flow step start', e);
    } catch (_) {
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
      if (e.response?.statusCode == 401) {
        throw const MfaCodeRejectedException();
      }
      throw _mfaRequestException('MFA finish', e);
    } catch (_) {
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
        ..._apiV1Segments,
        'mfa-flow',
        'step-finish',
      ],
    );
    try {
      final response = await _dio.postUri(endpoint, data: data.toJson());
      return wire.MfaFlowStepFinishResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const MfaCodeRejectedException();
      }
      throw _mfaRequestException('MFA flow step finish', e);
    } catch (_) {
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
      pathSegments: [
        ...url.pathSegments,
        ..._apiV1Segments,
        'mfa-flow',
        'approve',
      ],
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
