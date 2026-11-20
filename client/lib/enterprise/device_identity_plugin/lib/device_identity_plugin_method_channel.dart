import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_identity_plugin_platform_interface.dart';
import 'device_identity_types.dart';

class MethodChannelDeviceIdentityPlugin extends DeviceIdentityPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'net.defguard.device_identity_plugin',
  );

  @override
  Future<List<Uint8List>> generateAttestedIdentity(
    String alias,
    Uint8List challengeData,
  ) async {
    final result = await _invoke<List<Object?>>('generateAttestedIdentity', {
      'alias': alias,
      'challengeData': challengeData,
    });
    if (result == null ||
        result.any((certificate) => certificate is! Uint8List)) {
      throw const DeviceIdentityException(
        IdentityErrorCode.backendFailure,
        message:
            'generateAttestedIdentity returned a malformed certificate chain',
      );
    }
    return result.cast<Uint8List>();
  }

  @override
  Future<Uint8List> signPossession(String alias, Uint8List data) async {
    final result = await _invoke<Uint8List>('signPossession', {
      'alias': alias,
      'data': data,
    });
    if (result == null) {
      throw const DeviceIdentityException(
        IdentityErrorCode.backendFailure,
        message: 'signPossession returned no signature',
      );
    }
    return result;
  }

  @override
  Future<bool> hasIdentity(String alias) async {
    final result = await _invoke<bool>('hasIdentity', {'alias': alias});
    if (result == null) {
      throw const DeviceIdentityException(
        IdentityErrorCode.backendFailure,
        message: 'hasIdentity returned no result',
      );
    }
    return result;
  }

  @override
  Future<void> deleteIdentity(String alias) =>
      _invoke<void>('deleteIdentity', {'alias': alias});

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw DeviceIdentityException(_errorCode(e.code), message: e.message);
    } on MissingPluginException catch (e) {
      throw DeviceIdentityException(
        IdentityErrorCode.unsupported,
        message: e.message,
      );
    } catch (e) {
      throw DeviceIdentityException(
        IdentityErrorCode.backendFailure,
        message: '$e',
      );
    }
  }

  IdentityErrorCode _errorCode(String code) =>
      IdentityErrorCode.values.firstWhere(
        (value) =>
            value.name
                .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match[0]}')
                .toUpperCase() ==
            code,
        orElse: () => IdentityErrorCode.backendFailure,
      );
}
