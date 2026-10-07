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
    if (authenticatorData.length < 32 ||
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
    return switch (response.outcome) {
      wire.MfaFlowAccepted(:final token, :final firstStep) => MfaSessionStart(
        token: token,
        firstStep: _stepChallenge(firstStep),
      ),
      wire.MfaFlowRejected(:final rejections) =>
        throw MfaStartRejectedException(
          rejections.map((rejection) => rejection.message).join(' ').isEmpty
              ? 'The server rejected the MFA plan.'
              : rejections.map((rejection) => rejection.message).join(' '),
        ),
      wire.MfaFlowStartUnknown() => throw const FormatException(
        'Unrecognized MFA flow start response',
      ),
    };
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

/// What the server said about the proof just submitted.
sealed class MfaStepProgress {
  const MfaStepProgress();
}

class MfaStepAdvanced extends MfaStepProgress {
  const MfaStepAdvanced();
}

class MfaStepCompleted extends MfaStepProgress {
  const MfaStepCompleted();
}

class MfaStepAwaiting extends MfaStepProgress {
  const MfaStepAwaiting();
}

typedef MfaPlanRefresh = Future<List<MfaMethod>?> Function();

/// Drives one connect-time MFA flow and keeps the preshared key out of widgets.
class MfaFlowController {
  List<MfaMethod> _plan;
  final String devicePubkey;
  final int networkId;
  final DevicePostureData? postureData;
  final MfaTransport transport;
  final MfaPlanRefresh? refreshPlan;

  int _stepIndex = 0;
  String? _token;
  String? _challenge;
  List<String> _credentialIds = const [];
  String? _stepAttemptId;
  String? _presharedKey;
  bool _cancelled = false;
  bool _stepOpen = false;
  bool _startRetried = false;

  MfaFlowController({
    required this.transport,
    required List<MfaMethod> plan,
    required this.devicePubkey,
    required this.networkId,
    this.postureData,
    this.refreshPlan,
  }) : _plan = List.unmodifiable(plan),
       assert(plan.isNotEmpty, 'a flow needs at least one step');

  List<MfaMethod> get plan => _plan;

  int get stepIndex => _stepIndex;

  int get stepCount => _plan.length;

  MfaMethod get method => _plan[_stepIndex];

  String? get token => _token;

  String? get challenge => _challenge;

  String? get stepAttemptId => _stepAttemptId;

  List<String> get credentialIds => _credentialIds;

  bool get isCancelled => _cancelled;

  String? get stepLabel =>
      _plan.length > 1 ? 'Step ${_stepIndex + 1}/${_plan.length}' : null;

  void cancel() => _cancelled = true;

  String? takePresharedKey() {
    final key = _presharedKey;
    _presharedKey = null;
    return key;
  }

  Future<void> startStep() async {
    final token = _token;
    if (token != null && _plan.length > 1) {
      _setStep(await transport.startStep(token, method));
      return;
    }

    final session = await _startWithRetry();
    _token = session.token;
    _setStep(session.firstStep);
  }

  Future<MfaSessionStart> _startWithRetry() async {
    try {
      return await _start();
    } on MfaStartRejectedException {
      final refresh = refreshPlan;
      if (_startRetried || refresh == null) rethrow;
      _startRetried = true;
      final refreshedPlan = await refresh();
      if (refreshedPlan == null || refreshedPlan.isEmpty) rethrow;
      _plan = List.unmodifiable(refreshedPlan);
      return _start();
    }
  }

  Future<MfaSessionStart> _start() => transport.start(
    devicePubkey: devicePubkey,
    networkId: networkId,
    plan: _plan,
    postureData: postureData,
  );

  void _setStep(MfaStepChallenge step) {
    _stepAttemptId = step.stepAttemptId;
    _challenge = step.challenge;
    _credentialIds = step.credentialIds;
    _stepOpen = true;
  }

  Future<MfaStepProgress> submit({MfaCredential? credential}) async {
    final token = _token;
    if (token == null || !_stepOpen) {
      throw StateError('MFA proof submitted while no step was open');
    }
    _validateCredential(credential);
    final result = await transport.finish(
      token: token,
      stepAttemptId: _stepAttemptId,
      credential: credential,
    );

    switch (result) {
      case MfaFinishAdvanced(:final nextStep):
        if (nextStep < 0 || nextStep >= _plan.length) {
          throw const FormatException('Invalid MFA flow step transition');
        }
        _stepIndex = nextStep;
        _challenge = null;
        _credentialIds = const [];
        _stepAttemptId = null;
        _stepOpen = false;
        return const MfaStepAdvanced();
      case MfaFinishCompleted(:final presharedKey):
        _presharedKey = presharedKey;
        _stepOpen = false;
        return const MfaStepCompleted();
      case MfaFinishAwaitingExternal():
        return const MfaStepAwaiting();
    }
  }

  void _validateCredential(MfaCredential? credential) {
    final valid = switch (credential) {
      MfaCodeCredential() =>
        method == MfaMethod.totp || method == MfaMethod.email,
      MfaBiometricCredential(:final signature, :final authPubKey) =>
        method == MfaMethod.biometric &&
            signature.isNotEmpty &&
            authPubKey.isNotEmpty,
      MfaFido2Credential() => method == MfaMethod.fido2,
      null => method == MfaMethod.openid,
    };
    if (!valid) throw StateError('Credential does not match the MFA step');
  }

  Future<MfaStepProgress> submitFido2({
    required List<int> signature,
    required List<int> authData,
    required List<int> credentialId,
  }) => submit(
    credential: MfaFido2Credential.fromAssertion(
      signature: signature,
      authenticatorData: authData,
      credentialId: credentialId,
    ),
  );
}
