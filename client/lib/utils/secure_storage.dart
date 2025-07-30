import 'dart:convert';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/db/database.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mobile/data/proxy/mfa.dart';

SecureInstanceStorage _generateInstanceStorage() {
  final keyPair = ed.generateKey();
  final privateKey = base64.encode(keyPair.privateKey.bytes);
  final publicKey = base64.encode(keyPair.publicKey.bytes);
  return SecureInstanceStorage(privateKey: privateKey, publicKey: publicKey);
}

FlutterSecureStorage getSecureStorage() {
  final aOptions = AndroidOptions(encryptedSharedPreferences: true);
  return FlutterSecureStorage(aOptions: aOptions);
}

Future<SecureInstanceStorage> getInstanceSecureStorage(
  DefguardInstance instance,
) async {
  final storage = getSecureStorage();
  String? storageValue = await storage.read(key: instance.secureStorageKey);
  if (storageValue != null) {
    final parsed = SecureInstanceStorage.fromJson(jsonDecode(storageValue));
    return parsed;
  }
  final instanceStorageValue = _generateInstanceStorage();
  await storage.write(
    key: instance.secureStorageKey,
    value: jsonEncode(instanceStorageValue.toJson()),
  );
  return instanceStorageValue;
}

Future<SecureInstanceStorage> getBiometricInstanceStorage(
  DefguardInstance instance,
) async {
  final storage = await BiometricStorage().getStorage(
    instance.secureStorageKey,
  );
  final storeRawData = await storage.read();
  if (storeRawData != null) {
    return SecureInstanceStorage.fromJson(jsonDecode(storeRawData));
  }
  // gen new save and then return
  final instanceStorage = _generateInstanceStorage();
  final serializedStorage = jsonEncode(instanceStorage.toJson());
  storage.write(serializedStorage);
  return instanceStorage;
}
