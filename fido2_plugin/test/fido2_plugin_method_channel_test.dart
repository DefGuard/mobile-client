import 'package:fido2_plugin/fido2_plugin.dart';
import 'package:fido2_plugin/fido2_plugin_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFido2Plugin();

  void answer(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, handler);

  Future<Fido2Assertion> getAssertion() => platform.getAssertion(
    rpId: 'core.example',
    clientDataHash: Uint8List(32),
    allowCredentials: [
      Uint8List.fromList([1]),
    ],
    timeout: const Duration(seconds: 1),
  );

  Matcher throwsCode(Fido2ErrorCode code) =>
      throwsA(isA<Fido2Exception>().having((e) => e.code, 'code', code));

  test('an assertion is read from the result map', () async {
    answer(
      (_) async => {
        'authenticatorData': Uint8List.fromList([1]),
        'signature': Uint8List.fromList([2]),
        'credentialId': Uint8List.fromList([3]),
      },
    );
    final assertion = await getAssertion();
    expect(assertion.authenticatorData, [1]);
    expect(assertion.signature, [2]);
    expect(assertion.credentialId, [3]);
  });

  test('a malformed result is a plugin error, not a TypeError', () async {
    answer((_) async => {'signature': 'not bytes'});
    await expectLater(getAssertion(), throwsCode(Fido2ErrorCode.unknown));
  });

  test('a result of the wrong type is a plugin error', () async {
    answer((_) async => 'not a map');
    await expectLater(getAssertion(), throwsCode(Fido2ErrorCode.unknown));
  });

  test('a wrong PIN carries the retries left', () async {
    answer(
      (_) async => throw PlatformException(
        code: 'pinInvalid',
        details: {'pinRetries': 2},
      ),
    );
    await expectLater(
      getAssertion(),
      throwsA(
        isA<Fido2Exception>()
            .having((e) => e.code, 'code', Fido2ErrorCode.pinInvalid)
            .having((e) => e.pinRetries, 'pinRetries', 2),
      ),
    );
  });

  test('unknown native codes map to unknown', () async {
    answer((_) async => throw PlatformException(code: 'error'));
    await expectLater(getAssertion(), throwsCode(Fido2ErrorCode.unknown));
  });
}
