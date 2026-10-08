import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_transport.dart';
import 'package:mobile/enterprise/postures.dart';

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

  /// Opens the current step. A single-step flow never calls step-start, which
  /// the legacy contract does not have.
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
      // The previous step's screen stays on top while the next one is being
      // opened, so it can still be tapped in that gap.
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
