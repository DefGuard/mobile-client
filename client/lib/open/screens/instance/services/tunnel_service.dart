import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/openid_mfa_waiting_dialog.dart';
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    PluginConnectPayload payload = _makePayload(instance, location);
    // Handle traffic type selection if necessary
    payload.traffic = instance.disableAllTraffic
        ? TunnelTraffic.predefined
        : (await showDialog<TunnelTraffic?>(
                context: context,
                builder: (_) => ConnectDialog(),
              ))
              // if user dismisses the dialog
              ??
              TunnelTraffic.predefined;

    // Handle mfa
    if (location.mfaEnabled) {
      final presharedKey = instance.useOpenidForMfa
          ? await _handleOpenidMfaFlow(
              navigator: navigator,
              messenger: messenger,
              proxyUrl: instance.proxyUrl,
              payload: payload,
            )
          : await _handleMfaFlow(
              navigator: navigator,
              messenger: messenger,
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

  /// Helper function to show dialog using captured NavigatorState
  static Future<T?> _showDialog<T>({
    required NavigatorState navigator,
    required Widget Function(BuildContext) builder,
  }) {
    return showDialog<T>(
      context: navigator.context,
      builder: builder,
    );
  }

  /// Handles OpenID, browser-based MFA
  /// Returns preshared key.
  static Future<String?> _handleOpenidMfaFlow({
    required NavigatorState navigator,
    required ScaffoldMessengerState messenger,
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

      bool? browserOpened = await _showDialog<bool>(
        navigator: navigator,
        builder: (context) => OpenIdMfaStartDialog(
          proxyUrl: proxyUrl,
          token: startMfaResponse.token,
        ),
      );

      if (browserOpened == null || !browserOpened) {
        // dialog dismissed or failed to open the browser
        return null;
      }

      final FinishMfaResponse? finishMfaResponse = await _showDialog<FinishMfaResponse>(
        navigator: navigator,
        builder: (context) => OpenidMfaWaitingDialog(
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
        ),
      );

      return finishMfaResponse?.presharedKey;
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      return null;
    } catch (e) {
      talker.error("OpenID MFA flow error: $e");
      return null;
    }
  }

  /// Displays non-openid mfa method selection and code input dialogs
  /// Returns preshared key.
  static Future<String?> _handleMfaFlow({
    required NavigatorState navigator,
    required ScaffoldMessengerState messenger,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required bool useOpenid,
  }) async {
    try {
      // Show MFA method selection dialog
      final MfaMethod? method = await _showDialog<MfaMethod>(
        navigator: navigator,
        builder: (context) => SelectMfaMethodDialog(),
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
      return await _showDialog<String>(
        navigator: navigator,
        builder: (context) => CodeDialog(
          token: startMfaResponse.token,
          url: proxyUrl,
          method: method,
        ),
      );
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      return null;
    } catch (e) {
      talker.error("MFA flow error: $e");
      return null;
    }
  }
}
