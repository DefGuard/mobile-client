import 'package:dio/dio.dart';
import 'package:mobile/open/api.dart';

class ErrorHandler {
  static String getHumanReadableError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet connection.";
        case DioExceptionType.connectionError:
          return _connectionErrorMessage;
        case DioExceptionType.badResponse:
          return _statusMessage(e.response?.statusCode);
        case DioExceptionType.cancel:
          return "Request was cancelled.";
        default:
          // iOS error -1005: Network connection lost
          final errorString = e.error?.toString() ?? "";
          final messageString = e.message ?? "";
          if (errorString.contains("-1005") ||
              messageString.contains("-1005")) {
            return "Network connection lost. Please try again.";
          }

          return "An unexpected network error occurred.";
      }
    }

    if (e is MfaRequestException) {
      return switch (e.failure) {
        MfaRequestFailure.network => _connectionErrorMessage,
        MfaRequestFailure.policyDenied =>
          "This device does not meet the location's security requirements.",
        MfaRequestFailure.attemptLimit =>
          "Too many failed attempts. Start connecting again.",
        MfaRequestFailure.notReady =>
          "Verification can't start right now. Try again in a moment.",
        MfaRequestFailure.server => _statusMessage(e.statusCode),
      };
    }

    final s = e.toString();
    if (s.startsWith("Exception: ")) {
      return s.substring(11);
    }
    return s;
  }

  static const _connectionErrorMessage =
      "Unable to connect to the server. Please check your internet connection.";

  static String _statusMessage(int? statusCode) {
    if (statusCode == 401) {
      return "Unauthorized. Please check your credentials.";
    }
    if (statusCode == 403) {
      return "Access forbidden.";
    }
    if (statusCode == 404) {
      return "Service not found.";
    }
    if (statusCode != null && statusCode >= 500) {
      return "Server error. Please try again later.";
    }
    if (statusCode == null) {
      return "An unexpected network error occurred.";
    }
    return "Server returned an error: $statusCode";
  }
}
