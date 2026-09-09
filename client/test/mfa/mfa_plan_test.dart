import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/database.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_method_api.dart';
import 'package:mobile/data/mfa/mfa_plan.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';

Location _location({
  List<MfaStep> steps = const [],
  List<MfaMethod?> plan = const [],
  LocationMfaMode? mode,
  bool? mfaEnabled,
}) => Location(
  id: 1,
  instance: 1,
  networkId: 11,
  name: 'Warsaw',
  address: '10.0.0.1/24',
  pubKey: 'pubkey',
  endpoint: 'vpn.example:51820',
  allowedIps: '0.0.0.0/0',
  keepAliveInterval: 25,
  locationMfaMode: mode,
  mfaEnabled: mfaEnabled,
  mfaSteps: steps,
  mfaStepPlan: plan,
);

MfaStep _step(List<MfaStepMethod> methods) => MfaStep(methods);

MfaStepMethod _entry(MfaMethod method, {bool configured = true}) =>
    MfaStepMethod.supported(method, configured: configured);

const _fido2 = MfaStepMethod(
  apiMethod: ApiMfaMethod.fido2,
  configured: true,
);

void main() {
  group('effectiveMfaSteps', () {
    test('uses the server flow when there is one', () {
      final steps = [
        _step([_entry(MfaMethod.email)]),
      ];
      expect(effectiveMfaSteps(_location(steps: steps)), steps);
    });

    test('synthesizes from the legacy mode when there is not', () {
      final location = _location(mode: LocationMfaMode.external);
      expect(effectiveMfaSteps(location), [
        _step([_entry(MfaMethod.openid)]),
      ]);
    });
  });

  group('shouldStartMfa', () {
    test('is true for any non-empty flow', () {
      expect(
        shouldStartMfa(
          _location(
            steps: [
              _step([_entry(MfaMethod.totp)]),
            ],
          ),
        ),
        isTrue,
      );
      expect(shouldStartMfa(_location(mode: LocationMfaMode.internal)), isTrue);
      expect(shouldStartMfa(_location(mfaEnabled: true)), isTrue);
    });

    test('is false only when the flow is genuinely empty', () {
      expect(
        shouldStartMfa(_location(mode: LocationMfaMode.disabled)),
        isFalse,
      );
      expect(shouldStartMfa(_location()), isFalse);
    });

    test('counts the steps of the flow actually in use', () {
      expect(mfaStepCount(_location(mode: LocationMfaMode.internal)), 1);
      expect(
        mfaStepCount(
          _location(
            steps: [
              _step([_entry(MfaMethod.totp)]),
              _step([_entry(MfaMethod.email)]),
            ],
          ),
        ),
        2,
      );
    });
  });

  group('sanitizeMfaStepPlan', () {
    final twoSteps = [
      _step([_entry(MfaMethod.totp), _entry(MfaMethod.email)]),
      _step([_entry(MfaMethod.biometric), _entry(MfaMethod.totp)]),
    ];

    test('keeps a choice the step still allows', () {
      expect(sanitizeMfaStepPlan([MfaMethod.email, MfaMethod.totp], twoSteps), [
        MfaMethod.email,
        MfaMethod.totp,
      ]);
    });

    test('replaces a method the admin removed from the step', () {
      expect(
        sanitizeMfaStepPlan([MfaMethod.biometric, MfaMethod.totp], twoSteps),
        [MfaMethod.totp, MfaMethod.totp],
      );
    });

    test('replaces a method the user no longer has configured', () {
      final steps = [
        _step([
          _entry(MfaMethod.totp, configured: false),
          _entry(MfaMethod.email),
        ]),
      ];
      expect(sanitizeMfaStepPlan([MfaMethod.totp], steps), [MfaMethod.email]);
    });

    test('grows when a step was added', () {
      expect(sanitizeMfaStepPlan([MfaMethod.email], twoSteps), [
        MfaMethod.email,
        MfaMethod.biometric,
      ]);
    });

    test('truncates when a step was removed', () {
      expect(
        sanitizeMfaStepPlan([
          MfaMethod.email,
          MfaMethod.totp,
          MfaMethod.totp,
        ], twoSteps.take(1).toList()),
        [MfaMethod.email],
      );
    });

    test('seeds an empty plan with the first usable method of each step', () {
      expect(sanitizeMfaStepPlan(const [], twoSteps), [
        MfaMethod.totp,
        MfaMethod.biometric,
      ]);
    });

    test('leaves a hole for a step mobile cannot pass', () {
      final steps = [
        _step([_fido2]),
        _step([_entry(MfaMethod.email)]),
      ];
      expect(sanitizeMfaStepPlan(const [], steps), [null, MfaMethod.email]);
    });

    test('keeps a saved biometric choice', () {
      // Runs on the write path, where biometric availability is unknown. Only
      // resolveMfaStepPlan may drop it.
      expect(
        sanitizeMfaStepPlan([MfaMethod.totp, MfaMethod.biometric], twoSteps),
        [MfaMethod.totp, MfaMethod.biometric],
      );
    });

    test('returns nothing for a flow with no steps', () {
      expect(sanitizeMfaStepPlan([MfaMethod.email], const []), isEmpty);
    });
  });

  group('mfaMethodAvailability', () {
    test('classifies each way a method can be unavailable', () {
      expect(
        mfaMethodAvailability(
          _entry(MfaMethod.totp),
          biometricAvailable: false,
        ),
        MfaMethodAvailability.usable,
      );
      expect(
        mfaMethodAvailability(
          _entry(MfaMethod.email, configured: false),
          biometricAvailable: true,
        ),
        MfaMethodAvailability.notConfigured,
      );
      expect(
        mfaMethodAvailability(
          _entry(MfaMethod.biometric),
          biometricAvailable: false,
        ),
        MfaMethodAvailability.biometryUnavailable,
      );
      expect(
        mfaMethodAvailability(_fido2, biometricAvailable: true),
        MfaMethodAvailability.unsupported,
      );
    });

    test('an unconfigured biometric reads as unconfigured', () {
      expect(
        mfaMethodAvailability(
          _entry(MfaMethod.biometric, configured: false),
          biometricAvailable: false,
        ),
        MfaMethodAvailability.notConfigured,
      );
    });
  });

  group('usableMfaMethods', () {
    test('drops unconfigured, unsupported and gated methods', () {
      final step = _step([
        _entry(MfaMethod.totp),
        _entry(MfaMethod.email, configured: false),
        _entry(MfaMethod.biometric),
        _fido2,
      ]);
      expect(
        usableMfaMethods(step, biometricAvailable: false).map((e) => e.method),
        [MfaMethod.totp],
      );
      expect(
        usableMfaMethods(step, biometricAvailable: true).map((e) => e.method),
        [MfaMethod.totp, MfaMethod.biometric],
      );
    });
  });

  group('pickableMfaMethods', () {
    test('hides factors this client cannot perform', () {
      final step = _step([_entry(MfaMethod.totp), _fido2]);
      expect(pickableMfaMethods(step).map((e) => e.method), [MfaMethod.totp]);
    });

    test('keeps unconfigured methods so the user can see them', () {
      final step = _step([_entry(MfaMethod.email, configured: false)]);
      expect(pickableMfaMethods(step), hasLength(1));
    });

    test('falls back to the raw list when nothing is supported', () {
      final step = _step([_fido2]);
      expect(pickableMfaMethods(step), [_fido2]);
    });
  });

  group('resolveMfaStepPlan', () {
    final steps = [
      _step([_entry(MfaMethod.totp), _entry(MfaMethod.email)]),
      _step([_entry(MfaMethod.email), _entry(MfaMethod.biometric)]),
    ];

    test('prefers a one-off choice', () {
      expect(
        resolveMfaStepPlan(
          _location(steps: steps, plan: [MfaMethod.totp, MfaMethod.email]),
          oneOff: [MfaMethod.email],
          biometricAvailable: true,
        ),
        [MfaMethod.email, MfaMethod.email],
      );
    });

    test('then the saved plan', () {
      expect(
        resolveMfaStepPlan(
          _location(steps: steps, plan: [MfaMethod.email, MfaMethod.biometric]),
          biometricAvailable: true,
        ),
        [MfaMethod.email, MfaMethod.biometric],
      );
    });

    test('then the first usable method', () {
      expect(
        resolveMfaStepPlan(_location(steps: steps), biometricAvailable: true),
        [MfaMethod.totp, MfaMethod.email],
      );
    });

    test('ignores a choice the step no longer allows', () {
      expect(
        resolveMfaStepPlan(
          _location(steps: steps, plan: [MfaMethod.biometric, null]),
          oneOff: [MfaMethod.openid],
          biometricAvailable: true,
        ),
        [MfaMethod.totp, MfaMethod.email],
      );
    });

    test('drops a saved biometric when the device cannot use it', () {
      expect(
        resolveMfaStepPlan(
          _location(steps: steps, plan: [MfaMethod.totp, MfaMethod.biometric]),
          biometricAvailable: false,
        ),
        [MfaMethod.totp, MfaMethod.email],
      );
    });

    test('leaves a hole for a step nothing can satisfy', () {
      expect(
        resolveMfaStepPlan(
          _location(
            steps: [
              _step([_fido2]),
            ],
          ),
          biometricAvailable: true,
        ),
        [null],
      );
    });

    test('does not read past the end of a short plan', () {
      expect(
        resolveMfaStepPlan(
          _location(steps: steps, plan: [MfaMethod.email]),
          biometricAvailable: true,
        ),
        [MfaMethod.email, MfaMethod.email],
      );
    });

    test('ignores a plan longer than the flow', () {
      expect(
        resolveMfaStepPlan(
          _location(
            steps: steps.take(1).toList(),
            plan: [MfaMethod.email, MfaMethod.biometric, MfaMethod.totp],
          ),
          biometricAvailable: true,
        ),
        [MfaMethod.email],
      );
    });

    test('resolves a legacy location the way the old sheet did', () {
      final legacy = _location(mode: LocationMfaMode.internal);
      expect(resolveMfaStepPlan(legacy, biometricAvailable: true), [
        MfaMethod.biometric,
      ]);
      expect(resolveMfaStepPlan(legacy, biometricAvailable: false), [
        MfaMethod.totp,
      ]);
      expect(
        resolveMfaStepPlan(
          _location(mode: LocationMfaMode.internal, plan: [MfaMethod.email]),
          biometricAvailable: true,
        ),
        [MfaMethod.email],
      );
    });
  });

  group('unpassable steps', () {
    test('a flow with a usable method for every step is passable', () {
      final location = _location(
        steps: [
          _step([_entry(MfaMethod.totp)]),
          _step([_entry(MfaMethod.email)]),
        ],
      );
      expect(
        hasUnpassableMfaStep(location, biometricAvailable: false),
        isFalse,
      );
      expect(unpassableStepReason(location, biometricAvailable: false), isNull);
    });

    test('points at biometry setup when that is the fixable cause', () {
      final location = _location(
        steps: [
          _step([_entry(MfaMethod.biometric)]),
        ],
      );
      expect(hasUnpassableMfaStep(location, biometricAvailable: false), isTrue);
      expect(
        unpassableStepReason(location, biometricAvailable: false),
        MfaUnpassableReason.setUpBiometry,
      );
      expect(hasUnpassableMfaStep(location, biometricAvailable: true), isFalse);
    });

    test('reports server-side setup when the method is unconfigured', () {
      final location = _location(
        steps: [
          _step([_entry(MfaMethod.totp, configured: false)]),
        ],
      );
      expect(
        unpassableStepReason(location, biometricAvailable: true),
        MfaUnpassableReason.notConfigured,
      );
    });

    test('reports desktop-only when the step needs another client', () {
      final location = _location(
        steps: [
          _step([_fido2]),
        ],
      );
      expect(
        unpassableStepReason(location, biometricAvailable: true),
        MfaUnpassableReason.desktopOnly,
      );
    });

    test('prefers the actionable cause over the others', () {
      final location = _location(
        steps: [
          _step([
            _fido2,
            _entry(MfaMethod.totp, configured: false),
            _entry(MfaMethod.biometric),
          ]),
        ],
      );
      expect(
        unpassableStepReason(location, biometricAvailable: false),
        MfaUnpassableReason.setUpBiometry,
      );
    });

    test('names the step count for the badge', () {
      expect(mfaStepsToText(3), '3-step verification');
    });
  });
}
