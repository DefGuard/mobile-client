import 'package:json_annotation/json_annotation.dart';

part 'mfa.g.dart';

@JsonSerializable()
class StartMfaRequest {
  final String pubkey;
  final int locationId;
  final int method;

  const StartMfaRequest({
    required this.pubkey,
    required this.locationId,
    required this.method,
  });

  factory StartMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$StartMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaRequestToJson(this);
}

@JsonSerializable()
class StartMfaResponse {
  final String token;

  factory StartMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$StartMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaResponseToJson(this);

  const StartMfaResponse({required this.token});
}

@JsonSerializable()
class FinishMfaRequest {
  final String token;
  final String code;

  const FinishMfaRequest({
    required this.token,
    required this.code,
  });

  factory FinishMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaRequestToJson(this);
}

@JsonSerializable()
class FinishMfaResponse {
  final String token;

  factory FinishMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaResponseToJson(this);

  const FinishMfaResponse({required this.token});
}
