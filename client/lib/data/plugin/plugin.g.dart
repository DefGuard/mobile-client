// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginConnectPayload _$PluginConnectPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PluginConnectPayload',
  json,
  ($checkedConvert) {
    final val = PluginConnectPayload(
      publicKey: $checkedConvert('public_key', (v) => v as String),
      privateKey: $checkedConvert('private_key', (v) => v as String),
      address: $checkedConvert('address', (v) => v as String),
      endpoint: $checkedConvert('endpoint', (v) => v as String),
      allowedIps: $checkedConvert('allowed_ips', (v) => v as String),
      keepalive: $checkedConvert('keepalive', (v) => (v as num).toInt()),
      locationName: $checkedConvert('location_name', (v) => v as String),
      locationId: $checkedConvert('location_id', (v) => (v as num).toInt()),
      instanceId: $checkedConvert('instance_id', (v) => (v as num).toInt()),
      traffic: $checkedConvert(
        'traffic',
        (v) => $enumDecode(_$TunnelTrafficEnumMap, v),
      ),
      dns: $checkedConvert('dns', (v) => v as String?),
      presharedKey: $checkedConvert('preshared_key', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'publicKey': 'public_key',
    'privateKey': 'private_key',
    'allowedIps': 'allowed_ips',
    'locationName': 'location_name',
    'locationId': 'location_id',
    'instanceId': 'instance_id',
    'presharedKey': 'preshared_key',
  },
);

const _$PluginConnectPayloadFieldMap = <String, String>{
  'publicKey': 'public_key',
  'privateKey': 'private_key',
  'address': 'address',
  'dns': 'dns',
  'endpoint': 'endpoint',
  'allowedIps': 'allowed_ips',
  'keepalive': 'keepalive',
  'presharedKey': 'preshared_key',
  'locationName': 'location_name',
  'locationId': 'location_id',
  'instanceId': 'instance_id',
  'traffic': 'traffic',
};

Map<String, dynamic> _$PluginConnectPayloadToJson(
  PluginConnectPayload instance,
) => <String, dynamic>{
  'public_key': instance.publicKey,
  'private_key': instance.privateKey,
  'address': instance.address,
  'dns': instance.dns,
  'endpoint': instance.endpoint,
  'allowed_ips': instance.allowedIps,
  'keepalive': instance.keepalive,
  'preshared_key': instance.presharedKey,
  'location_name': instance.locationName,
  'location_id': instance.locationId,
  'instance_id': instance.instanceId,
  'traffic': _$TunnelTrafficEnumMap[instance.traffic]!,
};

const _$TunnelTrafficEnumMap = {
  TunnelTraffic.all: 'all',
  TunnelTraffic.predefined: 'predefined',
};

PluginTunnelEventData _$PluginTunnelEventDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PluginTunnelEventData',
  json,
  ($checkedConvert) {
    final val = PluginTunnelEventData(
      instanceId: $checkedConvert('instance_id', (v) => (v as num).toInt()),
      locationId: $checkedConvert('location_id', (v) => (v as num).toInt()),
      traffic: $checkedConvert(
        'traffic',
        (v) => $enumDecode(_$TunnelTrafficEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'instanceId': 'instance_id', 'locationId': 'location_id'},
);

const _$PluginTunnelEventDataFieldMap = <String, String>{
  'instanceId': 'instance_id',
  'locationId': 'location_id',
  'traffic': 'traffic',
};

Map<String, dynamic> _$PluginTunnelEventDataToJson(
  PluginTunnelEventData instance,
) => <String, dynamic>{
  'instance_id': instance.instanceId,
  'location_id': instance.locationId,
  'traffic': _$TunnelTrafficEnumMap[instance.traffic]!,
};
