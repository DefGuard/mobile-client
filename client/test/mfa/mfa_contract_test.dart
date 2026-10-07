import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/data/proxy/config.dart' as proxy_config;
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/utils/update_instance.dart';

class _RejectingFlowTransport implements MfaTransport {
  int startCalls = 0;

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async {
    startCalls++;
    throw const MfaStartRejectedException('stale flow plan');
  }

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) async =>
      throw StateError('unexpected second flow step');

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async => throw StateError('unexpected flow finish');
}

DeviceConfig _config({required bool legacy}) => DeviceConfig(
  networkId: 11,
  networkName: 'Warsaw',
  config: 'wg-config',
  endpoint: 'vpn.example:51820',
  assignedIp: '10.0.0.1/24',
  pubkey: 'pubkey',
  allowedIps: '0.0.0.0/0',
  mfaEnabled: true,
  keepaliveInterval: 25,
  locationMfaMode: LocationMfaMode.internal,
  steps: legacy
      ? const []
      : [
          MfaStep([MfaStepMethod.supported(MfaMethod.totp)]),
        ],
);

void main() {
  const base = <String, dynamic>{
    'id': 'instance-id',
    'name': 'instance',
    'url': 'https://defguard.example',
    'proxy_url': 'https://proxy.defguard.example',
    'username': 'user',
    'enterprise_enabled': false,
    'disable_all_traffic': false,
    'client_traffic_policy': 0,
  };

  test('missing or null mfa_user_state means legacy', () {
    final absent = InstanceInfo.fromJson(base);
    final nullValue = InstanceInfo.fromJson({...base, 'mfa_user_state': null});

    expect(mfaContractFromInstanceInfo(absent), MfaContract.legacy);
    expect(mfaContractFromInstanceInfo(nullValue), MfaContract.legacy);
    expect(absent.toCompanion().mfaContract.value, MfaContract.legacy);
  });

  test('polling config with mfa_user_state means multi-step', () {
    final response = proxy_config.InstanceInfoResponse.fromJson({
      'device_config': {
        'configs': [],
        'instance': {
          ...base,
          'mfa_user_state': {
            'configured_methods': [0],
          },
        },
      },
    });
    final info = response.deviceConfig!.instance!;

    expect(mfaContractFromInstanceInfo(info), MfaContract.multiStep);
    expect(info.toCompanion().mfaContract.value, MfaContract.multiStep);
  });

  test('config refresh promotes and demotes the stored contract', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.defguardInstances)
        .insert(
          DefguardInstancesCompanion.insert(
            name: 'instance',
            uuid: 'instance-id',
            url: 'https://defguard.example',
            deviceId: 7,
            proxyUrl: 'https://proxy.defguard.example',
            username: 'user',
            enterpriseEnabled: false,
            pubKey: 'public-key',
            mfaKeysStored: false,
          ),
        );

    var instance = await db.select(db.defguardInstances).getSingle();
    expect(instance.mfaContract, MfaContract.legacy);

    final promoted = await updateInstance(
      db: db,
      instance: instance,
      configs: const [],
      info: InstanceInfo.fromJson({
        ...base,
        'mfa_user_state': {'configured_methods': []},
      }),
    );
    expect(promoted?.instanceChanged, isTrue);
    instance = await db.select(db.defguardInstances).getSingle();
    expect(instance.mfaContract, MfaContract.multiStep);

    final demoted = await updateInstance(
      db: db,
      instance: instance,
      configs: const [],
      info: InstanceInfo.fromJson(base),
    );
    expect(demoted?.instanceChanged, isTrue);
    instance = await db.select(db.defguardInstances).getSingle();
    expect(instance.mfaContract, MfaContract.legacy);
  });

  test(
    'a refresh demoting the stored contract never retries the flow transport',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.defguardInstances)
          .insert(
            DefguardInstancesCompanion.insert(
              name: 'instance',
              uuid: 'instance-id',
              url: 'https://defguard.example',
              deviceId: 7,
              proxyUrl: 'https://proxy.defguard.example',
              username: 'user',
              enterpriseEnabled: false,
              pubKey: 'public-key',
              mfaKeysStored: false,
            ),
          );

      var instance = await db.select(db.defguardInstances).getSingle();
      final promoted = await updateInstance(
        db: db,
        instance: instance,
        configs: [_config(legacy: false)],
        info: InstanceInfo.fromJson({
          ...base,
          'mfa_user_state': {'configured_methods': []},
        }),
      );
      expect(promoted?.locationsAdded, 1);
      instance = await db.select(db.defguardInstances).getSingle();
      expect(instance.mfaContract, MfaContract.multiStep);

      final transport = _RejectingFlowTransport();
      final controller = MfaFlowController(
        transport: transport,
        plan: [MfaMethod.totp],
        devicePubkey: 'device-pubkey',
        networkId: 11,
        refreshPlan: () async {
          final result = await updateInstance(
            db: db,
            instance: instance,
            configs: [_config(legacy: true)],
            info: InstanceInfo.fromJson(base),
          );
          if (result == null) return null;
          final refreshed = await db.select(db.defguardInstances).getSingle();
          final refreshedLocation = await db.select(db.locations).getSingle();
          expect(refreshedLocation.networkId, 11);
          expect(
            effectiveMfaSteps(
              refreshedLocation,
            ).single.methods.map((method) => method.method),
            [MfaMethod.biometric, MfaMethod.totp, MfaMethod.email],
          );
          return resolveMfaRetryPlan(
            refreshedLocation,
            attemptContract: instance.mfaContract,
            refreshedContract: refreshed.mfaContract,
            biometricAvailable: true,
          );
        },
      );

      await expectLater(
        controller.startStep(),
        throwsA(isA<MfaStartRejectedException>()),
      );
      final refreshed = await db.select(db.defguardInstances).getSingle();
      expect(refreshed.mfaContract, MfaContract.legacy);
      expect(transport.startCalls, 1);
    },
  );
}
