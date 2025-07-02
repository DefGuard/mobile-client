// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentStartRequest _$EnrollmentStartRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EnrollmentStartRequest', json, ($checkedConvert) {
  final val = EnrollmentStartRequest(
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

const _$EnrollmentStartRequestFieldMap = <String, String>{'token': 'token'};

Map<String, dynamic> _$EnrollmentStartRequestToJson(
  EnrollmentStartRequest instance,
) => <String, dynamic>{'token': instance.token};

EnrollmentSettings _$EnrollmentSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EnrollmentSettings',
      json,
      ($checkedConvert) {
        final val = EnrollmentSettings(
          vpnSetupOptional: $checkedConvert(
            'vpn_setup_optional',
            (v) => v as bool,
          ),
          onlyClientActivation: $checkedConvert(
            'only_client_activation',
            (v) => v as bool,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'vpnSetupOptional': 'vpn_setup_optional',
        'onlyClientActivation': 'only_client_activation',
      },
    );

const _$EnrollmentSettingsFieldMap = <String, String>{
  'vpnSetupOptional': 'vpn_setup_optional',
  'onlyClientActivation': 'only_client_activation',
};

Map<String, dynamic> _$EnrollmentSettingsToJson(EnrollmentSettings instance) =>
    <String, dynamic>{
      'vpn_setup_optional': instance.vpnSetupOptional,
      'only_client_activation': instance.onlyClientActivation,
    };

EnrollmentStartResponse _$EnrollmentStartResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'EnrollmentStartResponse',
  json,
  ($checkedConvert) {
    final val = EnrollmentStartResponse(
      admin: $checkedConvert(
        'admin',
        (v) => AdminInfo.fromJson(v as Map<String, dynamic>),
      ),
      user: $checkedConvert(
        'user',
        (v) => UserInfo.fromJson(v as Map<String, dynamic>),
      ),
      instance: $checkedConvert(
        'instance',
        (v) => EnrollmentInstanceInfo.fromJson(v as Map<String, dynamic>),
      ),
      deadlineTimestamp: $checkedConvert(
        'deadline_timestamp',
        (v) => (v as num).toInt(),
      ),
      finalPageContent: $checkedConvert(
        'final_page_content',
        (v) => v as String,
      ),
      settings: $checkedConvert(
        'settings',
        (v) => EnrollmentSettings.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'deadlineTimestamp': 'deadline_timestamp',
    'finalPageContent': 'final_page_content',
  },
);

const _$EnrollmentStartResponseFieldMap = <String, String>{
  'admin': 'admin',
  'user': 'user',
  'instance': 'instance',
  'deadlineTimestamp': 'deadline_timestamp',
  'finalPageContent': 'final_page_content',
  'settings': 'settings',
};

Map<String, dynamic> _$EnrollmentStartResponseToJson(
  EnrollmentStartResponse instance,
) => <String, dynamic>{
  'admin': instance.admin,
  'user': instance.user,
  'instance': instance.instance,
  'deadline_timestamp': instance.deadlineTimestamp,
  'final_page_content': instance.finalPageContent,
  'settings': instance.settings,
};

EnrollmentInstanceInfo _$EnrollmentInstanceInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EnrollmentInstanceInfo', json, ($checkedConvert) {
  final val = EnrollmentInstanceInfo(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
  );
  return val;
});

const _$EnrollmentInstanceInfoFieldMap = <String, String>{
  'id': 'id',
  'name': 'name',
  'url': 'url',
};

Map<String, dynamic> _$EnrollmentInstanceInfoToJson(
  EnrollmentInstanceInfo instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'url': instance.url,
};

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserInfo',
  json,
  ($checkedConvert) {
    final val = UserInfo(
      firstName: $checkedConvert('first_name', (v) => v as String),
      lastName: $checkedConvert('last_name', (v) => v as String),
      login: $checkedConvert('login', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      isActive: $checkedConvert('is_active', (v) => v as bool),
      deviceNames: $checkedConvert(
        'device_names',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      enrolled: $checkedConvert('enrolled', (v) => v as bool),
      phoneNumber: $checkedConvert('phone_number', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'isActive': 'is_active',
    'deviceNames': 'device_names',
    'phoneNumber': 'phone_number',
  },
);

const _$UserInfoFieldMap = <String, String>{
  'firstName': 'first_name',
  'lastName': 'last_name',
  'login': 'login',
  'email': 'email',
  'isActive': 'is_active',
  'phoneNumber': 'phone_number',
  'deviceNames': 'device_names',
  'enrolled': 'enrolled',
};

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'login': instance.login,
  'email': instance.email,
  'is_active': instance.isActive,
  'phone_number': instance.phoneNumber,
  'device_names': instance.deviceNames,
  'enrolled': instance.enrolled,
};

AdminInfo _$AdminInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminInfo', json, ($checkedConvert) {
      final val = AdminInfo(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        phoneNumber: $checkedConvert('phone_number', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'phoneNumber': 'phone_number'});

const _$AdminInfoFieldMap = <String, String>{
  'name': 'name',
  'email': 'email',
  'phoneNumber': 'phone_number',
};

Map<String, dynamic> _$AdminInfoToJson(AdminInfo instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'phone_number': instance.phoneNumber,
};

Device _$DeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Device', json, ($checkedConvert) {
      final val = Device(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        pubkey: $checkedConvert('pubkey', (v) => v as String),
        userId: $checkedConvert('user_id', (v) => (v as num).toInt()),
        createdAt: $checkedConvert('created_at', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id', 'createdAt': 'created_at'});

const _$DeviceFieldMap = <String, String>{
  'id': 'id',
  'name': 'name',
  'pubkey': 'pubkey',
  'userId': 'user_id',
  'createdAt': 'created_at',
};

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pubkey': instance.pubkey,
  'user_id': instance.userId,
  'created_at': instance.createdAt,
};

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeviceConfig',
      json,
      ($checkedConvert) {
        final val = DeviceConfig(
          networkId: $checkedConvert('network_id', (v) => (v as num).toInt()),
          networkName: $checkedConvert('network_name', (v) => v as String),
          config: $checkedConvert('config', (v) => v as String),
          endpoint: $checkedConvert('endpoint', (v) => v as String),
          assignedIp: $checkedConvert('assigned_ip', (v) => v as String),
          pubkey: $checkedConvert('pubkey', (v) => v as String),
          allowedIps: $checkedConvert('allowed_ips', (v) => v as String),
          dns: $checkedConvert('dns', (v) => v as String?),
          mfaEnabled: $checkedConvert('mfa_enabled', (v) => v as bool),
          keepaliveInterval: $checkedConvert(
            'keepalive_interval',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'networkId': 'network_id',
        'networkName': 'network_name',
        'assignedIp': 'assigned_ip',
        'allowedIps': 'allowed_ips',
        'mfaEnabled': 'mfa_enabled',
        'keepaliveInterval': 'keepalive_interval',
      },
    );

const _$DeviceConfigFieldMap = <String, String>{
  'networkId': 'network_id',
  'networkName': 'network_name',
  'config': 'config',
  'endpoint': 'endpoint',
  'assignedIp': 'assigned_ip',
  'pubkey': 'pubkey',
  'allowedIps': 'allowed_ips',
  'dns': 'dns',
  'mfaEnabled': 'mfa_enabled',
  'keepaliveInterval': 'keepalive_interval',
};

Map<String, dynamic> _$DeviceConfigToJson(DeviceConfig instance) =>
    <String, dynamic>{
      'network_id': instance.networkId,
      'network_name': instance.networkName,
      'config': instance.config,
      'endpoint': instance.endpoint,
      'assigned_ip': instance.assignedIp,
      'pubkey': instance.pubkey,
      'allowed_ips': instance.allowedIps,
      'dns': instance.dns,
      'mfa_enabled': instance.mfaEnabled,
      'keepalive_interval': instance.keepaliveInterval,
    };

CreateDeviceRequest _$CreateDeviceRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateDeviceRequest', json, ($checkedConvert) {
      final val = CreateDeviceRequest(
        name: $checkedConvert('name', (v) => v as String),
        pubkey: $checkedConvert('pubkey', (v) => v as String),
      );
      return val;
    });

const _$CreateDeviceRequestFieldMap = <String, String>{
  'name': 'name',
  'pubkey': 'pubkey',
};

Map<String, dynamic> _$CreateDeviceRequestToJson(
  CreateDeviceRequest instance,
) => <String, dynamic>{'name': instance.name, 'pubkey': instance.pubkey};

CreateDeviceResponse _$CreateDeviceResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateDeviceResponse', json, ($checkedConvert) {
  final val = CreateDeviceResponse(
    device: $checkedConvert(
      'device',
      (v) => Device.fromJson(v as Map<String, dynamic>),
    ),
    configs: $checkedConvert(
      'configs',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    instance: $checkedConvert(
      'instance',
      (v) => InstanceInfo.fromJson(v as Map<String, dynamic>),
    ),
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

const _$CreateDeviceResponseFieldMap = <String, String>{
  'device': 'device',
  'configs': 'configs',
  'instance': 'instance',
  'token': 'token',
};

Map<String, dynamic> _$CreateDeviceResponseToJson(
  CreateDeviceResponse instance,
) => <String, dynamic>{
  'device': instance.device,
  'configs': instance.configs,
  'instance': instance.instance,
  'token': instance.token,
};

InstanceInfo _$InstanceInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InstanceInfo',
      json,
      ($checkedConvert) {
        final val = InstanceInfo(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          proxyUrl: $checkedConvert('proxy_url', (v) => v as String),
          username: $checkedConvert('username', (v) => v as String),
          enterpriseEnabled: $checkedConvert(
            'enterprise_enabled',
            (v) => v as bool,
          ),
          disableAllTraffic: $checkedConvert(
            'disable_all_traffic',
            (v) => v as bool,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'proxyUrl': 'proxy_url',
        'enterpriseEnabled': 'enterprise_enabled',
        'disableAllTraffic': 'disable_all_traffic',
      },
    );

const _$InstanceInfoFieldMap = <String, String>{
  'id': 'id',
  'name': 'name',
  'url': 'url',
  'proxyUrl': 'proxy_url',
  'username': 'username',
  'enterpriseEnabled': 'enterprise_enabled',
  'disableAllTraffic': 'disable_all_traffic',
};

Map<String, dynamic> _$InstanceInfoToJson(InstanceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'proxy_url': instance.proxyUrl,
      'username': instance.username,
      'enterprise_enabled': instance.enterpriseEnabled,
      'disable_all_traffic': instance.disableAllTraffic,
    };

AppInfoResponse _$AppInfoResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppInfoResponse', json, ($checkedConvert) {
      final val = AppInfoResponse(
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

const _$AppInfoResponseFieldMap = <String, String>{'version': 'version'};

Map<String, dynamic> _$AppInfoResponseToJson(AppInfoResponse instance) =>
    <String, dynamic>{'version': instance.version};

WireguardEncodedKeyPair _$WireguardEncodedKeyPairFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'WireguardEncodedKeyPair',
  json,
  ($checkedConvert) {
    final val = WireguardEncodedKeyPair(
      pubKey: $checkedConvert('pub_key', (v) => v as String),
      privKey: $checkedConvert('priv_key', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'pubKey': 'pub_key', 'privKey': 'priv_key'},
);

const _$WireguardEncodedKeyPairFieldMap = <String, String>{
  'pubKey': 'pub_key',
  'privKey': 'priv_key',
};

Map<String, dynamic> _$WireguardEncodedKeyPairToJson(
  WireguardEncodedKeyPair instance,
) => <String, dynamic>{
  'pub_key': instance.pubKey,
  'priv_key': instance.privKey,
};
