import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_screen.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/instance/widgets/mfa_method_dialog.dart';
import 'package:mobile/open/screens/instance/widgets/routing_method_dialog.dart';
import 'package:mobile/open/screens/next/mfa/next_mfa_email_screen.dart';
import 'package:mobile/enterprise/screens/mfa/next/next_mfa_openid_screen.dart';
import 'package:mobile/open/screens/next/mfa/next_mfa_totp_screen.dart';
import 'package:mobile/open/services/snackbar_service.dart';
import 'package:mobile/open/widgets/dg_snackbar.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/utils/error_handler.dart';
import 'package:mobile/utils/secure_storage.dart';

import '../../../../data/db/enums.dart';
import '../../../../logging.dart';
import '../../../../utils/notifications.dart';

/// Handles MFA flows and tunnel connection
class TunnelService {
  /// Main service method - displays traffic & MFA dialogs, handles
  /// interface configuration and connection.
  static Future<void> connect({
    required BuildContext context,
    required DefguardInstance instance,
    required Location location,
    required dynamic wireguardPlugin,
    required BiometricsState biometricsStatus,
    required AppDatabase db,
    RoutingMethod? trafficMethod,
    MfaMethod? mfaMethod,
  }) async {
    // prepare navigator to avoid "context use across async gaps"
    final navigator = Navigator.of(context);

    // handle traffic type selection if necessary
    late RoutingMethod selectedTrafficMethod;
    if (trafficMethod != null) {
      selectedTrafficMethod = trafficMethod;
    } else if (instance.clientTrafficPolicy ==
        ClientTrafficPolicy.disableAllTraffic) {
      // instance enforces predefined traffic
      selectedTrafficMethod = RoutingMethod.predefined;
    } else if (instance.clientTrafficPolicy ==
        ClientTrafficPolicy.forceAllTraffic) {
      // instance enforces all traffic
      selectedTrafficMethod = RoutingMethod.all;
    } else {
      // instance allows traffic type selection - use stored method or display selection dialog
      if (location.trafficMethod != null) {
        selectedTrafficMethod = location.trafficMethod!;
      } else {
        // no pre selected traffic choice available, ask user
        RoutingMethodDialogIntention dialogIntention = checkMfaEnabled(location)
            ? RoutingMethodDialogIntention.next
            : RoutingMethodDialogIntention.connect;
        RoutingMethod? userSelection = await _showDialog(
          navigator: navigator,
          builder: (_) => RoutingMethodDialog(
            location: location,
            intention: dialogIntention,
            clientTrafficPolicy: instance.clientTrafficPolicy,
          ),
        );
        // smth went wrong or user canceled the operation
        if (userSelection == null) {
          return;
        }
        selectedTrafficMethod = userSelection;
      }
    }

    // prepare wireguard plugin payload
    PluginConnectPayload payload = _makePayload(
      instance,
      location,
      selectedTrafficMethod,
    );

    // the method that actually authorized this connection - stays null when no
    // MFA was performed, which is what keeps non-MFA locations from having a
    // phantom method remembered for them
    MfaMethod? authorizedWith;

    // handle MFA if configured
    if (checkMfaEnabled(location)) {
      // Request notification permissions for MFA session expiry alerts
      await requestNotificationPermissions();
      late MfaMethod selectedMfaMethod;
      if (location.locationMfaMode == LocationMfaMode.external) {
        // location setup for openid mfa login - the server dictates the method,
        // so this stays ahead of any caller-supplied choice
        selectedMfaMethod = MfaMethod.openid;
      } else if (mfaMethod != null &&
          !(mfaMethod == MfaMethod.biometric &&
              !biometricsStatus.canOpenStorage)) {
        // caller already collected the choice from the user
        selectedMfaMethod = mfaMethod;
      } else {
        // non-openid mfa setup, use stored method or show method choice dialog
        if (location.mfaMethod == null ||
            (location.mfaMethod == MfaMethod.biometric &&
                !biometricsStatus.canOpenStorage)) {
          final userSelection = await _showDialog<MfaMethod?>(
            navigator: navigator,
            builder: (_) => MfaMethodDialog(
              instance: instance,
              location: location,
              intention: MfaMethodDialogIntention.connect,
            ),
          );
          if (userSelection == null) {
            // dialog dismissed
            return;
          }
          selectedMfaMethod = userSelection;
        } else {
          selectedMfaMethod = location.mfaMethod!;
        }
      }

      // perform MFA to get the preshared key
      final presharedKey = await _performMfa(
        navigator: navigator,
        proxyUrl: instance.proxyUrl,
        payload: payload,
        method: selectedMfaMethod,
        secureStorageKey: instance.secureStorageKey,
        openidDisplayName: instance.openidDisplayName,
      );
      if (presharedKey == null) {
        // user dismissed the dialog
        return;
      }
      payload.presharedKey = presharedKey;
      authorizedWith = selectedMfaMethod;
    } else if (payload.postureCheckRequired) {
      final presharedKey = await _performPostureCheck(
        navigator: navigator,
        proxyUrl: instance.proxyUrl,
        payload: payload,
        pollingToken: instance.poolingToken,
      );
      if (presharedKey == null) {
        return;
      }
      payload.presharedKey = presharedKey;
    }

    // start the tunnel
    await wireguardPlugin.startTunnel(jsonEncode(payload.toJson()));

    // only remember what the caller explicitly collected from the user - the
    // legacy dialogs keep owning their own "Remember my choice" checkbox
    await _rememberPreferences(
      db,
      instance,
      location,
      trafficMethod: trafficMethod,
      mfaMethod: mfaMethod != null ? authorizedWith : null,
    );
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
    RoutingMethod? trafficMethod,
    MfaMethod? mfaMethod,
  }) async {
    // only the "none" policy leaves the routing choice to the user - under an
    // enforced policy the value is the server's, not a preference
    final traffic =
        instance.clientTrafficPolicy == ClientTrafficPolicy.none &&
            trafficMethod != null
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
  static Future<String?> _performPostureCheck({
    required NavigatorState navigator,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required String pollingToken,
  }) async {
    final messenger = ScaffoldMessenger.of(navigator.context);
    try {
      return await _authorizePostureOnly(
        proxyUrl,
        payload.devicePublicKey,
        payload.networkId,
        pollingToken,
      );
    } on PostureCheckException catch (e) {
      talker.error('Posture check failed', e);
      messenger.showSnackBar(
        dgSnackBar(text: e.toString(), textColor: DgColor.textAlert),
      );
    } on HttpException catch (e) {
      talker.error('Posture check request failed', e);
      messenger.showSnackBar(
        dgSnackBar(text: 'Error: ${e.message}', textColor: DgColor.textAlert),
      );
    } catch (e) {
      talker.error('Posture-only connect failed: $e');
      messenger.showSnackBar(
        dgSnackBar(text: 'Error: $e', textColor: DgColor.textAlert),
      );
    }
    return null;
  }

  /// Performs MFA using specified method.
  /// Returns preshared key.
  static Future<String?> _performMfa({
    required NavigatorState navigator,
    required String proxyUrl,
    required PluginConnectPayload payload,
    required MfaMethod method,
    String? secureStorageKey,
    String? openidDisplayName,
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
        payload.postureCheckRequired,
      );
      if (method == MfaMethod.openid) {
        // perform openid-based MFA
        return await _handleOpenid(
          navigator: navigator,
          token: startMfaResponse.token,
          proxyUrl: proxyUrl,
          method: method,
          openidDisplayName: openidDisplayName,
        );
      }
      if (method == MfaMethod.biometric) {
        if (startMfaResponse.challenge == null) {
          throw "Challenge not found in start response";
        }
        if (secureStorageKey == null) {
          throw "Storage key not provided";
        }
        final secureStorage = await getBiometricInstanceStorage(
          secureStorageKey,
          prompt: "Confirm to connect",
        );
        final signed = signChallenge(
          startMfaResponse.challenge!,
          secureStorage.privateKey,
        );
        final finishData = FinishMfaRequest(
          token: startMfaResponse.token,
          code: signed,
        );
        final response = await proxyApi.finishMfa(
          Uri.parse(proxyUrl),
          finishData,
        );
        return response.presharedKey;
      }
      // perform email or totp MFA
      return await _handleCodeInput(
        navigator: navigator,
        token: startMfaResponse.token,
        proxyUrl: proxyUrl,
        method: method,
      );
    } on MfaMethodNotAvailableException catch (e) {
      final methodString = e.method.toReadableString();
      talker.error(
        "MFA method $methodString was not configured on the account. Connect Failed.",
      );
      messenger.showSnackBar(
        dgSnackBar(
          text:
              "You do not have $methodString method configured. Please either select a different MFA method or configure it on your account.",
          onDismiss: () {
            messenger.hideCurrentSnackBar();
          },
        ),
      );
      return null;
    } on HttpException catch (e) {
      talker.error("Connect MFA failed!", e);
      messenger.showSnackBar(
        dgSnackBar(text: "Error: ${e.message}", textColor: DgColor.textAlert),
      );
      return null;
    } catch (e) {
      talker.error("MFA flow error: $e");
      messenger.showSnackBar(
        dgSnackBar(text: "Error: $e", textColor: DgColor.textAlert),
      );
      return null;
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
        builder: (context) => NextOpenIdMfaScreen(
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

  /// Handles non-openid MFA flows (totp, email)
  static Future<String?> _handleCodeInput({
    required NavigatorState navigator,
    required String token,
    required String proxyUrl,
    required MfaMethod method,
  }) async {
    try {
      Widget screen;
      if (method == MfaMethod.email) {
        screen = NextMfaEmailScreen(
          onSubmit: (code, setError) async {
            try {
              final finishData = FinishMfaRequest(token: token, code: code);
              final response = await proxyApi.finishMfa(
                Uri.parse(proxyUrl),
                finishData,
              );
              if (navigator.mounted) {
                Navigator.of(navigator.context).pop(response.presharedKey);
              }
            } on DioException catch (e) {
              if (e.response?.statusCode == 401) {
                setError('Enter valid code');
              } else {
                SnackbarService.showError(
                  ErrorHandler.getHumanReadableError(e),
                );
              }
            } catch (e) {
              SnackbarService.showError(ErrorHandler.getHumanReadableError(e));
            }
          },
        );
      } else {
        screen = NextMfaTotpScreen(
          onSubmit: (code, setError) async {
            try {
              final finishData = FinishMfaRequest(token: token, code: code);
              final response = await proxyApi.finishMfa(
                Uri.parse(proxyUrl),
                finishData,
              );
              if (navigator.mounted) {
                Navigator.of(navigator.context).pop(response.presharedKey);
              }
            } on DioException catch (e) {
              if (e.response?.statusCode == 401) {
                setError('Enter valid code');
              } else {
                SnackbarService.showError(
                  ErrorHandler.getHumanReadableError(e),
                );
              }
            } catch (e) {
              SnackbarService.showError(ErrorHandler.getHumanReadableError(e));
            }
          },
        );
      }

      final presharedKey = await Navigator.of(
        navigator.context,
      ).push<String?>(MaterialPageRoute(builder: (context) => screen));
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
      postureCheckRequired: location.postureCheckRequired == true,
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
