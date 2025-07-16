// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstanceInfoResponse _$InstanceInfoResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstanceInfoResponse', json, ($checkedConvert) {
  final val = InstanceInfoResponse(
    deviceConfig: $checkedConvert(
      'device_config',
      (v) => v == null
          ? null
          : ConfigurationPollResponse.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'deviceConfig': 'device_config'});

const _$InstanceInfoResponseFieldMap = <String, String>{
  'deviceConfig': 'device_config',
};

Map<String, dynamic> _$InstanceInfoResponseToJson(
  InstanceInfoResponse instance,
) => <String, dynamic>{'device_config': instance.deviceConfig};

ConfigurationPollResponse _$ConfigurationPollResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConfigurationPollResponse', json, ($checkedConvert) {
  final val = ConfigurationPollResponse(
    device: $checkedConvert(
      'device',
      (v) => v == null ? null : Device.fromJson(v as Map<String, dynamic>),
    ),
    configs: $checkedConvert(
      'configs',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    instance: $checkedConvert(
      'instance',
      (v) =>
          v == null ? null : InstanceInfo.fromJson(v as Map<String, dynamic>),
    ),
    token: $checkedConvert('token', (v) => v as String?),
  );
  return val;
});

const _$ConfigurationPollResponseFieldMap = <String, String>{
  'device': 'device',
  'configs': 'configs',
  'instance': 'instance',
  'token': 'token',
};

Map<String, dynamic> _$ConfigurationPollResponseToJson(
  ConfigurationPollResponse instance,
) => <String, dynamic>{
  'device': instance.device,
  'configs': instance.configs,
  'instance': instance.instance,
  'token': instance.token,
};

NetworkInfoResponse _$NetworkInfoResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkInfoResponse', json, ($checkedConvert) {
      final val = NetworkInfoResponse(
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
      );
      return val;
    });

const _$NetworkInfoResponseFieldMap = <String, String>{
  'device': 'device',
  'configs': 'configs',
  'instance': 'instance',
};

Map<String, dynamic> _$NetworkInfoResponseToJson(
  NetworkInfoResponse instance,
) => <String, dynamic>{
  'device': instance.device,
  'configs': instance.configs,
  'instance': instance.instance,
};
