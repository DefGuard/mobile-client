import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/db/db_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging.dart';

/// iOS keychain items are stored with
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
///
/// The client never needs a secret while the device is locked: it declares no
/// `UIBackgroundModes`, sets no on-demand VPN rules, and every read happens in a
/// foreground flow (enrollment, tunnel start, configuration polling driven by
/// the app lifecycle). Requiring an unlocked device therefore costs no
/// functionality, and `ThisDeviceOnly` additionally keeps the secrets out of
/// device backups and off any other device.
const _iosOptions = IOSOptions(
  accessibility: KeychainAccessibility.unlocked_this_device,
);

const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);

/// Storage for every secret the client keeps at rest: WireGuard private keys,
/// proxy tokens and the biometric MFA key pairs.
const secureStorage = FlutterSecureStorage(
  iOptions: _iosOptions,
  aOptions: _androidOptions,
);

const _initializedKey = 'secure_storage_initialized';

/// Brings the secure storage in line with this installation, once.
///
/// Must be awaited during startup, before anything reads a secret. Both
/// branches are idempotent, so a failure leaves the marker unset and is simply
/// retried on the next launch.
Future<void> initSecureStorage() async {
  final prefs = SharedPreferencesAsync();
  if (await prefs.getBool(_initializedKey) == true) return;
  try {
    if (!await (await databaseFile()).exists()) {
      // Keychain items outlive the app on iOS: after a reinstall the client
      // starts with an empty database but inherits every secret the previous
      // installation wrote, and none of them can ever be used again.
      //
      // A missing marker alone would not prove a fresh install - it is missing
      // for clients upgrading from a version that predates it too - but the
      // database file is removed on uninstall and exists for every upgrading
      // client, so its absence does.
      talker.info("Fresh install, purging secrets of a previous installation");
      await secureStorage.deleteAll();
    } else {
      // Items written before the accessibility class was pinned use the plugin
      // default (`kSecAttrAccessibleWhenUnlocked`, which is included in
      // encrypted backups). Rewriting an item applies the current class.
      final stored = await secureStorage.readAll();
      for (final entry in stored.entries) {
        await secureStorage.write(key: entry.key, value: entry.value);
      }
      talker.info(
        "Applied accessibility class to ${stored.length} stored secret(s)",
      );
    }
    await prefs.setBool(_initializedKey, true);
  } catch (e) {
    talker.error("Secure storage setup failed, retrying on the next launch", e);
  }
}
