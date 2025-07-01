import 'dart:async';
import 'dart:convert';
import 'package:talker/talker.dart';

import 'wireguard_plugin_platform_interface.dart';

class WireguardPlugin {
  final Talker talker;

  static StreamSubscription? _subscription;

  const WireguardPlugin({required this.talker});

  Future<bool> requestPermissions() {
    return WireguardPluginPlatform.instance.requestPermissions();
  }

  Future<void> startTunnel(String config) {
    return WireguardPluginPlatform.instance.startTunnel(config);
  }

  Future<void> closeTunnel() {
    return WireguardPluginPlatform.instance.closeTunnel();
  }

  void startListening({
    required void Function(String eventName, Map<String, dynamic>? data)
    onEvent,
  }) {
    if (_subscription != null) return;
    _subscription = WireguardPluginPlatform.instance.eventStream.listen((
      event,
    ) {
      try {
        final eventName = event['event'] as String;
        final eventData = event['data'] as String?;

        final data = eventData != null
            ? json.decode(eventData) as Map<String, dynamic>
            : null;

        onEvent(eventName, data);
      } catch (e) {
        talker.error("Failed to handle wireguard_plugin event: $e");
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
