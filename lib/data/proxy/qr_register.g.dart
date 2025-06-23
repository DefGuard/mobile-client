// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_register.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrInstanceRegistration _$QrInstanceRegistrationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QrInstanceRegistration', json, ($checkedConvert) {
  final val = QrInstanceRegistration(
    url: $checkedConvert('url', (v) => v as String),
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

const _$QrInstanceRegistrationFieldMap = <String, String>{
  'url': 'url',
  'token': 'token',
};

Map<String, dynamic> _$QrInstanceRegistrationToJson(
  QrInstanceRegistration instance,
) => <String, dynamic>{'url': instance.url, 'token': instance.token};
