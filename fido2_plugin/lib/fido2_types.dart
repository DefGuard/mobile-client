import 'dart:typed_data';

enum Fido2NfcStatus { unsupported, disabled, enabled }

enum Fido2ErrorCode {
  nfcUnavailable,
  nfcDisabled,
  noCredentials,
  pinRequired,
  pinInvalid,
  pinBlocked,
  pinAuthBlocked,
  pinNotSet,
  unsupportedKey,
  cancelled,
  timeout,
  tagLost,
  unknown,
}

class Fido2Assertion {
  final Uint8List authenticatorData;
  final Uint8List signature;
  final Uint8List credentialId;

  const Fido2Assertion({
    required this.authenticatorData,
    required this.signature,
    required this.credentialId,
  });
}

class Fido2Exception implements Exception {
  final Fido2ErrorCode code;
  final String? message;

  /// Only set for [Fido2ErrorCode.pinInvalid], when the key reported it.
  final int? pinRetries;

  const Fido2Exception(this.code, {this.message, this.pinRetries});

  @override
  String toString() => message == null
      ? 'Fido2Exception(${code.name})'
      : 'Fido2Exception(${code.name}): $message';
}
