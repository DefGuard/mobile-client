import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/open/screens/mfa/mfa_step_chrome.dart';
import 'package:mobile/open/screens/mfa/mfa_step_flow.dart';

class _StubTransport implements MfaTransport {
  final List<FinishMfaResponse> answers;
  int _finishes = 0;
  int _attempts = 0;

  _StubTransport(this.answers);

  @override
  Future<StartMfaResponse> start(StartMfaRequest request) async =>
      const StartMfaResponse(token: 'token', challenge: null, rejections: []);

  @override
  Future<StepStartMfaResponse> stepStart(StepStartMfaRequest request) async =>
      StepStartMfaResponse(stepAttemptId: 'attempt-${++_attempts}');

  @override
  Future<FinishMfaResponse> finish(FinishMfaRequest request) async =>
      answers[_finishes++];
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

/// Counts the stacked step routes. Routes below the top one stay in the tree
/// offstage, so a step left behind still shows up here.
int _stepRouteCount() =>
    find.byType(_StubStep, skipOffstage: false).evaluate().length;

void main() {
  late NavigatorState navigator;

  Future<MfaStepFlow> pumpFlow(
    WidgetTester tester, {
    required List<MfaMethod> plan,
    required List<FinishMfaResponse> answers,
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
      buildStepScreen: (host) => _StubStep(host),
    );
  }

  testWidgets('a step screen is pushed on top, and the sheet stays put', (
    tester,
  ) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp],
      answers: [const FinishMfaResponse(outcome: MfaCompleted('psk'))],
    );

    final result = flow.run();
    await tester.pumpAndSettle();
    expect(find.text('step 0'), findsOneWidget);
    expect(_stepRouteCount(), 1);

    flow.reportProgress(await flow.controller.submit(code: '123456'));
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
        const FinishMfaResponse(outcome: MfaAdvanced(1)),
        const FinishMfaResponse(outcome: MfaAdvanced(2)),
        const FinishMfaResponse(outcome: MfaCompleted('psk')),
      ],
    );

    final result = flow.run();
    await tester.pumpAndSettle();

    flow.reportProgress(await flow.controller.submit(code: '111111'));
    await tester.pumpAndSettle();
    expect(find.text('step 1'), findsOneWidget);
    expect(_stepRouteCount(), 2);

    flow.reportProgress(await flow.controller.submit(code: '222222'));
    await tester.pumpAndSettle();
    expect(find.text('step 2'), findsOneWidget);
    expect(_stepRouteCount(), 3);

    flow.reportProgress(await flow.controller.submit(code: '333333'));
    await tester.pumpAndSettle();

    expect(await result, isA<MfaFlowConnected>());
    expect(find.text('connect sheet'), findsOneWidget);
    expect(_stepRouteCount(), 0);
  });

  testWidgets('back on a later step cancels the whole flow', (tester) async {
    final flow = await pumpFlow(
      tester,
      plan: [MfaMethod.totp, MfaMethod.email],
      answers: [const FinishMfaResponse(outcome: MfaAdvanced(1))],
    );

    final result = flow.run();
    await tester.pumpAndSettle();
    flow.reportProgress(await flow.controller.submit(code: '111111'));
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
      plan: [MfaMethod.totp],
      answers: [const FinishMfaResponse(outcome: MfaAwaitingExternal())],
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
