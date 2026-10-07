import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/enterprise/postures.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/screens/mfa/mfa_step_flow.dart';

class _StubTransport implements MfaTransport {
  final List<MfaFinishResult> answers;
  int _finishes = 0;
  int _attempts = 0;

  _StubTransport(this.answers);

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async => MfaSessionStart(
    token: 'token',
    firstStep: const MfaStepChallenge(stepAttemptId: 'first-attempt'),
  );

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) async =>
      MfaStepChallenge(stepAttemptId: 'attempt-${++_attempts}');

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async => answers[_finishes++];
}

/// Stands in for a real step screen: shows which step it is and nothing else.
class _StubStep extends StatelessWidget {
  final MfaStepHost host;

  const _StubStep(this.host);

  @override
  Widget build(BuildContext context) => MfaStepScope(
    host: host,
    child: Scaffold(
      body: Center(child: Text('step ${host.controller.stepIndex}')),
    ),
  );
}

const String _sheetRoute = 'connect-sheet';

int _stepRouteCount() =>
    find.byType(_StubStep, skipOffstage: false).evaluate().length;

void main() {
  late NavigatorState navigator;

  Future<MfaStepFlow> pumpFlow(
    WidgetTester tester, {
    required List<MfaMethod> plan,
    required List<MfaFinishResult> answers,
  }) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: const RouteSettings(name: _sheetRoute),
          builder: (_) => const Scaffold(body: Text('connect sheet')),
        ),
      ),
    );
    navigator = key.currentState!;

    return MfaStepFlow(
      navigator: navigator,
      controller: MfaFlowController(
        transport: _StubTransport(answers),
        plan: plan,
        devicePubkey: 'device-pubkey',
        networkId: 11,
      ),
      proxyUrl: 'https://proxy.example/',
      instanceUrl: 'https://core.example/',
      buildStepScreen: (host) => _StubStep(host),
    );
  }

  testWidgets('a step screen is pushed on top, and the sheet stays put', (
    tester,
  ) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp],
      answers: [const MfaFinishCompleted('psk')],
    );

    final result = flow.run();
    await tester.pumpAndSettle();
    expect(find.text('step 0'), findsOneWidget);
    expect(_stepRouteCount(), 1);

    flow.reportProgress(
      await flow.controller.submit(
        credential: const MfaCodeCredential('123456'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await result, isA<MfaFlowConnected>());
    expect(find.text('connect sheet'), findsOneWidget);
    expect(_stepRouteCount(), 0);
    expect(flow.controller.takePresharedKey(), 'psk');
  });

  testWidgets('later steps stack up, so the sheet is never exposed', (
    tester,
  ) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp, MfaMethod.email, MfaMethod.totp],
      answers: [
        const MfaFinishAdvanced(1),
        const MfaFinishAdvanced(2),
        const MfaFinishCompleted('psk'),
      ],
    );

    final result = flow.run();
    await tester.pumpAndSettle();

    flow.reportProgress(
      await flow.controller.submit(
        credential: const MfaCodeCredential('111111'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('step 1'), findsOneWidget);
    expect(_stepRouteCount(), 2);

    flow.reportProgress(
      await flow.controller.submit(
        credential: const MfaCodeCredential('222222'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('step 2'), findsOneWidget);
    expect(_stepRouteCount(), 3);

    flow.reportProgress(
      await flow.controller.submit(
        credential: const MfaCodeCredential('333333'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await result, isA<MfaFlowConnected>());
    expect(find.text('connect sheet'), findsOneWidget);
    expect(_stepRouteCount(), 0);
  });

  testWidgets('back on a later step cancels the whole flow', (tester) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp, MfaMethod.email],
      answers: [const MfaFinishAdvanced(1)],
    );

    final result = flow.run();
    await tester.pumpAndSettle();
    flow.reportProgress(
      await flow.controller.submit(
        credential: const MfaCodeCredential('111111'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_stepRouteCount(), 2);

    navigator.maybePop();
    await tester.pumpAndSettle();

    expect(await result, isA<MfaFlowCancelled>());
    expect(flow.controller.isCancelled, isTrue);
    expect(find.text('connect sheet'), findsOneWidget);
    expect(_stepRouteCount(), 0);
  });

  testWidgets('a reported failure unwinds with its message', (tester) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp],
      answers: const [],
    );

    final result = flow.run();
    await tester.pumpAndSettle();
    flow.reportFailure(message: 'Nope', logMessage: 'log', error: 'err');
    await tester.pumpAndSettle();

    final failure = await result as MfaFlowFailed;
    expect(failure.message, 'Nope');
    expect(_stepRouteCount(), 0);
  });

  testWidgets('an unresolved external factor leaves the step in place', (
    tester,
  ) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.openid],
      answers: [const MfaFinishAwaitingExternal()],
    );

    flow.run();
    await tester.pumpAndSettle();
    flow.reportProgress(await flow.controller.submit());
    await tester.pumpAndSettle();

    expect(find.text('step 0'), findsOneWidget);
    expect(_stepRouteCount(), 1);
    flow.abort();
    await tester.pumpAndSettle();
  });
}
