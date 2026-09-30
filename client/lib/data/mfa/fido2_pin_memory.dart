import 'package:shared_preferences/shared_preferences.dart';

/// Security keys already known to refuse an assertion without their PIN, so
/// later connects ask for it before the tap instead of after a failed one.
abstract class Fido2PinMemory {
  Future<bool> requiresPin(List<String> credentialIds);

  Future<void> remember(String credentialId);
}

class PrefsFido2PinMemory implements Fido2PinMemory {
  static const _key = 'fido2_pin_required_credentials';

  final SharedPreferencesAsync _prefs;

  PrefsFido2PinMemory([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<bool> requiresPin(List<String> credentialIds) async {
    final known = await _prefs.getStringList(_key) ?? const [];
    return credentialIds.any(known.contains);
  }

  @override
  Future<void> remember(String credentialId) async {
    final known = await _prefs.getStringList(_key) ?? const [];
    if (known.contains(credentialId)) return;
    await _prefs.setStringList(_key, [...known, credentialId]);
  }
}
