// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa.dart';

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
    };

StartMfaRequest _$StartMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StartMfaRequest',
      json,
      ($checkedConvert) {
        final val = StartMfaRequest(
          pubkey: $checkedConvert('pubkey', (v) => v as String),
          locationId: $checkedConvert('location_id', (v) => (v as num).toInt()),
          method: $checkedConvert(
            'method',
            (v) => $enumDecode(_$MfaMethodEnumMap, v),
          ),
          postureData: $checkedConvert(
            'posture_data',
            (v) => v == null
                ? null
                : DevicePostureData.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'locationId': 'location_id',
        'postureData': 'posture_data',
      },
    );

const _$StartMfaRequestFieldMap = <String, String>{
  'pubkey': 'pubkey',
  'locationId': 'location_id',
  'method': 'method',
  'postureData': 'posture_data',
};

Map<String, dynamic> _$StartMfaRequestToJson(StartMfaRequest instance) =>
    <String, dynamic>{
      'pubkey': instance.pubkey,
      'location_id': instance.locationId,
      'method': _$MfaMethodEnumMap[instance.method]!,
      'posture_data': instance.postureData,
    };

const _$MfaMethodEnumMap = {
  MfaMethod.totp: 0,
  MfaMethod.email: 1,
  MfaMethod.openid: 2,
  MfaMethod.biometric: 3,
};

StartMfaResponse _$StartMfaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartMfaResponse', json, ($checkedConvert) {
      final val = StartMfaResponse(
        token: $checkedConvert('token', (v) => v as String),
        challenge: $checkedConvert('challenge', (v) => v as String?),
      );
      return val;
    });

const _$StartMfaResponseFieldMap = <String, String>{
  'token': 'token',
  'challenge': 'challenge',
};

Map<String, dynamic> _$StartMfaResponseToJson(StartMfaResponse instance) =>
    <String, dynamic>{'token': instance.token, 'challenge': instance.challenge};

FinishMfaRequest _$FinishMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinishMfaRequest', json, ($checkedConvert) {
      final val = FinishMfaRequest(
        token: $checkedConvert('token', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String?),
        authPubKey: $checkedConvert('auth_pub_key', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'authPubKey': 'auth_pub_key'});

const _$FinishMfaRequestFieldMap = <String, String>{
  'token': 'token',
  'code': 'code',
  'authPubKey': 'auth_pub_key',
};

Map<String, dynamic> _$FinishMfaRequestToJson(FinishMfaRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'code': instance.code,
      'auth_pub_key': instance.authPubKey,
    };

FinishMfaResponse _$FinishMfaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinishMfaResponse', json, ($checkedConvert) {
      final val = FinishMfaResponse(
        presharedKey: $checkedConvert('preshared_key', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'presharedKey': 'preshared_key'});

const _$FinishMfaResponseFieldMap = <String, String>{
  'presharedKey': 'preshared_key',
};

Map<String, dynamic> _$FinishMfaResponseToJson(FinishMfaResponse instance) =>
    <String, dynamic>{'preshared_key': instance.presharedKey};

SecureInstanceStorage _$SecureInstanceStorageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SecureInstanceStorage',
  json,
  ($checkedConvert) {
    final val = SecureInstanceStorage(
      privateKey: $checkedConvert('private_key', (v) => v as String),
      publicKey: $checkedConvert('public_key', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'privateKey': 'private_key', 'publicKey': 'public_key'},
);

const _$SecureInstanceStorageFieldMap = <String, String>{
  'privateKey': 'private_key',
  'publicKey': 'public_key',
};

Map<String, dynamic> _$SecureInstanceStorageToJson(
  SecureInstanceStorage instance,
) => <String, dynamic>{
  'private_key': instance.privateKey,
  'public_key': instance.publicKey,
};

RemoteMfaQr _$RemoteMfaQrFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RemoteMfaQr', json, ($checkedConvert) {
      final val = RemoteMfaQr(
        instanceId: $checkedConvert('instance_id', (v) => v as String),
        token: $checkedConvert('token', (v) => v as String),
        challenge: $checkedConvert('challenge', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'instanceId': 'instance_id'});

const _$RemoteMfaQrFieldMap = <String, String>{
  'instanceId': 'instance_id',
  'token': 'token',
  'challenge': 'challenge',
};

Map<String, dynamic> _$RemoteMfaQrToJson(RemoteMfaQr instance) =>
    <String, dynamic>{
      'instance_id': instance.instanceId,
      'token': instance.token,
      'challenge': instance.challenge,
    };
