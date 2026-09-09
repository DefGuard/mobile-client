import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';

class _FakeTransport implements MfaTransport {
  final List<String> calls = [];
  final List<FinishMfaRequest> finishes = [];
  final List<StartMfaRequest> starts = [];

  /// Answers for successive finish calls. A response is returned, an exception
  /// is thrown.
  final List<Object> finishAnswers;

  int _attempt = 0;

  _FakeTransport({this.finishAnswers = const []});

  @override
  Future<StartMfaResponse> start(StartMfaRequest request) async {
    calls.add('start');
    starts.add(request);
    return const StartMfaResponse(
      token: 'session-token',
      challenge: 'start-challenge',
      rejections: [],
    );
  }

  @override
  Future<StepStartMfaResponse> stepStart(StepStartMfaRequest request) async {
    calls.add('step-start:${request.method.name}');
    return StepStartMfaResponse(
      stepAttemptId: 'attempt-${++_attempt}',
      challenge: 'step-challenge',
    );
  }

  @override
  Future<FinishMfaResponse> finish(FinishMfaRequest request) async {
    calls.add('finish');
    finishes.add(request);
    final answer = finishAnswers[finishes.length - 1];
    if (answer is Exception) throw answer;
    return answer as FinishMfaResponse;
  }
}

MfaFlowController _controller(_FakeTransport transport, List<MfaMethod> plan) =>
    MfaFlowController(
      transport: transport,
      plan: plan,
      devicePubkey: 'device-pubkey',
      networkId: 11,
    );

FinishMfaResponse _advanced(int nextStep) =>
    FinishMfaResponse(outcome: MfaAdvanced(nextStep));

FinishMfaResponse _completed([String? psk = 'psk']) =>
    FinishMfaResponse(outcome: MfaCompleted(psk));

void main() {
  test('a single-step flow never opens a step separately', () async {
    final transport = _FakeTransport(finishAnswers: [_completed()]);
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    expect(await controller.submit(code: '123456'), isA<MfaStepCompleted>());

    expect(transport.calls, ['start', 'finish']);
    expect(transport.starts.single.selectedMethods, [MfaMethod.totp]);
    expect(transport.starts.single.method, MfaMethod.totp);
    expect(transport.finishes.single.stepAttemptId, isNull);
    expect(controller.takePresharedKey(), 'psk');
    expect(controller.stepLabel, isNull);
  });

  test('a pre-2.2 completion comes through the deprecated field', () async {
    final transport = _FakeTransport(
      finishAnswers: [const FinishMfaResponse(presharedKey: 'legacy-psk')],
    );
    final controller = _controller(transport, [MfaMethod.email]);

    await controller.startStep();
    expect(await controller.submit(code: '123456'), isA<MfaStepCompleted>());
    expect(controller.takePresharedKey(), 'legacy-psk');
  });

  test('a pre-2.2 response with no key at all is a rejected proof', () async {
    final transport = _FakeTransport(
      finishAnswers: [const FinishMfaResponse()],
    );
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    await expectLater(
      controller.submit(code: '000000'),
      throwsA(isA<MfaCodeRejectedException>()),
    );
  });

  test('a three-step flow opens every step but the first', () async {
    final transport = _FakeTransport(
      finishAnswers: [_advanced(1), _advanced(2), _completed()],
    );
    final plan = [MfaMethod.totp, MfaMethod.email, MfaMethod.biometric];
    final controller = _controller(transport, plan);

    await controller.startStep();
    expect(controller.stepLabel, 'Step 1/3');
    expect(await controller.submit(code: '111111'), isA<MfaStepAdvanced>());
    expect(controller.stepIndex, 1);

    await controller.startStep();
    expect(controller.stepLabel, 'Step 2/3');
    expect(await controller.submit(code: '222222'), isA<MfaStepAdvanced>());

    await controller.startStep();
    expect(controller.method, MfaMethod.biometric);
    expect(await controller.submit(code: 'signature'), isA<MfaStepCompleted>());

    expect(transport.calls, [
      'start',
      'finish',
      'step-start:email',
      'finish',
      'step-start:biometric',
      'finish',
    ]);
    expect(transport.starts.single.selectedMethods, plan);
    expect(transport.finishes.map((r) => r.stepAttemptId), [
      null,
      'attempt-1',
      'attempt-2',
    ]);
    expect(controller.takePresharedKey(), 'psk');
  });

  test('the server decides which step comes next', () async {
    final transport = _FakeTransport(
      finishAnswers: [_advanced(2), _completed()],
    );
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
      MfaMethod.biometric,
    ]);

    await controller.startStep();
    await controller.submit(code: '111111');
    expect(controller.stepIndex, 2);
    expect(controller.method, MfaMethod.biometric);
  });

  test('an advance past the end of the plan is refused', () async {
    final transport = _FakeTransport(finishAnswers: [_advanced(2)]);
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
    ]);

    await controller.startStep();
    await expectLater(
      controller.submit(code: '111111'),
      throwsA(isA<FormatException>()),
    );
  });

  test('a rejected code is retried on the same attempt', () async {
    final transport = _FakeTransport(
      finishAnswers: [
        _advanced(1),
        const MfaCodeRejectedException(),
        _completed(),
      ],
    );
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
    ]);

    await controller.startStep();
    await controller.submit(code: '111111');
    await controller.startStep();

    await expectLater(
      controller.submit(code: 'wrong'),
      throwsA(isA<MfaCodeRejectedException>()),
    );
    expect(await controller.submit(code: 'right'), isA<MfaStepCompleted>());

    expect(transport.calls, [
      'start',
      'finish',
      'step-start:email',
      'finish',
      'finish',
    ]);
    expect(transport.finishes.last.stepAttemptId, 'attempt-1');
  });

  test(
    'an unresolved external factor is neither success nor failure',
    () async {
      final transport = _FakeTransport(
        finishAnswers: [
          const FinishMfaResponse(outcome: MfaAwaitingExternal()),
          _completed(),
        ],
      );
      final controller = _controller(transport, [MfaMethod.openid]);

      await controller.startStep();
      expect(await controller.submit(), isA<MfaStepAwaiting>());
      expect(controller.takePresharedKey(), isNull);
      expect(await controller.submit(), isA<MfaStepCompleted>());
      expect(controller.takePresharedKey(), 'psk');
    },
  );

  test('a completion with no preshared key still completes', () async {
    final transport = _FakeTransport(finishAnswers: [_completed(null)]);
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    expect(await controller.submit(code: '123456'), isA<MfaStepCompleted>());
    expect(controller.takePresharedKey(), isNull);
  });

  test('the preshared key is handed over exactly once', () async {
    final transport = _FakeTransport(finishAnswers: [_completed()]);
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    await controller.submit(code: '123456');
    expect(controller.takePresharedKey(), 'psk');
    expect(controller.takePresharedKey(), isNull);
  });

  test('the challenge follows the step being opened', () async {
    final transport = _FakeTransport(finishAnswers: [_advanced(1)]);
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.biometric,
    ]);

    await controller.startStep();
    expect(controller.challenge, 'start-challenge');
    await controller.submit(code: '111111');
    expect(controller.challenge, isNull);
    await controller.startStep();
    expect(controller.challenge, 'step-challenge');
  });

  test('cancelling is observable and submits nothing further', () async {
    final transport = _FakeTransport(finishAnswers: [_advanced(1)]);
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
    ]);

    await controller.startStep();
    await controller.submit(code: '111111');
    controller.cancel();

    expect(controller.isCancelled, isTrue);
    expect(transport.calls, ['start', 'finish']);
  });

  test('submitting before the session exists is a programming error', () async {
    final controller = _controller(_FakeTransport(), [MfaMethod.totp]);
    await expectLater(controller.submit(code: '123456'), throwsStateError);
  });

  test('a proof cannot be submitted into the gap between steps', () async {
    final transport = _FakeTransport(finishAnswers: [_advanced(1)]);
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
    ]);

    await controller.startStep();
    await controller.submit(code: '111111');

    // The previous step's screen is still on top until the next one is pushed.
    await expectLater(controller.submit(code: '111111'), throwsStateError);
    expect(transport.calls, ['start', 'finish']);

    await controller.startStep();
    expect(transport.calls.last, 'step-start:email');
  });

  test('polling an open external step does not close it', () async {
    final transport = _FakeTransport(
      finishAnswers: [
        const FinishMfaResponse(outcome: MfaAwaitingExternal()),
        const FinishMfaResponse(outcome: MfaAwaitingExternal()),
        _completed(),
      ],
    );
    final controller = _controller(transport, [MfaMethod.openid]);

    await controller.startStep();
    expect(await controller.submit(), isA<MfaStepAwaiting>());
    expect(await controller.submit(), isA<MfaStepAwaiting>());
    expect(await controller.submit(), isA<MfaStepCompleted>());
  });
}
