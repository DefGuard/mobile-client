import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wireguard_plugin_platform_interface.dart';

/// An implementation of [WireguardPluginPlatform] that uses method channels.
class MethodChannelWireguardPlugin extends WireguardPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wireguard_plugin');

  @override
  Future<bool> requestPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<bool> startTunnel(String config) async {
    final result = await methodChannel.invokeMethod<bool>(
      'startTunnel',
      config,
    );
    return result ?? false;
  }
}
