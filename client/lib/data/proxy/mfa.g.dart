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
};

StartMfaResponse _$StartMfaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartMfaResponse', json, ($checkedConvert) {
      final val = StartMfaResponse(
        token: $checkedConvert('token', (v) => v as String),
      );
      return val;
    });

const _$StartMfaResponseFieldMap = <String, String>{'token': 'token'};

Map<String, dynamic> _$StartMfaResponseToJson(StartMfaResponse instance) =>
    <String, dynamic>{'token': instance.token};

FinishMfaRequest _$FinishMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinishMfaRequest', json, ($checkedConvert) {
      final val = FinishMfaRequest(
        token: $checkedConvert('token', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String?),
      );
      return val;
    });

const _$FinishMfaRequestFieldMap = <String, String>{
  'token': 'token',
  'code': 'code',
};

Map<String, dynamic> _$FinishMfaRequestToJson(FinishMfaRequest instance) =>
    <String, dynamic>{'token': instance.token, 'code': instance.code};

FinishMfaResponse _$FinishMfaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FinishMfaResponse', json, ($checkedConvert) {
      final val = FinishMfaResponse(
        presharedKey: $checkedConvert('preshared_key', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'presharedKey': 'preshared_key'});

const _$FinishMfaResponseFieldMap = <String, String>{
  'presharedKey': 'preshared_key',
};

Map<String, dynamic> _$FinishMfaResponseToJson(FinishMfaResponse instance) =>
    <String, dynamic>{'preshared_key': instance.presharedKey};
