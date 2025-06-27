import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wireguard_plugin_platform_interface.dart';

/// An implementation of [WireguardPluginPlatform] that uses method channels.
class MethodChannelWireguardPlugin extends WireguardPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wireguard_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
