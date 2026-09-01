import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/riverpod/plugin/plugin.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';
import 'package:mobile/utils/notifications.dart';
import 'package:wireguard_plugin/wireguard_plugin.dart';

import 'logging.dart';

final wireguardPluginProvider = Provider<WireguardPlugin>((ref) {
  final plugin = WireguardPlugin(talker: talker);
  return plugin;
});

class PluginEventRouter extends Notifier<void> {
  @override
  void build() {
    final plugin = ref.read(wireguardPluginProvider);
    plugin.startListening(onEvent: handleEvent);
    ref.onDispose(() {
      ref.read(wireguardPluginProvider).stopListening();
    });
  }

  void handleEvent(String event, Map<String, dynamic>? data) {
    talker.debug("EventRouter Event $event received by event router");
    if (data != null) {
      talker.debug("EventRouter: Data received: $data");
    } else {
      talker.debug("Event had no data");
    }
    final notifier = ref.read(pluginActiveTunnelStateProvider.notifier);
    switch (event) {
      case "tunnel_down":
        // clear active connection
        notifier.clear();
        break;
      case "tunnel_up":
        if (data != null) {
          try {
            // display active connection
            notifier.set(PluginTunnelEventData.fromJson(data));
          } catch (e) {
            talker.error("Event $event handler failed ! Reason: $e");
          }
        } else {
          talker.error("Event handler did not received event data!");
        }
        break;
      case "mfa_session_expired":
        // clear active connection
        notifier.clear();
        // show notifications
        notifyMfaSessionExpired();
        break;
      default:
        talker.error("EventRouter: received $event has no handler!");
    }
  }

  /// Displays system notification and in-app toast
  void notifyMfaSessionExpired() {
    // show system notification
    flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Connection Lost',
      body:
          'VPN gateway unreachable, MFA session expired. Reconnect to continue.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'defguard_channel',
          'DefGuard',
          channelDescription: 'DefGuard VPN notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
    );

    // show in-app toast
    ref
        .read(toastManagerProvider.notifier)
        .show(
          message:
              'Connection Lost: VPN gateway unreachable, MFA session expired',
        );
  }
}

final pluginEventRouterProvider = NotifierProvider<PluginEventRouter, void>(
  PluginEventRouter.new,
);
