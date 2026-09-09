import 'package:mobile/utils/keychain.dart';

import '../logging.dart';

/// Per-instance secrets (WireGuard key, proxy token, MFA key pair) stored in
/// platform keychain keyed by instance UUID and device ID, allowing access
/// without database rows during enrollment or migration.

String wireguardKeyStorageKey(String uuid, int deviceId) =>
    'wg-key-$uuid-$deviceId';

String tokenStorageKey(String uuid, int deviceId) => 'token-$uuid-$deviceId';

String mfaStorageKey(String uuid, int deviceId) => 'mfa-$uuid-$deviceId';

Future<void> storeInstanceSecrets({
  required String uuid,
  required int deviceId,
  required String privateKey,
  required String poolingToken,
}) async {
  await secureStorage.write(
    key: wireguardKeyStorageKey(uuid, deviceId),
    value: privateKey,
  );
  await secureStorage.write(
    key: tokenStorageKey(uuid, deviceId),
    value: poolingToken,
  );
}

Future<void> removeInstanceSecrets({
  required String uuid,
  required int deviceId,
}) async {
  await secureStorage.delete(key: wireguardKeyStorageKey(uuid, deviceId));
  await secureStorage.delete(key: tokenStorageKey(uuid, deviceId));
  await secureStorage.delete(key: mfaStorageKey(uuid, deviceId));
}

/// Shown when a restored database lacks `ThisDeviceOnly` keychain secrets,
/// requiring re-enrollment.
const missingSecretsMessage =
    "This instance is missing its credentials. Please delete it and add it again.";

/// Logs a missing secret. Telling the user is the caller's business - show
/// [missingSecretsMessage] through the toaster where there is someone watching.
void reportMissingSecret(String logName, String what) {
  talker.error(
    "$what of $logName is not present in the secure storage, the instance has to be re-enrolled",
  );
}
