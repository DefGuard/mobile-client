import 'package:mobile/open/services/snackbar_service.dart';
import 'package:mobile/utils/keychain.dart';

import '../logging.dart';

/// Per-instance secrets kept in the platform keychain instead of the database:
/// the device WireGuard private key, the proxy (polling) token and the
/// biometric MFA key pair.
///
/// Items are keyed by the instance UUID and device id, so they stay addressable
/// without a database row - which is what enrollment (the row does not exist
/// yet) and the 4 -> 5 migration (the row is not mapped yet) need.

String wireguardKeyStorageKey(String uuid, int deviceId) =>
    'wg-key-$uuid-$deviceId';

String tokenStorageKey(String uuid, int deviceId) => 'token-$uuid-$deviceId';

String mfaStorageKey(String uuid, int deviceId) => 'mfa-$uuid-$deviceId';

/// Stores the secrets of a newly enrolled instance.
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

/// Removes every secret of an instance, including its biometric MFA key pair.
Future<void> removeInstanceSecrets({
  required String uuid,
  required int deviceId,
}) async {
  await secureStorage.delete(key: wireguardKeyStorageKey(uuid, deviceId));
  await secureStorage.delete(key: tokenStorageKey(uuid, deviceId));
  await secureStorage.delete(key: mfaStorageKey(uuid, deviceId));
}

/// Message shown when an instance has a database row but no secrets.
///
/// Secrets are stored `ThisDeviceOnly`, so a database restored from a backup
/// onto another device (or one restored after the keychain was reset) keeps its
/// instances while the key material is gone. Such an instance cannot connect
/// and has to be enrolled again.
const _missingSecretsMessage =
    "This instance is missing its credentials. Please delete it and add it again.";

/// Reports an instance whose secrets are gone.
///
/// Background work (configuration polling) passes `notifyUser: false`: it runs
/// without the user asking for anything, so it only logs.
void reportMissingSecret(
  String logName,
  String what, {
  bool notifyUser = true,
}) {
  talker.error(
    "$what of $logName is not present in the secure storage, the instance has to be re-enrolled",
  );
  if (notifyUser) {
    SnackbarService.showError(_missingSecretsMessage);
  }
}
