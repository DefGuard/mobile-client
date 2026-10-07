import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/mfa/mfa_transport.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/plugin/plugin.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/logging.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/riverpod/biometrics_state.dart';
import 'package:mobile/open/screens/mfa/mfa_step_flow.dart';
import 'package:mobile/utils/instance_secrets.dart';
import 'package:mobile/utils/update_instance.dart';

import '../../../../data/db/enums.dart';
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

    /// Overrides the saved default for the steps it covers, positionally.
    List<MfaMethod?> mfaPlan = const [],
  }) async {
    final navigator = Navigator.of(context);

    final privateKey = await instance.wireguardPrivateKey();
    if (privateKey == null) {
      reportMissingSecret(instance.logName, "WireGuard private key");
      return const ConnectResult.failed(message: missingSecretsMessage);
    }
    PluginConnectPayload payload = _makePayload(
      instance,
      location,
      trafficMethod,
      privateKey,
    );
    // An MFA retry may refresh the instance and location rows; the tunnel
    // payload and the saved preferences must follow the refreshed ones.
    DefguardInstance connectedInstance = instance;

    MfaMethod? authorizedWith;

    if (shouldStartMfa(location)) {
      final capabilities = MfaCapabilities(
        biometricAvailable:
            instance.mfaKeysStored && biometricsStatus.canOpenStorage,
        contract: instance.mfaContract,
      );
      final resolved = resolveMfaStepPlan(
        location,
        oneOff: mfaPlan,
        capabilities: capabilities,
      );
      if (resolved.isEmpty || resolved.contains(null)) {
        return const ConnectResult.failed(
          message: "This location cannot be verified from the mobile app.",
          logMessage: "Connect attempted on a location with an unpassable step",
        );
      }
      final plan = resolved.cast<MfaMethod>();
      talker.debug(
        "Starting ${plan.length}-step MFA for networkId ${payload.networkId}: "
        "${plan.map((m) => m.toReadableString()).join(', ')}",
      );

      await requestNotificationPermissions();
      final flow = MfaStepFlow(
        navigator: navigator,
        controller: MfaFlowController(
          transport: mfaTransportForContract(
            instance.mfaContract,
            Uri.parse(instance.proxyUrl),
          ),
          plan: plan,
          devicePubkey: payload.devicePublicKey,
          networkId: payload.networkId,
          postureData: payload.postureCheckRequired ? await getPosture() : null,
          refreshPlan: instance.mfaContract == MfaContract.multiStep
              ? () async {
                  final retry = await _refreshMfaPlan(
                    db: db,
                    instance: instance,
                    location: location,
                    oneOff: mfaPlan,
                    capabilities: capabilities,
                  );
                  if (retry == null) return null;
                  final refreshed = _makePayload(
                    retry.instance,
                    retry.location,
                    trafficMethod,
                    privateKey,
                  );
                  if (!canReuseMfaAttempt(payload, refreshed)) {
                    talker.warning(
                      "Not retrying MFA for networkId ${payload.networkId}: "
                      "the refresh changed what the started attempt was bound to",
                    );
                    return null;
                  }
                  payload = refreshed;
                  connectedInstance = retry.instance;
                  return retry.plan;
                }
              : null,
        ),
        proxyUrl: instance.proxyUrl,
        instanceUrl: instance.url,
        secureStorageKey: instance.secureStorageKey,
        openidDisplayName: instance.openidDisplayName,
        openidProvider: instance.openidProviderKind,
      );

      switch (await flow.run()) {
        case MfaFlowCancelled():
          return const ConnectResult.cancelled();
        case MfaFlowFailed(:final message, :final logMessage, :final error):
          return ConnectResult.failed(
            message: message,
            logMessage: logMessage,
            error: error,
          );
        case MfaFlowConnected():
          payload.presharedKey = flow.controller.takePresharedKey();
      }
      // Only meaningful for a single-step flow; a multi-step one is described
      // by its step count instead.
      final completedPlan = flow.controller.plan;
      authorizedWith = completedPlan.length == 1 ? completedPlan.single : null;
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
      connectedInstance,
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
    // Set only for a single-step flow, where the sheet's picker is also how the
    // step's default changes. A multi-step plan is owned by the MFA settings
    // screen and left alone here.
    final plan = mfaMethod != null
        ? drift.Value<List<MfaMethod?>>([mfaMethod])
        : const drift.Value<List<MfaMethod?>>.absent();

    if (!traffic.present && !mfa.present) {
      return;
    }

    try {
      await (db.update(
        db.locations,
      )..where((t) => t.id.equals(location.id))).write(
        LocationsCompanion(
          trafficMethod: traffic,
          mfaMethod: mfa,
          mfaStepPlan: plan,
        ),
      );
    } catch (e) {
      talker.error(
        "Failed to remember connection preferences for location ${location.id}",
        e,
      );
    }
  }

  /// The started MFA attempt was bound to the device key, network and posture
  /// data; a retry may only reuse it when the refresh left those unchanged.
  @visibleForTesting
  static bool canReuseMfaAttempt(
    PluginConnectPayload attempt,
    PluginConnectPayload refreshed,
  ) =>
      attempt.devicePublicKey == refreshed.devicePublicKey &&
      attempt.networkId == refreshed.networkId &&
      attempt.postureCheckRequired == refreshed.postureCheckRequired;

  static Future<
    ({List<MfaMethod> plan, DefguardInstance instance, Location location})?
  >
  _refreshMfaPlan({
    required AppDatabase db,
    required DefguardInstance instance,
    required Location location,
    required List<MfaMethod?> oneOff,
    required MfaCapabilities capabilities,
  }) async {
    final token = await instance.poolingToken();
    if (token == null) return null;

    final (config, _, _) = await proxyApi.pollConfiguration(
      instance.proxyUrl,
      token,
    );
    if (config == null) return null;

    final update = await updateInstance(
      db: db,
      instance: instance,
      configs: config.configs,
      info: config.instance,
      token: config.token,
    );
    if (update == null) return null;

    final refreshedInstance = await db.managers.defguardInstances
        .filter((row) => row.id.equals(instance.id))
        .getSingleOrNull();
    if (refreshedInstance == null) return null;

    final refreshedLocation = await db.managers.locations
        .filter((row) => row.id.equals(location.id))
        .getSingleOrNull();
    if (refreshedLocation == null) return null;

    final plan = resolveMfaRetryPlan(
      refreshedLocation,
      attempt: capabilities,
      refreshedContract: refreshedInstance.mfaContract,
      oneOff: oneOff,
    );
    if (plan == null) return null;
    return (
      plan: plan,
      instance: refreshedInstance,
      location: refreshedLocation,
    );
  }

  /// Whether the location has an MFA flow to satisfy. Legacy single-mode
  /// locations are normalized into a one-step flow by `effectiveMfaSteps`.
  static bool checkMfaEnabled(Location location) => shouldStartMfa(location);

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

  static PluginConnectPayload _makePayload(
    DefguardInstance instance,
    Location location,
    RoutingMethod trafficMethod,
    String privateKey,
  ) {
    // The instance policy outranks whatever the caller asked for - it is the
    // administrator's setting, not a user preference.
    final selectedTrafficMethod = switch (instance.clientTrafficPolicy) {
      ClientTrafficPolicy.disableAllTraffic => RoutingMethod.predefined,
      ClientTrafficPolicy.forceAllTraffic => RoutingMethod.all,
      ClientTrafficPolicy.none => trafficMethod,
    };
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
      traffic: selectedTrafficMethod,
      postureCheckRequired: location.postureCheckRequired == true,
    );
  }
}
