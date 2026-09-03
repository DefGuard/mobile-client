import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:mobile/data/db/database.steps.dart";
import "package:mobile/data/db/db_file.dart";
import "package:mobile/data/db/enums.dart";
import "package:mobile/utils/instance_secrets.dart";
import "package:mobile/utils/keychain.dart";
import "package:path_provider/path_provider.dart";

export 'database_provider.dart';

part 'database.g.dart';

mixin AutoIncrementingPrimaryKey on Table {
  IntColumn get id => integer().autoIncrement()();
}

@DataClassName('DefguardInstance')
class DefguardInstances extends Table with AutoIncrementingPrimaryKey {
  TextColumn get name => text()();

  TextColumn get uuid => text()();

  TextColumn get url => text()();

  IntColumn get deviceId => integer()();

  @JsonKey('proxy_url')
  TextColumn get proxyUrl => text()();

  TextColumn get username => text()();

  @JsonKey('client_traffic_policy')
  IntColumn get clientTrafficPolicy => integer()
      .withDefault(const Constant(0))
      .map(const ClientTrafficPolicyConverter())();

  @JsonKey('enterprise_enabled')
  BoolColumn get enterpriseEnabled => boolean()();

  // user public key
  TextColumn get pubKey => text()();

  // tells if the secure biometric storage exists for this instance
  BoolColumn get mfaKeysStored => boolean()();

  // openid provider display name configured on the server side
  TextColumn get openidDisplayName => text().nullable()();
}

@DataClassName('Location')
class Locations extends Table with AutoIncrementingPrimaryKey {
  @JsonKey('instance_id')
  IntColumn get instance => integer().references(
    DefguardInstances,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @JsonKey('network_id')
  IntColumn get networkId => integer()();

  TextColumn get name => text()();

  TextColumn get address => text()();

  @JsonKey('pubkey')
  TextColumn get pubKey => text()();

  TextColumn get endpoint => text()();

  @JsonKey('allowed_ips')
  TextColumn get allowedIps => text()();

  TextColumn get dns => text().nullable()();

  // deprecated, use locationMfaMode instead
  @Deprecated('1.5')
  @JsonKey('mfa_enabled')
  BoolColumn get mfaEnabled => boolean().nullable()();

  @JsonKey('traffic_method')
  TextColumn get trafficMethod => textEnum<RoutingMethod>().nullable()();

  @JsonKey('mfa_method')
  IntColumn get mfaMethod =>
      integer().nullable().map(const MfaMethodConverter())();

  @JsonKey('keepalive_interval')
  IntColumn get keepAliveInterval => integer()();

  @JsonKey('location_mfa_mode')
  IntColumn get locationMfaMode =>
      integer().nullable().map(const LocationMfaModeConverter())();
  @JsonKey('posture_check_required')
  BoolColumn get postureCheckRequired => boolean().nullable()();
}

@DriftDatabase(tables: [DefguardInstances, Locations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  Future<bool> get isSingleInstance async {
    final count =
        await (selectOnly(defguardInstances)
              ..addColumns([defguardInstances.id.count()]))
            .map((row) => row.read(defguardInstances.id.count()))
            .getSingle();
    return count == 1;
  }

  Stream<bool> watchIsSingleInstance() {
    return (selectOnly(defguardInstances)
          ..addColumns([defguardInstances.id.count()]))
        .map((row) => row.read(defguardInstances.id.count()))
        .watchSingle()
        .map((count) => count == 1);
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Overwrite deleted content instead of leaving it in freed pages.
        await customStatement('PRAGMA secure_delete = ON');
        if (details.hadUpgrade && details.versionBefore! < 5) {
          // Rebuild the database file so the pages that held the secrets moved
          // to the keychain in the 4 -> 5 migration are gone for good. Cannot
          // run inside the migration itself, VACUUM is not allowed in a
          // transaction.
          await customStatement('VACUUM');
        }
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          // 1. Add the new column manually.
          // This ensures Drift doesn't trigger a "Recreate Table" that might
          // drop 'disable_all_traffic' before we are done with it.
          await customStatement(
            'ALTER TABLE defguard_instances ADD COLUMN client_traffic_policy INTEGER NOT NULL DEFAULT 0',
          );
          // 2. Update values derived from the old column
          await customStatement('''
            UPDATE defguard_instances
            SET client_traffic_policy =
              CASE WHEN disable_all_traffic = 1 THEN 1 ELSE 0 END;
          ''');
          // 3. Drop old "disable_all_traffic" column
          await m.dropColumn(defguardInstances, "disable_all_traffic");
        },
        from2To3: (m, schema) async {
          await m.addColumn(
            schema.defguardInstances,
            schema.defguardInstances.openidDisplayName,
          );
        },
        from3To4: (m, schema) async {
          await m.addColumn(
            schema.locations,
            schema.locations.postureCheckRequired,
          );
        },
        from4To5: (m, schema) async {
          // Move the WireGuard private keys and the proxy tokens out of the
          // database and into the platform keychain. Any failure here aborts
          // the migration so it is retried on the next launch with the columns
          // still in place.
          await customStatement('PRAGMA secure_delete = ON');
          final instances = await customSelect(
            'SELECT uuid, device_id, private_key, pooling_token '
            'FROM defguard_instances',
          ).get();
          for (final instance in instances) {
            await storeInstanceSecrets(
              uuid: instance.read<String>('uuid'),
              deviceId: instance.read<int>('device_id'),
              privateKey: instance.read<String>('private_key'),
              poolingToken: instance.read<String>('pooling_token'),
            );
          }
          await m.dropColumn(schema.defguardInstances, 'private_key');
          await m.dropColumn(schema.defguardInstances, 'pooling_token');
        },
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: databaseName,
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

// database provider moved to database_provider.dart

extension DefguardInstanceLogName on DefguardInstance {
  String get logName => '$name ($id)';
}

extension DefguardInstanceStorageKey on DefguardInstance {
  String get secureStorageKey => mfaStorageKey(uuid, deviceId);
}

/// Secrets of an instance are kept in the platform keychain, not in the
/// database. They can be absent (see [reportMissingSecret]), callers have to
/// handle a `null`.
extension DefguardInstanceSecrets on DefguardInstance {
  Future<String?> wireguardPrivateKey() =>
      secureStorage.read(key: wireguardKeyStorageKey(uuid, deviceId));

  Future<String?> poolingToken() =>
      secureStorage.read(key: tokenStorageKey(uuid, deviceId));

  Future<void> storeToken(String token) =>
      secureStorage.write(key: tokenStorageKey(uuid, deviceId), value: token);

  Future<void> removeSecrets() =>
      removeInstanceSecrets(uuid: uuid, deviceId: deviceId);
}

extension LocationLogName on Location {
  String get logName => '$name ($id)';
}
