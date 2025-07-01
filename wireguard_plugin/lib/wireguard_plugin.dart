import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:talker/talker.dart';

import 'wireguard_plugin_platform_interface.dart';

class WireguardPlugin {
  static Talker? _talker;

  static const _eventChannel = EventChannel(
    'net.defguard.wireguard_plugin/event',
  );

  static StreamSubscription? _subscription;

  Future<bool> requestPermissions() {
    return WireguardPluginPlatform.instance.requestPermissions();
  }

  Future<bool> startTunnel(String config) {
    return WireguardPluginPlatform.instance.startTunnel(config);
  }

  static void setTalker(Talker talker) {
    _talker = talker;
  }

  static void startListening({
    required void Function(String eventName, Map<String, dynamic>? data)
    onEvent,
  }) {
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      try {
        final map = Map<String, dynamic>.from(event as Map);
        final eventName = map['event'] as String;
        final eventData = map['data'] as String?;

        final data = eventData != null
            ? json.decode(eventData) as Map<String, dynamic>
            : null;

        onEvent(eventName, data);
      } catch (e) {
        _talker?.error("Failed to handle wireguard_plugin event: $e");
      }
    });
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
