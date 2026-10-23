import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/mfa/mfa_transport.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/open/api.dart';
import 'package:mobile/open/screens/mfa/mfa_code_screen.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/widgets/toaster/toast_manager.dart';

class _FailingTransport implements MfaTransport {
  final MfaRequestFailure failure;

  const _FailingTransport(this.failure);

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async => const MfaSessionStart(
    token: 'flow-token',
    firstStep: MfaStepChallenge(stepAttemptId: 'attempt-1'),
  );

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) async =>
      const MfaStepChallenge(stepAttemptId: 'attempt-1');

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async {
    throw MfaRequestException(
      'MFA flow step finish',
      statusCode: 403,
      failure: failure,
    );
  }
}

class _TestHost implements MfaStepHost {
  @override
  final MfaFlowController controller;
  String? failureMessage;

  _TestHost(MfaRequestFailure failure)
    : controller = MfaFlowController(
        transport: _FailingTransport(failure),
        plan: const [MfaMethod.totp],
        devicePubkey: 'device-key',
        networkId: 11,
      );

  @override
  void reportFailure({
    required String message,
    String? logMessage,
    Object? error,
  }) {
    failureMessage = message;
  }

  @override
  void reportProgress(MfaStepProgress progress) {}

  @override
  void abort() {}
}

void main() {
  Future<(String?, ToastData?)> submitCode(
    WidgetTester tester,
    MfaRequestFailure failure,
  ) async {
    final host = _TestHost(failure);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await host.controller.startStep();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MfaCodeScreen(
            host: host,
            title: 'Verification',
            description: 'Enter your code.',
            fieldLabel: 'Code',
            logLabel: 'MFA',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    final toast = container.read(toastManagerProvider);
    container.read(toastManagerProvider.notifier).remove();
    return (host.failureMessage, toast);
  }

  testWidgets('an exhausted finish is reported with attempt-limit copy', (
    tester,
  ) async {
    final (failureMessage, toast) = await submitCode(
      tester,
      MfaRequestFailure.attemptLimit,
    );

    expect(failureMessage, 'Too many failed attempts. Start connecting again.');
    expect(toast, isNull);
  });

  testWidgets('an unrelated finish 403 remains a generic screen error', (
    tester,
  ) async {
    final (failureMessage, toast) = await submitCode(
      tester,
      MfaRequestFailure.server,
    );

    expect(failureMessage, isNull);
    expect(toast?.message, 'Access forbidden.');
  });
}
