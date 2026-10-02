import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fido2_plugin_method_channel.dart';
import 'fido2_types.dart';

abstract class Fido2PluginPlatform extends PlatformInterface {
  Fido2PluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static Fido2PluginPlatform _instance = MethodChannelFido2Plugin();

  static Fido2PluginPlatform get instance => _instance;

  static set instance(Fido2PluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Fido2NfcStatus> nfcStatus();

  Future<void> openNfcSettings();

  /// Waits for a key to be tapped and runs a CTAP2 getAssertion on it. [pin] is
  /// only sent to the key when given, so without it no user verification is
  /// requested.
  Future<Fido2Assertion> getAssertion({
    required String rpId,
    required Uint8List clientDataHash,
    required List<Uint8List> allowCredentials,
    String? pin,
    required Duration timeout,
  });

  Future<void> cancel();
}
