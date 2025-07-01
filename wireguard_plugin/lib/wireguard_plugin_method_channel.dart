import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wireguard_plugin_platform_interface.dart';

/// An implementation of [WireguardPluginPlatform] that uses method channels.
class MethodChannelWireguardPlugin extends WireguardPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wireguard_plugin');

  static const EventChannel _eventChannel = EventChannel(
    'net.defguard.wireguard_plugin/event',
  );

  @override
  Future<bool> requestPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<void> startTunnel(String config) async {
    await methodChannel.invokeMethod('startTunnel', config);
  }

  @override
  Future<void> closeTunnel() async {
    await methodChannel.invokeMethod('closeMethod');
  }

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic event) => Map<String, dynamic>.from(event as Map));
}
