import 'dart:typed_data';

import 'device_identity_plugin_platform_interface.dart';

export 'device_identity_plugin_platform_interface.dart'
    show DeviceIdentityPluginPlatform;
export 'device_identity_types.dart';

class DeviceIdentityPlugin {
  const DeviceIdentityPlugin();

  Future<List<Uint8List>> generateAttestedIdentity(
    String alias,
    Uint8List challengeData,
  ) => DeviceIdentityPluginPlatform.instance.generateAttestedIdentity(
    alias,
    challengeData,
  );

  Future<Uint8List> signPossession(String alias, Uint8List data) =>
      DeviceIdentityPluginPlatform.instance.signPossession(alias, data);

  Future<bool> hasIdentity(String alias) =>
      DeviceIdentityPluginPlatform.instance.hasIdentity(alias);

  Future<void> deleteIdentity(String alias) =>
      DeviceIdentityPluginPlatform.instance.deleteIdentity(alias);
}
