// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DefguardInstancesTable extends DefguardInstances
    with TableInfo<$DefguardInstancesTable, DefguardInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DefguardInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proxyUrlMeta = const VerificationMeta(
    'proxyUrl',
  );
  @override
  late final GeneratedColumn<String> proxyUrl = GeneratedColumn<String>(
    'proxy_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disableAllTrafficMeta = const VerificationMeta(
    'disableAllTraffic',
  );
  @override
  late final GeneratedColumn<bool> disableAllTraffic = GeneratedColumn<bool>(
    'disable_all_traffic',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disable_all_traffic" IN (0, 1))',
    ),
  );
  static const VerificationMeta _enterpriseEnabledMeta = const VerificationMeta(
    'enterpriseEnabled',
  );
  @override
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
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privateKeyMeta = const VerificationMeta(
    'privateKey',
  );
  @override
  late final GeneratedColumn<String> privateKey = GeneratedColumn<String>(
    'private_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useOpenidForMfaMeta = const VerificationMeta(
    'useOpenidForMfa',
  );
  @override
  late final GeneratedColumn<bool> useOpenidForMfa = GeneratedColumn<bool>(
    'use_openid_for_mfa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_openid_for_mfa" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    uuid,
    url,
    proxyUrl,
    username,
    token,
    disableAllTraffic,
    enterpriseEnabled,
    pubKey,
    privateKey,
    useOpenidForMfa,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'defguard_instances';
  @override
  VerificationContext validateIntegrity(
    Insertable<DefguardInstance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('proxy_url')) {
      context.handle(
        _proxyUrlMeta,
        proxyUrl.isAcceptableOrUnknown(data['proxy_url']!, _proxyUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_proxyUrlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('disable_all_traffic')) {
      context.handle(
        _disableAllTrafficMeta,
        disableAllTraffic.isAcceptableOrUnknown(
          data['disable_all_traffic']!,
          _disableAllTrafficMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disableAllTrafficMeta);
    }
    if (data.containsKey('enterprise_enabled')) {
      context.handle(
        _enterpriseEnabledMeta,
        enterpriseEnabled.isAcceptableOrUnknown(
          data['enterprise_enabled']!,
          _enterpriseEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enterpriseEnabledMeta);
    }
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('private_key')) {
      context.handle(
        _privateKeyMeta,
        privateKey.isAcceptableOrUnknown(data['private_key']!, _privateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_privateKeyMeta);
    }
    if (data.containsKey('use_openid_for_mfa')) {
      context.handle(
        _useOpenidForMfaMeta,
        useOpenidForMfa.isAcceptableOrUnknown(
          data['use_openid_for_mfa']!,
          _useOpenidForMfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_useOpenidForMfaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DefguardInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DefguardInstance(
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
      proxyUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proxy_url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      disableAllTraffic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disable_all_traffic'],
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
      useOpenidForMfa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_openid_for_mfa'],
      )!,
    );
  }

  @override
  $DefguardInstancesTable createAlias(String alias) {
    return $DefguardInstancesTable(attachedDatabase, alias);
  }
}

class DefguardInstance extends DataClass
    implements Insertable<DefguardInstance> {
  final int id;
  final String name;
  final String uuid;
  final String url;
  final String proxyUrl;
  final String username;
  final String token;
  final bool disableAllTraffic;
  final bool enterpriseEnabled;
  final String pubKey;
  final String privateKey;
  final bool useOpenidForMfa;
  const DefguardInstance({
    required this.id,
    required this.name,
    required this.uuid,
    required this.url,
    required this.proxyUrl,
    required this.username,
    required this.token,
    required this.disableAllTraffic,
    required this.enterpriseEnabled,
    required this.pubKey,
    required this.privateKey,
    required this.useOpenidForMfa,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['uuid'] = Variable<String>(uuid);
    map['url'] = Variable<String>(url);
    map['proxy_url'] = Variable<String>(proxyUrl);
    map['username'] = Variable<String>(username);
    map['token'] = Variable<String>(token);
    map['disable_all_traffic'] = Variable<bool>(disableAllTraffic);
    map['enterprise_enabled'] = Variable<bool>(enterpriseEnabled);
    map['pub_key'] = Variable<String>(pubKey);
    map['private_key'] = Variable<String>(privateKey);
    map['use_openid_for_mfa'] = Variable<bool>(useOpenidForMfa);
    return map;
  }

  DefguardInstancesCompanion toCompanion(bool nullToAbsent) {
    return DefguardInstancesCompanion(
      id: Value(id),
      name: Value(name),
      uuid: Value(uuid),
      url: Value(url),
      proxyUrl: Value(proxyUrl),
      username: Value(username),
      token: Value(token),
      disableAllTraffic: Value(disableAllTraffic),
      enterpriseEnabled: Value(enterpriseEnabled),
      pubKey: Value(pubKey),
      privateKey: Value(privateKey),
      useOpenidForMfa: Value(useOpenidForMfa),
    );
  }

  factory DefguardInstance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DefguardInstance(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      uuid: serializer.fromJson<String>(json['uuid']),
      url: serializer.fromJson<String>(json['url']),
      proxyUrl: serializer.fromJson<String>(json['proxy_url']),
      username: serializer.fromJson<String>(json['username']),
      token: serializer.fromJson<String>(json['token']),
      disableAllTraffic: serializer.fromJson<bool>(json['disable_all_traffic']),
      enterpriseEnabled: serializer.fromJson<bool>(json['enterprise_enabled']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      privateKey: serializer.fromJson<String>(json['privateKey']),
      useOpenidForMfa: serializer.fromJson<bool>(json['useOpenidForMfa']),
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
      'proxy_url': serializer.toJson<String>(proxyUrl),
      'username': serializer.toJson<String>(username),
      'token': serializer.toJson<String>(token),
      'disable_all_traffic': serializer.toJson<bool>(disableAllTraffic),
      'enterprise_enabled': serializer.toJson<bool>(enterpriseEnabled),
      'pubKey': serializer.toJson<String>(pubKey),
      'privateKey': serializer.toJson<String>(privateKey),
      'useOpenidForMfa': serializer.toJson<bool>(useOpenidForMfa),
    };
  }

  DefguardInstance copyWith({
    int? id,
    String? name,
    String? uuid,
    String? url,
    String? proxyUrl,
    String? username,
    String? token,
    bool? disableAllTraffic,
    bool? enterpriseEnabled,
    String? pubKey,
    String? privateKey,
    bool? useOpenidForMfa,
  }) => DefguardInstance(
    id: id ?? this.id,
    name: name ?? this.name,
    uuid: uuid ?? this.uuid,
    url: url ?? this.url,
    proxyUrl: proxyUrl ?? this.proxyUrl,
    username: username ?? this.username,
    token: token ?? this.token,
    disableAllTraffic: disableAllTraffic ?? this.disableAllTraffic,
    enterpriseEnabled: enterpriseEnabled ?? this.enterpriseEnabled,
    pubKey: pubKey ?? this.pubKey,
    privateKey: privateKey ?? this.privateKey,
    useOpenidForMfa: useOpenidForMfa ?? this.useOpenidForMfa,
  );
  DefguardInstance copyWithCompanion(DefguardInstancesCompanion data) {
    return DefguardInstance(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      url: data.url.present ? data.url.value : this.url,
      proxyUrl: data.proxyUrl.present ? data.proxyUrl.value : this.proxyUrl,
      username: data.username.present ? data.username.value : this.username,
      token: data.token.present ? data.token.value : this.token,
      disableAllTraffic: data.disableAllTraffic.present
          ? data.disableAllTraffic.value
          : this.disableAllTraffic,
      enterpriseEnabled: data.enterpriseEnabled.present
          ? data.enterpriseEnabled.value
          : this.enterpriseEnabled,
      pubKey: data.pubKey.present ? data.pubKey.value : this.pubKey,
      privateKey: data.privateKey.present
          ? data.privateKey.value
          : this.privateKey,
      useOpenidForMfa: data.useOpenidForMfa.present
          ? data.useOpenidForMfa.value
          : this.useOpenidForMfa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DefguardInstance(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('uuid: $uuid, ')
          ..write('url: $url, ')
          ..write('proxyUrl: $proxyUrl, ')
          ..write('username: $username, ')
          ..write('token: $token, ')
          ..write('disableAllTraffic: $disableAllTraffic, ')
          ..write('enterpriseEnabled: $enterpriseEnabled, ')
          ..write('pubKey: $pubKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('useOpenidForMfa: $useOpenidForMfa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    uuid,
    url,
    proxyUrl,
    username,
    token,
    disableAllTraffic,
    enterpriseEnabled,
    pubKey,
    privateKey,
    useOpenidForMfa,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefguardInstance &&
          other.id == this.id &&
          other.name == this.name &&
          other.uuid == this.uuid &&
          other.url == this.url &&
          other.proxyUrl == this.proxyUrl &&
          other.username == this.username &&
          other.token == this.token &&
          other.disableAllTraffic == this.disableAllTraffic &&
          other.enterpriseEnabled == this.enterpriseEnabled &&
          other.pubKey == this.pubKey &&
          other.privateKey == this.privateKey &&
          other.useOpenidForMfa == this.useOpenidForMfa);
}

class DefguardInstancesCompanion extends UpdateCompanion<DefguardInstance> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> uuid;
  final Value<String> url;
  final Value<String> proxyUrl;
  final Value<String> username;
  final Value<String> token;
  final Value<bool> disableAllTraffic;
  final Value<bool> enterpriseEnabled;
  final Value<String> pubKey;
  final Value<String> privateKey;
  final Value<bool> useOpenidForMfa;
  const DefguardInstancesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.uuid = const Value.absent(),
    this.url = const Value.absent(),
    this.proxyUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.token = const Value.absent(),
    this.disableAllTraffic = const Value.absent(),
    this.enterpriseEnabled = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.useOpenidForMfa = const Value.absent(),
  });
  DefguardInstancesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String uuid,
    required String url,
    required String proxyUrl,
    required String username,
    required String token,
    required bool disableAllTraffic,
    required bool enterpriseEnabled,
    required String pubKey,
    required String privateKey,
    required bool useOpenidForMfa,
  }) : name = Value(name),
       uuid = Value(uuid),
       url = Value(url),
       proxyUrl = Value(proxyUrl),
       username = Value(username),
       token = Value(token),
       disableAllTraffic = Value(disableAllTraffic),
       enterpriseEnabled = Value(enterpriseEnabled),
       pubKey = Value(pubKey),
       privateKey = Value(privateKey),
       useOpenidForMfa = Value(useOpenidForMfa);
  static Insertable<DefguardInstance> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? uuid,
    Expression<String>? url,
    Expression<String>? proxyUrl,
    Expression<String>? username,
    Expression<String>? token,
    Expression<bool>? disableAllTraffic,
    Expression<bool>? enterpriseEnabled,
    Expression<String>? pubKey,
    Expression<String>? privateKey,
    Expression<bool>? useOpenidForMfa,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (uuid != null) 'uuid': uuid,
      if (url != null) 'url': url,
      if (proxyUrl != null) 'proxy_url': proxyUrl,
      if (username != null) 'username': username,
      if (token != null) 'token': token,
      if (disableAllTraffic != null) 'disable_all_traffic': disableAllTraffic,
      if (enterpriseEnabled != null) 'enterprise_enabled': enterpriseEnabled,
      if (pubKey != null) 'pub_key': pubKey,
      if (privateKey != null) 'private_key': privateKey,
      if (useOpenidForMfa != null) 'use_openid_for_mfa': useOpenidForMfa,
    });
  }

  DefguardInstancesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? uuid,
    Value<String>? url,
    Value<String>? proxyUrl,
    Value<String>? username,
    Value<String>? token,
    Value<bool>? disableAllTraffic,
    Value<bool>? enterpriseEnabled,
    Value<String>? pubKey,
    Value<String>? privateKey,
    Value<bool>? useOpenidForMfa,
  }) {
    return DefguardInstancesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      uuid: uuid ?? this.uuid,
      url: url ?? this.url,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      username: username ?? this.username,
      token: token ?? this.token,
      disableAllTraffic: disableAllTraffic ?? this.disableAllTraffic,
      enterpriseEnabled: enterpriseEnabled ?? this.enterpriseEnabled,
      pubKey: pubKey ?? this.pubKey,
      privateKey: privateKey ?? this.privateKey,
      useOpenidForMfa: useOpenidForMfa ?? this.useOpenidForMfa,
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
    if (proxyUrl.present) {
      map['proxy_url'] = Variable<String>(proxyUrl.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (disableAllTraffic.present) {
      map['disable_all_traffic'] = Variable<bool>(disableAllTraffic.value);
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
    if (useOpenidForMfa.present) {
      map['use_openid_for_mfa'] = Variable<bool>(useOpenidForMfa.value);
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
          ..write('proxyUrl: $proxyUrl, ')
          ..write('username: $username, ')
          ..write('token: $token, ')
          ..write('disableAllTraffic: $disableAllTraffic, ')
          ..write('enterpriseEnabled: $enterpriseEnabled, ')
          ..write('pubKey: $pubKey, ')
          ..write('privateKey: $privateKey, ')
          ..write('useOpenidForMfa: $useOpenidForMfa')
          ..write(')'))
        .toString();
  }
}

class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, Location> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
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
  static const VerificationMeta _instanceMeta = const VerificationMeta(
    'instance',
  );
  @override
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
  static const VerificationMeta _networkIdMeta = const VerificationMeta(
    'networkId',
  );
  @override
  late final GeneratedColumn<int> networkId = GeneratedColumn<int>(
    'network_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
    'pub_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowedIpsMeta = const VerificationMeta(
    'allowedIps',
  );
  @override
  late final GeneratedColumn<String> allowedIps = GeneratedColumn<String>(
    'allowed_ips',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dnsMeta = const VerificationMeta('dns');
  @override
  late final GeneratedColumn<String> dns = GeneratedColumn<String>(
    'dns',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mfaEnabledMeta = const VerificationMeta(
    'mfaEnabled',
  );
  @override
  late final GeneratedColumn<bool> mfaEnabled = GeneratedColumn<bool>(
    'mfa_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mfa_enabled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RoutingMethod?, String>
  trafficMethod = GeneratedColumn<String>(
    'traffic_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RoutingMethod?>($LocationsTable.$convertertrafficMethodn);
  @override
  late final GeneratedColumnWithTypeConverter<MfaMethod?, int> mfaMethod =
      GeneratedColumn<int>(
        'mfa_method',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<MfaMethod?>($LocationsTable.$convertermfaMethodn);
  static const VerificationMeta _keepAliveIntervalMeta = const VerificationMeta(
    'keepAliveInterval',
  );
  @override
  late final GeneratedColumn<int> keepAliveInterval = GeneratedColumn<int>(
    'keep_alive_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Location> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instance')) {
      context.handle(
        _instanceMeta,
        this.instance.isAcceptableOrUnknown(data['instance']!, _instanceMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceMeta);
    }
    if (data.containsKey('network_id')) {
      context.handle(
        _networkIdMeta,
        networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('pub_key')) {
      context.handle(
        _pubKeyMeta,
        pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('allowed_ips')) {
      context.handle(
        _allowedIpsMeta,
        allowedIps.isAcceptableOrUnknown(data['allowed_ips']!, _allowedIpsMeta),
      );
    } else if (isInserting) {
      context.missing(_allowedIpsMeta);
    }
    if (data.containsKey('dns')) {
      context.handle(
        _dnsMeta,
        dns.isAcceptableOrUnknown(data['dns']!, _dnsMeta),
      );
    }
    if (data.containsKey('mfa_enabled')) {
      context.handle(
        _mfaEnabledMeta,
        mfaEnabled.isAcceptableOrUnknown(data['mfa_enabled']!, _mfaEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_mfaEnabledMeta);
    }
    if (data.containsKey('keep_alive_interval')) {
      context.handle(
        _keepAliveIntervalMeta,
        keepAliveInterval.isAcceptableOrUnknown(
          data['keep_alive_interval']!,
          _keepAliveIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keepAliveIntervalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Location map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Location(
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
      )!,
      trafficMethod: $LocationsTable.$convertertrafficMethodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}traffic_method'],
        ),
      ),
      mfaMethod: $LocationsTable.$convertermfaMethodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}mfa_method'],
        ),
      ),
      keepAliveInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}keep_alive_interval'],
      )!,
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RoutingMethod, String, String>
  $convertertrafficMethod = const EnumNameConverter<RoutingMethod>(
    RoutingMethod.values,
  );
  static JsonTypeConverter2<RoutingMethod?, String?, String?>
  $convertertrafficMethodn = JsonTypeConverter2.asNullable(
    $convertertrafficMethod,
  );
  static TypeConverter<MfaMethod, int> $convertermfaMethod =
      const MfaMethodConverter();
  static TypeConverter<MfaMethod?, int?> $convertermfaMethodn =
      NullAwareTypeConverter.wrap($convertermfaMethod);
}

class Location extends DataClass implements Insertable<Location> {
  final int id;
  final int instance;
  final int networkId;
  final String name;
  final String address;
  final String pubKey;
  final String endpoint;
  final String allowedIps;
  final String? dns;
  final bool mfaEnabled;
  final RoutingMethod? trafficMethod;
  final MfaMethod? mfaMethod;
  final int keepAliveInterval;
  const Location({
    required this.id,
    required this.instance,
    required this.networkId,
    required this.name,
    required this.address,
    required this.pubKey,
    required this.endpoint,
    required this.allowedIps,
    this.dns,
    required this.mfaEnabled,
    this.trafficMethod,
    this.mfaMethod,
    required this.keepAliveInterval,
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
    map['mfa_enabled'] = Variable<bool>(mfaEnabled);
    if (!nullToAbsent || trafficMethod != null) {
      map['traffic_method'] = Variable<String>(
        $LocationsTable.$convertertrafficMethodn.toSql(trafficMethod),
      );
    }
    if (!nullToAbsent || mfaMethod != null) {
      map['mfa_method'] = Variable<int>(
        $LocationsTable.$convertermfaMethodn.toSql(mfaMethod),
      );
    }
    map['keep_alive_interval'] = Variable<int>(keepAliveInterval);
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
      mfaEnabled: Value(mfaEnabled),
      trafficMethod: trafficMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(trafficMethod),
      mfaMethod: mfaMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(mfaMethod),
      keepAliveInterval: Value(keepAliveInterval),
    );
  }

  factory Location.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Location(
      id: serializer.fromJson<int>(json['id']),
      instance: serializer.fromJson<int>(json['instance_id']),
      networkId: serializer.fromJson<int>(json['network_id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      pubKey: serializer.fromJson<String>(json['pubkey']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      allowedIps: serializer.fromJson<String>(json['allowed_ips']),
      dns: serializer.fromJson<String?>(json['dns']),
      mfaEnabled: serializer.fromJson<bool>(json['mfa_enabled']),
      trafficMethod: $LocationsTable.$convertertrafficMethodn.fromJson(
        serializer.fromJson<String?>(json['traffic_method']),
      ),
      mfaMethod: serializer.fromJson<MfaMethod?>(json['mfa_method']),
      keepAliveInterval: serializer.fromJson<int>(json['keepalive_interval']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instance_id': serializer.toJson<int>(instance),
      'network_id': serializer.toJson<int>(networkId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'pubkey': serializer.toJson<String>(pubKey),
      'endpoint': serializer.toJson<String>(endpoint),
      'allowed_ips': serializer.toJson<String>(allowedIps),
      'dns': serializer.toJson<String?>(dns),
      'mfa_enabled': serializer.toJson<bool>(mfaEnabled),
      'traffic_method': serializer.toJson<String?>(
        $LocationsTable.$convertertrafficMethodn.toJson(trafficMethod),
      ),
      'mfa_method': serializer.toJson<MfaMethod?>(mfaMethod),
      'keepalive_interval': serializer.toJson<int>(keepAliveInterval),
    };
  }

  Location copyWith({
    int? id,
    int? instance,
    int? networkId,
    String? name,
    String? address,
    String? pubKey,
    String? endpoint,
    String? allowedIps,
    Value<String?> dns = const Value.absent(),
    bool? mfaEnabled,
    Value<RoutingMethod?> trafficMethod = const Value.absent(),
    Value<MfaMethod?> mfaMethod = const Value.absent(),
    int? keepAliveInterval,
  }) => Location(
    id: id ?? this.id,
    instance: instance ?? this.instance,
    networkId: networkId ?? this.networkId,
    name: name ?? this.name,
    address: address ?? this.address,
    pubKey: pubKey ?? this.pubKey,
    endpoint: endpoint ?? this.endpoint,
    allowedIps: allowedIps ?? this.allowedIps,
    dns: dns.present ? dns.value : this.dns,
    mfaEnabled: mfaEnabled ?? this.mfaEnabled,
    trafficMethod: trafficMethod.present
        ? trafficMethod.value
        : this.trafficMethod,
    mfaMethod: mfaMethod.present ? mfaMethod.value : this.mfaMethod,
    keepAliveInterval: keepAliveInterval ?? this.keepAliveInterval,
  );
  Location copyWithCompanion(LocationsCompanion data) {
    return Location(
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('Location(')
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
          ..write('keepAliveInterval: $keepAliveInterval')
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Location &&
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
          other.keepAliveInterval == this.keepAliveInterval);
}

class LocationsCompanion extends UpdateCompanion<Location> {
  final Value<int> id;
  final Value<int> instance;
  final Value<int> networkId;
  final Value<String> name;
  final Value<String> address;
  final Value<String> pubKey;
  final Value<String> endpoint;
  final Value<String> allowedIps;
  final Value<String?> dns;
  final Value<bool> mfaEnabled;
  final Value<RoutingMethod?> trafficMethod;
  final Value<MfaMethod?> mfaMethod;
  final Value<int> keepAliveInterval;
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
    required bool mfaEnabled,
    this.trafficMethod = const Value.absent(),
    this.mfaMethod = const Value.absent(),
    required int keepAliveInterval,
  }) : instance = Value(instance),
       networkId = Value(networkId),
       name = Value(name),
       address = Value(address),
       pubKey = Value(pubKey),
       endpoint = Value(endpoint),
       allowedIps = Value(allowedIps),
       mfaEnabled = Value(mfaEnabled),
       keepAliveInterval = Value(keepAliveInterval);
  static Insertable<Location> custom({
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
    Value<bool>? mfaEnabled,
    Value<RoutingMethod?>? trafficMethod,
    Value<MfaMethod?>? mfaMethod,
    Value<int>? keepAliveInterval,
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
      map['traffic_method'] = Variable<String>(
        $LocationsTable.$convertertrafficMethodn.toSql(trafficMethod.value),
      );
    }
    if (mfaMethod.present) {
      map['mfa_method'] = Variable<int>(
        $LocationsTable.$convertermfaMethodn.toSql(mfaMethod.value),
      );
    }
    if (keepAliveInterval.present) {
      map['keep_alive_interval'] = Variable<int>(keepAliveInterval.value);
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
          ..write('keepAliveInterval: $keepAliveInterval')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DefguardInstancesTable defguardInstances =
      $DefguardInstancesTable(this);
  late final $LocationsTable locations = $LocationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    defguardInstances,
    locations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'defguard_instances',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('locations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DefguardInstancesTableCreateCompanionBuilder =
    DefguardInstancesCompanion Function({
      Value<int> id,
      required String name,
      required String uuid,
      required String url,
      required String proxyUrl,
      required String username,
      required String token,
      required bool disableAllTraffic,
      required bool enterpriseEnabled,
      required String pubKey,
      required String privateKey,
      required bool useOpenidForMfa,
    });
typedef $$DefguardInstancesTableUpdateCompanionBuilder =
    DefguardInstancesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> uuid,
      Value<String> url,
      Value<String> proxyUrl,
      Value<String> username,
      Value<String> token,
      Value<bool> disableAllTraffic,
      Value<bool> enterpriseEnabled,
      Value<String> pubKey,
      Value<String> privateKey,
      Value<bool> useOpenidForMfa,
    });

final class $$DefguardInstancesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DefguardInstancesTable,
          DefguardInstance
        > {
  $$DefguardInstancesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocationsTable, List<Location>>
  _locationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.locations,
    aliasName: $_aliasNameGenerator(
      db.defguardInstances.id,
      db.locations.instance,
    ),
  );

  $$LocationsTableProcessedTableManager get locationsRefs {
    final manager = $$LocationsTableTableManager(
      $_db,
      $_db.locations,
    ).filter((f) => f.instance.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_locationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DefguardInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $DefguardInstancesTable> {
  $$DefguardInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proxyUrl => $composableBuilder(
    column: $table.proxyUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disableAllTraffic => $composableBuilder(
    column: $table.disableAllTraffic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enterpriseEnabled => $composableBuilder(
    column: $table.enterpriseEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useOpenidForMfa => $composableBuilder(
    column: $table.useOpenidForMfa,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> locationsRefs(
    Expression<bool> Function($$LocationsTableFilterComposer f) f,
  ) {
    final $$LocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.instance,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableFilterComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DefguardInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $DefguardInstancesTable> {
  $$DefguardInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proxyUrl => $composableBuilder(
    column: $table.proxyUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disableAllTraffic => $composableBuilder(
    column: $table.disableAllTraffic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enterpriseEnabled => $composableBuilder(
    column: $table.enterpriseEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useOpenidForMfa => $composableBuilder(
    column: $table.useOpenidForMfa,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DefguardInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DefguardInstancesTable> {
  $$DefguardInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get proxyUrl =>
      $composableBuilder(column: $table.proxyUrl, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<bool> get disableAllTraffic => $composableBuilder(
    column: $table.disableAllTraffic,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enterpriseEnabled => $composableBuilder(
    column: $table.enterpriseEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useOpenidForMfa => $composableBuilder(
    column: $table.useOpenidForMfa,
    builder: (column) => column,
  );

  Expression<T> locationsRefs<T extends Object>(
    Expression<T> Function($$LocationsTableAnnotationComposer a) f,
  ) {
    final $$LocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.instance,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DefguardInstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DefguardInstancesTable,
          DefguardInstance,
          $$DefguardInstancesTableFilterComposer,
          $$DefguardInstancesTableOrderingComposer,
          $$DefguardInstancesTableAnnotationComposer,
          $$DefguardInstancesTableCreateCompanionBuilder,
          $$DefguardInstancesTableUpdateCompanionBuilder,
          (DefguardInstance, $$DefguardInstancesTableReferences),
          DefguardInstance,
          PrefetchHooks Function({bool locationsRefs})
        > {
  $$DefguardInstancesTableTableManager(
    _$AppDatabase db,
    $DefguardInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DefguardInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DefguardInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DefguardInstancesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> proxyUrl = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<bool> disableAllTraffic = const Value.absent(),
                Value<bool> enterpriseEnabled = const Value.absent(),
                Value<String> pubKey = const Value.absent(),
                Value<String> privateKey = const Value.absent(),
                Value<bool> useOpenidForMfa = const Value.absent(),
              }) => DefguardInstancesCompanion(
                id: id,
                name: name,
                uuid: uuid,
                url: url,
                proxyUrl: proxyUrl,
                username: username,
                token: token,
                disableAllTraffic: disableAllTraffic,
                enterpriseEnabled: enterpriseEnabled,
                pubKey: pubKey,
                privateKey: privateKey,
                useOpenidForMfa: useOpenidForMfa,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String uuid,
                required String url,
                required String proxyUrl,
                required String username,
                required String token,
                required bool disableAllTraffic,
                required bool enterpriseEnabled,
                required String pubKey,
                required String privateKey,
                required bool useOpenidForMfa,
              }) => DefguardInstancesCompanion.insert(
                id: id,
                name: name,
                uuid: uuid,
                url: url,
                proxyUrl: proxyUrl,
                username: username,
                token: token,
                disableAllTraffic: disableAllTraffic,
                enterpriseEnabled: enterpriseEnabled,
                pubKey: pubKey,
                privateKey: privateKey,
                useOpenidForMfa: useOpenidForMfa,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DefguardInstancesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({locationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (locationsRefs) db.locations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (locationsRefs)
                    await $_getPrefetchedData<
                      DefguardInstance,
                      $DefguardInstancesTable,
                      Location
                    >(
                      currentTable: table,
                      referencedTable: $$DefguardInstancesTableReferences
                          ._locationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DefguardInstancesTableReferences(
                            db,
                            table,
                            p0,
                          ).locationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.instance == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DefguardInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DefguardInstancesTable,
      DefguardInstance,
      $$DefguardInstancesTableFilterComposer,
      $$DefguardInstancesTableOrderingComposer,
      $$DefguardInstancesTableAnnotationComposer,
      $$DefguardInstancesTableCreateCompanionBuilder,
      $$DefguardInstancesTableUpdateCompanionBuilder,
      (DefguardInstance, $$DefguardInstancesTableReferences),
      DefguardInstance,
      PrefetchHooks Function({bool locationsRefs})
    >;
typedef $$LocationsTableCreateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      required int instance,
      required int networkId,
      required String name,
      required String address,
      required String pubKey,
      required String endpoint,
      required String allowedIps,
      Value<String?> dns,
      required bool mfaEnabled,
      Value<RoutingMethod?> trafficMethod,
      Value<MfaMethod?> mfaMethod,
      required int keepAliveInterval,
    });
typedef $$LocationsTableUpdateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      Value<int> instance,
      Value<int> networkId,
      Value<String> name,
      Value<String> address,
      Value<String> pubKey,
      Value<String> endpoint,
      Value<String> allowedIps,
      Value<String?> dns,
      Value<bool> mfaEnabled,
      Value<RoutingMethod?> trafficMethod,
      Value<MfaMethod?> mfaMethod,
      Value<int> keepAliveInterval,
    });

final class $$LocationsTableReferences
    extends BaseReferences<_$AppDatabase, $LocationsTable, Location> {
  $$LocationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DefguardInstancesTable _instanceTable(_$AppDatabase db) =>
      db.defguardInstances.createAlias(
        $_aliasNameGenerator(db.locations.instance, db.defguardInstances.id),
      );

  $$DefguardInstancesTableProcessedTableManager get instance {
    final $_column = $_itemColumn<int>('instance')!;

    final manager = $$DefguardInstancesTableTableManager(
      $_db,
      $_db.defguardInstances,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instanceTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get networkId => $composableBuilder(
    column: $table.networkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowedIps => $composableBuilder(
    column: $table.allowedIps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dns => $composableBuilder(
    column: $table.dns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mfaEnabled => $composableBuilder(
    column: $table.mfaEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RoutingMethod?, RoutingMethod, String>
  get trafficMethod => $composableBuilder(
    column: $table.trafficMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MfaMethod?, MfaMethod, int> get mfaMethod =>
      $composableBuilder(
        column: $table.mfaMethod,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get keepAliveInterval => $composableBuilder(
    column: $table.keepAliveInterval,
    builder: (column) => ColumnFilters(column),
  );

  $$DefguardInstancesTableFilterComposer get instance {
    final $$DefguardInstancesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instance,
      referencedTable: $db.defguardInstances,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefguardInstancesTableFilterComposer(
            $db: $db,
            $table: $db.defguardInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get networkId => $composableBuilder(
    column: $table.networkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubKey => $composableBuilder(
    column: $table.pubKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowedIps => $composableBuilder(
    column: $table.allowedIps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dns => $composableBuilder(
    column: $table.dns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mfaEnabled => $composableBuilder(
    column: $table.mfaEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trafficMethod => $composableBuilder(
    column: $table.trafficMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mfaMethod => $composableBuilder(
    column: $table.mfaMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keepAliveInterval => $composableBuilder(
    column: $table.keepAliveInterval,
    builder: (column) => ColumnOrderings(column),
  );

  $$DefguardInstancesTableOrderingComposer get instance {
    final $$DefguardInstancesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instance,
      referencedTable: $db.defguardInstances,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DefguardInstancesTableOrderingComposer(
            $db: $db,
            $table: $db.defguardInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get networkId =>
      $composableBuilder(column: $table.networkId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get pubKey =>
      $composableBuilder(column: $table.pubKey, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get allowedIps => $composableBuilder(
    column: $table.allowedIps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dns =>
      $composableBuilder(column: $table.dns, builder: (column) => column);

  GeneratedColumn<bool> get mfaEnabled => $composableBuilder(
    column: $table.mfaEnabled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RoutingMethod?, String> get trafficMethod =>
      $composableBuilder(
        column: $table.trafficMethod,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MfaMethod?, int> get mfaMethod =>
      $composableBuilder(column: $table.mfaMethod, builder: (column) => column);

  GeneratedColumn<int> get keepAliveInterval => $composableBuilder(
    column: $table.keepAliveInterval,
    builder: (column) => column,
  );

  $$DefguardInstancesTableAnnotationComposer get instance {
    final $$DefguardInstancesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.instance,
          referencedTable: $db.defguardInstances,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DefguardInstancesTableAnnotationComposer(
                $db: $db,
                $table: $db.defguardInstances,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationsTable,
          Location,
          $$LocationsTableFilterComposer,
          $$LocationsTableOrderingComposer,
          $$LocationsTableAnnotationComposer,
          $$LocationsTableCreateCompanionBuilder,
          $$LocationsTableUpdateCompanionBuilder,
          (Location, $$LocationsTableReferences),
          Location,
          PrefetchHooks Function({bool instance})
        > {
  $$LocationsTableTableManager(_$AppDatabase db, $LocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instance = const Value.absent(),
                Value<int> networkId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> pubKey = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> allowedIps = const Value.absent(),
                Value<String?> dns = const Value.absent(),
                Value<bool> mfaEnabled = const Value.absent(),
                Value<RoutingMethod?> trafficMethod = const Value.absent(),
                Value<MfaMethod?> mfaMethod = const Value.absent(),
                Value<int> keepAliveInterval = const Value.absent(),
              }) => LocationsCompanion(
                id: id,
                instance: instance,
                networkId: networkId,
                name: name,
                address: address,
                pubKey: pubKey,
                endpoint: endpoint,
                allowedIps: allowedIps,
                dns: dns,
                mfaEnabled: mfaEnabled,
                trafficMethod: trafficMethod,
                mfaMethod: mfaMethod,
                keepAliveInterval: keepAliveInterval,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instance,
                required int networkId,
                required String name,
                required String address,
                required String pubKey,
                required String endpoint,
                required String allowedIps,
                Value<String?> dns = const Value.absent(),
                required bool mfaEnabled,
                Value<RoutingMethod?> trafficMethod = const Value.absent(),
                Value<MfaMethod?> mfaMethod = const Value.absent(),
                required int keepAliveInterval,
              }) => LocationsCompanion.insert(
                id: id,
                instance: instance,
                networkId: networkId,
                name: name,
                address: address,
                pubKey: pubKey,
                endpoint: endpoint,
                allowedIps: allowedIps,
                dns: dns,
                mfaEnabled: mfaEnabled,
                trafficMethod: trafficMethod,
                mfaMethod: mfaMethod,
                keepAliveInterval: keepAliveInterval,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({instance = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (instance) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.instance,
                                referencedTable: $$LocationsTableReferences
                                    ._instanceTable(db),
                                referencedColumn: $$LocationsTableReferences
                                    ._instanceTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationsTable,
      Location,
      $$LocationsTableFilterComposer,
      $$LocationsTableOrderingComposer,
      $$LocationsTableAnnotationComposer,
      $$LocationsTableCreateCompanionBuilder,
      $$LocationsTableUpdateCompanionBuilder,
      (Location, $$LocationsTableReferences),
      Location,
      PrefetchHooks Function({bool instance})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DefguardInstancesTableTableManager get defguardInstances =>
      $$DefguardInstancesTableTableManager(_db, _db.defguardInstances);
  $$LocationsTableTableManager get locations =>
      $$LocationsTableTableManager(_db, _db.locations);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'b43f5a38382427710fbceefeb419518e859b35ea';

/// See also [database].
@ProviderFor(database)
final databaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = AutoDisposeProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
