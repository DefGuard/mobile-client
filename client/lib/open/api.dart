import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/config.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/mfa.dart';

import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';

import '../logging.dart';

const _apiV1Segments = ['api', 'v1'];
final enrollmentPathSegments = ['api', 'v1', 'enrollment'];
final mfaPathSegments = ['api', 'v1', 'client-mfa'];

class MfaMethodNotAvailableException implements Exception {
  final MfaMethod method;

  const MfaMethodNotAvailableException(this.method);

  @override
  String toString() {
    return "Requested Mfa method not available on the account - ${method.toReadableString()}";
  }
}

class _ProxyApi {
  static final _ProxyApi _instance = _ProxyApi._internal();

  factory _ProxyApi() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      responseType: ResponseType.json,
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 30),
    ),
  );

  _ProxyApi._internal() {
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.interceptors.add(TalkerDioLogger(talker: talker));
  }

  Future<(ConfigurationPollResponse?, int?)> pollConfiguration(
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
      final response = await _dio.postUri(endpoint, data: data);
      final status = response.statusCode;
      // return early, instance lost it's enterprise status
      if (status == 402) {
        return (null, 402);
      }
      final responseData = InstanceInfoResponse.fromJson(response.data);
      return (responseData.deviceConfig, status);
    } catch (e) {
      talker.error("Failed to poll configuration!", e);
    }
    return (null, null);
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
      if (e.response != null) {
        if (e.response!.data != null &&
            e.response!.data is Map<String, dynamic>) {
          final responseData = e.response!.data!;
          final dataError = responseData['error'];
          final missingMFAMethodError = "selected MFA method not available"
              .toLowerCase();
          if (dataError is String &&
              dataError.toLowerCase().trim() == missingMFAMethodError) {
            throw MfaMethodNotAvailableException(data.method);
          }
        }
        throw HttpException(
          "Failed to start MFA. Status: ${e.response?.statusCode} Body: ${e.response?.data}",
        );
      }
      rethrow;
    } catch (e) {
      throw FormatException(
        "Invalid JSON sent by start MFA endpoint! Error: $e",
      );
    }
  }

  Future<FinishMfaResponse> finishMfa(Uri url, FinishMfaRequest data) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaPathSegments, 'finish'],
    );
    final response = await _dio.postUri(endpoint, data: data.toJson());
    return FinishMfaResponse.fromJson(response.data);
  }

  Future<void> finishRemoteMfa(Uri url, FinishMfaRequest data) async {
    final endpoint = url.replace(
      pathSegments: [...url.pathSegments, ...mfaPathSegments, 'finish-remote'],
    );
    await _dio.postUri(endpoint, data: data.toJson());
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

final proxyApi = _ProxyApi();
