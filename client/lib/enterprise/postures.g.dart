// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'postures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StringCheck _$StringCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StringCheck', json, ($checkedConvert) {
      final val = StringCheck(
        result: $checkedConvert('result', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

const _$StringCheckFieldMap = <String, String>{'result': 'result'};

Map<String, dynamic> _$StringCheckToJson(StringCheck instance) =>
    <String, dynamic>{'result': instance.result};

BoolCheck _$BoolCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BoolCheck', json, ($checkedConvert) {
      final val = BoolCheck(
        result: $checkedConvert('result', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

const _$BoolCheckFieldMap = <String, String>{'result': 'result'};

Map<String, dynamic> _$BoolCheckToJson(BoolCheck instance) => <String, dynamic>{
  'result': instance.result,
};

Int32Check _$Int32CheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Int32Check', json, ($checkedConvert) {
      final val = Int32Check(
        result: $checkedConvert('result', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

const _$Int32CheckFieldMap = <String, String>{'result': 'result'};

Map<String, dynamic> _$Int32CheckToJson(Int32Check instance) =>
    <String, dynamic>{'result': instance.result};

DevicePostureData _$DevicePostureDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DevicePostureData',
  json,
  ($checkedConvert) {
    final val = DevicePostureData(
      defguardClientVersion: $checkedConvert(
        'defguard_client_version',
        (v) => v as String,
      ),
      osType: $checkedConvert('os_type', (v) => v as String),
      osName: $checkedConvert(
        'os_name',
        (v) =>
            v == null ? null : StringCheck.fromJson(v as Map<String, dynamic>),
      ),
      osVersion: $checkedConvert(
        'os_version',
        (v) =>
            v == null ? null : StringCheck.fromJson(v as Map<String, dynamic>),
      ),
      diskEncryption: $checkedConvert(
        'disk_encryption',
        (v) => v == null ? null : BoolCheck.fromJson(v as Map<String, dynamic>),
      ),
      antivirusPresent: $checkedConvert(
        'antivirus_present',
        (v) => v == null ? null : BoolCheck.fromJson(v as Map<String, dynamic>),
      ),
      windowsAdDomainJoined: $checkedConvert(
        'windows_ad_domain_joined',
        (v) => v == null ? null : BoolCheck.fromJson(v as Map<String, dynamic>),
      ),
      windowsSecurityUpdateAgeDays: $checkedConvert(
        'windows_security_update_age_days',
        (v) =>
            v == null ? null : Int32Check.fromJson(v as Map<String, dynamic>),
      ),
      linuxKernelVersion: $checkedConvert(
        'linux_kernel_version',
        (v) =>
            v == null ? null : StringCheck.fromJson(v as Map<String, dynamic>),
      ),
      deviceIntegrity: $checkedConvert(
        'device_integrity',
        (v) => v == null ? null : BoolCheck.fromJson(v as Map<String, dynamic>),
      ),
      androidSecurityPatchDate: $checkedConvert(
        'android_security_patch_date',
        (v) =>
            v == null ? null : StringCheck.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'defguardClientVersion': 'defguard_client_version',
    'osType': 'os_type',
    'osName': 'os_name',
    'osVersion': 'os_version',
    'diskEncryption': 'disk_encryption',
    'antivirusPresent': 'antivirus_present',
    'windowsAdDomainJoined': 'windows_ad_domain_joined',
    'windowsSecurityUpdateAgeDays': 'windows_security_update_age_days',
    'linuxKernelVersion': 'linux_kernel_version',
    'deviceIntegrity': 'device_integrity',
    'androidSecurityPatchDate': 'android_security_patch_date',
  },
);

const _$DevicePostureDataFieldMap = <String, String>{
  'defguardClientVersion': 'defguard_client_version',
  'osType': 'os_type',
  'osName': 'os_name',
  'osVersion': 'os_version',
  'diskEncryption': 'disk_encryption',
  'antivirusPresent': 'antivirus_present',
  'windowsAdDomainJoined': 'windows_ad_domain_joined',
  'windowsSecurityUpdateAgeDays': 'windows_security_update_age_days',
  'linuxKernelVersion': 'linux_kernel_version',
  'deviceIntegrity': 'device_integrity',
  'androidSecurityPatchDate': 'android_security_patch_date',
};

Map<String, dynamic> _$DevicePostureDataToJson(DevicePostureData instance) =>
    <String, dynamic>{
      'defguard_client_version': instance.defguardClientVersion,
      'os_type': instance.osType,
      'os_name': instance.osName,
      'os_version': instance.osVersion,
      'disk_encryption': instance.diskEncryption,
      'antivirus_present': instance.antivirusPresent,
      'windows_ad_domain_joined': instance.windowsAdDomainJoined,
      'windows_security_update_age_days': instance.windowsSecurityUpdateAgeDays,
      'linux_kernel_version': instance.linuxKernelVersion,
      'device_integrity': instance.deviceIntegrity,
      'android_security_patch_date': instance.androidSecurityPatchDate,
    };

PostureConnectRequest _$PostureConnectRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PostureConnectRequest',
  json,
  ($checkedConvert) {
    final val = PostureConnectRequest(
      locationId: $checkedConvert('location_id', (v) => (v as num).toInt()),
      pubkey: $checkedConvert('pubkey', (v) => v as String),
      devicePostureData: $checkedConvert(
        'device_posture_data',
        (v) => DevicePostureData.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'locationId': 'location_id',
    'devicePostureData': 'device_posture_data',
  },
);

const _$PostureConnectRequestFieldMap = <String, String>{
  'locationId': 'location_id',
  'pubkey': 'pubkey',
  'devicePostureData': 'device_posture_data',
};

Map<String, dynamic> _$PostureConnectRequestToJson(
  PostureConnectRequest instance,
) => <String, dynamic>{
  'location_id': instance.locationId,
  'pubkey': instance.pubkey,
  'device_posture_data': instance.devicePostureData,
};

PostureConnectResponse _$PostureConnectResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PostureConnectResponse',
  json,
  ($checkedConvert) {
    final val = PostureConnectResponse(
      presharedKey: $checkedConvert('preshared_key', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'presharedKey': 'preshared_key'},
);

const _$PostureConnectResponseFieldMap = <String, String>{
  'presharedKey': 'preshared_key',
};

Map<String, dynamic> _$PostureConnectResponseToJson(
  PostureConnectResponse instance,
) => <String, dynamic>{'preshared_key': instance.presharedKey};
