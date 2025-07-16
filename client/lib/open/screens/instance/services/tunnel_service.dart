import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/open/screens/instance/screens/mfa/mfa_code_screen.dart';
import 'package:mobile/open/screens/instance/screens/mfa/openid_mfa_screen.dart';
import 'package:mobile/open/screens/instance/widgets/mfa/mfa_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/routing_method_dialog.dart';
import 'dart:convert';

import '../../../../data/db/enums.dart';
import '../../../../logging.dart';

/// Handles MFA flows and tunnel connection
class TunnelService {
  /// Main service method - displays traffic & MFA dialogs, handles
  /// interface configuration and connection.
  static Future<void> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required dynamic wireguardPlugin,
  }) async {
    // prepare navigator to avoid "context use across async gaps"
    final navigator = Navigator.of(context);

    // handle traffic type selection if necessary
    late RoutingMethod trafficMethod;
    if (instance.disableAllTraffic) {
      // instance enforces predefined traffic
      trafficMethod = RoutingMethod.predefined;
    } else {
      // instance allows traffic type selection - use stored method or display selection dialog
      if (location.trafficMethod != null) {
        trafficMethod = location.trafficMethod!;
      } else {
        // no pre selected traffic choice available, ask user
        RoutingMethodDialogIntention dialogIntention = location.mfaEnabled
            ? RoutingMethodDialogIntention.next
            : RoutingMethodDialogIntention.connect;
        RoutingMethod? userSelection = await _showDialog(
          navigator: navigator,
          builder: (_) => RoutingMethodDialog(
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

    // prepare wireguard plugin payload
    PluginConnectPayload payload = _makePayload(
      instance,
      location,
      trafficMethod,
    );

    // handle MFA if configured
    if (location.mfaEnabled) {
      MfaMethod mfaMethod;
      if (instance.useOpenidForMfa) {
        // instance setup for openid mfa login
        mfaMethod = MfaMethod.openid;
      } else {
        // non-openid mfa setup, use stored method or show method choice dialog
        if (location.mfaMethod == null) {
          final userSelection = await _showDialog<MfaMethod?>(
            navigator: navigator,
            builder: (_) => MfaMethodDialog(
              location: location,
              intention: MfaMethodDialogIntention.connect,
            ),
          );
          if (userSelection == null) {
            // dialog dismissed
            return;
          }
          mfaMethod = userSelection;
        } else {
          mfaMethod = location.mfaMethod!;
        }
      }

      // perform MFA to get the preshared key
      final presharedKey = await _performMfa(
        navigator: navigator,
        proxyUrl: instance.proxyUrl,
        payload: payload,
        method: mfaMethod,
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

  /// Performs MFA using specified method.
  /// Returns preshared key.
  static Future<String?> _performMfa({
    required NavigatorState navigator,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required MfaMethod method,
  }) async {
    // prepare messenger to avoid "context use across async gaps"
    final messenger = ScaffoldMessenger.of(navigator.context);
    try {
      // get session token
      final startMfaResponse = await _startMfa(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        method,
      );
      if (method == MfaMethod.openid) {
        // perform openid-based MFA
        return await _handleOpenid(
          navigator: navigator,
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
          method: method,
        );
      } else {
        // perform non-openid-based MFA
        return await _handleCodeInput(
          navigator: navigator,
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
          method: method,
        );
      }
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      return null;
    } catch (e) {
      talker.error("MFA flow error: $e");
      return null;
    }
  }

  /// Handles OpenID MFA flow
  static Future<String?> _handleOpenid({
    required NavigatorState navigator,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
  }) async {
    final presharedKey = await Navigator.of(navigator.context).push<String?>(
      MaterialPageRoute(
        builder: (context) => OpenIdMfaScreen(proxyUrl: proxyUrl, token: token),
      ),
    );
    if (presharedKey != null) {
      talker.info("Code authentication successful");
    }
    return presharedKey;
  }

  /// Handles non-openid MFA flows (totp, email)
  static Future<String?> _handleCodeInput({
    required NavigatorState navigator,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
  }) async {
    try {
      final presharedKey = await Navigator.of(navigator.context).push<String?>(
        MaterialPageRoute(
          builder: (context) =>
              MfaCodeScreen(token: token, url: proxyUrl, method: method),
        ),
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

  /// Prepares wireguard plugin configuration
  static PluginConnectPayload _makePayload(
    DefguardInstance instance,
    Location location,
    RoutingMethod trafficMethod,
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
      traffic: trafficMethod,
    );
  }

  /// Helper function to show dialog using captured NavigatorState
  static Future<T?> _showDialog<T>({
    required NavigatorState navigator,
    required Widget Function(BuildContext) builder,
  }) {
    return showDialog<T>(context: navigator.context, builder: builder);
  }
}
