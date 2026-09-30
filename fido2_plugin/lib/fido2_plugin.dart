import 'dart:typed_data';

import 'fido2_plugin_platform_interface.dart';
import 'fido2_types.dart';

export 'fido2_plugin_platform_interface.dart' show Fido2PluginPlatform;
export 'fido2_types.dart';

class Fido2Plugin {
  const Fido2Plugin();

  Future<Fido2NfcStatus> nfcStatus() =>
      Fido2PluginPlatform.instance.nfcStatus();

  Future<void> openNfcSettings() =>
      Fido2PluginPlatform.instance.openNfcSettings();

  Future<Fido2Assertion> getAssertion({
    required String rpId,
    required Uint8List clientDataHash,
    required List<Uint8List> allowCredentials,
    String? pin,
    Duration timeout = const Duration(seconds: 60),
  }) => Fido2PluginPlatform.instance.getAssertion(
    rpId: rpId,
    clientDataHash: clientDataHash,
    allowCredentials: allowCredentials,
    pin: pin,
    timeout: timeout,
  );

  Future<void> cancel() => Fido2PluginPlatform.instance.cancel();
}
