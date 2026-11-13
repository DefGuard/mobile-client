enum IdentityErrorCode {
  unspecified,
  unavailable,
  temporarilyUnavailable,
  timeout,
  rateLimited,
  permissionDenied,
  unsupported,
  identityLost,
  invalidChallenge,
  backendFailure,
  invalidEvidence,
  challengeExpired,
}

class DeviceIdentityException implements Exception {
  final IdentityErrorCode code;
  final String? message;

  const DeviceIdentityException(this.code, {this.message});

  @override
  String toString() => message == null
      ? 'DeviceIdentityException(${code.name})'
      : 'DeviceIdentityException(${code.name}): $message';
}
