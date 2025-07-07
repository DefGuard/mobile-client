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
