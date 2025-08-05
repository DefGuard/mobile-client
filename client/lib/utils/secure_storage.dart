import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mobile/data/proxy/mfa.dart';

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

Future<SecureInstanceStorage> getBiometricInstanceStorage(
  String storageKey, {
  String? prompt,
}) async {
  final promptInfo = prompt != null
      ? _makePrompt(prompt)
      : PromptInfo.defaultValues;
  final capabilityCheck = await BiometricStorage().canAuthenticate();
  if (capabilityCheck != CanAuthenticateResponse.success) {
    throw SecureStorageError(capabilityCheck);
  }
  // First creation of the storage doesn't require user interaction since we only write fresh data into the new storage it should be fine.
  final storage = await BiometricStorage().getStorage(
    storageKey,
    promptInfo: promptInfo,
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
