import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_flow.dart';
import 'package:mobile/data/proxy/mfa.dart';
import 'package:mobile/enterprise/postures.dart';

class _FakeTransport implements MfaTransport {
  final Queue<Object> startAnswers;
  final Queue<MfaStepChallenge> stepAnswers;
  final Queue<Object> finishAnswers;
  final calls = <String>[];
  final plans = <List<MfaMethod>>[];
  final openedSteps = <MfaMethod>[];
  final stepAttemptIds = <String?>[];
  final credentials = <MfaCredential?>[];

  _FakeTransport({
    Iterable<Object> startAnswers = const [],
    Iterable<MfaStepChallenge> stepAnswers = const [],
    Iterable<Object> finishAnswers = const [],
  }) : startAnswers = Queue.of(startAnswers),
       stepAnswers = Queue.of(stepAnswers),
       finishAnswers = Queue.of(finishAnswers);

  @override
  Future<MfaSessionStart> start({
    required String devicePubkey,
    required int networkId,
    required List<MfaMethod> plan,
    DevicePostureData? postureData,
  }) async {
    calls.add('start');
    plans.add(List.of(plan));
    final answer = startAnswers.removeFirst();
    if (answer is MfaStartRejectedException) throw answer;
    return answer as MfaSessionStart;
  }

  @override
  Future<MfaStepChallenge> startStep(String token, MfaMethod method) async {
    calls.add('step-start');
    openedSteps.add(method);
    return stepAnswers.removeFirst();
  }

  @override
  Future<MfaFinishResult> finish({
    required String token,
    required String? stepAttemptId,
    required MfaCredential? credential,
  }) async {
    calls.add('finish');
    stepAttemptIds.add(stepAttemptId);
    credentials.add(credential);
    final answer = finishAnswers.removeFirst();
    if (answer is MfaCodeRejectedException) throw answer;
    return answer as MfaFinishResult;
  }
}

MfaSessionStart _session({
  String token = 'token',
  String? attemptId = 'first-attempt',
  String? challenge = 'start-challenge',
  List<String> credentialIds = const [],
}) => MfaSessionStart(
  token: token,
  firstStep: MfaStepChallenge(
    stepAttemptId: attemptId,
    challenge: challenge,
    credentialIds: credentialIds,
  ),
);

MfaStepChallenge _step({
  String attemptId = 'step-attempt',
  String? challenge = 'step-challenge',
  List<String> credentialIds = const [],
}) => MfaStepChallenge(
  stepAttemptId: attemptId,
  challenge: challenge,
  credentialIds: credentialIds,
);

MfaFlowController _controller(
  MfaTransport transport,
  List<MfaMethod> plan, {
  MfaPlanRefresh? refreshPlan,
}) => MfaFlowController(
  transport: transport,
  plan: plan,
  devicePubkey: 'device-pubkey',
  networkId: 11,
  refreshPlan: refreshPlan,
);

void main() {
  test('opens each step and advances only from the server result', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      stepAnswers: [_step(attemptId: 'second-attempt')],
      finishAnswers: [
        const MfaFinishAdvanced(1),
        const MfaFinishCompleted('psk'),
      ],
    );
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.biometric,
    ]);

    await controller.startStep();
    expect(controller.token, 'token');
    expect(controller.stepAttemptId, 'first-attempt');
    expect(controller.challenge, 'start-challenge');
    expect(transport.calls, ['start']);

    expect(
      await controller.submit(credential: const MfaCodeCredential('123456')),
      isA<MfaStepAdvanced>(),
    );
    expect(controller.stepIndex, 1);
    expect(controller.stepAttemptId, isNull);
    await controller.startStep();
    expect(transport.openedSteps, [MfaMethod.biometric]);
    expect(controller.stepAttemptId, 'second-attempt');
    expect(controller.challenge, 'step-challenge');

    expect(
      await controller.submit(
        credential: const MfaBiometricCredential(
          signature: 'signature',
          authPubKey: 'auth-public-key',
        ),
      ),
      isA<MfaStepCompleted>(),
    );
    expect(controller.takePresharedKey(), 'psk');
    expect(controller.takePresharedKey(), isNull);
  });

  test('a single step never calls step-start', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      finishAnswers: [const MfaFinishCompleted('psk')],
    );
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    expect(
      await controller.submit(credential: const MfaCodeCredential('123456')),
      isA<MfaStepCompleted>(),
    );
    expect(transport.calls, ['start', 'finish']);
  });

  test(
    'OIDC polling stays pending until external completion on the same attempt',
    () async {
      final transport = _FakeTransport(
        startAnswers: [_session()],
        finishAnswers: [
          const MfaFinishAwaitingExternal(),
          const MfaFinishCompleted('psk'),
        ],
      );
      final controller = _controller(transport, [MfaMethod.openid]);

      await controller.startStep();
      expect(await controller.submit(), isA<MfaStepAwaiting>());
      expect(controller.takePresharedKey(), isNull);
      expect(await controller.submit(), isA<MfaStepCompleted>());
      expect(controller.takePresharedKey(), 'psk');
      expect(transport.stepAttemptIds, ['first-attempt', 'first-attempt']);
      expect(transport.credentials, [null, null]);
    },
  );

  test('a completion without a preshared key still completes', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      finishAnswers: [const MfaFinishCompleted(null)],
    );
    final controller = _controller(transport, [MfaMethod.totp]);

    await controller.startStep();
    expect(
      await controller.submit(credential: const MfaCodeCredential('123456')),
      isA<MfaStepCompleted>(),
    );
    expect(controller.takePresharedKey(), isNull);
  });

  test('FIDO2 sends the raw assertion and authenticator rpId hash', () async {
    final transport = _FakeTransport(
      startAnswers: [
        _session(
          attemptId: 'fido-attempt',
          challenge: 'fido-challenge',
          credentialIds: ['offered-key'],
        ),
      ],
      finishAnswers: [const MfaFinishCompleted('psk')],
    );
    final controller = _controller(transport, [MfaMethod.fido2]);

    await controller.startStep();
    expect(controller.credentialIds, ['offered-key']);
    await controller.submitFido2(
      signature: [0xfb, 0xff],
      authData: List<int>.generate(37, (index) => index),
      credentialId: [7, 8],
    );

    final assertion = transport.credentials.single as MfaFido2Credential;
    expect(assertion.rpIdHash, List<int>.generate(32, (index) => index));
    expect(
      assertion.authenticatorData,
      List<int>.generate(37, (index) => index),
    );
    expect(assertion.signature, [0xfb, 0xff]);
    expect(assertion.credentialId, [7, 8]);
    expect(transport.stepAttemptIds.single, 'fido-attempt');
  });

  test('malformed FIDO2 assertions are never submitted', () async {
    final transport = _FakeTransport(startAnswers: [_session()]);
    final controller = _controller(transport, [MfaMethod.fido2]);
    await controller.startStep();

    expect(
      () => controller.submitFido2(
        signature: [],
        authData: List<int>.filled(32, 1),
        credentialId: [1],
      ),
      throwsFormatException,
    );
    expect(
      () => controller.submitFido2(
        signature: [1],
        authData: List<int>.filled(31, 1),
        credentialId: [1],
      ),
      throwsFormatException,
    );
    expect(
      () => controller.submitFido2(
        signature: [1],
        authData: List<int>.filled(32, 1),
        credentialId: [],
      ),
      throwsFormatException,
    );
    expect(transport.calls, ['start']);
  });

  test('a rejected start refreshes the plan and retries once', () async {
    final transport = _FakeTransport(
      startAnswers: [
        const MfaStartRejectedException('stale plan'),
        _session(),
      ],
    );
    var refreshes = 0;
    final controller = _controller(
      transport,
      [MfaMethod.totp],
      refreshPlan: () async {
        refreshes++;
        return [MfaMethod.email];
      },
    );

    await controller.startStep();
    expect(refreshes, 1);
    expect(transport.calls, ['start', 'start']);
    expect(transport.plans, [
      [MfaMethod.totp],
      [MfaMethod.email],
    ]);
    expect(controller.plan, [MfaMethod.email]);
    expect(controller.method, MfaMethod.email);
  });

  test('a second rejection stops without a third start', () async {
    final transport = _FakeTransport(
      startAnswers: [
        const MfaStartRejectedException('stale plan'),
        const MfaStartRejectedException('still stale'),
      ],
    );
    var refreshes = 0;
    final controller = _controller(
      transport,
      [MfaMethod.totp],
      refreshPlan: () async {
        refreshes++;
        return [MfaMethod.email];
      },
    );

    await expectLater(
      controller.startStep(),
      throwsA(
        isA<MfaStartRejectedException>().having(
          (error) => error.message,
          'message',
          'still stale',
        ),
      ),
    );
    expect(refreshes, 1);
    expect(transport.calls, ['start', 'start']);
  });

  test('a legacy transport refuses multi-step and FIDO2 starts', () async {
    final transport = mfaTransportForContract(
      MfaContract.legacy,
      Uri.parse('https://proxy.example'),
    );
    expect(transport, isA<LegacyMfaTransport>());
    await expectLater(
      transport.start(
        devicePubkey: 'device-pubkey',
        networkId: 11,
        plan: [MfaMethod.totp, MfaMethod.email],
      ),
      throwsUnsupportedError,
    );
    await expectLater(
      transport.start(
        devicePubkey: 'device-pubkey',
        networkId: 11,
        plan: [MfaMethod.fido2],
      ),
      throwsUnsupportedError,
    );
  });

  test('contract selection chooses one transport', () {
    expect(
      mfaTransportForContract(
        MfaContract.multiStep,
        Uri.parse('https://proxy.example'),
      ),
      isA<MfaFlowProxyTransport>(),
    );
  });

  test('the server selects the next step and opens its challenge', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      stepAnswers: [
        _step(
          attemptId: 'fido-attempt',
          challenge: 'fido-challenge',
          credentialIds: ['offered-key'],
        ),
      ],
      finishAnswers: [
        const MfaFinishAdvanced(2),
        const MfaFinishCompleted('psk'),
      ],
    );
    final controller = _controller(transport, [
      MfaMethod.totp,
      MfaMethod.email,
      MfaMethod.fido2,
    ]);

    await controller.startStep();
    expect(
      await controller.submit(credential: const MfaCodeCredential('123456')),
      isA<MfaStepAdvanced>(),
    );
    expect(controller.stepIndex, 2);
    await expectLater(
      controller.submit(credential: const MfaCodeCredential('123456')),
      throwsStateError,
    );

    await controller.startStep();
    expect(transport.openedSteps, [MfaMethod.fido2]);
    expect(controller.challenge, 'fido-challenge');
    expect(controller.credentialIds, ['offered-key']);
    await controller.submitFido2(
      signature: [1],
      authData: List<int>.generate(32, (index) => index),
      credentialId: [2],
    );
    expect(transport.stepAttemptIds, ['first-attempt', 'fido-attempt']);
    expect(controller.takePresharedKey(), 'psk');
  });

  test('an advance beyond the plan is rejected', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      finishAnswers: [const MfaFinishAdvanced(1)],
    );
    final controller = _controller(transport, [MfaMethod.totp]);
    await controller.startStep();

    await expectLater(
      controller.submit(credential: const MfaCodeCredential('123456')),
      throwsA(isA<FormatException>()),
    );
    expect(controller.stepIndex, 0);
    expect(transport.calls, ['start', 'finish']);
  });

  test('a rejected proof can be retried on the same step attempt', () async {
    final transport = _FakeTransport(
      startAnswers: [_session()],
      finishAnswers: [
        const MfaCodeRejectedException(),
        const MfaFinishCompleted('psk'),
      ],
    );
    final controller = _controller(transport, [MfaMethod.totp]);
    await controller.startStep();

    await expectLater(
      controller.submit(credential: const MfaCodeCredential('bad-code')),
      throwsA(isA<MfaCodeRejectedException>()),
    );
    expect(controller.stepAttemptId, 'first-attempt');
    expect(controller.stepIndex, 0);
    await controller.submit(credential: const MfaCodeCredential('123456'));
    expect(transport.stepAttemptIds, ['first-attempt', 'first-attempt']);
    expect(controller.takePresharedKey(), 'psk');
  });

  test('submitting before a step is open is a programming error', () async {
    final controller = _controller(_FakeTransport(), [MfaMethod.totp]);
    await expectLater(
      controller.submit(credential: const MfaCodeCredential('123456')),
      throwsStateError,
    );
  });

  test('a credential for another method never reaches the transport', () async {
    final transport = _FakeTransport(startAnswers: [_session()]);
    final controller = _controller(transport, [MfaMethod.totp]);
    await controller.startStep();

    await expectLater(
      controller.submit(
        credential: const MfaBiometricCredential(
          signature: 'signature',
          authPubKey: 'auth-public-key',
        ),
      ),
      throwsStateError,
    );
    expect(transport.calls, ['start']);
  });
}
