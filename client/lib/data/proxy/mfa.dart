import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/enterprise/postures.dart';

part 'mfa.g.dart';

@JsonSerializable()
class StartMfaRequest {
  final String pubkey;
  final int locationId;

  /// Read by a pre-2.2 proxy, which ignores [selectedMethods]. Always the first
  /// step's method.
  final MfaMethod method;
  final DevicePostureData? postureData;

  /// One method per step in flow order. Non-empty is what tells a 2.2 proxy to
  /// run the multi-step flow rather than the legacy single-step adapter.
  final List<MfaMethod> selectedMethods;

  const StartMfaRequest({
    required this.pubkey,
    required this.locationId,
    required this.method,
    required this.selectedMethods,
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

  /// Sparse, and only ever sent by a 2.2 proxy. Non-empty means the plan was
  /// refused and no session exists.
  @JsonKey(defaultValue: <MfaStepRejection>[])
  final List<MfaStepRejection> rejections;

  factory StartMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$StartMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartMfaResponseToJson(this);

  const StartMfaResponse({
    required this.token,
    required this.challenge,
    required this.rejections,
  });
}

@JsonSerializable()
class FinishMfaRequest {
  final String token;
  final String? code;
  final String? authPubKey;

  /// Binds this proof to one attempt at the current step. Omitted on the legacy
  /// single-step path, which has no attempt id.
  @JsonKey(includeIfNull: false)
  final String? stepAttemptId;

  const FinishMfaRequest({
    required this.token,
    this.code,
    this.authPubKey,
    this.stepAttemptId,
  });

  factory FinishMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$FinishMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FinishMfaRequestToJson(this);
}

class FinishMfaResponse {
  /// Deprecated in 2.2 and the only field a pre-2.2 proxy sets.
  final String? presharedKey;

  /// Absent from a pre-2.2 proxy, which reports completion through
  /// [presharedKey] and failure through the status code.
  final MfaOutcome? outcome;

  const FinishMfaResponse({this.presharedKey, this.outcome});

  factory FinishMfaResponse.fromJson(Map<String, dynamic> json) =>
      FinishMfaResponse(
        presharedKey: json['preshared_key'] as String?,
        outcome: parseMfaOutcome(json['result']),
      );
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

@JsonSerializable()
class RemoteMfaQr {
  final String instanceId;
  final String token;
  final String challenge;

  factory RemoteMfaQr.fromJson(Map<String, dynamic> json) =>
      _$RemoteMfaQrFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteMfaQrToJson(this);

  const RemoteMfaQr({
    required this.instanceId,
    required this.token,
    required this.challenge,
  });
}

enum MfaStartRejectionReason {
  @JsonValue(0)
  unspecified,
  @JsonValue(1)
  methodNotInStep,
  @JsonValue(2)
  stepEmptyAfterLicense,
  @JsonValue(3)
  stepUnavailable,
}

@JsonSerializable()
class MfaStepRejection {
  final int step;
  @JsonKey(unknownEnumValue: MfaStartRejectionReason.unspecified)
  final MfaStartRejectionReason reason;

  const MfaStepRejection({required this.step, required this.reason});

  factory MfaStepRejection.fromJson(Map<String, dynamic> json) =>
      _$MfaStepRejectionFromJson(json);

  Map<String, dynamic> toJson() => _$MfaStepRejectionToJson(this);

  /// Step numbers are zero-based on the wire and one-based for people.
  String get message => switch (reason) {
    MfaStartRejectionReason.methodNotInStep =>
      "The method chosen for verification step ${step + 1} is not allowed. "
          "The location's MFA settings have changed, so pick a method again.",
    MfaStartRejectionReason.stepEmptyAfterLicense =>
      "Verification step ${step + 1} has no method available on this server. "
          "Contact your administrator.",
    MfaStartRejectionReason.stepUnavailable =>
      "The method chosen for verification step ${step + 1} cannot be used. "
          "Set it up first, or pick a different one.",
    MfaStartRejectionReason.unspecified =>
      "The server rejected verification step ${step + 1}.",
  };
}

class MfaRejectedException implements Exception {
  final List<MfaStepRejection> rejections;

  const MfaRejectedException(this.rejections);

  String get message => rejections.map((r) => r.message).join(' ');

  @override
  String toString() => "MFA start rejected: $message";
}

class MfaCodeRejectedException implements Exception {
  const MfaCodeRejectedException();

  @override
  String toString() => "MFA proof rejected";
}

@JsonSerializable()
class StepStartMfaRequest {
  final String token;
  final MfaMethod method;

  const StepStartMfaRequest({required this.token, required this.method});

  factory StepStartMfaRequest.fromJson(Map<String, dynamic> json) =>
      _$StepStartMfaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StepStartMfaRequestToJson(this);
}

@JsonSerializable()
class StepStartMfaResponse {
  final String stepAttemptId;
  final String? challenge;

  const StepStartMfaResponse({required this.stepAttemptId, this.challenge});

  factory StepStartMfaResponse.fromJson(Map<String, dynamic> json) =>
      _$StepStartMfaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StepStartMfaResponseToJson(this);
}

/// Outcome of one submitted proof.
sealed class MfaOutcome {
  const MfaOutcome();
}

class MfaAdvanced extends MfaOutcome {
  final int nextStep;

  const MfaAdvanced(this.nextStep);
}

class MfaCompleted extends MfaOutcome {
  /// Absent when the location's peer needs no preshared key.
  final String? presharedKey;

  const MfaCompleted(this.presharedKey);
}

/// The out-of-band factor has not resolved yet. Not a failure, and it does not
/// count against the attempt limit.
class MfaAwaitingExternal extends MfaOutcome {
  const MfaAwaitingExternal();
}

String _outcomeKey(String key) => key.toLowerCase().replaceAll('_', '');

Never _unrecognized(Object? result) =>
    throw FormatException('Unrecognized MFA step result', jsonEncode(result));

/// Reads `ClientMfaFinishResponse.result`. The proxy serializes the proto
/// `oneof` through serde, so the variant arrives as the single key of an
/// `outcome` object. Only the key spelling is treated as uncertain; an
/// unexpected shape throws with the body so the mismatch is visible.
MfaOutcome? parseMfaOutcome(Object? result) {
  if (result == null) return null;
  if (result is! Map<String, dynamic>) _unrecognized(result);

  final outcome = result['outcome'];
  if (outcome == null) return null;
  if (outcome is! Map<String, dynamic> || outcome.length != 1) {
    _unrecognized(result);
  }

  final body = outcome.values.single;
  return switch (_outcomeKey(outcome.keys.single)) {
    'advanced' => MfaAdvanced(
      body is Map<String, dynamic>
          ? (body['next_step'] ?? body['nextStep']) as int
          : _unrecognized(result),
    ),
    'completed' => MfaCompleted(
      body is Map<String, dynamic>
          ? (body['preshared_key'] ?? body['presharedKey']) as String?
          : _unrecognized(result),
    ),
    'awaitingexternal' => const MfaAwaitingExternal(),
    _ => _unrecognized(result),
  };
}
