import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/db/enums.dart';
import 'package:mobile/data/mfa/mfa_method_api.dart';
import 'package:mobile/data/mfa/mfa_steps.dart';
import 'package:mobile/data/proxy/config.dart';

Map<String, dynamic> _pollResponse(List<Map<String, dynamic>> steps) => {
  'device_config': {
    'configs': [
      {
        'network_id': 11,
        'network_name': 'Warsaw',
        'config': 'wg-config',
        'endpoint': 'vpn.example:51820',
        'assigned_ip': '10.0.0.1/24',
        'pubkey': 'location-pubkey',
        'allowed_ips': '0.0.0.0/0',
        'mfa_enabled': false,
        'keepalive_interval': 25,
        'location_mfa_mode': 2,
        'steps': steps,
      },
    ],
  },
};

void main() {
  group('ApiMfaMethod', () {
    test('maps the four methods mobile can perform', () {
      expect(ApiMfaMethod.totp.supported, MfaMethod.totp);
      expect(ApiMfaMethod.email.supported, MfaMethod.email);
      expect(ApiMfaMethod.oidc.supported, MfaMethod.openid);
      expect(ApiMfaMethod.biometric.supported, MfaMethod.biometric);
    });

    test('leaves the ones it cannot unsupported', () {
      expect(ApiMfaMethod.mobileApprove.supported, isNull);
      expect(ApiMfaMethod.fido2.supported, isNull);
      expect(ApiMfaMethod.unknown.supported, isNull);
    });

    test('round-trips MfaMethod', () {
      for (final method in MfaMethod.values) {
        expect(ApiMfaMethod.of(method).supported, method);
      }
    });

    test('reads a future wire value as unknown', () {
      expect(ApiMfaMethod.fromWire(4), ApiMfaMethod.mobileApprove);
      expect(ApiMfaMethod.fromWire(5), ApiMfaMethod.fido2);
      expect(ApiMfaMethod.fromWire(99), ApiMfaMethod.unknown);
    });
  });

  group('MfaStep parsing', () {
    test('keeps the raw method and marks it unsupported', () {
      final entry = MfaStepMethod.fromJson({'method': 5, 'configured': true});
      expect(entry.apiMethod, ApiMfaMethod.fido2);
      expect(entry.method, isNull);
      expect(entry.configured, isTrue);
    });

    test('treats a missing configured flag as not configured', () {
      expect(MfaStepMethod.fromJson({'method': 0}).configured, isFalse);
    });

    test('tolerates a step with no methods', () {
      expect(MfaStep.fromJson({}).methods, isEmpty);
      expect(MfaStep.fromJson({'methods': []}).methods, isEmpty);
    });

    test('encode is stable across a decode round trip', () {
      final steps = [
        MfaStep([
          MfaStepMethod.supported(MfaMethod.totp),
          const MfaStepMethod(
            apiMethod: ApiMfaMethod.fido2,
            configured: false,
          ),
        ]),
        MfaStep([MfaStepMethod.supported(MfaMethod.email)]),
      ];
      final encoded = encodeMfaSteps(steps);
      expect(encodeMfaSteps(decodeMfaSteps(encoded)), encoded);
      expect(decodeMfaSteps(encoded), steps);
    });

    test('reads corrupt stored JSON as no steps', () {
      expect(decodeMfaSteps('not json'), isEmpty);
      expect(decodeMfaStepPlan('not json'), isEmpty);
    });

    test('plan encoding keeps unsatisfiable steps as holes', () {
      const plan = [MfaMethod.email, null, MfaMethod.totp];
      expect(encodeMfaStepPlan(plan), '[1,null,0]');
      expect(decodeMfaStepPlan('[1,null,0]'), plan);
    });

    test('plan decoding drops nothing when a value is no longer known', () {
      expect(decodeMfaStepPlan('[0,99,1]'), [
        MfaMethod.totp,
        null,
        MfaMethod.email,
      ]);
    });
  });

  group('a whole poll response', () {
    test('parses when a step allows a method mobile cannot perform', () {
      final response = InstanceInfoResponse.fromJson(
        _pollResponse([
          {
            'methods': [
              {'method': 0, 'configured': true},
              {'method': 5, 'configured': true},
            ],
          },
        ]),
      );
      final config = response.deviceConfig!.configs.single;
      expect(config.steps.single.methods.map((m) => m.apiMethod), [
        ApiMfaMethod.totp,
        ApiMfaMethod.fido2,
      ]);
    });

    test('parses when a step allows a method added after 2.2', () {
      final response = InstanceInfoResponse.fromJson(
        _pollResponse([
          {
            'methods': [
              {'method': 99, 'configured': true},
            ],
          },
        ]),
      );
      final entry =
          response.deviceConfig!.configs.single.steps.single.methods.single;
      expect(entry.apiMethod, ApiMfaMethod.unknown);
      expect(entry.method, isNull);
    });

    test('parses a pre-2.2 response that omits steps entirely', () {
      final json = _pollResponse([]);
      (json['device_config'] as Map<String, dynamic>)['configs'][0].remove(
        'steps',
      );

      final config = InstanceInfoResponse.fromJson(
        json,
      ).deviceConfig!.configs.single;
      expect(config.steps, isEmpty);
      expect(config.effectiveSteps, hasLength(1));
    });
  });

  group('legacyMfaSteps', () {
    // The desktop client synthesizes [totp, email, mobileApprove] here. Mobile
    // has to synthesize what its connect sheet offered before multi-step, so a
    // legacy location keeps behaving the same. Do not align these.
    final internalStep = MfaStep(
      const [
        MfaMethod.biometric,
        MfaMethod.totp,
        MfaMethod.email,
      ].map(MfaStepMethod.supported).toList(),
    );

    test('internal offers biometric, authenticator and email', () {
      expect(legacyMfaSteps(LocationMfaMode.internal, false), [internalStep]);
    });

    test('external offers only openid', () {
      expect(legacyMfaSteps(LocationMfaMode.external, false), [
        MfaStep([MfaStepMethod.supported(MfaMethod.openid)]),
      ]);
    });

    test('disabled means no MFA', () {
      expect(legacyMfaSteps(LocationMfaMode.disabled, false), isEmpty);
      expect(legacyMfaSteps(LocationMfaMode.disabled, null), isEmpty);
      expect(legacyMfaSteps(null, false), isEmpty);
      expect(legacyMfaSteps(null, null), isEmpty);
      expect(legacyMfaSteps(LocationMfaMode.unspecified, false), isEmpty);
    });

    test('the pre-1.5 mfaEnabled flag is treated as internal', () {
      expect(legacyMfaSteps(null, true), [internalStep]);
      expect(legacyMfaSteps(LocationMfaMode.unspecified, true), [internalStep]);
    });

    test('external outranks the deprecated flag', () {
      expect(legacyMfaSteps(LocationMfaMode.external, true), [
        MfaStep([MfaStepMethod.supported(MfaMethod.openid)]),
      ]);
    });

    test('every synthesized method is assumed configured', () {
      final methods = legacyMfaSteps(
        LocationMfaMode.internal,
        false,
      ).single.methods;
      expect(methods.map((m) => m.configured), everyElement(isTrue));
    });
  });
}
