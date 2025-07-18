import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mobile/data/db/enums.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part 'database.g.dart';

mixin AutoIncrementingPrimaryKey on Table {
  IntColumn get id => integer().autoIncrement()();
}

@DataClassName('DefguardInstance')
class DefguardInstances extends Table with AutoIncrementingPrimaryKey {
  TextColumn get name => text()();

  TextColumn get uuid => text()();

  TextColumn get url => text()();

  @JsonKey('proxy_url')
  TextColumn get proxyUrl => text()();

  TextColumn get username => text()();

  TextColumn get token => text()();

  @JsonKey('disable_all_traffic')
  BoolColumn get disableAllTraffic => boolean()();

  @JsonKey('enterprise_enabled')
  BoolColumn get enterpriseEnabled => boolean()();

  // user public key
  TextColumn get pubKey => text()();

  // user private key
  TextColumn get privateKey => text()();
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

  @JsonKey('mfa_enabled')
  BoolColumn get mfaEnabled => boolean()();

  @JsonKey('traffic_method')
  TextColumn get trafficMethod => textEnum<RoutingMethod>().nullable()();

  @JsonKey('mfa_method')
  IntColumn get mfaMethod =>
      integer().nullable().map(const MfaMethodConverter())();

  @JsonKey('keepalive_interval')
  IntColumn get keepAliveInterval => integer()();

  @JsonKey('location_mfa_mode')
  IntColumn get locationMfaMode =>
      integer().nullable().map(const LocationMfaConverter())();
}

@DriftDatabase(tables: [DefguardInstances, Locations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'defguard',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

extension DefguardInstanceLogName on DefguardInstance {
  String get logName => '$name ($id)';
}

extension LocationLogName on Location {
  String get logName => '$name ($id)';
}
