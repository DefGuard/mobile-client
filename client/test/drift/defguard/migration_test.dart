// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldDefguardInstancesData = <v1.DefguardInstancesData>[];
    final expectedNewDefguardInstancesData = <v2.DefguardInstancesData>[];

    final oldLocationsData = <v1.LocationsData>[];
    final expectedNewLocationsData = <v2.LocationsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.defguardInstances, oldDefguardInstancesData);
        batch.insertAll(oldDb.locations, oldLocationsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewDefguardInstancesData,
          await newDb.select(newDb.defguardInstances).get(),
        );
        expect(
          expectedNewLocationsData,
          await newDb.select(newDb.locations).get(),
        );
      },
    );
  });

  test(
    'migration from v4 to v5 moves the secrets to the secure storage',
    () async {
      final storedSecrets = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(storedSecrets);

      final oldDefguardInstancesData = <v4.DefguardInstancesData>[
        const v4.DefguardInstancesData(
          id: 1,
          name: 'instance',
          uuid: 'instance-uuid',
          url: 'https://defguard.example',
          deviceId: 7,
          proxyUrl: 'https://proxy.defguard.example',
          username: 'user',
          poolingToken: 'polling-token',
          clientTrafficPolicy: 0,
          enterpriseEnabled: true,
          pubKey: 'public-key',
          privateKey: 'private-key',
          mfaKeysStored: false,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 4,
        newVersion: 5,
        createOld: v4.DatabaseAtV4.new,
        createNew: v5.DatabaseAtV5.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.defguardInstances, oldDefguardInstancesData);
        },
        validateItems: (newDb) async {
          // the instance is kept, only its secrets moved
          final instance = await newDb
              .select(newDb.defguardInstances)
              .getSingle();
          expect(instance.uuid, 'instance-uuid');
          expect(instance.deviceId, 7);
          expect(instance.pubKey, 'public-key');

          expect(storedSecrets, {
            'wg-key-instance-uuid-7': 'private-key',
            'token-instance-uuid-7': 'polling-token',
          });
        },
      );
    },
  );

  test(
    'migration from v5 to v6 keeps MFA locations gated and seeds the plan',
    () async {
      final oldLocations = <v5.LocationsData>[
        const v5.LocationsData(
          id: 1,
          instance: 1,
          networkId: 11,
          name: 'internal-with-remembered-method',
          address: '10.0.0.1/24',
          pubKey: 'pubkey-1',
          endpoint: 'vpn.example:51820',
          allowedIps: '0.0.0.0/0',
          keepAliveInterval: 25,
          locationMfaMode: 2,
          mfaMethod: 1,
        ),
        const v5.LocationsData(
          id: 2,
          instance: 1,
          networkId: 12,
          name: 'legacy-mfa-enabled',
          address: '10.0.0.2/24',
          pubKey: 'pubkey-2',
          endpoint: 'vpn.example:51820',
          allowedIps: '0.0.0.0/0',
          keepAliveInterval: 25,
          mfaEnabled: 1,
        ),
        const v5.LocationsData(
          id: 3,
          instance: 1,
          networkId: 13,
          name: 'no-mfa',
          address: '10.0.0.3/24',
          pubKey: 'pubkey-3',
          endpoint: 'vpn.example:51820',
          allowedIps: '0.0.0.0/0',
          keepAliveInterval: 25,
          locationMfaMode: 1,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 5,
        newVersion: 6,
        createOld: v5.DatabaseAtV5.new,
        createNew: v6.DatabaseAtV6.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.defguardInstances, <v5.DefguardInstancesData>[
            const v5.DefguardInstancesData(
              id: 1,
              name: 'instance',
              uuid: 'instance-uuid',
              url: 'https://defguard.example',
              deviceId: 7,
              proxyUrl: 'https://proxy.defguard.example',
              username: 'user',
              clientTrafficPolicy: 0,
              enterpriseEnabled: 1,
              pubKey: 'public-key',
              mfaKeysStored: 0,
            ),
          ]);
          batch.insertAll(oldDb.locations, oldLocations);
        },
        validateItems: (newDb) async {
          final rows = await (newDb.select(
            newDb.locations,
          )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
          expect(rows.map((r) => r.name), [
            'internal-with-remembered-method',
            'legacy-mfa-enabled',
            'no-mfa',
          ]);

          // The remembered single method becomes the step 0 default.
          expect(rows[0].mfaStepPlan, '[1]');
          expect(rows[1].mfaStepPlan, '[]');
          expect(rows[2].mfaStepPlan, '[]');
          expect(rows.map((r) => r.mfaSteps), everyElement('[]'));
        },
      );
    },
  );

  test('a migrated row still requires MFA before any config sync', () async {
    final schema = await verifier.schemaAt(5);
    final oldDb = v5.DatabaseAtV5(schema.newConnection());
    await oldDb.batch((batch) {
      batch.insertAll(oldDb.defguardInstances, <v5.DefguardInstancesData>[
        const v5.DefguardInstancesData(
          id: 1,
          name: 'instance',
          uuid: 'instance-uuid',
          url: 'https://defguard.example',
          deviceId: 7,
          proxyUrl: 'https://proxy.defguard.example',
          username: 'user',
          clientTrafficPolicy: 0,
          enterpriseEnabled: 1,
          pubKey: 'public-key',
          mfaKeysStored: 0,
        ),
      ]);
      batch.insertAll(oldDb.locations, <v5.LocationsData>[
        const v5.LocationsData(
          id: 1,
          instance: 1,
          networkId: 11,
          name: 'internal',
          address: '10.0.0.1/24',
          pubKey: 'pubkey-1',
          endpoint: 'vpn.example:51820',
          allowedIps: '0.0.0.0/0',
          keepAliveInterval: 25,
          locationMfaMode: 2,
          mfaMethod: 1,
        ),
        const v5.LocationsData(
          id: 2,
          instance: 1,
          networkId: 12,
          name: 'disabled',
          address: '10.0.0.2/24',
          pubKey: 'pubkey-2',
          endpoint: 'vpn.example:51820',
          allowedIps: '0.0.0.0/0',
          keepAliveInterval: 25,
          locationMfaMode: 1,
        ),
      ]);
    });
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    final locations = await (db.select(
      db.locations,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

    expect(locations[0].mfaSteps, isEmpty);
    expect(shouldStartMfa(locations[0]), isTrue);
    expect(locations[0].mfaStepPlan, [MfaMethod.email]);
    expect(shouldStartMfa(locations[1]), isFalse);
    await db.close();
  });
}
