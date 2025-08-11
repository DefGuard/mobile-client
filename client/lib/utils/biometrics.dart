import 'package:local_auth/local_auth.dart';
import 'package:tuple/tuple.dart';

enum BiometricsCheckErrorType { unsupported, cannotCheck }

class BiometricsCheckError implements Exception {
  final BiometricsCheckErrorType type;

  const BiometricsCheckError(this.type);

  @override
  String toString() {
    switch (type) {
      case BiometricsCheckErrorType.cannotCheck:
        return "Cannot check biometrics on the device";
      case BiometricsCheckErrorType.unsupported:
        return "Device is unsupported";
    }
  }
}

final LocalAuthentication _auth = LocalAuthentication();

// biometric storage package doesn't check as expected on iOS
Future<Tuple2<bool, List<BiometricType>>> canAuthWithBiometrics() async {
  final supported = await _auth.isDeviceSupported();
  if (!supported) {
    throw BiometricsCheckError(BiometricsCheckErrorType.unsupported);
  }
  final canCheck = await _auth.canCheckBiometrics;
  if (!canCheck) {
    throw BiometricsCheckError(BiometricsCheckErrorType.cannotCheck);
  }
  final availableBiometrics = await _auth.getAvailableBiometrics();
  //ios
  final hasFace = availableBiometrics.contains(BiometricType.face);
  final hasFinger = availableBiometrics.contains(BiometricType.fingerprint);
  //android
  final isStrong = availableBiometrics.contains(BiometricType.strong);

  final canAuth = hasFace || hasFinger || isStrong;

  return Tuple2(canAuth, availableBiometrics);
}
