import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/db/db_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging.dart';

/// Secure iOS storage configuration (`unlocked_this_device`).
/// Prevents background reads and keeps secrets out of device backups.
const _iosOptions = IOSOptions(
  accessibility: KeychainAccessibility.unlocked_this_device,
);

/// `encryptedSharedPreferences` disabled as it is deprecated by the plugin.
const _androidOptions = AndroidOptions();

/// Storage for client secrets at rest (WireGuard keys, proxy tokens, MFA keys).
const secureStorage = FlutterSecureStorage(
  iOptions: _iosOptions,
  aOptions: _androidOptions,
);

const _initializedKey = 'secure_storage_initialized';

/// Idempotent secure storage initialization; must be awaited before reading secrets.
Future<void> initSecureStorage() async {
  final prefs = SharedPreferencesAsync();
  if (await prefs.getBool(_initializedKey) == true) return;
  try {
    if (!await (await databaseFile()).exists()) {
      // iOS keychain items persist after app reinstall. Missing database file
      // confirms a fresh install, so purge leftover secrets.
      talker.info("Fresh install, purging secrets of a previous installation");
      await secureStorage.deleteAll();
    } else {
      // Re-write legacy secrets to update accessibility class to `unlocked_this_device`.
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
