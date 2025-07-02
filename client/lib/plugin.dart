import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:wireguard_plugin/wireguard_plugin.dart';

import 'main.dart';

final wireguardPluginProvider = Provider<WireguardPlugin>((ref) {
  final plugin = WireguardPlugin(talker: talker);
  return plugin;
});

class PluginEventRouter extends StateNotifier<void> {
  final Ref ref;

  PluginEventRouter(this.ref) : super(null) {
    final plugin = ref.read(wireguardPluginProvider);
    plugin.startListening(onEvent: handleEvent);
  }

  @override
  void dispose() {
    ref.read(wireguardPluginProvider).stopListening();
    super.dispose();
  }

  void handleEvent(String event, Map<String, dynamic>? data) {
    talker.debug("EventRouter Event $event received by event router");
    if (data != null) {
      talker.debug("EventRouter: Data received: $data");
    } else {
      talker.debug("Event had no data");
    }
    switch (event) {
      case "tunnel_down":
        ref.read(pluginActiveTunnelStateProvider.notifier).clear();
        break;
      case "tunnel_up":
        if (data != null) {
          try {
            final tunnelData = PluginTunnelEventData.fromJson(data);
            ref.read(pluginActiveTunnelStateProvider.notifier).set(tunnelData);
          } catch (e) {
            talker.error("Event $event handler failed ! Reason: $e");
          }
        } else {
          talker.error("Event handler did not received event data!");
        }
        break;
      default:
        talker.error("EventRouter: received $event has no handler !");
    }
  }
}

final pluginEventRouterProvider =
    StateNotifierProvider<PluginEventRouter, void>(
      (ref) => PluginEventRouter(ref),
    );
