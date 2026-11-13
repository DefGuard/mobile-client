import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device_identity_plugin_method_channel.dart';

abstract class DeviceIdentityPluginPlatform extends PlatformInterface {
  DeviceIdentityPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceIdentityPluginPlatform _instance =
      MethodChannelDeviceIdentityPlugin();

  static DeviceIdentityPluginPlatform get instance => _instance;

  static set instance(DeviceIdentityPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<Uint8List>> generateAttestedIdentity(
    String alias,
    Uint8List challengeData,
  );

  Future<Uint8List> signPossession(String alias, Uint8List data);

  Future<bool> hasIdentity(String alias);

  Future<void> deleteIdentity(String alias);
}
