import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/enterprise/postures.dart';

/// Round-tripped through jsonEncode so the assertions see the real wire shape,
/// not the nested check objects that toJson leaves in place.
Map<String, dynamic> _wire(DevicePlatformFacts facts) =>
    jsonDecode(
          jsonEncode(
            devicePostureData(
              ClientIdentity(version: '1.6.0', facts: facts),
            ),
          ),
        )
        as Map<String, dynamic>;

const _unspecified = {
  'result': {'Unavailable': 0},
};
const _notApplicable = {
  'result': {'Unavailable': 2},
};
const _detectionFailed = {
  'result': {'Unavailable': 3},
};

Map<String, dynamic> _value(Object value) => {
  'result': {'Value': value},
};

void main() {
  group('devicePostureData', () {
    test('reports android facts and the security patch date', () {
      final json = _wire(
        const DevicePlatformFacts(
          kind: PlatformKind.android,
          osFamily: 'android',
          osType: 'Android',
          osName: '14',
          osVersion: '14',
          androidSecurityPatch: '2026-08-01',
        ),
      );

      expect(json['defguard_client_version'], '1.6.0');
      expect(json['os_type'], 'Android');
      expect(json['os_name'], _value('14'));
      expect(json['os_version'], _value('14'));
      expect(json['android_security_patch_date'], _value('2026-08-01'));
      expect(json['device_integrity'], _unspecified);
      expect(json['disk_encryption'], _notApplicable);
      expect(json['antivirus_present'], _notApplicable);
      expect(json['windows_ad_domain_joined'], _notApplicable);
      expect(json['windows_security_update_age_days'], _notApplicable);
      expect(json['linux_kernel_version'], _notApplicable);
    });

    test('marks a missing android security patch as detection failed', () {
      final json = _wire(
        const DevicePlatformFacts(
          kind: PlatformKind.android,
          osFamily: 'android',
          osType: 'Android',
          osName: '14',
          osVersion: '14',
        ),
      );

      expect(json['android_security_patch_date'], _detectionFailed);
    });

    test('separates os name from os version on ios', () {
      final json = _wire(
        const DevicePlatformFacts(
          kind: PlatformKind.ios,
          osFamily: 'ios',
          osType: 'iOS',
          osName: 'iOS',
          osVersion: '18.2',
        ),
      );

      expect(json['os_type'], 'iOS');
      expect(json['os_name'], _value('iOS'));
      expect(json['os_version'], _value('18.2'));
      expect(json['device_integrity'], _notApplicable);
      expect(json['android_security_patch_date'], _notApplicable);
    });

    test('reports os version unavailable on unsupported platforms', () {
      final json = _wire(
        const DevicePlatformFacts(
          kind: PlatformKind.other,
          osFamily: 'linux',
          osType: 'linux',
          osName: 'linux',
          osVersion: '6.1.0',
        ),
      );

      expect(json['os_type'], 'linux');
      expect(json['os_name'], _value('linux'));
      expect(json['os_version'], _unspecified);
      expect(json['android_security_patch_date'], _notApplicable);
    });
  });
}
