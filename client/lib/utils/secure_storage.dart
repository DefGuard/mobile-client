import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mobile/data/proxy/mfa.dart';

final biometricSecureStorage = BiometricStorage();

class SecureStorageError implements Exception {
  final CanAuthenticateResponse storageResponse;

  const SecureStorageError(this.storageResponse);

  @override
  String toString() {
    return "SecureStorageError - capability check result rejected: ${storageResponse.toString()}";
  }
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

PromptInfo _makePrompt(String text) {
  return PromptInfo(
    androidPromptInfo: AndroidPromptInfo(
      title: text,
      confirmationRequired: true,
      negativeButton: "Cancel",
    ),
    iosPromptInfo: IosPromptInfo(accessTitle: text, saveTitle: text),
    macOsPromptInfo: IosPromptInfo(accessTitle: text, saveTitle: text),
  );
}

Future<void> removeInstanceStorage(String storageKey) async {
  final storage = await biometricSecureStorage.getStorage(
    storageKey,
    forceInit: false,
    options: StorageFileInitOptions(
      androidBiometricOnly: false,
      darwinBiometricOnly: false,
      authenticationRequired: false,
      authenticationValidityDurationSeconds: 5,
    ),
  );
  await storage.delete();
}

Future<SecureInstanceStorage> getBiometricInstanceStorage(
  String storageKey, {
  String? prompt,
}) async {
  final promptInfo = prompt != null
      ? _makePrompt(prompt)
      : PromptInfo.defaultValues;
  final storage = await biometricSecureStorage.getStorage(
    storageKey,
    promptInfo: promptInfo,
    forceInit: false,
    options: StorageFileInitOptions(
      authenticationRequired: true,
      androidBiometricOnly: true,
      darwinBiometricOnly: true,
    ),
  );
  final storeRawData = await storage.read();
  if (storeRawData != null) {
    return SecureInstanceStorage.fromJson(jsonDecode(storeRawData));
  }
  // gen new save and then return
  final instanceStorage = _generateInstanceStorage();
  final serializedStorage = jsonEncode(instanceStorage.toJson());
  storage.write(serializedStorage, promptInfo: promptInfo);
  return instanceStorage;
}
