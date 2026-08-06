import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/services.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile/logging.dart';

class UserCanceledAuth implements Exception {
  const UserCanceledAuth();
}

String getErrorMessageFromBiometricsException(Object e) {
  if (e is LocalAuthException) {
    talker.error("Biometrics check failed with code: ${e.code}");
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return "Device is not supported or is busy.";
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return "Biometrics auth is not configured on the device.";
      case LocalAuthExceptionCode.biometricLockout:
      case LocalAuthExceptionCode.temporaryLockout:
        return "Biometrics auth is temporarily locked.";
      default:
        return "Unknown error: ${e.description ?? 'No description'}";
    }
  }
  if (e is PlatformException) {
    talker.error("Biometrics check failed with PlatformException code: ${e.code}");
    return "Platform error: ${e.message ?? 'Unknown error'}";
  }
  talker.error("Biometrics check failed with unexpected error: $e");
  return "Unknown error";
}

AndroidOptions _getAndroidOptions() =>
    const AndroidOptions();

FlutterSecureStorage _getStorage() =>
    FlutterSecureStorage(aOptions: _getAndroidOptions());

String signChallenge(String challenge, String privateKey) {
  final List<int> decodedKey = base64.decode(privateKey).toList();
  final private = ed.PrivateKey(decodedKey);
  final signed = ed.sign(private, utf8.encode(challenge));
  return base64.encode(signed.toList());
}

SecureInstanceStorage _generateInstanceStorage() {
  final keyPair = ed.generateKey();
  final privateKey = base64.encode(keyPair.privateKey.bytes);
  final publicKey = base64.encode(keyPair.publicKey.bytes);
  return SecureInstanceStorage(privateKey: privateKey, publicKey: publicKey);
}

Future<void> removeInstanceStorage(String storageKey) async {
  final storage = _getStorage();
  await storage.delete(key: storageKey);
}

Future<SecureInstanceStorage> createBiometricStorage(
  String storageKey, {
  String? prompt,
}) async {
  final auth = LocalAuthentication();
  if (await auth.authenticate(
    localizedReason: prompt ?? "Authenticate to proceed",
    biometricOnly: true,
  )) {
    final storage = _getStorage();
    final instanceStorage = _generateInstanceStorage();
    final serializedStorage = jsonEncode(instanceStorage.toJson());
    await storage.write(key: storageKey, value: serializedStorage);
    return instanceStorage;
  }
  throw UserCanceledAuth();
}

Future<SecureInstanceStorage> getBiometricInstanceStorage(
  String storageKey, {
  String? prompt,
}) async {
  final message = prompt ?? "Authenticate to connect";
  final auth = LocalAuthentication();
  if (await auth.authenticate(
    localizedReason: message,
    biometricOnly: true,
  )) {
    final storage = _getStorage();
    final storeRawData = await storage.read(key: storageKey);
    if (storeRawData != null) {
      return SecureInstanceStorage.fromJson(jsonDecode(storeRawData));
    }
    throw Exception("Instance storage not found");
  }
  throw UserCanceledAuth();
}
