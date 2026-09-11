import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/client_identity.dart';
import 'package:mobile/data/proto/client_platform_info.pb.dart';

const _facts = DevicePlatformFacts(
  kind: PlatformKind.android,
  osFamily: 'android',
  osType: 'Android',
  osName: '14',
  osVersion: '14',
  codename: 'REL',
  architecture: 'arm64-v8a',
  bitness: '64',
  androidSecurityPatch: '2026-08-01',
);

ClientIdentity _identity({String version = '1.6.0'}) =>
    ClientIdentity(version: version, facts: _facts);

void main() {
  group('ClientIdentitySource', () {
    test('resolves once and caches for later callers', () async {
      var calls = 0;
      final source = ClientIdentitySource(() async {
        calls++;
        return _identity();
      });

      await source.get();
      await source.get();
      await source.get();

      expect(calls, 1);
      expect(source.resolved?.version, '1.6.0');
    });

    test('concurrent callers share one resolve', () async {
      var calls = 0;
      final gate = Completer<ClientIdentity>();
      final source = ClientIdentitySource(() {
        calls++;
        return gate.future;
      });

      final pending = [source.get(), source.get(), source.get()];
      gate.complete(_identity());
      final results = await Future.wait(pending);

      expect(calls, 1);
      expect(results.every((r) => identical(r, results.first)), isTrue);
    });

    test(
      'a failed resolve is not cached and is retried on the next call',
      () async {
        var calls = 0;
        final source = ClientIdentitySource(() async {
          calls++;
          if (calls == 1) throw StateError('no device info');
          return _identity();
        });

        await expectLater(source.get(), throwsStateError);
        expect(source.resolved, isNull);

        final identity = await source.get();

        expect(identity.version, '1.6.0');
        expect(calls, 2);
      },
    );

    test('a hanging resolve times out without poisoning later calls', () async {
      var calls = 0;
      final source = ClientIdentitySource(() {
        calls++;
        if (calls == 1) return Completer<ClientIdentity>().future;
        return Future.value(_identity());
      }, timeout: const Duration(milliseconds: 20));

      await expectLater(source.get(), throwsA(isA<TimeoutException>()));
      expect(await source.get(), isA<ClientIdentity>());
      expect(calls, 2);
    });

    test(
      'a resolve that lands after its timeout still populates the cache',
      () async {
        var calls = 0;
        final late = Completer<ClientIdentity>();
        final source = ClientIdentitySource(() {
          calls++;
          return late.future;
        }, timeout: const Duration(milliseconds: 20));

        await expectLater(source.get(), throwsA(isA<TimeoutException>()));
        late.complete(_identity(version: '9.9.9'));
        await pumpEventQueue();

        expect((await source.get()).version, '9.9.9');
        expect(calls, 1);
      },
    );

    test('warmUp swallows a failure so it can never break boot', () async {
      final source = ClientIdentitySource(
        () async => throw StateError('no device info'),
      );

      await expectLater(source.warmUp(), completes);
      expect(source.resolved, isNull);
    });
  });

  group('ClientIdentity', () {
    test('platformHeader is the base64 encoded platform info', () {
      final decoded = ClientPlatformInfo.fromBuffer(
        base64Decode(_identity().platformHeader),
      );

      expect(decoded.osFamily, 'android');
      expect(decoded.osType, 'Android');
      expect(decoded.version, '14');
      expect(decoded.codename, 'REL');
      expect(decoded.architecture, 'arm64-v8a');
      expect(decoded.bitness, '64');
      expect(decoded.hasEdition(), isFalse);
    });

    test('omits platform fields the device did not report', () {
      const bare = DevicePlatformFacts(
        kind: PlatformKind.other,
        osFamily: 'linux',
        osType: 'linux',
        osName: 'linux',
        osVersion: '6.1.0',
      );
      final decoded = ClientPlatformInfo.fromBuffer(
        base64Decode(
          ClientIdentity(version: '1.6.0', facts: bare).platformHeader,
        ),
      );

      expect(decoded.osFamily, 'linux');
      expect(decoded.version, '6.1.0');
      expect(decoded.hasCodename(), isFalse);
      expect(decoded.hasArchitecture(), isFalse);
      expect(decoded.hasBitness(), isFalse);
    });
  });
}
