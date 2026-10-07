import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/enterprise/screens/mfa/openid_mfa_waiting_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';

class _PollingTransport implements MfaTransport {
  final Queue<MfaFinishResult> results;
  final stepAttemptIds = <String?>[];
  final credentials = <MfaCredential?>[];

  _PollingTransport(Iterable<MfaFinishResult> results)
    : results = Queue.of(results);

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async => const MfaSessionStart(
    token: 'session-token',
    firstStep: MfaStepChallenge(stepAttemptId: 'openid-attempt'),
  );

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) =>
      throw StateError('OIDC polling does not open another step');

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async {
    stepAttemptIds.add(stepAttemptId);
    credentials.add(credential);
    return results.removeFirst();
  }
}

class _Host implements MfaStepHost {
  @override
  final MfaFlowController controller;
  final progress = Completer<MfaStepProgress>();

  _Host(this.controller);

  @override
  void reportProgress(MfaStepProgress value) {
    if (!progress.isCompleted) progress.complete(value);
  }

  @override
  void reportFailure({
    required String message,
    String? logMessage,
    Object? error,
  }) {
    if (!progress.isCompleted) progress.completeError(StateError(message));
  }

  @override
  void abort() {
    controller.cancel();
    if (!progress.isCompleted) progress.completeError(StateError('cancelled'));
  }
}

void main() {
  testWidgets('polls without a proof until the OIDC attempt completes', (
    tester,
  ) async {
    final transport = _PollingTransport([
      const MfaFinishAwaitingExternal(),
      const MfaFinishCompleted('preshared-key'),
    ]);
    final controller = MfaFlowController(
      transport: transport,
      plan: [MfaMethod.openid],
      devicePubkey: 'device-pubkey',
      networkId: 11,
    );
    await controller.startStep();
    final host = _Host(controller);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: OpenIdMfaWaitingScreen(host: host)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Waiting for authentication in your browser...'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(await host.progress.future, isA<MfaStepCompleted>());
    expect(transport.stepAttemptIds, ['openid-attempt', 'openid-attempt']);
    expect(transport.credentials, [null, null]);
    expect(controller.takePresharedKey(), 'preshared-key');
  });
}
