import 'package:dio/dio.dart';

class ErrorHandler {
  static String getHumanReadableError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet connection.";
        case DioExceptionType.connectionError:
          return "Unable to connect to the server. Please check your internet connection.";
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            return "Unauthorized. Please check your credentials.";
          }
          if (e.response?.statusCode == 403) {
            return "Access forbidden.";
          }
          if (e.response?.statusCode == 404) {
            return "Service not found.";
          }
          if (e.response?.statusCode != null &&
              e.response!.statusCode! >= 500) {
            return "Server error. Please try again later.";
          }
          return "Server returned an error: ${e.response?.statusCode}";
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

    final s = e.toString();
    if (s.startsWith("Exception: ")) {
      return s.substring(11);
    }
    return s;
  }
}
