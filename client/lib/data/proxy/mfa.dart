import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/enterprise/postures.dart';

part 'mfa.g.dart';

@JsonSerializable()
class StartMfaRequest {
  final String pubkey;
  final int locationId;
  final MfaMethod method;
  final DevicePostureData? postureData;

  const StartMfaRequest({
    required this.pubkey,
    required this.locationId,
    required this.method,
    this.postureData,
  });

  factory StartMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$StartMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaRequestToJson(this);
}

@JsonSerializable()
class StartMfaResponse {
  final String token;
  final String? challenge;

  const StartMfaResponse({required this.token, required this.challenge});

  factory StartMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$StartMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaResponseToJson(this);
}

@JsonSerializable()
class FinishMfaRequest {
  final String token;
  final String? code;
  final String? authPubKey;

  const FinishMfaRequest({required this.token, this.code, this.authPubKey});

  factory FinishMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaRequestToJson(this);
}

@JsonSerializable()
class FinishMfaResponse {
  final String? presharedKey;

  const FinishMfaResponse({this.presharedKey});

  factory FinishMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaResponseToJson(this);
}

class MfaCodeRejectedException implements Exception {
  const MfaCodeRejectedException();

  @override
  String toString() => 'MFA proof rejected';
}

@JsonSerializable()
class SecureInstanceStorage {
  final String privateKey;
  final String publicKey;

  factory SecureInstanceStorage.fromJson(Map<String, dynamic> json) =>
      _$SecureInstanceStorageFromJson(json);

  Map<String, dynamic> toJson() => _$SecureInstanceStorageToJson(this);

  const SecureInstanceStorage({
    required this.privateKey,
    required this.publicKey,
  });
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Core sends short alphanumeric values. The cap bounds size with headroom.
final _qrSecret = RegExp(r'^[A-Za-z0-9]{1,128}$');

/// A 2.2 token is alphanumeric, but a pre-2.2 token is a JWT.
final _qrToken = RegExp(r'^[A-Za-z0-9._-]{1,4096}$');

bool _isQrSecret(Object? value) => value is String && _qrSecret.hasMatch(value);

sealed class RemoteMfaQr {
  final String instanceId;
  final String token;
  final String challenge;

  const RemoteMfaQr({
    required this.instanceId,
    required this.token,
    required this.challenge,
  });

  factory RemoteMfaQr.fromJson(Map<String, dynamic> json) {
    final instanceId = json['instance_id'];
    final token = json['token'];
    final challenge = json['challenge'];
    if (instanceId is! String ||
        !_uuid.hasMatch(instanceId) ||
        token is! String ||
        !_qrToken.hasMatch(token) ||
        !_isQrSecret(challenge)) {
      throw const FormatException('Invalid remote MFA QR');
    }

    if (!json.containsKey('step_attempt_id')) {
      return LegacyRemoteMfaQr(
        instanceId: instanceId,
        token: token,
        challenge: challenge,
      );
    }

    final stepAttemptId = json['step_attempt_id'];
    if (!_isQrSecret(stepAttemptId)) {
      throw const FormatException('Invalid remote MFA flow QR');
    }
    return MfaFlowRemoteMfaQr(
      instanceId: instanceId,
      token: token,
      challenge: challenge,
      stepAttemptId: stepAttemptId,
    );
  }
}

final class LegacyRemoteMfaQr extends RemoteMfaQr {
  const LegacyRemoteMfaQr({
    required super.instanceId,
    required super.token,
    required super.challenge,
  });
}

final class MfaFlowRemoteMfaQr extends RemoteMfaQr {
  final String stepAttemptId;

  const MfaFlowRemoteMfaQr({
    required super.instanceId,
    required super.token,
    required super.challenge,
    required this.stepAttemptId,
  });
}

@JsonSerializable()
class MfaMobileApprovalProof {
  final String signature;
  final String authPubKey;

  const MfaMobileApprovalProof({
    required this.signature,
    required this.authPubKey,
  });

  factory MfaMobileApprovalProof.fromJson(Map<String, dynamic> json) =>
      _$MfaMobileApprovalProofFromJson(json);

  Map<String, dynamic> toJson() => _$MfaMobileApprovalProofToJson(this);
}

@JsonSerializable()
class MfaFlowApproveRequest {
  final String token;
  final String stepAttemptId;
  final MfaMobileApprovalProof proof;

  const MfaFlowApproveRequest({
    required this.token,
    required this.stepAttemptId,
    required this.proof,
  });

  factory MfaFlowApproveRequest.fromJson(Map<String, dynamic> json) =>
      _$MfaFlowApproveRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MfaFlowApproveRequestToJson(this);
}
