import 'dart:io';

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

/// `_v2` re-runs the accessibility migration, which skipped items in 1.7.0.
const _initializedKey = 'secure_storage_initialized_v2';

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
    } else if (Platform.isIOS) {
      await _migrateLegacyAccessibility();
    }
    await prefs.setBool(_initializedKey, true);
  } catch (e) {
    talker.error("Secure storage setup failed, retrying on the next launch", e);
  }
}

/// Moves secrets from other accessibility classes to `unlocked_this_device`.
///
/// Reads are filtered by accessibility, so each class is read separately.
/// Items are deleted before re-writing to avoid `errSecDuplicateItem`.
Future<void> _migrateLegacyAccessibility() async {
  var migrated = 0;
  for (final accessibility in KeychainAccessibility.values) {
    if (accessibility == _iosOptions.accessibility) continue;
    final legacyStorage = FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: accessibility),
    );
    final stored = await legacyStorage.readAll();
    for (final entry in stored.entries) {
      await secureStorage.delete(key: entry.key);
      await secureStorage.write(key: entry.key, value: entry.value);
      migrated++;
    }
  }
  talker.info("Migrated $migrated secret(s) to `unlocked_this_device`");
}
