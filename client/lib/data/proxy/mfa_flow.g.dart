// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa_flow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

const _$MfaFlowStartRequestFieldMap = <String, String>{
  'locationId': 'location_id',
  'pubkey': 'pubkey',
  'postureData': 'posture_data',
  'selectedMethods': 'selected_methods',
};

Map<String, dynamic> _$MfaFlowStartRequestToJson(
  MfaFlowStartRequest instance,
) => <String, dynamic>{
  'location_id': instance.locationId,
  'pubkey': instance.pubkey,
  'posture_data': instance.postureData,
  'selected_methods': instance.selectedMethods
      .map((e) => _$MfaMethodEnumMap[e]!)
      .toList(),
};

const _$MfaMethodEnumMap = {
  MfaMethod.totp: 0,
  MfaMethod.email: 1,
  MfaMethod.openid: 2,
  MfaMethod.biometric: 3,
  MfaMethod.fido2: 5,
};

const _$MfaFlowStepStartRequestFieldMap = <String, String>{
  'token': 'token',
  'method': 'method',
};

Map<String, dynamic> _$MfaFlowStepStartRequestToJson(
  MfaFlowStepStartRequest instance,
) => <String, dynamic>{
  'token': instance.token,
  'method': _$MfaMethodEnumMap[instance.method]!,
};
