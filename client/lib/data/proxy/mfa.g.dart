// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
          selectedMethods: $checkedConvert(
            'selected_methods',
            (v) => (v as List<dynamic>)
                .map((e) => $enumDecode(_$MfaMethodEnumMap, e))
                .toList(),
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
        'selectedMethods': 'selected_methods',
        'postureData': 'posture_data',
      },
    );

const _$StartMfaRequestFieldMap = <String, String>{
  'pubkey': 'pubkey',
  'locationId': 'location_id',
  'method': 'method',
  'postureData': 'posture_data',
  'selectedMethods': 'selected_methods',
};

Map<String, dynamic> _$StartMfaRequestToJson(StartMfaRequest instance) =>
    <String, dynamic>{
      'pubkey': instance.pubkey,
      'location_id': instance.locationId,
      'method': _$MfaMethodEnumMap[instance.method]!,
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
};

StartMfaResponse _$StartMfaResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StartMfaResponse', json, ($checkedConvert) {
      final val = StartMfaResponse(
        token: $checkedConvert('token', (v) => v as String),
        challenge: $checkedConvert('challenge', (v) => v as String?),
        rejections: $checkedConvert(
          'rejections',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => MfaStepRejection.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              [],
        ),
      );
      return val;
    });

const _$StartMfaResponseFieldMap = <String, String>{
  'token': 'token',
  'challenge': 'challenge',
  'rejections': 'rejections',
};

Map<String, dynamic> _$StartMfaResponseToJson(StartMfaResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'challenge': instance.challenge,
      'rejections': instance.rejections,
    };

FinishMfaRequest _$FinishMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'FinishMfaRequest',
      json,
      ($checkedConvert) {
        final val = FinishMfaRequest(
          token: $checkedConvert('token', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String?),
          authPubKey: $checkedConvert('auth_pub_key', (v) => v as String?),
          stepAttemptId: $checkedConvert(
            'step_attempt_id',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'authPubKey': 'auth_pub_key',
        'stepAttemptId': 'step_attempt_id',
      },
    );

const _$FinishMfaRequestFieldMap = <String, String>{
  'token': 'token',
  'code': 'code',
  'authPubKey': 'auth_pub_key',
  'stepAttemptId': 'step_attempt_id',
};

Map<String, dynamic> _$FinishMfaRequestToJson(FinishMfaRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
      'code': instance.code,
      'auth_pub_key': instance.authPubKey,
      'step_attempt_id': ?instance.stepAttemptId,
    };

SecureInstanceStorage _$SecureInstanceStorageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SecureInstanceStorage', json, ($checkedConvert) {
  final val = SecureInstanceStorage(
    privateKey: $checkedConvert('private_key', (v) => v as String),
    publicKey: $checkedConvert('public_key', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'privateKey': 'private_key', 'publicKey': 'public_key'});

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

MfaStepRejection _$MfaStepRejectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MfaStepRejection', json, ($checkedConvert) {
      final val = MfaStepRejection(
        step: $checkedConvert('step', (v) => (v as num).toInt()),
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(
            _$MfaStartRejectionReasonEnumMap,
            v,
            unknownValue: MfaStartRejectionReason.unspecified,
          ),
        ),
      );
      return val;
    });

const _$MfaStepRejectionFieldMap = <String, String>{
  'step': 'step',
  'reason': 'reason',
};

Map<String, dynamic> _$MfaStepRejectionToJson(MfaStepRejection instance) =>
    <String, dynamic>{
      'step': instance.step,
      'reason': _$MfaStartRejectionReasonEnumMap[instance.reason]!,
    };

const _$MfaStartRejectionReasonEnumMap = {
  MfaStartRejectionReason.unspecified: 0,
  MfaStartRejectionReason.methodNotInStep: 1,
  MfaStartRejectionReason.stepEmptyAfterLicense: 2,
  MfaStartRejectionReason.stepUnavailable: 3,
};

StepStartMfaRequest _$StepStartMfaRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StepStartMfaRequest', json, ($checkedConvert) {
      final val = StepStartMfaRequest(
        token: $checkedConvert('token', (v) => v as String),
        method: $checkedConvert(
          'method',
          (v) => $enumDecode(_$MfaMethodEnumMap, v),
        ),
      );
      return val;
    });

const _$StepStartMfaRequestFieldMap = <String, String>{
  'token': 'token',
  'method': 'method',
};

Map<String, dynamic> _$StepStartMfaRequestToJson(
  StepStartMfaRequest instance,
) => <String, dynamic>{
  'token': instance.token,
  'method': _$MfaMethodEnumMap[instance.method]!,
};

StepStartMfaResponse _$StepStartMfaResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StepStartMfaResponse', json, ($checkedConvert) {
  final val = StepStartMfaResponse(
    stepAttemptId: $checkedConvert('step_attempt_id', (v) => v as String),
    challenge: $checkedConvert('challenge', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'stepAttemptId': 'step_attempt_id'});

const _$StepStartMfaResponseFieldMap = <String, String>{
  'stepAttemptId': 'step_attempt_id',
  'challenge': 'challenge',
};

Map<String, dynamic> _$StepStartMfaResponseToJson(
  StepStartMfaResponse instance,
) => <String, dynamic>{
  'step_attempt_id': instance.stepAttemptId,
  'challenge': instance.challenge,
};
