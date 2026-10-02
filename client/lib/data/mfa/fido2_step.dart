import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fido2_plugin/fido2_plugin.dart';

sealed class Fido2Attempt {
  const Fido2Attempt();
}

class Fido2Success extends Fido2Attempt {
  final Fido2Assertion assertion;

  const Fido2Success(this.assertion);
}

/// The key demanded a PIN, or has one set and may be hiding a credential
/// registered with `credProtect=3`.
class Fido2NeedsPin extends Fido2Attempt {
  const Fido2NeedsPin();
}

/// The key has none of the offered credentials.
class Fido2WrongKey extends Fido2Attempt {
  const Fido2WrongKey();
}

/// A PIN was entered for a key that has none.
class Fido2PinNotSet extends Fido2Attempt {
  const Fido2PinNotSet();
}

/// Too short or too long for any key to accept, so the key was never asked.
class Fido2PinMalformed extends Fido2Attempt {
  const Fido2PinMalformed();
}

class Fido2PinInvalid extends Fido2Attempt {
  final int? retries;

  const Fido2PinInvalid(this.retries);
}

class Fido2Failed extends Fido2Attempt {
  final Fido2Exception error;

  const Fido2Failed(this.error);
}

/// One tap against the key. Signs the server's challenge the way the core
/// verifies it: `clientDataHash = SHA-256(challenge)`, no clientDataJSON.
class Fido2StepRunner {
  final Fido2Plugin plugin;

  const Fido2StepRunner({this.plugin = const Fido2Plugin()});

  Future<Fido2Attempt> attempt({
    required String rpId,
    required String challenge,
    required List<String> credentialIds,
    String? pin,
  }) async {
    if (pin != null && (pin.runes.length < 4 || utf8.encode(pin).length > 63)) {
      return const Fido2PinMalformed();
    }
    final Fido2Assertion assertion;
    try {
      assertion = await plugin.getAssertion(
        rpId: rpId,
        clientDataHash: Uint8List.fromList(
          sha256.convert(utf8.encode(challenge)).bytes,
        ),
        allowCredentials: credentialIds.map(decodeCredentialId).toList(),
        pin: pin,
      );
    } on Fido2Exception catch (e) {
      return switch (e.code) {
        Fido2ErrorCode.pinRequired => const Fido2NeedsPin(),
        Fido2ErrorCode.noCredentials => const Fido2WrongKey(),
        Fido2ErrorCode.pinNotSet => const Fido2PinNotSet(),
        Fido2ErrorCode.pinInvalid => Fido2PinInvalid(e.pinRetries),
        _ => Fido2Failed(e),
      };
    } catch (e) {
      return Fido2Failed(Fido2Exception(Fido2ErrorCode.unknown, message: '$e'));
    }
    return Fido2Success(assertion);
  }
}

Uint8List decodeCredentialId(String id) =>
    base64Url.decode(base64Url.normalize(id));
