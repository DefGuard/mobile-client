// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartMfaRequest _$StartMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartMfaRequest', json, ($checkedConvert) {
      final val = StartMfaRequest(
        pubkey: $checkedConvert('pubkey', (v) => v as String),
        locationId: $checkedConvert('location_id', (v) => (v as num).toInt()),
        method: $checkedConvert(
          'method',
          (v) => $enumDecode(_$MfaMethodEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'locationId': 'location_id'});

const _$StartMfaRequestFieldMap = <String, String>{
  'pubkey': 'pubkey',
  'locationId': 'location_id',
  'method': 'method',
};

Map<String, dynamic> _$StartMfaRequestToJson(StartMfaRequest instance) =>
    <String, dynamic>{
      'pubkey': instance.pubkey,
      'location_id': instance.locationId,
      'method': _$MfaMethodEnumMap[instance.method]!,
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
