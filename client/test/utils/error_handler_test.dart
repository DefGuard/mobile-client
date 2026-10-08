import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/utils/error_handler.dart';

void main() {
  String message(MfaRequestFailure failure, {int? statusCode}) =>
      ErrorHandler.getHumanReadableError(
        MfaRequestException(
          'MFA flow start',
          statusCode: statusCode,
          failure: failure,
        ),
      );

  test('MFA failures get fixed messages without request details', () {
    expect(
      message(MfaRequestFailure.network),
      'Unable to connect to the server. Please check your internet connection.',
    );
    expect(
      message(MfaRequestFailure.policyDenied, statusCode: 403),
      "This device does not meet the location's security requirements.",
    );
    expect(
      message(MfaRequestFailure.attemptLimit, statusCode: 403),
      'Too many failed attempts. Start connecting again.',
    );
    expect(
      message(MfaRequestFailure.notReady, statusCode: 428),
      "Verification can't start right now. Try again in a moment.",
    );
  });

  test('other MFA server failures read like other HTTP errors', () {
    expect(
      message(MfaRequestFailure.server, statusCode: 503),
      'Server error. Please try again later.',
    );
    expect(
      message(MfaRequestFailure.server, statusCode: 404),
      'Service not found.',
    );
    expect(
      message(MfaRequestFailure.server),
      isNot(contains('MFA flow start')),
    );
  });
}
