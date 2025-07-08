import 'package:flutter/material.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/totp_dialog.dart';
import 'package:mobile/main.dart';
import 'dart:convert';

class MfaService {
  static Future<String?> _handleMfaFlow({
    required BuildContext context,
    required String proxyUrl,
    required String devicePublicKey,
    required int networkId,
    required PluginConnectPayload payload,
  }) async {
    try {
      // Start MFA flow - show method selection
      final (method, token) = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return MfaStartDialog(
            url: proxyUrl,
            publicKey: devicePublicKey,
            locationId: networkId,
            method: 0,
          );
        },
      );

      if (method == null) {
        return null;
      }

      switch (method) {
        case MfaMethod.totp:
          return await _handleTotp(
            context: context,
            token: token,
            proxyUrl: proxyUrl,
          );
        case MfaMethod.email:
          talker.error("Email MFA not yet implemented");
          return null;
        default:
          return null;
      }
    } catch (e) {
      talker.error("MFA flow error: $e");
      return null;
    }
  }

  static Future<String?> _handleTotp({
    required BuildContext context,
    required String token,
    required String proxyUrl,
  }) async {
    try {
      final presharedKey = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return TotpDialog(token: token, url: proxyUrl);
        },
      );

      if (presharedKey != null) {
        talker.info("TOTP authentication successful");
      }

      return presharedKey;
    } catch (e) {
      talker.error("TOTP flow error: $e");
      return null;
    }
  }

  static Future<void> connect({
    required BuildContext context,
    required String proxyUrl,
    required String devicePublicKey,
    required int networkId,
    required PluginConnectPayload payload,
    required dynamic wireguardPlugin,
  }) async {
    final presharedKey = await _handleMfaFlow(
      context: context,
      proxyUrl: proxyUrl,
      devicePublicKey: devicePublicKey,
      networkId: networkId,
      payload: payload,
    );

    if (presharedKey != null) {
      payload.presharedKey = presharedKey;
      await wireguardPlugin.startTunnel(jsonEncode(payload.toJson()));
    }
  }
}
