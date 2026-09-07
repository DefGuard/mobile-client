import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_screen.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/mfa/mfa_biometric_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_email_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_totp_screen.dart';
import 'package:mobile/utils/instance_secrets.dart';

import '../../../../data/db/enums.dart';
import 'package:mobile/logging.dart';
import '../../../../utils/notifications.dart';

/// How a connect attempt ended. Reporting it - a toast, a snackbar, nothing at
/// all - is the caller's business, the service only states what happened.
enum ConnectStatus { connected, cancelled, failed }

class ConnectResult {
  final ConnectStatus status;

  /// Safe, user facing text. Set only when [status] is [ConnectStatus.failed].
  final String? message;

  /// Detail for the log, never displayed.
  final String? logMessage;
  final Object? error;

  const ConnectResult.connected()
    : status = ConnectStatus.connected,
      message = null,
      logMessage = null,
      error = null;

  const ConnectResult.cancelled()
    : status = ConnectStatus.cancelled,
      message = null,
      logMessage = null,
      error = null;

  const ConnectResult.failed({
    required this.message,
    this.logMessage,
    this.error,
  }) : status = ConnectStatus.failed;
}

/// Outcome of a single pre-connect step (MFA, posture check). [presharedKey] is
/// set when the step succeeded and [failure] when it failed with something the
/// user should be told about; both stay null when the user simply backed out.
class _StepOutcome {
  final String? presharedKey;
  final ConnectResult? failure;

  const _StepOutcome.success(this.presharedKey) : failure = null;
  const _StepOutcome.failed(this.failure) : presharedKey = null;
  const _StepOutcome.cancelled() : presharedKey = null, failure = null;
}

/// Handles MFA flows and tunnel connection
class TunnelService {
  /// Main service method - handles MFA, interface configuration and connection.
  ///
  /// The caller collects the user's traffic and MFA choices up front (the
  /// connect bottom sheet does), so this method never puts UI of its own in
  /// front of the user except the MFA step screens.
  static Future<ConnectResult> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required dynamic wireguardPlugin,
    required BiometricsState biometricsStatus,
    required AppDatabase db,
    required RoutingMethod trafficMethod,
    MfaMethod? mfaMethod,
  }) async {
    final navigator = Navigator.of(context);

    // The instance policy outranks whatever the caller asked for - it is the
    // administrator's setting, not a user preference.
    final RoutingMethod selectedTrafficMethod =
        switch (instance.clientTrafficPolicy) {
          ClientTrafficPolicy.disableAllTraffic => RoutingMethod.predefined,
          ClientTrafficPolicy.forceAllTraffic => RoutingMethod.all,
          ClientTrafficPolicy.none => trafficMethod,
        };

    // prepare wireguard plugin payload
    final privateKey = await instance.wireguardPrivateKey();
    if (privateKey == null) {
      reportMissingSecret(instance.logName, "WireGuard private key");
      return const ConnectResult.failed(message: missingSecretsMessage);
    }
    PluginConnectPayload payload = _makePayload(
      instance,
      location,
      selectedTrafficMethod,
      privateKey,
    );

    MfaMethod? authorizedWith;

    if (checkMfaEnabled(location)) {
      await requestNotificationPermissions();
      late MfaMethod selectedMfaMethod;
      if (location.locationMfaMode == LocationMfaMode.external) {
        selectedMfaMethod = MfaMethod.openid;
      } else if (mfaMethod != null &&
          !(mfaMethod == MfaMethod.biometric &&
              !biometricsStatus.canOpenStorage)) {
        selectedMfaMethod = mfaMethod;
      } else {
        // The caller only offers methods that are actually usable, so getting
        // here means its capability snapshot went stale mid-connect. Bail out
        // and let the user pick again rather than guessing a method.
        return const ConnectResult.failed(
          message: "Select an MFA method to connect.",
          logMessage:
              "Connect called without a usable MFA method for an MFA location",
        );
      }

      final mfaOutcome = await _performMfa(
        navigator: navigator,
        proxyUrl: instance.proxyUrl,
        payload: payload,
        method: selectedMfaMethod,
        secureStorageKey: instance.secureStorageKey,
        openidDisplayName: instance.openidDisplayName,
      );
      if (mfaOutcome.failure != null) {
        return mfaOutcome.failure!;
      }
      if (mfaOutcome.presharedKey == null) {
        return const ConnectResult.cancelled();
      }
      payload.presharedKey = mfaOutcome.presharedKey;
      authorizedWith = selectedMfaMethod;
    } else if (payload.postureCheckRequired) {
      final poolingToken = await instance.poolingToken();
      if (poolingToken == null) {
        reportMissingSecret(instance.logName, "Proxy token");
        return const ConnectResult.failed(message: missingSecretsMessage);
      }
      final postureOutcome = await _performPostureCheck(
        proxyUrl: instance.proxyUrl,
        payload: payload,
        pollingToken: poolingToken,
      );
      if (postureOutcome.failure != null) {
        return postureOutcome.failure!;
      }
      payload.presharedKey = postureOutcome.presharedKey;
    }

    await wireguardPlugin.startTunnel(jsonEncode(payload.toJson()));

    await _rememberPreferences(
      db,
      instance,
      location,
      trafficMethod: trafficMethod,
      // null unless an MFA step actually ran
      mfaMethod: authorizedWith,
    );

    return const ConnectResult.connected();
  }

  /// Stores the connection preferences on the location row so the next connect
  /// can pre-select them, and so the UI can show what authorized the tunnel.
  ///
  /// Runs only after the tunnel actually started, so a cancelled or failed
  /// connect never overwrites a working preference. Fields left absent keep
  /// their stored value - passing `Value(null)` would clear them instead.
  static Future<void> _rememberPreferences(
    AppDatabase db,
    DefguardInstance instance,
    Location location, {
    required RoutingMethod trafficMethod,
    MfaMethod? mfaMethod,
  }) async {
    // Under a forced policy the routing was not the user's choice, so there is
    // nothing worth remembering.
    final traffic = instance.clientTrafficPolicy == ClientTrafficPolicy.none
        ? drift.Value(trafficMethod)
        : const drift.Value<RoutingMethod?>.absent();
    final mfa = mfaMethod != null
        ? drift.Value(mfaMethod)
        : const drift.Value<MfaMethod?>.absent();

    if (!traffic.present && !mfa.present) {
      return;
    }

    try {
      await (db.update(db.locations)..where((t) => t.id.equals(location.id)))
          .write(LocationsCompanion(trafficMethod: traffic, mfaMethod: mfa));
    } catch (e) {
      talker.error(
        "Failed to remember connection preferences for location ${location.id}",
        e,
      );
    }
  }

  /// Checks if MFA is enabled for specified location taking into account
  /// the deprecated `mfaEnabled` option.
  static bool checkMfaEnabled(Location location) {
    return location.mfaEnabled == true ||
        location.locationMfaMode == LocationMfaMode.internal ||
        location.locationMfaMode == LocationMfaMode.external;
  }

  /// Performs posture-only authorization and returns runtime preshared key.
  static Future<_StepOutcome> _performPostureCheck({
    required String proxyUrl,
    required PluginConnectPayload payload,
    required String pollingToken,
  }) async {
    try {
      final presharedKey = await _authorizePostureOnly(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        pollingToken,
      );
      return _StepOutcome.success(presharedKey);
    } on PostureCheckException catch (e) {
      return _StepOutcome.failed(
        ConnectResult.failed(
          message: e.message,
          logMessage: 'Posture check failed',
          error: e,
        ),
      );
    } on HttpException catch (e) {
      return _StepOutcome.failed(
        ConnectResult.failed(
          message: 'Posture check request failed. Please try again.',
          logMessage: 'Posture check request failed',
          error: e,
        ),
      );
    } catch (e) {
      return _StepOutcome.failed(
        ConnectResult.failed(
          message: 'Posture check failed. Please try again.',
          logMessage: 'Posture-only connect failed!',
          error: e,
        ),
      );
    }
  }

  /// Performs MFA using specified method.
  /// Returns the runtime preshared key on success.
  static Future<_StepOutcome> _performMfa({
    required NavigatorState navigator,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required MfaMethod method,
    String? secureStorageKey,
    String? openidDisplayName,
  }) async {
    try {
      final startMfaResponse = await _startMfa(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        method,
        payload.postureCheckRequired,
      );

      String? presharedKey;
      if (method == MfaMethod.openid) {
        presharedKey = await _handleOpenid(
          navigator: navigator,
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
          method: method,
          openidDisplayName: openidDisplayName,
        );
      } else if (method == MfaMethod.biometric) {
        if (startMfaResponse.challenge == null) {
          throw "Challenge not found in start response";
        }
        if (secureStorageKey == null) {
          throw "Storage key not provided";
        }
        presharedKey = await _handleBiometric(
          navigator: navigator,
          proxyUrl: proxyUrl,
          token: startMfaResponse.token,
          challenge: startMfaResponse.challenge!,
          secureStorageKey: secureStorageKey,
        );
      } else {
        presharedKey = await _handleCodeInput(
          navigator: navigator,
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
          method: method,
        );
      }

      return presharedKey == null
          ? const _StepOutcome.cancelled()
          : _StepOutcome.success(presharedKey);
    } on MfaMethodNotAvailableException catch (e) {
      final methodString = e.method.toReadableString();
      return _StepOutcome.failed(
        ConnectResult.failed(
          message:
              "$methodString is not configured on your account. Select a different MFA method.",
          logMessage:
              "MFA method $methodString was not configured on the account. Connect Failed.",
          error: e,
        ),
      );
    } on HttpException catch (e) {
      return _StepOutcome.failed(
        ConnectResult.failed(
          message: "MFA request failed. Please try again.",
          logMessage: "Connect MFA failed!",
          error: e,
        ),
      );
    } catch (e) {
      return _StepOutcome.failed(
        ConnectResult.failed(
          message: "MFA failed. Please try again.",
          logMessage: "MFA flow error!",
          error: e,
        ),
      );
    }
  }

  /// Handles OpenID MFA flow
  static Future<String?> _handleOpenid({
    required NavigatorState navigator,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
    String? openidDisplayName,
  }) async {
    final presharedKey = await Navigator.of(navigator.context).push<String?>(
      MaterialPageRoute(
        builder: (context) => OpenIdMfaScreen(
          screenData: OpenIdMfaScreenData(
            proxyUrl: proxyUrl,
            token: token,
            openidDisplayName: openidDisplayName,
          ),
        ),
      ),
    );
    if (presharedKey != null) {
      talker.info("Code authentication successful");
    }
    return presharedKey;
  }

  /// Handles biometric MFA flow
  static Future<String?> _handleBiometric({
    required NavigatorState navigator,
    required String proxyUrl,
    required String token,
    required String challenge,
    required String secureStorageKey,
  }) async {
    final presharedKey = await Navigator.of(navigator.context).push<String?>(
      MaterialPageRoute(
        builder: (context) => MfaBiometricScreen(
          screenData: MfaBiometricScreenData(
            proxyUrl: proxyUrl,
            token: token,
            challenge: challenge,
            secureStorageKey: secureStorageKey,
          ),
        ),
      ),
    );
    if (presharedKey != null) {
      talker.info("Biometric authentication successful");
    }
    return presharedKey;
  }

  /// Handles code based MFA flows (totp, email)
  static Future<String?> _handleCodeInput({
    required NavigatorState navigator,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
  }) async {
    final screenData = MfaCodeScreenData(proxyUrl: proxyUrl, token: token);
    final Widget screen = method == MfaMethod.email
        ? MfaEmailScreen(screenData: screenData)
        : MfaTotpScreen(screenData: screenData);

    final presharedKey = await Navigator.of(
      navigator.context,
    ).push<String?>(MaterialPageRoute(builder: (context) => screen));
    if (presharedKey != null) {
      talker.info("Code authentication successful");
    }
    return presharedKey;
  }

  /// Calls `/client-mfa/start` endpoint, returns `StartMfaResponse` with session token.
  static Future<StartMfaResponse> _startMfa(
    String url,
    String pubkey,
    int networkId,
    MfaMethod method,
    bool postureCheckRequired,
  ) async {
    talker.debug(
      "Starting MFA for networkId: $networkId, method: ${method.toReadableString()}",
    );
    final postureData = postureCheckRequired ? await getPosture() : null;
    final request = StartMfaRequest(
      pubkey: pubkey,
      locationId: networkId,
      method: method,
      postureData: postureData,
    );

    final uri = Uri.parse(url);
    return await proxyApi.startMfa(uri, request);
  }

  /// Calls `/posture/connect` endpoint and returns runtime preshared key.
  static Future<String> _authorizePostureOnly(
    String url,
    String pubkey,
    int networkId,
    String poolingToken,
  ) async {
    talker.debug('Starting posture check for networkId: $networkId');
    final request = PostureConnectRequest(
      locationId: networkId,
      pubkey: pubkey,
      devicePostureData: await getPosture(),
      token: poolingToken,
    );

    final response = await proxyApi.postureConnect(Uri.parse(url), request);
    return response.presharedKey;
  }

  /// Prepares wireguard plugin configuration
  static PluginConnectPayload _makePayload(
    DefguardInstance instance,
    Location location,
    RoutingMethod trafficMethod,
    String privateKey,
  ) {
    return PluginConnectPayload(
      publicKey: location.pubKey,
      devicePublicKey: instance.pubKey,
      privateKey: privateKey,
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
      postureCheckRequired: location.postureCheckRequired == true,
    );
  }
}
