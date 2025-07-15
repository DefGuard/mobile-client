import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/routing_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/code_dialog.dart';
import 'dart:convert';

import '../../../../data/db/enums.dart';
import '../../../../logging.dart';

/// Handles MFA flows and tunnel connection
class TunnelService {

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

  static PluginConnectPayload _makePayload(DefguardInstance instance,
      Location location,
      RoutingMethod trafficMethod,) {
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
      traffic: trafficMethod,
    );
  }

  /// Main service method - displays traffic & MFA dialogs, handles
  /// interface configuration and connection.
  static Future<void> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required dynamic wireguardPlugin,
  }) async {
    // handle traffic type selection if necessary
    late RoutingMethod trafficMethod;
    // instance enforces predefined
    if (instance.disableAllTraffic) {
      trafficMethod = RoutingMethod.predefined;
    } else {
      if (location.trafficMethod != null) {
        trafficMethod = location.trafficMethod!;
      } else {
        // no pre selected traffic choice available, ask user
        RoutingMethodDialogIntention dialogIntention = location.mfaEnabled
            ? RoutingMethodDialogIntention.next
            : RoutingMethodDialogIntention.connect;
        RoutingMethod? userSelection = await showDialog(
          context: context,
          builder: (_) =>
              RoutingMethodDialog(
                location: location,
                intention: dialogIntention,
              ),
        );
        // smth went wrong or user canceled the operation
        if (userSelection == null) {
          return;
        }
        trafficMethod = userSelection;
      }
    }

    PluginConnectPayload payload = _makePayload(
      instance,
      location,
      trafficMethod,
    );

    // handle mfa
    if (location.mfaEnabled) {
      if (!context.mounted) {
        return;
      }
      MfaMethod mfaMethod;
      if (location.mfaMethod == null) {
        final userSelection = await showDialog<MfaMethod?>(context: context,
            builder: (_) =>
                MfaMethodDialog(location: location,
                  intention: MfaMethodDialogIntention.connect,));
        if(userSelection == null) {
          return;
        }
        mfaMethod = userSelection;
      } else {
        mfaMethod = location.mfaMethod!;
      }

      // get session token
      final startMfaResponse = await _startMfa(
        instance.proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        mfaMethod,
      );

      if(!context.mounted) return;

      final presharedKey = await _handleMfaFlow(
        context: context,
        proxyUrl: instance.proxyUrl,
        payload: payload,
        mfaMethod: mfaMethod,
        token: startMfaResponse.token,
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
    required MfaMethod mfaMethod,
    required String token,
  }) async {
    try {

      // handle specific MFA methods
      return await _handleCodeInput(
        context: context,
        token: token,
        proxyUrl: proxyUrl,
        method: mfaMethod,
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
