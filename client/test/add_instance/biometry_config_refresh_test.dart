import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/data/proxy/enrollment.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/add_instance/screens/biometry/biometry_setup_screen.dart';

class _StubAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String responseBody = '{}';
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _instanceJson = <String, dynamic>{
  'id': 'instance-id',
  'name': 'instance',
  'url': 'https://defguard.example',
  'proxy_url': 'https://proxy.defguard.example',
  'username': 'user',
  'enterprise_enabled': false,
  'disable_all_traffic': false,
};

DeviceConfig _config({required bool biometricConfigured}) => DeviceConfig(
  networkId: 11,
  networkName: 'Warsaw',
  config: '',
  endpoint: 'vpn.example:51820',
  assignedIp: '10.0.0.2/24',
  pubkey: 'location-pubkey',
  allowedIps: '10.0.0.0/24',
  mfaEnabled: true,
  keepaliveInterval: 25,
  steps: [
    MfaStep([
      MfaStepMethod.supported(
        MfaMethod.biometric,
        configured: biometricConfigured,
      ),
      MfaStepMethod.supported(MfaMethod.totp),
    ]),
  ],
);

void main() {
  late _StubAdapter adapter;
  late ProxyApi api;
  late AppDatabase db;
  late DefguardInstance instance;

  Future<bool> storedBiometricFlag() async {
    final location = await db.select(db.locations).getSingle();
    return location.mfaSteps.single.methods
        .firstWhere((entry) => entry.method == MfaMethod.biometric)
        .configured;
  }

  setUp(() async {
    adapter = _StubAdapter();
    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = adapter;
    api = ProxyApi.forTesting(dio);

    FlutterSecureStorage.setMockInitialValues({});

    db = AppDatabase(NativeDatabase.memory());
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
            mfaKeysStored: true,
          ),
        );
    instance = await db.select(db.defguardInstances).getSingle();
    await db
        .into(db.locations)
        .insert(
          _config(
            biometricConfigured: false,
          ).toCompanion(instanceId: instance.id),
        );
  });

  test('reads the config again and stores what Core now reports', () async {
    adapter.responseBody = jsonEncode({
      'device': {
        'id': 7,
        'name': 'phone',
        'pubkey': 'public-key',
        'user_id': 1,
        'created_at': 0,
      },
      'configs': [_config(biometricConfigured: true)],
      'instance': _instanceJson,
      'token': 'rotated-token',
    });
    expect(await storedBiometricFlag(), isFalse);

    await refreshConfigAfterBiometry(db, instance, api: api);

    expect(adapter.paths.single, endsWith('/enrollment/network_info'));
    expect(await storedBiometricFlag(), isTrue);
    expect(await instance.pollingToken(), 'rotated-token');
    final stored = await db.select(db.defguardInstances).getSingle();
    expect(stored.mfaKeysStored, isTrue);
  });

  test('a failed refresh does not throw and keeps stored data', () async {
    adapter.statusCode = 500;

    await refreshConfigAfterBiometry(db, instance, api: api);

    expect(await storedBiometricFlag(), isFalse);
    expect(await instance.pollingToken(), isNull);
  });
}
