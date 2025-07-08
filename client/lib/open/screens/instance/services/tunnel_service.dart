import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/connect_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/code_dialog.dart';
import 'dart:convert';

import '../../../../logging.dart';

enum MfaMethod {
  totp(0),
  email(1);

  final int value;
  const MfaMethod(this.value);
}

/// Handles MFA flows and tunnel connection
class TunnelService {

  /// Main service method - displays traffic & MFA dialogs, handles
  /// interface configuration and connection.
  static Future<void> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required PluginConnectPayload payload,
    required dynamic wireguardPlugin,
  }) async {
    // handle traffic type selection if necessary
    payload.traffic = instance.disableAllTraffic
        ? TunnelTraffic.predefined
        : (await showDialog<TunnelTraffic?>(
                context: context,
                builder: (_) => ConnectDialog(),
              ))
              // in case the user dismisses the dialog
              ??
              TunnelTraffic.predefined;

    // handle mfa
    if (location.mfaEnabled) {
      if (!context.mounted) {
        return;
      }
      final presharedKey = await _handleMfaFlow(
        context: context,
        proxyUrl: instance.proxyUrl,
        payload: payload,
      );
      if (presharedKey == null) {
        // user dismissed the dialog
        return;
      }
      payload.presharedKey = presharedKey;
    }

    // start the tunnel
    await wireguardPlugin.startTunnel(jsonEncode(payload.toJson()));
  }

  /// Displays mfa method selection and code input dialogs
  static Future<String?> _handleMfaFlow({
    required BuildContext context,
    required String proxyUrl,
    required PluginConnectPayload payload,
  }) async {
    try {
      // start MFA flow - show method selection dialog
      final (method, token) = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return MfaStartDialog(
            url: proxyUrl,
            publicKey: payload.devicePublicKey,
            locationId: payload.networkId,
          );
        },
      );

      if (method == null) {
        talker.warning("User dismissed mfa-start dialog, aborting MFA flow.");
        return null;
      }

      // handle specific MFA methods
      return await _handleCodeInput(
        context: context,
        token: token,
        proxyUrl: proxyUrl,
        method: method,
      );
    } catch (e) {
      talker.error("MFA flow error: $e");
      return null;
    }
  }

  /// Displays code input dialog
  static Future<String?> _handleCodeInput({
    required BuildContext context,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
  }) async {
    try {
      final presharedKey = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return CodeDialog(token: token, url: proxyUrl, method: method);
        },
      );

      if (presharedKey != null) {
        talker.info("Code authentication successful");
      }

      return presharedKey;
    } catch (e) {
      talker.error("MFA code input error: $e");
      return null;
    }
  }
}
