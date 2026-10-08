import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/data/proxy/mfa_flow.dart' as wire;
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/open/api.dart';

abstract class MfaTransport {
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  });

  Future<MfaStepChallenge> startStep(String token, MfaMethod method);

  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  });
}

class MfaSessionStart {
  final String token;
  final MfaStepChallenge firstStep;

  const MfaSessionStart({required this.token, required this.firstStep});
}

class MfaStepChallenge {
  final String? stepAttemptId;
  final String? challenge;
  final List<String> credentialIds;

  const MfaStepChallenge({
    this.stepAttemptId,
    this.challenge,
    this.credentialIds = const [],
  });
}

sealed class MfaCredential {
  const MfaCredential();
}

final class MfaCodeCredential extends MfaCredential {
  final String code;

  const MfaCodeCredential(this.code);
}

final class MfaBiometricCredential extends MfaCredential {
  final String signature;
  final String authPubKey;

  const MfaBiometricCredential({
    required this.signature,
    required this.authPubKey,
  });
}

final class MfaFido2Credential extends MfaCredential {
  final List<int> rpIdHash;
  final List<int> authenticatorData;
  final List<int> signature;
  final List<int> credentialId;

  const MfaFido2Credential._({
    required this.rpIdHash,
    required this.authenticatorData,
    required this.signature,
    required this.credentialId,
  });

  factory MfaFido2Credential.fromAssertion({
    required List<int> signature,
    required List<int> authenticatorData,
    required List<int> credentialId,
  }) {
    if (authenticatorData.length < 37 ||
        signature.isEmpty ||
        credentialId.isEmpty) {
      throw const FormatException('Invalid security key assertion');
    }
    return MfaFido2Credential._(
      rpIdHash: authenticatorData.sublist(0, 32),
      authenticatorData: List.of(authenticatorData),
      signature: List.of(signature),
      credentialId: List.of(credentialId),
    );
  }
}

sealed class MfaFinishResult {
  const MfaFinishResult();
}

final class MfaFinishAdvanced extends MfaFinishResult {
  final int nextStep;

  const MfaFinishAdvanced(this.nextStep);
}

final class MfaFinishCompleted extends MfaFinishResult {
  final String? presharedKey;

  const MfaFinishCompleted(this.presharedKey);
}

final class MfaFinishAwaitingExternal extends MfaFinishResult {
  const MfaFinishAwaitingExternal();
}

class MfaStartRejectedException implements Exception {
  final String message;

  const MfaStartRejectedException(this.message);

  @override
  String toString() => message;
}

class LegacyMfaTransport implements MfaTransport {
  final Uri proxyUrl;
  final ProxyApi _api;

  LegacyMfaTransport(this.proxyUrl, {ProxyApi? api}) : _api = api ?? proxyApi;

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async {
    if (plan.length != 1 || plan.single == MfaMethod.fido2) {
      throw UnsupportedError(
        'The legacy MFA contract supports one non-FIDO2 step',
      );
    }
    final response = await _api.startMfa(
      proxyUrl,
      StartMfaRequest(
        pubkey: devicePubkey,
        locationId: networkId,
        method: plan.single,
        postureData: postureData,
      ),
    );
    return MfaSessionStart(
      token: response.token,
      firstStep: MfaStepChallenge(challenge: response.challenge),
    );
  }

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) =>
      throw UnsupportedError('The legacy MFA contract has no step-start route');

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async {
    if (stepAttemptId != null) {
      throw StateError('The legacy MFA contract does not use step attempt IDs');
    }
    final request = switch (credential) {
      null => FinishMfaRequest(token: token),
      MfaCodeCredential(:final code) => FinishMfaRequest(
        token: token,
        code: code,
      ),
      MfaBiometricCredential(:final signature, :final authPubKey) =>
        FinishMfaRequest(
          token: token,
          code: signature,
          authPubKey: authPubKey,
        ),
      MfaFido2Credential() => throw UnsupportedError(
        'FIDO2 is unavailable on the legacy MFA contract',
      ),
    };
    final response = await _api.finishMfa(proxyUrl, request);
    if (response == null) return const MfaFinishAwaitingExternal();
    final presharedKey = response.presharedKey;
    if (presharedKey == null) throw const MfaCodeRejectedException();
    return MfaFinishCompleted(presharedKey);
  }
}

class MfaFlowProxyTransport implements MfaTransport {
  final Uri proxyUrl;
  final ProxyApi _api;

  MfaFlowProxyTransport(this.proxyUrl, {ProxyApi? api})
    : _api = api ?? proxyApi;

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async {
    final response = await _api.startMfaFlow(
      proxyUrl,
      wire.MfaFlowStartRequest(
        locationId: networkId,
        pubkey: devicePubkey,
        postureData: postureData,
        selectedMethods: plan,
      ),
    );
    switch (response.outcome) {
      case wire.MfaFlowAccepted(:final token, :final firstStep):
        return MfaSessionStart(
          token: token,
          firstStep: _stepChallenge(firstStep),
        );
      case wire.MfaFlowRejected(:final rejections):
        final message = rejections
            .map((rejection) => rejection.message)
            .join(' ');
        throw MfaStartRejectedException(
          message.isEmpty ? 'The server rejected the MFA plan.' : message,
        );
      case wire.MfaFlowStartUnknown():
        throw const FormatException('Unrecognized MFA flow start response');
    }
  }

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) async {
    final response = await _api.startMfaFlowStep(
      proxyUrl,
      wire.MfaFlowStepStartRequest(token: token, method: method),
    );
    final started = response.started;
    if (started == null) {
      throw const FormatException(
        'MFA flow step response did not include a step',
      );
    }
    return _stepChallenge(started);
  }

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async {
    if (stepAttemptId == null || stepAttemptId.isEmpty) {
      throw StateError('The MFA flow contract requires a step attempt ID');
    }
    final submission = switch (credential) {
      null => null,
      MfaCodeCredential(:final code) => wire.MfaFlowCodeSubmission(code),
      MfaBiometricCredential(:final signature) =>
        wire.MfaFlowBiometricSubmission(signature),
      MfaFido2Credential(
        :final rpIdHash,
        :final authenticatorData,
        :final signature,
        :final credentialId,
      ) =>
        wire.MfaFlowFido2Submission(
          rpIdHash: rpIdHash,
          authenticatorData: authenticatorData,
          signature: signature,
          credentialId: credentialId,
        ),
    };
    final response = await _api.finishMfaFlow(
      proxyUrl,
      wire.MfaFlowStepFinishRequest(
        token: token,
        stepAttemptId: stepAttemptId,
        submission: submission,
      ),
    );
    return switch (response.result) {
      wire.MfaFlowAdvanced(:final nextStep) => MfaFinishAdvanced(nextStep),
      wire.MfaFlowCompleted(:final presharedKey) => MfaFinishCompleted(
        presharedKey,
      ),
      wire.MfaFlowAwaitingExternal() => const MfaFinishAwaitingExternal(),
      _ => throw const FormatException('Unrecognized MFA flow finish response'),
    };
  }
}

MfaStepChallenge _stepChallenge(wire.MfaFlowStepStarted step) =>
    switch (step.challenge) {
      null => MfaStepChallenge(stepAttemptId: step.stepAttemptId),
      wire.MfaSignatureChallenge(:final challenge) => MfaStepChallenge(
        stepAttemptId: step.stepAttemptId,
        challenge: challenge,
      ),
      wire.MfaFido2Challenge(:final challenge, :final credentialIds) =>
        MfaStepChallenge(
          stepAttemptId: step.stepAttemptId,
          challenge: challenge,
          credentialIds: credentialIds,
        ),
      wire.MfaUnknownChallenge() => throw const FormatException(
        'Unrecognized MFA flow challenge',
      ),
    };

MfaTransport mfaTransportForContract(MfaContract contract, Uri proxyUrl) =>
    switch (contract) {
      MfaContract.legacy => LegacyMfaTransport(proxyUrl),
      MfaContract.multiStep => MfaFlowProxyTransport(proxyUrl),
    };
