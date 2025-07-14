import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/data/proxy/mfa.dart';

import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';

import '../logging.dart';

final enrollmentPathSegments = ['api', 'v1', 'enrollment'];
final mfaPathSegments = ['api', 'v1', 'client-mfa'];

class _ProxyApi {
  static final _ProxyApi _instance = _ProxyApi._internal();

  factory _ProxyApi() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      responseType: ResponseType.json,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 30),
    ),
  );

  _ProxyApi._internal() {
    final cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.interceptors.add(TalkerDioLogger(talker: talker));
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
}

final proxyApi = _ProxyApi();
