import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/open/api.dart';

/// The three calls the MFA flow makes, behind an interface so the flow can be
/// driven without a proxy in tests.
abstract class MfaTransport {
  Future<StartMfaResponse> start(StartMfaRequest request);

  Future<StepStartMfaResponse> stepStart(StepStartMfaRequest request);

  Future<FinishMfaResponse> finish(FinishMfaRequest request);
}

class ProxyMfaTransport implements MfaTransport {
  final Uri proxyUrl;

  const ProxyMfaTransport(this.proxyUrl);

  @override
  Future<StartMfaResponse> start(StartMfaRequest request) =>
      proxyApi.startMfa(proxyUrl, request);

  @override
  Future<StepStartMfaResponse> stepStart(StepStartMfaRequest request) =>
      proxyApi.stepStartMfa(proxyUrl, request);

  @override
  Future<FinishMfaResponse> finish(FinishMfaRequest request) =>
      proxyApi.finishMfa(proxyUrl, request);
}

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

/// Drives one connect-time MFA flow: opens each step, submits its proof, and
/// decides what the server's answer means. Holds the preshared key privately so
/// it never reaches a widget.
class MfaFlowController {
  /// One method per step, in flow order.
  final List<MfaMethod> plan;
  final String devicePubkey;
  final int networkId;

  /// Collected once for the whole flow and sent only with the first call.
  final DevicePostureData? postureData;

  final MfaTransport transport;

  int _stepIndex = 0;
  String? _token;
  String? _challenge;
  String? _stepAttemptId;
  String? _presharedKey;
  bool _cancelled = false;
  bool _stepOpen = false;

  MfaFlowController({
    required this.transport,
    required this.plan,
    required this.devicePubkey,
    required this.networkId,
    this.postureData,
  }) : assert(plan.isNotEmpty, "a flow needs at least one step");

  int get stepIndex => _stepIndex;

  int get stepCount => plan.length;

  MfaMethod get method => plan[_stepIndex];

  String? get token => _token;

  String? get challenge => _challenge;

  bool get isCancelled => _cancelled;

  /// Only shown for a flow with more than one step.
  String? get stepLabel =>
      plan.length > 1 ? "Step ${_stepIndex + 1}/${plan.length}" : null;

  void cancel() => _cancelled = true;

  /// Reads the preshared key out, leaving nothing behind.
  String? takePresharedKey() {
    final key = _presharedKey;
    _presharedKey = null;
    return key;
  }

  /// Opens the current step. The first call creates the session and submits the
  /// whole plan; later ones open a step within it. A single-step flow never
  /// calls step-start, which a pre-2.2 proxy does not have.
  Future<void> startStep() async {
    final token = _token;
    if (token != null && plan.length > 1) {
      final step = await transport.stepStart(
        StepStartMfaRequest(token: token, method: method),
      );
      _stepAttemptId = step.stepAttemptId;
      _challenge = step.challenge;
      _stepOpen = true;
      return;
    }

    final session = await transport.start(
      StartMfaRequest(
        pubkey: devicePubkey,
        locationId: networkId,
        method: plan.first,
        selectedMethods: plan,
        postureData: postureData,
      ),
    );
    _token = session.token;
    _challenge = session.challenge;
    _stepAttemptId = null;
    _stepOpen = true;
  }

  /// Submits a proof for the current step, or polls for an out-of-band one when
  /// [code] is null. The attempt id is reused across retries, so a rejected code
  /// does not need the step reopening.
  Future<MfaStepProgress> submit({String? code}) async {
    final token = _token;
    if (token == null || !_stepOpen) {
      // The previous step's screen stays on top while the next one is being
      // opened, so it can still be tapped in that gap.
      throw StateError("MFA proof submitted while no step was open");
    }

    final response = await transport.finish(
      FinishMfaRequest(
        token: token,
        code: code,
        stepAttemptId: _stepAttemptId,
      ),
    );

    switch (response.outcome) {
      case MfaAdvanced(:final nextStep):
        if (nextStep < 0 || nextStep >= plan.length) {
          throw FormatException(
            "Server advanced to step ${nextStep + 1} of a "
            "${plan.length}-step flow",
          );
        }
        _stepIndex = nextStep;
        _challenge = null;
        _stepAttemptId = null;
        _stepOpen = false;
        return const MfaStepAdvanced();
      case MfaCompleted(:final presharedKey):
        _presharedKey = presharedKey;
        _stepOpen = false;
        return const MfaStepCompleted();
      case MfaAwaitingExternal():
        return const MfaStepAwaiting();
      case null:
        // Pre-2.2 proxies report completion through the deprecated field only,
        // and an absent key there has always meant the proof was not accepted.
        if (response.presharedKey == null) {
          throw const MfaCodeRejectedException();
        }
        _presharedKey = response.presharedKey;
        _stepOpen = false;
        return const MfaStepCompleted();
    }
  }
}
