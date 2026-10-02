import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fido2_plugin_platform_interface.dart';
import 'fido2_types.dart';

class MethodChannelFido2Plugin extends Fido2PluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('net.defguard.fido2_plugin');

  @override
  Future<Fido2NfcStatus> nfcStatus() async {
    final status = await _invoke<String>('nfcStatus');
    return Fido2NfcStatus.values.asNameMap()[status] ??
        Fido2NfcStatus.unsupported;
  }

  @override
  Future<void> openNfcSettings() => _invoke<void>('openNfcSettings');

  @override
  Future<Fido2Assertion> getAssertion({
    required String rpId,
    required Uint8List clientDataHash,
    required List<Uint8List> allowCredentials,
    String? pin,
    required Duration timeout,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>('getAssertion', {
      'rpId': rpId,
      'clientDataHash': clientDataHash,
      'allowCredentials': allowCredentials,
      'pin': pin,
      'timeoutMs': timeout.inMilliseconds,
    });
    if (result case {
      'authenticatorData': final Uint8List authenticatorData,
      'signature': final Uint8List signature,
      'credentialId': final Uint8List credentialId,
    }) {
      return Fido2Assertion(
        authenticatorData: authenticatorData,
        signature: signature,
        credentialId: credentialId,
      );
    }
    throw const Fido2Exception(
      Fido2ErrorCode.unknown,
      message: 'getAssertion returned a malformed result',
    );
  }

  @override
  Future<void> cancel() => _invoke<void>('cancel');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw Fido2Exception(
        Fido2ErrorCode.values.asNameMap()[e.code] ?? Fido2ErrorCode.unknown,
        message: e.message,
        pinRetries: switch (e.details) {
          {'pinRetries': final int retries} => retries,
          _ => null,
        },
      );
    } on MissingPluginException catch (e) {
      throw Fido2Exception(Fido2ErrorCode.nfcUnavailable, message: e.message);
    } catch (e) {
      // invokeMethod's own cast of an unexpected result type.
      throw Fido2Exception(Fido2ErrorCode.unknown, message: '$e');
    }
  }
}
