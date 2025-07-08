import 'package:flutter/material.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/code_dialog.dart';
import 'package:mobile/main.dart';
import 'dart:convert';

enum MfaMethod {
  totp(0),
  email(1);

  final int value;
  const MfaMethod(this.value);
  }

class MfaService {
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

  static Future<void> connect({
    required BuildContext context,
    required String proxyUrl,
    required PluginConnectPayload pluginConnectPayload,
    required dynamic wireguardPlugin,
  }) async {
    final presharedKey = await _handleMfaFlow(
      context: context,
      proxyUrl: proxyUrl,
      payload: pluginConnectPayload,
    );

    if (presharedKey != null) {
      pluginConnectPayload.presharedKey = presharedKey;
      await wireguardPlugin.startTunnel(
        jsonEncode(pluginConnectPayload.toJson()),
      );
    }
  }
}
