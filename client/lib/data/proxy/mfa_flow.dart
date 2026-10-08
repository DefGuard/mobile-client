import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/enterprise/postures.dart';

part 'mfa_flow.g.dart';

@JsonSerializable(createFactory: false)
class MfaFlowStartRequest {
  final int locationId;
  final String pubkey;
  final DevicePostureData? postureData;
  final List<MfaMethod> selectedMethods;

  const MfaFlowStartRequest({
    required this.locationId,
    required this.pubkey,
    this.postureData,
    required this.selectedMethods,
  });

  Map<String, dynamic> toJson() => _$MfaFlowStartRequestToJson(this);
}

sealed class MfaFlowStartOutcome {
  const MfaFlowStartOutcome();
}

final class MfaFlowAccepted extends MfaFlowStartOutcome {
  final String token;
  final MfaFlowStepStarted firstStep;

  const MfaFlowAccepted({required this.token, required this.firstStep});

  factory MfaFlowAccepted.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final firstStep = _object(json['first_step']);
    if (token is! String || firstStep == null) {
      throw const FormatException('Invalid MFA flow start response');
    }
    return MfaFlowAccepted(
      token: token,
      firstStep: MfaFlowStepStarted.fromJson(firstStep),
    );
  }
}

final class MfaFlowRejected extends MfaFlowStartOutcome {
  final List<MfaStepRejection> rejections;

  const MfaFlowRejected(this.rejections);

  factory MfaFlowRejected.fromJson(Map<String, dynamic> json) {
    final values = json['rejections'];
    if (values == null) return const MfaFlowRejected([]);
    if (values is! List) {
      throw const FormatException('Invalid MFA flow start response');
    }
    return MfaFlowRejected(
      values
          .map((value) {
            final rejection = _object(value);
            if (rejection == null) {
              throw const FormatException('Invalid MFA flow start response');
            }
            return MfaStepRejection.fromJson(rejection);
          })
          .toList(growable: false),
    );
  }
}

final class MfaFlowStartUnknown extends MfaFlowStartOutcome {
  const MfaFlowStartUnknown();
}

class MfaFlowStartResponse {
  final MfaFlowStartOutcome outcome;

  const MfaFlowStartResponse(this.outcome);

  factory MfaFlowStartResponse.fromJson(Map<String, dynamic> json) =>
      switch (_variant(json['outcome'])) {
        ('Accepted', final body) => MfaFlowStartResponse(
          MfaFlowAccepted.fromJson(body),
        ),
        ('Rejected', final body) => MfaFlowStartResponse(
          MfaFlowRejected.fromJson(body),
        ),
        _ => const MfaFlowStartResponse(MfaFlowStartUnknown()),
      };
}

@JsonSerializable(createFactory: false)
class MfaFlowStepStartRequest {
  final String token;
  final MfaMethod method;

  const MfaFlowStepStartRequest({required this.token, required this.method});

  Map<String, dynamic> toJson() => _$MfaFlowStepStartRequestToJson(this);
}

sealed class MfaFlowChallenge {
  const MfaFlowChallenge();
}

final class MfaSignatureChallenge extends MfaFlowChallenge {
  final String challenge;

  const MfaSignatureChallenge(this.challenge);
}

final class MfaFido2Challenge extends MfaFlowChallenge {
  final String challenge;
  final List<String> credentialIds;

  const MfaFido2Challenge({
    required this.challenge,
    required this.credentialIds,
  });
}

final class MfaUnknownChallenge extends MfaFlowChallenge {
  const MfaUnknownChallenge();
}

class MfaFlowStepStarted {
  final String stepAttemptId;
  final MfaFlowChallenge? challenge;

  const MfaFlowStepStarted({required this.stepAttemptId, this.challenge});

  factory MfaFlowStepStarted.fromJson(Map<String, dynamic> json) {
    final attemptId = json['step_attempt_id'];
    if (attemptId is! String || attemptId.isEmpty) {
      throw const FormatException('Invalid MFA flow step response');
    }
    return MfaFlowStepStarted(
      stepAttemptId: attemptId,
      challenge: _parseChallenge(json['challenge']),
    );
  }
}

MfaFlowChallenge? _parseChallenge(Object? value) {
  if (value == null) return null;
  return switch (_variant(value)) {
    ('Signature', final body) =>
      body['challenge'] is String
          ? MfaSignatureChallenge(body['challenge'] as String)
          : const MfaUnknownChallenge(),
    ('Fido2', final body) => _parseFido2Challenge(body),
    _ => const MfaUnknownChallenge(),
  };
}

MfaFlowChallenge _parseFido2Challenge(Map<String, dynamic> json) {
  final challenge = json['challenge'];
  final credentialIds = json['credential_ids'];
  if (challenge is! String ||
      credentialIds is! List ||
      credentialIds.any((id) => id is! String)) {
    return const MfaUnknownChallenge();
  }
  return MfaFido2Challenge(
    challenge: challenge,
    credentialIds: credentialIds.cast<String>(),
  );
}

class MfaFlowStepStartResponse {
  final MfaFlowStepStarted? started;

  const MfaFlowStepStartResponse({this.started});

  factory MfaFlowStepStartResponse.fromJson(Map<String, dynamic> json) {
    final started = _object(json['started']);
    return MfaFlowStepStartResponse(
      started: started == null ? null : MfaFlowStepStarted.fromJson(started),
    );
  }
}

sealed class MfaFlowSubmission {
  const MfaFlowSubmission();

  Map<String, dynamic> toJson();
}

final class MfaFlowCodeSubmission extends MfaFlowSubmission {
  final String code;

  const MfaFlowCodeSubmission(this.code);

  @override
  Map<String, dynamic> toJson() => {
    'Code': {'code': code},
  };
}

final class MfaFlowBiometricSubmission extends MfaFlowSubmission {
  final String signature;

  const MfaFlowBiometricSubmission(this.signature);

  @override
  Map<String, dynamic> toJson() => {
    'Biometric': {'signature': signature},
  };
}

final class MfaFlowFido2Submission extends MfaFlowSubmission {
  final List<int> rpIdHash;
  final List<int> authenticatorData;
  final List<int> signature;
  final List<int> credentialId;

  const MfaFlowFido2Submission({
    required this.rpIdHash,
    required this.authenticatorData,
    required this.signature,
    required this.credentialId,
  });

  @override
  Map<String, dynamic> toJson() => {
    'Fido2': {
      'rp_id_hash': rpIdHash,
      'authenticator_data': authenticatorData,
      'signature': signature,
      'credential_id': credentialId,
    },
  };
}

class MfaFlowStepFinishRequest {
  final String token;
  final String stepAttemptId;
  final MfaFlowSubmission? submission;

  const MfaFlowStepFinishRequest({
    required this.token,
    required this.stepAttemptId,
    this.submission,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'step_attempt_id': stepAttemptId,
    'submission': submission?.toJson(),
  };
}

sealed class MfaFlowResult {
  const MfaFlowResult();
}

final class MfaFlowAdvanced extends MfaFlowResult {
  final int nextStep;

  const MfaFlowAdvanced(this.nextStep);
}

final class MfaFlowCompleted extends MfaFlowResult {
  final String? presharedKey;

  const MfaFlowCompleted(this.presharedKey);
}

final class MfaFlowAwaitingExternal extends MfaFlowResult {
  const MfaFlowAwaitingExternal();
}

final class MfaFlowResultUnknown extends MfaFlowResult {
  const MfaFlowResultUnknown();
}

class MfaFlowStepFinishResponse {
  final MfaFlowResult? result;

  const MfaFlowStepFinishResponse({this.result});

  factory MfaFlowStepFinishResponse.fromJson(Map<String, dynamic> json) {
    final result = _object(json['result']);
    if (result == null) return const MfaFlowStepFinishResponse();

    final parsed = switch (_variant(result['outcome'])) {
      ('Advanced', final body) =>
        body['next_step'] is int
            ? MfaFlowAdvanced(body['next_step'] as int)
            : const MfaFlowResultUnknown(),
      ('Completed', final body) =>
        body['preshared_key'] == null || body['preshared_key'] is String
            ? MfaFlowCompleted(body['preshared_key'] as String?)
            : const MfaFlowResultUnknown(),
      ('AwaitingExternal', _) => const MfaFlowAwaitingExternal(),
      _ => const MfaFlowResultUnknown(),
    };
    return MfaFlowStepFinishResponse(result: parsed);
  }
}

enum MfaStartRejectionReason {
  unspecified(0),
  methodNotInStep(1),
  stepEmptyAfterLicense(2),
  stepUnavailable(3);

  final int wireValue;

  const MfaStartRejectionReason(this.wireValue);

  /// A newer server may send a reason this client does not know yet.
  static MfaStartRejectionReason fromWire(int value) => values.firstWhere(
    (reason) => reason.wireValue == value,
    orElse: () => unspecified,
  );
}

class MfaStepRejection {
  final int step;
  final MfaStartRejectionReason reason;

  const MfaStepRejection({required this.step, required this.reason});

  factory MfaStepRejection.fromJson(Map<String, dynamic> json) {
    final step = json['step'];
    final reason = json['reason'];
    if (step is! int || reason is! int) {
      throw const FormatException('Invalid MFA flow start response');
    }
    return MfaStepRejection(
      step: step,
      reason: MfaStartRejectionReason.fromWire(reason),
    );
  }

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

Map<String, dynamic>? _object(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Splits a serde externally tagged oneof into its tag and body, or null when
/// the value has another shape.
(String, Map<String, dynamic>)? _variant(Object? value) {
  final tagged = _object(value);
  if (tagged == null || tagged.length != 1) return null;
  final body = _object(tagged.values.single);
  if (body == null) return null;
  return (tagged.keys.single, body);
}
