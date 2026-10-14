import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/enterprise/refresh_instance.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/utils/instance_secrets.dart';

class _StubAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String responseBody = '{}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
  'enterprise_enabled': true,
  'disable_all_traffic': false,
  'client_traffic_policy': 1,
};

void main() {
  late _StubAdapter adapter;
  late ProxyApi api;
  late AppDatabase db;
  late DefguardInstance instance;

  setUp(() async {
    adapter = _StubAdapter();
    final dio = Dio(BaseOptions(responseType: ResponseType.json));
    dio.httpClientAdapter = adapter;
    api = ProxyApi.forTesting(dio);

    FlutterSecureStorage.setMockInitialValues({
      tokenStorageKey('instance-id', 7): 'polling-token',
    });

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
            enterpriseEnabled: true,
            clientTrafficPolicy: const drift.Value(
              ClientTrafficPolicy.disableAllTraffic,
            ),
            pubKey: 'public-key',
            mfaKeysStored: false,
          ),
        );
    instance = await db.select(db.defguardInstances).getSingle();
  });

  test('successful poll refreshes the instance', () async {
    adapter.responseBody = jsonEncode({
      'device_config': {'configs': [], 'instance': _instanceJson},
    });

    final outcome = await refreshInstance(db, instance, api: api);

    expect(outcome, InstanceRefreshOutcome.refreshed);
  });

  test('402 reports a license error and disables enterprise', () async {
    adapter.statusCode = 402;

    final outcome = await refreshInstance(db, instance, api: api);

    expect(outcome, InstanceRefreshOutcome.licenseError);
    final updated = await db.select(db.defguardInstances).getSingle();
    expect(updated.enterpriseEnabled, isFalse);
    expect(updated.clientTrafficPolicy, ClientTrafficPolicy.none);
  });

  test('server error is reported as failed without throwing', () async {
    adapter.statusCode = 500;

    final outcome = await refreshInstance(db, instance, api: api);

    expect(outcome, InstanceRefreshOutcome.failed);
    final unchanged = await db.select(db.defguardInstances).getSingle();
    expect(unchanged.enterpriseEnabled, isTrue);
  });

  test('missing token skips the poll', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final outcome = await refreshInstance(db, instance, api: api);

    expect(outcome, InstanceRefreshOutcome.missingToken);
  });
}
