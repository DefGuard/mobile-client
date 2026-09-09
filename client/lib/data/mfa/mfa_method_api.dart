import 'package:mobile/data/db/enums.dart';

/// MFA methods as the proxy sends them, mirroring `MfaMethod` in
/// `proto/common/client_types.proto`. Values this client cannot perform are
/// still represented so that parsing never fails on them.
enum ApiMfaMethod {
  totp(0),
  email(1),
  oidc(2),
  biometric(3),
  mobileApprove(4),
  fido2(5),
  unknown(-1);

  final int value;

  const ApiMfaMethod(this.value);

  static ApiMfaMethod fromWire(int value) =>
      values.firstWhere((m) => m.value == value, orElse: () => unknown);

  static ApiMfaMethod of(MfaMethod method) => switch (method) {
    MfaMethod.totp => totp,
    MfaMethod.email => email,
    MfaMethod.openid => oidc,
    MfaMethod.biometric => biometric,
  };

  /// Null when this client cannot perform the method.
  MfaMethod? get supported => switch (this) {
    totp => MfaMethod.totp,
    email => MfaMethod.email,
    oidc => MfaMethod.openid,
    biometric => MfaMethod.biometric,
    mobileApprove || fido2 || unknown => null,
  };

  /// Row label for a method [supported] cannot map. Supported methods are named
  /// by [MfaMethod.toUiString] instead.
  String get unsupportedLabel => switch (this) {
    mobileApprove => "Mobile approval",
    fido2 => "Security key",
    _ => "Unsupported method",
  };
}
