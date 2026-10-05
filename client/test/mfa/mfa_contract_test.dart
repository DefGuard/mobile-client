import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/config.dart' as proxy_config;
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/utils/update_instance.dart';

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
}
