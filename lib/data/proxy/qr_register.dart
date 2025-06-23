import 'package:json_annotation/json_annotation.dart';

part 'qr_register.g.dart';

@JsonSerializable()
class QrInstanceRegistration {
  final String url;
  final String token;

  const QrInstanceRegistration({required this.url, required this.token});

  factory QrInstanceRegistration.fromJson(Map<String, dynamic> json) =>
      _$QrInstanceRegistrationFromJson(json);

  Map<String, dynamic> toJson() => _$QrInstanceRegistrationToJson(this);
}
