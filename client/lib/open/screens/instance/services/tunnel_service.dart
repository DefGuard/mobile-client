import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/select_mfa_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/connect_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/code_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/openid_mfa_dialog.dart';
import 'dart:convert';

import '../../../../logging.dart';

enum MfaMethod {
  totp(0),
  email(1),
  openid(2);

  final int value;
  const MfaMethod(this.value);
}

/// Handles all MFA flows and tunnel connection
class TunnelService {
  /// Main service method - displays traffic & MFA dialogs, handles
  /// interface configuration and connection.
  static Future<void> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required dynamic wireguardPlugin,
  }) async {
    PluginConnectPayload payload = _makePayload(instance, location);
    // Handle traffic type selection if necessary
    payload.traffic = instance.disableAllTraffic
        ? TunnelTraffic.predefined
        : (await showDialog<TunnelTraffic?>(
                context: context,
                builder: (_) => ConnectDialog(),
              ))
              // in case the user dismisses the dialog
              ??
              TunnelTraffic.predefined;

    // Handle mfa
    if (location.mfaEnabled) {
      final presharedKey = instance.useOpenidForMfa
          ? await _handleOpenidMfaFlow(
              context: context,
              proxyUrl: instance.proxyUrl,
              payload: payload,
            )
          : await _handleMfaFlow(
              context: context,
              proxyUrl: instance.proxyUrl,
              payload: payload,
              useOpenid: instance.useOpenidForMfa,
            );

      if (presharedKey == null) {
        // User dismissed the dialog
        return;
      }
      payload.presharedKey = presharedKey;
    }

    // Start the tunnel
    await wireguardPlugin.startTunnel(jsonEncode(payload.toJson()));
  }

  /// Prepares wireguard plugin configuration
  static PluginConnectPayload _makePayload(
    DefguardInstance instance,
    Location location,
  ) {
    return PluginConnectPayload(
      publicKey: location.pubKey,
      devicePublicKey: instance.pubKey,
      privateKey: instance.privateKey,
      address: location.address,
      dns: location.dns,
      endpoint: location.endpoint,
      allowedIps: location.allowedIps,
      keepalive: location.keepAliveInterval,
      locationName: location.name,
      locationId: location.id,
      networkId: location.networkId,
      instanceId: instance.id,
      traffic: TunnelTraffic.predefined,
    );
  }

  /// Calls `/client-mfa/start` endpoint, returns `StartMfaResponse` with session token.
  static Future<StartMfaResponse> _startMfa(
    String url,
    String pubkey,
    int networkId,
    MfaMethod method,
  ) async {
    talker.debug("Starting MFA for networkId: $networkId, method: $method");
    final request = StartMfaRequest(
      pubkey: pubkey,
      locationId: networkId,
      method: method.value,
    );

    final uri = Uri.parse(url);
    return await proxyApi.startMfa(uri, request);
  }

  static Future<String?> _pollOpenidMfa(
    String proxyUrl,
    String token,
  ) async {
    final request = FinishMfaRequest(token: token);
    final uri = Uri.parse(proxyUrl);
    // TODO: timeout
    while (true) {
      try {
        final response = await proxyApi.finishMfa(uri, request);
        return response.presharedKey;
      } on DioException catch (e) {
        if (e.response?.statusCode == 428) {
          talker.debug("User did not complete openid browser login, waiting");
          await Future.delayed(Duration(seconds: 2));
        } else {
          rethrow;
        }
      }
    }
  }

  /// Handles OpenID, browser-based MFA
  static Future<String?> _handleOpenidMfaFlow({
    required BuildContext context,
    required String proxyUrl,
    required PluginConnectPayload payload,
  }) async {
    try {
      // Get session token
      final startMfaResponse = await _startMfa(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        MfaMethod.openid,
      );

      bool? browserOpened = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return OpenIdMfaStartDialog(
            proxyUrl: proxyUrl,
            token: startMfaResponse.token,
          );
        },
      );

      if (browserOpened == null) {
        // dialog dismissed
        return null;
      }

      // Wait for user to complete authentication in the browser
      return await _pollOpenidMfa(proxyUrl, startMfaResponse.token);
    } catch (e) {
      talker.error("OpenID MFA flow error: $e");
      return null;
    }
  }

  /// Displays non-openid mfa method selection and code input dialogs
  static Future<String?> _handleMfaFlow({
    required BuildContext context,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required bool useOpenid,
  }) async {
    try {
      // Show MFA method selection dialog
      final MfaMethod? method = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SelectMfaMethodDialog();
        },
      );

      if (method == null) {
        // user dismissed method-selection dialog, abort
        return null;
      }

      // Get session token
      final startMfaResponse = await _startMfa(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        method,
      );

      // Show code input & verify the code
      return await _handleCodeInput(
        context: context,
        token: startMfaResponse.token,
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
