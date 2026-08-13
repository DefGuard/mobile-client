// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class DefguardInstances extends Table
    with TableInfo<DefguardInstances, DefguardInstancesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DefguardInstances(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> proxyUrl = GeneratedColumn<String>(
    'proxy_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> poolingToken = GeneratedColumn<String>(
    'pooling_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> clientTrafficPolicy = GeneratedColumn<int>(
    'client_traffic_policy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  late final GeneratedColumn<bool> enterpriseEnabled = GeneratedColumn<bool>(
    'enterprise_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enterprise_enabled" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> privateKey = GeneratedColumn<String>(
    'private_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> mfaKeysStored = GeneratedColumn<bool>(
    'mfa_keys_stored',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mfa_keys_stored" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    uuid,
    url,
    deviceId,
    proxyUrl,
    username,
    poolingToken,
    clientTrafficPolicy,
    enterpriseEnabled,
    pubKey,
    privateKey,
    mfaKeysStored,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'defguard_instances';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DefguardInstancesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DefguardInstancesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      proxyUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proxy_url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      poolingToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pooling_token'],
      )!,
      clientTrafficPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_traffic_policy'],
      )!,
      enterpriseEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enterprise_enabled'],
      )!,
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      privateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_key'],
      )!,
      mfaKeysStored: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mfa_keys_stored'],
      )!,
    );
  }

  @override
  DefguardInstances createAlias(String alias) {
    return DefguardInstances(attachedDatabase, alias);
  }
}

class DefguardInstancesData extends DataClass
    implements Insertable<DefguardInstancesData> {
  final int id;
  final String name;
  final String uuid;
  final String url;
  final int deviceId;
  final String proxyUrl;
  final String username;
  final String poolingToken;
  final int clientTrafficPolicy;
  final bool enterpriseEnabled;
  final String pubKey;
  final String privateKey;
  final bool mfaKeysStored;
  const DefguardInstancesData({
    required this.id,
    required this.name,
    required this.uuid,
    required this.url,
    required this.deviceId,
    required this.proxyUrl,
    required this.username,
    required this.poolingToken,
    required this.clientTrafficPolicy,
    required this.enterpriseEnabled,
    required this.pubKey,
    required this.privateKey,
    required this.mfaKeysStored,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['uuid'] = Variable<String>(uuid);
    map['url'] = Variable<String>(url);
    map['device_id'] = Variable<int>(deviceId);
    map['proxy_url'] = Variable<String>(proxyUrl);
    map['username'] = Variable<String>(username);
    map['pooling_token'] = Variable<String>(poolingToken);
    map['client_traffic_policy'] = Variable<int>(clientTrafficPolicy);
    map['enterprise_enabled'] = Variable<bool>(enterpriseEnabled);
    map['pub_key'] = Variable<String>(pubKey);
    map['private_key'] = Variable<String>(privateKey);
    map['mfa_keys_stored'] = Variable<bool>(mfaKeysStored);
    return map;
  }

  DefguardInstancesCompanion toCompanion(bool nullToAbsent) {
    return DefguardInstancesCompanion(
      id: Value(id),
      name: Value(name),
      uuid: Value(uuid),
      url: Value(url),
      deviceId: Value(deviceId),
      proxyUrl: Value(proxyUrl),
      username: Value(username),
      poolingToken: Value(poolingToken),
      clientTrafficPolicy: Value(clientTrafficPolicy),
      enterpriseEnabled: Value(enterpriseEnabled),
      pubKey: Value(pubKey),
      privateKey: Value(privateKey),
      mfaKeysStored: Value(mfaKeysStored),
    );
  }

  factory DefguardInstancesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DefguardInstancesData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      uuid: serializer.fromJson<String>(json['uuid']),
      url: serializer.fromJson<String>(json['url']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      proxyUrl: serializer.fromJson<String>(json['proxyUrl']),
      username: serializer.fromJson<String>(json['username']),
      poolingToken: serializer.fromJson<String>(json['poolingToken']),
      clientTrafficPolicy: serializer.fromJson<int>(
        json['clientTrafficPolicy'],
      ),
      enterpriseEnabled: serializer.fromJson<bool>(json['enterpriseEnabled']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      privateKey: serializer.fromJson<String>(json['privateKey']),
      mfaKeysStored: serializer.fromJson<bool>(json['mfaKeysStored']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'uuid': serializer.toJson<String>(uuid),
      'url': serializer.toJson<String>(url),
      'deviceId': serializer.toJson<int>(deviceId),
      'proxyUrl': serializer.toJson<String>(proxyUrl),
      'username': serializer.toJson<String>(username),
      'poolingToken': serializer.toJson<String>(poolingToken),
      'clientTrafficPolicy': serializer.toJson<int>(clientTrafficPolicy),
      'enterpriseEnabled': serializer.toJson<bool>(enterpriseEnabled),
      'pubKey': serializer.toJson<String>(pubKey),
      'privateKey': serializer.toJson<String>(privateKey),
      'mfaKeysStored': serializer.toJson<bool>(mfaKeysStored),
    };
  }

  DefguardInstancesData copyWith({
    int? id,
    String? name,
    String? uuid,
    String? url,
    int? deviceId,
    String? proxyUrl,
    String? username,
    String? poolingToken,
    int? clientTrafficPolicy,
    bool? enterpriseEnabled,
    String? pubKey,
    String? privateKey,
    bool? mfaKeysStored,
  }) => DefguardInstancesData(
    id: id ?? this.id,
    name: name ?? this.name,
    uuid: uuid ?? this.uuid,
    url: url ?? this.url,
    deviceId: deviceId ?? this.deviceId,
    proxyUrl: proxyUrl ?? this.proxyUrl,
    username: username ?? this.username,
    poolingToken: poolingToken ?? this.poolingToken,
    clientTrafficPolicy: clientTrafficPolicy ?? this.clientTrafficPolicy,
    enterpriseEnabled: enterpriseEnabled ?? this.enterpriseEnabled,
    pubKey: pubKey ?? this.pubKey,
    privateKey: privateKey ?? this.privateKey,
    mfaKeysStored: mfaKeysStored ?? this.mfaKeysStored,
  );
  DefguardInstancesData copyWithCompanion(DefguardInstancesCompanion data) {
    return DefguardInstancesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      url: data.url.present ? data.url.value : this.url,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      proxyUrl: data.proxyUrl.present ? data.proxyUrl.value : this.proxyUrl,
      username: data.username.present ? data.username.value : this.username,
      poolingToken: data.poolingToken.present
          ? data.poolingToken.value
          : this.poolingToken,
      clientTrafficPolicy: data.clientTrafficPolicy.present
          ? data.clientTrafficPolicy.value
          : this.clientTrafficPolicy,
      enterpriseEnabled: data.enterpriseEnabled.present
          ? data.enterpriseEnabled.value
          : this.enterpriseEnabled,
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      privateKey: data.privateKey.present
          ? data.privateKey.value
          : this.privateKey,
      mfaKeysStored: data.mfaKeysStored.present
          ? data.mfaKeysStored.value
          : this.mfaKeysStored,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DefguardInstancesData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('uuid: $uuid, ')
          ..write('url: $url, ')
          ..write('deviceId: $deviceId, ')
          ..write('proxyUrl: $proxyUrl, ')
          ..write('username: $username, ')
          ..write('poolingToken: $poolingToken, ')
          ..write('clientTrafficPolicy: $clientTrafficPolicy, ')
          ..write('enterpriseEnabled: $enterpriseEnabled, ')
          ..write('pubKey: $pubKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('mfaKeysStored: $mfaKeysStored')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    uuid,
    url,
    deviceId,
    proxyUrl,
    username,
    poolingToken,
    clientTrafficPolicy,
    enterpriseEnabled,
    pubKey,
    privateKey,
    mfaKeysStored,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefguardInstancesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.uuid == this.uuid &&
          other.url == this.url &&
          other.deviceId == this.deviceId &&
          other.proxyUrl == this.proxyUrl &&
          other.username == this.username &&
          other.poolingToken == this.poolingToken &&
          other.clientTrafficPolicy == this.clientTrafficPolicy &&
          other.enterpriseEnabled == this.enterpriseEnabled &&
          other.pubKey == this.pubKey &&
          other.privateKey == this.privateKey &&
          other.mfaKeysStored == this.mfaKeysStored);
}

class DefguardInstancesCompanion
    extends UpdateCompanion<DefguardInstancesData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> uuid;
  final Value<String> url;
  final Value<int> deviceId;
  final Value<String> proxyUrl;
  final Value<String> username;
  final Value<String> poolingToken;
  final Value<int> clientTrafficPolicy;
  final Value<bool> enterpriseEnabled;
  final Value<String> pubKey;
  final Value<String> privateKey;
  final Value<bool> mfaKeysStored;
  const DefguardInstancesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.uuid = const Value.absent(),
    this.url = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.proxyUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.poolingToken = const Value.absent(),
    this.clientTrafficPolicy = const Value.absent(),
    this.enterpriseEnabled = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.mfaKeysStored = const Value.absent(),
  });
  DefguardInstancesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String uuid,
    required String url,
    required int deviceId,
    required String proxyUrl,
    required String username,
    required String poolingToken,
    this.clientTrafficPolicy = const Value.absent(),
    required bool enterpriseEnabled,
    required String pubKey,
    required String privateKey,
    required bool mfaKeysStored,
  }) : name = Value(name),
       uuid = Value(uuid),
       url = Value(url),
       deviceId = Value(deviceId),
       proxyUrl = Value(proxyUrl),
       username = Value(username),
       poolingToken = Value(poolingToken),
       enterpriseEnabled = Value(enterpriseEnabled),
       pubKey = Value(pubKey),
       privateKey = Value(privateKey),
       mfaKeysStored = Value(mfaKeysStored);
  static Insertable<DefguardInstancesData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? uuid,
    Expression<String>? url,
    Expression<int>? deviceId,
    Expression<String>? proxyUrl,
    Expression<String>? username,
    Expression<String>? poolingToken,
    Expression<int>? clientTrafficPolicy,
    Expression<bool>? enterpriseEnabled,
    Expression<String>? pubKey,
    Expression<String>? privateKey,
    Expression<bool>? mfaKeysStored,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (uuid != null) 'uuid': uuid,
      if (url != null) 'url': url,
      if (deviceId != null) 'device_id': deviceId,
      if (proxyUrl != null) 'proxy_url': proxyUrl,
      if (username != null) 'username': username,
      if (poolingToken != null) 'pooling_token': poolingToken,
      if (clientTrafficPolicy != null)
        'client_traffic_policy': clientTrafficPolicy,
      if (enterpriseEnabled != null) 'enterprise_enabled': enterpriseEnabled,
      if (pubKey != null) 'pub_key': pubKey,
      if (privateKey != null) 'private_key': privateKey,
      if (mfaKeysStored != null) 'mfa_keys_stored': mfaKeysStored,
    });
  }

  DefguardInstancesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? uuid,
    Value<String>? url,
    Value<int>? deviceId,
    Value<String>? proxyUrl,
    Value<String>? username,
    Value<String>? poolingToken,
    Value<int>? clientTrafficPolicy,
    Value<bool>? enterpriseEnabled,
    Value<String>? pubKey,
    Value<String>? privateKey,
    Value<bool>? mfaKeysStored,
  }) {
    return DefguardInstancesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      uuid: uuid ?? this.uuid,
      url: url ?? this.url,
      deviceId: deviceId ?? this.deviceId,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      username: username ?? this.username,
      poolingToken: poolingToken ?? this.poolingToken,
      clientTrafficPolicy: clientTrafficPolicy ?? this.clientTrafficPolicy,
      enterpriseEnabled: enterpriseEnabled ?? this.enterpriseEnabled,
      pubKey: pubKey ?? this.pubKey,
      privateKey: privateKey ?? this.privateKey,
      mfaKeysStored: mfaKeysStored ?? this.mfaKeysStored,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (proxyUrl.present) {
      map['proxy_url'] = Variable<String>(proxyUrl.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (poolingToken.present) {
      map['pooling_token'] = Variable<String>(poolingToken.value);
    }
    if (clientTrafficPolicy.present) {
      map['client_traffic_policy'] = Variable<int>(clientTrafficPolicy.value);
    }
    if (enterpriseEnabled.present) {
      map['enterprise_enabled'] = Variable<bool>(enterpriseEnabled.value);
    }
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<String>(privateKey.value);
    }
    if (mfaKeysStored.present) {
      map['mfa_keys_stored'] = Variable<bool>(mfaKeysStored.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DefguardInstancesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('uuid: $uuid, ')
          ..write('url: $url, ')
          ..write('deviceId: $deviceId, ')
          ..write('proxyUrl: $proxyUrl, ')
          ..write('username: $username, ')
          ..write('poolingToken: $poolingToken, ')
          ..write('clientTrafficPolicy: $clientTrafficPolicy, ')
          ..write('enterpriseEnabled: $enterpriseEnabled, ')
          ..write('pubKey: $pubKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('mfaKeysStored: $mfaKeysStored')
          ..write(')'))
        .toString();
  }
}

class Locations extends Table with TableInfo<Locations, LocationsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Locations(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<int> instance = GeneratedColumn<int>(
    'instance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES defguard_instances (id) ON DELETE CASCADE',
    ),
  );
  late final GeneratedColumn<int> networkId = GeneratedColumn<int>(
    'network_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> allowedIps = GeneratedColumn<String>(
    'allowed_ips',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> dns = GeneratedColumn<String>(
    'dns',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<bool> mfaEnabled = GeneratedColumn<bool>(
    'mfa_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mfa_enabled" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<String> trafficMethod = GeneratedColumn<String>(
    'traffic_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> mfaMethod = GeneratedColumn<int>(
    'mfa_method',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> keepAliveInterval = GeneratedColumn<int>(
    'keep_alive_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> locationMfaMode = GeneratedColumn<int>(
    'location_mfa_mode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instance,
    networkId,
    name,
    address,
    pubKey,
    endpoint,
    allowedIps,
    dns,
    mfaEnabled,
    trafficMethod,
    mfaMethod,
    keepAliveInterval,
    locationMfaMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instance'],
      )!,
      networkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}network_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      pubKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_key'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      allowedIps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allowed_ips'],
      )!,
      dns: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dns'],
      ),
      mfaEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mfa_enabled'],
      ),
      trafficMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}traffic_method'],
      ),
      mfaMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mfa_method'],
      ),
      keepAliveInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}keep_alive_interval'],
      )!,
      locationMfaMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_mfa_mode'],
      ),
    );
  }

  @override
  Locations createAlias(String alias) {
    return Locations(attachedDatabase, alias);
  }
}

class LocationsData extends DataClass implements Insertable<LocationsData> {
  final int id;
  final int instance;
  final int networkId;
  final String name;
  final String address;
  final String pubKey;
  final String endpoint;
  final String allowedIps;
  final String? dns;
  final bool? mfaEnabled;
  final String? trafficMethod;
  final int? mfaMethod;
  final int keepAliveInterval;
  final int? locationMfaMode;
  const LocationsData({
    required this.id,
    required this.instance,
    required this.networkId,
    required this.name,
    required this.address,
    required this.pubKey,
    required this.endpoint,
    required this.allowedIps,
    this.dns,
    this.mfaEnabled,
    this.trafficMethod,
    this.mfaMethod,
    required this.keepAliveInterval,
    this.locationMfaMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instance'] = Variable<int>(instance);
    map['network_id'] = Variable<int>(networkId);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['pub_key'] = Variable<String>(pubKey);
    map['endpoint'] = Variable<String>(endpoint);
    map['allowed_ips'] = Variable<String>(allowedIps);
    if (!nullToAbsent || dns != null) {
      map['dns'] = Variable<String>(dns);
    }
    if (!nullToAbsent || mfaEnabled != null) {
      map['mfa_enabled'] = Variable<bool>(mfaEnabled);
    }
    if (!nullToAbsent || trafficMethod != null) {
      map['traffic_method'] = Variable<String>(trafficMethod);
    }
    if (!nullToAbsent || mfaMethod != null) {
      map['mfa_method'] = Variable<int>(mfaMethod);
    }
    map['keep_alive_interval'] = Variable<int>(keepAliveInterval);
    if (!nullToAbsent || locationMfaMode != null) {
      map['location_mfa_mode'] = Variable<int>(locationMfaMode);
    }
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      instance: Value(instance),
      networkId: Value(networkId),
      name: Value(name),
      address: Value(address),
      pubKey: Value(pubKey),
      endpoint: Value(endpoint),
      allowedIps: Value(allowedIps),
      dns: dns == null && nullToAbsent ? const Value.absent() : Value(dns),
      mfaEnabled: mfaEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(mfaEnabled),
      trafficMethod: trafficMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(trafficMethod),
      mfaMethod: mfaMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(mfaMethod),
      keepAliveInterval: Value(keepAliveInterval),
      locationMfaMode: locationMfaMode == null && nullToAbsent
          ? const Value.absent()
          : Value(locationMfaMode),
    );
  }

  factory LocationsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationsData(
      id: serializer.fromJson<int>(json['id']),
      instance: serializer.fromJson<int>(json['instance']),
      networkId: serializer.fromJson<int>(json['networkId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      allowedIps: serializer.fromJson<String>(json['allowedIps']),
      dns: serializer.fromJson<String?>(json['dns']),
      mfaEnabled: serializer.fromJson<bool?>(json['mfaEnabled']),
      trafficMethod: serializer.fromJson<String?>(json['trafficMethod']),
      mfaMethod: serializer.fromJson<int?>(json['mfaMethod']),
      keepAliveInterval: serializer.fromJson<int>(json['keepAliveInterval']),
      locationMfaMode: serializer.fromJson<int?>(json['locationMfaMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instance': serializer.toJson<int>(instance),
      'networkId': serializer.toJson<int>(networkId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'pubKey': serializer.toJson<String>(pubKey),
      'endpoint': serializer.toJson<String>(endpoint),
      'allowedIps': serializer.toJson<String>(allowedIps),
      'dns': serializer.toJson<String?>(dns),
      'mfaEnabled': serializer.toJson<bool?>(mfaEnabled),
      'trafficMethod': serializer.toJson<String?>(trafficMethod),
      'mfaMethod': serializer.toJson<int?>(mfaMethod),
      'keepAliveInterval': serializer.toJson<int>(keepAliveInterval),
      'locationMfaMode': serializer.toJson<int?>(locationMfaMode),
    };
  }

  LocationsData copyWith({
    int? id,
    int? instance,
    int? networkId,
    String? name,
    String? address,
    String? pubKey,
    String? endpoint,
    String? allowedIps,
    Value<String?> dns = const Value.absent(),
    Value<bool?> mfaEnabled = const Value.absent(),
    Value<String?> trafficMethod = const Value.absent(),
    Value<int?> mfaMethod = const Value.absent(),
    int? keepAliveInterval,
    Value<int?> locationMfaMode = const Value.absent(),
  }) => LocationsData(
    id: id ?? this.id,
    instance: instance ?? this.instance,
    networkId: networkId ?? this.networkId,
    name: name ?? this.name,
    address: address ?? this.address,
    pubKey: pubKey ?? this.pubKey,
    endpoint: endpoint ?? this.endpoint,
    allowedIps: allowedIps ?? this.allowedIps,
    dns: dns.present ? dns.value : this.dns,
    mfaEnabled: mfaEnabled.present ? mfaEnabled.value : this.mfaEnabled,
    trafficMethod: trafficMethod.present
        ? trafficMethod.value
        : this.trafficMethod,
    mfaMethod: mfaMethod.present ? mfaMethod.value : this.mfaMethod,
    keepAliveInterval: keepAliveInterval ?? this.keepAliveInterval,
    locationMfaMode: locationMfaMode.present
        ? locationMfaMode.value
        : this.locationMfaMode,
  );
  LocationsData copyWithCompanion(LocationsCompanion data) {
    return LocationsData(
      id: data.id.present ? data.id.value : this.id,
      instance: data.instance.present ? data.instance.value : this.instance,
      networkId: data.networkId.present ? data.networkId.value : this.networkId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      allowedIps: data.allowedIps.present
          ? data.allowedIps.value
          : this.allowedIps,
      dns: data.dns.present ? data.dns.value : this.dns,
      mfaEnabled: data.mfaEnabled.present
          ? data.mfaEnabled.value
          : this.mfaEnabled,
      trafficMethod: data.trafficMethod.present
          ? data.trafficMethod.value
          : this.trafficMethod,
      mfaMethod: data.mfaMethod.present ? data.mfaMethod.value : this.mfaMethod,
      keepAliveInterval: data.keepAliveInterval.present
          ? data.keepAliveInterval.value
          : this.keepAliveInterval,
      locationMfaMode: data.locationMfaMode.present
          ? data.locationMfaMode.value
          : this.locationMfaMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationsData(')
          ..write('id: $id, ')
          ..write('instance: $instance, ')
          ..write('networkId: $networkId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('pubKey: $pubKey, ')
          ..write('endpoint: $endpoint, ')
          ..write('allowedIps: $allowedIps, ')
          ..write('dns: $dns, ')
          ..write('mfaEnabled: $mfaEnabled, ')
          ..write('trafficMethod: $trafficMethod, ')
          ..write('mfaMethod: $mfaMethod, ')
          ..write('keepAliveInterval: $keepAliveInterval, ')
          ..write('locationMfaMode: $locationMfaMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instance,
    networkId,
    name,
    address,
    pubKey,
    endpoint,
    allowedIps,
    dns,
    mfaEnabled,
    trafficMethod,
    mfaMethod,
    keepAliveInterval,
    locationMfaMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationsData &&
          other.id == this.id &&
          other.instance == this.instance &&
          other.networkId == this.networkId &&
          other.name == this.name &&
          other.address == this.address &&
          other.pubKey == this.pubKey &&
          other.endpoint == this.endpoint &&
          other.allowedIps == this.allowedIps &&
          other.dns == this.dns &&
          other.mfaEnabled == this.mfaEnabled &&
          other.trafficMethod == this.trafficMethod &&
          other.mfaMethod == this.mfaMethod &&
          other.keepAliveInterval == this.keepAliveInterval &&
          other.locationMfaMode == this.locationMfaMode);
}

class LocationsCompanion extends UpdateCompanion<LocationsData> {
  final Value<int> id;
  final Value<int> instance;
  final Value<int> networkId;
  final Value<String> name;
  final Value<String> address;
  final Value<String> pubKey;
  final Value<String> endpoint;
  final Value<String> allowedIps;
  final Value<String?> dns;
  final Value<bool?> mfaEnabled;
  final Value<String?> trafficMethod;
  final Value<int?> mfaMethod;
  final Value<int> keepAliveInterval;
  final Value<int?> locationMfaMode;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.instance = const Value.absent(),
    this.networkId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.allowedIps = const Value.absent(),
    this.dns = const Value.absent(),
    this.mfaEnabled = const Value.absent(),
    this.trafficMethod = const Value.absent(),
    this.mfaMethod = const Value.absent(),
    this.keepAliveInterval = const Value.absent(),
    this.locationMfaMode = const Value.absent(),
  });
  LocationsCompanion.insert({
    this.id = const Value.absent(),
    required int instance,
    required int networkId,
    required String name,
    required String address,
    required String pubKey,
    required String endpoint,
    required String allowedIps,
    this.dns = const Value.absent(),
    this.mfaEnabled = const Value.absent(),
    this.trafficMethod = const Value.absent(),
    this.mfaMethod = const Value.absent(),
    required int keepAliveInterval,
    this.locationMfaMode = const Value.absent(),
  }) : instance = Value(instance),
       networkId = Value(networkId),
       name = Value(name),
       address = Value(address),
       pubKey = Value(pubKey),
       endpoint = Value(endpoint),
       allowedIps = Value(allowedIps),
       keepAliveInterval = Value(keepAliveInterval);
  static Insertable<LocationsData> custom({
    Expression<int>? id,
    Expression<int>? instance,
    Expression<int>? networkId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? pubKey,
    Expression<String>? endpoint,
    Expression<String>? allowedIps,
    Expression<String>? dns,
    Expression<bool>? mfaEnabled,
    Expression<String>? trafficMethod,
    Expression<int>? mfaMethod,
    Expression<int>? keepAliveInterval,
    Expression<int>? locationMfaMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instance != null) 'instance': instance,
      if (networkId != null) 'network_id': networkId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (pubKey != null) 'pub_key': pubKey,
      if (endpoint != null) 'endpoint': endpoint,
      if (allowedIps != null) 'allowed_ips': allowedIps,
      if (dns != null) 'dns': dns,
      if (mfaEnabled != null) 'mfa_enabled': mfaEnabled,
      if (trafficMethod != null) 'traffic_method': trafficMethod,
      if (mfaMethod != null) 'mfa_method': mfaMethod,
      if (keepAliveInterval != null) 'keep_alive_interval': keepAliveInterval,
      if (locationMfaMode != null) 'location_mfa_mode': locationMfaMode,
    });
  }

  LocationsCompanion copyWith({
    Value<int>? id,
    Value<int>? instance,
    Value<int>? networkId,
    Value<String>? name,
    Value<String>? address,
    Value<String>? pubKey,
    Value<String>? endpoint,
    Value<String>? allowedIps,
    Value<String?>? dns,
    Value<bool?>? mfaEnabled,
    Value<String?>? trafficMethod,
    Value<int?>? mfaMethod,
    Value<int>? keepAliveInterval,
    Value<int?>? locationMfaMode,
  }) {
    return LocationsCompanion(
      id: id ?? this.id,
      instance: instance ?? this.instance,
      networkId: networkId ?? this.networkId,
      name: name ?? this.name,
      address: address ?? this.address,
      pubKey: pubKey ?? this.pubKey,
      endpoint: endpoint ?? this.endpoint,
      allowedIps: allowedIps ?? this.allowedIps,
      dns: dns ?? this.dns,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      trafficMethod: trafficMethod ?? this.trafficMethod,
      mfaMethod: mfaMethod ?? this.mfaMethod,
      keepAliveInterval: keepAliveInterval ?? this.keepAliveInterval,
      locationMfaMode: locationMfaMode ?? this.locationMfaMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instance.present) {
      map['instance'] = Variable<int>(instance.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<int>(networkId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (allowedIps.present) {
      map['allowed_ips'] = Variable<String>(allowedIps.value);
    }
    if (dns.present) {
      map['dns'] = Variable<String>(dns.value);
    }
    if (mfaEnabled.present) {
      map['mfa_enabled'] = Variable<bool>(mfaEnabled.value);
    }
    if (trafficMethod.present) {
      map['traffic_method'] = Variable<String>(trafficMethod.value);
    }
    if (mfaMethod.present) {
      map['mfa_method'] = Variable<int>(mfaMethod.value);
    }
    if (keepAliveInterval.present) {
      map['keep_alive_interval'] = Variable<int>(keepAliveInterval.value);
    }
    if (locationMfaMode.present) {
      map['location_mfa_mode'] = Variable<int>(locationMfaMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('instance: $instance, ')
          ..write('networkId: $networkId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('pubKey: $pubKey, ')
          ..write('endpoint: $endpoint, ')
          ..write('allowedIps: $allowedIps, ')
          ..write('dns: $dns, ')
          ..write('mfaEnabled: $mfaEnabled, ')
          ..write('trafficMethod: $trafficMethod, ')
          ..write('mfaMethod: $mfaMethod, ')
          ..write('keepAliveInterval: $keepAliveInterval, ')
          ..write('locationMfaMode: $locationMfaMode')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV2 extends GeneratedDatabase {
  DatabaseAtV2(QueryExecutor e) : super(e);
  late final DefguardInstances defguardInstances = DefguardInstances(this);
  late final Locations locations = Locations(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    defguardInstances,
    locations,
  ];
  @override
  int get schemaVersion => 2;
}
