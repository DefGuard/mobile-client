import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/services.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:mobile/logging.dart';
import 'package:mobile/utils/keychain.dart';

class UserCanceledAuth implements Exception {
  const UserCanceledAuth();
}

String getErrorMessageFromBiometricsException(PlatformException e) {
  final errorCode = e.code;
  talker.error("Biometrics check failed with code: $errorCode");
  if (errorCode == auth_error.notAvailable) {
    return "Device is not supported or is busy.";
  }
  if (errorCode == auth_error.biometricOnlyNotSupported) {
    return "Biometrics auth is not configured on the device.";
  }
  if (errorCode == auth_error.lockedOut) {
    return "Biometrics auth is not configured on the device.";
  }
  if (errorCode == auth_error.notEnrolled) {
    return "Biometrics auth is not configured on the device.";
  }
  return "Unknown error";
}

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

Future<SecureInstanceStorage> createBiometricStorage(
  String storageKey, {
  String? prompt,
}) async {
  final auth = LocalAuthentication();
  if (await auth.authenticate(
    localizedReason: prompt ?? "Authenticate to proceed",
    options: const AuthenticationOptions(
      useErrorDialogs: false,
      biometricOnly: true,
    ),
  )) {
    final instanceStorage = _generateInstanceStorage();
    final serializedStorage = jsonEncode(instanceStorage.toJson());
    await secureStorage.write(key: storageKey, value: serializedStorage);
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
    options: const AuthenticationOptions(
      useErrorDialogs: false,
      biometricOnly: true,
    ),
  )) {
    final storeRawData = await secureStorage.read(key: storageKey);
    if (storeRawData != null) {
      return SecureInstanceStorage.fromJson(jsonDecode(storeRawData));
    }
    throw Exception("Instance storage not found");
  }
  throw UserCanceledAuth();
}
